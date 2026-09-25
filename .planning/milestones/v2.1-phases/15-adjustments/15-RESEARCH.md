# Phase 15: Adjustments - Research

**Researched:** 2026-06-09
**Domain:** Elixir SDK / Paddle API Integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Signature: Positional args vs Attrs
- **D-01:** `create(client, attrs)` (No positional args for action/reason). Positional arguments are strictly reserved for URL path parameters (e.g., `id` in `get/2`). Since Paddle's Create Adjustment endpoint (`POST /adjustments`) takes `action`, `reason`, and `transaction_id` in the JSON body, they belong in the `attrs` map. This prevents arbitrary API body fields from leaking into function signatures, maintaining a clean, predictable `(client, attrs)` contract across the SDK.

### Partial Adjustments Helper vs Raw Attrs
- **D-02:** Raw `attrs` with strict Typespecs (No dedicated helper). The principle of least surprise for a foundational Elixir SDK is "data in, data out." We will not create a dedicated `create_partial` helper or builder pattern. Instead, developers should pass the `items` array directly in the `attrs` map. We provide excellent DX by defining precise Dialyzer typespecs for the `items` shape, allowing editor autocomplete (ElixirLS) to guide the developer without adding runtime bloat or maintenance debt.

### the agent's Discretion
- The exact Dialyzer typespec definitions for the `items` shape to maximize editor autocomplete utility.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADJ-01 | User can create a full refund or credit adjustment for a completed/billed transaction (`Paddle.Adjustments.create/2`). | The `POST /adjustments` endpoint accepts `action`, `reason`, `transaction_id`. Supported via `create/2`. |
| ADJ-02 | User can create a partial refund or credit adjustment by specifying line items and amounts. | The `POST /adjustments` endpoint accepts an `items` array with `item_id`, `type`, `amount`. Validated via strict Dialyzer typespecs in `Paddle.Adjustments` per D-02. |
| ADJ-03 | User can retrieve an existing adjustment by its ID (`Paddle.Adjustments.get/2`). | Supported via the `GET /adjustments/{adjustment_id}` endpoint. Validates prefix `adj_`. |
| ADJ-04 | User can list adjustments with standard pagination (`Paddle.Adjustments.stream`, `Paddle.Adjustments.all`). | Supported via `GET /adjustments` endpoint and existing `Paddle.Internal.Pagination` utilities. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Adjustments Endpoint Invocation | `Paddle.Adjustments` Module | `Paddle.Http` | Encapsulates the specific API URLs and request types (POST, GET). |
| Data Pagination | `Paddle.Internal.Pagination` | `Paddle.Adjustments` | Pagination is standard across endpoints; it leverages generic stream and reduction functions. |
| Data Modeling & Structuring | `Paddle.Adjustment` Struct | — | Contains the strongly-typed Elixir struct that maps to Paddle's API response. |
| Parameter Validation (Payload) | Dialyzer / Type Specs | `Paddle.Internal.Attrs` | Enforces "data in, data out" payload validation statically at compile-time/development via language server, combined with runtime allowlist filtering. |

## Standard Stack

This phase relies completely on existing built-in SDK infrastructure (no new dependencies).

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Core | (existing) | Dialyzer Typespecs (`@type`) | Required for D-02 constraint for partial adjustment DX. |
| `Paddle.Http` | (internal) | API Transport | SDK standard HTTP wrapper returning `{:ok, struct} | {:error, error}` |

## Architecture Patterns

### System Architecture Diagram
Data Flow for Adjustment Creation:
1. `Developer App` -> calls `Paddle.Adjustments.create(client, attrs)`
2. `Paddle.Adjustments` -> normalizes attrs, checks allowlist, sends to `Paddle.Http.request(:post, "/adjustments")`
3. `Paddle.Http` -> parses Paddle API response
4. `Paddle.Adjustments` -> uses `Http.build_struct(Adjustment, data)`
5. `Developer App` <- receives `{:ok, %Paddle.Adjustment{}}` or `{:error, %Paddle.Error{}}`

### Recommended Project Structure
```text
lib/paddle/
├── adjustment.ex       # The struct and typespecs (e.g., items, totals)
├── adjustments.ex      # Functions: create/2, get/2, list/2, stream/2, all/2
test/paddle/
├── adjustment_test.exs # Optional: Tests for struct casting if any helpers exist
├── adjustments_test.exs# API interaction and typespec validation tests
```

### Pattern 1: Strict Typespec for Attrs Input (D-02)
**What:** Define a clear `@type create_attrs` mapping the expected payload.
**When to use:** In `Paddle.Adjustments.create/2` instead of plain `map()`.
**Example:**
```elixir
@type adjustment_item_attr :: %{
  required(:item_id) => String.t(),
  required(:type) => String.t(), # "full", "partial", "tax", "proration"
  optional(:amount) => String.t() | integer()
}

@type create_attrs :: %{
  required(:action) => String.t(), # "refund" | "credit"
  required(:reason) => String.t(),
  required(:transaction_id) => String.t(),
  optional(:items) => [adjustment_item_attr()]
}

@spec create(Paddle.Client.t(), create_attrs() | keyword(), [request_opt()]) ::
        {:ok, Paddle.Adjustment.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cursor-based Pagination | Custom recursive loop | `Paddle.Internal.Pagination` | Properly decodes cursor next links, handles errors gracefully, exposes standard `stream/2` and `all/2`. |
| Map Key Normalization | Custom `Enum.map` | `Paddle.Internal.Attrs.normalize/1` | Enforces standard validation (map/keyword check) and ensures atom/string key conversions match SDK style. |

## Common Pitfalls

### Pitfall 1: Unsafe URL Paths
**What goes wrong:** Calling `get/2` with a malformed ID string causes a malformed HTTP request or 404 instead of a structured validation error.
**Why it happens:** Skipping local ID validation prior to interpolating the URL.
**How to avoid:** Always include a `validate_adjustment_id(id)` step (similar to `Customers`) that ensures the string is not empty before returning the `"/adjustments/#{id}"` path.

### Pitfall 2: Silent Attribute Drops on Creation
**What goes wrong:** A developer passes `items` in a partial adjustment, but it gets filtered out by `Attrs.allowlist`.
**Why it happens:** Forgetting to add `"items"` to the module attribute `@create_allowlist`.
**How to avoid:** Ensure `@create_allowlist` includes all valid Paddle v1 payload keys (`action`, `reason`, `transaction_id`, `items`).

## Code Examples

### Standard SDK Listing Pattern
```elixir
def list(%Client{} = client, params \\ []) do
  with {:ok, params} <- normalize_params(params),
       query <- Attrs.allowlist(params, @list_allowlist),
       {:ok, %{"data" => data, "meta" => meta}} <-
         Http.request(client, :get, "/adjustments", params: query) do
    {:ok, build_page(data, meta)}
  end
end

def stream(%Client{} = client, params \\ []) do
  Pagination.stream(
    fn -> list(client, params) end,
    fn path -> next_page(client, path) end
  )
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No new external dependencies required (environment check skipped). | Standard Stack | Low - Elixir standard library provides everything required for typespecs. |
| A2 | Missing Validation Architecture section (nyquist disabled). | Meta | None - configuration correctly applied. |

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified, Elixir standard library and current `deps` are sufficient).

## Sources
### Primary (HIGH confidence)
- [Official docs URL] - Paddle Billing API v1 Adjustments Reference
- [Official docs URL] - Paddle Billing API v1 Adjustment Object Properties
- Local `15-CONTEXT.md`

### Secondary (MEDIUM confidence)
- Web search for Paddle Adjustments `items` shape and capabilities.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core SDK modules are already built.
- Architecture: HIGH - Dictated strongly by CONTEXT.md.
- Pitfalls: HIGH - Extrapolated from other `Paddle.*` modules.

**Research date:** 2026-06-09
**Valid until:** 2026-07-09
