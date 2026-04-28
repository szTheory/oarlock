defmodule Paddle.Webhooks do
  @default_tolerance 5
  @required_digest_bytes 32
  @required_keys ~w(event_id event_type occurred_at notification_id data)

  def verify_signature(raw_body, signature_header, secret_key, opts \\ [])

  def verify_signature(raw_body, signature_header, secret_key, opts)
      when is_binary(raw_body) and is_binary(signature_header) and is_binary(secret_key) do
    with {:ok, tolerance} <- normalize_tolerance(opts[:tolerance] || @default_tolerance),
         {:ok, timestamp, signatures} <- parse_signature_header(signature_header),
         :ok <- validate_timestamp(timestamp, Keyword.get(opts, :now, System.os_time(:second)), tolerance),
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

  defp normalize_tolerance(tolerance) when is_integer(tolerance) and tolerance >= 0, do: {:ok, tolerance}
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
      |> String.split(";", trim: true)
      |> Enum.map(&String.trim/1)

    if parts == [] do
      {:error, :invalid_signature_header}
    else
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

  defp validate_timestamp(timestamp, now, tolerance) when is_integer(timestamp) and is_integer(now) do
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
