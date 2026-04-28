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

  test "request/4 surfaces transport exceptions unchanged" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :timeout}}
      end)

    assert {:error, %Req.TransportError{reason: :timeout}} =
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

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
    }
  end
end
