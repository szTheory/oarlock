---
phase: 31-repository-planning-truth
fixed_at: 2026-09-10T05:36:29Z
review_path: $HOME/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md
iteration: 3
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 31: Code Review Fix Report

**Fixed at:** 2026-09-10T05:36:29Z
**Source review:** `$HOME/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Duplicate STATE routing fields silently select the last value

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** d0747fe
**Applied fix:** Reads every `milestone` and `current_phase` declaration, requires exactly one non-empty value for each, and blocks missing, duplicate-equal, and conflicting declarations without selecting an ordering winner. Added both-order and duplicate-equal regressions. Status: fixed; requires human verification.

### CR-02: Committed scope is taken from the first versioned section, not the active milestone

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** f115fd7
**Applied fix:** Binds committed requirement parsing to the uniquely active ROADMAP milestone, requires exactly one matching requirements section and one traceability section, and propagates ambiguity diagnostics into authority and completion validation. Added active-section and duplicate-section regressions. Status: fixed; requires human verification.

### CR-03: Duplicate plan checklist entries reuse one artifact as multiple completed plans

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 2fabd74
**Applied fix:** Rejects repeated plan filenames, parses the declared executed/total counts, and validates those totals against the unique checklist. Added identical and checked/unchecked duplicate regressions. Status: fixed; requires human verification.

### CR-04: Milestone history ignores names, shipment dates, and contradictory duplicate metadata

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commits:** 4f37b2c, cc8781c
**Applied fix:** Preserves duplicate milestone blocks and field values, requires one canonical block and one value per required field, compares milestone names and calendar-valid shipment dates with ROADMAP, and rejects competing status/identity/archive metadata. Supports both canonical date-heading forms already present in repository history. Added name, date, invalid-date, duplicate-block, and competing-status regressions. Status: fixed; requires human verification.

### WR-01: A claim expires at midnight on its own revisit date

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/repository_inventory.test.cjs`
**Commit:** 2bb9f4c
**Applied fix:** Treats a revisit date as valid through the end of that UTC calendar day and marks it stale at the next day's boundary. Added before, during, end-of-day, and after-boundary regressions. Status: fixed; requires human verification.

## Verification

Verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- Tier 1 source re-reads and CommonJS syntax checks passed for every modified section.
- Focused regression tests passed for each finding.
- `node --test scripts/planning_health.test.cjs scripts/repository_inventory.test.cjs`: 83 passed, 0 failed.
- `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`: 128 passed, 0 failed.
- `node scripts/prohibitions/enforce_phase31.cjs`: 6/6 prohibition contracts passed.
- Source and test changes are committed; this report remains uncommitted for the orchestrator.

---

_Fixed: 2026-09-10T05:36:29Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
