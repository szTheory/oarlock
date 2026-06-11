defmodule Demo.BillingTest do
  use Demo.DataCase

  alias Demo.Billing

  describe "webhook_events" do
    alias Demo.Billing.WebhookEvent

    import Demo.BillingFixtures

    @invalid_attrs %{status: nil, paddle_event_id: nil, raw_data: nil, processed_at: nil, error_message: nil}

    test "list_webhook_events/0 returns all webhook_events" do
      webhook_event = webhook_event_fixture()
      assert Billing.list_webhook_events() == [webhook_event]
    end

    test "get_webhook_event!/1 returns the webhook_event with given id" do
      webhook_event = webhook_event_fixture()
      assert Billing.get_webhook_event!(webhook_event.id) == webhook_event
    end

    test "create_webhook_event/1 with valid data creates a webhook_event" do
      valid_attrs = %{status: "some status", paddle_event_id: "some paddle_event_id", raw_data: %{}, processed_at: ~U[2026-06-10 15:59:00Z], error_message: "some error_message"}

      assert {:ok, %WebhookEvent{} = webhook_event} = Billing.create_webhook_event(valid_attrs)
      assert webhook_event.status == "some status"
      assert webhook_event.paddle_event_id == "some paddle_event_id"
      assert webhook_event.raw_data == %{}
      assert webhook_event.processed_at == ~U[2026-06-10 15:59:00Z]
      assert webhook_event.error_message == "some error_message"
    end

    test "create_webhook_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Billing.create_webhook_event(@invalid_attrs)
    end

    test "update_webhook_event/2 with valid data updates the webhook_event" do
      webhook_event = webhook_event_fixture()
      update_attrs = %{status: "some updated status", paddle_event_id: "some updated paddle_event_id", raw_data: %{}, processed_at: ~U[2026-06-11 15:59:00Z], error_message: "some updated error_message"}

      assert {:ok, %WebhookEvent{} = webhook_event} = Billing.update_webhook_event(webhook_event, update_attrs)
      assert webhook_event.status == "some updated status"
      assert webhook_event.paddle_event_id == "some updated paddle_event_id"
      assert webhook_event.raw_data == %{}
      assert webhook_event.processed_at == ~U[2026-06-11 15:59:00Z]
      assert webhook_event.error_message == "some updated error_message"
    end

    test "update_webhook_event/2 with invalid data returns error changeset" do
      webhook_event = webhook_event_fixture()
      assert {:error, %Ecto.Changeset{}} = Billing.update_webhook_event(webhook_event, @invalid_attrs)
      assert webhook_event == Billing.get_webhook_event!(webhook_event.id)
    end

    test "delete_webhook_event/1 deletes the webhook_event" do
      webhook_event = webhook_event_fixture()
      assert {:ok, %WebhookEvent{}} = Billing.delete_webhook_event(webhook_event)
      assert_raise Ecto.NoResultsError, fn -> Billing.get_webhook_event!(webhook_event.id) end
    end

    test "change_webhook_event/1 returns a webhook_event changeset" do
      webhook_event = webhook_event_fixture()
      assert %Ecto.Changeset{} = Billing.change_webhook_event(webhook_event)
    end
  end

  describe "subscriptions" do
    alias Demo.Billing.Subscription

    import Demo.BillingFixtures

    @invalid_attrs %{status: nil, mock_user_id: nil, paddle_customer_id: nil, paddle_subscription_id: nil, current_period_end: nil}

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = subscription_fixture()
      assert Billing.list_subscriptions() == [subscription]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = subscription_fixture()
      assert Billing.get_subscription!(subscription.id) == subscription
    end

    test "create_subscription/1 with valid data creates a subscription" do
      valid_attrs = %{status: "some status", mock_user_id: "some mock_user_id", paddle_customer_id: "some paddle_customer_id", paddle_subscription_id: "some paddle_subscription_id", current_period_end: ~U[2026-06-10 16:01:00Z]}

      assert {:ok, %Subscription{} = subscription} = Billing.create_subscription(valid_attrs)
      assert subscription.status == "some status"
      assert subscription.mock_user_id == "some mock_user_id"
      assert subscription.paddle_customer_id == "some paddle_customer_id"
      assert subscription.paddle_subscription_id == "some paddle_subscription_id"
      assert subscription.current_period_end == ~U[2026-06-10 16:01:00Z]
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Billing.create_subscription(@invalid_attrs)
    end

    test "update_subscription/2 with valid data updates the subscription" do
      subscription = subscription_fixture()
      update_attrs = %{status: "some updated status", mock_user_id: "some updated mock_user_id", paddle_customer_id: "some updated paddle_customer_id", paddle_subscription_id: "some updated paddle_subscription_id", current_period_end: ~U[2026-06-11 16:01:00Z]}

      assert {:ok, %Subscription{} = subscription} = Billing.update_subscription(subscription, update_attrs)
      assert subscription.status == "some updated status"
      assert subscription.mock_user_id == "some updated mock_user_id"
      assert subscription.paddle_customer_id == "some updated paddle_customer_id"
      assert subscription.paddle_subscription_id == "some updated paddle_subscription_id"
      assert subscription.current_period_end == ~U[2026-06-11 16:01:00Z]
    end

    test "update_subscription/2 with invalid data returns error changeset" do
      subscription = subscription_fixture()
      assert {:error, %Ecto.Changeset{}} = Billing.update_subscription(subscription, @invalid_attrs)
      assert subscription == Billing.get_subscription!(subscription.id)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = subscription_fixture()
      assert {:ok, %Subscription{}} = Billing.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Billing.get_subscription!(subscription.id) end
    end

    test "change_subscription/1 returns a subscription changeset" do
      subscription = subscription_fixture()
      assert %Ecto.Changeset{} = Billing.change_subscription(subscription)
    end
  end
end
