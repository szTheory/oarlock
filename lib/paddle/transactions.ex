defmodule Paddle.Transactions do
  alias Paddle.Http
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout

  def create(%Paddle.Client{} = client, attrs) do
    with {:ok, attrs} <- normalize_attrs(attrs),
         {:ok, customer_id} <- validate_customer_id(attrs),
         {:ok, address_id} <- validate_address_id(attrs),
         {:ok, items} <- validate_items(attrs),
         {:ok, checkout} <- validate_checkout(attrs),
         body <- build_body(customer_id, address_id, items, attrs, checkout),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, "/transactions", json: body) do
      {:ok, build_transaction(data)}
    end
  end

  defp build_body(customer_id, address_id, items, attrs, checkout) do
    %{
      "customer_id" => customer_id,
      "address_id" => address_id,
      "items" => items,
      "collection_mode" => "automatic"
    }
    |> maybe_put("custom_data", Map.get(attrs, "custom_data"))
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
    item = normalize_map_keys(item)

    with price_id when is_binary(price_id) <- Map.get(item, "price_id"),
         false <- String.trim(price_id) == "",
         true <- Map.has_key?(item, "quantity"),
         quantity <- Map.get(item, "quantity") do
      {:ok, %{"price_id" => price_id, "quantity" => quantity}}
    else
      _ -> :error
    end
  end

  defp normalize_item(_item), do: :error

  defp validate_checkout(attrs) do
    case Map.fetch(attrs, "checkout") do
      :error ->
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
end
