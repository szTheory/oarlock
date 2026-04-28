# Phase 3: Core Entities (Customers & Addresses) - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the foundational customer and billing-address resources on top of the existing transport layer so developers can create, get, and update customers plus create, list, get, and update customer-scoped addresses. This phase defines the public entity-module patterns that later billing resources should follow.

</domain>

<decisions>
## Implementation Decisions

### Public API Shape
- **D-01:** Use resource modules rather than a flat `Paddle` facade.
- **D-02:** Expose customers as `Paddle.Customers.create/2`, `get/2`, and `update/3`.
- **D-03:** Expose addresses as a nested customer-owned resource: `Paddle.Customers.Addresses.create/3`, `list/3`, `get/3`, and `update/4`.
- **D-04:** Do not expose duplicate public API shapes for the same address operations. If a lower-level endpoint helper is useful, keep it private/internal.

### Entity Struct Strategy
- **D-05:** Model `%Paddle.Customer{}` and `%Paddle.Address{}` as first-class structs with the most common top-level Paddle fields promoted to atom keys.
- **D-06:** Preserve the full API payload in `raw_data` on both structs for forward compatibility and escape-hatch access.
- **D-07:** Keep field names snake_case and aligned with Paddle JSON keys where possible (`:marketing_consent`, `:country_code`, `:created_at`, `:updated_at`) to minimize surprise and mapping complexity.
- **D-08:** Keep nested/dynamic fields lightweight: `custom_data` stays a plain map; only selectively model nested objects when the shape is stable and high-value.
- **D-09:** Do not inline address collections onto `%Paddle.Customer{}`. Addresses remain separate endpoint-backed resources.

### Address Ownership & Listing Semantics
- **D-10:** Keep address operations explicitly customer-scoped in the function signature, not hidden inside payload maps.
- **D-11:** Address listing returns `{:ok, %Paddle.Page{data: [%Paddle.Address{}, ...], meta: ...}}` and is always interpreted as "addresses for this customer."
- **D-12:** Preserve Paddle's ownership semantics directly: addresses are customer subentities, not standalone global resources in the public API.

### Request Ergonomics
- **D-13:** Accept `map | keyword` attrs for create/update operations rather than request-builder structs.
- **D-14:** Normalize inputs only enough to produce JSON-ready request bodies and keep nested attrs in the SDK's snake_case vocabulary.
- **D-15:** Perform only lightweight, stable local checks at the boundary: container shape, required path arguments, and obvious invalid combinations. Leave business validation to Paddle and return remote failures as `{:error, %Paddle.Error{}}`.
- **D-16:** Preserve PATCH semantics: omitted fields mean "leave unchanged"; explicit `nil` clears nullable fields where Paddle supports it.

### Developer Experience Direction
- **D-17:** Bias toward least surprise and coherence with existing Elixir client-library norms (`Req`, `stripity_stripe`): explicit client passing, predictable resource modules, and simple attrs maps.
- **D-18:** Bias future decisions toward researched, opinionated defaults. Only surface user decisions when the tradeoff is meaningfully impactful to product or architecture.

### the agent's Discretion
- Exact first-pass field lists for `%Paddle.Customer{}` and `%Paddle.Address{}`.
- Whether `import_meta` is a small nested struct or left as a plain map in Phase 3.
- Internal helper-module names and request normalization helper boundaries.
- Whether to accept both maps and keyword lists directly everywhere or normalize keyword lists at the public edge into maps immediately.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Requirements & Scope
- `.planning/PROJECT.md` — Product goals, architectural constraints, and locked SDK direction.
- `.planning/REQUIREMENTS.md` — Phase requirements `CUST-01` and `ADDR-01`, plus cross-phase constraints like typed structs and `raw_data`.
- `.planning/ROADMAP.md` — Phase 3 goal and its relationship to later transaction/subscription phases.
- `.planning/phases/01-core-transport-client-setup/01-CONTEXT.md` — Prior locked decisions for explicit client passing, error tuples, telemetry, and pagination patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/paddle/http.ex` — `request/4` already provides the success/error transport boundary and `build_struct/2` already supports known-field mapping plus `raw_data`.
- `lib/paddle/client.ex` — `%Paddle.Client{}` and preconfigured `Req` request struct remain the entry point for all public operations.
- `lib/paddle/page.ex` — Existing page abstraction should back address list responses.
- `lib/paddle/error.ex` — Existing normalized error shape should remain the only public error path for remote API failures.

### Established Patterns
- Public API uses explicit `%Paddle.Client{}` passing rather than global config.
- Successful calls return `{:ok, struct}` and API failures return `{:error, %Paddle.Error{}}`.
- Struct mapping currently keeps payload fields close to Paddle's response shape and preserves `raw_data`.

### Integration Points
- New customers/address modules should call into `Paddle.Http.request/4` for transport.
- Entity structs should plug into `Paddle.Http.build_struct/2` or a thin extension of that pattern.
- Address listing should map list payloads into `%Paddle.Page{}` with `%Paddle.Address{}` entries.

</code_context>

<specifics>
## Specific Ideas

- The SDK should feel like a modern Elixir library, not an ORM or generated endpoint dump.
- Learn from Stripe/Paddle-style SDKs: typed resources are valuable, but over-modeling evolving APIs creates churn.
- Learn from Ecto boundary discipline without coupling to Ecto: allow-list external attrs at the request edge, but do not turn SDK entities into pseudo-schemas.
- Favor decisive, researched defaults and only interrupt the user for genuinely high-impact tradeoffs.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-core-entities-customers-addresses*
*Context gathered: 2026-04-28*
