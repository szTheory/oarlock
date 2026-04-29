---
phase: 04-transactions-hosted-checkout
fixed_at: 2026-04-28T00:00:00Z
review_path: .planning/phases/04-transactions-hosted-checkout/04-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 04: Code Review Fix Report

**Fixed at:** 2026-04-28
**Source review:** `.planning/phases/04-transactions-hosted-checkout/04-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (Critical: 0, Warning: 4)
- Fixed: 4
- Skipped: 0
- Out of scope (Info, deferred): 4

All Critical + Warning findings were applied. Info findings (IN-01..IN-04) are out of scope per `fix_scope: critical_warning` and were not addressed.

After every fix, `mix test test/paddle/transactions_test.exs` was run and stayed green; after the WR-04 cross-module refactor, the full `mix test` suite was run (1 doctest, 75 tests, 0 failures).

## Fixed Issues

### WR-01: `normalize_item/1` does not validate `quantity` type or value

**Files modified:** `lib/paddle/transactions.ex`, `test/paddle/transactions_test.exs`
**Commit:** `23efa59`
**Applied fix:** Replaced the lax `Map.has_key?(item, "quantity")` check in `normalize_item/1` with the guarded clause `quantity when is_integer(quantity) and quantity > 0`, so that `nil`, `0`, negative integers, strings, and floats are now rejected locally with `{:error, :invalid_items}`. Extended the `:invalid_items` test case to assert each of those shapes (`quantity: nil`, `0`, `-1`, `"1"`, `1.5`).

### WR-02: `checkout: nil` returns `{:error, :invalid_checkout}` instead of being treated as omitted

**Files modified:** `lib/paddle/transactions.ex`, `test/paddle/transactions_test.exs`
**Commit:** `aca0765`
**Applied fix:** Added a `{:ok, nil} -> {:ok, nil}` clause to `validate_checkout/1` so that an explicit `checkout: nil` is treated the same as an absent key. Added a dedicated test asserting that `Transactions.create(client, [..., checkout: nil])` posts a body with no `"checkout"` key (and that the rest of the body is still the strict allowlisted shape).

### WR-03: `custom_data` is forwarded without a type check

**Files modified:** `lib/paddle/transactions.ex`, `test/paddle/transactions_test.exs`
**Commit:** `3b8ba58`
**Applied fix:** Introduced `validate_custom_data/1`, threaded it through the `with` chain in `create/2`, and switched `build_body/5` to take the validated value rather than re-reading from `attrs`. Non-map, non-`nil` values now short-circuit with `{:error, :invalid_custom_data}` before any HTTP call. Added two tests: one asserting `:invalid_custom_data` for a string, an integer, and a list of maps; another asserting that `custom_data: nil` is omitted from the request body.

### WR-04: `normalize_attrs/1` and `normalize_map_keys/1` are now triplicated across resource modules

**Files modified:** `lib/paddle/internal/attrs.ex` (new), `lib/paddle/customers.ex`, `lib/paddle/customers/addresses.ex`, `lib/paddle/transactions.ex`
**Commit:** `78d312e`
**Applied fix:** Extracted the byte-identical `normalize_attrs/1`, `normalize_map_keys/1`, and `allowlist_attrs/2` helpers into a new private support module `Paddle.Internal.Attrs` (with `@moduledoc false`). All three resource modules now call `Attrs.normalize/1`, `Attrs.normalize_keys/1`, and `Attrs.allowlist/2`. Local `normalize_params/1` in `Paddle.Customers.Addresses` was kept module-local because it returns the resource-specific `{:error, :invalid_params}` tag (different from `:invalid_attrs`) and would change the public error contract if collapsed; it now reuses `Attrs.normalize_keys/1` internally. The full test suite (75 tests + 1 doctest) was rerun after the refactor and stayed green, confirming no regression in the customer or address paths.

## Out of Scope (Info findings, not fixed)

The following findings were deferred because the configured `fix_scope` is `critical_warning`:

- **IN-01:** Redundant `:raw_data` filtering in `Http.build_struct/2` consumers
- **IN-02:** `build_transaction/1` silently keeps a non-map `checkout` value
- **IN-03:** Missing `@moduledoc` / `@doc` on `Transactions`, `Transaction`, `Transaction.Checkout`
- **IN-04:** No test coverage for `data["checkout"]` absent / non-map response branch of `build_transaction/1`

---

_Fixed: 2026-04-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
