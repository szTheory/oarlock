---
status: resolved
trigger: "Phase 31 UAT gap G-31-1: All actions remain report-only proposals; determine why this truth still requires human UAT and what automated coverage/CI wiring is missing."
created: 2026-09-10T00:55:03Z
updated: 2026-09-27T14:21:39Z
---

## Current Focus

hypothesis: The diagnosed PROHIB-REPO-01-SAFETY proof-plumbing gap has been closed by later Phase 31 plans.
test: Compare the original diagnosis with 31-06-SUMMARY.md, the canonical Phase 31 verification, and the current required planning-truth workflow.
expecting: The prohibition is resolved at the test tier; its bad/clean proof and recurring CI wiring are present.
next_action: None — closure recorded; do not repeat the original Phase 31 investigation or UAT.
bug_class: bohrbug

## Symptoms

expected: Inventory disposition paths never authorize alteration, discard, unlock, or concealment; this recurring invariant is enforced automatically with zero human UAT.
actual: UAT Test 1 remains a major issue because the truth is routed to human review despite automated evidence described in 31-VERIFICATION.md.
errors: None reported.
reproduction: Run Phase 31 verification/UAT Test 1 and observe that PROHIB-REPO-01-SAFETY remains unresolved with verification null, producing human_needed status.
started: Discovered during Phase 31 UAT on 2026-09-09.

## Eliminated

- hypothesis: The implementation currently mutates repository state during inventory.
  evidence: The exact local inventory suite passed its before/between/after Git/file manifest assertions; the implementation allowlists inspection commands and permits worktree prune only with --dry-run --verbose.
  timestamp: 2026-09-10T00:57:50Z

- hypothesis: No automated behavioral test exists for report-only operation.
  evidence: scripts/repository_inventory.test.cjs contains a CLI-level byte-preservation test and the full file passed 17/17 locally.
  timestamp: 2026-09-10T00:57:50Z

- hypothesis: The human-needed result is only a stale verification-report artifact.
  evidence: Current plan metadata remains unresolved/null, and the current GSD enforcement helpers deterministically return flagged unverified with no enforcement evidence.
  timestamp: 2026-09-10T00:57:50Z

## Evidence

- timestamp: 2026-09-10T00:55:03Z
  checked: Phase 31 UAT and verification report
  found: Verification reports 21/21 observable truths and 40/40 Node tests passing, but explicitly classifies PROHIB-REPO-01-SAFETY as a non-authoritative automated pass because its plan frontmatter has status unresolved and verification null.
  implication: The reported gap is not an observed inventory mutation failure; it is an automation-authority and gate-wiring gap.

- timestamp: 2026-09-10T00:57:30Z
  checked: 31-01-PLAN.md prohibition declaration
  found: PROHIB-REPO-01-SAFETY is status unresolved, verification null, and has no check_kind, check_target, check_violation_fixture, or optional check_clean_fixture fields.
  implication: The deterministic verifier has no resolved test-tier contract and no locatable enforcement check for this prohibition.

- timestamp: 2026-09-10T00:57:30Z
  checked: Local inventory suite
  found: node --test scripts/repository_inventory.test.cjs passed 17/17, including the before/after repository-manifest read-only test.
  implication: Ordinary behavior coverage exists and is green locally, so lack of any test is not the cause; the missing piece is authoritative prohibition enforcement and recurring execution.

- timestamp: 2026-09-10T00:57:30Z
  checked: GSD dispositionForProhibition behavior
  found: Both the current unresolved/null item and a hypothetical resolved/test item without enforcement evidence return status unverified and flagged true.
  implication: Merely relabeling the prohibition test-tier would still not remove human verification; a wired, passing, machine-proven fail-first check is required.

- timestamp: 2026-09-10T00:57:30Z
  checked: .github/workflows/ci.yml and repository-wide node-test workflow references
  found: Hosted CI invokes node --test only for scripts/ci_monitor.test.cjs; it never invokes scripts/repository_inventory.test.cjs, scripts/planning_health.test.cjs, or scripts/*.test.cjs.
  implication: Phase 31 safety regressions are not rechecked on pushes or pull requests even though the local suite is green.

- timestamp: 2026-09-10T00:57:50Z
  checked: GSD runProhibitionEnforcement with a resolved/test prohibition but no check descriptor
  found: The producer returned located false, status unverified, flagged true, and no evidence.
  implication: The missing artifact is specifically a locatable node-test or lint-rule descriptor plus a machine-proven violation fixture; ordinary passing tests cannot authorize green status.

- timestamp: 2026-09-10T00:57:50Z
  checked: Repository search for prohibition check conventions
  found: No GSD_PROHIB_SUBJECT consumer and no check_kind, check_target, check_violation_fixture, or check_clean_fixture exist in Phase 31 scripts or plan metadata.
  implication: There is no negative-test harness that can prove the invariant fails against a known authorizing/mutating implementation and passes against the clean implementation.

- timestamp: 2026-09-10T00:57:50Z
  checked: Spectrum-based fault localization eligibility
  found: The relevant local suite has no failing test; the symptom is a deterministic metadata/enforcement disposition rather than a failing implementation test.
  implication: SBFL is not applicable; working backward from the human_needed disposition directly localized the fault to contract and CI wiring.

- timestamp: 2026-09-27T14:21:39Z
  checked: 31-06-SUMMARY.md, .planning/phases/31-repository-planning-truth/31-VERIFICATION.md, scripts/prohibitions/repository_inventory_report_only.test.cjs, scripts/fixtures/prohibitions/repository_inventory_mutating.cjs, and .github/workflows/ci.yml
  found: PROHIB-REPO-01-SAFETY is resolved with a named test target and bad subject; Phase 31 Plan 09 records 98 passing tests, 6/6 bad/clean prohibition proofs, live planning-health success, and required CI wiring for the suite and smoke.
  implication: This diagnosis describes the earlier missing proof; subsequent implementation resolved it and it can be closed without rerunning its historical UAT.

## Resolution
root_cause: "The immediate human-UAT routing is caused by PROHIB-REPO-01-SAFETY remaining status unresolved with verification null in 31-01-PLAN.md. Its existing no-mutation tests are ordinary local evidence, not a resolved test-tier prohibition with a locatable check descriptor and machine-proven fail-first violation fixture, so GSD correctly fails closed as unverified. Independently, .github/workflows/ci.yml runs only ci_monitor.test.cjs and never runs repository_inventory.test.cjs or the prohibition-enforcement gate, so the invariant has no recurring hosted regression gate."
fix: "Phase 31 Plan 06 resolved the report-only prohibition with a mutating bad subject and repository-inventory clean control. Plan 09 wires it into the six-check enforcement lane and required planning-truth CI contract."
verification: "Validated by 31-06-SUMMARY.md and 31-VERIFICATION.md: the full Phase 31 Node/prohibition suite passed 98/98, the enforcer passed all 6/6 non-vacuous bad/clean checks, live planning health exited healthy, and ci.yml wires the planning-truth lane. Fresh planning health on 2026-09-27 also reports healthy with 0 errors."
oracle_type: specified
files_changed: ["scripts/prohibitions/repository_inventory_report_only.test.cjs", "scripts/fixtures/prohibitions/repository_inventory_mutating.cjs", ".github/workflows/ci.yml", ".planning/phases/31-repository-planning-truth/31-06-SUMMARY.md"]
