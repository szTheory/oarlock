---
status: diagnosed
trigger: "Phase 31 UAT gap G-31-4: determine why the truth 'Repairs remain inert and authority conflicts remain blocking' still requires human UAT and what recurring automated integration/e2e/smoke or CI coverage is missing."
created: 2026-09-10T01:11:37Z
updated: 2026-09-10T01:14:33Z
---

## Current Focus

hypothesis: Confirmed — human UAT is caused by unresolved descriptor-less prohibition metadata, while zero-human recurring assurance is additionally blocked by missing planning-health CI and missing fail-first CLI/filesystem prohibition fixtures.
test: Completed: PLAN/verification trace, focused and full local tests, live CLI, prohibition-enforcement contract audit, descriptor search, and workflow/CI-contract audit.
expecting: Confirmed by direct evidence; alternatives are recorded under Eliminated.
next_action: Return diagnose-only root cause and suggested automation direction to the orchestrator; do not implement changes.
bug_class: bohrbug
candidate_causes:
  - "data: source PLAN prohibition metadata remains unresolved/null even after behavioral verification"
  - "config: recurring CI/test entry points may not include scripts/planning_health.test.cjs"
and_gate: "yes for the user's zero-human recurring goal: authoritative prohibition disposition and recurring CI/e2e enforcement are independently missing; either omission leaves human UAT or regression exposure"

## Symptoms

expected: Repairs remain inert and authority conflicts remain blocking, with recurring automated integration/e2e/smoke or CI coverage sufficient to require zero human UAT for this truth when that coverage has recurring value.
actual: Phase 31 verification reports the runtime truth as automatically verified, but classifies PROHIB-REPO-04-SAFETY as unresolved with verification null and creates human UAT Test 4.
errors: None reported.
reproduction: Review Test 4 in `.planning/phases/31-repository-planning-truth/31-UAT.md` and its source in `31-VERIFICATION.md`.
started: Discovered during Phase 31 UAT.

## Eliminated

- hypothesis: Planning health currently executes proposed repairs or suppresses authority conflicts.
  evidence: Focused conflict/read-only tests pass, all 37 suite tests pass, and the live CLI is healthy; tests directly observe `active: null`, preserved conflict diagnostics, and unchanged planning bytes.
  timestamp: 2026-09-10T01:14:00Z

- hypothesis: Existing recurring CI already enforces the Phase 31 planning-health proofs, so the only defect is stale verification wording.
  evidence: All three GitHub workflows omit the planning-health suite and live command; the CI aggregate job and exact-SHA monitor do not name a planning-health lane.
  timestamp: 2026-09-10T01:14:00Z

- hypothesis: The prohibition intrinsically requires human judgment and cannot be automated.
  evidence: Its two behaviors are deterministic and already partly exercised mechanically; GSD explicitly permits test-tier automated prohibition disposition when a fail-first wired descriptor and bad/clean controls exist.
  timestamp: 2026-09-10T01:14:00Z

## Evidence

- timestamp: 2026-09-10T01:11:37Z
  checked: `.planning/phases/31-repository-planning-truth/31-VERIFICATION.md`
  found: The report says all 21 observable truths pass, including D-07 blocking authority disagreement and D-09 inert repair proposals, but Test 4 is routed to human verification because `PROHIB-REPO-04-SAFETY remains unresolved with verification: null`.
  implication: The reported UAT gap is a verification-authority/automation-coverage gap, not evidence that planning-health currently mutates or suppresses conflicts.

- timestamp: 2026-09-10T01:11:37Z
  checked: `.planning/phases/31-repository-planning-truth/31-UAT.md`
  found: Test 4's failure reason requests recurring integration/e2e/smoke/CI automation and zero human UAT; it reports no runtime error or observed violation of inertness/blocking behavior.
  implication: Diagnosis must distinguish missing recurring proof from an implementation defect.

- timestamp: 2026-09-10T01:13:00Z
  checked: `.planning/phases/31-repository-planning-truth/31-02-PLAN.md`
  found: PROHIB-REPO-04-SAFETY is explicitly `status: unresolved`, `verification: null`, and `flagged_unverified: true`, even though Task 1 separately requires authority conflicts to block and Task 2 separately requires read-only/no-write behavior.
  implication: Ordinary task verification does not resolve the prohibition lifecycle; the verifier must fail closed and route it to human review.

- timestamp: 2026-09-10T01:13:00Z
  checked: `scripts/planning_health.test.cjs`
  found: Evaluator-level tests assert `active: null` on ROADMAP/STATE conflict and assert conflict diagnostics do not suppress missing-proof diagnostics; a separate filesystem/CLI test snapshots planning bytes before and after normal human/JSON runs. No one test drives a conflict through `main()` while also proving bytes unchanged and exit nonzero.
  implication: Both behavioral halves have local automated evidence, but the exact control-flow prohibition lacks an integrated CLI/filesystem oracle.

- timestamp: 2026-09-10T01:13:00Z
  checked: `.github/workflows/ci.yml`, release workflows, and `scripts/ci_monitor.cjs`
  found: Push/PR CI runs only `scripts/ci_monitor.test.cjs` among Node tests; no workflow invokes `scripts/planning_health.test.cjs`, `scripts/repository_inventory.test.cjs`, or `scripts/planning_health.cjs`. The aggregate CI contract and exact-SHA monitor require only mix test, static analysis, demo PostgreSQL, package smoke, optional dependencies, and CI contract.
  implication: The Phase 31 planning-health regressions are one-time/local evidence, not recurring hosted enforcement.

- timestamp: 2026-09-10T01:13:00Z
  checked: GSD `prohibition-probe.md`, `probe-core.cjs`, and `prohibition-enforcement.cjs`
  found: Automated green disposition requires a `resolved`/`test` prohibition with a locatable `check_*` descriptor, a known-bad violation fixture, a known-clean control for node-test, machine-proven non-vacuous red on the violation, and non-vacuous green on clean/current behavior. Unresolved/null or descriptor-less items fail closed.
  implication: The general Phase 31 suite cannot become authoritative prohibition proof merely by passing; the PLAN item lacks the metadata and fixtures the verifier is allowed to trust.

- timestamp: 2026-09-10T01:14:00Z
  checked: Focused and full `scripts/planning_health.test.cjs` execution plus live `node scripts/planning_health.cjs --json`
  found: The three focused conflict/read-only tests pass, all 37 planning-health tests pass, and the live command exits 0 with `status: healthy`; no repair was executed and no live authority conflict was hidden.
  implication: The implementation violation hypothesis is falsified. The reproducible failure is proof routing and durability, not current planning-health behavior.

- timestamp: 2026-09-10T01:14:00Z
  checked: Phase 1.25 spectrum-based fault localization eligibility
  found: There are zero failing tests in the relevant suite, so no failing/passing spectrum exists for SBFL.
  implication: SBFL is inapplicable; working backward from deterministic verifier metadata is the appropriate Bohrbug route.

- timestamp: 2026-09-10T01:14:33Z
  checked: `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`
  found: CI-01 explicitly requires planning guards in every proposed change's complete proof contract, but CI-01 is pending and assigned to future Phase 33.
  implication: The repository itself recognizes recurring planning-guard CI as valuable, but that contract is not implemented yet; Phase 31's local Nyquist validation cannot substitute for it.

## Resolution

root_cause: "Two contributing gaps cause G-31-4's human-UAT/zero-recurring-proof result: (1) data/verification-contract gap — `PROHIB-REPO-04-SAFETY` was intentionally left `status: unresolved`, `verification: null`, `flagged_unverified: true`, with no `check_*` descriptor or bad/clean fixtures, so GSD must fail closed and route it to human review even when ordinary behavioral tests pass; (2) config/coverage gap — the planning-health Node suite and live smoke are absent from push/PR/release CI and from the aggregate CI contract, and the local suite separates conflict blocking from healthy-run byte preservation instead of providing one fail-first CLI/filesystem check proving a conflicting input returns nonzero, selects no winner, executes no repair, and preserves bytes."
fix: "Not applied (diagnose-only). Suggested direction: resolve the prohibition at the test tier and wire a node-test descriptor to a content-dependent known-bad conflict/repair-attempt fixture plus known-clean control; make the test drive `planning_health.cjs` through the filesystem/CLI boundary and assert nonzero blocking diagnostics, `active: null`, unchanged planning/repository state, and inert repair fields. Run the planning-health suite (and a live read-only smoke where stable) in push/PR CI, add the lane to `ci-contract` and the exact-SHA monitor. This naturally fulfills pending CI-01/Phase 33 planning-guard work."
verification: "Diagnosis confirmed by direct PLAN and verifier metadata, GSD prohibition-policy inspection, absence of descriptor wiring, focused 3/3 and full 37/37 planning-health tests passing, live planning health exit 0/healthy, and all-workflow/CI-contract search showing no planning-health execution."
files_changed: []
