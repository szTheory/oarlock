defmodule Demo.BillingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Demo.Billing` context.
  """

  @doc """
  Generate a unique webhook_event paddle_event_id.
  """
  def unique_webhook_event_paddle_event_id,
    do: "some paddle_event_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a webhook_event.
  """
  def webhook_event_fixture(attrs \\ %{}) do
    {:ok, webhook_event} =
      attrs
      |> Enum.into(%{
        error_message: "some error_message",
        paddle_event_id: unique_webhook_event_paddle_event_id(),
        processed_at: ~U[2026-06-10 15:59:00Z],
        raw_data: %{},
        status: "some status"
      })
      |> Demo.Billing.create_webhook_event()

    webhook_event
  end

  @doc """
  Generate a unique subscription mock_user_id.
  """
  def unique_subscription_mock_user_id,
    do: "some mock_user_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(%{
        current_period_end: ~U[2026-06-10 16:01:00Z],
        mock_user_id: unique_subscription_mock_user_id(),
        paddle_customer_id: "some paddle_customer_id",
        paddle_subscription_id: "some paddle_subscription_id",
        status: "some status"
      })
      |> Demo.Billing.create_subscription()

    subscription
  end
end
