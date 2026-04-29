# Phase 02: Webhook Verification - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/paddle/webhooks.ex` | service | transform | `lib/paddle/http.ex` | role-match |
| `lib/paddle/event.ex` | model | transform | `lib/paddle/page.ex` | role-match |
| `test/paddle/webhooks_test.exs` | test | transform | `test/paddle/http_test.exs` | role-match |
| `test/paddle/event_test.exs` | test | transform | `test/paddle/page_test.exs` | exact |

## Pattern Assignments

### `lib/paddle/webhooks.ex` (service, transform)

**Analog:** `lib/paddle/http.ex`

**Core tuple boundary** (`lib/paddle/http.ex:2-14`):
```elixir
def request(%Paddle.Client{} = client, method, path, opts \\ []) do
  opts = Keyword.merge(opts, method: method, url: path)

  case Req.request(client.req, opts) do
    {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
      {:ok, body}

    {:ok, %Req.Response{} = resp} ->
      {:error, Paddle.Error.from_response(resp)}

    {:error, exception} ->
      {:error, exception}
  end
end
```

**Struct-building helper style** (`lib/paddle/http.ex:17-28`):
```elixir
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
```

**Copy from this pattern**
- Keep `verify_signature/4` and `parse_event/1` as pure functions returning `{:ok, value}` or `{:error, reason}`.
- Use a `case`-driven control flow instead of raising on malformed signatures or invalid payloads.
- Keep helpers private inside the module first; phase research explicitly prefers `lib/paddle/webhooks.ex` over framework middleware or extra helper modules.

**Supporting error-shape analog:** `lib/paddle/error.ex`

**Explicit fallback handling** (`lib/paddle/error.ex:7-20`):
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
    raw: body
  }
end
```

**Apply this to webhook verification**
- Normalize bad inputs into explicit error tuples instead of exceptions.
- Provide safe fallbacks for malformed header segments, non-map decoded payloads, and missing keys.

---

### `lib/paddle/event.ex` (model, transform)

**Analog:** `lib/paddle/page.ex`

**Minimal struct module pattern** (`lib/paddle/page.ex:1-8`):
```elixir
defmodule Paddle.Page do
  defstruct [:data, :meta]

  def next_cursor(%__MODULE__{meta: %{"pagination" => %{"next" => next}}}) when is_binary(next) do
    next
  end

  def next_cursor(_), do: nil
end
```

**Supporting raw-data mapping analog:** `lib/paddle/http.ex`

**Known-fields plus `raw_data` convention** (`lib/paddle/http.ex:17-28`):
```elixir
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
```

**Copy from this pattern**
- Keep `Paddle.Event` as a small explicit struct module with no framework coupling.
- Preserve the project’s existing `raw_data` field name from `Paddle.Http.build_struct/2`.
- If the parser uses `Paddle.Http.build_struct/2`, only map the known envelope keys and keep the full decoded payload in `raw_data`.

---

### `test/paddle/webhooks_test.exs` (test, transform)

**Analog:** `test/paddle/http_test.exs`

**Async ExUnit module and alias layout** (`test/paddle/http_test.exs:1-10`):
```elixir
defmodule Paddle.HttpTest do
  use ExUnit.Case, async: true

  defmodule SampleStruct do
    defstruct [:id, :name, :raw_data]
  end

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Http
```

**Focused tuple assertions** (`test/paddle/http_test.exs:12-18`, `21-29`, `51-58`):
```elixir
test "request/4 returns ok tuples for 2xx responses" do
  assert {:ok, %{"data" => %{"id" => "cus_123"}}} = Http.request(client, :get, "/customers")
end

test "request/4 maps non-2xx responses to Paddle.Error" do
  assert {:error, %Error{status_code: 422}} = Http.request(client, :post, "/customers", body: %{})
end

test "request/4 surfaces transport exceptions unchanged" do
  assert {:error, %Req.TransportError{reason: :timeout}} =
           Http.request(client, :get, "/customers")
end
```

**Copy from this pattern**
- Keep tests as small async unit tests with inline fixtures and no network calls.
- Assert exact tuple shapes for success and failure cases.
- Use helper functions only when they remove repeated setup; for webhook tests, small inline signed payload helpers are preferred by the research doc.

---

### `test/paddle/event_test.exs` (test, transform)

**Analog:** `test/paddle/page_test.exs`

**Describe-block organization** (`test/paddle/page_test.exs:1-28`):
```elixir
defmodule Paddle.PageTest do
  use ExUnit.Case, async: true

  alias Paddle.Page

  describe "struct" do
    test "stores data and meta" do
      page = %Page{data: [%{"id" => "txn_123"}], meta: %{"pagination" => %{"next" => "/next"}}}

      assert page.data == [%{"id" => "txn_123"}]
      assert page.meta == %{"pagination" => %{"next" => "/next"}}
    end
  end
end
```

**Supporting exact-field assertions:** `test/paddle/error_test.exs`

**Pattern for exhaustive struct matching** (`test/paddle/error_test.exs:12-60`):
```elixir
assert %Error{
         status_code: 422,
         request_id: "req_123",
         type: "validation_error",
         code: "invalid_field",
         message: "Email is invalid",
         errors: [%{"field" => "email", "message" => "must be present"}],
         raw: %{"error" => %{"type" => "validation_error"}}
       } = Error.from_response(response)
```

**Copy from this pattern**
- Group event parsing cases under `describe "parse_event/1"`.
- Use exact struct matches for `event_id`, `event_type`, `notification_id`, `occurred_at`, `data`, and `raw_data`.
- Keep invalid JSON and incomplete-payload cases as direct `{:error, reason}` assertions rather than broad truthy/falsy checks.

## Shared Patterns

### Explicit SDK Tuple Boundaries
**Sources:** `lib/paddle/http.ex:2-14`, `test/paddle/http_test.exs:12-18`, `test/paddle/http_test.exs:51-58`
**Apply to:** `lib/paddle/webhooks.ex`, `test/paddle/webhooks_test.exs`, `test/paddle/event_test.exs`
```elixir
case some_operation do
  {:ok, value} ->
    {:ok, value}

  {:error, reason} ->
    {:error, reason}
end
```

Use explicit `{:ok, value}` / `{:error, reason}` returns for both signature verification and event parsing. Do not introduce boolean-only success paths unless the planner deliberately trades away failure introspection.

### `raw_data` Preservation
**Source:** `lib/paddle/http.ex:17-28`
**Apply to:** `lib/paddle/event.ex`, `test/paddle/event_test.exs`
```elixir
struct(struct_module, Map.put(attrs, :raw_data, data))
```

Preserve the full decoded webhook payload in `raw_data` while exposing the known event envelope fields directly on `%Paddle.Event{}`.

### Explicit Fallback Handling
**Source:** `lib/paddle/error.ex:7-20`
**Apply to:** `lib/paddle/webhooks.ex`, `lib/paddle/event.ex`
```elixir
body = if is_map(body), do: body, else: %{}
error_body = Map.get(body, "error", %{})
```

Normalize malformed inputs before extracting keys. The same defensive style should be used for signature header parsing and webhook payload validation.

### Async Unit Test Shape
**Sources:** `test/paddle/http_test.exs:1-10`, `test/paddle/page_test.exs:1-28`, `test/paddle/error_test.exs:12-60`
**Apply to:** `test/paddle/webhooks_test.exs`, `test/paddle/event_test.exs`
```elixir
use ExUnit.Case, async: true

describe "some_function/arity" do
  test "describes one behavior" do
    assert ...
  end
end
```

Keep tests deterministic, inline, and adapter-free. Research already calls out `opts[:now]` and direct `:crypto.mac/4` usage for deterministic webhook verification tests.

## No Analog Found

None. The existing SDK already has close role-matches for pure function modules, explicit structs, and async ExUnit tests.

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`, `.planning/phases/01-core-transport-client-setup/01-PATTERNS.md`
**Files scanned:** 8
**Pattern extraction date:** 2026-04-28
