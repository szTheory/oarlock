defmodule Paddle.CustomerTest do
  use ExUnit.Case, async: true

  alias Paddle.Customer
  alias Paddle.Http

  describe "struct" do
    test "exposes the promoted customer fields plus raw_data" do
      assert %Customer{
               id: nil,
               name: nil,
               email: nil,
               marketing_consent: nil,
               status: nil,
               custom_data: nil,
               locale: nil,
               created_at: nil,
               updated_at: nil,
               import_meta: nil,
               raw_data: nil
             } = %Customer{}
    end

    test "build_struct/2 promotes known customer keys and preserves the full payload in raw_data" do
      data = %{
        "id" => "ctm_01",
        "name" => "Ada Lovelace",
        "email" => "ada@example.com",
        "status" => "active",
        "custom_data" => %{"crm_id" => "crm_123"},
        "locale" => "en",
        "created_at" => "2024-04-12T10:15:30Z",
        "updated_at" => "2024-04-13T11:16:31Z",
        "import_meta" => %{"imported_from" => "legacy"},
        "marketing_consent" => false,
        "ignored_key" => "kept in raw only"
      }

      assert %Customer{
               id: "ctm_01",
               name: "Ada Lovelace",
               email: "ada@example.com",
               status: "active",
               custom_data: %{"crm_id" => "crm_123"},
               locale: "en",
               created_at: "2024-04-12T10:15:30Z",
               updated_at: "2024-04-13T11:16:31Z",
               import_meta: %{"imported_from" => "legacy"},
               marketing_consent: false,
               raw_data: ^data
             } = Http.build_struct(Customer, data)
    end
  end
end
