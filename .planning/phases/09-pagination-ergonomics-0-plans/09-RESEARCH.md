# Phase 9: Pagination Ergonomics - Research

**Researched:** 2026-05-30
**Domain:** Paddle cursor pagination, Elixir lazy streams, existing oarlock resource-module patterns
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use per-resource public helpers, not top-level `Paddle.stream/3` / `Paddle.all/3`.
- **D-02:** Add `Paddle.Subscriptions.stream/2`, `Paddle.Subscriptions.all/2`, `Paddle.Customers.Addresses.stream/3`, and `Paddle.Customers.Addresses.all/3`.
- **D-03:** Do not add public `Paddle.stream/3`, public `Paddle.all/3`, or public `Paddle.Pagination`.
- **D-04:** Back helpers with a hidden shared implementation, likely `Paddle.Internal.Pagination` with `@moduledoc false`.
- **D-05:** Future list endpoints should add colocated `stream` / `all` helpers alongside `list`.
- **D-06:** `stream/*` returns a lazy `Enumerable` of resource structs, not tagged tuples or `%Paddle.Page{}` values.
- **D-07:** Later-page failures during stream enumeration raise. Raise `%Paddle.Error{}` directly; validation atoms raise `ArgumentError`.
- **D-08:** `all/*` returns `{:ok, items}` on complete success or `{:error, atom | %Paddle.Error{}}` on the first failed page; no partial list on error.
- **D-09:** `all/*` and `stream/* |> Enum.to_list()` produce the same item order on success.
- **D-10:** Document stream-side-effect caveat and eager `all/*` memory caveat.
- **D-11:** Do not introduce `stream!/*`.
- **D-12:** Keep `Paddle.Page.next_cursor/1` behavior unchanged.
- **D-13:** Continue only when `page.meta["pagination"]["has_more"] == true`, not merely when `next_cursor/1` is non-nil.
- **D-14:** Treat Paddle's `meta.pagination.next` as the authoritative replay reference.
- **D-15:** Normalize absolute `next` URLs to `path?query`; the client's Req base URL still decides sandbox vs live.
- **D-16:** Subsequent-page fetching must accept normalized `path?query` and reuse the resource's page mapper.
- **D-17:** Do not change `Paddle.Page.next_cursor/1` to return only the cursor ID.
- **D-18:** Add adapter-backed three-page tests proving each helper yields every item in order and terminates cleanly.
- **D-19:** Add equivalence tests proving `all/*` matches `stream/* |> Enum.to_list()`.
- **D-20:** Add list-shape regression tests for `Paddle.Subscriptions.list/2` and `Paddle.Customers.Addresses.list/3`.
- **D-21:** Add failure-mode and laziness tests.
- **D-22:** Add cursor replay tests for absolute and relative next URLs, preserved query, nested address paths, and `has_more: false` with non-nil `next`.

### Out of Scope

- Public top-level `Paddle.stream/3` / `Paddle.all/3`
- Public `Paddle.Pagination` or `%Paddle.Paginator{}`
- Public `Paddle.Page.has_more?/1`
- Streams of `%Paddle.Page{}` values
- Concurrent page prefetching, rate-limit backpressure controls, and custom pagination retry knobs
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-01 | Provide auto-pagination helpers over list endpoints by chaining `Paddle.Page.next_cursor/1`, preserving existing per-resource `list/*` shapes | Paddle docs confirm `next` is the replay URL and `has_more` controls continuation; Elixir `Stream.resource/3` fits lazy page fetching; current code has two list endpoints and one shared HTTP chokepoint |
</phase_requirements>

---

## Summary

Phase 9 is a narrow additive API layer: add discoverable per-resource helpers over the two currently public list endpoints, with a hidden shared pagination engine that fetches subsequent pages through `Paddle.Http.request/4`.

The most important external fact is Paddle's pagination contract: list responses include `data` plus `meta.pagination`; `meta.pagination.next` contains the original query parameters plus the next `after` cursor and is always returned even when `has_more` is false. Paddle's docs explicitly say to use `has_more` to decide whether another page exists and to use `next` directly rather than constructing it. Source: https://developer.paddle.com/api-reference/about/pagination/

**Primary recommendation:** create `Paddle.Internal.Pagination` with `stream/1` and `all/1` helpers that accept:

- a zero-arity `first_page` callback returning `{:ok, %Paddle.Page{}} | {:error, reason}`;
- a one-arity `next_page` callback receiving normalized `path?query` and returning the same tuple shape.

Resource modules stay public-facing and discoverable. Each module owns validation, allowlisting, endpoint path, and struct mapping. The internal engine owns cursor replay, lazy enumeration, error-to-exception conversion for streams, eager all-or-error reduction for `all/*`, and absolute-URL normalization.

One plan is sufficient. The implementation touches one new internal module plus the two resource modules, tests, and docs.

---

## External API Findings

### Paddle Pagination Semantics

Source: https://developer.paddle.com/api-reference/about/pagination/

Confirmed behaviors:

- List endpoints return a `data` array and `meta.pagination`.
- `meta.pagination.next` is a URL containing the original query parameters plus the next `after` cursor.
- `next` is always returned, even when `has_more` is `false`.
- `has_more` is the continuation flag.
- The docs recommend using the `next` URL directly, not reconstructing it.
- Most list endpoints default to 50 items and max at 200. Transactions are a useful counterexample: default and max 30, proving helper code must not hard-code page-size assumptions.

Implementation consequence:

- `Paddle.Page.next_cursor/1` remains a raw next-reference accessor.
- `Paddle.Internal.Pagination.has_more?/1` should be private/internal and check exactly `page.meta["pagination"]["has_more"] == true`.
- `Paddle.Internal.Pagination.next_page_path/1` should call `Paddle.Page.next_cursor/1`, then normalize to `path?query`.

### Subscription List Endpoint

Source: https://developer.paddle.com/api-reference/subscriptions/list-subscriptions/

Confirmed behaviors:

- Endpoint is `GET /subscriptions`.
- Query params include `after` and `per_page`; `after` is used in `meta.pagination.next`.
- Current local allowlist already covers Phase 5's selected filters plus `after` and `per_page`: `id`, `customer_id`, `address_id`, `price_id`, `status`, `scheduled_change_action`, `collection_mode`, `next_billed_at`, `order_by`, `after`, `per_page`.

Implementation consequence:

- Initial `Subscriptions.stream/2` and `Subscriptions.all/2` can delegate through existing `list/2` for first-page validation and allowlisting.
- Subsequent-page fetches should not reconstruct params through the allowlist; they should call the normalized `next` path returned by Paddle and run the same subscription page mapper.

### Customer Address List Endpoint

Source: https://developer.paddle.com/api-reference/addresses/list-addresses/

Confirmed behaviors:

- Endpoint is `GET /customers/{customer_id}/addresses`.
- Query params include `after`, `per_page`, `order_by`, `status`, and `search`.
- Nested path shape matters for cursor replay.

Implementation consequence:

- Initial `Addresses.stream/3` and `Addresses.all/3` must validate `customer_id` before returning/fetching.
- Relative next URLs such as `/customers/ctm_01/addresses?after=cursor_123` can be sent directly to `Http.request/4`.
- Absolute next URLs from either sandbox or live must be normalized to the path/query only so the `%Paddle.Client{}` base URL remains authoritative.

### Elixir Stream Mechanics

Sources:

- https://elixir.hexdocs.pm/Stream.html
- https://elixir.hexdocs.pm/Enumerable.html

Useful primitives:

- `Stream.resource/3` computes initial state lazily and supports cleanup on success or failure.
- `Stream.resource/3` emits a list of values and next accumulator per step, and halts when `next_fun` returns `{:halt, acc}`.
- `Enumerable` has no normal producer-side error channel for "yield these previous items, then return `{:error, reason}`." Raising during lazy enumeration is the idiomatic fit for stream failures.

Implementation consequence:

- `Paddle.Internal.Pagination.stream/1` should use `Stream.resource/3`.
- `Enum.take(stream, 1)` should fetch only the first page when the first page contains at least one item. This is a key laziness regression test.
- Raising `%Paddle.Error{}` directly is viable because `Paddle.Error` is already a `defexception`.

### URI Normalization

Source: https://elixir.hexdocs.pm/URI.html

Useful primitives:

- `URI.parse/1` parses into path and query components without validating or resolving against a base URL.
- `URI.to_string/1` can reconstruct a `%URI{}` after host/scheme/userinfo/port/fragment are removed.

Implementation recommendation:

```elixir
defp normalize_next_path(next) when is_binary(next) do
  next
  |> URI.parse()
  |> Map.take([:path, :query])
  |> then(fn %{path: path, query: query} ->
    case query do
      nil -> path
      "" -> path
      query -> path <> "?" <> query
    end
  end)
end
```

Planner note: implement without depending on `then/2` if the project wants to keep the code visually simpler, but Elixir 1.19 is configured in `mix.exs`, so `then/2` is available.

---

## Codebase Findings

### Current Pagination Primitive

`lib/paddle/page.ex:1-9`:

- `%Paddle.Page{}` has `:data` and `:meta`.
- `Paddle.Page.next_cursor/1` returns `meta["pagination"]["next"]` when it is a binary, otherwise `nil`.

Phase 9 should add tests proving:

- `next_cursor/1` still returns a full URL/string when `has_more` is false.
- No new fields are added to `%Paddle.Page{}`.

### Current Subscription Listing

`lib/paddle/subscriptions.ex:21-31`:

- `list/2` validates params, allowlists query params, calls `Http.request(client, :get, "/subscriptions", params: query)`, maps each item through `build_subscription/1`, and returns `{:ok, %Paddle.Page{}}`.

Refactor recommendation:

- Keep `list/2` behavior unchanged.
- Extract a private `fetch_page(client, path, opts)` or two helpers:
  - `fetch_list_page(client, params)` for initial allowlisted calls;
  - `fetch_next_page(client, path)` for `next` path replay.
- Better option: use a single private `build_page(data, meta)` function and keep `list/2` nearly identical, adding a private `next_page(client, path)` that calls `Http.request(client, :get, path)` and then `build_page/2`.

### Current Address Listing

`lib/paddle/customers/addresses.ex:34-45`:

- `list/3` validates customer ID, normalizes params, allowlists query params, calls `Http.request(client, :get, customer_addresses_path(customer_id), params: query)`, maps each item to `%Paddle.Address{}`, and returns `{:ok, %Paddle.Page{}}`.

Refactor recommendation:

- Keep `list/3` behavior unchanged.
- Extract a private `build_page(data, meta)` and `next_page(client, path)` exactly like subscriptions.
- Do not validate `customer_id` for `next_page/2`; the path is a server-returned replay URL. Initial validation still happens before the stream/all helper returns meaningful work.

### HTTP Chokepoint

`lib/paddle/http.ex:4-23`:

- `Http.request/4` already accepts arbitrary Req opts, adds method/url, handles normalized HTTP and transport errors, and uses the Phase 8 retry baseline through `Paddle.Client.new!/1`.

Implementation consequence:

- No change is required in `Http.request/4`.
- Subsequent-page fetches get retry behavior automatically.
- Passing a normalized `path?query` string as `url:` should preserve the client Req base URL. Tests should assert a live absolute `next` URL does not make the adapter see `api.paddle.com` when the client is sandbox.

### Error Shape

`lib/paddle/error.ex`:

- `%Paddle.Error{}` is a `defexception`.
- Stream can raise it directly.
- `all/*` should return it inside `{:error, error}` without wrapping.

### Documentation State

`guides/accrue-seam.md` already documents `list/*` and `%Paddle.Page{}` as locked support types. Since Phase 9 intentionally adds public helpers, update the guide to list the four helpers. Keep `Paddle.Page.next_cursor/1` wording precise: it returns the next reference string, not a guarantee that more pages exist.

`guides/getting-started.md` currently shows manual subscription pagination. Update it after implementation to prefer `stream/*` and mention `all/*` for bounded result sets.

`CHANGELOG.md` should get a PAGE-01 bullet under `[Unreleased]` `Added`.

---

## Recommended Internal API

### `Paddle.Internal.Pagination`

```elixir
defmodule Paddle.Internal.Pagination do
  @moduledoc false

  def stream(first_page_fun, next_page_fun) when is_function(first_page_fun, 0) and is_function(next_page_fun, 1) do
    Stream.resource(
      fn -> {:first, first_page_fun, next_page_fun} end,
      &next_chunk/1,
      fn _ -> :ok end
    )
  end

  def all(first_page_fun, next_page_fun) do
    ...
  end
end
```

Suggested accumulator states:

- `{:first, first_page_fun, next_page_fun}`
- `{:next, path, next_page_fun}`
- `:done`

Suggested `next_chunk/1` behavior:

- Fetch first page only when enumeration starts.
- On `{:ok, page}`, emit `page.data` and move to `{:next, normalized_path, next_page_fun}` only when `has_more?(page)` is true.
- When `has_more?(page)` is false, emit `page.data` and move to `:done`.
- On `{:error, %Paddle.Error{} = error}`, raise `error`.
- On `{:error, atom}`, raise `ArgumentError` with context.
- On `:done`, return `{:halt, :done}`.

Important detail:

- If a page has `data: []` and `has_more: true`, `Stream.resource/3` will emit `[]` and continue only on the next pull. This can still terminate correctly, but tests do not need to create a zero-item intermediate page. If executor sees edge complexity, use a private recursive `fetch_non_empty_or_done/1` to avoid odd `Enum.take/2` behavior on empty pages.

### `all/2`

Do not implement `all/*` by rescuing `stream/*` exceptions. Normal eager control flow should use the same callbacks and return tuples:

- `{:ok, items}` after all pages succeed.
- `{:error, reason}` on first error before or during pagination.
- Preserve order by accumulating reversed chunks and `Enum.reverse/1` once at the end, or append chunks carefully for the small expected page counts in tests.

### Resource Module Additions

`Paddle.Subscriptions`:

```elixir
def stream(%Client{} = client, params \\ []) do
  Pagination.stream(fn -> list(client, params) end, fn path -> next_page(client, path) end)
end

def all(%Client{} = client, params \\ []) do
  Pagination.all(fn -> list(client, params) end, fn path -> next_page(client, path) end)
end
```

`Paddle.Customers.Addresses`:

```elixir
def stream(%Paddle.Client{} = client, customer_id, params \\ []) do
  Pagination.stream(fn -> list(client, customer_id, params) end, fn path -> next_page(client, path) end)
end

def all(%Paddle.Client{} = client, customer_id, params \\ []) do
  Pagination.all(fn -> list(client, customer_id, params) end, fn path -> next_page(client, path) end)
end
```

Both modules need private `next_page/2` and `build_page/2`.

---

## Test Strategy

### Test Helpers

Use the existing inline `client_with_adapter/1` helper pattern. For multi-page tests, wrap a list of expected request assertions in an `Agent`:

```elixir
{:ok, requests} = Agent.start_link(fn -> expected_pages end)

client =
  client_with_adapter(fn request ->
    [next | rest] = Agent.get_and_update(requests, fn [next | rest] -> {next, rest} end)
    next.(request)
  end)
```

This mirrors Phase 8 retry tests and avoids mutable process dictionary state.

### Required Coverage

For `Paddle.Subscriptions`:

- `stream/2` over three pages yields subscription IDs in order.
- `all/2` over the same three pages returns `{:ok, items}` with the same IDs as `stream/2 |> Enum.to_list()`.
- `list/2` regression still returns `{:ok, %Paddle.Page{}}`.
- Page 2 `%Paddle.Error{}` makes `stream/2 |> Enum.to_list()` raise `%Paddle.Error{}` and `all/2` return `{:error, error}`.
- Invalid initial params make `stream/2 |> Enum.to_list()` raise `ArgumentError` and `all/2` return `{:error, :invalid_params}`.
- `Enum.take(stream, 1)` does not fetch page 2.
- Absolute next URL normalizes to request path/query, preserving the sandbox base URL.
- `has_more: false` with a non-nil `next` does not fetch another page.

For `Paddle.Customers.Addresses`:

- Same happy-path, equivalence, list-shape, error, laziness, absolute/relative replay coverage, with an emphasis on nested path `/customers/{id}/addresses`.
- Invalid initial customer ID raises `ArgumentError` for stream and returns `{:error, :invalid_customer_id}` for all.

For `Paddle.Page`:

- `next_cursor/1` still returns `"https://api.paddle.com/subscriptions?after=sub_01"` even when `meta.pagination.has_more` is false.

### Verification Commands

- `mix test test/paddle/page_test.exs test/paddle/subscriptions_test.exs test/paddle/customers/addresses_test.exs --color`
- `mix test --color`
- `mix compile --warnings-as-errors`
- `mix format --check-formatted`

---

## Pitfalls

1. **Using `next_cursor != nil` as continuation.** Paddle returns `next` even when `has_more` is false. This causes one extra request at best and an infinite/polling bug at worst.
2. **Reconstructing `after` params manually.** `next` preserves filters, order, nested path, and future Paddle query params. Reconstructing only `after` drops semantics.
3. **Using absolute `next` URL directly.** Doing so risks bypassing the client's sandbox/live base URL. Normalize to `path?query`.
4. **Implementing `all/*` with `Enum.to_list(stream)` and rescue.** This loses clear tuple control flow and makes local validation errors depend on exception messages.
5. **Fetching the first page before returning the stream.** `stream/*` must be lazy. The first HTTP request belongs to enumeration, not helper construction.
6. **Changing `list/*` return shapes while refactoring.** `list/*` is locked and must keep returning `{:ok, %Paddle.Page{}}`.
7. **Adding a public generic pagination module.** It violates D-03 and expands the public seam prematurely.
8. **Forgetting docs.** This phase intentionally adds public helper functions; `guides/accrue-seam.md`, `guides/getting-started.md`, and `CHANGELOG.md` should reflect them.

---

## Sources Checked

- Paddle pagination overview: https://developer.paddle.com/api-reference/about/pagination/
- Paddle subscriptions list endpoint: https://developer.paddle.com/api-reference/subscriptions/list-subscriptions/
- Paddle customer addresses list endpoint: https://developer.paddle.com/api-reference/addresses/list-addresses/
- Paddle transactions list endpoint: https://developer.paddle.com/api-reference/transactions/list-transactions/
- Elixir `Stream.resource/3`: https://elixir.hexdocs.pm/Stream.html#resource/3
- Elixir `Enumerable`: https://elixir.hexdocs.pm/Enumerable.html
- Elixir `URI`: https://elixir.hexdocs.pm/URI.html

## RESEARCH COMPLETE
