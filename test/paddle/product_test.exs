defmodule Paddle.ProductTest do
  use ExUnit.Case, async: true

  alias Paddle.Product
  alias Paddle.Http

  describe "struct" do
    test "exposes the promoted product fields plus raw_data" do
      assert %Product{
               id: nil,
               name: nil,
               status: nil,
               tax_category: nil,
               description: nil,
               image_url: nil,
               custom_data: nil,
               created_at: nil,
               updated_at: nil,
               import_meta: nil,
               raw_data: nil
             } = %Product{}
    end

    test "build_struct/2 promotes known product keys and preserves the full payload in raw_data" do
      data = %{
        "id" => "pro_01",
        "name" => "Super Product",
        "status" => "active",
        "tax_category" => "standard",
        "description" => "A very super product",
        "image_url" => "https://example.com/image.png",
        "custom_data" => %{"internal_id" => "123"},
        "created_at" => "2024-04-12T10:15:30Z",
        "updated_at" => "2024-04-13T11:16:31Z",
        "import_meta" => %{"imported_from" => "legacy"},
        "ignored_key" => "kept in raw only"
      }

      assert %Product{
               id: "pro_01",
               name: "Super Product",
               status: "active",
               tax_category: "standard",
               description: "A very super product",
               image_url: "https://example.com/image.png",
               custom_data: %{"internal_id" => "123"},
               created_at: "2024-04-12T10:15:30Z",
               updated_at: "2024-04-13T11:16:31Z",
               import_meta: %{"imported_from" => "legacy"},
               raw_data: ^data
             } = Http.build_struct(Product, data)
    end
  end
end
