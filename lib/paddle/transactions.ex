defmodule Paddle.Transactions do
  @moduledoc """
  Provides operations for managing Paddle Transactions.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123", environment: :sandbox)

  case Paddle.Transactions.create(client, %{
    "customer_id" => "ctm_123",
    "address_id" => "add_123",
    "items" => [%{"price_id" => "pri_123", "quantity" => 1}]
  }) do
    {:ok, %Paddle.Transaction{} = transaction} ->
      # Handle successful transaction creation
      IO.puts("Created transaction: \#{transaction.id}")

    {:error, %Paddle.Error{} = error} ->
      # Handle provider or network errors
      IO.puts("Failed: \#{error.message}")

    {:error, local_error} ->
      # Handle validation errors (e.g. :invalid_customer_id)
      IO.puts("Validation failed: \#{inspect(local_error)}")
  end
  ```
  """

  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout

  @type transaction_id :: String.t()
  @type request_opt :: {:idempotency_key, String.t()} | {:retry, boolean()}

  @doc """
  Retrieves a transaction by ID.

  ## Examples

  ```elixir
  case Paddle.Transactions.get(client, "txn_123") do
    {:ok, %Paddle.Transaction{} = transaction} ->
      transaction

    {:error, :invalid_transaction_id} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Get a transaction](https://developer.paddle.com/api-reference/transactions/get-transaction)
  """
  @spec get(Paddle.Client.t(), transaction_id()) ::
          {:ok, Paddle.Transaction.t()} | {:error, Paddle.Error.t() | :invalid_transaction_id}
  def get(%Client{} = client, transaction_id) do
    with :ok <- validate_transaction_id(transaction_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, transaction_path(transaction_id)) do
      {:ok, build_transaction(data)}
    end
  end

  @doc """
  Creates a new transaction.

  Local validation is performed on the provided attributes before sending the request to the provider.

  ## Validation Errors
  - `:invalid_attrs` - The attributes provided are not a valid map or keyword list.
  - `:invalid_customer_id` - The `customer_id` is empty or not a string.
  - `:invalid_address_id` - The `address_id` is empty or not a string.
  - `:invalid_items` - The `items` array is missing, empty, or contains invalid item configurations.
  - `:invalid_custom_data` - The `custom_data` is not a valid map.
  - `:invalid_checkout` - The `checkout` parameter is not valid.

  ## Examples

  ```elixir
  attrs = %{
    "customer_id" => "ctm_123",
    "address_id" => "add_123",
    "items" => [%{"price_id" => "pri_123", "quantity" => 1}]
  }

  case Paddle.Transactions.create(client, attrs) do
    {:ok, %Paddle.Transaction{} = transaction} ->
      transaction

    {:error, :invalid_items} ->
      # Handle local validation error for items

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Provider behavior
  When a transaction is created, its `collection_mode` will be automatically set to `automatic` by the SDK as required by the typical checkout flow.

  ## Related Paddle docs
  - [Create a transaction](https://developer.paddle.com/api-reference/transactions/create-transaction)
  """
  @spec create(Paddle.Client.t(), map() | keyword(), [request_opt()]) ::
          {:ok, Paddle.Transaction.t()}
          | {:error,
             Paddle.Error.t()
             | :invalid_attrs
             | :invalid_customer_id
             | :invalid_address_id
             | :invalid_items
             | :invalid_custom_data
             | :invalid_checkout}
  def create(%Client{} = client, attrs, opts \\ []) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         {:ok, customer_id} <- validate_customer_id(attrs),
         {:ok, address_id} <- validate_address_id(attrs),
         {:ok, items} <- validate_items(attrs),
         {:ok, custom_data} <- validate_custom_data(attrs),
         {:ok, checkout} <- validate_checkout(attrs),
         body <- build_body(customer_id, address_id, items, custom_data, checkout),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, "/transactions", Keyword.merge([json: body], opts)) do
      {:ok, build_transaction(data)}
    end
  end

  defp build_body(customer_id, address_id, items, custom_data, checkout) do
    %{
      "customer_id" => customer_id,
      "address_id" => address_id,
      "items" => items,
      "collection_mode" => "automatic"
    }
    |> maybe_put("custom_data", custom_data)
    |> maybe_put("checkout", checkout)
  end

  defp maybe_put(body, _key, nil), do: body
  defp maybe_put(body, key, value), do: Map.put(body, key, value)

  defp build_transaction(data) when is_map(data) do
    transaction = Http.build_struct(Transaction, data)

    case data["checkout"] do
      checkout_data when is_map(checkout_data) ->
        %{transaction | checkout: Http.build_struct(Checkout, checkout_data)}

      _ ->
        transaction
    end
  end

  defp validate_customer_id(attrs) do
    case Map.get(attrs, "customer_id") do
      value when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, :invalid_customer_id}
        else
          {:ok, value}
        end

      _ ->
        {:error, :invalid_customer_id}
    end
  end

  defp validate_address_id(attrs) do
    case Map.get(attrs, "address_id") do
      value when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, :invalid_address_id}
        else
          {:ok, value}
        end

      _ ->
        {:error, :invalid_address_id}
    end
  end

  defp validate_items(attrs) do
    case Map.get(attrs, "items") do
      [_ | _] = items -> normalize_items(items)
      _ -> {:error, :invalid_items}
    end
  end

  defp normalize_items(items) do
    Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
      case normalize_item(item) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        :error -> {:halt, {:error, :invalid_items}}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      {:error, _} = error -> error
    end
  end

  defp normalize_item(item) when is_map(item) do
    item = Attrs.normalize_keys(item)

    with price_id when is_binary(price_id) <- Map.get(item, "price_id"),
         false <- String.trim(price_id) == "",
         quantity when is_integer(quantity) and quantity > 0 <- Map.get(item, "quantity") do
      {:ok, %{"price_id" => price_id, "quantity" => quantity}}
    else
      _ -> :error
    end
  end

  defp normalize_item(_item), do: :error

  defp validate_custom_data(attrs) do
    case Map.fetch(attrs, "custom_data") do
      :error -> {:ok, nil}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} when is_map(value) -> {:ok, value}
      {:ok, _} -> {:error, :invalid_custom_data}
    end
  end

  defp validate_checkout(attrs) do
    case Map.fetch(attrs, "checkout") do
      :error ->
        {:ok, nil}

      {:ok, nil} ->
        {:ok, nil}

      {:ok, checkout} ->
        normalize_checkout(checkout)
    end
  end

  defp normalize_checkout(checkout) when is_map(checkout) do
    case fetch_checkout_url(checkout) do
      {:ok, url} when is_binary(url) ->
        if String.trim(url) == "" do
          {:error, :invalid_checkout}
        else
          {:ok, %{"url" => url}}
        end

      _ ->
        {:error, :invalid_checkout}
    end
  end

  defp normalize_checkout(_checkout), do: {:error, :invalid_checkout}

  defp fetch_checkout_url(%{"url" => url}), do: {:ok, url}
  defp fetch_checkout_url(%{url: url}), do: {:ok, url}
  defp fetch_checkout_url(_), do: :error

  defp validate_transaction_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :invalid_transaction_id}, else: :ok
  end

  defp validate_transaction_id(_id), do: {:error, :invalid_transaction_id}

  defp transaction_path(id), do: "/transactions/#{encode_path_segment(id)}"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
