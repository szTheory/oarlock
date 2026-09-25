# Project: Paddle Elixir SDK

## What This Is
A production-quality, idiomatic Elixir SDK for Paddle Billing (`paddle_sdk`) to serve as a pure, standalone foundation for Accrue's "second processor" strategy. The library relies on `req` for modern HTTP interactions and uses explicit client contexts without enforcing global app configs.

## Core Value
Provides seamless, native Elixir interaction with the current Paddle Billing API v1 through explicit %Paddle.Client{} passing, typed struct responses, and robust webhook verification that avoids reliance on Phoenix or Ecto coupling.

## Key Constraints & Context
- Must be a pure functional library, avoiding UI, database syncing, or framework-specific plugins (like `Plug.Parsers` implementations for Phoenix, which will be documented instead).
- Must avoid legacy "Paddle Classic" concepts.
- Must retain forward compatibility via `__raw__` mapping of API responses.
- Explicit deferment of broad endpoint mirroring, invoice generation, marketplaces/connect, and app-level billing workflows to demand-driven future work.

## Current State

**Shipped:** v2.1 Adopter Truth & Release Readiness on 2026-06-25 — see `.planning/milestones/v2.1-ROADMAP.md`.

oarlock now exposes a typed, documented, and resilient consumer surface including core entities, events, notification settings, support adjustments, portal sessions, and an Offline Mode mock server:
- `Paddle.MockServer` powered by Bandit for local offline development and tests.
- Complex upgrade and downgrade subscription scenarios verified through MockServer-backed integration tests, with sandbox/provider-state checks remaining optional and demand-driven.
- Phase 27 aligned README, Getting Started, Accrue seam contract, demo runbook,
  changelog, and generated docs with the shipped SDK surface and proof
  boundary.
- Phase 29 reconciled GSD planning state: active work lives in
  `.planning/BACKLOG.md`, shipped or historical backlog entries live in
  `.planning/BACKLOG-ARCHIVE.md`, proof classification lives in
  `.planning/EVIDENCE.md`, resolved investigations are indexed in
  `.planning/threads/INDEX.md`, and durable GSD planning preferences live in
  `.planning/GSD-PREFERENCES.md`.
- Phase 30 closed the DOCS-02/PROOF-02 handoff gap with deterministic
  MockServer-backed LiveView and PhoenixTest proof for checkout and customer
  portal handoffs.

## Current Milestone: v2.2 Trust, Coverage & Green Delivery

**Goal:** Establish a trustworthy, secure, clean, and fast development
foundation while creating a durable, provenance-backed map of the library's
relevant personas, jobs, coverage, and future trajectory.

**Target features:**
- Repository and planning truth: classify existing dirty state, reconcile
  archives and milestone history, and prevent stale artifacts from presenting
  shipped work as active work.
- Green delivery: exact-SHA main-branch proof, fast deterministic CI, release
  gating, clean worktrees, reviewable PRs, ownership, and triage conventions.
- Trustworthy SDK core: close known telemetry, secret-redaction,
  retry/idempotency, client-validation, compatibility, and documentation-truth
  gaps before expanding endpoint breadth.
- Durable orientation: map personas and JTBD to capabilities, gaps,
  requirements, evidence, provenance, ownership, and explicit non-goals; keep
  short-, mid-, and long-term horizons discoverable as committed, candidate,
  or conditional work.

<details>
<summary>v1.5 Demo App & DX Hardening (Shipped 2026-06-11)</summary>

oarlock introduced a realistic Demo App with a polished Admin UI, e2e tests, and robust Docker DX serving as adoption evidence.
</details>

<details>
<summary>v1.4 Catalog & Events (Shipped 2026-06-10)</summary>

oarlock exposed a fully typed, documented, and resilient consumer surface including core entities, events, and notification settings:
- Catalog read surface (`Paddle.Products` and `Paddle.Prices` list/get) with auto-pagination.
- Event history retrieval (`Paddle.Events` list/get) fully integrated with the existing webhook structs.
- Notification Settings (`Paddle.NotificationSettings` management) with full CRUD support.
- Reliability primitives: idempotency keys, automatic retries, and transport error normalization.
- Subscriptions surface: `pause`, `resume`, and validated recurring-start flows.
- Process guard preventing SUMMARY drift.
</details>

<details>
<summary>v1.2 Production Surface (Shipped 2026-06-09)</summary>

oarlock exposed a fully typed, documented, and resilient consumer surface:
- Reliability primitives: idempotency keys, automatic retries, and transport error normalization.
- Pagination ergonomics: per-resource `stream/*` + `all/*` helpers.
- Subscriptions surface: `pause`, `resume`, and validated recurring-start flows.
- Full type safety and complete `@moduledoc` / `@doc` coverage with guides.
- Process guard preventing SUMMARY drift.

</details>

<details>
<summary>v1.1 Accrue Seam Hardening (Shipped 2026-04-29)</summary>

oarlock exposed a closed, documented consumer surface for Accrue:
- `Paddle.Transactions.get/2` retrieval (TXN-03)
- Adapter-backed end-to-end Accrue seam contract test (`test/paddle/seam_test.exs`, SEAM-01)
- Canonical seam guide `guides/accrue-seam.md` with locked/additive/opaque vocabulary, sealed internal modules via `@moduledoc false` (SEAM-02)
- 111 tests, 0 failures at v1.1 tag

</details>

## Next Milestone Goals

- **Short term (committed in v2.2):** restore repository, planning, SDK safety,
  CI/CD, PR, release, and worktree trust; establish the canonical JTBD and
  provenance model.
- **Mid term (candidate):** operational customer/transaction discovery,
  quote-before-mutate workflows, and bounded causal MockServer/provider proof,
  prioritized by adopter evidence.
- **Long term (conditional):** real packaged Accrue adoption, demand-backed
  B2B/manual-collection capabilities, and public-contract graduation with
  explicit compatibility and release guarantees.
- Future milestone discovery may revise these horizons, but must preserve the
  source evidence, rationale, status changes, and reopen/promotion conditions.

## Requirements

### Validated
- [x] **REPO-01..04**: Repository inventory, active-scope authority,
  milestone-history integrity, and non-mutating planning-health checks are
  fail-closed and continuously proven. *(Validated in Phase 31)*
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
- [x] **ADV-01**: Offline Mode mock server for local SDK and demo integration tests. *(Validated in Phase 25)*
- [x] **ADV-02**: Complex upgrade/downgrade flows verified through MockServer-backed integration tests. *(Validated in Phase 26)*
- [x] **DOCS-01..04**: Public README, Getting Started, seam contract, demo
  runbook, changelog, and generated docs describe the shipped SDK surface,
  app-owned responsibilities, and MockServer/sandbox/live proof boundary.
  *(Validated in Phase 27)*
- [x] **PROOF-01..04**: CI runs root library gates, demo PostgreSQL checks,
  downstream Hex package smoke proof, and positive/negative optional
  dependency proof for `Paddle.MockServer`. *(Validated in Phase 28)*
- [x] **GSD-01..04**: Root planning state, backlog/archive split, evidence
  ledger, resolved investigation index, and durable GSD preferences agree on
  shipped/open scope. *(Validated in Phase 29)*
- [x] **DOCS-02 / PROOF-02 closure**: Demo checkout and customer portal
  handoffs are directly verified through deterministic MockServer-backed
  LiveView/PhoenixTest coverage. *(Validated in Phase 30)*

### Active

- [ ] Remote `main` is green and synchronized through reviewable changes with exact-SHA evidence.
- [ ] CI, release, PR, triage, and worktree workflows enforce fast, clean, reproducible delivery.
- [ ] Known SDK safety and contract-truth gaps are fixed before adding broad endpoint surface.
- [ ] Relevant personas and JTBD have a canonical coverage and provenance map.
- [ ] Short-, mid-, and long-term development horizons remain discoverable without presenting candidates as commitments.

### Out of Scope
- **Paddle Classic Support**: Must only support Paddle Billing API v1.
- **Phoenix/Ecto coupling**: No framework or database integration code in the core library.
- **App-owned billing workflows**: Entitlements, provisioning, support policies, and database synchronization remain consumer concerns.
- **Direct Subscription Creation**: Paddle-native recurring starts remain transaction/checkout or invoice-backed, not `Paddle.Subscriptions.create/2`.
- **Payment Method APIs**: Deferred beyond customer portal sessions and surfaced management URLs.
- **Invoice Generation**: Deferred for v0.x.
- **Connect / Marketplaces**: Deferred for v0.x.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **HTTP Client** | `req` provides modern Elixir standard, built-in JSON, and telemetry out-of-the-box. | `req` selected over Tesla/Finch. |
| **Response Payloads** | Typed Structs (e.g., `%Paddle.Customer{}`) with a `raw_data` field improve DX while preserving forward-compatibility. | Structs selected over raw Maps. |
| **Client Instantiation** | Explicit `client` passing supports multi-tenant apps and avoids global application config conflicts. | Explicit structs selected. |
| **Mock Server** | Offline Mode using Bandit provides fast local integration proof without sandbox state leak. | Useful development fixture; not a complete Paddle clone. |
| **Next Work Boundary** | The recurring SaaS lifecycle is mostly covered; broad API expansion now risks endpoint mirroring. | Prioritize adopter truth, CI/package proof, and Accrue consumption before more endpoints. |
| **Repository Truth** | Planning and cleanup decisions need one bounded, non-mutating authority chain. | Phase 31 established fail-closed inventory, planning-health, history-integrity, and six recurring bad/clean prohibition proofs. |
| **Planning Evidence** | Completion claims must be tied to exact canonical artifacts and per-requirement evidence. | Summaries, verification, requirement mappings, milestone identities, and archive links are validated independently; ambiguity blocks. |
| **Planning-Truth CI** | Local green results cannot stand in for hosted exact-SHA proof. | CI now has a required planning-truth lane and the monitor requires its result for the exact commit SHA. |

## Integration Consumers

### Accrue (`~/projects/accrue`)
Higher-level multi-processor billing library that consumes oarlock for Paddle (and `lattice_stripe` for Stripe). Treats the following oarlock surface as a stable seam:

- **Locked struct surfaces:** `%Paddle.Transaction{}`, `%Paddle.Transaction.Checkout{}`, `%Paddle.Subscription{}`, `%Paddle.Subscription.ScheduledChange{}`, `%Paddle.Subscription.ManagementUrls{}`, `%Paddle.Event{}`. Field additions are safe (the `:raw_data` field on each preserves forward compatibility); field removals or renames are breaking and require a major bump.
- **Webhook seam:** `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1` remain pure functions. No Phoenix/Plug coupling will land in core; framework helpers, if ever needed, ship as optional adjacent packages.
- **Deferred surface:** payment-method APIs beyond portal sessions/management URLs remain deferred. Phase 10 locked transaction-driven recurring starts and subscription lifecycle/update operations without adding `Paddle.Subscriptions.create/2`.

Outstanding Accrue requests are tracked in `.planning/BACKLOG.md`; shipped,
superseded, or historical backlog entries are preserved in
`.planning/BACKLOG-ARCHIVE.md`. Proof boundaries for v2.0/v2.1 planning are
classified in `.planning/EVIDENCE.md`, and recurring GSD planning preferences
are documented in `.planning/GSD-PREFERENCES.md`.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-10 after Phase 31*
