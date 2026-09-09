---
phase: 31-repository-planning-truth
reviewed: 2026-09-09T19:57:25Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/lib/repository_truth.cjs
  - scripts/repository_inventory.cjs
  - scripts/repository_inventory.test.cjs
  - scripts/planning_health.cjs
  - scripts/planning_health.test.cjs
findings:
  critical: 6
  warning: 1
  info: 0
  total: 7
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-09-09T19:57:25Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The five scoped CommonJS files were reviewed in full and their 31 focused tests pass. Adversarial fixtures nevertheless demonstrate fail-open completion proof, repository-boundary escapes, and incomplete Git identity collection that is misclassified as ordinary policy disagreement. These defects make a healthy result possible from non-authoritative evidence and must be fixed before shipping.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Phase artifacts are matched globally by basename (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:972-975`
**Issue:** `artifactForPlan` searches every phase directory with `endsWith`, and the same global basename search is repeated for active plans and verification artifacts at lines 1011-1012 and 1049. A `31-01-PLAN.md`, `31-01-SUMMARY.md`, or `31-VERIFICATION.md` under an unrelated directory such as `.planning/phases/99-decoy/` is therefore accepted as Phase 31 evidence. A fixture containing only those three decoy files produces `status: healthy` and exit 0. This contradicts the intended inert-decoy boundary and can falsely certify completion.
**Fix:** Resolve the one canonical directory for the active phase first, then require every plan, summary, and verification path to have that exact directory prefix. Reject zero or multiple matching phase directories as incomplete/ambiguous instead of searching globally by filename.

### CR-02: Body text is accepted as completion frontmatter (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:1004-1015`
**Issue:** The summary and verification checks use multiline regular expressions against the entire Markdown document. Consequently, plain body lines such as `status: complete` or `status: passed` satisfy the proof checks even when no YAML frontmatter exists. Combined with otherwise valid requirement/evidence links, this returns exit 0 for artifacts that explicitly lack the promised structured proof metadata.
**Fix:** Parse only the leading YAML frontmatter (using a strict parser or the existing `parseFrontmatter`) and compare its normalized `status`/`result`/`verdict` value. Do not search Markdown body text for authoritative status fields.

### CR-03: Intermediate symlinks escape the repository boundary (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:819-833`
**Issue:** `readPlanningFile` checks only that the lexical path starts with the repository root and that the final path entry is not itself a symlink. It never resolves or validates intermediate components. If `.planning` (or `.planning/phases`/`.planning/milestones`) is a symlink to an external directory, all canonical documents are read from outside the repository with no `PAUTH_SOURCE_UNREADABLE` diagnostic. This both violates the stated repository-bounded trust model and permits external content to determine planning health.
**Fix:** Resolve the repository root and candidate with `realpath`, require the resolved candidate to remain beneath the resolved root, and open with no-follow semantics where available. Validate the opened file with `fstat` and read from that same descriptor to avoid check/read races. Apply the same containment rule before traversing phase and milestone directories.

### CR-04: Ownership registry reading follows arbitrary symlinks (BLOCKER)

**File:** `scripts/repository_inventory.cjs:30-33`
**Issue:** `readRegistry` uses `statSync` and then `readFileSync`, both of which follow symlinks, and performs no repository-containment or regular-file check. A repository-controlled `.planning/repository-ownership.json` symlink can read JSON outside the repository; invalid-schema JSON is then embedded in the JSON diagnostic's `actual` field. In CI this can disclose a mounted JSON secret, and the separate stat/read calls also permit a size-check race.
**Fix:** Anchor the registry to the collected repository root, reject symlinks and non-regular files, verify the resolved path remains inside that root, and open/fstat/read one file descriptor with no-follow semantics. Do not include an entire invalid registry payload in diagnostics.

### CR-05: Git tag inspection failures are silently reported as policy mismatches (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:623-654`
**Issue:** `collectTagIdentities` catches any `for-each-ref` failure and returns an empty array; `readPackageVersion` similarly converts `git show` failures into an ordinary unknown value. No collection error is added to the planning snapshot. The evaluator then reports tags as absent or versions as mismatched and exits 1, even though the CLI contract says unreadable Git data is an incomplete snapshot requiring exit 2. This loses the true cause and can produce false historical conclusions.
**Fix:** Return structured collection errors (or throw them to `collectPlanningSnapshot`) for failed ref enumeration and tag reads, append them with `incomplete: true`, and reserve an empty identity list for a successful enumeration containing no tags.

### CR-06: Phase-range validation uses substring matching (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:695-696`
**Issue:** History validation accepts `actualPhases.includes(expected.phases)`. An expected range of `8-13` therefore passes against a contradictory value such as `18-130`; an adversarial fixture produces no `PHIST_PHASE_RANGE_MISMATCH`. This allows incorrect milestone history to be reported as reconciled.
**Fix:** Parse the `Phases` field into its exact normalized range and compare both endpoints (or compare a fully anchored normalized string), rejecting extra prefix/suffix text unless it is explicitly part of the schema.

## Warnings

### WR-01: Corroboration executes a hard-coded Phase 31 query whose result is unused (WARNING)

**File:** `scripts/lib/repository_truth.cjs:919-931`
**Issue:** Every planning-health collection invokes `drift-guard.phase-status 31` regardless of the active phase, yet `evaluatePlanningHealth` never reads `snapshot.corroboration`. After Phase 31 this gathers the wrong phase and adds an external process failure surface without affecting any diagnostic or conclusion.
**Fix:** Either remove this dead collection or resolve the canonical active phase first and surface corroboration explicitly as non-authoritative evidence. Handle spawn errors as structured collection results rather than silently retaining a null status.

---

_Reviewed: 2026-09-09T19:57:25Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
