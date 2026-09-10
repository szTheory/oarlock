---
phase: 31-repository-planning-truth
fixed_at: 2026-09-10T04:28:27Z
review_path: /Users/jon/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md
iteration: 2
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 31: Code Review Fix Report

**Fixed at:** 2026-09-10T04:28:27Z
**Source review:** `/Users/jon/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Completed requirements omitted from the ROADMAP phase escape all proof checks

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** a8f7608
**Applied fix:** Validates unique committed requirement and traceability rows before constructing lookup maps, requires one trace row per committed requirement, and requires every requirement traced to Phase 31 to occur exactly once in that ROADMAP phase. Added omission and contradictory-duplicate regressions. Status: fixed; requires human verification.

### CR-02: Duplicate frontmatter statuses can turn failed proof into passing proof

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** f9439ac
**Applied fix:** Reads all summary and verification status declarations, accepts exactly one recognized passing declaration, and rejects duplicate or competing `status`/`result`/`verdict` metadata regardless of ordering. Status: fixed; requires human verification.

### CR-03: Shipped milestones may link to another milestone's archives

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 79ea2d8
**Applied fix:** Normalizes ROADMAP and MILESTONES archive targets, requires exact equality with the current milestone's canonical roadmap or requirements archive, and emits `PARCHIVE_LINK_MISMATCH` for cross-milestone and swapped-kind links. Status: fixed; requires human verification.

### WR-01: `--timeout` does not bound CI monitoring wall time

**Files modified:** `scripts/ci_monitor.cjs`, `scripts/ci_monitor.test.cjs`
**Commit:** ff82862
**Applied fix:** Uses one absolute deadline, passes the remaining bounded duration to each synchronous `gh` invocation, caps polling sleeps to remaining time, and returns structured timeout evidence for hung subprocesses. Status: fixed; requires human verification.

### WR-02: Nonzero corroboration queries are recorded and then ignored

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 626c293
**Applied fix:** Converts every nonzero installed-runtime query and invalid JSON response into `PAUTH_CORROBORATION_UNAVAILABLE` incomplete collection evidence while retaining valid JSON as non-authoritative corroboration. Status: fixed; requires human verification.

## Verification

Verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- Tier 1 re-reads and CommonJS syntax checks passed for every modified source and test section.
- Focused regression tests passed for every finding.
- `node --test scripts/ci_monitor.test.cjs`: 15 passed, 0 failed.
- `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`: 128 passed, 0 failed.
- `node scripts/prohibitions/enforce_phase31.cjs`: 6/6 prohibition contracts passed.
- All source and test changes are committed atomically; this report remains uncommitted for the orchestrator.

---

_Fixed: 2026-09-10T04:28:27Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
