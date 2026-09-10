"use strict";

const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");

const PROJECT_ROOT = path.resolve(__dirname, "../..");
const DEFAULT_SUBJECT = "scripts/lib/repository_truth.cjs";

function resolveSubject() {
  const requested = process.env.GSD_PROHIB_SUBJECT || DEFAULT_SUBJECT;
  return require(path.isAbsolute(requested) ? requested : path.resolve(PROJECT_ROOT, requested));
}

function snapshot(overrides = {}) {
  return {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git", pruneDryRun: [] },
    worktrees: [{
      path: "/fixture", role: "main", head: "a".repeat(40), branch: "main",
      upstream: null, ahead: null, behind: null, detached: false, bare: false,
      lock: null, prunable: null, processEvidence: null,
      dirty: [{ kind: "ordinary", path: "owned.txt", originalPath: null, index: ".", worktree: "M" }],
      collectionErrors: [],
      ...overrides,
    }],
    collectionErrors: [],
  };
}

function claim(overrides = {}) {
  return {
    selector: { kind: "dirty_path", worktree_role: "main", path: "owned.txt" },
    owner: "fixture-owner",
    provenance: "reviewed fixture evidence",
    confidence: "high",
    revisit_at: "2099-01-01",
    proposed_disposition: "preserve",
    ...overrides,
  };
}

function assertRendered(subject, result, expectedStatus, expectedCode) {
  const human = subject.renderHuman(result);
  const json = JSON.parse(subject.renderJson(result));
  assert.equal(subject.exitCodeFor(result), expectedStatus);
  assert.equal(json.conclusion.exitCode, expectedStatus);
  assert.equal(json.conclusion.status, expectedCode);
  assert.match(human, new RegExp(`Conclusion: ${expectedCode}`));
  return { human, json };
}

test("PROHIB-REPO-01-TRANSPARENCY: ownership and incomplete evidence never become established facts", () => {
  const subject = resolveSubject();
  for (const name of ["evaluateRepositoryInventory", "renderHuman", "renderJson", "exitCodeFor"]) {
    assert.equal(typeof subject[name], "function", `subject must expose ${name}`);
  }

  const inferred = subject.evaluateRepositoryInventory(snapshot(), { schema_version: 1, claims: [] });
  assert.equal(inferred.dispositions[0].state, "unknown");
  assert.equal(inferred.dispositions[0].owner, "unknown");
  assertRendered(subject, inferred, 1, "policy-error");

  const unsupportedClaim = claim({ owner: { inferred: "from-path" } });
  const unsupported = subject.evaluateRepositoryInventory(snapshot(), { schema_version: 1, claims: [unsupportedClaim] });
  assert.equal(unsupported.dispositions[0].state, "unknown");
  assert.equal(unsupported.dispositions[0].owner, "unknown");
  assert.ok(unsupported.diagnostics.some(({ code }) => code === "RINV_CLAIM_INVALID"));
  assertRendered(subject, unsupported, 2, "incomplete");

  const stale = subject.evaluateRepositoryInventory(snapshot(), {
    schema_version: 1,
    claims: [claim({ revisit_at: "2026-01-01" })],
  });
  assert.equal(stale.dispositions[0].state, "stale");
  const staleViews = assertRendered(subject, stale, 1, "policy-error");
  assert.match(staleViews.human, /RINV_STALE_CLAIM/);
  assert.ok(staleViews.json.diagnostics.some(({ code }) => code === "RINV_STALE_CLAIM"));

  const partial = subject.evaluateRepositoryInventory(snapshot({ head: null }), { schema_version: 1, claims: [] });
  const partialViews = assertRendered(subject, partial, 2, "incomplete");
  assert.match(partialViews.human, /RINV_COLLECTION_INCOMPLETE/);
  assert.ok(partialViews.json.diagnostics.some(({ code, incomplete }) => code === "RINV_COLLECTION_INCOMPLETE" && incomplete === true));
  assert.equal(partialViews.json.conclusion.status === "healthy", false);
});
