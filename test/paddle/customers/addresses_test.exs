defmodule Paddle.Customers.AddressesTest do
  use ExUnit.Case, async: true

  alias Paddle.Address
  alias Paddle.Client
  alias Paddle.Customers.Addresses
  alias Paddle.Error

  describe "create/3" do
    test "posts to the customer-scoped path with only the allowlisted create attrs and returns a typed address" do
      response_data = address_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/customers/ctm_01/addresses"

          assert decode_json_body(request.body) == %{
                   "city" => "New York",
                   "country_code" => "US",
                   "custom_data" => %{"crm_id" => "crm_123"},
                   "description" => "Home office",
                   "first_line" => "123 Main Street",
                   "postal_code" => "10001",
                   "region" => "NY",
                   "second_line" => "Suite 4"
                 }

          {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
        end)

      assert {:ok, %Address{id: "add_01", customer_id: "ctm_01", raw_data: ^response_data}} =
               Addresses.create(client, "ctm_01",
                 description: "Home office",
                 first_line: "123 Main Street",
                 second_line: "Suite 4",
                 city: "New York",
                 postal_code: "10001",
                 region: "NY",
                 country_code: "US",
                 custom_data: %{"crm_id" => "crm_123"},
                 status: "archived",
                 import_meta: %{"source" => "legacy"},
                 ignored: "drop me"
               )
    end
  end

  describe "get/3" do
    test "requests the customer-owned address path and returns a typed address" do
      response_data = address_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/customers/ctm_01/addresses/add_01"
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Address{id: "add_01", customer_id: "ctm_01", raw_data: ^response_data}} =
               Addresses.get(client, "ctm_01", "add_01")
    end
  end

  describe "update/4" do
    test "patches only the allowlisted update attrs and preserves explicit nil clears" do
      response_data = address_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :patch
          assert request.url.path == "/customers/ctm_01/addresses/add_01"

          assert decode_json_body(request.body) == %{
                   "city" => "Brooklyn",
                   "country_code" => "US",
                   "custom_data" => %{"crm_id" => "crm_456"},
                   "description" => nil,
                   "first_line" => nil,
                   "postal_code" => "11201",
                   "region" => "NY",
                   "second_line" => "Floor 2",
                   "status" => "archived"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Address{id: "add_01", raw_data: ^response_data}} =
               Addresses.update(client, "ctm_01", "add_01", %{
                 description: nil,
                 first_line: nil,
                 second_line: "Floor 2",
                 city: "Brooklyn",
                 postal_code: "11201",
                 region: "NY",
                 country_code: "US",
                 status: "archived",
                 custom_data: %{"crm_id" => "crm_456"},
                 import_meta: %{"source" => "legacy"},
                 ignored: "drop me"
               })
    end

    test "returns exact validation tuples before dispatch" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_customer_id} = Addresses.create(client, nil, %{})
      assert {:error, :invalid_customer_id} = Addresses.create(client, " ", %{})
      assert {:error, :invalid_attrs} = Addresses.create(client, "ctm_01", "nope")

      assert {:error, :invalid_customer_id} = Addresses.get(client, "", "add_01")
      assert {:error, :invalid_address_id} = Addresses.get(client, "ctm_01", nil)
      assert {:error, :invalid_address_id} = Addresses.get(client, "ctm_01", "   ")

      assert {:error, :invalid_customer_id} = Addresses.update(client, nil, "add_01", %{})
      assert {:error, :invalid_address_id} = Addresses.update(client, "ctm_01", "", %{})
      assert {:error, :invalid_attrs} = Addresses.update(client, "ctm_01", "add_01", "nope")
    end
  end

  describe "error handling" do
    test "preserves non-2xx API error tuples from Paddle.Http.request/4" do
      client =
        client_with_adapter(fn request ->
          response =
            Req.Response.new(
              status: 404,
              body: %{
                "error" => %{
                  "type" => "request_error",
                  "code" => "entity_not_found",
                  "detail" => "Address not found",
                  "errors" => []
                }
              }
            )
            |> Req.Response.put_header("x-request-id", "req_404")

          {request, response}
        end)

      assert {:error,
              %Error{
                status_code: 404,
                request_id: "req_404",
                type: "request_error",
                code: "entity_not_found",
                message: "Address not found"
              }} = Addresses.get(client, "ctm_01", "add_404")
    end

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Addresses.update(client, "ctm_01", "add_01", %{city: "New York"})
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

  defp address_payload do
    %{
      "id" => "add_01",
      "customer_id" => "ctm_01",
      "description" => "Home office",
      "first_line" => "123 Main Street",
      "second_line" => "Suite 4",
      "city" => "New York",
      "postal_code" => "10001",
      "region" => "NY",
      "country_code" => "US",
      "custom_data" => %{"crm_id" => "crm_123"},
      "status" => "active",
      "created_at" => "2024-04-12T10:15:30Z",
      "updated_at" => "2024-04-13T11:16:31Z",
      "import_meta" => %{"imported_from" => "legacy"}
    }
  end
end
