---
phase: 03-core-entities-customers-addresses
plan: "01"
subsystem: api
tags: [elixir, paddle, req, customers, structs]
requires:
  - phase: 01-core-transport-client-setup
    provides: explicit client passing, HTTP tuple boundary, struct hydration via Paddle.Http.build_struct/2
  - phase: 02-webhook-verification
    provides: lightweight public-boundary validation style for typed tuple APIs
provides:
  - Paddle.Customer struct with promoted customer fields and raw payload preservation
  - Paddle.Customers.create/2, get/2, and update/3 over explicit %Paddle.Client{} passing
  - allowlisted customer request shaping that preserves PATCH nil clears
affects: [03-02, addresses, transactions, subscriptions]
tech-stack:
  added: []
  patterns: [struct-only entity modules, resource-local Paddle data unwrapping, per-endpoint write allowlists]
key-files:
  created:
    - lib/paddle/customer.ex
    - lib/paddle/customers.ex
    - test/paddle/customer_test.exs
    - test/paddle/customers_test.exs
  modified: []
key-decisions:
  - "Kept Paddle success-envelope unwrapping inside Paddle.Customers instead of changing Paddle.Http.request/4."
  - "Normalized map and keyword attrs to string-key maps, then applied separate create and update allowlists."
patterns-established:
  - "Entity contract pattern: define promoted Paddle fields in a struct-only module and rely on Paddle.Http.build_struct/2 for raw_data preservation."
  - "Resource boundary pattern: validate IDs and attr container shape locally, then delegate API and transport tuple semantics to Paddle.Http.request/4."
requirements-completed: [CUST-01]
duration: 2 min
completed: 2026-04-28
---

# Phase 3 Plan 01: Customer entity contract and CRUD boundary Summary

**Typed Paddle customer structs plus explicit client-backed create/get/update functions with allowlisted writes and preserved PATCH nil semantics**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-29T00:49:59Z
- **Completed:** 2026-04-29T00:51:50Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `%Paddle.Customer{}` with the researched promoted field surface and `raw_data` escape hatch.
- Implemented `Paddle.Customers.create/2`, `get/2`, and `update/3` over explicit `%Paddle.Client{}` passing.
- Locked request shaping, local validation tuples, API-error alignment, and transport passthrough in focused ExUnit coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the `%Paddle.Customer{}` contract and lock its field surface** - `3f1f063` (feat)
2. **Task 2: Implement `Paddle.Customers.create/2`, `get/2`, and `update/3` with allowlisted request shaping** - `b72706f` (feat)

## Files Created/Modified
- `lib/paddle/customer.ex` - Customer entity struct with promoted top-level Paddle fields and `raw_data`.
- `lib/paddle/customers.ex` - Customer CRUD resource module with local validation, allowlists, and typed response mapping.
- `test/paddle/customer_test.exs` - Struct contract and hydration coverage for `%Paddle.Customer{}`.
- `test/paddle/customers_test.exs` - Resource request/response coverage for customer CRUD behavior and tuple semantics.

## Decisions Made
- Kept `"data"` envelope unwrapping local to `Paddle.Customers` so `Paddle.Http.request/4` remains list-response friendly for later paginated resources.
- Used separate create and update allowlists to prevent write-forbidden fields like `marketing_consent` and `import_meta` from leaking into outbound requests.
- Preserved explicit `nil` values for allowlisted update keys so PATCH clears survive request shaping.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Customer entity and CRUD boundary are ready for downstream billing flows to depend on without changing tuple or client conventions.
- The next customer-address plan can reuse the same entity/resource split, local validation style, and allowlist pattern.

## Self-Check: PASSED

- Verified summary file and all four plan-created code/test files exist on disk.
- Verified task commits `3f1f063` and `b72706f` exist in git history.
