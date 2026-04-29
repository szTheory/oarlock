defmodule Paddle.Customers.Addresses do
  alias Paddle.Address
  alias Paddle.Http

  @create_allowlist ~w(description first_line second_line city postal_code region country_code custom_data)
  @list_allowlist ~w(id after per_page order_by status search)
  @update_allowlist ~w(description first_line second_line city postal_code region country_code custom_data status)

  def create(%Paddle.Client{} = client, customer_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- normalize_attrs(attrs),
         body <- allowlist_attrs(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, customer_addresses_path(customer_id), json: body) do
      {:ok, Http.build_struct(Address, data)}
    end
  end

  def get(%Paddle.Client{} = client, customer_id, address_id) do
    with :ok <- validate_customer_id(customer_id),
         :ok <- validate_address_id(address_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, customer_address_path(customer_id, address_id)) do
      {:ok, Http.build_struct(Address, data)}
    end
  end

  def list(%Paddle.Client{} = client, customer_id, params \\ []) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, params} <- normalize_params(params),
         query <- allowlist_attrs(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, customer_addresses_path(customer_id), params: query) do
      {:ok,
       %Paddle.Page{
         data: Enum.map(data, &Http.build_struct(Address, &1)),
         meta: meta
       }}
    end
  end

  def update(%Paddle.Client{} = client, customer_id, address_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         :ok <- validate_address_id(address_id),
         {:ok, attrs} <- normalize_attrs(attrs),
         body <- allowlist_attrs(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, customer_address_path(customer_id, address_id), json: body) do
      {:ok, Http.build_struct(Address, data)}
    end
  end

  defp customer_addresses_path(customer_id),
    do: "/customers/#{encode_path_segment(customer_id)}/addresses"

  defp customer_address_path(customer_id, address_id) do
    "#{customer_addresses_path(customer_id)}/#{encode_path_segment(address_id)}"
  end

  defp validate_customer_id(customer_id), do: validate_id(customer_id, :invalid_customer_id)
  defp validate_address_id(address_id), do: validate_id(address_id, :invalid_address_id)

  defp validate_id(id, error) when is_binary(id) do
    if String.trim(id) == "" do
      {:error, error}
    else
      :ok
    end
  end

  defp validate_id(_id, error), do: {:error, error}

  defp normalize_attrs(attrs) when is_list(attrs) do
    if Keyword.keyword?(attrs) do
      {:ok, attrs |> Enum.into(%{}) |> normalize_map_keys()}
    else
      {:error, :invalid_attrs}
    end
  end

  defp normalize_attrs(attrs) when is_map(attrs), do: {:ok, normalize_map_keys(attrs)}
  defp normalize_attrs(_attrs), do: {:error, :invalid_attrs}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> normalize_map_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, normalize_map_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

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

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
