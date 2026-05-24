# JTBD Gap Map

_Last reviewed: 2026-05-23_

This document is for maintainers, not first-time adopters.

Reader: the maintainer deciding what to build next.
Post-read action: choose the next milestone based on real SaaS-integrator user
flows instead of endpoint-completeness instincts.

## Summary

oarlock already covers the core "take a user into Paddle Checkout, verify the
result, and inspect the resulting subscription" story.

It is strongest at the seam moments:

- create customer
- create address
- create transaction
- verify and parse webhook
- fetch transaction
- fetch/list/cancel subscription

For a Phoenix or Ecto SaaS integrator, the biggest remaining value is not
"cover more Paddle nouns." It is "close the remaining operational gaps in the
recurring billing lifecycle."

## Current JTBD Coverage

### Fully supported today

| Job | Current support | Notes |
| --- | --- | --- |
| Start a hosted checkout for a known customer | Strong | Customer + address + transaction create is in place. |
| Verify that a webhook is genuine | Strong | Pure-function verification/parsing is a good fit for Phoenix handlers. |
| Reconcile a completed purchase | Strong | `Paddle.Transactions.get/2` closes the loop cleanly. |
| Inspect the current state of a subscription | Strong | `get/2` and `list/2` are enough for dashboards and support tooling. |
| End renewal | Strong | `cancel/2` and `cancel_immediately/2` cover the main off-ramp. |

### Partially supported today

| Job | Current support | Gap |
| --- | --- | --- |
| Let customers self-serve billing changes | Partial | `management_urls` are exposed, but there is no customer-portal session helper. |
| Backfill or operate on large subscription/customer sets | Partial | List endpoints exist, but cursor iteration is still manual. |
| Explain the integration to a fresh adopter | Partial | This improved with `guides/getting-started.md`, but function docs are still thin. |
| Handle production HTTP failure modes confidently | Partial | Reliability work is planned, not shipped. |

### Missing for the SaaS-integrator job map

| Job | Why it matters |
| --- | --- |
| Pause and resume a subscription | Common save-motion in B2B and prosumer SaaS. |
| Refund or credit a billed transaction | Essential support and retention workflow. |
| Create authenticated customer-portal sessions | Better signed-in UX than handing out raw management links. |
| Read prices/products from Elixir | Useful when your app wants server-driven plan selection or catalog sync. |
| Guide-level provisioning patterns | Teams still need explicit examples for mapping webhook events to entitlements. |

## Priority Order

### Tier 1: highest-value gaps

These close obvious holes in the lifecycle a SaaS team actually operates.

1. **Pause/resume subscriptions**
   - Current Paddle docs support this operationally.
   - It is a real retention lever, not endpoint vanity.
   - It fits the existing subscription seam better than many broader expansions.

2. **Refunds/credits via adjustments**
   - Support teams need a financial correction path.
   - "We can charge customers but not reverse a charge" is not a mature SaaS story.
   - Paddle models this through adjustments, not by mutating the original transaction.

3. **Pagination ergonomics**
   - The current `Page.next_cursor/1` primitive is fine, but manual cursor loops are low-value repetition.
   - This becomes noticeable as soon as an integrator builds backoffice tooling.

4. **Customer portal session support**
   - Current subscription entities expose `management_urls`, which is useful.
   - Paddle's current docs make clear that authenticated customer portal sessions are the better signed-in UX for payment-method updates and subscription management.

5. **Production reliability primitives**
   - Idempotency, retries, and normalized network errors are not glamorous, but they stop support incidents.
   - These are already on the local roadmap for good reason.

### Tier 2: useful soon after Tier 1

1. **Read-only catalog support**
   - Listing prices and products is often enough for a SaaS app that already manages its product model locally.
   - Full CRUD is less urgent than read support.

2. **Provisioning and operations guides**
   - Not code-first, but high leverage.
   - The next documentation wave should show how to map webhook events to entitlements, audits, and support-friendly records.

3. **Customer listing/search ergonomics**
   - Helpful for support consoles and admin tools.
   - Lower leverage than subscription lifecycle gaps.

### Tier 3: demand-driven only

These are legitimate surfaces, but they are where endpoint parity starts to
outpace user-value.

- Full products/prices CRUD
- Notification settings management
- Reports and simulations
- Broad admin APIs with no current consumer pressure
- A complete mirror of Paddle's API reference

## Biggest Strategic Mismatch to Resolve

### `Paddle.Subscriptions.create/2` needs re-validation

As of the current Paddle documentation reviewed on **2026-05-23**, the
subscription overview says:

- subscriptions are created automatically when customers pay for recurring items
  using checkout
- or when you create and issue an invoice using a manually-collected transaction

That means the roadmap item `SUB-04` should not be treated as obviously valid.

Recommendation:

- Reframe the user job as **"start a recurring subscription flow"**, not
  **"directly create a subscription record."**
- Re-check whether the real need is:
  - better transaction/create guidance
  - support for manual invoice flows
  - support for subscription updates/pause/resume
  - or a narrower API that maps to a current Paddle endpoint

Until that re-validation happens, maintainers should avoid documenting or
designing around a direct subscription-create seam as if it were settled truth.

## What "Feature-Complete Enough" Looks Like

For the target user, oarlock reaches the "done enough" zone when it supports
all of these cleanly:

- Start a recurring purchase with transaction + checkout
- Verify webhook authenticity and parse payloads
- Reconcile transactions after the fact
- Persist and inspect subscription state
- Cancel, pause, and resume subscriptions
- Refund or credit purchases
- Offer sane customer self-serve billing paths
- Iterate paginated collections ergonomically
- Survive production HTTP failure patterns
- Explain the integration clearly enough that adopters do not have to read source

After that point, returns drop quickly. New work should be justified by a real
consumer job, not by the fact that Paddle happens to expose another endpoint.

## Diminishing Returns Boundary

The practical boundary is:

**Once the library fully covers the recurring purchase lifecycle plus the most
common support and retention operations, the next wave of API expansion becomes
optional rather than strategic.**

Signs you have crossed that boundary:

- Most new asks sound like "it would be nice if the SDK also had..."
- The next endpoints are admin/reporting surfaces rather than user-critical flows.
- Documentation and production hardening are creating more adoption value than
  new resource modules.

At that point, default to:

- docs
- examples
- reliability
- consumer-driven additions

not endpoint-mirroring.

## Recommended Near-Term Ordering

If planning restarted today for SaaS-integrator value, the recommended order
would be:

1. Reliability primitives
2. Pagination ergonomics
3. Pause/resume subscription flows
4. Refund/credit adjustments
5. Customer portal session support
6. Read-only prices/products support

The reason is simple: these steps complete the operating loop before broadening
the catalog.

## Update Procedure

When revisiting this document later:

1. Re-read the current public API surface and seam guide.
2. Re-read the seam test to see the actual locked end-to-end story.
3. Diff `CHANGELOG.md`, roadmap, and requirements since the last review.
4. Re-check Paddle's current lifecycle docs for any truth that may have moved.
5. Update these sections in one pass:
   - current coverage
   - top gaps
   - roadmap mismatches
   - diminishing-returns boundary

This keeps the doc useful as strategy, not just as a historical note.
