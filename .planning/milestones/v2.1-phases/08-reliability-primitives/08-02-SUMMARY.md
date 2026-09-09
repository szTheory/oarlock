---
phase: 08-reliability-primitives
plan: "02"
subsystem: errors
tags: [elixir, paddle, transport-error, network-error, retryable, req]

requires:
  - phase: 08-reliability-primitives
    provides: Plan 08-01 %Paddle.Error{} raw_data field and network/retry boolean defaults
provides:
  - "Paddle.Error.from_transport/1 maps Req.TransportError values into normalized Paddle.Error structs"
  - "Paddle.Http.request/4 normalizes transport failures while preserving the non-TransportError catch-all"
  - "Transport-error expectations across resource tests now match the normalized error contract"
affects: [http-boundary, resource-error-handling, accrue]

tech-stack:
  added: []
  patterns:
    - "Transport errors normalize at the Http.request/4 chokepoint before resource modules receive them"
    - "Stable network type taxonomy: network_timeout, network_nxdomain, network_closed, network_unknown"

key-files:
  created:
    - .planning/phases/08-reliability-primitives/08-02-SUMMARY.md
  modified:
    - lib/paddle/error.ex
    - lib/paddle/http.ex
    - test/paddle/http_test.exs
    - test/paddle/customers_test.exs
    - test/paddle/customers/addresses_test.exs
    - test/paddle/transactions_test.exs
    - test/paddle/subscriptions_test.exs
    - CHANGELOG.md

key-decisions:
  - "Only %Req.TransportError{} is normalized; non-transport errors still pass through unchanged."
  - "The :econnrefused reason stays in the catch-all network_unknown bucket for v1.2."
  - "Resource-level tests were updated because every public resource flows through the same Http.request/4 chokepoint."

patterns-established:
  - "Resource modules should assert normalized %Paddle.Error{} transport failures, not leaked Req exceptions."
  - "HTTP response errors keep network_error?: false by staying on from_response/1."

requirements-completed: [REL-03]

duration: 11min
completed: 2026-05-30
---

# Phase 08 Plan 02: Transport Error Normalization Summary

**Req transport failures now return a single `%Paddle.Error{network_error?: true, retryable?: true}` shape across the HTTP boundary and all resource modules.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-05-30T11:36:00Z
- **Completed:** 2026-05-30T11:47:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `Paddle.Error.from_transport/1`, preserving the original `%Req.TransportError{}` in `:raw_data`.
- Added private `transport_type/1` clauses for `:timeout`, `:nxdomain`, `:closed`, and a catch-all `"network_unknown"`.
- Refactored `Paddle.Http.request/4` with a `%Req.TransportError{}` arm before the existing catch-all.
- Replaced the old direct `Req.TransportError` expectation in `http_test.exs` with four taxonomy tests.
- Updated stale resource-level tests to assert normalized `%Paddle.Error{}` transport failures.
- Documented `Paddle.Error.from_transport/1` and REL-03 in the changelog.

## Task Commits

1. **Plan 08-02 implementation:** `c7341ae` (feat)

**Plan metadata:** final docs commit follows this SUMMARY creation.

## Files Created/Modified

- `lib/paddle/error.ex` - new transport constructor and taxonomy helper.
- `lib/paddle/http.ex` - `%Req.TransportError{}` normalization arm.
- `test/paddle/http_test.exs` - four adapter-backed transport taxonomy tests.
- `test/paddle/customers_test.exs`, `test/paddle/customers/addresses_test.exs`, `test/paddle/transactions_test.exs`, `test/paddle/subscriptions_test.exs` - resource tests now expect normalized transport errors.
- `CHANGELOG.md` - `Paddle.Error.from_transport/1` REL-03 entry.

## Decisions Made

- Kept the non-TransportError catch-all in `Http.request/4` unchanged, so only the transport class is normalized in v1.2.
- Left HTTP 5xx response errors on `from_response/1`; they continue to inherit `network_error?: false`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Test contract drift] Updated resource-level transport expectations**
- **Found during:** Full-suite verification.
- **Issue:** Plan 08-02 listed `http_test.exs`, but existing customers, addresses, transactions, and subscriptions tests still asserted the previous v1.1 behavior of leaking `%Req.TransportError{}`. After normalizing at `Http.request/4`, those expectations were stale.
- **Fix:** Updated resource tests to expect `%Paddle.Error{type: "network_timeout", network_error?: true, retryable?: true}`.
- **Files modified:** `test/paddle/customers_test.exs`, `test/paddle/customers/addresses_test.exs`, `test/paddle/transactions_test.exs`, `test/paddle/subscriptions_test.exs`.
- **Verification:** Targeted resource test batch passed; full `mix test --color` passed with 118 tests, 0 failures.
- **Committed in:** `c7341ae`.

**Total deviations:** 1 auto-fixed test-contract drift.
**Impact on plan:** This aligns all public resources with the new REL-03 behavior and avoids carrying contradictory tests.

## Issues Encountered

The first full test run failed 5 tests that still expected raw `%Req.TransportError{}`. They were updated as described above.

## Verification

- `mix test test/paddle/error_test.exs --color` -> 7 tests, 0 failures.
- `mix test test/paddle/http_test.exs --color` -> 8 tests, 0 failures.
- Targeted resource batch (`transactions`, `subscriptions`, `customers`, `customers/addresses`) -> 63 tests, 0 failures.
- `mix compile --warnings-as-errors` -> exit 0.
- `mix test --color` -> 118 tests, 0 failures.
- `mix format --check-formatted` -> exit 0.

## User Setup Required

None.

## Self-Check: PASSED

## Next Phase Readiness

Plan 08-03 can thread `idempotency_key:` through create calls on top of the normalized error boundary. The `Http.request/4` catch-all remains available for non-transport exceptions.

---
*Phase: 08-reliability-primitives*
*Plan: 02*
*Completed: 2026-05-30*
