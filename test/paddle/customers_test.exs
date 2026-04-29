defmodule Paddle.CustomersTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Customers
  alias Paddle.Error

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
               Customers.create(client,
                 email: "ada@example.com",
                 name: "Ada Lovelace",
                 locale: "en",
                 custom_data: %{"crm_id" => "crm_123"},
                 marketing_consent: true,
                 import_meta: %{"source" => "legacy"},
                 ignored: "drop me"
               )
    end

    test "returns an explicit error for invalid attrs containers" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_attrs} = Customers.create(client, "nope")
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

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Customers.create(client, %{email: "ada@example.com"})
    end
  end

  describe "get/2" do
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

    test "returns an explicit error for blank customer ids" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_customer_id} = Customers.get(client, nil)
      assert {:error, :invalid_customer_id} = Customers.get(client, "")
      assert {:error, :invalid_customer_id} = Customers.get(client, "   ")
    end

    test "url-encodes customer ids before building the request path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/customers/ctm%2Fwith%3Freserved"

          {request, Req.Response.new(status: 200, body: %{"data" => customer_payload()})}
        end)

      assert {:ok, %Customer{}} = Customers.get(client, "ctm/with?reserved")
    end
  end

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

    test "returns explicit validation tuples before dispatch" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_customer_id} = Customers.update(client, nil, %{})
      assert {:error, :invalid_customer_id} = Customers.update(client, " ", %{})
      assert {:error, :invalid_attrs} = Customers.update(client, "ctm_01", "nope")
    end

    test "url-encodes customer ids for patch requests" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :patch
          assert request.url.path == "/customers/ctm%2Fwith%3Freserved"

          {request, Req.Response.new(status: 200, body: %{"data" => customer_payload()})}
        end)

      assert {:ok, %Customer{}} = Customers.update(client, "ctm/with?reserved", %{name: "Ada"})
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

  defp customer_payload do
    %{
      "id" => "ctm_01",
      "name" => "Ada Lovelace",
      "email" => "ada@example.com",
      "marketing_consent" => false,
      "status" => "active",
      "custom_data" => %{"crm_id" => "crm_123"},
      "locale" => "en",
      "created_at" => "2024-04-12T10:15:30Z",
      "updated_at" => "2024-04-13T11:16:31Z",
      "import_meta" => %{"imported_from" => "legacy"}
    }
  end
end
