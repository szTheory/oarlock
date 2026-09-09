---
phase: 09-pagination-ergonomics
plan: "01"
subsystem: pagination
tags: [elixir, paddle, pagination, stream, enumerable, cursor]

requires:
  - phase: 08-reliability-primitives
    provides: Req-backed HTTP retry/error behavior inherited by subsequent page fetches
provides:
  - "Paddle.Internal.Pagination streams or eagerly collects items across Paddle cursor pages"
  - "Paddle.Subscriptions.stream/2 and all/2 expose per-resource auto-pagination"
  - "Paddle.Customers.Addresses.stream/3 and all/3 expose nested-resource auto-pagination"
  - "Adapter-backed tests pin ordering, equivalence, laziness, errors, and cursor replay"
affects: [subscriptions, customer-addresses, public-docs, pagination]

tech-stack:
  added: []
  patterns:
    - "Per-resource stream/all wrappers delegate first-page and next-page callbacks to a hidden internal engine"
    - "Paddle next URLs are normalized to path?query before dispatch through Paddle.Http.request/4"
    - "Auto-pagination continuation uses meta.pagination.has_more, not next_cursor/1 non-nil checks"

key-files:
  created:
    - lib/paddle/internal/pagination.ex
    - guides/getting-started.md
    - .planning/phases/09-pagination-ergonomics-0-plans/09-01-SUMMARY.md
  modified:
    - lib/paddle/subscriptions.ex
    - lib/paddle/customers/addresses.ex
    - test/paddle/page_test.exs
    - test/paddle/subscriptions_test.exs
    - test/paddle/customers/addresses_test.exs
    - guides/accrue-seam.md
    - CHANGELOG.md

key-decisions:
  - "Keep pagination helpers colocated on resource modules rather than adding a public root-level pagination API."
  - "Keep Paddle.Page.next_cursor/1 as a raw next-reference accessor; the internal engine owns has_more continuation semantics."
  - "Raise during lazy stream enumeration for callback errors, while all/* returns tagged errors without partial results."

patterns-established:
  - "Resource modules own page mapping and next_page/2; Paddle.Internal.Pagination owns traversal and error semantics."
  - "Adapter-backed request sequences assert normalized replay paths and prove lazy consumers do not fetch unused pages."

requirements-completed: [PAGE-01]

duration: 24min
completed: 2026-05-30
---

# Phase 09 Plan 01: Pagination Ergonomics Summary

**Per-resource auto-pagination now streams and eagerly collects subscriptions and customer addresses without changing the locked list-page API.**

## Performance

- **Duration:** ~24 min
- **Started:** 2026-05-30T12:18:00Z
- **Completed:** 2026-05-30T12:41:41Z
- **Tasks:** 4
- **Files modified:** 9

## Accomplishments

- Added hidden `Paddle.Internal.Pagination` with lazy `stream/2` and eager `all/2` traversal over `%Paddle.Page{}` callbacks.
- Added `Paddle.Subscriptions.stream/2`, `Paddle.Subscriptions.all/2`, `Paddle.Customers.Addresses.stream/3`, and `Paddle.Customers.Addresses.all/3`.
- Preserved `Paddle.Subscriptions.list/2`, `Paddle.Customers.Addresses.list/3`, and `Paddle.Page.next_cursor/1` return shapes.
- Added adapter-backed coverage for three-page ordering, stream/all equivalence, page-2 errors, invalid initial validation, lazy early-stop behavior, absolute and relative cursor replay, nested address paths, and `has_more: false` with non-nil `next`.
- Updated seam docs, getting-started examples, and changelog with stream/all behavior and caveats.

## Task Commits

1. **Task 1: Add adapter-backed pagination contract tests** - `a420b7c` (test)
2. **Task 2/3: Implement hidden engine and resource wrappers** - `14114af` (feat)
3. **Test formatting cleanup** - `9d39980` (test)
4. **Task 4: Document helper surface** - `d32b44a` (docs)

**Plan metadata:** final docs commit follows this SUMMARY creation.

## Files Created/Modified

- `lib/paddle/internal/pagination.ex` - hidden traversal engine using `Stream.resource/3`, `Paddle.Page.next_cursor/1`, `has_more`, and `URI.parse/1`.
- `lib/paddle/subscriptions.ex` - public `stream/2` and `all/2` wrappers plus private `next_page/2` and `build_page/2`.
- `lib/paddle/customers/addresses.ex` - public `stream/3` and `all/3` wrappers plus private `next_page/2` and `build_page/2`.
- `test/paddle/page_test.exs` - regression proving `next_cursor/1` may be non-nil when `has_more` is false.
- `test/paddle/subscriptions_test.exs` - stream/all contract, failure, laziness, and cursor replay tests.
- `test/paddle/customers/addresses_test.exs` - nested-address stream/all contract, failure, laziness, and cursor replay tests.
- `guides/accrue-seam.md` - documented the new locked public helper surface and next-cursor semantics.
- `guides/getting-started.md` - added stream/all examples and memory/error caveats.
- `CHANGELOG.md` - added PAGE-01 release note.

## Decisions Made

- Followed the phase decision to expose only per-resource helpers and keep `Paddle.Internal.Pagination` hidden with `@moduledoc false`.
- Implemented `all/2` with tuple control flow instead of rescuing stream exceptions, so eager collection never returns partial results.
- Kept subsequent-page fetching resource-private so each module reuses its existing page mapper and locked list shape.

## Deviations from Plan

### Process Deviations

**1. Combined Task 2 and Task 3 into one implementation commit**
- **Found during:** Task 3 close-out
- **Issue:** The internal engine and resource wrappers were tightly coupled enough that they were committed together rather than as separate Task 2 and Task 3 commits.
- **Fix:** Documented the combined commit explicitly in this summary; behavioral verification covers both task acceptance sets.
- **Files modified:** `lib/paddle/internal/pagination.ex`, `lib/paddle/subscriptions.ex`, `lib/paddle/customers/addresses.ex`
- **Verification:** Targeted pagination suite passed with 54 tests, 0 failures.
- **Committed in:** `14114af`

---

**Total deviations:** 1 process deviation.
**Impact on plan:** No behavioral scope change. Commit granularity is less strict than the plan requested, but each deliverable is covered by tests and source assertions.

## Issues Encountered

- `guides/getting-started.md` existed as a pre-existing untracked file before Phase 9 execution. The file was preserved, updated for PAGE-01, and included in the docs commit because the phase explicitly required that guide update.

## Verification

- Initial RED run: `mix test test/paddle/page_test.exs test/paddle/subscriptions_test.exs test/paddle/customers/addresses_test.exs --color` -> 54 tests, 14 expected missing-helper failures.
- Targeted GREEN run after implementation: `mix test test/paddle/page_test.exs test/paddle/subscriptions_test.exs test/paddle/customers/addresses_test.exs --color` -> 54 tests, 0 failures.
- Final targeted run: `mix test test/paddle/page_test.exs test/paddle/subscriptions_test.exs test/paddle/customers/addresses_test.exs --color` -> 54 tests, 0 failures.
- `mix compile --warnings-as-errors` -> exit 0.
- `mix test --color` -> 145 tests, 0 failures.
- `mix format --check-formatted` -> exit 0.
- Source/doc assertion greps from the plan all returned hits for internal pagination, resource wrappers, seam docs, getting-started examples, and PAGE-01 changelog text.

## User Setup Required

None.

## Self-Check: PASSED

## Next Phase Readiness

Phase 10 can continue building subscription mutations on the existing resource-module pattern. The pagination engine is hidden and callback-based, so future list endpoints can add colocated stream/all helpers without changing the public root module or `%Paddle.Page{}` shape.

---
*Phase: 09-pagination-ergonomics*
*Plan: 01*
*Completed: 2026-05-30*
