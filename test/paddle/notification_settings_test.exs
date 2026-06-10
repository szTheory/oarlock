defmodule Paddle.NotificationSettingsTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.NotificationSetting
  alias Paddle.NotificationSettings

  describe "get/2" do
    test "requests the notification setting path with explicit client passing and returns a typed struct" do
      response_data = setting_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings/ntfset_01"
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %NotificationSetting{id: "ntfset_01", raw_data: ^response_data}} =
               NotificationSettings.get(client, "ntfset_01")
    end

    test "returns an explicit error for blank notification setting ids" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_notification_setting_id} = NotificationSettings.get(client, nil)
      assert {:error, :invalid_notification_setting_id} = NotificationSettings.get(client, "")
      assert {:error, :invalid_notification_setting_id} = NotificationSettings.get(client, "   ")
    end

    test "url-encodes notification setting ids before building the request path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings/ntfset%2Fwith%3Freserved"

          {request, Req.Response.new(status: 200, body: %{"data" => setting_payload()})}
        end)

      assert {:ok, %NotificationSetting{}} =
               NotificationSettings.get(client, "ntfset/with?reserved")
    end
  end

  describe "list/2" do
    test "requests the notification settings collection and returns a typed page" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings"
          assert URI.decode_query(request.url.query) == %{"per_page" => "10"}

          body = %{
            "data" => [setting_payload()],
            "meta" => %{
              "pagination" => %{
                "has_more" => false,
                "estimated_total" => 1,
                "next" => "/notification-settings?after=ntfset_01",
                "per_page" => 10
              },
              "request_id" => "req_123"
            }
          }

          {request, Req.Response.new(status: 200, body: body)}
        end)

      assert {:ok, %Paddle.Page{data: [%NotificationSetting{}]}} =
               NotificationSettings.list(client, per_page: 10)
    end
  end

  describe "stream/2" do
    test "yields items and automatically paginates" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings"

          query = request.url.query || ""

          if not String.contains?(query, "after=") do
            body = %{
              "data" => [setting_payload()],
              "meta" => %{
                "pagination" => %{
                  "has_more" => true,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_01",
                  "per_page" => 1
                },
                "request_id" => "req_123"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          else
            assert String.contains?(query, "after=ntfset_01")

            body = %{
              "data" => [%{setting_payload() | "id" => "ntfset_02"}],
              "meta" => %{
                "pagination" => %{
                  "has_more" => false,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_02",
                  "per_page" => 1
                },
                "request_id" => "req_456"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          end
        end)

      items = NotificationSettings.stream(client, per_page: 1) |> Enum.to_list()

      assert length(items) == 2

      assert [%NotificationSetting{id: "ntfset_01"}, %NotificationSetting{id: "ntfset_02"}] =
               items
    end
  end

  describe "all/2" do
    test "accumulates items and automatically paginates" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings"

          query = request.url.query || ""

          if not String.contains?(query, "after=") do
            body = %{
              "data" => [setting_payload()],
              "meta" => %{
                "pagination" => %{
                  "has_more" => true,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_01",
                  "per_page" => 1
                },
                "request_id" => "req_123"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          else
            assert String.contains?(query, "after=ntfset_01")

            body = %{
              "data" => [%{setting_payload() | "id" => "ntfset_02"}],
              "meta" => %{
                "pagination" => %{
                  "has_more" => false,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_02",
                  "per_page" => 1
                },
                "request_id" => "req_456"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          end
        end)

      assert {:ok, items} = NotificationSettings.all(client)

      assert length(items) == 2

      assert [%NotificationSetting{id: "ntfset_01"}, %NotificationSetting{id: "ntfset_02"}] =
               items
    end
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
    }
  end

  defp setting_payload do
    %{
      "id" => "ntfset_01",
      "description" => "Main App Webhook",
      "type" => "url",
      "destination" => "https://example.com/webhooks",
      "active" => true,
      "api_version" => 1,
      "include_sensitive_fields" => true,
      "subscribed_events" => [
        %{"name" => "transaction.completed", "description" => "When a transaction is completed."}
      ]
    }
  end
end
