# oarlock

Paddle Billing for Elixir, with a deliberately small surface.

oarlock gives you typed `Paddle.*` structs, explicit `%Paddle.Client{}` passing,
and pure-function webhook verification/parsing. It does not try to be your
billing domain model, your Phoenix integration layer, or your persistence
strategy.

If you are integrating this into a SaaS app, start with
[Getting Started](guides/getting-started.md). It explains the actual user flow:
customer -> address -> transaction -> checkout -> webhook -> subscription.

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
- Run local integration flows against `Paddle.MockServer` for offline development
  when the optional `plug` and `bandit` dependencies are installed.

## Proof Boundary

Use the same proof ladder throughout an integration:

- Unit and contract tests prove local SDK behavior.
- `Paddle.MockServer` proves deterministic local SDK/demo wiring when optional
  `plug` and `bandit` are available. It is not live Paddle provider-state
  verification.
- Package and downstream consumer checks prove that the built package and named
  consumer seam compile and pass against this SDK; they do not prove Paddle
  provider behavior.
- Paddle sandbox checks prove real provider-state behavior only when you run
  them with real Paddle sandbox credentials.
- Hosted CI proves only the exact commit and workflow rows it actually ran; that
  authority belongs to the hosted phase and is not inferred from local output.
- Live provider verification remains your operator-owned readiness step before
  charging customers and requires live credentials and observed live behavior.

## What This Library Is For

The mental model is simple:

- Your app owns users, accounts, provisioning, entitlements, and persistence.
- Paddle owns billing state and checkout.
- oarlock is the seam between them.

That seam is intentionally narrow. It helps you talk to Paddle in idiomatic
Elixir without pulling Phoenix, Ecto, Plug, or Bandit into the core library.

## Installation

The Hex package is named `oarlock`, while the OTP app and module namespace are
still `:paddle` / `Paddle.*`.

```elixir
def deps do
  [
    {:paddle, "~> 0.1.1", hex: :oarlock}
  ]
end
```

The package runtime depends on Req `~> 0.7.4`. The supported BEAM range is
Elixir `~> 1.19`; the tracked and fully exercised toolchain is Elixir 1.19.5 / OTP 28.1.
Broader OTP combinations are not implied by the local compatibility evidence.

## Client Construction Contract

`Paddle.Client.new!/1` accepts only `:api_key`, `:environment`, and `:base_url`.
The key must be a nonblank binary, URLs must be absolute HTTP(S) URLs with a
host, and invalid input raises a value-redacted `ArgumentError` before Req
construction or network dispatch.

| Input | Result |
| --- | --- |
| No environment and no base URL | Canonical `:sandbox` client |
| `:sandbox`, with no URL or the canonical sandbox URL | Canonical `:sandbox` client |
| `:live`, with no URL or the canonical live URL | Canonical `:live` client |
| `:custom` plus an absolute HTTP(S) base URL | Explicit `:custom` client |
| Noncanonical base URL only | Inferred `:custom` client |
| Unknown/duplicate options, invalid key/URL, custom without URL, or conflicting canonical environment/URL | Secret-safe `ArgumentError` before Req construction |

## Retry, Mutation, and Inspection Safety

Safe `GET` and `HEAD` reads retry only HTTP 408, 429, 500, 502, 503, and 504
or the documented transient transport reasons `:timeout`, `:econnrefused`, and
`:closed`. The ceiling is three retries (four total attempts). A read-side 429
honors `Retry-After` only up to 60,000 ms; `retry: false` disables retries for
that call.

Every `POST`, `PATCH`, `PUT`, and `DELETE` mutation makes a single attempt.
`retry: true` is rejected before dispatch, and `idempotency_key` is unsupported:
the presence of a header would not prove provider deduplication. A mutation
transport failure or terminal HTTP 408/5xx response is returned as a
non-retryable, `ambiguous` `%Paddle.Error{}`. Reconcile with the fixed
`:lookup`, `:webhook`, and `:provider_dashboard` actions; never blindly replay
the mutation.

Inspection of capability-bearing public values retains their stored data but
renders credentials, operational URLs, transport state, and secret-capable
`raw_data` containers with the stable `[REDACTED]` marker.

## Quick Start

Create a client:

```elixir
client =
  Paddle.Client.new!(
    api_key: System.fetch_env!("PADDLE_API_KEY"),
    environment: :sandbox
  )
```

Create the customer and address you want Paddle to bill:

```elixir
{:ok, customer} =
  Paddle.Customers.create(client,
    email: "ada@example.com",
    name: "Ada Lovelace",
    locale: "en"
  )

{:ok, address} =
  Paddle.Customers.Addresses.create(client, customer.id,
    description: "Home office",
    first_line: "123 Main Street",
    city: "New York",
    postal_code: "10001",
    region: "NY",
    country_code: "US"
  )
```

Create a transaction for a recurring price, then redirect the user to the hosted
checkout URL:

```elixir
case Paddle.Transactions.create(client,
       customer_id: customer.id,
       address_id: address.id,
       items: [%{price_id: "pri_monthly_123", quantity: 1}]
     ) do
  {:ok, %Paddle.Transaction{} = transaction} ->
    checkout_url = transaction.checkout.url
    # Redirect user to checkout_url
  {:error, %Paddle.Error{} = error} ->
    raise "Failed: #{error.message}"
end
```

Later, when Paddle calls your webhook endpoint, verify the raw body before you
trust it:

```elixir
with {:ok, :verified} <-
       Paddle.Webhooks.verify_signature(raw_body, signature_header, secret),
     {:ok, event} <- Paddle.Webhooks.parse_event(raw_body) do
  {:ok, event}
end
```

For a recurring purchase, the usual app-level next step is:

1. Confirm the transaction completed.
2. Save the Paddle customer and subscription IDs against your user or account.
3. Grant access in your app.

When you need more than one page of provider state, use the pagination helpers:

```elixir
active_subscriptions =
  client
  |> Paddle.Subscriptions.stream(status: "active")
  |> Enum.take(100)

{:ok, subscriptions} = Paddle.Subscriptions.all(client, status: "active")
{:ok, page} = Paddle.Subscriptions.list(client, status: "active")
next_cursor = Paddle.Page.next_cursor(page)
```

## Guides

- [Getting Started](guides/getting-started.md): the jobs-to-be-done and the
  happy path through a real SaaS integration.
- [Telemetry](guides/telemetry.md): request lifecycle events for logging and
  metrics.
- [Accrue Seam Contract](guides/accrue-seam.md): the locked consumer-facing
  contract, including supported modules, functions, and struct guarantees.
- [Demo App](demo/README.md): a Phoenix example with mock auth, webhook
  persistence, customer portal handoff, and offline test flows.

## Current Boundary

oarlock is intentionally not:

- A Phoenix or Plug integration package.
- An Ecto schema or database sync layer.
- A billing UI or customer portal replacement.
- A complete Paddle endpoint mirror.

`Paddle.MockServer` is the one intentionally optional development/test fixture
in the package. It needs `plug` and `bandit` to serve local HTTP requests, but
the core SDK modules, webhook verification, typed resources, and Req-based HTTP
client do not require Phoenix, Ecto, Plug, or Bandit.

If you need the exact supported public surface, use the
[Accrue Seam Contract](guides/accrue-seam.md) as the source of truth.
