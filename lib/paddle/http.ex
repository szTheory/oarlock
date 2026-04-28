defmodule Paddle.Http do
  def request(%Paddle.Client{} = client, method, path, opts \\ []) do
    opts = Keyword.merge(opts, method: method, url: path)

    case Req.request(client.req, opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{} = resp} ->
        {:error, Paddle.Error.from_response(resp)}

      {:error, exception} ->
        {:error, exception}
    end
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
