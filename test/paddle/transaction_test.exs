defmodule Paddle.TransactionTest do
  use ExUnit.Case, async: true

  alias Paddle.Http
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout

  describe "%Paddle.Transaction{} struct" do
    test "exposes the promoted transaction fields plus raw_data" do
      assert %Transaction{
               id: nil,
               status: nil,
               customer_id: nil,
               address_id: nil,
               business_id: nil,
               custom_data: nil,
               currency_code: nil,
               origin: nil,
               subscription_id: nil,
               invoice_number: nil,
               collection_mode: nil,
               items: nil,
               details: nil,
               payments: nil,
               checkout: nil,
               created_at: nil,
               updated_at: nil,
               billed_at: nil,
               revised_at: nil,
               raw_data: nil
             } = %Transaction{}
    end

    test "build_struct/2 promotes known transaction keys and preserves the full payload in raw_data" do
      data = %{
        "id" => "txn_01",
        "status" => "ready",
        "customer_id" => "ctm_01",
        "address_id" => "add_01",
        "business_id" => nil,
        "custom_data" => %{"source" => "accrue"},
        "currency_code" => "USD",
        "origin" => "api",
        "subscription_id" => nil,
        "invoice_number" => nil,
        "collection_mode" => "automatic",
        "items" => [%{"price_id" => "pri_01", "quantity" => 1}],
        "details" => %{"totals" => %{"subtotal" => "1000"}},
        "payments" => [],
        "checkout" => %{"url" => "https://approved.example.com/checkout?_ptxn=txn_01"},
        "created_at" => "2026-04-28T10:15:30Z",
        "updated_at" => "2026-04-28T10:15:31Z",
        "billed_at" => nil,
        "revised_at" => nil,
        "ignored_key" => "kept in raw only"
      }

      assert %Transaction{
               id: "txn_01",
               status: "ready",
               customer_id: "ctm_01",
               address_id: "add_01",
               business_id: nil,
               custom_data: %{"source" => "accrue"},
               currency_code: "USD",
               origin: "api",
               subscription_id: nil,
               invoice_number: nil,
               collection_mode: "automatic",
               items: [%{"price_id" => "pri_01", "quantity" => 1}],
               details: %{"totals" => %{"subtotal" => "1000"}},
               payments: [],
               checkout: %{"url" => "https://approved.example.com/checkout?_ptxn=txn_01"},
               created_at: "2026-04-28T10:15:30Z",
               updated_at: "2026-04-28T10:15:31Z",
               billed_at: nil,
               revised_at: nil,
               raw_data: ^data
             } = Http.build_struct(Transaction, data)
    end
  end

  describe "%Paddle.Transaction.Checkout{} struct" do
    test "exposes only url and raw_data" do
      assert %Checkout{url: nil, raw_data: nil} = %Checkout{}
    end

    test "build_struct/2 promotes the checkout url and preserves the full payload in raw_data" do
      data = %{
        "url" => "https://approved.example.com/checkout?_ptxn=txn_01",
        "ignored_nested_key" => "kept in raw only"
      }

      assert %Checkout{
               url: "https://approved.example.com/checkout?_ptxn=txn_01",
               raw_data: ^data
             } = Http.build_struct(Checkout, data)
    end
  end
end
