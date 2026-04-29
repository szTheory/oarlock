defmodule Paddle.Customers do
  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Http
  alias Paddle.Internal.Attrs

  @create_allowlist ~w(email name custom_data locale)
  @update_allowlist ~w(name email status custom_data locale)

  def create(%Client{} = client, attrs) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, "/customers", json: body) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  def get(%Client{} = client, customer_id) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, customer_path(customer_id)) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  def update(%Client{} = client, customer_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, customer_path(customer_id), json: body) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  defp customer_path(customer_id), do: "/customers/#{encode_path_segment(customer_id)}"

  defp validate_customer_id(customer_id) when is_binary(customer_id) do
    if String.trim(customer_id) == "" do
      {:error, :invalid_customer_id}
    else
      :ok
    end
  end

  defp validate_customer_id(_customer_id), do: {:error, :invalid_customer_id}

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
