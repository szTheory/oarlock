#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const DEFAULT_REQUIRED_JOBS = [
  "mix test",
  "static analysis",
  "demo PostgreSQL",
  "package smoke",
  "optional dependencies",
  "planning truth",
  "quality checks",
  "CI contract",
];
const MAX_POLL_SECONDS = 3600;
const PROOF_REQUIRED_JOBS = [
  ["test", "mix test"],
  ["dialyzer", "static analysis"],
  ["demo-postgres", "demo PostgreSQL"],
  ["package-smoke", "package smoke"],
  ["optional-deps", "optional dependencies"],
  ["planning-truth", "planning truth"],
  ["quality", "quality checks"],
];

function usage() {
  return `Usage:
  node scripts/ci_monitor.cjs assert-ci --sha <sha> [options]

Commands:
  assert-ci              Wait for and verify a GitHub Actions CI run.

Options:
  --workflow <name>      Workflow name or file name. Default: CI
  --repo <owner/repo>    GitHub repository. Default: inferred by gh
  --timeout <seconds>    Max wait time. Default: 1800
  --poll <seconds>       Poll interval (0 = single shot, max 3600). Default: 20
  --required-job <name>  Required job name. Can be repeated.
  --required-jobs <csv>  Comma-separated required job names.
  --json                 Print machine-readable JSON evidence.
  --help                 Show this help.

Exit codes:
  0    CI evidence verified
  1    CI run or a required job completed unsuccessfully
  2    Blocked: no pushed run, missing auth, or invalid usage
  124  Timed out waiting for CI
`;
}

function parseArgs(argv) {
  const args = { _: [], requiredJobs: [] };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--json") {
      args.json = true;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else if (arg.startsWith("--")) {
      const key = arg.slice(2);
      const value = argv[index + 1];
      if (!value || value.startsWith("--")) {
        throw new Error(`Missing value for ${arg}`);
      }
      index += 1;

      if (key === "required-job") {
        args.requiredJobs.push(value);
      } else if (key === "required-jobs") {
        args.requiredJobs.push(
          ...value
            .split(",")
            .map((job) => job.trim())
            .filter(Boolean),
        );
      } else {
        args[key] = value;
      }
    } else {
      args._.push(arg);
    }
  }

  return args;
}

function runGh(args, options = {}) {
  const ghBin = options.ghBin || process.env.CI_MONITOR_GH_BIN || "gh";
  const result = spawnSync(ghBin, args, {
    encoding: "utf8",
    env: options.env || process.env,
    timeout: options.timeoutMs,
  });

  if (result.error) {
    throw new GhError(`Unable to execute ${ghBin}: ${result.error.message}`, {
      status: 2,
      stderr: result.error.message,
      timedOut: result.error.code === "ETIMEDOUT",
      timeoutMs: options.timeoutMs,
    });
  }

  if (result.status !== 0) {
    throw new GhError(result.stderr || result.stdout || "gh command failed", {
      status: 2,
      stderr: result.stderr,
      stdout: result.stdout,
      ghStatus: result.status,
    });
  }

  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new GhError(`gh returned invalid JSON: ${error.message}`, {
      status: 2,
      stdout: result.stdout,
    });
  }
}

class GhError extends Error {
  constructor(message, details = {}) {
    super(message);
    this.name = "GhError";
    this.details = details;
  }
}

function normalizeRun(run) {
  return {
    id: run.databaseId,
    workflowName: run.workflowName,
    headSha: run.headSha,
    status: run.status,
    conclusion: run.conclusion,
    url: run.url,
    attempt: run.attempt,
    createdAt: run.createdAt,
    updatedAt: run.updatedAt,
  };
}

function findRun({ sha, workflow, repo }, options = {}) {
  const args = [
    "run",
    "list",
    "--commit",
    sha,
    "--workflow",
    workflow,
    "--limit",
    "20",
    "--json",
    "databaseId,workflowName,headSha,status,conclusion,url,attempt,createdAt,updatedAt",
  ];

  if (repo) {
    args.push("--repo", repo);
  }

  const runs = runGh(args, options);
  return runs.find((run) => run.headSha === sha) || null;
}

function viewRun({ runId, repo }, options = {}) {
  const args = [
    "run",
    "view",
    String(runId),
    "--json",
    "databaseId,workflowName,headSha,status,conclusion,url,jobs",
  ];

  if (repo) {
    args.push("--repo", repo);
  }

  return runGh(args, options);
}

function downloadProof({ runId, attempt, repo }, options = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ci-monitor-proof-"));
  const artifactName = `ci-proof-${runId}-${attempt}`;
  const args = ["run", "download", String(runId), "--name", artifactName, "--dir", dir];
  if (repo) args.push("--repo", repo);
  const ghBin = options.ghBin || process.env.CI_MONITOR_GH_BIN || "gh";
  const result = spawnSync(ghBin, args, {
    encoding: "utf8",
    env: options.env || process.env,
    timeout: options.timeoutMs,
    maxBuffer: 1024 * 1024,
  });
  try {
    if (result.error || result.status !== 0) {
      const message = result.error ? result.error.message : result.stderr || result.stdout || "gh artifact download failed";
      throw new GhError(`Unable to observe CI proof artifact: ${message}`, {
        status: 2,
        stderr: result.stderr,
        timedOut: result.error?.code === "ETIMEDOUT",
        timeoutMs: options.timeoutMs,
      });
    }
    const file = path.join(dir, "ci-contract-proof.json");
    const stat = fs.statSync(file);
    if (!stat.isFile() || stat.size === 0 || stat.size > 1024 * 1024) {
      throw new GhError("CI proof artifact is missing, empty, or too large", { status: 2 });
    }
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    if (error instanceof GhError) throw error;
    throw new GhError(`Unable to read CI proof artifact: ${error.message}`, { status: 2 });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function verifyProofAgainstRun(proof, run, options = {}) {
  let validateProof;
  try {
    ({ validateProof } = require("./ci_proof.cjs"));
    validateProof(proof, {
      headSha: run.headSha,
      runId: run.databaseId,
      runAttempt: run.attempt,
    });
  } catch (error) {
    throw new GhError(`CI proof artifact is invalid: ${error.message}`, { status: 2 });
  }
  const byName = new Map((run.jobs || []).map((job) => [job.name, job]));
  for (const [id, name] of PROOF_REQUIRED_JOBS) {
    const recorded = proof.required_jobs.find((job) => job.id === id);
    const hosted = byName.get(name);
    if (!recorded || (hosted && recorded.result !== hosted.conclusion)) {
      throw new GhError(`CI proof job result does not match hosted job: ${id}`, { status: 2 });
    }
  }
  if (options.testedSha && proof.tested_sha !== options.testedSha.toLowerCase()) {
    throw new GhError("CI proof tested SHA does not match requested event SHA", { status: 2 });
  }
  return proof;
}

function jobEvidence(jobs, requiredJobs) {
  const byName = new Map(jobs.map((job) => [job.name, job]));
  const required = requiredJobs.map((name) => {
    const job = byName.get(name);
    return {
      name,
      found: Boolean(job),
      status: job ? job.status : "missing",
      conclusion: job ? job.conclusion : "missing",
      databaseId: job ? job.databaseId : undefined,
      url: job ? job.url : undefined,
    };
  });

  return {
    required,
    missing: required.filter((job) => !job.found).map((job) => job.name),
    failed: required
      .filter((job) => job.found && (job.status !== "completed" || job.conclusion !== "success"))
      .map((job) => job.name),
  };
}

async function assertCi(args, options = {}) {
  const sha = args.sha;
  if (!sha) {
    return {
      exitCode: 2,
      evidence: {
        verified: false,
        reason: "missing_sha",
        message: "Pass --sha <commit-sha>.",
      },
    };
  }

  const workflow = args.workflow || "CI";
  const requiredJobs = args.requiredJobs.length > 0 ? args.requiredJobs : DEFAULT_REQUIRED_JOBS;
  const timeoutSeconds = Number(args.timeout ?? 1800);
  const pollSeconds = Number(args.poll ?? 20);
  if (!Number.isFinite(timeoutSeconds) || timeoutSeconds < 0
    || !Number.isFinite(pollSeconds) || pollSeconds < 0 || pollSeconds > MAX_POLL_SECONDS) {
    return {
      exitCode: 2,
      evidence: {
        verified: false,
        reason: "invalid_usage",
        message: `timeout must be finite and non-negative; poll must be finite and between 0 and ${MAX_POLL_SECONDS} seconds`,
      },
    };
  }
  const repo = args.repo;
  const start = Date.now();
  const deadline = start + timeoutSeconds * 1000;
  let lastEvidence = null;
  let attempted = false;

  while (!attempted || Date.now() < deadline) {
    attempted = true;
    const remainingMs = Math.max(1, deadline - Date.now());
    const commandOptions = { ...options, timeoutMs: Math.max(1, Math.min(remainingMs, options.timeoutMs ?? remainingMs)) };
    let run;
    try {
      run = findRun({ sha, workflow, repo }, commandOptions);
    } catch (error) {
      return {
        exitCode: 2,
        evidence: {
          verified: false,
          reason: "gh_error",
          message: error.message,
          details: error.details || {},
        },
      };
    }

    if (!run) {
      return {
        exitCode: 2,
        evidence: {
          verified: false,
          reason: "no_ci_run_for_sha",
          workflow,
          sha,
        },
      };
    }

    const normalizedRun = normalizeRun(run);

    if (run.status !== "completed") {
      lastEvidence = {
        verified: false,
        reason: "ci_in_progress",
        run: normalizedRun,
      };

      if (pollSeconds <= 0) {
        break;
      }
      const sleepMs = Math.min(pollSeconds * 1000, Math.max(0, deadline - Date.now()));
      if (sleepMs <= 0) break;
      await (options.sleep || sleep)(sleepMs);
      continue;
    }

    const viewRemainingMs = deadline - Date.now();
    if (viewRemainingMs <= 0) break;
    let viewed;
    try {
      viewed = viewRun({ runId: run.databaseId, repo }, {
        ...options,
        timeoutMs: Math.max(1, Math.min(viewRemainingMs, options.timeoutMs ?? viewRemainingMs)),
      });
    } catch (error) {
      return {
        exitCode: 2,
        evidence: {
          verified: false,
          reason: "gh_error",
          message: error.message,
          details: error.details || {},
        },
      };
    }
    const jobs = Array.isArray(viewed.jobs) ? viewed.jobs : [];
    const jobsEvidence = jobEvidence(jobs, requiredJobs);
    const runConclusion = viewed.conclusion || run.conclusion;

    let proof;
    try {
      proof = downloadProof({ runId: run.databaseId, attempt: run.attempt, repo }, {
        ...options,
        timeoutMs: Math.max(1, Math.min(deadline - Date.now(), options.timeoutMs ?? deadline - Date.now())),
      });
      verifyProofAgainstRun(proof, { ...run, ...viewed });
    } catch (error) {
      return {
        exitCode: error.details?.status === 1 ? 1 : 2,
        evidence: {
          verified: false,
          reason: error.details?.status === 1 ? "proof_reports_failed_job" : "proof_unobserved_or_invalid",
          message: error.message,
          details: error.details || {},
          run: normalizeRun({ ...run, ...viewed }),
        },
      };
    }

    const evidence = {
      verified:
        runConclusion === "success" &&
        jobsEvidence.missing.length === 0 &&
        jobsEvidence.failed.length === 0 &&
        proof.verified === true,
      workflow,
      sha,
      run: normalizeRun({ ...run, ...viewed }),
      jobs: jobsEvidence.required,
      proof: {
        testedSha: proof.tested_sha,
        eventHeadSha: proof.event_head_sha,
        runId: proof.run_id,
        runAttempt: proof.run_attempt,
        verified: proof.verified,
      },
    };

    if (!evidence.verified) {
      return {
        exitCode: 1,
        evidence: {
          ...evidence,
          reason: runConclusion !== "success"
              ? "workflow_not_successful"
              : jobsEvidence.missing.length > 0
                ? "required_job_missing"
                : jobsEvidence.failed.length > 0
                  ? "required_job_not_successful"
                  : "proof_reports_failed_job",
          missingJobs: jobsEvidence.missing,
          failedJobs: jobsEvidence.failed,
        },
      };
    }

    return { exitCode: 0, evidence };
  }

  return {
    exitCode: 124,
    evidence: {
      verified: false,
      reason: "timeout",
      workflow,
      sha,
      lastEvidence,
    },
  };
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function printEvidence(evidence, asJson) {
  if (asJson) {
    console.log(JSON.stringify(evidence, null, 2));
    return;
  }

  if (evidence.verified) {
    console.log(`CI verified for ${evidence.sha}: ${evidence.run.url}`);
    return;
  }

  console.error(`CI verification failed: ${evidence.reason}`);
  if (evidence.message) {
    console.error(evidence.message);
  }
}

async function main(argv = process.argv.slice(2), options = {}) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 2;
  }

  if (args.help || args._.length === 0) {
    console.log(usage());
    return 0;
  }

  const command = args._[0];
  if (command !== "assert-ci") {
    console.error(`Unknown command: ${command}`);
    console.error(usage());
    return 2;
  }

  const { exitCode, evidence } = await assertCi(args, options);
  printEvidence(evidence, args.json);
  return exitCode;
}

if (require.main === module) {
  main().then((exitCode) => {
    process.exitCode = exitCode;
  });
}

module.exports = {
  DEFAULT_REQUIRED_JOBS,
  assertCi,
  jobEvidence,
  main,
  parseArgs,
};
