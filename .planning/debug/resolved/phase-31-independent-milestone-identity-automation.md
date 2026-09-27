---
status: resolved
trigger: "Phase 31 UAT gap G-31-6: integration/e2e/smoke automate the world devops mindset shift left even onto CI iff and only iff recurring value there... 0 human verification/uat required"
created: 2026-09-10T01:25:11Z
updated: 2026-09-27T14:21:39Z
---

## Current Focus

hypothesis: The diagnosed PROHIB-REPO-03-IDENTITY proof-plumbing gap has been closed by later Phase 31 plans.
test: Compare the original diagnosis with 31-08-SUMMARY.md, the canonical Phase 31 verification, and the current required planning-truth workflow.
expecting: The prohibition is resolved at the test tier; its bad/clean proof and recurring CI wiring are present.
next_action: None — closure recorded; do not repeat the original Phase 31 investigation or UAT.
bug_class: bohrbug

## Symptoms

expected: Milestone, tag, SHA, package version, and publication remain independently sourced, with recurring automated integration/e2e/smoke or CI proof so no human UAT is required.
actual: The verifier reports all observable truths automated, but still requests human review of milestone identity rows because PROHIB-REPO-03-IDENTITY is unresolved with verification null.
errors: None reported.
reproduction: Run/review Test 6 in .planning/phases/31-repository-planning-truth/31-UAT.md and the human_verification list in 31-VERIFICATION.md.
started: Discovered during Phase 31 UAT.

## Eliminated

- hypothesis: The milestone identity implementation currently infers a Hex package version from v2.1 or claims publication from local Git evidence.
  evidence: Seven focused tests pass, the current index asserts v2.1 package 0.1.1, and live planning health exits 0 while reporting publication as explicitly unknown for every inspected shipped milestone.
  timestamp: 2026-09-10T01:34:00Z

- hypothesis: Existing push/PR CI already runs the Phase 31 identity suite indirectly through mix test or the aggregate CI contract.
  evidence: The workflow explicitly runs only scripts/ci_monitor.test.cjs among Node suites; mix test is the Elixir suite, and ci-contract lists five jobs with no planning-truth job.
  timestamp: 2026-09-10T01:34:00Z

- hypothesis: The identity prohibition inherently requires subjective human judgment.
  evidence: Deterministic collection and PIDENT diagnostics already distinguish the five fields and reject a positive publication claim; GSD supports a resolved/test tier for mechanically checkable must-NOT contracts.
  timestamp: 2026-09-10T01:34:00Z

- hypothesis: The gap is intermittent, timing-dependent, or platform-specific.
  evidence: The human gate follows static PLAN metadata and deterministic absence of workflow commands; all focused checks reproduce consistently.
  timestamp: 2026-09-10T01:34:00Z

## Evidence

- timestamp: 2026-09-10T01:25:11Z
  checked: Phase 31 UAT and verification report
  found: UAT Test 6 requests automation; verification truth 18 is marked VERIFIED, while human verification is still required solely because PROHIB-REPO-03-IDENTITY remains unresolved with verification null.
  implication: The reported failure is a verification-closure/recurrence gap, not evidence that the runtime identity model currently conflates fields.

- timestamp: 2026-09-10T01:31:00Z
  checked: Phase 0 knowledge recall
  found: .planning/debug/knowledge-base.md is absent; sibling Phase 31 debug sessions show similar unresolved-prohibition/CI-omission patterns but are treated only as candidates, not proof for G-31-6.
  implication: The identity gap must be confirmed directly from its plan, tests, implementation, and workflows.

- timestamp: 2026-09-10T01:31:00Z
  checked: 31-03-PLAN.md prohibition and task verification contract
  found: PROHIB-REPO-03-IDENTITY is status unresolved, verification null, flagged_unverified true, and has no check_kind/check_target/check_violation_fixture/check_clean_fixture fields, even though Task 1 specifies a local node:test identity pattern.
  implication: Passing task tests cannot generate the wired enforcement evidence that GSD requires before a test-tier prohibition may dispose green.

- timestamp: 2026-09-10T01:31:00Z
  checked: GSD prohibition-probe and dispositionForProhibition policy
  found: Only a resolved/test prohibition with a deterministic wired check, machine-proven red violation fixture, and genuine green pass may become green; absent enforcement evidence is deliberately flagged unverified.
  implication: The verifier is fail-closed by design, so unresolved/null/descriptor-less identity metadata mechanically requires human review.

- timestamp: 2026-09-10T01:31:00Z
  checked: .github/workflows/ci.yml and all workflow command references
  found: Push/PR CI runs scripts/ci_monitor.test.cjs and Mix tests but never scripts/planning_health.test.cjs, scripts/repository_inventory.test.cjs, or scripts/planning_health.cjs; ci-contract depends only on test, dialyzer, demo-postgres, package-smoke, and optional-deps.
  implication: Identity separation is not a recurring required CI proof and may regress without failing the repository's aggregate CI contract.

- timestamp: 2026-09-10T01:31:00Z
  checked: scripts/planning_health.test.cjs identity coverage and scripts/lib/repository_truth.cjs
  found: Local tests separately assert tag/peeled SHA/tagged mix.exs package collection, planning-milestone mismatch, publication overclaim, unknown publication, Git observation failure, and current v2.1 package 0.1.1 versus planning milestone v2.1. The implementation stores five distinct fields and emits PIDENT diagnostics.
  implication: Current unit/integration-level coverage is substantive; the missing proof is authoritative fail-first binding and recurring execution, not an absent basic identity assertion.

- timestamp: 2026-09-10T01:33:00Z
  checked: Focused identity regression execution
  found: Seven selected tests passed, including separate tag/SHA/package/publication collection, planning-milestone mismatch, publication overclaim rejection, both Git failure paths, five-identity renderer parity, and current-repository reconciliation.
  implication: G-31-6 is reproducibly a verification-authority and recurrence gap; the present identity implementation satisfies the local behavioral oracle.

- timestamp: 2026-09-10T01:34:00Z
  checked: Live node scripts/planning_health.cjs --json
  found: The command exited 0 with status healthy, zero errors, and PIDENT_PUBLICATION_UNKNOWN informational diagnostics for v1.1 through v2.1; v1.5's missing local tag remains an explicit warning rather than an inferred identity.
  implication: Current repository rows preserve publication unknown and do not infer the absent v1.5 tag; human review is not caused by a live history error.

- timestamp: 2026-09-10T01:34:00Z
  checked: Repository-wide prohibition enforcement descriptor search
  found: Outside debug notes, there is no GSD_PROHIB_SUBJECT consumer and no check_kind/check_target/check_violation_fixture/check_clean_fixture entry for this identity prohibition.
  implication: The existing green unit/integration tests cannot be consumed by GSD's fail-first prohibition producer, so they remain non-authoritative for closing the must-NOT lifecycle.

- timestamp: 2026-09-10T01:34:00Z
  checked: Spectrum-based fault localization eligibility and common-pattern scan
  found: There is no failing automated test; the focused suite and live command are green. The matching common pattern is environment/config omission rather than runtime logic, and the failure is deterministic.
  implication: SBFL is inapplicable; static policy/workflow tracing and differential comparison of local verification versus recurring CI localize the gap.

- timestamp: 2026-09-27T14:21:39Z
  checked: 31-08-SUMMARY.md, .planning/phases/31-repository-planning-truth/31-VERIFICATION.md, scripts/prohibitions/planning_identity.test.cjs, scripts/fixtures/prohibitions/planning_identity_inference.cjs, and .github/workflows/ci.yml
  found: PROHIB-REPO-03-IDENTITY is resolved with a named test target and bad subject; Phase 31 Plan 09 records 98 passing tests, 6/6 bad/clean prohibition proofs, live planning-health success, and required CI wiring for the suite and smoke.
  implication: This diagnosis describes the earlier missing proof; subsequent implementation resolved it and it can be closed without rerunning its historical UAT.

## Resolution
root_cause: "Two contributing layers explain G-31-6. First, PROHIB-REPO-03-IDENTITY remains status unresolved with verification null and no wired descriptor, so GSD's fail-closed policy cannot promote ordinary green tests and 31-VERIFICATION must request human review. Second, the repository has no recurring enforcement path: push/PR/release workflows do not run scripts/planning_health.test.cjs or the live planning_health.cjs smoke, ci-contract does not require a planning-truth job, and the existing tests are not a subject-driven fail-first prohibition check with known-bad and clean fixtures. Thus the identity behavior is locally implemented and green, but no authoritative recurring gate can replace UAT."
fix: "Phase 31 Plan 08 resolved the identity prohibition with independent bad/clean source checks. Plan 09 includes the descriptor in the six-check enforcement lane and required planning-truth CI contract."
verification: "Validated by 31-08-SUMMARY.md and 31-VERIFICATION.md: the full Phase 31 Node/prohibition suite passed 98/98, the enforcer passed all 6/6 non-vacuous bad/clean checks, live planning health exited healthy, and ci.yml wires the planning-truth lane. Fresh planning health on 2026-09-27 also reports healthy with 0 errors."
oracle_type: specified
files_changed: ["scripts/prohibitions/planning_identity.test.cjs", "scripts/fixtures/prohibitions/planning_identity_inference.cjs", ".github/workflows/ci.yml", ".planning/phases/31-repository-planning-truth/31-08-SUMMARY.md"]
