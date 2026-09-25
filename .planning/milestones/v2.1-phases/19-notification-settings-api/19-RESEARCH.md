# Phase 19: Notification Settings API - Research

**Researched:** 2026-06-10
**Domain:** Elixir SDK API Wrapper for Paddle Notification Settings
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01/D-02:** Pass-through event names as strings. Do not restrict or validate `subscribed_events` against a hardcoded list of known atoms. This ensures forward-compatibility.
- **D-03/D-04:** No client-side regex validation for URLs. Pass the `destination` URL directly to Paddle; let Paddle return a 400 if malformed.
- **D-05/D-06:** Stick to pure CRUD (`update/3`). Do not introduce specialized `enable/2` or `disable/2` functions for the `active` flag.
- **D-07/D-08:** Require `api_version` as an explicit parameter on creation to ensure consumers consciously set the webhook version.

### the agent's Discretion
- The specific test file layout and descriptor naming.
- How to structure the `@moduledoc` to guide developers towards proper CRUD usage.

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTIF-01 | List notification settings | Standard paginated lists, matching `Paddle.Products.list/2` pattern |
| NOTIF-02 | Fetch a single setting | Standard get, mapping to GET `/notification-settings/{id}` |
| NOTIF-03 | Create a notification setting | Requires `create/2`, mapping to POST `/notification-settings` |
| NOTIF-04 | Update a notification setting | Requires `update/3`, mapping to PATCH `/notification-settings/{id}` |
| NOTIF-05 | Delete a notification setting | Requires `delete/2`, mapping to DELETE `/notification-settings/{id}` |
</phase_requirements>

## Summary

This phase implements a pure CRUD interface for Paddle's Notification Settings API within the `paddle_sdk`. Following established SDK patterns (like `Paddle.Products` and `Paddle.Events`), the module `Paddle.NotificationSettings` will handle requests, passing strict maps to Paddle and parsing responses into `%Paddle.NotificationSetting{}` structs. We avoid client-side validations (URL regexes, hardcoded event enums) to keep the SDK fast, forward-compatible, and aligned with prior architectural decisions. 

**Primary recommendation:** Implement `Paddle.NotificationSettings` mimicking `Paddle.Products` for reads, but extend it with `create/2`, `update/3`, and `delete/2` using `Paddle.Http.request/4`, dropping unsupported keys via `@create_allowlist` and `@update_allowlist`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Notification Settings CRUD API | API / Backend | — | The Elixir SDK provides typed bindings to Paddle's REST API. Operations map 1:1 with HTTP (GET, POST, PATCH, DELETE) without client-side side-effects. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| req | (existing) | HTTP client | SDK standard for all API calls |
| Paddle.Http | (internal) | SDK transport | Standardizes response parsing and `%Paddle.Error{}` mapping |

**No new dependencies are installed for this phase.**

## Package Legitimacy Audit

> No external packages are required for this phase.

## Architecture Patterns

### Recommended Project Structure
```text
lib/paddle/notification_setting.ex     # The struct definition
lib/paddle/notification_settings.ex    # The CRUD logic module
test/paddle/notification_settings_test.exs
```

### Pattern 1: Pure CRUD without side-effect helpers
**What:** Expose `update/3` instead of domain-specific helpers.
**When to use:** Managing simple data records like webhook endpoints.
**Example:**
```elixir
# Instead of Paddle.NotificationSettings.enable(client, id)
Paddle.NotificationSettings.update(client, id, %{active: true})
```

### Pattern 2: Explicit payload allowlists
**What:** Use module attributes to strip unsupported keys before sending POST/PATCH requests.
**When to use:** Creating or updating a Notification Setting.
**Example:**
```elixir
@create_allowlist ~w(description destination type subscribed_events api_version include_sensitive_fields active)
@update_allowlist ~w(description destination active subscribed_events include_sensitive_fields)

def create(%Client{} = client, attrs) do
  payload = Attrs.allowlist(attrs, @create_allowlist)
  # ...
end
```

### Anti-Patterns to Avoid
- **Client-Side Validation:** Do not validate URLs via Regex or validate `subscribed_events` against atoms. Paddle frequently adds new event types and strict validation breaks SDKs.
- **Defaulting `api_version`:** Do not auto-inject `api_version: 1` on creation. Force the consumer to define it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pagination | Custom recursion | `Paddle.Internal.Pagination` | Shared SDK standard; handles `meta` cursors safely. |
| Attr mapping | Manual key iteration | `Paddle.Internal.Attrs` | Prevents string/atom key collisions and drops unknown keys. |
| HTTP errors | Custom `case` parsing | `Paddle.Http.request/4` | Automates mapping 4xx/5xx responses to `%Paddle.Error{}`. |

## Runtime State Inventory

> Greenfield feature. No existing runtime state applies.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

## Common Pitfalls

### Pitfall 1: Leaking `endpoint_secret_key` on Updates
**What goes wrong:** Assuming `endpoint_secret_key` is available on GET or PATCH requests.
**Why it happens:** Paddle only returns the `endpoint_secret_key` once, immediately upon creation (POST). It is masked/null in subsequent queries.
**How to avoid:** Warn developers in the `@moduledoc` that they must capture and store the secret key immediately upon creation.

### Pitfall 2: Silent Key Dropping on Create
**What goes wrong:** Forgetting to require `api_version` when filtering attributes.
**Why it happens:** Standard allowlists filter out missing keys. If `api_version` is omitted, the API might reject the request or default unpredictably.
**How to avoid:** Explicitly check for `api_version` in `create/2` before making the request.

## Code Examples

Verified patterns from official sources:

### Notification Setting Struct Definition
```elixir
defmodule Paddle.NotificationSetting do
  defstruct [
    :id,
    :description,
    :type,
    :destination,
    :active,
    :api_version,
    :include_sensitive_fields,
    :subscribed_events,
    :endpoint_secret_key, # Only present on creation
    :raw_data
  ]
end
```

### Explicit HTTP Delete Pattern
```elixir
def delete(%Client{} = client, id) do
  with :ok <- validate_id(id),
       {:ok, _} <- Http.request(client, :delete, "/notification-settings/\#{encode_path_segment(id)}") do
    :ok
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dashboard config | Programmatic API | Paddle Billing | Complete control over webhook management via SDK. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `endpoint_secret_key` is only returned on create | Pitfalls | If returned elsewhere, our struct behavior remains unchanged, but docs may be overly cautious. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Paddle API | Sandbox testing | ✓ | Billing v2 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/paddle/notification_settings_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-01 | List returns page | unit | `mix test test/paddle/notification_settings_test.exs` | ❌ Wave 0 |
| NOTIF-02 | Get returns struct | unit | `mix test test/paddle/notification_settings_test.exs` | ❌ Wave 0 |
| NOTIF-03 | Create requires api_version | unit | `mix test test/paddle/notification_settings_test.exs` | ❌ Wave 0 |
| NOTIF-04 | Update modifies attrs | unit | `mix test test/paddle/notification_settings_test.exs` | ❌ Wave 0 |
| NOTIF-05 | Delete returns :ok | unit | `mix test test/paddle/notification_settings_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/paddle/notification_settings_test.exs` — Covers all NOTIF-XX CRUD operations
- [ ] `test/paddle/notification_setting_test.exs` — Ensures struct keys map properly

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `Paddle.Client` (Bearer Token) |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Server-side validation (Paddle). SDK avoids regex filtering (D-03). |
| V6 Cryptography | yes | HTTPS enforcement (built into Req default adapters) |

### Known Threat Patterns for Elixir API Clients

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom exhaustion | Denial of Service | Parse JSON keys as strings before structured casting (handled by `Paddle.Internal.Attrs.normalize_keys/1`) |

## Sources

### Primary (HIGH confidence)
- `19-CONTEXT.md` - Phase constraints and locked decisions
- Paddle Notification Settings API Docs - Validation of endpoint shapes

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Follows `Paddle.Products` exactly
- Architecture: HIGH - Matches user decisions in CONTEXT
- Pitfalls: HIGH - SDK best practices for HTTP wrappers

**Research date:** 2026-06-10
**Valid until:** 2026-07-10