# Telemetry

oarlock uses [`telemetry`](https://hexdocs.pm/telemetry/) for instrumentation and metrics.

It emits events during the lifecycle of HTTP requests made to the Paddle API. You can attach to these events to log requests, measure performance, or track errors.

## Request Events

The library emits three events around network requests.

### `[:paddle, :request, :start]`

Executed immediately before the HTTP request is dispatched.

**Measurements**
- `:time` - System time in native units (`System.system_time()`).

**Metadata**
- `:request` - The `Req.Request` struct representing the outgoing request.

### `[:paddle, :request, :stop]`

Executed when a successful HTTP response is received (including HTTP error statuses like 4xx/5xx).

**Measurements**
- `:time` - System time in native units (`System.system_time()`).

**Metadata**
- `:request` - The `Req.Request` struct representing the original request.
- `:response` - The `Req.Response` struct containing the HTTP response.

### `[:paddle, :request, :exception]`

Executed when the HTTP request fails due to a network or client exception (e.g., connection refused, timeout).

**Measurements**
- `:time` - System time in native units (`System.system_time()`).

**Metadata**
- `:request` - The `Req.Request` struct representing the original request.
- `:exception` - The exception struct raised during the request.

## Example

To log all Paddle API errors, you could create a handler like this:

```elixir
defmodule MyApp.PaddleTelemetry do
  require Logger

  def handle_event([:paddle, :request, :stop], %{time: _time}, %{request: request, response: response}, _config) do
    Logger.debug("Paddle request to #{request.url} completed with status #{response.status}")
  end

  def handle_event([:paddle, :request, :exception], %{time: _time}, %{request: request, exception: exception}, _config) do
    Logger.error("Paddle request to #{request.url} failed: #{inspect(exception)}")
  end
end
```

And attach it when your application starts:

```elixir
:telemetry.attach_many(
  "my-app-paddle-telemetry",
  [
    [:paddle, :request, :stop],
    [:paddle, :request, :exception]
  ],
  &MyApp.PaddleTelemetry.handle_event/4,
  nil
)
```
