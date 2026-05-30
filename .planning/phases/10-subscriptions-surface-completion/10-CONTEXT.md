# Phase 10: Subscriptions Surface Completion - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete the high-value subscription lifecycle surface for oarlock's v1.2 production-readiness milestone while preserving the locked Accrue seam.

This phase corrects the roadmap's stale direct-create assumption: Paddle Billing does not expose a direct create-subscription operation. Subscriptions are created by recurring checkout or manually-collected transaction flows, then materialized asynchronously by Paddle. Phase 10 therefore treats `Paddle.Transactions.create/3` as the canonical recurring-start seam and focuses new `Paddle.Subscriptions` work on real subscription lifecycle mutations: pause and resume.

In scope:
- Correct SUB-04 from "direct `Paddle.Subscriptions.create/2`" to transaction-driven subscription start documentation/tests.
- Add `Paddle.Subscriptions.pause/3` and `Paddle.Subscriptions.pause_immediately/3`.
- Add `Paddle.Subscriptions.resume/3` with immediate default and narrow options.
- Preserve `%Paddle.Subscription{}` locked struct shape; any new Paddle response data remains available through `raw_data`.
- Update `guides/accrue-seam.md` and targeted tests so the public contract matches the real Paddle model.

Out of scope:
- Public `Paddle.Subscriptions.create/2`.
- Synthetic orchestration that hides transaction/checkout/webhook subscription materialization behind a fake subscription create API.
- `Paddle.Subscriptions.update/3`, preview-update, one-time charge, payment-method update transaction, customer portal sessions, refunds/adjustments, catalog support, and app-local sync.
- Phoenix, Plug, Ecto, LiveView, database, or admin UI code.

</domain>

<decisions>
## Implementation Decisions

### SUB-04 correction: subscription start is transaction-driven

- **D-01:** Do not add `Paddle.Subscriptions.create/2` in Phase 10. Paddle's current Billing API explicitly says subscriptions cannot be created directly; creating a public direct-create function would be a provider-model lie.
- **D-02:** Correct SUB-04 to: recurring subscription start is driven by `Paddle.Transactions.create/3`, followed by checkout completion or manually-collected invoice issuance, webhook correlation, and canonical `Paddle.Subscriptions.get/2` hydration.
- **D-03:** The recurring-start acceptance path is:
  1. `Paddle.Transactions.create(client, attrs, opts)` starts the recurring flow for recurring price items.
  2. Automatically-collected transactions expose `transaction.checkout.url` for hosted checkout handoff.
  3. Paddle creates the subscription after checkout completion or billed manually-collected transaction flow.
  4. Consumers correlate with `subscription.created` webhook `transaction_id` and/or `Paddle.Transactions.get/2` returning `subscription_id`.
  5. Consumers fetch the canonical typed subscription via `Paddle.Subscriptions.get/2`.
- **D-04:** Do not add `Paddle.Subscriptions.start_checkout/3` in Phase 10. Although truthful, it would duplicate the transaction surface, blur module ownership, and create long-term API clutter. The best DX here is honest documentation around the existing transaction seam.
- **D-05:** Update `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md` in planning or execution if the workflow permits requirement mutation; at minimum, Phase 10 plans must treat `Paddle.Subscriptions.create/2` as explicitly rejected.
- **D-06:** Update `guides/getting-started.md` and `guides/accrue-seam.md` so outside adopters do not assume "billing SDK" means direct subscription creation. The guide should say: start with a recurring transaction, then reconcile the subscription.

### Pause surface

- **D-07:** Expose two named pause entry points:
  - `Paddle.Subscriptions.pause(client, subscription_id, opts \\ [])`
  - `Paddle.Subscriptions.pause_immediately(client, subscription_id, opts \\ [])`
- **D-08:** `pause/3` always sends `effective_from: "next_billing_period"`. `pause_immediately/3` always sends `effective_from: "immediately"`. Do not expose raw `effective_from` as a public option.
- **D-09:** This mirrors the Phase 5 cancel split (`cancel/2` vs `cancel_immediately/2`) because the timing distinction is a safety property at the call site. A mode flag such as `pause(..., effective_from: :immediately)` reintroduces the exact polymorphic-footgun class Phase 5 avoided for cancellation.
- **D-10:** Support exactly these pause-behavior options on both pause functions:
  - `resume_at:` RFC3339 timestamp or `DateTime.t()`, encoded as RFC3339.
  - `on_resume:` `:start_new_billing_period | :continue_existing_billing_period`, with equivalent Paddle string values accepted.
- **D-11:** Reject invalid pause options explicitly with local validation errors (`:invalid_resume_at`, `:invalid_on_resume`, or planner-equivalent names). Do not silently drop unknown lifecycle options.
- **D-12:** `pause/*` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or local validation tuples such as `{:error, :invalid_subscription_id}`. The returned subscription may still have `status: "active"` for scheduled pause, with the scheduled change captured in `scheduled_change`.

### Resume surface

- **D-13:** Expose one resume entry point: `Paddle.Subscriptions.resume(client, subscription_id, opts \\ [])`.
- **D-14:** Omitted `:effective_from` means immediate resume. This keeps `resume/2` as the obvious happy path without adding a redundant `resume_immediately/2`.
- **D-15:** Support exactly these resume-behavior options:
  - `effective_from:` `:immediately | DateTime.t() | RFC3339 binary`.
  - `on_resume:` `:start_new_billing_period | :continue_existing_billing_period`, with equivalent Paddle string values accepted.
- **D-16:** Do not add public variants such as `resume_immediately/*`, `resume_at/*`, or command structs in Phase 10. Resume is one provider operation and the extra names would enlarge the seam without adding capability.
- **D-17:** Validate option values at the SDK boundary (`:invalid_effective_from`, `:invalid_on_resume`, or planner-equivalent names) and pass Paddle state errors through unchanged. State-dependent failures like missing payment method or invalid continue-existing-billing-period behavior belong to Paddle.
- **D-18:** Documentation must warn that immediate resume can charge immediately, and that resume may emit subscription and transaction events. Callers should reconcile via webhooks and canonical fetches, not assume the local request alone is the whole billing story.

### Mutation opts boundary

- **D-19:** Keep the Phase 8 idempotency boundary: `:idempotency_key` is create/start-flow-only. It remains valid for `Paddle.Transactions.create/3` and other public create functions, including any future real create/start surface where Paddle supports the semantics.
- **D-20:** Add trailing request opts to pause/resume only for per-call retry control. `pause/*` and `resume/*` support `retry: false | true`; they do not support `idempotency_key:`.
- **D-21:** If callers pass `idempotency_key:` to `pause/*` or `resume/*`, reject explicitly, preferably with `ArgumentError`, rather than silently forwarding or dropping it. False idempotency safety on lifecycle mutations is worse than a loud unsupported-option failure.
- **D-22:** Keep lifecycle-behavior opts (`resume_at`, `effective_from`, `on_resume`) separate from request opts (`retry`) in implementation, even if they share one public `opts` keyword list. The planner should avoid raw `Keyword.merge([json: body], opts)` forwarding for pause/resume because it would leak lifecycle keys into `Req.request/2`.
- **D-23:** Do not expose broad passthrough opts, `max_retries`, `retry_delay`, timeout knobs, or Req internals in Phase 10. Phase 8 already rejected those for the locked v1.2 public vocabulary.

### Contract and test discipline

- **D-24:** Preserve `%Paddle.Subscription{}` fields exactly. Phase 10 must add a struct-shape regression test showing no locked fields were added, removed, or renamed.
- **D-25:** Add adapter-backed request/response tests for `pause/3`, `pause_immediately/3`, and `resume/3`: method, path encoding, JSON body, retry forwarding, invalid ID, invalid opts, Paddle error passthrough, transport-error normalization, and nested `scheduled_change` / `management_urls` hydration.
- **D-26:** Add or update seam tests only at the public boundary. Do not full-fixture-match Paddle payloads. Assert typed structs, selected locked fields, and `raw_data` presence.
- **D-27:** Update `guides/accrue-seam.md` to list the new public functions under `Paddle.Subscriptions`, remove stale "pause/resume out of scope" wording, and keep `Paddle.Subscriptions.create/2` out of the public seam.

### the agent's Discretion

- Exact private helper layout inside `lib/paddle/subscriptions.ex` (`do_pause/4`, `build_pause_body/2`, `normalize_lifecycle_opts/1`, etc.).
- Exact local validation atom names for malformed lifecycle options, as long as they are explicit and tested.
- Whether `DateTime` encoding accepts only UTC or any `DateTime.t()` with offset normalization. Prefer standard library formatting and document the accepted shape.
- Exact docs wording and examples, as long as they preserve the provider-native truth: transaction starts the recurring flow; subscription mutations operate on an existing Paddle subscription.
- Whether tests for request-option rejection live in `subscriptions_test.exs` only or share lower-level helpers with `http_test.exs`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and locked local decisions

- `.planning/PROJECT.md` - v1.2 production-surface goal, Accrue consumer framing, pure SDK constraints, no Phoenix/Ecto coupling, locked struct seam.
- `.planning/REQUIREMENTS.md` - Current SUB-04/SUB-05/SUB-06 wording; Phase 10 planning must correct SUB-04.
- `.planning/ROADMAP.md` - Phase 10 goal and success criteria; treat direct `Subscriptions.create/2` language as stale after this discussion.
- `.planning/STATE.md` - Release-truth reset note and explicit warning to revalidate direct subscription create before planning.
- `.planning/research/JTBD-GAPS.md` - Maintainer strategy note that direct subscription create needs revalidation and recurring-start should be transaction-driven.
- `prompts/oarlock-master-context.md` - Core DNA: explicit client passing, typed responses, transaction/checkout-driven first slice, no framework coupling.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` - Accrue slice mapping: hosted checkout for recurring product, webhook-driven subscription sync, canonical fetch, cancellation.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` - Paddle-native strategy and warning against Stripe-shaped parity.
- `prompts/oarlock-brand-book.md` - Provider-native, small, explicit, honest public positioning.
- `prompts/paddle-elixir-lib-deep-research.md` - Original research brief and confirmed Paddle Billing/current API framing.

### Prior phase context

- `.planning/phases/08-reliability-primitives/08-CONTEXT.md` - `idempotency_key:` and `retry:` vocabulary; create-only idempotency boundary; no broad Req option leakage.
- `.planning/phases/09-pagination-ergonomics-0-plans/09-CONTEXT.md` - Resource-module-first public API and seam-preserving additive surface discipline.
- `.planning/milestones/archived-phases/05-subscriptions-management/05-CONTEXT.md` - Existing `Paddle.Subscriptions` semantics, cancel/cancel_immediately split, flat subscription struct, nested scheduled_change and management_urls hydration.
- `.planning/milestones/archived-phases/07-accrue-seam-lock/07-CONTEXT.md` - Closed public seam, field tier policy, semantic seam-test discipline, decisive-default preference.

### Existing code and docs

- `lib/paddle/subscriptions.ex` - Add pause/resume functions here; reuse existing ID validation, path encoding, nested hydration, and page/list patterns.
- `lib/paddle/transactions.ex` - Existing `create/3` is the corrected recurring-start entrypoint; document/test it instead of inventing `Subscriptions.create/2`.
- `lib/paddle/http.ex` - Request opts boundary, idempotency-key handling, retry passthrough, and error normalization.
- `lib/paddle/client.ex` - Client-level Req retry baseline; pause/resume need per-call `retry:` override support.
- `lib/paddle/subscription.ex` - Locked struct field list; Phase 10 must preserve it.
- `test/paddle/subscriptions_test.exs` - Existing adapter-backed subscription test patterns; add pause/resume coverage here.
- `test/paddle/seam_test.exs` - Accrue seam proof; preserve semantic boundary and update only if Phase 10 intentionally expands the seam.
- `guides/accrue-seam.md` - Public contract guide to update with pause/resume and corrected subscription-start wording.
- `guides/getting-started.md` - Already warns about transaction-driven subscription start; keep aligned with Phase 10 decisions.

### Paddle official docs

- `https://developer.paddle.com/api-reference/subscriptions/` - Subscription overview; says subscriptions cannot be created directly and are created through checkout or manually-collected transactions.
- `https://developer.paddle.com/api-reference/transactions/create-transaction/` - `POST /transactions`; automatically-collected transactions return checkout URL and create related subscriptions for recurring items when completed.
- `https://developer.paddle.com/api-reference/subscriptions/pause-subscription/` - `POST /subscriptions/{subscription_id}/pause`; `effective_from`, `resume_at`, and `on_resume` behavior.
- `https://developer.paddle.com/api-reference/subscriptions/resume-subscription/` - `POST /subscriptions/{subscription_id}/resume`; only paused subscriptions can resume, scheduled-pause resume date may be changed, canceled subscriptions cannot resume.
- `https://developer.paddle.com/webhooks/subscriptions/subscription-created/` - Webhook correlation surface for subscription materialization.
- `https://developer.paddle.com/webhooks/subscriptions/subscription-resumed/` - Resume event to mention in docs and reconciliation guidance.
- `https://developer.paddle.com/api-reference/about/rate-limiting/` - Retry/rate-limit context for per-call `retry:` decisions.
- `https://developer.paddle.com/errors/subscriptions/subscription_continuing_existing_billing_period_not_allowed/` - State-dependent `on_resume` provider error.
- `https://developer.paddle.com/errors/subscriptions/subscription_continuing_existing_billing_period_not_allowed_subscription_past_due/` - Past-due variant of continue-existing-billing-period error.
- `https://developer.paddle.com/errors/subscriptions/subscription_missing_payment_method_cannot_resume/` - Resume provider error that must pass through unchanged.

### Ecosystem precedents and footguns

- `https://hexdocs.pm/elixir/keywords-and-maps.html` - Keyword opts are idiomatic for optional behavior on Elixir functions.
- `https://hexdocs.pm/elixir/naming-conventions.html` - Function naming and bang/non-bang conventions.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - Elixir precedent for opts-last APIs with explicit behavior, not broad magical config.
- `https://hexdocs.pm/plug/Plug.Conn.html` - Plug/Phoenix ecosystem preference for explicit, composable data flow; no core framework coupling.
- `https://docs.stripe.com/api/subscriptions/create` - Stripe has direct subscription creation; this is a footgun when porting Stripe mental models to Paddle.
- `https://docs.stripe.com/billing/subscriptions/cancel` - Cancellation timing confusion in Stripe-shaped APIs informs oarlock's separate named cancel/pause safety split.
- `https://docs.stripe.com/api/idempotent_requests` - Idempotency lessons and caveats; avoid false safety.
- `https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/` - Retry/idempotency ownership precedent.
- `https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2` - HTTP idempotency semantics for retry decisions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Paddle.Subscriptions.validate_subscription_id/1` already returns `{:error, :invalid_subscription_id}` for nil, blank, whitespace, and non-binary IDs.
- `Paddle.Subscriptions.build_subscription/1` already hydrates `scheduled_change` and `management_urls` nested structs; pause/resume responses should reuse it.
- `Paddle.Subscriptions.subscription_path/1` and `encode_path_segment/1` already encode subscription IDs for `get` and cancel; pause/resume should follow the same path pattern.
- `Paddle.Http.request/4` already forwards `retry:` through Req and normalizes HTTP/transport failures.
- `Paddle.Http.request/4` already raises on invalid `idempotency_key:`; pause/resume should prevent unsupported idempotency keys before forwarding.
- `Paddle.Transactions.create/3` already accepts `opts \\ []`, validates attrs, returns typed `%Paddle.Transaction{}` with `%Checkout{}` hydration, and supports `idempotency_key:`.

### Established Patterns

- Public functions take `%Paddle.Client{}` explicitly and return tagged tuples.
- Resource modules own endpoint-specific validation, allowlisting, path construction, and response hydration.
- Request attrs and params accept `map | keyword`, normalize to string-key maps, and allowlist public keys.
- Tests use inline `Req.new(adapter: fn request -> ... end)` clients; no live Paddle calls, Bypass, ExVCR, or fixture replay server.
- Public seam is closed and enumerated in `guides/accrue-seam.md`; internals remain hidden via `@moduledoc false`.

### Integration Points

- Add pause/resume code to `lib/paddle/subscriptions.ex`, near the existing cancel functions.
- Add tests to `test/paddle/subscriptions_test.exs`, likely new `describe "pause/3"`, `"pause_immediately/3"`, and `"resume/3"` blocks.
- Update `guides/accrue-seam.md` public module table and unsupported-surface wording.
- Update `guides/getting-started.md` only if wording around pause/resume or subscription start needs tightening after implementation.
- Planning should decide whether to create a small private opts normalizer in `Paddle.Subscriptions` or a hidden shared helper only if multiple lifecycle operations need the same conversion.

</code_context>

<specifics>
## Specific Ideas

Preferred public examples:

```elixir
{:ok, transaction} =
  Paddle.Transactions.create(client, attrs,
    idempotency_key: "accrue:checkout:#{checkout_id}:attempt:#{attempt}"
  )

checkout_url = transaction.checkout.url

{:ok, subscription} = Paddle.Subscriptions.get(client, subscription_id)

{:ok, subscription} = Paddle.Subscriptions.pause(client, subscription_id)

{:ok, subscription} =
  Paddle.Subscriptions.pause_immediately(client, subscription_id,
    resume_at: ~U[2026-07-01 00:00:00Z],
    on_resume: :start_new_billing_period,
    retry: false
  )

{:ok, subscription} =
  Paddle.Subscriptions.resume(client, subscription_id,
    effective_from: :immediately,
    on_resume: :continue_existing_billing_period,
    retry: false
  )
```

Docs should explicitly say:
- Start recurring subscriptions through transaction/checkout or manually-collected transaction flows.
- Webhooks and canonical fetches are part of the subscription materialization story.
- Scheduled pause can return an active subscription with `scheduled_change` populated.
- Immediate resume can charge immediately depending on `on_resume` and billing-period state.
- `idempotency_key:` is for create/start-flow calls, not pause/resume.

</specifics>

<deferred>
## Deferred Ideas

- Public `Paddle.Subscriptions.create/2` - explicitly rejected because Paddle Billing has no direct create-subscription endpoint.
- Public `Paddle.Subscriptions.start_checkout/3` - truthful but redundant; defer unless real consumer evidence shows the transaction namespace is too hard to discover.
- `Paddle.Subscriptions.update/3`, `preview_update/3`, one-time charge, activate trialing subscription, and payment-method update transaction - valid future lifecycle/API surfaces, but out of Phase 10.
- Public customer portal session helpers - higher-value post-v1.2 work, separate from exposing returned `management_urls`.
- Refunds/credits via adjustments - planned as a future support workflow after v1.2.
- Broad lifecycle command structs - too much ceremony for the current codebase; revisit after Phase 11 typespec pass if the API matrix grows.
- Idempotency keys on pause/resume - rejected for Phase 10 because it creates false provider-safety expectations.

</deferred>

---

*Phase: 10-subscriptions-surface-completion*
*Context gathered: 2026-05-30*
