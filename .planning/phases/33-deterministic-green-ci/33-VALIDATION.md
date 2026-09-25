---
phase: "33"
slug: "deterministic-green-ci"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-24"
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in `node:test`; Elixir ExUnit for existing SDK checks |
| **Config file** | `package.json` / `mix.exs`; no Node test config |
| **Quick run command** | `node --test scripts/ci_monitor.test.cjs scripts/ci_proof.test.cjs` |
| **Full suite command** | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` plus the required hosted CI contract |
| **Estimated runtime** | Not measured yet; Phase 33 measures hosted critical-path timing before setting a target |

## Sampling Rate

- **After every task commit:** Run the focused Node test named in that plan task.
- **After every plan wave:** Run the Node contract suites and inspect workflow syntax/required-job coverage.
- **Before `$gsd-verify-work`:** Require the complete hosted CI aggregate for the candidate SHA and a matching proof artifact.
- **Max feedback latency:** Establish from hosted baseline in Plan 33-03; do not invent a threshold before measurement.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | CI-05, CI-04 | T-33-01, T-33-03 | Proof is bound to event SHA, run identity, toolchains, lock digests, and every lane, including failed runs | unit/integration | `node --test scripts/ci_proof.test.cjs` | No — created in task | ⬜ pending |
| 33-01-02 | 01 | 1 | CI-04, CI-05 | T-33-02, T-33-04 | Hosted monitor accepts only matching exact-SHA run, attempt, artifact, and successful required jobs | unit | `node --test scripts/ci_monitor.test.cjs scripts/ci_proof.test.cjs` | Partial — extend in task | ⬜ pending |
| 33-02-01 | 02 | 2 | CI-01 | — | Credo, ExDoc, and Hex audit execute as required checks alongside existing proof lanes | unit/integration | `node --test scripts/ci_workflow_contract.test.cjs`; run the affected Mix commands | No — created in task | ⬜ pending |
| 33-02-02 | 02 | 2 | CI-01, CI-05 | T-33-02 | The added required lane is included in proof schema, aggregate, and exact-SHA monitor | unit | `node --test scripts/ci_proof.test.cjs scripts/ci_monitor.test.cjs` | Partial — extend in task | ⬜ pending |
| 33-03-01 | 03 | 3 | CI-03 | — | Baseline records queue and job durations, critical path, cache state, and sample identity before performance changes | hosted integration | `gh run view <run-id> --json headSha,jobs,runAttempt,url` and the plan's timing summarizer | No — create in task | ⬜ pending |
| 33-03-02 | 03 | 3 | CI-02, CI-03 | T-33-01, T-33-04 | Reviewed inputs, runtime-aware caches, least privilege, and timeouts preserve every required lane | unit/contract | `node --test scripts/ci_workflow_contract.test.cjs` and compare post-change hosted timings with baseline | No — created in task | ⬜ pending |
| 33-04-01 | 04 | 4 | CI-03, CI-04, CI-05 | T-33-02, T-33-03 | A hosted candidate run has exact-SHA success, retained matching artifact, and complete timing evidence | hosted integration | `node scripts/ci_monitor.cjs assert-ci --sha <candidate-sha> --json` plus artifact/schema validation | Partial — extend in task | ⬜ pending |
| 33-04-02 | 04 | 4 | CI-04 | — | Remote `main` requires the stable `CI contract`, and the current main SHA has a successful exact-SHA hosted proof | hosted integration | `gh api repos/{owner}/{repo}/rulesets` and `node scripts/ci_monitor.cjs assert-ci --sha <main-sha> --json` | Existing monitor; hosted state external | ⬜ pending |

## Wave 0 Requirements

Existing Node and ExUnit infrastructure covers phase behaviors. Each new workflow/proof test is introduced with its implementing task; no separate test-only wave is needed.

## Manual-Only Verifications

All repository behavior and workflow contracts should have automated checks. Remote ruleset and hosted-run observations use authenticated GitHub APIs/CLI. If credentials or network access are unavailable, report the result as **unobserved** and hand off only that external-state limitation; local green tests do not substitute for hosted evidence.

## Validation Sign-Off

- [x] All tasks have automated verification or a hosted integration command
- [x] Sampling continuity: every task has a verification command
- [x] Wave 0 covers all missing test references through task-owned test creation
- [x] No watch-mode flags
- [ ] Feedback latency target is derived from hosted measurements
- [ ] `nyquist_compliant: true` set in frontmatter after phase validation

**Approval:** pending
