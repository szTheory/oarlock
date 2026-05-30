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

  describe "stream/3" do
    test "streams addresses across three nested pages in order and replays Paddle next URLs" do
      {client, requests} = client_with_get_sequence(address_pagination_requests())

      addresses =
        client
        |> Addresses.stream("ctm_01", status: "active")
        |> Enum.to_list()

      assert Enum.map(addresses, & &1.id) == ["add_01", "add_02", "add_03"]
      assert Enum.all?(addresses, &match?(%Address{}, &1))
      assert_no_more_requests(requests)
    end

    test "raises Paddle.Error when a later page fails" do
      {client, _requests} =
        client_with_get_sequence([
          %{
            path: "/customers/ctm_01/addresses",
            query: %{},
            response: address_page(["add_01"], true, "/customers/ctm_01/addresses?after=cursor_1")
          },
          %{
            path: "/customers/ctm_01/addresses",
            query: %{"after" => "cursor_1"},
            response: paddle_unavailable_response()
          }
        ])

      error =
        assert_raise Error, fn ->
          client
          |> Addresses.stream("ctm_01")
          |> Enum.to_list()
        end

      assert error.status_code == 503
      assert error.message == "Paddle unavailable"
    end

    test "raises ArgumentError for invalid initial validation during enumeration" do
      client =
        client_with_adapter(fn request -> flunk("unexpected request: #{inspect(request)}") end)

      invalid_customer_stream = Addresses.stream(client, nil)
      invalid_params_stream = Addresses.stream(client, "ctm_01", "nope")

      assert_raise ArgumentError, ~r/:invalid_customer_id/, fn ->
        Enum.to_list(invalid_customer_stream)
      end

      assert_raise ArgumentError, ~r/:invalid_params/, fn ->
        Enum.to_list(invalid_params_stream)
      end
    end

    test "fetches only the first page when the consumer stops early" do
      {client, requests} =
        client_with_get_sequence([
          %{
            path: "/customers/ctm_01/addresses",
            query: %{},
            response: address_page(["add_01"], true, "/customers/ctm_01/addresses?after=cursor_1")
          }
        ])

      assert [%Address{id: "add_01"}] =
               client
               |> Addresses.stream("ctm_01")
               |> Enum.take(1)

      assert_no_more_requests(requests)
    end
  end

  describe "all/3" do
    test "returns the same ordered addresses as stream/3" do
      {stream_client, stream_requests} = client_with_get_sequence(address_pagination_requests())

      stream_ids =
        stream_client
        |> Addresses.stream("ctm_01", status: "active")
        |> Enum.map(& &1.id)

      assert_no_more_requests(stream_requests)

      {all_client, all_requests} = client_with_get_sequence(address_pagination_requests())

      assert {:ok, addresses} = Addresses.all(all_client, "ctm_01", status: "active")
      assert Enum.map(addresses, & &1.id) == stream_ids
      assert_no_more_requests(all_requests)
    end

    test "returns the first later-page Paddle.Error without partial results" do
      {client, _requests} =
        client_with_get_sequence([
          %{
            path: "/customers/ctm_01/addresses",
            query: %{},
            response: address_page(["add_01"], true, "/customers/ctm_01/addresses?after=cursor_1")
          },
          %{
            path: "/customers/ctm_01/addresses",
            query: %{"after" => "cursor_1"},
            response: paddle_unavailable_response()
          }
        ])

      assert {:error, %Error{status_code: 503, message: "Paddle unavailable"}} =
               Addresses.all(client, "ctm_01")
    end

    test "returns validation atoms from the initial list call" do
      client =
        client_with_adapter(fn request -> flunk("unexpected request: #{inspect(request)}") end)

      assert {:error, :invalid_customer_id} = Addresses.all(client, nil)
      assert {:error, :invalid_params} = Addresses.all(client, "ctm_01", "nope")
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

    test "normalizes transport exceptions into Paddle.Error" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
               Addresses.update(client, "ctm_01", "add_01", %{city: "New York"})
    end

    test "normalizes list transport exceptions into Paddle.Error" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
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

  defp client_with_get_sequence(expected_requests) do
    {:ok, requests} = Agent.start_link(fn -> expected_requests end)

    client =
      client_with_adapter(fn request ->
        expected =
          Agent.get_and_update(requests, fn
            [expected | rest] ->
              {expected, rest}

            [] ->
              flunk("unexpected request: #{request.method} #{URI.to_string(request.url)}")
          end)

        assert request.method == :get
        assert request.url.path == expected.path
        assert URI.decode_query(request.url.query || "") == expected.query
        assert request.body == nil

        {request, expected.response}
      end)

    {client, requests}
  end

  defp assert_no_more_requests(requests) do
    assert Agent.get(requests, & &1) == []
  end

  defp address_pagination_requests do
    [
      %{
        path: "/customers/ctm_01/addresses",
        query: %{"status" => "active"},
        response:
          address_page(
            ["add_01"],
            true,
            "https://api.paddle.com/customers/ctm_01/addresses?status=active&after=cursor_1"
          )
      },
      %{
        path: "/customers/ctm_01/addresses",
        query: %{"status" => "active", "after" => "cursor_1"},
        response:
          address_page(
            ["add_02"],
            true,
            "/customers/ctm_01/addresses?status=active&after=cursor_2"
          )
      },
      %{
        path: "/customers/ctm_01/addresses",
        query: %{"status" => "active", "after" => "cursor_2"},
        response:
          address_page(
            ["add_03"],
            false,
            "/customers/ctm_01/addresses?status=active&after=cursor_3"
          )
      }
    ]
  end

  defp address_page(ids, has_more, next) do
    Req.Response.new(
      status: 200,
      body: %{
        "data" => Enum.map(ids, &address_payload/1),
        "meta" => %{
          "pagination" => %{
            "per_page" => 1,
            "next" => next,
            "has_more" => has_more,
            "estimated_total" => 3
          }
        }
      }
    )
  end

  defp address_payload(id) do
    Map.put(address_payload(), "id", id)
  end

  defp paddle_unavailable_response do
    Req.Response.new(
      status: 503,
      body: %{
        "error" => %{
          "type" => "request_error",
          "code" => "service_unavailable",
          "detail" => "Paddle unavailable",
          "errors" => []
        }
      }
    )
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
