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
- Fetch, list, and cancel subscriptions.

## What This Library Is For

The mental model is simple:

- Your app owns users, accounts, provisioning, entitlements, and persistence.
- Paddle owns billing state and checkout.
- oarlock is the seam between them.

That seam is intentionally narrow. It helps you talk to Paddle in idiomatic
Elixir without pulling Phoenix, Plug, or Ecto into the core library.

## Installation

The Hex package is named `oarlock`, while the OTP app and module namespace are
still `:paddle` / `Paddle.*`.

```elixir
def deps do
  [
    {:paddle, "~> 0.1.0", hex: :oarlock}
  ]
end
```

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
{:ok, transaction} =
  Paddle.Transactions.create(client,
    customer_id: customer.id,
    address_id: address.id,
    items: [%{price_id: "pri_monthly_123", quantity: 1}]
  )

checkout_url = transaction.checkout.url
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

## Guides

- [Getting Started](guides/getting-started.md): the jobs-to-be-done and the
  happy path through a real SaaS integration.
- [Accrue Seam Contract](guides/accrue-seam.md): the locked consumer-facing
  contract, including supported modules, functions, and struct guarantees.

## Current Boundary

oarlock is intentionally not:

- A Phoenix or Plug integration package.
- An Ecto schema or database sync layer.
- A billing UI or customer portal replacement.
- A complete Paddle endpoint mirror.

If you need the exact supported public surface, use the
[Accrue Seam Contract](guides/accrue-seam.md) as the source of truth.
