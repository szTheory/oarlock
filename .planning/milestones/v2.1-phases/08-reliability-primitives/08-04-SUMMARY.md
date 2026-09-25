---
phase: 08-reliability-primitives
plan: "04"
subsystem: http
tags: [elixir, paddle, req, retry, transient, retry-after]

requires:
  - phase: 08-reliability-primitives
    provides: Plan 08-03 opts pipeline preserving Req's :retry option
provides:
  - "Paddle.Client.new!/1 configures Req with retry: :transient and max_retries: 3"
  - "Adapter-backed retry tests cover 503 success, 429 success, 422 no-retry, retry: false opt-out, and max-3 ceiling"
  - "CHANGELOG documents REL-02 and the locked v1.2 opts vocabulary"
affects: [http-boundary, create-posts, pagination, subscriptions]

tech-stack:
  added: []
  patterns:
    - "Production client owns baseline retry policy; per-call retry: false remains a pass-through Req override"
    - "Retry tests use Agent counters and retry_delay: 0 to avoid wall-clock backoff"

key-files:
  created:
    - .planning/phases/08-reliability-primitives/08-04-SUMMARY.md
  modified:
    - lib/paddle/client.ex
    - test/paddle/http_test.exs
    - CHANGELOG.md

key-decisions:
  - "Use Req's built-in :transient retry mode rather than custom retry logic."
  - "Do not expose :max_retries, :retry_delay, :retry_log_level, or :timeout as public SDK opts in v1.2."
  - "Tests set retry_delay: 0 only in the test client helper."

patterns-established:
  - "Agent-backed adapter counters are the local pattern for retry attempt assertions."
  - "Per-call Req opts can override client defaults through Http.request/4 without special SDK plumbing."

requirements-completed: [REL-02]

duration: 8min
completed: 2026-05-30
---

# Phase 08 Plan 04: Retry Policy Summary

**The default Paddle client now retries transient failures with Req's built-in policy while preserving a per-call `retry: false` opt-out.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-30T11:57:00Z
- **Completed:** 2026-05-30T12:05:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `retry: :transient` and `max_retries: 3` to `Paddle.Client.new!/1`.
- Added `client_with_retry_adapter/1` in `http_test.exs` with `retry_delay: 0` for fast deterministic retry tests.
- Added five retry-policy tests: 503 then success, 422 no retry, 429 then success, per-call `retry: false`, and persistent 503 capped at 4 total calls.
- Documented REL-02 and the public opts boundary in `CHANGELOG.md`.

## Task Commits

1. **Plan 08-04 implementation:** `11ccffd` (feat)

**Plan metadata:** final docs commit follows this SUMMARY creation.

## Files Created/Modified

- `lib/paddle/client.ex` - production Req retry config.
- `test/paddle/http_test.exs` - retry helper and five retry behavior tests.
- `CHANGELOG.md` - automatic retry policy entry.

## Decisions Made

- No custom retry function was added; Req's `:transient` mode covers the required 429/5xx/transport conditions.
- `retry_delay: 0` is test-only and does not appear in production code.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Verification

- `mix test test/paddle/http_test.exs --color` -> 20 tests, 0 failures.
- `mix compile --warnings-as-errors` -> exit 0.
- `mix test --color` -> 130 tests, 0 failures.
- `mix format --check-formatted` -> exit 0.
- `time mix test test/paddle/http_test.exs` -> about 0.9 seconds wall clock; retry tests are not sleeping.
- Spot checks confirmed production has `retry: :transient` and `max_retries: 3`, and production code does not contain `retry_delay` or `retry_log_level`.

## Phase 8 Closing Notes

- REL-03: uniform transport error shape delivered in Plans 08-01 and 08-02.
- REL-01: idempotency-key support delivered in Plan 08-03.
- REL-02: retry baseline and opt-out delivered in Plan 08-04.
- The full suite now has 130 tests and passes.

## User Setup Required

None.

## Self-Check: PASSED

## Next Phase Readiness

Phase 09 pagination helpers can inherit the client retry baseline transparently. Phase 10 subscription creation should copy the `create(..., opts \\ [])` and `Keyword.merge([json: body], opts)` shape established in Plan 08-03.

---
*Phase: 08-reliability-primitives*
*Plan: 04*
*Completed: 2026-05-30*
