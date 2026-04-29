# Phase 01: Core Transport & Client Setup - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 9
**Analogs found:** 0 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/paddle/client.ex` | config | request-response | None | n/a |
| `lib/paddle/error.ex` | model | transform | None | n/a |
| `lib/paddle/page.ex` | model | request-response | None | n/a |
| `lib/paddle/http.ex` | service | request-response | None | n/a |
| `lib/paddle/http/telemetry.ex` | middleware | event-driven | None | n/a |
| `test/paddle/client_test.exs` | test | request-response | None | n/a |
| `test/paddle/http_test.exs` | test | request-response | None | n/a |
| `test/paddle/error_test.exs` | test | transform | None | n/a |
| `test/paddle/page_test.exs` | test | request-response | None | n/a |

## Pattern Assignments

*(No existing codebase analogs to map from. Phase 1 is the foundational layer. Planners should use patterns from `01-RESEARCH.md` extracted below.)*

## Shared Patterns

### Stateless Client Configuration
**Source:** `01-RESEARCH.md`
**Apply to:** `lib/paddle/client.ex`
```elixir
defmodule Paddle.Client do
  @enforce_keys [:api_key, :environment]
  defstruct [:api_key, :environment, :req]

  def new!(opts \\ []) do
    api_key = Keyword.fetch!(opts, :api_key)
    environment = Keyword.get(opts, :environment, :sandbox)
    base_url = if environment == :live, do: "https://api.paddle.com", else: "https://sandbox-api.paddle.com"
    
    req = Req.new(
      base_url: base_url,
      auth: {:bearer, api_key},
      headers: [{"Paddle-Version", "1"}]
    ) |> Paddle.Http.Telemetry.attach()

    %__MODULE__{api_key: api_key, environment: environment, req: req}
  end
end
```

### API Error Handling & Decoding
**Source:** `01-RESEARCH.md`
**Apply to:** `lib/paddle/error.ex` and `lib/paddle/http.ex`
```elixir
defmodule Paddle.Error do
  defexception [:type, :code, :message, :errors, :request_id, :status_code, :raw]

  @impl Exception
  def message(%{message: message}), do: message

  def from_response(%Req.Response{status: status, body: body} = resp) do
    # Fallback default values
    body = if is_map(body), do: body, else: %{}
    error_body = Map.get(body, "error", %{})
    
    %__MODULE__{
      status_code: status,
      request_id: Req.Response.get_header(resp, "x-request-id") |> List.first(),
      type: Map.get(error_body, "type"),
      code: Map.get(error_body, "code"),
      message: Map.get(error_body, "detail", "Unknown Paddle Error"),
      errors: Map.get(error_body, "errors", []),
      raw: body
    }
  end
end
```

### Telemetry Middleware (Req Steps)
**Source:** `01-RESEARCH.md`
**Apply to:** `lib/paddle/http/telemetry.ex`
```elixir
defmodule Paddle.Http.Telemetry do
  def attach(req) do
    req
    |> Req.Request.append_request_steps(paddle_telemetry_start: &telemetry_start/1)
    |> Req.Request.append_response_steps(paddle_telemetry_stop: &telemetry_stop/1)
    |> Req.Request.append_error_steps(paddle_telemetry_error: &telemetry_error/1)
  end

  defp telemetry_start(request) do
    metadata = %{request: request}
    :telemetry.execute([:paddle, :request, :start], %{time: System.system_time()}, metadata)
    request
  end

  defp telemetry_stop({request, response}) do
    metadata = %{request: request, response: response}
    :telemetry.execute([:paddle, :request, :stop], %{time: System.system_time()}, metadata)
    {request, response}
  end

  defp telemetry_error({request, exception}) do
    metadata = %{request: request, exception: exception}
    :telemetry.execute([:paddle, :request, :exception], %{time: System.system_time()}, metadata)
    {request, exception}
  end
end
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/paddle/client.ex` | config | request-response | Greenfield project; no existing client structs. |
| `lib/paddle/error.ex` | model | transform | Greenfield project; no existing API error structs. |
| `lib/paddle/page.ex` | model | request-response | Greenfield project; no existing pagination structs. |
| `lib/paddle/http.ex` | service | request-response | Greenfield project; no existing HTTP clients. |
| `lib/paddle/http/telemetry.ex` | middleware | event-driven | Greenfield project; no existing custom Req steps. |
| `test/paddle/client_test.exs` | test | request-response | Greenfield project; no existing tests. |
| `test/paddle/http_test.exs` | test | request-response | Greenfield project; no existing tests. |
| `test/paddle/error_test.exs` | test | transform | Greenfield project; no existing tests. |
| `test/paddle/page_test.exs` | test | request-response | Greenfield project; no existing tests. |

## Metadata

**Analog search scope:** `**/*.ex`, `**/*.exs` (Elixir files)
**Files scanned:** 0 (Codebase is currently empty of Elixir files)
**Pattern extraction date:** 2026-04-28