---
phase: 31-repository-planning-truth
reviewed: 2026-09-09T21:50:40Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/lib/repository_truth.cjs
  - scripts/planning_health.cjs
  - scripts/planning_health.test.cjs
  - scripts/repository_inventory.cjs
  - scripts/repository_inventory.test.cjs
findings:
  critical: 15
  warning: 0
  info: 0
  total: 15
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-09-09T21:50:40Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The five scoped CommonJS files were reviewed at standard depth. The combined 40-test suite passes, but focused adversarial probes demonstrate that the tools can still report healthy from contradictory completion data, malformed ownership metadata, incomplete Git porcelain, and unverified history identities. Snapshot race detection and mirror validation also contain fail-open or crash paths. These correctness and trust-boundary defects must be fixed before shipping.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Completion accepts failing evidence as proof (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:1192-1200
**Issue:** Requirement linkage is only a word-boundary search for the requirement ID in EVIDENCE.md and the planning verification content. Rows saying that proof failed or is missing still satisfy both searches, so an explicitly failed requirement can be reported healthy.
**Fix:** Parse the canonical evidence row for each requirement, require an accepted/pass classification and a repository-bounded proof target, and require the verification artifact to classify that requirement as passed. Treat failed, pending, missing, and malformed rows as PCOMP_REQUIREMENT_UNLINKED.

### CR-02: Rejected ownership claims can still become intentional dispositions (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:318-375
**Issue:** Registry validity is checked only at the envelope level before all claims are matched. A claim diagnosed as invalid can still populate an intentional disposition, and required metadata is not type-checked at all: object values for owner, provenance, and proposed_disposition pass validation and produce exit 0. This accepts non-evidence as ownership policy.
**Fix:** Validate every claim into a separate accepted-claims collection. Require non-empty strings for owner/provenance/disposition, a strict supported disposition enum, a strict finite date, and exact selector types. Match observations only against accepted claims; invalid matches must remain unknown.

### CR-03: Same-length in-place rewrites evade snapshot identity checks (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:861-866
**Issue:** Identity contains only device, inode, size, and mtimeMs. A same-length rewrite followed by restoring the original mtime preserves every compared field, allowing changed canonical planning or registry bytes to be accepted without PSCOPE_SNAPSHOT_CHANGED.
**Fix:** Include ctime and descriptor identity checks, and compare a digest of the accepted bytes during the final consistency pass. Do not use mutable timestamps alone as content identity.

### CR-04: The configured byte limit is not enforced during reads (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:915-929
**Issue:** File size is checked once before readFileSync. A concurrent writer can grow the open file after that check, causing an allocation and read far beyond maximumBytes before the later identity check rejects it. The promised bounded-read denial-of-service control is therefore ineffective during the actual read.
**Fix:** Read the descriptor in bounded chunks, stop after maximumBytes plus one byte, and emit a source-boundary error immediately. Recheck descriptor identity after the bounded read.

### CR-05: JSON null mirror content crashes planning-health (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:1241-1253
**Issue:** JSON.parse('null') succeeds, then value.contract dereferences null. With demonstrated consumer evidence, planning-health throws a TypeError instead of returning PMIRROR_METADATA_INVALID and a controlled nonzero conclusion.
**Fix:** After parsing, require a non-null, non-array object before accessing fields. Classify every other JSON value as PMIRROR_METADATA_INVALID.

### CR-06: Contradictory consumer mirrors pass validation (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:1251-1263
**Issue:** Mirror validation checks only contract, flavor, phases-as-array, and a prefix milestone match. It never compares phase records or status to ROADMAP/STATE, and startsWith accepts v2.20 for canonical v2.2. A demonstrated-consumer stale mirror can therefore pass with no diagnostic.
**Fix:** Require exact milestone equality, validate the full mirror schema, and compare its active phase/status projection to canonical ROADMAP and STATE. Emit PMIRROR_CONTENT_MISMATCH for every missing, extra, or contradictory routing value.

### CR-07: An authority conflict suppresses incomplete-proof diagnostics (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:1266-1271
**Issue:** activeArtifactDiagnostics returns when activeScope.active is null, while validateCompletionProof runs only after canonical directory resolution. If ROADMAP marks a phase complete but STATE disagrees and the canonical phase directory is missing or ambiguous, the result reports only the status conflict and omits the required incomplete snapshot/proof diagnostic.
**Fix:** When completion is claimed, resolve and validate the canonical proof set independently of whether active scope agreement succeeded. Preserve both the authority-conflict and incomplete-proof diagnostics.

### CR-08: Unchecked ROADMAP plans can produce a healthy completed phase (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:1150-1167
**Issue:** Completion validation iterates declared plans but never checks plan.complete. activeArtifactDiagnostics downgrades an unchecked plan with a complete summary to a warning, and warnings do not affect exit status. A ROADMAP phase checked complete with an unchecked plan, passing summary, verification, and evidence returns status healthy and exit 0.
**Fix:** In validateCompletionProof, emit a blocking PCOMP_PLAN_NOT_ACCEPTED diagnostic for every unchecked declared plan. A summary must not override the ROADMAP checklist.

### CR-09: Malformed or unknown porcelain records are silently discarded (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:151-190
**Issue:** parseStatus has no final rejection branch. Any nonempty unrecognized token is ignored, so a future, truncated, or malformed dirty record can disappear and the inventory can report a clean healthy worktree. Existing tests reject malformed records only when they begin with known record prefixes.
**Fix:** Reject every nonempty token that is neither a supported header nor a supported record. Also validate the mandatory branch headers before returning, so incomplete porcelain becomes RINV_COLLECTION_INCOMPLETE.

### CR-10: Phase-artifact namespace changes are absent from consistency checking (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:1007-1025
**Issue:** The final consistency pass rechecks only files already recorded in documents/artifactIdentities. It does not re-list .planning/phases or compare the artifact-name set. A second canonical phase directory or proof artifact added during collection is invisible, allowing a result derived from a stale namespace to be reported healthy.
**Fix:** Snapshot a deterministic identity for relevant directories and their exact entry sets, then re-list and compare them during the final consistency pass. Any addition, removal, or rename must produce PSCOPE_SNAPSHOT_CHANGED and exit 2.

### CR-11: ROADMAP archive links are parsed and then ignored (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:600-606
**Issue:** parseShippedMilestones stores roadmapLink, but validateMilestoneHistory never reads it. A shipped ROADMAP entry can point outside the repository, to a mutable file, or to a missing archive while the validator reports history healthy based solely on MILESTONES.md links.
**Fix:** Resolve each ROADMAP link relative to .planning/ROADMAP.md, enforce the repository boundary and immutable .planning/milestones destination, and require it to exist in milestoneArchives.

### CR-12: The recorded planning-milestone identity is never validated (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:731-785
**Issue:** The milestone index's Planning milestone field is not parsed or compared with the ROADMAP milestone. A v1.2 block can claim Planning milestone v9.9 without any diagnostic, violating the five-separate-identities contract.
**Fix:** Parse Planning milestone from each block and require exact equality with expected.planningMilestone. Emit a dedicated PIDENT diagnostic for missing or contradictory values.

### CR-13: Unsupported publication claims are accepted as truth (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:778-785
**Issue:** Publication produces an informational diagnostic only when absent or beginning with unknown. Any other text, including an unevidenced Published claim, receives no validation or diagnostic even though no publication-registry evidence is collected. Local tags can therefore be presented as published releases without proof.
**Fix:** Keep publication unknown unless independent registry evidence is supplied through a defined source. Without such evidence, make every positive publication assertion a blocking PIDENT_PUBLICATION_OVERCLAIM diagnostic.

### CR-14: Duplicate canonical phase definitions silently select the first winner (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:575-597,825
**Issue:** parseRoadmap permits repeated phase numbers and resolveActiveScope uses Array.find, silently selecting the first duplicate. Contradictory names or completion states inside the canonical ROADMAP therefore do not block, contrary to the no-guessed-winner authority rule.
**Fix:** Index phases by number while parsing, emit an ambiguity diagnostic for duplicates, and refuse to resolve active scope until exactly one definition exists for the STATE pointer.

### CR-15: Any undated keyword mention can satisfy the archive-correction requirement (BLOCKER)

**File:** /Users/jon/projects/oarlock/scripts/lib/repository_truth.cjs:707-708
**Issue:** correctionRecorded checks only whether a line contains the milestone and one of four generic words. It does not require a date, the contradictory archive path, a correction classification, or accepted evidence. Text such as v1.2 archive status therefore suppresses PHIST_CORRECTION_REFERENCE_MISSING.
**Fix:** Parse a structured EVIDENCE entry and require a valid date, exact milestone, exact preserved archive target, correction/erratum classification, and substantive evidence before treating the contradiction as corrected.

---

_Reviewed: 2026-09-09T21:50:40Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
