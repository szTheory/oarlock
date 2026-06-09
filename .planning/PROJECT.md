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

**Shipped:** v1.2 Production Surface on 2026-06-09 — see `.planning/milestones/v1.2-ROADMAP.md`.

oarlock now exposes a fully typed, documented, and resilient consumer surface:
- Reliability primitives: idempotency keys, automatic retries, and transport error normalization.
- Pagination ergonomics: per-resource `stream/*` + `all/*` helpers.
- Subscriptions surface: `pause`, `resume`, and validated recurring-start flows.
- Full type safety and complete `@moduledoc` / `@doc` coverage with guides.
- Process guard preventing SUMMARY drift.

<details>
<summary>v1.1 Accrue Seam Hardening (Shipped 2026-04-29)</summary>

oarlock exposed a closed, documented consumer surface for Accrue:
- `Paddle.Transactions.get/2` retrieval (TXN-03)
- Adapter-backed end-to-end Accrue seam contract test (`test/paddle/seam_test.exs`, SEAM-01)
- Canonical seam guide `guides/accrue-seam.md` with locked/additive/opaque vocabulary, sealed internal modules via `@moduledoc false` (SEAM-02)
- 111 tests, 0 failures at v1.1 tag

</details>

## Next Milestone Goals

*Pending definition via `/gsd:new-milestone`.*

Potential targets include:
1. Support operations: refunds/credits via `Paddle.Adjustments`.
2. Customer self-serve billing: smallest provider-native portal/session/payment-management surface.
3. Catalog read surface: products/prices read/list before any broad CRUD.

## Requirements

### Validated
- [x] Explicit client passing with `Paddle.Client.new!/1` (Bearer auth, Paddle-Version). *(Phase 1)*
- [x] HTTP transport via `req` with retries and telemetry. *(Phase 1)*
- [x] Typed `{:ok, struct}` / `{:error, %Paddle.Error{}}` responses with `raw_data` forward compatibility. *(Phase 1, applied throughout)*
- [x] `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1` with strict raw-body matching. *(Phase 2)*
- [x] `Paddle.Customers` (create, get, update). *(Phase 3)*
- [x] `Paddle.Customers.Addresses` (create, list, update). *(Phase 3)*
- [x] `Paddle.Transactions.create/2` returning hosted checkout URL. *(Phase 4)*
- [x] `Paddle.Subscriptions` (get, list, cancel). *(Phase 5)*
- [x] Testing matrix across Elixir/Erlang versions, Credo, Dialyzer, ExDoc. *(Phase 1 baseline)*
- [x] **TXN-03**: `Paddle.Transactions.get/2` — fetch a transaction by ID with hydrated checkout struct. *(Validated in Phase 6)*
- [x] **SEAM-01**: End-to-end Accrue seam contract test. *(Validated in Phase 7)*
- [x] **SEAM-02**: Canonical Accrue seam guide (`guides/accrue-seam.md`). *(Validated in Phase 7)*
- [x] **REL-01**: `idempotency_key:` opt on current `create/*` POSTs. *(Validated in Phase 8)*
- [x] **REL-02**: `Paddle.Client.new!/1` default retry policy. *(Validated in Phase 8)*
- [x] **REL-03**: Transport errors normalize to `%Paddle.Error{}`. *(Validated in Phase 8)*
- [x] **PAGE-01**: Per-resource auto-pagination helpers. *(Validated in Phase 9)*
- [x] **SUB-04**: Transaction-driven recurring start via `Paddle.Transactions.create/3`. *(Validated in Phase 10)*
- [x] **SUB-05**: `Paddle.Subscriptions.pause/3` and `pause_immediately/3`. *(Validated in Phase 10)*
- [x] **SUB-06**: `Paddle.Subscriptions.resume/3`. *(Validated in Phase 10)*
- [x] **TYPES-01**: Add `@spec` annotations mechanically enforced. *(Validated in Phase 11)*
- [x] **TYPES-02**: Wire `:dialyxir` with CI gate. *(Validated in Phase 11)*
- [x] **DOCS**: Documentation pass with guides. *(Validated in Phase 12)*
- [x] **PROC-01 / PROC-02**: Pre-commit hook and CI step to prevent SUMMARY drift. *(Validated in Phase 13)*
- [x] **PORTAL-01**: Customer Portal Sessions (`Paddle.Customers.PortalSessions.create/3`). *(Validated in Phase 14)*
- [x] **ADJ-01**: Adjustments (`Paddle.Adjustments` for refunds and credits). *(Validated in Phase 15)*

### Active

### Out of Scope
- **Paddle Classic Support**: Must only support Paddle Billing API v1.
- **Phoenix/Ecto coupling**: No framework or database integration code in the core library.
- **Payment Method Portals**: Deferred for v0.x.
- **Invoice Generation**: Deferred for v0.x.
- **Refunds**: Deferred for v0.x.
- **Connect / Marketplaces**: Deferred for v0.x.

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
- **Deferred surface:** subscription `update` and payment-method update flows remain deferred. Phase 10 expands the seam additively with transaction-driven recurring start guidance/tests plus `pause`, `pause_immediately`, and `resume`; it does not add `Paddle.Subscriptions.create/2`.

Outstanding Accrue requests are tracked in `.planning/BACKLOG.md`.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-09 — v1.3 milestone shipped.*
 reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-09 — v1.3 milestone started.*
