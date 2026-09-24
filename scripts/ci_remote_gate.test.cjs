const assert = require("node:assert/strict");
const test = require("node:test");
const { DEFAULT_REQUIRED_JOBS } = require("./ci_monitor.cjs");
const { evaluateCandidate, matchProofArtifact, requiredCheckStatus } = require("./ci_remote_gate.cjs");

const SHA = "a".repeat(40);
const run = { id: 42, attempt: 2, headSha: SHA, url: "https://github.test/run/42", status: "completed", conclusion: "success" };
const jobs = DEFAULT_REQUIRED_JOBS.map((name) => ({ name, found: true, status: "completed", conclusion: "success" }));
const ci = {
  exitCode: 0,
  evidence: {
    verified: true,
    sha: SHA,
    workflow: "CI",
    run,
    jobs,
    proof: { verified: true, testedSha: SHA, runId: 42, runAttempt: 2 },
  },
};
const timing = { observed: true, sha: SHA, run: { id: 42, attempt: 2 }, criticalPathMs: 1200 };

test("accepts only an exact-SHA successful contract, artifact identity, and timing run", () => {
  const result = evaluateCandidate({ sha: SHA, ci, timing });
  assert.equal(result.verified, true);
  assert.deepEqual(result.artifact, { name: "ci-proof-42-2", runId: 42, attempt: 2 });
  assert.equal(result.jobs.length, DEFAULT_REQUIRED_JOBS.length);
});

test("classifies unavailable hosted data as unobserved", () => {
  assert.deepEqual(evaluateCandidate({ sha: SHA, ci: { exitCode: 2, evidence: { reason: "no_ci_run_for_sha" } } }), {
    observed: false, verified: false, reason: "no_ci_run_for_sha", message: undefined,
  });
  assert.equal(evaluateCandidate({ sha: SHA, ci, timing: { observed: false } }).reason, "timing_unobserved_or_mismatched");
  assert.equal(evaluateCandidate({ sha: SHA, ci: { exitCode: 2, evidence: { reason: "proof_unobserved_or_invalid", run: { headSha: SHA } } } }).reason, "proof_missing_or_invalid");
});

test("rejects mismatched SHA, run/attempt proof, missing artifact proof, and non-success lanes", () => {
  assert.equal(evaluateCandidate({ sha: "b".repeat(40), ci, timing }).reason, "run_sha_mismatch");
  assert.equal(evaluateCandidate({ sha: SHA, ci: { ...ci, evidence: { ...ci.evidence, proof: { ...ci.evidence.proof, runAttempt: 1 } } }, timing }).reason, "proof_identity_or_lanes_invalid");
  assert.equal(evaluateCandidate({ sha: SHA, ci: { ...ci, evidence: { ...ci.evidence, jobs: [{ ...jobs[0], conclusion: "skipped" }, ...jobs.slice(1)] } }, timing }).reason, "required_lane_invalid");
});

test("detects the stable aggregate as an effective required status check", () => {
  assert.deepEqual(requiredCheckStatus([{ type: "required_status_checks", parameters: { required_status_checks: [{ context: "CI contract" }] } }]), {
    observed: true, required: true, reason: null,
  });
  assert.equal(requiredCheckStatus([]).required, false);
  assert.equal(requiredCheckStatus(null).observed, false);
});

test("matches only a retained, SHA-bound artifact with a digest for the exact run attempt", () => {
  const artifact = {
    id: 7,
    name: "ci-proof-42-2",
    digest: `sha256:${"b".repeat(64)}`,
    expired: false,
    workflow_run: { id: 42, head_sha: SHA },
  };
  assert.deepEqual(matchProofArtifact(run, { artifacts: [artifact] }), {
    observed: true,
    verified: true,
    name: artifact.name,
    id: 7,
    digest: artifact.digest,
    runId: 42,
    headSha: SHA,
  });
  assert.equal(matchProofArtifact(run, { artifacts: [] }).reason, "proof_artifact_missing");
  assert.equal(matchProofArtifact(run, { artifacts: [{ ...artifact, workflow_run: { id: 9, head_sha: SHA } }] }).reason, "proof_artifact_identity_invalid");
  assert.equal(matchProofArtifact(run, null).observed, false);
});
