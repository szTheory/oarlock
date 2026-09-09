# Phase 17: Catalog API - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Read-only REST endpoints for Products, Prices, and Events (`Paddle.Products`, `Paddle.Prices`, `Paddle.Events`), with robust auto-pagination and fully typed structs. New modules must align perfectly with the pure functional, no-framework-coupling design of the SDK.

</domain>

<decisions>
## Implementation Decisions

### API Design & Query Parameters (Include Param)
- **D-01:** **Drop `include` from allowlists.** Do not support eager hydration of nested trees (e.g. `include=prices` on Products) within the SDK structs. This adheres to the strict functional isolation and avoids building an Ecto-like ORM preload abstraction.
- **D-02:** Consumers needing prices for a product must explicitly call `Paddle.Prices.list(client, product_id: prod.id)`. Any unexpected nested payloads returned by Paddle will safely fall into the `:raw_data` map on the struct.

### Custom Item Warnings (CAT-05)
- **D-03:** **Documentation-only warnings.** Provide explicit `@moduledoc` and `@doc` warnings on `Paddle.Products` and `Paddle.Prices` explaining that custom items created during checkout are not queryable via the Catalog endpoints.
- **D-04:** Do NOT implement runtime inspection or `:telemetry` emission for custom items in the HTTP response. Keep the execution path pure, fast, and free of side-effects. 

### ID Validation
- **D-05:** **Use native `String.t()` without regex enforcement.** Do not hardcode regex validation for Paddle ID prefixes (e.g., `pro_`, `pri_`, `evt_`) in the SDK client.
- **D-06:** Pass the ID string directly to the API, allowing Paddle to return a 400/404, which the SDK will correctly normalize into `%Paddle.Error{}`. This maximizes future-proofing.

### Claude's Discretion
- Formatting and layout of the `@moduledoc` warnings.
- Placement of the test files and naming of test descriptors.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope and Architecture
- `.planning/ROADMAP.md` — Phase 17 goal and success criteria.
- `.planning/REQUIREMENTS.md` — Active CAT-* requirements.
- `.planning/research/ARCHITECTURE.md` — Read-only API implementation strategy (Pattern 1) and struct reuse for Events (Pattern 2).
- `.planning/research/STACK.md` — Req, JSON, and telemetry boundaries.

### Prior Phase Context
- `.planning/phases/13-process-guard/13-CONTEXT.md` — (Prior art for integration rules).
- `.planning/phases/16-seam-validation-documentation/16-CONTEXT.md` — Example of `seam_test.exs` integration constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `%Paddle.Client{}`: The explicit client struct for all API calls.
- `Paddle.Internal.Pagination`: The `all/2` and `stream/2` helpers for cursor-based pagination.
- `Paddle.Http`: The core transport module (`request/4`, `build_struct/2`).
- `%Paddle.Event{}`: Existing struct (from webhooks) to be reused by `Paddle.Events`.

### Established Patterns
- **Allowlists:** Module attributes like `@list_allowlist` to drop unsupported keys before making API requests.
- **Typed Responses:** Returning `{:ok, struct}` or `{:error, %Paddle.Error{}}`.
- **Tests:** Using `client_with_adapter` for mock responses in `Req`.

### Integration Points
- `lib/paddle/products.ex`
- `lib/paddle/prices.ex`
- `lib/paddle/events.ex`
- `test/paddle/products_test.exs`
- `test/paddle/prices_test.exs`
- `test/paddle/events_test.exs`

</code_context>

<specifics>
## Specific Ideas

The user explicitly requested "deep, cohesive, one-shot recommendations" for gray areas emphasizing "developer ergonomics, principle of least surprise, and great UX" based on the `.gemini/GEMINI.md` guidance. The decisions above (D-01 through D-06) execute on that mandate.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 17-Catalog API*
*Context gathered: 2026-06-10*