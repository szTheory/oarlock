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

    test "url-encodes customer and address ids in the request path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/customers/ctm%2F01/addresses/add%3F01"

          {request, Req.Response.new(status: 200, body: %{"data" => address_payload()})}
        end)

      assert {:ok, %Address{}} = Addresses.get(client, "ctm/01", "add?01")
    end
  end

  describe "list/3" do
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

          {request,
           Req.Response.new(status: 200, body: %{"data" => response_data, "meta" => meta})}
        end)

      assert {:ok, %Paddle.Page{data: [%Address{}, %Address{}], meta: ^meta} = page} =
               Addresses.list(client, "ctm_01")

      assert Enum.map(page.data, & &1.id) == ["add_01", "add_02"]
      assert Enum.at(page.data, 0).raw_data == address_payload()
      assert Enum.at(page.data, 1).raw_data == archived_address_payload()
      assert Paddle.Page.next_cursor(page) == "/customers/ctm_01/addresses?after=cursor_123"
    end

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

    test "allows archived status queries to pass through local filtering" do
      client =
        client_with_adapter(fn request ->
          assert URI.decode_query(request.url.query) == %{"status" => "archived"}

          {request,
           Req.Response.new(
             status: 200,
             body: %{"data" => [archived_address_payload()], "meta" => %{}}
           )}
        end)

      assert {:ok, %Paddle.Page{data: [%Address{status: "archived"}], meta: %{}}} =
               Addresses.list(client, "ctm_01", status: "archived")
    end

    test "returns exact validation tuples before dispatch" do
      client =
        client_with_adapter(
          &{&1, Req.Response.new(status: 200, body: %{"data" => [], "meta" => %{}})}
        )

      assert {:error, :invalid_customer_id} = Addresses.list(client, nil)
      assert {:error, :invalid_customer_id} = Addresses.list(client, " ")
      assert {:error, :invalid_params} = Addresses.list(client, "ctm_01", "nope")
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

    test "url-encodes customer and address ids for patch requests" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :patch
          assert request.url.path == "/customers/ctm%2F01/addresses/add%3F01"

          {request, Req.Response.new(status: 200, body: %{"data" => address_payload()})}
        end)

      assert {:ok, %Address{}} =
               Addresses.update(client, "ctm/01", "add?01", %{city: "Brooklyn"})
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

    test "surfaces list transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Addresses.list(client, "ctm_01", status: "archived")
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

  defp archived_address_payload do
    %{
      "id" => "add_02",
      "customer_id" => "ctm_01",
      "description" => "Former HQ",
      "first_line" => "55 Water Street",
      "second_line" => nil,
      "city" => "New York",
      "postal_code" => "10041",
      "region" => "NY",
      "country_code" => "US",
      "custom_data" => %{"crm_id" => "crm_999"},
      "status" => "archived",
      "created_at" => "2023-01-01T00:00:00Z",
      "updated_at" => "2024-01-01T00:00:00Z",
      "import_meta" => %{"imported_from" => "legacy"}
    }
  end
end
