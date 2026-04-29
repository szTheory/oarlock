# Phase 1: Core Transport & Client Setup - Research

**Researched:** 2026-04-28
**Domain:** Elixir HTTP Client / API Integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### Client Initialization
- Strictly require explicit passing (`Paddle.Client.new(api_key: "...")`).
- Do absolutely no `Application.get_env` lookups within the SDK.
- Consumers should wrap the client in their own application context.

#### Error Struct Shape
- Use a Hybrid Idiomatic Wrapper for `%Paddle.Error{}`.
- Map exactly to Paddle's v1 terminology (`type`, `code`, `detail`, `errors`).
- Extract `request_id` and `status_code` to top-level fields.
- Implement Elixir's `Exception` behavior (aliasing `detail` to `message`).
- Keep the raw payload in a `:raw` field.

#### Pagination Interface
- Use a Manual `next()` Cursor approach for Phase 1.
- Return `{:ok, %Paddle.Page{data: [...], meta: ...}}`.
- Provide a helper like `Paddle.Page.next_cursor/1`.
- Wait on Stream implementation until Phase 2 as a pure DX convenience wrapper.

#### Telemetry & Logging
- Emit custom domain-specific telemetry events (`[:paddle, :request, :start | :stop | :exception]`).
- Do this using a custom `Req.Step`.
- Do not rely solely on `req`'s built-in telemetry to isolate Paddle metrics from global HTTP traffic.

### the agent's Discretion
- Exact naming of internal helper modules (e.g., `Paddle.Request` vs `Paddle.Http`).
- Telemetry payload struct details.

### Deferred Ideas (OUT OF SCOPE)
- Phoenix/Plug integration helpers for webhooks (Phase 2).
- Elixir Stream wrapper for pagination (`Paddle.stream!/1`).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-01 | Explicit client instantiation (`Paddle.Client.new!/1`) with Bearer auth, base URLs, and API version header ("1"). | Use `Req.new/1` embedded in `Paddle.Client` struct with proper defaults and explicit configurations. |
| CORE-02 | HTTP transport built on `req` with built-in JSON parsing, retries, and telemetry. | Implement a dedicated `Paddle.Http` module acting as the execution boundary using `Req.Request`. |
| CORE-03 | Consistent typed responses: `{:ok, struct}` and `{:error, %Paddle.Error{}}`. | Pattern matching `Req.Response{}` to map status codes < 300 to `{:ok, _}` and >= 400 to `{:error, %Paddle.Error{}}`. |
| CORE-04 | Retain raw response payloads (e.g., `raw_data`) in structs for forward compatibility. | Enforce that any struct decoding includes a `:raw` map capturing the verbatim API response. |
| CORE-05 | Pagination support returning `{:ok, %Paddle.Page{data: [...], meta: ...}}`. | Define a `Paddle.Page` struct encapsulating the list of generic payloads and the Paddle pagination meta map. |
</phase_requirements>

## Summary

This phase establishes the foundational HTTP communication layer for the Paddle SDK using the modern Elixir `req` library. The primary focus is designing a pure, stateless client configuration without any reliance on implicit global state (e.g., `Application.get_env/2`). We will enforce strict typed boundaries mapping to `{:ok, _}` tuples and explicitly handled exception structs.

**Primary recommendation:** Build a `Paddle.Client` struct containing the initialized `Req.Request` configuration, and centralize all execution into a single `Paddle.Http` helper module that manages HTTP semantics, error mappings, and isolated custom telemetry execution steps.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transport Transport Layer | API / Backend | — | Core foundational layer communicating with the external Paddle REST API. |
| Response Parsing | API / Backend | — | Interprets external JSON responses into deterministic Elixir data structures. |
| Telemetry | API / Backend | — | Reports fine-grained operational metrics specifically for SDK traffic, not interfering with the host app. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req` | `~> 0.5.17` | HTTP Transport Layer | The modern default HTTP client for Elixir, encompassing connection pooling (via Finch), JSON encoding/decoding, and flexible middleware via "Steps". |
| `telemetry` | `~> 1.4` | System Metrics | Core Elixir standard for dispatching and listening to system telemetry events. |

**Version verification:** 
Verified via Hex using `mix hex.info req` and `mix hex.info telemetry`.

## Architecture Patterns

### System Architecture Diagram

```
[Consumer Application] 
       | (calls Paddle SDK)
       v
[Paddle.Client] (Holds config, auth, and base URL)
       |
       v
[Paddle.Http] (Constructs Req with Base Request Options)
       |
       |----> [Req Custom Steps]
       |          |-- 1. paddle_telemetry_start
       |          |-- 2. req_core_steps (auth, retry, json parsing)
       |          |-- 3. paddle_telemetry_stop / exception
       v
[Paddle API (REST)]
```

### Recommended Project Structure
```
lib/paddle/
├── client.new      # Initialization (Paddle.Client)
├── error.ex        # Custom API Exception behavior
├── page.ex         # Pagination standard struct wrapper
├── http/
│   ├── http.ex     # Core executor mapping responses and struct decoders
│   └── telemetry.ex # Custom req steps for isolated telemetry
```

### Pattern 1: Explicit Stateless Client
**What:** Eliminating global configuration (`config :paddle, ...`) in favor of direct struct passage.
**When to use:** Universally within SDKs designed for scale or multi-tenant Elixir applications.
**Example:**
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

### Anti-Patterns to Avoid
- **Implicit Environment Config:** Never use `Application.get_env(:paddle, :api_key)` internally. If users want to use global config, they must fetch it themselves and pass it explicitly to `Paddle.Client.new!/1`.
- **Relying on Default Req Telemetry:** Req emits `[:req, :request, ...]` which blends the SDK traffic with all other `Req` usages in the application.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Connection Pooling | A custom `:poolboy` or `:nimble_pool` module | `req` (built on `Finch`) | Built-in, extremely battle-tested, transparent. |
| Retries & Backoff | Custom recursive algorithms with `:timer.sleep` | `req` retry steps | Standardized retry mechanisms conforming to typical rate-limit `Retry-After` headers. |

**Key insight:** `req` implements nearly all robust HTTP features via "Steps". Implementing custom SDK behavior (like isolated metrics) is best done by injecting domain-specific Steps into the Req pipeline rather than building custom wrappers around core execution.

## Common Pitfalls

### Pitfall 1: Unhandled Non-2xx Responses as `:ok`
**What goes wrong:** `Req` returns `{:ok, %Req.Response{status: 404}}` by default, instead of an `{:error, _}` tuple.
**Why it happens:** The HTTP call succeeded, even if the application response was an error code. 
**How to avoid:** Explicitly parse the response status code and cast it to `Paddle.Error`.
```elixir
case Req.request(req) do
  {:ok, %Req.Response{status: status, body: body} = resp} when status in 200..299 ->
    {:ok, body}
  {:ok, %Req.Response{status: status, body: body} = resp} ->
    {:error, Paddle.Error.from_response(resp)}
  {:error, exception} ->
    {:error, exception}
end
```

## Code Examples

### Implementing Elixir Exception Behavior
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

### Attaching Custom Req Telemetry
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

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `HTTPoison` / `Hackney` | `Req` / `Finch` | ~2022 | Cleaner, native JSON parsing, easy step-based middleware for extensions, and standard async/retry logic. |
| Global config (`config.exs`) | Explicit client structs | Modern Elixir | Guarantees testability (`async: true`) and allows multiple API keys to coexist in multi-tenant environments. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Req` allows injecting telemetry efficiently using custom pipeline steps | Code Examples | [LOW] If changed, we might have to wrap `Req.request/1` externally, slightly muddying the clean pipeline interface. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Core framework | ✓ | 1.19.5 | — |
| `mix` | Package management | ✓ | 1.19.5 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-01 | Client initialization | unit | `mix test test/paddle/client_test.exs` | ❌ Wave 0 |
| CORE-02 | HTTP setup + telemetry | unit | `mix test test/paddle/http_test.exs` | ❌ Wave 0 |
| CORE-03 | Error decoding | unit | `mix test test/paddle/error_test.exs` | ❌ Wave 0 |
| CORE-04 | Raw payloads intact | unit | `mix test test/paddle/http_test.exs` | ❌ Wave 0 |
| CORE-05 | Pagination wrapper | unit | `mix test test/paddle/page_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `mix.exs` (Need to run `mix new paddle --sup` to setup the standard library project)
- [ ] `test/test_helper.exs` — standard testing configuration

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Bearer Token included in HTTP Auth headers via `Req.new(auth: {:bearer, key})` |
| V3 Session Management | No | API clients are strictly stateless. |
| V5 Input Validation | No | We rely on the external Paddle API to validate inputs and respond with `4xx`. |
| V6 Cryptography | Yes | Implicitly via `req` utilizing TLS/SSL natively for all transit. |

### Known Threat Patterns for Elixir / HTTP
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Leakage of API Keys | Information Disclosure | Do not log `Req.Request` headers directly in telemetry handlers or general logs. Ensure errors safely omit API keys. |
| Insecure SSL | Tampering | Elixir `Req` uses `CAStore` natively to enforce valid TLS certificates for `https`. No overrides allowed. |

## Sources

### Primary (HIGH confidence)
- [Verified via `mix hex.info`] - Hex Package Registry for `req` and `telemetry` versions.
- [Elixir Community Standards] - Transition from Application configuration to explicitly passed state structs.

### Secondary (MEDIUM confidence)
- [Req Documentation Patterns] - Known best practices for intercepting Requests and Responses using pipeline `Steps`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `req` is universally accepted as standard HTTP client.
- Architecture: HIGH - explicit structs perfectly aligns with idiomatic Elixir.
- Pitfalls: HIGH - Common confusion with `Req` default status code handling is well known.

**Research date:** 2026-04-28
**Valid until:** 2026-06-28
