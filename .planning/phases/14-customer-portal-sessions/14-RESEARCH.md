# Phase 14: Customer Portal Sessions - Research

**Researched:** 2026-06-09
**Domain:** Elixir SDK / Paddle API Integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Flat namespace mapping to the Paddle URL. Use `Paddle.Customers.PortalSessions` since it maps to `POST /customers/{customer_id}/portal-sessions`, mirroring the existing `Paddle.Customers.Addresses` pattern.
- **D-02:** Strict positional mapping. `create(client, customer_id, attrs)` where `customer_id` is passed as a positional argument and `attrs` maps to the JSON request body.
- **D-03:** Rely on API rejection and use Dialyzer typespecs + guard clauses. Do not build complex local validation (e.g., verifying `subscription_ids` shape), let the SDK remain a thin layer and normalize the Paddle `400 Bad Request` into `{:error, %Paddle.Error{}}`.
- **D-04:** Keep the `urls` property flat. The `Paddle.PortalSession` struct should have a `urls: map()` field that literally maps Paddle's `{"urls": {"general": {"url": "..."}}}` object to avoid struct bloat and maintain forward compatibility. Access via `session.urls["general"]["url"]`.
- **D-05:** Strictly limit the module to `create/3`. Do not expose `get`, `list`, `update`, or `delete` as the Paddle API does not support these operations for portal sessions.

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PORTAL-01 | User can generate a short-lived Customer Portal session URL (`Paddle.Customers.PortalSessions.create/3`). | Paddle API provides `POST /customers/{customer_id}/portal-sessions` which returns temporary `urls`. |
| PORTAL-02 | User can optionally scope a Portal session to specific subscription IDs. | Paddle API accepts `subscription_ids` (array of strings) in the request body for this endpoint. |
</phase_requirements>

## Summary

This phase introduces the ability to generate authenticated customer portal session URLs using the Paddle Billing API. The implementation will mirror the established `Paddle.Customers.Addresses` pattern, exposing a single `Paddle.Customers.PortalSessions.create/3` function. To support this, we will introduce a new `Paddle.PortalSession` struct.

**Primary recommendation:** Implement `Paddle.Customers.PortalSessions` mapping to `POST /customers/:customer_id/portal-sessions` and map the response to a lightweight `Paddle.PortalSession` struct with an unstructured `urls` map.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Generate Portal Session URL | API / Backend | — | Generating the URL requires an authenticated API call using the private Paddle API key. This must be done on the backend to ensure security. The returned URL is then given to the client to redirect the user. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Req | project default | HTTP transport and JSON decoding | Req is the established HTTP client in this codebase; `Paddle.Http.request/4` already handles transport and error normalization. |

**Installation:**
No new dependencies are required. This phase uses the existing project stack.

## Architecture Patterns

### Recommended Project Structure
```text
lib/paddle/
├── portal_session.ex                # New struct for the response
└── customers/
    ├── portal_sessions.ex           # New module for the create/3 function
```

### Pattern 1: Create Resource
**What:** Pass `client`, `id` as positional arguments, and `attrs` for the payload.
**When to use:** For scoped resource creation (e.g., portal sessions for a customer).
**Example:**
```elixir
# Source: Codebase patterns in Paddle.Customers.Addresses
@doc """
Creates a new portal session for a customer.
"""
@spec create(Paddle.Client.t(), customer_id(), map() | keyword(), [request_opt()]) ::
        {:ok, Paddle.PortalSession.t()}
        | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_attrs}
def create(%Paddle.Client{} = client, customer_id, attrs \\ %{}, opts \\ []) do
  with :ok <- validate_customer_id(customer_id),
       {:ok, attrs} <- Attrs.normalize(attrs),
       body <- Attrs.allowlist(attrs, @create_allowlist),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(
           client,
           :post,
           customer_portal_sessions_path(customer_id),
           Keyword.merge([json: body], opts)
         ) do
    {:ok, Http.build_struct(Paddle.PortalSession, data)}
  end
end
```

### Anti-Patterns to Avoid
- **Deep validation of `subscription_ids`:** Do not validate the shape or content of the `subscription_ids` list. Let the Paddle API reject bad requests and rely on the SDK's existing error normalization.
- **Deep struct definitions for `urls`:** Do not create `Paddle.PortalSession.Urls.General`, etc. Keep the `urls` field as a plain `map()` per decision D-04.
- **CRUD Operations:** Do not implement `get`, `list`, `update`, or `delete`. The Paddle API only supports `POST` for portal sessions (D-05).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Error Normalization | Custom error matching | `Paddle.Error` | `Paddle.Http.request` already normalizes 400 Bad Request and API errors. |
| URL Path Encoding | `URI.encode` manually everywhere | Local helper `encode_path_segment/1` | Consistency with `Paddle.Customers.Addresses`. |

**Key insight:** The SDK should remain a thin wrapper over the Paddle API. By not hand-rolling deep validation, we ensure the SDK is forward-compatible if Paddle adds new portal session options in the future.

## Code Examples

### Portal Session Struct
```elixir
defmodule Paddle.PortalSession do
  @moduledoc """
  Represents a Paddle Customer Portal Session.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          customer_id: String.t(),
          urls: map(),
          created_at: DateTime.t() | String.t(),
          custom_data: map() | nil
        }

  @derive {Inspect, except: [:urls]}
  defstruct [:id, :customer_id, :urls, :created_at, :custom_data]
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom billing portals | Hosted Paddle Customer Portal | Paddle Billing v1 | Apps can offload complex subscription management flows (upgrades, card updates) to Paddle securely via temporary session URLs. |

## Assumptions Log

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

## Open Questions

None. The API is straightforward and the scope is strictly constrained by the user decisions.

## Sources

### Primary (HIGH confidence)
- `lib/paddle/customers/addresses.ex` - Checked existing validation and error handling patterns for nested resources.
- [Paddle API Reference: Create a portal session](https://developer.paddle.com/api-reference/customer-portal-sessions/create-portal-session) - Confirmed endpoint structure (`POST /customers/{customer_id}/portal-sessions`), parameters (`subscription_ids`), and return shape (`urls`).

### Secondary (MEDIUM confidence)
- Google Web Search: Verified that `subscription_ids` is the only supported top-level property inside the body besides the customer ID in the path.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using the codebase's existing HTTP layer and struct building.
- Architecture: HIGH - Conforming strictly to D-01 through D-05.
- Pitfalls: HIGH - Avoiding anti-patterns is directly mandated by the user decisions.

**Research date:** 2026-06-09
**Valid until:** 2026-07-09
