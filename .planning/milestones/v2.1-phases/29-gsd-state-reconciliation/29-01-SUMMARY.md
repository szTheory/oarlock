---
phase: 29-gsd-state-reconciliation
plan: 01
subsystem: planning-state
tags: [gsd, backlog, archive, threads, paddle]

requires:
  - phase: 27-public-contract-documentation-truth
    provides: Documentation truth and provider-native recurring-start boundary.
  - phase: 28-ci-demo-and-package-proof
    provides: Current release-readiness proof context for v2.1 planning.
provides:
  - Active backlog limited to current planning candidates and explicit Accrue-only follow-up.
  - Backlog archive preserving shipped B-IDs with satisfied-by evidence.
  - Resolved thread index with durable lesson, canonical link, and reopen condition.
affects: [phase-29, future-milestone-planning, gsd-state]

tech-stack:
  added: []
  patterns:
    - Active-small, archive-rich planning state.
    - Resolved investigations retained under indexed resolved paths.

key-files:
  created:
    - .planning/BACKLOG-ARCHIVE.md
    - .planning/threads/INDEX.md
    - .planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md
  modified:
    - .planning/BACKLOG.md
    - .planning/threads/2026-05-30-subscription-create-revalidation.md

key-decisions:
  - "Keep B-04 visible only as Accrue-only consumer follow-up, not oarlock SDK scope."
  - "Move the subscription-create investigation to resolved thread memory with an explicit provider-native reopen condition."

patterns-established:
  - "Backlog archive entries preserve original B-IDs and add Satisfied by evidence."
  - "Resolved thread memory uses an index row with status, lesson, canonical link, and reopen condition."

requirements-completed: [GSD-01, GSD-02]

duration: 3 min
completed: 2026-06-25
status: complete
---

# Phase 29 Plan 01: Backlog and Thread Surface Reconciliation Summary

**Active planning surfaces now expose only current candidates while shipped backlog and resolved investigation history remain searchable through archive and index files.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-25T02:14:27Z
- **Completed:** 2026-06-25T02:17:27Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Split shipped backlog entries B-01, B-02, B-03, B-05, B-06, and B-07 into `.planning/BACKLOG-ARCHIVE.md` with preserved IDs and `Satisfied by:` evidence.
- Reduced `.planning/BACKLOG.md` to a short active queue with status taxonomy and B-04 labeled as `Accrue-only`.
- Moved the resolved subscription-create investigation under `.planning/threads/resolved/2026/` and added `.planning/threads/INDEX.md` with the durable Paddle recurring-start lesson and reopen condition.

## Task Commits

1. **Task 1: Split active backlog from historical archive** - `53678df` (docs)
2. **Task 2: Index and move resolved investigations** - `a633bc2` (docs)

**Plan metadata:** committed in the final `docs(29-01)` closeout commit.

## Files Created/Modified

- `.planning/BACKLOG.md` - Short active queue, archive pointer, status taxonomy, and B-04 Accrue-only follow-up.
- `.planning/BACKLOG-ARCHIVE.md` - Historical shipped backlog entries preserving original B-IDs and satisfied-by evidence.
- `.planning/threads/INDEX.md` - Thread status, lesson, canonical link, and reopen condition index.
- `.planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md` - Canonical resolved investigation path.
- `.planning/threads/2026-05-30-subscription-create-revalidation.md` - Removed from active-looking root thread path via git rename.

## Decisions Made

- Kept B-04 in active backlog only as Accrue-only consumer work because oarlock already shipped `raw_data`.
- Preserved resolved investigation content and indexed it instead of promoting a broader ADR set.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected oversized STATE decision entry**
- **Found during:** Metadata closeout
- **Issue:** The state decision handler accepted the full summary file as a decision entry, which made `.planning/STATE.md` too noisy for future planning context.
- **Fix:** Replaced the oversized decision block with concise Phase 29 Plan 01 decisions and corrected the Phase 29 progress line to 1/3 plans complete.
- **Files modified:** `.planning/STATE.md`
- **Verification:** Re-read `.planning/STATE.md` and confirmed the decision content is concise.
- **Committed in:** final metadata commit

## Issues Encountered

The first state decision update used the wrong handler shape for concise extraction. Fixed before the metadata commit; no production task artifacts were affected.

## User Setup Required

None - no external service configuration required.

## Verification

- `test -f .planning/BACKLOG-ARCHIVE.md && rg -n "Status Taxonomy|Accrue-only|B-04" .planning/BACKLOG.md && rg -n "B-01|B-02|B-03|B-05|B-06|B-07|Satisfied by:|Shipped" .planning/BACKLOG-ARCHIVE.md && ! rg -n "^## B-0[123567]" .planning/BACKLOG.md`
- `test -f .planning/threads/INDEX.md && test -f .planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md && test ! -f .planning/threads/2026-05-30-subscription-create-revalidation.md && rg -n "Reopen Condition|Paddle\\.Subscriptions\\.create/2|transaction/checkout|invoice-backed|resolved/2026/2026-05-30-subscription-create-revalidation.md" .planning/threads/INDEX.md .planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md`
- `rg -n "B-0[123567]" .planning/BACKLOG.md .planning/BACKLOG-ARCHIVE.md`
- `rg -n '=\\[\\]|=\\{\\}|=null|=""|not available|coming soon|placeholder|TODO|FIXME' .planning/BACKLOG.md .planning/BACKLOG-ARCHIVE.md .planning/threads/INDEX.md .planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md || true`

## Known Stubs

None.

## Threat Flags

None.

## Next Phase Readiness

Ready for 29-02 to reconcile v2.0 evidence ledger and audit wording now that backlog and thread surfaces no longer over-signal stale scope.

## Self-Check: PASSED

- Summary exists at `.planning/phases/29-gsd-state-reconciliation/29-01-SUMMARY.md`.
- Task commits exist: `53678df`, `a633bc2`.
- Key created files exist: `.planning/BACKLOG-ARCHIVE.md`, `.planning/threads/INDEX.md`, `.planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md`.

---
*Phase: 29-gsd-state-reconciliation*
*Completed: 2026-06-25*
