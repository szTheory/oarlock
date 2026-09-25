---
status: diagnosed
trigger: 'Phase 31 UAT gap G-31-5: Frozen archives are unchanged and corrections are additive. User requests recurring integration/e2e/smoke or CI automation where valuable so no human UAT is required.'
created: 2026-09-10T01:17:00Z
updated: 2026-09-10T01:21:36Z
---

## Current Focus

bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: Human UAT remains required because the prohibition's authority metadata was never resolved, and it cannot safely be resolved from the present automation because the Phase 31 suite is absent from CI and its preservation oracle has no cross-revision baseline.
  confirming_evidence:
    - PROHIB-REPO-03-PRESERVATION is status unresolved, verification null, and flagged_unverified true while the verifier explicitly uses those fields as the reason for human review.
    - CI runs ci_monitor.test.cjs and mix test but never planning_health.test.cjs or repository_inventory.test.cjs.
    - In an isolated clone, committed frozen-archive and prior-EVIDENCE rewrites both left git diff clean and the current-repository preservation test green.
  falsification_test: This diagnosis would be false if CI invoked a cross-revision preservation test that failed after either committed counterexample, or if the prohibition metadata already pointed to an authoritative automated verification tier.
  fix_rationale: A recurring base-to-head immutability/additivity guard closes the missing proof class; wiring it into required CI gives it recurring authority; recording that automated tier on the prohibition removes the verifier's explicit human-only fallback.
  blind_spots: Hosted branch-protection configuration is not available from repository files, so the diagnosis establishes missing workflow coverage but does not assert which hosted checks are currently required.
  candidate_causes:
    - 'config: PLAN prohibition remains unresolved with verification null, and CI omits the Phase 31 Node suites.'
    - 'code: preservation tests compare before/after within one execution, and planned git diff compares only current HEAD to its clean worktree rather than base-to-head history.'
    - 'environment: hosted CI cannot exercise proof that is not present in its checked-in workflow; no runtime-specific or flaky condition was observed.'
    - 'data: current archive content and correction rows are healthy, so malformed current data is not the cause.'
  and_gate: 'yes: the verifier requests human review because metadata is unresolved, while safe replacement by automation additionally requires both a cross-revision oracle and recurring CI wiring.'
next_action: Return root-cause-only diagnosis to the orchestrator; do not implement changes.

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

## Resolution

root_cause: 'Three contributing gaps: (1) PROHIB-REPO-03-PRESERVATION remains explicitly unresolved with verification null, which mechanically forces human review; (2) Phase 31 planning-health/repository-inventory Node suites are not run by push/PR CI; and (3) the preservation checks lack a base-to-head/frozen-baseline oracle, so committed archive rewrites and non-additive EVIDENCE rewrites can pass. Consequently the verifier has local present-state/no-mutation evidence but no authoritative recurring regression gate capable of replacing human UAT.'
fix: 'Not applied (diagnose-only). Suggested direction: add a base-to-head history-integrity test/script that forbids edits/deletions to archives already present at the base revision, permits newly created milestone snapshots, and rejects deletion/modification of prior correction-ledger entries while validating new dated correction rows; run the Phase 31 Node suites and live planning-health smoke in required push/PR CI; then set the prohibition verification metadata to that concrete automated tier.'
verification: 'Root cause confirmed by static workflow/metadata trace, 4/4 focused tests passing, and two isolated committed-change counterexamples that both escaped the existing advertised checks.'
files_changed: []
