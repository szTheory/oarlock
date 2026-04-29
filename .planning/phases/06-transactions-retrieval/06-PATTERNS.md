# Phase 06: Transactions Retrieval - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 2
**Analogs found:** 2 / 2

This phase is a reconciliation-first pattern map. The workspace already contains the likely Phase 6 implementation in `lib/paddle/transactions.ex` and `test/paddle/transactions_test.exs`, so the planner should treat those files as the primary targets to verify and refine, not as missing files to invent from scratch.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/paddle/transactions.ex` | service (resource module) | request-response | `lib/paddle/transactions.ex` with `lib/paddle/subscriptions.ex` as sibling retrieval analog | exact existing implementation |
| `test/paddle/transactions_test.exs` | test (adapter-backed resource contract) | request-response | `test/paddle/transactions_test.exs` with `test/paddle/subscriptions_test.exs` as sibling retrieval analog | exact existing implementation |

## Pattern Assignments

### `lib/paddle/transactions.ex` (service, request-response)

**Primary reconciliation target:** `lib/paddle/transactions.ex`

**Sibling analog:** `lib/paddle/subscriptions.ex`

**Imports / alias pattern** (`lib/paddle/transactions.ex` lines 1-6):
```elixir
defmodule Paddle.Transactions do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout
```

**Single-entity GET pattern** (`lib/paddle/transactions.ex` lines 8-14):
```elixir
def get(%Client{} = client, transaction_id) do
  with :ok <- validate_transaction_id(transaction_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :get, transaction_path(transaction_id)) do
    {:ok, build_transaction(data)}
  end
end
```

**Why this is the exact Phase 6 shape:** this already matches the locked seam from `06-CONTEXT.md`: explicit `%Paddle.Client{}`, lightweight local validation, `GET /transactions/{id}`, reuse of `build_transaction/1`, and unchanged tuple/error boundary.

**Validation + path encoding pattern** (`lib/paddle/transactions.ex` lines 160-168):
```elixir
defp validate_transaction_id(id) when is_binary(id) do
  if String.trim(id) == "", do: {:error, :invalid_transaction_id}, else: :ok
end

defp validate_transaction_id(_id), do: {:error, :invalid_transaction_id}

defp transaction_path(id), do: "/transactions/#{encode_path_segment(id)}"

defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

**Nested typed-struct hydration pattern** (`lib/paddle/transactions.ex` lines 44-54):
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

**Sibling retrieval analog to compare against** (`lib/paddle/subscriptions.ex` lines 13-19, 76-80, 93-96):
```elixir
def get(%Client{} = client, subscription_id) do
  with :ok <- validate_subscription_id(subscription_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :get, subscription_path(subscription_id)) do
    {:ok, build_subscription(data)}
  end
end

defp validate_subscription_id(id) when is_binary(id) do
  if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
end

defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}

defp subscription_path(id), do: "/subscriptions/#{encode_path_segment(id)}"
defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

**Planner guidance:** copy from the current `get/2` in `lib/paddle/transactions.ex` first. Use `lib/paddle/subscriptions.ex` only as the sibling precedent for why the retrieval shape is correct and complete.

---

### `test/paddle/transactions_test.exs` (test, request-response)

**Primary reconciliation target:** `test/paddle/transactions_test.exs`

**Sibling analog:** `test/paddle/subscriptions_test.exs`

**Adapter-backed GET success contract** (`test/paddle/transactions_test.exs` lines 10-32):
```elixir
describe "get/2" do
  test "issues GET /transactions/{id} and returns a typed transaction with hydrated checkout" do
    response_data = transaction_payload()

    client =
      client_with_adapter(fn request ->
        assert request.method == :get
        assert request.url.path == "/transactions/txn_01"
        assert request.body == nil

        {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
      end)

    assert {:ok, %Transaction{} = transaction} = Transactions.get(client, "txn_01")
    assert transaction.raw_data == response_data
    assert transaction.checkout.raw_data == response_data["checkout"]
  end
end
```

**Locked edge-case coverage already present** (`test/paddle/transactions_test.exs` lines 34-93):
```elixir
test "url-encodes transaction ids with reserved characters in the request path" do
  client =
    client_with_adapter(fn request ->
      assert request.url.path == "/transactions/txn%2Fwith%3Freserved"
      {request, Req.Response.new(status: 200, body: %{"data" => transaction_payload()})}
    end)

  assert {:ok, %Transaction{}} = Transactions.get(client, "txn/with?reserved")
end

test "returns :invalid_transaction_id for nil/blank/whitespace/integer ids without dispatching HTTP" do
  client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

  assert {:error, :invalid_transaction_id} = Transactions.get(client, nil)
  assert {:error, :invalid_transaction_id} = Transactions.get(client, "")
  assert {:error, :invalid_transaction_id} = Transactions.get(client, "   ")
  assert {:error, :invalid_transaction_id} = Transactions.get(client, 42)
end

test "preserves a 404 entity_not_found %Paddle.Error{} unchanged" do
  # ...
end

test "surfaces transport exceptions unchanged" do
  # ...
end
```

**Sibling retrieval-test analog** (`test/paddle/subscriptions_test.exs` lines 16-24, 64-84, 86-124):
```elixir
describe "get/2" do
  test "issues GET /subscriptions/{id} and returns a typed canceled subscription with hydrated management_urls and nil scheduled_change" do
    client =
      client_with_adapter(fn request ->
        assert request.method == :get
        assert request.url.path == "/subscriptions/sub_01"
        assert request.body == nil
```

```elixir
  test "url-encodes subscription ids with reserved characters in the request path" do
    # ...
  end

  test "returns :invalid_subscription_id for nil/blank/whitespace/integer ids without dispatching HTTP" do
    # ...
  end

  test "preserves a 404 entity_not_found %Paddle.Error{} unchanged" do
    # ...
  end

  test "surfaces transport exceptions unchanged" do
    # ...
  end
end
```

**Planner guidance:** do not create a new test harness. Extend or validate the existing `describe "get/2"` block in `test/paddle/transactions_test.exs` and use `test/paddle/subscriptions_test.exs` only as the sibling pattern for naming, adapter assertions, and retrieval edge-case coverage symmetry.

## Shared Patterns

### Transport and error boundary
**Source:** `lib/paddle/http.ex` lines 2-14  
**Apply to:** `lib/paddle/transactions.ex` and any future resource `get/2` function

```elixir
def request(%Paddle.Client{} = client, method, path, opts \\ []) do
  opts = Keyword.merge(opts, method: method, url: path)

  case Req.request(client.req, opts) do
    {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
      {:ok, body}

    {:ok, %Req.Response{} = resp} ->
      {:error, Paddle.Error.from_response(resp)}

    {:error, exception} ->
      {:error, exception}
  end
end
```

**What to preserve:** Phase 6 must not wrap or translate these tuples after local validation. Resource modules delegate to `Http.request/4` and pass the result through via `with`.

### Shared struct builder
**Source:** `lib/paddle/http.ex` lines 17-28  
**Apply to:** top-level transaction mapping and nested checkout hydration

```elixir
def build_struct(struct_module, data) when is_map(data) do
  base_struct = struct(struct_module)
  valid_keys = Map.keys(base_struct) |> Enum.map(&to_string/1)

  attrs =
    data
    |> Enum.filter(fn {k, _} -> k in valid_keys end)
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Enum.into(%{})

  struct(struct_module, Map.put(attrs, :raw_data, data))
end
```

**What to preserve:** `raw_data` always points at the exact map given to `build_struct/2`. For checkout hydration, that means passing `data["checkout"]`, not the transaction root.

### Canonical transaction entity surface
**Source:** `lib/paddle/transaction.ex` lines 1-24 and `lib/paddle/transaction/checkout.ex` lines 1-3  
**Apply to:** `Paddle.Transactions.get/2` return shape

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

```elixir
defmodule Paddle.Transaction.Checkout do
  defstruct [:url, :raw_data]
end
```

**What to preserve:** `get/2` returns the same `%Paddle.Transaction{}` surface as `create/2`; only `checkout` is promoted to a nested typed struct in this phase.

### Seam coverage
**Source:** `test/paddle/seam_test.exs` lines 104-125  
**Apply to:** planner verification steps

```elixir
transaction_get_client =
  client_with_adapter(fn request ->
    assert request.method == :get
    assert request.url.path == "/transactions/txn_seam01"
    assert request.body == nil

    {request,
     Req.Response.new(status: 200, body: %{"data" => transaction_payload("completed")})}
  end)

assert {:ok,
        %Transaction{
          id: "txn_seam01",
          customer_id: "ctm_seam01",
          subscription_id: "sub_seam01"
        } = fetched_transaction} =
         Paddle.Transactions.get(transaction_get_client, transaction.id)

assert fetched_transaction.checkout.raw_data == transaction_payload("completed")["checkout"]
```

**What to preserve:** the repo already treats `Transactions.get/2` as part of the Accrue seam. Planner work should include reconciling unit coverage with this existing end-to-end seam expectation.

## No Analog Found

None. Both Phase 6 targets already exist in the workspace and have exact local analogs.

## Metadata

**Analog search scope:** `lib/paddle/*.ex`, `lib/paddle/**/*.ex`, `test/paddle/**/*.exs`, prior phase pattern maps  
**Files scanned:** 9 primary files (`lib/paddle/transactions.ex`, `lib/paddle/subscriptions.ex`, `lib/paddle/http.ex`, `lib/paddle/transaction.ex`, `lib/paddle/transaction/checkout.ex`, `test/paddle/transactions_test.exs`, `test/paddle/subscriptions_test.exs`, `test/paddle/seam_test.exs`, `.planning/phases/05-subscriptions-management/05-PATTERNS.md`)  
**Pattern extraction date:** 2026-04-29
