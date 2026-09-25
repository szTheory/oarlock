# Phase 4: Transactions & Hosted Checkout - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/paddle/transaction.ex` | model | transform | `lib/paddle/customer.ex` | exact |
| `lib/paddle/transaction/checkout.ex` | model | transform | `lib/paddle/customer.ex` | role-match |
| `lib/paddle/transactions.ex` | service | request-response | `lib/paddle/customers.ex` | exact |
| `test/paddle/transaction_test.exs` | test | transform | `test/paddle/customer_test.exs` | exact |
| `test/paddle/transactions_test.exs` | test | request-response | `test/paddle/customers_test.exs` + `test/paddle/customers/addresses_test.exs` | exact |

## Pattern Assignments

### `lib/paddle/transaction.ex` (model, transform)

**Analog:** [lib/paddle/customer.ex](/Users/jon/projects/oarlock/lib/paddle/customer.ex:1)

**Struct module pattern** (lines 1-15):
```elixir
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

**Mapping constraint to preserve** from [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:17) (lines 17-27):
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

**Apply to Phase 4**
- Keep `Paddle.Transaction` as a plain `defstruct` module with promoted top-level fields only.
- Include `:checkout` in `defstruct`, but rely on a resource-layer helper to hydrate it into a nested struct.
- Keep `:raw_data` as the last field so the shared mapper behavior stays consistent.

---

### `lib/paddle/transaction/checkout.ex` (model, transform)

**Analog:** [lib/paddle/customer.ex](/Users/jon/projects/oarlock/lib/paddle/customer.ex:1)

**Tiny nested struct pattern** (lines 1-15):
```elixir
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

**Apply to Phase 4**
- Make `Paddle.Transaction.Checkout` a tiny dedicated struct module, not a string-key map.
- Follow the same entity convention: explicit fields plus `:raw_data`.
- First-pass field list should stay narrow: `:url` and `:raw_data`.

---

### `lib/paddle/transactions.ex` (service, request-response)

**Analog:** [lib/paddle/customers.ex](/Users/jon/projects/oarlock/lib/paddle/customers.ex:1)

**Imports and allowlist pattern** (lines 1-7):
```elixir
defmodule Paddle.Customers do
  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Http

  @create_allowlist ~w(email name custom_data locale)
  @update_allowlist ~w(name email status custom_data locale)
```

**Core create pattern** (lines 9-15):
```elixir
def create(%Client{} = client, attrs) do
  with {:ok, attrs} <- normalize_attrs(attrs),
       body <- allowlist_attrs(attrs, @create_allowlist),
       {:ok, %{"data" => data}} when is_map(data) <- Http.request(client, :post, "/customers", json: body) do
    {:ok, Http.build_struct(Customer, data)}
  end
end
```

**Validation and normalization pattern** (lines 47-74):
```elixir
defp normalize_attrs(attrs) when is_list(attrs) do
  if Keyword.keyword?(attrs) do
    {:ok, attrs |> Enum.into(%{}) |> normalize_map_keys()}
  else
    {:error, :invalid_attrs}
  end
end

defp normalize_attrs(attrs) when is_map(attrs), do: {:ok, normalize_map_keys(attrs)}
defp normalize_attrs(_attrs), do: {:error, :invalid_attrs}

defp normalize_map_keys(attrs) do
  Enum.reduce(attrs, %{}, fn
    {key, value}, acc when is_atom(key) -> Map.put(acc, Atom.to_string(key), value)
    {key, value}, acc when is_binary(key) -> Map.put(acc, key, value)
    {_key, _value}, acc -> acc
  end)
end

defp allowlist_attrs(attrs, allowed_keys) do
  Enum.reduce(attrs, %{}, fn {key, value}, acc ->
    if key in allowed_keys do
      Map.put(acc, key, value)
    else
      acc
    end
  end)
end
```

**Transport/error boundary pattern** from [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:2) (lines 2-14):
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

**Phase 4-specific extension to add**
- Copy the `create/2` resource-module shape directly from `Paddle.Customers.create/2`.
- Keep local validation lightweight, but add explicit checks for nonblank `customer_id`, nonblank `address_id`, and non-empty `items`.
- Reuse the same `map | keyword -> normalized string keys -> allowlist` pipeline, but add a private builder for nested `checkout.url` and the internal `"collection_mode" => "automatic"` constant.
- Do not change `Paddle.Http.request/4`; unwrap `%{"data" => data}` locally in `Paddle.Transactions`.
- Add a private `build_transaction/1` helper after `Http.build_struct/2` to replace the shallow `checkout` map with `%Paddle.Transaction.Checkout{}`.

**Nested mapping precedent to respect** from [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:17) (lines 17-27):
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

This is why `checkout` must be post-processed in `Paddle.Transactions` instead of expecting recursive mapping from the shared helper.

---

### `test/paddle/transaction_test.exs` (test, transform)

**Analog:** [test/paddle/customer_test.exs](/Users/jon/projects/oarlock/test/paddle/customer_test.exs:1)

**Struct contract pattern** (lines 7-21):
```elixir
describe "struct" do
  test "exposes the promoted customer fields plus raw_data" do
    assert %Customer{
             id: nil,
             name: nil,
             email: nil,
             marketing_consent: nil,
             status: nil,
             custom_data: nil,
             locale: nil,
             created_at: nil,
             updated_at: nil,
             import_meta: nil,
             raw_data: nil
           } = %Customer{}
  end
end
```

**Build-struct assertion pattern** (lines 24-51):
```elixir
test "build_struct/2 promotes known customer keys and preserves the full payload in raw_data" do
  data = %{
    "id" => "ctm_01",
    "name" => "Ada Lovelace",
    "email" => "ada@example.com",
    "status" => "active",
    "custom_data" => %{"crm_id" => "crm_123"},
    "locale" => "en",
    "created_at" => "2024-04-12T10:15:30Z",
    "updated_at" => "2024-04-13T11:16:31Z",
    "import_meta" => %{"imported_from" => "legacy"},
    "marketing_consent" => false,
    "ignored_key" => "kept in raw only"
  }

  assert %Customer{
           id: "ctm_01",
           name: "Ada Lovelace",
           email: "ada@example.com",
           status: "active",
           custom_data: %{"crm_id" => "crm_123"},
           locale: "en",
           created_at: "2024-04-12T10:15:30Z",
           updated_at: "2024-04-13T11:16:31Z",
           import_meta: %{"imported_from" => "legacy"},
           marketing_consent: false,
           raw_data: ^data
         } = Http.build_struct(Customer, data)
end
```

**Apply to Phase 4**
- Add one struct-shape test for `%Paddle.Transaction{}`.
- Add one focused mapping test that proves top-level fields populate and `raw_data` is preserved.
- Add a second focused test for `%Paddle.Transaction.Checkout{}` so the nested `url` contract is explicit.

---

### `test/paddle/transactions_test.exs` (test, request-response)

**Analogs:** [test/paddle/customers_test.exs](/Users/jon/projects/oarlock/test/paddle/customers_test.exs:1), [test/paddle/customers/addresses_test.exs](/Users/jon/projects/oarlock/test/paddle/customers/addresses_test.exs:1)

**Req adapter harness pattern** from `test/paddle/customers_test.exs` (lines 182-194):
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

**Create request-shape assertion pattern** from `test/paddle/customers_test.exs` (lines 9-41):
```elixir
describe "create/2" do
  test "posts only the allowlisted create attrs and returns a typed customer" do
    response_data = customer_payload()

    client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/customers"
        assert decode_json_body(request.body) == %{
                 "custom_data" => %{"crm_id" => "crm_123"},
                 "email" => "ada@example.com",
                 "locale" => "en",
                 "name" => "Ada Lovelace"
               }

        {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
      end)

    assert {:ok,
            %Customer{
              id: "ctm_01",
              email: "ada@example.com",
              raw_data: ^response_data
            }} =
             Customers.create(client, ...)
  end
end
```

**Validation-tuple pattern** from `test/paddle/customers_test.exs` (lines 44-47) and `test/paddle/customers/addresses_test.exs` (lines 154-160, 203-216):
```elixir
assert {:error, :invalid_attrs} = Customers.create(client, "nope")
assert {:error, :invalid_customer_id} = Addresses.list(client, nil)
assert {:error, :invalid_params} = Addresses.list(client, "ctm_01", "nope")
assert {:error, :invalid_address_id} = Addresses.update(client, "ctm_01", "", %{})
```

**Error propagation pattern** from `test/paddle/customers_test.exs` (lines 50-88):
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
              "detail" => "Email is invalid",
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
            message: "Email is invalid"
          }} = Customers.create(client, %{email: "invalid"})
end
```

**Apply to Phase 4**
- Main happy-path test should assert `POST /transactions`, curated request body, explicit automatic collection semantics, and typed `%Paddle.Transaction{checkout: %{url: ...}}`.
- Add validation tests for invalid attrs container, blank `customer_id`, blank `address_id`, empty `items`, and malformed item entries.
- Preserve current public behavior for API errors and transport exceptions unchanged.
- Assert specifically on `transaction.checkout.url`; that is the new contract this phase introduces beyond prior entity tests.

## Shared Patterns

### Transport Boundary
**Source:** [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:2)
**Apply to:** `lib/paddle/transactions.ex`, `test/paddle/transactions_test.exs`
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

### Attr Normalization And Allowlisting
**Source:** [lib/paddle/customers.ex](/Users/jon/projects/oarlock/lib/paddle/customers.ex:47)
**Apply to:** `lib/paddle/transactions.ex`
```elixir
defp normalize_attrs(attrs) when is_list(attrs) do
  if Keyword.keyword?(attrs) do
    {:ok, attrs |> Enum.into(%{}) |> normalize_map_keys()}
  else
    {:error, :invalid_attrs}
  end
end

defp normalize_attrs(attrs) when is_map(attrs), do: {:ok, normalize_map_keys(attrs)}
defp normalize_attrs(_attrs), do: {:error, :invalid_attrs}

defp normalize_map_keys(attrs) do
  Enum.reduce(attrs, %{}, fn
    {key, value}, acc when is_atom(key) -> Map.put(acc, Atom.to_string(key), value)
    {key, value}, acc when is_binary(key) -> Map.put(acc, key, value)
    {_key, _value}, acc -> acc
  end)
end
```

### Raw Payload Preservation
**Source:** [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:17)
**Apply to:** `lib/paddle/transaction.ex`, `lib/paddle/transaction/checkout.ex`
```elixir
struct(struct_module, Map.put(attrs, :raw_data, data))
```

### Adapter-Backed Resource Tests
**Source:** [test/paddle/customers_test.exs](/Users/jon/projects/oarlock/test/paddle/customers_test.exs:182)
**Apply to:** `test/paddle/transactions_test.exs`
```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

## No Analog Found

None. Every Phase 4 file has a strong Phase 3 analog; the only new behavior is transaction-specific nested checkout hydration.

## Metadata

**Analog search scope:** `.planning/`, `lib/paddle/`, `test/paddle/`
**Files scanned:** 14
**Pattern extraction date:** 2026-04-28
