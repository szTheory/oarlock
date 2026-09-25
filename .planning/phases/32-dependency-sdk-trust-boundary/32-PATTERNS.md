# Phase 32: Dependency & SDK Trust Boundary - Pattern Map

**Mapped:** 2026-09-10
**Files analyzed:** 49 expected or compatibility-sensitive files
**Analogs found:** 48 / 49

The phase changes existing seams more often than it creates new ones. Existing files are therefore often their own closest structural analog. Where the current semantics are unsafe, copy only the surrounding module/test shape and replace the specifically identified behavior.

## File Classification

| New/Modified File | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config | dependency-resolution | `mix.exs` | exact/self |
| `mix.lock` | config | dependency-resolution | `mix.lock` | exact/self, generated |
| `demo/mix.exs` | config | dependency-resolution | `demo/mix.exs` | exact/self; compatibility-sensitive |
| `demo/mix.lock` | config | dependency-resolution | `demo/mix.lock` | exact/self, generated |
| `lib/paddle/client.ex` | provider/config | request-response | `lib/paddle/client.ex` | exact/self |
| `lib/paddle/http.ex` | service | request-response | `lib/paddle/http.ex` | exact/self |
| `lib/paddle/http/telemetry.ex` | middleware | event-driven | `lib/paddle/http/telemetry.ex` | exact/self |
| `lib/paddle/error.ex` | model | transform | `lib/paddle/error.ex` | exact/self |
| `lib/paddle/notification_setting.ex` | model | transform | `lib/paddle/portal_session.ex` | role-match |
| `lib/paddle/portal_session.ex` | model | transform | `lib/paddle/portal_session.ex` | exact/self |
| `lib/paddle/subscription/management_urls.ex` | model | transform | `lib/paddle/portal_session.ex` | role-match |
| `lib/paddle/transaction/checkout.ex` | model | transform | `lib/paddle/portal_session.ex` | role-match |
| `lib/paddle/adjustments.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/customers.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | exact/self |
| `lib/paddle/customers/addresses.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/customers/portal_sessions.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/events.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/internal/pagination.ex` | utility | streaming/request-response | `lib/paddle/internal/pagination.ex` | exact/self |
| `lib/paddle/notification_settings.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/portal_sessions.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/prices.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/products.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/subscriptions.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `lib/paddle/transactions.ex` | service | request-response/CRUD | `lib/paddle/customers.ex` | role + flow |
| `test/paddle/inspection_safety_test.exs` (new) | test | transform/event-driven | `test/paddle/portal_session_test.exs` + `test/paddle/http/telemetry_test.exs` | composite |
| `test/paddle/client_test.exs` | test | request-response | `test/paddle/client_test.exs` | exact/self |
| `test/paddle/http_test.exs` | test | request-response | `test/paddle/http_test.exs` | exact/self |
| `test/paddle/http/telemetry_test.exs` | test | event-driven | `test/paddle/http/telemetry_test.exs` | exact/self |
| `test/paddle/portal_session_test.exs`, `test/paddle/notification_setting_test.exs`, `test/paddle/subscription_test.exs`, `test/paddle/transaction_test.exs` | test | transform | `test/paddle/portal_session_test.exs` | exact/role-match |
| `test/paddle/adjustments_test.exs`, `test/paddle/customers/addresses_test.exs`, `test/paddle/customers/portal_sessions_test.exs`, `test/paddle/customers_test.exs`, `test/paddle/events_test.exs`, `test/paddle/notification_settings_test.exs`, `test/paddle/prices_test.exs`, `test/paddle/products_test.exs`, `test/paddle/subscriptions_test.exs`, `test/paddle/transactions_test.exs` | test | request-response/CRUD | `test/paddle/http_test.exs` | role + flow |
| `test/paddle/mock_server_test.exs`, `test/paddle/subscription_flows_test.exs` | test | request-response/integration | `test/paddle/http_test.exs` | flow-match; compatibility-sensitive |
| `test/paddle/seam_test.exs` | test | file-I/O/contract | `test/paddle/seam_test.exs` | exact/self |
| `README.md`, `guides/getting-started.md`, `guides/telemetry.md`, `guides/accrue-seam.md`, `demo/README.md`, `CHANGELOG.md` | documentation/config | file-I/O | `guides/accrue-seam.md` + `test/paddle/seam_test.exs` | composite |

Compatibility-sensitive files should be edited only when the Req 0.7.4 probe or contract update requires it. In particular, `demo/mix.exs`, MockServer tests, and subscription-flow tests belong in the proof matrix even if their contents remain unchanged.

## Pattern Assignments

### Dependency manifests and locks

**Apply to:** `mix.exs`, `mix.lock`, `demo/mix.exs`, `demo/mix.lock`

**Analog:** `mix.exs`

**Dependency declaration pattern** (lines 40-48):

```elixir
defp deps do
  [
    {:req, "~> 0.5.17"},
    {:telemetry, "~> 1.4"},
    {:plug, "~> 1.0", optional: true},
    {:bandit, "~> 1.0", optional: true},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    {:dialyxir, "~> 1.4.7", only: [:dev, :test], runtime: false}
  ]
end
```

Preserve the ordered dependency list and optional dependency flags; change only Req's constraint to the locked `~> 0.7.4` floor. Regenerate both locks using Mix. Never hand-edit lock entries. The demo consumes the tracked root package through this declaration (`demo/mix.exs` lines 61-69):

```elixir
{:telemetry_metrics, "~> 1.0"},
{:telemetry_poller, "~> 1.0"},
{:gettext, "~> 1.0"},
{:jason, "~> 1.2"},
{:dns_cluster, "~> 0.2.0"},
{:bandit, "~> 1.5"},
{:paddle, path: "../"},
{:petal_components, "~> 2.4"},
{:phoenix_test, ">= 0.4.0", only: :test, runtime: false}
```

Do not add audit tooling: the acceptance command is the built-in `mix hex.audit`.

---

### `lib/paddle/client.ex` (provider/config, request-response)

**Analog:** `lib/paddle/client.ex`

**Public type and explicit-client pattern** (lines 25-33):

```elixir
@type t :: %__MODULE__{
        api_key: String.t(),
        environment: :sandbox | :live | :custom,
        base_url: String.t(),
        req: struct()
      }

@enforce_keys [:api_key, :environment, :base_url]
defstruct [:api_key, :environment, :base_url, :req]
```

Keep this explicit struct and `new!/1`; validation belongs before `Req.new/1`. The current construction sequence is the structural analog (lines 55-76): fetch/classify inputs, derive URL, build Req, attach instrumentation, return the struct.

```elixir
def new!(opts \\ []) do
  api_key = Keyword.fetch!(opts, :api_key)
  environment = Keyword.get(opts, :environment, :sandbox)
  # derive base_url
  req =
    Req.new(base_url: base_url, auth: {:bearer, api_key}, headers: [{"Paddle-Version", "1"}],
      retry: :transient, max_retries: 3)
    |> Paddle.Http.Telemetry.attach()

  %__MODULE__{api_key: api_key, environment: environment, base_url: base_url, req: req}
end
```

Do **not** copy `Keyword.fetch!/2` failure behavior or `retry: :transient`. Replace them with the constructor decision table and secret-safe `ArgumentError` messages from research. Add a total custom `Inspect` implementation here using the redaction analog below; redact `api_key`, `base_url`, and `req` so credentialized URLs and bearer state cannot render.

**Test pattern:** `test/paddle/client_test.exs` lines 10-35 constructs a client and asserts both public classification and Req state. Expand that style into a table covering defaults, base-URL-only `:custom`, every valid explicit environment, unknown/duplicate options, blank/nonbinary keys, invalid URLs, and conflicting environment/URL pairs. For every rejected secret value, refute that the canary appears in the exception message.

---

### `lib/paddle/http.ex` and `lib/paddle/error.ex` (service/model, request-response)

**Analogs:** `lib/paddle/http.ex`, `lib/paddle/error.ex`

**Stable result normalization pattern** (`lib/paddle/http.ex` lines 10-22):

```elixir
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
```

Preserve `{:ok, value} | {:error, %Paddle.Error{}}` for provider/transport outcomes. Move method-aware retry validation and normalized operation/resource context into this central request seam. Delete the current `idempotency_key` extraction/header helpers (lines 5-8 and 25-50); they are an anti-pattern for Phase 32, not code to copy.

**Error constructor pattern** (`lib/paddle/error.ex` lines 59-84):

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

def from_transport(%Req.TransportError{reason: reason} = exception) do
  %__MODULE__{
    type: transport_type(reason),
    message: Exception.message(exception),
    network_error?: true,
    retryable?: true,
    raw_data: exception
  }
end
```

Extend this constructor family rather than inventing a new return type. Ambiguous mutations must set an explicit non-retryable ambiguity/reconciliation signal and safe operation/resource/provider request identifiers. Prefer provider body `meta.request_id`, with the existing header extraction as fallback. Make `Inspect` redact `raw_data` wholesale.

**Retry/attempt test pattern** (`test/paddle/http_test.exs` lines 198-215 and 270-308):

```elixir
{:ok, agent} = Agent.start_link(fn -> 0 end)

client =
  client_with_retry_adapter(fn request ->
    count = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

    if count == 0 do
      {request, Req.Response.new(status: 503, body: %{})}
    else
      {request, Req.Response.new(status: 200, body: %{"data" => %{}})}
    end
  end)

assert {:ok, _} = Http.request(client, :get, "/customers")
assert Agent.get(agent, & &1) == 2
```

Keep deterministic adapter-driven counting, but migrate function adapters to Req 0.7's supported shape. Build a method × status/transport × override matrix. Assert four total attempts for eligible persistent reads, one for every mutation, one when disabled, capped 429 delay behavior, terminal result, and pre-dispatch `ArgumentError` for attempts to enable mutation retries. Avoid real sleeps by injecting or otherwise controlling delays in tests.

---

### Resource request modules (service, CRUD/request-response)

**Apply to:**

- `lib/paddle/adjustments.ex`
- `lib/paddle/customers.ex`
- `lib/paddle/customers/addresses.ex`
- `lib/paddle/customers/portal_sessions.ex`
- `lib/paddle/events.ex`
- `lib/paddle/internal/pagination.ex`
- `lib/paddle/notification_settings.ex`
- `lib/paddle/portal_sessions.ex`
- `lib/paddle/prices.ex`
- `lib/paddle/products.ex`
- `lib/paddle/subscriptions.ex`
- `lib/paddle/transactions.ex`

**Analog:** `lib/paddle/customers.ex`

**Imports/types/core request pattern** (lines 25-34 and 73-80):

```elixir
alias Paddle.Client
alias Paddle.Customer
alias Paddle.Http
alias Paddle.Internal.Attrs

@type request_opt :: {:idempotency_key, String.t()} | {:retry, boolean()}

@spec create(Paddle.Client.t(), map() | keyword(), [request_opt()]) ::
        {:ok, Paddle.Customer.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
def create(%Client{} = client, attrs, opts \\ []) do
  with {:ok, attrs} <- Attrs.normalize(attrs),
       body <- Attrs.allowlist(attrs, @create_allowlist),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, "/customers", Keyword.merge([json: body], opts)) do
    {:ok, Http.build_struct(Customer, data)}
  end
end
```

Copy the aliases/spec/`with`/hydration organization. Remove `:idempotency_key` from public option types and every call path; keep only the legal per-call retry restriction. Add static `operation` and normalized `route` labels at each call site. Labels must be literals or resource-derived constants such as `:create_customer` and `/customers/:customer_id`; never derive them from the runtime URL.

**Validated path pattern** (lines 114-189): validate identifiers before dispatch, encode path segments only for the actual request URL, and keep the telemetry label static.

Pagination is a special case: `lib/paddle/internal/pagination.ex` lines 100-112 deliberately preserves provider cursor query data for dispatch. That dynamic path must never be reused as telemetry metadata; pass a static operation/route through pagination state instead.

Update the corresponding resource tests listed in File Classification to remove header-presence claims, migrate Req adapters, and assert operation labels or ambiguity behavior where appropriate.

---

### `lib/paddle/http/telemetry.ex` (middleware, event-driven)

**Analog:** `lib/paddle/http/telemetry.ex`

**Req step attachment pattern** (lines 4-9):

```elixir
def attach(req) do
  req
  |> Req.Request.append_request_steps(paddle_telemetry_start: &telemetry_start/1)
  |> Req.Request.append_response_steps(paddle_telemetry_stop: &telemetry_stop/1)
  |> Req.Request.append_error_steps(paddle_telemetry_error: &telemetry_error/1)
end
```

Keep the public event names and pipeline attachment style. Replace the payloads at lines 11-37: current metadata embeds full request/response/exception terms and is expressly forbidden. Put terminal instrumentation before Req's retry step so every physical attempt gets one start plus one stop/exception.

**Subscriber lifecycle test pattern** (`test/paddle/http/telemetry_test.exs` lines 4-21):

```elixir
setup do
  handler_id = {__MODULE__, make_ref()}

  :ok =
    :telemetry.attach_many(
      handler_id,
      [
        [:paddle, :request, :start],
        [:paddle, :request, :stop],
        [:paddle, :request, :exception]
      ],
      &__MODULE__.handle_event/4,
      self()
    )

  on_exit(fn -> :telemetry.detach(handler_id) end)
  :ok
end
```

Retain unique handler IDs and `on_exit/1` cleanup. Change assertions to exact measurement/metadata key sets and recursively reject canaries, `%Req.Request{}`, `%Req.Response{}`, exceptions, URL paths/queries, headers, bodies, `raw_data`, and identifiers. Assert paired per-attempt event counts across retries.

---

### Secret-bearing public structs (model, transform)

**Apply to:** `lib/paddle/client.ex`, `lib/paddle/notification_setting.ex`, `lib/paddle/portal_session.ex`, `lib/paddle/subscription/management_urls.ex`, `lib/paddle/transaction/checkout.ex`, `lib/paddle/error.ex`

**Analog:** `lib/paddle/portal_session.ex`

**Custom inspection pattern** (lines 32-46):

```elixir
defimpl Inspect, for: Paddle.PortalSession do
  import Inspect.Algebra

  def inspect(session, opts) do
    fields =
      session
      |> Map.from_struct()
      |> Map.replace(:urls, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.PortalSession{", to_doc(fields, opts), "}"])
  end
end
```

Use this total, explicit projection and stable `"[REDACTED]"` marker. Extend it to redact the entire `raw_data` field and every promoted capability field:

- Client: `api_key`, `base_url`, `req`.
- Notification setting: `destination`, `endpoint_secret_key`, `raw_data`.
- Portal session: `urls`, `raw_data`.
- Subscription management URLs: `update_payment_method`, `cancel`, `raw_data`.
- Transaction checkout: `url`, `raw_data`.
- Error: `raw_data`.

Do not recursively search arbitrary provider maps by key name. Stored data remains unchanged; only its inspection projection changes.

**Existing assertion style** (`test/paddle/portal_session_test.exs` lines 35-53):

```elixir
inspected = inspect(session)

assert inspected =~ "cptrsess_01hv8"
refute inspected =~ "secret=true"
assert inspected =~ "urls: \"[REDACTED]\""
```

Retain focused per-struct tests, but the new cross-struct test must hydrate realistic values through `Paddle.Http.build_struct/2`, place distinct canaries in promoted and nested `raw_data` locations, and recursively prove absence from the rendered inspection.

---

### `test/paddle/inspection_safety_test.exs` (new test, transform/event-driven)

**Composite analogs:** `test/paddle/portal_session_test.exs` and `test/paddle/http/telemetry_test.exs`

Use `ExUnit.Case, async: true`, the telemetry handler setup above, and provider-shaped fixtures passed through the real hydration path. A private recursive walker should traverse structs via `Map.from_struct/1`, maps, tuples, and lists; it should compare binary leaves against a set of unique canaries. Keep assertions about exact allowlisted telemetry keys alongside absence assertions so adding a new metadata field fails closed.

There is no existing recursive canary helper in the tracked codebase. The planner should use the research skeleton for that helper rather than copying an unrelated utility.

---

### Contract docs and migration guidance (documentation/config, file-I/O)

**Apply to:** `README.md`, `guides/getting-started.md`, `guides/telemetry.md`, `guides/accrue-seam.md`, `demo/README.md`, `CHANGELOG.md`, `test/paddle/seam_test.exs`

**Analog:** `guides/accrue-seam.md` lines 338-351

```markdown
## Proof Boundary

Use this ladder when describing evidence for the seam:

- Unit and contract tests prove local SDK behavior.
- `Paddle.MockServer` proves deterministic local SDK/demo wiring. It is a
  development fixture, not a complete Paddle clone, and MockServer-backed tests
  are not live Paddle provider-state verification.
- Paddle sandbox checks prove real provider-state behavior only when they are
  run with real Paddle sandbox credentials and documented as such.
- Live mode remains operator-owned readiness before charging customers.

Do not treat offline or MockServer-backed checks as evidence that Paddle will
create, retry, order, or deliver real provider state.
```

Preserve this vocabulary and add the missing package/downstream and hosted-CI distinctions required by D-19. Rewrite `guides/telemetry.md`; its current lines 15-41 publicly promise full transport objects. Remove the `idempotency_key` example at `guides/getting-started.md` lines 103-120 and replace it with reconciliation guidance for ambiguous mutation outcomes. Document Req `~> 0.7.4`, supported BEAM range, validation truth table, safe-read retry ceiling/cap, mutation single-attempt behavior, telemetry schema break, inspection redaction, and pre-1.0 migration impact consistently.

**Mechanical contract-test pattern** (`test/paddle/seam_test.exs` lines 643-689):

```elixir
readme = "README.md" |> File.read!() |> normalize_markdown()
getting_started = "guides/getting-started.md" |> File.read!() |> normalize_markdown()

assert readme =~ "explicit `%Paddle.Client{}` passing"
# positive contract assertions ...

for path <- @public_docs do
  body = File.read!(path)

  for claim <- unsupported_claims do
    refute Regex.match?(claim, body),
           "#{path} contains unsupported provider proof wording matching #{inspect(claim)}"
  end
end
```

Extend the existing positive-and-negative assertion style. Mechanically reject stale `idempotency_key` support, unsafe retry descriptions, raw telemetry object claims, unsupported evidence wording, and conflicting version ranges.

---

### Compatibility proof script/checklist (config/test, batch)

**Analog:** `bin/package_smoke.sh`

**Shell safety and isolated-consumer pattern** (lines 1-16 and 67-78):

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${RUNNER_TEMP:-$(mktemp -d)}"

echo "==> Building and unpacking local Hex artifact"
cd "$ROOT_DIR"
mix hex.build --unpack --output "$UNPACKED_DIR"

echo "==> Compiling fresh consumer with warnings as errors"
cd "$CONSUMER_DIR"
OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix deps.get
OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix compile --warnings-as-errors
```

If the planner creates a Phase 32 matrix runner, use `set -euo pipefail`, resolve the repository relative to the script, use isolated temporary consumers, and run named commands without masking failures. There is no locked filename for a new runner; keep this as a planner decision. The matrix must include root tests, focused adapters/telemetry, MockServer/subscription flows, Dialyzer, docs, package smoke, optional-dependency proof, demo `mix precommit`, downstream Accrue seam, and online `mix hex.audit`.

## Shared Patterns

### Explicit boundary ownership

**Source:** `lib/paddle/client.ex` and `lib/paddle/http.ex`

Client construction validates static configuration. Resource modules validate domain input and supply static operation/route labels. `Paddle.Http` alone owns dispatch, retry eligibility, attempt accounting, terminal normalization, and mutation ambiguity.

### Error handling

**Source:** `lib/paddle/http.ex` lines 10-22; `lib/paddle/error.ex` lines 59-84

All dispatched provider and transport failures converge on `%Paddle.Error{}`. Do not leak Req exceptions as the public result and do not add a second error family for ambiguous mutations.

### Validation before dispatch

**Source:** `lib/paddle/customers.ex` lines 75-80 and 179-187

Use guards/normalizers and `with` before `Http.request/4`. Invalid constructor/retry options raise secret-safe `ArgumentError`; invalid domain IDs retain the established tagged-atom errors. Adapter tests should `flunk/1` if pre-dispatch validation unexpectedly reaches transport.

### Deny-by-default observability

**Source:** `lib/paddle/portal_session.ex` lines 32-46

Telemetry is a strict allowlist of low-cardinality facts. Inspection is an explicit per-struct projection with whole-container redaction. Neither boundary may serialize transport state and hope downstream consumers filter it.

### Test isolation

**Source:** `test/paddle/http/telemetry_test.exs` lines 4-21

Use async ExUnit cases where safe, unique telemetry handler IDs, `on_exit/1` cleanup, and deterministic adapters/counters. Do not depend on real provider calls or sleep-based timing for unit behavior.

### Documentation as a tested contract

**Source:** `test/paddle/seam_test.exs` lines 643-689

Read tracked public docs from tests, normalize prose when necessary, and combine required-string assertions with forbidden-claim regexes. A MockServer or header assertion is never evidence of provider replay semantics.

## No Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `test/paddle/inspection_safety_test.exs` recursive canary walker | test utility | transform | Existing tests assert rendered redaction but contain no recursive term walker; use the research guidance. |

No fixed path exists yet for a compatibility-matrix runner or standalone migration guide. The planner may keep the matrix as plan commands and migration guidance in `CHANGELOG.md`, or create tracked files using the package-smoke/document patterns above.

## Metadata

**Analog search scope:** `lib/paddle/**`, `test/paddle/**`, root/demo Mix manifests and locks, `bin/**`, `README.md`, `demo/README.md`, `guides/**`, `CHANGELOG.md`

**Tracked-source verification:** Every named analog was confirmed by `git ls-files`; ignored `deps/`, `_build/`, `.gsd/`, and generated `doc/` trees were excluded.

**Primary analogs:** `mix.exs`, `lib/paddle/client.ex`, `lib/paddle/http.ex`, `lib/paddle/http/telemetry.ex`, `lib/paddle/portal_session.ex`; supporting tests/docs are cited for their own file types.

**Pattern extraction date:** 2026-09-10
