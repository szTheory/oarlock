---
phase: 31-repository-planning-truth
reviewed: 2026-09-10T03:44:49Z
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
  critical: 8
  warning: 4
  info: 0
  total: 12
status: issues_found
---

# Phase 31: Code Review Report

**Reviewed:** 2026-09-10T03:44:49Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

The 24 scoped workflow, implementation, fixture, and test files were reviewed at standard depth. The scoped Node suite passes (98 tests), but focused adversarial probes demonstrate multiple fail-open proof paths: ledger insertions and unreadable ledgers can pass history integrity, linked-worktree ownership claims bleed across worktrees, and completion can be accepted through non-canonical or failed evidence. CI monitoring also has documented-input and error-handling defects.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Append-only history check accepts rows inserted into the existing ledger [BLOCKER]

**File:** `scripts/history_integrity.cjs:72-86`
**Issue:** `compareEvidence` implements a subsequence check, so new rows may appear anywhere as long as every old line remains in order. A valid correction row inserted before an existing row returns `valid: true`, even though the ledger was rewritten rather than appended. This defeats the CI guard's append-only promise.
**Fix:** Require the head bytes to begin with the complete base bytes (with an explicitly defined newline boundary), then validate only the suffix as new correction rows. Add a test that inserts a valid row before and between existing rows and expects `HIST_EVIDENCE_NOT_APPEND_ONLY`.

### CR-02: Evidence read failures are treated as absence and can produce a healthy result [BLOCKER]

**File:** `scripts/history_integrity.cjs:47-52`
**Issue:** `readObject(..., required = false)` suppresses every Git failure, not just a missing path. If both base and head reads of `.planning/EVIDENCE.md` fail (for example from `maxBuffer`, timeout, or object corruption), both values become `null`; lines 112-126 then perform no ledger check and `inspectHistory` returns `healthy`. A focused runner probe reproduced this result with both `git show` calls failing.
**Fix:** Distinguish “path absent” using a prior tree lookup or a narrowly recognized missing-path status. Propagate all other observation failures so the result is `incomplete`/exit 2. Add tests for base-only, head-only, and both-side read errors.

### CR-03: A linked-worktree claim silently classifies matching paths in every linked worktree [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:334-369`
**Issue:** A `dirty_path` selector contains only `worktree_role` and relative `path`. Because every non-main tree has role `linked`, one claim for `same.txt` matches that path in all linked worktrees. A focused two-worktree probe assigned one owner's evidence to both trees and returned exit 0, even though only one tree was reviewed.
**Fix:** Include an exact normalized `worktree_path` (or another stable unique worktree identity) in linked dirty-path selectors and require it in `selectorMatches`. Reject legacy ambiguous linked selectors as invalid/incomplete, and test two linked worktrees with the same relative dirty path.

### CR-04: Evidence links are validated by basename rather than canonical artifact path [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:1315-1330`
**Issue:** `acceptedProofRow` accepts any relative Markdown path whose basename equals the canonical verification filename. Thus `decoy/31-VERIFICATION.md` satisfies a row for `.planning/phases/31-real/31-VERIFICATION.md`. A focused probe returned no completion diagnostics with that decoy link.
**Fix:** Resolve evidence links relative to the ledger, reject escapes/symlinks, normalize to a repository-relative path, and require exact equality with `verificationArtifact`. Add negative tests for same-basename paths in other directories.

### CR-05: A generic caveat sentence overrides a failed verification artifact [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:1387-1407`
**Issue:** Any single EVIDENCE line matching “Phase 31 ... accepted/acknowledged ... caveat” makes `acknowledgedCaveat` true. That suppresses `PCOMP_VERIFICATION_UNPROVEN` and also satisfies the per-requirement verification side of `linked`, even when the canonical verification frontmatter says `status: failed` and its requirement row says `failed`. A focused probe returned an empty diagnostics list for that contradiction.
**Fix:** Parse a structured, unique caveat record tied to the exact phase, requirement IDs, canonical verification artifact, reviewer/authority, and explicit accepted disposition. A caveat must not override an explicit failed verification unless the policy expressly models and validates that transition.

### CR-06: Global verification status plus an arbitrary ID mention proves each requirement [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:1333-1339`
**Issue:** When verification frontmatter is globally passed, `requirementPassedByVerification` treats any non-negative line containing the requirement ID as passed. Narrative text such as `REPO-01 mentioned` therefore counts as requirement-level proof. Combined with a superficially accepted EVIDENCE row, completion is reported healthy without a parsed per-requirement result.
**Fix:** Parse a defined requirement-results table or structured section and require exactly one explicit accepted status for each ID. Reject narrative mentions, duplicates, and absent/malformed rows. Add a test where a globally passed document merely discusses the ID.

### CR-07: Unknown STATE status values are accepted without diagnostics [BLOCKER]

**File:** `scripts/lib/repository_truth.cjs:909-969`
**Issue:** `resolveActiveScope` validates milestone and phase pointers but never validates `state.status`. A STATE document with `status: nonsense` resolves an active phase with no diagnostics. For an otherwise valid in-progress phase, planning health can therefore report healthy while its canonical session state is outside the supported state model.
**Fix:** Define and enforce the allowed STATE statuses and their consistency with ROADMAP completion. Missing, duplicate, or unsupported status values should produce a blocking authority/schema diagnostic. Add tests for unknown, missing, and contradictory statuses.

### CR-08: History CLI renders repository-controlled control characters unescaped [BLOCKER]

**File:** `scripts/history_integrity.cjs:150-156`
**Issue:** Human output interpolates Git-derived archive paths and observation errors directly. Git filenames may contain newlines and terminal escape characters, allowing a crafted archive path in a pull request to forge log lines or emit terminal control sequences in CI/local review output. The repository inventory renderer already escapes this class of input, but the history renderer does not.
**Fix:** Apply the same control-character escaping used by `repository_truth.cjs` to base/head values, artifact paths, change labels, and error text before human rendering. Add hostile newline, tab, and ANSI-path tests; keep JSON as the exact machine-readable representation.

## Warnings

### WR-01: `--workflow <file name>` can never match the returned run [WARNING]

**File:** `scripts/ci_monitor.cjs:132-152`
**Issue:** Help advertises a workflow name or file name, and `gh run list --workflow ci.yml` supports the file form, but `findRun` additionally requires `run.workflowName === workflow`. GitHub returns the display name (`CI`), so a valid `--workflow ci.yml` query is discarded as `no_ci_run_for_sha`.
**Fix:** Trust the server-side `--workflow` filter and match only the exact SHA, or resolve the requested file to the workflow display name/ID before comparing. Add a fake-gh test where the requested selector is `ci.yml` and `workflowName` is `CI`.

### WR-02: Completed-run lookup errors bypass the documented blocked result [WARNING]

**File:** `scripts/ci_monitor.cjs:260`
**Issue:** Only `findRun` is inside the `GhError` handler. If `viewRun` fails or returns invalid JSON, `assertCi` rejects; the CLI's promise has no catch, so it emits an unhandled stack and typically exits 1 instead of the documented exit 2 with JSON `reason: gh_error`.
**Fix:** Wrap both list and view operations in the same error-to-evidence boundary (or catch around the whole polling iteration), and add a test for `gh run view` failure in both JSON and human modes.

### WR-03: Timeout and polling options accept non-finite and negative values [WARNING]

**File:** `scripts/ci_monitor.cjs:206-215`
**Issue:** `Number()` results are never validated. Values such as `--poll NaN`, `--poll Infinity`, or negative timeouts produce immediate timers, tight polling, warnings, or inconsistent one-attempt behavior rather than invalid-usage exit 2.
**Fix:** Require finite numeric values, `timeout >= 0`, and a bounded positive poll interval (allow zero only if explicitly supported as a test/single-shot mode). Return structured `invalid_usage` evidence and test boundary values.

### WR-04: Repository-truth subprocesses have no execution timeout [WARNING]

**File:** `scripts/lib/repository_truth.cjs:69-78`
**Issue:** Git inspection commands omit `timeout`, and the installed GSD corroboration call at line 1219 also has no timeout. A hung Git helper, filesystem, credential helper, or runtime query can block the report and CI indefinitely instead of yielding the documented incomplete snapshot.
**Fix:** Set bounded timeouts on every subprocess, classify timeout/signal results as collection errors with `incomplete: true`, and cover both Git and corroboration timeout paths with injected-runner tests.

---

_Reviewed: 2026-09-10T03:44:49Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
