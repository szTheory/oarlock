# Phase 34: Release Integrity - Pattern Map

**Mapped:** 2026-09-25  
**Files analyzed:** 9 planned/modified files  
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/release-please.yml` | config / workflow | event-driven, request-response | `.github/workflows/ci.yml` | role-match |
| `.github/workflows/hex-publish.yml` | config / workflow | request-response | `.github/workflows/release-please.yml` | exact |
| `scripts/release_integrity.cjs` | utility / release gate | request-response, transform | `scripts/ci_remote_gate.cjs` | role-match |
| `scripts/release_evidence.cjs` | utility / evidence serializer | transform, file-I/O | `scripts/ci_proof.cjs` | role-match |
| `scripts/release_integrity.test.cjs` | test | transform | `scripts/ci_remote_gate.test.cjs` | exact |
| `scripts/release_workflow_contract.test.cjs` | test | file-I/O, transform | `scripts/ci_workflow_contract.test.cjs` | exact |
| `scripts/release_evidence.test.cjs` | test | transform, file-I/O | `scripts/ci_proof.test.cjs` | role-match |
| `bin/package_smoke.sh` (extend) | utility / consumer smoke | file-I/O, request-response | `bin/package_smoke.sh` | exact |
| `.planning/EVIDENCE.md` (append acceptance evidence/policy) | documentation / evidence ledger | append-only record | `.planning/EVIDENCE.md` | exact |

The first seven file candidates derive from the recommended shared gate, manifest, and explicit test map in `34-RESEARCH.md` (especially lines 64-79, 138, 341-356). Existing workflows, package smoke, and evidence ledger are explicitly identified in `34-CONTEXT.md` lines 76-114. The context names implementation boundaries rather than requiring every discretionary helper above; the planner should keep helper count aligned with the concrete design.

## Pattern Assignments

### `.github/workflows/release-please.yml` and `.github/workflows/hex-publish.yml` (workflow config)

**Analogs:** `.github/workflows/ci.yml` for bounded permissions, pinned actions, explicit job dependencies; the two existing release workflows for their event-specific Release Please and dispatch wiring. All three paths were verified as git-tracked with `git ls-files`.

**Existing automatic release identity and job boundary** (`.github/workflows/release-please.yml`, lines 28-61):

```yaml
jobs:
  release-please:
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd
        with:
          fetch-depth: 0
```

The publish job currently checks out the produced tag and has `contents: read` (lines 51-61). Preserve the tag/version outputs as inputs to shared validation, but do not treat outputs alone as proof of peeled SHA or package identity.

**Existing recovery entry** (`.github/workflows/hex-publish.yml`, lines 9-32):

```yaml
on:
  workflow_dispatch:
    inputs:
      tag:
        description: 'Git tag or commit SHA to publish from (e.g. v0.1.0).'
        required: true
        type: string
      release_version:
        description: 'Expected @version string in mix.exs at that ref (e.g. 0.1.0).'
        required: true
        type: string

permissions:
  contents: write
```

Change this to the locked single existing `vX.Y.Z` tag input, derive the version, and scope write permission to the separate evidence-attachment job. The current workflow mixes checkout, tests, dry-run, and secret-bearing publication in one job (lines 24-73); use explicit job boundaries so preflight and post-publish verification have no Hex secret.

**Pinned action and permission convention** (`.github/workflows/ci.yml`, lines 8-17; workflow assertions in `scripts/ci_workflow_contract.test.cjs`, lines 107-129):

```yaml
permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-24.04
    timeout-minutes: 30
```

Use full commit SHAs for actions and minimum permissions per job, matching the current CI contract. Both external publication jobs need the same `hex-publish` concurrency group with no cancellation and `queue: max`; revalidate candidate and registry state inside the serialized job after it acquires the group.

### `scripts/release_integrity.cjs` (utility, request-response/transform)

**Analog:** `scripts/ci_remote_gate.cjs` (tracked; verified with `git ls-files`). It is the closest release gate: CLI parsing, injected observations, fail-closed identity checks, and structured JSON result.

**Imports and external observation boundary** (`scripts/ci_remote_gate.cjs`, lines 1-5, 10-23):

```javascript
const { spawnSync } = require("node:child_process");
const { assertCi, DEFAULT_REQUIRED_JOBS } = require("./ci_monitor.cjs");
const { observe: observeTiming } = require("./ci_timing.cjs");

function ghJson(endpoint, options = {}) {
  const result = spawnSync(options.ghBin || process.env.CI_REMOTE_GATE_GH_BIN || "gh", ["api", endpoint], {
    encoding: "utf8",
    env: options.env || process.env,
    timeout: options.timeoutMs || 15_000,
    maxBuffer: 2 * 1024 * 1024,
  });
  if (result.error) throw new Error(`GitHub observation unavailable: ${result.error.message}`);
  if (result.status !== 0) throw new Error(`GitHub observation unavailable: ${result.stderr || result.stdout || "gh api failed"}`);
```

**Core gate and structured result** (`scripts/ci_remote_gate.cjs`, lines 26-73):

```javascript
function evaluateCandidate({ sha, ci, timing }) {
  const requestedSha = typeof sha === "string" ? sha.toLowerCase() : "";
  if (!SHA.test(requestedSha)) return { observed: false, verified: false, reason: "invalid_sha" };
  if (!ci || !ci.evidence) return { observed: false, verified: false, reason: "ci_unobserved" };
  const evidence = ci.evidence;
  if (evidence.sha?.toLowerCase() !== requestedSha || evidence.run?.headSha?.toLowerCase() !== requestedSha) {
    return { observed: true, verified: false, reason: "run_sha_mismatch" };
  }
  // Further checks bind workflow, proof run/attempt, required lanes, timing and artifact.
```

Follow this fail-closed shape for tag syntax/peeled SHA/package name/version, exact proof, build checksum and Hex state. Return machine-readable `observed`, `verified`, reason, expected and observed identities, plus run/tag links; keep external `gh`/Hex calls injectable for deterministic tests. Reuse the existing proof interface rather than duplicating CI evaluation.

### `scripts/release_evidence.cjs` and `scripts/release_evidence.test.cjs` (serializer and tests)

**Analogs:** `scripts/ci_proof.cjs` and `scripts/ci_proof.test.cjs` (tracked). The proof module provides strict versioned JSON construction/validation; tests use temporary fixtures and cleanup.

**Imports and validation helpers** (`scripts/ci_proof.cjs`, lines 1-20):

```javascript
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function fail(message) {
  throw new Error(message);
}

function requiredString(value, label) {
  if (typeof value !== "string" || value.trim() === "" || value.length > 160 || /[\r\n\0]/.test(value)) {
    fail(`Invalid or missing ${label}`);
  }
  return value.trim();
}
```

**Versioned strict record validation** (`scripts/ci_proof.cjs`, lines 82-103):

```javascript
function validateProof(proof, expected = {}) {
  const keys = ["schema_version", "tested_sha", "event_head_sha", "run_id", "run_attempt", "workflow", "repository", "run_url", "toolchain", "lockfiles", "required_jobs", "verified"];
  if (!proof || typeof proof !== "object" || Array.isArray(proof) || Object.keys(proof).sort().join(",") !== [...keys].sort().join(",")) fail("Invalid proof schema: unexpected or missing fields");
  if (proof.schema_version !== 1 || !SHA.test(proof.tested_sha) || !SHA.test(proof.event_head_sha)) fail("Invalid proof schema identity");
  // Validate every identity and ensure status agrees with component results.
```

Apply exact required-field validation and reject secrets, payloads, or contradictory identity/status. Preserve a schema version and write a compact JSON record only after successful package and consumer verification. Test required fields, excluded sensitive fields, attachment ordering and round-trip serialization.

**Test structure / fixture cleanup** (`scripts/ci_proof.test.cjs`, lines 1-39, 41-54):

```javascript
const assert = require("node:assert/strict");
const { mkdtempSync, mkdirSync, writeFileSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join } = require("node:path");
const test = require("node:test");

function fixture() {
  const dir = mkdtempSync(join(tmpdir(), "ci-proof-"));
  return dir;
}

test("proof binds exact event, run, toolchain, lockfiles, and all required job results", () => {
  const dir = fixture();
  try {
    // Arrange fixture and assert a valid versioned record.
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
```

### `scripts/release_integrity.test.cjs` (tests, transform)

**Analog:** `scripts/ci_remote_gate.test.cjs` (tracked). It tests pure validation and rejection cases with fixture objects rather than requiring live GitHub access.

**Imports and exact-SHA assertion style** (`scripts/ci_remote_gate.test.cjs`, lines 1-28):

```javascript
const assert = require("node:assert/strict");
const test = require("node:test");
const { DEFAULT_REQUIRED_JOBS } = require("./ci_monitor.cjs");
const { evaluateCandidate, matchProofArtifact } = require("./ci_remote_gate.cjs");

test("accepts only an exact-SHA successful contract, artifact identity, and timing run", () => {
  const result = evaluateCandidate({ sha: SHA, ci, timing });
  assert.equal(result.verified, true);
  assert.deepEqual(result.artifact, { name: "ci-proof-42-2", runId: 42, attempt: 2 });
});
```

Cover valid tag-to-SHA/version identity, malformed/nonexistent tag, package/version mismatch, missing or stale exact-SHA proof, checksum disagreement, Hex absent/matching/conflicting outcomes, and safe retry/idempotent success. Keep remote observations as injected values.

### `scripts/release_workflow_contract.test.cjs` (test, file-I/O/transform)

**Analog:** `scripts/ci_workflow_contract.test.cjs` (tracked). It reads workflow text and asserts structural contracts without invoking a hosted run.

**Workflow text and bounded block helpers** (`scripts/ci_workflow_contract.test.cjs`, lines 1-27):

```javascript
const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");
const test = require("node:test");

const root = join(__dirname, "..");
const workflow = readFileSync(join(root, ".github", "workflows", "ci.yml"), "utf8");

function jobBlock(id) {
  const start = workflow.indexOf(`  ${id}:\n`);
  assert.notEqual(start, -1, `workflow job ${id} is required`);
```

Assert both release routes invoke the shared gate, share one concurrency group, do not cancel in-progress publication, expose the Hex key only in the final publish step/job environment, and put GitHub write access only on evidence attachment.

### `bin/package_smoke.sh` (consumer smoke, file-I/O)

**Analog:** itself (tracked). Keep this runnable shell script's strict mode, temporary consumer workspace, dependency-boundary check, and compile-with-warnings-as-errors sequence. Convert/add a mode that pins the published Hex version and fetches the registry package, then compiles a clean Mix consumer; do not infer package-byte agreement from an API version response alone.

**Existing safety and consumer construction** (`bin/package_smoke.sh`, lines 1-16, 67-78):

```bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${RUNNER_TEMP:-$(mktemp -d)}"
UNPACKED_DIR="${WORK_DIR%/}/oarlock-unpacked"
CONSUMER_DIR="${WORK_DIR%/}/oarlock-consumer-proof"
```

```bash
echo "==> Verifying fresh consumer dependency boundary"
if grep -Eq '\{:(plug|bandit),' "$CONSUMER_DIR/mix.exs"; then
  echo "Fresh consumer declared an optional fixture dependency"
  exit 1
fi

echo "==> Compiling fresh consumer with warnings as errors"
cd "$CONSUMER_DIR"
OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix deps.get
OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix compile --warnings-as-errors
```

For the release-specific mode, set the exact Hex dependency version and use a clean temp project. Avoid relying on local path dependencies for the post-publish proof.

### `.planning/EVIDENCE.md` (append-only evidence documentation)

**Analog:** `.planning/EVIDENCE.md` itself (tracked); use the existing ledger conventions at lines 5-23 and identity rules at lines 41-46. Keep source SHA, tag, declared version, and publication status as distinct facts. Record the Phase 34 acceptance class and evidence authority/schema, not a second copy of each release manifest's logs or package bytes.

## Shared Patterns

### Exact source proof

**Source:** `scripts/ci_remote_gate.cjs`, lines 26-72 and 84-103; `scripts/ci_monitor.cjs` supplies the stable required-job contract.  
**Apply to:** Both automatic and recovery release flows. Query exact peeled SHA, require exact run/attempt and retained artifact identity, and stop before any publish environment can expose the Hex key when any check is unavailable or mismatched.

### Minimal and staged credentials

**Source:** `.github/workflows/ci.yml`, lines 8-17; current credential-bearing anti-pattern shown by `.github/workflows/hex-publish.yml`, lines 65-73.  
**Apply to:** Release workflow jobs. Keep preflight, proof retrieval, package inspection, and post-publish verification secret-free. Scope environment secret mapping to the publish step. Use a distinct least-privileged GitHub-write job for the release asset.

### Explicit evidence identities

**Source:** `scripts/ci_proof.cjs`, lines 34-79, and `.planning/EVIDENCE.md`, lines 41-46.  
**Apply to:** Release gate and release-evidence manifest. Keep tag, peeled SHA, package name/version, CI run/attempt/artifact digest, candidate checksum, registry checksum, served tarball verification, and consumer result as separate named fields.

## No Analog Found

No existing helper handles Hex release checksum reconciliation, ambiguous upload idempotency, or GitHub Release asset attachment. Use the standard Mix/Hex CLI and registry observations from research; use `ci_proof.cjs` only as the versioned-record pattern, not as a release implementation analog.

## Metadata

**Analog search scope:** `.github/workflows/`, `scripts/`, `bin/`, `.planning/`  
**Files scanned:** 11 tracked source/workflow/test analogs  
**Tracked-source check:** Every named code analog was checked with `git ls-files`; no ignored `.gsd` or plugin mirror paths are referenced.  
**Pattern extraction date:** 2026-09-25
