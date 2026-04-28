defmodule Paddle.EventTest do
  use ExUnit.Case, async: true

  alias Paddle.Event
  alias Paddle.Webhooks

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

  describe "parse_event/1" do
    test "returns a typed event for a valid Paddle webhook payload" do
      assert {:ok,
              %Event{
                event_id: "evt_01",
                event_type: "subscription.created",
                occurred_at: "2024-04-12T10:15:30Z",
                notification_id: "ntf_01",
                data: %{
                  "id" => "sub_01",
                  "status" => "active"
                },
                raw_data: %{
                  "event_id" => "evt_01",
                  "event_type" => "subscription.created",
                  "occurred_at" => "2024-04-12T10:15:30Z",
                  "notification_id" => "ntf_01",
                  "data" => %{
                    "id" => "sub_01",
                    "status" => "active"
                  }
                }
              }} = Webhooks.parse_event(valid_payload_json())
    end

    test "returns an explicit error for invalid JSON" do
      assert {:error, :invalid_json} = Webhooks.parse_event("{")
    end

    test "returns an explicit error for incomplete payloads" do
      assert {:error, :invalid_event_payload} = Webhooks.parse_event(incomplete_payload_json())
    end
  end

  defp valid_payload_json do
    ~s({"event_id":"evt_01","event_type":"subscription.created","occurred_at":"2024-04-12T10:15:30Z","notification_id":"ntf_01","data":{"id":"sub_01","status":"active"}})
  end

  defp incomplete_payload_json do
    ~s({"event_id":"evt_01","event_type":"subscription.created","occurred_at":"2024-04-12T10:15:30Z","data":{"id":"sub_01"}})
  end
end
