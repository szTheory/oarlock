---
phase: 31-repository-planning-truth
fixed_at: 2026-09-09T22:09:28Z
review_path: /Users/jon/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md
iteration: 1
findings_in_scope: 15
fixed: 15
skipped: 0
status: all_fixed
---

# Phase 31: Code Review Fix Report

**Fixed at:** 2026-09-09T22:09:28Z
**Source review:** `/Users/jon/projects/oarlock/.planning/phases/31-repository-planning-truth/31-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 15
- Fixed: 15
- Skipped: 0

## Fixed Issues

### CR-01: Completion accepts failing evidence as proof

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** c4db46d
**Applied fix:** Parses one canonical evidence row, requires an accepted classification and bounded verification target, and rejects negative requirement classifications. Status: fixed; requires human verification.

### CR-02: Rejected ownership claims can still become intentional dispositions

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/repository_inventory.test.cjs`, `.planning/repository-ownership.json`
**Commit:** a3fb40b
**Applied fix:** Builds an accepted-claims collection using strict selector, metadata, disposition, confidence, and calendar-date validation; invalid claims cannot match observations. Status: fixed; requires human verification.

### CR-03: Same-length in-place rewrites evade snapshot identity checks

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** ca19237
**Applied fix:** Adds ctime, descriptor-after-read identity checks, and SHA-256 content digests to snapshot consistency. Status: fixed; requires human verification.

### CR-04: The configured byte limit is not enforced during reads

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 959e8b6
**Applied fix:** Replaces unbounded descriptor reads with capped chunks that stop at `maximumBytes + 1` and fail at the source boundary. Status: fixed; requires human verification.

### CR-05: JSON null mirror content crashes planning-health

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 1f4f12b
**Applied fix:** Requires parsed mirror JSON to be a non-null, non-array object before field access. Status: fixed.

### CR-06: Contradictory consumer mirrors pass validation

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** d9301d9
**Applied fix:** Validates phase-record schema, exact milestone identity, unique phase numbers, and every canonical phase name/status projection, including missing and extra routes. Status: fixed; requires human verification.

### CR-07: An authority conflict suppresses incomplete-proof diagnostics

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 9163825
**Applied fix:** Runs completion proof resolution independently from active-scope agreement and retains both conflict and incomplete-proof diagnostics. Status: fixed; requires human verification.

### CR-08: Unchecked ROADMAP plans can produce a healthy completed phase

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** c76069e
**Applied fix:** Emits blocking `PCOMP_PLAN_NOT_ACCEPTED` diagnostics for every unchecked declared plan regardless of summary presence. Status: fixed; requires human verification.

### CR-09: Malformed or unknown porcelain records are silently discarded

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/repository_inventory.test.cjs`
**Commit:** e7567b2
**Applied fix:** Rejects every unsupported nonempty porcelain token, duplicate mandatory headers, and incomplete branch headers. Status: fixed.

### CR-10: Phase-artifact namespace changes are absent from consistency checking

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 9187609
**Applied fix:** Snapshots phase-directory identities and exact typed entry sets, then compares the namespace during final consistency validation. Status: fixed; requires human verification.

### CR-11: ROADMAP archive links are parsed and then ignored

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** d53c366
**Applied fix:** Resolves shipped ROADMAP links relative to ROADMAP.md and validates repository bounds, immutable namespace, and collected archive existence. Status: fixed; requires human verification.

### CR-12: The recorded planning-milestone identity is never validated

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 30e433d
**Applied fix:** Parses and exactly compares each milestone block's Planning milestone field, with a dedicated mismatch diagnostic. Status: fixed.

### CR-13: Unsupported publication claims are accepted as truth

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** f927598
**Applied fix:** Keeps absent/unknown publication informational and blocks every positive assertion when no independent registry source was collected. Status: fixed; requires human verification.

### CR-14: Duplicate canonical phase definitions silently select the first winner

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** ea8645b
**Applied fix:** Indexes ROADMAP phase counts, emits `PSCOPE_PHASE_DEFINITION_AMBIGUOUS`, and refuses to select or validate a duplicate phase winner. Status: fixed; requires human verification.

### CR-15: Any undated keyword mention can satisfy the archive-correction requirement

**Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
**Commit:** 2baa309
**Applied fix:** Requires a structured evidence row with a valid date, exact milestone, exact preserved archive target, correction classification, and substantive evidence. Status: fixed; requires human verification.

## Verification

Verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- Syntax checks passed for all three modified CommonJS files.
- `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs`: 54 passed, 0 failed.
- All source and test changes are committed; only the orchestrator-owned report and pre-existing user files remain uncommitted.

---

_Fixed: 2026-09-09T22:09:28Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
