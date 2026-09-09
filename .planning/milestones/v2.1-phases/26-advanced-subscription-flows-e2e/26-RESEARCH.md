# Phase 26: Advanced Subscription Flows E2E - Research

**Researched:** 2026-06-11
**Domain:** Elixir HTTP Mocking, API Serialization, E2E Testing
**Confidence:** HIGH

## Summary

This phase implements E2E testing for complex subscription upgrade and downgrade scenarios. By strictly following the pure REST architectural principle of `oarlock`, the domain logic for what constitutes an "upgrade" vs "downgrade" remains firmly in the consuming application (`Accrue`). The SDK is simply responsible for reliably executing `Paddle.Subscriptions.update/3` and serializing/deserializing the complex `scheduled_change` struct when proration behavior dictates.

**Primary recommendation:** Expand `Paddle.MockServer` to parse `proration_billing_mode` from the request body to deterministically return either an immediate update (for upgrades) or a delayed `scheduled_change` (for downgrades), enabling fast, deterministic E2E assertions without sandbox flakiness.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Use `Paddle.MockServer` as the default for E2E tests.** Keeping tests offline and fast is idiomatic for Elixir library development.
- **D-02:** Build minimal "happy path" stubs for the specific upgrade/downgrade payloads in the mock server. We will *not* attempt to recreate Paddle's complex proration engine in the mock. The mock just returns the expected JSON for a successful upgrade/downgrade.
- **D-03:** Tests should be structured so they can run against the real sandbox on demand (e.g. `@tag :integration`), but default to the mock.
- **D-04:** **Implement pure CRUD `Paddle.Subscriptions.update/3`.** Do not introduce domain helpers like `upgrade/2` or `downgrade/2`.
- **D-05:** This perfectly aligns with `oarlock`'s design principle: pure REST mapping with no framework coupling. The domain logic of upgrade/downgrade belongs in the consuming application (`Accrue`), not `oarlock`.
- **D-06:** **Verify both immediate and scheduled changes.** The E2E tests must cover an immediate upgrade (items change immediately, triggering proration) and a scheduled downgrade (proration billing_cycle is set to next_billing_period).
- **D-07:** The scheduled downgrade test MUST explicitly assert that the `scheduled_change` struct is populated on the returned subscription, proving the SDK correctly serializes and deserializes this complex nested struct.

### Claude's Discretion
- The specific test file layout and descriptor naming.
- How to structure the `@moduledoc` on `Paddle.Subscriptions.update/3` to guide developers towards proper usage.
- The exact mock payload structures required to simulate the upgrade/downgrade responses.

### Deferred Ideas
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADV-02 | Complex upgrade/downgrade E2E testing flows via Paddle. | Implements `update/3` and the accompanying MockServer routes/fixtures. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| E2E Mocking | `Paddle.MockServer` | `MockServer.Fixtures` | Intercepts updates to simulate immediate vs scheduled behavior based on request payload. |
| API Transport | `Paddle.Subscriptions`| `Paddle.Http` | Standard Req mapping of `update/3` via `PATCH /subscriptions/:id`. |
| Upgrade Logic | Consuming App | — | Accrue owns domain concepts like "upgrade" or "downgrade". `oarlock` only knows "update items with specific proration mode". |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| req | `0.4.x+` | HTTP Transport | Standard idiomatic HTTP client in modern Elixir. |
| bandit | `1.4.x+` | Mock Server HTTP | Powering `Paddle.MockServer` for frictionless offline tests. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

*No external packages are installed in this phase.*

## Architecture Patterns

### System Architecture Diagram

```
[Test Case] --> [Paddle.Subscriptions.update/3]
                     |
                     v
             [Req HTTP Client]
                     |
                     v (PATCH /subscriptions/:id)
             [Paddle.MockServer]
                     |
        {inspects body for proration_billing_mode}
           /                           \
["prorated_immediately"]        ["next_billing_period"]
         /                               \
[Fixtures.subscription_updated()] [Fixtures.subscription_scheduled_change()]
```

### Pattern 1: Deterministic Mocking via Request Inspection
**What:** The `MockServer` inspects `conn.body_params` to determine which fixture to return.
**When to use:** When you need a single REST endpoint (like `PATCH /subscriptions/:id`) to simulate fundamentally different backend behaviors (e.g. an immediate upgrade vs a scheduled downgrade) without relying on a stateful mock database.
**Example:**
```elixir
patch "/subscriptions/:id" do
  mode = conn.body_params["proration_billing_mode"]

  fixture =
    if mode == "next_billing_period" do
      Fixtures.subscription_scheduled_change(id)
    else
      Fixtures.subscription_updated(id)
    end

  send_json(conn, 200, fixture)
end
```

### Anti-Patterns to Avoid
- **Domain verbs in SDK:** Do not build `upgrade/2` or `downgrade/2`. Maintain `update/3`.
- **Complex Mock State:** Do not attempt to calculate Paddle's proration math inside the mock.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Proration math | Custom pricing logic in `MockServer` | Hardcoded fixtures | Paddle's engine is complex; the SDK only cares about successful struct deserialization. |

## Code Examples

### 1. The Pure CRUD Update

```elixir
@doc """
Updates a subscription.

## Examples

```elixir
# Immediate upgrade
case Paddle.Subscriptions.update(client, "sub_123", items: [...], proration_billing_mode: "prorated_immediately") do
  {:ok, %Paddle.Subscription{} = subscription} -> subscription
end

# Scheduled downgrade
case Paddle.Subscriptions.update(client, "sub_123", items: [...], proration_billing_mode: "next_billing_period") do
  {:ok, %Paddle.Subscription{} = subscription} ->
    # subscription.scheduled_change will be populated
    subscription
end
```
"""
@spec update(Paddle.Client.t(), subscription_id(), map() | keyword()) ::
        {:ok, Paddle.Subscription.t()} | {:error, Paddle.Error.t() | :invalid_subscription_id | :invalid_params}
def update(%Client{} = client, subscription_id, params) do
  with :ok <- validate_subscription_id(subscription_id),
       {:ok, params_map} <- normalize_params(params),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :patch, subscription_path(subscription_id), json: params_map) do
    {:ok, build_subscription(data)}
  end
end
```

### 2. Integration Toggled Test Setup

To satisfy D-03 (run against sandbox on demand, default to mock):

```elixir
setup_all do
  if System.get_env("PADDLE_API_KEY") && System.get_env("INTEGRATION_TESTS") == "true" do
    {:ok, client: Paddle.Client.new!(api_key: System.get_env("PADDLE_API_KEY"), environment: :sandbox)}
  else
    port = 4448
    {:ok, _pid} = Paddle.MockServer.start_link(port: port)
    client = Paddle.Client.new!(
      api_key: "sk_test_mock",
      base_url: "http://localhost:\#{port}"
    )
    {:ok, client: client}
  end
end
```

## Assumptions Log

If this table is empty: All claims in this research were verified or cited — no user confirmation needed.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/paddle/subscription_flows_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADV-02 | Verify immediate upgrade via MockServer payload | integration | `mix test test/paddle/subscription_flows_test.exs` | ❌ Wave 0 |
| ADV-02 | Verify scheduled downgrade populates `scheduled_change` struct | integration | `mix test test/paddle/subscription_flows_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/paddle/subscription_flows_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/paddle/subscription_flows_test.exs` — covers ADV-02
- [ ] `test/paddle/subscriptions_test.exs` — needs `update/3` coverage

## Sources

### Primary (HIGH confidence)
- `.planning/phases/26-advanced-subscription-flows-e2e/26-CONTEXT.md` - Phase constraints and locked decisions.
- `lib/paddle/subscriptions.ex` - Checked for existing implementations of `update/3` (none exist).
- `lib/paddle/mock_server.ex` - Confirmed absence of `/subscriptions/:id` endpoints.
- `lib/paddle/subscription/scheduled_change.ex` - Validated the struct fields.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core standard tooling.
- Architecture: HIGH - Fits into existing `oarlock` HTTP mock structures natively.
- Pitfalls: HIGH - Elixir tests defaulting to offline prevent test flakiness while keeping `integration` option open.

**Research date:** 2026-06-11
**Valid until:** 30 days