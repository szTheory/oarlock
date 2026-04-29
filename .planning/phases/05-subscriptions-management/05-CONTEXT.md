# Phase 5: Subscriptions Management - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the canonical SaaS lifecycle loop for subscriptions: fetch a single subscription's state, list subscriptions filtered by customer (and other dimensions), and cancel a subscription with both end-of-period and immediate semantics. This phase introduces the `%Paddle.Subscription{}` typed entity and exposes only the locked SUB-01/SUB-02/SUB-03 surface. All other subscription mutations (update, pause, resume, activate, charge, preview-update) are deferred.

</domain>

<decisions>
## Implementation Decisions

### Public API Surface (Strict Mutation Scope)

- **D-01:** Phase 5 ships exactly three public functions on `Paddle.Subscriptions`: `get/2`, `list/2`, `cancel/2`, plus `cancel_immediately/2`. No other subscription mutations are exposed in Phase 5.
- **D-02:** Mirror the established resource-module pattern from Phase 3/4. Module path is `Paddle.Subscriptions` (sibling of `Paddle.Customers`, `Paddle.Transactions`), not nested under `Paddle.Customers`.
- **D-03:** Defer subscription update, pause, resume, activate, charge, preview-update, and update-payment-method-transaction to v0.2 or later. Trigger to fold any of these in later: a real consumer (Accrue or another) demonstrates a concrete lifecycle gap AND a curated, opinionated subset of the Paddle payload emerges from real usage. The bar is **demonstrated need + clear curation**, not API completeness.

### Cancel Semantics (Two Named Functions)

- **D-04:** Expose end-of-period and immediate cancellation as **two separately named public functions** rather than a single polymorphic function.
  - `Paddle.Subscriptions.cancel/2` — end-of-period (Paddle's `effective_from: "next_billing_period"`)
  - `Paddle.Subscriptions.cancel_immediately/2` — immediate (Paddle's `effective_from: "immediately"`)
- **D-05:** This decision extends the locked Phase 4 D-10/D-11 stance ("separately named paths over polymorphic flags or hidden modes") to Phase 5. Both cancellation modes are destructive and irreversible per Paddle's docs ("Canceled subscriptions cannot be reinstated"), so call-site clarity is a safety property, not just a style preference.
- **D-06:** Both functions return `{:ok, %Paddle.Subscription{}}` on success — Paddle returns the updated subscription on both modes (end-of-period: `status: "active"` with `scheduled_change` populated; immediate: `status: "canceled"`).
- **D-07:** Both functions share a private `do_cancel/3` helper that posts to `/subscriptions/{id}/cancel` with the appropriate `effective_from` value. No public arity-3 cancel.
- **D-08:** Future Paddle additions (e.g., scheduled cancel at a specific timestamp, removing a scheduled cancellation) get their own separately named functions when added — never retrofit `cancel/2` or `cancel_immediately/2` with a polymorphic mode arg.

### List Scoping (Generic Filter-Based, Not Customer-Scoped)

- **D-09:** Expose listing as `Paddle.Subscriptions.list(client, params \\ [])` — a single top-level function that accepts a curated filter map.
- **D-10:** Do **not** mirror Phase 3's `Paddle.Customers.Addresses.list/3` positional-customer-id pattern for subscriptions. Subscriptions are NOT a child resource of customers in Paddle's API (the endpoint is `GET /subscriptions`, not `GET /customers/{id}/subscriptions`); they are a top-level resource queryable by `customer_id` filter alongside many other dimensions. This honors the underlying Phase 3 D-12 principle ("preserve Paddle's ownership semantics directly") rather than mechanically mirroring Phase 3's signature shape.
- **D-11:** "List a customer's subscriptions" (SUB-02) is satisfied by passing `customer_id:` in the params map: `Paddle.Subscriptions.list(client, customer_id: "ctm_...")`. This keeps the SDK's filter dimensions orthogonal and composable (e.g., `customer_id: ..., status: "active"`).
- **D-12:** Allowlist for `list/2` params:
  ```
  ~w(id customer_id address_id price_id status
     scheduled_change_action collection_mode
     next_billed_at order_by after per_page)
  ```
- **D-13:** Response shape is unchanged from Phase 3: `{:ok, %Paddle.Page{data: [%Paddle.Subscription{}, ...], meta: ...}}`.
- **D-14:** Do NOT introduce a `list_for_customer/3` convenience wrapper — that violates Phase 3 D-04 ("do not expose duplicate public API shapes for the same operation").

### Subscription Entity Struct

- **D-15:** Introduce `%Paddle.Subscription{}` as a flat top-level struct in `lib/paddle/subscription.ex`, following the precedent of `%Paddle.Transaction{}`. Preserve `:raw_data` for forward compatibility (Phase 3 D-06).
- **D-16:** Field list (snake_case atom keys aligned with Paddle JSON):
  ```
  :id, :status, :customer_id, :address_id, :business_id,
  :currency_code, :collection_mode, :custom_data, :items,
  :scheduled_change, :management_urls,
  :current_billing_period, :billing_cycle, :billing_details,
  :discount, :next_billed_at, :started_at, :first_billed_at,
  :paused_at, :canceled_at, :created_at, :updated_at,
  :import_meta, :raw_data
  ```
- **D-17:** Timestamps stay as ISO8601 strings — match the existing Customer/Transaction precedent. Do NOT introduce `DateTime` parsing in Phase 5; if/when added, it lands cross-cutting for all entities at once.

### Nested Struct Promotion (Disciplined Carve-Outs)

- **D-18:** Promote exactly **two** nested objects to typed structs because their dot-access paths are the canonical DX paths consumers will hit on every cancel and portal flow:
  - `%Paddle.Subscription.ScheduledChange{}` — fields `:action, :effective_at, :resume_at, :raw_data`. Required because `cancel/2` populates this and consumers need `subscription.scheduled_change.effective_at` to render end-of-period UX. Mirrors the Phase 4 D-13 carve-out for `%Paddle.Transaction.Checkout{}`.
  - `%Paddle.Subscription.ManagementUrls{}` — fields `:update_payment_method, :cancel, :raw_data`. Required for the customer-portal self-serve link (`subscription.management_urls.cancel`).
- **D-19:** The whole `:scheduled_change` field is `nil` when no change is scheduled. The whole `:management_urls` field may be `nil` for non-portal flows.
- **D-20:** Do NOT promote `current_billing_period`, `billing_cycle`, `billing_details`, `items`, `discount`, `next_transaction`, `recurring_transaction_details`, `consent_requirements`, or `import_meta` to typed structs in Phase 5. These remain plain string-keyed maps. Reasoning: Phase 3 D-08 — "only selectively model nested objects when the shape is stable AND high-value." These are stable but lower-DX or evolving. Defer until usage proves they earn the surface.
- **D-21:** Action enum strings (`"pause" | "cancel" | "resume"` for scheduled_change, plus subscription `status`) stay as strings — no atom conversion. Matches existing precedent.

### Nested Struct Wiring

- **D-22:** Do NOT extend `Paddle.Http.build_struct/2` with a nested-fields keyword. Instead, perform per-resource post-processing inside `Paddle.Subscriptions` after `build_struct/2` returns the flat entity — same pattern Phase 4 used for `transaction.checkout` (see `lib/paddle/transactions.ex:35-45`). Wrap `data["scheduled_change"]` via `Http.build_struct(Paddle.Subscription.ScheduledChange, sc)` when non-nil; same for `data["management_urls"]`.

### Validation And Boundary Discipline

- **D-23:** Carry forward Phase 3 D-13/D-14/D-15: accept `map | keyword`, normalize via `Paddle.Internal.Attrs.normalize`, allowlist-filter writes/queries, perform only lightweight stable boundary checks (subscription_id present and nonblank, params container valid). Leave business validation (status transitions, scheduled-change conflicts, etc.) to Paddle.
- **D-24:** Path encoding for `subscription_id` follows the existing `URI.encode/2` pattern from `lib/paddle/customers.ex:48` and `lib/paddle/customers/addresses.ex:85`.

### Decision-Making Preference

- **D-25:** Continue Phase 3/4's bias toward decisive, researched defaults (D-18 from Phase 4). Surface user choices only for genuinely high-impact tradeoffs that affect product direction or public API stability. All Phase 5 decisions above were made with researcher-backed analysis and locked here so downstream agents do not re-ask.

### Claude's Discretion

- Internal helper-module organization within `Paddle.Subscriptions` (e.g., whether path-building is inline or extracted).
- Test fixture shape for the new entity (mirror existing customer/transaction test fixture patterns).
- Whether `do_cancel/3`'s `effective_from` parameter is a string or atom-then-stringified internally — both are acceptable as long as the public functions remain `cancel/2` and `cancel_immediately/2`.
- Exact docstring wording, typespec choices, and module ordering in the new files.

</decisions>

<specifics>
## Specific Ideas

- The two cancellation modes are both **destructive and irreversible** per Paddle docs — call-site clarity (`cancel_immediately/2` vs `cancel/2`) is a safety property. Stripe's Ruby/Node SDKs use `cancel` for immediate and `update(cancel_at_period_end: true)` for end-of-period; this is the most-asked Stripe support question and a textbook footgun. Two named functions sidestep that ambiguity entirely.
- `subscription.scheduled_change.effective_at` is the canonical "when does this end?" inspection after end-of-period cancellation — same DX role that `transaction.checkout.url` plays after transaction creation.
- `subscription.management_urls.cancel` is the customer-portal self-serve cancellation link — likely surfaced by Accrue (or any consumer) in end-user UI.
- Subscription listing is multi-dimensional (customer_id, status, price_id, scheduled_change_action). A nested `Paddle.Customers.Subscriptions.list/3` would lie about the URL hierarchy and cannot express "all subs scheduled to cancel" cleanly.
- Paddle's own Node SDK exposes `paddle.subscriptions.list()` as a top-level call, not nested. stripity_stripe, ChargeBee, and Recurly all use filter-based listing on subscriptions for the same reason.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope And Phase Contracts
- `.planning/PROJECT.md` — Product goals, SDK constraints, v0.1 deferments.
- `.planning/REQUIREMENTS.md` — Phase requirements `SUB-01`, `SUB-02`, `SUB-03`, plus cross-phase typed-struct/tuple-return constraints.
- `.planning/ROADMAP.md` — Phase 5 goal and success criteria.
- `.planning/STATE.md` — Current project progress and prior phase notes.

### Prior Locked Decisions
- `.planning/phases/01-core-transport-client-setup/01-CONTEXT.md` — Explicit client passing, error tuples, telemetry, pagination conventions.
- `.planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md` — Resource module pattern, allowlists, raw-data preservation, light boundary validation, decisive defaults (D-04, D-08, D-13–D-15, D-17, D-18).
- `.planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md` — Strict happy path discipline, separate named functions over polymorphic flags (D-10, D-11), tiny nested struct precedent for `transaction.checkout` (D-13), curated attrs (D-04 through D-08), decisive defaults preference (D-18).

### Supporting Prior Analysis
- `.planning/phases/03-core-entities-customers-addresses/03-RESEARCH.md` — Thin resource modules over the transport boundary, allowlist discipline.
- `.planning/phases/03-core-entities-customers-addresses/03-PATTERNS.md` — Existing request/response and struct-mapping patterns.
- `.planning/phases/04-transactions-hosted-checkout/04-RESEARCH.md` — Resource-module + curated-attrs reasoning for billing entities.
- `.planning/phases/04-transactions-hosted-checkout/04-PATTERNS.md` — Per-resource post-processing pattern for nested structs.

### Paddle API Reference
- `https://developer.paddle.com/api-reference/subscriptions/get-subscription` — SUB-01 endpoint and response shape.
- `https://developer.paddle.com/api-reference/subscriptions/list-subscriptions` — SUB-02 endpoint, filter dimensions, pagination shape.
- `https://developer.paddle.com/api-reference/subscriptions/cancel-subscription` — SUB-03 endpoint and `effective_from` semantics.
- `https://developer.paddle.com/build/lifecycle/subscription-pause-resume` — Reference for deferred lifecycle mutations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/paddle/http.ex` — `request/4` is the success/error transport boundary; `build_struct/2` handles flat top-level mapping with `raw_data` preservation. No changes required for Phase 5.
- `lib/paddle/client.ex` — `%Paddle.Client{}` remains the entry point for all public operations.
- `lib/paddle/error.ex` — `%Paddle.Error{}` remains the public non-2xx failure shape.
- `lib/paddle/page.ex` — `%Paddle.Page{}` and `Page.next_cursor/1` back the `list/2` response.
- `lib/paddle/internal/attrs.ex` — `normalize/1`, `normalize_keys/1`, `allowlist/2` cover all Phase 5 attr/param handling.
- `lib/paddle/transactions.ex:35-45` — Per-resource post-processing precedent for wrapping a nested `checkout` map into `%Paddle.Transaction.Checkout{}`. Phase 5 mirrors this for `scheduled_change` and `management_urls`.
- `lib/paddle/customers.ex:48` and `lib/paddle/customers/addresses.ex:85` — Path encoding via `URI.encode(id, &URI.char_unreserved?/1)`.
- `lib/paddle/customers.ex:38-46` — ID validation precedent (`validate_customer_id/1`) for the new `validate_subscription_id/1`.

### Established Patterns
- Public functions take `%Paddle.Client{}` explicitly.
- Success → `{:ok, struct}` or `{:ok, %Paddle.Page{}}`; API failures → `{:error, %Paddle.Error{}}`; transport exceptions surface unchanged.
- Entity structs promote common top-level Paddle fields, keep nested/dynamic payloads lightweight, preserve full payloads in `:raw_data`.
- Tiny nested struct only when a documented dot-access DX path materially benefits (Phase 4 D-13).
- Request attrs/params normalized from `map | keyword`, filtered through allowlists, snake_case at the SDK boundary.

### Integration Points
- New files:
  - `lib/paddle/subscriptions.ex` — public resource module (`get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`).
  - `lib/paddle/subscription.ex` — `%Paddle.Subscription{}` flat entity struct.
  - `lib/paddle/subscription/scheduled_change.ex` — `%Paddle.Subscription.ScheduledChange{}` tiny nested struct.
  - `lib/paddle/subscription/management_urls.ex` — `%Paddle.Subscription.ManagementUrls{}` tiny nested struct.
- `Paddle.Subscriptions` calls into `Paddle.Http.request/4` for transport, performs the `"data"` envelope unwrap locally (matching Phase 3/4 pattern), and post-processes nested structs.
- Phase 5 sits directly on top of customer/address foundations (Phase 3) and transaction foundations (Phase 4) — no alternate identity flows.

</code_context>

<deferred>
## Deferred Ideas

- `Paddle.Subscriptions.update/3` — highest-surface mutation in Paddle's subscription API. Defer until a real consumer demonstrates a hot path and a curated subset (e.g., "swap price_id only", "change quantity only") emerges from usage rather than exposing the full Paddle update payload.
- `Paddle.Subscriptions.pause/3` and `resume/3` — symmetric, low-cost; pull forward in v0.2 if Accrue or another consumer hits a real lifecycle-recovery gap (billing-failure pause, dunning pause, trial pause).
- `Paddle.Subscriptions.activate/2` (trialing → active) — niche; only relevant for trial-led flows.
- `Paddle.Subscriptions.charge/3` (one-time charge on subscription) — adjacent to invoices, which are explicitly out of scope per `PROJECT.md`.
- `Paddle.Subscriptions.preview_update/3` — depends on `update` shipping first.
- `Paddle.Subscriptions.get_update_payment_method_transaction/2` — ties into payment method portals, deferred per `PROJECT.md`.
- `Paddle.Subscriptions.cancel_at/3` (scheduled cancel at a specific timestamp) — if Paddle adds it, ship as a third named function rather than retrofitting `cancel/2`.
- `Paddle.Subscriptions.remove_scheduled_cancellation/2` — separately named when added (D-08 logic).
- Public helpers like `Paddle.Subscription.scheduled_to_cancel?/1` — additive sugar; only add when usage proves it earns the surface (Phase 4 D-14 precedent).
- `%Paddle.Subscription.CurrentBillingPeriod{}`, `%Paddle.Subscription.BillingCycle{}`, `%Paddle.Subscription.Item{}` typed nested structs — defer until usage proves period inspection / item access is hot.
- Cross-cutting ISO8601 → `DateTime` parsing for all entity timestamps — should land for all entities at once, not in Phase 5.
- `:next_transaction`, `:recurring_transaction_details`, `:consent_requirements` typed access — situational and evolving.

</deferred>

---

*Phase: 05-subscriptions-management*
*Context gathered: 2026-04-28*
