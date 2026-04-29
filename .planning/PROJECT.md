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

## Requirements

### Validated
- [x] Implement `Paddle.Subscriptions` (get, list, cancel). *(Validated in Phase 5: Subscriptions Management — `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2` with hydrated `%ScheduledChange{}` and `%ManagementUrls{}` nested structs; 23 adapter-backed tests.)*

### Active
- [ ] Create explicit client passing with `Paddle.Client.new!/1` (Bearer auth, Paddle-Version).
- [ ] Return typed responses and errors (`{:ok, struct}` / `{:error, %Paddle.Error{}}`).
- [ ] Implement `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1` with strict raw-body matching.
- [ ] Implement `Paddle.Customers` (create, get, update).
- [ ] Implement `Paddle.Addresses` (create, list, update).
- [ ] Implement `Paddle.Transactions` (create recurring -> returns hosted checkout URL).
- [ ] Utilize `req` for underlying HTTP transport.
- [ ] Retain original response body mapping (e.g. `raw_data`) inside domain structs.
- [ ] Setup testing matrix across Elixir/Erlang versions, Credo, Dialyzer, ExDoc.

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

## Evolution
This document evolves at phase transitions and milestone boundaries.
---
*Last updated: 2026-04-29 after Phase 5 (Subscriptions Management) completion — milestone v1.0 fully executed.*