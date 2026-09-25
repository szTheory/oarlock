---
phase: 08-reliability-primitives
plan: "01"
subsystem: errors
tags: [elixir, paddle, error-shape, raw_data, network-error, retryable, changelog]

requires:
  - phase: 01-core-transport-client-setup
    provides: Baseline %Paddle.Error{} response mapping and Req-backed HTTP boundary
provides:
  - "%Paddle.Error{} now uses :raw_data instead of :raw"
  - "%Paddle.Error{} has explicit false defaults for :network_error? and :retryable?"
  - Consumer-facing changelog and seam-guide documentation for the breaking field rename
affects: [accrue, transport-error-normalization, reliability-primitives]

tech-stack:
  added: []
  patterns:
    - "Error structs use keyword-default defexception fields so boolean flags default to false, not nil"
    - "Paddle.Error.from_response/1 leaves transport/retry booleans at their false defaults"

key-files:
  created:
    - .planning/phases/08-reliability-primitives/08-01-SUMMARY.md
  modified:
    - lib/paddle/error.ex
    - test/paddle/error_test.exs
    - guides/accrue-seam.md
    - CHANGELOG.md
    - .planning/BACKLOG.md

key-decisions:
  - "The :raw -> :raw_data rename is total for %Paddle.Error{}; no transitional dual field was introduced."
  - "Elixir formatter expands the defexception keyword list vertically; the behavior matches the plan even though one plan grep expected a compact line shape."
  - "Accrue-side migration is tracked as backlog B-04 and does not block oarlock Phase 08."

patterns-established:
  - "Error-shape changes must move code, focused tests, seam docs, and changelog together."
  - "Downstream consumer migration notes live in .planning/BACKLOG.md rather than blocking SDK implementation."

requirements-completed: [REL-03]

duration: 12min
completed: 2026-05-30
---

# Phase 08 Plan 01: Paddle.Error raw_data Rename Summary

**%Paddle.Error{} now matches the SDK-wide raw_data escape-hatch convention and carries explicit false defaults for network/retry booleans.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-30T11:24:45Z
- **Completed:** 2026-05-30T11:36:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Replaced `%Paddle.Error{raw: ...}` with `%Paddle.Error{raw_data: ...}` in source and focused tests.
- Added `network_error?: false` and `retryable?: false` to the `defexception` declaration and locked those defaults with four tests.
- Updated `guides/accrue-seam.md` so the documented `%Paddle.Error{}` escape hatch is `:raw_data`.
- Added top-level `[Unreleased]` changelog entries for the breaking rename and the two new boolean fields.
- Added `.planning/BACKLOG.md` B-04 to track the downstream Accrue migration note.

## Task Commits

1. **Plan 08-01 implementation:** `01f3552` (feat)

**Plan metadata:** final docs commit follows this SUMMARY creation.

## Files Created/Modified

- `lib/paddle/error.ex` - keyword-default exception fields, `raw_data: body` in `from_response/1`.
- `test/paddle/error_test.exs` - `raw_data` assertions plus struct/default tests for both booleans.
- `guides/accrue-seam.md` - `%Paddle.Error{}` field table now documents `:raw_data`.
- `CHANGELOG.md` - `[Unreleased]` breaking-change and added-field notes.
- `.planning/BACKLOG.md` - B-04 Accrue migration note.

## Decisions Made

- No dual-population period for `:raw` and `:raw_data`; the rename is direct per the phase decision log.
- Kept the formatted `defexception` layout. The plan's exact grep expected a compact multiline form, but `mix format --check-formatted` requires the vertical keyword layout on this Elixir formatter version.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Formatting correctness] Kept Elixir formatter output for defexception**
- **Found during:** Task 1 acceptance checks.
- **Issue:** The plan's grep expected `defexception type: nil, code: nil, ...` on one line, but `mix format --check-formatted` rejects that shape and rewrites the keyword list vertically.
- **Fix:** Kept the formatter-approved code. The semantic requirements are satisfied: keyword defaults are present, `raw_data` exists, and both booleans default to `false`.
- **Files modified:** `lib/paddle/error.ex`
- **Verification:** `mix format --check-formatted lib/paddle/error.ex` passes after formatting; `mix test test/paddle/error_test.exs --color` passes.
- **Committed in:** `01f3552`.

**Total deviations:** 1 auto-fixed formatting deviation.
**Impact on plan:** No behavior change. The implementation is formatter-compliant and preserves every requested field/default.

## Issues Encountered

None beyond the formatter-vs-grep shape described above.

## Verification

- `mix test test/paddle/error_test.exs --color` -> 7 tests, 0 failures.
- `mix compile --warnings-as-errors` -> exit 0.
- `mix test --color` -> 115 tests, 0 failures.
- Acceptance spot checks confirmed zero `raw:` references in `lib/paddle/error.ex` and `test/paddle/error_test.exs`, zero guide rows for `:raw`, changelog entries present, and B-04 present as the last backlog entry.

## User Setup Required

None.

## Self-Check: PASSED

## Next Phase Readiness

Plan 08-02 can now build `Paddle.Error.from_transport/1` on the new `%Paddle.Error{raw_data:, network_error?:, retryable?:}` shape without further struct changes.

---
*Phase: 08-reliability-primitives*
*Plan: 01*
*Completed: 2026-05-30*
