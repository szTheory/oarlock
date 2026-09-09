# Phase 15: Adjustments - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Create, get, and list (paginate) Adjustments (refunds/credits) for transactions via `Paddle.Adjustments`.

</domain>

<decisions>
## Implementation Decisions

### Signature: Positional args vs Attrs
- **D-01:** `create(client, attrs)` (No positional args for action/reason). Positional arguments are strictly reserved for URL path parameters (e.g., `id` in `get/2`). Since Paddle's Create Adjustment endpoint (`POST /adjustments`) takes `action`, `reason`, and `transaction_id` in the JSON body, they belong in the `attrs` map. This prevents arbitrary API body fields from leaking into function signatures, maintaining a clean, predictable `(client, attrs)` contract across the SDK.

### Partial Adjustments Helper vs Raw Attrs
- **D-02:** Raw `attrs` with strict Typespecs (No dedicated helper). The principle of least surprise for a foundational Elixir SDK is "data in, data out." We will not create a dedicated `create_partial` helper or builder pattern. Instead, developers should pass the `items` array directly in the `attrs` map. We provide excellent DX by defining precise Dialyzer typespecs for the `items` shape, allowing editor autocomplete (ElixirLS) to guide the developer without adding runtime bloat or maintenance debt.

### Claude's Discretion
- The exact Dialyzer typespec definitions for the `items` shape to maximize editor autocomplete utility.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context and Requirements
- `.planning/ROADMAP.md` — Phase 15 Goal and Success Criteria
- `.planning/REQUIREMENTS.md` — ADJ-01, ADJ-02, ADJ-03, ADJ-04

### Architecture and Vision
- `prompts/paddle-elixir-lib-deep-research.md` — Vision and architecture for the Paddle SDK
- `prompts/oarlock-master-context.md` — Master project context
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` — Minimal surface definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Paddle.Http.request/4`: Use for network transport.
- `Paddle.Internal.Attrs`: Use `Attrs.normalize/1` and `Attrs.allowlist/2` for payload prep.
- `Paddle.Error`: Use for normalizing API errors.

### Established Patterns
- **Return shapes:** `{:ok, struct} | {:error, %Paddle.Error{}}`.
- **Validation:** Rely on API validation and Dialyzer Typespecs, similar to Phase 14 `Paddle.Customers.PortalSessions` and `Paddle.Customers.Addresses`.
- **Client Instantiation:** Explicit `client` passing (`%Paddle.Client{}`).

### Integration Points
- `Paddle.Adjustments` module.
- Struct `%Paddle.Adjustment{}` containing a `raw_data: map()` field for forward compatibility.

</code_context>

<specifics>
## Specific Ideas

Follow idiomatic Elixir patterns (e.g. `stripity_stripe`): "data in, data out" for payload shape. Prioritize explicit type mapping and avoid runtime logic bloat.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 15-Adjustments*
*Context gathered: 2026-06-09*