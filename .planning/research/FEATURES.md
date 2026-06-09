# Feature Landscape

**Domain:** Paddle Billing SDK (Customer Portal & Adjustments)
**Researched:** 2026-06-09

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Portal Session Creation | The only secure, API-native way to allow customers to update payment methods or cancel subscriptions. | Low | POST to `/customers/{id}/portal-sessions`. Returns `urls` object. |
| Adjustment Creation | Critical for ops. Handles "refunds" (for `completed` transactions) and "credits" (for `billed` transactions). | Medium | POST to `/adjustments`. Must support `full` and `partial` with item tracking. |
| Adjustment Retrieval | Refunds often enter `pending_approval` state. Retrieval is necessary to check if approved/rejected. | Low | GET to `/adjustments/{id}` mapping to an `%Adjustment{}` struct. |
| Adjustment Webhooks | Apps need to react to asynchronous refund approvals. | Low | Parse `adjustment.created` and `adjustment.updated` events. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Credit Note PDF Retrieval | `GET /adjustments/{id}/credit-note` enables automated tax/receipt workflows. | Low | Great QoL addition for an SDK. |
| Client-Side Validation | Guarding `action: "refund"` vs `"credit"` based on transaction status before hitting the API. | Medium | Shifts errors left, improving DX and avoiding API errors. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Portal URL Caching | URLs contain one-time tokens. Caching leads to expired sessions. | Generate on-demand and document this constraint. |
| Iframe UI Helpers | Paddle explicitly advises against embedding the portal in an iframe. | Return raw URLs for standard redirects. |
| Transaction Mutation | Transactions are immutable. | Exclusively use `Paddle.Adjustments` for financial changes. |

## Feature Dependencies

```text
Portal Sessions → Paddle.Customers (needs customer_id)
Portal Sessions → Paddle.Subscriptions (optionally needs subscription_ids)
Adjustments → Paddle.Transactions (needs transaction_id)
Adjustments (Partial) → Transaction Items (needs item_id)
```

## MVP Recommendation

Prioritize:
1. Portal Session Creation (`Paddle.Customers.PortalSessions.create/3`)
2. Adjustment Creation (`Paddle.Adjustments.create/2`)
3. Adjustment Retrieval & Webhooks (`Paddle.Adjustments.get/2`, `adjustment.*`)

Defer: 
- Credit Note Retrieval: useful but not necessary for v1.
- Deep client-side validation: rely on Paddle's API errors for the first pass to reduce complexity.

## Sources

- [Paddle API Docs: Customer Portal Sessions](https://developer.paddle.com/api-reference/customer-portal-sessions/create-customer-portal-session) (HIGH)
- [Paddle API Docs: Adjustments](https://developer.paddle.com/api-reference/adjustments/create-adjustment) (HIGH)
