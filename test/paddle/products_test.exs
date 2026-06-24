defmodule Paddle.ProductsTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Product
  alias Paddle.Products
  alias Paddle.Page

  describe "get/2" do
    test "returns a Product struct for a valid ID" do
      response_data = product_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/products/pro_01"

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

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
    }
  end

  defp product_payload do
    %{
      "id" => "pro_01",
      "name" => "Test Product",
      "status" => "active"
    }
  end
end
