defmodule Paddle.ProductsTest do
  use ExUnit.Case, async: true

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

  alias Paddle.Client
  alias Paddle.Page
  alias Paddle.Product
  alias Paddle.Products

  describe "get/2" do
    test "returns a Product struct for a valid ID" do
      response_data = product_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/products/pro_01"
          assert request_context(request) == product_request_context()

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Product{id: "pro_01", raw_data: ^response_data}} =
               Products.get(client, "pro_01")
    end

    test "rejects empty strings with {:error, :invalid_product_id}" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_product_id} = Products.get(client, "")
      assert {:error, :invalid_product_id} = Products.get(client, "   ")
      assert {:error, :invalid_product_id} = Products.get(client, nil)
    end
  end

  describe "list/2" do
    test "calls GET /products dropping unknown query parameters and specifically ignores include" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/products"
          assert request_context(request) == list_request_context()
          # include should be dropped
          assert request.options[:params] == %{"status" => "active"}

          {request,
           Req.Response.new(status: 200, body: %{"data" => [product_payload()], "meta" => %{}})}
        end)

      assert {:ok, %Page{data: [%Product{id: "pro_01"}]}} =
               Products.list(client, status: "active", include: "prices", unknown: "dropped")
    end

    test "builds a Page struct with nested Product structs" do
      client =
        client_with_adapter(fn request ->
          {request,
           Req.Response.new(
             status: 200,
             body: %{"data" => [product_payload()], "meta" => %{"pagination" => %{}}}
           )}
        end)

      assert {:ok, %Page{data: [%Product{id: "pro_01"}], meta: %{"pagination" => %{}}}} =
               Products.list(client, [])
    end
  end

  describe "stream/2" do
    test "keeps literal list context across a dynamic cursor continuation" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          attempt = Agent.get_and_update(attempts, fn count -> {count, count + 1} end)

          assert request_context(request) == list_request_context()

          case attempt do
            0 ->
              assert request.url.path == "/products"

              body = %{
                "data" => [product_payload()],
                "meta" => %{
                  "pagination" => %{
                    "has_more" => true,
                    "next" => "/products?after=pro_runtime_secret",
                    "per_page" => 1
                  }
                }
              }

              {request, Req.Response.new(status: 200, body: body)}

            1 ->
              assert request.url.path == "/products"
              assert URI.decode_query(request.url.query) == %{"after" => "pro_runtime_secret"}

              body = %{
                "data" => [%{product_payload() | "id" => "pro_02"}],
                "meta" => %{"pagination" => %{"has_more" => false, "next" => nil}}
              }

              {request, Req.Response.new(status: 200, body: body)}
          end
        end)

      assert [%Product{id: "pro_01"}, %Product{id: "pro_02"}] =
               Products.stream(client) |> Enum.to_list()

      assert Agent.get(attempts, & &1) == 2
    end
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req:
        Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: Adapter)
        |> Req.Request.put_private(:paddle_test_adapter, adapter)
    }
  end

  defp request_context(request) do
    Req.Request.get_private(request, :paddle_request_context)
  end

  defp product_request_context do
    %{method: :get, operation: :get_product, route: "/products/:product_id"}
  end

  defp list_request_context do
    %{method: :get, operation: :list_products, route: "/products"}
  end

  defp product_payload do
    %{
      "id" => "pro_01",
      "name" => "Test Product",
      "status" => "active"
    }
  end
end
