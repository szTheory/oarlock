---
phase: 01-core-transport-client-setup
plan: "03"
subsystem: api
tags: [elixir, req, http, errors, raw-data]
requires:
  - phase: 01-02
    provides: configured Paddle.Client req instance
provides:
  - Paddle.Http request execution boundary
  - Standard ok/error tuple mapping for Paddle API interactions
  - Generic struct builder that preserves raw API payloads
affects: [customers, addresses, transactions, subscriptions]
tech-stack:
  added: []
  patterns: [tuple response normalization, raw payload preservation, tdd]
key-files:
  created:
    - lib/paddle/http.ex
    - test/paddle/http_test.exs
  modified: []
key-decisions:
  - "Map non-2xx responses through Paddle.Error.from_response/1 instead of trusting Req's status semantics."
  - "Preserve forward compatibility by storing the raw response map in struct raw_data."
patterns-established:
  - "HTTP entrypoints return {:ok, body} or {:error, exception} tuples."
  - "Struct decoders only map known fields and keep the original payload."
requirements-completed: [CORE-02, CORE-04]
duration: 1min
completed: 2026-04-28
---

# Phase 1: Core Transport & Client Setup Summary

**HTTP execution boundary that normalizes Paddle responses into strict tuples and preserves raw payloads for future entity decoding**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-28T17:45:38-04:00
- **Completed:** 2026-04-28T21:45:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `Paddle.Http.request/4` to execute requests via `client.req` and normalize success, API error, and transport error outcomes.
- Added `Paddle.Http.build_struct/2` to decode string-keyed maps into typed structs while retaining `raw_data`.
- Covered success, failure, and transport paths with unit tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement HTTP Execution Module** - `14a555e`, `4a07f51` (`test` -> `feat`)
2. **Task 2: Implement struct decoding with raw payloads** - `14a555e`, `4a07f51` (shared test + feature commit)

**Plan metadata:** Recorded in the summary commit for this plan.

_Note: Both tasks were implemented in the same module and validated together by the shared HTTP test file._

## Files Created/Modified

- `lib/paddle/http.ex` - Request execution and struct decoding helpers.
- `test/paddle/http_test.exs` - Coverage for tuple normalization and raw-data struct decoding.

## Decisions Made

- Used `Keyword.merge/2` to apply method and path on each request call while reusing the client's configured Req state.
- Used `String.to_existing_atom/1` inside the decoder so only declared struct keys are mapped.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Req retries had to be disabled in the transport-error test helper to keep the failure-path tests fast and deterministic.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The core transport layer is now ready for higher-level Paddle resources to build on.
- Future phases can reuse `Paddle.Http.request/4` and `build_struct/2` for entity modules without redefining error handling.

---
*Phase: 01-core-transport-client-setup*
*Completed: 2026-04-28*
