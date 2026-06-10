# Feature Landscape

**Domain:** API SDK (Paddle Billing - Catalog & Events)
**Researched:** 2026-06-09

## Table Stakes

Features users expect for the foundational read-only surface of Catalog and Events in an Elixir SDK. Missing = product feels incomplete for webhook reconciliation and catalog presentation.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `Paddle.Products.get/2` & `list/2` | Basic catalog retrieval to show products on custom pricing pages. | Low | Core entities. Returns `%Paddle.Product{}` structs. |
| `Paddle.Prices.get/2` & `list/2` | Required to retrieve pricing details and localized pricing for checkouts. | Low | Returns `%Paddle.Price{}` structs. Must handle complex `billing_cycle` definitions. |
| `Paddle.Events.get/2` & `list/2` | Necessary for webhook reconciliation and audit trails. | Med | Must reuse the webhook `%Paddle.Event{}` payload parsing so API fetches match webhook payloads perfectly. |
| Automatic Pagination | Crucial for iterating through full product catalogs and historical events without writing custom cursor loops. | Low | Handled by existing `stream/*` functionality built in Phase 9 (`PAGE-01`). |
| Explicit Structs with `:raw_data` | Forward-compatibility and DX (pattern matching, Dialyzer typing). | Low | Standard pattern established in earlier phases. Avoids drift. |

## Differentiators

Features that set the SDK apart, emphasizing great Developer Experience (DX) and idiomatic Elixir.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Event Payload Polymorphism | `Paddle.Events.list/2` yields strongly-typed embedded structs (e.g., `%Paddle.Transaction{}`) identical to webhook payloads. | Med | Requires `Paddle.Event` decoder to seamlessly share logic with `Paddle.Webhooks.parse_event/1`. |
| Embedded Entities in Catalog | Support for Paddle's `?include=` params (like including Product details when querying Prices) with struct nesting. | Med | Dramatically reduces N+1 API calls when rendering pricing tables. |
| Filter/Query Type Safety | Providing explicit types/structs for Event query parameters (like `event_type=transaction.completed`) to aid reconciliation. | Low | Idiomatic typing prevents typos in queries. |

## Anti-Features

Features to explicitly NOT build to maintain purity, avoid bloat, and uphold `oarlock` mandates.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Ecto Schema Syncing / Dual Writes | Bloats the SDK, couples it to Ecto/DB, and makes assumptions about the app's persistence layer. | Leave synchronization to the consumer (like `Accrue`). Return pure `%Paddle.Product{}` structs. |
| Catalog Write Surface (Create/Update) | Unnecessary for Phase 1.4 read-only goals. Most users manage the catalog in the Paddle Dashboard. | Defer to v0.x or future milestones. Focus exclusively on `list/2` and `get/2`. |
| Built-in Event Replay/Worker Queue | SDK should not include Oban or background job abstractions. | Return the stream of events; let the host app's Oban/Task infrastructure handle ingestion and replay. |
| Caching | In-memory or ETS caching of the catalog adds stateful complexity and invalidation headaches. | Provide fast HTTP calls. Host apps can use Nebulex or Cachex. |

## Feature Dependencies

```
Catalog (Products/Prices) Schema → Existing HTTP Transport
Events API Fetch → Existing %Paddle.Event{} schema & Webhook parsers
Events API Fetch → Existing Pagination helpers (stream/2)
```

## MVP Recommendation

Prioritize:
1. `Paddle.Products` read surface (`list`, `get`).
2. `Paddle.Prices` read surface (`list`, `get`).
3. `Paddle.Events` read surface (`list`, `get`) integrated with the existing `Paddle.Event` parser.
4. Auto-pagination (via existing generic helpers) for both APIs.

Defer: 
- Catalog Create/Update: Not required for displaying pricing or syncing state.
- `Paddle.NotificationSettings` management: Unless immediately needed for dynamic endpoint registration, the dashboard is sufficient for v1.4.

## Sources

- `.planning/PROJECT.md`: Constrains scope to read-only catalog and events.
- `prompts/paddle-elixir-lib-deep-research.md`: Emphasizes structs, `raw_data` preservation, and explicit `req`-driven pure functional API.
- Official Paddle Billing API v1 Documentation (Products, Prices, Events).
