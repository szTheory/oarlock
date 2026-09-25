#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const { assertCi, DEFAULT_REQUIRED_JOBS } = require("./ci_monitor.cjs");
const { observe: observeTiming } = require("./ci_timing.cjs");

const SHA = /^[a-f0-9]{40}$/i;
const REQUIRED_WORKFLOW = "CI";

function ghJson(endpoint, options = {}) {
  const result = spawnSync(options.ghBin || process.env.CI_REMOTE_GATE_GH_BIN || "gh", ["api", endpoint], {
    encoding: "utf8",
    env: options.env || process.env,
    timeout: options.timeoutMs || 15_000,
    maxBuffer: 2 * 1024 * 1024,
  });
  if (result.error) throw new Error(`GitHub observation unavailable: ${result.error.message}`);
  if (result.status !== 0) throw new Error(`GitHub observation unavailable: ${result.stderr || result.stdout || "gh api failed"}`);
  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new Error(`GitHub returned invalid JSON: ${error.message}`);
  }
}

function evaluateCandidate({ sha, ci, timing }) {
  const requestedSha = typeof sha === "string" ? sha.toLowerCase() : "";
  if (!SHA.test(requestedSha)) return { observed: false, verified: false, reason: "invalid_sha" };
  if (!ci || !ci.evidence) return { observed: false, verified: false, reason: "ci_unobserved" };
  const evidence = ci.evidence;
  if (ci.exitCode === 2 && ["gh_error", "no_ci_run_for_sha", "timeout"].includes(evidence.reason)) {
    return { observed: false, verified: false, reason: evidence.reason || "ci_unobserved", message: evidence.message };
  }
  if (evidence.reason === "proof_unobserved_or_invalid" && evidence.run?.headSha?.toLowerCase() === requestedSha) {
    return { observed: true, verified: false, reason: "proof_missing_or_invalid", run: evidence.run, message: evidence.message };
  }
  if (evidence.sha?.toLowerCase() !== requestedSha || evidence.run?.headSha?.toLowerCase() !== requestedSha) {
    return { observed: true, verified: false, reason: "run_sha_mismatch" };
  }
  if (evidence.workflow !== REQUIRED_WORKFLOW || evidence.run?.workflowName !== REQUIRED_WORKFLOW) {
    return { observed: true, verified: false, reason: "workflow_identity_invalid" };
  }
  const proof = evidence.proof;
  if (!evidence.verified || !proof?.verified || !SHA.test(proof.testedSha || "") ||
      proof.eventHeadSha?.toLowerCase() !== requestedSha ||
      proof.runId !== evidence.run.id || proof.runAttempt !== evidence.run.attempt) {
    return { observed: true, verified: false, reason: "proof_identity_or_lanes_invalid" };
  }
  const jobs = evidence.jobs || [];
  const jobNames = jobs.map((job) => job.name);
  if (jobs.length !== DEFAULT_REQUIRED_JOBS.length || new Set(jobNames).size !== DEFAULT_REQUIRED_JOBS.length ||
      DEFAULT_REQUIRED_JOBS.some((name) => !jobNames.includes(name)) ||
      jobs.some((job) => !job.found || job.status !== "completed" || job.conclusion !== "success")) {
    return { observed: true, verified: false, reason: "required_lane_invalid" };
  }
  if (!timing?.observed || timing.sha?.toLowerCase() !== requestedSha || timing.run?.id !== evidence.run.id || timing.run?.attempt !== evidence.run.attempt) {
    return { observed: Boolean(timing?.observed), verified: false, reason: "timing_unobserved_or_mismatched" };
  }
  return {
    observed: true,
    verified: true,
    reason: null,
    sha: requestedSha,
    eventHeadSha: proof.eventHeadSha.toLowerCase(),
    testedSha: proof.testedSha.toLowerCase(),
    workflow: evidence.workflow,
    run: evidence.run,
    proof,
    artifact: { name: `ci-proof-${evidence.run.id}-${evidence.run.attempt}`, runId: evidence.run.id, attempt: evidence.run.attempt },
    jobs,
    timing,
  };
}

function requiredCheckStatus(rules) {
  if (!Array.isArray(rules)) return { observed: false, required: null, reason: "rules_unobserved" };
  const required = rules
    .filter((rule) => rule.type === "required_status_checks")
    .flatMap((rule) => rule.parameters?.required_status_checks || [])
    .some((check) => check.context === "CI contract");
  return { observed: true, required, reason: null };
}

function matchProofArtifact(run, response) {
  const artifacts = response && response.artifacts;
  if (!Array.isArray(artifacts)) return { observed: false, verified: false, reason: "artifact_metadata_unobserved" };
  const name = `ci-proof-${run.id}-${run.attempt}`;
  const artifact = artifacts.find((item) => item.name === name);
  if (!artifact) return { observed: true, verified: false, reason: "proof_artifact_missing" };
  if (artifact.expired || artifact.workflow_run?.id !== run.id || artifact.workflow_run?.head_sha?.toLowerCase() !== run.headSha?.toLowerCase() ||
      !Number.isSafeInteger(artifact.id) || !/^sha256:[a-f0-9]{64}$/i.test(artifact.digest || "")) {
    return { observed: true, verified: false, reason: "proof_artifact_identity_invalid" };
  }
  return {
    observed: true,
    verified: true,
    name: artifact.name,
    id: artifact.id,
    digest: artifact.digest.toLowerCase(),
    runId: artifact.workflow_run.id,
    headSha: artifact.workflow_run.head_sha.toLowerCase(),
  };
}

function parseArgs(argv) {
  const args = { _: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--json") args.json = true;
    else if (arg === "--help" || arg === "-h") args.help = true;
    else if (arg.startsWith("--")) {
      const value = argv[index + 1];
      if (!value || value.startsWith("--")) throw new Error(`Missing value for ${arg}`);
      args[arg.slice(2)] = value;
      index += 1;
    } else args._.push(arg);
  }
  return args;
}

function usage() {
  return "Usage: node scripts/ci_remote_gate.cjs candidate --sha <full-sha> [--repo owner/repo] [--json]\n       node scripts/ci_remote_gate.cjs main [--repo owner/repo] [--json]";
}

function repository(options = {}) {
  if (options.repo) return options.repo;
  const result = spawnSync(options.ghBin || process.env.CI_REMOTE_GATE_GH_BIN || "gh", ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], {
    encoding: "utf8", env: options.env || process.env, timeout: options.timeoutMs || 15_000,
  });
  if (result.error || result.status !== 0) throw new Error(`Unable to identify GitHub repository: ${result.stderr || result.error?.message || "gh failed"}`);
  const repo = result.stdout.trim();
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) throw new Error("GitHub returned an invalid repository identity");
  return repo;
}

async function observeCandidate(sha, repo, options = {}) {
  if (!SHA.test(sha || "")) return { observed: false, verified: false, reason: "invalid_sha" };
  const ci = await (options.assertCi || assertCi)({ sha, workflow: "CI", repo, timeout: "60", poll: "0", requiredJobs: [] }, options);
  const timing = (options.observeTiming || observeTiming)({ sha, workflow: "CI", repo }, options);
  const result = evaluateCandidate({ sha, ci, timing });
  if (!result.verified) return result;
  try {
    const metadata = (options.listArtifacts || ((id) => ghJson(`repos/${repo}/actions/runs/${id}/artifacts`, options)))(result.run.id);
    const artifact = matchProofArtifact(result.run, metadata);
    return { ...result, observed: result.observed && artifact.observed, verified: result.verified && artifact.verified, reason: artifact.verified ? null : artifact.reason, artifact };
  } catch (error) {
    return { ...result, observed: false, verified: false, reason: "artifact_metadata_unobserved", message: error.message };
  }
}

async function observeMain(repo, options = {}) {
  const readMainSha = options.getMainSha || (() => ghJson(`repos/${repo}/commits/main`, options).sha);
  const readRules = options.getRules || (() => ghJson(`repos/${repo}/rules/branches/main`, options));
  const observe = options.observeCandidate || observeCandidate;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    let sha;
    let candidate;
    let rules;
    let confirmedSha;
    try {
      sha = await readMainSha(repo);
      candidate = await observe(sha, repo, options);
      rules = await readRules(repo);
      confirmedSha = await readMainSha(repo);
    } catch (error) {
      return { observed: false, verified: false, reason: "github_observation_unavailable", message: error.message };
    }

    if (confirmedSha !== sha) {
      if (attempt < 2) continue;
      return {
        observed: false,
        verified: false,
        reason: "main_head_changed_during_observation",
        sha: confirmedSha,
        previousSha: sha,
        candidate,
      };
    }

    const check = requiredCheckStatus(rules);
    return {
      observed: check.observed && candidate.observed,
      verified: check.required && candidate.verified,
      reason: !check.observed ? check.reason : !check.required ? "CI_contract_not_required" : candidate.reason,
      sha,
      rule: check,
      candidate,
    };
  }
}

async function main(argv = process.argv.slice(2), options = {}) {
  let args;
  try { args = parseArgs(argv); } catch (error) { console.error(error.message); console.error(usage()); return 2; }
  if (args.help || !args._.length) { console.log(usage()); return 0; }
  const command = args._[0];
  if (!["candidate", "main"].includes(command)) { console.error(usage()); return 2; }
  let result;
  try {
    const repo = repository({ ...options, repo: args.repo });
    result = command === "candidate"
      ? await observeCandidate(args.sha, repo, options)
      : await observeMain(repo, options);
  } catch (error) {
    result = { observed: false, verified: false, reason: "github_observation_unavailable", message: error.message };
  }
  console.log(JSON.stringify(result, null, 2));
  return result.verified ? 0 : result.observed ? 1 : 2;
}

if (require.main === module) main().then((code) => { process.exitCode = code; });

module.exports = { evaluateCandidate, ghJson, main, matchProofArtifact, observeCandidate, observeMain, parseArgs, requiredCheckStatus };
