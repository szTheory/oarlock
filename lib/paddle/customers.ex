defmodule Paddle.Customers do
  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Http

  @create_allowlist ~w(email name custom_data locale)
  @update_allowlist ~w(name email status custom_data locale)

  def create(%Client{} = client, attrs) do
    with {:ok, attrs} <- normalize_attrs(attrs),
         body <- allowlist_attrs(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <- Http.request(client, :post, "/customers", json: body) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  def get(%Client{} = client, customer_id) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, "/customers/#{customer_id}") do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  def update(%Client{} = client, customer_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- normalize_attrs(attrs),
         body <- allowlist_attrs(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, "/customers/#{customer_id}", json: body) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  defp validate_customer_id(customer_id) when is_binary(customer_id) do
    if String.trim(customer_id) == "" do
      {:error, :invalid_customer_id}
    else
      :ok
    end
  end

  defp validate_customer_id(_customer_id), do: {:error, :invalid_customer_id}

  defp normalize_attrs(attrs) when is_list(attrs) do
    if Keyword.keyword?(attrs) do
      {:ok, attrs |> Enum.into(%{}) |> normalize_map_keys()}
    else
      {:error, :invalid_attrs}
    end
  end

  defp normalize_attrs(attrs) when is_map(attrs), do: {:ok, normalize_map_keys(attrs)}
  defp normalize_attrs(_attrs), do: {:error, :invalid_attrs}

  defp normalize_map_keys(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, Atom.to_string(key), value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, key, value)
      {_key, _value}, acc -> acc
    end)
  end

  defp allowlist_attrs(attrs, allowed_keys) do
    Enum.reduce(attrs, %{}, fn {key, value}, acc ->
      if key in allowed_keys do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end
end
