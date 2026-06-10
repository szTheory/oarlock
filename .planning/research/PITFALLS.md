# Domain Pitfalls

**Domain:** Paddle Billing API (Catalog & Events)
**Researched:** 2026-06-09

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Pagination Cursor Mishandling for Events
**What goes wrong:** Skipping events or getting stuck in an infinite polling loop when reconciling webhook history.
**Why it happens:** Paddle's Events API is purely cursor-based. Developers often try to manually extract the `after` cursor and rebuild the query string, dropping important filters, or they try to use standard offset pagination.
**Consequences:** Skipped events lead to desynced databases where customers are billed but not provisioned, or canceled but still have access.
**Prevention:** The SDK's `all/*` and `stream/*` pagination helpers must blindly follow the exact `meta.pagination.next` URL provided in the response rather than attempting to construct the next request manually.
**Detection:** Missing data reports in downstream consumers, or API 400s from malformed cursor queries.

### Pitfall 2: Custom vs. Standard Catalog Item Blindness
**What goes wrong:** Fetching a transaction's items and attempting to look up their details via `Paddle.Prices.get/2`, resulting in an unexpected `404 Not Found`.
**Why it happens:** Paddle Billing allows for "Custom" prices/products created on the fly during checkout, alongside "Standard" catalog items. Custom items do not exist in the canonical Catalog and will not be returned by the `/products` or `/prices` endpoints.
**Consequences:** Hard crashes in SDK consumers attempting to hydrate or reconcile all items using the Catalog API.
**Prevention:** The SDK must clearly document this distinction in the `@moduledoc` for `Paddle.Products` and `Paddle.Prices`. The SDK should not attempt to automatically "hydrate" transaction line items using catalog lookups behind the scenes.
**Detection:** Unhandled `404` errors in consumer logs when processing transactions.

## Moderate Pitfalls

### Pitfall 1: Event State "Source of Truth" Blindness
**What goes wrong:** A consumer polls the `Paddle.Events` API for missed webhooks and directly saves the `data` payload of the event to their database, inadvertently regressing a user's state.
**Why it happens:** Events are immutable historical records. If an app processes a `subscription.updated` event from 4 hours ago, but the user canceled 10 minutes ago, saving the event's payload overwrites the cancellation.
**Prevention:** Add explicit warnings in the `Paddle.Events` module documentation that events are *triggers*, not truth. Advise consumers to use the event to know *what* changed, but to call `Paddle.Subscriptions.get/2` or `Paddle.Transactions.get/2` to fetch the current canonical state.

### Pitfall 2: Exhausting API Limits via "All Events"
**What goes wrong:** Polling the Events API without filters, triggering Paddle's 240 requests/minute rate limit.
**Why it happens:** The events stream is incredibly noisy. Fetching it blindly for reconciliation generates massive payloads and requires rapid pagination.
**Prevention:** The `Paddle.Events.list/2` function should encourage the use of `event_type` filtering (e.g., only fetching `subscription.*` events) through examples in its `@doc` block.

## Minor Pitfalls

### Pitfall 1: Mixing Billing Intervals
**What goes wrong:** Attempting to combine different Prices in a single checkout/transaction fails with an API error.
**Why it happens:** Paddle Billing strictly prohibits mixing intervals (e.g., a monthly subscription and an annual add-on) in the same transaction.
**Prevention:** Note this limitation in the Catalog documentation to guide users on how to properly structure their Products and Prices.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Events Retrieval (`Paddle.Events`) | Breaking cursor pagination. | Ensure `PAGE-01` helpers (auto-pagination) natively follow the `meta.pagination.next` full URL instead of manually rebuilding query parameters. |
| Catalog Listing (`Paddle.Products`) | Assuming Custom items appear in lists. | Document the Standard vs. Custom distinction clearly in the `@moduledoc`. |
| Events Reconciliation | Using old event payloads as truth. | Warn in `Paddle.Events` documentation to fetch canonical state using `Paddle.Subscriptions.get/2` rather than applying event data directly. |

## Sources

- **HIGH Confidence:** Paddle Official Documentation (Cursor pagination, Standard vs Custom items, Billing intervals limit).
- **HIGH Confidence:** hookwatch.dev (Event Ordering, State Synchronization pitfalls for Paddle v2).
