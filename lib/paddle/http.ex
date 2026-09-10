defmodule Paddle.Http do
  @moduledoc """
  Central request and response boundary for the Paddle SDK.

  Only `GET` and `HEAD` requests retry documented transient outcomes, with at
  most four physical attempts. Mutations always make one attempt; `retry: true`
  cannot enable replay, while `retry: false` can restrict a read.

  Static `:operation` and `:route` context remains separate from runtime cursor
  URLs. `:resource_id` is optional safe context. `:idempotency_key` is
  unsupported and is never converted into a request header.
  """

  @type request_opt ::
          {:retry, boolean()}
          | {:operation, atom()}
          | {:route, String.t()}
          | {:resource_id, String.t()}

  @safe_methods [:get, :head]
  @retryable_statuses [408, 429, 500, 502, 503, 504]
  @retryable_transport_reasons [:timeout, :econnrefused, :closed]
  @max_retry_after_ms 60_000

  @doc """
  Dispatches a request and normalizes its terminal result.

  Eligible safe reads use three retries/four total attempts. `retry: false`
  disables read retries. Enabling mutation retry or passing a non-boolean retry
  value raises before dispatch. Static context options are consumed here rather
  than sent to Req, and `:idempotency_key` is unsupported.
  """
  @spec request(Paddle.Client.t(), atom(), String.t(), keyword()) ::
          {:ok, term()} | {:error, Paddle.Error.t() | term()}
  def request(%Paddle.Client{} = client, method, path, opts \\ []) do
    reject_idempotency_key!(opts)
    {retry_options, opts} = retry_options!(method, opts)
    {context, opts} = request_context(opts)
    context = Map.put(context, :method, method)
    opts = Keyword.merge(opts, method: method, url: path)
    opts = Keyword.merge(opts, retry_options)

    request = Req.Request.put_private(client.req, :paddle_request_context, context)

    case Req.request(request, opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{} = resp} ->
        {:error, Paddle.Error.from_response(resp, context)}

      {:error, %Req.TransportError{} = exception} ->
        {:error, Paddle.Error.from_transport(exception, context)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp retry_options!(method, opts) do
    retry_values = Keyword.get_values(opts, :retry)
    opts = Keyword.delete(opts, :retry)

    retry =
      case retry_values do
        [] -> :default
        [value] when is_boolean(value) -> value
        [_value] -> raise ArgumentError, "retry must be a boolean"
        _values -> raise ArgumentError, "retry may be supplied only once"
      end

    cond do
      method in @safe_methods and retry != false ->
        {[retry: &retry_decision/2, max_retries: 3], opts}

      method in @safe_methods ->
        {[retry: false], opts}

      retry == true ->
        raise ArgumentError, "retry cannot enable mutation replay for #{method} requests"

      true ->
        {[retry: false], opts}
    end
  end

  defp retry_decision(%Req.Request{method: method}, outcome) when method in @safe_methods do
    case outcome do
      %Req.Response{status: 429} = response ->
        case Req.Response.get_retry_after(response) do
          delay when is_integer(delay) -> {:delay, min(delay, @max_retry_after_ms)}
          nil -> true
        end

      %Req.Response{status: status} when status in @retryable_statuses ->
        true

      %Req.TransportError{reason: reason} when reason in @retryable_transport_reasons ->
        true

      _outcome ->
        false
    end
  end

  defp retry_decision(_request, _outcome), do: false

  defp request_context(opts) do
    for key <- [:operation, :route, :resource_id], length(Keyword.get_values(opts, key)) > 1 do
      raise ArgumentError, "#{key} may be supplied only once"
    end

    {context, opts} = Keyword.split(opts, [:operation, :route, :resource_id])
    context = Map.new(context)

    validate_context_value!(context, :operation, &is_atom/1)
    validate_context_value!(context, :route, &is_binary/1)
    validate_context_value!(context, :resource_id, &is_binary/1)

    {context, opts}
  end

  defp validate_context_value!(context, key, predicate) do
    case Map.fetch(context, key) do
      :error ->
        :ok

      {:ok, value} ->
        if predicate.(value), do: :ok, else: raise(ArgumentError, "#{key} is invalid")
    end
  end

  defp reject_idempotency_key!(opts) do
    if Keyword.has_key?(opts, :idempotency_key) do
      raise ArgumentError, "idempotency_key is not supported"
    end
  end

  @doc false
  @spec build_struct(module(), map()) :: struct()
  def build_struct(struct_module, data) when is_map(data) do
    base_struct = struct(struct_module)
    valid_keys = Map.keys(base_struct) |> Enum.map(&to_string/1)

    attrs =
      data
      |> Enum.filter(fn {k, _} -> k in valid_keys end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Enum.into(%{})

    struct(struct_module, Map.put(attrs, :raw_data, data))
  end
end
