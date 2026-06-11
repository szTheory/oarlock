secret = "pdl_ntf_test_fallback_secret"
payload = """
{
  "event_id": "evt_126",
  "event_type": "subscription.canceled",
  "occurred_at": "2026-06-11T12:00:00.000000Z",
  "notification_id": "ntf_124",
  "data": {
    "id": "sub_123",
    "status": "canceled",
    "customer_id": "ctm_123",
    "current_billing_period": {
      "starts_at": "2026-06-11T12:00:00.000000Z",
      "ends_at": "2026-07-11T12:00:00.000000Z"
    },
    "custom_data": {
      "mock_user_id": "mock-merchant-123"
    }
  }
}
"""

ts = System.system_time(:second)
h1 = :crypto.mac(:hmac, :sha256, secret, "#{ts}:#{payload}") |> Base.encode16(case: :lower)
signature = "ts=#{ts};h1=#{h1}"

Req.post!("http://localhost:8000/webhooks/paddle", body: payload, headers: [{"paddle-signature", signature}, {"content-type", "application/json"}, {"host", "demo.docker.localhost"}])
|> IO.inspect()
