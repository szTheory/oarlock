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

## Current Milestone: v1.2 Production Surface

**Goal:** Drive oarlock to genuine production-readiness as a hex package while completing the subscription surface Accrue needs for its Phase 97+ Paddle slice.

**Target features:**
- Reliability primitives: idempotency keys on POSTs, 429/`Retry-After` retry policy, normalized network-error shape
- Pagination ergonomics: per-resource `stream/*` + `all/*` helpers built on `Paddle.Page.next_cursor/1`
- Subscriptions surface completion: transaction-driven recurring start guidance/tests plus `pause/3`, `pause_immediately/3`, and `resume/3` (closes the P0 Accrue blocker plus the P1 mutation surface truthfully)
- Type-safety pass: `@spec` on every public function, `:dialyxir` wired with green baseline + CI gate
- Documentation pass: `@doc` everywhere, `@moduledoc` on every public module, README rewrite, new `guides/getting-started.md` and `guides/telemetry.md`
- Process guard: pre-commit hook that prevents the v1.1 SUMMARY/git-state drift class

**Phase numbering:** continues from v1.1 → Phases 8–13. Six phases.

## Previous State

**Shipped:** v1.1 Accrue Seam Hardening on 2026-04-29 — see `.planning/milestones/v1.1-ROADMAP.md`.

oarlock exposed a closed, documented consumer surface for Accrue:
- `Paddle.Transactions.get/2` retrieval (TXN-03)
- Adapter-backed end-to-end Accrue seam contract test (`test/paddle/seam_test.exs`, SEAM-01)
- Canonical seam guide `guides/accrue-seam.md` with locked/additive/opaque vocabulary, sealed internal modules via `@moduledoc false` (SEAM-02)
- 111 tests, 0 failures at v1.1 tag

Accrue-side asks continue to be triaged into `.planning/BACKLOG.md`, not auto-inserted as phases.

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
- [x] **REL-01**: `idempotency_key:` opt on current `create/*` POSTs with `Idempotency-Key` header forwarding and invalid-key rejection. *(Validated in Phase 8)*
- [x] **REL-02**: `Paddle.Client.new!/1` default retry policy using `retry: :transient, max_retries: 3`, with per-call `retry: false` opt-out. *(Validated in Phase 8)*
- [x] **REL-03**: Transport errors normalize to `%Paddle.Error{network_error?: true, retryable?: true, raw_data: %Req.TransportError{}}`. *(Validated in Phase 8)*
- [x] **PAGE-01**: Per-resource auto-pagination helpers for subscriptions and customer addresses, with lazy streams, eager all-or-error collection, normalized next URL replay, and locked `list/*` page shapes preserved. *(Validated in Phase 9)*
- [x] **SUB-04**: Transaction-driven recurring start via `Paddle.Transactions.create/3`, checkout/manual collection, webhook or canonical transaction correlation, and `Paddle.Subscriptions.get/2` hydration; no public `Paddle.Subscriptions.create/2`. *(Validated in Phase 10)*
- [x] **SUB-05**: `Paddle.Subscriptions.pause/3` and `pause_immediately/3` with typed hydration, strict lifecycle opts, explicit `idempotency_key:` rejection, and retry-only request opts. *(Validated in Phase 10)*
- [x] **SUB-06**: `Paddle.Subscriptions.resume/3` with validated `effective_from:` / `on_resume:`, explicit `idempotency_key:` rejection, retry-only request opts, and provider-error passthrough. *(Validated in Phase 10)*
- [x] **TYPES-01**: Add `@spec` annotations to every public function across `lib/paddle/` mechanically enforced by `mix typecheck.specs`. *(Validated in Phase 11)*
- [x] **TYPES-02**: Wire `:dialyxir` with a clean `mix dialyzer` baseline (empty `.dialyzer_ignore.exs`) and CI gate. *(Validated in Phase 11)*

### Active
Remaining v1.2 Production Surface requirements are tracked in `.planning/REQUIREMENTS.md`; next up is Phase 12 Documentation pass.

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
- **Deferred surface:** subscription `update` and payment-method update flows remain deferred. Phase 10 expands the seam additively with transaction-driven recurring start guidance/tests plus `pause`, `pause_immediately`, and `resume`; it does not add `Paddle.Subscriptions.create/2`.

Outstanding Accrue requests are tracked in `.planning/BACKLOG.md` (entries `B-01` through `B-04`).

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
*Last updated: 2026-05-30 — Phase 10 (Subscriptions Surface Completion) validated. v1.0 = Phases 1-5; v1.1 = Phases 6-7; v1.2 = Phases 8-13.*
