---
phase: 36-jtbd-coverage-durable-trajectory-handoff
plan: 02
subsystem: planning
tags: [jtbd, provenance, history, ci]
requires:
  - phase: 36-jtbd-coverage-durable-trajectory-handoff
    plan: 01
    provides: canonical JTBD records and navigation indexes
provides:
  - bounded cross-link validation against requirement, roadmap, evidence, backlog, phase, and milestone authorities
  - base/head append-only JTBD status-history enforcement
  - planning-truth CI smoke with fixture contract
affects: [36-03 handoff and candidate closeout]
actuals:
  tokens: 24000
  tasks: 2
  commits: 2
plan_head_before: 9fafb200d05364eedd02d3c11153bd1b002b12c7
tech-stack:
  added: []
  patterns: [bounded no-follow references, stable diagnostics, immutable transition prefixes]
key-files:
  created: []
  modified:
    - .planning/JTBD-COVERAGE.md
    - scripts/jtbd_coverage.cjs
    - scripts/jtbd_coverage.test.cjs
    - scripts/history_integrity.cjs
    - scripts/history_integrity.test.cjs
    - .github/workflows/ci.yml
    - scripts/ci_workflow_contract.test.cjs
key-decisions:
  - Integrate the map check after the existing planning-health smoke in the required planning-truth job; the complete-map runtime was 53.06 ms median and 71.03 ms maximum over five runs.
  - Keep evidence classes, identities, and caveats explicit while preserving every existing transition row byte-for-byte.
requirements-completed: [ORIENT-02, ORIENT-03, ORIENT-04, ORIENT-05]
coverage:
  - id: D1
    description: Canonical requirement, phase, evidence, backlog, and milestone links resolve through their owning sources.
    requirement: ORIENT-05
    verification:
      - kind: unit
        ref: scripts/jtbd_coverage.test.cjs#future, evidence, and backlog identities cannot contradict their owning authorities
        status: pass
      - kind: other
        ref: node scripts/jtbd_coverage.cjs --json
        status: pass
    human_judgment: false
  - id: D2
    description: Existing transitions stay byte-identical and valid dated status changes append with continuous prior state.
    requirement: ORIENT-04
    verification:
      - kind: unit
        ref: scripts/history_integrity.test.cjs#JTBD history
        status: pass
    human_judgment: false
  - id: D3
    description: Measured runtime and distinct recurring drift risk justify inclusion in the required planning lane.
    requirement: ORIENT-05
    verification:
      - kind: unit
        ref: scripts/ci_workflow_contract.test.cjs#every CI-01 proof has an executable step in a required aggregate dependency
        status: pass
    human_judgment: false
duration: 23min
completed: 2026-09-26
status: complete
---

# Phase 36 Plan 02: Cross-Link and History Validation Summary

**The 18-record map now validates its authority links, preserves decision history, and runs in the required planning-truth CI lane.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-09-26T20:58:00Z
- **Completed:** 2026-09-26T21:21:08Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added source-linked validation for committed and future requirements, roadmap phases and phase directories, evidence paths and identities, backlog references, proof classes, and milestone archive identities.
- Added explicit evidence class, identity, and caveat fields to all canonical records without rewriting prior status-history rows.
- Extended base/head history inspection to reject deleted, rewritten, reordered, invalid, or discontinuous JTBD transitions.
- Measured five complete CLI runs before editing CI: median 53.06 ms, maximum 71.03 ms. The recurring check prevents later planning edits from orphaning or misclassifying linked job evidence; maintenance remains the existing CLI plus its fixture suite.
- Added the live check next to planning health in the required `planning-truth` job. Its Node fixture remains covered by the existing test glob and aggregate dependency.

## Task Commits

1. **Task 1: Diagnose full traceability and enforce decision-preserving history** — `27971a3`
2. **Task 2: Measure recurring value and integrate the map check** — `7ec75b0`

## Files Created/Modified

- `.planning/JTBD-COVERAGE.md` — explicit proof identity, class, and caveat for each record.
- `scripts/jtbd_coverage.cjs` and `scripts/jtbd_coverage.test.cjs` — bounded authority checks and negative fixtures.
- `scripts/history_integrity.cjs` and `scripts/history_integrity.test.cjs` — immutable transition-prefix comparison and append fixtures.
- `.github/workflows/ci.yml` and `scripts/ci_workflow_contract.test.cjs` — required planning-lane invocation and workflow contract.

## Decisions Made

- The check earns recurring CI time at its measured cost and protects a distinct drift surface that local-only runs could miss.
- Current evidence fields identify the artifact and limits; an historical caveat does not itself misclassify the artifact as historical-only proof.

## Deviations from Plan

None. Scoped commits were prepared from clean HEAD-derived files in an alternate Git index so pre-existing staged and unstaged work stayed untouched.

## Issues Encountered

The working tree contains unrelated staged and unstaged project changes. They remain untouched; Plan 03 must use only the Phase 36 manifest when building its independent candidate.

## User Setup Required

None.

## Next Phase Readiness

Plan 03 can capture the actual worktree and exact proof caveats, then attempt an independent-clone candidate and hosted evidence. Existing dirty and locked worktree state must be reported accurately.

## Self-Check: PASSED

- Both task commit hashes resolve.
- `node --test scripts/ci_workflow_contract.test.cjs scripts/jtbd_coverage.test.cjs scripts/history_integrity.test.cjs` passed all 41 tests.
- `node scripts/jtbd_coverage.cjs --json` returned `healthy` for all 18 records with zero diagnostics.

---
*Phase: 36-jtbd-coverage-durable-trajectory-handoff*
*Completed: 2026-09-26*
