# Phase 5: Subscriptions Management - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 6 (4 lib + 2 test, plus reference excerpts)
**Analogs found:** 6 / 6

All Phase 5 files have strong line-level analogs already in the repository. There are zero gaps requiring fallback to RESEARCH.md heuristics. The single new shape — a top-level filter-based `list/2` (no positional ID) — is mechanically identical to `Paddle.Customers.Addresses.list/3` minus the `validate_customer_id/1` step.

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `lib/paddle/subscription.ex` | model (entity struct) | request-response (mapping target) | `lib/paddle/transaction.ex` | exact |
| `lib/paddle/subscription/scheduled_change.ex` | model (tiny nested struct) | request-response (mapping target) | `lib/paddle/transaction/checkout.ex` | exact |
| `lib/paddle/subscription/management_urls.ex` | model (tiny nested struct) | request-response (mapping target) | `lib/paddle/transaction/checkout.ex` | exact |
| `lib/paddle/subscriptions.ex` | service (resource module) | request-response (CRUD-ish: get/list/cancel) | `lib/paddle/transactions.ex` (post-processing) + `lib/paddle/customers.ex` (get/validate/encode) + `lib/paddle/customers/addresses.ex` (list pagination, normalize_params) | exact composite |
| `test/paddle/subscription_test.exs` | test (struct shape + build_struct) | request-response | `test/paddle/transaction_test.exs` | exact |
| `test/paddle/subscriptions_test.exs` | test (adapter-backed resource module) | request-response | `test/paddle/transactions_test.exs` + `test/paddle/customers_test.exs` + `test/paddle/customers/addresses_test.exs` | exact composite |

## Pattern Assignments

### `lib/paddle/subscription.ex` (model, flat entity struct)

**Analog:** `lib/paddle/transaction.ex` (entire file, 24 lines)

**Full file pattern** (`lib/paddle/transaction.ex` lines 1-24):
```elixir
defmodule Paddle.Transaction do
  defstruct [
    :id,
    :status,
    :customer_id,
    :address_id,
    :business_id,
    :custom_data,
    :currency_code,
    :origin,
    :subscription_id,
    :invoice_number,
    :collection_mode,
    :items,
    :details,
    :payments,
    :checkout,
    :created_at,
    :updated_at,
    :billed_at,
    :revised_at,
    :raw_data
  ]
end
```

**What to copy:**
- Module shape: `defmodule Paddle.<Entity> do ... defstruct [...] end` — no functions, no behaviors, no typespecs (none of the existing entities have typespecs).
- `:raw_data` is the **last** element of the keyword list — consistent with Customer, Transaction, Address.
- All fields are atoms with leading colon, snake_case, one per line.
- No `@moduledoc` is required (Transaction has none); add only if Plan 1 explicitly opts in.

**What changes for Phase 5:**
- 24 fields per CONTEXT.md D-16 (vs Transaction's 20):
  ```
  :id, :status, :customer_id, :address_id, :business_id,
  :currency_code, :collection_mode, :custom_data, :items,
  :scheduled_change, :management_urls,
  :current_billing_period, :billing_cycle, :billing_details,
  :discount, :next_billed_at, :started_at, :first_billed_at,
  :paused_at, :canceled_at, :created_at, :updated_at,
  :import_meta, :raw_data
  ```
- `:scheduled_change` and `:management_urls` are typed-struct slots; the rest are plain maps/strings/lists/nil.

---

### `lib/paddle/subscription/scheduled_change.ex` (model, tiny nested struct)

**Analog:** `lib/paddle/transaction/checkout.ex` (entire file, 3 lines)

**Full file pattern** (`lib/paddle/transaction/checkout.ex` lines 1-3):
```elixir
defmodule Paddle.Transaction.Checkout do
  defstruct [:url, :raw_data]
end
```

**What to copy:**
- One-line `defstruct [...]` body with `:raw_data` as the last element.
- Nested under the parent entity's submodule namespace (`Paddle.Transaction.Checkout` → `Paddle.Subscription.ScheduledChange`).
- File path mirrors module path (`lib/paddle/transaction/checkout.ex` → `lib/paddle/subscription/scheduled_change.ex`).

**What changes for Phase 5:**
- Field list per CONTEXT.md D-18: `[:action, :effective_at, :resume_at, :raw_data]`.

---

### `lib/paddle/subscription/management_urls.ex` (model, tiny nested struct)

**Analog:** `lib/paddle/transaction/checkout.ex` (entire file, 3 lines) — same as `scheduled_change.ex`.

**What changes for Phase 5:**
- Field list per CONTEXT.md D-18: `[:update_payment_method, :cancel, :raw_data]`.
- Note: per RESEARCH.md Pitfall 5, `:update_payment_method` may be `nil` for `collection_mode: "manual"` subscriptions; `:cancel` is always a string. No code change required — `Http.build_struct/2` already handles nil pass-through. Document the null behavior in `@moduledoc` if Plan 1 chooses to add docs.

---

### `lib/paddle/subscriptions.ex` (service, resource module — composite analog)

This file blends three existing analogs because no single existing module has the same composition (get + filter-based list + two named cancel functions + nested-struct post-processing). The composition is novel; every constituent pattern is exact.

#### Pattern A: Imports / Aliases

**Analog:** `lib/paddle/transactions.ex` lines 1-5

```elixir
defmodule Paddle.Transactions do
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout
```

**What to copy:** Aliases at the top of the module, one per line, sorted only by what the file actually uses. No `import` statements. No `use` directives.

**What changes for Phase 5:**
```elixir
defmodule Paddle.Subscriptions do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange
```

Note: `lib/paddle/customers.ex:2` aliases `Paddle.Client`; `lib/paddle/transactions.ex` does NOT (it pattern-matches on `%Paddle.Client{}` inline). Phase 5 may follow either convention — they are equivalent. The skeleton in RESEARCH.md uses `alias Paddle.Client`, which matches `customers.ex`.

#### Pattern B: `get/2` — single-entity GET with ID validation + URI encoding

**Analog:** `lib/paddle/customers.ex` lines 18-24, 36-48

```elixir
def get(%Client{} = client, customer_id) do
  with :ok <- validate_customer_id(customer_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :get, customer_path(customer_id)) do
    {:ok, Http.build_struct(Customer, data)}
  end
end

defp customer_path(customer_id), do: "/customers/#{encode_path_segment(customer_id)}"

defp validate_customer_id(customer_id) when is_binary(customer_id) do
  if String.trim(customer_id) == "" do
    {:error, :invalid_customer_id}
  else
    :ok
  end
end

defp validate_customer_id(_customer_id), do: {:error, :invalid_customer_id}

defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

**What to copy verbatim:**
- The `with :ok <- validate_X_id(id), {:ok, %{"data" => data}} when is_map(data) <- Http.request(...)` chain.
- The `defp X_path(id), do: "/.../#{encode_path_segment(id)}"` shape.
- The `defp validate_X_id/1` two-clause pattern: `is_binary` guard + `String.trim/1 == ""` check, then catch-all returning `{:error, :invalid_X_id}`.
- The `defp encode_path_segment/1` one-liner using `URI.encode(id, &URI.char_unreserved?/1)`.

**What changes for Phase 5:**
- `validate_subscription_id/1` returning `{:error, :invalid_subscription_id}`.
- `subscription_path(id)` returning `"/subscriptions/#{encode_path_segment(id)}"`.
- The terminal mapping is `build_subscription(data)` (Pattern C), NOT `Http.build_struct(Subscription, data)` directly — because of nested-struct post-processing.

#### Pattern C: Per-resource nested-struct post-processing (THE central Phase 5 pattern)

**Analog:** `lib/paddle/transactions.ex` lines 35-45

```elixir
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

**What to copy verbatim:**
- The function name shape: `defp build_<entity>/1` (singular noun).
- The `when is_map(data)` guard on the head.
- First line: `entity = Http.build_struct(<EntityModule>, data)` — Phase 5 reuses the shared shallow mapper for top-level fields.
- The `case data["<nested_key>"] do nested when is_map(nested) -> %{entity | <nested_key>: Http.build_struct(<NestedModule>, nested)}; _ -> entity end` pattern. The catch-all (`_ ->`) covers both `nil` and any unexpected non-map shape, leaving the field as `nil` from the base struct.
- String-keyed access (`data["checkout"]`, not `data[:checkout]`) — Paddle responses are always string-keyed JSON-decoded maps.

**What changes for Phase 5:**
- Two nested keys instead of one: `"scheduled_change"` and `"management_urls"`.
- Per RESEARCH.md Open Question 2 (and CONTEXT.md "Claude's Discretion"), either two inline `case` clauses chained with `|>` rebinding, or a single private `put_nested_struct/4` helper, is acceptable. Two inline `case` clauses match `transactions.ex` precedent line-for-line and are recommended for fidelity. Example:

  ```elixir
  defp build_subscription(data) when is_map(data) do
    subscription = Http.build_struct(Subscription, data)

    subscription =
      case data["scheduled_change"] do
        sc when is_map(sc) ->
          %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}

        _ ->
          subscription
      end

    case data["management_urls"] do
      mu when is_map(mu) ->
        %{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}

      _ ->
        subscription
    end
  end
  ```

#### Pattern D: `list/2` — filter-based pagination (top-level, NOT customer-scoped)

**Analog:** `lib/paddle/customers/addresses.ex` lines 29-41 (mechanics) + lines 74-83 (`normalize_params/1`)

```elixir
def list(%Paddle.Client{} = client, customer_id, params \\ []) do
  with :ok <- validate_customer_id(customer_id),
       {:ok, params} <- normalize_params(params),
       query <- Attrs.allowlist(params, @list_allowlist),
       {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
         Http.request(client, :get, customer_addresses_path(customer_id), params: query) do
    {:ok,
     %Paddle.Page{
       data: Enum.map(data, &Http.build_struct(Address, &1)),
       meta: meta
     }}
  end
end

# ...

defp normalize_params(params) when is_list(params) do
  if Keyword.keyword?(params) do
    {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
  else
    {:error, :invalid_params}
  end
end

defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
defp normalize_params(_params), do: {:error, :invalid_params}
```

**What to copy verbatim:**
- The `with` chain order: `normalize_params -> Attrs.allowlist -> Http.request(..., params: query)`.
- The Req `params:` option (NOT a query-string-built path) — Req encodes it.
- The success branch: `{:ok, %Paddle.Page{data: Enum.map(data, &<builder>(&1)), meta: meta}}`.
- The three-clause `normalize_params/1` with `Keyword.keyword?/1` guard, map fall-through, and catch-all `:invalid_params`. Copy this verbatim — it's correct as-is.
- The module attribute pattern: `@list_allowlist ~w(...)` (sigil with space-separated tokens).

**What changes for Phase 5:**
- **Drop** the `:ok <- validate_customer_id(customer_id)` step — there is no positional ID. The function signature is `def list(%Paddle.Client{} = client, params \\ [])`, two args (client + params).
- Drop the `customer_id` parameter from the path — fixed path `"/subscriptions"`.
- Builder is `&build_subscription/1` (Pattern C), NOT `&Http.build_struct(Subscription, &1)` directly — required for nested-struct hydration on each list item.
- Allowlist per CONTEXT.md D-12:
  ```elixir
  @list_allowlist ~w(id customer_id address_id price_id status
                     scheduled_change_action collection_mode
                     next_billed_at order_by after per_page)
  ```

#### Pattern E: Two named cancel functions over a shared private `do_cancel/3`

**No exact existing analog.** No current resource module exposes two public functions backed by a single private helper. The closest mechanics come from `transactions.ex` (`POST /...` with `json: body`) and `customers.ex` (path-with-encoded-id pattern).

**Compose from:**
- `lib/paddle/customers.ex:18-24` (with-chain shape, validation, path building, `data` envelope unwrap).
- `lib/paddle/transactions.ex:7-19` (`Http.request(client, :post, "/...", json: body)` pattern with `{:ok, %{"data" => data}}` unwrap).

**Phase 5 application:**
```elixir
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

defp cancel_path(id), do: "/subscriptions/#{encode_path_segment(id)}/cancel"
```

**Key requirements (from CONTEXT.md):**
- D-07: Validation lives **inside** `do_cancel/3` (not in each public function), so the public bodies stay one-liners.
- D-06: Both cancel functions return `{:ok, %Paddle.Subscription{}}` on success — Paddle returns the full updated subscription envelope on both modes. Do NOT short-circuit to `:ok` or `{:ok, :canceled}`.
- D-04/D-05: NO polymorphic `cancel/3` public function. NO `mode:` keyword. The two named functions are the safety property.

#### Pattern F: Public function `with`-chain success-only return (already covered above)

All four public functions follow the same skeleton: `with` chain → `{:ok, ...}` on the happy path. Failures from `validate_*`, `normalize_params`, and `Http.request/4` propagate through the `with` short-circuit. This is Phase 3/4 precedent and Phase 5 does not deviate.

---

### `test/paddle/subscription_test.exs` (test, struct shape + `build_struct/2`)

**Analog:** `test/paddle/transaction_test.exs` (entire file, 100 lines)

#### Imports + Module Header

**Analog** (`test/paddle/transaction_test.exs:1-7`):
```elixir
defmodule Paddle.TransactionTest do
  use ExUnit.Case, async: true

  alias Paddle.Http
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout
```

**What to copy verbatim:**
- `use ExUnit.Case, async: true` — every existing test file is async.
- Aliases: `Paddle.Http` (for `build_struct/2`), the entity, and any nested struct under test.

#### Struct Shape Test

**Analog** (`test/paddle/transaction_test.exs:8-32`):
```elixir
describe "%Paddle.Transaction{} struct" do
  test "exposes the promoted transaction fields plus raw_data" do
    assert %Transaction{
             id: nil,
             status: nil,
             # ... all 20 fields ...
             raw_data: nil
           } = %Transaction{}
  end
```

**What to copy:**
- One `describe` block per struct module under test.
- One test that pattern-matches the empty struct against an explicit map of all fields = `nil`. This is the "all 24 fields exist and default to nil" coverage.

#### `build_struct/2` Mapping Test

**Analog** (`test/paddle/transaction_test.exs:34-80`):
```elixir
test "build_struct/2 promotes known transaction keys and preserves the full payload in raw_data" do
  data = %{
    "id" => "txn_01",
    "status" => "ready",
    # ... full payload including an "ignored_key" => "kept in raw only" ...
  }

  assert %Transaction{
           id: "txn_01",
           # ... all promoted fields ...
           raw_data: ^data
         } = Http.build_struct(Transaction, data)
end
```

**What to copy verbatim:**
- The `^data` pin in the `raw_data:` slot — guarantees the entire input payload is preserved.
- An `"ignored_key" => "kept in raw only"` entry in the input map — proves un-declared keys land only in `raw_data`, not in the typed slots.
- Keys in the input map are strings (Paddle JSON shape), values match the asserted struct field types.

#### Tiny-Nested-Struct Test

**Analog** (`test/paddle/transaction_test.exs:83-99`):
```elixir
describe "%Paddle.Transaction.Checkout{} struct" do
  test "exposes only url and raw_data" do
    assert %Checkout{url: nil, raw_data: nil} = %Checkout{}
  end

  test "build_struct/2 promotes the checkout url and preserves the full payload in raw_data" do
    data = %{
      "url" => "https://approved.example.com/checkout?_ptxn=txn_01",
      "ignored_nested_key" => "kept in raw only"
    }

    assert %Checkout{
             url: "https://approved.example.com/checkout?_ptxn=txn_01",
             raw_data: ^data
           } = Http.build_struct(Checkout, data)
  end
end
```

**What to copy:**
- Same two-test shape (empty struct + `build_struct/2` round-trip with an extra ignored key) for both `ScheduledChange` and `ManagementUrls`.
- The empty-struct test asserts every field is `nil` (3 or 4 fields).
- The mapping test includes an `"ignored_nested_key" => "kept in raw only"` entry to prove shallow-mapper discipline.

**What changes for Phase 5:**
- Three `describe` blocks instead of two: `%Paddle.Subscription{}`, `%Paddle.Subscription.ScheduledChange{}`, `%Paddle.Subscription.ManagementUrls{}`.
- For `ManagementUrls`, include at least one assertion exercising `update_payment_method: nil` (per RESEARCH.md Pitfall 5).

---

### `test/paddle/subscriptions_test.exs` (test, adapter-backed resource module — composite)

This is a multi-source composite. Different facets of the test file pull from different existing tests.

#### Helper Functions (verbatim copy)

**Analog:** `test/paddle/transactions_test.exs:369-381` (also identical in `customers_test.exs:182-194` and `customers/addresses_test.exs:285-297`)

```elixir
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

**What to copy:** Both helpers verbatim. They are duplicated across all three existing resource-module test files; Phase 5 follows suit. Do NOT introduce a `test/support/` shared module — the repo does not have one (`test/support/` does not exist).

#### `get/2` Happy Path Test

**Analog:** `test/paddle/customers_test.exs:91-106` (single-entity GET)

```elixir
test "requests the customer path with explicit client passing and returns a typed customer" do
  response_data = customer_payload()

  client =
    client_with_adapter(fn request ->
      assert request.method == :get
      assert request.url.path == "/customers/ctm_01"
      assert request.body == nil

      {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
    end)

  assert {:ok, %Customer{id: "ctm_01", raw_data: ^response_data}} =
           Customers.get(client, "ctm_01")
end
```

**What to copy verbatim:**
- The `client_with_adapter(fn request -> ... end)` adapter-installation pattern.
- The three GET-specific assertions inside the adapter: `request.method == :get`, `request.url.path == "/path"`, `request.body == nil`.
- The fixture-based response: `Req.Response.new(status: 200, body: %{"data" => response_data})`.
- The terminal pattern-match: `assert {:ok, %Entity{id: "...", raw_data: ^response_data}} = Resource.get(client, "id")`.

**Phase 5 addition:** Also assert the nested-struct presence on the result, e.g.:
```elixir
assert %ManagementUrls{cancel: "https://buyer-portal.paddle.com/..."} = subscription.management_urls
```
And for the `subscription_payload_active_with_scheduled_change/0` fixture:
```elixir
assert %ScheduledChange{action: "cancel", effective_at: "...", resume_at: nil} =
         subscription.scheduled_change
```

#### `get/2` URL Encoding Test

**Analog:** `test/paddle/customers_test.exs:116-126`

```elixir
test "url-encodes customer ids before building the request path" do
  client =
    client_with_adapter(fn request ->
      assert request.method == :get
      assert request.url.path == "/customers/ctm%2Fwith%3Freserved"

      {request, Req.Response.new(status: 200, body: %{"data" => customer_payload()})}
    end)

  assert {:ok, %Customer{}} = Customers.get(client, "ctm/with?reserved")
end
```

**What to copy verbatim:** The exact assertion shape — pass an ID containing `/` and `?`, assert the encoded path uses `%2F` and `%3F`.

**Phase 5 changes:** `"sub/with?reserved"` → `/subscriptions/sub%2Fwith%3Freserved`.

#### `get/2` Validation Tuple Test

**Analog:** `test/paddle/customers_test.exs:108-114`

```elixir
test "returns an explicit error for blank customer ids" do
  client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

  assert {:error, :invalid_customer_id} = Customers.get(client, nil)
  assert {:error, :invalid_customer_id} = Customers.get(client, "")
  assert {:error, :invalid_customer_id} = Customers.get(client, "   ")
end
```

**What to copy verbatim:**
- The single-line adapter (`&{&1, Req.Response.new(...)}`) when the test never expects HTTP to fire.
- Four assertions covering `nil`, `""`, `"   "`, and an integer — Phase 5 adds the integer per RESEARCH.md Plan 3 test matrix.

**Phase 5 changes:** Replace `:invalid_customer_id` → `:invalid_subscription_id`.

#### `list/2` Pagination Test (with `next_cursor` assertion)

**Analog:** `test/paddle/customers/addresses_test.exs:79-108`

```elixir
test "returns a typed Paddle.Page with preserved meta and a working next cursor" do
  response_data = [address_payload(), archived_address_payload()]

  meta = %{
    "pagination" => %{
      "estimated_total" => 2,
      "next" => "/customers/ctm_01/addresses?after=cursor_123",
      "per_page" => 2
    }
  }

  client =
    client_with_adapter(fn request ->
      assert request.method == :get
      assert request.url.path == "/customers/ctm_01/addresses"
      assert URI.decode_query(request.url.query) == %{}
      assert request.body == nil

      {request, Req.Response.new(status: 200, body: %{"data" => response_data, "meta" => meta})}
    end)

  assert {:ok, %Paddle.Page{data: [%Address{}, %Address{}], meta: ^meta} = page} =
           Addresses.list(client, "ctm_01")

  assert Enum.map(page.data, & &1.id) == ["add_01", "add_02"]
  assert Enum.at(page.data, 0).raw_data == address_payload()
  assert Enum.at(page.data, 1).raw_data == archived_address_payload()
  assert Paddle.Page.next_cursor(page) == "/customers/ctm_01/addresses?after=cursor_123"
end
```

**What to copy verbatim:**
- The `meta` map shape (`"pagination" => %{"estimated_total" => ..., "next" => ..., "per_page" => ...}`).
- The `assert URI.decode_query(request.url.query) == %{}` empty-query assertion when no params are passed.
- The `assert request.body == nil` for GET requests.
- The two-arg `Addresses.list(client, "ctm_01")` style — but Phase 5 drops the second arg (no positional ID).
- The terminal `assert Paddle.Page.next_cursor(page) == "<full URL>"` — note this is the **entire** `next` string, not just an extracted cursor (per RESEARCH.md Pitfall 2).

**Phase 5 changes:**
- Drop the `customer_id` positional. Call: `Subscriptions.list(client)`.
- Path is `/subscriptions`.
- Per RESEARCH.md Pitfall 2: Phase 5's `meta.pagination.next` should match Paddle's real shape — a **full URL** like `"https://api.paddle.com/subscriptions?after=sub_..."`. Tests assert this full URL string; do NOT assert a bare `"sub_..."` cursor.

#### `list/2` Allowlist Forwarding Test

**Analog:** `test/paddle/customers/addresses_test.exs:110-139`

```elixir
test "forwards only the allowlisted query params to the adapter" do
  client =
    client_with_adapter(fn request ->
      assert request.method == :get
      assert request.url.path == "/customers/ctm_01/addresses"

      assert URI.decode_query(request.url.query) == %{
               "after" => "cursor_123",
               "id" => "add_01",
               "order_by" => "updated_at[DESC]",
               "per_page" => "50",
               "search" => "Main",
               "status" => "active"
             }

      {request, Req.Response.new(status: 200, body: %{"data" => [], "meta" => %{}})}
    end)

  assert {:ok, %Paddle.Page{data: [], meta: %{}}} =
           Addresses.list(client, "ctm_01",
             id: "add_01",
             after: "cursor_123",
             per_page: 50,
             order_by: "updated_at[DESC]",
             status: "active",
             search: "Main",
             city: "New York",
             ignored: "drop me"
           )
end
```

**What to copy verbatim:**
- `URI.decode_query(request.url.query)` returns a string-keyed map; assert against an explicit expected map.
- Pass at least one unsupported key (`city`, `ignored`) to prove allowlist filtering.
- Note: `per_page: 50` (integer) becomes `"per_page" => "50"` (string) after URL encoding by Req — assert the string form.

**Phase 5 changes:**
- Pass all 11 allowlisted keys per CONTEXT.md D-12: `id, customer_id, address_id, price_id, status, scheduled_change_action, collection_mode, next_billed_at, order_by, after, per_page`.
- Pass at least one unsupported key (e.g., `ignored: "drop"`) to prove dropping.

#### `list/2` Validation Tuple Test (No Positional ID)

**Analog:** `test/paddle/customers/addresses_test.exs:154-160`

```elixir
test "returns exact validation tuples before dispatch" do
  client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => [], "meta" => %{}})})

  assert {:error, :invalid_customer_id} = Addresses.list(client, nil)
  assert {:error, :invalid_customer_id} = Addresses.list(client, " ")
  assert {:error, :invalid_params} = Addresses.list(client, "ctm_01", "nope")
end
```

**What to copy:** The `:invalid_params` assertion shape with a non-keyword/non-map value as second arg.

**Phase 5 changes:**
- No `:invalid_customer_id` cases (no positional ID).
- Three `:invalid_params` assertions: `Subscriptions.list(client, "nope")`, `Subscriptions.list(client, 42)`, `Subscriptions.list(client, [1, 2, 3])` (non-keyword bare list).

#### `cancel/2` and `cancel_immediately/2` POST Body Tests

**Analog:** `test/paddle/transactions_test.exs:14-50` (POST with JSON body assertion)

```elixir
client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/transactions"

    assert decode_json_body(request.body) == %{
             "address_id" => "add_01",
             # ...
           }

    {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
  end)
```

**What to copy verbatim:**
- `request.method == :post`.
- `request.url.path == "/<full path>"`.
- `decode_json_body(request.body) == %{...exact body map...}`.

**Phase 5 application:**
- For `cancel/2`: assert `decode_json_body(request.body) == %{"effective_from" => "next_billing_period"}`.
- For `cancel_immediately/2`: assert `decode_json_body(request.body) == %{"effective_from" => "immediately"}`.
- Path: `/subscriptions/sub_01/cancel`.
- Response status: 200 (Paddle returns the updated subscription, not a 204). Body: `%{"data" => subscription_payload_*}`.
- Pattern-match the result: `{:ok, %Subscription{status: "active", scheduled_change: %ScheduledChange{action: "cancel"}}}` (for `cancel/2`) or `{:ok, %Subscription{status: "canceled", scheduled_change: nil}}` (for `cancel_immediately/2`).

#### Error Propagation Test (`%Paddle.Error{}`)

**Analog:** `test/paddle/transactions_test.exs:319-352`

```elixir
test "preserves non-2xx API error tuples from Paddle.Http.request/4" do
  client =
    client_with_adapter(fn request ->
      response =
        Req.Response.new(
          status: 422,
          body: %{
            "error" => %{
              "type" => "validation_error",
              "code" => "invalid_field",
              "detail" => "items is invalid",
              "errors" => []
            }
          }
        )
        |> Req.Response.put_header("x-request-id", "req_422")

      {request, response}
    end)

  assert {:error,
          %Error{
            status_code: 422,
            request_id: "req_422",
            type: "validation_error",
            code: "invalid_field",
            message: "items is invalid"
          }} = Transactions.create(client, ...)
end
```

**What to copy verbatim:**
- The full `Req.Response.new(status: ..., body: %{"error" => %{...}})` shape with `type/code/detail/errors` keys.
- The `Req.Response.put_header("x-request-id", "req_...")` pipe.
- The `%Paddle.Error{status_code: ..., request_id: ..., type: ..., code: ..., message: ...}` pattern-match — `Paddle.Error.from_response/1` maps `detail` → `message`.

**Phase 5 application — TWO error tests:**
1. **404 entity_not_found** (for `get/2`, `cancel/2`, `cancel_immediately/2`): `code: "entity_not_found"`, status 404.
2. **422 subscription_locked_pending_changes** (for cancel paths): `code: "subscription_locked_pending_changes"`, status 422 (per RESEARCH.md Assumption A1; the SDK does not depend on the precise status, only on `code` propagation).

#### Transport Exception Passthrough Test

**Analog:** `test/paddle/transactions_test.exs:354-366`

```elixir
test "surfaces transport exceptions unchanged" do
  client =
    client_with_adapter(fn request ->
      {request, %Req.TransportError{reason: :timeout}}
    end)

  assert {:error, %Req.TransportError{reason: :timeout}} =
           Transactions.create(client, ...)
end
```

**What to copy verbatim:** The adapter returns a `%Req.TransportError{}` struct (not a `Req.Response{}`); the assertion pattern-matches the same struct unchanged.

**Phase 5 application:** One test per public function (`get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`) — or one consolidated test that exercises all four if the planner judges that's clearer. Either is acceptable per Phase 3/4 precedent (`addresses_test.exs:264-282` runs separate tests for `update/4` and `list/3`).

#### Fixture Builders

**Analog:** `test/paddle/transactions_test.exs:383-405` and `test/paddle/customers/addresses_test.exs:299-335` (multi-fixture pattern)

```elixir
defp transaction_payload do
  %{"id" => "txn_01", "status" => "ready", ...}
end

# OR (multi-fixture pattern from addresses_test):
defp address_payload do %{...} end
defp archived_address_payload do %{...} end
```

**What to copy:**
- One `defp <entity>_payload` per distinct response shape needed.
- All keys are strings (matches Paddle JSON-decoded shape).
- All field names match the entity's struct field list 1:1, with extras allowed (they land in `raw_data`).

**Phase 5 changes — three fixture builders per RESEARCH.md Plan 3:**
- `subscription_payload_canceled/0` — `status: "canceled"`, `scheduled_change: nil`, `management_urls` populated.
- `subscription_payload_active_with_scheduled_change/0` — `status: "active"`, `scheduled_change` populated with `action: "cancel"`.
- `subscription_payload_manual_no_payment_link/0` — `collection_mode: "manual"`, `management_urls.update_payment_method: nil` (covers RESEARCH.md Pitfall 5).

The latter two should compose from the first using `Map.merge(subscription_payload_canceled(), %{...overrides...})` — see RESEARCH.md lines 770-791 for the exact composition pattern.

---

## Shared Patterns

### Pattern: Response Envelope Unwrap (`%{"data" => data}`)

**Source:** `lib/paddle/customers.ex:13`, `lib/paddle/customers.ex:20`, `lib/paddle/customers.ex:30`, `lib/paddle/transactions.ex:15`, `lib/paddle/customers/addresses.ex:14`, etc.

**Apply to:** Every Phase 5 public function (`get/2`, `cancel/2`, `cancel_immediately/2` use single-data form; `list/2` uses paginated form).

**Single-entity form** (used in `get/2`, `cancel/2`, `cancel_immediately/2`):
```elixir
{:ok, %{"data" => data}} when is_map(data) <- Http.request(client, ...)
```

**Paginated form** (used in `list/2`):
```elixir
{:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <- Http.request(client, ..., params: query)
```

The `is_map(data)` / `is_list(data) and is_map(meta)` guards are load-bearing — they protect against malformed Paddle responses or transport-layer surprises and let `Http.request/4` errors short-circuit through the `with`. Copy verbatim.

### Pattern: Public Function Signature Discipline

**Source:** All existing resource modules (`lib/paddle/customers.ex`, `lib/paddle/transactions.ex`, `lib/paddle/customers/addresses.ex`).

**Apply to:** All four Phase 5 public functions.

- First parameter is always `%Paddle.Client{} = client` (or `%Client{} = client` if `Client` is aliased) — pattern-match enforces type at the boundary.
- No defaults except for `params \\ []` on list functions.
- No `opts \\ []` keyword for one-off transport options — these go through the established `Http.request/4` boundary, not exposed at the resource layer.

### Pattern: Error Module Reference

**Source:** `lib/paddle/error.ex` (transitively via `Paddle.Http.request/4`).

**Apply to:** Phase 5 has zero direct interaction with `Paddle.Error` in production code. It only appears in tests as `alias Paddle.Error` to pattern-match the propagated `%Error{...}` from non-2xx responses. The SDK does not construct `%Error{}` structs anywhere in resource modules — `Paddle.Http.request/4` does it once at the transport boundary.

### Pattern: Path Encoding via `URI.encode/2`

**Source:** `lib/paddle/customers.ex:48`, `lib/paddle/customers/addresses.ex:85`.

**Apply to:** `subscription_path/1` and `cancel_path/1` (both consume `subscription_id`).

```elixir
defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

Copy verbatim. Same one-liner exists in both existing analog files.

### Pattern: Adapter-Backed Test Transport (Mock)

**Source:** `test/paddle/transactions_test.exs:369-381`, identical in `customers_test.exs:182-194` and `customers/addresses_test.exs:285-297`.

**Apply to:** `test/paddle/subscriptions_test.exs` only (not `subscription_test.exs` — that file uses `Http.build_struct/2` directly without HTTP).

**Critical:** Per RESEARCH.md Pitfall 3, NO live-API tests for cancel paths. Cancellation is irreversible per Paddle docs. All Phase 5 transport tests use `Req.new(adapter: fn req -> ... end)` exclusively. Document this in the resource module's `@moduledoc` (or test-file header) so future contributors do not add a `@tag :integration` block hitting the sandbox.

### Pattern: `import_meta` Stays as a Plain Map

**Source:** `lib/paddle/customer.ex` (has `:import_meta` field), `lib/paddle/address.ex`, `lib/paddle/transaction.ex` (no import_meta — Transaction doesn't expose it).

**Apply to:** `lib/paddle/subscription.ex` field `:import_meta`.

Per CONTEXT.md D-20, `:import_meta` is in the field list but is NEVER promoted to a typed struct in Phase 5. It stays as a string-keyed map (or nil) — `Http.build_struct/2` handles it as-is.

---

## No Analog Found

None. Every Phase 5 file has at least one strong existing analog. The only "novel" composition is the resource module itself, which combines patterns from three existing analogs (`transactions.ex`, `customers.ex`, `customers/addresses.ex`) — the constituent patterns are all exact line-level matches.

The closest thing to a gap is the **two-named-cancel-functions over a private `do_cancel/3` helper** shape (Pattern E in `subscriptions.ex`). No existing module has that exact composition, but every part of it (POST with JSON body, `with`-chain validation, shared private helper) maps cleanly to existing precedent.

## Metadata

**Analog search scope:**
- `lib/paddle/` — all `.ex` files
- `lib/paddle/customers/` — `addresses.ex`
- `lib/paddle/transaction/` — `checkout.ex`
- `test/paddle/` — `customers_test.exs`, `transactions_test.exs`, `transaction_test.exs`
- `test/paddle/customers/` — `addresses_test.exs`

**Files scanned:** 11 lib files + 7 test files = 18 total (out of ~20 in the repo).

**Confidence in pattern fidelity:** HIGH. Phase 5 is mechanically a repeat of Phase 3/4 patterns with two new wrinkles (filter-based list, two named cancel functions) that have direct line-level analogs for every constituent piece.

**Pattern extraction date:** 2026-04-29

## PATTERN MAPPING COMPLETE
