# Phase 5: Subscriptions Management - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 05-subscriptions-management
**Areas discussed:** Cancel API shape, List scoping, Mutation scope, Subscription struct fields

**Mode note:** User requested research-backed decisive recommendations rather than user-facing AskUserQuestion menus. Four `gsd-advisor-researcher` subagents ran in parallel — one per gray area — with full project context (PROJECT.md, REQUIREMENTS.md, prior phase CONTEXT.md files, existing source). Recommendations were synthesized into CONTEXT.md without further user choice points. This preference is now persisted as a memory feedback rule for future GSD discuss-phase runs.

---

## Cancel API Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Default end-of-period, opts to override | `cancel(client, sub_id, opts \\ [])`, default end-of-period; `effective_from: :immediately` overrides | |
| Two named functions | `cancel/2` (end-of-period) + `cancel_immediately/2` | ✓ |
| Single attrs map (mirror Paddle) | `cancel(client, sub_id, attrs)` always-required map with `effective_from` | |
| `cancel/2` + `cancel/3` with bare atom | `cancel(client, sub_id)` defaults; `cancel(client, sub_id, :immediately)` for immediate | |

**Selected option:** Two named functions.

**Rationale:**
- Coherent with locked Phase 4 D-10/D-11 ("separately named paths over polymorphic flags or hidden modes").
- Both modes are destructive and irreversible per Paddle docs — call-site clarity is a safety property, not just a style preference. A reviewer scanning a PR can instantly tell `cancel_immediately/2` from `cancel/2`; they cannot reliably tell `cancel(client, id)` from `cancel(client, id, effective_from: :immediately)` without reading opts.
- Stripe's Ruby/Node SDK uses bare `cancel` for immediate and `update(cancel_at_period_end: true)` for end-of-period — the most-asked Stripe support question and a textbook footgun. ChargeBee inverts it with an `end_of_term: false` default that silently destroys subscriptions.
- Future scheduled-cancel variants (e.g., `cancel_at` timestamp) get their own named function with no breaking change to either of these two — same pattern Phase 4 reserved for `create_draft_checkout/2`.

**Result in CONTEXT.md:** D-04 through D-08.

---

## List Scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Customer-scoped positional | `Paddle.Customers.Subscriptions.list(client, customer_id, params)` mirroring Phase 3 addresses | |
| Generic filter-based | `Paddle.Subscriptions.list(client, params)` with `customer_id` in params | ✓ |
| Both (generic + `list_for_customer/3`) | Generic `list/2` plus thin convenience wrapper | |
| Customer-scoped only with extra filters | `Paddle.Subscriptions.list(client, customer_id, params)` mixing positional + filter | |

**Selected option:** Generic filter-based.

**Rationale:**
- Subscriptions are NOT a child resource of customers in Paddle's API — endpoint is `GET /subscriptions`, not `GET /customers/{id}/subscriptions`. Phase 3's customer-scoped positional shape was correct *for addresses* because addresses live at `/customers/{id}/addresses` and have no global existence. Subscriptions are top-level resources queryable across orthogonal dimensions.
- Phase 3 D-12 ("preserve Paddle's ownership semantics directly") points to filter-based for subscriptions, not nested-positional.
- Multi-dimensional filtering (`customer_id` + `status` + `scheduled_change_action`) composes naturally in a single attrs map. Forcing nesting would either require a second module for cross-customer queries or break the namespace promise.
- Stripe (stripity_stripe), Paddle's own Node SDK (`paddle.subscriptions.list()`), ChargeBee, and Recurly all use filter-based listing for subscriptions.
- Phase 3 D-04 ("do not expose duplicate public API shapes") rules out the hybrid Option C.

**Result in CONTEXT.md:** D-09 through D-14.

---

## Mutation Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Strict — get/list/cancel only | Ship exactly SUB-01/SUB-02/SUB-03; defer all other mutations | ✓ |
| Strict + cancel-adjacent | Add scheduled_change inspection helpers but no new endpoints | (folded into selected) |
| Add pause/resume now | Symmetric with cancel; common SaaS lifecycle | |
| Add update + pause/resume | Maximally complete subscription mutation surface | |

**Selected option:** Strict — get/list/cancel only, with `%Paddle.Subscription.ScheduledChange{}` thin nested struct (since cancel populates it).

**Rationale:**
- v0.1 strategy is explicit and locked: REQUIREMENTS.md SUB-01/02/03 specify only get/list/cancel; PROJECT.md frames this as the "minimum viable canonical SaaS lifecycle loop"; Phase 4 set strong precedent (D-08, D-09, D-19) of strict scoping over OpenAPI mirroring.
- The SDK's stated value is opinionated curation. `update` is precisely where opinionation cost compounds — every Paddle field (proration_billing_mode, item-level changes, scheduled_change semantics, billing_details) becomes a public API decision that v0.1 has no signal to make well.
- Accrue's documented "second processor" v0.1 needs are state retrieval, listing, and cancellation. Pause/resume is a *plausible* later need but not a *demonstrated* one.
- Trigger to fold more in later: a real consumer hits a concrete lifecycle gap AND a curated, opinionated subset emerges from real usage. The bar is **demonstrated need + clear curation**, not API completeness.

**Result in CONTEXT.md:** D-01, D-03, plus the deferred-ideas list.

---

## Subscription Struct Fields

| Option | Description | Selected |
|--------|-------------|----------|
| Strict Transaction mirror | Flat scalars only; ALL nested objects as plain maps | |
| Targeted nested structs (scheduled_change + management_urls only) | Promote the two highest-DX dot-access paths; leave others raw | ✓ |
| Aggressive nested structs | Also promote current_billing_period + billing_cycle | |

**Selected option:** Targeted nested structs.

**Rationale:**
- The Phase 4 `transaction.checkout.url` carve-out succeeded because it represented the single must-hit DX path of that phase. The Phase 5 equivalents are exactly two paths:
  - `subscription.scheduled_change.effective_at` — canonical post-cancel inspection (Accrue must render "your subscription ends on X")
  - `subscription.management_urls.cancel` — customer-portal self-serve link
- Both have stable, narrow Paddle-documented shapes (3 and 2 fields), both are nullable-as-a-whole rather than partially-typed, both match the `Transaction.Checkout` precedent exactly.
- `current_billing_period` and `billing_cycle` are stable but lower-DX (Accrue's product layer already knows the cycle from price config; period inspection is ops-debugging, not happy path), so they stay as plain maps under Phase 3 D-08.
- `items` stays a list of plain maps (matches Transaction `:items/:details/:payments` precedent).
- `Http.build_struct/2` does NOT need extension — `Paddle.Subscriptions` post-processes the two nested maps after the flat build, mirroring Phase 4's `transaction.checkout` integration.

**Result in CONTEXT.md:** D-15 through D-22.

---

## Claude's Discretion

- Internal helper-module organization within `Paddle.Subscriptions` (path-building inline vs extracted).
- Test fixture shape for the new entity (mirror existing customer/transaction patterns).
- Whether `do_cancel/3`'s `effective_from` parameter is internally a string or atom-then-stringified.
- Exact docstring wording, typespec choices, module ordering.

## Deferred Ideas

(See CONTEXT.md `<deferred>` section for the full list and rationale.)

- `update/3`, `pause/3`, `resume/3`, `activate/2`, `charge/3`, `preview_update/3`, `get_update_payment_method_transaction/2`
- `cancel_at/3` (scheduled cancel at timestamp), `remove_scheduled_cancellation/2`
- `Paddle.Subscription.scheduled_to_cancel?/1` and similar additive sugar
- `%Paddle.Subscription.CurrentBillingPeriod{}`, `%Paddle.Subscription.BillingCycle{}`, `%Paddle.Subscription.Item{}` typed nested structs
- Cross-cutting ISO8601 → `DateTime` parsing for all entities
- Typed access for `:next_transaction`, `:recurring_transaction_details`, `:consent_requirements`
