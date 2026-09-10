---
phase: 31-repository-planning-truth
fixed_at: 2026-09-10T04:04:37Z
review_path: /Users/jon/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md
iteration: 1
findings_in_scope: 12
fixed: 12
skipped: 0
status: all_fixed
---

# Phase 31: Code Review Fix Report

**Fixed at:** 2026-09-10T04:04:37Z
**Source review:** `/Users/jon/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 12
- Fixed: 12
- Skipped: 0

## Fixed Issues

### CR-01: Append-only history check accepts rows inserted into the existing ledger

**Files modified:** `scripts/history_integrity.cjs`, `scripts/history_integrity.test.cjs`
**Commit:** d9fe54a
**Applied fix:** Requires the candidate ledger to preserve the complete base byte prefix, enforces a newline boundary, and validates only appended correction rows. Added before-row and between-row insertion regressions. Status: fixed; requires human verification.

### CR-02: Evidence read failures are treated as absence and can produce a healthy result

**Files modified:** `scripts/history_integrity.cjs`, `scripts/history_integrity.test.cjs`
**Commit:** b5ef67f
**Applied fix:** Uses an exact tree lookup to distinguish an absent evidence path from a failed object read, allowing read failures on either revision to produce incomplete history evidence.

### CR-03: A linked-worktree claim silently classifies matching paths in every linked worktree

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/repository_inventory.test.cjs`
**Commit:** 56f24a3
**Applied fix:** Requires linked dirty-path selectors to carry a normalized absolute `worktree_path` and matches it exactly. Legacy ambiguous linked selectors are invalid. Status: fixed; requires human verification.

### CR-04: Evidence links are validated by basename rather than canonical artifact path

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 7f382b5
**Applied fix:** Resolves relative evidence targets from `.planning/EVIDENCE.md`, rejects absolute and escaping targets, and requires exact equality with the canonical verification artifact. Status: fixed; requires human verification.

### CR-05: A generic caveat sentence overrides a failed verification artifact

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** aa9746d
**Applied fix:** Removes unstructured caveat overrides so an explicit failed verification remains blocking at both phase and requirement level. Status: fixed; requires human verification.

### CR-06: Global verification status plus an arbitrary ID mention proves each requirement

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** b776b23
**Applied fix:** Requires exactly one structured verification-table row with one explicit accepted status per requirement; narrative mentions, duplicates, missing rows, and negative rows do not prove completion. Status: fixed; requires human verification.

### CR-07: Unknown STATE status values are accepted without diagnostics

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 4ecc32b
**Applied fix:** Requires exactly one supported STATE status (`executing` or `complete`) and checks it bidirectionally against the ROADMAP phase checkbox. Added unknown, missing, duplicate, and contradictory status regressions. Status: fixed; requires human verification.

### CR-08: History CLI renders repository-controlled control characters unescaped

**Files modified:** `scripts/history_integrity.cjs`, `scripts/history_integrity.test.cjs`
**Commit:** ba07f9c
**Applied fix:** Escapes terminal control characters in every human-rendered history value while preserving exact JSON facts. Added newline, tab, and ANSI filename coverage.

### WR-01: `--workflow <file name>` can never match the returned run

**Files modified:** `scripts/ci_monitor.cjs`, `scripts/ci_monitor.test.cjs`
**Commit:** 5ea0fc5
**Applied fix:** Trusts the server-side workflow selector and performs the local match only on the exact commit SHA. Added file-selector/display-name regression coverage. Status: fixed; requires human verification.

### WR-02: Completed-run lookup errors bypass the documented blocked result

**Files modified:** `scripts/ci_monitor.cjs`, `scripts/ci_monitor.test.cjs`
**Commit:** 3a3eb7b
**Applied fix:** Converts completed-run view failures and malformed responses into exit-2 `gh_error` evidence in both JSON and human output.

### WR-03: Timeout and polling options accept non-finite and negative values

**Files modified:** `scripts/ci_monitor.cjs`, `scripts/ci_monitor.test.cjs`
**Commit:** 45460e2
**Applied fix:** Requires a finite non-negative timeout and a finite poll interval from 0 through 3600 seconds, with zero documented as single-shot mode. Invalid boundaries return structured `invalid_usage` evidence. Status: fixed; requires human verification.

### WR-04: Repository-truth subprocesses have no execution timeout

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/repository_inventory.test.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 78bbf62
**Applied fix:** Adds bounded timeouts to Git, process inspection, and installed-runtime corroboration subprocesses. Timeout and signal failures now produce incomplete collection evidence.

## Verification

Verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- Tier 1 re-reads and CommonJS syntax checks passed for every modified source and test section.
- Focused regression tests passed after every finding.
- `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`: 119 passed, 0 failed.
- `node scripts/prohibitions/enforce_phase31.cjs`: 6/6 prohibition contracts passed.
- All source and test changes are committed atomically; this report remains uncommitted for the orchestrator.

---

_Fixed: 2026-09-10T04:04:37Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
