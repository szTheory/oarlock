---
status: resolved
trigger: 'Phase 31 UAT gap G-31-5: Frozen archives are unchanged and corrections are additive. User requests recurring integration/e2e/smoke or CI automation where valuable so no human UAT is required.'
created: 2026-09-10T01:17:00Z
updated: 2026-09-27T14:21:39Z
---

## Current Focus

hypothesis: The diagnosed PROHIB-REPO-03-PRESERVATION proof-plumbing gap has been closed by later Phase 31 plans.
test: Compare the original diagnosis with 31-09-SUMMARY.md, the canonical Phase 31 verification, and the current required planning-truth workflow.
expecting: The prohibition is resolved at the test tier; its bad/clean proof and recurring CI wiring are present.
next_action: None — closure recorded; do not repeat the original Phase 31 investigation or UAT.
bug_class: bohrbug

## Symptoms

expected: Frozen archives are unchanged and corrections are additive; recurring-value integration/e2e/smoke coverage should run in CI so zero human verification/UAT is required.
actual: Phase 31 verification marks the truth verified by local automated evidence but still requires human review because PROHIB-REPO-03-PRESERVATION is unresolved with verification: null.
errors: None reported.
reproduction: Test 5 in Phase 31 UAT; review history changes against frozen milestone snapshots.
started: Discovered during Phase 31 UAT.

## Eliminated

- hypothesis: The frozen-history implementation is currently producing a REPO-03 history error.
  evidence: Focused archive/current-repository tests pass, and 31-VERIFICATION records all 21 truths verified with no behavior-unverified items.
  timestamp: 2026-09-10T01:21:36Z

- hypothesis: mix test or a Mix alias indirectly executes the Phase 31 Node suites in CI.
  evidence: mix.exs defines only the setup alias; the complete CI workflow explicitly invokes only scripts/ci_monitor.test.cjs before mix test, with no planning-health or repository-inventory suite reference.
  timestamp: 2026-09-10T01:21:36Z

- hypothesis: The failure is flaky, timing-dependent, or platform-specific.
  evidence: The metadata state and missing workflow invocation are static, and both committed-change counterexamples reproduce deterministically in an isolated clone.
  timestamp: 2026-09-10T01:21:36Z

## Evidence

- timestamp: 2026-09-10T01:17:00Z
  checked: Phase 31 UAT and verification report
  found: UAT gap G-31-5 repeats the automation request, while 31-VERIFICATION reports truth 17 as VERIFIED using archive/history git diff plus a current-repository preservation test; the same report nevertheless flags PROHIB-REPO-03-PRESERVATION because its structured status is unresolved and verification is null.
  implication: The reported gap is not evidence that archive preservation currently fails; it is a verification-authority/recurrence-coverage gap.

- timestamp: 2026-09-10T01:18:56Z
  checked: 31-03-PLAN prohibition metadata and planned verification commands
  found: PROHIB-REPO-03-PRESERVATION is still status unresolved, verification null, and flagged_unverified true. The plan nevertheless specifies local node:test coverage and git diff --exit-code against .planning/milestones.
  implication: The verifier is behaving as designed: executable task acceptance never updated the separate structured prohibition disposition that controls whether human review is required.

- timestamp: 2026-09-10T01:18:56Z
  checked: .github/workflows/ci.yml and mix.exs aliases
  found: CI invokes only scripts/ci_monitor.test.cjs among Node tests and then mix test; it never invokes scripts/planning_health.test.cjs, scripts/repository_inventory.test.cjs, or planning_health.cjs. mix.exs has no alias that includes these Node suites.
  implication: Phase 31 history/preservation proof is ad hoc verifier-time evidence, not a recurring push/PR gate.

- timestamp: 2026-09-10T01:18:56Z
  checked: scripts/planning_health.test.cjs preservation tests and Plan 31-03/31-05 git-diff checks
  found: The current-repository test captures archive bytes immediately before collect/evaluate and compares immediately afterward; the interrupted-CLI test does the same for planning files. The git-diff checks compare the working tree/index to current HEAD. No test loads a frozen manifest/hash or merge-base snapshot, and no test compares prior EVIDENCE/MILESTONES content to enforce append-only evolution.
  implication: These checks prove the health command does not mutate files during one execution, but do not prove a proposed commit preserved archives or made corrections additively across revisions.

- timestamp: 2026-09-10T01:21:36Z
  checked: Focused node:test execution for milestone archive, dated corrections, and current-repository reconciliation
  found: All four selected tests passed locally (4/4), including current repository milestone history is reconciled and archive bytes stay immutable.
  implication: Existing automation is green for current-state semantics; the UAT issue is about proof scope and recurrence rather than a presently failing validator.

- timestamp: 2026-09-10T01:21:36Z
  checked: Isolated-clone frozen-archive counterexample
  found: After committing a two-line change to .planning/milestones/v1.4-ROADMAP.md, git diff --exit-code -- .planning/milestones .planning/MILESTONES.md .planning/EVIDENCE.md returned 0 and the named current-repository preservation test returned 0.
  implication: The advertised D-11 commands accept a committed rewrite of a frozen snapshot because neither has an earlier-revision oracle.

- timestamp: 2026-09-10T01:21:36Z
  checked: Isolated-clone additive-correction counterexample
  found: After committing a one-line replacement of an existing .planning/EVIDENCE.md row (one insertion, one deletion), the same git-diff command returned 0 and the current-repository preservation test returned 0.
  implication: The current checks validate selected present-day correction rows and no-runtime-mutation, but do not enforce append-only ledger evolution across commits.

- timestamp: 2026-09-10T01:21:36Z
  checked: Spectrum-based fault localization eligibility
  found: No failing automated test exists; the focused suite is green and the gap concerns an absent/insufficient gate.
  implication: SBFL is not applicable because there is no failing-test spectrum to rank.

- timestamp: 2026-09-27T14:21:39Z
  checked: 31-09-SUMMARY.md, .planning/phases/31-repository-planning-truth/31-VERIFICATION.md, scripts/history_integrity.test.cjs, scripts/fixtures/prohibitions/history_rewrite.json, and .github/workflows/ci.yml
  found: PROHIB-REPO-03-PRESERVATION is resolved with a named test target and bad subject; Phase 31 Plan 09 records 98 passing tests, 6/6 bad/clean prohibition proofs, live planning-health success, and required CI wiring for the suite and smoke.
  implication: This diagnosis describes the earlier missing proof; subsequent implementation resolved it and it can be closed without rerunning its historical UAT.

## Resolution
root_cause: 'Three contributing gaps: (1) PROHIB-REPO-03-PRESERVATION remains explicitly unresolved with verification null, which mechanically forces human review; (2) Phase 31 planning-health/repository-inventory Node suites are not run by push/PR CI; and (3) the preservation checks lack a base-to-head/frozen-baseline oracle, so committed archive rewrites and non-additive EVIDENCE rewrites can pass. Consequently the verifier has local present-state/no-mutation evidence but no authoritative recurring regression gate capable of replacing human UAT.'
fix: "Phase 31 Plan 03 resolved the preservation prohibition with a history-integrity test and rewrite/additive fixtures. Plan 09 adds the base-to-head history guard and required planning-truth CI lane."
verification: "Validated by 31-09-SUMMARY.md and 31-VERIFICATION.md: the full Phase 31 Node/prohibition suite passed 98/98, the enforcer passed all 6/6 non-vacuous bad/clean checks, live planning health exited healthy, and ci.yml wires the planning-truth lane. Fresh planning health on 2026-09-27 also reports healthy with 0 errors."
oracle_type: specified
files_changed: ["scripts/history_integrity.test.cjs", "scripts/fixtures/prohibitions/history_rewrite.json", ".github/workflows/ci.yml", ".planning/phases/31-repository-planning-truth/31-09-SUMMARY.md"]
