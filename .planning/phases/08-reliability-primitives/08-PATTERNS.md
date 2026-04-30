# Phase 8: Reliability Primitives - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 10 (new/modified across all four deliverables)
**Analogs found:** 9 / 10 (1 flagged as no-codebase-analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/paddle/error.ex` | error-struct | request-response | `lib/paddle/error.ex` (pre-modification) | self — exact |
| `lib/paddle/http.ex` | transport-chokepoint | request-response | `lib/paddle/http.ex` (pre-modification) | self — exact |
| `lib/paddle/client.ex` | client-config | request-response | `lib/paddle/client.ex` (pre-modification) | self — exact |
| `lib/paddle/customers.ex` | resource-module | CRUD | `lib/paddle/customers.ex` (pre-modification) | self — exact |
| `lib/paddle/customers/addresses.ex` | resource-module | CRUD | `lib/paddle/customers.ex` | role-match |
| `lib/paddle/transactions.ex` | resource-module | CRUD | `lib/paddle/customers.ex` | role-match |
| `test/paddle/error_test.exs` | test-fixture | request-response | `test/paddle/error_test.exs` (pre-modification) | self — exact |
| `test/paddle/http_test.exs` | test-fixture | request-response | `test/paddle/http_test.exs` (pre-modification) | self — exact |
| `test/paddle/seam_test.exs` | test-fixture | request-response | `test/paddle/customers_test.exs` | role-match |
| `test/paddle/http_test.exs` (retry adapter tests) | test-fixture | request-response | **NO CODEBASE ANALOG** | — |

---

## Pattern Assignments by Deliverable

---

### Wave 0: Rename `:raw` → `:raw_data`

---

#### `lib/paddle/error.ex` — defexception field list (Wave 0 + Wave 1 combined)

**Analog:** `lib/paddle/error.ex` lines 1-21 (pre-modification, self-analog)

**Current defexception declaration (line 2) — the line being replaced:**
```elixir
defexception [:type, :code, :message, :errors, :request_id, :status_code, :raw]
```

**Target pattern after Wave 0 + Wave 1 (D-16 explicit defaults, D-01 rename, new fields):**
```elixir
defexception type: nil, code: nil, message: nil, errors: [],
             request_id: nil, status_code: nil, raw_data: nil,
             network_error?: false, retryable?: false
```

Key change: shorthand `[:atom]` list becomes keyword-default syntax. This is the ONLY syntactic form that allows boolean fields to carry `false` defaults (not `nil`). Both the rename (`:raw` → `:raw_data`) and the two new fields (`:network_error?`, `:retryable?`) land in this same declaration — never split across commits.

**Current `from_response/1` body (lines 7-20) — shows `:raw` field being renamed:**
```elixir
def from_response(%Req.Response{status: status, body: body} = resp) do
  body = if is_map(body), do: body, else: %{}
  error_body = Map.get(body, "error", %{})

  %__MODULE__{
    status_code: status,
    request_id: resp |> Req.Response.get_header("x-request-id") |> List.first(),
    type: error_body["type"],
    code: error_body["code"],
    message: Map.get(error_body, "detail", "Unknown Paddle Error"),
    errors: Map.get(error_body, "errors", []),
    raw: body          # <-- rename this to raw_data:
  }
end
```

**Target pattern (after rename):**
```elixir
raw_data: body
```
All other fields in `from_response/1` remain unchanged. The field struct key is the only edit in the function body.

---

#### `test/paddle/error_test.exs` — Wave 0 rename + Wave 1 default assertions

**Analog:** `test/paddle/error_test.exs` lines 1-62 (pre-modification, self-analog)

**Current assertions that reference `:raw` (lines 35-43 and 51-59) — both must become `:raw_data`:**
```elixir
# Line 35-43 (success path):
assert %Error{
         ...
         raw: %{
           "error" => %{ ... }
         }
       } = Error.from_response(response)

# Line 51-59 (fallback path):
assert %Error{
         ...
         raw: %{}
       } = Error.from_response(response)
```

**Target pattern (after rename in both assertions):**
```elixir
raw_data: %{ ... }   # replace raw: in both describe blocks
```

**New tests to ADD for D-16 explicit defaults (no existing analog — pattern is straightforward struct assertion):**
```elixir
describe "struct defaults" do
  test "network_error? defaults to false on a bare struct" do
    assert %Error{network_error?: false} = %Error{}
  end

  test "retryable? defaults to false on a bare struct" do
    assert %Error{retryable?: false} = %Error{}
  end

  test "network_error? defaults to false on from_response/1 result" do
    response = Req.Response.new(status: 422, body: %{})
    assert %Error{network_error?: false} = Error.from_response(response)
  end

  test "retryable? defaults to false on from_response/1 result" do
    response = Req.Response.new(status: 422, body: %{})
    assert %Error{retryable?: false} = Error.from_response(response)
  end
end
```

The 4xx non-429 path test (using `from_response/1`) also implicitly locks D-12: non-transport errors carry `retryable?: false` because `from_response/1` does not set `:retryable?` and the default is `false`.

---

### Wave 1: REL-03 Transport Error Normalization

---

#### `lib/paddle/error.ex` — new `from_transport/1` constructor

**Analog:** `lib/paddle/error.ex` lines 7-20 — `from_response/1` is the direct structural mirror.

**`from_response/1` shape to mirror (lines 7-20):**
```elixir
def from_response(%Req.Response{status: status, body: body} = resp) do
  body = if is_map(body), do: body, else: %{}
  error_body = Map.get(body, "error", %{})

  %__MODULE__{
    status_code: status,
    request_id: resp |> Req.Response.get_header("x-request-id") |> List.first(),
    type: error_body["type"],
    code: error_body["code"],
    message: Map.get(error_body, "detail", "Unknown Paddle Error"),
    errors: Map.get(error_body, "errors", []),
    raw_data: body
  }
end
```

**Pattern to copy — `from_transport/1` mirrors this structure exactly but maps different source fields:**
```elixir
def from_transport(%Req.TransportError{reason: reason} = exception) do
  %__MODULE__{
    type: transport_type(reason),
    message: Exception.message(exception),
    network_error?: true,
    retryable?: true,
    raw_data: exception
  }
end

defp transport_type(:timeout), do: "network_timeout"
defp transport_type(:nxdomain), do: "network_nxdomain"
defp transport_type(:closed), do: "network_closed"
defp transport_type(_), do: "network_unknown"
```

Same shape as `from_response/1`: struct constructor at the top, private helpers below. The `transport_type/1` private helpers follow Elixir multiclause convention — no `case`, just pattern-matched function heads with a catch-all clause. The catch-all (`_`) mapping to `"network_unknown"` is mandatory so new transport reasons never crash.

---

#### `lib/paddle/http.ex` — transport error normalization in `{:error, exception}` arm

**Analog:** `lib/paddle/http.ex` lines 1-17 (pre-modification, self-analog)

**Current `{:error, exception}` arm (lines 14-15) — the arm being refined:**
```elixir
{:error, exception} ->
  {:error, exception}
```

**Target pattern — split into two clauses, specific before catch-all:**
```elixir
{:error, %Req.TransportError{} = exception} ->
  {:error, Paddle.Error.from_transport(exception)}

{:error, exception} ->
  {:error, exception}
```

The catch-all clause is retained verbatim. Elixir pattern matches top-to-bottom; `%Req.TransportError{}` match fires first for transport errors, all other `{:error, ...}` tuples fall through unchanged. This is the same "specific pattern then catch-all" idiom already present in the `case` for the HTTP response arms (lines 8-15).

---

#### `test/paddle/http_test.exs` — rewrite transport test + add reason variants

**Analog:** `test/paddle/http_test.exs` lines 51-58 (current transport test, self-analog for the rewrite)

**Current test at lines 51-58 (to be fully replaced):**
```elixir
test "request/4 surfaces transport exceptions unchanged" do
  client =
    client_with_adapter(fn request ->
      {request, %Req.TransportError{reason: :timeout}}
    end)

  assert {:error, %Req.TransportError{reason: :timeout}} =
           Http.request(client, :get, "/customers")
end
```

**Target pattern (normalizes into `%Paddle.Error{}` — replaces the test above):**
```elixir
test "request/4 normalizes transport exceptions into Paddle.Error" do
  client =
    client_with_adapter(fn request ->
      {request, %Req.TransportError{reason: :timeout}}
    end)

  assert {:error,
          %Paddle.Error{
            network_error?: true,
            retryable?: true,
            type: "network_timeout",
            raw_data: %Req.TransportError{reason: :timeout}
          }} = Http.request(client, :get, "/customers")
end
```

**Additional reason-variant tests to add (same adapter pattern, different reason atoms):**
```elixir
test "request/4 maps nxdomain to network_nxdomain type" do
  client = client_with_adapter(fn req -> {req, %Req.TransportError{reason: :nxdomain}} end)

  assert {:error, %Paddle.Error{type: "network_nxdomain", network_error?: true}} =
           Http.request(client, :get, "/customers")
end

test "request/4 maps closed to network_closed type" do
  client = client_with_adapter(fn req -> {req, %Req.TransportError{reason: :closed}} end)

  assert {:error, %Paddle.Error{type: "network_closed", network_error?: true}} =
           Http.request(client, :get, "/customers")
end

test "request/4 maps unknown reason to network_unknown type" do
  client = client_with_adapter(fn req -> {req, %Req.TransportError{reason: :econnrefused}} end)

  assert {:error, %Paddle.Error{type: "network_unknown", network_error?: true}} =
           Http.request(client, :get, "/customers")
end
```

These four tests exhaustively cover the D-14 taxonomy. The existing `client_with_adapter/1` helper (lines 73-79) is reused unchanged:
```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

---

### Wave 2a: REL-01 Idempotency-Key Header

---

#### `lib/paddle/http.ex` — idempotency-key extraction before Req dispatch

**Analog:** `lib/paddle/http.ex` lines 4-17 (pre-modification, self-analog for the chokepoint pattern)

**Current `request/4` body (lines 4-17) — shows the opts merge site where extraction lands:**
```elixir
def request(%Paddle.Client{} = client, method, path, opts \\ []) do
  opts = Keyword.merge(opts, method: method, url: path)

  case Req.request(client.req, opts) do
    {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
      {:ok, body}

    {:ok, %Req.Response{} = resp} ->
      {:error, Paddle.Error.from_response(resp)}

    {:error, %Req.TransportError{} = exception} ->
      {:error, Paddle.Error.from_transport(exception)}

    {:error, exception} ->
      {:error, exception}
  end
end
```

**Target pattern — pop `:idempotency_key` BEFORE the Req merge (critical ordering, see Pitfall 3 in RESEARCH.md):**
```elixir
def request(%Paddle.Client{} = client, method, path, opts \\ []) do
  {idempotency_key, opts} = Keyword.pop(opts, :idempotency_key)
  opts = Keyword.merge(opts, method: method, url: path)
  opts = maybe_add_idempotency_header(opts, idempotency_key)

  case Req.request(client.req, opts) do
    # ... arms unchanged ...
  end
end

defp maybe_add_idempotency_header(opts, nil), do: opts

defp maybe_add_idempotency_header(opts, key) when is_binary(key) do
  trimmed = String.trim(key)
  if trimmed == "" do
    raise ArgumentError, "idempotency_key must be a non-empty string, got: #{inspect(key)}"
  else
    Keyword.update(opts, :headers, [{"Idempotency-Key", key}],
                   &[{"Idempotency-Key", key} | &1])
  end
end

defp maybe_add_idempotency_header(_opts, key) do
  raise ArgumentError, "idempotency_key must be a non-empty string, got: #{inspect(key)}"
end
```

`ArgumentError` is used for both nil and non-binary cases per RESEARCH.md recommendation (programmer-error idiom consistent with `Keyword.fetch!/2`). The `Keyword.pop/2` call happens before `Keyword.merge` — this is load-bearing; reversing the order causes `ArgumentError: unknown option :idempotency_key` from Req.

---

#### `lib/paddle/customers.ex` — canonical `opts \\ []` pattern for all `create/*`

**Analog:** `lib/paddle/customers.ex` lines 10-17 (canonical resource module create — self-analog, pre-modification)

**Current `create/2` (lines 10-17) — the function gaining `opts \\ []`:**
```elixir
def create(%Client{} = client, attrs) do
  with {:ok, attrs} <- Attrs.normalize(attrs),
       body <- Attrs.allowlist(attrs, @create_allowlist),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, "/customers", json: body) do
    {:ok, Http.build_struct(Customer, data)}
  end
end
```

**Target pattern — `opts \\ []` becomes third arg; merged after `json: body`:**
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

`Keyword.merge([json: body], opts)` places caller opts AFTER the base `json: body` key. Since `Keyword.merge` gives precedence to the right-side list, caller-supplied `:retry`, `:idempotency_key`, and any future opts take precedence over defaults. The `json: body` key will not be overridden by typical caller opts (callers supply `:idempotency_key` or `:retry`, not `:json`).

**Apply IDENTICALLY to these sibling modules — only the function arity and path argument differ:**
- `lib/paddle/customers/addresses.ex` — `create/3` → `create/4`: `(client, customer_id, attrs, opts \\ [])`, same `Keyword.merge([json: body], opts)` merge at `Http.request` call site (line 15)
- `lib/paddle/transactions.ex` — `create/2` → `create/3`: `(client, attrs, opts \\ [])`, same merge pattern at `Http.request` call site (line 25)

No other changes are needed in these sibling modules. The `opts \\ []` default makes the change fully backward-compatible — all existing callers with 2 or 3 args continue to work.

---

#### `test/paddle/customers_test.exs` — analog for idempotency-key adapter test

**Analog:** `test/paddle/customers_test.exs` lines 10-43 (canonical resource adapter test — shows how to assert on request properties inside the adapter closure)

**Pattern to copy — adapter closure inspects the live `%Req.Request{}` before returning a response:**
```elixir
client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/customers"
    assert decode_json_body(request.body) == %{ ... }

    {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
  end)
```

**Target pattern for idempotency-key header assertion (new test in `seam_test.exs` or `http_test.exs`):**
```elixir
test "idempotency_key opt is forwarded as Idempotency-Key header" do
  client =
    client_with_adapter(fn request ->
      assert Req.Request.get_header(request, "idempotency-key") == ["my-key-123"]
      {request, Req.Response.new(status: 201, body: %{"data" => %{"id" => "cus_123"}})}
    end)

  {:ok, _} =
    Paddle.Customers.create(client, [email: "x@example.com", name: "X"],
      idempotency_key: "my-key-123")
end
```

Note: Req normalizes header names to lowercase; assert `"idempotency-key"` (lowercase), not `"Idempotency-Key"`. The `client_with_adapter/1` helper in `customers_test.exs` (lines 184-190) is the exact template:

```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

---

### Wave 2b: REL-02 Retry Policy

---

#### `lib/paddle/client.ex` — retry baseline in `new!/1`

**Analog:** `lib/paddle/client.ex` lines 14-21 (pre-modification, self-analog for `Req.new` block)

**Current `Req.new` block (lines 14-20) — two options being added:**
```elixir
req =
  Req.new(
    base_url: base_url,
    auth: {:bearer, api_key},
    headers: [{"Paddle-Version", "1"}]
  )
  |> Paddle.Http.Telemetry.attach()
```

**Target pattern — add `retry:` and `max_retries:` inline with existing opts:**
```elixir
req =
  Req.new(
    base_url: base_url,
    auth: {:bearer, api_key},
    headers: [{"Paddle-Version", "1"}],
    retry: :transient,
    max_retries: 3
  )
  |> Paddle.Http.Telemetry.attach()
```

This is the complete Wave 2b change to `client.ex`. `retry: :transient` retries all HTTP methods (POST included) on 429/500/502/503/504 and `%Req.TransportError{reason: :timeout | :econnrefused | :closed}`. `Retry-After` on 429/503 is honored automatically. Exponential backoff (`1s/2s/4s`) is used when `Retry-After` is absent. No custom retry function needed.

---

#### `test/paddle/http_test.exs` — retry adapter tests

**NO CODEBASE ANALOG.** The existing `client_with_adapter/1` in every test file (lines 73-79 of `http_test.exs`, lines 192-198 of `seam_test.exs`, lines 184-190 of `customers_test.exs`) always sets `retry: false`. No test currently exercises retry-ON behavior. The stateful-adapter pattern using `Agent` is sourced from Req's own test suite (cited in RESEARCH.md as "verified" pattern for test closures that need stateful call counting).

**Stateful adapter pattern (Agent-based — no codebase analog; copy from RESEARCH.md Wave 2b section):**
```elixir
test "retries on 5xx then succeeds" do
  {:ok, agent} = Agent.start_link(fn -> 0 end)

  client = %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(
      base_url: "https://sandbox-api.paddle.com",
      retry: :transient,
      max_retries: 3,
      retry_delay: 0,
      adapter: fn request ->
        count = Agent.get_and_update(agent, fn n -> {n, n + 1} end)
        if count == 0 do
          {request, Req.Response.new(status: 503, body: %{})}
        else
          {request, Req.Response.new(status: 200, body: %{"data" => %{"id" => "cus_123"}})}
        end
      end
    )
  }

  assert {:ok, _} = Http.request(client, :get, "/customers")
  assert Agent.get(agent, & &1) == 2
  Agent.stop(agent)
end
```

**Critical difference from all existing test clients:** `retry: false` is ABSENT and `retry_delay: 0` is PRESENT. `retry_delay: 0` eliminates wall-clock delays in tests without affecting retry decision logic (Req accepts integer 0 as constant delay in ms per RESEARCH.md A3). Tests that set `retry: false` on the client base remain unaffected by Wave 2b — they still work as-is.

**Three additional retry tests needed (RESEARCH.md Wave 2b section is the source):**
1. "does not retry on 422 validation error" — Agent counts calls, asserts count == 1
2. "retries on 429 then succeeds" — same Agent pattern, first response is 429
3. "per-call retry: false opt-out disables retry on 5xx" — passes `retry: false` in opts to `Http.request/4`, asserts count == 1 even on 503

The per-call opt-out test proves the `Keyword.merge` precedence chain works end-to-end: `Http.request(client, :get, path, retry: false)` → remaining opts after `Keyword.pop(:idempotency_key)` → `Keyword.merge([method:, url:], opts)` → `Req.request(client.req, final_opts)` where `retry: false` overrides `retry: :transient` from `client.req`.

---

## Shared Patterns

### Adapter-backed test client construction

**Source:** `test/paddle/http_test.exs` lines 73-79 (identical across all test files)
**Apply to:** All new tests (transport normalization, idempotency header, retry tests)

```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

For retry tests: copy this helper verbatim but OMIT `retry: false` and ADD `retry_delay: 0` and `retry: :transient`. Do not modify the existing helper — add a second helper (e.g., `client_with_retry_adapter/1`) or inline the `%Client{}` struct directly in retry tests.

### Tagged-tuple return contract

**Source:** `lib/paddle/customers.ex` lines 10-17, `lib/paddle/http.ex` lines 7-16
**Apply to:** All modified public functions

All public functions return `{:ok, struct}` or `{:error, atom | %Paddle.Error{}}`. The `from_transport/1` result flows through `http.ex` as `{:error, %Paddle.Error{}}` — same shape as `from_response/1` results. Resource modules see no change in their return type contract.

### defexception keyword-default syntax

**Source:** D-16 (locked decision); current codebase uses shorthand `[:atom]` form — this is the anti-pattern to replace
**Apply to:** `lib/paddle/error.ex` line 2 only

Any `defexception` field that must carry a non-nil default MUST use keyword syntax. Boolean guard fields (`:network_error?`, `:retryable?`) must always use this form. List fields (`:errors`) should also be declared with `[]` default to avoid nil/list mismatches downstream.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Retry-ON adapter tests in `http_test.exs` | test-fixture | request-response | No existing test in the codebase sets `retry: :transient` with a stateful adapter. Pattern sourced from Req's own test suite (RESEARCH.md Wave 2b, Agent-based stateful closure). |

---

## Metadata

**Analog search scope:** `lib/paddle/`, `test/paddle/`
**Files read:** 10 source files
**Pattern extraction date:** 2026-04-30
**Wave ordering enforced:**
- Wave 0 (rename) must precede all others — `from_transport/1` (Wave 1) writes to `:raw_data`; splitting the rename from the seam guide update is explicitly prohibited (D-02, Pitfall 6)
- Wave 1 (REL-03) must precede Wave 2 — `from_transport/1` referenced by `Http.request/4`
- Wave 2a (REL-01) and Wave 2b (REL-02) are independent and can be planned/executed in parallel
