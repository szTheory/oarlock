# Project: Paddle Elixir SDK

## What This Is
A production-quality, idiomatic Elixir SDK for Paddle Billing (`paddle_sdk`) to serve as a pure, standalone foundation for Accrue's "second processor" strategy. The library relies on `req` for modern HTTP interactions and uses explicit client contexts without enforcing global app configs.

## Core Value
Provides seamless, native Elixir interaction with the current Paddle Billing API v1 through explicit %Paddle.Client{} passing, typed struct responses, and robust webhook verification that avoids reliance on Phoenix or Ecto coupling.

## Key Constraints & Context
- Must be a pure functional library, avoiding UI, database syncing, or framework-specific plugins (like `Plug.Parsers` implementations for Phoenix, which will be documented instead).
- Must avoid legacy "Paddle Classic" concepts.
- Must retain forward compatibility via `__raw__` mapping of API responses.
- Explicit deferment of complex domain areas (refunds, invoices, marketplaces, payment portals) to v0.2+.

## Current Milestone: v1.1 Accrue Seam Hardening

**Goal:** Close the consumer-contract gaps Accrue needs to confidently consume oarlock as its Paddle backend.

**Target features:**
- `Paddle.Transactions.get/2` — closes the Phase 4 retrieval gap; mirrors `Paddle.Subscriptions.get/2`. (B-01)
- End-to-end Accrue seam integration test — single-fixture path through customer → address → transaction → webhook → subscription get → cancel. (B-02)
- Consumer-facing seam surface doc — renderable contract listing public modules, locked structs, and stability tiers. (B-03)

**Phase numbering:** continues from v1.0 (last phase 5) → v1.1 starts at Phase 6.

## Requirements

### Validated
- [x] Explicit client passing with `Paddle.Client.new!/1` (Bearer auth, Paddle-Version). *(Phase 1)*
- [x] HTTP transport via `req` with retries and telemetry. *(Phase 1)*
- [x] Typed `{:ok, struct}` / `{:error, %Paddle.Error{}}` responses with `raw_data` forward compatibility. *(Phase 1, applied throughout)*
- [x] `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1` with strict raw-body matching. *(Phase 2)*
- [x] `Paddle.Customers` (create, get, update). *(Phase 3)*
- [x] `Paddle.Customers.Addresses` (create, list, update). *(Phase 3)*
- [x] `Paddle.Transactions.create/2` returning hosted checkout URL. *(Phase 4)*
- [x] `Paddle.Subscriptions` (get, list, cancel). *(Phase 5 — `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2` with hydrated `%ScheduledChange{}` and `%ManagementUrls{}`; 23 adapter-backed tests.)*
- [x] Testing matrix across Elixir/Erlang versions, Credo, Dialyzer, ExDoc. *(Phase 1 baseline; carried through v1.0)*

### Active (v1.1)
- [ ] **TXN-03**: `Paddle.Transactions.get/2` — fetch a transaction by ID with hydrated checkout struct.
- [ ] **SEAM-01**: End-to-end Accrue seam integration test exercising the full consumer contract path.
- [ ] **SEAM-02**: Consumer-facing seam surface doc enumerating locked modules, structs, and stability tiers.

### Out of Scope
- **Paddle Classic Support**: Must only support Paddle Billing API v1.
- **Phoenix/Ecto coupling**: No framework or database integration code in the core library.
- **Payment Method Portals**: Deferred for v0.1.
- **Invoice Generation**: Deferred for v0.1.
- **Refunds**: Deferred for v0.1.
- **Connect / Marketplaces**: Deferred for v0.1.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **HTTP Client** | `req` provides modern Elixir standard, built-in JSON, and telemetry out-of-the-box. | `req` selected over Tesla/Finch. |
| **Response Payloads** | Typed Structs (e.g., `%Paddle.Customer{}`) with a `raw_data` field improve DX while preserving forward-compatibility. | Structs selected over raw Maps. |
| **Client Instantiation** | Explicit `client` passing supports multi-tenant apps and avoids global application config conflicts. | Explicit structs selected. |

## Integration Consumers

### Accrue (`~/projects/accrue`)
Higher-level multi-processor billing library that consumes oarlock for Paddle (and `lattice_stripe` for Stripe). Treats the following oarlock surface as a stable seam:

- **Locked struct surfaces:** `%Paddle.Transaction{}`, `%Paddle.Transaction.Checkout{}`, `%Paddle.Subscription{}`, `%Paddle.Subscription.ScheduledChange{}`, `%Paddle.Subscription.ManagementUrls{}`, `%Paddle.Event{}`. Field additions are safe (the `:raw_data` field on each preserves forward compatibility); field removals or renames are breaking and require a major bump.
- **Webhook seam:** `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1` remain pure functions. No Phoenix/Plug coupling will land in core; framework helpers, if ever needed, ship as optional adjacent packages.
- **Deferred surface (not on near-term roadmap):** subscription mutations (`update`, `pause`, `resume`), payment-method update flows. These remain out of v0.1 scope and are not currently planned for v1.x — Accrue's first slice does not depend on them.

Outstanding Accrue requests are tracked in `.planning/BACKLOG.md` (entries `B-01` through `B-03`).

## Evolution
This document evolves at phase transitions and milestone boundaries.
---
*Last updated: 2026-04-29 — milestone v1.1 (Accrue Seam Hardening) opened; v1.0 requirements moved to Validated.*