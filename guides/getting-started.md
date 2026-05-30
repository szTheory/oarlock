# Getting Started with oarlock

This guide is for the Elixir or Phoenix engineer who wants to wire Paddle into
a SaaS app without reverse-engineering the library first.

After reading it, you should be able to take a user from "starts checkout" to
"has access in my app" and know exactly which parts belong to Paddle, which
parts belong to oarlock, and which parts still belong to you.

## The One-Sentence Mental Model

oarlock is not your billing brain.

It is your Elixir-shaped seam into Paddle:

- `Paddle.Client` knows how to talk to Paddle.
- `Paddle.*` structs give you typed responses instead of loose maps.
- `Paddle.Webhooks` lets you verify and parse incoming events safely.

Everything else that makes your SaaS feel like a product is still yours:
users, accounts, access control, data models, retries at the app boundary,
audit trails, and support workflows.

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

That is the flow oarlock supports well today.

## Job 1: Start Billing Without Owning Checkout

The job is not "call `create/2` everywhere."

The real job is: "I want a user to pay for a recurring plan, and I do not want
to build card collection, tax handling, and payment orchestration myself."

Start by building a client:

```elixir
client =
  Paddle.Client.new!(
    api_key: System.fetch_env!("PADDLE_API_KEY"),
    environment: :sandbox
  )
```

Then create the customer you want Paddle to know about:

```elixir
{:ok, customer} =
  Paddle.Customers.create(client,
    email: "ada@example.com",
    name: "Ada Lovelace",
    locale: "en"
  )
```

Then attach the address Paddle needs for billing and tax:

```elixir
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

Now create the transaction:

```elixir
{:ok, transaction} =
  Paddle.Transactions.create(client,
    customer_id: customer.id,
    address_id: address.id,
    items: [%{price_id: "pri_monthly_123", quantity: 1}]
  )
```

If Paddle returns checkout data, you now have the next move:

```elixir
checkout_url = transaction.checkout.url
```

Send the browser there. That is the handoff. Your app stops pretending it is a
payment processor and Paddle takes over.

### What your app should persist here

- Your user/account ID -> `customer.id`
- The billing address ID if you plan to reuse it
- The initial `transaction.id`
- Any internal purchase intent or checkout session record you use for support

### Why this flow matters

This is where the library earns its keep. You stay in plain Elixir, but you do
not have to model Paddle's raw JSON by hand.

## Job 2: Trust the Webhook Before You Trust the Purchase

The moment of truth is not "the user saw a success page."

The moment of truth is "Paddle sent me an event I can verify."

oarlock keeps that boundary pure:

```elixir
with {:ok, :verified} <-
       Paddle.Webhooks.verify_signature(raw_body, signature_header, secret),
     {:ok, event} <- Paddle.Webhooks.parse_event(raw_body) do
  {:ok, event}
end
```

Two practical rules matter here:

- Use the raw request body. Signature verification depends on exact bytes.
- Do not grant access before verification succeeds.

For recurring billing, `transaction.completed` is the event that usually moves
your app from "checkout happened" to "fulfill the purchase." Paddle's own
subscription guidance also treats webhook-driven provisioning as the normal
control point for recurring billing.

### What your app should do after verification

Flat version:

- Check the event type.
- Extract the IDs you care about.
- Persist them against your user or account.
- Grant or update access.
- Record enough audit information to explain what happened later.

The important subtlety: oarlock verifies and parses the webhook. It does not
decide what "grant access" means in your app. That is still your domain.

## Job 3: Reconcile What Happened, Not What You Hoped Happened

Webhooks are the event signal. Transactions are the billable record.

If you want to confirm the final state from Paddle after checkout, fetch the
transaction again:

```elixir
{:ok, transaction} = Paddle.Transactions.get(client, transaction_id)
```

This is especially useful when your app wants one clean server-side place to
read:

- `transaction.status`
- `transaction.customer_id`
- `transaction.subscription_id`
- `transaction.checkout.url`

For recurring items, the `subscription_id` is the bridge from "purchase" to
"ongoing relationship."

This is the quiet power move in the current library design: the user-facing
story is not "we have every endpoint." It is "the endpoints we do have connect
the important moments cleanly."

## Job 4: Inspect or End an Existing Subscription

Once a recurring purchase exists, the next common job is operational:

"Show me the subscription state," or "let this customer stop renewing."

That is what the current subscription surface covers.

Fetch one subscription:

```elixir
{:ok, subscription} = Paddle.Subscriptions.get(client, subscription_id)
```

List subscriptions when you need an account-management or backoffice view:

```elixir
active_subscriptions =
  client
  |> Paddle.Subscriptions.stream(status: "active")
  |> Enum.take(100)
```

For bounded scripts or small accounts, collect all pages eagerly:

```elixir
{:ok, subscriptions} = Paddle.Subscriptions.all(client, status: "active")
```

`stream/2` is lazy. If a later page fails, it raises during enumeration after
any earlier items may already have been yielded. Keep side effects idempotent
when consuming it. `all/2` is convenient, but it loads every returned item into
memory and returns `{:error, reason}` instead of partial results on the first
failed page.

Manual page control remains available when you need it:

```elixir
{:ok, page} = Paddle.Subscriptions.list(client, status: "active")
next_reference = Paddle.Page.next_cursor(page)
```

Cancel at the next billing period:

```elixir
{:ok, subscription} = Paddle.Subscriptions.cancel(client, subscription_id)
```

Cancel immediately:

```elixir
{:ok, subscription} =
  Paddle.Subscriptions.cancel_immediately(client, subscription_id)
```

Two fields are especially useful:

- `subscription.scheduled_change`
- `subscription.management_urls`

`scheduled_change` tells you what is queued next.
`management_urls` gives you customer-portal links for actions Paddle already
hosts.

Treat those URLs as temporary operational links, not as durable database data.

## Job 5: Know What the Library Deliberately Does Not Do

This is where people usually burn time.

They assume "billing SDK" means "complete billing platform abstraction."
oarlock is intentionally narrower than that.

Today, the library does not try to own:

- Phoenix request parsing or webhook plugs
- Ecto schemas or synchronization tables
- Entitlement logic
- Refund workflows
- Product and price catalog management
- Customer portal session creation
- Direct subscription pause/resume flows

One more important truth: as of Paddle's current documentation on May 23, 2026,
subscriptions are normally created indirectly through checkout or invoicing
flows, not by calling a direct "create subscription" API. So the practical
"start a subscription" job today is still transaction -> checkout -> webhook,
which is exactly the path this guide teaches.

## What to Save in Your Own Database

If you want the shortest useful checklist, save:

- Your user/account ID
- Paddle `customer_id`
- Paddle `subscription_id` once it exists
- The most recent relevant `transaction_id`
- Enough webhook receipt data to debug support issues

You may also want:

- The latest known subscription status
- The latest known billing email and address snapshot
- An internal audit trail for provisioning decisions

## A Realistic App-Level Sequence

If you are building this into a Phoenix SaaS, the sequence usually feels like
this:

1. A signed-in user clicks "Start plan."
2. Your app creates or reuses a Paddle customer.
3. Your app creates or reuses a billing address.
4. Your app creates a transaction and redirects to `transaction.checkout.url`.
5. The customer pays in Paddle Checkout.
6. Paddle sends `transaction.completed`.
7. Your webhook handler verifies the raw body and parses the event.
8. Your app stores the Paddle IDs and grants access.
9. Later, support or account settings use `Paddle.Subscriptions.get/2`,
   `list/2`, or `cancel/2`.

That is the current oarlock story in one screen.

## Where to Go Next

- Read the [Accrue Seam Contract](accrue-seam.md) if you want the exact locked
  public surface.
- Read the generated module docs when you want function-by-function detail.

If you only remember one thing, remember this:

oarlock is best when you let Paddle run billing, let your app run product
access, and let this library be the clean seam between them.
