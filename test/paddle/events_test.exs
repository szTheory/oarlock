defmodule Paddle.EventsTest do
  use ExUnit.Case, async: true

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

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
          assert request_context(request) == event_request_context()

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
          assert request_context(request) == list_request_context()
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

    test "keeps literal list context across a dynamic cursor continuation" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          attempt = Agent.get_and_update(attempts, fn count -> {count, count + 1} end)

          assert request_context(request) == list_request_context()

          case attempt do
            0 ->
              assert request.url.path == "/events"

              body = %{
                "data" => [event_payload()],
                "meta" => %{
                  "pagination" => %{
                    "has_more" => true,
                    "next" => "/events?after=evt_runtime_secret",
                    "per_page" => 1
                  }
                }
              }

              {request, Req.Response.new(status: 200, body: body)}

            1 ->
              assert request.url.path == "/events"
              assert URI.decode_query(request.url.query) == %{"after" => "evt_runtime_secret"}

              body = %{
                "data" => [%{event_payload() | "event_id" => "evt_02"}],
                "meta" => %{"pagination" => %{"has_more" => false, "next" => nil}}
              }

              {request, Req.Response.new(status: 200, body: body)}
          end
        end)

      assert {:ok, [%Event{event_id: "evt_01h6"}, %Event{event_id: "evt_02"}]} =
               Events.all(client)

      assert Agent.get(attempts, & &1) == 2
    end
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req:
        Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: Adapter)
        |> Req.Request.put_private(:paddle_test_adapter, adapter)
    }
  end

  defp request_context(request) do
    Req.Request.get_private(request, :paddle_request_context)
  end

  defp event_request_context do
    %{method: :get, operation: :get_event, route: "/events/:event_id"}
  end

  defp list_request_context do
    %{method: :get, operation: :list_events, route: "/events"}
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
