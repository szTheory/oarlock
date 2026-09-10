# Telemetry

oarlock uses [`telemetry`](https://hexdocs.pm/telemetry/) for attempt-scoped
instrumentation around Paddle API requests. Every physical attempt emits one
start event and exactly one terminal stop or exception event, including attempts
that Req later retries.

## Request Events

The event names remain stable, but the Phase 32 metadata schema is an intentional
pre-1.0 breaking change: transport objects and dynamic request data are no longer
published.

### `[:paddle, :request, :start]`

- Measurements: exactly `:system_time`, in native system-time units.
- Metadata: exactly `:method`, `:host`, `:attempt`, plus optional static
  `:operation` and normalized `:route`.

### `[:paddle, :request, :stop]`

- Measurements: exactly `:duration`, in native monotonic-time units.
- Metadata: the start keys plus exactly `:status` and `:result`.
- `:result` is `:ok` for 2xx responses and `:error` otherwise.

### `[:paddle, :request, :exception]`

- Measurements: exactly `:duration`, in native monotonic-time units.
- Metadata: the start keys plus exactly `:error_class` and `:result`.
- `:error_class` is one of `:transport_error`, `:http_error`, or `:exception`;
  `:result` is `:error`.

The projection never contains raw URLs or queries, resource IDs, credentials,
headers, bodies, customer data, `raw_data`, Req transport state, response terms,
exception terms, messages, reasons, or stacktraces. The host is sanitized and
the operation/route labels are static low-cardinality values owned by the SDK.

## Example

Attach a handler when your application starts and pattern-match only on the
documented allowlist:

```elixir
defmodule MyApp.PaddleTelemetry do
  require Logger

  def handle_event(
        [:paddle, :request, :stop],
        %{duration: duration},
        %{operation: operation, status: status, attempt: attempt},
        _config
      ) do
    Logger.debug(
      "Paddle #{operation} attempt=#{attempt} status=#{status} duration=#{duration}"
    )
  end

  def handle_event(
        [:paddle, :request, :exception],
        %{duration: duration},
        %{operation: operation, error_class: error_class, attempt: attempt},
        _config
      ) do
    Logger.error(
      "Paddle #{operation} attempt=#{attempt} error=#{error_class} duration=#{duration}"
    )
  end
end

:telemetry.attach_many(
  "my-app-paddle-telemetry",
  [
    [:paddle, :request, :start],
    [:paddle, :request, :stop],
    [:paddle, :request, :exception]
  ],
  &MyApp.PaddleTelemetry.handle_event/4,
  nil
)
```

Existing subscribers that consumed full transport terms must migrate to these
static keys. Correlate provider failures through the returned
`%Paddle.Error{request_id: request_id}` rather than emitting response data.
