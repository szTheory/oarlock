# Phase 27: Public Contract & Documentation Truth - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.md` | documentation | request-response | `README.md` | exact |
| `guides/getting-started.md` | documentation | request-response | `guides/getting-started.md` | exact |
| `guides/accrue-seam.md` | documentation | transform | `guides/accrue-seam.md` + `test/paddle/seam_test.exs` | exact |
| `demo/README.md` | documentation | event-driven | `demo/README.md` + `demo/lib/demo_web/controllers/webhook_controller.ex` | exact |
| `CHANGELOG.md` | documentation | batch | `CHANGELOG.md` | exact |
| `guides/telemetry.md` | documentation | event-driven | `guides/telemetry.md` | role-match |
| `test/paddle/seam_test.exs` | test | request-response | `test/paddle/seam_test.exs` | exact |
| `check_docs.exs` or new lightweight docs-truth script | utility | transform | `check_docs.exs` + `check_examples.exs` | role-match |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `prompts/oarlock-brand-book.md` | documentation reference | transform | `prompts/oarlock-brand-book.md` | exact |

## Pattern Assignments

### `README.md` (documentation, request-response)

**Analog:** `README.md`

**Boundary and first-read pattern** (lines 3-12):
```markdown
Paddle Billing for Elixir, with a deliberately small surface.

oarlock gives you typed `Paddle.*` structs, explicit `%Paddle.Client{}` passing,
and pure-function webhook verification/parsing. It does not try to be your
billing domain model, your Phoenix integration layer, or your persistence
strategy.

If you are integrating this into a SaaS app, start with
[Getting Started](guides/getting-started.md). It explains the actual user flow:
customer -> address -> transaction -> checkout -> webhook -> subscription.
```

**Supported surface summary pattern** (lines 14-25):
```markdown
## What You Can Do Today

- Create, fetch, and update Paddle customers.
- Create, fetch, list, and update customer addresses.
- Create a transaction and hand the hosted checkout URL to a browser.
- Fetch a transaction later to reconcile what happened.
- Verify and parse Paddle webhooks as pure functions.
- Fetch, list, update, pause, resume, and cancel subscriptions.
- Create customer portal sessions for signed-in self-serve billing.
- Create, fetch, list, and page through adjustments for refunds and credits.
- Read products, prices, historical events, and notification settings.
- Run local integration flows against `Paddle.MockServer` for offline development.
```

**Client and checkout example pattern** (lines 53-98):
```elixir
client =
  Paddle.Client.new!(
    api_key: System.fetch_env!("PADDLE_API_KEY"),
    environment: :sandbox
  )

case Paddle.Transactions.create(client,
       customer_id: customer.id,
       address_id: address.id,
       items: [%{price_id: "pri_monthly_123", quantity: 1}]
     ) do
  {:ok, %Paddle.Transaction{} = transaction} ->
    checkout_url = transaction.checkout.url
    # Redirect user to checkout_url
  {:error, error} ->
    raise "Failed: #{error.message}"
end
```

**Webhook security pattern** (lines 101-110):
```elixir
with {:ok, :verified} <-
       Paddle.Webhooks.verify_signature(raw_body, signature_header, secret),
     {:ok, event} <- Paddle.Webhooks.parse_event(raw_body) do
  {:ok, event}
end
```

**Links and scope pattern** (lines 118-139):
```markdown
- [Getting Started](guides/getting-started.md): the jobs-to-be-done and the
  happy path through a real SaaS integration.
- [Telemetry](guides/telemetry.md): request lifecycle events for logging and
  metrics.
- [Accrue Seam Contract](guides/accrue-seam.md): the locked consumer-facing
  contract, including supported modules, functions, and struct guarantees.
- [Demo App](demo/README.md): a Phoenix example with mock auth, webhook
  persistence, customer portal handoff, and offline test flows.
```

Apply this pattern by keeping README short, concrete, and link-driven. Add error handling and pagination examples if needed, but do not duplicate the full seam inventory.

---

### `guides/getting-started.md` (documentation, request-response)

**Analog:** `guides/getting-started.md`

**JTBD framing pattern** (lines 24-41):
```markdown
## The Happy Path

Most teams do not start with "create a subscription."

They start with: "A user wants to buy my recurring plan."

In Paddle, that story usually looks like this:

1. Create or look up a Paddle customer.
2. Attach a billing address.
3. Create a transaction for the price you want to sell.
4. Send the user to Paddle Checkout.
5. Verify the webhook when Paddle tells you payment completed.
6. Fetch the transaction if you want a fresh server-side reconciliation step.
7. Save the resulting Paddle IDs and grant access in your app.
8. Fetch or cancel the subscription later as part of account management.
```

**Typed response and local error pattern** (lines 62-75):
```elixir
case Paddle.Customers.create(client,
       email: "ada@example.com",
       name: "Ada Lovelace",
       locale: "en"
     ) do
  {:ok, %Paddle.Customer{} = customer} ->
    # Proceed with the customer
    customer

  {:error, %Paddle.Error{} = error} ->
    # Handle the error
    raise "Failed to create customer: #{error.message}"
end
```

**Pagination truth pattern** (lines 220-246):
```elixir
active_subscriptions =
  client
  |> Paddle.Subscriptions.stream(status: "active")
  |> Enum.take(100)

{:ok, subscriptions} = Paddle.Subscriptions.all(client, status: "active")

{:ok, page} = Paddle.Subscriptions.list(client, status: "active")
next_reference = Paddle.Page.next_cursor(page)
```

**App-owned persistence boundary pattern** (lines 314-328):
```markdown
If you want the shortest useful checklist, save:

- Your user/account ID
- Paddle `customer_id`
- Paddle `subscription_id` once it exists
- The most recent relevant `transaction_id`
- Enough webhook receipt data to debug support issues
```

**No direct subscription-create pattern** (lines 289-298):
```markdown
One more important truth: as of Paddle's current documentation on May 23, 2026,
subscriptions are normally created indirectly through checkout or invoicing
flows, not by calling a direct "create subscription" API. The public seam
intentionally avoids direct subscription-create helpers and checkout-start
shortcuts on the subscriptions namespace; the practical start path is still
transaction -> checkout/manual collection -> webhook + `Paddle.Transactions.get/2`
reconciliation -> `Paddle.Subscriptions.get/2`.
```

Use this file as the model for task-based docs. Keep Phoenix/Ecto examples labeled as app-owned code.

---

### `guides/accrue-seam.md` (documentation, transform)

**Analog:** `guides/accrue-seam.md`

**Closed contract pattern** (lines 8-22):
```markdown
## Boundary Policy

The published seam is **closed and explicitly enumerated**.
Only explicitly documented modules, functions, structs, and support types are supported as part of this seam.
Anything not listed here — including internal modules, helper functions, and the internals of `%Paddle.Client{}` such as `:req` — is outside the consumer contract and undocumented internals may change without notice inside the 0.x minor series.
```

**Stability vocabulary pattern** (lines 24-39):
```markdown
- `locked`: typed top-level struct fields, narrow nested typed structs that are
  part of the documented seam, and other fields consumers may safely
  pattern-match and depend on. Removal or rename within 0.x is breaking.
- `additive`: the documented contract intentionally allows growth without
  breaking existing meaning. New fields or functions may appear; existing
  documented fields remain.
- `opaque`: forwarded provider data whose internal shape is not part of the
  typed seam. Consumers may inspect it defensively, but must not depend on
  key-level stability.
```

**Public module inventory pattern** (lines 41-56):
```markdown
The supported consumer entry modules are:

- `Paddle.Customers`
- `Paddle.Customers.Addresses`
- `Paddle.Customers.PortalSessions`
- `Paddle.Transactions`
- `Paddle.Adjustments`
- `Paddle.Subscriptions`
- `Paddle.Webhooks`
- `Paddle.Products`
- `Paddle.Prices`
- `Paddle.Events`
- `Paddle.NotificationSettings`
```

**Function contract pattern** (lines 72-80):
```markdown
### `Paddle.Customers.PortalSessions`

- `create(client, customer_id, attrs \\ %{}, opts \\ [])` returns `{:ok, %Paddle.PortalSession{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / validation errors. Tier: `locked`.

### `Paddle.Transactions`

- `get(client, transaction_id)` returns `{:ok, %Paddle.Transaction{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_transaction_id}`. Tier: `locked`.
- `create(client, attrs, opts \\ [])` returns `{:ok, %Paddle.Transaction{}}`, `{:error, %Paddle.Error{}}`, or validation error atoms. Tier: `locked`.
```

**Struct field table pattern** (lines 197-211):
```markdown
### `%Paddle.Transaction{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:status`, `:customer_id`, `:address_id`, `:business_id`, `:custom_data`, `:currency_code`, `:origin`, `:subscription_id`, `:invoice_number`, `:collection_mode`, `:created_at`, `:updated_at`, `:billed_at`, `:revised_at` | `locked` | Typed top-level transaction fields. |
| `:checkout` | `locked` | Hydrated `%Paddle.Transaction.Checkout{}` when checkout data is present. |
| `:items`, `:details`, `:payments` | `opaque` | Forwarded provider data; nested shape is not part of the typed seam. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |
```

**Live inventory source:** current introspection showed:
```text
Paddle.Customers [create: 2, create: 3, get: 2, update: 3]
Paddle.Customers.Addresses [all: 2, all: 3, create: 3, create: 4, get: 3, list: 2, list: 3, stream: 2, stream: 3, update: 4]
Paddle.Customers.PortalSessions [create: 2, create: 3, create: 4]
Paddle.Transactions [create: 2, create: 3, get: 2]
Paddle.Adjustments [all: 1, all: 2, create: 2, create: 3, get: 2, list: 1, list: 2, stream: 1, stream: 2]
Paddle.Subscriptions [all: 1, all: 2, cancel: 2, cancel_immediately: 2, get: 2, list: 1, list: 2, pause: 2, pause: 3, pause_immediately: 2, pause_immediately: 3, resume: 2, resume: 3, stream: 1, stream: 2, update: 3]
Paddle.Webhooks [parse_event: 1, verify_signature: 3, verify_signature: 4]
Paddle.Products [all: 1, all: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2]
Paddle.Prices [all: 1, all: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2]
Paddle.Events [all: 1, all: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2]
Paddle.NotificationSettings [all: 1, all: 2, create: 2, create: 3, delete: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2, update: 3]
Paddle.Page [next_cursor: 1]
Paddle.Error [exception: 1, from_response: 1, from_transport: 1, message: 1]
Paddle.PortalSessions [create: 2]
```

Planner checkpoint: decide whether `Paddle.PortalSessions.create/2` is supported, legacy/compat, or hidden/deprecated. It is exported in `lib/paddle/portal_sessions.ex` lines 1-34 but absent from the seam guide.

---

### `demo/README.md` (documentation, event-driven)

**Analog:** `demo/README.md`

**Demo boundary pattern** (lines 3-8):
```markdown
This demo is a small Phoenix SaaS shell that shows how an app can use oarlock
without turning the SDK into a Phoenix or Ecto framework.

After reading this, you should be able to run the demo, sign in as the mock
merchant, trigger the checkout and portal paths, and understand which parts are
demo app code versus oarlock SDK code.
```

**Proof boundary pattern** (lines 43-61):
```markdown
## Offline Paddle Mode

The tests start `Paddle.MockServer` and point the demo client at it. For manual
experiments, start the mock server in IEx and create a client with `base_url`
set to that server:

```elixir
{:ok, _pid} = Paddle.MockServer.start_link(port: 4448)

client =
  Paddle.Client.new!(
    api_key: "sk_test_mock",
    base_url: "http://localhost:4448"
  )
```

The mock server is intentionally a development fixture, not a complete Paddle
clone. It covers the demo and SDK integration paths, but it does not model every
Paddle endpoint, error, rate-limit, or provider state transition.
```

**Webhook flow pattern** (lines 63-70):
```markdown
The webhook endpoint verifies the exact raw request body before it trusts an
event. The endpoint then stores the event and updates local subscription state.

Tests use `DemoWeb.WebhookSimulator` to send signed payloads directly into the
Phoenix endpoint. This keeps the feedback loop local while still exercising the
raw-body verification boundary.
```

**App-owned production boundary pattern** (lines 83-94):
```markdown
Do not copy this demo as a full billing system. A real app still needs its own:

- User/account model and authorization.
- Entitlement and provisioning rules.
- Durable webhook de-duplication and retry strategy.
- Operational logging and support workflows.
- Paddle sandbox/live configuration and real price IDs.
```

**Raw body implementation analog:** `demo/lib/demo_web/cache_body_reader.ex` lines 1-6:
```elixir
defmodule DemoWeb.CacheBodyReader do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
```

**Webhook controller analog:** `demo/lib/demo_web/controllers/webhook_controller.ex` lines 13-45:
```elixir
def paddle(conn, _params) do
  raw_body = conn.assigns[:raw_body]

  secret = System.get_env("PADDLE_WEBHOOK_SECRET") || "pdl_ntf_test_fallback_secret"
  signature_header = get_req_header(conn, "paddle-signature") |> List.first()

  case Paddle.Webhooks.verify_signature(raw_body, signature_header, secret) do
    {:ok, :verified} ->
      raw_json = Jason.decode!(raw_body)
      case Billing.create_webhook_event(%{
             paddle_event_id: raw_json["event_id"],
             raw_data: raw_json,
             status: "pending"
           }) do
        {:ok, event_record} ->
          process_event(event_record)
          send_resp(conn, 200, "OK")

        {:error, _changeset} ->
          send_resp(conn, 500, "Internal Server Error")
      end

    {:error, reason} ->
      Logger.warning("Webhook signature verification failed: #{inspect(reason)}")
      send_resp(conn, 401, "Unauthorized")
  end
end
```

---

### `CHANGELOG.md` (documentation, batch)

**Analog:** `CHANGELOG.md`

**Keep-a-Changelog header pattern** (lines 1-12):
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases
```

**Unreleased grouping pattern** (lines 12-28):
```markdown
## [Unreleased]

### Breaking Changes

* **`%Paddle.Error{}`**: Field `:raw` renamed to `:raw_data` for consistency with all other locked structs ...

### Added

* Docs: rewrite the README for cold-start adopters and add [`guides/getting-started.md`](guides/getting-started.md), a JTBD/user-flow guide for the current Paddle integration path.
* Docs: align README, Getting Started, Accrue seam contract, and demo runbook with the shipped SDK surface and MockServer-backed proof boundary.
```

Add a concise Phase 27 entry under `Unreleased`. Name README, Getting Started, Accrue seam contract, demo runbook, changelog, and generated docs truth. Avoid implying a new Hex major/minor release unless the package version actually changes.

---

### `guides/telemetry.md` (documentation, event-driven)

**Analog:** `guides/telemetry.md`

**Event catalog pattern** (lines 7-31):
```markdown
## Request Events

The library emits three events around network requests.

### `[:paddle, :request, :start]`

Executed immediately before the HTTP request is dispatched.

**Measurements**
- `:time` - System time in native units (`System.system_time()`).

**Metadata**
- `:request` - The `Req.Request` struct representing the outgoing request.
```

**Attach example pattern** (lines 47-72):
```elixir
defmodule MyApp.PaddleTelemetry do
  require Logger

  def handle_event([:paddle, :request, :stop], %{time: _time}, %{request: request, response: response}, _config) do
    Logger.debug("Paddle request to #{request.url} completed with status #{response.status}")
  end
end

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

If touched, keep it scoped to request lifecycle debugging and align error wording with `%Paddle.Error{}` raw provider data guidance.

---

### `test/paddle/seam_test.exs` (test, request-response)

**Analog:** `test/paddle/seam_test.exs`

**Lifecycle seam test pattern** (lines 22-44):
```elixir
test "locks the Accrue seam across the customer, checkout, webhook, and subscription lifecycle flow" do
  customer_client =
    client_with_adapter(fn request ->
      assert request.method == :post
      assert request.url.path == "/customers"

      assert decode_json_body(request.body) == %{
               "email" => "ada@example.com",
               "locale" => "en",
               "name" => "Ada Lovelace"
             }

      {request, Req.Response.new(status: 201, body: %{"data" => customer_payload()})}
    end)

  assert {:ok, %Customer{id: "ctm_seam01", email: "ada@example.com"} = customer} =
           Paddle.Customers.create(customer_client,
             email: "ada@example.com",
             name: "Ada Lovelace",
             locale: "en"
           )

  assert is_map(customer.raw_data)
```

**Webhook proof pattern** (lines 145-160):
```elixir
header = signature_header(@transaction_completed_body, @seam_secret, @seam_timestamp)

assert {:ok, :verified} =
         Webhooks.verify_signature(
           @transaction_completed_body,
           header,
           @seam_secret,
           now: @seam_timestamp
         )

assert {:ok,
        %Event{
          event_id: "evt_seam01",
          event_type: "transaction.completed",
          notification_id: "ntf_seam01"
        } = event} = Webhooks.parse_event(@transaction_completed_body)
```

**Negative contract pattern** (lines 189 and 471-481):
```elixir
refute function_exported?(Paddle.Subscriptions, :create, 2)

test "sealed modules remain undocumented" do
  for module <- [
        Paddle,
        Paddle.Http,
        Paddle.Http.Telemetry,
        Paddle.Application,
        Paddle.Internal.Attrs,
        Paddle.Internal.Pagination
      ] do
    assert {:docs_v1, _, _, _, :hidden, _, _} = Code.fetch_docs(module)
  end
end
```

**Client adapter pattern** (lines 276-283):
```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    base_url: "https://sandbox-api.paddle.com",
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end
```

For a docs-truth guard, extend this test or add a nearby test that compares a live public inventory with the seam guide. Keep it focused and avoid a broad docs generator.

---

### `check_docs.exs` or new lightweight docs-truth script (utility, transform)

**Analog:** `check_docs.exs` and `check_examples.exs`

**Loaded module discovery pattern:** `check_docs.exs` lines 3-7:
```elixir
modules =
  :code.all_loaded()
  |> Enum.map(&elem(&1, 0))
  |> Enum.filter(fn m -> String.starts_with?(to_string(m), "Elixir.Paddle") end)
```

**Docs metadata pattern:** `check_docs.exs` lines 8-32:
```elixir
Enum.each(modules, fn mod ->
  case Code.fetch_docs(mod) do
    {:docs_v1, _, _, _, :hidden, _, _} ->
      :ok
    {:docs_v1, _, _, _, _, _, docs} ->
      Enum.each(docs, fn
        {{:function, name, arity}, _, _, doc_content, _} ->
          if doc_content == :none do
            IO.puts("FAIL: #{mod}.#{name}/#{arity} missing @doc")
          else
            # Check for examples
            case doc_content do
              %{"en" => doc_str} ->
                unless String.contains?(doc_str, "## Examples") || String.contains?(doc_str, "## Example") do
                  IO.puts("FAIL: #{mod}.#{name}/#{arity} missing ## Examples in @doc")
                end
              _ ->
                IO.puts("FAIL: #{mod}.#{name}/#{arity} has unexpected doc format")
            end
          end
        _ -> :ok
      end)
    _ ->
      IO.puts("FAIL: Could not fetch docs for #{mod}")
  end
end)
```

**Application module discovery pattern:** `check_examples.exs` lines 32-38:
```elixir
defp application_modules(app) do
  Application.load(app)
  case Application.spec(app, :modules) do
    nil -> {:error, :not_found}
    modules -> {:ok, modules}
  end
end
```

If planner chooses a script, prefer this style. If planner chooses ExUnit, use the same `Code.fetch_docs/1` and `Application.spec/2` mechanics but fail with assertions.

---

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Package and docs config pattern** (lines 57-88):
```elixir
defp package do
  [
    name: "oarlock",
    licenses: ["MIT"],
    links: %{
      "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
      "Documentation" => "https://hexdocs.pm/oarlock",
      "GitHub" => @source_url
    },
    files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
  ]
end

defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    formatters: ["html"],
    extras: [
      "README.md",
      "CHANGELOG.md",
      "LICENSE",
      "guides/getting-started.md",
      "guides/telemetry.md",
      "guides/accrue-seam.md"
    ],
    groups_for_extras: [
      Guides: ~r/guides\//
    ]
  ]
end
```

If docs extras change, keep README as main and keep public guides included. `demo/README.md` is not currently an ExDoc extra.

---

### `prompts/oarlock-brand-book.md` (documentation reference, transform)

**Analog:** `prompts/oarlock-brand-book.md`

**Positioning pattern** (lines 34-51):
```markdown
What Oarlock is

* An open-source Elixir SDK/client for Paddle Billing.
* A thin integration layer over Paddle’s API.
* A library for developers who care about explicit behavior, verified webhooks, and production-safe primitives.
* A dependency that should feel natural in Phoenix, Plug, and OTP applications without requiring any of them.

What Oarlock is not

* Not an official Paddle SDK.
* Not a billing framework.
* Not an Accrue replacement.
* Not a Stripe compatibility shim.
* Not a local subscription-sync engine.
* Not a Phoenix admin panel.
* Not an Ecto schema package.
```

**Voice and vocabulary pattern** (lines 87-118):
```markdown
Use a voice that is:

1. Direct. Say what the library does.
2. Concrete. Prefer exact nouns and verbs.
3. Calm. Do not oversell.
4. Transparent. Name limitations and provider differences.
5. Helpful. Always give the next useful action.
6. Developer-respectful. Assume the reader is competent.

Use copy like:

Provider-native, not framework-opinionated.

Use the raw request body when verifying webhook signatures.

The SDK returns normalized errors, but preserves the original Paddle response for debugging.
```

**Docs rules pattern** (lines 724-791):
```markdown
Oarlock docs should be:

* example-first
* explicit about return shapes
* honest about provider differences
* careful with security-sensitive details
* useful for production debugging
* readable without reading the whole Paddle docs first
* respectful of Paddle’s terminology

Code examples should:
- be copy-pasteable
- use realistic variable names
- show `{:ok, result}` and `{:error, error}` patterns
- avoid hiding setup in unexplained helpers
- preserve raw response access where relevant
- include sandbox/live notes where needed
```

Use the brand book for wording constraints only. Do not copy its stale `Oarlock.*` namespace examples into public docs; current package modules are `Paddle.*`.

## Shared Patterns

### Explicit Client Construction
**Source:** `lib/paddle/client.ex` lines 55-77  
**Apply to:** README, Getting Started, demo README, seam examples
```elixir
def new!(opts \\ []) do
  api_key = Keyword.fetch!(opts, :api_key)
  environment = Keyword.get(opts, :environment, :sandbox)

  default_url =
    if environment == :live,
      do: "https://api.paddle.com",
      else: "https://sandbox-api.paddle.com"

  base_url = Keyword.get(opts, :base_url, default_url)

  req =
    Req.new(
      base_url: base_url,
      auth: {:bearer, api_key},
      headers: [{"Paddle-Version", "1"}],
      retry: :transient,
      max_retries: 3
    )
    |> Paddle.Http.Telemetry.attach()

  %__MODULE__{api_key: api_key, environment: environment, base_url: base_url, req: req}
end
```

### Resource Function Shape
**Source:** `lib/paddle/customers.ex` lines 73-81 and 167-174  
**Apply to:** seam function inventory and examples
```elixir
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

### Webhook Verification Before Parsing
**Source:** `lib/paddle/webhooks.ex` lines 98-123 and 159-173  
**Apply to:** all webhook docs and demo docs
```elixir
def verify_signature(raw_body, signature_header, secret_key, opts)
    when is_binary(raw_body) and is_binary(signature_header) and is_binary(secret_key) do
  with {:ok, tolerance} <- normalize_tolerance(opts[:tolerance] || @default_tolerance),
       {:ok, timestamp, signatures} <- parse_signature_header(signature_header),
       :ok <- validate_timestamp(timestamp, Keyword.get(opts, :now, System.os_time(:second)), tolerance),
       expected_digest <- expected_digest(timestamp, raw_body, secret_key),
       false <- Enum.empty?(signatures),
       true <- Enum.any?(signatures, &secure_compare_digest(expected_digest, &1)) do
    {:ok, :verified}
  else
    {:error, reason} -> {:error, reason}
    false -> {:error, :signature_mismatch}
  end
end

def parse_event(raw_body) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, %{"data" => data} = payload} when is_map(data) ->
      if valid_payload?(payload) do
        {:ok, Paddle.Http.build_struct(Paddle.Event, payload)}
      else
        {:error, :invalid_event_payload}
      end
    {:ok, _payload} -> {:error, :invalid_event_payload}
    {:error, _reason} -> {:error, :invalid_json}
  end
end
```

### Pagination Truth
**Source:** `lib/paddle/internal/pagination.ex` lines 22-57 and 117-125  
**Apply to:** README, Getting Started, seam guide
```elixir
def stream(first_page_fun, next_page_fun)
    when is_function(first_page_fun, 0) and is_function(next_page_fun, 1) do
  Stream.resource(
    fn -> {:first, first_page_fun, next_page_fun} end,
    &stream_next/1,
    fn _state -> :ok end
  )
end

def all(first_page_fun, next_page_fun)
    when is_function(first_page_fun, 0) and is_function(next_page_fun, 1) do
  reduce_pages({:first, first_page_fun, next_page_fun}, [])
end

defp raise_stream_error(%Error{} = error), do: raise(error)
defp raise_stream_error(reason) when is_atom(reason) do
  raise ArgumentError, "pagination failed with #{inspect(reason)}"
end
```

### MockServer Proof Boundary
**Source:** `lib/paddle/mock_server.ex` lines 1-22 and `demo/README.md` lines 59-61  
**Apply to:** README, Getting Started, demo README, changelog
```elixir
defmodule Paddle.MockServer do
  @moduledoc """
  A standalone Plug Router that simulates the Paddle Billing API.

  This server can be started in your application's supervision tree during
  development or testing to allow fully offline development without hitting
  the real Paddle sandbox.
  """

  use Plug.Router
```

Use wording equivalent to: MockServer-backed tests prove deterministic local SDK/demo wiring. They do not prove Paddle will create, retry, order, or deliver real provider state. Run a real sandbox checkout and webhook verification before live mode.

### ExDoc Extras
**Source:** `mix.exs` lines 70-88  
**Apply to:** docs config and validation
```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    formatters: ["html"],
    extras: [
      "README.md",
      "CHANGELOG.md",
      "LICENSE",
      "guides/getting-started.md",
      "guides/telemetry.md",
      "guides/accrue-seam.md"
    ],
    groups_for_extras: [
      Guides: ~r/guides\//
    ]
  ]
end
```

## No Analog Found

No files in scope lacked an analog. Two non-blocking cautions for the planner:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `guides/accrue-seam.md` | documentation | transform | Must reconcile `Paddle.PortalSessions.create/2` exported in `lib/paddle/portal_sessions.ex` with the canonical scoped `Paddle.Customers.PortalSessions` seam. |
| docs proof wording | documentation | event-driven | No automated proof-term assertion exists yet; planner should choose a focused grep/checklist/test for forbidden overclaim terms. |

## Metadata

**Analog search scope:** `README.md`, `CHANGELOG.md`, `guides/`, `demo/README.md`, `demo/lib/demo_web/`, `lib/paddle/`, `test/paddle/seam_test.exs`, `check_docs.exs`, `check_examples.exs`, `mix.exs`, `prompts/oarlock-brand-book.md`

**Files scanned:** 10 primary files plus public API support modules.

**Pattern extraction date:** 2026-06-24

**Validation commands for planner:** `mix test test/paddle/seam_test.exs --warnings-as-errors`, `mix test --warnings-as-errors`, `mix docs --warnings-as-errors`
