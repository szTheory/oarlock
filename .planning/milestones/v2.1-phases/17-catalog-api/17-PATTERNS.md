# Phase 17: Catalog API - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/paddle/product.ex` | struct | request-response | `lib/paddle/customer.ex` | exact |
| `lib/paddle/products.ex` | service | read-only list/get | `lib/paddle/subscriptions.ex` | exact |
| `test/paddle/products_test.exs` | test | read-only test | `test/paddle/subscriptions_test.exs` | exact |
| `lib/paddle/price.ex` | struct | request-response | `lib/paddle/customer.ex` | exact |
| `lib/paddle/prices.ex` | service | read-only list/get | `lib/paddle/subscriptions.ex` | exact |
| `test/paddle/prices_test.exs` | test | read-only test | `test/paddle/subscriptions_test.exs` | exact |
| `lib/paddle/events.ex` | service | read-only list/get | `lib/paddle/subscriptions.ex` | exact |
| `test/paddle/events_test.exs` | test | read-only test | `test/paddle/subscriptions_test.exs` | exact |

## Pattern Assignments

### `lib/paddle/product.ex` & `lib/paddle/price.ex` (struct, request-response)

**Analog:** `lib/paddle/customer.ex`

**Struct definition pattern** (lines 1-28):
```elixir
defmodule Paddle.Customer do
  @moduledoc """
  Represents a Paddle Customer.

  The `raw_data` field contains the original, unparsed response from the Paddle API.
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          # ... other fields
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :name,
    # ... other fields
    :raw_data
  ]
end
```

### `lib/paddle/products.ex`, `lib/paddle/prices.ex`, `lib/paddle/events.ex` (service, read-only list/get)

**Analog:** `lib/paddle/subscriptions.ex`

**Imports and module attributes pattern** (lines 24-34):
```elixir
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
  alias Paddle.Subscription # Replace with Product/Price/Event

  @type subscription_id :: String.t()

  @list_allowlist ~w(id status per_page after order_by)
```

**Get pattern** (lines 55-63):
```elixir
  @spec get(Paddle.Client.t(), subscription_id()) ::
          {:ok, Paddle.Subscription.t()} | {:error, Paddle.Error.t() | :invalid_subscription_id}
  def get(%Client{} = client, subscription_id) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, subscription_path(subscription_id)) do
      {:ok, build_subscription(data)} # Note: use Http.build_struct for simple entities
    end
  end
```

**List pattern** (lines 88-96):
```elixir
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/subscriptions", params: query) do
      {:ok, build_page(data, meta)}
    end
  end
```

**Pagination stream/all pattern** (lines 115-120, 142-147):
```elixir
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.Subscription.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end
```

**ID Validation pattern** (lines 565-568) - Note D-05: Use native `String.t()` without regex enforcement:
```elixir
  defp validate_subscription_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
  end

  defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}
```

### Test Files (test/paddle/*_test.exs)

**Analog:** `test/paddle/subscriptions_test.exs`

**Get endpoint test pattern** (lines 16-29):
```elixir
    test "issues GET /subscriptions/{id} and returns a typed subscription" do
      response_data = subscription_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions/sub_01"
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{} = subscription} = Subscriptions.get(client, "sub_01")
      assert subscription.id == "sub_01"
    end
```

**List endpoint test pattern** (lines 127-147):
```elixir
    test "returns a typed %Paddle.Page with hydrated structs and a working full-URL next cursor" do
      response_data = [subscription_payload()]

      meta = %{
        "pagination" => %{
          "per_page" => 50,
          "next" => "https://api.paddle.com/subscriptions?after=cursor_123",
          "has_more" => false,
          "estimated_total" => 1
        }
      }

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions"
          assert URI.decode_query(request.url.query || "") == %{}
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data, "meta" => meta})}
        end)

      assert {:ok, %Page{data: [%Subscription{} = sub], meta: ^meta} = page} = Subscriptions.list(client)
      assert Page.next_cursor(page) == "https://api.paddle.com/subscriptions?after=cursor_123"
    end
```

## Shared Patterns

### Error Handling
**Source:** `lib/paddle/subscriptions.ex` and `test/paddle/subscriptions_test.exs`
**Apply to:** All services
- Use `with` statements that fall through to bubble up standard `%Paddle.Error{}` tuples.
- Return explicit validation atoms (e.g. `{:error, :invalid_product_id}`) for non-string IDs.
- HTTP transport anomalies are normalized automatically by `Paddle.Http.request/4`.

### Strict Struct Hydration (D-01 & D-02)
**Rule:** No `include` payload hydration in the top-level structs.
- Any unexpectedly nested payload (such as `prices` in a `product` response) will be safely absorbed into the `:raw_data` map field on the struct, preventing missing fields or SDK crashes while respecting purely functional isolation.

### Documentation Warnings (D-03 & D-04)
**Rule:** Custom items are ignored by Catalog APIs.
- Products and Prices must include a `@moduledoc` warning that custom items created at checkout cannot be fetched via the REST endpoints.

## Metadata

**Analog search scope:** `lib/paddle/`, `test/paddle/`
**Files scanned:** 25
**Pattern extraction date:** 2026-06-10