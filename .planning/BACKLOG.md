# Backlog

Future work captured outside the current milestone. Each entry is an idea or request that should surface during next-milestone planning, not work being done now.

Promotion path: when the user is ready, an entry becomes a phase via `/gsd-new-milestone` → `/gsd-discuss-phase` (or `/gsd-add-phase`). The entry ID (e.g. `B-01`) gets cited in the resulting phase's source-of-requirement field so the trail stays intact.

---

## B-01 — `Paddle.Transactions.get/2`

**Source:** Accrue (`~/projects/accrue`) — checkout reconciliation flow needs to fetch a transaction by ID after creation.
**Priority:** High — small, isolated, unblocks a real downstream consumer.
**Status:** Captured 2026-04-29.

**Why it's a gap:** Phase 4 (Transactions & Hosted Checkout) executed only `Paddle.Transactions.create/2`. The retrieval surface was deliberately deferred at the time. Accrue's first slice can't reconcile checkouts without it.

**Sizing:** ~1 plan, ~1 day. Pure extension — same pattern as `Paddle.Subscriptions.get/2` (`lib/paddle/subscriptions.ex:13-22`) but against `/transactions/{id}`. The `%Paddle.Transaction{}` struct (`lib/paddle/transaction.ex`) and contract tests (`test/paddle/transaction_test.exs`) are already locked, so this is purely the resource-level fetch.

**Surface to add:**
- `Paddle.Transactions.get(client, transaction_id)` → `{:ok, %Paddle.Transaction{}} | {:error, %Paddle.Error{}}`
- Adapter-backed test covering happy path, 404 error tuple, and id-validation tuple
- Per-resource hydration of nested `:checkout` (already a typed struct; reuse build pattern)

**Promotion hint:** Phase 6 in milestone v1.1, OR a 4.1 decimal phase if v1.0 stays open. Decimal phase is cleanest because the work fits inside Phase 4's frame.

**Out of scope for B-01:** `list/2`, mutations, refund actions.

---

## B-02 — Accrue Seam Integration Test (End-to-End Contract Path)

**Source:** Accrue — needs a stable, observable seam to target.
**Priority:** Medium — unblocks confident Accrue integration; defends the seam against silent regressions.
**Status:** Captured 2026-04-29.

**Why it's a gap:** No test or guide currently strings the public surface together. Each resource is unit-tested in isolation, but the consumer-facing journey isn't pinned anywhere. A regression in any single resource's contract could quietly break Accrue.

**Path to walk (single test, single fixture set):**

1. `Paddle.Customers.create/2` — produce a customer
2. `Paddle.Customers.Addresses.create/3` — attach an address
3. `Paddle.Transactions.create/2` — automatic-collection transaction → assert `transaction.checkout.url` is a string
4. `Paddle.Webhooks.verify_signature/4` + `Paddle.Webhooks.parse_event/1` — synthesize a `transaction.completed` webhook payload, signature-verify, parse to `%Paddle.Event{}`
5. `Paddle.Subscriptions.get/2` — fetch the subscription created from the completed transaction (depends on B-01 NOT being needed; subscription has its own get/2)
6. `Paddle.Subscriptions.cancel/2` — exercise the cancellation path

All steps run against the existing Req adapter test pattern (no live network). Doubles as integration documentation: future readers see exactly what oarlock guarantees as a usable surface.

**Sizing:** ~1 phase (1 spec/doc plan + 1 test plan, 2–3 days).

**Promotion hint:** Phase 7 (after B-01 lands so the test can include `Transactions.get/2` if useful). Companion to B-03.

**Pitfalls to design around:**
- Webhook step needs a deterministic raw-body fixture and matching signature — borrow from `test/paddle/webhooks_test.exs` patterns.
- Subscription fetch needs a fixture transaction-id → subscription-id mapping; keep adapter responses inline rather than introducing fixture files.

---

## B-03 — Accrue-Facing Seam Surface Doc

**Source:** Accrue — needs an authoritative list of "what is part of the consumer contract."
**Priority:** Low (capture only) — nice-to-have once B-02 lands.
**Status:** Captured 2026-04-29.

**Why it's a gap:** PROJECT.md now names the locked struct surfaces in prose, but a developer pulling oarlock as a dep needs a renderable list: which fields, which functions, which guarantees. Without this, every consumer re-reads source to figure it out.

**Deliverable:** `guides/accrue-seam.md` (or `pages/CONSUMER_CONTRACT.md`) listing:
- Each public module + function signature for: `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, `Paddle.Webhooks`
- Each locked struct with its field list and stability tier (locked / additive / experimental)
- Explicit "not on roadmap" callouts: subscription mutations, payment-method portals, refunds, marketplaces

No new code — purely a rendered surface map. All the truths are already in the codebase.

**Sizing:** ~0.5 day, docs-only.

**Promotion hint:** Bundle into the same phase as B-02, or fold into a v1.1 "consumer documentation" plan.

---

## Integration Posture Reference

Two of Accrue's five prereqs do not need backlog entries because oarlock already meets them:

- **Pure-function webhook layer** — Phase 2 delivered `verify_signature/4` + `parse_event/1` + `%Paddle.Event{}` exactly as Accrue requested. No coupling to Phoenix/Plug. Already documented in `PROJECT.md` under Integration Consumers.
- **De-prioritized subscription mutations** — `update/3`, `pause/3`, `resume/3`, payment-method updates are explicitly out of v0.1 scope and not in any planned phase. Reaffirmed in `PROJECT.md` Out of Scope and Integration Consumers.

If those positions ever shift, these reference points are the place to revisit.
