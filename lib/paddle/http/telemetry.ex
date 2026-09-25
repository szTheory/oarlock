defmodule Paddle.Http.Telemetry do
  @moduledoc """
  Safe, attempt-scoped telemetry for Paddle HTTP requests.

  `attach/1` emits one start event and one terminal event for every physical
  request attempt. Retryable responses and transport errors are observed before
  Req consumes them, so retries produce independent pairs with request-local
  attempt numbers.

  The public event names and their exact payload schemas are:

    * `[:paddle, :request, :start]` — measurement `:system_time`; metadata
      `:method`, `:host`, `:attempt`, and optional `:operation`/`:route`.
    * `[:paddle, :request, :stop]` — measurement `:duration`; the start
      metadata plus `:status` and `:result`.
    * `[:paddle, :request, :exception]` — measurement `:duration`; the start
      metadata plus `:error_class` and `:result`.

  Durations use native monotonic-time units. The projection never includes raw
  URLs or queries, IDs, requests, responses, exceptions, headers, bodies,
  credentials, customer data, or `raw_data` containers.

  `:result` is `:ok` for 2xx responses and `:error` otherwise. Error classes
  are normalized to `:transport_error`, `:http_error`, or `:exception`; an
  exception module, message, reason, or stacktrace is never emitted.
  """

  @state_key :paddle_telemetry_attempt_state

  @doc """
  Attaches the three Paddle telemetry events to a Req request pipeline.

  Terminal steps run before Req retry handling, preserving exactly one terminal
  event for each physical attempt.
  """
  @spec attach(Req.Request.t()) :: Req.Request.t()

  def attach(req) do
    req
    |> Req.Request.append_request_steps(paddle_telemetry_start: &telemetry_start/1)
    |> Req.Request.prepend_response_steps(paddle_telemetry_stop: &telemetry_stop/1)
    |> Req.Request.prepend_error_steps(paddle_telemetry_error: &telemetry_error/1)
  end

  defp telemetry_start(request) do
    previous = Req.Request.get_private(request, @state_key, %{attempt: 0})
    state = %{attempt: previous.attempt + 1, started_at: System.monotonic_time()}
    request = Req.Request.put_private(request, @state_key, state)

    :telemetry.execute(
      [:paddle, :request, :start],
      %{system_time: System.system_time()},
      base_metadata(request, state.attempt)
    )

    request
  end

  defp telemetry_stop({request, response}) do
    state = attempt_state(request)

    :telemetry.execute(
      [:paddle, :request, :stop],
      %{duration: duration(state)},
      request
      |> base_metadata(state.attempt)
      |> Map.merge(%{
        status: response.status,
        result: response_result(response)
      })
    )

    {request, response}
  end

  defp telemetry_error({request, exception}) do
    state = attempt_state(request)

    :telemetry.execute(
      [:paddle, :request, :exception],
      %{duration: duration(state)},
      request
      |> base_metadata(state.attempt)
      |> Map.merge(%{
        error_class: error_class(exception),
        result: :error
      })
    )

    {request, exception}
  end

  defp attempt_state(request) do
    Req.Request.get_private(request, @state_key, %{
      attempt: 1,
      started_at: System.monotonic_time()
    })
  end

  defp duration(%{started_at: started_at}) do
    max(System.monotonic_time() - started_at, 0)
  end

  defp base_metadata(request, attempt) do
    context = Req.Request.get_private(request, :paddle_request_context, %{})

    context
    |> Map.take([:operation, :route])
    |> Map.merge(%{
      method: request.method,
      host: sanitized_host(request.url.host),
      attempt: attempt
    })
  end

  defp sanitized_host(host) when is_binary(host), do: String.downcase(host)
  defp sanitized_host(_host), do: "unknown"

  defp response_result(%Req.Response{status: status}) when status in 200..299, do: :ok
  defp response_result(%Req.Response{}), do: :error

  defp error_class(%Req.TransportError{}), do: :transport_error
  defp error_class(%Req.HTTPError{}), do: :http_error
  defp error_class(_exception), do: :exception
end
