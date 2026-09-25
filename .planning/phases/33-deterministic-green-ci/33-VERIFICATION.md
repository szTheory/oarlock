---
phase: 33-deterministic-green-ci
verified: 2026-09-25T02:11:22Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
  - .planning/phases/34-release-integrity/34-NEXT.md
  - .planning/phases/33-deterministic-green-ci/33-01-PLAN.md
  - .planning/phases/33-deterministic-green-ci/33-01-SUMMARY.md
  - .planning/phases/33-deterministic-green-ci/33-02-PLAN.md
  - .planning/phases/33-deterministic-green-ci/33-02-SUMMARY.md
  - .planning/phases/33-deterministic-green-ci/33-03-PLAN.md
  - .planning/phases/33-deterministic-green-ci/33-03-SUMMARY.md
  - .planning/phases/33-deterministic-green-ci/33-04-PLAN.md
  - .planning/phases/33-deterministic-green-ci/33-04-SUMMARY.md
  - .planning/phases/33-deterministic-green-ci/33-CI-BASELINE.md
  - .planning/phases/33-deterministic-green-ci/33-CI-HOSTED.md
  - .planning/phases/33-deterministic-green-ci/33-VALIDATION.md
  - lib/paddle/error.ex
  - mix.exs
  - mix.lock
  - scripts/ci_monitor.cjs
  - scripts/ci_monitor.test.cjs
  - scripts/ci_proof.cjs
  - scripts/ci_proof.test.cjs
  - scripts/ci_remote_gate.cjs
  - scripts/ci_remote_gate.test.cjs
  - scripts/ci_timing.cjs
  - scripts/ci_timing.test.cjs
  - scripts/ci_workflow_contract.test.cjs
  - test/paddle/error_test.exs
  - test/paddle/inspection_safety_test.exs
covered_digest: "v1:sha256:5f5fe3c7fa921b87825b326882b38284de8ebc1aaaaccfdcbdb837eb99420586"
behavior_unverified: 0
overrides_applied: 0
decision_coverage: { honored: 0, total: 0, not_honored: [] }
---

# Phase 33: Deterministic Green CI Verification Report

**Phase Goal:** Contributors and maintainers can rely on a complete, fast, reproducible CI contract that proves one exact commit and keeps remote main green.
**Verified:** 2026-09-25T02:11:22Z
**Status:** passed
**Re-verification:** No. The prior report had no `gaps:` section, so this was an initial-mode verification. All truths were re-established against the finalized closeout branch and live GitHub.

## Goal Achievement

| # | Observable truth | Status | Evidence |
|---|---|---|---|
| 1 | Every proposed change runs the complete named proof matrix under one required aggregate. | ✓ VERIFIED | `.github/workflows/ci.yml` wires the seven lanes into `ci-contract`; the targeted workflow-contract test passed and the hosted candidate and main runs each report all eight jobs successful, including the aggregate. |
| 2 | Maintainers can inspect immutable inputs, controlled runners/toolchains, runtime-aware caches, timeouts, and least-privilege permissions. | ✓ VERIFIED | The workflow uses full-SHA action pins, versioned runner and service image, scoped permissions, explicit job timeouts, and toolchain/lock-aware cache keys. The targeted CI policy test and `actionlint .github/workflows/ci.yml` passed. |
| 3 | Exact-run timing and a baseline-derived target remain visible without dropping proof lanes. | ✓ VERIFIED | `33-CI-BASELINE.md` records sample count, cache context, per-run timing, and the provisional <120s/<6-runner-minute target. The final candidate and main observations remain complete eight-job proofs; neither target is claimed met. |
| 4 | The stable aggregate is required by remote `main`. | ✓ VERIFIED | Live effective-rule API read: active ruleset 23970515 targets `refs/heads/main` and requires `CI contract` from integration 15368; no bypass actors and strict freshness disabled. The remote gate also returned `required: true`. |
| 5 | Authoritative proof binds exact tested/event SHAs, run and attempt, toolchains, lockfiles, and every required lane. | ✓ VERIFIED | `scripts/ci_proof.cjs` constructs and validates an allowlisted proof schema; the named proof-binding test passed. Live run artifacts validate against their hosted run identities. |
| 6 | A failed or incomplete required lane leaves an unverified proof and fails the aggregate. | ✓ VERIFIED | Workflow proof/upload runs with `always()`; proof validity requires every lane. `scripts/ci_proof.test.cjs` covers missing/failed/skipped/cancelled lanes and writes proof before failure; workflow contract test ties proof to the aggregate. |
| 7 | Hosted acceptance rejects mismatched workflow, SHA, run/attempt, artifact, duplicate/missing lane, or unsuccessful job; transport failures remain unobserved. | ✓ VERIFIED | `ci_remote_gate.cjs` composes hosted monitor, timing, artifact and rules checks. Targeted identity/drift and monitor tests passed; live outputs matched all requested identities. |
| 8 | Phase 31 planning-truth checks remain a required lane. | ✓ VERIFIED | The workflow contract test confirms all six planning-truth diagnostics are executable steps in the required aggregate dependency. The planning-truth job passed on both live eight-job runs. |
| 9 | A candidate has exact-SHA hosted success, matching retained proof, and measured timing. | ✓ VERIFIED | Live candidate gate: head `580c1c836232e712b31e49913c694af9e1ca123e`; tested merge SHA `74ca59097ae258329e06a2481b2e359cf952b24e`; run [36077014434, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36077014434); artifact 10839959367, digest `sha256:1e9bfde9f0062dd9753b22d16982cb51d6f660301f03bf9985106547ecf84561`; all eight jobs successful; critical path 213s / 8.68 runner minutes. |
| 10 | The exact current remote-main SHA has successful hosted proof and durable artifact. | ✓ VERIFIED | Live main gate independently re-read main head before acceptance: `0db804c18eaea751d19e662d020f770d53cefc57`; run [36077488230, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36077488230); artifact 10841045079, digest `sha256:8ad67fd8a3669401ea2a32552aecc23ea37b5c5ecaa03f85abe574107c81b752`; all eight jobs successful; gate returned `observed: true`, `verified: true`. |
| 11 | Post-change timing is compared honestly with baseline/target while preserving every lane. | ✓ VERIFIED | Candidate measured 213s / 8.68 runner minutes and main 206s / 8.87; both complete proof artifacts are retained. The baseline explicitly keeps the provisional target unmet and makes no speed-improvement claim. |

**Score:** 11/11 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml` | Complete required contract, pinned inputs and aggregate proof upload | ✓ VERIFIED | Substantive workflow; each lane is an aggregate dependency; targeted policy test, actionlint, and hosted execution agree. |
| `scripts/ci_proof.cjs` / `scripts/ci_monitor.cjs` | Fail-closed proof creation and exact hosted-run validation | ✓ VERIFIED | Source implements identity/lane/artifact validation; targeted tests passed; live gates matched the remote evidence. |
| `scripts/ci_timing.cjs` | Exact-run durations and incomplete-data handling | ✓ VERIFIED | Timing calculation and missing-data behavior are exercised by tests; live exact-run timings were measured. |
| `scripts/ci_remote_gate.cjs` | Candidate/main exact-SHA acceptance and rules validation | ✓ VERIFIED | Candidate and main commands both returned `observed: true`, `verified: true` on this pass. |
| `33-CI-HOSTED.md` / `33-CI-BASELINE.md` | Hosted evidence, ruleset, baseline and target comparison | ✓ VERIFIED | Recorded identities and timings matched live re-queries; target is disclosed as unmet. |
| `lib/paddle/error.ex` and its regression tests | Redact provider-controlled Inspect fields while retaining stored values | ✓ VERIFIED | `mix test test/paddle/error_test.exs:158` passed the named regression test. This is a documented plan deviation, not needed to establish the CI goal. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | `scripts/ci_proof.cjs` | Aggregate writes attempt proof | ✓ WIRED | Workflow invokes the proof CLI before aggregate verdict and uploads its file on `always()`. |
| `scripts/ci_monitor.cjs` | `scripts/ci_proof.cjs` | Downloaded artifact schema/identity validation | ✓ WIRED | Monitor imports the proof validator and compares hosted run, attempt, SHA, and required job outcomes. |
| `.github/workflows/ci.yml` | `CI contract` | Required `needs` and stable display name | ✓ WIRED | Seven lanes feed the always-run aggregate; all eight job conclusions were successful on both hosted runs. |
| `scripts/ci_remote_gate.cjs` | `scripts/ci_monitor.cjs` and `scripts/ci_timing.cjs` | Exact run acceptance and timing | ✓ WIRED | Direct imports compose hosted identity/proof and timing validation; targeted drift test and live calls passed. |
| `scripts/ci_remote_gate.cjs` | effective `main` rule | GitHub rules API read | ✓ WIRED | Main command queries `rules/branches/main`; direct ruleset read confirmed ID 23970515 and exact required context/app. |
| `scripts/ci_timing.cjs` | `33-CI-BASELINE.md` | Observed run timestamps and durations | ✓ WIRED | Baseline rows carry exact run IDs/SHA and measured values; re-query produced matching candidate/main timings. |

The generic `verify.key-links` query returned false negatives for relative JavaScript imports and documentation/provenance links. Those links were manually traced in source and verified above; this is a literal-path heuristic limitation, not missing wiring.

## Data-Flow Trace (Level 4)

No rendered/database-backed data applies. Proof inputs flow from GitHub event/run metadata, setup toolchain output, lockfile bytes and `needs` job results into the allowlisted JSON. The monitor fetches run/job/artifact data, validates it against the requested identity, and the timing tool derives durations from hosted timestamps. The live artifact and timing observations provide non-static end-to-end evidence.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Main-head drift triggers a fresh exact-SHA observation | `node --test --test-name-pattern='repeats exact-SHA observation when main advances' scripts/ci_remote_gate.test.cjs` | 1 test passed | ✓ PASS |
| CI-01 checks are executable required workflow steps | `node --test --test-name-pattern='every CI-01 proof has an executable step' scripts/ci_workflow_contract.test.cjs` | 1 test passed | ✓ PASS |
| Proof binds event/run/toolchain/lock/lane identities | `node --test --test-name-pattern='proof binds exact event, run, toolchain, lockfiles, and all required job results' scripts/ci_proof.test.cjs` | 1 test passed | ✓ PASS |
| Hosted monitor accepts exact SHA and successful required jobs | `node --test --test-name-pattern='assert-ci exits 0 with exact SHA and all required jobs successful' scripts/ci_monitor.test.cjs` | 1 test passed | ✓ PASS |
| Timing summarizes exact expected durations | `node --test --test-name-pattern='fixed job timestamps produce queue, per-job, aggregate, critical path, and runner-minute totals' scripts/ci_timing.test.cjs` | 1 test passed | ✓ PASS |
| Provider fields are redacted in Inspect without mutating stored values | `mix test test/paddle/error_test.exs:158` | 1 test passed | ✓ PASS |
| GitHub candidate acceptance | `node scripts/ci_remote_gate.cjs candidate --sha 580c1c836232e712b31e49913c694af9e1ca123e --repo szTheory/oarlock --json` | `observed: true`, `verified: true`; exact artifact and all eight jobs matched | ✓ PASS |
| GitHub current-main acceptance | `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json` | `observed: true`, `verified: true`; main SHA remained `0db804c18eaea751d19e662d020f770d53cefc57`; required rule and exact proof matched | ✓ PASS |
| Workflow syntax | `actionlint .github/workflows/ci.yml` | exit 0 | ✓ PASS |

The six named local checks in the Validation Strategy were re-run at closeout and passed: proof binding, monitor identity, required workflow contract, timing, hosted candidate acceptance, and hosted main acceptance. The provider-inspection regression also passed.

## Probe Execution

No phase-declared or conventional `scripts/*/tests/probe-*.sh` probe was found. Probe execution is not applicable.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CI-01 | 33-02 | Complete required proof contract | ✓ SATISFIED | Workflow contract test and live all-lane candidate/main runs. |
| CI-02 | 33-03 | Controlled immutable inputs, runners/toolchains, caches, timeouts, least privilege | ✓ SATISFIED | Workflow inspection, targeted policy test, actionlint, and hosted execution. |
| CI-03 | 33-03, 33-04 | Measured timing and baseline-derived target without dropping proof | ✓ SATISFIED | Baseline and two final exact-run observations; target truthfully marked unmet. |
| CI-04 | 33-01, 33-04 | Stable required main check and exact-current-main proof | ✓ SATISFIED | Active ruleset 23970515 plus live current-main gate and retained artifact. |
| CI-05 | 33-01, 33-02, 33-04 | Durable exact-run proof summary | ✓ SATISFIED | Proof writer, monitor, passing identity test, and downloaded live artifact validation. |

No orphaned Phase 33 requirements were found. ROADMAP reports 4/4 plans complete, REQUIREMENTS marks CI-01 through CI-05 complete, and STATE points to Phase 34 with 28/28 plans complete. The phase validation contract now has all eight task rows marked pass, all six sign-off checks complete, `nyquist_compliant: true`, and approved sign-off.

### Decision Coverage

Skipped: Phase 33 has no `*-CONTEXT.md` file with a `<decisions>` block to audit.

### Planning Ledger Consistency

`node scripts/planning_health.cjs --json` exited 0 with `status: healthy` and zero errors. The active phase is 34, its `34-NEXT.md` anchor is present without a declared plan, and STATE uses `status: executing` consistently with the active incomplete phase. Existing health warnings concern historical archive/publication records and the unused `.planning/state.json` mirror; none indicate a Phase 33 completion mismatch.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/ci_timing.cjs` | 67 | `return null` for unavailable timing values | ℹ️ Info | Intentional unmeasured-data representation; callers reject missing timing instead of treating it as zero. Not a stub. |

No unresolved `TBD`, `FIXME`, or `XXX` markers, disabled requirement-linked tests, or empty implementations were found in the inspected implementation/test files. The only `return null` match is the intentional unavailable-timing representation described above.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| `scripts/ci_proof.test.cjs` | CI-05 | Yes | 0 | 0 | Behavioral/value | PASS |
| `scripts/ci_monitor.test.cjs` | CI-04, CI-05 | Yes | 0 | 0 | Behavioral/value | PASS |
| `scripts/ci_workflow_contract.test.cjs` | CI-01, CI-02 | Yes | 0 | 0 | Contract/value | PASS |
| `scripts/ci_timing.test.cjs` | CI-03 | Yes | 0 | 0 | Value | PASS |
| `scripts/ci_remote_gate.test.cjs` | CI-03, CI-04, CI-05 | Yes | 0 | 0 | Behavioral/value | PASS |
| `test/paddle/error_test.exs`, `test/paddle/inspection_safety_test.exs` | Deviation regression | Yes | 0 | 0 | Behavioral/value | PASS |

**Disabled tests on requirements:** 0. **Circular patterns detected:** 0. **Insufficient assertions:** 0. Fixture-writing matches create isolated test inputs or fake command responses; they do not generate expected outputs from the system under test.

## Human Verification Required

N/A — infrastructure/foundation phase with no user-facing elements. Hosted integration was directly re-observed through authenticated read-only GitHub queries; no phase plan contains deferred `<human-check>` items and no truth remains behavior-unverified.

## Gaps Summary

No code, wiring, hosted-evidence, or Phase 33 ledger gap blocks the phase goal. Exact candidate and current-main proof artifacts were revalidated, all required lanes passed, the active main ruleset requires `CI contract`, the phase validation contract is signed off, and measured timing remains honestly reported against the unmet provisional target.

---

_Verified: 2026-09-25T02:11:22Z_  
_Verifier: the agent (gsd-verifier)_
