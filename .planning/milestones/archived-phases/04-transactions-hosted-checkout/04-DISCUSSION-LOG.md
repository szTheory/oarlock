# Phase 4: Transactions & Hosted Checkout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 04-transactions-hosted-checkout
**Areas discussed:** Transaction input shape, Checkout ergonomics, Billing strictness

---

## Transaction input shape

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow recurring catalog-item API | Minimal curated attrs for existing customer + address + recurring catalog items only. | |
| Broad raw-Paddle attrs API | Near-pass-through request body covering much of Paddle's transaction endpoint. | |
| Hybrid curated API with controlled extras | Curated main contract with a very small optional allowlist such as `custom_data` and `checkout.url`. | ✓ |

**User's choice:** Delegate to research-backed recommendation and adopt the cohesive default set.
**Notes:** Recommendation synthesized from subagent research: use a curated attrs map with required `customer_id`, `address_id`, and recurring `items`, while allowing only the near-term hosted-checkout extras that materially improve DX without dragging in invoice/manual-collection scope.

---

## Checkout ergonomics

| Option | Description | Selected |
|--------|-------------|----------|
| Typed `%Paddle.Transaction{}` only | Return the transaction entity and document `transaction.checkout.url` as the success path. | ✓ |
| `%Paddle.Transaction{}` plus helper | Return the transaction entity and also provide additive sugar like `Paddle.Transaction.checkout_url/1`. | |
| Custom hosted-checkout response | Return a wrapper such as `%Paddle.HostedCheckout{}` or another checkout-oriented response shape. | |

**User's choice:** Delegate to research-backed recommendation and adopt the cohesive default set.
**Notes:** The selected path keeps the SDK's primary contract entity-centric and consistent with earlier phases. Any helper is explicitly deferred as optional future sugar, not part of Phase 4's primary API.

---

## Billing strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict ready-only public path | Require existing `customer_id` and `address_id` and keep Phase 4 on the ready recurring-checkout path. | ✓ |
| Flexible draft-or-ready single path | Let one `create/2` support missing customer/address and expose either draft or ready behavior implicitly. | |
| Strict default plus explicit future draft path | Keep the main path strict now and reserve draft support for a separately named future API if needed. | ✓ |

**User's choice:** Delegate to research-backed recommendation and adopt the cohesive default set.
**Notes:** Phase 4 implements the strict ready-only path now. A distinct draft-oriented API remains a future expansion path rather than a hidden branch in the main function.

---

## the agent's Discretion

- Exact `%Paddle.Transaction{}` field list beyond the fields Phase 4 strictly needs.
- Exact internal normalization/helper boundaries that preserve a clean future path for draft support.
- Whether to ignore or reject unknown attrs, as long as the public contract stays curated and predictable.

## Deferred Ideas

- Draft checkout support that collects missing customer or address information later in checkout.
- Manual/invoice collection support and related billing-details branches.
- Broader raw-Paddle transaction payload coverage.
- Alternate hosted-checkout wrapper return types.
- A transaction checkout helper unless usage proves it materially improves DX.
