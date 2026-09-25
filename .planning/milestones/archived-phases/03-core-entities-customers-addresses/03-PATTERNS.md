# Phase 3: Core Entities (Customers & Addresses) - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/paddle/customer.ex` | model | transform | `lib/paddle/event.ex` | role-match |
| `lib/paddle/address.ex` | model | transform | `lib/paddle/event.ex` | role-match |
| `lib/paddle/customers.ex` | service | request-response | `lib/paddle/webhooks.ex` + `lib/paddle/http.ex` | partial |
| `lib/paddle/customers/addresses.ex` | service | request-response + CRUD | `lib/paddle/webhooks.ex` + `lib/paddle/http.ex` + `lib/paddle/page.ex` | partial |
| `test/paddle/customer_test.exs` | test | transform | `test/paddle/event_test.exs` | role-match |
| `test/paddle/address_test.exs` | test | transform | `test/paddle/event_test.exs` | role-match |
| `test/paddle/customers_test.exs` and/or `test/paddle/customers/addresses_test.exs` | test | request-response + CRUD | `test/paddle/http_test.exs` + `test/paddle/page_test.exs` | partial |

## Pattern Assignments

### `lib/paddle/customer.ex`

**Analog:** [lib/paddle/event.ex](/Users/jon/projects/oarlock/lib/paddle/event.ex:1)

**Module layout to copy** (lines 1-2):
```elixir
defmodule Paddle.Event do
  defstruct [:event_id, :event_type, :occurred_at, :notification_id, :data, :raw_data]
end
```

**Phase 3 application**
- Keep entity modules as single-purpose struct modules with no HTTP logic.
- Preserve `raw_data` as the last struct field.
- Predeclare every promoted JSON field in `defstruct`; `Paddle.Http.build_struct/2` only fills keys that already exist.

**Recommended shape**
- `Paddle.Customer` should stay minimal like `Paddle.Event`, with only promoted top-level fields plus `raw_data`.
- Keep nested `custom_data` as a plain map unless Phase 3 explicitly chooses otherwise.

### `lib/paddle/address.ex`

**Analog:** [lib/paddle/event.ex](/Users/jon/projects/oarlock/lib/paddle/event.ex:1)

**Same struct pattern applies**
- Small explicit `defmodule`.
- `defstruct [...]` only.
- `raw_data` retained for forward compatibility.

**Phase 3 nuance**
- Because addresses are customer-owned resources, ownership should live in the service API and path building, not in a special model behavior layer.

### `lib/paddle/customers.ex`

**Analogs:** [lib/paddle/webhooks.ex](/Users/jon/projects/oarlock/lib/paddle/webhooks.ex:1), [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:1), [lib/paddle/client.ex](/Users/jon/projects/oarlock/lib/paddle/client.ex:1)

**Explicit client boundary** from `Paddle.Http.request/4` (lines 2-14):
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

**Boundary-validation pattern** from `Paddle.Webhooks.parse_event/1` (lines 27-41):
```elixir
def parse_event(raw_body) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, %{"data" => data} = payload} when is_map(data) ->
      if valid_payload?(payload) do
        {:ok, Paddle.Http.build_struct(Paddle.Event, payload)}
      else
        {:error, :invalid_event_payload}
      end

    {:ok, _payload} ->
      {:error, :invalid_event_payload}

    {:error, _reason} ->
      {:error, :invalid_json}
  end
end
```

**Struct-mapping helper** from `Paddle.Http.build_struct/2` (lines 17-28):
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

**Phase 3 API pattern to preserve**
- Public functions should accept `%Paddle.Client{}` as the first argument, matching the explicit-client pattern.
- Return `{:ok, %Paddle.Customer{}}` on success.
- Return `{:error, %Paddle.Error{}}` for API failures that come back as non-2xx HTTP responses.
- Do not add a `Paddle` facade wrapper; Phase 3 decisions already lock resource modules as the public boundary.

**Concrete implementation shape**
- `create/2`: validate attrs container shape, POST to `"/customers"`, map response `"data"` into `%Paddle.Customer{}`.
- `get/2`: validate required id, GET `"/customers/#{id}"`, map response `"data"`.
- `update/3`: validate required id plus attrs container shape, PATCH `"/customers/#{id}"`, map response `"data"`.

### `lib/paddle/customers/addresses.ex`

**Analogs:** [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:1), [lib/paddle/page.ex](/Users/jon/projects/oarlock/lib/paddle/page.ex:1), [lib/paddle/webhooks.ex](/Users/jon/projects/oarlock/lib/paddle/webhooks.ex:27)

**Pagination wrapper** from `Paddle.Page` (lines 1-8):
```elixir
defmodule Paddle.Page do
  defstruct [:data, :meta]

  def next_cursor(%__MODULE__{meta: %{"pagination" => %{"next" => next}}}) when is_binary(next) do
    next
  end

  def next_cursor(_), do: nil
end
```

**Phase 3 API pattern to preserve**
- Nest addresses under `Paddle.Customers.Addresses`, matching the locked customer-owned public API.
- Keep customer id explicit in every function signature; do not hide ownership in attrs.
- `list/3` should return `{:ok, %Paddle.Page{data: [%Paddle.Address{}, ...], meta: meta}}`.

**Concrete implementation shape**
- `create/3`: POST to `"/customers/#{customer_id}/addresses"`.
- `list/3`: GET `"/customers/#{customer_id}/addresses"` with optional query params, then map each `"data"` item with `Paddle.Http.build_struct(Paddle.Address, item)` and preserve `"meta"` unchanged.
- `get/3`: GET `"/customers/#{customer_id}/addresses/#{address_id}"`.
- `update/4`: PATCH `"/customers/#{customer_id}/addresses/#{address_id}"`.

**Important gap**
- There is no existing helper for list-to-page mapping. Phase 3 will need a thin private helper in the resource module or a narrow `Paddle.Http` extension to transform `%{"data" => list, "meta" => meta}` into `%Paddle.Page{}`.

### `test/paddle/customer_test.exs` and `test/paddle/address_test.exs`

**Analog:** [test/paddle/event_test.exs](/Users/jon/projects/oarlock/test/paddle/event_test.exs:1)

**Minimal struct test pattern** (lines 7-17):
```elixir
describe "struct" do
  test "exposes the generic webhook envelope fields" do
    assert %Event{
             event_id: nil,
             event_type: nil,
             occurred_at: nil,
             notification_id: nil,
             data: nil,
             raw_data: nil
           } = %Event{}
  end
end
```

**Phase 3 application**
- Add one struct-shape test per entity that asserts the public field list and `raw_data`.
- Keep these tests pure and fast; no HTTP adapter needed for model-only modules.

### Request/response tests for customer and address resources

**Analog:** [test/paddle/http_test.exs](/Users/jon/projects/oarlock/test/paddle/http_test.exs:12)

**Req adapter stub pattern** (lines 73-79):
```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

**Transport assertions to copy** (lines 12-18, 21-49, 51-58):
- Success path asserts `{:ok, body}` from transport, then resource module should assert mapped typed struct.
- Error path asserts `%Paddle.Error{}` fields, not ad hoc maps.
- Transport exception path is currently returned unchanged as `{:error, %Req.TransportError{}}`.

**Page behavior test analog:** [test/paddle/page_test.exs](/Users/jon/projects/oarlock/test/paddle/page_test.exs:15)
- Add one address list test that asserts `page.data` contains `%Paddle.Address{}` structs and `Page.next_cursor/1` still works off preserved `meta`.

## Shared Patterns

### Naming and module layout
- Public resource modules use the `Paddle.*` namespace and explicit nesting, not a generated endpoint dump.
- Current library modules are small and single-purpose: [lib/paddle/event.ex](/Users/jon/projects/oarlock/lib/paddle/event.ex:1), [lib/paddle/page.ex](/Users/jon/projects/oarlock/lib/paddle/page.ex:1), [lib/paddle/error.ex](/Users/jon/projects/oarlock/lib/paddle/error.ex:1).
- Phase 3 should follow the same split:
  - `Paddle.Customer` and `Paddle.Address` for structs.
  - `Paddle.Customers` and `Paddle.Customers.Addresses` for request functions.

### Tuple-return conventions
- Transport layer already defines the public success/error tuple shape at [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:2).
- Phase 3 modules should preserve:
  - `{:ok, %Paddle.Customer{}}`
  - `{:ok, %Paddle.Address{}}`
  - `{:ok, %Paddle.Page{data: [%Paddle.Address{}, ...], meta: meta}}`
  - `{:error, %Paddle.Error{}}` for non-2xx Paddle responses
- Current code also returns transport exceptions unchanged (`{:error, exception}`), so planners should explicitly decide whether Phase 3 mirrors that behavior at the public resource boundary or wraps it later.

### Raw payload preservation
- `raw_data` is the established forward-compatibility escape hatch in [lib/paddle/http.ex](/Users/jon/projects/oarlock/lib/paddle/http.ex:17) and is asserted in [test/paddle/http_test.exs](/Users/jon/projects/oarlock/test/paddle/http_test.exs:67).
- Phase 3 should not rename this field or split it into alternate raw payload containers.

### Validation style
- Existing boundary checks are lightweight and explicit, not schema-heavy. `Paddle.Webhooks.parse_event/1` only checks container shape and required keys before returning a typed struct: [lib/paddle/webhooks.ex](/Users/jon/projects/oarlock/lib/paddle/webhooks.ex:27).
- Phase 3 should mirror that level of validation:
  - ensure ids are non-empty binaries
  - ensure attrs are `map | keyword`
  - leave business validation to Paddle

## Gaps And Quirks Planning Must Account For

| Area | Current Behavior | Planning Impact |
|---|---|---|
| `Paddle.Http.build_struct/2` | Only copies keys already present in the target `defstruct` and silently drops the rest while keeping `raw_data` | Customer and Address structs must declare every promoted field up front |
| `Paddle.Http.build_struct/2` | Compares incoming keys to strings and calls `String.to_existing_atom/1` | It is for JSON response maps, not atom-key attrs; request normalization needs a separate helper |
| `Paddle.Http.request/4` | Success returns the full decoded body, not `body["data"]` | Resource modules must unwrap Paddle envelopes themselves |
| `Paddle.Http.request/4` | Transport failures pass through as raw exceptions, not `%Paddle.Error{}` | Tests and plans should cover this explicitly so public behavior is intentional |
| Pagination | Only `%Paddle.Page{}` and `next_cursor/1` exist today | Address listing needs custom page construction and page-specific tests |
| Root module | [lib/paddle.ex](/Users/jon/projects/oarlock/lib/paddle.ex:1) is still the default scaffold and not a real facade | Phase 3 should not copy anything from `Paddle`; ignore it as a pattern source |

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/paddle/customers.ex` | service | CRUD request-response | No existing resource module performs API CRUD yet; combine `Paddle.Http` transport with `Paddle.Webhooks.parse_event/1` boundary checks |
| `lib/paddle/customers/addresses.ex` | service | CRUD request-response + pagination | No existing paginated resource module exists yet; `Paddle.Page` is only the container |

## Metadata

**Analog search scope:** `.planning/`, `lib/paddle/`, `test/paddle/`
**Files scanned:** 16
**Pattern extraction date:** 2026-04-28
