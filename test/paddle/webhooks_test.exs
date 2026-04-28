defmodule Paddle.WebhooksTest do
  use ExUnit.Case, async: true

  alias Paddle.Webhooks

  @secret "pdl_ntfset_test_secret"
  @now 1_700_000_000

  describe "verify_signature/4" do
    test "returns ok for a valid raw-body signature" do
      raw_body = ~s({"event_id":"evt_01"})
      header = signature_header(raw_body, @secret, @now)

      assert {:ok, :verified} = Webhooks.verify_signature(raw_body, header, @secret, now: @now)
    end

    test "accepts any matching h1 during secret rotation" do
      raw_body = ~s({"event_id":"evt_01"})
      valid_signature = signature(@now, raw_body, @secret)
      rotated_signature = String.duplicate("a", 64)
      header = "ts=#{@now};h1=#{rotated_signature};h1=#{valid_signature}"

      assert {:ok, :verified} = Webhooks.verify_signature(raw_body, header, @secret, now: @now)
    end

    test "rejects a tampered raw body" do
      original_body = ~s({"event_id":"evt_01"})
      tampered_body = ~s({"event_id":"evt_02"})
      header = signature_header(original_body, @secret, @now)

      assert {:error, :signature_mismatch} =
               Webhooks.verify_signature(tampered_body, header, @secret, now: @now)
    end

    test "rejects stale timestamps outside the default tolerance" do
      raw_body = ~s({"event_id":"evt_01"})
      timestamp = @now - 6
      header = signature_header(raw_body, @secret, timestamp)

      assert {:error, :stale_timestamp} =
               Webhooks.verify_signature(raw_body, header, @secret, now: @now)
    end

    test "rejects future timestamps outside the default tolerance" do
      raw_body = ~s({"event_id":"evt_01"})
      timestamp = @now + 6
      header = signature_header(raw_body, @secret, timestamp)

      assert {:error, :future_timestamp} =
               Webhooks.verify_signature(raw_body, header, @secret, now: @now)
    end

    test "accepts a custom tolerance override" do
      raw_body = ~s({"event_id":"evt_01"})
      timestamp = @now - 10
      header = signature_header(raw_body, @secret, timestamp)

      assert {:ok, :verified} =
               Webhooks.verify_signature(raw_body, header, @secret, now: @now, tolerance: 10)
    end

    test "fails when the header is missing `ts`" do
      raw_body = ~s({"event_id":"evt_01"})
      digest = signature(@now, raw_body, @secret)

      assert {:error, :missing_timestamp} =
               Webhooks.verify_signature(raw_body, "h1=#{digest}", @secret, now: @now)
    end

    test "fails when the header is missing `h1`" do
      raw_body = ~s({"event_id":"evt_01"})

      assert {:error, :missing_signature} =
               Webhooks.verify_signature(raw_body, "ts=#{@now}", @secret, now: @now)
    end

    test "fails when the header contains an empty `h1`" do
      raw_body = ~s({"event_id":"evt_01"})

      assert {:error, :empty_signature} =
               Webhooks.verify_signature(raw_body, "ts=#{@now};h1=", @secret, now: @now)
    end

    test "fails when the header contains malformed segments" do
      raw_body = ~s({"event_id":"evt_01"})

      assert {:error, :invalid_signature_header} =
               Webhooks.verify_signature(raw_body, "ts=#{@now};invalid", @secret, now: @now)
    end

    test "fails when `ts` is not an integer" do
      raw_body = ~s({"event_id":"evt_01"})
      digest = signature(@now, raw_body, @secret)

      assert {:error, :invalid_timestamp} =
               Webhooks.verify_signature(raw_body, "ts=abc;h1=#{digest}", @secret, now: @now)
    end
  end

  defp signature_header(raw_body, secret, timestamp) do
    "ts=#{timestamp};h1=#{signature(timestamp, raw_body, secret)}"
  end

  defp signature(timestamp, raw_body, secret) do
    :crypto.mac(:hmac, :sha256, secret, "#{timestamp}:#{raw_body}")
    |> Base.encode16(case: :lower)
  end
end
