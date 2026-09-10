---
phase: 31-repository-planning-truth
plan: "09"
subsystem: ci
tags: [github-actions, planning-truth, exact-sha, prohibitions, tap]
requires:
  - phase: 31-06
    provides: repository inventory safety and transparency prohibition fixtures
  - phase: 31-07
    provides: planning authority and repair-safety prohibition fixtures
  - phase: 31-08
    provides: cross-revision history and milestone identity prohibition fixtures
provides:
  - required planning-truth CI lane for push/main and pull requests
  - descriptor-driven non-vacuous bad/clean proof for all six Phase 31 prohibitions
  - exact-SHA hosted monitor and aggregate proof dependency on planning truth
affects: [phase-32, phase-33, phase-34, release-readiness]
tech-stack:
  added: []
  patterns: [bounded argument-array subprocesses, fail-closed descriptor validation, exact-SHA aggregate evidence]
key-files:
  created:
    - scripts/prohibitions/enforce_phase31.cjs
    - scripts/prohibitions/enforce_phase31.test.cjs
  modified:
    - .github/workflows/ci.yml
    - scripts/ci_monitor.cjs
    - scripts/ci_monitor.test.cjs
key-decisions:
  - "Treat the six Phase 31 prohibition descriptors as untrusted repository input and require exact IDs, resolved/test metadata, and safe regular-file targets before execution."
  - "Accept a bad fixture only when Node TAP reports a named failure for its stable prohibition ID; process crashes and unrelated failures are not proof."
  - "Fetch existing historical tags in ephemeral CI, assert the known tag set, and fail if v1.5 unexpectedly appears rather than creating or guessing that identity."
  - "Require planning truth by both workflow job ID in ci-contract and display name in the exact-SHA hosted monitor."
patterns-established:
  - "Recurring prohibition proof: validated plan descriptor -> bounded bad TAP red -> bounded clean TAP green."
  - "Planning history CI: full checkout -> explicit tag provisioning -> event-derived base/head validation -> history guard -> live planning-health JSON."
requirements-completed: [REPO-01, REPO-02, REPO-03, REPO-04]
status: complete
actuals:
  tokens: 5986
  tasks: 2
  commits: 5
duration: 18min
completed: 2026-09-09
---

# Phase 31 Plan 09: Repository & Planning Truth CI Summary

**A required exact-SHA planning-truth lane now validates all six Phase 31 prohibition descriptors, proves named non-vacuous bad/clean behavior, guards committed history, and runs live planning health.**

## Performance

- **Duration:** 18 minutes
- **Started:** 2026-09-10T02:58:00Z
- **Completed:** 2026-09-10T03:16:28Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added the `planning-truth`/`planning truth` GitHub Actions lane with full history, explicit historical tag fetch/assertion, event-specific fail-closed base selection, complete Node proof, cross-revision guard, and live JSON health smoke.
- Added a dependency-free descriptor enforcer that requires exactly the six stable Phase 31 IDs and validates status, verification kind, repository containment, and target/fixture file existence.
- Proved each violation fixture produces a named TAP red and each clean control produces a named, non-vacuous TAP green; malformed descriptors, missing paths, crash-only reds, toothless bad fixtures, and failing clean controls all fail closed.
- Bound planning truth into both the always-running `ci-contract` aggregate evidence and `DEFAULT_REQUIRED_JOBS`, retaining exact head-SHA selection and wrong-SHA rejection.

## Task Commits

Each task was committed atomically with explicit TDD red/green gates:

1. **Task 1: Run Phase 31 proof and live smoke in a required planning-truth lane**
   - `433157f` — `test(31-09): add failing planning truth contract tests`
   - `0733c28` — `feat(31-09): add required planning truth lane`
2. **Task 2: Bind planning truth into aggregate and exact-SHA hosted proof**
   - `71839f0` — `test(31-09): add failing aggregate planning truth tests`
   - `8c02ecf` — `feat(31-09): bind planning truth to exact-SHA CI proof`
3. **Diff hygiene:** `53bb782` — `style(31-09): normalize enforcement file endings`

## Files Created/Modified

- `scripts/prohibitions/enforce_phase31.cjs` — Validates the six stable descriptors and executes bounded bad/clean Node TAP proofs.
- `scripts/prohibitions/enforce_phase31.test.cjs` — Covers the happy path and all required fail-closed descriptor/fixture/TAP cases.
- `.github/workflows/ci.yml` — Adds the required planning-truth lane and aggregate dependency/evidence.
- `scripts/ci_monitor.cjs` — Requires the `planning truth` display job for exact-SHA success.
- `scripts/ci_monitor.test.cjs` — Proves workflow structure, exact job naming, missing/failed planning truth rejection, and wrong-SHA isolation.

## Decisions Made

- Descriptor execution is repository-contained and dependency-free; no YAML package or shell interpolation was added.
- A failing process is insufficient prohibition proof unless TAP reports a non-zero test count and a named failure containing the stable descriptor ID.
- CI fetches actual remote tag refs and explicitly verifies v1.5 remains absent; planning health continues to report its identity as unknown.
- The broader Phase 33 CI redesign remains out of scope. This plan adds only the recurring Phase 31 truth contract.
- No hosted-green claim is made here: local exact-SHA contract behavior is proven, while hosted proof awaits an actual GitHub Actions run for the pushed candidate SHA.

## Verification

- `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` — 98 tests passed, 0 failed.
- `node scripts/prohibitions/enforce_phase31.cjs` — all 6/6 bad/clean descriptor proofs passed.
- `node scripts/history_integrity.cjs --base 91f892b4422d37f022ecba4b6dc2b9e68c581b5a --head 53bb782682db6c638cf983a1ca99d3daf51f55fa` — healthy.
- `node scripts/planning_health.cjs --json` — healthy, exit 0, with only the already documented warnings/unknowns.
- `DEFAULT_REQUIRED_JOBS` contains `planning truth`, and monitor tests reject missing, failed, and wrong-SHA evidence.
- `git diff --check` passed after the file-ending hygiene commit.

## TDD Gate Compliance

- RED and GREEN commits exist in order for both explicit `tdd="true"` tasks.
- The tracer verification gate passed before Task 2 expansion.

## Deviations from Plan

None - plan executed exactly as written. The trailing-file-ending cleanup was a non-behavioral hygiene commit discovered by final `git diff --check`.

## Known Stubs

None. The changed files contain no placeholder behavior, skipped tests, or unwired mock data.

## Issues Encountered

None.

## User Setup Required

None. No secrets, dependencies, or external configuration were added.

## Next Phase Readiness

- Phase 31 now has recurring local and CI-defined automation for all six gap IDs and no human-needed prohibition proof.
- Hosted exact-SHA green evidence must still come from the first actual push or pull-request run; this plan intentionally does not fabricate that external evidence.

## Self-Check: PASSED

- All five changed production/test artifacts and this summary exist on disk.
- All five task/TDD/hygiene commits are present in Git history.
- Final cross-revision history verification passed against the realized implementation HEAD.
