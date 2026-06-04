defmodule Paddle.Webhooks do
  @moduledoc """
  Provides functions for verifying and parsing webhooks from the Paddle Billing API.

  ## Example Pipeline

  ```elixir
  # In a Phoenix controller or similar HTTP handler

  secret_key = System.fetch_env!("PADDLE_WEBHOOK_SECRET")
  signature_header = get_req_header(conn, "paddle-signature")
  raw_body = conn.assigns.raw_body # Note: Ensure you have the raw, unparsed body

  case Paddle.Webhooks.verify_signature(raw_body, signature_header, secret_key) do
    {:ok, :verified} ->
      case Paddle.Webhooks.parse_event(raw_body) do
        {:ok, %Paddle.Event{} = event} ->
          # Process the event
          IO.puts("Received event: \#{event.event_type}")

        {:error, :invalid_event_payload} ->
          IO.puts("Event payload was missing required fields.")

        {:error, :invalid_json} ->
          IO.puts("Body could not be decoded as JSON.")
      end

    {:error, :signature_mismatch} ->
      IO.puts("Signature did not match. Possible tampering.")

    {:error, reason} ->
      IO.puts("Failed to verify webhook: \#{reason}")
  end
  ```
  """

  @default_tolerance 5
  @required_digest_bytes 32
  @required_keys ~w(event_id event_type occurred_at notification_id data)

  @type verify_opt :: {:tolerance, non_neg_integer()} | {:now, integer()}

  @doc """
  Verifies the `Paddle-Signature` header from an incoming webhook request.

  This ensures that the request originated from Paddle and has not been tampered with in transit.

  ```elixir
  raw_body = "{\\"data\\":{...}}"
  signature_header = "ts=1690000000;h1=abcd..."
  secret_key = "pdl_wh_..."

  case Paddle.Webhooks.verify_signature(raw_body, signature_header, secret_key) do
    {:ok, :verified} ->
      # Signature is valid
      :ok

    {:error, :signature_mismatch} ->
      # The signatures did not match
      :error

    {:error, :stale_timestamp} ->
      # The webhook is too old (older than tolerance)
      :error

    {:error, :invalid_signature_header} ->
      # The header was malformed
      :error
  end
  ```

  ## Errors
  - `{:error, :invalid_signature_header}`: The `Paddle-Signature` header is malformed.
  - `{:error, :invalid_timestamp}`: The timestamp in the header could not be parsed.
  - `{:error, :invalid_tolerance}`: The provided tolerance option was invalid.
  - `{:error, :empty_signature}`: The header contained an empty signature value.
  - `{:error, :missing_timestamp}`: The header did not contain a timestamp (`ts=`).
  - `{:error, :missing_signature}`: The header did not contain a signature (`h1=`).
  - `{:error, :stale_timestamp}`: The timestamp is older than `now - tolerance`.
  - `{:error, :future_timestamp}`: The timestamp is further in the future than `now + tolerance`.
  - `{:error, :signature_mismatch}`: The computed signature did not match any of the provided signatures.

  ## Related Paddle docs
  https://developer.paddle.com/webhooks/overview
  """
  @spec verify_signature(String.t(), String.t(), String.t(), [verify_opt()]) ::
          {:ok, :verified}
          | {:error,
             :invalid_signature_header
             | :invalid_timestamp
             | :invalid_tolerance
             | :empty_signature
             | :missing_timestamp
             | :missing_signature
             | :stale_timestamp
             | :future_timestamp
             | :signature_mismatch}
  def verify_signature(raw_body, signature_header, secret_key, opts \\ [])

  def verify_signature(raw_body, signature_header, secret_key, opts)
      when is_binary(raw_body) and is_binary(signature_header) and is_binary(secret_key) do
    with {:ok, tolerance} <- normalize_tolerance(opts[:tolerance] || @default_tolerance),
         {:ok, timestamp, signatures} <- parse_signature_header(signature_header),
         :ok <-
           validate_timestamp(
             timestamp,
             Keyword.get(opts, :now, System.os_time(:second)),
             tolerance
           ),
         expected_digest <- expected_digest(timestamp, raw_body, secret_key),
         false <- Enum.empty?(signatures),
         true <- Enum.any?(signatures, &secure_compare_digest(expected_digest, &1)) do
      {:ok, :verified}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :signature_mismatch}
    end
  end

  def verify_signature(_raw_body, _signature_header, _secret_key, _opts) do
    {:error, :invalid_signature_header}
  end

  @doc """
  Parses the raw webhook body into a `Paddle.Event` struct.

  It is highly recommended to call `verify_signature/4` before parsing the event.

  ```elixir
  raw_body = "{\\"event_id\\":\\"evt_123\\",\\"event_type\\":\\"customer.created\\",...}"

  case Paddle.Webhooks.parse_event(raw_body) do
    {:ok, %Paddle.Event{} = event} ->
      # Event parsed successfully
      event

    {:error, :invalid_json} ->
      # The body is not valid JSON
      :error

    {:error, :invalid_event_payload} ->
      # The JSON is missing required top-level event fields
      :error
  end
  ```

  ## Errors
  - `{:error, :invalid_json}`: The raw body could not be decoded by Jason.
  - `{:error, :invalid_event_payload}`: The JSON payload was decoded but did not contain the required webhook wrapper keys (`event_id`, `event_type`, `occurred_at`, `notification_id`, `data`).

  ## Related Paddle docs
  https://developer.paddle.com/webhooks/overview
  """
  @spec parse_event(String.t()) ::
          {:ok, Paddle.Event.t()}
          | {:error, :invalid_json | :invalid_event_payload}
  def parse_event(raw_body) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, %{"data" => data} = payload} when is_map(data) ->
        if valid_payload?(payload) do
          {:ok, Paddle.Http.build_struct(Paddle.Event, payload)}
        else
          {:error, :invalid_event_payload}
        end

      {:ok, _payload} ->
        {:error, :invalid_event_payload}

      {:error, _reason} ->
        {:error, :invalid_json}
    end
  end

  defp valid_payload?(payload) do
    Enum.all?(@required_keys, &Map.has_key?(payload, &1))
  end

  defp normalize_tolerance(tolerance) when is_integer(tolerance) and tolerance >= 0,
    do: {:ok, tolerance}

  defp normalize_tolerance(_tolerance), do: {:error, :invalid_tolerance}

  defp parse_signature_header(signature_header) do
    with {:ok, parts} <- split_header(signature_header),
         {:ok, parsed} <- parse_segments(parts),
         {:ok, timestamp} <- fetch_timestamp(parsed),
         {:ok, signatures} <- fetch_signatures(parsed) do
      {:ok, timestamp, signatures}
    end
  end

  defp split_header(signature_header) do
    parts =
      signature_header
      |> String.split(";", trim: false)
      |> Enum.map(&String.trim/1)

    cond do
      parts == [] ->
        {:error, :invalid_signature_header}

      Enum.any?(parts, &(&1 == "")) ->
        {:error, :invalid_signature_header}

      true ->
        {:ok, parts}
    end
  end

  defp parse_segments(parts) do
    Enum.reduce_while(parts, {:ok, %{ts: nil, signatures: []}}, fn part, {:ok, acc} ->
      case String.split(part, "=", parts: 2) do
        [key, value] -> reduce_segment(String.trim(key), String.trim(value), acc)
        _parts -> {:halt, {:error, :invalid_signature_header}}
      end
    end)
  end

  defp reduce_segment("ts", "", _acc), do: {:halt, {:error, :invalid_timestamp}}

  defp reduce_segment("ts", value, %{ts: nil} = acc) do
    case Integer.parse(value) do
      {timestamp, ""} -> {:cont, {:ok, %{acc | ts: timestamp}}}
      _result -> {:halt, {:error, :invalid_timestamp}}
    end
  end

  defp reduce_segment("ts", _value, _acc), do: {:halt, {:error, :invalid_signature_header}}
  defp reduce_segment("h1", "", _acc), do: {:halt, {:error, :empty_signature}}

  defp reduce_segment("h1", value, acc) do
    if valid_digest?(value) do
      {:cont, {:ok, %{acc | signatures: [String.downcase(value) | acc.signatures]}}}
    else
      {:halt, {:error, :invalid_signature_header}}
    end
  end

  defp reduce_segment(_key, _value, _acc), do: {:halt, {:error, :invalid_signature_header}}

  defp fetch_timestamp(%{ts: nil}), do: {:error, :missing_timestamp}
  defp fetch_timestamp(%{ts: timestamp}), do: {:ok, timestamp}

  defp fetch_signatures(%{signatures: []}), do: {:error, :missing_signature}
  defp fetch_signatures(%{signatures: signatures}), do: {:ok, Enum.reverse(signatures)}

  defp validate_timestamp(timestamp, now, tolerance)
       when is_integer(timestamp) and is_integer(now) do
    cond do
      timestamp < now - tolerance -> {:error, :stale_timestamp}
      timestamp > now + tolerance -> {:error, :future_timestamp}
      true -> :ok
    end
  end

  defp validate_timestamp(_timestamp, _now, _tolerance), do: {:error, :invalid_timestamp}

  defp expected_digest(timestamp, raw_body, secret_key) do
    :crypto.mac(:hmac, :sha256, secret_key, "#{timestamp}:#{raw_body}")
  end

  defp secure_compare_digest(expected_digest, candidate_digest) do
    with true <- byte_size(expected_digest) == @required_digest_bytes,
         true <- valid_digest?(candidate_digest),
         {:ok, candidate_binary} <- Base.decode16(candidate_digest, case: :mixed) do
      :crypto.hash_equals(expected_digest, candidate_binary)
    else
      _result -> false
    end
  end

  defp valid_digest?(digest) when is_binary(digest) do
    byte_size(digest) == @required_digest_bytes * 2 and
      String.match?(digest, ~r/\A[0-9a-fA-F]+\z/)
  end

  defp valid_digest?(_digest), do: false
end
