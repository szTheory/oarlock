# Phase 1: Core Transport & Client Setup - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the foundational HTTP layer using `req`, define the explicit `%Paddle.Client{}` struct, manage base URLs (sandbox/live), and setup the standard `{:ok, struct}` and `{:error, error}` response patterns alongside pagination.

</domain>

<decisions>
## Implementation Decisions

### Client Initialization
- Strictly require explicit passing (`Paddle.Client.new(api_key: "...")`).
- Do absolutely no `Application.get_env` lookups within the SDK.
- Consumers should wrap the client in their own application context.

### Error Struct Shape
- Use a Hybrid Idiomatic Wrapper for `%Paddle.Error{}`.
- Map exactly to Paddle's v1 terminology (`type`, `code`, `detail`, `errors`).
- Extract `request_id` and `status_code` to top-level fields.
- Implement Elixir's `Exception` behavior (aliasing `detail` to `message`).
- Keep the raw payload in a `:raw` field.

### Pagination Interface
- Use a Manual `next()` Cursor approach for Phase 1.
- Return `{:ok, %Paddle.Page{data: [...], meta: ...}}`.
- Provide a helper like `Paddle.Page.next_cursor/1`.
- Wait on Stream implementation until Phase 2 as a pure DX convenience wrapper.

### Telemetry & Logging
- Emit custom domain-specific telemetry events (`[:paddle, :request, :start | :stop | :exception]`).
- Do this using a custom `Req.Step`.
- Do not rely solely on `req`'s built-in telemetry to isolate Paddle metrics from global HTTP traffic.

### Claude's Discretion
- Exact naming of internal helper modules (e.g., `Paddle.Request` vs `Paddle.Http`).
- Telemetry payload struct details.

</decisions>

<specifics>
## Specific Ideas

- The library should feel like `req` and modern Elixir: stateless, predictable, and heavily relying on `telemetry`.
- Test suite should be able to run with `async: true` exclusively, without global configs getting in the way.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Goals & Architecture
- `.planning/PROJECT.md` — Core constraints, value proposition, and key architectural decisions.
- `.planning/REQUIREMENTS.md` — The specific requirements to implement for CORE-01, CORE-02, CORE-03, CORE-04, and CORE-05.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None (Phase 1 is the foundational layer).

### Established Patterns
- Modern Elixir explicit configuration and Telemetry usage (from research).

### Integration Points
- The `req` library is the underlying transport mechanism.

</code_context>

<deferred>
## Deferred Ideas

- Phoenix/Plug integration helpers for webhooks (Phase 2).
- Elixir Stream wrapper for pagination (`Paddle.stream!/1`).

</deferred>

---

*Phase: 01-core-transport-client-setup*
*Context gathered: 2026-04-28*