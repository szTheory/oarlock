# Project Research Summary

**Project:** oarlock (Customer Portal Sessions and Adjustments)
**Domain:** Elixir SDK / API Client (Paddle Billing v1)
**Researched:** 2026-06-09
**Confidence:** HIGH

## Executive Summary

The project entails integrating two new entities into the `oarlock` Elixir SDK for Paddle Billing v1: **Customer Portal Sessions** and **Adjustments**. Both domains rely entirely on standard JSON over HTTP REST APIs and map perfectly into the project's existing explicit client-passing architecture. The recommended approach continues utilizing the zero-dependency `req` HTTP client without requiring any new external libraries like `Ecto` or Phoenix, preserving the SDK's purity.

To integrate these features correctly, developers must strictly adhere to the established nested resource context patterns and define top-level structs (`Paddle.PortalSession`, `Paddle.Adjustment`). The core capabilities include synchronous on-demand portal session creation (to avoid cached token expiration) and complete adjustment lifecycle operations (creation, retrieval, and pagination).

The most critical risks involve state and timing mismatches. Specifically, developers might mistakenly cache the short-lived portal session URLs or assume refunds are finalized synchronously rather than handling asynchronous `pending_approval` webhooks. We mitigate these by explicitly avoiding URL caching in our design guidelines, relying solely on on-demand generation, and strictly enforcing the immutability of Adjustments while ensuring the `status` field is prominently typed and exposed.

## Key Findings

### Recommended Stack

No new dependencies are required; the current core stack is fully capable. 

**Core technologies:**
- **Elixir (~> 1.19):** Core language — existing project requirement.
- **`req` (~> 0.5.17):** HTTP Client — zero-dependency client with built-in JSON parsing and retries, sufficient for Paddle API interactions.
- **`dialyxir`:** Static typing — ensures new structs maintain strong typing guarantees.

### Expected Features

**Must have (table stakes):**
- **Portal Session Creation:** POST to `/customers/{id}/portal-sessions`. Returns `urls` object.
- **Adjustment Creation:** POST to `/adjustments` to handle "refunds" and "credits". Must support full and partial (with item tracking).
- **Adjustment Retrieval & Pagination:** GET `/adjustments/{id}` and `/adjustments` to check refund approval states.
- **Adjustment Webhooks:** Parsing `adjustment.created` and `adjustment.updated` events.

**Should have (competitive):**
- **Credit Note PDF Retrieval:** `GET /adjustments/{id}/credit-note` for automated tax/receipt workflows.
- **Client-Side Validation:** Guarding `action` based on transaction status before hitting the API.

**Defer (v2+):**
- Deep client-side validation (rely on Paddle's API errors for v1).
- Credit Note Retrieval (useful but not essential for initial launch).

### Architecture Approach

The architecture will introduce new pure data structures and contextual operation modules parallel to existing resources, avoiding any UI/DB coupling.

**Major components:**
1. **`Paddle.PortalSession` & `Paddle.Adjustment`:** Structs defining responses and lifecycle metadata. Both require `raw_data: map() | nil` for forward compatibility.
2. **`Paddle.Customers.PortalSessions`:** HTTP context for generating portal sessions (`create/3`).
3. **`Paddle.Adjustments`:** HTTP context operations (`create/2`, `get/2`, `all/2`) supporting standard CRUD pagination.

### Critical Pitfalls

1. **Caching Portal Session URLs** — Never store portal URLs. The SDK must generate them synchronously on-demand and clients must immediately redirect to prevent expiration errors.
2. **Assuming Synchronous Refund Execution** — Refunds often enter `pending_approval`. The SDK must explicitly surface the `status` field and consumers should rely on webhooks.
3. **Wrong ID for Partial Refunds** — Passing `price_id` instead of `item_id`. Explicitly document and type the `items` array to require transaction line item IDs.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Customer Portal Sessions
**Rationale:** Portal sessions are a standalone feature nested under Customers. It's an isolated, low-complexity entry point.
**Delivers:** `Paddle.PortalSession` struct and `Paddle.Customers.PortalSessions.create/3` operation.
**Addresses:** Portal Session Creation feature and nested resource context patterns.
**Avoids:** Caching Portal URLs (by explicitly documenting synchronous usage and deep-linking).

### Phase 2: Adjustments (Refunds & Credits)
**Rationale:** Adjustments are top-level but complex, involving partial items and status tracking.
**Delivers:** `Paddle.Adjustment` struct, `Paddle.Adjustments` operations (`create/2`, `get/2`, `all/2`), and `adjustment.*` webhook handlers.
**Addresses:** Adjustment Creation, Retrieval, Webhooks features.
**Avoids:** Assuming Synchronous Refund Execution and Wrong ID for Partial Refunds (by explicitly surfacing `status` and typing `item_id`).

### Phase 3: Seam Validation and Documentation
**Rationale:** Ensures the core library continues perfectly serving the primary consumer application (Accrue) and meets testing guarantees.
**Delivers:** Updates to `guides/accrue-seam.md`, `seam_test.exs`, and `@moduledoc` coverage.
**Uses:** Standard project testing and HTTP mocking setups.
**Implements:** The final integration contract between the SDK and consumer app.

### Phase Ordering Rationale

- **Independence:** Portals (Phase 1) and Adjustments (Phase 2) are mostly independent, but Portals are smaller and simpler, allowing for quick initial velocity.
- **Verification Last:** Phase 3 groups seam validation to ensure all newly introduced structs (Portals and Adjustments) correctly mock out responses required by the primary Accrue application.

### Research Flags

Phases with standard patterns (skip research-phase):
- **Phase 1 (Portal Sessions):** Standard HTTP POST returning nested JSON; idiomatic to existing code.
- **Phase 2 (Adjustments):** Existing pagination and POST patterns (`Paddle.Internal.Pagination`) are already well-established.
- **Phase 3 (Validation):** Existing seam guide handles this explicitly.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Pure REST API; existing `req` and Elixir stack are perfectly suited. |
| Features | HIGH | Table stakes are clearly defined in official Paddle API docs. |
| Architecture | HIGH | Codebase already has strict, well-established patterns for new API resources. |
| Pitfalls | HIGH | Known pain points (like magic link expiration and async refunds) are documented in Paddle integration guides. |

**Overall confidence:** HIGH

### Gaps to Address

- **Webhook Verification:** We must ensure `adjustment.updated` webhooks provide the exact same payload structure as the standard API responses so `Http.build_struct/2` works flawlessly. This will be verified during Phase 2 execution.

## Sources

### Primary (HIGH confidence)
- [Paddle API Docs: Customer Portal Sessions](https://developer.paddle.com/api-reference/customer-portal-sessions) — Endpoints and payload structures.
- [Paddle API Docs: Adjustments](https://developer.paddle.com/api-reference/adjustments) — Endpoints, item requirements, and `status` tracking.
- Internal `oarlock` Codebase — `Paddle.Customers.Addresses`, `Paddle.Internal.Attrs`, and `Paddle.Internal.Pagination`.

---
*Research completed: 2026-06-09*
*Ready for roadmap: yes*