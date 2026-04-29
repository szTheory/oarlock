---
phase: 03-core-entities-customers-addresses
plan: "02"
subsystem: api
tags: [elixir, paddle, req, addresses, customers]
requires:
  - phase: 03-01
    provides: customer entity, explicit client resource conventions, allowlisted write normalization
provides:
  - Paddle.Address struct with promoted fields and raw_data preservation
  - Paddle.Customers.Addresses.create/3, get/3, and update/4 over customer-scoped paths
  - Adapter-backed tests for scoped paths, allowlists, nil-preserving PATCH bodies, and tuple alignment
affects: [phase-03, transactions, billing-addresses]
tech-stack:
  added: []
  patterns: [struct-only entity modules, resource-local data envelope unwrapping, per-endpoint write allowlists]
key-files:
  created: [lib/paddle/address.ex, lib/paddle/customers/addresses.ex, test/paddle/address_test.exs, test/paddle/customers/addresses_test.exs]
  modified: []
key-decisions:
  - "Kept address ownership explicit in every public function signature via customer_id and address_id path arguments."
  - "Used separate create and update allowlists so read-only fields stay out of writes while PATCH bodies still preserve explicit nil values."
patterns-established:
  - "Map Paddle entity payloads by unwrapping the local data envelope and passing the inner map to Paddle.Http.build_struct/2."
  - "Validate only blank path IDs and attrs container shape locally, then preserve Paddle.Http.request/4 error tuples unchanged."
requirements-completed: [ADDR-01]
duration: 3 min
completed: 2026-04-29
---

# Phase 03 Plan 02: Customer Addresses Summary

**Customer-scoped Paddle addresses with typed `%Paddle.Address{}` mapping, explicit ownership in public signatures, and allowlisted PATCH-safe writes**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-29T00:54:00Z
- **Completed:** 2026-04-29T00:56:51Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `%Paddle.Address{}` with the researched top-level address fields and `raw_data`.
- Implemented `Paddle.Customers.Addresses.create/3`, `get/3`, and `update/4` against nested `/customers/{customer_id}/addresses` paths.
- Locked request shaping and tuple behavior with adapter-backed tests for allowlists, nil-preserving PATCH bodies, local validation tuples, API errors, and transport passthrough.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the `%Paddle.Address{}` contract and lock its field surface** - `3588180` (feat)
2. **Task 2: Implement scoped address create/get/update with separate allowlists** - `518390c` (feat)

## Files Created/Modified
- `lib/paddle/address.ex` - Defines the address entity contract used by `Paddle.Http.build_struct/2`.
- `lib/paddle/customers/addresses.ex` - Implements the scoped address resource functions and local validation helpers.
- `test/paddle/address_test.exs` - Freezes the address struct field surface and `raw_data` behavior.
- `test/paddle/customers/addresses_test.exs` - Verifies scoped CRUD request shaping and public tuple behavior with Req adapters.

## Decisions Made
- Kept the nested resource boundary explicit by requiring `customer_id` on every public address function and `address_id` on entity reads and updates.
- Mirrored the existing customer module pattern: unwrap `"data"` locally, map with `Paddle.Http.build_struct/2`, and leave API and transport failure tuples unchanged.
- Split create and update allowlists so `status` is update-only and unsupported fields like `import_meta` never leave the SDK.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The SDK now has both customer entities and customer-scoped address entities available for downstream transaction work.
- The remaining Phase 3 address slice can build `list/3` on top of the same explicit path, envelope-unwrapping, and page-mapping conventions.

## Self-Check: PASSED

---
*Phase: 03-core-entities-customers-addresses*
*Completed: 2026-04-29*
