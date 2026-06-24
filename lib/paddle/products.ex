defmodule Paddle.Products do
  @moduledoc """
  Provides the interface for managing products via the Paddle Billing API.

  Products are the primary items in the Paddle Catalog.

  > #### Warning {: .warning}
  > Custom products created dynamically during checkout are NOT returned by this Catalog API.
  > This API only returns standard Catalog products.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123")

  case Paddle.Products.get(client, "pro_12345") do
    {:ok, %Paddle.Product{} = product} ->
      IO.puts("Found product: \#{product.name}")

    {:error, %Paddle.Error{} = error} ->
      IO.inspect(error, label: "Paddle API Error")

    {:error, :invalid_product_id} ->
      IO.puts("The provided product ID was invalid.")
  end
  ```
  """

  alias Paddle.Client
  alias Paddle.Product
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination

  @type product_id :: String.t()
  @type request_opt :: {:idempotency_key, String.t()} | {:retry, boolean()}

  @list_allowlist ~w(after id status tax_category order_by per_page)

  @doc """
  Retrieves a product by ID.

  ## Examples

      Paddle.Products.get(client, "pro_01")
  """
  @spec get(Paddle.Client.t(), product_id()) ::
          {:ok, Paddle.Product.t()} | {:error, Paddle.Error.t() | :invalid_product_id}
  def get(%Client{} = client, product_id) do
    with :ok <- validate_product_id(product_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, product_path(product_id)) do
      {:ok, Http.build_struct(Product, data)}
    end
  end

  @doc """
  Lists products.

  ## Examples

      Paddle.Products.list(client, status: "active", per_page: 10)
  """
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/products", params: query) do
      {:ok, build_page(data, meta)}
    end
  end

  @doc """
  Returns a stream of products.
  """
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Retrieves all products, automatically handling pagination.
  """
  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.Product.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  defp validate_product_id(product_id) when is_binary(product_id) do
    if String.trim(product_id) == "" do
      {:error, :invalid_product_id}
    else
      :ok
    end
  end

  defp validate_product_id(_product_id), do: {:error, :invalid_product_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp product_path(product_id), do: "/products/#{encode_path_segment(product_id)}"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)

  defp next_page(client, path) do
    with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, path) do
      {:ok, build_page(data, meta)}
    end
  end

  defp build_page(data, meta) do
    Pagination.build_page(Product, data, meta)
  end
end
