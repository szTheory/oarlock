# Phase 18: Events API - Research

**Researched:** 2024-05-30
**Domain:** Elixir API Integration / HTTP Client wrapper
**Confidence:** HIGH

## Summary

This phase adds support for the Paddle Events API. We will create a new `Paddle.Events` module to allow fetching historical events or polling for changes. The module will provide `get/2` for retrieving a single event by ID, and `list/2`, `stream/2`, and `all/2` for paginated retrieval. 

Critically, we will reuse the existing `%Paddle.Event{}` struct that was created during the webhooks phase. Although events fetched from the API differ slightly from webhooks (e.g., they lack a `notification_id`), the existing `Paddle.Http.build_struct/2` utility gracefully ignores missing keys and assigns the entire raw JSON payload to the `raw_data` field. We will also include strong developer documentation recommending that events be used strictly as triggers for canonical fetches rather than as sources of state.

**Primary recommendation:** Implement `Paddle.Events` mirroring the structure of `Paddle.Products`, utilizing `Paddle.Internal.Pagination` for list methods and `Paddle.Http` for requests.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVT-01 | User can list event history with auto-pagination (`Paddle.Events.list/2`, `Paddle.Events.stream/2`, `Paddle.Events.all/2`). | Standard `Paddle.Internal.Pagination` pattern using GET `/events`. The `list` query allowlist must include `after`, `per_page`, `order_by`, and `event_type`. |
| EVT-02 | User can fetch a single event by ID (`Paddle.Events.get/2`). | Implemented using GET `/events/{event_id}` and `Paddle.Http.request/4`. |
| EVT-03 | Events fetched via the API are parsed into the same `%Paddle.Event{}` struct used by webhook verification. | `Paddle.Http.build_struct(Paddle.Event, data)` will populate standard keys and leave webhook-only fields like `notification_id` as `nil`. |
| EVT-04 | User is guided in documentation to use events as triggers for canonical fetches rather than state. | Add a `@moduledoc` warning explaining that `event.data` is a snapshot and outlining the "fetch-before-act" pattern. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event Retrieval API | API / Backend | — | The Elixir client sends authenticated HTTP requests to Paddle API to retrieve data. |
| Pagination & Stream | API / Backend | — | `Paddle.Internal.Pagination` owns lazily fetching subsequent pages of data. |
| Data Deserialization | API / Backend | — | `Paddle.Http.build_struct/2` maps the JSON response into the shared `%Paddle.Event{}` struct. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Req | ~> 0.4 or 0.5 | HTTP Client | Project standard for HTTP communication, handled via `Paddle.Http`. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/paddle/events.ex          # New module for Events API
test/paddle/events_test.exs   # New test file for Events API
```

### Pattern 1: Elixir API Wrapper with Pagination
**What:** Mirroring other endpoints by delegating core iteration to internal utilities.
**When to use:** Whenever an endpoint returns Paddle's standard `data` and `meta.pagination` structure.
**Example:**
```elixir
def stream(%Client{} = client, params \\ []) do
  Paddle.Internal.Pagination.stream(
    fn -> list(client, params) end,
    fn path -> next_page(client, path) end
  )
end
```

### Pattern 2: Struct Reuse via `build_struct`
**What:** Reusing `%Paddle.Event{}` for both webhook payloads and API fetch payloads.
**When to use:** Since the data shape matches, `Paddle.Http.build_struct/2` strips out unknown keys, assigns matched keys, and injects the raw payload into `:raw_data`.

### Anti-Patterns to Avoid
- **Treating `event.data` as Canonical Truth:** Never use the `data` map inside an event to drive application state. The API specifically recommends performing canonical fetches (e.g., `Paddle.Transactions.get(client, txn_id)`) when an event occurs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pagination iteration | Custom recursive loops | `Paddle.Internal.Pagination.stream/2` | Already handles page traversal, cursors, and returning an `Enumerable.t()`. |
| Query param filtering | Custom map/list iteration | `Paddle.Internal.Attrs.allowlist/2` | Standardizes how we filter valid keys before sending to Paddle. |
| JSON to Struct | Direct `struct()` or `Kernel.struct/2` | `Paddle.Http.build_struct/2` | Guarantees `:raw_data` is injected and avoids `KeyError` exceptions for unknown keys. |

## Common Pitfalls

### Pitfall 1: Expecting `notification_id` in API Events
**What goes wrong:** Logic assumes `event.notification_id` is always a string.
**Why it happens:** Webhooks include this field for deduplication. The Events API does not.
**How to avoid:** Do not rely on `notification_id` for deduplication when fetching via the API; use `event_id` instead.

### Pitfall 2: Allowing undocumented query params
**What goes wrong:** Passing `id` or `status` directly to `/events`.
**Why it happens:** Developers assume endpoints behave identically. `status` is valid on `/products` but not `/events`.
**How to avoid:** Define an explicit allowlist in `Paddle.Events`: `@list_allowlist ~w(after per_page order_by event_type)`.

## Code Examples

### API Module Scaffold
```elixir
defmodule Paddle.Events do
  @moduledoc """
  Provides operations for retrieving historical events from the Paddle API.

  ## Best Practices
  Events should be used as triggers to perform canonical fetches of the underlying resource,
  rather than relying on the event payload for the source of truth. The payload inside an event
  represents a snapshot in time and may not reflect the current state of the resource.

  For example, when receiving a `transaction.completed` event, you should use
  `Paddle.Transactions.get(client, event.data["id"])` to fetch the latest state of the transaction.
  """

  alias Paddle.Client
  alias Paddle.Event
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination

  @list_allowlist ~w(after per_page order_by event_type)

  # ... get, list, stream, all definitions ...
end
```

## Assumptions Log

If this table is empty: All claims in this research were verified or cited — no user confirmation needed.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| (Empty) | | | |

## Open Questions (RESOLVED)

None. The integration cleanly maps to existing infrastructure and utilities in the `Paddle` library.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/paddle/events_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVT-01 | List, stream, and all pagination | unit | `mix test test/paddle/events_test.exs` | ❌ New |
| EVT-02 | Fetch a single event by ID | unit | `mix test test/paddle/events_test.exs` | ❌ New |
| EVT-03 | Parsed as `%Paddle.Event{}` | unit | `mix test test/paddle/events_test.exs` | ❌ New |
| EVT-04 | Documentation guidance | manual | Check `mix docs` or source code directly | N/A |

### Sampling Rate
- **Per task commit:** `mix test test/paddle/events_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/paddle/events_test.exs` — Covers REQ-EVT-01, EVT-02, EVT-03. Needs to be created using bypass/mocked HTTP responses matching Paddle's JSON structure.

## Sources

### Primary (HIGH confidence)
- `lib/paddle/products.ex` - Verified standard pagination and list allowlist usage.
- `lib/paddle/event.ex` - Verified struct and keys available (`:notification_id` and `:raw_data`).
- Official docs URL - [List events](https://developer.paddle.com/api-reference/events/list-events) - verified `after`, `per_page`, `order_by`, `event_type` params.
- Official docs URL - [Get an event](https://developer.paddle.com/api-reference/events/get-event) - verified single event fetching by `event_id`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core structure is already defined in existing module patterns (`Paddle.Products`, `Paddle.Transactions`).
- Architecture: HIGH - Pagination and HTTP handling use established `Paddle.Internal.Pagination` and `Paddle.Http` layers.
- Pitfalls: HIGH - Differences between webhook and API properties mapped out properly.

**Research date:** 2024-05-30
**Valid until:** 2024-12-30
