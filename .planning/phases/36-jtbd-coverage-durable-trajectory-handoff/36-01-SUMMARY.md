---
phase: 36-jtbd-coverage-durable-trajectory-handoff
plan: 01
subsystem: planning
tags: [jtbd, provenance, navigation, node]
requires:
  - phase: 35-review-ownership-worktree-operations
    provides: bounded contribution and worktree ownership contracts
provides:
  - one canonical JTBD and trajectory record set with 18 stable IDs
  - persona and lifecycle link-only indexes into the canonical IDs
  - injectable read-only validator for canonical fields and index links
affects: [36-02 cross-reference validation, 36-03 handoff]
actuals:
  tokens: 17500
  tasks: 2
  commits: 2
plan_head_before: 1fb0e79db2f2dba7258e9ccfdc68fae0752afc8c
tech-stack:
  added: []
  patterns: [bounded repository reads, stable Markdown anchors, link-only indexes]
key-files:
  created:
    - .planning/JTBD-COVERAGE.md
    - .planning/PERSONAS.md
    - .planning/WORKFLOWS.md
    - scripts/jtbd_coverage.cjs
    - scripts/jtbd_coverage.test.cjs
  modified: []
key-decisions:
  - One canonical file owns mutable JTBD facts; persona and lifecycle files only navigate.
  - Horizon and commitment status are separate fields with dated transition rows.
requirements-completed: [ORIENT-01]
coverage:
  - id: D1
    description: Maintainers can reach each stable JTBD record through either index.
    requirement: ORIENT-01
    verification:
      - kind: unit
        ref: scripts/jtbd_coverage.test.cjs#both indexes resolve one stable JTBD ID to one complete canonical record
        status: pass
      - kind: other
        ref: node scripts/jtbd_coverage.cjs --json
        status: pass
    human_judgment: false
  - id: D2
    description: Each direct, downstream, and future job has explicit source, ownership, proof, freshness, and promotion boundaries.
    requirement: ORIENT-02
    verification:
      - kind: unit
        ref: scripts/jtbd_coverage.test.cjs#dated source paths and accountable/adopter ownership are explicit and surfaced
        status: pass
      - kind: unit
        ref: scripts/jtbd_coverage.test.cjs#future discovery and Accrue source ownership judgments stay bounded until promotion evidence exists
        status: pass
      - kind: other
        ref: node scripts/jtbd_coverage.cjs --json
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-09-26
status: complete
---

# Phase 36 Plan 01: Canonical JTBD Records Summary

**Eighteen stable JTBD records with two link-only navigation views and a bounded read-only validator.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-09-26T20:22:00Z
- **Completed:** 2026-09-26T20:52:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Established one canonical record for each relevant direct, downstream, and future capability job.
- Added persona and lifecycle indexes that each link every stable ID once.
- Added a CLI that reports malformed, duplicate, unsafe, missing, or incomplete records without editing repository state.
- Kept horizon and commitment status independent and retained initial dated rationale and evidence for each record.

## Task Commits

1. **Task 1: Trace one adopter job through both indexes** — `feef4ac`
2. **Task 2: Complete direct, external, candidate, and conditional job coverage** — `9fafb20`

## Files Created/Modified

- `.planning/JTBD-COVERAGE.md` — canonical jobs, source and proof boundaries, controlled trajectory fields, and dated history.
- `.planning/PERSONAS.md` — persona navigation links only.
- `.planning/WORKFLOWS.md` — lifecycle navigation links only.
- `scripts/jtbd_coverage.cjs` — bounded, read-only canonical/index validation.
- `scripts/jtbd_coverage.test.cjs` — valid, malformed, duplicate, unsafe-link, and complete-map fixtures.

## Decisions Made

- One canonical file owns trajectory and decision facts; indexes do not copy mutable fields.
- External Accrue work stays externally owned; support and finance capabilities remain candidates with unknown adopter owners.
- Future capability requirements remain unmapped from committed phases.

## Deviations from Plan

None. The task commits used a separate temporary Git index to avoid touching the pre-staged Phase 35 changes.

## Issues Encountered

The sandbox initially denied Git index writes. The required commits succeeded through the approved permission path, with the pre-existing staged paths preserved. The state helper needed an explicit current-plan position after seeing the summary; that pointer is now at plan 02. The progress helper skipped recalculation because the phase is not yet complete.

## User Setup Required

None.

## Next Phase Readiness

The complete canonical set is ready for Plan 02 cross-reference, history-prefix, and recurring-runtime validation.

## Self-Check: PASSED

- Summary file exists and both task commit hashes resolve.
- Focused validator tests passed and the live 18-record map returned `healthy` with zero diagnostics.

---
*Phase: 36-jtbd-coverage-durable-trajectory-handoff*
*Completed: 2026-09-26*
