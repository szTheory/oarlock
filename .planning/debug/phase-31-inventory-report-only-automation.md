---
status: diagnosed
trigger: "Phase 31 UAT gap G-31-1: All actions remain report-only proposals; determine why this truth still requires human UAT and what automated coverage/CI wiring is missing."
created: 2026-09-10T00:55:03Z
updated: 2026-09-10T00:57:50Z
---

## Current Focus

bug_class: bohrbug
hypothesis: Confirmed — the plan's unresolved/null prohibition metadata gives the verifier no authoritative automated disposition, and the repository supplies neither a fail-first wired prohibition check nor recurring CI execution of the inventory suite.
test: Completed by running the local suite, exercising dispositionForProhibition and runProhibitionEnforcement, and inspecting all GitHub Actions node-test commands.
expecting: Confirmed — local behavior passes, absent enforcement remains flagged unverified, and hosted CI omits the suite.
next_action: Return diagnose-only root cause and suggest wiring a resolved test-tier negative check plus CI gate.
reasoning_checkpoint:
  hypothesis: "PROHIB-REPO-01-SAFETY routes to human UAT because its plan item is unresolved with verification null; no machine-proven fail-first check can green it, and CI does not execute its behavioral suite."
  confirming_evidence:
    - "Current plan lines 57-64 contain unresolved/null metadata and no check descriptor."
    - "The enforcement producer returned located false and flagged unverified for a hypothetical resolved/test item with no descriptor."
    - "CI runs only ci_monitor.test.cjs while the inventory suite passes 17/17 locally."
  falsification_test: "A resolved/test prohibition with a valid check descriptor, known-bad fixture that goes red, clean run that goes green, and a CI invocation of that gate would falsify this diagnosis. None exists."
  fix_rationale: "A subject-injectable negative test supplies authoritative fail-first evidence; CI execution makes that evidence recurring rather than a one-time local verification."
  blind_spots: "Hosted branch-protection/ruleset configuration is external and was not inspected; repository CI nevertheless lacks the required command."
  candidate_causes:
    - "config: 31-01-PLAN.md leaves the safety prohibition unresolved/null and omits its flat wired-check descriptor."
    - "code/test: repository_inventory.test.cjs has ordinary no-mutation coverage but no GSD_PROHIB_SUBJECT-compatible known-bad/clean prohibition harness."
    - "environment/CI: .github/workflows/ci.yml never invokes the Phase 31 inventory tests or prohibition-enforcement gate."
  and_gate: "No for the immediate human_needed status: unresolved/null metadata alone is sufficient. Yes for the requested zero-human recurring guarantee: authoritative fail-first enforcement and CI execution are both required."

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

## Resolution

root_cause: "The immediate human-UAT routing is caused by PROHIB-REPO-01-SAFETY remaining status unresolved with verification null in 31-01-PLAN.md. Its existing no-mutation tests are ordinary local evidence, not a resolved test-tier prohibition with a locatable check descriptor and machine-proven fail-first violation fixture, so GSD correctly fails closed as unverified. Independently, .github/workflows/ci.yml runs only ci_monitor.test.cjs and never runs repository_inventory.test.cjs or the prohibition-enforcement gate, so the invariant has no recurring hosted regression gate."
fix: "Not applied (diagnose-only). Suggested direction: author a dedicated subject-injectable negative test with known-bad and preferably clean fixtures; resolve the prohibition as test-tier with check_kind/check_target/check_violation_fixture/check_clean_fixture; invoke the enforcement check and Phase 31 Node suite in required CI."
verification: "Diagnosis reproduced: inventory suite 17/17 passes locally; disposition helper flags current unresolved item; enforcement producer flags even resolved/test when descriptor is absent; workflow search finds no Phase 31 test command."
files_changed: []
