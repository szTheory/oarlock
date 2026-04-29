defmodule Paddle.Customers.Addresses do
  alias Paddle.Address
  alias Paddle.Http
  alias Paddle.Internal.Attrs

  @create_allowlist ~w(description first_line second_line city postal_code region country_code custom_data)
  @list_allowlist ~w(id after per_page order_by status search)
  @update_allowlist ~w(description first_line second_line city postal_code region country_code custom_data status)

  def create(%Paddle.Client{} = client, customer_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
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
         query <- Attrs.allowlist(params, @list_allowlist),
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
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, customer_address_path(customer_id, address_id),
             json: body
           ) do
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

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
