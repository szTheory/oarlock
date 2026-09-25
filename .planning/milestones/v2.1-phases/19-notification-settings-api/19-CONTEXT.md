# Phase 19: Notification Settings API - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement full CRUD operations for Notification Settings (`Paddle.NotificationSettings`), allowing developers to manage webhook destinations programmatically. This must follow the existing read-only patterns from Phase 17 and Phase 18, extending them to include `create`, `update`, and `delete` mutations without coupling to external frameworks.

</domain>

<decisions>
## Implementation Decisions

### 1. Subscribed Events Validation
- **D-01:** **Pass-through event names as strings.** Do not restrict or validate `subscribed_events` against a hardcoded list of known atoms. 
- **D-02:** The Paddle API frequently adds new event types. Enforcing a strict list would break forward-compatibility and require constant SDK updates. This perfectly aligns with the prior Phase 17 decision (D-05) to avoid regex/ID validation in favor of API-level validation.

### 2. URL and Format Validation
- **D-03:** **No client-side regex validation for URLs.**
- **D-04:** Pass the `destination` URL directly to Paddle. If it's malformed, Paddle will return a 400, which the SDK correctly normalizes to `%Paddle.Error{}`. This keeps the SDK pure, fast, and avoids subtle regex bugs.

### 3. Specialized Helpers vs Pure CRUD
- **D-05:** **Stick to pure CRUD (`update/3`).** Do not introduce specialized `enable/2` or `disable/2` functions for the `active` flag.
- **D-06:** While `Subscriptions` have `pause/resume` (domain actions), notification settings are simple data records. Requiring `Paddle.NotificationSettings.update(client, id, %{active: false})` minimizes surface area and adheres to the principle of least surprise for a REST wrapper.

### 4. API Versioning
- **D-07:** **Require `api_version` as an explicit parameter on creation.**
- **D-08:** While the client explicitly supports `api_version: 1`, forcing the user to supply it (or passing it from their configuration) ensures they are consciously setting the webhook version.

### Claude's Discretion
- The specific test file layout and descriptor naming.
- How to structure the `@moduledoc` to guide developers towards proper CRUD usage.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope and Architecture
- `.planning/ROADMAP.md` — Phase 19 goal and success criteria.
- `.planning/REQUIREMENTS.md` — Active NOTIF-* requirements.
- `.planning/research/ARCHITECTURE.md` — API implementation strategy and struct rules.
- `.planning/research/STACK.md` — Req, JSON, and telemetry boundaries.

### Prior Phase Context
- `.planning/phases/17-catalog-api/17-CONTEXT.md` — Prior art for avoiding ID validation and explicit client passing.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `%Paddle.Client{}`: The explicit client struct for all API calls.
- `Paddle.Internal.Pagination`: The `all/2` and `stream/2` helpers for cursor-based pagination.
- `Paddle.Http`: The core transport module (`request/4`, `build_struct/2`).

### Established Patterns
- **Allowlists:** Module attributes like `@list_allowlist`, `@create_allowlist`, and `@update_allowlist` to drop unsupported keys before making API requests.
- **Typed Responses:** Returning `{:ok, struct}` or `{:error, %Paddle.Error{}}`.
- **Tests:** Using `client_with_adapter` for mock responses in `Req`.

### Integration Points
- `lib/paddle/notification_settings.ex`
- `test/paddle/notification_settings_test.exs`

</code_context>

<specifics>
## Specific Ideas

The user explicitly requested "deep, cohesive, one-shot recommendations" for gray areas emphasizing "developer ergonomics, principle of least surprise, and great UX" based on the `.gemini/GEMINI.md` guidance. The decisions above (D-01 through D-08) execute on that mandate by maximizing forward compatibility and minimizing surface area bloat.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 19-Notification Settings API*
*Context gathered: 2026-06-10*