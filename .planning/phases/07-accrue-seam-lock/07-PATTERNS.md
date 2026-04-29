# Phase 07: Accrue Seam Lock - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 10
**Analogs found:** 7 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/paddle/seam_test.exs` | test | request-response | `test/paddle/seam_test.exs` | exact |
| `guides/accrue-seam.md` | config | transform | `guides/accrue-seam.md` | exact |
| `mix.exs` | config | transform | `mix.exs` | exact |
| `README.md` | config | transform | `README.md` | exact |
| `lib/paddle/http.ex` | utility | request-response | `lib/paddle/internal/attrs.ex` | partial |
| `lib/paddle/http/telemetry.ex` | utility | event-driven | `lib/paddle/internal/attrs.ex` | partial |
| `lib/paddle.ex` | utility | transform | `lib/paddle/application.ex` | partial |
| `lib/paddle/client.ex` | model | request-response | `test/paddle/client_test.exs` | partial |
| `lib/paddle/page.ex` | model | transform | `test/paddle/page_test.exs` | partial |
| `lib/paddle/error.ex` | model | transform | `test/paddle/error_test.exs` | partial |

## Pattern Assignments

### `test/paddle/seam_test.exs` (test, request-response)

**Primary analog:** `test/paddle/seam_test.exs`

**Test shell / aliases pattern** (`test/paddle/seam_test.exs:5-17`):
```elixir
defmodule Paddle.SeamTest do
  use ExUnit.Case, async: false

  alias Paddle.Address
  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Event
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout
  alias Paddle.Webhooks
```

**Semantic contract assertion pattern** (`test/paddle/seam_test.exs:38-45`, `65-76`, `93-102`, `114-125`, `129-149`, `160-192`):
```elixir
assert {:ok, %Customer{id: "ctm_seam01", email: "ada@example.com"} = customer} =
         Paddle.Customers.create(customer_client, ...)

assert customer.raw_data == customer_payload()

assert {:ok, %Transaction{id: "txn_seam01"} = transaction} =
         Paddle.Transactions.create(transaction_create_client, ...)

assert %Checkout{url: checkout_url} = transaction.checkout
assert checkout_url == "https://checkout.paddle.com/checkout/txn_seam01"

assert {:ok,
        %Event{
          event_id: "evt_seam01",
          event_type: "transaction.completed",
          notification_id: "ntf_seam01",
          data: %{
            "id" => "txn_seam01",
            "subscription_id" => "sub_seam01",
            "checkout" => %{"url" => "https://checkout.paddle.com/checkout/txn_seam01"}
          }
        } = event} = Webhooks.parse_event(@transaction_completed_body)
```

Copy this style: pattern-match only documented tuple/struct fields, then assert a few targeted nested values and `raw_data` presence. Do not replace this with full payload equality.

**One-shot adapter client pattern** (`test/paddle/seam_test.exs:24-36`, `47-63`, `195-200`):
```elixir
customer_client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/customers"
    ...
    {request, Req.Response.new(status: 201, body: %{"data" => customer_payload()})}
  end)

defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

**Supporting analogs for sub-assertions**

- `test/paddle/transactions_test.exs:10-32`, `107-148` for typed `Transaction` + `Checkout` hydration and `raw_data` assertions.
- `test/paddle/subscriptions_test.exs:16-62`, `143-187` for typed `Subscription`, `ManagementUrls`, `ScheduledChange`, and `Page.next_cursor/1`.
- `test/paddle/webhooks_test.exs:9-15`, `17-24`, `26-107` for narrow tuple assertions around signature verification.
- `test/paddle/customers_test.exs:9-43` and `test/paddle/customers/addresses_test.exs:9-46`, `79-108` for allowlisted request-body assertions and typed resource/page checks.

---

### `guides/accrue-seam.md` (config, transform)

**Primary analog:** `guides/accrue-seam.md`

**Guide structure pattern** (`guides/accrue-seam.md:5-44`):
```markdown
## Stability Vocabulary

- `locked`: ...
- `additive`: ...
- `raw`: ...
- `not-planned`: ...

## Public Modules

### `Paddle.Customers`
- `create(client, attrs)` returns ...
...
### `Paddle.Webhooks`
- `verify_signature(...)` returns ...
```

Keep this exact high-level shape: vocabulary first, then enumerated public modules/functions, then locked structs/error contract, then exclusions. Phase 7 should update the vocabulary and boundary language in place rather than invent a new guide layout.

**Field-table pattern** (`guides/accrue-seam.md:44-116`):
```markdown
### `%Paddle.Transaction{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:status`, ... | `locked` | Typed top-level transaction fields. |
| `:checkout` | `locked` | Hydrated `%Paddle.Transaction.Checkout{}` when checkout data is present. |
| `:items`, `:details`, `:payments` | `raw` | Forwarded Paddle data; nested shape is not locked. |
| `:raw_data` | `additive` | Full payload for forward compatibility. |
```

Reuse the existing table pattern, but align terminology with the phase decisions: `opaque` instead of `raw`, and `:raw_data` should be documented as a locked field whose contents are opaque.

**Boundary / exclusions section pattern** (`guides/accrue-seam.md:117-125`):
```markdown
## Not Planned

The following areas are explicitly outside the supported Accrue seam:

- Subscription mutations beyond cancel: `update`, `pause`, `resume`
- Payment-method portal update flows beyond surfaced management URLs
...
```

Retain the explicit exclusion list pattern, but convert the heading/vocabulary to the locked Phase 7 buckets instead of `Not Planned`.

---

### `mix.exs` (config, transform)

**Primary analog:** `mix.exs`

**ExDoc extras wiring pattern** (`mix.exs:11-16`):
```elixir
docs: [
  extras: ["guides/accrue-seam.md"],
  groups_for_extras: [
    Guides: ~r/guides\//
  ]
]
```

If the planner changes docs publication behavior, extend this block rather than creating a new docs configuration style elsewhere.

---

### `README.md` (config, transform)

**Primary analog:** `README.md`

**Guide discoverability pattern** (`README.md:18-22`):
```markdown
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/paddle>.

For the Accrue-facing integration surface, see [Accrue Seam Contract](guides/accrue-seam.md).
```

Use the README only as a lightweight pointer into the canonical seam guide. Do not duplicate the full seam contract here.

---

### `lib/paddle/http.ex` (utility, request-response)

**Closest analog:** `lib/paddle/internal/attrs.ex`

**Hidden internal utility pattern to copy** (`lib/paddle/internal/attrs.ex:1-3`):
```elixir
defmodule Paddle.Internal.Attrs do
  @moduledoc false
```

`Paddle.Http` is currently source-visible and undocumented public-facing by accident (`lib/paddle/http.ex:1-29`). If Phase 7 hides it from ExDoc, copy the `@moduledoc false` pattern from hidden helper modules rather than adding narrative docs.

**Current request utility shape to preserve** (`lib/paddle/http.ex:1-14`):
```elixir
defmodule Paddle.Http do
  def request(%Paddle.Client{} = client, method, path, opts \\ []) do
    opts = Keyword.merge(opts, method: method, url: path)

    case Req.request(client.req, opts) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %Req.Response{} = resp} -> {:error, Paddle.Error.from_response(resp)}
      {:error, exception} -> {:error, exception}
    end
  end
end
```

Hide the module without changing this request/tuple behavior.

---

### `lib/paddle/http/telemetry.ex` (utility, event-driven)

**Closest analog:** `lib/paddle/internal/attrs.ex`

**Hidden helper pattern** (`lib/paddle/internal/attrs.ex:1-3`):
```elixir
defmodule Paddle.Internal.Attrs do
  @moduledoc false
```

`Paddle.Http.Telemetry` is another implementation-detail module currently lacking a hidden moduledoc marker (`lib/paddle/http/telemetry.ex:1-36`). Apply the same hide-from-docs pattern if the planner chooses source-level suppression.

**Current event hook shape to preserve** (`lib/paddle/http/telemetry.ex:1-7`, `17-34`):
```elixir
def attach(req) do
  req
  |> Req.Request.append_request_steps(paddle_telemetry_start: &telemetry_start/1)
  |> Req.Request.append_response_steps(paddle_telemetry_stop: &telemetry_stop/1)
  |> Req.Request.append_error_steps(paddle_telemetry_error: &telemetry_error/1)
end
```

Suppress docs visibility without changing the telemetry attachment API used by `Paddle.Client.new!/1`.

---

### `lib/paddle.ex` (utility, transform)

**Closest analog:** `lib/paddle/application.ex`

**Hidden root-module pattern** (`lib/paddle/application.ex:1-6`):
```elixir
defmodule Paddle.Application do
  @moduledoc false

  use Application
```

`lib/paddle.ex` is currently placeholder/generated docs (`lib/paddle.ex:1-18`):
```elixir
defmodule Paddle do
  @moduledoc """
  Documentation for `Paddle`.
  """

  def hello do
    :world
  end
end
```

If Phase 7 closes the published seam, this file should follow the hidden-module pattern or be otherwise removed from the published boundary. Do not keep placeholder docs in the consumer API reference.

---

### `lib/paddle/client.ex` (model, request-response)

**Closest analog:** `test/paddle/client_test.exs`

**Support-type contract evidence** (`test/paddle/client_test.exs:4-24`):
```elixir
assert_raise KeyError, fn ->
  Paddle.Client.new!()
end

assert %Paddle.Client{
         api_key: "sk_test_123",
         environment: :live,
         req: %Req.Request{} = req
       } = client

assert req.options.auth == {:bearer, "sk_test_123"}
assert req.options.base_url == "https://api.paddle.com"
assert req.headers["paddle-version"] == ["1"]
```

Use this test as the contract source if the planner adds inline docs or guide cross-references for `Paddle.Client.new!/1`. The repo does not yet have a public moduledoc pattern for support types.

---

### `lib/paddle/page.ex` (model, transform)

**Closest analog:** `test/paddle/page_test.exs`

**Support-type contract evidence** (`test/paddle/page_test.exs:15-27`):
```elixir
page = %Page{
  data: [],
  meta: %{"pagination" => %{"next" => "/transactions?after=cursor_123"}}
}

assert Page.next_cursor(page) == "/transactions?after=cursor_123"
assert Page.next_cursor(%Page{data: [], meta: %{}}) == nil
```

Use this as the pattern for documenting `%Paddle.Page{}` and `Paddle.Page.next_cursor/1`: narrow, behavioral, and independent from the end-to-end seam path.

---

### `lib/paddle/error.ex` (model, transform)

**Closest analog:** `test/paddle/error_test.exs`

**Support-type contract evidence** (`test/paddle/error_test.exs:12-59`):
```elixir
assert %Error{
         status_code: 422,
         request_id: "req_123",
         type: "validation_error",
         code: "invalid_field",
         message: "Email is invalid",
         errors: [%{"field" => "email", "message" => "must be present"}],
         raw: %{"error" => %{...}}
       } = Error.from_response(response)
```

If the planner adds inline docs or guide wording for `%Paddle.Error{}`, copy the exact stable fields from this test rather than broadening the contract beyond `type`, `code`, `message`, `status_code`, and `request_id`.

## Shared Patterns

### Semantic ExUnit seam assertions
**Source:** `test/paddle/seam_test.exs:38-45`, `93-102`, `137-149`, `179-192`
**Apply to:** `test/paddle/seam_test.exs`
```elixir
assert {:ok, %Transaction{id: "txn_seam01"} = transaction} = ...
assert %Checkout{url: checkout_url} = transaction.checkout
assert {:ok, %Event{event_type: "transaction.completed", data: %{"id" => "txn_seam01"}}} = ...
assert {:ok, %Subscription{scheduled_change: %ScheduledChange{action: "cancel"}}} = ...
```

This repo consistently uses pattern matching plus a few exact value checks to lock consumer-facing guarantees. Avoid full struct equality and avoid asserting undocumented nested map keys.

### Request adapter closures instead of mocks
**Source:** `test/paddle/seam_test.exs:24-36`, `195-200`; `test/paddle/customers_test.exs:13-26`; `test/paddle/subscriptions_test.exs:20-27`
**Apply to:** `test/paddle/seam_test.exs` and any supporting contract tests
```elixir
client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/customers"
    {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
  end)
```

Keep the seam test adapter-backed and deterministic. Do not introduce Mox, live HTTP, or snapshot fixtures.

### Support types are proven in focused tests, not the end-to-end seam path
**Source:** `test/paddle/client_test.exs:10-24`; `test/paddle/page_test.exs:15-27`; `test/paddle/error_test.exs:12-59`
**Apply to:** guide wording for `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, `%Paddle.Error{}`
```elixir
assert %Paddle.Client{...} = client
assert Page.next_cursor(page) == "/transactions?after=cursor_123"
assert %Error{status_code: 422, request_id: "req_123"} = Error.from_response(response)
```

Phase 7 should document these support types explicitly, but it does not need to bloat `test/paddle/seam_test.exs` to prove them.

### Hide internal modules with `@moduledoc false`
**Source:** `lib/paddle/internal/attrs.ex:1-3`; `lib/paddle/application.ex:1-6`
**Apply to:** `lib/paddle/http.ex`, `lib/paddle/http/telemetry.ex`, potentially `lib/paddle.ex`
```elixir
defmodule Paddle.Internal.Attrs do
  @moduledoc false
```

The existing repo convention for non-public modules is source visibility plus suppressed published docs.

### ExDoc extras are the publication control point for guides
**Source:** `mix.exs:11-16`; `README.md:18-22`
**Apply to:** `mix.exs`, `README.md`, `guides/accrue-seam.md`
```elixir
docs: [
  extras: ["guides/accrue-seam.md"],
  groups_for_extras: [
    Guides: ~r/guides\//
  ]
]
```

Treat the guide as canonical and the README as a pointer. Publication boundary changes should be made in `mix.exs`, not by duplicating contract content.

## No Analog Found

Files with no close consumer-facing inline-doc analog in the repo:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/paddle/client.ex` | model | request-response | The repo has contract tests for `Paddle.Client.new!/1`, but no existing public moduledoc style for support types. |
| `lib/paddle/page.ex` | model | transform | The repo has focused behavioral tests, but no established inline documentation pattern for public support structs/helpers. |
| `lib/paddle/error.ex` | model | transform | Error-field stability is asserted in tests and the guide, but there is no current source-level doc pattern to copy. |

Planner should treat guide-first documentation as the canonical pattern for these support types unless it explicitly decides to introduce a new moduledoc convention.

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`, `guides/**/*.md`, `README.md`, `mix.exs`
**Files scanned:** 42
**Pattern extraction date:** 2026-04-29
