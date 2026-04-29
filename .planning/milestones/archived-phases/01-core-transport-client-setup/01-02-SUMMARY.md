---
phase: 01-core-transport-client-setup
plan: "02"
subsystem: api
tags: [elixir, req, telemetry, client]
requires:
  - phase: 01-01
    provides: foundational error and pagination structs
provides:
  - Explicit Paddle.Client constructor with environment-aware Req configuration
  - Paddle-specific telemetry middleware for request start, stop, and exception events
affects: [http, webhooks, customers, subscriptions]
tech-stack:
  added: []
  patterns: [explicit client instantiation, req step instrumentation, tdd]
key-files:
  created:
    - lib/paddle/http/telemetry.ex
    - lib/paddle/client.ex
    - test/paddle/http/telemetry_test.exs
    - test/paddle/client_test.exs
  modified: []
key-decisions:
  - "Keep API key and environment on the client struct instead of reading application config."
  - "Emit Paddle-specific telemetry via custom Req steps instead of relying on global Req events."
patterns-established:
  - "Client construction returns a fully configured Req.Request stored on Paddle.Client."
  - "Telemetry events wrap request lifecycle boundaries with request and response metadata."
requirements-completed: [CORE-01, CORE-02]
duration: 2min
completed: 2026-04-28
---

# Phase 1: Core Transport & Client Setup Summary

**Explicit Paddle client construction with environment-aware Req configuration and isolated Paddle telemetry events**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-28T17:44:09-04:00
- **Completed:** 2026-04-28T21:45:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Paddle.Http.Telemetry.attach/1` to instrument request start, stop, and exception events.
- Added `Paddle.Client.new!/1` with explicit API key passing, environment-specific base URLs, and the `Paddle-Version` header.
- Covered both modules with request-pipeline and constructor tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement Telemetry Middleware** - `ac946f0`, `da1f40b` (`test` -> `feat`)
2. **Task 2: Implement Client Struct** - `e04c2d3`, `23c4067` (`test` -> `feat`)

**Plan metadata:** Formatting cleanup recorded in `e1f48f6`.

_Note: TDD tasks used separate test and implementation commits._

## Files Created/Modified

- `lib/paddle/http/telemetry.ex` - Req step hooks for Paddle telemetry events.
- `lib/paddle/client.ex` - Client struct and constructor.
- `test/paddle/http/telemetry_test.exs` - Middleware coverage for request lifecycle events.
- `test/paddle/client_test.exs` - Constructor and Req configuration coverage.

## Decisions Made

- Chose direct Req adapter-based tests for telemetry instead of adding `:plug` just to use `Req.Test`.
- Stored base URL configuration inside the Req options and preserved the API version header on the request struct.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `Req.Test` required an unplanned `:plug` dependency, so the telemetry tests were rewritten against Req's adapter contract to keep phase scope minimal.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The HTTP boundary can now depend on a stable `Paddle.Client` shape and on emitted telemetry events.
- Phase `01-03` can execute requests through the configured `req` instance without introducing new configuration paths.

---
*Phase: 01-core-transport-client-setup*
*Completed: 2026-04-28*
