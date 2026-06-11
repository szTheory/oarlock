defmodule DemoWeb.WebhookController do
  use DemoWeb, :controller
  require Logger

  alias Demo.Billing
  alias Demo.Repo

  @doc """
  Receives webhooks from Paddle. Uses Paddle.Webhooks to securely verify
  the payload against our configured secret, then persists it to the
  inbox for processing.
  """
  def paddle(conn, _params) do
    # 1. Read the raw body cached by CacheBodyReader
    raw_body = conn.assigns[:raw_body]

    # Note: For production, secret should be in env config.
    secret = System.get_env("PADDLE_WEBHOOK_SECRET") || "pdl_ntf_test_fallback_secret"
    signature_header = get_req_header(conn, "paddle-signature") |> List.first()

    case Paddle.Webhooks.verify_signature(raw_body, signature_header, secret) do
      {:ok, :verified} ->
        Logger.info("Webhook signature verified successfully.")

        # Persist raw payload to inbox
        raw_json = Jason.decode!(raw_body)
        case Billing.create_webhook_event(%{
               paddle_event_id: raw_json["event_id"],
               raw_data: raw_json,
               status: "pending"
             }) do
          {:ok, event_record} ->
            # Process synchronously for the demo (often done async via Oban in prod)
            process_event(event_record)
            send_resp(conn, 200, "OK")

          {:error, _changeset} ->
            Logger.error("Failed to insert webhook event into database.")
            send_resp(conn, 500, "Internal Server Error")
        end

      {:error, reason} ->
        Logger.warning("Webhook signature verification failed: #{inspect(reason)}")
        send_resp(conn, 401, "Unauthorized")
    end
  end

  defp process_event(event_record) do
    case Paddle.Webhooks.parse_event(Jason.encode!(event_record.raw_data)) do
      {:ok, %Paddle.Event{event_type: event_type} = event} when event_type in [
        "subscription.created", 
        "subscription.updated", 
        "subscription.canceled", 
        "subscription.past_due", 
        "subscription.paused"
      ] ->
        handle_subscription_change(event)
        Billing.update_webhook_event(event_record, %{status: "processed", processed_at: DateTime.utc_now()})

      {:ok, %Paddle.Event{event_type: event_type}} ->
        Logger.info("Ignoring unhandled event type: #{event_type}")
        Billing.update_webhook_event(event_record, %{status: "processed", processed_at: DateTime.utc_now()})

      {:error, error} ->
        Logger.error("Failed to parse Paddle event: #{inspect(error)}")
        Billing.update_webhook_event(event_record, %{status: "failed", error_message: inspect(error)})
    end
  end

  defp handle_subscription_change(%Paddle.Event{data: sub_data}) do
    # sub_data might be a struct or a map depending on SDK implementation.
    # We'll normalize it to a map for safe extraction.
    sub = if is_struct(sub_data), do: sub_data |> Map.from_struct(), else: sub_data
    
    mock_user_id = Map.get(sub["custom_data"] || %{}, "mock_user_id")

    if mock_user_id do
      # Upsert subscription
      attrs = %{
        mock_user_id: mock_user_id,
        paddle_customer_id: sub["customer_id"],
        paddle_subscription_id: sub["id"],
        status: sub["status"],
        current_period_end: get_in(sub, ["current_billing_period", "ends_at"])
      }

      case Repo.get_by(Demo.Billing.Subscription, mock_user_id: mock_user_id) do
        nil -> Billing.create_subscription(attrs)
        existing -> Billing.update_subscription(existing, attrs)
      end

      # Broadcast to LiveView
      Phoenix.PubSub.broadcast(Demo.PubSub, "subscriptions:#{mock_user_id}", :subscription_updated)
    else
      Logger.warning("Received subscription webhook without a mock_user_id in custom_data. Ignoring.")
    end
  end
end
