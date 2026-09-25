---
phase: 31-repository-planning-truth
plan: "01"
subsystem: repository-operations
tags: [git-porcelain, worktrees, node-test, diagnostics, read-only]

requires:
  - phase: 30-demo-handoff-proof
    provides: Shipped repository baseline and current planning state
provides:
  - Read-only inventory of the main and every Git-registered linked worktree
  - Shared normalized facts, dispositions, diagnostics, renderers, and exit policy
  - Versioned evidence-backed ownership and intentional-exception registry
affects: [31-02-planning-health, 31-03-milestone-history, phase-35-worktree-operations]

actuals:
  tokens: 12173
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns: [dependency-free CommonJS CLI, NUL-delimited Git porcelain, collect-evaluate-render pipeline, node:test temporary repositories]

key-files:
  created:
    - scripts/lib/repository_truth.cjs
    - scripts/repository_inventory.cjs
    - scripts/repository_inventory.test.cjs
    - .planning/repository-ownership.json
  modified: []

key-decisions:
  - "Observed Git and process facts remain immutable inputs; ownership claims create separate dispositions and diagnostics."
  - "Dirty-path selectors are exact by worktree role and relative path, while worktree hazards require an exact absolute registered path."
  - "Git inspection uses a command allowlist, argument arrays, bounded buffers, GIT_OPTIONAL_LOCKS=0, and prune only with --dry-run."
  - "Policy errors exit 1; unreadable, malformed, bounded, or otherwise incomplete collection exits 2."

patterns-established:
  - "Collect once, evaluate once, render twice: human and JSON views never recollect or reclassify."
  - "Repository diagnostics are stable actionable RINV_* records sorted with deterministic tie-breakers."
  - "Ownership never follows from age, path, branch, or PID; unsupported and overlapping claims fail closed."

requirements-completed: [REPO-01]

coverage:
  - id: D1
    description: "One read-only CLI reports all registered worktrees, dirty paths, divergence, locks, process evidence, ownership, and proposed dispositions."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/repository_inventory.test.cjs#all worktrees: collector preserves spaces, newlines, detached state, locks, and process evidence"
        status: pass
      - kind: integration
        ref: "scripts/repository_inventory.test.cjs#read-only: both CLI formats preserve repository bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: "Human and deterministic JSON output preserve the same normalized facts, dispositions, diagnostic codes, and conclusion."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/repository_inventory.test.cjs#tracer: one evaluated inventory drives human and JSON truth"
        status: pass
      - kind: unit
        ref: "scripts/repository_inventory.test.cjs#deterministic: repeated collection and both renderers retain ordered conclusions"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unknown, stale, ambiguous, malformed, unreadable, and bounded state fails closed without granting mutation authority."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/repository_inventory.test.cjs#edge policy and hostile paths tests"
        status: pass
      - kind: other
        ref: "node --test scripts/repository_inventory.test.cjs (14/14 passing)"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-09-09
status: complete
---

# Phase 31 Plan 01: Read-Only Repository Inventory Summary

**Dependency-free Git inventory with NUL-safe all-worktree collection, evidence-backed dispositions, stable diagnostics, and byte-preserving human/JSON reports**

## Performance

- **Duration:** 18 min
- **Started:** 2026-09-09T18:43:00Z
- **Completed:** 2026-09-09T19:01:00Z
- **Tasks:** 2
- **Files modified:** 4 implementation artifacts

## Accomplishments

- Added one normalized repository snapshot that inventories the main worktree and every Git-registered linked, detached, locked, or prunable record without whitespace corruption.
- Kept observed facts structurally separate from exact, evidence-backed ownership claims and proposed dispositions, with unknown, stale, ambiguous, and incomplete state failing closed.
- Proved both renderers preserve the same conclusions and that human output escapes terminal controls while JSON retains raw facts.
- Proved both CLI formats leave refs, index contents, tracked/untracked contents, and worktree administrative bytes unchanged.

## Task Commits

Each task was committed with explicit TDD gates:

1. **Task 1 RED: inventory tracer specification** - `35dff08` (test)
2. **Task 1 GREEN: normalized read-only inventory** - `331123c` (feat)
3. **Task 2 RED: all-worktree and hostile-edge specification** - `dc6474c` (test)
4. **Task 2 GREEN: complete worktree expansion and fail-closed policy** - `26ebdbb` (feat)

## Files Created/Modified

- `scripts/lib/repository_truth.cjs` - Git/process collection, porcelain parsing, registry validation, classification, stable diagnostics, renderers, and exit policy.
- `scripts/repository_inventory.cjs` - Thin report-only CLI with `--json`, `--help`, bounded registry reading, and explicit exit meanings.
- `scripts/repository_inventory.test.cjs` - Temporary-repository, all-worktree, hostile-path, parity, determinism, and no-mutation proof.
- `.planning/repository-ownership.json` - Versioned exact claims for the three planning-documented user-owned paths, with provenance, confidence, and finite revisit dates.

## Decisions Made

- Worktree status comes from `git worktree list --porcelain -z` plus per-tree `status --porcelain=v2 --branch -z`; prune evidence is observation-only via `--dry-run --verbose`.
- Lock/process, divergence, prunable, and dirty-path evidence stays under facts. Registry matches add dispositions but never rewrite observations.
- Exact selector collisions block instead of merging or selecting by file order; empty dirty state and an empty registry remain valid.
- Collection commands disable Git optional locks and use bounded buffers, argument arrays, and a narrow read-only allowlist.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Task 1 GREEN run exposed macOS `/var` versus `/private/var` canonical path aliases. The test was corrected to compare Git's canonical filesystem identity.
- The initial Task 2 RED assertions passed unexpectedly because they did not require behavior beyond the tracer. The RED gate was strengthened to require recorded dry-run prune evidence before implementation continued.

## User Setup Required

None - no external service configuration or dependency installation is required.

## Next Phase Readiness

- Plan 31-02 can reuse `makeDiagnostic`, the normalized fact/disposition separation, stable ordering, renderers, and exit taxonomy for planning-health checks.
- The live repository intentionally remains non-healthy until all observed `.gsd/`, milestone-lock, divergence, and linked-worktree lock state receives evidence-backed disposition; the inventory reports these hazards and does not alter them.

## Self-Check: PASSED

All four implementation artifacts and this summary exist, and all four task commit hashes are present in Git history.

---
*Phase: 31-repository-planning-truth*
*Completed: 2026-09-09*
