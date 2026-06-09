# Architecture Patterns: Customer Portal Sessions and Adjustments

**Domain:** Payment processing SDK (oarlock)  
**Researched:** 2026-06-09  

## Recommended Architecture

The `oarlock` library strictly follows an explicit client-passing pattern and returns strongly typed structs wrapping raw data from the Paddle Billing v1 API.

To integrate Customer Portal Sessions and Adjustments without deviating from this standard or introducing external coupling (Ecto/Phoenix), the new entities must be built as pure data structures and contextual operation modules that parallel existing resources like `Paddle.Customers.Addresses` and `Paddle.Transactions`.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Paddle.PortalSession` | Defines the struct for a Customer Portal Session response, capturing generated `urls` and lifecycle metadata. | Returned by `Paddle.Customers.PortalSessions` |
| `Paddle.Customers.PortalSessions` | HTTP context operations for generating a session link (e.g. `create/3`). Path: `/customers/{customer_id}/portal-sessions` | `Paddle.Http`, `Paddle.Client`, `Paddle.Internal.Attrs` |
| `Paddle.Adjustment` | Defines the struct for an Adjustment (Refund/Credit) response, including `items`, `totals`, and `status`. | Returned by `Paddle.Adjustments` |
| `Paddle.Adjustments` | HTTP context operations for adjusting transactions (e.g. `create/2`, `get/2`, `all/2`). Path: `/adjustments` | `Paddle.Http`, `Paddle.Client`, `Paddle.Internal.Pagination`, `Paddle.Internal.Attrs` |

### Data Flow

1. **Client Instantiation:** Caller initializes `%Paddle.Client{}`.
2. **Operation Execution:**
   - **For Portals:** Caller passes client, `customer_id`, and optional `subscription_ids` to `Paddle.Customers.PortalSessions.create/3`.
   - **For Adjustments:** Caller passes client and payload containing `action`, `transaction_id`, `reason`, and `items` to `Paddle.Adjustments.create/2`.
3. **Payload Sanitization:** `Paddle.Internal.Attrs.allowlist/2` strips out any unknown parameters before sending the JSON body.
4. **Network Request:** `Paddle.Http.request/4` handles the req pipeline (auth, telemetry, retries).
5. **Struct Hydration:** The JSON `"data"` payload is injected into `Paddle.PortalSession` or `Paddle.Adjustment` using `Http.build_struct/2`. The entire raw JSON payload is preserved in the `raw_data` field for forward-compatibility.

## Patterns to Follow

### Pattern 1: Nested Resource Contexts
**What:** The Paddle API often nests resources under a parent ID but returns a flat representation.
**When:** Creating endpoints bound to another entity, like Customer Portal Sessions.
**Example:**
```elixir
defmodule Paddle.Customers.PortalSessions do
  alias Paddle.{Client, Http, Internal.Attrs, PortalSession}
  
  @create_allowlist ~w(subscription_ids)
  
  @spec create(Paddle.Client.t(), String.t(), map() | keyword(), keyword()) ::
          {:ok, Paddle.PortalSession.t()} | {:error, Paddle.Error.t() | :invalid_attrs | :invalid_customer_id}
  def create(%Client{} = client, customer_id, attrs \\ %{}, opts \\ []) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         path = "/customers/\#{encode_path_segment(customer_id)}/portal-sessions",
         {:ok, %{"data" => data}} <- Http.request(client, :post, path, Keyword.merge([json: body], opts)) do
      {:ok, Http.build_struct(PortalSession, data)}
    end
  end
end
```

### Pattern 2: Top-Level Struct Definitions
**What:** Even if an endpoint is nested (e.g. `Paddle.Customers.Addresses`), the resulting struct is defined at the top level (`Paddle.Address`) to avoid deep, confusing aliases.
**When:** Creating new data models.
**Example:** 
- Correct: `Paddle.PortalSession`, `Paddle.Adjustment`
- Incorrect: `Paddle.Customer.PortalSession`, `Paddle.Transaction.Adjustment`

### Pattern 3: Standard CRUD Pagination
**What:** Standardizing `list` operations with the existing auto-pagination helper.
**When:** Implementing the `list` or `all` capability for Adjustments.
**Example:**
```elixir
defmodule Paddle.Adjustments do
  @spec all(Paddle.Client.t(), keyword()) :: Paddle.Page.t(Paddle.Adjustment.t())
  def all(%Client{} = client, params \\ []) do
    Paddle.Internal.Pagination.stream(client, "/adjustments", params, Paddle.Adjustment)
  end
end
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Leaking Provider Nuance
**What:** Exposing HTTP status codes or generic `req` errors directly to the caller.
**Why bad:** Forces the consumer (e.g., Accrue) to know about `Req` or parse JSON.
**Instead:** Rely on existing `Paddle.Http` middleware to normalize all transport/API issues into `%Paddle.Error{}`.

### Anti-Pattern 2: Missing Raw Data Mapping
**What:** Defining a struct without the `:raw_data` fallback map.
**Why bad:** Breaks the SDK's promise of forward compatibility. If Paddle adds a field, the Accrue seam cannot read it until the library updates.
**Instead:** Always include `raw_data: map() | nil` in `defstruct` and let `Http.build_struct/2` populate it.

## Build Order

To preserve testing confidence and ensure dependency ordering, the following sequence is recommended for the integration:

1. **Struct Definition:** Add `lib/paddle/portal_session.ex` and `lib/paddle/adjustment.ex`. Add corresponding basic tests `test/paddle/portal_session_test.exs` to verify struct compliance.
2. **Operations:**
   - Add `lib/paddle/customers/portal_sessions.ex` with `create/3`.
   - Add `lib/paddle/adjustments.ex` with `create/2`, `get/2`, and `all/2`.
3. **Integration Tests:** Add tests using bypass or HTTP mocking (standard to the repo) in `test/paddle/customers/portal_sessions_test.exs` and `test/paddle/adjustments_test.exs`.
4. **Seam Validation:** Expand the Accrue seam contract guide (`guides/accrue-seam.md`) and tests (`seam_test.exs`) to incorporate the newly locked structs.
5. **Documentation:** Expose new modules in `mix.exs` or `check_docs.exs`, ensuring `@moduledoc` and `@doc` coverage aligns with `SUMMARY` validation tools.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Short-lived tokens | Generate session links synchronously on-demand. | Token links expire rapidly. Only generate them immediately before client redirection. | Consider asynchronous link pre-fetching strategies, strictly avoiding DB caching due to token expiration constraints. |
| Auto-pagination | Loading all adjustments via `.all()` stream works directly. | Consider yielding streams vs fully materialized lists. `Paddle.Internal.Pagination.stream/4` supports safe, lazy yielding. | High-frequency adjustment querying requires consumer-side webhooks rather than polling `/adjustments`. |

## Sources

- [Paddle API: Customer Portal Sessions](https://developer.paddle.com/api-reference/customer-portal-sessions/create-portal-session) (HIGH)
- [Paddle API: Adjustments](https://developer.paddle.com/api-reference/adjustments/overview) (HIGH)
- Internal `oarlock` Codebase: `Paddle.Customers.Addresses`, `Paddle.Internal.Attrs` (HIGH)
