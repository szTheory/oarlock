defmodule Paddle.TransactionsTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout
  alias Paddle.Transactions

  describe "create/2" do
    test "posts the strict hosted-checkout body to /transactions and returns a typed transaction" do
      response_data = transaction_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/transactions"

          assert decode_json_body(request.body) == %{
                   "address_id" => "add_01",
                   "checkout" => %{"url" => "https://approved.example.com/checkout"},
                   "collection_mode" => "automatic",
                   "custom_data" => %{"crm_id" => "crm_123"},
                   "customer_id" => "ctm_01",
                   "items" => [%{"price_id" => "pri_01", "quantity" => 1}]
                 }

          {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
        end)

      assert {:ok, %Transaction{} = transaction} =
               Transactions.create(client,
                 customer_id: "ctm_01",
                 address_id: "add_01",
                 items: [%{price_id: "pri_01", quantity: 1}],
                 custom_data: %{"crm_id" => "crm_123"},
                 checkout: %{url: "https://approved.example.com/checkout"}
               )

      assert transaction.id == "txn_01"
      assert transaction.customer_id == "ctm_01"
      assert transaction.address_id == "add_01"
      assert transaction.collection_mode == "automatic"
      assert transaction.raw_data == response_data

      assert %Checkout{url: "https://approved.example.com/checkout?_ptxn=txn_01"} =
               transaction.checkout

      assert transaction.checkout.url == "https://approved.example.com/checkout?_ptxn=txn_01"
      assert transaction.checkout.raw_data == response_data["checkout"]
    end

    test "drops unsupported caller attrs and forces automatic collection mode" do
      response_data = transaction_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/transactions"

          body = decode_json_body(request.body)

          # The strict allowlisted body
          assert body == %{
                   "address_id" => "add_01",
                   "collection_mode" => "automatic",
                   "customer_id" => "ctm_01",
                   "items" => [%{"price_id" => "pri_01", "quantity" => 1}]
                 }

          # Unsupported caller-supplied attrs are absent
          refute Map.has_key?(body, "discount_id")
          refute Map.has_key?(body, "billing_period")
          refute Map.has_key?(body, "invoice_id")
          refute Map.has_key?(body, "currency_code")
          refute Map.has_key?(body, "business_id")

          # Caller-supplied collection_mode is overridden, not forwarded
          assert body["collection_mode"] == "automatic"

          {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
        end)

      assert {:ok, %Transaction{}} =
               Transactions.create(client,
                 customer_id: "ctm_01",
                 address_id: "add_01",
                 items: [%{price_id: "pri_01", quantity: 1}],
                 collection_mode: "manual",
                 discount_id: "dsc_01",
                 billing_period: %{starts_at: "2026-01-01"},
                 invoice_id: "inv_01",
                 currency_code: "USD",
                 business_id: "biz_01",
                 ignored: "drop me"
               )
    end

    test "returns :invalid_attrs for non-map/non-keyword containers" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_attrs} = Transactions.create(client, "nope")
      assert {:error, :invalid_attrs} = Transactions.create(client, 123)
      assert {:error, :invalid_attrs} = Transactions.create(client, [1, 2, 3])
      assert {:error, :invalid_attrs} = Transactions.create(client, nil)
    end

    test "returns :invalid_customer_id for blank or missing customer_id" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      base = [
        address_id: "add_01",
        items: [%{price_id: "pri_01", quantity: 1}]
      ]

      assert {:error, :invalid_customer_id} = Transactions.create(client, base)

      assert {:error, :invalid_customer_id} =
               Transactions.create(client, [{:customer_id, nil} | base])

      assert {:error, :invalid_customer_id} =
               Transactions.create(client, [{:customer_id, ""} | base])

      assert {:error, :invalid_customer_id} =
               Transactions.create(client, [{:customer_id, "   "} | base])

      assert {:error, :invalid_customer_id} =
               Transactions.create(client, [{:customer_id, 123} | base])
    end

    test "returns :invalid_address_id for blank or missing address_id" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      base = [
        customer_id: "ctm_01",
        items: [%{price_id: "pri_01", quantity: 1}]
      ]

      assert {:error, :invalid_address_id} = Transactions.create(client, base)

      assert {:error, :invalid_address_id} =
               Transactions.create(client, [{:address_id, nil} | base])

      assert {:error, :invalid_address_id} =
               Transactions.create(client, [{:address_id, ""} | base])

      assert {:error, :invalid_address_id} =
               Transactions.create(client, [{:address_id, "   "} | base])

      assert {:error, :invalid_address_id} =
               Transactions.create(client, [{:address_id, 123} | base])
    end

    test "returns :invalid_items for missing/empty/malformed items" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      base = [
        customer_id: "ctm_01",
        address_id: "add_01"
      ]

      # Missing items entirely
      assert {:error, :invalid_items} = Transactions.create(client, base)

      # Empty list
      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, []} | base])

      # Non-list
      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, "nope"} | base])

      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, %{price_id: "pri_01", quantity: 1}} | base])

      # Item entry missing price_id
      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, [%{quantity: 1}]} | base])

      # Item entry with blank price_id
      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, [%{price_id: "  ", quantity: 1}]} | base])

      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, [%{price_id: nil, quantity: 1}]} | base])

      # Item entry missing quantity
      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, [%{price_id: "pri_01"}]} | base])

      # Item entry that is not a map
      assert {:error, :invalid_items} =
               Transactions.create(client, [{:items, ["pri_01"]} | base])
    end

    test "returns :invalid_checkout for malformed checkout nesting" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      base = [
        customer_id: "ctm_01",
        address_id: "add_01",
        items: [%{price_id: "pri_01", quantity: 1}]
      ]

      # checkout is a string instead of a nested map
      assert {:error, :invalid_checkout} =
               Transactions.create(client, [
                 {:checkout, "https://approved.example.com/checkout"} | base
               ])

      # checkout url is nil
      assert {:error, :invalid_checkout} =
               Transactions.create(client, [{:checkout, %{url: nil}} | base])

      # checkout url is blank
      assert {:error, :invalid_checkout} =
               Transactions.create(client, [{:checkout, %{url: ""}} | base])

      assert {:error, :invalid_checkout} =
               Transactions.create(client, [{:checkout, %{url: "   "}} | base])

      # checkout map missing url entirely
      assert {:error, :invalid_checkout} =
               Transactions.create(client, [{:checkout, %{}} | base])

      # checkout url is not a binary
      assert {:error, :invalid_checkout} =
               Transactions.create(client, [{:checkout, %{url: 123}} | base])
    end

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
              }} =
               Transactions.create(client,
                 customer_id: "ctm_01",
                 address_id: "add_01",
                 items: [%{price_id: "pri_01", quantity: 1}]
               )
    end

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Transactions.create(client,
                 customer_id: "ctm_01",
                 address_id: "add_01",
                 items: [%{price_id: "pri_01", quantity: 1}]
               )
    end
  end

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

  defp transaction_payload do
    %{
      "id" => "txn_01",
      "status" => "ready",
      "customer_id" => "ctm_01",
      "address_id" => "add_01",
      "business_id" => nil,
      "custom_data" => %{"crm_id" => "crm_123"},
      "currency_code" => "USD",
      "origin" => "api",
      "subscription_id" => nil,
      "invoice_number" => nil,
      "collection_mode" => "automatic",
      "items" => [%{"price_id" => "pri_01", "quantity" => 1}],
      "details" => %{"totals" => %{"subtotal" => "1000"}},
      "payments" => [],
      "checkout" => %{"url" => "https://approved.example.com/checkout?_ptxn=txn_01"},
      "created_at" => "2026-04-28T10:15:30Z",
      "updated_at" => "2026-04-28T10:15:31Z",
      "billed_at" => nil,
      "revised_at" => nil
    }
  end
end
