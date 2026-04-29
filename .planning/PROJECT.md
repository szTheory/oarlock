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

## Current State

**Shipped:** v1.1 Accrue Seam Hardening on 2026-04-29 — see `.planning/milestones/v1.1-ROADMAP.md`.

oarlock now exposes a closed, documented consumer surface for Accrue:
- `Paddle.Transactions.get/2` retrieval (TXN-03)
- Adapter-backed end-to-end Accrue seam contract test (`test/paddle/seam_test.exs`, SEAM-01)
- Canonical seam guide `guides/accrue-seam.md` with locked/additive/opaque vocabulary, sealed internal modules via `@moduledoc false` (SEAM-02)
- 111 tests, 0 failures at v1.1 tag

**Next milestone:** TBD — start via `/gsd-new-milestone`. Accrue-side asks continue to be triaged into `.planning/BACKLOG.md`, not auto-inserted as phases.

**Phase numbering:** v1.0 covered phases 1-5; v1.1 covered phases 6-7. The next milestone continues at phase 8.

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
- [x] **TXN-03**: `Paddle.Transactions.get/2` — fetch a transaction by ID with hydrated checkout struct. *(Validated in Phase 6)*
- [x] **SEAM-01**: End-to-end Accrue seam contract test (adapter-backed; 7-step Accrue path with `is_map/1` opacity checks for `:raw_data`). *(Validated in Phase 7)*
- [x] **SEAM-02**: Canonical Accrue seam guide (`guides/accrue-seam.md`) with locked vocabulary and sealed docs surface (`@moduledoc false` on `Paddle`, `Paddle.Http`, `Paddle.Http.Telemetry`). *(Validated in Phase 7)*

### Active
_None — v1.1 shipped 2026-04-29. Next milestone's requirements will be defined via `/gsd-new-milestone`._

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
*Last updated: 2026-04-29 after v1.1 milestone (Accrue Seam Hardening) archived. v1.1 = Phases 6-7. Ready for next-milestone planning via `/gsd-new-milestone`.*