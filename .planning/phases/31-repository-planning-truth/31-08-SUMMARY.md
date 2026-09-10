---
phase: 31-repository-planning-truth
plan: "08"
subsystem: repository-truth
tags: [git-history, node-test, planning-health, prohibition-proof]
requires:
  - phase: 31-05
    provides: repository-bounded planning collection and causal Git identity failures
provides:
  - Base-to-head guard for frozen milestone archives and append-only evidence corrections
  - Fail-first independent milestone identity prohibition matrix
  - Separate tag and peeled-source-SHA mismatch diagnostics
affects: [31-09, phase-31-verification, planning-truth-ci]
actuals:
  tokens: 7478
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [bounded argument-array Git observation, subject-driven fail-first prohibition tests]
key-files:
  created:
    - scripts/history_integrity.cjs
    - scripts/history_integrity.test.cjs
    - scripts/prohibitions/planning_identity.test.cjs
    - scripts/fixtures/prohibitions/history_rewrite.json
    - scripts/fixtures/prohibitions/history_additive.json
    - scripts/fixtures/prohibitions/planning_identity_inference.cjs
  modified:
    - scripts/lib/repository_truth.cjs
    - .planning/phases/31-repository-planning-truth/31-03-PLAN.md
key-decisions:
  - "Frozen history is evaluated from explicit base/head Git objects; a clean candidate worktree is not preservation evidence."
  - "Tag existence and peeled source SHA use distinct PIDENT diagnostics so neither authority can substitute for the other."
patterns-established:
  - "History guard: resolve complete non-shallow revisions, compare every base-frozen path byte-for-byte, and fail incomplete observation with exit 2."
  - "Prohibition proof: the same named test must pass a clean subject and fail non-vacuously for its inferential or rewriting subject."
requirements-completed: [REPO-03, REPO-04]
coverage:
  - id: D1
    description: "Committed frozen archive rewrites and prior-ledger changes fail while new archives and dated additive corrections pass."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "scripts/history_integrity.test.cjs#frozen archives and correction ledger matrix"
        status: pass
      - kind: integration
        ref: "node scripts/history_integrity.cjs --base ed209b6d92c4a3709f1044b1bac6c21dc0c7ce04 --head HEAD --json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Planning milestone, tag, peeled SHA, tagged package version, and publication evidence fail independently without cross-field inference."
    requirement: REPO-04
    verification:
      - kind: unit
        ref: "scripts/prohibitions/planning_identity.test.cjs#PROHIB-REPO-03-IDENTITY"
        status: pass
      - kind: unit
        ref: "scripts/planning_health.test.cjs"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-09-10
status: complete
---

# Phase 31 Plan 08: Repository & Planning Truth Summary

**Explicit Git-object history preservation and five-source milestone identity proof now replace worktree-relative and inferential checks.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-10T02:36:59Z
- **Completed:** 2026-09-10T02:45:47Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added a dependency-free base/head CLI that detects committed edits, deletions, renames, and replacements of archives already frozen at the base revision.
- Enforced ordered byte preservation for prior EVIDENCE ledger lines while allowing structurally valid dated corrections and genuinely new milestone archives.
- Added fail-first prohibition subjects proving five identity authorities independently, including distinct tag-only and peeled-SHA-only failures.
- Resolved both stable REPO-03 prohibition descriptors with exact target, violation-fixture, and clean-fixture paths.

## Task Commits

Each task followed the required TDD gates:

1. **Task 1 RED: cross-revision history contract** — `d2b1acb` (test)
2. **Task 1 GREEN: history integrity guard** — `348fbb7` (feat)
3. **Task 2 RED: independent identity matrix** — `6b86f5e` (test)
4. **Task 2 GREEN: authority-specific identity diagnostics** — `426c916` (fix)

## Files Created/Modified

- `scripts/history_integrity.cjs` — Bounded base/head Git-object history guard with human and deterministic JSON output.
- `scripts/history_integrity.test.cjs` — Synthetic committed-history matrix and preservation prohibition target.
- `scripts/prohibitions/planning_identity.test.cjs` — Five one-variable identity counterexamples plus v1.5/v1.0 caveat proof.
- `scripts/fixtures/prohibitions/history_rewrite.json` — Non-vacuous frozen-archive rewrite subject.
- `scripts/fixtures/prohibitions/history_additive.json` — Clean new-archive and dated-correction subject.
- `scripts/fixtures/prohibitions/planning_identity_inference.cjs` — Deliberately inferential identity evaluator.
- `scripts/lib/repository_truth.cjs` — Separate tag and peeled-SHA mismatch diagnostics.
- `.planning/phases/31-repository-planning-truth/31-03-PLAN.md` — Resolved preservation and identity prohibition metadata.

## Decisions Made

- Treat shallow repositories as incomplete evidence for this guard, even when a named commit happens to resolve locally.
- Preserve every base ledger line byte-for-byte and in order; only added nonblank lines that are valid dated correction rows are accepted.
- Split the former combined `PIDENT_TAG_SHA_MISMATCH` into authority-specific `PIDENT_TAG_MISMATCH` and `PIDENT_SOURCE_SHA_MISMATCH` diagnostics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Split conflated tag and source-SHA diagnostics**

- **Found during:** Task 2 RED
- **Issue:** A bad tag with a still-valid peeled SHA was reported against the SHA field using the same code as a bad SHA with a valid tag.
- **Fix:** Added separate tag-existence and peeled-target diagnostics with authority-specific fields and evidence.
- **Files modified:** `scripts/lib/repository_truth.cjs`
- **Verification:** New six-test identity suite and all 40 existing planning-health tests pass.
- **Committed in:** `426c916`

**2. [Rule 3 - Blocking] Reconciled progress after the state progress handler skipped**

- **Found during:** Plan closeout
- **Issue:** `state.update-progress` reported the phase scope as unscoped and left the visible 7/9 progress text unchanged despite recording eight completed summaries.
- **Fix:** Reconciled the visible progress percentage, completed-plan count, and gap-closure count to the handler-recorded 8/9 state.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Frontmatter, current position, metrics, roadmap plan list, and progress table all report eight of nine plans complete.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking issue)
**Impact on plan:** The identity fix was required for the plan's explicit two-way non-substitution guarantee, and the state reconciliation kept closeout metadata internally consistent; no unrelated behavior changed.

## Issues Encountered

- The existing implementation already separated most identity sources, but Task 2's RED phase revealed that tag and peeled SHA still shared one diagnostic. The authority-specific split resolved the ambiguity.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED and GREEN commits exist in order for both tasks.
- The Task 1 tracer feedback gate was rerun end-to-end before Task 2 expansion.

## Known Stubs

None.

## Next Phase Readiness

- Plan 31-09 can consume both resolved REPO-03 descriptors and run their fail-first targets in the recurring planning-truth CI lane.
- No blockers remain for the plan; unrelated dirty repository state remains preserved and unmodified.

## Self-Check: PASSED

- All nine created/modified artifacts exist.
- All four TDD task commits are present in Git history.

---
*Phase: 31-repository-planning-truth*
*Completed: 2026-09-10*
