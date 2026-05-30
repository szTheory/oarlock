# Investigation: Phase 10 Subscription Create Revalidation

**Status:** open
**Created:** 2026-05-30
**Owner:** next Phase 10 discussion/planning pass

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
