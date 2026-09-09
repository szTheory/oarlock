# Phase 17: Catalog API - Research

**Researched:** 2026-06-10
**Domain:** Elixir SDK API / Paddle Billing v1 (Products & Prices)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Drop `include` from allowlists.** Do not support eager hydration of nested trees (e.g. `include=prices` on Products) within the SDK structs. This adheres to the strict functional isolation and avoids building an Ecto-like ORM preload abstraction.
- **D-02:** Consumers needing prices for a product must explicitly call `Paddle.Prices.list(client, product_id: prod.id)`. Any unexpected nested payloads returned by Paddle will safely fall into the `:raw_data` map on the struct.
- **D-03:** **Documentation-only warnings.** Provide explicit `@moduledoc` and `@doc` warnings on `Paddle.Products` and `Paddle.Prices` explaining that custom items created during checkout are not queryable via the Catalog endpoints.
- **D-04:** Do NOT implement runtime inspection or `:telemetry` emission for custom items in the HTTP response. Keep the execution path pure, fast, and free of side-effects. 
- **D-05:** **Use native `String.t()` without regex enforcement.** Do not hardcode regex validation for Paddle ID prefixes (e.g., `pro_`, `pri_`, `evt_`) in the SDK client.
- **D-06:** Pass the ID string directly to the API, allowing Paddle to return a 400/404, which the SDK will correctly normalize into `%Paddle.Error{}`. This maximizes future-proofing.

### Claude's Discretion
- Formatting and layout of the `@moduledoc` warnings.
- Placement of the test files and naming of test descriptors.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAT-01 | User can list products with auto-pagination (`Paddle.Products.list/2`, `stream/2`, `all/2`). | Supported by matching the standard API list pattern in `Paddle.Subscriptions`, using `@list_allowlist` and delegating to `Paddle.Internal.Pagination`. |
| CAT-02 | User can fetch a single product by ID (`Paddle.Products.get/2`). | Supported by building `Paddle.Products.get/2` which calls `GET /products/{id}`. Handled per D-05 and D-06. |
| CAT-03 | User can list prices with auto-pagination (`Paddle.Prices.list/2`, `stream/2`, `all/2`). | Supported by `Paddle.Prices.list` querying `GET /prices` with pagination, and allowing standard query params like `product_id`. |
| CAT-04 | User can fetch a single price by ID (`Paddle.Prices.get/2`). | Supported by building `Paddle.Prices.get/2` which calls `GET /prices/{id}`. |
| CAT-05 | User is warned in documentation about attempting to fetch "Custom" prices/products via the Catalog. | Addressed directly by D-03: explicitly inserting `@moduledoc` and `@doc` warnings into both Modules without adding runtime checks. |
</phase_requirements>

## Summary

This phase implements read-only REST endpoints for the Paddle Billing v1 Catalog (`Products` and `Prices`). Following the strict pure-functional nature of the `oarlock` SDK, the implementation avoids eager-hydration (`include` parameters are explicitly dropped per D-01) and delegates all ID validation natively to Paddle (D-05/D-06), wrapping responses in strongly typed structs (`%Paddle.Product{}` and `%Paddle.Price{}`). Auto-pagination is exposed via the existing `Paddle.Internal.Pagination` abstractions, meaning the consumer interface will exactly match the established patterns in `Paddle.Customers` and `Paddle.Subscriptions`.

**Primary recommendation:** Implement `Paddle.Product`, `Paddle.Products`, `Paddle.Price`, and `Paddle.Prices` relying purely on `Paddle.Http.request/4`, dropping `include` from any list allowlists, and explicitly adding `@moduledoc` warnings for custom item constraints (CAT-05).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Struct Definitions | API / Backend | — | Defines the strongly typed schema for Catalog items (e.g., `Paddle.Product` and `Paddle.Price`). Provides the `raw_data` fallback. |
| Catalog Listing & Retrieval | API / Backend | — | Implements the `get`, `list`, `stream`, and `all` read operations making HTTP requests via `Req` without side-effects. |
| ID String Validation | API / Backend | — | Defers strict format validation to the Paddle API (returning 400/404) rather than using local regex, maintaining SDK future-proofing. Empty string checks are the only local validation. |
| Pagination Abstraction | API / Backend | — | Reuses `Paddle.Internal.Pagination` logic for seamless auto-pagination matching the REST convention already present in the SDK. |

## Standard Stack

No new dependencies are required. The existing core stack is perfectly sufficient for the phase.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Req` | `~> 0.5.17` | HTTP Transport & JSON Parsing | Built-in JSON decoding (`jason`), retry mechanisms, and telemetry. Required by `Paddle.Http`. |
| `Elixir` | `~> 1.19` | Language & Types | Built-in `Stream` for auto-pagination and pure structs for API data representation. |

## Package Legitimacy Audit

*Step skipped: No external packages are installed during this phase.*

## Architecture Patterns

### Recommended Project Structure
```
lib/paddle/
├── product.ex       # Defines %Paddle.Product{}
├── products.ex      # Implements get, list, stream, all for /products
├── price.ex         # Defines %Paddle.Price{}
└── prices.ex        # Implements get, list, stream, all for /prices

test/paddle/
├── product_test.exs
├── products_test.exs
├── price_test.exs
└── prices_test.exs
```

### Pattern 1: Typed Read-Only Modules
**What:** Implementing read-only APIs for Products and Prices, skipping CRUD operations for standard management.
**When to use:** When exposing the Catalog API, which is primarily managed via the Paddle Dashboard but frequently queried by Accrue implementations.
**Example:**
```elixir
defmodule Paddle.Products do
  # CAT-05: Documentation-only warnings.
  @moduledoc """
  ...
  > #### Custom Items Warning
  >
  > Custom products and prices created on-the-fly during checkout cannot be queried
  > via the Catalog endpoints. Only standard catalog items are returned.
  """
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Product
  alias Paddle.Internal.Pagination
  alias Paddle.Internal.Attrs

  # D-01: No `include` param supported to prevent Ecto-like hydration
  @list_allowlist ~w(id status tax_category order_by after per_page)

  @spec get(Client.t(), String.t()) :: {:ok, Product.t()} | {:error, Paddle.Error.t() | :invalid_product_id}
  def get(%Client{} = client, product_id) do
    with :ok <- validate_product_id(product_id),
         {:ok, %{"data" => data}} <- Http.request(client, :get, product_path(product_id)) do
      {:ok, Http.build_struct(Product, data)}
    end
  end
  # ...list, stream, all
```

### Anti-Patterns to Avoid
- **Eager Struct Hydration:** Never support the `include=prices` parameter on `Paddle.Products.list` nor `include=product` on `Paddle.Prices.list`. Ecto-like hydration violates D-01.
- **Regex ID Enforcement:** Do not implement strict prefix matching (e.g. `^pro_`). Use simple empty-string validation and pass through to Paddle.
- **Runtime Telemetry for Warnings:** Do not inject runtime warnings for custom items in the `get` response. Keep code execution pure (D-04).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Handling paginated API iterations | Recursive recursive HTTP loop builders | `Paddle.Internal.Pagination.stream/2` | Already manages cursors (`after`) natively based on Paddle's generic response metadata (`meta`). |
| Payload Allowlisting | Custom map pruning algorithms | `Paddle.Internal.Attrs.allowlist/2` | Guarantees unknown user parameters are cleanly filtered to match `@list_allowlist`. |
| Unrecognized attributes storage | Ad-hoc map merging | `:raw_data` field on structs | Paddle frequently introduces new fields. All structs must enforce `:raw_data` natively to guarantee forward compatibility. |

## Common Pitfalls

### Pitfall 1: Opaque Local Validation Errors
**What goes wrong:** The SDK rejects a perfectly valid ID because it does not match a hardcoded regex, forcing an urgent hotfix release.
**Why it happens:** Attempting to over-optimize validation locally.
**How to avoid:** (D-05/D-06) Restrict local ID validation to simple binary/empty checks: `if String.trim(id) == "", do: {:error, :invalid_product_id}, else: :ok`.

### Pitfall 2: Missing Struct Fields
**What goes wrong:** Missing `raw_data` or standard timestamps (`created_at`, `updated_at`) on the structs.
**Why it happens:** Paddle's API docs emphasize the core fields, and sometimes timestamps are assumed implicit.
**How to avoid:** Always map `created_at`, `updated_at`, `custom_data`, `import_meta`, and `raw_data` explicitly in `%Paddle.Product{}` and `%Paddle.Price{}` struct definitions.

## Code Examples

Verified read-only list module pattern:
### Read-only Listing & Pagination
```elixir
@spec list(Paddle.Client.t(), map() | keyword()) ::
        {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
def list(%Client{} = client, params \\ []) do
  with {:ok, params} <- Attrs.normalize(params),
       query <- Attrs.allowlist(params, @list_allowlist),
       {:ok, %{"data" => data, "meta" => meta}} <-
         Http.request(client, :get, "/products", params: query) do
    {:ok, Paddle.Internal.Pagination.build_page(Product, data, meta)}
  end
end

@spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
def stream(%Client{} = client, params \\ []) do
  Pagination.stream(
    fn -> list(client, params) end,
    fn path -> Pagination.next_page(client, Product, path) end
  )
end
```
*(Note: `build_page/3` and `next_page/3` usage should match the exact function signature of the existing `Paddle.Internal.Pagination` or module-specific `build_page/2` depending on how `customers/addresses.ex` or `subscriptions.ex` implements it).*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Paddle Classic schema | Paddle Billing API v1 | Billing v1 release | Products and Prices are strictly decoupled. No single combined payload without using `include`. |
| SDK-level complex object relationships | Functional isolation with fallback | Decided D-01 | Simpler, more robust SDK with fewer runtime failures and no complex data merging functions. |

## Assumptions Log

If this table is empty: All claims in this research were verified or cited — no user confirmation needed.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| (None) | All phase requirements strictly follow CONTEXT.md lock-ins. | | |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (~> 1.19) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/paddle/product_test.exs test/paddle/products_test.exs test/paddle/price_test.exs test/paddle/prices_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CAT-01 | List and paginate products natively | unit/integration | `mix test test/paddle/products_test.exs` | ❌ Wave 0 |
| CAT-02 | Fetch a single product by ID | unit/integration | `mix test test/paddle/products_test.exs` | ❌ Wave 0 |
| CAT-03 | List and paginate prices natively | unit/integration | `mix test test/paddle/prices_test.exs` | ❌ Wave 0 |
| CAT-04 | Fetch a single price by ID | unit/integration | `mix test test/paddle/prices_test.exs` | ❌ Wave 0 |
| CAT-05 | Custom catalog item documentation warnings | unit (doc checks) | `mix docs` / checked via dialyzer | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/paddle/product_test.exs` — covers struct properties and raw_data mapping.
- [ ] `test/paddle/products_test.exs` — covers get, list, stream, all operations on Products.
- [ ] `test/paddle/price_test.exs` — covers struct properties for Price.
- [ ] `test/paddle/prices_test.exs` — covers get, list, stream, all operations on Prices.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Basic string checks (empty binary protection before sending). Delegation to Paddle API for deep format verification. |

### Known Threat Patterns for Elixir API SDKs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Parameter Pollution | Tampering | Using `@list_allowlist` and `Paddle.Internal.Attrs.allowlist/2` before transmitting data. |
| Application DoS (Atom Exhaustion) | Denial of Service | Using `Jason` properly; ensuring struct keys are safely statically allocated (no runtime atoms created from untrusted input), mapping unknown data cleanly to `raw_data: map()`. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/17-catalog-api/17-CONTEXT.md` - Phase constraints (D-01 to D-06)
- `.planning/REQUIREMENTS.md` - (CAT-01 to CAT-05 explicit definitions)
- [Paddle Official API Docs - Products](https://developer.paddle.com/api-reference/products/overview) - Struct payload references
- [Paddle Official API Docs - Prices](https://developer.paddle.com/api-reference/prices/overview) - Struct payload references

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core project constraints enforce existing toolchains
- Architecture: HIGH - Dictated by locked CONTEXT.md decisions D-01 through D-06
- Pitfalls: HIGH - Documented anti-patterns map strictly to context guidelines

**Research date:** 2026-06-10
**Valid until:** Milestone v1.4 release
