defmodule Paddle.PageTest do
  use ExUnit.Case, async: true

  alias Paddle.Page

  describe "struct" do
    test "stores data and meta" do
      page = %Page{data: [%{"id" => "txn_123"}], meta: %{"pagination" => %{"next" => "/next"}}}

      assert page.data == [%{"id" => "txn_123"}]
      assert page.meta == %{"pagination" => %{"next" => "/next"}}
    end
  end

  describe "next_cursor/1" do
    test "returns the next pagination cursor when present" do
      page = %Page{
        data: [],
        meta: %{"pagination" => %{"next" => "/transactions?after=cursor_123"}}
      }

      assert Page.next_cursor(page) == "/transactions?after=cursor_123"
    end

    test "returns nil when no next cursor exists" do
      assert Page.next_cursor(%Page{data: [], meta: %{}}) == nil
    end
  end
end
