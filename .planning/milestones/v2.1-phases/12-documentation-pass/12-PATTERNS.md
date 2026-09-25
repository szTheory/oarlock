# Phase 12: Documentation Pass - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 21
**Analogs found:** 2 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.md` | documentation | none | `guides/accrue-seam.md` | role-match |
| `guides/getting-started.md` | documentation | narrative | `guides/accrue-seam.md` | role-match |
| `guides/telemetry.md` | documentation | event-driven | `guides/accrue-seam.md` | role-match |
| `mix.exs` | config | none | none | none |
| `lib/paddle/customers.ex` | controller | request-response | none | none |
| `lib/paddle/customers/addresses.ex` | controller | request-response | none | none |
| `lib/paddle/transactions.ex` | controller | request-response | none | none |
| `lib/paddle/subscriptions.ex` | controller | request-response | none | none |
| `lib/paddle/webhooks.ex` | controller | request-response | none | none |
| `lib/paddle/client.ex` | model | config | none | none |
| `lib/paddle/event.ex` | model | event-driven | none | none |
| `lib/paddle/address.ex` | model | CRUD | none | none |
| `lib/paddle/customer.ex` | model | CRUD | none | none |
| `lib/paddle/error.ex` | model | error | none | none |
| `lib/paddle/page.ex` | model | request-response | none | none |
| `lib/paddle/subscription.ex` | model | CRUD | none | none |
| `lib/paddle/subscription/management_urls.ex` | model | CRUD | none | none |
| `lib/paddle/subscription/scheduled_change.ex` | model | CRUD | none | none |
| `lib/paddle/transaction.ex` | model | CRUD | none | none |
| `lib/paddle/transaction/checkout.ex` | model | CRUD | none | none |

## Pattern Assignments

### `guides/getting-started.md` (documentation, narrative)

**Analog:** `guides/accrue-seam.md`

**Structure and formatting pattern** (lines 1-17):
```markdown
# Accrue Seam Contract

This guide is the canonical published contract for the oarlock surface that Accrue
(and any other consumer) is expected to depend on as its Paddle integration seam.
It enumerates the closed set of supported modules, functions, structs, and support
types and describes how each field may evolve inside the 0.x series.

## Boundary Policy

The published seam is **closed and explicitly enumerated**.
Only explicitly documented modules, functions, structs, and support types are supported as part of this seam.
```

---

## Shared Patterns

### Module-Level Hybrid Explicit Pipeline
**Source:** `.planning/phases/12-documentation-pass/12-RESEARCH.md` (Lines 67-87)
**Apply to:** All public controller modules (e.g., `lib/paddle/customers.ex`, `lib/paddle/transactions.ex`)
```elixir
@moduledoc """
Provides operations for managing Paddle Customers.

## Example Pipeline

```elixir
client = Paddle.Client.new!(api_key: "...", environment: :sandbox)

case Paddle.Customers.create(client, email: "ada@example.com", name: "Ada Lovelace") do
  {:ok, %Paddle.Customer{} = customer} ->
    # Store customer.id
    IO.puts("Created: #{customer.id}")

  {:error, %Paddle.Error{} = error} ->
    # Handle API or network errors
    IO.puts("Failed: #{error.message}")
end
```
"""
```

### Function-Level Explicit Pattern Match
**Source:** `.planning/phases/12-documentation-pass/12-RESEARCH.md` (Lines 89-114)
**Apply to:** All public functions inside controller modules
```elixir
@doc """
Retrieves a customer by ID.

## Examples

```elixir
case Paddle.Customers.get(client, "ctm_123") do
  {:ok, %Paddle.Customer{} = customer} ->
    customer

  {:error, :invalid_customer_id} ->
    # Handle local validation error

  {:error, %Paddle.Error{} = error} ->
    # Handle provider/network error
end
```

## Provider behavior
If a customer is archived, they are still returned but `status` will be `"archived"`.

## Related Paddle docs
- [Get a customer](https://developer.paddle.com/api-reference/customers/get-customer)
"""
```

### Internal Modules Remaining Sealed
**Source:** `.planning/phases/12-documentation-pass/12-RESEARCH.md` (Lines 125-131)
**Apply to:** `Paddle`, `Paddle.Http`, `Paddle.Http.Telemetry`, `Paddle.Application`, `Paddle.Internal.Attrs`, `Paddle.Internal.Pagination`
```elixir
@moduledoc false
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `README.md` | documentation | none | Documentation draft exists but requires top-level project context |
| `mix.exs` | config | none | No configuration file analog |
| `lib/paddle/customers.ex` | controller | request-response | No documented modules exist yet |
| `lib/paddle/customers/addresses.ex` | controller | request-response | No documented modules exist yet |
| `lib/paddle/transactions.ex` | controller | request-response | No documented modules exist yet |
| `lib/paddle/subscriptions.ex` | controller | request-response | No documented modules exist yet |
| `lib/paddle/webhooks.ex` | controller | request-response | No documented modules exist yet |
| `lib/paddle/client.ex` | model | config | No documented models exist yet |
| `lib/paddle/event.ex` | model | event-driven | No documented models exist yet |
| `lib/paddle/address.ex` | model | CRUD | No documented models exist yet |
| `lib/paddle/customer.ex` | model | CRUD | No documented models exist yet |
| `lib/paddle/error.ex` | model | error | No documented models exist yet |
| `lib/paddle/page.ex` | model | request-response | No documented models exist yet |
| `lib/paddle/subscription.ex` | model | CRUD | No documented models exist yet |
| `lib/paddle/subscription/management_urls.ex` | model | CRUD | No documented models exist yet |
| `lib/paddle/subscription/scheduled_change.ex` | model | CRUD | No documented models exist yet |
| `lib/paddle/transaction.ex` | model | CRUD | No documented models exist yet |
| `lib/paddle/transaction/checkout.ex` | model | CRUD | No documented models exist yet |

## Metadata

**Analog search scope:** `lib/`, `guides/`, `mix.exs`, `README.md`
**Files scanned:** 21
**Pattern extraction date:** 2026-06-04
