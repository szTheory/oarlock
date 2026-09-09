# Phase 9: Pagination Ergonomics - Pattern Map

**Mapped:** 2026-05-30
**Scope:** Internal pagination helper, per-resource stream/all wrappers, adapter-backed pagination tests, public docs

---

## Summary

Phase 9 should preserve the existing resource-module shape and add one hidden shared pagination engine. The closest analogs are already in the codebase:

- `Paddle.Subscriptions.list/2` and `Paddle.Customers.Addresses.list/3` are the source-of-truth public list functions.
- `Paddle.Http.request/4` is the transport chokepoint; next-page fetches should go through it unchanged.
- `Paddle.Page.next_cursor/1` is the locked accessor for `meta.pagination.next`.
- Existing adapter-backed tests are the local pattern for asserting request path/query and response mapping.

No schema files are involved.

---

## Files To Create

### `lib/paddle/internal/pagination.ex`

**Role:** Hidden shared implementation for item streams and eager collection over `%Paddle.Page{}` list functions.

**Closest analogs:**

- `lib/paddle/internal/attrs.ex` — internal module, `@moduledoc false`, shared behavior used by public resource modules.
- `lib/paddle/page.ex` — small focused support module around pagination data.

**Required behavior:**

- `stream(first_page_fun, next_page_fun)` returns an `Enumerable`.
- `all(first_page_fun, next_page_fun)` returns `{:ok, items}` or `{:error, reason}`.
- Internal continuation uses `page.meta["pagination"]["has_more"] == true`.
- Internal next path uses `Paddle.Page.next_cursor/1`.
- Absolute next URLs normalize to `path?query`.
- `%Paddle.Error{}` errors raise directly in streams; atom errors raise `ArgumentError`.

**Source patterns to copy:**

```elixir
defmodule Paddle.Internal.Attrs do
  @moduledoc false
  ...
end
```

```elixir
defmodule Paddle.Page do
  defstruct [:data, :meta]

  def next_cursor(%__MODULE__{meta: %{"pagination" => %{"next" => next}}}) when is_binary(next) do
    next
  end
end
```

---

## Files To Modify

### `lib/paddle/subscriptions.ex`

**Role:** Add public `stream/2` and `all/2` helpers, plus private next-page page builder.

**Current source-of-truth code:**

```elixir
def list(%Client{} = client, params \\ []) do
  with {:ok, params} <- normalize_params(params),
       query <- Attrs.allowlist(params, @list_allowlist),
       {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
         Http.request(client, :get, "/subscriptions", params: query) do
    {:ok,
     %Paddle.Page{
       data: Enum.map(data, &build_subscription/1),
       meta: meta
     }}
  end
end
```

**Recommended refactor:**

- Add `alias Paddle.Internal.Pagination`.
- Add:
  - `def stream(%Client{} = client, params \\ [])`
  - `def all(%Client{} = client, params \\ [])`
- Extract private `build_page(data, meta)` and reuse in `list/2` and `next_page/2`.
- Add private `next_page(client, path)`:

```elixir
defp next_page(client, path) do
  with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
         Http.request(client, :get, path) do
    {:ok, build_page(data, meta)}
  end
end
```

**Do not change:**

- `list/2` signature
- `@list_allowlist`
- `build_subscription/1`
- return tuple shape

---

### `lib/paddle/customers/addresses.ex`

**Role:** Add public `stream/3` and `all/3` helpers for nested customer addresses.

**Current source-of-truth code:**

```elixir
def list(%Paddle.Client{} = client, customer_id, params \\ []) do
  with :ok <- validate_customer_id(customer_id),
       {:ok, params} <- normalize_params(params),
       query <- Attrs.allowlist(params, @list_allowlist),
       {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
         Http.request(client, :get, customer_addresses_path(customer_id), params: query) do
    {:ok,
     %Paddle.Page{
       data: Enum.map(data, &Http.build_struct(Address, &1)),
       meta: meta
     }}
  end
end
```

**Recommended refactor:**

- Add `alias Paddle.Internal.Pagination`.
- Add:
  - `def stream(%Paddle.Client{} = client, customer_id, params \\ [])`
  - `def all(%Paddle.Client{} = client, customer_id, params \\ [])`
- Extract private `build_page(data, meta)`.
- Add private `next_page(client, path)` that calls `Http.request(client, :get, path)` and reuses `build_page/2`.

**Do not change:**

- `list/3` signature
- `customer_addresses_path/1`
- `validate_customer_id/1`
- return tuple shape

---

### `lib/paddle/page.ex`

**Role:** Preserve `next_cursor/1`; add regression coverage only unless implementation proves a tiny internal helper belongs here.

**Current source-of-truth code:**

```elixir
def next_cursor(%__MODULE__{meta: %{"pagination" => %{"next" => next}}}) when is_binary(next) do
  next
end
```

**Recommended change:** none in source. Add a test in `test/paddle/page_test.exs`.

---

### `guides/accrue-seam.md`

**Role:** Public seam guide.

**Current pattern:**

- Resource module sections list public functions with return shapes and tiers.
- `%Paddle.Page{}` section documents support type.

**Recommended update:**

- Under `Paddle.Customers.Addresses`, add:
  - `stream(client, customer_id, params \\ [])` returns an `Enumerable` of `%Paddle.Address{}`; later page errors raise.
  - `all(client, customer_id, params \\ [])` returns `{:ok, [%Paddle.Address{}]}` or `{:error, reason}`.
- Under `Paddle.Subscriptions`, add:
  - `stream(client, params \\ [])` returns an `Enumerable` of `%Paddle.Subscription{}`; later page errors raise.
  - `all(client, params \\ [])` returns `{:ok, [%Paddle.Subscription{}]}` or `{:error, reason}`.
- Update `Paddle.Page.next_cursor/1` wording to clarify it returns Paddle's next reference string and `has_more` determines continuation for auto-pagination.

---

### `guides/getting-started.md`

**Role:** User-facing adoption guide.

**Current pattern:** manual subscription pagination around lines that call `Paddle.Subscriptions.list/2` and `Paddle.Page.next_cursor/1`.

**Recommended update:**

- Show `Paddle.Subscriptions.stream(client, status: ["active"]) |> Enum.take(100)`.
- Show `{:ok, subscriptions} = Paddle.Subscriptions.all(client, status: ["active"])`.
- Keep a short note that `Paddle.Page.next_cursor/1` remains available for manual page control.

---

### `CHANGELOG.md`

**Role:** Release notes.

**Recommended update:**

- Add `[Unreleased]` `Added` bullet for PAGE-01:
  - per-resource auto-pagination helpers;
  - stream is lazy and may raise on later page failures;
  - all returns tagged tuple and no partial results;
  - existing `list/*` shape preserved.

---

## Test Files To Modify

### `test/paddle/subscriptions_test.exs`

**Patterns already present:**

- Adapter-backed clients inspect `request.method`, `request.url.path`, and query.
- List tests assert `%Paddle.Page{}` and nested struct hydration.
- Payload helpers produce realistic subscription maps.

**Add tests for:**

- `stream/2` three-page success.
- `all/2` equals `stream/2 |> Enum.to_list()` on the same fixture.
- `list/2` still returns `{:ok, %Paddle.Page{}}`.
- page-2 `%Paddle.Error{}`: stream raises, all returns `{:error, error}`.
- invalid params: stream raises `ArgumentError`, all returns `{:error, :invalid_params}`.
- `Enum.take(stream, 1)` fetches only first page.
- absolute next URL normalizes to `request.url.path == "/subscriptions"` and query contains original filters plus `after`.
- `has_more: false` with non-nil next does not fetch an extra page.

### `test/paddle/customers/addresses_test.exs`

**Patterns already present:**

- Adapter-backed clients assert nested path `/customers/ctm_01/addresses`.
- List tests assert `%Paddle.Page{}` and address raw payload preservation.

**Add tests for:**

- `stream/3` three-page success.
- `all/3` equals `stream/3 |> Enum.to_list()` on the same fixture.
- `list/3` still returns `{:ok, %Paddle.Page{}}`.
- page-2 `%Paddle.Error{}` behavior.
- invalid customer ID and params behavior.
- `Enum.take(stream, 1)` fetches only first page.
- relative nested next URL replay.
- absolute nested next URL replay.
- `has_more: false` with non-nil next does not fetch page 2.

### `test/paddle/page_test.exs`

**Add test:**

- `Page.next_cursor/1` returns a non-nil next URL even when `has_more` is false, proving auto-pagination must not infer continuation from `next_cursor/1`.

---

## Verification Commands

- `mix test test/paddle/page_test.exs test/paddle/subscriptions_test.exs test/paddle/customers/addresses_test.exs --color`
- `mix test --color`
- `mix compile --warnings-as-errors`
- `mix format --check-formatted`

## PATTERN MAPPING COMPLETE
