defmodule Paddle.Events do
  @moduledoc """
  Provides operations for retrieving historical events from the Paddle API.

  ## Best Practices
  Events should be used as triggers to perform canonical fetches of the underlying resource,
  rather than relying on the event payload for the source of truth. The payload inside an event
  represents a snapshot in time and may not reflect the current state of the resource.

  For example, when receiving a `transaction.completed` event, you should use
  `Paddle.Transactions.get(client, event.data["id"])` to fetch the latest state of the transaction.

  Event reads use bounded retries for documented transient failures. Request
  observability uses only the literal `:get_event`/`:list_events` operations and
  normalized `/events/:event_id`/`/events` routes; runtime IDs, filters, and
  pagination cursors remain dispatch-only. Idempotency keys are unsupported.
  """

  alias Paddle.Client
  alias Paddle.Event
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination

  @type event_id :: String.t()

  @list_allowlist ~w(after per_page order_by event_type)

  @doc """
  Retrieves a single event by ID.

  This bounded read is labeled with the static `:get_event` operation and
  `/events/:event_id` route. The runtime event ID is used only in the encoded
  dispatch path. Idempotency keys are not accepted.
  """
  @spec get(Paddle.Client.t(), event_id()) :: {:ok, Paddle.Event.t()} | {:error, any()}
  def get(%Client{} = client, event_id) do
    with :ok <- validate_event_id(event_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, event_path(event_id),
             operation: :get_event,
             route: "/events/:event_id"
           ) do
      {:ok, Http.build_struct(Event, data)}
    end
  end

  @doc """
  Returns a paginated list of events.

  The first page and every continuation are bounded reads labeled with the
  static `:list_events` operation and `/events` route. Filters and cursor values
  are never copied into request context. Idempotency keys are not accepted.
  """
  @spec list(Paddle.Client.t(), map() | keyword()) :: {:ok, Paddle.Page.t()} | {:error, any()}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/events",
             params: query,
             operation: :list_events,
             route: "/events"
           ) do
      {:ok, build_page(data, meta)}
    end
  end

  @doc """
  Returns a stream of events using the bounded, statically labeled list reads.
  """
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Returns all events across statically labeled, bounded-read pages.
  """
  @spec all(Paddle.Client.t(), map() | keyword()) :: {:ok, [Paddle.Event.t()]} | {:error, any()}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  defp validate_event_id(event_id) when is_binary(event_id) do
    if String.trim(event_id) == "" do
      {:error, :invalid_event_id}
    else
      :ok
    end
  end

  defp validate_event_id(_event_id), do: {:error, :invalid_event_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp event_path(event_id), do: "/events/#{encode_path_segment(event_id)}"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)

  defp next_page(client, path) do
    Pagination.next_page(client, Event, path,
      operation: :list_events,
      route: "/events"
    )
  end

  defp build_page(data, meta) do
    Pagination.build_page(Event, data, meta)
  end
end
