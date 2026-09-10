---
phase: 31-repository-planning-truth
reviewed: 2026-09-10T04:13:50Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - .github/workflows/ci.yml
  - scripts/ci_monitor.cjs
  - scripts/ci_monitor.test.cjs
  - scripts/fixtures/prohibitions/history_additive.json
  - scripts/fixtures/prohibitions/history_rewrite.json
  - scripts/fixtures/prohibitions/planning_conflict_repair.cjs
  - scripts/fixtures/prohibitions/planning_identity_inference.cjs
  - scripts/fixtures/prohibitions/planning_phantom_authority.cjs
  - scripts/fixtures/prohibitions/repository_inventory_inference.cjs
  - scripts/fixtures/prohibitions/repository_inventory_mutating.cjs
  - scripts/history_integrity.cjs
  - scripts/history_integrity.test.cjs
  - scripts/lib/repository_truth.cjs
  - scripts/planning_health.cjs
  - scripts/planning_health.test.cjs
  - scripts/prohibitions/enforce_phase31.cjs
  - scripts/prohibitions/enforce_phase31.test.cjs
  - scripts/prohibitions/planning_authority.test.cjs
  - scripts/prohibitions/planning_identity.test.cjs
  - scripts/prohibitions/planning_repair_safety.test.cjs
  - scripts/prohibitions/repository_inventory_report_only.test.cjs
  - scripts/prohibitions/repository_inventory_transparency.test.cjs
  - scripts/repository_inventory.cjs
  - scripts/repository_inventory.test.cjs
findings:
  critical: 3
  warning: 2
  info: 0
  total: 5
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-09-10T04:13:50Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

All 12 findings from the prior review (8 Critical, 4 Warning) are resolved in the current sources, and the scoped suite passes 119 tests. The broader adversarial re-review found five additional defects: completion can still pass with omitted or contradictory canonical requirement data, duplicate proof statuses are accepted, milestone links can silently cross-link to another release, CI's advertised timeout is not an end-to-end bound, and ordinary installed-runtime query failures are discarded.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Completed requirements omitted from the ROADMAP phase escape all proof checks [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:985-995, 1453-1469`
**Issue:** Scope validation only checks that IDs listed by the ROADMAP exist in committed REQUIREMENTS, while completion validation iterates only the ROADMAP's requirement list. It never checks the inverse mapping from committed REQUIREMENTS/Traceability into the phase. A focused probe added a checked `REPO-02` row traced to Phase 31 but omitted it from `Phase 31`'s ROADMAP requirements; `validateCompletionProof` returned no diagnostics even though `REPO-02` had no evidence or verification row. The `Map` construction also silently overwrites duplicate requirement/traceability rows, so a later `Complete` row can conceal an earlier contradictory `Pending`/different-phase row; that probe also returned no diagnostics.
**Fix:** Validate a bijective, unique mapping before completion: reject duplicate committed requirement IDs and duplicate traceability IDs, require each committed ID to have exactly one trace row, and require every trace row for Phase 31 to appear exactly once in the ROADMAP phase requirements. Do not construct last-write-wins maps until uniqueness has been established. Add omission and contradictory-duplicate regressions.

### CR-02: Duplicate frontmatter statuses can turn failed proof into passing proof [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:588-605, 1428-1443`
**Issue:** `parseFrontmatter` overwrites repeated keys. Summary and verification status checks use that lossy object without checking cardinality. A canonical summary containing `status: failed` followed by `status: complete`, and a verification containing `status: failed` followed by `status: passed`, plus one valid requirement row, produce zero completion diagnostics. Contradictory proof metadata therefore passes solely because the favorable value appears last.
**Fix:** Use `frontmatterFieldValues` (or a structured parser) for summary `status` and for the verification status aliases, require exactly one recognized status field/value, and reject duplicates or simultaneous `status`/`result`/`verdict` declarations as ambiguous. Add failed-then-passed and passed-then-failed tests for both summaries and verification artifacts.

### CR-03: Shipped milestones may link to another milestone's archives [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:800-832, 864-875`
**Issue:** Both ROADMAP and MILESTONES link validation require only that a normalized target is inside `.planning/milestones/` and exists. They never require the target to equal the current milestone's canonical `{milestone}-ROADMAP.md` or `{milestone}-REQUIREMENTS.md`. A focused `v1.2` probe linked all three navigation fields to existing `v2.1` archives and produced no `PARCHIVE_*` error. This reports a navigable, reconciled history while routing readers to the wrong release evidence.
**Fix:** For each shipped record, compute the exact expected targets `.planning/milestones/${planningMilestone}-ROADMAP.md` and `...-REQUIREMENTS.md`; after normalization, require equality with the corresponding expected target as well as bounded existence. Emit a stable mismatch diagnostic and add cross-milestone and swapped-kind tests for ROADMAP and MILESTONES links.

## Warnings

### WR-01: `--timeout` does not bound CI monitoring wall time [WARNING]

**File:** `scripts/ci_monitor.cjs:78-83, 227-269`
**Issue:** The timeout is checked only between polling iterations. Each synchronous `gh` subprocess has no execution timeout, and each sleep always uses the full poll interval. A hung `gh` invocation can block forever, while `--timeout 1 --poll 3600` can sleep for an hour before noticing the one-second deadline. This contradicts the documented "Max wait time" contract.
**Fix:** Compute an absolute deadline, pass the remaining bounded duration to every `spawnSync` call, and sleep for `Math.min(pollInterval, remainingTime)`. Convert subprocess timeouts into structured `gh_error`/timeout evidence and test a poll interval longer than the remaining deadline plus a hung fake `gh` process.

### WR-02: Nonzero corroboration queries are recorded and then ignored [WARNING]

**File:** `scripts/lib/repository_truth.cjs:1243-1266, 1308-1314`
**Issue:** Corroboration becomes an incomplete collection only for spawn errors, signals, or `status === null`. A normal nonzero exit is stored as `{status: 1, output: ...}` but never converted to a diagnostic or used anywhere else. A focused runner probe returned `planning.inspect` status 1 with `query failed`; the snapshot had no `PAUTH_CORROBORATION_UNAVAILABLE` error. Thus timeout failure blocks while an ordinary query failure silently disappears from the report.
**Fix:** Treat every status other than 0 as a bounded corroboration failure (while keeping corroboration non-authoritative), add it to `collectionErrors` with `incomplete: true`, and test nonzero status, invalid output, and successful output separately. If unavailable corroboration is intentionally non-blocking, expose a stable warning instead of discarding it.

---

_Reviewed: 2026-09-10T04:13:50Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
