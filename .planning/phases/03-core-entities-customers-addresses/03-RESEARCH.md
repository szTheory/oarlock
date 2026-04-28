# Phase 3: Core Entities (Customers & Addresses) - Research

**Researched:** 2026-04-28
**Domain:** Paddle customers and customer-scoped addresses for an Elixir SDK
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Public API Shape
- **D-01:** Use resource modules rather than a flat `Paddle` facade.
- **D-02:** Expose customers as `Paddle.Customers.create/2`, `get/2`, and `update/3`.
- **D-03:** Expose addresses as a nested customer-owned resource: `Paddle.Customers.Addresses.create/3`, `list/3`, `get/3`, and `update/4`.
- **D-04:** Do not expose duplicate public API shapes for the same address operations. If a lower-level endpoint helper is useful, keep it private/internal.

### Entity Struct Strategy
- **D-05:** Model `%Paddle.Customer{}` and `%Paddle.Address{}` as first-class structs with the most common top-level Paddle fields promoted to atom keys.
- **D-06:** Preserve the full API payload in `raw_data` on both structs for forward compatibility and escape-hatch access.
- **D-07:** Keep field names snake_case and aligned with Paddle JSON keys where possible (`:marketing_consent`, `:country_code`, `:created_at`, `:updated_at`) to minimize surprise and mapping complexity.
- **D-08:** Keep nested/dynamic fields lightweight: `custom_data` stays a plain map; only selectively model nested objects when the shape is stable and high-value.
- **D-09:** Do not inline address collections onto `%Paddle.Customer{}`. Addresses remain separate endpoint-backed resources.

### Address Ownership & Listing Semantics
- **D-10:** Keep address operations explicitly customer-scoped in the function signature, not hidden inside payload maps.
- **D-11:** Address listing returns `{:ok, %Paddle.Page{data: [%Paddle.Address{}, ...], meta: ...}}` and is always interpreted as "addresses for this customer."
- **D-12:** Preserve Paddle's ownership semantics directly: addresses are customer subentities, not standalone global resources in the public API.

### Request Ergonomics
- **D-13:** Accept `map | keyword` attrs for create/update operations rather than request-builder structs.
- **D-14:** Normalize inputs only enough to produce JSON-ready request bodies and keep nested attrs in the SDK's snake_case vocabulary.
- **D-15:** Perform only lightweight, stable local checks at the boundary: container shape, required path arguments, and obvious invalid combinations. Leave business validation to Paddle and return remote failures as `{:error, %Paddle.Error{}}`.
- **D-16:** Preserve PATCH semantics: omitted fields mean "leave unchanged"; explicit `nil` clears nullable fields where Paddle supports it.

### Developer Experience Direction
- **D-17:** Bias toward least surprise and coherence with existing Elixir client-library norms (`Req`, `stripity_stripe`): explicit client passing, predictable resource modules, and simple attrs maps.
- **D-18:** Bias future decisions toward researched, opinionated defaults. Only surface user decisions when the tradeoff is meaningfully impactful to product or architecture.

### the agent's Discretion
- Exact first-pass field lists for `%Paddle.Customer{}` and `%Paddle.Address{}`.
- Whether `import_meta` is a small nested struct or left as a plain map in Phase 3.
- Internal helper-module names and request normalization helper boundaries.
- Whether to accept both maps and keyword lists directly everywhere or normalize keyword lists at the public edge into maps immediately.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CUST-01 | Map application users to Paddle Customers (create, get, update). | Use `Paddle.Customers.create/2`, `get/2`, and `update/3` over `/customers` and `/customers/{customer_id}`, with `%Paddle.Customer{}` built from the `"data"` object and `raw_data` preserving the entity payload. [CITED: https://developer.paddle.com/api-reference/customers/create-customer] [CITED: https://developer.paddle.com/api-reference/customers/get-customer] [CITED: https://developer.paddle.com/api-reference/customers/update-customer] [VERIFIED: lib/paddle/http.ex] |
| ADDR-01 | Support customer billing addresses (create, list, update). | Use `Paddle.Customers.Addresses.create/3`, `list/3`, `get/3`, and `update/4` over nested `/customers/{customer_id}/addresses` paths, with `%Paddle.Page{}` for list responses and `%Paddle.Address{}` for entity responses. [CITED: https://developer.paddle.com/api-reference/addresses/create-address] [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] [CITED: https://developer.paddle.com/api-reference/addresses/get-address] [CITED: https://developer.paddle.com/api-reference/addresses/update-adddress] [VERIFIED: lib/paddle/page.ex] |
</phase_requirements>

## Summary

Phase 3 should add four public modules only: `%Paddle.Customer{}`, `%Paddle.Address{}`, `Paddle.Customers`, and `Paddle.Customers.Addresses`. That matches the locked nested-resource API and Paddle’s current REST shape, where customers are top-level resources and addresses live under `/customers/{customer_id}/addresses`. [CITED: https://developer.paddle.com/api-reference/customers/overview] [CITED: https://developer.paddle.com/api-reference/addresses/overview]

The existing transport boundary is already sufficient. `Paddle.Http.request/4` returns decoded response bodies for 2xx, `%Paddle.Error{}` for non-2xx API responses, and raw transport exceptions unchanged; `Paddle.Http.build_struct/2` already maps known string keys onto declared struct fields and stores the original entity payload in `raw_data`. Phase 3 should build on those semantics rather than add a second response wrapper. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/error.ex] [CITED: https://hexdocs.pm/req/Req.Steps.html]

**Primary recommendation:** implement thin resource modules that pattern-match on Paddle’s `"data"` and `"meta"` envelope, use allowlisted attrs/query keys per endpoint, map entity payloads with `Paddle.Http.build_struct/2`, and map address lists into `%Paddle.Page{data: [%Paddle.Address{}], meta: meta}`. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/page.ex] [CITED: https://developer.paddle.com/api-reference/about/success-responses]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Customer create/get/update | API / Backend | — | The SDK process owns request shaping and entity mapping for `/customers` resources. [CITED: https://developer.paddle.com/api-reference/customers/overview] |
| Address create/get/list/update | API / Backend | — | Addresses are customer subresources, so the SDK process must preserve customer-scoped paths and page mapping. [CITED: https://developer.paddle.com/api-reference/addresses/overview] |
| Response envelope parsing | API / Backend | — | Paddle returns `"data"` plus `"meta"` envelopes; this repo’s HTTP boundary already returns decoded maps for callers to interpret. [VERIFIED: lib/paddle/http.ex] [CITED: https://developer.paddle.com/api-reference/about/success-responses] |
| Raw payload preservation | API / Backend | — | Struct construction belongs in the SDK boundary, using declared fields plus `raw_data` for forward compatibility. [VERIFIED: lib/paddle/http.ex] [VERIFIED: .planning/PROJECT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req` | `~> 0.5.17` | HTTP execution, query encoding, JSON request/response handling | Already installed and already used by `%Paddle.Client{}` and `Paddle.Http.request/4`; it supports `json:` request bodies, `params:` query encoding, and automatic JSON response decoding. [VERIFIED: mix.exs] [VERIFIED: lib/paddle/client.ex] [VERIFIED: lib/paddle/http.ex] [CITED: https://hexdocs.pm/req/Req.Steps.html] |
| `telemetry` | `~> 1.4` | Existing request instrumentation | Already attached at the client level; Phase 3 should reuse it unchanged. [VERIFIED: mix.exs] [VERIFIED: lib/paddle/client.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `%Paddle.Page{}` | existing local module | Paginated list wrapper for addresses | Use only for `Paddle.Customers.Addresses.list/3`; customer CRUD remains direct entity tuples. [VERIFIED: lib/paddle/page.ex] [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] |
| `Paddle.Http.build_struct/2` | existing local function | Known-field + `raw_data` mapping | Use for every entity response after extracting the `"data"` object from Paddle’s response envelope. [VERIFIED: lib/paddle/http.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Paddle.Customers.Addresses.*` | Flat `Paddle.Addresses.*` facade | Reject it; the phase context locks customer-scoped public addresses, and Paddle’s paths are customer-scoped. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/addresses/overview] |
| Plain-map `import_meta` | Dedicated `%Paddle.ImportMeta{}` | Defer it; `import_meta` is present but low-value for this slice, while `build_struct/2` already preserves it as a nested plain map without extra modeling churn. [VERIFIED: lib/paddle/http.ex] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] |

**Installation:** No new runtime dependencies are needed for Phase 3. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
caller
  -> Paddle.Customers / Paddle.Customers.Addresses
  -> attrs/query normalization + path argument checks
  -> Paddle.Http.request/4
  -> Paddle API ("data" + "meta" envelope)
  -> Paddle.Http.build_struct/2 or %Paddle.Page{}
  -> {:ok, %Paddle.Customer{} | %Paddle.Address{} | %Paddle.Page{}} | {:error, %Paddle.Error{} | transport_exception}
```

### Recommended Project Structure
```text
lib/paddle/
├── customer.ex              # %Paddle.Customer{}
├── address.ex               # %Paddle.Address{}
├── customers.ex             # create/get/update
└── customers/
   └── addresses.ex          # create/list/get/update
```

### Pattern 1: Thin Resource Modules Over The Existing Transport
**What:** Resource functions should extract the response envelope locally instead of changing `Paddle.Http.request/4`. [VERIFIED: lib/paddle/http.ex]
**When to use:** Every Phase 3 public function. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md]
**Example:**
```elixir
# Source: lib/paddle/http.ex + Paddle success response docs
def create(%Paddle.Client{} = client, attrs) do
  with {:ok, %{"data" => data}} <-
         Paddle.Http.request(client, :post, "/customers", json: customer_create_body(attrs)) do
    {:ok, Paddle.Http.build_struct(Paddle.Customer, data)}
  end
end
```

### Pattern 2: Separate Allowlists For Create And Update
**What:** Create and update requests should not share one unrestricted body builder. Customer create supports `email`, `name`, `custom_data`, and `locale`; customer update adds `status`. Address create requires `country_code`; address update adds `status`. `marketing_consent` and `import_meta` appear in request schemas but are marked external read-only in the OpenAPI spec and should not be sent. [CITED: https://developer.paddle.com/api-reference/customers/create-customer] [CITED: https://developer.paddle.com/api-reference/customers/update-customer] [CITED: https://developer.paddle.com/api-reference/addresses/create-address] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**When to use:** In private normalization helpers such as `customer_create_body/1`, `customer_update_body/1`, `address_create_body/1`, and `address_update_body/1`. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md]

### Pattern 3: Page Mapping Only At The List Boundary
**What:** List responses return `%Paddle.Page{}` with mapped data and unmodified `meta`; entity responses return direct structs. [VERIFIED: lib/paddle/page.ex] [CITED: https://developer.paddle.com/api-reference/about/success-responses]
**When to use:** `Paddle.Customers.Addresses.list/3` only. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md]
**Example:**
```elixir
# Source: lib/paddle/page.ex + Paddle address list docs
def list(%Paddle.Client{} = client, customer_id, params \\ []) do
  with {:ok, %{"data" => data, "meta" => meta}} <-
         Paddle.Http.request(
           client,
           :get,
           "/customers/#{customer_id}/addresses",
           params: address_list_params(params)
         ) do
    page = %Paddle.Page{
      data: Enum.map(data, &Paddle.Http.build_struct(Paddle.Address, &1)),
      meta: meta
    }

    {:ok, page}
  end
end
```

### Public API Recommendation

```elixir
Paddle.Customers.create(client, attrs)
Paddle.Customers.get(client, customer_id)
Paddle.Customers.update(client, customer_id, attrs)

Paddle.Customers.Addresses.create(client, customer_id, attrs)
Paddle.Customers.Addresses.list(client, customer_id, params \\ [])
Paddle.Customers.Addresses.get(client, customer_id, address_id)
Paddle.Customers.Addresses.update(client, customer_id, address_id, attrs)
```

The customer public API should stop at create/get/update for Phase 3 even though Paddle also supports list; keeping customer list out of this phase matches the roadmap scope and avoids expanding planner work unnecessarily. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://developer.paddle.com/api-reference/customers/list-customers]

### First-Pass Struct Fields

#### `%Paddle.Customer{}`
| Field | Include | Reason |
|------|---------|--------|
| `:id`, `:name`, `:email`, `:marketing_consent`, `:status`, `:custom_data`, `:locale`, `:created_at`, `:updated_at`, `:import_meta`, `:raw_data` | yes | These are the full top-level customer entity fields in Paddle’s current schema, and `import_meta` can remain a plain nested map for now. [CITED: https://developer.paddle.com/api-reference/customers/overview] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] [VERIFIED: lib/paddle/http.ex] |

#### `%Paddle.Address{}`
| Field | Include | Reason |
|------|---------|--------|
| `:id`, `:customer_id`, `:description`, `:first_line`, `:second_line`, `:city`, `:postal_code`, `:region`, `:country_code`, `:custom_data`, `:status`, `:created_at`, `:updated_at`, `:import_meta`, `:raw_data` | yes | These are the full top-level address entity fields in Paddle’s current schema, and they map cleanly through `build_struct/2` without custom nested structs. [CITED: https://developer.paddle.com/api-reference/addresses/overview] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] [VERIFIED: lib/paddle/http.ex] |

### Endpoint And Mapping Boundaries

| Function | Method + Path | Request allowlist | Success mapping |
|----------|---------------|-------------------|-----------------|
| `Paddle.Customers.create/2` | `POST /customers` [CITED: https://developer.paddle.com/api-reference/customers/create-customer] | `email`, `name`, `custom_data`, `locale` [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] | `%{"data" => data}` -> `{:ok, Paddle.Http.build_struct(Paddle.Customer, data)}`. [VERIFIED: lib/paddle/http.ex] |
| `Paddle.Customers.get/2` | `GET /customers/{customer_id}` [CITED: https://developer.paddle.com/api-reference/customers/get-customer] | path arg only | `%{"data" => data}` -> `%Paddle.Customer{}`. The OpenAPI uses `CustomerIncludes`, but its current top-level fields match `Customer`, so Phase 3 does not need a second struct. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] |
| `Paddle.Customers.update/3` | `PATCH /customers/{customer_id}` [CITED: https://developer.paddle.com/api-reference/customers/update-customer] | `name`, `email`, `status`, `custom_data`, `locale` [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] | `%{"data" => data}` -> `%Paddle.Customer{}`. [VERIFIED: lib/paddle/http.ex] |
| `Paddle.Customers.Addresses.create/3` | `POST /customers/{customer_id}/addresses` [CITED: https://developer.paddle.com/api-reference/addresses/create-address] | `country_code`, `description`, `first_line`, `second_line`, `city`, `postal_code`, `region`, `custom_data` [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] | `%{"data" => data}` -> `%Paddle.Address{}`. [VERIFIED: lib/paddle/http.ex] |
| `Paddle.Customers.Addresses.list/3` | `GET /customers/{customer_id}/addresses` [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] | query allowlist `id`, `after`, `per_page`, `order_by`, `status`, `search` [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] | `%{"data" => data, "meta" => meta}` -> `%Paddle.Page{data: mapped_addresses, meta: meta}`. [VERIFIED: lib/paddle/page.ex] |
| `Paddle.Customers.Addresses.get/3` | `GET /customers/{customer_id}/addresses/{address_id}` [CITED: https://developer.paddle.com/api-reference/addresses/get-address] | path args only | `%{"data" => data}` -> `%Paddle.Address{}`. [VERIFIED: lib/paddle/http.ex] |
| `Paddle.Customers.Addresses.update/4` | `PATCH /customers/{customer_id}/addresses/{address_id}` [CITED: https://developer.paddle.com/api-reference/addresses/update-adddress] | `description`, `first_line`, `second_line`, `city`, `postal_code`, `region`, `country_code`, `custom_data`, `status` [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] | `%{"data" => data}` -> `%Paddle.Address{}`. [VERIFIED: lib/paddle/http.ex] |

### Anti-Patterns to Avoid
- **Do not change `Paddle.Http.request/4` to unwrap `"data"` automatically:** list responses need `"meta"` intact, and Phase 1 tests already assert that `request/4` returns the decoded body as-is. [VERIFIED: lib/paddle/http.ex] [VERIFIED: test/paddle/http_test.exs]
- **Do not send `marketing_consent` or `import_meta` in customer writes, or `import_meta` in address writes:** they are read-only in Paddle’s OpenAPI even though they appear on create/update schemas. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
- **Do not drop explicit `nil` keys from PATCH bodies:** Phase context locks PATCH semantics where explicit `nil` clears nullable fields. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md]
- **Do not inline addresses onto `%Paddle.Customer{}` or add a customer list API in this phase:** both expand scope beyond the locked phase boundary. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Response envelope abstraction | A second transport wrapper just for entities | `Paddle.Http.request/4` + resource-local envelope pattern matching | The existing transport already normalizes API vs transport failures and returns decoded maps. [VERIFIED: lib/paddle/http.ex] |
| Struct hydration | Per-resource manual field-copy functions | `Paddle.Http.build_struct/2` | It already filters to declared keys and preserves `raw_data`. [VERIFIED: lib/paddle/http.ex] |
| Pagination container | A custom address list struct | `%Paddle.Page{}` | Phase 1 already established the page abstraction and `next_cursor/1`. [VERIFIED: lib/paddle/page.ex] |
| Deep nested entity modeling | Custom structs for `custom_data` or `import_meta` | Plain maps inside the first-pass structs | The phase context explicitly prefers lightweight handling for nested/dynamic fields. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] |

**Key insight:** the only new domain logic in Phase 3 is path construction plus allowlisted request/query normalization; transport, error normalization, page shape, and raw payload preservation are already built. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/page.ex] [VERIFIED: lib/paddle/error.ex]

## Common Pitfalls

### Pitfall 1: Customer ID Prefix Confusion
**What goes wrong:** Some Paddle prose for address fields says `customer_id` is prefixed with `cus_`, while the actual customer schema and examples use `ctm_`. [CITED: https://developer.paddle.com/api-reference/addresses/overview] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**Why it happens:** The docs mix entity descriptions and examples inconsistently. [CITED: https://developer.paddle.com/api-reference/addresses/overview]
**How to avoid:** Treat customer IDs as opaque strings in public functions, but use `ctm_` in fixtures and docs because that is what the current customer schema and examples show. [CITED: https://developer.paddle.com/api-reference/customers/overview] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**Warning signs:** Tests or docs using `cus_` for customer fixtures. [CITED: https://developer.paddle.com/api-reference/addresses/overview]

### Pitfall 2: Read-Only Fields Leaking Into Write Bodies
**What goes wrong:** A naive allowlist based only on response fields or broad schemas can send `marketing_consent` and `import_meta`, which are not true writable Phase 3 inputs. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**Why it happens:** Paddle’s generated create/update schemas include some read-only properties with `x-external-readOnly`. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**How to avoid:** Maintain explicit create/update allowlists per function. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**Warning signs:** Request-body assertions containing `marketing_consent` or `import_meta`. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]

### Pitfall 3: Losing PATCH Clear Semantics
**What goes wrong:** Generic body cleanup that removes `nil` values makes it impossible to clear nullable Paddle fields. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md]
**Why it happens:** Many normalization helpers strip `nil` by default. [ASSUMED]
**How to avoid:** Filter unknown keys, but keep known keys even when the value is `nil`. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md]
**Warning signs:** Update tests passing `first_line: nil` or `name: nil` and observing that the key never reaches the adapter. [ASSUMED]

### Pitfall 4: Forgetting Address List Defaults
**What goes wrong:** Archived addresses appear “missing” because Paddle defaults address list results to `active` status only. [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses]
**Why it happens:** `status` defaults to `active` in the list query contract. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
**How to avoid:** Document `status` in the public API and include archived-list tests. [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses]
**Warning signs:** A customer with archived addresses returns an empty list unless `status` is passed. [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses]

## Code Examples

Verified patterns from official sources and the current codebase:

### Customer Entity Struct
```elixir
# Source: Paddle customer schema + lib/paddle/http.ex
defmodule Paddle.Customer do
  defstruct [
    :id,
    :name,
    :email,
    :marketing_consent,
    :status,
    :custom_data,
    :locale,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
```

### Address Entity Struct
```elixir
# Source: Paddle address schema + lib/paddle/http.ex
defmodule Paddle.Address do
  defstruct [
    :id,
    :customer_id,
    :description,
    :first_line,
    :second_line,
    :city,
    :postal_code,
    :region,
    :country_code,
    :custom_data,
    :status,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
```

### Existing Transport-Compatible Page Mapping
```elixir
# Source: lib/paddle/http.ex, lib/paddle/page.ex, Req params/json docs
defp map_address_page(%{"data" => data, "meta" => meta}) do
  %Paddle.Page{
    data: Enum.map(data, &Paddle.Http.build_struct(Paddle.Address, &1)),
    meta: meta
  }
end
```

## Verification Ideas

| Target | Test Idea | Why It Matters |
|--------|-----------|----------------|
| `Paddle.Customers.create/2` | Stub `POST /customers`, assert `json:` body contains only `email`, `name`, `custom_data`, and `locale`, and assert `{:ok, %Paddle.Customer{raw_data: data}}`. [VERIFIED: test/paddle/http_test.exs] [CITED: https://developer.paddle.com/api-reference/customers/create-customer] | Confirms allowlist discipline and `raw_data` preservation. [VERIFIED: lib/paddle/http.ex] |
| `Paddle.Customers.update/3` | Send `name: nil` or `custom_data: nil` through a stubbed PATCH and assert the key is still present in the outgoing JSON. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] | Protects the locked PATCH-clear semantics. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] |
| `Paddle.Customers.get/2` | Stub `GET /customers/{id}` and assert mapping uses the `"data"` object only, not the whole response envelope. [CITED: https://developer.paddle.com/api-reference/about/success-responses] | Prevents `raw_data` from accidentally becoming `%{"data" => ..., "meta" => ...}`. [VERIFIED: lib/paddle/http.ex] |
| `Paddle.Customers.Addresses.list/3` | Stub a paginated address response, assert `%Paddle.Page{data: [%Paddle.Address{}, ...], meta: %{"pagination" => ...}}`, and assert `Paddle.Page.next_cursor/1` works on the returned page. [VERIFIED: lib/paddle/page.ex] [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] | Verifies the only list boundary in this phase. [VERIFIED: .planning/ROADMAP.md] |
| `Paddle.Customers.Addresses.list/3` filters | Assert `params:` encoding for `after`, `per_page`, `status`, `search`, and `order_by`; include one test for archived addresses via `status`. [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] [CITED: https://hexdocs.pm/req/Req.Steps.html] | Covers the default-status footgun and query normalization. [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] |
| `Paddle.Customers.Addresses.update/4` | Stub `PATCH /customers/{customer_id}/addresses/{address_id}` and assert `status: "archived"` passes through for archive semantics. [CITED: https://developer.paddle.com/api-reference/addresses/update-adddress] | Ensures address archival remains possible without adding a separate public archive function. [CITED: https://developer.paddle.com/api-reference/addresses/overview] |
| Error passthrough | Stub `customer_already_exists` and ownership/path mismatch 4xx responses, assert the public modules return the `%Paddle.Error{}` from `Paddle.Http.request/4` unchanged. [VERIFIED: lib/paddle/http.ex] [CITED: https://developer.paddle.com/build/customers/create-update-customers] | Confirms resource modules do not fork error handling. [VERIFIED: lib/paddle/error.ex] |
| Transport exception passthrough | Stub `%Req.TransportError{}` from the adapter and assert it bubbles out unchanged from customer and address functions. [VERIFIED: test/paddle/http_test.exs] | Keeps Phase 3 aligned with the existing tuple/error conventions. [VERIFIED: lib/paddle/http.ex] |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Standalone or flat address APIs | Customer-scoped address APIs (`/customers/{customer_id}/addresses`) | Current Paddle Billing API v1 docs and OpenAPI | The Elixir SDK should make customer ownership explicit in function signatures. [CITED: https://developer.paddle.com/api-reference/addresses/overview] [CITED: https://github.com/PaddleHQ/paddle-openapi] |
| Homegrown HTTP wrappers around raw JSON | Thin resource modules over `Req` + decoded maps | Current repo architecture | Phase 3 can focus on domain mapping rather than transport design. [VERIFIED: lib/paddle/client.ex] [VERIFIED: lib/paddle/http.ex] |

**Deprecated/outdated:**
- `Paddle Classic` naming and older Elixir packages are out of scope for this repo; the project and Paddle’s own docs target current Paddle Billing API v1 only. [VERIFIED: .planning/PROJECT.md] [CITED: https://developer.paddle.com/api-reference/overview] [CITED: https://github.com/PaddleHQ/paddle-openapi]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Nil-stripping helpers are a likely implementation hazard in local normalization code. | Common Pitfalls | Low; the fix is simply to retain known keys with `nil` values in update bodies. |

## Open Questions

1. **Should Phase 3 add small private validators for ID prefixes (`ctm_`, `add_`), or only blank/nil checks?**
   - What we know: The phase context allows lightweight stable local checks, and the official schemas define ID patterns. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
   - What's unclear: Whether enforcing prefixes locally is worth the added strictness for a thin SDK. [ASSUMED]
   - Recommendation: Limit Phase 3 to nil/empty path checks and body/query container-shape checks; rely on Paddle for deeper ID validation to keep the boundary thin. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse `%Paddle.Client{}` Bearer-authenticated `Req` client from Phase 1; do not add alternate auth paths here. [VERIFIED: lib/paddle/client.ex] |
| V3 Session Management | no | Not applicable to these server-side API wrappers. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | yes | Preserve customer-scoped address paths exactly so callers cannot accidentally use a global address API shape that Paddle does not expose. [CITED: https://developer.paddle.com/api-reference/addresses/overview] |
| V5 Input Validation | yes | Allowlist attrs/query keys and validate container/path presence locally before calling Paddle. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] |
| V6 Cryptography | no | No new cryptography is introduced in this phase. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-customer address access due to path mix-up | Tampering | Keep `customer_id` explicit in every public address function and every path builder. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/addresses/overview] |
| Over-posting unsupported fields | Tampering | Use per-endpoint allowlists rather than passing arbitrary attrs through to `json:`. [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml] |
| Losing remote failure detail | Repudiation | Let `Paddle.Http.request/4` preserve `%Paddle.Error{}` and transport exceptions unchanged. [VERIFIED: lib/paddle/http.ex] |

## Sources

### Primary (HIGH confidence)
- `lib/paddle/http.ex`, `lib/paddle/client.ex`, `lib/paddle/page.ex`, `lib/paddle/error.ex`, and current tests — transport, page, and tuple conventions checked directly in the codebase. [VERIFIED: codebase grep]
- Paddle API reference overview — current API envelope, base API shape, and official OpenAPI location. [CITED: https://developer.paddle.com/api-reference/overview]
- Paddle customers overview and operation docs — customer fields and `/customers` endpoints. [CITED: https://developer.paddle.com/api-reference/customers/overview] [CITED: https://developer.paddle.com/api-reference/customers/create-customer] [CITED: https://developer.paddle.com/api-reference/customers/get-customer] [CITED: https://developer.paddle.com/api-reference/customers/update-customer]
- Paddle addresses overview and operation docs — nested address ownership and `/customers/{customer_id}/addresses` endpoints. [CITED: https://developer.paddle.com/api-reference/addresses/overview] [CITED: https://developer.paddle.com/api-reference/addresses/create-address] [CITED: https://developer.paddle.com/api-reference/addresses/list-addresses] [CITED: https://developer.paddle.com/api-reference/addresses/get-address] [CITED: https://developer.paddle.com/api-reference/addresses/update-adddress]
- Paddle OpenAPI repository and `v1/openapi.yaml` — exact request/response schemas, query params, enum defaults, and read-only write-field annotations. [CITED: https://github.com/PaddleHQ/paddle-openapi] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]
- Req docs — automatic JSON decoding plus `json:` and `params:` request options. [CITED: https://hexdocs.pm/req/Req.Steps.html]

### Secondary (MEDIUM confidence)
- Paddle Node SDK resource layout — confirms official SDKs expose customers top-level and addresses customer-scoped. [CITED: https://github.com/PaddleHQ/paddle-node-sdk]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 3 uses only the repo’s existing `Req` and local transport/page modules. [VERIFIED: mix.exs] [VERIFIED: lib/paddle/http.ex]
- Architecture: HIGH - The public resource shape is locked by phase context and matches Paddle’s current REST and OpenAPI surface. [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/addresses/overview]
- Pitfalls: HIGH - Each listed pitfall is grounded in the current phase context, current code, or current Paddle docs/OpenAPI. [VERIFIED: lib/paddle/http.ex] [VERIFIED: .planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md] [CITED: https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
