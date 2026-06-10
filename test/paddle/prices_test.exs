defmodule Paddle.PricesTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Price
  alias Paddle.Prices
  alias Paddle.Page

  describe "get/2" do
    test "requests the price path and returns a typed price" do
      response_data = price_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/prices/pri_01"
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Price{id: "pri_01", raw_data: ^response_data}} =
               Prices.get(client, "pri_01")
    end

    test "returns an explicit error for blank price ids" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_price_id} = Prices.get(client, nil)
      assert {:error, :invalid_price_id} = Prices.get(client, "")
      assert {:error, :invalid_price_id} = Prices.get(client, "   ")
    end
  end

  describe "list/2" do
    test "calls GET /prices dropping unknown query parameters and ignores include" do
      response_data = [price_payload()]
      meta = %{"pagination" => %{"per_page" => 10, "next" => "url", "has_more" => true}}

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/prices"
          # include should be dropped
          assert request.options[:params] == %{"status" => "active", "per_page" => 10}

          {request,
           Req.Response.new(status: 200, body: %{"data" => response_data, "meta" => meta})}
        end)

      assert {:ok, %Page{data: [%Price{id: "pri_01"}], meta: ^meta}} =
               Prices.list(client,
                 status: "active",
                 per_page: 10,
                 include: "product",
                 unknown_param: "drop_me"
               )
    end

    test "delegates response to Paddle.Internal.Pagination.build_page/3" do
      response_data = [price_payload()]
      meta = %{"pagination" => %{"per_page" => 10, "next" => "url", "has_more" => true}}

      client =
        client_with_adapter(fn request ->
          {request,
           Req.Response.new(status: 200, body: %{"data" => response_data, "meta" => meta})}
        end)

      assert {:ok, page} = Prices.list(client)
      assert %Page{} = page
      assert [%Price{id: "pri_01"}] = page.data
      assert page.meta == meta
    end
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
    }
  end

  defp price_payload do
    %{
      "id" => "pri_01",
      "product_id" => "pro_01",
      "description" => "A test price",
      "type" => "standard",
      "name" => "Standard Price",
      "billing_cycle" => %{"interval" => "month", "frequency" => 1},
      "trial_period" => %{"interval" => "day", "frequency" => 14},
      "tax_mode" => "account_setting",
      "unit_price" => %{"amount" => "1000", "currency_code" => "USD"},
      "unit_price_overrides" => [],
      "quantity" => %{"minimum" => 1, "maximum" => 10},
      "status" => "active",
      "custom_data" => %{"feature" => "premium"},
      "import_meta" => %{"imported_from" => "stripe"},
      "created_at" => "2024-04-12T10:15:30Z",
      "updated_at" => "2024-04-13T11:16:31Z"
    }
  end
end
