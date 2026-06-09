defmodule Paddle.Adjustments do
  @moduledoc """
  Provides operations for managing Paddle Adjustments.

  Adjustments allow you to issue refunds and credits for a transaction.
  """

  alias Paddle.Adjustment
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
  alias Paddle.Page

  @type adjustment_id :: String.t()

  @type adjustment_item_attr :: %{
          required(:item_id) => String.t(),
          required(:type) => String.t(),
          optional(:amount) => String.t() | integer()
        }

  @type create_attrs :: %{
          required(:action) => String.t(),
          required(:reason) => String.t(),
          required(:transaction_id) => String.t(),
          optional(:items) => [adjustment_item_attr()]
        }

  @create_allowlist ~w(action reason transaction_id items)
  @list_allowlist ~w(after id action transaction_id subscription_id customer_id status order_by per_page)

  @doc """
  Creates a new adjustment.

  ## Examples

      Paddle.Adjustments.create(client, %{
        action: "refund",
        reason: "fraud",
        transaction_id: "txn_123",
        items: [%{item_id: "txnitm_123", type: "partial", amount: "100"}]
      })
  """
  @spec create(Paddle.Client.t(), create_attrs() | keyword(), keyword()) ::
          {:ok, Paddle.Adjustment.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
  def create(%Client{} = client, attrs, opts \\ []) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, "/adjustments", Keyword.merge([json: body], opts)) do
      {:ok, Http.build_struct(Adjustment, data)}
    end
  end

  @doc """
  Retrieves an adjustment by ID.

  ## Examples

      Paddle.Adjustments.get(client, "adj_123")
  """
  @spec get(Paddle.Client.t(), adjustment_id()) ::
          {:ok, Paddle.Adjustment.t()} | {:error, Paddle.Error.t() | :invalid_adjustment_id}
  def get(%Client{} = client, adjustment_id) do
    with :ok <- validate_adjustment_id(adjustment_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, adjustment_path(adjustment_id)) do
      {:ok, Http.build_struct(Adjustment, data)}
    end
  end

  @doc """
  Lists adjustments.

  ## Examples

      Paddle.Adjustments.list(client, action: "refund", per_page: 10)
  """
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/adjustments", params: query) do
      {:ok, build_page(data, meta)}
    end
  end

  @doc """
  Returns a stream of adjustments.
  """
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Retrieves all adjustments, automatically handling pagination.
  """
  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.Adjustment.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  defp validate_adjustment_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :invalid_adjustment_id}, else: :ok
  end

  defp validate_adjustment_id(_id), do: {:error, :invalid_adjustment_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp adjustment_path(id), do: "/adjustments/#{encode_path_segment(id)}"
  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)

  defp next_page(client, path) do
    with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, path) do
      {:ok, build_page(data, meta)}
    end
  end

  defp build_page(data, meta) do
    %Page{
      data: Enum.map(data, &Http.build_struct(Adjustment, &1)),
      meta: meta
    }
  end
end
