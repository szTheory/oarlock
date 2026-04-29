---
phase: 04-transactions-hosted-checkout
plan: "01"
subsystem: payments
tags: [paddle, transactions, hosted-checkout, struct-contract, tdd]

# Dependency graph
requires:
  - phase: 01-core-transport-client-setup
    provides: Paddle.Http.build_struct/2 shallow top-level mapper plus raw_data preservation contract
  - phase: 03-core-entities-customers-addresses
    provides: Established entity-struct + raw_data convention mirrored by Paddle.Customer and Paddle.Address
provides:
  - Paddle.Transaction struct with the locked Phase 4 top-level field surface (id, status, customer_id, address_id, business_id, custom_data, currency_code, origin, subscription_id, invoice_number, collection_mode, items, details, payments, checkout, created_at, updated_at, billed_at, revised_at, raw_data)
  - Paddle.Transaction.Checkout struct with exactly :url and :raw_data so transaction.checkout.url dot access is contract-locked
  - Executable contract coverage in test/paddle/transaction_test.exs that freezes both struct shapes and raw-data preservation behavior
affects:
  - 04-02 transactions resource (Paddle.Transactions.create/2 will rely on this typed surface and on a private build_transaction/1 helper to hydrate the nested checkout struct)
  - Phase 5 subscriptions (subscription_id field on Paddle.Transaction is the future link to the subscription entity)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Struct-only entity module mirrors Paddle.Customer / Paddle.Address with :raw_data as the last field so Paddle.Http.build_struct/2 can hydrate it."
    - "Tiny nested struct (Paddle.Transaction.Checkout) reserved for stable nested branches that must support Elixir dot access; broader nested transaction payloads stay as plain maps inside :raw_data."
    - "TDD red/green discipline applied at the struct-contract layer before any resource module depends on it."

key-files:
  created:
    - lib/paddle/transaction.ex
    - lib/paddle/transaction/checkout.ex
    - test/paddle/transaction_test.exs
  modified: []

key-decisions:
  - "Lock the Paddle.Transaction first-pass field list to the researched stable top-level surface only; broader nested branches stay in :raw_data for forward compatibility."
  - "Make Paddle.Transaction.Checkout a dedicated struct (not a string-key map) so transaction.checkout.url is a guaranteed dot-access contract, satisfying D-13."
  - "Keep both modules transport-free; the resource module added in 04-02 will own envelope handling and the build_transaction/1 nested-checkout hydration step."

patterns-established:
  - "Struct-only entity contract: defstruct list ends with :raw_data and pairs with Paddle.Http.build_struct/2 for top-level promotion."
  - "Nested-shape struct contract: small dedicated struct module under lib/paddle/{entity}/{nested}.ex when a nested branch must support dot access."
  - "Contract-first TDD for entity surfaces: write the failing struct + build_struct/2 test, then add the struct module to satisfy it."

requirements-completed: [TXN-02]

# Metrics
duration: 1.8min
completed: 2026-04-29
---

# Phase 04 Plan 01: Transaction Entity & Nested Checkout Contract Summary

**Locked the Phase 4 transaction surface as Paddle.Transaction (researched top-level fields plus :raw_data) and Paddle.Transaction.Checkout ({:url, :raw_data}) so transaction.checkout.url is a contract-locked dot-access path before the create resource depends on it.**

## Performance

- **Duration:** ~1.8 min
- **Started:** 2026-04-29T02:14:36Z
- **Completed:** 2026-04-29T02:16:26Z
- **Tasks:** 2
- **Files created:** 3
- **Files modified:** 0

## Accomplishments
- Defined `Paddle.Transaction` with the exact 20-field surface called out in 04-RESEARCH.md (`:id`, `:status`, `:customer_id`, `:address_id`, `:business_id`, `:custom_data`, `:currency_code`, `:origin`, `:subscription_id`, `:invoice_number`, `:collection_mode`, `:items`, `:details`, `:payments`, `:checkout`, `:created_at`, `:updated_at`, `:billed_at`, `:revised_at`, `:raw_data`).
- Defined `Paddle.Transaction.Checkout` with exactly `:url` and `:raw_data`, satisfying D-03 / D-13 so `transaction.checkout.url` is a real Elixir dot-access contract instead of a leaked string-key map.
- Added `test/paddle/transaction_test.exs` with executable assertions for both struct shapes and for `Paddle.Http.build_struct/2` mapping behavior, including unknown-key isolation in `:raw_data`.
- Confirmed no regressions: full `mix test` suite went from `1 doctest, 59 tests, 0 failures` (baseline) to `1 doctest, 63 tests, 0 failures` after this plan.

## Task Commits

Each task was committed atomically following TDD discipline:

1. **Task 1 (RED): Add failing contract tests for `Paddle.Transaction` and `Paddle.Transaction.Checkout`** — `5a71553` (test)
2. **Task 2 (GREEN): Implement `Paddle.Transaction` and `Paddle.Transaction.Checkout` struct modules** — `61a9b6a` (feat)

No REFACTOR commit was needed — the struct modules were already in their minimal final form.

**Plan metadata commit:** added in the post-summary metadata commit by the executor (this file plus REQUIREMENTS.md changes if any).

## Files Created/Modified
- `lib/paddle/transaction.ex` — Paddle.Transaction struct module with the locked Phase 4 top-level field surface plus `:raw_data`.
- `lib/paddle/transaction/checkout.ex` — Paddle.Transaction.Checkout struct module with exactly `:url` and `:raw_data` for contract-locked dot access.
- `test/paddle/transaction_test.exs` — ExUnit contract coverage for both struct shapes and `Paddle.Http.build_struct/2` mapping (top-level promotion + raw_data preservation + unknown-key isolation + checkout URL string).

## Decisions Made
- **Field surface locked to research recommendation:** The `Paddle.Transaction` defstruct list matches the "First-Pass Struct Fields" table in `04-RESEARCH.md` exactly (verified against acceptance criteria asserting `:collection_mode`, `:checkout`, `:billed_at`, and `:revised_at`). Broader nested branches like `details`, `items`, and `payments` stay as plain maps/lists, kept verbatim in `:raw_data` for forward compatibility.
- **`:raw_data` placed last** to mirror `Paddle.Customer` and `Paddle.Address` so the shared mapper convention (`Paddle.Http.build_struct/2`) keeps treating it as the catch-all forward-compatibility slot.
- **Struct-only modules in this plan:** Deliberately deferred any resource helpers, body builders, or nested-checkout hydration to 04-02 so this plan is purely the entity contract surface, matching the plan's `<objective>`.
- **Nested checkout contract via dedicated struct (not atom-keyed map):** Chose `Paddle.Transaction.Checkout` so the public API guarantees `%Paddle.Transaction.Checkout{url: ...}` rather than leaking a string-key map into callers, satisfying D-03/D-13.

## Deviations from Plan

None - plan executed exactly as written.

The plan's two TDD tasks (RED then GREEN) were executed in order with no Rule 1/2/3 auto-fixes triggered. No architectural decisions arose. No additional files were touched beyond the three the plan called out (`lib/paddle/transaction.ex`, `lib/paddle/transaction/checkout.ex`, `test/paddle/transaction_test.exs`).

## Issues Encountered
None. The expected RED-phase compile error (`Paddle.Transaction.__struct__/1 is undefined`) appeared exactly as planned, and the GREEN phase compiled and passed all four new tests on the first run.

## TDD Gate Compliance
- RED gate: `5a71553 test(04-01): add failing contract tests for Paddle.Transaction and Paddle.Transaction.Checkout` (commit captures the test file before any struct module exists; verified locally that `mix test test/paddle/transaction_test.exs` failed at compile time at this commit).
- GREEN gate: `61a9b6a feat(04-01): implement Paddle.Transaction and Paddle.Transaction.Checkout struct modules` (commit adds the struct modules; `mix test test/paddle/transaction_test.exs` -> `4 tests, 0 failures`).
- REFACTOR gate: not needed; both modules are already minimal struct-only definitions.

## User Setup Required
None - no external service configuration required for this plan. (Hosted-checkout dashboard prerequisites — default payment link and approved checkout domain — remain a Phase 4 integration concern and are tracked in `04-RESEARCH.md` Pitfall 3 / "User Setup Required" considerations for the resource-module plan in 04-02 to surface.)

## Next Phase Readiness
- The typed entity surface is in place, so Plan 04-02 can implement `Paddle.Transactions.create/2` with the documented private `build_transaction/1` helper that swaps the shallow `checkout` map produced by `Paddle.Http.build_struct/2` with `%Paddle.Transaction.Checkout{}`.
- Requirement TXN-02 ("Return hosted checkout URLs from transaction creation") has its struct-level contract locked here; the request/response wiring in 04-02 will complete it end-to-end.
- Requirement TXN-01 still owned by 04-02; nothing in this plan blocks it.

## Self-Check: PASSED

Created files (verified to exist):
- FOUND: lib/paddle/transaction.ex
- FOUND: lib/paddle/transaction/checkout.ex
- FOUND: test/paddle/transaction_test.exs

Commits (verified in git log):
- FOUND: 5a71553 (test(04-01): add failing contract tests for Paddle.Transaction and Paddle.Transaction.Checkout)
- FOUND: 61a9b6a (feat(04-01): implement Paddle.Transaction and Paddle.Transaction.Checkout struct modules)

Verification commands (all PASS):
- `mix test test/paddle/transaction_test.exs` -> `4 tests, 0 failures`
- `mix test` (full suite) -> `1 doctest, 63 tests, 0 failures`
- `grep -n 'defmodule Paddle.Transaction do' lib/paddle/transaction.ex` -> `1:defmodule Paddle.Transaction do`
- `grep -n 'defstruct \[:url, :raw_data\]' lib/paddle/transaction/checkout.ex` -> `2:  defstruct [:url, :raw_data]`

---
*Phase: 04-transactions-hosted-checkout*
*Plan: 01*
*Completed: 2026-04-29*
