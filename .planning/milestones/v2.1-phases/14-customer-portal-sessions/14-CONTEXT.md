# Phase 14: Customer Portal Sessions - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate on-demand, authenticated portal session URLs for customers, optionally scoped to specific subscription IDs.

</domain>

<decisions>
## Implementation Decisions

### Module Namespace
- **D-01:** Flat namespace mapping to the Paddle URL. Use `Paddle.Customers.PortalSessions` since it maps to `POST /customers/{customer_id}/portal-sessions`, mirroring the existing `Paddle.Customers.Addresses` pattern.

### Function Signature
- **D-02:** Strict positional mapping. `create(client, customer_id, attrs)` where `customer_id` is passed as a positional argument and `attrs` maps to the JSON request body.

### Validation Strictness
- **D-03:** Rely on API rejection and use Dialyzer typespecs + guard clauses. Do not build complex local validation (e.g., verifying `subscription_ids` shape), let the SDK remain a thin layer and normalize the Paddle `400 Bad Request` into `{:error, %Paddle.Error{}}`.

### Struct Design
- **D-04:** Keep the `urls` property flat. The `Paddle.PortalSession` struct should have a `urls: map()` field that literally maps Paddle's `{"urls": {"general": {"url": "..."}}}` object to avoid struct bloat and maintain forward compatibility. Access via `session.urls["general"]["url"]`.

### API Surface Scope
- **D-05:** Strictly limit the module to `create/3`. Do not expose `get`, `list`, `update`, or `delete` as the Paddle API does not support these operations for portal sessions.

### Claude's Discretion
None

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context and Requirements
- `.planning/ROADMAP.md` — Phase 14 Goal and Success Criteria
- `.planning/REQUIREMENTS.md` — PORTAL-01, PORTAL-02

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
- **Validation:** Empty string checks via `String.trim(id) == ""` guard validation before requests (as seen in `Paddle.Customers.Addresses`).

### Integration Points
- `Paddle.Customers.PortalSessions`

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-Customer Portal Sessions*
*Context gathered: 2026-06-09*