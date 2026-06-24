defmodule Paddle.Prices do
  @moduledoc """
  Provides operations for retrieving Paddle Prices.

  > **Important Note:** Custom prices created dynamically during checkout are NOT returned by this Catalog API. This API only returns predefined Catalog prices.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123")

  case Paddle.Prices.get(client, "pri_12345") do
    {:ok, %Paddle.Price{} = price} ->
      IO.puts("Found price: \#{price.description}")

    {:error, %Paddle.Error{} = error} ->
      IO.inspect(error, label: "Paddle API Error")

    {:error, :invalid_price_id} ->
      IO.puts("The provided price ID was invalid.")
  end
  ```
  """

  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
  alias Paddle.Price

  @type price_id :: String.t()

  @list_allowlist ~w(id product_id status recurring type order_by after per_page)

  @doc """
  Retrieves a specific price by ID.

  ## Examples

  ```elixir
  case Paddle.Prices.get(client, "pri_12345") do
    {:ok, %Paddle.Price{} = price} ->
      # Price retrieved successfully
      price

    {:error, :invalid_price_id} ->
      # The price ID was empty or not a string
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error (e.g. 404 Not Found)
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_price_id}`: The provided price ID was not a binary, or was an empty string.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/prices/get-price
  """
  @spec get(Paddle.Client.t(), price_id()) ::
          {:ok, Paddle.Price.t()} | {:error, Paddle.Error.t() | :invalid_price_id}
  def get(%Client{} = client, price_id) do
    with :ok <- validate_price_id(price_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, price_path(price_id)) do
      {:ok, Http.build_struct(Price, data)}
    end
  end

  @doc """
  Lists prices.

  ## Examples

  ```elixir
  case Paddle.Prices.list(client, per_page: 10) do
    {:ok, %Paddle.Page{} = page} ->
      page.data

    {:error, :invalid_params} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Provider behavior
  Filtering and sorting options must match the allowlist.
  Eager hydration (`include`) is not supported by this SDK.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/prices/list-prices
  """
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/prices", params: query) do
      {:ok, Pagination.build_page(Price, data, meta)}
    end
  end

  @doc """
  Returns a stream of prices.

  ## Examples

  ```elixir
  stream = Paddle.Prices.stream(client, per_page: 50)

  # Stream handles pagination automatically
  Enum.each(stream, fn
    {:ok, %Paddle.Price{} = price} -> IO.puts("Price: \#{price.id}")
    {:error, _} = error -> IO.puts("Error: \#{inspect(error)}")
  end)
  ```

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/prices/list-prices
  """
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> Pagination.next_page(client, Price, path) end
    )
  end

  @doc """
  Retrieves all prices, automatically handling pagination.

  ## Examples

  ```elixir
  case Paddle.Prices.all(client, status: "active") do
    {:ok, prices} ->
      # A list of Paddle.Price structs
      prices

    {:error, :invalid_params} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/prices/list-prices
  """
  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.Price.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> Pagination.next_page(client, Price, path) end
    )
  end

  defp price_path(price_id), do: "/prices/#{encode_path_segment(price_id)}"

  defp validate_price_id(price_id) when is_binary(price_id) do
    if String.trim(price_id) == "" do
      {:error, :invalid_price_id}
    else
      :ok
    end
  end

  defp validate_price_id(_price_id), do: {:error, :invalid_price_id}

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}
end
