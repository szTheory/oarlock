defmodule Paddle.Subscriptions do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange

  @list_allowlist ~w(id customer_id address_id price_id status
                     scheduled_change_action collection_mode
                     next_billed_at order_by after per_page)

  def get(%Client{} = client, subscription_id) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, subscription_path(subscription_id)) do
      {:ok, build_subscription(data)}
    end
  end

  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/subscriptions", params: query) do
      {:ok, build_page(data, meta)}
    end
  end

  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  def cancel(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "next_billing_period")
  end

  def cancel_immediately(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "immediately")
  end

  def pause(%Client{} = client, subscription_id, opts \\ []) do
    do_pause(client, subscription_id, "next_billing_period", opts)
  end

  def pause_immediately(%Client{} = client, subscription_id, opts \\ []) do
    do_pause(client, subscription_id, "immediately", opts)
  end

  defp do_cancel(client, subscription_id, effective_from) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             cancel_path(subscription_id),
             json: %{"effective_from" => effective_from}
           ) do
      {:ok, build_subscription(data)}
    end
  end

  defp do_pause(client, subscription_id, effective_from, opts) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, pause_body, request_opts} <- normalize_pause_opts(opts),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             pause_path(subscription_id),
             Keyword.merge(
               [json: Map.put(pause_body, "effective_from", effective_from)],
               request_opts
             )
           ) do
      {:ok, build_subscription(data)}
    end
  end

  defp normalize_pause_opts(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      case Keyword.pop(opts, :retry) do
        {retry_value, remaining} ->
          with :ok <- reject_idempotency_key!(remaining),
               :ok <- reject_unknown_pause_opts(remaining),
               {:ok, body} <- build_pause_body(remaining) do
            request_opts =
              if retry_value == nil and not Keyword.has_key?(opts, :retry),
                do: [],
                else: [retry: retry_value]

            {:ok, body, request_opts}
          end
      end
    else
      raise ArgumentError, "pause options must be a keyword list"
    end
  end

  defp normalize_pause_opts(_opts),
    do: raise(ArgumentError, "pause options must be a keyword list")

  defp reject_idempotency_key!(opts) do
    if Keyword.has_key?(opts, :idempotency_key) do
      raise ArgumentError,
            "idempotency_key is not supported for pause operations; only retry is supported"
    else
      :ok
    end
  end

  defp reject_unknown_pause_opts(opts) do
    supported_keys = [:resume_at, :on_resume, :idempotency_key]

    case Enum.find(Keyword.keys(opts), &(&1 not in supported_keys)) do
      nil ->
        :ok

      key ->
        raise ArgumentError, "unknown pause option: #{inspect(key)}"
    end
  end

  defp build_pause_body(opts) do
    with {:ok, body} <- maybe_put_resume_at(%{}, Keyword.get(opts, :resume_at)),
         {:ok, body} <- maybe_put_on_resume(body, Keyword.get(opts, :on_resume)) do
      {:ok, body}
    end
  end

  defp maybe_put_resume_at(body, nil), do: {:ok, body}

  defp maybe_put_resume_at(body, %DateTime{} = resume_at) do
    {:ok, Map.put(body, "resume_at", DateTime.to_iso8601(resume_at))}
  end

  defp maybe_put_resume_at(body, resume_at) when is_binary(resume_at) do
    case DateTime.from_iso8601(resume_at) do
      {:ok, _datetime, _offset} -> {:ok, Map.put(body, "resume_at", resume_at)}
      _ -> {:error, :invalid_resume_at}
    end
  end

  defp maybe_put_resume_at(_body, _resume_at), do: {:error, :invalid_resume_at}

  defp maybe_put_on_resume(body, nil), do: {:ok, body}

  defp maybe_put_on_resume(body, :start_new_billing_period),
    do: {:ok, Map.put(body, "on_resume", "start_new_billing_period")}

  defp maybe_put_on_resume(body, :continue_existing_billing_period),
    do: {:ok, Map.put(body, "on_resume", "continue_existing_billing_period")}

  defp maybe_put_on_resume(body, "start_new_billing_period"),
    do: {:ok, Map.put(body, "on_resume", "start_new_billing_period")}

  defp maybe_put_on_resume(body, "continue_existing_billing_period"),
    do: {:ok, Map.put(body, "on_resume", "continue_existing_billing_period")}

  defp maybe_put_on_resume(_body, _on_resume), do: {:error, :invalid_on_resume}

  defp build_subscription(data) when is_map(data) do
    subscription = Http.build_struct(Subscription, data)

    subscription =
      case data["scheduled_change"] do
        sc when is_map(sc) ->
          %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}

        _ ->
          subscription
      end

    case data["management_urls"] do
      mu when is_map(mu) ->
        %{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}

      _ ->
        subscription
    end
  end

  defp next_page(client, path) do
    with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, path) do
      {:ok, build_page(data, meta)}
    end
  end

  defp build_page(data, meta) do
    %Paddle.Page{
      data: Enum.map(data, &build_subscription/1),
      meta: meta
    }
  end

  defp validate_subscription_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
  end

  defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp subscription_path(id), do: "/subscriptions/#{encode_path_segment(id)}"
  defp cancel_path(id), do: subscription_path(id) <> "/cancel"
  defp pause_path(id), do: subscription_path(id) <> "/pause"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
