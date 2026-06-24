defmodule DemoWeb.WebhookSimulator do
  @moduledoc """
  A test helper for simulating cryptographically signed incoming Paddle Webhooks.
  """
  import Plug.Conn

  @doc """
  Sends a simulated webhook to the given connection endpoint.
  It generates a valid Paddle signature using the configured test secret.
  """
  def post_webhook(conn, path, event_type, payload_data) do
    secret = System.get_env("PADDLE_WEBHOOK_SECRET") || "pdl_ntf_test_fallback_secret"

    # Construct the base wrapper for Paddle events
    payload_wrapper = %{
      "event_id" => "evt_#{System.unique_integer()}",
      "event_type" => event_type,
      "occurred_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "notification_id" => "ntf_#{System.unique_integer()}",
      "data" => payload_data
    }

    raw_body = Jason.encode!(payload_wrapper)

    # Generate the cryptographic signature
    ts = System.system_time(:second)
    h1 = :crypto.mac(:hmac, :sha256, secret, "#{ts}:#{raw_body}") |> Base.encode16(case: :lower)
    signature = "ts=#{ts};h1=#{h1}"

    # We must set the raw_body assign to simulate how our CacheBodyReader plug
    # operates in a real environment, as `Phoenix.ConnTest` bypasses standard parsing
    # when posting a map, but we want to post the exact raw string to verify parsing.

    conn
    |> assign(:raw_body, raw_body)
    |> put_req_header("paddle-signature", signature)
    |> put_req_header("content-type", "application/json")
    |> Phoenix.ConnTest.dispatch(DemoWeb.Endpoint, :post, path, raw_body)
  end
end
