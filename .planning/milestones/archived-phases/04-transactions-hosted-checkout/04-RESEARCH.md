# Phase 4: Transactions & Hosted Checkout - Research

**Researched:** 2026-04-28
**Domain:** Paddle transaction creation for hosted checkout in an Elixir SDK
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Public API Shape
- **D-01:** Keep the established resource-module pattern and expose Phase 4 through `Paddle.Transactions.create/2`.
- **D-02:** Do not introduce a checkout-specific wrapper type or tuple shape for the happy path. Success should return `{:ok, %Paddle.Transaction{}}`.
- **D-03:** The primary documented access path for the hosted checkout URL is `transaction.checkout.url`, so the `checkout` field must be represented in a shape that supports Elixir dot access.

### Transaction Input Contract
- **D-04:** Use a curated attrs map, not a near-pass-through Paddle payload.
- **D-05:** Require `customer_id`, `address_id`, and a non-empty `items` list for the public Phase 4 create path.
- **D-06:** `items` should be constrained to the recurring catalog-item shape for this phase: `%{price_id: ..., quantity: ...}`.
- **D-07:** Support only a very small optional allowlist beyond the required fields: `custom_data` and `checkout.url`.
- **D-08:** Omit broader transaction fields from the public contract for now, especially invoice/manual-collection fields, discounts, billing period controls, non-catalog pricing, and other raw-Paddle transaction branches.

### Billing Lifecycle Strictness
- **D-09:** Phase 4's main public path is strict and ready-oriented: it represents an existing customer plus existing address flowing into an automatically collected recurring transaction.
- **D-10:** Do not make `create/2` polymorphic between draft and ready flows. Missing `customer_id` or `address_id` should not silently produce a different lifecycle.
- **D-11:** If draft checkout support is added later, it should be a separately named path rather than a boolean flag or hidden mode on `create/2`.

### Response Modeling And DX
- **D-12:** Introduce `%Paddle.Transaction{}` as the primary entity for Phase 4, preserving `raw_data` like earlier resource structs.
- **D-13:** Model `checkout` in a way that makes `transaction.checkout.url` work naturally and predictably; a tiny nested struct is preferred over a string-key map.
- **D-14:** Keep the entity-centric return shape as the canonical contract. Any future helper like `Paddle.Transaction.checkout_url/1` would be additive sugar, not the primary API.

### Validation And Boundary Discipline
- **D-15:** Preserve the existing boundary style from earlier phases: accept `map | keyword`, normalize keys into the SDK's snake_case vocabulary, and keep local validation lightweight.
- **D-16:** Local validation should stop at stable boundary checks: required IDs present and nonblank, attrs container valid, `items` present and non-empty, and item entries shaped like `%{price_id, quantity}`.
- **D-17:** Leave deeper billing/business rules to Paddle, including recurring interval compatibility, approved checkout domain rules, and checkout-link environment configuration.

### Decision-Making Preference
- **D-18:** Favor decisive, researched defaults for SDK ergonomics and architecture. Only surface future user choices when the tradeoff is meaningfully impactful to product direction or public API stability.
- **D-19:** Within this phase, default toward least surprise, coherent Elixir resource-module patterns, and a single obvious happy path rather than exposing all upstream API branches.

### the agent's Discretion
- Exact first-pass field list for `%Paddle.Transaction{}` beyond the must-have fields for this phase.
- Whether `checkout` is a tiny `%Paddle.Transaction.Checkout{}` struct or another atom-keyed shape that still guarantees `transaction.checkout.url`.
- Whether unknown attrs are ignored or rejected explicitly, so long as the public contract stays curated and predictable.
- Whether a private normalization seam is added now to make a later `create_draft_checkout/2` expansion straightforward.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TXN-01 | Create recurring transactions mapping to hosted checkouts. | Implement `Paddle.Transactions.create/2` over `POST /transactions` with a strict ready-transaction body: `customer_id`, `address_id`, `items`, plus optional `custom_data` and `checkout.url`; keep `collection_mode` automatic for the hosted-checkout lane. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/create-transaction] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |
| TXN-02 | Return hosted checkout URLs from transaction creation. | Model `%Paddle.Transaction{checkout: %Paddle.Transaction.Checkout{url: ...}}` so the supported access path is `transaction.checkout.url`, and populate it in a transaction-specific builder because `Paddle.Http.build_struct/2` is shallow. [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout] [VERIFIED: lib/paddle/http.ex] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 4 should stay small and follow the Phase 3 resource pattern: add `%Paddle.Transaction{}`, add a tiny `%Paddle.Transaction.Checkout{}`, and expose one public function `Paddle.Transactions.create/2` that unwraps Paddle’s `"data"` envelope locally and returns `{:ok, %Paddle.Transaction{}}`. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/customers/addresses.ex] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/about/success-responses]

The main implementation wrinkle is nested checkout mapping. Paddle documents `checkout.url` as the hosted payment link for automatically collected transactions, but the repo’s shared mapper only copies top-level string keys directly into a struct and leaves nested maps untouched. If Phase 4 reuses `Paddle.Http.build_struct/2` without a transaction-specific post-processing step, `transaction.checkout.url` will not be a reliable contract. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout] [VERIFIED: lib/paddle/http.ex]

Hosted checkout also has one non-code prerequisite that the planner should treat as real work: Paddle requires a default payment link, and live environments require an approved domain for checkout payment links; `checkout.url` can override the domain only when that domain is approved. The SDK should not try to validate that locally beyond shape/allowlist checks, but the plan should call it out as a manual integration dependency. [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]

**Primary recommendation:** implement a thin `Paddle.Transactions.create/2` resource that builds a strict ready transaction body, explicitly sets automatic collection semantics, maps the top-level entity with `Paddle.Http.build_struct/2`, then replaces `checkout` with `%Paddle.Transaction.Checkout{}` so `transaction.checkout.url` is guaranteed. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/customers.ex] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transaction request shaping | API / Backend | — | The SDK owns the public Elixir contract, attrs normalization, allowlisting, and path selection before sending `/transactions` requests. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/customers/addresses.ex] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |
| Transaction lifecycle state selection | API / Backend | Paddle API | Ready vs. draft depends on whether `customer_id`, `address_id`, and `items` are supplied; the SDK must enforce the ready-only public path and let Paddle own deeper billing rules. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/create-transaction] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |
| Hosted checkout URL generation | Paddle API | Browser / Client | Paddle generates `checkout.url`; the SDK returns it, and the caller later opens or redirects to it. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout] |
| Nested checkout struct hydration | API / Backend | — | The repo’s shared struct mapper is shallow, so the SDK layer must convert the nested checkout payload into a dot-accessible Elixir shape. [VERIFIED: lib/paddle/http.ex] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |
| Payment-link domain configuration | Paddle Dashboard / External Service | API / Backend | Domain approval and default payment-link setup live outside the repo; the SDK can accept `checkout.url`, but Paddle enforces whether it is valid. [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req` | `0.5.17` (published 2026-01-05) | HTTP execution, JSON request bodies, JSON response decoding | Already installed, current in `mix.lock`, and already used at the transport boundary for all existing resource modules. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info req] [CITED: https://hex.pm/packages/req/versions] |
| `telemetry` | `1.4.1` (published 2026-03-09) | Existing HTTP instrumentation | Already pinned and already attached to `%Paddle.Client{}`; Phase 4 should reuse it without adding a second instrumentation path. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: lib/paddle/client.ex] [VERIFIED: mix hex.info telemetry] [CITED: https://hex.pm/packages/telemetry/versions] |
| `Paddle.Http.build_struct/2` | existing local function | Top-level typed entity mapping with `raw_data` preservation | Existing entity modules already depend on it, and it matches the repo’s forward-compatibility strategy. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/customer.ex] [VERIFIED: lib/paddle/address.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` | `1.4.4` (published 2024-07-26) | Test-side JSON body decoding through Req/Jason integration | Use in request-body assertions and keep relying on Req’s JSON handling rather than introducing a second serializer. [VERIFIED: mix.lock] [VERIFIED: test/paddle/customers_test.exs] [VERIFIED: mix hex.info jason] [CITED: https://hex.pm/packages/jason/versions] |
| `%Paddle.Transaction.Checkout{}` | new local struct | Guarantees `transaction.checkout.url` dot access | Use only for the stable nested `checkout` surface; leave broader nested transaction payloads as plain maps for now. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [VERIFIED: lib/paddle/http.ex] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `%Paddle.Transaction.Checkout{}` | Plain nested map | Reject it for Phase 4 because the locked API contract is `transaction.checkout.url`, and a plain string-key map does not satisfy that DX reliably. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [VERIFIED: lib/paddle/http.ex] |
| Curated `Paddle.Transactions.create/2` | Near-pass-through transaction payload | Reject it because the phase scope explicitly excludes invoice/manual-collection and non-catalog branches. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |
| Relying on Paddle’s default `collection_mode` | Explicitly sending `"collection_mode": "automatic"` internally | Prefer the explicit internal constant because it makes the hosted-checkout intent obvious and keeps future manual-collection work from accidentally reusing this path. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |

**Installation:** No new runtime dependencies are needed for Phase 4; run `mix deps.get` only if the local environment is not hydrated already. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Version verification:** Verified locally with `mix hex.info req`, `mix hex.info telemetry`, and `mix hex.info jason`; publish dates cross-checked against Hex package version pages. [VERIFIED: mix hex.info req] [VERIFIED: mix hex.info telemetry] [VERIFIED: mix hex.info jason] [CITED: https://hex.pm/packages/req/versions] [CITED: https://hex.pm/packages/telemetry/versions] [CITED: https://hex.pm/packages/jason/versions]

## Architecture Patterns

### System Architecture Diagram

```text
caller
  -> Paddle.Transactions.create/2
  -> attrs normalization + required-id/item checks + curated allowlist
  -> POST /transactions
  -> Paddle.Http.request/4
  -> Paddle API
     -> ready transaction created when customer_id + address_id + items are present
     -> checkout.url generated for automatic collection
  -> transaction-specific builder
     -> Paddle.Http.build_struct(Paddle.Transaction, data)
     -> nested checkout map -> %Paddle.Transaction.Checkout{}
  -> {:ok, %Paddle.Transaction{checkout: %Paddle.Transaction.Checkout{url: ...}}}
     | {:error, %Paddle.Error{} | transport_exception}
```

### Recommended Project Structure
```text
lib/paddle/
├── transaction.ex              # %Paddle.Transaction{}
├── transactions.ex             # create/2 resource module
└── transaction/
   └── checkout.ex              # %Paddle.Transaction.Checkout{}

test/paddle/
├── transaction_test.exs        # struct field contract
└── transactions_test.exs       # request/response, validation, error handling
```

### Pattern 1: Thin Resource Module Over Existing Transport
**What:** Keep envelope handling in `Paddle.Transactions` instead of changing `Paddle.Http.request/4`. [VERIFIED: lib/paddle/http.ex]
**When to use:** For the single Phase 4 create path. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
**Example:**
```elixir
# Source: current resource-module pattern + Paddle transaction create docs
def create(%Paddle.Client{} = client, attrs) do
  with {:ok, normalized} <- normalize_attrs(attrs),
       :ok <- validate_transaction_attrs(normalized),
       body <- build_create_body(normalized),
       {:ok, %{"data" => data}} when is_map(data) <-
         Paddle.Http.request(client, :post, "/transactions", json: body) do
    {:ok, build_transaction(data)}
  end
end
```

### Pattern 2: Shallow Shared Mapper Plus Explicit Nested Checkout Mapping
**What:** Use `Paddle.Http.build_struct/2` for top-level fields, then replace `checkout` with a small nested struct in a private helper because the shared mapper does not recurse. [VERIFIED: lib/paddle/http.ex]
**When to use:** In every successful transaction entity response. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
**Example:**
```elixir
# Source: lib/paddle/http.ex + hosted checkout contract
defp build_transaction(data) do
  transaction = Paddle.Http.build_struct(Paddle.Transaction, data)
  checkout = if is_map(data["checkout"]), do: Paddle.Http.build_struct(Paddle.Transaction.Checkout, data["checkout"]), else: nil
  %{transaction | checkout: checkout}
end
```

### Pattern 3: Curated Body Builder With Internal Automatic Collection Constant
**What:** The public function should accept only the curated Phase 4 attrs, but the private body builder may add `"collection_mode" => "automatic"` to keep the path semantically narrow. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
**When to use:** In `build_create_body/1` only. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]

### Recommended Public API

```elixir
Paddle.Transactions.create(client,
  customer_id: "ctm_...",
  address_id: "add_...",
  items: [%{price_id: "pri_...", quantity: 1}],
  custom_data: %{"source" => "accrue"},
  checkout: %{url: "https://approved.example.com/checkout"}
)
```

This API should be the only public transaction entry point in Phase 4. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]

### First-Pass Struct Fields

#### `%Paddle.Transaction{}`
| Field | Include | Reason |
|------|---------|--------|
| `:id`, `:status`, `:customer_id`, `:address_id`, `:business_id`, `:custom_data`, `:currency_code`, `:origin`, `:subscription_id`, `:invoice_number`, `:collection_mode`, `:items`, `:details`, `:payments`, `:checkout`, `:created_at`, `:updated_at`, `:billed_at`, `:revised_at`, `:raw_data` | yes | These are stable top-level transaction entity fields in the current API reference and are enough for the hosted-checkout slice without trying to model every nested subdocument. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [VERIFIED: lib/paddle/http.ex] |

#### `%Paddle.Transaction.Checkout{}`
| Field | Include | Reason |
|------|---------|--------|
| `:url`, `:raw_data` | yes | `url` is the only locked Phase 4 checkout field, and `raw_data` keeps the nested payload forward-compatible. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |

### Endpoint And Mapping Boundaries

| Function | Method + Path | Request allowlist | Success mapping |
|----------|---------------|-------------------|-----------------|
| `Paddle.Transactions.create/2` | `POST /transactions` [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] | Required: `customer_id`, `address_id`, `items`; Optional: `custom_data`, `checkout.url`; Internal constant: `collection_mode = "automatic"`. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] | `%{"data" => data}` -> `Paddle.Http.build_struct(Paddle.Transaction, data)` -> replace nested `checkout` with `%Paddle.Transaction.Checkout{}`. [VERIFIED: lib/paddle/http.ex] |

### Anti-Patterns to Avoid
- **Do not broaden Phase 4 into a raw transaction wrapper:** invoice fields, billing details, discounts, and non-catalog prices are explicitly out of scope here. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
- **Do not modify `Paddle.Http.request/4` to unwrap `"data"` automatically:** existing resource modules already do local envelope handling, and list endpoints depend on preserving `"meta"`. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/customers/addresses.ex]
- **Do not rely on a string-key checkout map for the public contract:** it breaks the locked `transaction.checkout.url` access path. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
- **Do not locally reimplement Paddle billing rules like recurring-interval compatibility or domain approval:** keep local validation stable and let Paddle reject business-invalid requests. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Top-level transaction mapping | Per-field manual copy logic for every response | `Paddle.Http.build_struct/2` plus a narrow nested-checkout post-step | The repo already has the top-level mapper and `raw_data` convention; only `checkout` needs special handling. [VERIFIED: lib/paddle/http.ex] |
| Hosted checkout URL creation | Custom `?_ptxn=` URL assembly | Paddle’s returned `checkout.url` | Paddle documents that it generates the payment link from the approved/default domain plus the transaction identifier. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout] |
| Broad transaction schema validation | Local billing-rule engine | Lightweight boundary validation + Paddle API validation | Recurring interval compatibility, approved checkout domains, and other transaction rules are upstream billing concerns. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] |
| New transport abstraction | Transaction-specific HTTP wrapper | Existing `Paddle.Http.request/4` | Current transport already normalizes API errors vs transport exceptions consistently across the repo. [VERIFIED: lib/paddle/http.ex] [VERIFIED: test/paddle/http_test.exs] |

**Key insight:** Phase 4 is mostly a boundary-design problem, not a transport problem: the planner should spend effort on body curation, nested checkout hydration, and tests for ready-only semantics rather than on new infrastructure. [VERIFIED: lib/paddle/http.ex] [VERIFIED: lib/paddle/customers.ex] [VERIFIED: test/paddle/customers_test.exs] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Shallow Mapping Breaks `transaction.checkout.url`
**What goes wrong:** The transaction struct is built, but `checkout` stays a plain map or is dropped entirely, so callers cannot rely on dot access. [VERIFIED: lib/paddle/http.ex]
**Why it happens:** `Paddle.Http.build_struct/2` only copies top-level keys that already exist on the target struct and does not recurse into nested maps. [VERIFIED: lib/paddle/http.ex]
**How to avoid:** Add a private `build_transaction/1` helper that hydrates `checkout` explicitly after the top-level struct build. [VERIFIED: lib/paddle/http.ex] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
**Warning signs:** Tests only assert `%Paddle.Transaction{}` exists and never assert `transaction.checkout.url`. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 2: Missing Customer Or Address Quietly Produces Draft Behavior
**What goes wrong:** A permissive request builder allows callers to omit `customer_id` or `address_id`, and Paddle creates a `draft` transaction instead of the ready hosted-checkout flow this phase is meant to expose. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/create-transaction]
**Why it happens:** Paddle uses supplied fields to determine lifecycle state, and `items` alone are enough for draft creation. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction]
**How to avoid:** Fail fast locally on blank or missing `customer_id`, `address_id`, or `items`, and keep draft checkout as a future separately named API. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
**Warning signs:** Tests or examples that successfully create transactions with `items` only. [CITED: https://developer.paddle.com/build/transactions/create-transaction]

### Pitfall 3: Hosted Checkout Works In Tests But Not In Live
**What goes wrong:** The SDK returns a transaction, but the returned checkout link is unusable in production because the account has no default payment link or the requested override domain is not approved. [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]
**Why it happens:** Checkout-link configuration lives in the Paddle dashboard, not in the repo. [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout]
**How to avoid:** Call out the dashboard prerequisite in the plan and keep adapter-backed tests separate from live-account verification. [CITED: https://developer.paddle.com/build/transactions/create-transaction]
**Warning signs:** Sandbox adapter tests pass, but manual browser validation fails only in live. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]

### Pitfall 4: Unsupported Recurring Item Mixes Leak Through Local Examples
**What goes wrong:** Example payloads or fixtures imply that any recurring items can be mixed together, but Paddle requires recurring items on a transaction to share the same billing interval. [CITED: https://developer.paddle.com/build/transactions/create-transaction]
**Why it happens:** The Phase 4 public API intentionally keeps local validation lightweight and does not inspect catalog pricing metadata. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md]
**How to avoid:** Keep fixtures simple, document that deeper billing validation is remote, and assert that upstream validation errors propagate as `%Paddle.Error{}`. [VERIFIED: test/paddle/customers_test.exs] [CITED: https://developer.paddle.com/build/transactions/create-transaction]
**Warning signs:** Integration tests fail with 4xx validation errors when item intervals differ. [CITED: https://developer.paddle.com/build/transactions/create-transaction]

## Code Examples

Verified patterns from official sources and the current codebase:

### Ready Transaction Request Shape
```elixir
# Source: Paddle create-transaction docs, adapted to the repo's public API
attrs = %{
  customer_id: "ctm_01...",
  address_id: "add_01...",
  items: [%{price_id: "pri_01...", quantity: 1}],
  custom_data: %{"source" => "accrue"},
  checkout: %{url: "https://approved.example.com/checkout"}
}
```

### Resource Module Success Mapping
```elixir
# Source: lib/paddle/customers.ex + lib/paddle/http.ex pattern
with {:ok, %{"data" => data}} <- Paddle.Http.request(client, :post, "/transactions", json: body) do
  {:ok, build_transaction(data)}
end
```

### Nested Checkout Struct
```elixir
# Source: hosted-checkout contract from 04-CONTEXT.md + Paddle transaction docs
defmodule Paddle.Transaction.Checkout do
  defstruct [:url, :raw_data]
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `transaction.checkout.url` was response-only | `transaction.checkout.url` is writable on create/update for approved domains | 2023-08-17 changelog entry for API v1. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] | Phase 4 can safely expose optional caller-supplied `checkout.url` without inventing a custom override mechanism. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] |
| Checkout-created transactions were the default mental model | Paddle documents explicit API-created draft or ready transactions that can then be passed to checkout | Current build docs as crawled in 2026. [CITED: https://developer.paddle.com/build/transactions/create-transaction] | The SDK should expose direct transaction creation rather than forcing all hosted-checkout flows through Paddle.js-first patterns. [CITED: https://developer.paddle.com/build/transactions/create-transaction] |

**Deprecated/outdated:**
- `invoice_id` on transaction responses is documented as deprecated and scheduled for removal in the next API version, so planner work should not depend on it beyond optional raw-data preservation. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction]

## Assumptions Log

All material claims in this research were verified or cited in this session. No user confirmation is required before planning. [VERIFIED: this document]

## Open Questions (RESOLVED)

1. **Should one manual live-account verification step be required in the execution plan?**
   - Resolution: no. Phase 4 should require adapter-backed automated verification for request shaping, typed response mapping, and `transaction.checkout.url`, while any real checkout-opening step remains an explicit manual-only follow-up outside the required execution path. [VERIFIED: test/paddle/customers_test.exs] [VERIFIED: test/paddle/customers/addresses_test.exs] [VERIFIED: .planning/ROADMAP.md] [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout]
   - Why: Paddle dashboard payment-link and approved-domain setup are external prerequisites that the repo cannot automate, so making live checkout opening mandatory would turn an infrastructure dependency into a false blocker for SDK code completion. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]
   - Planning impact: required work stays focused on code and adapter tests; the optional manual verification is tracked separately in `04-VALIDATION.md`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and run tests | ✓ | `1.19.5` | — [VERIFIED: `elixir -e 'IO.puts(System.version())'`] |
| Mix | Dependency resolution and `mix test` | ✓ | `1.19.5` | — [VERIFIED: `mix run -e 'IO.puts(System.version())'`] |
| Paddle account checkout configuration | Real hosted-checkout URL behavior outside adapter tests | not locally verifiable | — | Use adapter-backed tests for code correctness; perform dashboard/manual verification separately. [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] |

**Missing dependencies with no fallback:**
- None for planning or code-level implementation. [VERIFIED: this repository state]

**Missing dependencies with fallback:**
- Real Paddle dashboard configuration is outside the repo, but adapter-backed tests cover the SDK contract until a manual integration check is scheduled. [VERIFIED: test/paddle/customers_test.exs] [VERIFIED: test/paddle/customers/addresses_test.exs] [CITED: https://developer.paddle.com/build/transactions/create-transaction]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `%Paddle.Client{}` already sends Bearer auth and the `Paddle-Version` header through Req; Phase 4 should keep using that boundary. [VERIFIED: lib/paddle/client.ex] |
| V3 Session Management | no | This SDK path is stateless request/response code and does not manage browser or server sessions. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | no | Authorization remains external to this library; Phase 4 should not invent per-user access logic inside the SDK. [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/paddle/client.ex] |
| V5 Input Validation | yes | Keep lightweight local validation for IDs, attrs container shape, item shape, and optional `checkout.url` nesting; defer business rules to Paddle. [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |
| V6 Cryptography | no | The transaction path adds no custom cryptography; reuse the existing HTTPS/Bearer transport boundary. [VERIFIED: lib/paddle/client.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller injects unsupported transaction fields into the public API | Tampering | Use explicit allowlists and ignore or reject unknown keys consistently rather than forwarding raw payloads. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |
| Caller supplies an unapproved checkout domain | Tampering | Allow only nested `checkout.url` at the SDK boundary and rely on Paddle’s approved-domain enforcement for the actual business rule. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains] [VERIFIED: .planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md] |
| Wrong customer/address identifiers create or attempt to bill the wrong entity | Tampering | Validate nonblank IDs locally and preserve `%Paddle.Error{}` propagation for upstream validation failures. [VERIFIED: lib/paddle/error.ex] [VERIFIED: test/paddle/customers_test.exs] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |

## Sources

### Primary (HIGH confidence)
- `lib/paddle/http.ex` - current transport and struct-building constraints. [VERIFIED: lib/paddle/http.ex]
- `lib/paddle/client.ex` - existing auth/header/instrumentation boundary. [VERIFIED: lib/paddle/client.ex]
- `lib/paddle/customers.ex` and `lib/paddle/customers/addresses.ex` - established resource-module pattern to mirror. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/customers/addresses.ex]
- `test/paddle/customers_test.exs`, `test/paddle/customers/addresses_test.exs`, `test/paddle/http_test.exs` - adapter-based testing pattern and existing tuple/error expectations. [VERIFIED: test/paddle/customers_test.exs] [VERIFIED: test/paddle/customers/addresses_test.exs] [VERIFIED: test/paddle/http_test.exs]
- https://developer.paddle.com/api-reference/transactions/create-transaction - current transaction request/response contract. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction]
- https://developer.paddle.com/build/transactions/create-transaction - current hosted-checkout-oriented transaction flow and recurring-item constraints. [CITED: https://developer.paddle.com/build/transactions/create-transaction]
- https://developer.paddle.com/build/transactions/pass-transaction-checkout - current `checkout.url` usage guidance. [CITED: https://developer.paddle.com/build/transactions/pass-transaction-checkout]
- https://developer.paddle.com/changelog/2023/checkout-domains - current writeable `checkout.url` behavior and approved-domain rule. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]
- https://developer.paddle.com/api-reference/about/success-responses - success envelope semantics. [CITED: https://developer.paddle.com/api-reference/about/success-responses]
- https://hex.pm/packages/req/versions, https://hex.pm/packages/telemetry/versions, https://hex.pm/packages/jason/versions - package version and publish-date verification. [CITED: https://hex.pm/packages/req/versions] [CITED: https://hex.pm/packages/telemetry/versions] [CITED: https://hex.pm/packages/jason/versions]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: this research scope]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research scope]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the repo already pins the stack, and current versions were verified against Hex. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info req] [VERIFIED: mix hex.info telemetry] [VERIFIED: mix hex.info jason]
- Architecture: HIGH - the repo has an established resource-module and transport pattern, and the Paddle transaction contract is current in the official docs. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/http.ex] [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction]
- Pitfalls: HIGH - each listed pitfall is grounded either in current repo behavior or explicit Paddle documentation. [VERIFIED: lib/paddle/http.ex] [CITED: https://developer.paddle.com/build/transactions/create-transaction] [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28 for planning purposes, or sooner if Paddle updates transaction or checkout semantics. [CITED: https://developer.paddle.com/changelog/2023/checkout-domains]
