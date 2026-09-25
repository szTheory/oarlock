defmodule Paddle.SubscriptionFlowsTest do
  use ExUnit.Case, async: false

  alias Paddle.Subscription

  setup_all do
    if System.get_env("PADDLE_API_KEY") && System.get_env("INTEGRATION_TESTS") == "true" do
      {:ok,
       client:
         Paddle.Client.new!(api_key: System.get_env("PADDLE_API_KEY"), environment: :sandbox)}
    else
      port = 4448
      {:ok, _pid} = Paddle.MockServer.start_link(port: port)

      client =
        Paddle.Client.new!(
          api_key: "sk_test_mock",
          base_url: "http://localhost:#{port}"
        )

      {:ok, client: client}
    end
  end

  test "immediate upgrade processes immediately and returns updated subscription", %{
    client: client
  } do
    assert {:ok, %Subscription{} = sub} =
             Paddle.Subscriptions.update(
               client,
               "sub_mock123",
               items: [%{price_id: "pri_upgrade", quantity: 1}],
               proration_billing_mode: "prorated_immediately"
             )

    assert sub.id == "sub_mock123"
    assert sub.scheduled_change == nil
  end

  test "scheduled downgrade populates scheduled_change struct on returned subscription", %{
    client: client
  } do
    assert {:ok, %Subscription{} = sub} =
             Paddle.Subscriptions.update(
               client,
               "sub_mock123",
               items: [%{price_id: "pri_downgrade", quantity: 1}],
               proration_billing_mode: "next_billing_period"
             )

    assert sub.id == "sub_mock123"

    assert %Subscription.ScheduledChange{
             action: "pause",
             effective_at: "2026-12-01T12:00:00Z"
           } = sub.scheduled_change
  end
end
