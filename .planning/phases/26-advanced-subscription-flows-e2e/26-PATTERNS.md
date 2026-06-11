# Phase 26: Advanced Subscription Flows E2E - Pattern Map

**Mapped:** 2026-06-11
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/paddle/subscriptions.ex` | service | request-response | `lib/paddle/customers.ex` | role-match |
| `lib/paddle/mock_server.ex` | route | request-response | `lib/paddle/mock_server.ex` | exact |
| `test/paddle/subscriptions_test.exs` | test | request-response | `test/paddle/customers_test.exs` | exact |
| `test/paddle/subscription_flows_test.exs` | test | request-response | `test/paddle/seam_test.exs` | role-match |

## Pattern Assignments

### `lib/paddle/subscriptions.ex` (service, request-response)

**Analog:** `lib/paddle/customers.ex`

**Core CRUD pattern** (lines 98-111):
```elixir
  @spec update(Paddle.Client.t(), customer_id(), map() | keyword()) ::
          {:ok, Paddle.Customer.t()}
          | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_attrs}
  def update(%Client{} = client, customer_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, customer_path(customer_id), json: body) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end
```

### `lib/paddle/mock_server.ex` (route, request-response)

**Analog:** `lib/paddle/mock_server.ex`

**Core Endpoint Pattern** (lines 51-53):
```elixir
  patch "/customers/:id" do
    send_json(conn, 200, Fixtures.customer(id))
  end
```

### `test/paddle/subscriptions_test.exs` (test, request-response)

**Analog:** `test/paddle/customers_test.exs`

**Core Update Test Pattern** (lines 114-138):
```elixir
  describe "update/3" do
    test "patches only the allowlisted update attrs and preserves explicit nil clears" do
      response_data = customer_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :patch
          assert request.url.path == "/customers/ctm_01"

          assert decode_json_body(request.body) == %{
                   "custom_data" => %{"crm_id" => "crm_456"},
                   "email" => "ada@example.com",
                   "locale" => "fr",
                   "name" => nil,
                   "status" => "inactive"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Customer{id: "ctm_01", raw_data: ^response_data}} =
               Customers.update(client, "ctm_01", %{
                 name: nil,
                 email: "ada@example.com",
                 locale: "fr",
                 status: "inactive",
                 custom_data: %{"crm_id" => "crm_456"},
                 marketing_consent: false,
                 import_meta: %{"source" => "legacy"},
                 ignored: "drop me"
               })
    end
```

### `test/paddle/subscription_flows_test.exs` (test, request-response)

**Analog:** `test/paddle/seam_test.exs`

**Client Test Helper Pattern** (lines 282-289):
```elixir
  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
    }
  end
```

**End-to-End Execution Flow Pattern** (lines 20-35):
```elixir
    customer_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/customers"

        assert decode_json_body(request.body) == %{
                 "email" => "ada@example.com",
                 "locale" => "en",
                 "name" => "Ada Lovelace"
               }

        {request, Req.Response.new(status: 201, body: %{"data" => customer_payload()})}
      end)

    assert {:ok, %Customer{id: "ctm_seam01", email: "ada@example.com"} = customer} =
             Paddle.Customers.create(customer_client, ...
```

## Shared Patterns

### HTTP Error Wrapping
**Source:** `test/paddle/customers_test.exs`
**Apply to:** `test/paddle/subscriptions_test.exs` (if adding error tests)
```elixir
    test "returns explicit validation tuples before dispatch" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_customer_id} = Customers.update(client, nil, %{})
      assert {:error, :invalid_customer_id} = Customers.update(client, " ", %{})
      assert {:error, :invalid_attrs} = Customers.update(client, "ctm_01", "nope")
    end
```

## No Analog Found

Files with no close match in the codebase:
*(None. All files have exact or role-match analogs)*

## Metadata

**Analog search scope:** `lib/paddle`, `test/paddle`
**Files scanned:** 4
**Pattern extraction date:** 2026-06-11
