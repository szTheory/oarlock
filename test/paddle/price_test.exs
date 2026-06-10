defmodule Paddle.PriceTest do
  use ExUnit.Case, async: true

  alias Paddle.Price
  alias Paddle.Http

  describe "struct" do
    test "exposes the promoted price fields plus raw_data" do
      assert %Price{
               id: nil,
               product_id: nil,
               description: nil,
               type: nil,
               name: nil,
               billing_cycle: nil,
               trial_period: nil,
               tax_mode: nil,
               unit_price: nil,
               unit_price_overrides: nil,
               quantity: nil,
               status: nil,
               custom_data: nil,
               import_meta: nil,
               created_at: nil,
               updated_at: nil,
               raw_data: nil
             } = %Price{}
    end

    test "build_struct/2 promotes known price keys and preserves the full payload in raw_data" do
      data = %{
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
        "updated_at" => "2024-04-13T11:16:31Z",
        "ignored_key" => "kept in raw only"
      }

      assert %Price{
               id: "pri_01",
               product_id: "pro_01",
               description: "A test price",
               type: "standard",
               name: "Standard Price",
               billing_cycle: %{"interval" => "month", "frequency" => 1},
               trial_period: %{"interval" => "day", "frequency" => 14},
               tax_mode: "account_setting",
               unit_price: %{"amount" => "1000", "currency_code" => "USD"},
               unit_price_overrides: [],
               quantity: %{"minimum" => 1, "maximum" => 10},
               status: "active",
               custom_data: %{"feature" => "premium"},
               import_meta: %{"imported_from" => "stripe"},
               created_at: "2024-04-12T10:15:30Z",
               updated_at: "2024-04-13T11:16:31Z",
               raw_data: ^data
             } = Http.build_struct(Price, data)
    end
  end
end
