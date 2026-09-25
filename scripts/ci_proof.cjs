#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const REQUIRED_JOBS = ["test", "dialyzer", "demo-postgres", "package-smoke", "optional-deps", "planning-truth", "quality"];
const JOB_RESULTS = ["success", "failure", "cancelled", "skipped", "missing"];
const SHA = /^[a-f0-9]{40}$/i;

function fail(message) {
  throw new Error(message);
}

function requiredString(value, label) {
  if (typeof value !== "string" || value.trim() === "" || value.length > 160 || /[\r\n\0]/.test(value)) {
    fail(`Invalid or missing ${label}`);
  }
  return value.trim();
}

function digest(file) {
  let data;
  try {
    data = fs.readFileSync(file);
  } catch {
    fail(`Required lockfile is missing or unreadable: ${path.basename(file)}`);
  }
  if (!data.length || data.length > 5 * 1024 * 1024) fail(`Invalid lockfile size: ${path.basename(file)}`);
  return crypto.createHash("sha256").update(data).digest("hex");
}

function buildProof({ needs, event, cwd = process.cwd() }) {
  if (!needs || typeof needs !== "object" || Array.isArray(needs)) fail("Invalid needs JSON");
  const testedSha = requiredString(event.testedSha, "tested SHA");
  const headSha = requiredString(event.headSha, "event head SHA");
  const checkedOutSha = requiredString(event.checkedOutSha, "checked-out SHA");
  if (!SHA.test(testedSha) || !SHA.test(headSha) || !SHA.test(checkedOutSha) || [testedSha, headSha, checkedOutSha].some((sha) => /^0+$/.test(sha))) {
    fail("Malformed event or checkout SHA");
  }
  if (testedSha.toLowerCase() !== checkedOutSha.toLowerCase()) fail("Checked-out HEAD does not match tested event SHA");
  const runIdText = requiredString(String(event.runId ?? ""), "run ID");
  const attemptText = requiredString(String(event.runAttempt ?? ""), "run attempt");
  if (!/^\d{1,20}$/.test(runIdText) || !/^\d{1,6}$/.test(attemptText) || Number(runIdText) <= 0 || Number(attemptText) <= 0) fail("Malformed run identity");
  const repository = requiredString(event.repository, "repository");
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) fail("Malformed repository identity");
  const workflow = requiredString(event.workflow, "workflow name");
  const toolchain = {
    otp: requiredString(event.otp, "toolchain version"),
    elixir: requiredString(event.elixir, "toolchain version"),
    node: requiredString(event.node, "toolchain version"),
    hex: requiredString(event.hex, "toolchain version"),
    rebar: requiredString(event.rebar, "toolchain version"),
    runner: requiredString(event.runner, "runner identity"),
  };
  const required_jobs = REQUIRED_JOBS.map((id) => {
    const value = needs[id];
    const result = value && JOB_RESULTS.includes(value.result) ? value.result : value ? "missing" : "missing";
    return { id, result };
  });
  const verified = required_jobs.every((job) => job.result === "success");
  return {
    schema_version: 1,
    tested_sha: testedSha.toLowerCase(),
    event_head_sha: headSha.toLowerCase(),
    run_id: Number(runIdText),
    run_attempt: Number(attemptText),
    workflow,
    repository,
    run_url: `https://github.com/${repository}/actions/runs/${Number(runIdText)}/attempts/${Number(attemptText)}`,
    toolchain,
    lockfiles: {
      root_mix_lock_sha256: digest(path.join(cwd, "mix.lock")),
      demo_mix_lock_sha256: digest(path.join(cwd, "demo", "mix.lock")),
    },
    required_jobs,
    verified,
  };
}

function validateProof(proof, expected = {}) {
  const keys = ["schema_version", "tested_sha", "event_head_sha", "run_id", "run_attempt", "workflow", "repository", "run_url", "toolchain", "lockfiles", "required_jobs", "verified"];
  if (!proof || typeof proof !== "object" || Array.isArray(proof) || Object.keys(proof).sort().join(",") !== [...keys].sort().join(",")) fail("Invalid proof schema: unexpected or missing fields");
  if (proof.schema_version !== 1 || !SHA.test(proof.tested_sha) || !SHA.test(proof.event_head_sha)) fail("Invalid proof schema identity");
  if (!Number.isSafeInteger(proof.run_id) || proof.run_id <= 0 || !Number.isSafeInteger(proof.run_attempt) || proof.run_attempt <= 0) fail("Invalid proof schema run identity");
  if (typeof proof.repository !== "string" || typeof proof.workflow !== "string" || proof.run_url !== `https://github.com/${proof.repository}/actions/runs/${proof.run_id}/attempts/${proof.run_attempt}`) fail("Invalid proof schema URL");
  const toolKeys = ["otp", "elixir", "node", "hex", "rebar", "runner"];
  if (!proof.toolchain || Object.keys(proof.toolchain).sort().join(",") !== toolKeys.sort().join(",") || toolKeys.some((key) => typeof proof.toolchain[key] !== "string" || !proof.toolchain[key])) fail("Invalid proof schema toolchain");
  const lockKeys = ["root_mix_lock_sha256", "demo_mix_lock_sha256"];
  if (!proof.lockfiles || Object.keys(proof.lockfiles).sort().join(",") !== lockKeys.sort().join(",") || lockKeys.some((key) => !/^[a-f0-9]{64}$/.test(proof.lockfiles[key]))) fail("Invalid proof schema lockfile digest");
  if (!Array.isArray(proof.required_jobs) || proof.required_jobs.length !== REQUIRED_JOBS.length) fail("Invalid proof schema required jobs");
  for (let index = 0; index < REQUIRED_JOBS.length; index += 1) {
    const job = proof.required_jobs[index];
    if (!job || Object.keys(job).sort().join(",") !== "id,result" || job.id !== REQUIRED_JOBS[index] || !JOB_RESULTS.includes(job.result)) fail("Invalid proof schema job result");
  }
  const allPassed = proof.required_jobs.every((job) => job.result === "success");
  if (proof.verified !== allPassed) fail("Proof verified flag contradicts required job results");
  if (expected.testedSha && proof.tested_sha !== expected.testedSha.toLowerCase()) fail("Proof identity does not match hosted run");
  if (expected.headSha && proof.event_head_sha !== expected.headSha.toLowerCase()) fail("Proof event identity does not match hosted run");
  if (expected.runId && proof.run_id !== Number(expected.runId)) fail("Proof run identity does not match hosted run");
  if (expected.runAttempt && proof.run_attempt !== Number(expected.runAttempt)) fail("Proof attempt identity does not match hosted run");
  return proof;
}

function cliEvent(env = process.env) {
  return {
    testedSha: env.GITHUB_SHA_VALUE,
    headSha: env.EVENT_HEAD_SHA_VALUE,
    checkedOutSha: env.CHECKED_OUT_SHA_VALUE,
    runId: env.GITHUB_RUN_ID_VALUE,
    runAttempt: env.GITHUB_RUN_ATTEMPT_VALUE,
    workflow: env.GITHUB_WORKFLOW_VALUE,
    repository: env.GITHUB_REPOSITORY_VALUE,
    otp: env.OTP_VERSION,
    elixir: env.ELIXIR_VERSION,
    node: process.versions.node,
    hex: env.HEX_VERSION,
    rebar: env.REBAR_VERSION,
    runner: env.RUNNER_OS && env.RUNNER_ARCH ? `${env.RUNNER_OS}/${env.RUNNER_ARCH}` : env.RUNNER_IMAGE,
  };
}

function main(env = process.env) {
  let needs;
  try {
    needs = JSON.parse(env.NEEDS_JSON || "");
  } catch {
    fail("Invalid NEEDS_JSON");
  }
  const proof = buildProof({ needs, event: cliEvent(env), cwd: env.GITHUB_WORKSPACE || process.cwd() });
  const output = env.PROOF_OUTPUT || "ci-contract-proof.json";
  fs.writeFileSync(output, `${JSON.stringify(proof, null, 2)}\n`, { mode: 0o600 });
  process.stdout.write(`${JSON.stringify(proof, null, 2)}\n`);
  if (!proof.verified) process.exitCode = 1;
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(`CI proof unavailable: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { JOB_RESULTS, REQUIRED_JOBS, buildProof, validateProof };
