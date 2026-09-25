---
status: diagnosed
trigger: "Phase 31 UAT gap G-31-6: integration/e2e/smoke automate the world devops mindset shift left even onto CI iff and only iff recurring value there... 0 human verification/uat required"
created: 2026-09-10T01:25:11Z
updated: 2026-09-10T01:34:00Z
---

## Current Focus

bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: "G-31-6 requires human UAT because PROHIB-REPO-03-IDENTITY is unresolved/null and therefore cannot green under GSD's fail-closed prohibition policy; replacing that review with recurring automation also requires a wired fail-first identity check and a required CI job, neither of which exists."
  confirming_evidence:
    - "31-03-PLAN leaves PROHIB-REPO-03-IDENTITY status unresolved, verification null, flagged_unverified true, and supplies no check descriptor; 31-VERIFICATION cites that exact state as why_human."
    - "The focused local identity suite passes 7/7 and live planning health exits 0 with only explicit-unknown publication info, proving the current implementation is healthy rather than reproducing an identity conflation."
    - "All repository workflows omit planning_health.test.cjs and planning_health.cjs, and the aggregate ci-contract has no planning-truth dependency."
  falsification_test: "The diagnosis would be false if the prohibition were already resolved/test with passing wired fail-first enforcement evidence, or if required push/PR CI invoked the identity suite/live smoke and the verifier still required human review for another stated reason."
  fix_rationale: "A subject-driven identity prohibition check with known-bad and clean fixtures provides authoritative machine evidence; required CI execution makes it recurring; resolving the PLAN item to the test tier removes the explicit human fallback."
  blind_spots: "Hosted branch-protection/ruleset state was not available, so this establishes repository-workflow omission but does not claim which hosted checks are mandatory. A live CI smoke would also need an explicitly complete local-tag input; the present workflow does not declare one."
  candidate_causes:
    - "data/config: unresolved/null prohibition lifecycle and absent check descriptor mechanically force human_needed"
    - "automation/config: push/PR/release workflows never run planning-health identity tests or live smoke, and ci-contract does not require such a job"
    - "code/test: existing green tests are ordinary direct assertions, not a GSD_PROHIB_SUBJECT fail-first check with known-bad and clean fixtures"
    - "environment: a future CI live smoke must explicitly make the historical local tags used as authorities available"
  and_gate: "Immediate human_needed needs only the unresolved/null item. The requested zero-human recurring guarantee is an AND: resolved/test metadata + machine-proven fail-first descriptor + recurring required CI execution (with tag inputs for live smoke)."
next_action: Return root-cause-only diagnosis to the orchestrator; do not implement changes.

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

## Resolution

root_cause: "Two contributing layers explain G-31-6. First, PROHIB-REPO-03-IDENTITY remains status unresolved with verification null and no wired descriptor, so GSD's fail-closed policy cannot promote ordinary green tests and 31-VERIFICATION must request human review. Second, the repository has no recurring enforcement path: push/PR/release workflows do not run scripts/planning_health.test.cjs or the live planning_health.cjs smoke, ci-contract does not require a planning-truth job, and the existing tests are not a subject-driven fail-first prohibition check with known-bad and clean fixtures. Thus the identity behavior is locally implemented and green, but no authoritative recurring gate can replace UAT."
fix: "Not applied (diagnose-only). Suggested direction: classify PROHIB-REPO-03-IDENTITY as resolved/test and wire a node-test descriptor to a clean milestone-identity subject plus known-bad fixtures that independently mutate planning milestone, tag/SHA, package version, and publication claim; make the check prove red on inference/overclaim and green on independently sourced/explicit-unknown rows. Run it, the planning-health suite, and a live planning-health JSON smoke in a required push/PR CI job, explicitly provision the local tag refs needed by the smoke, and add that job to ci-contract."
verification: "Diagnosis confirmed by metadata/policy trace, repository-wide descriptor/workflow searches, 7/7 focused identity tests passing, and live planning-health exit 0 with only explicit-unknown PIDENT publication information."
files_changed: []
