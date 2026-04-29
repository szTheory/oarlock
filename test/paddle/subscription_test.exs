defmodule Paddle.SubscriptionTest do
  use ExUnit.Case, async: true

  alias Paddle.Http
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange

  describe "%Paddle.Subscription{} struct" do
    test "exposes the promoted subscription fields plus raw_data" do
      assert %Subscription{
               id: nil,
               status: nil,
               customer_id: nil,
               address_id: nil,
               business_id: nil,
               currency_code: nil,
               collection_mode: nil,
               custom_data: nil,
               items: nil,
               scheduled_change: nil,
               management_urls: nil,
               current_billing_period: nil,
               billing_cycle: nil,
               billing_details: nil,
               discount: nil,
               next_billed_at: nil,
               started_at: nil,
               first_billed_at: nil,
               paused_at: nil,
               canceled_at: nil,
               created_at: nil,
               updated_at: nil,
               import_meta: nil,
               raw_data: nil
             } = %Subscription{}
    end

    test "build_struct/2 promotes known subscription keys and preserves the full payload in raw_data" do
      data = %{
        "id" => "sub_01",
        "status" => "active",
        "customer_id" => "ctm_01",
        "address_id" => "add_01",
        "business_id" => nil,
        "currency_code" => "USD",
        "collection_mode" => "automatic",
        "custom_data" => %{"crm_id" => "crm_123"},
        "items" => [%{"price_id" => "pri_01", "quantity" => 1}],
        "scheduled_change" => %{
          "action" => "cancel",
          "effective_at" => "2024-05-12T10:37:59.556997Z",
          "resume_at" => nil
        },
        "management_urls" => %{
          "update_payment_method" =>
            "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
          "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
        },
        "current_billing_period" => %{
          "starts_at" => "2024-04-12T10:37:59.556997Z",
          "ends_at" => "2024-05-12T10:37:59.556997Z"
        },
        "billing_cycle" => %{"frequency" => 1, "interval" => "month"},
        "billing_details" => nil,
        "discount" => nil,
        "next_billed_at" => "2024-05-12T10:37:59.556997Z",
        "started_at" => "2024-04-12T10:37:59.556997Z",
        "first_billed_at" => "2024-04-12T10:37:59.556997Z",
        "paused_at" => nil,
        "canceled_at" => nil,
        "created_at" => "2024-04-12T10:38:00.761Z",
        "updated_at" => "2024-04-12T11:24:54.873Z",
        "import_meta" => nil,
        "ignored_key" => "kept in raw only"
      }

      assert %Subscription{
               id: "sub_01",
               status: "active",
               customer_id: "ctm_01",
               address_id: "add_01",
               business_id: nil,
               currency_code: "USD",
               collection_mode: "automatic",
               custom_data: %{"crm_id" => "crm_123"},
               items: [%{"price_id" => "pri_01", "quantity" => 1}],
               scheduled_change: %{
                 "action" => "cancel",
                 "effective_at" => "2024-05-12T10:37:59.556997Z",
                 "resume_at" => nil
               },
               management_urls: %{
                 "update_payment_method" =>
                   "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
                 "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
               },
               current_billing_period: %{
                 "starts_at" => "2024-04-12T10:37:59.556997Z",
                 "ends_at" => "2024-05-12T10:37:59.556997Z"
               },
               billing_cycle: %{"frequency" => 1, "interval" => "month"},
               billing_details: nil,
               discount: nil,
               next_billed_at: "2024-05-12T10:37:59.556997Z",
               started_at: "2024-04-12T10:37:59.556997Z",
               first_billed_at: "2024-04-12T10:37:59.556997Z",
               paused_at: nil,
               canceled_at: nil,
               created_at: "2024-04-12T10:38:00.761Z",
               updated_at: "2024-04-12T11:24:54.873Z",
               import_meta: nil,
               raw_data: ^data
             } = Http.build_struct(Subscription, data)
    end
  end

  describe "%Paddle.Subscription.ScheduledChange{} struct" do
    test "exposes only action, effective_at, resume_at, and raw_data" do
      assert %ScheduledChange{action: nil, effective_at: nil, resume_at: nil, raw_data: nil} =
               %ScheduledChange{}
    end

    test "build_struct/2 promotes the scheduled_change keys and preserves the full payload in raw_data" do
      data = %{
        "action" => "cancel",
        "effective_at" => "2024-05-12T10:37:59.556997Z",
        "resume_at" => nil,
        "ignored_nested_key" => "kept in raw only"
      }

      assert %ScheduledChange{
               action: "cancel",
               effective_at: "2024-05-12T10:37:59.556997Z",
               resume_at: nil,
               raw_data: ^data
             } = Http.build_struct(ScheduledChange, data)
    end
  end

  describe "%Paddle.Subscription.ManagementUrls{} struct" do
    test "exposes only update_payment_method, cancel, and raw_data" do
      assert %ManagementUrls{update_payment_method: nil, cancel: nil, raw_data: nil} =
               %ManagementUrls{}
    end

    test "build_struct/2 promotes both portal urls and preserves the full payload in raw_data" do
      data = %{
        "update_payment_method" =>
          "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
        "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel",
        "ignored_nested_key" => "kept in raw only"
      }

      assert %ManagementUrls{
               update_payment_method:
                 "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
               cancel: "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel",
               raw_data: ^data
             } = Http.build_struct(ManagementUrls, data)
    end

    test "build_struct/2 maps update_payment_method to nil for manual-collection subscriptions" do
      data = %{
        "update_payment_method" => nil,
        "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
      }

      assert %ManagementUrls{
               update_payment_method: nil,
               cancel: "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel",
               raw_data: ^data
             } = Http.build_struct(ManagementUrls, data)
    end
  end
end
