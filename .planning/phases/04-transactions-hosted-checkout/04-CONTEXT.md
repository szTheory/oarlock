# Phase 4: Transactions & Hosted Checkout - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the transaction bridge for Accrue's hosted-checkout flow on top of the existing Paddle client, customer, and address foundations. This phase is specifically about creating an automatically collected recurring transaction for an existing customer and address, then returning the hosted checkout URL needed to collect payment. It does not expand into invoices, manual collection, discounts, non-catalog pricing, or full transaction lifecycle management.

</domain>

<decisions>
## Implementation Decisions

### Public API Shape
- **D-01:** Keep the established resource-module pattern and expose Phase 4 through `Paddle.Transactions.create/2`.
- **D-02:** Do not introduce a checkout-specific wrapper type or tuple shape for the happy path. Success should return `{:ok, %Paddle.Transaction{}}`.
- **D-03:** The primary documented access path for the hosted checkout URL is `transaction.checkout.url`, so the `checkout` field must be represented in a shape that supports Elixir dot access.

### Transaction Input Contract
- **D-04:** Use a curated attrs map, not a near-pass-through Paddle payload.
- **D-05:** Require `customer_id`, `address_id`, and a non-empty `items` list for the public Phase 4 create path.
- **D-06:** `items` should be constrained to the recurring catalog-item shape for this phase: `%{price_id: ..., quantity: ...}`.
- **D-07:** Support only a very small optional allowlist beyond the required fields: `custom_data` and `checkout.url`.
- **D-08:** Omit broader transaction fields from the public contract for now, especially invoice/manual-collection fields, discounts, billing period controls, non-catalog pricing, and other raw-Paddle transaction branches.

### Billing Lifecycle Strictness
- **D-09:** Phase 4's main public path is strict and ready-oriented: it represents an existing customer plus existing address flowing into an automatically collected recurring transaction.
- **D-10:** Do not make `create/2` polymorphic between draft and ready flows. Missing `customer_id` or `address_id` should not silently produce a different lifecycle.
- **D-11:** If draft checkout support is added later, it should be a separately named path rather than a boolean flag or hidden mode on `create/2`.

### Response Modeling And DX
- **D-12:** Introduce `%Paddle.Transaction{}` as the primary entity for Phase 4, preserving `raw_data` like earlier resource structs.
- **D-13:** Model `checkout` in a way that makes `transaction.checkout.url` work naturally and predictably; a tiny nested struct is preferred over a string-key map.
- **D-14:** Keep the entity-centric return shape as the canonical contract. Any future helper like `Paddle.Transaction.checkout_url/1` would be additive sugar, not the primary API.

### Validation And Boundary Discipline
- **D-15:** Preserve the existing boundary style from earlier phases: accept `map | keyword`, normalize keys into the SDK's snake_case vocabulary, and keep local validation lightweight.
- **D-16:** Local validation should stop at stable boundary checks: required IDs present and nonblank, attrs container valid, `items` present and non-empty, and item entries shaped like `%{price_id, quantity}`.
- **D-17:** Leave deeper billing/business rules to Paddle, including recurring interval compatibility, approved checkout domain rules, and checkout-link environment configuration.

### Decision-Making Preference
- **D-18:** Favor decisive, researched defaults for SDK ergonomics and architecture. Only surface future user choices when the tradeoff is meaningfully impactful to product direction or public API stability.
- **D-19:** Within this phase, default toward least surprise, coherent Elixir resource-module patterns, and a single obvious happy path rather than exposing all upstream API branches.

### the agent's Discretion
- Exact first-pass field list for `%Paddle.Transaction{}` beyond the must-have fields for this phase.
- Whether `checkout` is a tiny `%Paddle.Transaction.Checkout{}` struct or another atom-keyed shape that still guarantees `transaction.checkout.url`.
- Whether unknown attrs are ignored or rejected explicitly, so long as the public contract stays curated and predictable.
- Whether a private normalization seam is added now to make a later `create_draft_checkout/2` expansion straightforward.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope And Phase Contracts
- `.planning/PROJECT.md` — Product goals, SDK constraints, and high-level architectural direction.
- `.planning/REQUIREMENTS.md` — Phase requirements `TXN-01` and `TXN-02`, plus cross-phase typed-struct and tuple-return constraints.
- `.planning/ROADMAP.md` — Phase 4 goal, success criteria, and relation to completed entity work plus later subscription work.
- `.planning/STATE.md` — Current project progress and the latest phase notes.

### Prior Locked Decisions
- `.planning/phases/01-core-transport-client-setup/01-CONTEXT.md` — Explicit client passing, normalized error tuples, telemetry, and page-shape conventions that Phase 4 must preserve.
- `.planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md` — Resource-module public API shape, allowlisted attrs, raw-data preservation, and decisive-defaults preference that Phase 4 should carry forward.

### Supporting Prior Analysis
- `.planning/phases/03-core-entities-customers-addresses/03-RESEARCH.md` — Prior reasoning about thin resource modules over the transport boundary and allowlist discipline.
- `.planning/phases/03-core-entities-customers-addresses/03-PATTERNS.md` — Existing request/response and struct-mapping patterns to mirror when adding transaction resources.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/paddle/http.ex` — `request/4` remains the success/error transport boundary and `build_struct/2` remains the core typed-entity mapper with `raw_data` preservation.
- `lib/paddle/client.ex` — `%Paddle.Client{}` with preconfigured `Req` request remains the entry point for all public operations.
- `lib/paddle/error.ex` — `%Paddle.Error{}` should remain the public non-2xx API failure shape.
- `lib/paddle/page.ex` — Existing helper style (`Page.next_cursor/1`) is the right precedent if any small transaction helper is ever added.
- `lib/paddle/customers.ex` and `lib/paddle/customers/addresses.ex` — Current resource modules define the public API pattern Phase 4 should follow: explicit client, curated allowlists, light validation, typed entity returns.

### Established Patterns
- Public functions take `%Paddle.Client{}` explicitly rather than relying on global config.
- Success paths return `{:ok, struct}` or `{:ok, %Paddle.Page{}}`; API failures return `{:error, %Paddle.Error{}}`; transport exceptions surface unchanged.
- Entity structs promote common top-level Paddle fields, keep nested/dynamic payloads lightweight, and preserve full payloads in `raw_data`.
- Request attrs are normalized from `map | keyword`, filtered through explicit allowlists, and kept in snake_case at the SDK boundary.

### Integration Points
- `Paddle.Transactions.create/2` should use `Paddle.Http.request/4` and perform the `"data"` envelope handling locally, matching existing resource modules.
- `%Paddle.Transaction{}` should integrate with `Paddle.Http.build_struct/2` and any narrow nested-shape helper needed for `checkout`.
- Phase 4 should sit directly on top of the customer/address resources established in Phase 3, not create alternate identity/address flows.

</code_context>

<specifics>
## Specific Ideas

- The SDK should learn from strong client libraries like `stripity_stripe`: resource modules, attrs maps, typed entities, and clear public boundaries.
- The value of this SDK is not OpenAPI mirroring; it is opinionated, ergonomic curation over a broad billing API surface.
- Hosted checkout is a transaction-centered workflow in Paddle, so the transaction should remain the primary object rather than being hidden behind a convenience wrapper.
- Draft checkout support is a legitimate future capability, but it should be an explicitly named later expansion rather than a hidden branch in Phase 4's main path.
- Caller-supplied `checkout.url` is the only near-term extra worth supporting now because it fits the hosted-checkout lane without dragging in wider transaction complexity.

</specifics>

<deferred>
## Deferred Ideas

- Draft transaction support where checkout collects missing customer or address data.
- Manual/invoice collection flows and related billing details.
- Broader transaction payload coverage such as discounts, billing periods, businesses, and non-catalog pricing.
- Checkout-specific wrapper responses or other alternate success shapes.
- A public helper like `Paddle.Transaction.checkout_url/1` unless real usage proves the additive sugar is worth the extra API surface.

</deferred>

---

*Phase: 04-transactions-hosted-checkout*
*Context gathered: 2026-04-28*
