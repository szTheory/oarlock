const assert = require("node:assert/strict");
const test = require("node:test");
const { buildEvidence, mergeAcceptedEvidence } = require("./release_evidence.cjs");

function packet(overrides = {}) {
  return {
    schema_version: 1,
    repository: "szTheory/oarlock",
    tag: "v1.2.3",
    sha: "a".repeat(40),
    version: "1.2.3",
    candidate: {
      verified: true,
      sha: "a".repeat(40),
      run: { id: 123, attempt: 2, url: "https://github.com/szTheory/oarlock/actions/runs/123" },
      artifact: { id: 456, name: "ci-proof-123-2", digest: `sha256:${"b".repeat(64)}`, runId: 123, headSha: "a".repeat(40) },
    },
    checksum: "c".repeat(64),
    packageName: "oarlock",
    packageVersion: "1.2.3",
    published: {
      version: "1.2.3", packageName: "oarlock", checksum: "c".repeat(64),
      fetchedChecksum: "c".repeat(64), url: "https://hex.pm/packages/oarlock/1.2.3",
    },
    consumer_compile: "passed",
    dryRunOutput: "secret raw output",
    buildOutput: "raw output",
    ...overrides,
  };
}

const env = {
  RELEASE_WORKFLOW_RUN: "https://github.com/szTheory/oarlock/actions/runs/789",
  RELEASE_RUN_ID: "789",
  RELEASE_RUN_ATTEMPT: "3",
};

test("serializes strict allowlisted versioned release evidence", () => {
  const record = buildEvidence(packet(), env, () => "2026-09-25T12:00:00.000Z");
  assert.equal(record.schema_version, 1);
  assert.equal(record.peeled_sha, "a".repeat(40));
  assert.equal(record.ci_run_attempt, 2);
  assert.equal(record.ci_artifact_id, 456);
  assert.equal(record.release_workflow_attempt, 3);
  assert.equal(record.dry_run, "passed");
  assert.equal(record.downstream_compile, "passed");
  assert.equal(record.created_at, "2026-09-25T12:00:00.000Z");
  assert.equal("buildOutput" in record, false);
  assert.equal("dryRunOutput" in record, false);
});

test("rejects missing, malformed, mismatched, or unverified release proof", () => {
  for (const input of [
    packet({ consumer_compile: "failed" }),
    packet({ published: null }),
    packet({ candidate: { verified: false } }),
    packet({ sha: "bad" }),
    packet({ tag: "v9.9.9" }),
    packet({ published: { ...packet().published, fetchedChecksum: "d".repeat(64) } }),
    packet({ candidate: { ...packet().candidate, artifact: { id: 0, digest: "no" } } }),
  ]) assert.throws(() => buildEvidence(input, env), /Release evidence/);
  assert.throws(() => buildEvidence(packet(), {}), /Release evidence/);
});

test("retains compatible prior accepted attempts and rejects contradictory identity or checksums", () => {
  const current = buildEvidence(packet(), env);
  const prior = { ...current, ci_run_id: 99, ci_run_attempt: 1, ci_run_url: "https://github.com/szTheory/oarlock/actions/runs/99",
    release_workflow_run_id: 700, release_workflow_attempt: 1,
    accepted_attempts: [{ ...current.accepted_attempts[0], ci_run_id: 99, ci_run_attempt: 1,
      ci_run_url: "https://github.com/szTheory/oarlock/actions/runs/99", release_workflow_run_id: 700,
      release_workflow_attempt: 1 }] };
  const merged = mergeAcceptedEvidence(current, prior);
  assert.deepEqual(merged.accepted_attempts.map(({ ci_run_id }) => ci_run_id), [99, 123]);
  assert.throws(() => mergeAcceptedEvidence(current, { ...prior, peeled_sha: "d".repeat(40) }), /contradictory/);
  assert.throws(() => mergeAcceptedEvidence(current, { ...prior, hex_checksum: "d".repeat(64) }), /contradictory/);
});

test("rejects unrecognized asset fields instead of copying them forward", () => {
  assert.throws(() => mergeAcceptedEvidence(buildEvidence(packet(), env), { ...buildEvidence(packet(), env), credential: "private" }), /schema/);
});
