---
phase: 31-repository-planning-truth
reviewed: 2026-09-09T21:25:44Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/lib/repository_truth.cjs
  - scripts/repository_inventory.cjs
  - scripts/repository_inventory.test.cjs
  - scripts/planning_health.cjs
  - scripts/planning_health.test.cjs
findings:
  critical: 7
  warning: 0
  info: 0
  total: 7
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-09-09T21:25:44Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The five scoped CommonJS files were re-reviewed after gap-closure Plans 31-04 and 31-05. All seven findings in the previous report were addressed, and the combined 40-test suite passes. New adversarial probes nevertheless demonstrate that completion can still be certified from explicitly failing evidence, invalid ownership claims can still become intentional dispositions, bounded reads can accept an in-place rewrite or allocate beyond their limit, contradictory mirrors can pass or crash evaluation, and one authority conflict suppresses the required incomplete-proof diagnostic. These are correctness and trust-boundary defects that must be fixed before shipping.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Completion accepts failing evidence as proof (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:1192-1194`
**Issue:** Requirement linkage is reduced to a word-boundary search for the requirement ID in `EVIDENCE.md` and the verification body. It does not parse the ledger's proof target or classification. A completed fixture whose evidence says `| REPO-01 | proof explicitly missing | fail |` and whose verification body says `REPO-01 failed` returns no diagnostics because both strings merely mention the ID. This violates the defined proof chain and permits an explicitly failed requirement to be reported healthy.
**Fix:** Parse the canonical evidence row for each requirement, require an accepted/pass classification and a repository-bounded proof target, and require the verification artifact to classify that requirement as passed. Treat missing, failed, pending, or malformed rows as `PCOMP_REQUIREMENT_UNLINKED`.

### CR-02: Invalid ownership claims still produce intentional dispositions (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:354-375`
**Issue:** `validRegistry` validates only the registry envelope. `registryDiagnostics` reports malformed member claims, but `classifyObservation` subsequently matches every member of that same array, including claims missing required evidence fields or carrying invalid dates/confidence. An exact malformed claim therefore emits `RINV_CLAIM_INVALID` while also producing `state: "intentional"` and `RINV_INTENTIONAL_STATE`. Although the conclusion is incomplete, the machine-readable disposition has accepted the very claim that validation rejected, violating the fact/disposition contract.
**Fix:** Validate each claim once into a separate accepted-claims collection and match observations only against that collection. If any matching claim is invalid, keep the observation unknown and never copy its owner, provenance, or proposed disposition into accepted output.

### CR-03: In-place rewrites can evade the bounded reader's identity check (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:862-866`
**Issue:** File identity consists only of device, inode, size, and `mtimeMs`; it omits `ctimeMs`. An in-place same-length rewrite followed by restoration of the original mtime retains every compared field. An adversarial `afterOpen` probe changed `trusted!` to `hostile!`, restored the mtime, and `readBoundedRepositoryFile` returned `hostile!` without an error. Canonical planning or registry content can therefore change during collection without producing the promised incomplete result.
**Fix:** Include `ctimeMs` (and preferably nanosecond-resolution stat fields where available) in the identity comparison, and compare a second `fstat` of the open descriptor before accepting bytes. For a stronger guarantee, hash the bytes and verify the same content during the whole-snapshot consistency pass.

### CR-04: The byte limit is not enforced while a file is read (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:915-929`
**Issue:** The size limit is checked once before `fs.readFileSync(descriptor)`. A concurrent writer can grow the already-open regular file after line 917, causing `readFileSync` to allocate and read far more than `maximumBytes`; the later identity check occurs only after that allocation. This leaves the T-31-18 denial-of-service boundary open even if the eventual result is rejected.
**Fix:** Read from the descriptor in bounded chunks and stop once `maximumBytes + 1` bytes are observed, then emit a source-boundary error. Recheck descriptor size/identity after the bounded read; do not rely on a pre-read `fstat` as an allocation bound.

### CR-05: JSON `null` mirror content crashes planning-health evaluation (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:1241-1253`
**Issue:** `JSON.parse("null")` succeeds, after which `value.contract` dereferences `null`. With demonstrated consumer evidence, `evaluatePlanningHealth` throws `TypeError: Cannot read properties of null` instead of returning `PMIRROR_METADATA_INVALID` and a nonzero conclusion. The same crash occurs when collection supplies `content: null` alongside consumer evidence.
**Fix:** After parsing, require `value` to be a non-null, non-array object before reading properties. Return `PMIRROR_METADATA_INVALID` for every other JSON value and ensure unreadable mirror collection short-circuits schema evaluation.

### CR-06: A stale or contradictory consumer mirror can pass validation (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:1251-1263`
**Issue:** Mirror validation checks only three schema fields and a prefix match on milestone. It never reconciles the `phases` entries with canonical ROADMAP/STATE and `startsWith` accepts `v2.20` as matching canonical `v2.2`. A demonstrated-consumer mirror `{contract:"1.0.0", flavor:"core", milestone:"v2.20 stale", phases:[]}` produces no mirror diagnostic. Downstream consumers can therefore receive stale routing while planning health reports agreement.
**Fix:** Require exact milestone equality, validate the full mirror schema including source metadata, and compare its active phase/status projection to canonical ROADMAP and STATE. Emit `PMIRROR_CONTENT_MISMATCH` for missing, extra, or contradictory phase records.

### CR-07: A status conflict suppresses missing canonical completion proof (BLOCKER)

**File:** `scripts/lib/repository_truth.cjs:1266-1271`
**Issue:** `activeArtifactDiagnostics` returns immediately when `activeScope.active` is null, while the completion branch calls `validateCompletionProof` only when canonical resolution already succeeded. If ROADMAP marks Phase 31 complete, STATE says `executing`, and the canonical phase directory is absent, evaluation reports only `PSCOPE_PHASE_STATUS_CONFLICT` and exits 1. It omits `PSCOPE_CANONICAL_PHASE_DIRECTORY_MISSING` and the required incomplete exit 2 even though a completion claim cannot be collected safely.
**Fix:** Whenever either canonical authority claims completion, always evaluate canonical directory resolution. Append `canonicalPhaseDirectoryDiagnostic` on missing/ambiguous resolution regardless of other authority conflicts; call `validateCompletionProof` only after that diagnostic has been recorded and resolution is unique.

---

_Reviewed: 2026-09-09T21:25:44Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
