# Architecture Patterns: Catalog & Events

**Domain:** SaaS Billing / API SDK
**Researched:** 2026-06-09

## Recommended Architecture

The addition of Catalog (Products/Prices) and Events seamlessly extends the existing functional and typed architecture of `paddle_sdk` (`oarlock`). We continue with the explicit `%Paddle.Client{}` parameter, reliance on `Req` for the HTTP transport, strict allowlists for query parameters, and per-resource auto-pagination. 

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Paddle.Product` | Struct defining the Product schema. Maintains forward-compatibility via `:raw_data`. | None |
| `Paddle.Products` | Read-only API surface (`get`, `list`, `all`, `stream`). | `Paddle.Http`, `Paddle.Internal.Pagination` |
| `Paddle.Price` | Struct defining the Price schema. Maintains forward-compatibility via `:raw_data`. | None |
| `Paddle.Prices` | Read-only API surface (`get`, `list`, `all`, `stream`). | `Paddle.Http`, `Paddle.Internal.Pagination` |
| `Paddle.Events` | Read-only API surface for retrieving event history (`get`, `list`, `all`, `stream`). Reuses existing `Paddle.Event` struct. | `Paddle.Http`, `Paddle.Internal.Pagination`, `Paddle.Event` |
| `Paddle.NotificationSetting` | Struct defining webhook destination configs, including `endpoint_secret_key` and `subscribed_events`. | None |
| `Paddle.NotificationSettings` | Full CRUD surface (`create`, `get`, `update`, `delete`, `list`, `all`, `stream`). | `Paddle.Http`, `Paddle.Internal.Pagination` |

### Data Flow

1. **Read Path:** A consumer passes a `%Paddle.Client{}` struct and an entity ID (or query params) to `Paddle.Products.get/2` or `list/2`. The module normalizes params (using `Paddle.Internal.Attrs`), drops un-allowlisted keys, and calls `Paddle.Http.request/4`. The JSON response is parsed into the respective Struct via `Paddle.Http.build_struct/2`.
2. **Pagination Flow:** Endpoints that return lists are wrapped using `Paddle.Internal.Pagination.all/2` and `stream/2` helpers, exposing an idiomatic Elixir stream interface.
3. **Event Unification:** Webhooks and the REST API use identical event payload formats. `Paddle.Events.get/2` will return the exact same `%Paddle.Event{}` shape that `Paddle.Webhooks.parse_event/1` generates.

## Patterns to Follow

### Pattern 1: Typed Read-Only Modules
**What:** Implementing read-only APIs for `Products`, `Prices`, and `Events` without providing `create`, `update`, or `delete` methods, per the current milestone requirements.
**When:** For foundational catalog items managed via the Paddle Dashboard instead of an app.
**Example:**
```elixir
# lib/paddle/products.ex
defmodule Paddle.Products do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Product
  alias Paddle.Internal.Pagination

  @list_allowlist ~w(id status tax_category include order_by after per_page)

  @spec get(Paddle.Client.t(), String.t()) :: {:ok, Paddle.Product.t()} | {:error, Paddle.Error.t() | :invalid_product_id}
  def get(%Client{} = client, product_id) do
    # validation, http call, struct building
  end

  @spec list(Paddle.Client.t(), keyword()) :: {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t()}
  def list(%Client{} = client, params \\ []) do
    # allowlist check, http call, map to Page
  end

  @spec stream(Paddle.Client.t(), keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(fn -> list(client, params) end, &next_page(client, &1))
  end
end
```

### Pattern 2: Struct Reuse for Events
**What:** `Paddle.Event` was initially built for the `Webhooks` webhook parser. The exact same struct is used for REST API responses in `Paddle.Events`.
**When:** To maintain data model consistency between push (Webhooks) and pull (API stream) integrations.
**Example:**
```elixir
case Paddle.Events.get(client, "evt_123") do
  {:ok, %Paddle.Event{} = event} -> 
    # Can process this identically to an event coming through the webhook router
    process_event(event)
end
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Eager Struct Hydration for nested objects
**What:** Trying to hydrate nested Price objects when calling `Paddle.Products.list(client, include: "prices")`.
**Why bad:** The API might return relational includes. Adding nested complex relationships within `Paddle.Http.build_struct` makes the core SDK brittle and complex to maintain.
**Instead:** Rely on `:raw_data` for nested relationships, or instruct consumers to fetch the relationships via `Paddle.Prices.list(client, product_id: product_id)`. Follow the current standard of simple `build_struct` behavior with fallback.

### Anti-Pattern 2: Skipping Allowlists
**What:** Passing through query options dynamically in `list/2`.
**Why bad:** Allows bad or unsupported inputs to hit the Paddle API, generating opaque 400 errors instead of quick local validation failures.
**Instead:** Maintain explicit `@list_allowlist`, `@create_allowlist`, and `@update_allowlist` attributes in each new module.

## Suggested Build Order

To properly handle dependencies and isolate functional areas:

1. **`Paddle.Product` / `Paddle.Products`**: Implement read-only REST APIs and pagination. Add tests for `get`, `list`, `stream`.
2. **`Paddle.Price` / `Paddle.Prices`**: Implement read-only REST APIs. Add tests. Ensure `product_id` query param filtering works.
3. **`Paddle.Events`**: Add the new API module. Re-use existing `Paddle.Event` struct. Ensure `list/2` supports filtering by `event_type` and `id` which is critical for Accrue to reconcile missed webhooks.
4. **`Paddle.NotificationSetting` / `Paddle.NotificationSettings`**: Provide the full CRUD layer. Handle complex types for nested elements like `subscribed_events`.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Missed Webhooks | Ignore or handle manually. | Webhooks occasionally drop. Run cron job hitting `Paddle.Events.stream/2` to verify and ingest missing `subscription.created` events. | Same approach. Paginating the `/events` endpoint sequentially becomes the source of truth, minimizing webhook reliance. |

## Sources
- [Paddle API Reference: Products](https://developer.paddle.com/api-reference/products/list-products) (HIGH Confidence)
- [Paddle API Reference: Prices](https://developer.paddle.com/api-reference/prices/list-prices) (HIGH Confidence)
- [Paddle API Reference: Events](https://developer.paddle.com/api-reference/events/list-events) (HIGH Confidence)
- [Paddle API Reference: Notification Settings](https://developer.paddle.com/api-reference/notification-settings/list-notification-settings) (HIGH Confidence)
