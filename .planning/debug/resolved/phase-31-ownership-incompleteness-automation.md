---
status: resolved
trigger: "Phase 31 UAT gap G-31-2: integration/e2e/smoke automate the world devops mindset goal 0 human verification/uat required"
created: 2026-09-10T01:00:38Z
updated: 2026-09-27T14:21:39Z
---

## Current Focus

hypothesis: The diagnosed PROHIB-REPO-01-TRANSPARENCY proof-plumbing gap has been closed by later Phase 31 plans.
test: Compare the original diagnosis with 31-06-SUMMARY.md, the canonical Phase 31 verification, and the current required planning-truth workflow.
expecting: The prohibition is resolved at the test tier; its bad/clean proof and recurring CI wiring are present.
next_action: None — closure recorded; do not repeat the original Phase 31 investigation or UAT.
bug_class: bohrbug

## Symptoms

expected: Unsupported ownership stays unknown and incomplete observation is visibly incomplete.
actual: Test 2 is routed to human UAT; user requests recurring integration/e2e/smoke automation and zero human verification for this machine-testable invariant.
errors: None reported.
reproduction: Run/review Test 2 in Phase 31 UAT.
started: Discovered during Phase 31 UAT.

## Evidence

- timestamp: 2026-09-10T01:00:38Z
  checked: Phase 31 UAT and verification frontmatter
  found: UAT Test 2 is generated because PROHIB-REPO-01-TRANSPARENCY remains unresolved with verification null, even though the verification report separately marks D-03 and D-04 behavior verified.
  implication: The immediate human-UAT trigger is unresolved prohibition traceability, not a reported runtime failure.

- timestamp: 2026-09-10T01:02:00Z
  checked: Phase 31 Plan 31-01 prohibition and verification contract
  found: PROHIB-REPO-01-TRANSPARENCY was authored as status unresolved, verification null, and flagged_unverified true; the plan's automated acceptance commands target D-01 through D-05 but do not assign a verification reference to the prohibition.
  implication: The verifier correctly preserves the explicit unresolved tier instead of inferring approval from adjacent truth coverage.

- timestamp: 2026-09-10T01:03:00Z
  checked: Phase 31 validation and summary coverage
  found: 31-VALIDATION.md declares all phase behaviors automated and records `node --test scripts/repository_inventory.test.cjs` as green; 31-01-SUMMARY.md records human_judgment false and integration/unit evidence for unknown, stale, ambiguous, malformed, unreadable, and bounded state.
  implication: Automated evidence exists, but it is represented in summary/validation records rather than attached to the structured prohibition that controls human escalation.

- timestamp: 2026-09-10T01:04:00Z
  checked: Live repository inventory test suite
  found: `node --test scripts/repository_inventory.test.cjs` passed 17/17, including unknown ownership, invalid/unsafe ownership sources, bounded/null incomplete collection, human/JSON parity, and read-only behavior.
  implication: No current implementation failure reproduces; the UAT gap concerns durable automation and proof authority.

- timestamp: 2026-09-10T01:05:00Z
  checked: Required GitHub Actions CI workflow and repository-wide command references
  found: `.github/workflows/ci.yml` runs `node --test scripts/ci_monitor.test.cjs` and `mix test`, but never runs `scripts/repository_inventory.test.cjs` or the documented full command `node --test scripts/*.test.cjs`; no non-planning CI entry point references the inventory suite.
  implication: A push or pull request can pass required CI without executing ownership/incompleteness regressions.

- timestamp: 2026-09-10T01:06:00Z
  checked: Direct stale-claim behavior and static test assertions
  found: A direct evaluator/render probe produced disposition state stale, diagnostic RINV_STALE_CLAIM, human-visible policy-error, and exit 1; however, repository_inventory.test.cjs contains no explicit RINV_STALE_CLAIM/stale assertion.
  implication: The implementation currently handles stale claims, but that specific prohibition branch can regress even after the existing suite is wired into CI.

- timestamp: 2026-09-10T01:07:00Z
  checked: Spectrum-based fault localization eligibility and bug-pattern scan
  found: There is no failing automated test and no per-test coverage spectrum; SBFL is inapplicable. The deterministic mismatch is a config/metadata proof-gate problem, not an async, state, or runtime data-shape failure.
  implication: Working backward from the human_needed gate is the appropriate localization method.

## Eliminated

- hypothesis: "The inventory implementation currently infers unsupported ownership or hides incomplete collection."
  evidence: "17/17 tests passed, unsafe registry fixtures retain owner unknown and incomplete status, and the direct stale probe rendered a blocking RINV_STALE_CLAIM policy error."
  timestamp: 2026-09-10T01:06:00Z

- hypothesis: "No automated behavioral coverage exists for ownership or incomplete collection."
  evidence: "The dedicated integration suite and Phase 31 validation map exercise those behaviors; the defect is that CI and prohibition metadata do not consume that evidence, plus stale claims lack a direct regression assertion."
  timestamp: 2026-09-10T01:07:00Z

- timestamp: 2026-09-27T14:21:39Z
  checked: 31-06-SUMMARY.md, .planning/phases/31-repository-planning-truth/31-VERIFICATION.md, scripts/prohibitions/repository_inventory_transparency.test.cjs, scripts/fixtures/prohibitions/repository_inventory_inference.cjs, and .github/workflows/ci.yml
  found: PROHIB-REPO-01-TRANSPARENCY is resolved with a named test target and bad subject; Phase 31 Plan 09 records 98 passing tests, 6/6 bad/clean prohibition proofs, live planning-health success, and required CI wiring for the suite and smoke.
  implication: This diagnosis describes the earlier missing proof; subsequent implementation resolved it and it can be closed without rerunning its historical UAT.

## Resolution
root_cause: "PROHIB-REPO-01-TRANSPARENCY remains explicitly unresolved with verification null, so the verifier must route it to human UAT despite adjacent automated evidence; additionally, required CI never invokes the repository inventory integration suite, and that suite lacks a direct stale-claim regression assertion, so the full inferred/stale/unsupported/partial matrix has no recurring authoritative gate."
fix: "Phase 31 Plan 06 resolved the ownership/transparency prohibition with bad inference and clean-control subjects plus human/JSON CLI coverage. Plan 09 wires it into the six-check enforcement lane and required planning-truth CI contract."
verification: "Validated by 31-06-SUMMARY.md and 31-VERIFICATION.md: the full Phase 31 Node/prohibition suite passed 98/98, the enforcer passed all 6/6 non-vacuous bad/clean checks, live planning health exited healthy, and ci.yml wires the planning-truth lane. Fresh planning health on 2026-09-27 also reports healthy with 0 errors."
oracle_type: specified
files_changed: ["scripts/prohibitions/repository_inventory_transparency.test.cjs", "scripts/fixtures/prohibitions/repository_inventory_inference.cjs", ".github/workflows/ci.yml", ".planning/phases/31-repository-planning-truth/31-06-SUMMARY.md"]
