defmodule Paddle.Http do
  @moduledoc false

  def request(%Paddle.Client{} = client, method, path, opts \\ []) do
    idempotency_key_present? = Keyword.has_key?(opts, :idempotency_key)
    {idempotency_key, opts} = Keyword.pop(opts, :idempotency_key)
    opts = Keyword.merge(opts, method: method, url: path)
    opts = maybe_add_idempotency_header(opts, idempotency_key, idempotency_key_present?)

    case Req.request(client.req, opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{} = resp} ->
        {:error, Paddle.Error.from_response(resp)}

      {:error, %Req.TransportError{} = exception} ->
        {:error, Paddle.Error.from_transport(exception)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp maybe_add_idempotency_header(opts, nil, false), do: opts

  defp maybe_add_idempotency_header(_opts, nil, true) do
    raise ArgumentError, "idempotency_key must be a non-empty string, got: nil"
  end

  defp maybe_add_idempotency_header(opts, key, true) when is_binary(key) do
    trimmed = String.trim(key)

    if trimmed == "" do
      raise ArgumentError,
            "idempotency_key must be a non-empty string, got: #{inspect(key)}"
    else
      Keyword.update(
        opts,
        :headers,
        [{"Idempotency-Key", key}],
        &[{"Idempotency-Key", key} | &1]
      )
    end
  end

  defp maybe_add_idempotency_header(_opts, key, true) do
    raise ArgumentError,
          "idempotency_key must be a non-empty string, got: #{inspect(key)}"
  end

  def build_struct(struct_module, data) when is_map(data) do
    base_struct = struct(struct_module)
    valid_keys = Map.keys(base_struct) |> Enum.map(&to_string/1)

    attrs =
      data
      |> Enum.filter(fn {k, _} -> k in valid_keys end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Enum.into(%{})

    struct(struct_module, Map.put(attrs, :raw_data, data))
  end
end
