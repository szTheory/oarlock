defmodule Paddle.NotificationSettingTest do
  use ExUnit.Case, async: true

  alias Paddle.NotificationSetting
  alias Paddle.Http

  describe "struct" do
    test "exposes the promoted fields plus raw_data" do
      assert %NotificationSetting{
               id: nil,
               description: nil,
               type: nil,
               destination: nil,
               active: nil,
               api_version: nil,
               include_sensitive_fields: nil,
               subscribed_events: nil,
               endpoint_secret_key: nil,
               raw_data: nil
             } = %NotificationSetting{}
    end

    test "build_struct/2 promotes known keys and preserves the full payload in raw_data" do
      data = %{
        "id" => "ntfset_01",
        "description" => "Main App Webhook",
        "type" => "url",
        "destination" => "https://example.com/webhooks",
        "active" => true,
        "api_version" => 1,
        "include_sensitive_fields" => true,
        "subscribed_events" => [
          %{"name" => "transaction.completed", "description" => "When a transaction is completed."}
        ],
        "endpoint_secret_key" => "pdl_sec_xxx",
        "ignored_key" => "kept in raw only"
      }

      assert %NotificationSetting{
               id: "ntfset_01",
               description: "Main App Webhook",
               type: "url",
               destination: "https://example.com/webhooks",
               active: true,
               api_version: 1,
               include_sensitive_fields: true,
               subscribed_events: [
                 %{"name" => "transaction.completed", "description" => "When a transaction is completed."}
               ],
               endpoint_secret_key: "pdl_sec_xxx",
               raw_data: ^data
             } = Http.build_struct(NotificationSetting, data)
    end
  end
end
