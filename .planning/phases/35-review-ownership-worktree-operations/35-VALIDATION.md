---
phase: "35"
slug: "review-ownership-worktree-operations"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
validated: "2026-09-26"
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit for root/demo; Node.js built-in test runner for repository scripts |
| **Config file** | `mix.exs`, `demo/mix.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `node --test scripts/worktree_lifecycle.test.cjs scripts/triage_audit.test.cjs scripts/collaboration_contract.test.cjs scripts/dependabot_contract.test.cjs scripts/ci_workflow_contract.test.cjs` |
| **Full suite command** | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` and `mix test`; exact-SHA `CI contract` for hosted proof |
| **Estimated runtime** | Confirm during Wave 0 against CI and targeted fixture timings |

## Sampling Rate

- **After every task commit:** Run the targeted Node fixture/contract tests for the changed audit, worktree, or Dependabot behavior and relevant format/docs checks.
- **After every plan wave:** Run `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`, `mix test`, and affected demo/package/optional checks.
- **Before `$gsd-verify-work`:** Require exact candidate-SHA `CI contract` success for every required job; local results do not substitute for hosted proof.
- **Max feedback latency:** Keep targeted tests below 30 seconds where practical; record actual suite timings in Wave 0.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 35-01 | 1 | OPS-03 | T-35-01/02 | Clean dedicated tree yields manifest-bound entry and exit receipts. | temporary Git repo integration | `node --test scripts/worktree_lifecycle.test.cjs` | Created in task | ✅ pass |
| 35-01-02 | 35-01 | 1 | OPS-03 | T-35-01/02/03 | Unsafe tree state blocks clean claims and no destructive call runs. | temporary Git repo and runner spy | `node --test scripts/worktree_lifecycle.test.cjs`; hosted CI baseline in 35-05-SUMMARY.md | First created in 35-01-01 | ✅ pass; local ancillary `ps` probe is denied with EPERM and reports unreadable |
| 35-02-01 | 35-02 | 2 | OPS-01/02 | T-35-05/06 | Forms and guidance use bounded intent and proportional evidence. | static contract | `node --test scripts/collaboration_contract.test.cjs` | Created in task | ✅ pass |
| 35-02-02 | 35-02 | 2 | OPS-01 | T-35-04 | Private route is read back enabled before docs/chooser link to it. | static contract plus hosted GET | `node --test scripts/collaboration_contract.test.cjs`; current GET returned `enabled:true` | First created in 35-02-01 | ✅ pass |
| 35-03-01 | 35-03 | 2 | OPS-02 | T-35-07/08 | Complete read-only issue/PR pagination and verified maintainer comment drive verdict. | fixture collection test | `node --test scripts/triage_audit.test.cjs` | Created in task | ✅ pass |
| 35-03-02 | 35-03 | 2 | OPS-02 | T-35-08/09 | Missing/contradictory triage is reported without secrets or mutation. | fixture collection test | `node --test scripts/triage_audit.test.cjs` | First created in 35-03-01 | ✅ pass |
| 35-04-01 | 35-04 | 2 | OPS-04 | T-35-10/12 | Root/demo/Actions, routine/security, and major boundaries stay distinct. | config contract | `node --test scripts/dependabot_contract.test.cjs` | Created in task | ✅ pass |
| 35-04-02 | 35-04 | 2 | OPS-04 | T-35-10/11/16 | Hosted alerts/security updates are enabled; PR updates use existing exact-SHA CI and Hex audit. | config/CI contract plus hosted GET | `node --test scripts/dependabot_contract.test.cjs scripts/ci_workflow_contract.test.cjs`; current GETs: automated security fixes `true`, vulnerability alerts HTTP 204 | First created in 35-04-01 | ✅ pass |
| 35-05-01 | 35-05 | 3 | OPS-02 | T-35-13/15 | Live open-item inventory is complete before judgment. | read-only hosted smoke | `GH_TOKEN="$(gh auth token)" GITHUB_REPOSITORY=szTheory/oarlock node scripts/triage_audit.cjs --inventory-only --json` | Created in 35-03-01 | ✅ pass; fresh authenticated collection complete |
| 35-05-02 | 35-05 | 3 | OPS-02 | T-35-13/14 | Every current open item has a verified maintainer decision. | read-only hosted acceptance | `GH_TOKEN="$(gh auth token)" GITHUB_REPOSITORY=szTheory/oarlock node scripts/triage_audit.cjs --json` | Created in 35-03-01 | ✅ pass; fresh audit conclusion complete, 0 gaps |

## Test Creation and External Prerequisite

- [ ] Plan 01 Task 1 creates `scripts/worktree_lifecycle.test.cjs` before implementation; Task 2 expands unsafe-state fixtures.
- [ ] Plan 02 Task 1 creates `scripts/collaboration_contract.test.cjs`; Task 2 expands it and confirms the private route via live GET after any authorized enablement.
- [ ] Plan 03 Task 1 creates `scripts/triage_audit.test.cjs` before implementation; Task 2 expands missing and contradictory records.
- [ ] Plan 04 Task 1 creates `scripts/dependabot_contract.test.cjs`; Task 2 adds exact-SHA CI and Hex audit checks.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review open issue/PR dispositions and choose unknown ownership/scope/actions. | OPS-02 | These are maintainer judgments; automation may report omissions but must not infer them. | Review the audit output and record dated decisions with explicit owner, scope, and next action. |

The private reporting setting is a hosted prerequisite with a documented admin PUT and read-only GET. Plan 02 enabled it after authorization and the current readback remains `enabled:true`. Worktree removal is outside the automated acceptance path and requires separate scoped approval if requested. The maintainer disposition that required judgment is resolved by the user's explicit authorization and normal PR #4 merge recorded in 35-05-SUMMARY.md; no additional UAT is pending.

## Artifacts this phase produces

- `scripts/worktree_lifecycle.cjs`, `scripts/worktree_lifecycle.test.cjs`, `docs/worktree-operations.md`
- `CONTRIBUTING.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/change_proposal.yml`, `.github/ISSUE_TEMPLATE/config.yml`, `.github/pull_request_template.md`, `scripts/collaboration_contract.test.cjs`
- `scripts/triage_audit.cjs`, `scripts/triage_audit.test.cjs`, `docs/triage.md`, `35-TRIAGE-BASELINE.md`
- `.github/dependabot.yml`, `scripts/dependabot_contract.test.cjs`, `docs/dependency-updates.md`

## Source Coverage Audit

| Source | ID or feature | Plan | Status |
|--------|---------------|------|--------|
| GOAL | Clean worktree entry through owned review, triage, and evidenced exit | 01-05 | COVERED |
| REQ | OPS-01 contribution, security, ownership, issue, PR guidance | 02 | COVERED |
| REQ | OPS-02 every open issue/PR disposition | 02, 03, 05 | COVERED |
| REQ | OPS-03 isolated worktree entry/exit and preservation | 01 | COVERED |
| REQ | OPS-04 grouped reviewable dependency updates | 04 | COVERED |
| RESEARCH | Verified private route and verified owner/path only | 02 | COVERED |
| RESEARCH | Dated maintainer comments, complete read-only pagination, current live baseline | 03, 05 | COVERED |
| RESEARCH | Manifest-bound NUL-safe Git evidence, unchanged host preference | 01 | COVERED |
| RESEARCH | Root/demo/Actions groups, security separation and settings, exact-SHA CI, Hex audit | 04 | COVERED |
| CONTEXT | D-01, D-02, D-03, D-04 | 02 | COVERED |
| CONTEXT | D-05, D-06, D-07 | 02, 03, 05 | COVERED |
| CONTEXT | D-08, D-09, D-10 | 01 | COVERED |
| CONTEXT | D-11, D-12, D-13 | 04 | COVERED |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing test references
- [x] No watch-mode flags
- [x] Targeted checks complete in under 30 seconds; full-suite sandbox limitation is recorded below
- [x] `nyquist_compliant: true` set after validation coverage is implemented

**Approval:** validation coverage complete. The reviewed post-review candidate is now proven by the exact-head hosted CI record below; the Phase 34 release evidence remains separate.

## Validation Audit 2026-09-26

| Metric | Count |
|--------|-------|
| Verification rows filled | 10 |
| Coverage gaps | 0 |
| Human UAT items outstanding | 0 |

- Phase 35's five contract suites and the added worktree/triage security regressions passed in the combined run; the focused fixer run passed 19/19 tests, and standard-depth review is clean (16 files, 0 findings).
- `mix test` passed 275 tests with 0 failures.
- The full Node command passed 226/227 tests. Its sole failure is the existing real-`ps` inventory assertion: `spawnSync ps EPERM` in this sandbox; the collector reports `unreadable` and fails closed. Plan 35-01 already records the same sandbox limitation, and hosted main CI passed for the merged SHA in 35-05-SUMMARY.md.
- Fresh authenticated triage collection completed with conclusion `complete` and 0 disposition gaps. Private vulnerability reporting read back `enabled:true`; vulnerability alerts returned HTTP 204; automated security fixes read back `true`.
- Candidate `889d091def2dd9e62c92f1e7401ab10d387cc77e` was the exact head of [PR #8](https://github.com/szTheory/oarlock/pull/8), based on freshly observed `main` `9eb5c14aa5cc362ac9262fea1044975a9505cebf`. [Hosted CI run 36251913054, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36251913054) passed all eight required jobs: `mix test`, `static analysis`, `demo PostgreSQL`, `package smoke`, `optional dependencies`, `planning truth`, `quality checks`, and `CI contract`. The event head equals the candidate SHA; tested SHA is the PR merge commit `6320adb14cf2e893283cfb3090866bdf0493581d`. The retained artifact `ci-proof-36251913054-1` (ID `10909960844`, digest `sha256:d5718da4376788e031a13fdf2a4f43c54974d30771c6f69a311432485d658035`) is bound to run 36251913054/attempt 1 and the candidate head; `ci_remote_gate.cjs candidate --sha` returned `verified: true`. After the maintainer authorized merging when exact-head CI was green, PR #8 merged at `8905febdb55342aa07590bf6c108b079a1e12af0`. Exact-main [CI run 36255786569, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36255786569) passed the same eight jobs and required `CI contract`; main proof returned `verified: true` with artifact `ci-proof-36255786569-1` (ID `10910592092`, digest `sha256:c728e0835f02e6117f6f55f50ed7aca53e1949e04add6a86b0688dcb0b877820`). Local focused tests passed 32/32; planning health and history integrity passed. The prior full Node feasibility run's single sandbox `ps` EPERM limitation remains recorded; hosted exact-SHA CI passed the complete contract. Phase 35's already-complete 13/13 UAT was not repeated. Phase 34 release-byte identity and durable-evidence work remains open separately in `.planning/EVIDENCE.md`.
