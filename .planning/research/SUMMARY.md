# Project Research Summary

**Project:** oarlock
**Domain:** Elixir SDK for Paddle Billing (Catalog & Events)
**Researched:** 2026-06-09
**Confidence:** HIGH

## Executive Summary

This research informs the addition of the Catalog (Products/Prices) and Events API surface to the `oarlock` Elixir SDK for Paddle Billing. The goal is to provide a comprehensive, read-only functional interface for the v1.4 milestone, enabling developers to sync products, render pricing tables, and reconcile historical webhooks without coupling the library to specific frameworks like Phoenix or Ecto.

The recommended approach continues the established architectural patterns of the SDK: using `Req` for HTTP transport, maintaining explicit `%Paddle.Client{}` state, relying on built-in Elixir streams for auto-pagination, and strictly mapping JSON responses to strongly-typed structs with `:raw_data` escape hatches. No new dependencies are required to fulfill these features. The REST Events API will seamlessly reuse the existing `%Paddle.Event{}` struct and parsers originally built for webhooks, providing polymorphic payloads regardless of whether events are pushed or pulled.

Key risks involve improper handling of cursor-based pagination for the high-volume Events API, which can lead to desynced state or infinite loops, and developers treating historical event payloads as the "source of truth." These are mitigated by blindly following Paddle's provided next-page URLs and documenting clear guidance to fetch canonical state using other endpoints.

## Key Findings

### Recommended Stack

No new dependencies are required for the v1.4 Catalog & Events milestone. The existing core stack is 100% sufficient and perfectly aligns with the pure functional mandates.

**Core technologies:**
- **Req (`~> 0.5.17`)**: HTTP Transport & JSON Parsing — Perfectly handles standard REST endpoints for Products, Prices, and Events natively without adding complex HTTP clients.
- **Elixir (`~> 1.19`)**: Language & Types — Leverages built-in `Stream` for auto-pagination and strict typing.
- **Telemetry (`~> 1.4`)**: Observability — Existing integration via `Req` will emit events when Catalog queries or Event history fetches complete.

### Expected Features

The scope is tightly focused on read-only endpoints and robust developer experience.

**Must have (table stakes):**
- `Paddle.Products.get/2` & `list/2` — Returns `%Paddle.Product{}` structs.
- `Paddle.Prices.get/2` & `list/2` — Returns `%Paddle.Price{}` structs.
- `Paddle.Events.get/2` & `list/2` — Necessary for webhook reconciliation and audit trails.
- Auto-Pagination — Critical for iterating through catalogs and events using existing `stream/*` helpers.
- Explicit Structs with `:raw_data` — Preserves forward compatibility.

**Should have (competitive):**
- Event Payload Polymorphism — `Paddle.Events.list/2` yields strongly-typed embedded structs (e.g., `%Paddle.Transaction{}`) identical to webhook payloads.
- Filter/Query Type Safety — Explicit types for query parameters to aid reconciliation.

**Defer (v2+):**
- Catalog Write Surface (Create/Update) — Not required for Phase 1.4. Focus strictly on read-only.
- Ecto Schema Syncing — Bloats the SDK, violates architectural constraints.
- Built-in Event Replay/Worker Queue — Host applications should handle ingestion and replay natively.

### Architecture Approach

The addition of Catalog and Events seamlessly extends the existing functional and typed architecture. We continue with the explicit `%Paddle.Client{}` parameter, strict allowlists for query parameters, and per-resource auto-pagination.

**Major components:**
1. **`Paddle.Products` / `Paddle.Prices`** — Read-only API surface wrapping `Paddle.Http` calls, returning explicit structs.
2. **`Paddle.Events`** — Read-only API surface for retrieving event history. Reuses existing `Paddle.Event` struct and logic from `Paddle.Webhooks`.
3. **`Paddle.Internal.Pagination`** — Existing logic used to expose an idiomatic Elixir stream interface.

### Critical Pitfalls

1. **Pagination Cursor Mishandling for Events** — The SDK must blindly follow the exact `meta.pagination.next` URL provided in the response rather than attempting to construct the next request manually.
2. **Custom vs. Standard Catalog Item Blindness** — Custom items created during checkout won't appear in the Catalog. Attempting to fetch them via `Paddle.Prices.get/2` returns a 404. Must be clearly documented.
3. **Event State "Source of Truth" Blindness** — Events are immutable triggers, not absolute truth. Overwriting current state with an old event payload regresses state. Document clearly to fetch canonical state.
4. **Exhausting API Limits via "All Events"** — The events stream is incredibly noisy. Encourage `event_type` filtering to avoid hitting the 240 req/min rate limit.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Products API
**Rationale:** The foundational entity of the Catalog. Has no dependencies and establishes the read-only catalog pattern.
**Delivers:** `Paddle.Product` struct and `Paddle.Products` read-only module (`get`, `list`, `stream`).
**Addresses:** Basic catalog retrieval.
**Avoids:** Custom vs Standard item blindness (via explicit documentation).

### Phase 2: Prices API
**Rationale:** Prices depend on Products conceptually and are the second half of the catalog needed for checkouts.
**Delivers:** `Paddle.Price` struct and `Paddle.Prices` read-only module (`get`, `list`, `stream`).
**Addresses:** Retrieval of pricing details and localized pricing.
**Uses:** Standard `Req` HTTP transport and explicit structs.

### Phase 3: Events API
**Rationale:** Reuses the existing webhook parser infrastructure but applies it to the REST API. Complex but isolated.
**Delivers:** `Paddle.Events` read-only API module (`get`, `list`, `stream`).
**Addresses:** Webhook reconciliation and audit trails with polymorphic payloads.
**Avoids:** Pagination Cursor Mishandling (by leveraging existing auto-pagination stream implementation) and API Limit exhaustion (by allowing `event_type` filters).

### Phase 4: Notification Settings API (Optional / Deferrable)
**Rationale:** While researched, creating/updating notification settings is rarely done via API (usually via Dashboard). Can be implemented if full CRUD for settings is strictly desired in this milestone, otherwise defer.
**Delivers:** `Paddle.NotificationSetting` struct and full CRUD module.

### Phase Ordering Rationale

- **Products before Prices:** Follows Paddle's logical hierarchy.
- **Events last:** Events are standalone and rely heavily on reusing the `Paddle.Event` struct from previous webhook phases. Placing them last ensures catalog primitives are established in case events reference them.
- **Consistent patterns:** All phases rely heavily on the existing `Paddle.Internal.Pagination` module, making implementation primarily focused on schema definition and query allowlisting.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Events API):** May require verifying exactly how the REST response payload maps to the existing `Paddle.Event` decoder to ensure 100% compatibility without breaking existing webhook logic.

Phases with standard patterns (skip research-phase):
- **Phase 1 & 2:** Standard REST GET operations. Highly predictable and well-documented by Paddle. Follows exact patterns established in earlier `oarlock` entities.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Constrained by existing, well-tested project boundaries. No new dependencies. |
| Features | HIGH | Read-only API goals are explicitly defined by Paddle API specs. |
| Architecture | HIGH | Extending existing mature patterns within the SDK. |
| Pitfalls | HIGH | Identified from documented limitations in Paddle APIs and community issues. |

**Overall confidence:** HIGH

### Gaps to Address

- **Payload discrepancies:** Need to validate during Phase 3 planning if Paddle's `/events` REST payload differs in any subtle way from incoming webhook payloads.
- **Notification Settings Scope:** Decision needed on whether to implement full CRUD for Notification Settings in this milestone or strictly defer it to keep scope tight.

## Sources

### Primary (HIGH confidence)
- `.planning/PROJECT.md` — Verified constraint: pure functional library without UI, database, or Phoenix/Ecto coupling.
- [Paddle API Reference: Products](https://developer.paddle.com/api-reference/products/list-products)
- [Paddle API Reference: Prices](https://developer.paddle.com/api-reference/prices/list-prices)
- [Paddle API Reference: Events](https://developer.paddle.com/api-reference/events/list-events)

### Secondary (MEDIUM confidence)
- hookwatch.dev — Event Ordering, State Synchronization pitfalls for Paddle v2.

---
*Research completed: 2026-06-09*
*Ready for roadmap: yes*