---
phase: 33-deterministic-green-ci
verified: 2026-09-27T13:03:57Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - .github/workflows/ci.yml
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
  - .planning/phases/33-deterministic-green-ci/33-RESEARCH.md
  - .planning/phases/33-deterministic-green-ci/33-SECURITY.md
  - .planning/phases/33-deterministic-green-ci/33-UAT.md
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
covered_digest: "v1:sha256:b886e895c16240699993329386379884d68e9cf953754ab45fb6c4767212dd41"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 33: Deterministic Green CI — Verification Report

**Phase Goal:** Contributors and maintainers can rely on a complete, fast, reproducible CI contract that proves one exact commit and keeps remote main green.
**Verified:** 2026-09-27T13:03:57Z
**Status:** passed
**Re-verification:** No; the previous report had no `gaps:` section, so all truths were re-established against the current code and hosted state.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Every proposed change reports one required aggregate covering formatting, dependency/warning/test/spec checks, Dialyzer, quality/audit, demo/PostgreSQL, package and optional-dependency smoke, and planning guards. | ✓ VERIFIED | `.github/workflows/ci.yml` wires the named lanes into `CI contract`; all eight jobs succeeded on the exact current-main hosted run. The 41-case contract suite passed, including named-check and aggregate dependency assertions. |
| 2 | Failed or missing required lanes remain visible in a durable unverified proof and fail the aggregate. | ✓ VERIFIED | `scripts/ci_proof.cjs` writes proof before aggregate failure; fixture tests cover failed, skipped, cancelled, absent, malformed, and mismatched inputs. The current 41-test suite passed. |
| 3 | Each authoritative proof binds exact tested/event SHA, run and attempt, toolchains, lockfiles, and every required job result; hosted monitoring rejects identity or artifact mismatches. | ✓ VERIFIED | `ci_proof.cjs` and `ci_monitor.cjs` implement the allowlisted proof/validation contract, invoked by the workflow and remote gate. The 41 fixture tests passed. The live current-main artifact matched run 36085849017 attempt 1, SHA `1f2b3aa19ddfe7d8f6aaa0683df73af76abb06c5`, and its digest. |
| 4 | Inputs, runners, service/toolchain versions, timeouts, cache trust boundaries, and token permissions are controlled and inspectable. | ✓ VERIFIED | Workflow policy contract assertions passed; `actionlint .github/workflows/ci.yml` exited 0. Workflow pins actions and PostgreSQL, uses `ubuntu-24.04`, explicit timeouts and runtime/lock-aware cache keys, with cache writes restricted to successful pushes to `main`. |
| 5 | Maintainers can inspect exact-run queue/job/aggregate/critical-path timings and an honestly derived feedback target without losing required proof. | ✓ VERIFIED | `scripts/ci_timing.cjs` and fixtures validate exact-run timing and missing-data handling. `33-CI-BASELINE.md` records samples and the provisional `<120s` / `<6 runner minutes` target. Current main measured 188s critical path / 6.42 runner minutes, so the provisional target remains unmet; the criterion requires visibility and honest comparison, not a false claim that the target was reached. |
| 6 | A proposed candidate is accepted only when the exact tested SHA, all required jobs, and retained proof artifact agree. | ✓ VERIFIED | `node scripts/ci_remote_gate.cjs candidate --sha a8ae282a8bc50c3b8125d83e2dba41d95a49e2dc --repo szTheory/oarlock --json` returned `observed: true`, `verified: true`; run 36085594315 attempt 1 tested merge SHA `3411bf625b3ce026c535d347a1d211415ef03c98`, all eight jobs passed, artifact 10843468882 digest `sha256:ee718e458081a525061b625d79d7a61ab24056be9f780d293f64aa20ec99f1a5`. |
| 7 | The effective remote `main` rule requires the stable `CI contract` check and current main has exact-SHA hosted-green proof. | ✓ VERIFIED | `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json` returned `observed: true`, `verified: true`; active required rule observed. Main SHA and tested/event SHA `1f2b3aa19ddfe7d8f6aaa0683df73af76abb06c5`, run 36085849017 attempt 1, all eight jobs successful, retained artifact 10843607663 digest `sha256:8b29ee8031b401d9da35eb5b99e370d1bf8ac47637415208ea818aa30dfbebc4`. |
| 8 | The Phase 31 planning-truth diagnostics remain in the required aggregate. | ✓ VERIFIED | Workflow contract checks assert the planning-truth lane and aggregate dependency; the lane passed on both the candidate and current-main hosted runs. |
| 9 | The required CI quality lane is executable and included in the proof contract. | ✓ VERIFIED | Workflow, proof writer, hosted monitor, and contract fixtures include the quality job. The 41-case suite passed; the current-main hosted `quality checks` job succeeded. |
| 10 | Baseline and post-change comparisons preserve the full proof matrix and disclose actual performance honestly. | ✓ VERIFIED | Baseline and hosted evidence record candidate/current-main timings with all eight jobs successful. The target remains reported as unmet; no speed improvement is inferred from insufficient warm-cache evidence. |
| 11 | The phase requirements CI-01 through CI-05 are fulfilled by wired local and hosted evidence. | ✓ VERIFIED | Requirement-by-requirement coverage below maps all five requirements to the verified workflow, fixture suite, exact-SHA candidate/current-main runs, retained artifacts, effective rule, and timing records. |

**Score:** 11/11 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml` | Complete required lanes, controlled inputs, aggregate and durable proof upload | ✓ VERIFIED | Substantive workflow, checked by static contract tests and actionlint; all eight jobs ran successfully on hosted main. |
| `scripts/ci_proof.cjs` | Fail-closed proof creation and validation | ✓ VERIFIED | Invoked by aggregate; fixture tests exercise success and failure paths. |
| `scripts/ci_monitor.cjs` | Exact hosted run/artifact validator | ✓ VERIFIED | Used by remote gate; fixtures reject wrong/incomplete identities and artifacts. |
| `scripts/ci_timing.cjs` | Exact-run timing calculation | ✓ VERIFIED | Fixture tests verify durations and incomplete-timestamp behavior; live main observation supplied real timing data. |
| `scripts/ci_remote_gate.cjs` | Candidate, main, and effective-rule acceptance | ✓ VERIFIED | Independent candidate and current-main invocations returned verified results with retained proof identities. |
| `scripts/ci_workflow_contract.test.cjs` | Executable static CI policy contract | ✓ VERIFIED | Included in the 41-test run; checks required lanes, quality, runner/timeouts/cache identities. |
| `33-CI-BASELINE.md`, `33-CI-HOSTED.md` | Dated baseline, target, candidate, main, and rule evidence | ✓ VERIFIED | Recorded evidence agrees with fresh live gate results; target is explicitly unmet. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Workflow aggregate | `scripts/ci_proof.cjs` | Proof writer receives run/event/job identity | ✓ WIRED | Direct workflow invocation; aggregate creates proof before evaluating dependency failure and uploads on `always()`. |
| `scripts/ci_monitor.cjs` | `scripts/ci_proof.cjs` | Downloaded proof schema and identity validation | ✓ WIRED | Dynamic require and validator call at `ci_monitor.cjs`; covered by the 41 tests. |
| Required jobs | `CI contract` | Aggregate dependencies and stable display name | ✓ WIRED | Workflow contract assertions plus eight successful hosted job records. |
| `scripts/ci_remote_gate.cjs` | Monitor and timing scripts | Candidate/main run, artifact, rule, and duration checks | ✓ WIRED | Direct imports/calls; both live invocations returned verified results. |
| Timing script / hosted observations | Baseline and hosted evidence | Recorded observed run/SHA timings and identities | ✓ EVIDENCE LINK | These are documentation/provenance links, not runtime imports. Exact live results agree with the recorded reports. |

The generic `verify.key-links` heuristic reports false negatives for dynamic JavaScript `require` and documentation/provenance links. Each was traced directly as shown above; all execution links are independently covered by passing contract tests and live hosted observations.

### Data-Flow Trace

Not applicable to rendered/database-backed data. CI proof data originates in workflow event/run/job metadata and lockfiles; hosted acceptance reads GitHub run, job, artifact, branch-rule, and timestamp data. The proof and monitor code validate and retain those observed identities rather than substituting static success values.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| CI proof/monitor/timing/workflow/remote-gate contracts and negative paths | `node --test scripts/ci_proof.test.cjs scripts/ci_monitor.test.cjs scripts/ci_timing.test.cjs scripts/ci_workflow_contract.test.cjs scripts/ci_remote_gate.test.cjs` | 42 tests, 0 failures | ✓ PASS |
| Provider error inspection-safety regression cases | `mix test test/paddle/error_test.exs test/paddle/inspection_safety_test.exs` | 18 tests, 0 failures | ✓ PASS |
| Workflow syntax | `actionlint .github/workflows/ci.yml` | exit 0 | ✓ PASS |
| Candidate exact-SHA hosted proof | `node scripts/ci_remote_gate.cjs candidate --sha a8ae282a8bc50c3b8125d83e2dba41d95a49e2dc --repo szTheory/oarlock --json` | verified; run 36085594315 attempt 1; 8/8 jobs; artifact 10843468882/digest matched | ✓ PASS |
| Current-main exact-SHA hosted proof and required rule | `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json` | verified; SHA `1f2b3aa19ddfe7d8f6aaa0683df73af76abb06c5`; run 36085849017 attempt 1; 8/8 jobs; artifact 10843607663/digest matched; required rule active | ✓ PASS |

### Probe Execution

No phase-declared probe script or conventional `scripts/*/tests/probe-*.sh` probe was found. The phase's verification relies on named test commands and hosted acceptance commands instead; all were run above.

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|---|---|---|---|
| CI-01 | Complete required proof contract, including planning guards | ✓ SATISFIED | Workflow/static contract plus successful candidate and current-main runs with all eight required jobs. |
| CI-02 | Controlled immutable inputs, runners/toolchains, caches, timeouts, least privilege | ✓ SATISFIED | Workflow inspection, 41-case policy suite, actionlint, and successful hosted execution. |
| CI-03 | Measured critical-path evidence and baseline-derived target without dropping proof | ✓ SATISFIED | Baseline and exact-run timing records include all lanes; current target is honestly marked unmet. |
| CI-04 | Required stable main check and current-main exact-SHA hosted proof | ✓ SATISFIED | Live effective-rule read and current-main gate verified required check, SHA, run, all jobs, and artifact. |
| CI-05 | Durable exact-run proof with SHA, identity, toolchains, locks, and lane outcomes | ✓ SATISFIED | Proof writer/monitor tests and live retained candidate/current-main artifacts. |

No additional requirement mapped to Phase 33 is orphaned. Phase 33 roadmap lists four executed plans, and `33-VALIDATION.md` records validation complete.

### UAT, Nyquist, and Security Audit

`33-UAT.md` records 8/8 automated criteria passed, with no pending, skipped, or issue items. `33-VALIDATION.md` records the Nyquist audit as compliant and validated, with zero gaps or escalations; this refresh independently reran the 41 Node tests, 18 focused ExUnit tests, actionlint, and current-main gate. `33-SECURITY.md` records all high-severity threats closed and no accepted risks. T-33-07 remains one documented medium-severity, non-blocking audit-provenance limitation; it does not require human UAT or block the phase.

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion | Verdict |
|---|---|---:|---:|---|---|---|
| `scripts/ci_proof.test.cjs` | CI-05 | Yes | 0 | No | Behavioral/value | PASS |
| `scripts/ci_monitor.test.cjs` | CI-04, CI-05 | Yes | 0 | No | Behavioral/value | PASS |
| `scripts/ci_timing.test.cjs` | CI-03 | Yes | 0 | No | Value | PASS |
| `scripts/ci_workflow_contract.test.cjs` | CI-01, CI-02 | Yes | 0 | No | Structural/behavioral | PASS |
| `scripts/ci_remote_gate.test.cjs` | CI-03, CI-04, CI-05 | Yes | 0 | No | Behavioral/value | PASS |

Disabled tests linked to requirements: 0. Circular expected-value generation: 0. Insufficient assertions: 0.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | — | No unresolved `TBD`, `FIXME`, or `XXX` markers or stub/disconnected CI artifacts found | — | No blocker. |

### Decision Coverage

No `33-CONTEXT.md` decision block exists, so the optional decision-coverage gate has no decisions to evaluate.

### Human Verification Required

None — this is a CI/infrastructure phase with no user-facing flow. Exact candidate/current-main acceptance, artifact identity, required rule, timing, workflow syntax, and local contracts were verified programmatically. No irreducible human/UAT item remains.

### Covered-File Refresh

The covered-file digest changed after the prior verification. Review of the changed covered files found additional workflow assertions for the integration seam, demo E2E, package smoke, pinned toolchains, cache identities, timeouts, and runner policy. The current workflow contract suite passes 42/42, `actionlint` passes, and the focused error inspection regression tests pass 18/18. These local checks refresh evidence for the changed checkout contents. The completed 8/8 UAT remains valid, and the durable hosted-main evidence remains explicitly bound to SHA `1f2b3aa19ddfe7d8f6aaa0683df73af76abb06c5`, run 36085849017 attempt 1; no new hosted run or human UAT was performed.

### Gaps Summary

**No gaps found.** The phase goal and CI-01 through CI-05 are verified. The provisional `<120s` / `<6 runner minutes` target remains unmet (current main: 188s / 6.42 runner minutes), and is transparently recorded as a performance target rather than concealed or represented as achieved. It does not invalidate the stated success criterion, which requires inspectable timing and target evidence while preserving the full proof contract.

---

_Verified: 2026-09-27T13:03:57Z_  
_Verifier: the agent (gsd-verifier)_
