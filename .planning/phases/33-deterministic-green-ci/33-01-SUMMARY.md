---
phase: 33-deterministic-green-ci
plan: 01
subsystem: ci
tags: [github-actions, exact-sha, artifacts, node-test]
requires: []
provides:
  - "Strict run-attempt CI proof JSON with exact event identity, toolchain, lockfile hashes, and required job results"
  - "Exact-SHA monitor validation of hosted jobs and their retained proof artifact"
affects: [phase-33-ci-quality, phase-33-hosted-acceptance]
actuals:
  tokens: 7800
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: ["Allowlisted proof schema with fail-closed validation", "Attempt-specific artifact and hosted-run identity matching"]
key-files:
  created: [scripts/ci_proof.cjs, scripts/ci_proof.test.cjs]
  modified: [.github/workflows/ci.yml, scripts/ci_monitor.cjs, scripts/ci_monitor.test.cjs]
key-decisions:
  - "Keep the pull-request event tested SHA separate from the source head SHA and require the checkout to match the tested SHA."
  - "Bind hosted monitoring to the exact run attempt and require its retained proof artifact."
requirements-completed: [CI-05, CI-04]
coverage:
  - id: D1
    description: "A failed required lane still produces a valid, explicitly unverified proof document."
    requirement: CI-05
    verification:
      - kind: unit
        ref: scripts/ci_proof.test.cjs#workflow CLI writes a valid proof before returning dependency failure
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact-SHA monitor accepts only a matching hosted run, job set, attempt, and proof artifact."
    requirement: CI-04
    verification:
      - kind: unit
        ref: scripts/ci_monitor.test.cjs#assert-ci rejects missing, mismatched, or failed proof artifacts
        status: pass
    human_judgment: false
duration: 40min
completed: 2026-09-23
status: complete
---

# Phase 33: Deterministic Green CI — Plan 01 Summary

**Exact-SHA CI proof artifact creation and hosted monitor verification**

## Performance

- **Duration:** 40 min
- **Started:** 2026-09-23
- **Completed:** 2026-09-23
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a proof writer that binds the tested SHA, source head SHA, run attempt, toolchain, root and demo lockfile digests, and all required lane results.
- Changed the aggregate to check out the tested event SHA, write proof before failing on unsuccessful dependencies, and upload it under a run-attempt-specific artifact name.
- Extended the exact-SHA monitor to download the proof from the selected run attempt and compare its schema, identity, and lane results with hosted job evidence.

## Task Commits

1. **Task 1: Carry an existing CI lane through the aggregate into a retained exact-SHA proof** — `08ece53`
2. **Task 2: Require the matching artifact in exact-SHA hosted monitoring** — `e2629e7`
3. **Follow-up: reject all-zero SHA identities** — `c5a5802`

Plan metadata will be committed with this summary.

## Files Created/Modified

- `scripts/ci_proof.cjs` — proof creation and strict validation.
- `scripts/ci_proof.test.cjs` — schema, identity, failed-lane, and CLI contract tests.
- `.github/workflows/ci.yml` — aggregate checkout, toolchain capture, proof artifact upload, and run-summary link.
- `scripts/ci_monitor.cjs` — exact-run artifact retrieval and comparison.
- `scripts/ci_monitor.test.cjs` — artifact mismatch and transport fixtures.

## Decisions Made

- Used the signed `actions/upload-artifact` v7.0.1 release pinned to full commit `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`.
- Represented absent required dependencies as `missing` and kept the proof artifact schema allowlisted.

## Deviations from Plan

**1. [Rule 1 - Bug] Reject all-zero SHA identities.** The first validator implementation checked the concatenated SHA values and could miss one all-zero identity when another identity was nonzero. Added an individual check and regression assertion.

- **Found during:** Task 1
- **Files modified:** `scripts/ci_proof.cjs`, `scripts/ci_proof.test.cjs`
- **Verification:** Focused suites passed (21/21).
- **Committed in:** `c5a5802`

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Closes a fail-closed identity validation edge case.

## Issues Encountered

- Hex and GitHub hosted APIs are unavailable from the local shell due DNS resolution failure; hosted acceptance remains for later plans.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The proof pipeline is ready for the added quality lane. Credo registry metadata is confirmed through current official Hex and Credo documentation, but local `mix hex.info credo` cannot resolve `hex.pm`; dependency resolution is blocked until registry access returns.

---
*Phase: 33-deterministic-green-ci*
*Completed: 2026-09-23*
