# Phase 5: Subscriptions Management - Research

**Researched:** 2026-04-29
**Domain:** Paddle subscription get/list/cancel for an Elixir SDK
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Public API Surface (Strict Mutation Scope)
- **D-01:** Phase 5 ships exactly three public functions on `Paddle.Subscriptions`: `get/2`, `list/2`, `cancel/2`, plus `cancel_immediately/2`. No other subscription mutations are exposed in Phase 5.
- **D-02:** Mirror the established resource-module pattern from Phase 3/4. Module path is `Paddle.Subscriptions` (sibling of `Paddle.Customers`, `Paddle.Transactions`), not nested under `Paddle.Customers`.
- **D-03:** Defer subscription update, pause, resume, activate, charge, preview-update, and update-payment-method-transaction to v0.2 or later.

#### Cancel Semantics (Two Named Functions)
- **D-04:** Expose end-of-period and immediate cancellation as **two separately named public functions**:
  - `Paddle.Subscriptions.cancel/2` — end-of-period (Paddle's `effective_from: "next_billing_period"`)
  - `Paddle.Subscriptions.cancel_immediately/2` — immediate (Paddle's `effective_from: "immediately"`)
- **D-05:** Extends Phase 4 D-10/D-11 stance: separately named paths over polymorphic flags. Both modes are destructive and irreversible per Paddle docs.
- **D-06:** Both functions return `{:ok, %Paddle.Subscription{}}` on success.
- **D-07:** Both functions share a private `do_cancel/3` helper that posts to `/subscriptions/{id}/cancel` with the appropriate `effective_from` value. No public arity-3 cancel.
- **D-08:** Future Paddle additions (e.g., scheduled cancel at a specific timestamp) get their own separately named functions.

#### List Scoping (Generic Filter-Based, Not Customer-Scoped)
- **D-09:** Expose listing as `Paddle.Subscriptions.list(client, params \\ [])` — a single top-level function that accepts a curated filter map.
- **D-10:** Do **not** mirror Phase 3's `Paddle.Customers.Addresses.list/3` positional-customer-id pattern. Subscriptions are NOT a child resource of customers in Paddle's API.
- **D-11:** "List a customer's subscriptions" (SUB-02) is satisfied by passing `customer_id:` in the params map.
- **D-12:** Allowlist for `list/2` params:
  ```
  ~w(id customer_id address_id price_id status
     scheduled_change_action collection_mode
     next_billed_at order_by after per_page)
  ```
- **D-13:** Response shape: `{:ok, %Paddle.Page{data: [%Paddle.Subscription{}, ...], meta: ...}}`.
- **D-14:** Do NOT introduce a `list_for_customer/3` convenience wrapper.

#### Subscription Entity Struct
- **D-15:** `%Paddle.Subscription{}` is a flat top-level struct in `lib/paddle/subscription.ex`. Preserve `:raw_data`.
- **D-16:** Field list (snake_case atom keys):
  ```
  :id, :status, :customer_id, :address_id, :business_id,
  :currency_code, :collection_mode, :custom_data, :items,
  :scheduled_change, :management_urls,
  :current_billing_period, :billing_cycle, :billing_details,
  :discount, :next_billed_at, :started_at, :first_billed_at,
  :paused_at, :canceled_at, :created_at, :updated_at,
  :import_meta, :raw_data
  ```
- **D-17:** Timestamps stay as ISO8601 strings. No DateTime parsing in Phase 5.

#### Nested Struct Promotion (Disciplined Carve-Outs)
- **D-18:** Promote exactly **two** nested objects:
  - `%Paddle.Subscription.ScheduledChange{}` — fields `:action, :effective_at, :resume_at, :raw_data`.
  - `%Paddle.Subscription.ManagementUrls{}` — fields `:update_payment_method, :cancel, :raw_data`.
- **D-19:** `:scheduled_change` is `nil` when no change scheduled. `:management_urls` may be `nil` for non-portal flows.
- **D-20:** Do NOT promote `current_billing_period`, `billing_cycle`, `billing_details`, `items`, `discount`, `next_transaction`, `recurring_transaction_details`, `consent_requirements`, or `import_meta`.
- **D-21:** Action enum strings stay as strings — no atom conversion.

#### Nested Struct Wiring
- **D-22:** Per-resource post-processing inside `Paddle.Subscriptions` after `build_struct/2`. Mirror `lib/paddle/transactions.ex:35-45`. Do NOT extend `Paddle.Http.build_struct/2`.

#### Validation And Boundary Discipline
- **D-23:** Carry forward Phase 3 D-13/D-14/D-15: accept `map | keyword`, normalize via `Paddle.Internal.Attrs.normalize`, allowlist-filter, light boundary checks only.
- **D-24:** Path encoding via `URI.encode(id, &URI.char_unreserved?/1)` per `lib/paddle/customers.ex:48`.

#### Decision-Making Preference
- **D-25:** Continue Phase 3/4's bias toward decisive, researched defaults.

### Claude's Discretion
- Internal helper-module organization within `Paddle.Subscriptions`.
- Test fixture shape for the new entity.
- Whether `do_cancel/3`'s `effective_from` parameter is a string or atom-then-stringified internally.
- Exact docstring wording, typespec choices, and module ordering.

### Deferred Ideas (OUT OF SCOPE)
- `Paddle.Subscriptions.update/3`, `pause/3`, `resume/3`, `activate/2`, `charge/3`, `preview_update/3`, `get_update_payment_method_transaction/2`, `cancel_at/3`, `remove_scheduled_cancellation/2`.
- Public helpers like `Paddle.Subscription.scheduled_to_cancel?/1`.
- `%Paddle.Subscription.CurrentBillingPeriod{}`, `%Paddle.Subscription.BillingCycle{}`, `%Paddle.Subscription.Item{}` typed structs.
- Cross-cutting ISO8601 → `DateTime` parsing.
- Typed access for `:next_transaction`, `:recurring_transaction_details`, `:consent_requirements`.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **SUB-01** | Fetch canonical subscription state from Paddle. | Implement `Paddle.Subscriptions.get/2` against `GET /subscriptions/{subscription_id}`. Unwrap `"data"` envelope locally and post-process `scheduled_change`/`management_urls` into typed nested structs. [CITED: https://developer.paddle.com/api-reference/subscriptions/get-subscription] [VERIFIED: /tmp/paddle-openapi.yaml lines 10495-10668] [VERIFIED: lib/paddle/customers.ex:18-24] |
| **SUB-02** | List subscriptions for a customer. | Implement `Paddle.Subscriptions.list/2` against `GET /subscriptions` with curated query allowlist that includes `customer_id`. Return `%Paddle.Page{}` with mapped subscription structs. [CITED: https://developer.paddle.com/api-reference/subscriptions/list-subscriptions] [VERIFIED: /tmp/paddle-openapi.yaml lines 9785-10491] [VERIFIED: lib/paddle/customers/addresses.ex:29-41] |
| **SUB-03** | Cancel subscription with end-of-period and immediate cancellation semantics. | Implement two named functions `cancel/2` and `cancel_immediately/2` that share private `do_cancel/3` against `POST /subscriptions/{subscription_id}/cancel` with body `{"effective_from": "next_billing_period" \| "immediately"}`. [CITED: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription] [VERIFIED: /tmp/paddle-openapi.yaml lines 10914-11144] |
</phase_requirements>

## Summary

Phase 5 is mostly a boundary-design problem with zero new infrastructure. The closest analog already in the repo is `lib/paddle/transactions.ex`, not `customers.ex` — `transactions.ex` is the single existing precedent for **per-resource post-processing of a nested map into a typed struct after `Http.build_struct/2`**, which is the central pattern Phase 5 must replicate twice (once for `scheduled_change`, once for `management_urls`). [VERIFIED: lib/paddle/transactions.ex:35-45]

The list endpoint introduces a genuinely new pattern shape: a **top-level filter-based list** (no positional ID). Phase 3's `Customers.Addresses.list/3` is the structural analog (envelope unwrap + `Enum.map` of `build_struct/2` + `%Paddle.Page{}` wrap), but its function signature is `(client, customer_id, params)` whereas Phase 5 wants `(client, params)`. The `params` normalization helper (`normalize_params/1`) and the `params:` Req option transfer cleanly; only the path is fixed and the validate-customer-id step is removed. [VERIFIED: lib/paddle/customers/addresses.ex:29-41,74-83]

Cancellation is a `POST` to a sub-path with a small body (`{"effective_from": ...}`) and returns the **full updated subscription envelope**, not a `204 No Content`. Both `cancel/2` and `cancel_immediately/2` therefore share the same response-mapping path as `get/2` — the only divergence is the request body. The shared private `do_cancel/3` collapses both into one transport call site. [VERIFIED: /tmp/paddle-openapi.yaml lines 10914-11144]

**Primary recommendation:** Three plans, mirroring the Phase 4 plan split exactly (entity struct -> resource module -> tests), plus optionally a fourth for any nested-struct-specific tests if the planner wants to keep `subscription_test.exs` tight. Each plan reuses the established Phase 3/4 patterns with no new transport, telemetry, or attrs-normalization code.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Subscription request shaping | API / Backend | — | The SDK owns the public Elixir contract, params normalization, allowlisting, and path selection before sending `/subscriptions` requests. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/customers/addresses.ex] [CITED: https://developer.paddle.com/api-reference/subscriptions/get-subscription] |
| Subscription state mapping | API / Backend | — | Paddle returns `data` envelope plus paginated `meta`; Phase 5 owns the local unwrap and entity hydration. [VERIFIED: /tmp/paddle-openapi.yaml line 10944] [VERIFIED: lib/paddle/http.ex:17-28] |
| Nested struct hydration | API / Backend | — | `Paddle.Http.build_struct/2` is shallow; the resource layer must convert `scheduled_change` and `management_urls` maps into typed structs. [VERIFIED: lib/paddle/http.ex:17-28] [VERIFIED: lib/paddle/transactions.ex:35-45] |
| Cancel mode selection | API / Backend | — | The SDK selects `effective_from` based on which public function the caller invoked. Paddle owns the actual lifecycle transition. [CITED: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription] [VERIFIED: /tmp/paddle-openapi.yaml lines 27521-27534] |
| Customer portal link rendering | Browser / Client | API / Backend | Paddle returns `management_urls.cancel`; the browser eventually opens it. The SDK only surfaces the URL string. [VERIFIED: /tmp/paddle-openapi.yaml lines 21334-21358] |
| Subscription state lifecycle | Paddle API | — | Status transitions (`active` → `canceled`, scheduled-change creation, billing period boundaries) are owned by Paddle. The SDK does not enforce them locally. [CITED: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req` | `0.5.17` | HTTP execution, query encoding, JSON request/response | Already installed and used at the transport boundary by every existing resource module. No new dependency. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: lib/paddle/http.ex] |
| `telemetry` | `1.4.1` | Existing HTTP instrumentation | Already attached to `%Paddle.Client{}`; reused unchanged. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: lib/paddle/client.ex] |
| `Paddle.Http.request/4` | existing local function | Transport boundary returning `{:ok, body} \| {:error, %Paddle.Error{}} \| {:error, exception}` | Established pattern across customers/addresses/transactions. [VERIFIED: lib/paddle/http.ex:2-15] |
| `Paddle.Http.build_struct/2` | existing local function | Top-level field mapping with `raw_data` preservation | Used by every entity in the repo. Critical: it does NOT recurse into nested maps. [VERIFIED: lib/paddle/http.ex:17-28] |
| `Paddle.Internal.Attrs` | existing local module | `normalize/1`, `normalize_keys/1`, `allowlist/2` | Phase 5 reuses verbatim. [VERIFIED: lib/paddle/internal/attrs.ex] |
| `Paddle.Page` + `Paddle.Page.next_cursor/1` | existing local module | Pagination wrapper for list responses | `next_cursor/1` returns the entire `meta.pagination.next` string as-is (full URL or path) — consumers extract `after=` themselves. [VERIFIED: lib/paddle/page.ex:1-9] [VERIFIED: test/paddle/customers/addresses_test.exs:107] |

### Supporting (new local modules to add)

| Module | Purpose |
|--------|---------|
| `Paddle.Subscription` | Flat top-level entity struct mirroring `Paddle.Transaction`. [VERIFIED: lib/paddle/transaction.ex] |
| `Paddle.Subscription.ScheduledChange` | Tiny nested struct: `:action, :effective_at, :resume_at, :raw_data`. Mirrors `Paddle.Transaction.Checkout` precedent. [VERIFIED: lib/paddle/transaction/checkout.ex] |
| `Paddle.Subscription.ManagementUrls` | Tiny nested struct: `:update_payment_method, :cancel, :raw_data`. |
| `Paddle.Subscriptions` | Public resource module: `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`. Mirrors `Paddle.Customers` and `Paddle.Transactions` shape. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/transactions.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff / Decision |
|------------|-----------|---------------------|
| Per-resource nested-struct post-processing | Extend `Paddle.Http.build_struct/2` with a nested-fields keyword | Rejected by D-22. Keeps the shared mapper minimal and matches Phase 4's precedent. [VERIFIED: lib/paddle/transactions.ex:35-45] |
| Two named cancel functions | One `cancel/3` with `mode:` keyword | Rejected by D-04/D-05. Two named paths sidestep the Stripe-style footgun where `cancel` (immediate) and `update(cancel_at_period_end: true)` (end-of-period) get confused. [VERIFIED: .planning/phases/05-subscriptions-management/05-CONTEXT.md] |
| Top-level `Paddle.Subscriptions.list/2` | Nested `Paddle.Customers.Subscriptions.list/3` | Rejected by D-10/D-11. Paddle's URL is `/subscriptions`, not `/customers/{id}/subscriptions`. [VERIFIED: /tmp/paddle-openapi.yaml line 9785] |
| Atom action enum | String `"cancel" \| "pause" \| "resume"` | Rejected by D-21. Strings match existing precedent (status, collection_mode). [VERIFIED: lib/paddle/transaction.ex] |

**Installation:** No new runtime dependencies. [VERIFIED: mix.exs]

**Version verification:**
```bash
$ grep -E "req|telemetry|jason" mix.lock
# req: 0.5.17, telemetry: 1.4.1, jason: 1.4.4 (transitive via req)
```
All versions match Phase 4 research. [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
caller (with %Paddle.Client{})
  │
  ├─ Paddle.Subscriptions.get(client, subscription_id)
  │   ├─ validate_subscription_id(id)            (light boundary check)
  │   ├─ Paddle.Http.request(client, :get, "/subscriptions/#{encoded_id}")
  │   ├─ unwrap %{"data" => data} envelope locally
  │   ├─ Paddle.Http.build_struct(Paddle.Subscription, data)
  │   ├─ post-process: data["scheduled_change"] -> %Paddle.Subscription.ScheduledChange{} (or nil)
  │   ├─ post-process: data["management_urls"] -> %Paddle.Subscription.ManagementUrls{} (or nil)
  │   └─ {:ok, %Paddle.Subscription{...}}
  │
  ├─ Paddle.Subscriptions.list(client, params \\ [])
  │   ├─ normalize_params(params) -> {:ok, %{...}} | {:error, :invalid_params}
  │   ├─ Attrs.allowlist(params, @list_allowlist)
  │   ├─ Paddle.Http.request(client, :get, "/subscriptions", params: query)
  │   ├─ unwrap %{"data" => list, "meta" => meta} envelope locally
  │   ├─ Enum.map(data, &build_subscription/1)   (each item gets nested-struct post-processing)
  │   └─ {:ok, %Paddle.Page{data: [...], meta: meta}}
  │
  ├─ Paddle.Subscriptions.cancel(client, subscription_id)
  │   └─ do_cancel(client, subscription_id, "next_billing_period")
  │
  └─ Paddle.Subscriptions.cancel_immediately(client, subscription_id)
      └─ do_cancel(client, subscription_id, "immediately")

  do_cancel(client, id, effective_from):
   ├─ validate_subscription_id(id)
   ├─ Paddle.Http.request(client, :post, "/subscriptions/#{encoded_id}/cancel",
   │                      json: %{"effective_from" => effective_from})
   ├─ unwrap %{"data" => data} envelope locally
   └─ build_subscription(data) -> {:ok, %Paddle.Subscription{...}}
```

### Recommended Project Structure

```text
lib/paddle/
├── subscription.ex                         # %Paddle.Subscription{} flat entity (NEW)
├── subscriptions.ex                        # public resource module (NEW)
└── subscription/
   ├── scheduled_change.ex                  # %Paddle.Subscription.ScheduledChange{} (NEW)
   └── management_urls.ex                   # %Paddle.Subscription.ManagementUrls{} (NEW)

test/paddle/
├── subscription_test.exs                   # struct shape + nested struct shape tests (NEW)
└── subscriptions_test.exs                  # adapter-backed get/list/cancel/cancel_immediately tests (NEW)
```

### Pattern 1: Per-Resource Nested Struct Post-Processing

**What:** After `Paddle.Http.build_struct/2` returns the flat entity, replace nested map fields with typed structs in a private resource-module helper. The shared mapper does not recurse.
**When to use:** Every subscription mapping site (`get/2` response, each item in `list/2`, both cancel responses).
**Source:** `lib/paddle/transactions.ex:35-45` — the canonical existing precedent.

```elixir
# Source: lib/paddle/transactions.ex:35-45
defp build_transaction(data) when is_map(data) do
  transaction = Http.build_struct(Transaction, data)

  case data["checkout"] do
    checkout_data when is_map(checkout_data) ->
      %{transaction | checkout: Http.build_struct(Checkout, checkout_data)}

    _ ->
      transaction
  end
end
```

**Phase 5 application:**

```elixir
# In lib/paddle/subscriptions.ex
defp build_subscription(data) when is_map(data) do
  subscription = Http.build_struct(Subscription, data)

  subscription
  |> put_nested_struct(data, "scheduled_change", ScheduledChange)
  |> put_nested_struct(data, "management_urls", ManagementUrls)
end

defp put_nested_struct(subscription, data, key, module) do
  case Map.get(data, key) do
    nested when is_map(nested) ->
      Map.put(subscription, String.to_existing_atom(key), Http.build_struct(module, nested))

    _ ->
      subscription
  end
end
```

The two-helper split is one of the discretionary points (D-25 + Discretion section) — inlining both case branches is equally acceptable.

### Pattern 2: Top-Level Filter-Based List (NEW SHAPE FOR THIS REPO)

**What:** A list function whose only positional argument is the client, with all filtering done through a single allowlisted params map. The list path is fixed (`/subscriptions`).
**When to use:** `Paddle.Subscriptions.list/2`.
**Closest analog:** `Paddle.Customers.Addresses.list/3` for the **internal mechanics** (envelope unwrap, allowlist, `%Paddle.Page{}` mapping). The **signature shape** is new — no existing repo function takes only `(client, params)`.

```elixir
# In lib/paddle/subscriptions.ex
@list_allowlist ~w(id customer_id address_id price_id status
                   scheduled_change_action collection_mode
                   next_billed_at order_by after per_page)

def list(%Paddle.Client{} = client, params \\ []) do
  with {:ok, params} <- normalize_params(params),
       query <- Attrs.allowlist(params, @list_allowlist),
       {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
         Http.request(client, :get, "/subscriptions", params: query) do
    {:ok,
     %Paddle.Page{
       data: Enum.map(data, &build_subscription/1),
       meta: meta
     }}
  end
end
```

The `normalize_params/1` helper transfers verbatim from `lib/paddle/customers/addresses.ex:74-83`.

### Pattern 3: Two Named Cancel Functions Over a Shared Private Helper

**What:** Two public arity-2 functions that differ only in the `effective_from` value sent to Paddle. A single private `do_cancel/3` performs the actual transport call.
**When to use:** Phase 5 cancel paths only (D-07).

```elixir
# In lib/paddle/subscriptions.ex
def cancel(%Paddle.Client{} = client, subscription_id) do
  do_cancel(client, subscription_id, "next_billing_period")
end

def cancel_immediately(%Paddle.Client{} = client, subscription_id) do
  do_cancel(client, subscription_id, "immediately")
end

defp do_cancel(client, subscription_id, effective_from) do
  with :ok <- validate_subscription_id(subscription_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, cancel_path(subscription_id),
           json: %{"effective_from" => effective_from}) do
    {:ok, build_subscription(data)}
  end
end

defp cancel_path(subscription_id),
  do: "/subscriptions/#{encode_path_segment(subscription_id)}/cancel"
```

### Pattern 4: Subscription ID Validation + URI Encoding

**What:** Light boundary check (binary, non-blank) plus URI-encode-on-path-construction. Direct adaptation of customer-id/address-id pattern.
**Source:** `lib/paddle/customers.ex:38-48` and `lib/paddle/customers/addresses.ex:61-72,85`.

```elixir
defp validate_subscription_id(id) when is_binary(id) do
  if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
end

defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}

defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

### Anti-Patterns to Avoid

- **Do not extend `Paddle.Http.build_struct/2`** to recurse into nested maps. Locked by D-22; breaks the shallow-mapper contract every other entity depends on. [VERIFIED: lib/paddle/http.ex:17-28]
- **Do not introduce a polymorphic `cancel(client, id, mode)` public function.** Locked by D-04/D-05/D-07. The Stripe naming-collision footgun is the precise scenario this avoids.
- **Do not introduce `list_for_customer/3`.** Locked by D-14.
- **Do not parse timestamps into `DateTime`.** Locked by D-17. Cross-cutting concern for a future phase.
- **Do not promote `current_billing_period`, `billing_cycle`, `items`, etc., to typed structs.** Locked by D-20.
- **Do not assume `meta.pagination.next` is just the `after=` cursor value.** It is a full URL like `https://api.paddle.com/subscriptions?after=sub_...`. `Paddle.Page.next_cursor/1` returns it as-is. [VERIFIED: /tmp/paddle-openapi.yaml line 10479] [VERIFIED: lib/paddle/page.ex:4-9]
- **Do not validate scheduled-change-action enum values locally.** Pass them through; Paddle returns 4xx if invalid.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Top-level entity mapping | Per-field manual copy | `Paddle.Http.build_struct/2` | Already filters declared keys and preserves `raw_data`. [VERIFIED: lib/paddle/http.ex:17-28] |
| Nested struct hydration | New transport-layer recursion logic | Per-resource `build_subscription/1` helper mirroring `transactions.ex:35-45` | Matches Phase 4 precedent and keeps the shared mapper unchanged. [VERIFIED: lib/paddle/transactions.ex:35-45] |
| Attrs/params normalization | New regex/string-key helpers | `Paddle.Internal.Attrs.normalize/1`, `Attrs.normalize_keys/1`, `Attrs.allowlist/2` | Already covers `map \| keyword`, atom→string keys, and key filtering. [VERIFIED: lib/paddle/internal/attrs.ex] |
| Pagination container | A custom subscription page struct | `%Paddle.Page{}` + `Paddle.Page.next_cursor/1` | Phase 1 established this for all list endpoints. [VERIFIED: lib/paddle/page.ex] |
| HTTP error envelope | Per-resource error parsing | `Paddle.Http.request/4` returns `{:error, %Paddle.Error{}}` for non-2xx automatically | All other resource modules rely on this. [VERIFIED: lib/paddle/http.ex:9-10] [VERIFIED: lib/paddle/error.ex] |
| Path encoding | Manual URL escaping | `URI.encode(id, &URI.char_unreserved?/1)` | Already in use for customer and address IDs. [VERIFIED: lib/paddle/customers.ex:48] [VERIFIED: lib/paddle/customers/addresses.ex:85] |
| Test transport | A new mock library or behavior | `Req.new(adapter: fn request -> {request, response} end)` | Existing precedent in every resource test file. [VERIFIED: test/paddle/customers_test.exs:182-188] [VERIFIED: test/paddle/transactions_test.exs:369-375] |

**Key insight:** Phase 5 introduces zero new infrastructure. Every primitive needed (transport, error mapping, struct hydration, attr normalization, pagination, mock transport) exists. The only new code is **three structs, one resource module, and one test file** — all with strong line-level analogs.

## Common Pitfalls

### Pitfall 1: `Http.build_struct/2` is Shallow — Nested Structs Will Silently Become Maps
**What goes wrong:** `subscription.scheduled_change` ends up as `%{"action" => "cancel", ...}` (a string-keyed map) instead of `%Paddle.Subscription.ScheduledChange{}`. Calling code's `subscription.scheduled_change.effective_at` fails with `KeyError`.
**Why it happens:** `Http.build_struct/2` only filters and converts top-level keys; it never recurses. The `:scheduled_change` field on the struct gets the raw map. [VERIFIED: lib/paddle/http.ex:17-28]
**How to avoid:** Implement the `build_subscription/1` post-processor exactly like `Paddle.Transactions.build_transaction/1`. Wrap each nested-struct handoff in a `case data["..."] do nested when is_map(nested) -> ...` clause so the field stays `nil` when the upstream key is null. [VERIFIED: lib/paddle/transactions.ex:35-45]
**Warning signs:** Tests assert only `%Paddle.Subscription{}` exists, never `%Paddle.Subscription.ScheduledChange{...} = subscription.scheduled_change`.

### Pitfall 2: `meta.pagination.next` is a Full URL, Not Just an `after` Cursor
**What goes wrong:** Tests assert `Paddle.Page.next_cursor(page) == "sub_..."` and fail. Or callers feed the full URL into `Subscriptions.list(client, after: cursor)` and Paddle returns 422 because `after` should be just the ID.
**Why it happens:** Paddle returns the entire next-page URL like `https://api.paddle.com/subscriptions?after=sub_01hv8x29kz0t586xy6zn1a62ny`. `Paddle.Page.next_cursor/1` returns this string as-is. [VERIFIED: /tmp/paddle-openapi.yaml line 10479] [VERIFIED: lib/paddle/page.ex:4-9] [VERIFIED: test/paddle/customers/addresses_test.exs:107]
**How to avoid:** Document this in the resource module docstring. Tests should match on the full URL string in fixtures. Consumers extract `after=` themselves (this is consistent with how Phase 3's address listing already works).
**Warning signs:** A list test fixture sets `pagination.next` to a bare ID like `"sub_01"`.

### Pitfall 3: Cancellation Is Irreversible — Do Not Test Against Real API
**What goes wrong:** A naive integration test cancels a real subscription, and "you can't reinstate a canceled subscription" per Paddle docs. Re-running the test is impossible. [CITED: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription]
**Why it happens:** Cancel is a `POST` that mutates real billing state, not a read-only check.
**How to avoid:** Phase 5 tests use `Req.new(adapter: ...)` exclusively. No live-API tests. Document this in the test file (or in the resource module's `@moduledoc`) so future contributors do not add live tests.
**Warning signs:** Anyone proposing a `@tag :integration` block that hits `https://sandbox-api.paddle.com` for cancel.

### Pitfall 4: `scheduled_change` is Sometimes `nil`, Sometimes Populated — Tests Must Cover Both
**What goes wrong:** Tests cover only the end-of-period cancel response (where `scheduled_change` is populated) and miss the immediate-cancel response (where `scheduled_change` is `null` and the `:scheduled_change` field on the struct should be `nil`). Or vice versa.
**Why it happens:** Both modes return the full subscription envelope, but the field's null-or-populated state is the only structural difference. [VERIFIED: /tmp/paddle-openapi.yaml lines 10972 (immediate, scheduled_change: null) and 11206 (pause, scheduled_change: populated)]
**How to avoid:** Two separate fixture builders — `subscription_payload_active_with_scheduled_change/0` and `subscription_payload_canceled/0`. Cancel tests use the appropriate fixture.
**Warning signs:** A single test fixture used for both cancel modes.

### Pitfall 5: `management_urls.update_payment_method` Can Be `null` for Manual-Collection Subscriptions
**What goes wrong:** `subscription.management_urls.update_payment_method` is asserted as a non-empty string in tests, but for `collection_mode: "manual"` subscriptions Paddle returns `null`. [VERIFIED: /tmp/paddle-openapi.yaml lines 21340-21345]
**Why it happens:** `update_payment_method` is `anyOf: [string, null]` in the OpenAPI spec; `cancel` is always a string.
**How to avoid:** Test fixtures should include at least one case where `update_payment_method` is `null` and assert the field maps to `nil` on the struct. Document the null behavior in the struct module's `@moduledoc`.
**Warning signs:** All fixtures have non-null `update_payment_method`.

### Pitfall 6: Subscription Lock Errors Surface as Domain-Specific 4xx Codes
**What goes wrong:** Tests assume a 404 path for "missing" cases, but Paddle's subscription endpoints return rich error codes like `subscription_locked_pending_changes`, `subscription_locked_processing`, `subscription_locked_renewal`, and `subscription_update_when_canceled` for cancel-on-already-canceled or cancel-during-renewal-window scenarios. [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_pending_changes] [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_processing] [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_renewal] [CITED: https://developer.paddle.com/errors/subscriptions/subscription_update_when_canceled]
**Why it happens:** Paddle has a 30-minute lock window before renewal/processing during which mutations are rejected with these specific codes.
**How to avoid:** Phase 5 makes NO local validation of these states (D-23 — leave business validation to Paddle). Tests assert that these errors propagate as `%Paddle.Error{}` unchanged from `Paddle.Http.request/4`. The `code` field carries the snake_case error string.
**Warning signs:** Local code inspecting `subscription.status == "canceled"` before sending a cancel request — that's premature business validation.

### Pitfall 7: Boolean-Style Status Filter Ambiguity
**What goes wrong:** `status: "active"` works; `status: ["active", "trialing"]` is also valid for Paddle (comma-separated array). The SDK passes it through to `Req` which encodes lists as `status=active&status=trialing` — but Paddle expects `status=active,trialing`. [VERIFIED: /tmp/paddle-openapi.yaml lines 17219-17228 (`explode: false`)]
**Why it happens:** OpenAPI's `explode: false` means Paddle wants a single comma-separated string per query parameter, not repeated parameters.
**How to avoid:** **Phase 5 does not need to solve this.** D-12 lists `status` as a single allowlist key. Document in the moduledoc that callers passing multiple values should pre-join them (`status: "active,trialing"`). Defer multi-value support to a future phase if a real consumer asks for it. Adapter tests should pass single-value strings only.
**Warning signs:** A test passing `status: ["active", "trialing"]` and expecting it to "just work."

## Code Examples

Verified patterns from official sources and the current codebase.

### Subscription Entity Struct

```elixir
# Source: D-15/D-16 + lib/paddle/transaction.ex shape
defmodule Paddle.Subscription do
  defstruct [
    :id,
    :status,
    :customer_id,
    :address_id,
    :business_id,
    :currency_code,
    :collection_mode,
    :custom_data,
    :items,
    :scheduled_change,
    :management_urls,
    :current_billing_period,
    :billing_cycle,
    :billing_details,
    :discount,
    :next_billed_at,
    :started_at,
    :first_billed_at,
    :paused_at,
    :canceled_at,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
```

### Tiny Nested Structs

```elixir
# Source: D-18 + lib/paddle/transaction/checkout.ex shape
defmodule Paddle.Subscription.ScheduledChange do
  defstruct [:action, :effective_at, :resume_at, :raw_data]
end

defmodule Paddle.Subscription.ManagementUrls do
  defstruct [:update_payment_method, :cancel, :raw_data]
end
```

### Resource Module (Skeleton)

```elixir
# Source: lib/paddle/customers.ex + lib/paddle/transactions.ex
defmodule Paddle.Subscriptions do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange

  @list_allowlist ~w(id customer_id address_id price_id status
                     scheduled_change_action collection_mode
                     next_billed_at order_by after per_page)

  def get(%Client{} = client, subscription_id) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, subscription_path(subscription_id)) do
      {:ok, build_subscription(data)}
    end
  end

  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/subscriptions", params: query) do
      {:ok,
       %Paddle.Page{
         data: Enum.map(data, &build_subscription/1),
         meta: meta
       }}
    end
  end

  def cancel(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "next_billing_period")
  end

  def cancel_immediately(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "immediately")
  end

  defp do_cancel(client, subscription_id, effective_from) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             cancel_path(subscription_id),
             json: %{"effective_from" => effective_from}
           ) do
      {:ok, build_subscription(data)}
    end
  end

  # --- private builders ---

  defp build_subscription(data) when is_map(data) do
    subscription = Http.build_struct(Subscription, data)

    subscription =
      case data["scheduled_change"] do
        sc when is_map(sc) -> %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}
        _ -> subscription
      end

    case data["management_urls"] do
      mu when is_map(mu) -> %{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}
      _ -> subscription
    end
  end

  # --- private validators / normalizers ---

  defp validate_subscription_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
  end

  defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp subscription_path(id), do: "/subscriptions/#{encode_path_segment(id)}"
  defp cancel_path(id), do: subscription_path(id) <> "/cancel"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
```

### Real Paddle Response — Get / Cancel-Immediately (status: canceled, scheduled_change: null)

```json
{
  "data": {
    "id": "sub_01hv8y5ehszzq0yv20ttx3166y",
    "status": "canceled",
    "customer_id": "ctm_01hv8wt8nffez4p2t6typn4a5j",
    "address_id": "add_01hv8y4jk511j9g2n9a2mexjbx",
    "business_id": null,
    "currency_code": "USD",
    "created_at": "2024-04-12T10:38:00.761Z",
    "updated_at": "2024-04-12T11:24:54.873Z",
    "started_at": "2024-04-12T10:37:59.556997Z",
    "first_billed_at": "2024-04-12T10:37:59.556997Z",
    "next_billed_at": null,
    "paused_at": null,
    "canceled_at": "2024-04-12T11:24:54.868Z",
    "collection_mode": "automatic",
    "billing_details": null,
    "current_billing_period": null,
    "billing_cycle": {"frequency": 1, "interval": "month"},
    "scheduled_change": null,
    "items": [...],
    "custom_data": null,
    "management_urls": {
      "update_payment_method": "https://buyer-portal.paddle.com/subscriptions/sub_01hv8y5ehszzq0yv20ttx3166y/update-payment-method",
      "cancel": "https://buyer-portal.paddle.com/subscriptions/sub_01hv8y5ehszzq0yv20ttx3166y/cancel"
    },
    "discount": null,
    "import_meta": null
  },
  "meta": {"request_id": "f21058d1-281a-4877-bb3b-261a753d08c4"}
}
```
[VERIFIED: /tmp/paddle-openapi.yaml lines 10952-11121]

### Real Paddle Response — End-of-Period Cancel (status: active, scheduled_change populated)

The cancel endpoint with `effective_from: "next_billing_period"` (default) returns `status: "active"` and a populated `scheduled_change`:

```json
{
  "data": {
    "id": "sub_01hv8y5ehszzq0yv20ttx3166y",
    "status": "active",
    "scheduled_change": {
      "action": "cancel",
      "effective_at": "2024-05-12T10:37:59.556997Z",
      "resume_at": null
    },
    "canceled_at": null,
    "...": "..."
  },
  "meta": {"request_id": "..."}
}
```
[CITED: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription docs prose] [VERIFIED: /tmp/paddle-openapi.yaml lines 10921 (description), 11206-11209 (pause example shape — same scheduled_change envelope, just different action)]

### Real Paddle Response — List with Pagination

```json
{
  "data": [
    {"id": "sub_01hv959anj4zrw503h2acawb3p", "status": "active", "...": "..."},
    {"id": "sub_01hv915hmgnwqd9n5yxgy8t60c", "status": "active", "...": "..."}
  ],
  "meta": {
    "request_id": "170e71a2-ed13-4f45-b002-45693f5361b4",
    "pagination": {
      "per_page": 50,
      "next": "https://api.paddle.com/subscriptions?after=sub_01hv8x29kz0t586xy6zn1a62ny",
      "has_more": false,
      "estimated_total": 1
    }
  }
}
```
[VERIFIED: /tmp/paddle-openapi.yaml lines 9826-10481]

### Real Paddle Request — Cancel Body

```json
{"effective_from": "immediately"}
```
or
```json
{"effective_from": "next_billing_period"}
```
[VERIFIED: /tmp/paddle-openapi.yaml lines 27521-27534 (EffectiveFrom enum)] [VERIFIED: /tmp/paddle-openapi.yaml lines 27823-27830 (SubscriptionCancel body schema, default `next_billing_period`)]

## Plan-Level Concerns

The output here is structured to map cleanly to three (or optionally four) atomic PLAN.md files.

### Plan 1: Subscription Entity & Nested Structs

**Files to create (absolute paths):**
- `/Users/jon/projects/oarlock/lib/paddle/subscription.ex` — `%Paddle.Subscription{}` flat struct (24 fields per D-16).
- `/Users/jon/projects/oarlock/lib/paddle/subscription/scheduled_change.ex` — `%Paddle.Subscription.ScheduledChange{}` (4 fields).
- `/Users/jon/projects/oarlock/lib/paddle/subscription/management_urls.ex` — `%Paddle.Subscription.ManagementUrls{}` (3 fields).
- `/Users/jon/projects/oarlock/test/paddle/subscription_test.exs` — struct-shape + `build_struct/2` mapping tests for all three structs.

**Closest existing analogs:**
- `/Users/jon/projects/oarlock/lib/paddle/transaction.ex` (lines 1-24) — exact analog for the flat entity struct.
- `/Users/jon/projects/oarlock/lib/paddle/transaction/checkout.ex` (lines 1-3) — exact analog for the tiny nested struct shape.
- `/Users/jon/projects/oarlock/test/paddle/transaction_test.exs` (lines 1-100) — exact analog for both struct-shape tests and `Http.build_struct/2` mapping tests including the tiny nested struct case.

**Concrete test file pattern to mirror (5-15 lines):**
```elixir
# Source: test/paddle/transaction_test.exs:9-32
describe "%Paddle.Subscription{} struct" do
  test "exposes the promoted subscription fields plus raw_data" do
    assert %Subscription{
             id: nil,
             status: nil,
             # ... all 24 fields, all nil ...
             raw_data: nil
           } = %Subscription{}
  end

  test "build_struct/2 promotes known subscription keys and preserves the full payload in raw_data" do
    data = subscription_payload_active_with_scheduled_change()  # see Plan 3 fixture builders
    assert %Subscription{id: "sub_01...", raw_data: ^data} = Http.build_struct(Subscription, data)
  end
end
```

**Risks specific to Plan 1:**
- The struct field list MUST be the exact 24 fields from D-16 in the same order — `Http.build_struct/2` only fills declared keys, so a missing field becomes silent data loss into `raw_data` only.
- `import_meta` is in the field list (D-16) but is NEVER promoted to a typed struct (D-20). It stays as a plain map.
- `:raw_data` MUST be the last field (consistency with Customer/Transaction/Address).

### Plan 2: Subscriptions Resource Module

**Files to create:**
- `/Users/jon/projects/oarlock/lib/paddle/subscriptions.ex` — public resource module with `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`, plus private `do_cancel/3`, `build_subscription/1`, `validate_subscription_id/1`, `normalize_params/1`, `subscription_path/1`, `cancel_path/1`, `encode_path_segment/1`.

**Closest existing analogs:**
- `/Users/jon/projects/oarlock/lib/paddle/transactions.ex` (full file, especially lines 35-45) — exact analog for the per-resource nested-struct post-processing pattern. This is the **single most important reference** for Plan 2.
- `/Users/jon/projects/oarlock/lib/paddle/customers.ex` (lines 18-24, 36-48) — exact analog for `validate_subscription_id` and `subscription_path` + URI encoding.
- `/Users/jon/projects/oarlock/lib/paddle/customers/addresses.ex` (lines 29-41, 74-83) — exact analog for the `list/2` envelope unwrap, page mapping, and `normalize_params/1` helper. The signature differs (Phase 5 drops the positional customer_id) but every other line transfers.

**Concrete code excerpt — the nested-struct post-processor (the canonical analog):**
```elixir
# Source: lib/paddle/transactions.ex:35-45 (THE precedent for D-22)
defp build_transaction(data) when is_map(data) do
  transaction = Http.build_struct(Transaction, data)

  case data["checkout"] do
    checkout_data when is_map(checkout_data) ->
      %{transaction | checkout: Http.build_struct(Checkout, checkout_data)}

    _ ->
      transaction
  end
end
```

Plan 2 replicates this idea twice (once for `scheduled_change`, once for `management_urls`) inside a single `build_subscription/1`.

**Concrete API request/response examples:** See "Code Examples → Real Paddle Response" sections above.

**Endpoint table:**

| Function | Method + Path | Request body / query | Response mapping |
|----------|---------------|----------------------|------------------|
| `get/2` | `GET /subscriptions/{id}` | (path arg only) | `%{"data" => data}` → `build_subscription(data)` |
| `list/2` | `GET /subscriptions` | `params: query` (allowlisted) | `%{"data" => list, "meta" => meta}` → `%Paddle.Page{data: Enum.map(list, &build_subscription/1), meta: meta}` |
| `cancel/2` | `POST /subscriptions/{id}/cancel` | `json: %{"effective_from" => "next_billing_period"}` | `%{"data" => data}` → `build_subscription(data)` |
| `cancel_immediately/2` | `POST /subscriptions/{id}/cancel` | `json: %{"effective_from" => "immediately"}` | `%{"data" => data}` → `build_subscription(data)` |

**Risks specific to Plan 2:**
- Forgetting that BOTH cancel functions return `{:ok, %Paddle.Subscription{}}` (not `:ok` or `{:ok, :canceled}`). Paddle returns the full updated subscription envelope on both modes. [VERIFIED: /tmp/paddle-openapi.yaml lines 10936-10947]
- Forgetting `do_cancel/3` validates the ID **inside** the helper (not just in the public functions) — otherwise the public functions need to duplicate the validation. The skeleton above puts validation in `do_cancel/3` which is cleaner.
- The `list/2` allowlist contains 11 keys per D-12; missing any one (especially `customer_id`, which is how SUB-02 is satisfied) silently breaks the public contract.
- `body == nil` check in `Req` adapter assertions for GET requests (per existing tests) — make sure the GET tests assert `request.body == nil` as is convention.
- **Existing repo idiosyncrasy:** `lib/paddle/transactions.ex:38` uses a `case`-branch nested-struct hydration. Either inlining two case clauses or extracting a single `put_nested_struct/4` helper is acceptable per D-25 / Discretion section — do not block on the choice.

### Plan 3: Tests for Subscriptions Resource Module

**Files to create:**
- `/Users/jon/projects/oarlock/test/paddle/subscriptions_test.exs` — adapter-backed tests for `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`, plus boundary-validation and error-propagation tests.

**Closest existing analogs:**
- `/Users/jon/projects/oarlock/test/paddle/transactions_test.exs` — request-body assertion shape, error propagation, transport exception passthrough. (Lines 14-50, 319-366.)
- `/Users/jon/projects/oarlock/test/paddle/customers_test.exs` — single-entity GET path test (lines 91-127), `client_with_adapter/1` and `decode_json_body/1` helpers (lines 182-194), URL-encoding test (lines 116-126).
- `/Users/jon/projects/oarlock/test/paddle/customers/addresses_test.exs` — list pagination test with `Paddle.Page.next_cursor/1` assertion (lines 79-108), allowlisted-query-params test (lines 110-139), validation-tuple test (lines 154-160).

**Concrete test fixtures to write:**

```elixir
# Source: synthesized from /tmp/paddle-openapi.yaml lines 10952-11121
defp subscription_payload_canceled do
  %{
    "id" => "sub_01",
    "status" => "canceled",
    "customer_id" => "ctm_01",
    "address_id" => "add_01",
    "business_id" => nil,
    "currency_code" => "USD",
    "collection_mode" => "automatic",
    "custom_data" => nil,
    "items" => [],
    "scheduled_change" => nil,
    "management_urls" => %{
      "update_payment_method" => "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
      "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
    },
    "current_billing_period" => nil,
    "billing_cycle" => %{"frequency" => 1, "interval" => "month"},
    "billing_details" => nil,
    "discount" => nil,
    "next_billed_at" => nil,
    "started_at" => "2024-04-12T10:37:59.556997Z",
    "first_billed_at" => "2024-04-12T10:37:59.556997Z",
    "paused_at" => nil,
    "canceled_at" => "2024-04-12T11:24:54.868Z",
    "created_at" => "2024-04-12T10:38:00.761Z",
    "updated_at" => "2024-04-12T11:24:54.873Z",
    "import_meta" => nil
  }
end

defp subscription_payload_active_with_scheduled_change do
  Map.merge(subscription_payload_canceled(), %{
    "status" => "active",
    "canceled_at" => nil,
    "current_billing_period" => %{"starts_at" => "2024-04-12T10:37:59.556997Z", "ends_at" => "2024-05-12T10:37:59.556997Z"},
    "scheduled_change" => %{
      "action" => "cancel",
      "effective_at" => "2024-05-12T10:37:59.556997Z",
      "resume_at" => nil
    }
  })
end

defp subscription_payload_manual_no_payment_link do
  Map.merge(subscription_payload_canceled(), %{
    "collection_mode" => "manual",
    "management_urls" => %{
      "update_payment_method" => nil,
      "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
    }
  })
end
```

**Required test cases (one row = one `test` block):**

| Test target | Assertion focus |
|-------------|-----------------|
| `get/2` happy path | `GET /subscriptions/sub_01`, `body == nil`, returns `{:ok, %Subscription{id: "sub_01", scheduled_change: nil, management_urls: %ManagementUrls{cancel: "..."}}}` |
| `get/2` URL-encodes ID | path becomes `/subscriptions/sub%2F01` for `"sub/01"` |
| `get/2` populated scheduled_change | uses `subscription_payload_active_with_scheduled_change/0`; asserts `%ScheduledChange{action: "cancel", effective_at: "...", resume_at: nil}` |
| `get/2` blank ID validation | `nil`, `""`, `"   "`, integers all return `{:error, :invalid_subscription_id}` |
| `get/2` 404 error propagation | adapter returns `Req.Response.new(status: 404, body: ...entity_not_found...)`; assert `%Error{status_code: 404, code: "entity_not_found"}` |
| `get/2` transport exception passthrough | adapter returns `%Req.TransportError{reason: :timeout}`; assert it bubbles |
| `list/2` happy path | `GET /subscriptions` no query, returns `%Paddle.Page{data: [%Subscription{}, ...], meta: meta}`; `Paddle.Page.next_cursor(page) == "https://api.paddle.com/subscriptions?after=sub_..."` |
| `list/2` allowlisted query params | passes all 11 allowed keys, asserts they all appear in `request.url.query`; passes `unknown_key: "drop"`, asserts it does NOT appear |
| `list/2` `customer_id` filter (SUB-02 satisfaction) | passes `customer_id: "ctm_01"`, asserts query encodes it |
| `list/2` invalid params validation | `Subscriptions.list(client, "nope")` and `Subscriptions.list(client, 42)` both return `{:error, :invalid_params}`; bare list `[1,2,3]` (non-keyword) also rejected |
| `list/2` empty result + has_more=false | data: [], meta with empty pagination |
| `list/2` transport exception passthrough | adapter returns `%Req.TransportError{}`; assert bubbles |
| `cancel/2` happy path | `POST /subscriptions/sub_01/cancel`, body: `%{"effective_from" => "next_billing_period"}`, returns `{:ok, %Subscription{status: "active", scheduled_change: %ScheduledChange{action: "cancel"}}}` |
| `cancel/2` URL-encodes ID | path becomes `/subscriptions/sub%2F01/cancel` |
| `cancel/2` blank ID validation | same set as `get/2` |
| `cancel_immediately/2` happy path | `POST /subscriptions/sub_01/cancel`, body: `%{"effective_from" => "immediately"}`, returns `{:ok, %Subscription{status: "canceled", scheduled_change: nil}}` |
| `cancel_immediately/2` URL-encodes ID | same |
| `cancel_immediately/2` blank ID validation | same |
| `cancel/2` and `cancel_immediately/2` `subscription_locked_pending_changes` propagation | adapter returns 422 with code `subscription_locked_pending_changes`; assert `%Error{status_code: 422, code: "subscription_locked_pending_changes"}` propagates |
| `cancel/2` and `cancel_immediately/2` 404 propagation | adapter returns 404 entity_not_found; same propagation pattern |
| `cancel/2` transport exception passthrough | bubbles unchanged |
| `management_urls.update_payment_method` null path | uses `subscription_payload_manual_no_payment_link/0`; asserts `%ManagementUrls{update_payment_method: nil, cancel: "..."}` |

**Risks specific to Plan 3:**
- Cancellation tests MUST use the mock adapter only — never live API. Document this explicitly in `@moduledoc` or test-file header to prevent future regressions.
- The `next_cursor` assertion must match the **full URL** (e.g., `"https://api.paddle.com/subscriptions?after=sub_..."`) not a bare ID — easy to get wrong.
- The `body == nil` assertion is what the existing GET tests use (e.g., `test/paddle/customers_test.exs:99`); transactions tests don't assert this because POST always has a body. Phase 5 GET tests (and only GET tests) should include this.
- For the request-body assertion in cancel tests, JSON-decoding step uses the existing helper:
  ```elixir
  defp decode_json_body(body), do: body |> IO.iodata_to_binary() |> Jason.decode!()
  ```
  Source: `test/paddle/customers_test.exs:190-194`.

### (Optional) Plan 4: Documentation / Typespecs / Dialyzer

If the planner wants to keep Plan 2 lean, a fourth plan could carry the `@moduledoc`s, `@doc`s, `@spec`s, and a Dialyzer pass. Otherwise these can fold into Plan 2 since the public surface is small (4 functions). The Discretion section permits either approach. This research does NOT recommend a fourth plan unless the planner judges the file has gotten too large with 4 public functions + their docs.

## Mox / Bypass / Mock Transport Setup

The repo does NOT use Mox or Bypass. Every existing resource test uses **inline `Req.new(adapter: fn request -> ... end)`** to short-circuit transport. [VERIFIED: test/paddle/customers_test.exs:182-188] [VERIFIED: test/paddle/customers/addresses_test.exs:285-291] [VERIFIED: test/paddle/transactions_test.exs:369-375]

The exact pattern Phase 5 must reuse:

```elixir
# Source: test/paddle/transactions_test.exs:369-381
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end

defp decode_json_body(body) do
  body
  |> IO.iodata_to_binary()
  |> Jason.decode!()
end
```

The adapter function takes a `Req.Request{}` and returns `{request, response}` where `response` is a `Req.Response{}` or a transport-exception struct (e.g., `%Req.TransportError{}`). Asserting on the request inside the adapter is the established way to verify outgoing HTTP. [VERIFIED: test/paddle/customers_test.exs:14-25] [VERIFIED: test/paddle/transactions_test.exs:14-29]

**No new mock-transport infrastructure is needed.** Phase 5 copies these helper functions verbatim into `test/paddle/subscriptions_test.exs`.

## HTTPoison/Req Error Surface (Re-confirmed)

`Paddle.Http.request/4` returns three result shapes — Phase 5 inherits all three unchanged: [VERIFIED: lib/paddle/http.ex:2-15]

| Outcome | Returned shape |
|---------|----------------|
| 2xx HTTP response | `{:ok, decoded_body}` |
| Non-2xx HTTP response | `{:error, %Paddle.Error{type, code, message, errors, request_id, status_code, raw}}` |
| Transport exception (e.g., `%Req.TransportError{}`, `%Req.HTTPError{}`) | `{:error, exception}` (the exception struct, **unchanged**) |

The third shape is what CONTEXT.md means by "transport exceptions surface unchanged." Phase 5 tests must assert this with `assert {:error, %Req.TransportError{reason: :timeout}} = Subscriptions.get(client, "sub_01")` — exactly mirroring the existing precedent. [VERIFIED: test/paddle/customers_test.exs:80-88] [VERIFIED: test/paddle/transactions_test.exs:354-366]

`Paddle.Error.from_response/1` extracts the Paddle-specific fields (`type`, `code`, `detail` → `message`, `errors`) from the JSON envelope and the `x-request-id` header. Subscription-specific error codes (e.g., `subscription_locked_pending_changes`) flow into `error.code` as-is. [VERIFIED: lib/paddle/error.ex] [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_pending_changes]

## Subscription-Specific HTTP Errors

Paddle returns these subscription-specific error codes that Phase 5 propagates through `%Paddle.Error{}` unchanged. The SDK does NOT map them to symbolic atoms (per D-23 boundary discipline) — `error.code` is just the snake_case string from Paddle.

| Error code | HTTP status | When | Source |
|------------|-------------|------|--------|
| `subscription_locked_pending_changes` | 422 (assumed; not enumerated) | Mutation attempted while another change is pending | [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_pending_changes] |
| `subscription_locked_processing` | 422 | Mutation attempted within 30-min processing lock window | [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_processing] |
| `subscription_locked_renewal` | 422 | Mutation attempted within 30-min renewal lock window | [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_renewal] |
| `subscription_locked_consent_review_period` | 422 | Mutation attempted during consent review period | [CITED: https://developer.paddle.com/errors/subscriptions/subscription_locked_consent_review_period] |
| `subscription_update_when_canceled` | 422 | Modify attempted on already-canceled subscription | [CITED: https://developer.paddle.com/errors/subscriptions/subscription_update_when_canceled] |
| `entity_not_found` | 404 | Subscription ID does not exist | [CITED: https://developer.paddle.com/errors/shared/not_found] [VERIFIED: /tmp/paddle-openapi.yaml lines 17438-17472 (ApiError shape, generic shared error)] |

The exact HTTP status codes for the `subscription_locked_*` family are NOT explicitly enumerated in the OpenAPI spec or error reference summaries; testing should assert on `code` rather than `status_code` for those. [ASSUMED: 422 status based on Paddle's general validation-error convention]

Phase 5 should include at least ONE test that asserts a `subscription_locked_*`-style error propagates as `%Paddle.Error{code: "subscription_locked_pending_changes"}` to demonstrate the contract. The remaining error codes need not be individually tested — they all flow through the same `Paddle.Http.request/4` boundary. [VERIFIED: lib/paddle/http.ex:9-10]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stripe-style polymorphic `cancel(id, options)` with `cancel_at_period_end: true` | Two separately named cancel functions per Phase 5 D-04/D-05 | Locked in CONTEXT.md | The most-reported Stripe footgun is sidestepped at the API surface. |
| Customer-scoped subscription nesting (e.g., `customer.subscriptions.cancel`) | Top-level `Paddle.Subscriptions` module + `customer_id` filter | Paddle's own URL design | Matches Paddle's REST shape; allows multi-dimensional filtering (`customer_id`, `status`, `scheduled_change_action`, etc.). [VERIFIED: /tmp/paddle-openapi.yaml line 9785] |
| OpenAPI mirroring with raw maps | Curated typed entity + tiny nested structs only where DX matters | Phase 3/4 precedent extended | `subscription.scheduled_change.effective_at` and `subscription.management_urls.cancel` are guaranteed dot-access paths; everything else stays as plain maps under `raw_data`. [VERIFIED: lib/paddle/transactions.ex] |

**Deprecated/outdated:** None applicable to Phase 5. The Paddle subscription endpoints are stable in Paddle Billing API v1 as of the latest OpenAPI spec.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The HTTP status code for `subscription_locked_*` errors is 422 | Subscription-Specific HTTP Errors | Low. Tests should assert on `error.code` not `error.status_code` for these. The 422-vs-409 distinction does not affect the SDK contract; `Paddle.Error.from_response/1` extracts both fields uniformly from any non-2xx response. [VERIFIED: lib/paddle/error.ex] |
| A2 | Pitfall 7 (`status` array not auto-comma-joined) is correctly described | Common Pitfalls | Low. Phase 5 documents the single-value contract and defers list values. If a future caller really needs multi-value filters, that becomes a feature request, not a Phase 5 bug. |

All other claims in this research were verified directly against `/tmp/paddle-openapi.yaml` (downloaded fresh from `https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml`), against the existing repo (`lib/paddle/*`, `test/paddle/*`), or against current Paddle developer documentation pages.

## Open Questions (RESOLVED)

1. **Should `do_cancel/3` accept an atom (`:next_billing_period`) or a string (`"next_billing_period"`) for `effective_from`?**
   - Discretion item per CONTEXT.md. Recommended: pass strings internally because the JSON body sends strings. No conversion overhead.
   - Resolution: planner's call. Either is correct. The skeleton in this research uses strings. [VERIFIED: .planning/phases/05-subscriptions-management/05-CONTEXT.md "Claude's Discretion"]

2. **Should `build_subscription/1` use one inline `case` per nested struct, or extract a `put_nested_struct/4` helper?**
   - Discretion item per CONTEXT.md. Recommended: two inline `case` clauses (matches `transactions.ex` precedent exactly).
   - Resolution: planner's call. The skeleton in this research uses two inline `case` clauses for line-level fidelity to the analog. [VERIFIED: lib/paddle/transactions.ex:35-45]

3. **Does any existing repo module list-without-positional-id?**
   - No. Phase 5's `list/2` (client + params only) introduces a new signature shape. Customers list is not yet implemented; addresses list is positional-customer-scoped. The mechanical pattern (envelope unwrap, allowlist, `%Paddle.Page{}` wrap) transfers verbatim — only the lack of a positional ID and the absence of `validate_X_id` differ.
   - Resolution: explicitly noted as a new shape in this research; planner is informed. [VERIFIED: lib/paddle/customers.ex] [VERIFIED: lib/paddle/customers/addresses.ex] [VERIFIED: lib/paddle/transactions.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile + run tests | ✓ | (matches Phase 4 — `~> 1.19` per mix.exs) | — |
| Mix | Dependency resolution + `mix test` | ✓ | matches Elixir | — |
| `req` | HTTP transport | ✓ | 0.5.17 | — [VERIFIED: mix.lock] |
| `telemetry` | Instrumentation | ✓ | 1.4.1 | — [VERIFIED: mix.lock] |
| `jason` | JSON encoding (transitive via req) | ✓ | 1.4.4 | — [VERIFIED: mix.lock] |
| Paddle sandbox account | Live integration testing | not required | — | Use mock adapter exclusively (cancellation is irreversible per Pitfall 3) [VERIFIED: test/paddle/transactions_test.exs:369-375] |

**Missing dependencies with no fallback:** None for code or test implementation.

**Missing dependencies with fallback:** None applicable.

## Validation Architecture

> Skipped per `.planning/config.json` `workflow.nyquist_validation: false`. [VERIFIED: .planning/config.json]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `%Paddle.Client{}` Bearer-token auth from Phase 1 reused unchanged. [VERIFIED: lib/paddle/client.ex] |
| V3 Session Management | no | Stateless API wrappers; no SDK-managed sessions. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | no | Authorization is external to the SDK. [VERIFIED: .planning/PROJECT.md] |
| V5 Input Validation | yes | Allowlist params/attrs, validate `subscription_id` non-blank, validate params container shape. [VERIFIED: .planning/phases/05-subscriptions-management/05-CONTEXT.md D-23] |
| V6 Cryptography | no | No new cryptography; HTTPS via Req's existing TLS handling. [VERIFIED: lib/paddle/client.ex] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller injects unsupported list-filter keys (e.g., `select_all=true`) | Tampering | `Attrs.allowlist/2` with the 11-key D-12 list. Unknown keys silently dropped. [VERIFIED: lib/paddle/internal/attrs.ex:23-31] [VERIFIED: lib/paddle/customers/addresses.ex:7,32] |
| Caller passes a malformed subscription_id (e.g., `nil`, `""`, integer) | Tampering | `validate_subscription_id/1` boundary check returns `{:error, :invalid_subscription_id}` before any HTTP call. [VERIFIED: lib/paddle/customers.ex:38-46] |
| Caller's subscription_id contains URL-reserved characters | Tampering | `URI.encode(id, &URI.char_unreserved?/1)` ensures the path is well-formed. [VERIFIED: lib/paddle/customers.ex:48] |
| Wrong subscription canceled due to ID mix-up | Tampering | The SDK has no role here beyond passing the ID through. Caller responsibility; Paddle's auth scope enforces tenant boundaries. |
| Cancellation accidentally fires against live API | Repudiation / Loss of revenue | Tests use mock adapter only. Plan 3 includes an explicit no-live-API note in `@moduledoc`. [VERIFIED: test/paddle/transactions_test.exs] |
| Customer portal `management_urls.cancel` link logged to user-visible logs | Information Disclosure | The links contain temporary tokens per [VERIFIED: /tmp/paddle-openapi.yaml lines 21354-21358]. Phase 5 does not log these. Document in moduledoc that consumers should not log them either. |

## Sources

### Primary (HIGH confidence)
- `lib/paddle/http.ex` — transport boundary, build_struct shallow mapper. [VERIFIED: lib/paddle/http.ex]
- `lib/paddle/customers.ex`, `lib/paddle/customers/addresses.ex`, `lib/paddle/transactions.ex` — exact analog files for Plan 2. [VERIFIED: codebase grep]
- `lib/paddle/transaction.ex`, `lib/paddle/transaction/checkout.ex` — exact analog files for Plan 1. [VERIFIED: codebase grep]
- `test/paddle/customers_test.exs`, `test/paddle/customers/addresses_test.exs`, `test/paddle/transactions_test.exs`, `test/paddle/transaction_test.exs` — exact analog test files for Plan 3. [VERIFIED: codebase grep]
- `.planning/phases/05-subscriptions-management/05-CONTEXT.md` — locked decisions D-01 through D-25. [VERIFIED: file read in this session]
- `.planning/REQUIREMENTS.md` — SUB-01, SUB-02, SUB-03 requirement statements. [VERIFIED: file read in this session]
- `https://github.com/PaddleHQ/paddle-openapi/blob/main/v1/openapi.yaml` (downloaded as `/tmp/paddle-openapi.yaml`, 5.5 MB) — exhaustive endpoint, schema, enum, and example verification. [VERIFIED: curl downloaded 2026-04-29] Specific line ranges:
  - Subscription schema: lines 27314-27430+
  - SubscriptionScheduledChange schema: lines 21308-21333
  - SubscriptionScheduledChangeAction enum: lines 21292-21307
  - SubscriptionManagementUrls schema: lines 21334-21359
  - StatusSubscription enum: lines 27135-27156
  - EffectiveFrom enum: lines 27521-27534
  - SubscriptionCancel request schema: lines 27823-27830
  - GET /subscriptions/{id}: lines 10495-10668
  - GET /subscriptions: lines 9785-10491
  - POST /subscriptions/{id}/cancel: lines 10914-11144
  - ListSubscriptionsQueryParams.*: lines 17159-17228
  - Pagination schema: lines 18478-18504
  - PaginatedMeta schema: lines 18505-18519
  - ApiError schema: lines 17438-17472
- `https://developer.paddle.com/api-reference/subscriptions/get-subscription` — endpoint surface confirmation. [CITED]
- `https://developer.paddle.com/api-reference/subscriptions/list-subscriptions` — pagination + filter dimensions. [CITED]
- `https://developer.paddle.com/api-reference/subscriptions/cancel-subscription` — effective_from semantics. [CITED]

### Secondary (MEDIUM confidence)
- `https://developer.paddle.com/errors/subscriptions/subscription_locked_pending_changes` — error code surface. [CITED]
- `https://developer.paddle.com/errors/subscriptions/subscription_locked_processing` — error code surface. [CITED]
- `https://developer.paddle.com/errors/subscriptions/subscription_locked_renewal` — error code surface. [CITED]
- `https://developer.paddle.com/errors/subscriptions/subscription_locked_consent_review_period` — error code surface. [CITED]
- `https://developer.paddle.com/errors/subscriptions/subscription_update_when_canceled` — error code surface. [CITED]
- Paddle Node.js SDK confirmation that `paddle.subscriptions.list/get/cancel` is the canonical surface. [CITED: https://github.com/PaddleHQ/paddle-node-sdk]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every dependency is already in `mix.lock`; no new versions introduced.
- Architecture: HIGH — every pattern has a line-level analog already in the repo, and the locked decisions in CONTEXT.md cleanly bind to those analogs.
- Pitfalls: HIGH — each pitfall is grounded in an explicit OpenAPI spec line, repo behavior, or Paddle docs URL.
- API endpoint shape: HIGH — schemas verified against the downloaded OpenAPI YAML, with example responses cross-referenced.
- Error code surface: MEDIUM — error codes confirmed via Paddle's error-reference URLs, but exact HTTP status mapping is `[ASSUMED]` 422 for the `subscription_locked_*` family. Tests should assert on `code` not `status_code` for those.

**Research date:** 2026-04-29
**Valid until:** 2026-05-29 (30 days; Paddle Billing API v1 subscription endpoints are stable, but re-check before any major version bump).

## RESEARCH COMPLETE
