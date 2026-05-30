defmodule Paddle.HttpTest do
  use ExUnit.Case, async: true

  defmodule SampleStruct do
    defstruct [:id, :name, :raw_data]
  end

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Http

  test "request/4 returns ok tuples for 2xx responses" do
    client =
      client_with_adapter(fn request ->
        {request, Req.Response.new(status: 200, body: %{"data" => %{"id" => "cus_123"}})}
      end)

    assert {:ok, %{"data" => %{"id" => "cus_123"}}} = Http.request(client, :get, "/customers")
  end

  test "request/4 maps non-2xx responses to Paddle.Error" do
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
            }} = Http.request(client, :post, "/customers", body: %{})
  end

  test "request/4 normalizes transport exceptions into Paddle.Error" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :timeout}}
      end)

    assert {:error,
            %Paddle.Error{
              network_error?: true,
              retryable?: true,
              type: "network_timeout",
              raw_data: %Req.TransportError{reason: :timeout}
            }} = Http.request(client, :get, "/customers")
  end

  test "request/4 maps nxdomain to network_nxdomain type" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :nxdomain}}
      end)

    assert {:error,
            %Paddle.Error{type: "network_nxdomain", network_error?: true, retryable?: true}} =
             Http.request(client, :get, "/customers")
  end

  test "request/4 maps closed to network_closed type" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :closed}}
      end)

    assert {:error, %Paddle.Error{type: "network_closed", network_error?: true, retryable?: true}} =
             Http.request(client, :get, "/customers")
  end

  test "request/4 maps unknown transport reason to network_unknown type" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :econnrefused}}
      end)

    assert {:error,
            %Paddle.Error{type: "network_unknown", network_error?: true, retryable?: true}} =
             Http.request(client, :get, "/customers")
  end

  test "build_struct/2 maps known string keys into the target struct" do
    data = %{"id" => "txn_123", "name" => "Starter", "ignored" => "value"}

    assert %SampleStruct{id: "txn_123", name: "Starter"} = Http.build_struct(SampleStruct, data)
  end

  test "build_struct/2 preserves the raw payload in raw_data" do
    data = %{"id" => "txn_123", "name" => "Starter", "ignored" => "value"}

    assert %SampleStruct{raw_data: ^data} = Http.build_struct(SampleStruct, data)
  end

  describe "request/4 idempotency_key opt" do
    test "forwards the supplied key as Idempotency-Key header on POST" do
      client =
        client_with_adapter(fn request ->
          assert Req.Request.get_header(request, "idempotency-key") == ["my-key-123"]
          {request, Req.Response.new(status: 201, body: %{"data" => %{"id" => "cus_1"}})}
        end)

      assert {:ok, _} =
               Http.request(client, :post, "/customers",
                 json: %{name: "x"},
                 idempotency_key: "my-key-123"
               )
    end

    test "sends no Idempotency-Key header when the opt is absent" do
      client =
        client_with_adapter(fn request ->
          assert Req.Request.get_header(request, "idempotency-key") == []
          {request, Req.Response.new(status: 200, body: %{"data" => %{"id" => "cus_1"}})}
        end)

      assert {:ok, _} = Http.request(client, :get, "/customers")
    end

    test "raises ArgumentError when idempotency_key is nil" do
      client =
        client_with_adapter(fn request ->
          flunk(
            "adapter should not be called when idempotency_key is invalid; got: #{inspect(request)}"
          )
        end)

      assert_raise ArgumentError, ~r/idempotency_key must be a non-empty string/, fn ->
        Http.request(client, :post, "/customers", json: %{}, idempotency_key: nil)
      end
    end

    test "raises ArgumentError when idempotency_key is the empty string" do
      client =
        client_with_adapter(fn request ->
          flunk("adapter should not be called; got: #{inspect(request)}")
        end)

      assert_raise ArgumentError, ~r/idempotency_key must be a non-empty string/, fn ->
        Http.request(client, :post, "/customers", json: %{}, idempotency_key: "")
      end
    end

    test "raises ArgumentError when idempotency_key is whitespace-only" do
      client =
        client_with_adapter(fn request ->
          flunk("adapter should not be called; got: #{inspect(request)}")
        end)

      assert_raise ArgumentError, ~r/idempotency_key must be a non-empty string/, fn ->
        Http.request(client, :post, "/customers", json: %{}, idempotency_key: "   ")
      end
    end

    test "raises ArgumentError when idempotency_key is not a binary" do
      client =
        client_with_adapter(fn request ->
          flunk("adapter should not be called; got: #{inspect(request)}")
        end)

      assert_raise ArgumentError, ~r/idempotency_key must be a non-empty string/, fn ->
        Http.request(client, :post, "/customers", json: %{}, idempotency_key: 12345)
      end
    end

    test "Paddle.Customers.create/3 forwards idempotency_key as Idempotency-Key header" do
      client =
        client_with_adapter(fn request ->
          assert Req.Request.get_header(request, "idempotency-key") == [
                   "accrue:job:42:attempt:1"
                 ]

          {request, Req.Response.new(status: 201, body: %{"data" => %{"id" => "cus_999"}})}
        end)

      assert {:ok, %Paddle.Customer{id: "cus_999"}} =
               Paddle.Customers.create(client, %{email: "x@example.com", name: "X"},
                 idempotency_key: "accrue:job:42:attempt:1"
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
end
