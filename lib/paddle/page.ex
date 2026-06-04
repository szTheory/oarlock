defmodule Paddle.Page do
  @moduledoc """
  Represents a paginated response from the Paddle Billing API.

  Many collection endpoints in Paddle use cursor-based pagination. The SDK encapsulates
  these responses in a `%Paddle.Page{}` struct, which contains the list of resource
  structs in `data` and the raw pagination information in `meta`.

  Use `next_cursor/1` to easily extract the next page token.
  """

  @type t :: %__MODULE__{
          data: list(map() | struct()),
          meta: map()
        }

  defstruct [:data, :meta]

  @doc """
  Extracts the `after` cursor for fetching the next page of results.

  Returns `nil` if there is no next page.

  ## Examples

  ```elixir
  case Paddle.Customers.list(client) do
    {:ok, %Paddle.Page{} = page} ->
      case Paddle.Page.next_cursor(page) do
        nil ->
          IO.puts("Reached the end.")

        cursor ->
          # Fetch next page using the cursor
          Paddle.Customers.list(client, after: cursor)
      end

    {:error, error} ->
      IO.inspect(error)
  end
  ```

  ## Related Paddle docs
  - [Pagination](https://developer.paddle.com/api-reference/about/pagination)
  """
  @spec next_cursor(t() | term()) :: String.t() | nil
  def next_cursor(%__MODULE__{meta: %{"pagination" => %{"next" => next}}}) when is_binary(next) do
    next
  end

  def next_cursor(_), do: nil
end
