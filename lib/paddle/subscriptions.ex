defmodule Paddle.Subscriptions do
  @moduledoc """
  Provides operations for managing Paddle Subscriptions.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123", environment: :sandbox)

  case Paddle.Subscriptions.get(client, "sub_123") do
    {:ok, %Paddle.Subscription{} = subscription} ->
      # Handle successful fetch
      IO.puts("Fetched subscription: \#{subscription.id}")

    {:error, %Paddle.Error{} = error} ->
      # Handle provider or network errors
      IO.puts("Failed: \#{error.message}")

    {:error, local_error} ->
      # Handle validation errors (e.g. :invalid_subscription_id)
      IO.puts("Validation failed: \#{inspect(local_error)}")
  end
  ```
  """

  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange

  @type subscription_id :: String.t()
  @type pause_opt ::
          {:resume_at, DateTime.t() | String.t()}
          | {:on_resume,
             :start_new_billing_period | :continue_existing_billing_period | String.t()}
          | {:retry, boolean()}
  @type resume_opt ::
          {:effective_from, :immediately | DateTime.t() | String.t()}
          | {:on_resume,
             :start_new_billing_period | :continue_existing_billing_period | String.t()}
          | {:retry, boolean()}

  @list_allowlist ~w(id customer_id address_id price_id status
                     scheduled_change_action collection_mode
                     next_billed_at order_by after per_page)

  @update_allowlist ~w(customer_id address_id business_id currency_code next_billed_at discount collection_mode billing_details scheduled_change custom_data proration_billing_mode items)

  @doc """
  Retrieves a subscription by ID.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.get(client, "sub_123") do
    {:ok, %Paddle.Subscription{} = subscription} ->
      subscription

    {:error, :invalid_subscription_id} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Get a subscription](https://developer.paddle.com/api-reference/subscriptions/get-subscription)
  """
  @spec get(Paddle.Client.t(), subscription_id()) ::
          {:ok, Paddle.Subscription.t()} | {:error, Paddle.Error.t() | :invalid_subscription_id}
  def get(%Client{} = client, subscription_id) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, subscription_path(subscription_id)) do
      {:ok, build_subscription(data)}
    end
  end

  @doc """
  Updates a subscription.

  ## Examples

  ```elixir
  # Immediate upgrade
  case Paddle.Subscriptions.update(client, "sub_123", items: [...], proration_billing_mode: "prorated_immediately") do
    {:ok, %Paddle.Subscription{} = subscription} -> subscription
  end

  # Scheduled downgrade
  case Paddle.Subscriptions.update(client, "sub_123", items: [...], proration_billing_mode: "next_billing_period") do
    {:ok, %Paddle.Subscription{} = subscription} ->
      # subscription.scheduled_change will be populated
      subscription
  end
  ```
  """
  @spec update(Paddle.Client.t(), subscription_id(), map() | keyword()) ::
          {:ok, Paddle.Subscription.t()}
          | {:error, Paddle.Error.t() | :invalid_subscription_id | :invalid_params}
  def update(%Client{} = client, subscription_id, params) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, params_map} <- normalize_params(params),
         body <- Attrs.allowlist(params_map, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, subscription_path(subscription_id), json: body) do
      {:ok, build_subscription(data)}
    end
  end

  @doc """
  Lists subscriptions.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.list(client, per_page: 10) do
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

  ## Related Paddle docs
  - [List subscriptions](https://developer.paddle.com/api-reference/subscriptions/list-subscriptions)
  """
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/subscriptions", params: query) do
      {:ok, build_page(data, meta)}
    end
  end

  @doc """
  Returns a stream of subscriptions.

  ## Examples

  ```elixir
  stream = Paddle.Subscriptions.stream(client, per_page: 50)

  # Stream handles pagination automatically
  Enum.each(stream, fn
    {:ok, %Paddle.Subscription{} = sub} -> IO.puts("Sub: \#{sub.id}")
    {:error, _} = error -> IO.puts("Error: \#{inspect(error)}")
  end)
  ```

  ## Related Paddle docs
  - [List subscriptions](https://developer.paddle.com/api-reference/subscriptions/list-subscriptions)
  """
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Retrieves all subscriptions, automatically handling pagination.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.all(client, status: "active") do
    {:ok, subscriptions} ->
      # A list of Paddle.Subscription structs
      subscriptions

    {:error, :invalid_params} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [List subscriptions](https://developer.paddle.com/api-reference/subscriptions/list-subscriptions)
  """
  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.Subscription.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Cancels a subscription at the end of the next billing period.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.cancel(client, "sub_123") do
    {:ok, %Paddle.Subscription{} = subscription} ->
      subscription

    {:error, :invalid_subscription_id} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Cancel a subscription](https://developer.paddle.com/api-reference/subscriptions/cancel-subscription)
  """
  @spec cancel(Paddle.Client.t(), subscription_id()) ::
          {:ok, Paddle.Subscription.t()} | {:error, Paddle.Error.t() | :invalid_subscription_id}
  def cancel(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "next_billing_period")
  end

  @doc """
  Cancels a subscription immediately.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.cancel_immediately(client, "sub_123") do
    {:ok, %Paddle.Subscription{} = subscription} ->
      subscription

    {:error, :invalid_subscription_id} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Cancel a subscription](https://developer.paddle.com/api-reference/subscriptions/cancel-subscription)
  """
  @spec cancel_immediately(Paddle.Client.t(), subscription_id()) ::
          {:ok, Paddle.Subscription.t()} | {:error, Paddle.Error.t() | :invalid_subscription_id}
  def cancel_immediately(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "immediately")
  end

  @doc """
  Pauses a subscription at the end of the next billing period.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.pause(client, "sub_123", on_resume: :continue_existing_billing_period) do
    {:ok, %Paddle.Subscription{} = subscription} ->
      subscription

    {:error, :invalid_subscription_id} ->
      # Handle local validation error

    {:error, :invalid_resume_at} ->
      # Handle local validation error

    {:error, :invalid_on_resume} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Pause a subscription](https://developer.paddle.com/api-reference/subscriptions/pause-subscription)
  """
  @spec pause(Paddle.Client.t(), subscription_id(), [pause_opt()]) ::
          {:ok, Paddle.Subscription.t()}
          | {:error,
             Paddle.Error.t()
             | :invalid_subscription_id
             | :invalid_resume_at
             | :invalid_on_resume}
  def pause(%Client{} = client, subscription_id, opts \\ []) do
    do_pause(client, subscription_id, "next_billing_period", opts)
  end

  @doc """
  Pauses a subscription immediately.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.pause_immediately(client, "sub_123") do
    {:ok, %Paddle.Subscription{} = subscription} ->
      subscription

    {:error, :invalid_subscription_id} ->
      # Handle local validation error

    {:error, :invalid_resume_at} ->
      # Handle local validation error

    {:error, :invalid_on_resume} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Pause a subscription](https://developer.paddle.com/api-reference/subscriptions/pause-subscription)
  """
  @spec pause_immediately(Paddle.Client.t(), subscription_id(), [pause_opt()]) ::
          {:ok, Paddle.Subscription.t()}
          | {:error,
             Paddle.Error.t()
             | :invalid_subscription_id
             | :invalid_resume_at
             | :invalid_on_resume}
  def pause_immediately(%Client{} = client, subscription_id, opts \\ []) do
    do_pause(client, subscription_id, "immediately", opts)
  end

  @doc """
  Resumes a paused subscription.

  ## Examples

  ```elixir
  case Paddle.Subscriptions.resume(client, "sub_123", effective_from: :immediately) do
    {:ok, %Paddle.Subscription{} = subscription} ->
      subscription

    {:error, :invalid_subscription_id} ->
      # Handle local validation error

    {:error, :invalid_effective_from} ->
      # Handle local validation error

    {:error, :invalid_on_resume} ->
      # Handle local validation error

    {:error, %Paddle.Error{} = error} ->
      # Handle provider/network error
  end
  ```

  ## Related Paddle docs
  - [Resume a subscription](https://developer.paddle.com/api-reference/subscriptions/resume-subscription)
  """
  @spec resume(Paddle.Client.t(), subscription_id(), [resume_opt()]) ::
          {:ok, Paddle.Subscription.t()}
          | {:error,
             Paddle.Error.t()
             | :invalid_subscription_id
             | :invalid_effective_from
             | :invalid_on_resume}
  def resume(%Client{} = client, subscription_id, opts \\ []) do
    do_resume(client, subscription_id, opts)
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

  defp do_resume(client, subscription_id, opts) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, resume_body, request_opts} <- normalize_resume_opts(opts),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             resume_path(subscription_id),
             Keyword.merge([json: resume_body], request_opts)
           ) do
      {:ok, build_subscription(data)}
    end
  end

  defp normalize_pause_opts(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      case Keyword.pop(opts, :retry) do
        {retry_value, remaining} ->
          with :ok <- reject_idempotency_key!(remaining, "pause"),
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

  defp reject_idempotency_key!(opts, operation) do
    if Keyword.has_key?(opts, :idempotency_key) do
      raise ArgumentError,
            "idempotency_key is not supported for #{operation} operations; only retry is supported"
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

  defp normalize_resume_opts(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      case Keyword.pop(opts, :retry) do
        {retry_value, remaining} ->
          with :ok <- reject_idempotency_key!(remaining, "resume"),
               :ok <- reject_unknown_resume_opts(remaining),
               {:ok, body} <- build_resume_body(remaining) do
            request_opts =
              if retry_value == nil and not Keyword.has_key?(opts, :retry),
                do: [],
                else: [retry: retry_value]

            {:ok, body, request_opts}
          end
      end
    else
      raise ArgumentError, "resume options must be a keyword list"
    end
  end

  defp normalize_resume_opts(_opts),
    do: raise(ArgumentError, "resume options must be a keyword list")

  defp reject_unknown_resume_opts(opts) do
    supported_keys = [:effective_from, :on_resume, :idempotency_key]

    case Enum.find(Keyword.keys(opts), &(&1 not in supported_keys)) do
      nil ->
        :ok

      key ->
        raise ArgumentError, "unknown resume option: #{inspect(key)}"
    end
  end

  defp build_resume_body(opts) do
    with {:ok, body} <- maybe_put_effective_from(%{}, Keyword.get(opts, :effective_from)),
         {:ok, body} <- maybe_put_on_resume(body, Keyword.get(opts, :on_resume)) do
      {:ok, body}
    end
  end

  defp maybe_put_effective_from(body, nil),
    do: {:ok, Map.put(body, "effective_from", "immediately")}

  defp maybe_put_effective_from(body, :immediately),
    do: {:ok, Map.put(body, "effective_from", "immediately")}

  defp maybe_put_effective_from(body, "immediately"),
    do: {:ok, Map.put(body, "effective_from", "immediately")}

  defp maybe_put_effective_from(body, %DateTime{} = effective_from) do
    {:ok, Map.put(body, "effective_from", DateTime.to_iso8601(effective_from))}
  end

  defp maybe_put_effective_from(body, effective_from) when is_binary(effective_from) do
    case DateTime.from_iso8601(effective_from) do
      {:ok, _datetime, _offset} -> {:ok, Map.put(body, "effective_from", effective_from)}
      _ -> {:error, :invalid_effective_from}
    end
  end

  defp maybe_put_effective_from(_body, _effective_from), do: {:error, :invalid_effective_from}

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
  defp resume_path(id), do: subscription_path(id) <> "/resume"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
