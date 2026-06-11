defmodule DemoWeb.Integration.BillingFlowTest do
  use DemoWeb.ConnCase, async: false
  import PhoenixTest

  alias DemoWeb.WebhookSimulator

  test "E2E Billing Flow: User signs in, intends to checkout, and real-time UI updates on webhook", %{conn: conn} do
    # Phase A: Unauthenticated access is blocked
    conn
    |> visit("/admin")
    |> assert_path("/login")

    # Phase B: Mock Auth via UI
    session =
      conn
      |> visit("/login")
      |> click_button("Login as Demo Merchant")
      |> assert_path("/admin")
      |> assert_has("h1", text: "Dashboard")
      |> assert_has("h3", text: "No Active Subscription")
      |> assert_has("button", text: "Subscribe Now")
      
    # Phase D & E: Simulate Webhook & Real-time PubSub update
    # In a real E2E test with Playwright, we would click checkout, fill out the paddle iframe,
    # and Paddle would hit our live webhook. Here we shift-left by simulating the webhook 
    # directly against our endpoint, while keeping the LiveView session open via phoenix_test.
    
    webhook_payload = %{
      "id" => "sub_test_e2e_123",
      "status" => "active",
      "customer_id" => "ctm_test_123",
      "current_billing_period" => %{
        "starts_at" => "2026-06-11T12:00:00.000000Z",
        "ends_at" => "2026-07-11T12:00:00.000000Z"
      },
      "custom_data" => %{
        "mock_user_id" => "mock-merchant-123" # The ID of the mock user from MockAuth
      }
    }

    # Simulate Paddle sending the webhook to our application using a fresh connection
    WebhookSimulator.post_webhook(build_conn(), "/webhooks/paddle", "subscription.created", webhook_payload)

    # Because PhoenixTest natively wraps LiveView, we can just assert on the existing `session`
    # and it will automatically handle the PubSub re-render cycle!
    session
    |> assert_has("h3", text: "Subscription Active")
    |> assert_has("button", text: "Manage Subscription")
    |> refute_has("button", text: "Subscribe Now")
  end
end
