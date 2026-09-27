---
status: resolved
trigger: 'Phase 31 UAT gap G-31-3: "Only the documented authority chain and canonical phase directory contribute proof." User requests recurring automated integration/e2e/smoke or CI coverage so no human UAT is required.'
created: 2026-09-10T01:05:33Z
updated: 2026-09-27T14:21:39Z
---

## Current Focus

hypothesis: The diagnosed PROHIB-REPO-02-TRANSPARENCY proof-plumbing gap has been closed by later Phase 31 plans.
test: Compare the original diagnosis with 31-07-SUMMARY.md, the canonical Phase 31 verification, and the current required planning-truth workflow.
expecting: The prohibition is resolved at the test tier; its bad/clean proof and recurring CI wiring are present.
next_action: None — closure recorded; do not repeat the original Phase 31 investigation or UAT.
bug_class: bohrbug

## Symptoms

expected: Only the documented authority chain and canonical phase directory contribute proof, demonstrated by recurring automation with no human verification/UAT required.
actual: Phase verification reports 21/21 observable truths verified but requires human UAT for Test 3 because PROHIB-REPO-02-TRANSPARENCY remains unresolved with verification null.
errors: None reported.
reproduction: Run/review Test 3 in `.planning/phases/31-repository-planning-truth/31-UAT.md` after Phase 31 verification.
started: Discovered during Phase 31 UAT.

## Eliminated

- hypothesis: The production authority resolver currently accepts generated, cached, archived, or decoy artifacts as routing/completion proof.
  evidence: All 37 planning-health tests pass, including phantom-scope, same-basename decoy, body-only status, and canonical-directory ambiguity cases; the live planning-health command exits 0 with the intended Phase 31 scope.
  timestamp: 2026-09-10T01:09:41Z

- hypothesis: Existing recurring CI already runs the Phase 31 planning-health suite, so only verification-report wording is stale.
  evidence: All three GitHub workflows omit `scripts/planning_health.test.cjs`, `scripts/repository_inventory.test.cjs`, and `scripts/planning_health.cjs`; the required CI contract job list contains only test, dialyzer, demo-postgres, package-smoke, and optional-deps.
  timestamp: 2026-09-10T01:09:41Z

- hypothesis: The prohibition intrinsically requires human judgment and cannot be automated.
  evidence: The invariant is already mechanically asserted by deterministic tests, and the GSD prohibition contract explicitly supports `resolved`/`test` prohibitions with wired node-test enforcement.
  timestamp: 2026-09-10T01:09:41Z

## Evidence

- timestamp: 2026-09-10T01:05:33Z
  checked: `.planning/phases/31-repository-planning-truth/31-VERIFICATION.md`
  found: The verifier reports 21/21 truths verified, including D-08 and authority/completion decoy tests, but sets `status: human_needed` solely because six structured prohibitions remain `status: unresolved`, `verification: null`, and `flagged_unverified: true`.
  implication: G-31-3 is not presently an observed authority-chain behavior failure; it is an automation/verification-authority gap.

- timestamp: 2026-09-10T01:05:33Z
  checked: `.planning/phases/31-repository-planning-truth/31-UAT.md`
  found: Test 3 records no runtime error or counterexample; the report asks to shift the invariant into recurring integration/e2e/smoke or CI coverage and eliminate human UAT.
  implication: Diagnosis must identify why automated evidence does not satisfy the prohibition and whether the relevant suite is recurring in CI.

- timestamp: 2026-09-10T01:06:58Z
  checked: Phase 0 knowledge recall
  found: MemPalace and `.planning/debug/knowledge-base.md` are unavailable, so no prior resolved-session candidate can be tested.
  implication: The investigation proceeds from repository evidence; no known-pattern result is being treated as diagnosis.

- timestamp: 2026-09-10T01:06:58Z
  checked: `.planning/phases/31-repository-planning-truth/31-02-PLAN.md`
  found: PROHIB-REPO-02-TRANSPARENCY is explicitly declared `status: unresolved`, `verification: null`, and `flagged_unverified: true`, while Task 1 separately defines and runs an automated authority/phantom/conflict test pattern.
  implication: The plan distinguishes behavioral test evidence from authoritative resolution of its must-NOT contract; passing the former cannot automatically satisfy the latter.

- timestamp: 2026-09-10T01:06:58Z
  checked: `.github/workflows/ci.yml` and workflow command search
  found: Push/PR CI runs `scripts/ci_monitor.test.cjs`, Elixir tests, formatting, Dialyzer, demo PostgreSQL, package smoke, optional-dependency checks, and summary drift, but never invokes `scripts/planning_health.test.cjs`, `scripts/repository_inventory.test.cjs`, or the live `scripts/planning_health.cjs` command.
  implication: Phase 31 authority/completion regressions can pass once locally yet are not enforced on each change; there is no recurring CI proof for G-31-3.

- timestamp: 2026-09-10T01:08:52Z
  checked: `node --test scripts/planning_health.test.cjs`
  found: All 37 tests pass. The suite includes `phantom scope: archives, caches, summaries, and future phase directories are inert`, `canonical completion: same-basename decoys and body-only status remain inert`, and missing/ambiguous canonical-directory cases.
  implication: The current implementation has direct automated regression evidence for the reported invariant; the UAT gap is not reproducible as a current code failure.

- timestamp: 2026-09-10T01:08:52Z
  checked: `scripts/planning_health.test.cjs` test construction and CLI invocation sites
  found: Phantom-scope and canonical-completion cases call evaluator/library functions over in-memory snapshots. The file invokes CLI `main()` only in the interrupted/read-only test; no filesystem-level CLI test combines generated/cache/archive/decoy artifacts with routing and completion assertions.
  implication: A full e2e/CLI regression covering the exact UAT statement is absent even before considering CI scheduling.

- timestamp: 2026-09-10T01:08:52Z
  checked: GSD prohibition verification contract in `prohibition-probe.md` and `probe-core.cjs`
  found: Only a `resolved`/`test` prohibition with a wired `check_*` descriptor, a known-violation fixture, machine-proven fail-first behavior, and a non-vacuous clean pass can dispose green. Unresolved or descriptor-less prohibitions are deliberately flagged and cannot silently pass.
  implication: General passing tests in the verification report are non-authoritative for this prohibition by design; the PLAN item lacks the lifecycle/tier/descriptor data required for automated disposition.

- timestamp: 2026-09-10T01:08:52Z
  checked: Phase 31 plan and repository search for `GSD_PROHIB_SUBJECT` and `check_*` descriptor fields
  found: No prohibition enforcement descriptor, violation fixture, clean fixture, or subject-injection consumer exists for PROHIB-REPO-02-TRANSPARENCY.
  implication: The verifier has no deterministic enforcement target it is allowed to treat as authoritative prohibition proof.

- timestamp: 2026-09-10T01:09:41Z
  checked: `node scripts/planning_health.cjs --json`
  found: The live command exits 0, selects milestone v2.2 / Phase 31 through ROADMAP+STATE, and returns no authority/completion errors.
  implication: Current repository behavior is healthy; the reported gap concerns durable automated proof and verifier disposition, not a live authority-selection defect.

- timestamp: 2026-09-27T14:21:39Z
  checked: 31-07-SUMMARY.md, .planning/phases/31-repository-planning-truth/31-VERIFICATION.md, scripts/prohibitions/planning_authority.test.cjs, scripts/fixtures/prohibitions/planning_phantom_authority.cjs, and .github/workflows/ci.yml
  found: PROHIB-REPO-02-TRANSPARENCY is resolved with a named test target and bad subject; Phase 31 Plan 09 records 98 passing tests, 6/6 bad/clean prohibition proofs, live planning-health success, and required CI wiring for the suite and smoke.
  implication: This diagnosis describes the earlier missing proof; subsequent implementation resolved it and it can be closed without rerunning its historical UAT.

## Resolution
root_cause: "PROHIB-REPO-02-TRANSPARENCY was carried into 31-02-PLAN.md as `status: unresolved`, `verification: null`, and descriptor-less, so GSD's fail-closed prohibition policy cannot treat the otherwise-green behavioral suite as authoritative and emits human_needed. For the requested zero-human recurring guarantee, the repository also lacks a fail-first wired prohibition check and a filesystem/CLI e2e case for the exact decoy matrix, and no push/PR/release workflow or CI-contract dependency runs planning_health tests or the live smoke."
fix: "Phase 31 Plan 07 resolved the authority prohibition with a fail-first subject-driven test and production clean control. Plan 09 wires all six prohibition checks, the Node suite, history guard, live planning-health smoke, and aggregate CI contract."
verification: "Validated by 31-07-SUMMARY.md and 31-VERIFICATION.md: the full Phase 31 Node/prohibition suite passed 98/98, the enforcer passed all 6/6 non-vacuous bad/clean checks, live planning health exited healthy, and ci.yml wires the planning-truth lane. Fresh planning health on 2026-09-27 also reports healthy with 0 errors."
oracle_type: specified
files_changed: ["scripts/prohibitions/planning_authority.test.cjs", "scripts/fixtures/prohibitions/planning_phantom_authority.cjs", ".github/workflows/ci.yml", ".planning/phases/31-repository-planning-truth/31-07-SUMMARY.md"]
