---
phase: 31-repository-planning-truth
reviewed: 2026-09-10T04:35:50Z
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
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-09-10T04:35:50Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

The five findings from the iteration-2 review are resolved: requirement/traceability mappings are now checked bidirectionally and for duplicates, proof frontmatter must be unique, shipped links must target the exact milestone archives, CI subprocesses and sleeps are deadline-bounded, and nonzero or malformed corroboration results make the snapshot incomplete. The scoped suite passes 128 tests.

The final adversarial pass found five additional defects. Four allow contradictory or incomplete canonical planning/history data to be accepted, and one makes ownership claims expire at the start rather than the end of their stated revisit date.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Duplicate STATE routing fields silently select the last value [BLOCKER]

**File:** `/Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:588-596, 941-969`
**Issue:** `parseFrontmatter` still overwrites repeated keys, while `resolveActiveScope` checks cardinality only for `status`. Duplicate `milestone` and `current_phase` declarations are therefore accepted using the last value. A focused snapshot containing `milestone: v9.9` followed by `milestone: v2.2` and `current_phase: 99` followed by `current_phase: 31` returned an active `{ milestone: "v2.2", phase: "31" }` scope with no diagnostics. Contradictory canonical routing data can thus acquire authority solely by ordering.
**Fix:** Read `milestone` and `current_phase` with `frontmatterFieldValues`, require exactly one non-empty value for each, and emit blocking ambiguity diagnostics before resolving a phase. Add both field orders and duplicate-equal-value regressions.

### CR-02: Committed scope is taken from the first versioned section, not the active milestone [BLOCKER]

**File:** `/Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:558-585, 941-950, 1418-1425`
**Issue:** `parseCommittedRequirements` selects the first heading matching `## v... Requirements` without receiving or validating the active milestone. Its traceability parser likewise takes the first global `## Traceability` section. A focused completed `v2.2` snapshot with a `v2.1 Requirements` section first, a later `v2.2 Requirements` section containing an additional unproved requirement, and proof only for the old ID returned zero completion diagnostics. Current committed scope can therefore be omitted merely by retaining or inserting an older versioned section above it.
**Fix:** Resolve the unique active milestone first, parse the exact `## ${milestone} Requirements` section and its associated traceability table, and reject missing or duplicate matching sections. Add regressions with older/newer sections before and after the active section and with multiple traceability headings.

### CR-03: Duplicate plan checklist entries reuse one artifact as multiple completed plans [BLOCKER]

**File:** `/Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:625-637, 1434-1458`
**Issue:** `parseRoadmap` appends every plan row without enforcing unique filenames, and completion validation independently accepts each duplicate against the same summary. A focused phase declaring `31-01-PLAN.md` twice, with only one plan file and one summary, returned zero completion diagnostics. This permits a claimed `2/2` completion to be proven by one executed plan repeated twice.
**Fix:** Count plan filenames within each phase and emit a blocking ambiguity diagnostic unless every declared plan appears exactly once. Validate declared plan totals against the unique checklist when a totals field is present, and add duplicate-identical plus contradictory checked/unchecked regressions.

### CR-04: Milestone history ignores names, shipment dates, and contradictory duplicate metadata [BLOCKER]

**File:** `/Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:655-663, 684-693, 749-752, 789-926`
**Issue:** `parseShippedMilestones` captures each ROADMAP milestone's name and shipped date, but `validateMilestoneHistory` never compares either value with the MILESTONES heading. `milestoneBlocks` also overwrites duplicate milestone headings, `fieldFromBlock` accepts the first duplicate field, and the shipped-status check succeeds if any matching status occurs anywhere in the block. A focused snapshot with ROADMAP name/date `Roadmap Name`/`2026-01-01`, MILESTONES name/date `Different Name`/`2099-12-31`, and both `Status: Failed` and `Status: Shipped` produced no error. The history report can therefore certify materially contradictory release identity.
**Fix:** Parse milestone blocks into cardinality-preserving records; require one block and one value for each canonical field. Compare the exact name and a calendar-valid shipped date against ROADMAP, and reject all duplicate headings/status/phase/identity/archive fields even when values agree. Add name-only, date-only, invalid-date, duplicate-block, and competing-status regressions.

## Warnings

### WR-01: A claim expires at midnight on its own revisit date [WARNING]

**File:** `/Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:431-439`
**Issue:** Staleness compares `Date.parse(claim.revisit_at)`, which is midnight UTC, with the full snapshot timestamp. A claim whose `revisit_at` equals the observation's calendar date is marked stale for nearly the entire stated date. This creates false blocking inventory failures at a boundary that users reasonably interpret as valid through that date.
**Fix:** Compare normalized `YYYY-MM-DD` calendar values, or define the deadline as the exclusive start of the following UTC day. Add tests immediately before, during, and after the revisit date.

---

_Reviewed: 2026-09-10T04:35:50Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
