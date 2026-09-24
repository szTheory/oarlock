const assert = require("node:assert/strict");
const { mkdtempSync, mkdirSync, writeFileSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join } = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");
const { buildProof, validateProof, REQUIRED_JOBS } = require("./ci_proof.cjs");

function fixture() {
  const dir = mkdtempSync(join(tmpdir(), "ci-proof-"));
  mkdirSync(join(dir, "demo"));
  writeFileSync(join(dir, "mix.lock"), "root lock\n");
  writeFileSync(join(dir, "demo", "mix.lock"), "demo lock\n");
  return dir;
}

function input(dir, overrides = {}) {
  const needs = Object.fromEntries(REQUIRED_JOBS.map((id) => [id, { result: "success" }]));
  return {
    cwd: dir,
    needs,
    event: {
      testedSha: "a".repeat(40),
      headSha: "b".repeat(40),
      checkedOutSha: "a".repeat(40),
      runId: "123456",
      runAttempt: "2",
      workflow: "CI",
      repository: "owner/repo",
      otp: "28.1",
      elixir: "1.19.5",
      node: "22.14.0",
      hex: "2.2.1",
      rebar: "3.25.1",
      runner: "ubuntu-24.04",
      ...overrides,
    },
  };
}

test("proof binds exact event, run, toolchain, lockfiles, and all required job results", () => {
  const dir = fixture();
  try {
    const proof = buildProof(input(dir));
    assert.equal(proof.verified, true);
    assert.equal(proof.tested_sha, "a".repeat(40));
    assert.equal(proof.event_head_sha, "b".repeat(40));
    assert.equal(proof.run_attempt, 2);
    assert.equal(proof.required_jobs.length, REQUIRED_JOBS.length);
    assert.equal(validateProof(proof).verified, true);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("failed, skipped, cancelled, or absent required jobs produce unverified proof", () => {
  for (const result of ["failure", "skipped", "cancelled", undefined]) {
    const dir = fixture();
    try {
      const data = input(dir);
      if (result === undefined) delete data.needs["planning-truth"];
      else data.needs["planning-truth"].result = result;
      const proof = buildProof(data);
      assert.equal(proof.verified, false, String(result));
      assert.equal(validateProof(proof).verified, false, String(result));
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  }
});

test("malformed identity, mismatched checkout, missing lock, or incomplete toolchain fails closed", () => {
  const dir = fixture();
  try {
    assert.throws(() => buildProof(input(dir, { testedSha: "bad" })), /SHA/);
    assert.throws(() => buildProof(input(dir, { checkedOutSha: "c".repeat(40) })), /Checked-out/);
    assert.throws(() => buildProof(input(dir, { node: "" })), /toolchain/);
    rmSync(join(dir, "demo", "mix.lock"));
    assert.throws(() => buildProof(input(dir)), /lockfile/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("proof validator rejects unknown keys and identity substitution", () => {
  const dir = fixture();
  try {
    const proof = buildProof(input(dir));
    assert.throws(() => validateProof({ ...proof, actor: "private" }), /schema/);
    assert.throws(() => validateProof({ ...proof, tested_sha: "c".repeat(40) }, { testedSha: "a".repeat(40) }), /identity/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("workflow CLI writes a valid proof before returning dependency failure", () => {
  const dir = fixture();
  try {
    const needs = Object.fromEntries(REQUIRED_JOBS.map((id) => [id, { result: "success" }]));
    needs["planning-truth"].result = "failure";
    const env = {
      ...process.env,
      NEEDS_JSON: JSON.stringify(needs),
      GITHUB_SHA_VALUE: "a".repeat(40),
      EVENT_HEAD_SHA_VALUE: "b".repeat(40),
      CHECKED_OUT_SHA_VALUE: "a".repeat(40),
      GITHUB_RUN_ID_VALUE: "123456",
      GITHUB_RUN_ATTEMPT_VALUE: "2",
      GITHUB_WORKFLOW_VALUE: "CI",
      GITHUB_REPOSITORY_VALUE: "owner/repo",
      OTP_VERSION: "28.1",
      ELIXIR_VERSION: "1.19.5",
      HEX_VERSION: "2.2.1",
      REBAR_VERSION: "3.25.1",
      RUNNER_OS: "Linux",
      RUNNER_ARCH: "X64",
      GITHUB_WORKSPACE: dir,
    };
    const result = spawnSync(process.execPath, [join(__dirname, "ci_proof.cjs")], { cwd: dir, env, encoding: "utf8" });
    assert.equal(result.status, 1);
    const proof = JSON.parse(require("node:fs").readFileSync(join(dir, "ci-contract-proof.json"), "utf8"));
    assert.equal(validateProof(proof).verified, false);
    assert.equal(JSON.parse(result.stdout).required_jobs.find((job) => job.id === "planning-truth").result, "failure");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
