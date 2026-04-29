---
phase: 05-subscriptions-management
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/paddle/subscription.ex
  - lib/paddle/subscription/management_urls.ex
  - lib/paddle/subscription/scheduled_change.ex
  - lib/paddle/subscriptions.ex
  - test/paddle/subscription_test.exs
  - test/paddle/subscriptions_test.exs
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 5 ships `Paddle.Subscriptions` (`get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`) plus three structs (`Paddle.Subscription`, `Paddle.Subscription.ScheduledChange`, `Paddle.Subscription.ManagementUrls`). The implementation is a faithful application of the Phase 3/4 resource-module patterns (validation -> normalize -> allowlist -> Http.request -> envelope unwrap -> per-resource nested-struct hydration). Pattern fidelity vs. the locked analogs (`lib/paddle/customers.ex`, `lib/paddle/transactions.ex`, `lib/paddle/customers/addresses.ex`) is near-exact: identical `with`-chains, identical `validate_*_id/1` shape, identical `URI.encode/2` path encoding, identical `normalize_params/1` three-clause function, and the nested-struct post-processor mirrors `Paddle.Transactions.build_transaction/1` line-for-line, extended to two nested keys.

Test coverage is solid: 30 assertions across 18 tests, all passing. The pitfall-driven cases (URL encoding with reserved chars, `update_payment_method: nil` for manual collection, locked-pending-changes 422, transport timeout passthrough, full-URL `next` cursor, integer-id rejection) are all exercised.

The findings below are minor: two robustness gaps in `build_subscription/1` plus four coverage/style gaps in tests. None block shipping; all are opportunistic improvements consistent with the project's defensive-but-thin transport boundary discipline.

## Warnings

### WR-01: `build_subscription/1` leaves non-map nested values as raw scalars instead of normalizing to nil

**File:** `lib/paddle/subscriptions.ex:55-74`
**Issue:** `Http.build_struct/2` is shape-blind — it promotes any value at a string key matching a struct field into that field. So if Paddle ever returns (or a contract drift introduces) `"scheduled_change" => "some_string"` or `"management_urls" => 42`, the flat mapper assigns those scalars to `subscription.scheduled_change` / `subscription.management_urls`, and the subsequent `case data["scheduled_change"] do sc when is_map(sc) -> ... ; _ -> subscription end` clause does NOT clear them — it falls through to the unchanged subscription, which still has the scalar.

Consequence: a downstream pattern-match like `%Subscription{scheduled_change: %ScheduledChange{}}` or `subscription.scheduled_change.action` crashes with `BadMapError`/`KeyError` on what should be a typed nil-or-struct field. The contract per CONTEXT.md D-19 is that `:scheduled_change` is either `nil` or `%ScheduledChange{}` and `:management_urls` is either `nil` or `%ManagementUrls{}` — never a raw string/integer.

The same shape-blindness exists in `Paddle.Transactions.build_transaction/1` for `:checkout`, so this is a project-wide robustness pattern, but Phase 5 has TWO carve-outs and a stronger downstream contract (`scheduled_change.effective_at` is the canonical "when does this end?" DX path), so the impact lands harder here.

Reproduction:
```elixir
iex> data = %{"id" => "sub_01", "scheduled_change" => "oops", "management_urls" => 42}
iex> Paddle.Http.build_struct(Paddle.Subscription, data).scheduled_change
"oops"
iex> Paddle.Http.build_struct(Paddle.Subscription, data).management_urls
42
```

**Fix:** Normalize non-map nested values to `nil` instead of leaving them as raw scalars. One option — defensively reset both fields before the `case` clauses:
```elixir
defp build_subscription(data) when is_map(data) do
  subscription =
    Subscription
    |> Http.build_struct(data)
    |> Map.put(:scheduled_change, nil)
    |> Map.put(:management_urls, nil)

  subscription =
    case data["scheduled_change"] do
      sc when is_map(sc) ->
        %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}

      _ ->
        subscription
    end

  case data["management_urls"] do
    mu when is_map(mu) ->
      %{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}

    _ ->
      subscription
  end
end
```
Or, equivalently, change the `case` catch-alls to explicitly write `nil`:
```elixir
case data["scheduled_change"] do
  sc when is_map(sc) -> %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}
  _ -> %{subscription | scheduled_change: nil}
end
```
Pair the fix with a regression test in `test/paddle/subscriptions_test.exs` that feeds a non-map `"scheduled_change"` / `"management_urls"` through `Subscriptions.get/2` and asserts `%Subscription{scheduled_change: nil, management_urls: nil}`.

---

### WR-02: `list/2` has zero `%Paddle.Error{}` propagation coverage

**File:** `test/paddle/subscriptions_test.exs:143-285`
**Issue:** The `list/2` describe block tests transport exceptions (line 277), validation tuples (line 247), and happy paths, but never exercises a non-2xx Paddle API error (e.g., 401 unauthorized, 403 forbidden, 5xx server error). All three sibling test files cover this for their list functions (`test/paddle/customers/addresses_test.exs:233-262` covers a 404 on `Addresses.get/3`; transactions covers a 422). The Phase 5 `get/2`, `cancel/2`, and `cancel_immediately/2` describe blocks all have `%Paddle.Error{}` propagation tests (lines 86-114, 336-364, 421-448 respectively) — `list/2` is the lone exception.

While Paddle list endpoints rarely return 404, they DO return 401/403 (auth failure) and 5xx (server error). A regression in `Http.request/4`'s error path or in the `with`-chain would silently slip past the existing list tests.

**Fix:** Add a test mirroring the existing 422 / 404 patterns:
```elixir
test "preserves a 401 unauthorized %Paddle.Error{} unchanged" do
  client =
    client_with_adapter(fn request ->
      response =
        Req.Response.new(
          status: 401,
          body: %{
            "error" => %{
              "type" => "request_error",
              "code" => "authentication_missing",
              "detail" => "Authentication header is missing",
              "errors" => []
            }
          }
        )
        |> Req.Response.put_header("x-request-id", "req_401")

      {request, response}
    end)

  assert {:error,
          %Error{
            status_code: 401,
            request_id: "req_401",
            code: "authentication_missing",
            message: "Authentication header is missing"
          }} = Subscriptions.list(client)
end
```

## Info

### IN-01: `subscription_test.exs` `build_struct/2` test asserts raw-map nested shapes — relies on the post-processor for typed-struct hydration

**File:** `test/paddle/subscription_test.exs:78-114`
**Issue:** The single `build_struct/2 promotes known subscription keys` test asserts `scheduled_change: %{"action" => "cancel", ...}` and `management_urls: %{"update_payment_method" => "...", ...}` (raw maps, not typed structs). This is technically correct because `Http.build_struct/2` is the SHALLOW mapper — it does not hydrate nested structs; that's `build_subscription/1`'s job. But a careless future maintainer reading only this test would mistakenly conclude that `scheduled_change` and `management_urls` are plain-map fields on the struct. The downstream contract (CONTEXT.md D-18) says these fields should hold typed structs after the resource-module pipeline.

This is consistent with `test/paddle/transaction_test.exs:34-80` (which asserts the same raw-map shape for `:checkout`), so it's a project-wide pattern. Just a documentation/clarity opportunity.
**Fix:** Add a one-line comment immediately above the `scheduled_change` / `management_urls` assertions in the test clarifying the intent:
```elixir
# build_struct/2 is shallow — Subscriptions.build_subscription/1 hydrates
# scheduled_change and management_urls into typed structs.
scheduled_change: %{"action" => "cancel", ...},
```

### IN-02: `Subscriptions.list(client, nil)` is not directly asserted

**File:** `test/paddle/subscriptions_test.exs:247-256`
**Issue:** The `list/2` validation-tuple test covers `"nope"` (binary), `42` (integer), and `[1, 2, 3]` (non-keyword list), but not `nil` directly. Tracing through `normalize_params/1` (`lib/paddle/subscriptions.ex:82-91`), `nil` falls through the `is_list/1` and `is_map/1` clauses to the catch-all and correctly returns `{:error, :invalid_params}`. The behavior is well-defined; the assertion is just absent. Other resource modules' validation tests include the `nil` case (e.g., `test/paddle/transactions_test.exs:106` asserts `Transactions.create(client, nil)` returns `:invalid_attrs`).
**Fix:** Add one assertion to the existing test:
```elixir
assert {:error, :invalid_params} = Subscriptions.list(client, nil)
```

### IN-03: `do_cancel/3`'s `effective_from` parameter is implicitly trusted as a binary

**File:** `lib/paddle/subscriptions.ex:42-53`
**Issue:** `do_cancel/3` accepts `effective_from` and inlines it into a JSON body without typing or guard. This is private and only ever called with the two literal strings `"next_billing_period"` and `"immediately"` from the public functions, so there is zero risk today. But the function is one inline edit away from accepting an external value, and its signature gives no hint that the contract is "must be a binary in the {next_billing_period, immediately} set." Per CONTEXT.md "Claude's Discretion": atom or binary is fine — the production contract is just the public function names.
**Fix:** None required. Optionally add a guard (`when effective_from in ["next_billing_period", "immediately"]`) to make the contract explicit and refuse to add future modes by hand without going through the named-function pattern (D-08). This is purely defensive style.

### IN-04: Test header comment lives at the top of the file before the `defmodule` — Elixir convention prefers `@moduledoc`

**File:** `test/paddle/subscriptions_test.exs:1-4`
**Issue:** The four-line comment block warning future contributors away from live-API tests for cancellation is intentional and valuable (per RESEARCH.md Pitfall 3 / 05-PATTERNS.md). Placing it as bare `#`-comments above `defmodule` works, but Elixir convention is to use a `@moduledoc` inside the test module so the warning is tooled (visible to `mix help`, `iex h Paddle.SubscriptionsTest`, doc generators). Sibling test files don't do this either, so it's not a divergence — just an opportunity.
**Fix:** Optional. Move the comment inside the module as a `@moduledoc`:
```elixir
defmodule Paddle.SubscriptionsTest do
  @moduledoc """
  All Phase 5 transport tests use `Req.new(adapter: ...)` exclusively.

  Cancellation is destructive and irreversible per Paddle docs:
  https://developer.paddle.com/api-reference/subscriptions/cancel-subscription

  Do NOT add `@tag :integration` tests that hit the live or sandbox API.
  """
  use ExUnit.Case, async: true
  ...
```

---

## Pattern Fidelity vs. Sibling Modules

Cross-checked against `lib/paddle/customers.ex`, `lib/paddle/transactions.ex`, and `lib/paddle/customers/addresses.ex` (the three established analogs called out in `05-PATTERNS.md`). No divergences:

- `validate_subscription_id/1` matches `validate_customer_id/1` (`lib/paddle/customers.ex:38-46`) line-for-line in shape (binary guard + `String.trim/1 == ""` + catch-all).
- `subscription_path/1` and `cancel_path/1` use the same `URI.encode(id, &URI.char_unreserved?/1)` helper as `customers.ex:48` and `addresses.ex:85`.
- `normalize_params/1` is a verbatim copy of `lib/paddle/customers/addresses.ex:74-83` (same three clauses, same `Keyword.keyword?/1` guard, same `:invalid_params` failure tag).
- `@list_allowlist` uses the same `~w(...)` sigil convention as `lib/paddle/customers/addresses.ex:7` (with the 11 D-12 keys).
- `build_subscription/1` mirrors `Paddle.Transactions.build_transaction/1` (`lib/paddle/transactions.ex:35-45`) with one extra `case`/rebind for the second nested key, exactly as recommended by `05-PATTERNS.md` Pattern C.
- `do_cancel/3` composes the customers `with`-chain validation shape with the transactions `:post` + `json:` body shape, as recommended by `05-PATTERNS.md` Pattern E.
- Public function signatures all match the discipline in `05-PATTERNS.md` "Public Function Signature Discipline" — `%Paddle.Client{} = client` first, default only on `params \\ []`, no `opts` keyword.
- Test fixture builders use the `Map.merge(base_payload(), %{...overrides...})` composition pattern (RESEARCH.md lines 770-791), exactly as `addresses_test.exs` does.

---

## What Was Verified

1. Pattern-matching correctness in `Paddle.Subscriptions`:
   - `get/2`: `with :ok <- validate_subscription_id(id), {:ok, %{"data" => data}} when is_map(data) <- ...` — matches `customers.ex:18-24`.
   - `list/2`: `with {:ok, params} <- normalize_params(...), query <- Attrs.allowlist(...), {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <- ...` — matches `addresses.ex:29-41`.
   - `cancel/2` / `cancel_immediately/2`: thin wrappers over `do_cancel/3` (`with :ok <- validate_..., {:ok, %{"data" => data}} when is_map(data) <- Http.request(:post, ..., json: %{"effective_from" => ...})`).
   - All four short-circuit `:invalid_subscription_id` / `:invalid_params` / `%Paddle.Error{}` / `%Req.TransportError{}` correctly through the `with`.

2. Per-resource nested-struct hydration:
   - Both `:scheduled_change` and `:management_urls` correctly run through `Http.build_struct/2` for nested promotion when the source is a map.
   - Hydration runs on EVERY list item (`Enum.map(data, &build_subscription/1)` at `subscriptions.ex:28`), not just `get/2`. This is verified by the `subscriptions_test.exs:144-187` per-item assertions (T-05-14).

3. Tuple shapes:
   - `{:error, :invalid_subscription_id}` for nil/blank/whitespace/integer ids — covered for all three id-taking functions.
   - `{:error, :invalid_params}` for non-keyword/non-map containers in `list/2`.
   - `{:error, %Paddle.Error{...}}` for non-2xx — covered for `get/2` (404), `cancel/2` (422), `cancel_immediately/2` (404). Not covered for `list/2` (see WR-02).
   - `{:error, %Req.TransportError{...}}` passthrough — covered for all four public functions.

4. Allowlist coverage for `list/2`:
   - 11 keys per CONTEXT.md D-12: `id, customer_id, address_id, price_id, status, scheduled_change_action, collection_mode, next_billed_at, order_by, after, per_page` — exactly matches the `~w(...)` sigil at `subscriptions.ex:9-11`.
   - Test at `subscriptions_test.exs:189-231` asserts all 11 forwarded and `ignored: "drop me"` filtered out.
   - Per RESEARCH.md Pitfall 2: `meta.pagination.next` is a full URL like `"https://api.paddle.com/subscriptions?after=sub_..."`, and the `Paddle.Page.next_cursor/1` assertion (`subscriptions_test.exs:175-176`) returns the entire string unchanged.

5. Pitfall coverage:
   - Pitfall 5 (manual-collection `update_payment_method: nil`) — `subscriptions_test.exs:126-140` and `subscription_test.exs:163-174`.
   - Pitfall 6 (`subscription_locked_pending_changes` 422) — `subscriptions_test.exs:336-364`.
   - URL encoding for reserved chars — covered for `get/2` (line 64-75), `cancel/2` (311-325), `cancel_immediately/2` (398-410).
   - Integer-id rejection — covered for all three id-taking functions.

6. Compile + tests:
   - `mix compile --warnings-as-errors` — clean.
   - `mix test test/paddle/subscription_test.exs test/paddle/subscriptions_test.exs` — 30 tests, 0 failures.

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
