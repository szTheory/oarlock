# oarlock Phoenix Demo

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
- Offline development against `Paddle.MockServer` with the optional `plug` and
  `bandit` dependencies available in the demo/test dependency set.

The demo owns users, database tables, PubSub updates, and UI state. oarlock only
owns the Paddle client seam.

The mock login is intentionally local: it signs you in as a fixed demo merchant
so the checkout, webhook, subscription, and portal paths can be exercised without
adding an authentication system to the SDK.

## Run Locally

From the repository root:

```sh
cd demo
mix setup
mix phx.server
```

Open `http://localhost:4000/login`, then choose the demo merchant login. The
admin dashboard is at `http://localhost:4000/admin`.

By default the demo uses local development configuration. If PostgreSQL is not
on `localhost`, set `DB_HOST` before running setup or tests:

```sh
DB_HOST=db mix setup
```

## Offline Paddle Mode

The tests start `Paddle.MockServer` and point the demo client at it. The demo
includes the optional `plug` and `bandit` dependencies needed to run those
MockServer-backed tests. For manual experiments, start the mock server in IEx
and create a client with `base_url` set to that server:

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

The proof ladder is:

- Unit and contract tests prove local SDK behavior.
- `Paddle.MockServer` proves deterministic local SDK/demo wiring.
- Paddle sandbox checks prove real provider-state behavior only when real Paddle
  sandbox credentials are used.
- Live mode is operator-owned readiness before charging customers.

MockServer-backed demo tests are not live Paddle provider-state verification.

## Webhook Flow

The webhook endpoint verifies the exact raw request body before it trusts an
event. The endpoint then stores the event and updates local subscription state.

Tests use `DemoWeb.WebhookSimulator` to send signed payloads directly into the
Phoenix endpoint. This keeps the feedback loop local while still exercising the
raw-body verification boundary.

The raw-body cache reader, controller, inbox table, and subscription state
updates are demo Phoenix/Ecto code. They show one app-owned shape for webhook
processing; they are not core SDK routes, schemas, migrations, or provisioning
policy.

## Portal Handoff

The dashboard's manage-subscription action creates a Paddle portal session for
the signed-in demo merchant and redirects to a Paddle-hosted URL. In a real app,
authorize the signed-in user before creating a portal session, store any audit
record you need, and treat the returned URL as an operational handoff rather
than durable state.

## Tests

Run the demo test suite from this directory:

```sh
mix test
```

The integration tests cover the mock login, dashboard state, signed webhook
processing, subscription UI update, checkout handoff path, and portal handoff.

## Production Boundary

Do not copy this demo as a full billing system. A real app still needs its own:

- User/account model and authorization.
- Entitlement and provisioning rules.
- Durable webhook de-duplication and retry strategy.
- Operational logging and support workflows.
- Paddle sandbox/live configuration and real price IDs.

## Before Live Mode

Before charging customers with a real app:

- Configure real Paddle price IDs for the environment you are testing.
- Complete a sandbox checkout using real sandbox credentials.
- Configure the Paddle webhook destination and endpoint secret.
- Verify the exact raw request body before parsing or trusting events.
- Make webhook handling idempotent for duplicate delivery and retries.
- Keep sandbox and live credentials, secrets, and price IDs separated.
- Perform the final live credential swap as an operator-owned release step.

Use this demo to understand where oarlock fits in a Phoenix app, then adapt the
boundaries to your own product.
