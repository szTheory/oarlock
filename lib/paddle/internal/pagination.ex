defmodule Paddle.Internal.Pagination do
  @moduledoc """
  Internal pagination helpers that keep provider cursor dispatch separate from
  static request context.

  `next_page/4` accepts the dynamic cursor path only as the dispatch URL. Its
  keyword context carries a normalized `:operation` and `:route`, so later
  pages retain the owning resource operation without exposing cursor data.
  Pagination uses `GET`, so `retry: false` may restrict its bounded read retry.
  """

  alias Paddle.Error
  alias Paddle.Http
  alias Paddle.Page

  @spec build_page(module(), [map()], map()) :: Page.t()
  def build_page(module, data, meta) do
    %Page{
      data: Enum.map(data, &Http.build_struct(module, &1)),
      meta: meta
    }
  end

  @doc """
  Fetches a cursor URL using static operation/route context.

  The `path` is used only for provider dispatch. Callers should pass literal
  `:operation` and normalized `:route` labels in `context`; `:resource_id` and
  `retry: false` are also accepted by the central request boundary. The legacy
  context-free arity is intentionally not exported, so every caller must state
  the originating resource context explicitly.
  """
  @spec next_page(Paddle.Client.t(), module(), String.t(), [Paddle.Http.request_opt()]) ::
          {:ok, Page.t()} | {:error, Error.t() | term()}
  def next_page(client, module, path, context) when is_list(context) do
    with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, path, context) do
      {:ok, build_page(module, data, meta)}
    end
  end

  @spec stream(
          (-> {:ok, Page.t()} | {:error, term()}),
          (String.t() -> {:ok, Page.t()} | {:error, term()})
        ) :: Enumerable.t()
  def stream(first_page_fun, next_page_fun)
      when is_function(first_page_fun, 0) and is_function(next_page_fun, 1) do
    Stream.resource(
      fn -> {:first, first_page_fun, next_page_fun} end,
      &stream_next/1,
      fn _state -> :ok end
    )
  end

  @spec all(
          (-> {:ok, Page.t()} | {:error, term()}),
          (String.t() -> {:ok, Page.t()} | {:error, term()})
        ) :: {:ok, [map() | struct()]} | {:error, term()}
  def all(first_page_fun, next_page_fun)
      when is_function(first_page_fun, 0) and is_function(next_page_fun, 1) do
    reduce_pages({:first, first_page_fun, next_page_fun}, [])
  end

  defp stream_next(:done), do: {:halt, :done}

  defp stream_next(state) do
    case fetch_page(state) do
      {:ok, %Page{} = page, next_state} ->
        {page.data, next_state}

      {:error, reason} ->
        raise_stream_error(reason)
    end
  end

  defp reduce_pages(:done, acc), do: {:ok, Enum.reverse(acc)}

  defp reduce_pages(state, acc) do
    case fetch_page(state) do
      {:ok, %Page{} = page, next_state} ->
        reduce_pages(next_state, Enum.reduce(page.data, acc, &[&1 | &2]))

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_page({:first, first_page_fun, next_page_fun}) do
    first_page_fun.()
    |> handle_page_result(next_page_fun)
  end

  defp fetch_page({:next, path, next_page_fun}) do
    path
    |> next_page_fun.()
    |> handle_page_result(next_page_fun)
  end

  defp handle_page_result({:ok, %Page{} = page}, next_page_fun) do
    case next_state(page, next_page_fun) do
      {:ok, state} -> {:ok, page, state}
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_page_result({:error, reason}, _next_page_fun), do: {:error, reason}

  defp next_state(%Page{} = page, next_page_fun) do
    if has_more?(page) do
      case next_page_path(page) do
        {:ok, path} -> {:ok, {:next, path, next_page_fun}}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, :done}
    end
  end

  defp has_more?(%Page{meta: %{"pagination" => %{"has_more" => true}}}), do: true
  defp has_more?(_page), do: false

  defp next_page_path(%Page{} = page) do
    page
    |> Page.next_cursor()
    |> normalize_next_path()
  end

  defp normalize_next_path(next) when is_binary(next) do
    uri = URI.parse(next)

    cond do
      not is_binary(uri.path) or uri.path == "" ->
        {:error, :missing_next_cursor}

      is_binary(uri.query) and uri.query != "" ->
        {:ok, uri.path <> "?" <> uri.query}

      true ->
        {:ok, uri.path}
    end
  end

  defp normalize_next_path(_next), do: {:error, :missing_next_cursor}

  defp raise_stream_error(%Error{} = error), do: raise(error)

  defp raise_stream_error(reason) when is_atom(reason) do
    raise ArgumentError, "pagination failed with #{inspect(reason)}"
  end

  defp raise_stream_error(reason) do
    raise ArgumentError, "pagination failed with #{inspect(reason)}"
  end
end
