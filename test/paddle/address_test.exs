defmodule Paddle.AddressTest do
  use ExUnit.Case, async: true

  alias Paddle.Address
  alias Paddle.Http

  describe "struct" do
    test "exposes the promoted address fields plus raw_data" do
      assert %Address{
               id: nil,
               customer_id: nil,
               description: nil,
               first_line: nil,
               second_line: nil,
               city: nil,
               postal_code: nil,
               region: nil,
               country_code: nil,
               custom_data: nil,
               status: nil,
               created_at: nil,
               updated_at: nil,
               import_meta: nil,
               raw_data: nil
             } = %Address{}
    end

    test "build_struct/2 promotes known address keys and preserves the full payload in raw_data" do
      data = %{
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
        "import_meta" => %{"imported_from" => "legacy"},
        "ignored_key" => "kept in raw only"
      }

      assert %Address{
               id: "add_01",
               customer_id: "ctm_01",
               description: "Home office",
               first_line: "123 Main Street",
               second_line: "Suite 4",
               city: "New York",
               postal_code: "10001",
               region: "NY",
               country_code: "US",
               custom_data: %{"crm_id" => "crm_123"},
               status: "active",
               created_at: "2024-04-12T10:15:30Z",
               updated_at: "2024-04-13T11:16:31Z",
               import_meta: %{"imported_from" => "legacy"},
               raw_data: ^data
             } = Http.build_struct(Address, data)
    end
  end
end
