# Investigation: Phase 10 Subscription Create Revalidation

**Status:** resolved
**Created:** 2026-05-30
**Resolved:** 2026-06-24
**Owner:** Phase 10 / v2.1 adopter truth assessment

## Question

Does Paddle Billing support a direct `Paddle.Subscriptions.create/2` API surface that belongs in oarlock, or should SUB-04 be reframed around the correct transaction/invoice-backed recurring-start flow?

## Why This Matters

Current v1.2 roadmap text says Phase 10 should add `Paddle.Subscriptions.create/2`, but repo-local research in `.planning/research/JTBD-GAPS.md` warns that Paddle subscriptions are normally created when a customer pays for recurring items through checkout, or through manually-collected transaction/invoice flows. Shipping a fake or provider-hostile subscription-create seam would make oarlock less honest and less provider-native.

## Planning Rule

Before Phase 10 plans are written:

- Re-check current Paddle Billing primary docs/API reference for subscription creation, pause, and resume.
- If direct subscription creation exists and maps cleanly, implement `Paddle.Subscriptions.create/2` with the same idempotency/retry opts pattern as other `create/*` calls.
- If direct creation does not exist, update REQUIREMENTS/ROADMAP to replace SUB-04 with the correct recurring-start surface and document the decision in Phase 10 CONTEXT.
- Preserve the locked subscription struct seam either way; no field removals or renames.

## Resolution

Phase 10 resolved this by rejecting a direct `Paddle.Subscriptions.create/2`
surface for the current seam. The provider-native recurring-start path is:

1. create a transaction for recurring items,
2. send the customer through Paddle Checkout or manual collection,
3. verify webhook events,
4. reconcile with `Paddle.Transactions.get/2`,
5. fetch canonical subscription state with `Paddle.Subscriptions.get/2`.

The SDK now documents this as the supported path and explicitly avoids adding
`Paddle.Subscriptions.create/2`. Reopen this thread only if current Paddle
primary docs introduce a clean direct subscription-create API that fits the
provider model.
