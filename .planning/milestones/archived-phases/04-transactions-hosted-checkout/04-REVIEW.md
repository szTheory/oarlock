---
phase: 04-transactions-hosted-checkout
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/paddle/transaction.ex
  - lib/paddle/transaction/checkout.ex
  - test/paddle/transaction_test.exs
  - lib/paddle/transactions.ex
  - test/paddle/transactions_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-04-28
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The Phase 4 implementation faithfully follows the patterns established by `Paddle.Customers` / `Paddle.Customers.Addresses`: typed `%Paddle.Transaction{}` and `%Paddle.Transaction.Checkout{}` structs, a strict allowlisted body builder, lightweight per-field validation, and a post-`build_struct` hydration step for the nested checkout map.

No security issues or correctness-breaking bugs were identified. The transport boundary is unchanged, `String.to_existing_atom/1` use in `Http.build_struct/2` remains safe (the keyset is derived from existing struct atoms before conversion), and the strict allowlist correctly drops untrusted caller keys (`discount_id`, `currency_code`, `business_id`, `collection_mode`, etc.) per the test contract.

The findings below are robustness and code-quality concerns:

- Items validation is too lax on the `quantity` field — any value (including `nil`, negative numbers, strings, floats) is forwarded to Paddle as long as the key is present.
- `checkout: nil` is treated as a hard validation error rather than as "omit the optional checkout block", which is mildly surprising for an optional parameter.
- `custom_data` is forwarded with no type check — a non-map value would still be POSTed and rejected only by Paddle.
- The normalization helpers (`normalize_attrs/1`, `normalize_map_keys/1`) are now triplicated across `Customers`, `Customers.Addresses`, and `Transactions`.

There is no ambiguity in scope: every issue below is local to the diff under review or to a new shared helper opportunity it creates.

## Warnings

### WR-01: `normalize_item/1` does not validate `quantity` type or value

**File:** `lib/paddle/transactions.ex:112-123`

**Issue:** `normalize_item/1` only checks `Map.has_key?(item, "quantity")` — it never inspects the value. Items such as `%{price_id: "pri_01", quantity: nil}`, `%{price_id: "pri_01", quantity: -5}`, `%{price_id: "pri_01", quantity: "1"}`, or `%{price_id: "pri_01", quantity: 1.5}` all pass local validation and are forwarded to Paddle, which then rejects them with a remote 4xx and an opaque error message. This contradicts the spirit of the "lightweight per-field validation" the phase plan calls for, since `price_id` is type-checked but its sibling `quantity` is not.

The fact that the test suite explicitly covers `nil` / blank / non-binary `price_id` but only the missing-quantity case for `quantity` makes this asymmetry easy to miss.

**Fix:**
```elixir
defp normalize_item(item) when is_map(item) do
  item = normalize_map_keys(item)

  with price_id when is_binary(price_id) <- Map.get(item, "price_id"),
       false <- String.trim(price_id) == "",
       quantity when is_integer(quantity) and quantity > 0 <- Map.get(item, "quantity") do
    {:ok, %{"price_id" => price_id, "quantity" => quantity}}
  else
    _ -> :error
  end
end
```

Add corresponding test cases for `quantity: nil`, `quantity: 0`, `quantity: -1`, `quantity: "1"`, and `quantity: 1.5`, all expected to return `{:error, :invalid_items}`.

### WR-02: `checkout: nil` returns `{:error, :invalid_checkout}` instead of being treated as omitted

**File:** `lib/paddle/transactions.ex:127-151`

**Issue:** `validate_checkout/1` uses `Map.fetch/2` to distinguish "key absent" from "key present with `nil`". That makes `Transactions.create(client, customer_id: "...", address_id: "...", items: [...], checkout: nil)` fail with `:invalid_checkout`, while omitting the key entirely returns `{:ok, nil}` and proceeds normally.

This is surprising for an optional parameter; idiomatic Elixir treats `nil` as "no value provided", and other resource modules in this codebase do not raise on explicit `nil` for optional inputs. It also breaks the common caller pattern of building a keyword list with `checkout: get_optional_checkout()` where the helper may return `nil`.

There is no test exercising this path either way, so the behavior is silently encoded.

**Fix:** Treat `nil` as "no checkout" and either accept it or, if the strict-input behavior is intended, document and test it explicitly. Recommended:
```elixir
defp validate_checkout(attrs) do
  case Map.fetch(attrs, "checkout") do
    :error -> {:ok, nil}
    {:ok, nil} -> {:ok, nil}
    {:ok, checkout} -> normalize_checkout(checkout)
  end
end
```

Add a test asserting `Transactions.create(client, [..., checkout: nil])` posts a body without a `"checkout"` key.

### WR-03: `custom_data` is forwarded without a type check

**File:** `lib/paddle/transactions.ex:19-28`

**Issue:** `build_body/5` blindly threads `Map.get(attrs, "custom_data")` into the request body whenever it is non-`nil`. There is no check that the value is a map. A caller supplying `custom_data: "crm_123"` (a bare string), `custom_data: [1, 2, 3]`, or `custom_data: 42` will produce a JSON body like `{"custom_data": "crm_123", ...}` that Paddle then rejects with a remote 4xx, even though every other field has local pre-flight validation.

This is the same class of issue as WR-01: the validation is asymmetric across siblings. It also leaks malformed payloads to the wire, which is undesirable when callers want defense-in-depth.

**Fix:** Add a small validator and thread it through the `with`:
```elixir
defp validate_custom_data(attrs) do
  case Map.fetch(attrs, "custom_data") do
    :error -> {:ok, nil}
    {:ok, nil} -> {:ok, nil}
    {:ok, value} when is_map(value) -> {:ok, value}
    {:ok, _} -> {:error, :invalid_custom_data}
  end
end
```

And switch `build_body/5` to take the validated value rather than re-reading from `attrs`. Add tests covering `custom_data: "string"`, `custom_data: 1`, and `custom_data: [%{}]`.

### WR-04: `normalize_attrs/1` and `normalize_map_keys/1` are now triplicated across resource modules

**File:** `lib/paddle/transactions.ex:45-62` (also `lib/paddle/customers.ex:47-64`, `lib/paddle/customers/addresses.ex:73-101`)

**Issue:** With this phase, three resource modules now carry byte-identical copies of `normalize_attrs/1` (both clauses), `normalize_map_keys/1`, and the keyword-vs-map handling. A future change to one (e.g., to reject non-binary/non-atom keys, or to recurse into nested maps to allow atom keys inside `custom_data`) requires three coordinated edits, with no compile-time link between them. This is a maintainability hazard that grows linearly with each new resource module.

The three resource modules also disagree on the `validate_id` shape (`:ok | {:error, atom}` in `Customers.Addresses` vs `{:ok, value} | {:error, atom}` in `Transactions`), which compounds the duplication problem if any future helper has to handle both.

**Fix:** Extract the shared helpers into a private support module (e.g., `Paddle.Internal.Attrs`):
```elixir
defmodule Paddle.Internal.Attrs do
  @moduledoc false

  def normalize(attrs) when is_list(attrs) do
    if Keyword.keyword?(attrs),
      do: {:ok, attrs |> Enum.into(%{}) |> normalize_keys()},
      else: {:error, :invalid_attrs}
  end

  def normalize(attrs) when is_map(attrs), do: {:ok, normalize_keys(attrs)}
  def normalize(_), do: {:error, :invalid_attrs}

  def normalize_keys(map) do
    Enum.reduce(map, %{}, fn
      {k, v}, acc when is_atom(k) -> Map.put(acc, Atom.to_string(k), v)
      {k, v}, acc when is_binary(k) -> Map.put(acc, k, v)
      {_, _}, acc -> acc
    end)
  end

  def allowlist(attrs, allowed) do
    Enum.reduce(attrs, %{}, fn {k, v}, acc ->
      if k in allowed, do: Map.put(acc, k, v), else: acc
    end)
  end
end
```

Then have all three resource modules delegate. This is appropriate to do during this phase, while the pattern is fresh; deferring it makes the eventual extraction more invasive.

## Info

### IN-01: Redundant `:raw_data` filtering pass in `build_struct/2` consumers

**File:** `lib/paddle/transaction.ex:22`, `lib/paddle/transaction/checkout.ex:2`

**Issue:** Both struct modules include `:raw_data` in their `defstruct`, which means `valid_keys` in `Http.build_struct/2` (`lib/paddle/http.ex:19`) contains `"raw_data"`. If an upstream payload ever happens to include a `"raw_data"` field, it will first be promoted into `attrs[:raw_data]` and then immediately overwritten by `Map.put(attrs, :raw_data, data)`. This is harmless but is a subtle invariant that depends on `Map.put` running last; future refactors of `build_struct/2` could silently break it.

**Fix:** Either drop `:raw_data` from each struct's `defstruct` and rely on `struct(struct_module, ...)` accepting the key (it will not — `struct/2` ignores unknown keys, so this approach won't work directly), or filter `"raw_data"` out of `valid_keys` inside `Http.build_struct/2`. The simplest fix is to add a one-line filter in `Http.build_struct/2`:
```elixir
valid_keys =
  base_struct
  |> Map.keys()
  |> Enum.map(&to_string/1)
  |> List.delete("raw_data")
```

Optional — flagged for awareness, not action.

### IN-02: `build_transaction/1` silently keeps a non-map `checkout` value as-is

**File:** `lib/paddle/transactions.ex:33-43`

**Issue:** When `data["checkout"]` is present but not a map (e.g., a list, string, or number returned by a misbehaving response or future API change), `build_transaction/1` falls through the `_ ->` arm and leaves `transaction.checkout` with whatever raw value `Http.build_struct(Transaction, data)` stored there (the raw list/string/number). Callers expecting `transaction.checkout` to always be either `nil` or `%Paddle.Transaction.Checkout{}` may be surprised.

**Fix:** Tighten the fallback to coerce non-map checkout values to `nil`:
```elixir
defp build_transaction(data) when is_map(data) do
  transaction = Http.build_struct(Transaction, data)

  case data["checkout"] do
    checkout_data when is_map(checkout_data) ->
      %{transaction | checkout: Http.build_struct(Checkout, checkout_data)}

    _ ->
      %{transaction | checkout: nil}
  end
end
```

### IN-03: `Transactions` module lacks `@moduledoc` / `@doc` entries

**File:** `lib/paddle/transactions.ex:1`, `lib/paddle/transaction.ex:1`, `lib/paddle/transaction/checkout.ex:1`

**Issue:** None of the three new modules carries a `@moduledoc` or `@doc` for `create/2`. The existing peers (`Paddle.Customers`, `Paddle.Customer`) are also undocumented, so this is consistent — but as the public surface area of the SDK grows it gets harder to add docs retroactively without breaking existing tooling assumptions. Phase 4 introduces a new public function with non-obvious strict-allowlist semantics (silent drop of `discount_id`, `business_id`, `currency_code`, forced `collection_mode: "automatic"`) that is exactly the kind of behavior worth documenting.

**Fix:** Add a brief `@moduledoc false` (if internal) or a one-paragraph `@moduledoc` plus a `@doc` on `create/2` explicitly listing the allowlist and the forced collection mode. Optional — low priority.

### IN-04: Tests do not cover the `data["checkout"]` absent / non-map response branches of `build_transaction/1`

**File:** `test/paddle/transactions_test.exs`

**Issue:** `build_transaction/1` has two branches: the happy path (map checkout, hydrated) and the fallback (no/non-map checkout). All tests in `test/paddle/transactions_test.exs` exercise only the happy path — `transaction_payload/0` always includes a map `"checkout"` field. The fallback branch is reachable from real production responses (e.g., 201 transactions where the API does not return a checkout block, manual collection mode in the future, etc.) but has no test coverage.

**Fix:** Add a test where the adapter responds with a `"data"` map missing `"checkout"` and assert `transaction.checkout == nil`. Also add a test where `"checkout"` is present but `nil`.

---

_Reviewed: 2026-04-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
