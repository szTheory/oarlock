# Backlog Archive

Historical backlog entries that are shipped, superseded, or retained only for
reference. Preserve original B-IDs here so old phase notes, changelog entries,
and source-of-requirement references remain searchable without making completed
work look active.

Active planning candidates live in `.planning/BACKLOG.md`.

## Status Taxonomy

- `Open`: candidate for future oarlock planning.
- `Accrue-only`: consumer-side follow-up tracked for context; not oarlock SDK
  scope unless a later milestone explicitly promotes related oarlock work.
- `Shipped`: satisfied by a prior phase or milestone; retained in archive only.
- `Superseded`: replaced by a newer decision or scope.
- `Reference`: historical context, not a planning candidate.

---

## Shipped Entries

### B-01 - `Paddle.Transactions.get/2`

**Source:** Accrue (`~/projects/accrue`) - checkout reconciliation flow needs to
fetch a transaction by ID after creation.
**Priority:** High - small, isolated, unblocks a real downstream consumer.
**Status:** Shipped.
**Satisfied by:** Phase 6 / v1.1 Accrue Seam Hardening; see
`.planning/MILESTONES.md` and commit `813438d` for the retroactive
`Paddle.Transactions.get/2` implementation evidence.

**Why it was a gap:** Phase 4 (Transactions & Hosted Checkout) executed only
`Paddle.Transactions.create/2`. The retrieval surface was deliberately deferred
at the time. Accrue's first slice could not reconcile checkouts without it.

**Original sizing:** ~1 plan, ~1 day. Pure extension - same pattern as
`Paddle.Subscriptions.get/2` but against `/transactions/{id}`. The
`%Paddle.Transaction{}` struct and contract tests were already locked, so this
was the resource-level fetch.

**Surface added:**

- `Paddle.Transactions.get(client, transaction_id)` ->
  `{:ok, %Paddle.Transaction{}} | {:error, %Paddle.Error{}}`
- Adapter-backed test covering happy path, 404 error tuple, and id-validation
  tuple
- Per-resource hydration of nested `:checkout`

**Out of scope for B-01:** `list/2`, mutations, refund actions.

### B-02 - Accrue Seam Integration Test (End-to-End Contract Path)

**Source:** Accrue - needs a stable, observable seam to target.
**Priority:** Medium - unblocks confident Accrue integration; defends the seam
against silent regressions.
**Status:** Shipped.
**Satisfied by:** Phase 7 / v1.1 seam contract work, with later seam expansion in
v2.1 documentation truth and test updates.

**Why it was a gap:** No test or guide strung the public surface together. Each
resource was unit-tested in isolation, but the consumer-facing journey was not
pinned anywhere. A regression in any single resource's contract could quietly
break Accrue.

**Original path to walk:**

1. `Paddle.Customers.create/2` - produce a customer
2. `Paddle.Customers.Addresses.create/3` - attach an address
3. `Paddle.Transactions.create/2` - automatic-collection transaction -> assert
   `transaction.checkout.url` is a string
4. `Paddle.Webhooks.verify_signature/4` + `Paddle.Webhooks.parse_event/1` -
   synthesize a `transaction.completed` webhook payload, signature-verify, parse
   to `%Paddle.Event{}`
5. `Paddle.Subscriptions.get/2` - fetch the subscription created from the
   completed transaction
6. `Paddle.Subscriptions.cancel/2` - exercise the cancellation path

All steps used the existing Req adapter test pattern with no live network. This
doubles as integration documentation: future readers see exactly what oarlock
guarantees as a usable surface.

**Original sizing:** ~1 phase (1 spec/doc plan + 1 test plan, 2-3 days).

**Pitfalls captured:** deterministic raw-body webhook fixture and matching
signature; inline adapter responses rather than fixture sprawl.

### B-03 - Accrue-Facing Seam Surface Doc

**Source:** Accrue - needs an authoritative list of "what is part of the
consumer contract."
**Priority:** Low (capture only) - nice-to-have once B-02 lands.
**Status:** Shipped.
**Satisfied by:** `guides/accrue-seam.md`, created in v1.1 and refreshed during
Phase 27 / v2.1 documentation truth.

**Why it was a gap:** PROJECT.md named the locked struct surfaces in prose, but a
developer pulling oarlock as a dependency needed a renderable list: which fields,
which functions, which guarantees. Without this, every consumer re-read source to
figure it out.

**Deliverable:** `guides/accrue-seam.md` listing:

- Each public module + function signature for customers, addresses,
  transactions, subscriptions, and webhooks
- Each locked struct with its field list and stability tier
- Explicit unsupported or deferred scope callouts

No new runtime code was required for the original backlog entry.

### B-05 - Support operations: refunds/credits via `Paddle.Adjustments`

**Status:** Shipped.
**Satisfied by:** Phase 15 / v1.3 Support & Self-Serve Surface via
`Paddle.Adjustments`.

**Priority:** High after v1.2.

**Why it mattered:** A serious SaaS billing library should not stop at charging
customers. Support teams need a provider-native correction path for refunds or
credits, and Accrue already has Stripe-side refund vocabulary.

**Done enough:** Typed adjustment create/retrieve/list surface, normalized
errors, raw-data escape hatch, adapter-backed success/error tests, changelog
entry, and guide text explaining Paddle's adjustment model without pretending it
is Stripe.

### B-06 - Customer self-serve billing surface

**Status:** Shipped.
**Satisfied by:** Phase 14 / v1.3 Support & Self-Serve Surface via
`Paddle.Customers.PortalSessions`.

**Priority:** Medium after B-05.

**Why it mattered:** Existing subscription `management_urls` help, but signed-in
SaaS UX often wants a cleaner customer self-serve path for payment-method or
subscription management.

**Done enough:** The smallest current Paddle Billing portal/session/payment
management surface that is provider-native, tested, documented, and kept free of
Phoenix/Ecto/UI coupling in core.

### B-07 - Catalog read surface

**Status:** Shipped.
**Satisfied by:** Phase 17 / v1.4 Catalog & Events via read/list products and
prices.

**Priority:** Medium-low, demand-driven.

**Why it mattered:** Products/prices read/list support helps server-driven plan
selection and support/admin tools. Full catalog CRUD is endpoint-mirroring until
a consumer asks for it.

**Done enough:** Read/list products and prices with typed structs, pagination
helpers where list endpoints exist, and docs that frame this as catalog
inspection rather than full product-management ownership.
