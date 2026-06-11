defmodule Paddle.EventsTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Event
  alias Paddle.Events
  alias Paddle.Page

  describe "get/2" do
    test "returns an Event struct for a valid ID" do
      response_data = event_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/events/evt_01h6"

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Event{event_id: "evt_01h6", raw_data: ^response_data}} =
               Events.get(client, "evt_01h6")
    end

    test "rejects empty strings with {:error, :invalid_event_id}" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_event_id} = Events.get(client, "")
      assert {:error, :invalid_event_id} = Events.get(client, "   ")
      assert {:error, :invalid_event_id} = Events.get(client, nil)
    end
  end

  describe "list/2" do
    test "calls GET /events dropping unknown query parameters" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/events"
          # unknown_param should be dropped
          assert request.options[:params] == %{"event_type" => "transaction.completed"}

          body = %{
            "data" => [event_payload()],
            "meta" => %{
              "pagination" => %{
                "has_more" => false,
                "per_page" => 10,
                "estimated_total" => 1
              }
            }
          }

          {request, Req.Response.new(status: 200, body: body)}
        end)

      assert {:ok, %Page{data: [%Event{event_id: "evt_01h6"}]}} =
               Events.list(client, event_type: "transaction.completed", unknown_param: "test")
    end
  end

  describe "stream/2" do
    test "returns a stream of events" do
      client =
        client_with_adapter(fn request ->
          assert request.url.path == "/events"

          body = %{
            "data" => [event_payload()],
            "meta" => %{
              "pagination" => %{
                "has_more" => false,
                "per_page" => 10,
                "estimated_total" => 1,
                "next" => nil
              }
            }
          }

          {request, Req.Response.new(status: 200, body: body)}
        end)

      stream = Events.stream(client)
      assert [%Event{event_id: "evt_01h6"}] = Enum.to_list(stream)
    end
  end

  describe "all/2" do
    test "returns a list of events" do
      client =
        client_with_adapter(fn request ->
          assert request.url.path == "/events"

          body = %{
            "data" => [event_payload()],
            "meta" => %{
              "pagination" => %{
                "has_more" => false,
                "per_page" => 10,
                "estimated_total" => 1,
                "next" => nil
              }
            }
          }

          {request, Req.Response.new(status: 200, body: body)}
        end)

      assert {:ok, [%Event{event_id: "evt_01h6"}]} = Events.all(client)
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

  defp event_payload do
    %{
      "event_id" => "evt_01h6",
      "event_type" => "transaction.completed",
      "occurred_at" => "2023-08-01T12:00:00Z",
      "data" => %{"id" => "txn_01h6"}
    }
  end
end
