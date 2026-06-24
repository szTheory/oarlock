defmodule Paddle.AdjustmentsTest do
  use ExUnit.Case, async: true

  alias Paddle.Adjustment
  alias Paddle.Adjustments
  alias Paddle.Client
  alias Paddle.Page

  describe "get/2" do
    test "issues GET /adjustments/{id} and returns a typed adjustment" do
      response_data = adjustment_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/adjustments/adj_01"
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Adjustment{} = adjustment} = Adjustments.get(client, "adj_01")
      assert adjustment.id == "adj_01"
      assert adjustment.action == "refund"
      assert adjustment.raw_data == response_data
    end

    test "url-encodes adjustment ids with reserved characters in the request path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/adjustments/adj%2Fwith%3Freserved"

          {request, Req.Response.new(status: 200, body: %{"data" => adjustment_payload()})}
        end)

      assert {:ok, %Adjustment{}} = Adjustments.get(client, "adj/with?reserved")
    end

    test "returns :invalid_adjustment_id for empty ids without HTTP request" do
      client =
        client_with_adapter(fn request ->
          send(self(), :http_called)
          {request, Req.Response.new(status: 200, body: %{"data" => %{}})}
        end)

      assert {:error, :invalid_adjustment_id} = Adjustments.get(client, "")
      assert {:error, :invalid_adjustment_id} = Adjustments.get(client, "   ")
      assert {:error, :invalid_adjustment_id} = Adjustments.get(client, nil)
      refute_received :http_called
    end
  end

  describe "create/2" do
    test "posts strictly allowlisted attrs to /adjustments and returns an adjustment" do
      response_data = adjustment_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/adjustments"

          body = decode_json_body(request.body)

          assert body == %{
                   "action" => "refund",
                   "reason" => "fraud",
                   "transaction_id" => "txn_01",
                   "items" => [
                     %{"item_id" => "txnitm_01", "type" => "partial", "amount" => "100"}
                   ]
                 }

          {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
        end)

      assert {:ok, %Adjustment{} = adjustment} =
               Adjustments.create(client,
                 action: "refund",
                 reason: "fraud",
                 transaction_id: "txn_01",
                 items: [%{item_id: "txnitm_01", type: "partial", amount: "100"}],
                 ignored: "drop me"
               )

      assert adjustment.id == "adj_01"
      assert adjustment.transaction_id == "txn_01"
    end
  end

  describe "list/2" do
    test "issues GET /adjustments with query parameters" do
      response_data = [adjustment_payload()]

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/adjustments"
          assert request.url.query == "action=refund&status=pending"

          {request,
           Req.Response.new(
             status: 200,
             body: %{
               "data" => response_data,
               "meta" => %{"pagination" => %{"has_more" => false, "estimated_total" => 1}}
             }
           )}
        end)

      assert {:ok, %Page{} = page} =
               Adjustments.list(client, action: "refund", status: "pending", ignored: "drop")

      assert [%Adjustment{id: "adj_01"}] = page.data
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

  defp decode_json_body(body) do
    body
    |> IO.iodata_to_binary()
    |> Jason.decode!()
  end

  defp adjustment_payload do
    %{
      "id" => "adj_01",
      "action" => "refund",
      "transaction_id" => "txn_01",
      "subscription_id" => nil,
      "customer_id" => "ctm_01",
      "reason" => "fraud",
      "credit_applied_to_balance" => false,
      "currency_code" => "USD",
      "status" => "pending",
      "items" => [%{"item_id" => "txnitm_01", "type" => "partial", "amount" => "100"}],
      "totals" => %{"subtotal" => "100", "tax" => "0", "total" => "100"},
      "payouts" => %{"subtotal" => "100", "tax" => "0", "total" => "100"},
      "created_at" => "2026-04-28T10:15:30Z",
      "updated_at" => "2026-04-28T10:15:31Z"
    }
  end
end
