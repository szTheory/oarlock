# Phase 11: Type-Safety Pass - Pattern Map

**Mapped:** 2026-05-30  
**Files analyzed:** 26  
**Analogs found:** 24 / 26

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config | request-response | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.dialyzer_ignore.exs` | config | batch | none | no-analog |
| `priv/plts/` | config | batch | none | no-analog |
| `lib/mix/tasks/typecheck.specs.ex` | task | transform | `mix.exs` (project task/config style), `lib/paddle/internal/attrs.ex` (normalize/reduce style) | partial |
| `lib/paddle/application.ex` | provider | request-response | `lib/paddle/client.ex` | role-match |
| `lib/paddle/client.ex` | model | request-response | `lib/paddle/client.ex` | exact |
| `lib/paddle/error.ex` | model | transform | `lib/paddle/error.ex` | exact |
| `lib/paddle/page.ex` | model | transform | `lib/paddle/page.ex` | exact |
| `lib/paddle/address.ex` | model | transform | `lib/paddle/customer.ex` | role-match |
| `lib/paddle/customer.ex` | model | transform | `lib/paddle/customer.ex` | exact |
| `lib/paddle/event.ex` | model | transform | `lib/paddle/transaction.ex` | role-match |
| `lib/paddle/subscription.ex` | model | transform | `lib/paddle/subscription.ex` | exact |
| `lib/paddle/subscription/management_urls.ex` | model | transform | `lib/paddle/subscription/scheduled_change.ex` | role-match |
| `lib/paddle/subscription/scheduled_change.ex` | model | transform | `lib/paddle/subscription/scheduled_change.ex` | exact |
| `lib/paddle/transaction.ex` | model | transform | `lib/paddle/transaction.ex` | exact |
| `lib/paddle/transaction/checkout.ex` | model | transform | `lib/paddle/transaction/checkout.ex` | exact |
| `lib/paddle/customers.ex` | service | CRUD | `lib/paddle/customers.ex` | exact |
| `lib/paddle/customers/addresses.ex` | service | CRUD + streaming | `lib/paddle/customers/addresses.ex` | exact |
| `lib/paddle/transactions.ex` | service | CRUD | `lib/paddle/transactions.ex` | exact |
| `lib/paddle/subscriptions.ex` | service | CRUD + streaming | `lib/paddle/subscriptions.ex` | exact |
| `lib/paddle/webhooks.ex` | service | event-driven | `lib/paddle/webhooks.ex` | exact |
| `lib/paddle/http.ex` | service | request-response | `lib/paddle/transactions.ex` | role-match |
| `lib/paddle/http/telemetry.ex` | middleware | event-driven | `lib/paddle/webhooks.ex` | partial |
| `lib/paddle/internal/attrs.ex` | utility | transform | `lib/paddle/internal/attrs.ex` | exact |
| `lib/paddle/internal/pagination.ex` | utility | streaming | `lib/paddle/internal/pagination.ex` | exact |

## Pattern Assignments

### `lib/paddle/*.ex` + `lib/paddle/**/*.ex` public resource/struct modules

**Primary analogs:**  
- `lib/paddle/customers.ex`  
- `lib/paddle/customers/addresses.ex`  
- `lib/paddle/subscriptions.ex`  
- `lib/paddle/transactions.ex`  
- `lib/paddle/webhooks.ex`  

**Imports/Alias pattern** (`lib/paddle/customers.ex:2-5`):
```elixir
alias Paddle.Client
alias Paddle.Customer
alias Paddle.Http
alias Paddle.Internal.Attrs
```

**Public function shape pattern** (`lib/paddle/customers.ex:10-16`):
```elixir
def create(%Client{} = client, attrs, opts \\ []) do
  with {:ok, attrs} <- Attrs.normalize(attrs),
       body <- Attrs.allowlist(attrs, @create_allowlist),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, "/customers", Keyword.merge([json: body], opts)) do
    {:ok, Http.build_struct(Customer, data)}
  end
end
```

**ID validation + tagged error atoms** (`lib/paddle/customers.ex:39-47`):
```elixir
defp validate_customer_id(customer_id) when is_binary(customer_id) do
  if String.trim(customer_id) == "" do
    {:error, :invalid_customer_id}
  else
    :ok
  end
end
```

**Pagination stream/all contract pattern** (`lib/paddle/customers/addresses.ex:45-57`):
```elixir
def stream(%Paddle.Client{} = client, customer_id, params \\ []) do
  Pagination.stream(
    fn -> list(client, customer_id, params) end,
    fn path -> next_page(client, path) end
  )
end
```

**Lifecycle options normalization pattern** (`lib/paddle/subscriptions.ex:109-122`, `191-204`):
```elixir
case Keyword.pop(opts, :retry) do
  {retry_value, remaining} ->
    with :ok <- reject_idempotency_key!(remaining, "pause"),
         :ok <- reject_unknown_pause_opts(remaining),
         {:ok, body} <- build_pause_body(remaining) do
      request_opts =
        if retry_value == nil and not Keyword.has_key?(opts, :retry), do: [], else: [retry: retry_value]
      {:ok, body, request_opts}
    end
end
```

**Event/webhook parse + explicit reason atoms** (`lib/paddle/webhooks.ex:32-46`):
```elixir
def parse_event(raw_body) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, %{"data" => data} = payload} when is_map(data) ->
      if valid_payload?(payload), do: {:ok, Paddle.Http.build_struct(Paddle.Event, payload)}, else: {:error, :invalid_event_payload}
    {:ok, _payload} -> {:error, :invalid_event_payload}
    {:error, _reason} -> {:error, :invalid_json}
  end
end
```

### `mix.exs` (Dialyxir dependency/config)

**Analog:** `mix.exs`

**Project config placement pattern** (`mix.exs:7-23`):
```elixir
def project do
  [
    app: :paddle,
    version: @version,
    elixir: "~> 1.19",
    start_permanent: Mix.env() == :prod,
    deps: deps(),
    ...
  ]
end
```

**Dependency style pattern** (`mix.exs:33-38`):
```elixir
defp deps do
  [
    {:req, "~> 0.5.17"},
    {:telemetry, "~> 1.4"},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false}
  ]
end
```

Use same list shape to add `{:dialyxir, "...", only: [:dev, :test], runtime: false}` and `dialyzer: [...]` in `project/0`.

### `.github/workflows/ci.yml` (dedicated Dialyzer/spec gate)

**Analog:** `.github/workflows/ci.yml`

**Job + setup-beam pattern** (`.github/workflows/ci.yml:21-32`):
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@...
      - uses: erlef/setup-beam@...
        with:
          version-file: .tool-versions
          version-type: strict
```

**Cache and command step pattern** (`.github/workflows/ci.yml:33-61`):
```yaml
- name: Cache library deps
  uses: actions/cache@...
  with:
    path: |
      deps
      _build
    key: ${{ runner.os }}-library-${{ hashFiles('mix.lock') }}
...
- name: Run tests
  env:
    MIX_ENV: test
  run: mix test
```

Add a separate `dialyzer` job using this same pinned-action style, with PLT cache path at `priv/plts` and steps for `mix typecheck.specs` then `mix dialyzer`.

### `lib/mix/tasks/typecheck.specs.ex` (new Mix task)

**Closest analogs:** `lib/paddle/internal/attrs.ex`, `lib/paddle/webhooks.ex`

**Deterministic reducer pattern** (`lib/paddle/internal/attrs.ex:15-21`):
```elixir
Enum.reduce(attrs, %{}, fn
  {key, value}, acc when is_atom(key) -> Map.put(acc, Atom.to_string(key), value)
  {key, value}, acc when is_binary(key) -> Map.put(acc, key, value)
  {_key, _value}, acc -> acc
end)
```

**Explicit guard + reason atom pattern** (`lib/paddle/webhooks.ex:53-57`):
```elixir
defp normalize_tolerance(tolerance) when is_integer(tolerance) and tolerance >= 0,
  do: {:ok, tolerance}

defp normalize_tolerance(_tolerance), do: {:error, :invalid_tolerance}
```

Implement task with deterministic scan/reduce and explicit failure output (missing `@spec` entries) followed by non-zero exit.

## Shared Patterns

### Option/Attrs Normalization
**Source:** `lib/paddle/internal/attrs.ex:4-13`, `:23-31`  
**Apply to:** all resource modules with attrs/params/opts
```elixir
def normalize(attrs) when is_list(attrs) do
  if Keyword.keyword?(attrs), do: {:ok, attrs |> Enum.into(%{}) |> normalize_keys()}, else: {:error, :invalid_attrs}
end
...
def allowlist(attrs, allowed_keys) do
  Enum.reduce(attrs, %{}, fn {key, value}, acc -> if key in allowed_keys, do: Map.put(acc, key, value), else: acc end)
end
```

### Streaming Pagination Contract
**Source:** `lib/paddle/internal/pagination.ex:7-19`, `:102-110`  
**Apply to:** `stream/*` and `all/*` specs in list modules
```elixir
def stream(first_page_fun, next_page_fun) when is_function(first_page_fun, 0) and is_function(next_page_fun, 1) do
  Stream.resource(fn -> {:first, first_page_fun, next_page_fun} end, &stream_next/1, fn _state -> :ok end)
end
...
defp raise_stream_error(%Error{} = error), do: raise(error)
```

### Error Struct + Exception Interop
**Source:** `lib/paddle/error.ex:2-10`, `:15-37`  
**Apply to:** return specs and error typing in all public modules
```elixir
defexception type: nil, code: nil, message: nil, errors: [], request_id: nil, status_code: nil, raw_data: nil, network_error?: false, retryable?: false
...
def from_transport(%Req.TransportError{reason: reason} = exception) do
  %__MODULE__{type: transport_type(reason), message: Exception.message(exception), network_error?: true, retryable?: true, raw_data: exception}
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.dialyzer_ignore.exs` | config | batch | New baseline artifact; no existing ignore file in repo |
| `priv/plts/` | config | batch | New PLT storage path; `priv/` directory does not currently exist |

## Metadata

**Analog search scope:** `lib/paddle/**`, `mix.exs`, `.github/workflows/**`, `test/paddle/**`, `.tool-versions`  
**Files scanned:** 12 primary analog files + phase context docs  
**Pattern extraction date:** 2026-05-30
