# Phase 30: close-gap-docs-02-proof-02-demo-checkout-handoff-proof - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `demo/lib/demo_web/live/admin_live/index.ex` | component / LiveView | event-driven + request-response | `demo/lib/demo_web/live/admin_live/index.ex` | exact |
| `demo/test/demo_web/live/admin_live_test.exs` | test | event-driven + request-response | `demo/test/demo_web/integration/billing_flow_test.exs` + `demo/test/support/conn_case.ex` | role-match |
| `demo/test/demo_web/integration/billing_flow_test.exs` | test | event-driven + request-response | `demo/test/demo_web/integration/billing_flow_test.exs` | exact |
| `demo/test/support/webhook_simulator.ex` / fixtures if adjusted | test utility | event-driven + request-response | `demo/test/support/webhook_simulator.ex` + `demo/test/support/fixtures/billing_fixtures.ex` | exact |
| `demo/README.md` | docs | transform | `demo/README.md` | exact |
| `.planning/EVIDENCE.md` | docs | transform | `.planning/EVIDENCE.md` + `.planning/phases/29-gsd-state-reconciliation/29-PATTERNS.md` | exact |
| `.github/workflows/ci.yml` or Phase 30 verification summary references | config / evidence | batch | `.github/workflows/ci.yml` + `.planning/phases/28-ci-demo-and-package-proof/28-PATTERNS.md` | exact |

## Pattern Assignments

### `demo/lib/demo_web/live/admin_live/index.ex` (component / LiveView, event-driven + request-response)

**Analog:** `demo/lib/demo_web/live/admin_live/index.ex`

**Imports and module pattern** (lines 1-3):
```elixir
defmodule DemoWeb.AdminLive.Index do
  use DemoWeb, :live_view
  require Logger
```

**Template hook and event names pattern** (lines 7-10, 76-98):
```elixir
<div
  id="admin-shell"
  phx-hook="PaddleCheckout"
  class="min-h-screen bg-gray-100 dark:bg-gray-900 flex"
>

<.button
  phx-click="open_portal"
  color="white"
  variant="outline"
  disabled={@portal_loading}
>
  {if @portal_loading, do: "Loading...", else: "Manage Subscription"}
</.button>

<.button phx-click="subscribe_now" color="primary" disabled={@checkout_loading}>
  {if @checkout_loading, do: "Loading...", else: "Subscribe Now"}
</.button>
```

Planner notes:
- If copy changes are needed, preserve provider-native language: checkout should become "Start checkout" or "Continue to Paddle Checkout"; portal should become "Manage billing" or "Open Paddle portal".
- Add stable button IDs if direct LiveView tests need selectors; `demo/AGENTS.md` says LiveView tests should reference key element IDs.
- Preserve the external `PaddleCheckout` hook shape; do not add inline scripts.

**Mount and PubSub refresh pattern** (lines 110-127):
```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(Demo.PubSub, "subscriptions:#{socket.assigns.current_user.id}")
  end

  socket =
    socket
    |> assign(:layout, false)
    |> assign(:checkout_loading, false)
    |> assign(:portal_loading, false)
    |> load_subscription()

  {:ok, socket, layout: false}
end

def handle_info(:subscription_updated, socket) do
  {:noreply, load_subscription(socket)}
end
```

**Portal handoff pattern** (lines 129-156):
```elixir
def handle_event("open_portal", _, socket) do
  socket = assign(socket, :portal_loading, true)

  base_url_opt =
    if url = Application.get_env(:demo, :paddle_base_url), do: [base_url: url], else: []

  client =
    Paddle.Client.new!(
      [api_key: System.get_env("PADDLE_API_KEY") || "pdl_sandbox_test_token"] ++ base_url_opt
    )

  case Paddle.PortalSessions.create(client, %{
         "customer_id" => socket.assigns.subscription.paddle_customer_id
       }) do
    {:ok, %Paddle.PortalSession{} = session} ->
      {:noreply, redirect(socket, external: session.urls["general"]["url"])}

    {:error, error} ->
      Logger.error("Portal generation failed: #{inspect(error)}")

      socket =
        socket
        |> assign(:portal_loading, false)
        |> put_flash(:error, "Failed to load customer portal.")

      {:noreply, socket}
  end
end
```

**Checkout handoff pattern and known fix point** (lines 159-199):
```elixir
def handle_event("subscribe_now", _, socket) do
  socket = assign(socket, :checkout_loading, true)

  base_url_opt =
    if url = Application.get_env(:demo, :paddle_base_url), do: [base_url: url], else: []

  client =
    Paddle.Client.new!(
      [api_key: System.get_env("PADDLE_API_KEY") || "pdl_sandbox_test_token"] ++ base_url_opt
    )

  price_id = System.get_env("PADDLE_TEST_PRICE_ID") || "pri_01j00000000000000000000000"

  case Paddle.Transactions.create(client, %{
         items: [%{price_id: price_id, quantity: 1}],
         custom_data: %{"mock_user_id" => socket.assigns.current_user.id}
       }) do
    {:ok, %Paddle.Transaction{} = txn} ->
      socket =
        socket
        |> assign(:checkout_loading, false)
        |> push_event("open_checkout", %{url: txn.checkout.url})

      {:noreply, socket}

    {:error, error} ->
      Logger.error("Checkout creation failed: #{inspect(error)}")

      socket =
        socket
        |> assign(:checkout_loading, false)
        |> put_flash(:error, "Failed to initialize checkout.")

      {:noreply, socket}
  end
end
```

Planner note: `Paddle.Transactions.create/3` currently requires `customer_id`, `address_id`, and `items`; Phase 30 should make this demo-owned call satisfy the SDK contract rather than weakening SDK validation.

---

### `demo/test/demo_web/live/admin_live_test.exs` (test, event-driven + request-response)

**Analog:** `demo/test/demo_web/integration/billing_flow_test.exs` plus `demo/test/support/conn_case.ex`

**Test module setup pattern** (`billing_flow_test.exs` lines 1-5; `conn_case.ex` lines 20-37):
```elixir
defmodule DemoWeb.Integration.BillingFlowTest do
  use DemoWeb.ConnCase, async: false
  import PhoenixTest

  alias DemoWeb.WebhookSimulator
end
```

```elixir
using do
  quote do
    @endpoint DemoWeb.Endpoint

    use DemoWeb, :verified_routes

    import Plug.Conn
    import Phoenix.ConnTest
    import DemoWeb.ConnCase
  end
end

setup tags do
  Demo.DataCase.setup_sandbox(tags)
  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

Planner notes:
- New direct LiveView tests should `use DemoWeb.ConnCase, async: false` and `import Phoenix.LiveViewTest`.
- The existing `ConnCase` already imports `Phoenix.ConnTest`; use it to post login and mount `/admin`.
- Prefer rendered element selectors and outcomes, not direct `handle_event/3` calls.

**Existing login journey pattern** (`billing_flow_test.exs` lines 15-23, 61-66):
```elixir
session =
  conn
  |> visit("/login")
  |> click_button("Login as Demo Merchant")
  |> assert_path("/admin")
  |> assert_has("h1", text: "Dashboard")
  |> assert_has("h3", text: "No Active Subscription")
  |> assert_has("button", text: "Subscribe Now")
```

For direct `Phoenix.LiveViewTest`, copy the same auth path using `Phoenix.ConnTest.post/3` or rendered login submit, then `live(conn, "/admin")`.

**MockServer test startup pattern** (`demo/test/test_helper.exs` lines 1-6):
```elixir
{:ok, _pid} = Paddle.MockServer.start_link(port: 4448)
Application.put_env(:demo, :paddle_base_url, "http://localhost:4448")

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Demo.Repo, :manual)
```

**Checkout push-event assertion target** (`admin_live/index.ex` lines 181-187; `fixtures.ex` lines 79-80):
```elixir
{:ok, %Paddle.Transaction{} = txn} ->
  socket =
    socket
    |> assign(:checkout_loading, false)
    |> push_event("open_checkout", %{url: txn.checkout.url})
```

```elixir
"checkout" => %{
  "url" => "https://sandbox-checkout.paddle.com/mock-checkout-url"
},
```

Planner action: assert `assert_push_event(view, "open_checkout", %{url: "https://sandbox-checkout.paddle.com/mock-checkout-url"})` after clicking the rendered checkout button.

**Portal redirect assertion target** (`admin_live/index.ex` lines 140-145; `fixtures.ex` lines 87-95):
```elixir
case Paddle.PortalSessions.create(client, %{
       "customer_id" => socket.assigns.subscription.paddle_customer_id
     }) do
  {:ok, %Paddle.PortalSession{} = session} ->
    {:noreply, redirect(socket, external: session.urls["general"]["url"])}
```

```elixir
def portal_session(customer_id \\ "ctm_mock123") do
  %{
    "id" => "pts_mock123",
    "customer_id" => customer_id,
    "urls" => %{
      "general" => %{
        "url" => "https://sandbox-my.paddle.com/mock-portal-session"
      }
    },
```

Planner action: seed or create an active subscription for `mock-merchant-123`, mount `/admin`, click the portal button, and assert the external redirect URL.

---

### `demo/test/demo_web/integration/billing_flow_test.exs` (test, event-driven + request-response)

**Analog:** `demo/test/demo_web/integration/billing_flow_test.exs`

**Readable PhoenixTest journey pattern** (lines 7-23):
```elixir
test "E2E Billing Flow: User signs in, intends to checkout, and real-time UI updates on webhook",
     %{conn: conn} do
  conn
  |> visit("/admin")
  |> assert_path("/login")

  session =
    conn
    |> visit("/login")
    |> click_button("Login as Demo Merchant")
    |> assert_path("/admin")
    |> assert_has("h1", text: "Dashboard")
    |> assert_has("h3", text: "No Active Subscription")
    |> assert_has("button", text: "Subscribe Now")
```

**Signed webhook simulation pattern** (lines 29-57):
```elixir
webhook_payload = %{
  "id" => "sub_test_e2e_123",
  "status" => "active",
  "customer_id" => "ctm_test_123",
  "current_billing_period" => %{
    "starts_at" => "2026-06-11T12:00:00.000000Z",
    "ends_at" => "2026-07-11T12:00:00.000000Z"
  },
  "custom_data" => %{
    "mock_user_id" => "mock-merchant-123"
  }
}

WebhookSimulator.post_webhook(
  build_conn(),
  "/webhooks/paddle",
  "subscription.created",
  webhook_payload
)

session
|> assert_has("h3", text: "Subscription Active")
|> assert_has("button", text: "Manage Subscription")
|> refute_has("button", text: "Subscribe Now")
```

**Current weak checkout proof to replace or supplement** (lines 67-73):
```elixir
session =
  session
  |> click_button("Subscribe Now")
  # unhandled pushes are silently swallowed or returned. We just ensure it doesn't crash.
  |> assert_path("/admin")
```

Planner action: keep PhoenixTest as the readable journey, but do not rely on it for checkout proof. Add direct `Phoenix.LiveViewTest` coverage for the pushed `open_checkout` event.

**Portal journey pattern** (lines 94-98):
```elixir
session
|> assert_has("button", text: "Manage Subscription")
|> click_button("Manage Subscription")
|> assert_path("/mock-portal-session")
```

Planner action: direct LiveViewTest should assert the external redirect; PhoenixTest can remain the user-journey smoke.

---

### `demo/test/support/webhook_simulator.ex` / fixtures if adjusted (test utility, event-driven + request-response)

**Analogs:** `demo/test/support/webhook_simulator.ex`, `demo/test/support/fixtures/billing_fixtures.ex`

**Signed webhook helper pattern** (`webhook_simulator.ex` lines 11-39):
```elixir
def post_webhook(conn, path, event_type, payload_data) do
  secret = System.get_env("PADDLE_WEBHOOK_SECRET") || "pdl_ntf_test_fallback_secret"

  payload_wrapper = %{
    "event_id" => "evt_#{System.unique_integer()}",
    "event_type" => event_type,
    "occurred_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
    "notification_id" => "ntf_#{System.unique_integer()}",
    "data" => payload_data
  }

  raw_body = Jason.encode!(payload_wrapper)

  ts = System.system_time(:second)
  h1 = :crypto.mac(:hmac, :sha256, secret, "#{ts}:#{raw_body}") |> Base.encode16(case: :lower)
  signature = "ts=#{ts};h1=#{h1}"

  conn
  |> assign(:raw_body, raw_body)
  |> put_req_header("paddle-signature", signature)
  |> put_req_header("content-type", "application/json")
  |> Phoenix.ConnTest.dispatch(DemoWeb.Endpoint, :post, path, raw_body)
end
```

**Subscription fixture pattern** (`billing_fixtures.ex` lines 40-52):
```elixir
def subscription_fixture(attrs \\ %{}) do
  {:ok, subscription} =
    attrs
    |> Enum.into(%{
      current_period_end: ~U[2026-06-10 16:01:00Z],
      mock_user_id: unique_subscription_mock_user_id(),
      paddle_customer_id: "some paddle_customer_id",
      paddle_subscription_id: "some paddle_subscription_id",
      status: "some status"
    })
    |> Demo.Billing.create_subscription()

  subscription
end
```

Planner action: use this fixture for portal tests if a direct seed is clearer than simulating webhook setup. Override at least `mock_user_id: "mock-merchant-123"`, `status: "active"`, `paddle_customer_id: "ctm_mock123"`, and a current/future `current_period_end`.

---

### `demo/README.md` (docs, transform)

**Analog:** `demo/README.md`

**Demo boundary and capability list pattern** (lines 3-22):
```markdown
This demo is a small Phoenix SaaS shell that shows how an app can use oarlock
without turning the SDK into a Phoenix or Ecto framework.

After reading this, you should be able to run the demo, sign in as the mock
merchant, trigger the checkout and portal paths, and understand which parts are
demo app code versus oarlock SDK code.

## What It Demonstrates

- Mock authentication around an `/admin` dashboard.
- A server-side checkout handoff using `Paddle.Transactions.create/3`.
- Raw-body webhook verification through `Paddle.Webhooks`.
- Webhook inbox persistence before business logic runs.
- Local subscription state updated from signed Paddle-style webhook events.
- Customer portal handoff through oarlock.
```

**Proof ladder pattern** (lines 69-78):
```markdown
The proof ladder is:

- Unit and contract tests prove local SDK behavior.
- `Paddle.MockServer` proves deterministic local SDK/demo wiring.
- Paddle sandbox checks prove real provider-state behavior only when real Paddle
  sandbox credentials are used.
- Live mode is operator-owned readiness before charging customers.

MockServer-backed demo tests are not live Paddle provider-state verification.
```

**Webhook boundary pattern** (lines 81-91):
```markdown
The webhook endpoint verifies the exact raw request body before it trusts an
event. The endpoint then stores the event and updates local subscription state.

Tests use `DemoWeb.WebhookSimulator` to send signed payloads directly into the
Phoenix endpoint. This keeps the feedback loop local while still exercising the
raw-body verification boundary.

The raw-body cache reader, controller, inbox table, and subscription state
updates are demo Phoenix/Ecto code. They show one app-owned shape for webhook
processing; they are not core SDK routes, schemas, migrations, or provisioning
policy.
```

**Portal handoff pattern** (lines 93-99):
```markdown
## Portal Handoff

The dashboard's manage-subscription action creates a Paddle portal session for
the signed-in demo merchant and redirects to a Paddle-hosted URL. In a real app,
authorize the signed-in user before creating a portal session, store any audit
record you need, and treat the returned URL as an operational handoff rather
than durable state.
```

Planner notes:
- Public docs should change only if they overclaim or underspecify Phase 30 proof.
- Do not paste local command transcripts or CI logs into public docs.
- Update line 109-110 only if the strengthened proof changes the exact wording needed for checkout/portal coverage.

---

### `.planning/EVIDENCE.md` (docs, transform)

**Analog:** `.planning/EVIDENCE.md`

**Ledger table pattern** (lines 5-18):
```markdown
## v2.0 and v2.1 Requirement Evidence

| Requirement | Artifact | Evidence Class | Command / Proof | Caveat |
|-------------|----------|----------------|-----------------|--------|
| DOCS-02 | `.planning/phases/27-public-contract-documentation-truth/27-02-SUMMARY.md` | Public documentation runbook proof | README, Getting Started, and demo runbook updates describe local setup, mock auth, webhook processing, portal handoff, and Offline Mode | Demo runbook describes MockServer/offline proof boundaries; live Paddle readiness remains operator-owned |
| PROOF-02 | `.planning/phases/28-ci-demo-and-package-proof/28-VALIDATION.md`; `.planning/phases/28-ci-demo-and-package-proof/28-02-SUMMARY.md` | Demo PostgreSQL CI proof | Demo test job with PostgreSQL service is tracked as Phase 28 proof work | Local machines may not exactly match GitHub service-container networking |
```

**Proof-class rules pattern** (lines 24-29):
```markdown
## Proof-Class Rules

- `VALIDATION.md` can be real proof even when a standard `VERIFICATION.md` filename is absent. The caveat is artifact-standard drift, not missing evidence.
- MockServer-backed integration proof demonstrates deterministic local SDK/demo behavior. It does not prove Paddle sandbox/live provider state.
- Sandbox/live provider-state proof requires real credentials, isolated provider state, and a separately recorded command or run artifact.
- Planning reconciliation evidence proves repository memory and release posture, not new SDK runtime behavior.
```

Planner action: update DOCS-02/PROOF-02 rows or add a dated Phase 30 addendum. Include the strengthened proof class, exact local command, and hosted CI caveat/run URL if available. Do not claim hosted GitHub Actions passed without an exact relevant run.

---

### `.github/workflows/ci.yml` or Phase 30 verification summary references (config / evidence, batch)

**Analog:** `.github/workflows/ci.yml`

**Demo PostgreSQL job pattern** (lines 119-178):
```yaml
demo-postgres:
  name: demo PostgreSQL
  runs-on: ubuntu-latest
  env:
    MIX_ENV: test
    DB_HOST: localhost
  services:
    postgres:
      image: postgres:17
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: postgres
      ports:
        - 5432:5432
      options: >-
        --health-cmd "pg_isready -U postgres"
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5

  - name: Compile demo (warnings as errors)
    working-directory: demo
    run: mix compile --warnings-as-errors

  - name: Run demo tests
    working-directory: demo
    run: mix test
```

**CI contract proof pattern** (lines 234-277):
```yaml
ci-contract:
  name: CI contract
  runs-on: ubuntu-latest
  needs:
    - test
    - dialyzer
    - demo-postgres
    - package-smoke
    - optional-deps
  if: ${{ always() }}
  steps:
    - name: Assert required CI jobs passed
      env:
        NEEDS_JSON: ${{ toJson(needs) }}
        GITHUB_SHA_VALUE: ${{ github.sha }}
        GITHUB_WORKFLOW_VALUE: ${{ github.workflow }}
        GITHUB_RUN_ID_VALUE: ${{ github.run_id }}
        GITHUB_RUN_ATTEMPT_VALUE: ${{ github.run_attempt }}
      run: |
        node <<'NODE'
        const needs = JSON.parse(process.env.NEEDS_JSON);
        const required = ["test", "dialyzer", "demo-postgres", "package-smoke", "optional-deps"];
        const jobs = required.map((id) => ({
          id,
          result: needs[id] && needs[id].result,
        }));
        const failed = jobs.filter((job) => job.result !== "success");
```

Planner notes:
- Phase 30 should not need workflow changes unless test command coverage needs adjustment; current `demo-postgres` runs all demo tests.
- Verification/summary artifacts should record local command output and hosted status separately.
- If no pushed run exists for the relevant SHA, record that explicitly in `.planning/EVIDENCE.md` and phase summary.

## Shared Patterns

### Raw-Body Webhook Security Boundary
**Source:** `demo/lib/demo_web/endpoint.ex`, `demo/lib/demo_web/cache_body_reader.ex`, `demo/lib/demo_web/controllers/webhook_controller.ex`
**Apply to:** demo webhook docs, integration tests, evidence wording

`demo/lib/demo_web/endpoint.ex` lines 46-50:
```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {DemoWeb.CacheBodyReader, :read_body, []},
  json_decoder: Phoenix.json_library()
```

`demo/lib/demo_web/cache_body_reader.ex` lines 1-7:
```elixir
defmodule DemoWeb.CacheBodyReader do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
```

`demo/lib/demo_web/controllers/webhook_controller.ex` lines 13-22:
```elixir
def paddle(conn, _params) do
  raw_body = conn.assigns[:raw_body]

  secret = System.get_env("PADDLE_WEBHOOK_SECRET") || "pdl_ntf_test_fallback_secret"
  signature_header = get_req_header(conn, "paddle-signature") |> List.first()

  case Paddle.Webhooks.verify_signature(raw_body, signature_header, secret) do
    {:ok, :verified} ->
```

### Subscription Projection and PubSub Refresh
**Source:** `demo/lib/demo_web/controllers/webhook_controller.ex`
**Apply to:** PhoenixTest journey and any direct LiveView portal setup decisions

Lines 89-111:
```elixir
mock_user_id = Map.get(sub["custom_data"] || %{}, "mock_user_id")

if mock_user_id do
  attrs = %{
    mock_user_id: mock_user_id,
    paddle_customer_id: sub["customer_id"],
    paddle_subscription_id: sub["id"],
    status: sub["status"],
    current_period_end: get_in(sub, ["current_billing_period", "ends_at"])
  }

  case Repo.get_by(Demo.Billing.Subscription, mock_user_id: mock_user_id) do
    nil -> Billing.create_subscription(attrs)
    existing -> Billing.update_subscription(existing, attrs)
  end

  Phoenix.PubSub.broadcast(
    Demo.PubSub,
    "subscriptions:#{mock_user_id}",
    :subscription_updated
  )
```

### SDK Transaction Validation Contract
**Source:** `lib/paddle/transactions.ex`
**Apply to:** demo checkout fix and checkout handoff tests

Lines 120-130:
```elixir
def create(%Client{} = client, attrs, opts \\ []) do
  with {:ok, attrs} <- Attrs.normalize(attrs),
       {:ok, customer_id} <- validate_customer_id(attrs),
       {:ok, address_id} <- validate_address_id(attrs),
       {:ok, items} <- validate_items(attrs),
       {:ok, custom_data} <- validate_custom_data(attrs),
       {:ok, checkout} <- validate_checkout(attrs),
       body <- build_body(customer_id, address_id, items, custom_data, checkout),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, "/transactions", Keyword.merge([json: body], opts)) do
    {:ok, build_transaction(data)}
  end
end
```

Lines 134-143:
```elixir
defp build_body(customer_id, address_id, items, custom_data, checkout) do
  %{
    "customer_id" => customer_id,
    "address_id" => address_id,
    "items" => items,
    "collection_mode" => "automatic"
  }
  |> maybe_put("custom_data", custom_data)
  |> maybe_put("checkout", checkout)
end
```

### Client-Side Checkout Hook Boundary
**Source:** `demo/assets/js/app.js`
**Apply to:** docs/evidence wording; not browser-tested in Phase 30

Lines 28-36:
```javascript
const Hooks = {}

Hooks.PaddleCheckout = {
  mounted() {
    this.handleEvent("open_checkout", ({ url }) => {
      // Open the Paddle checkout overlay using the backend-generated URL
      Paddle.Checkout.open({ settings: { displayMode: "overlay" }, transactionId: url.split("=")[1] || url })
    })
  }
}
```

Planner note: Phase 30 should prove the server pushes `open_checkout`; browser-level JavaScript proof is explicitly out of scope.

### Verification Command Pattern
**Source:** `.planning/phases/30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof/30-VALIDATION.md`
**Apply to:** phase plans and summary

Lines 12-18:
```markdown
| **Framework** | ExUnit, Phoenix.LiveViewTest, PhoenixTest |
| **Config file** | `demo/config/test.exs` |
| **Quick run command** | `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs` |
| **Full suite command** | `cd demo && mix precommit` |
| **Estimated runtime** | ~60-180 seconds |
```

## No Analog Found

All expected Phase 30 files have close analogs in the codebase. No new framework, dependency, browser automation suite, or live Paddle provider-state proof pattern is needed.

## Metadata

**Analog search scope:** `demo/lib`, `demo/test`, `demo/assets`, `lib/paddle`, `.planning`, `.github/workflows`  
**Files scanned:** 40+ via `rg --files`, targeted `rg`, and line-numbered reads  
**Pattern extraction date:** 2026-06-25
