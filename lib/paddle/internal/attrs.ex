defmodule Paddle.Internal.Attrs do
  @moduledoc false

  def normalize(attrs) when is_list(attrs) do
    if Keyword.keyword?(attrs) do
      {:ok, attrs |> Enum.into(%{}) |> normalize_keys()}
    else
      {:error, :invalid_attrs}
    end
  end

  def normalize(attrs) when is_map(attrs), do: {:ok, normalize_keys(attrs)}
  def normalize(_attrs), do: {:error, :invalid_attrs}

  def normalize_keys(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, Atom.to_string(key), value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, key, value)
      {_key, _value}, acc -> acc
    end)
  end

  def allowlist(attrs, allowed_keys) do
    Enum.reduce(attrs, %{}, fn {key, value}, acc ->
      if key in allowed_keys do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end
end
