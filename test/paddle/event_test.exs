defmodule Paddle.EventTest do
  use ExUnit.Case, async: true

  alias Paddle.Event

  describe "struct" do
    test "exposes the generic webhook envelope fields" do
      assert %Event{
               event_id: nil,
               event_type: nil,
               occurred_at: nil,
               notification_id: nil,
               data: nil,
               raw_data: nil
             } = %Event{}
    end
  end
end
