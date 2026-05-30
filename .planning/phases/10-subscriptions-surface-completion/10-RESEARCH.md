# Phase 10: subscriptions-surface-completion - Research

**Researched:** 2026-05-30  
**Domain:** Elixir Paddle SDK subscription lifecycle surface (transaction-driven start + pause/resume mutations)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `10-CONTEXT.md` per workflow requirement. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

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

Copied verbatim from `10-CONTEXT.md` per workflow requirement. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

- Exact private helper layout inside `lib/paddle/subscriptions.ex` (`do_pause/4`, `build_pause_body/2`, `normalize_lifecycle_opts/1`, etc.).
- Exact local validation atom names for malformed lifecycle options, as long as they are explicit and tested.
- Whether `DateTime` encoding accepts only UTC or any `DateTime.t()` with offset normalization. Prefer standard library formatting and document the accepted shape.
- Exact docs wording and examples, as long as they preserve the provider-native truth: transaction starts the recurring flow; subscription mutations operate on an existing Paddle subscription.
- Whether tests for request-option rejection live in `subscriptions_test.exs` only or share lower-level helpers with `http_test.exs`.

### Deferred Ideas (OUT OF SCOPE)

Copied verbatim from `10-CONTEXT.md` per workflow requirement. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

- Public `Paddle.Subscriptions.create/2` - explicitly rejected because Paddle Billing has no direct create-subscription endpoint.
- Public `Paddle.Subscriptions.start_checkout/3` - truthful but redundant; defer unless real consumer evidence shows the transaction namespace is too hard to discover.
- `Paddle.Subscriptions.update/3`, `preview_update/3`, one-time charge, activate trialing subscription, and payment-method update transaction - valid future lifecycle/API surfaces, but out of Phase 10.
- Public customer portal session helpers - higher-value post-v1.2 work, separate from exposing returned `management_urls`.
- Refunds/credits via adjustments - planned as a future support workflow after v1.2.
- Broad lifecycle command structs - too much ceremony for the current codebase; revisit after Phase 11 typespec pass if the API matrix grows.
- Idempotency keys on pause/resume - rejected for Phase 10 because it creates false provider-safety expectations.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUB-04 | `Paddle.Subscriptions.create/2` create requirement text in current REQUIREMENTS/ROADMAP is stale and must be corrected to transaction-driven recurring start. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] | Uses `Paddle.Transactions.create/3` + checkout/webhook correlation + `Paddle.Subscriptions.get/2`; no new `Subscriptions.create/2` API. [CITED: https://developer.paddle.com/api-reference/subscriptions/overview; CITED: https://developer.paddle.com/api-reference/transactions/create-transaction; CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-created/] |
| SUB-05 | Add pause surface for existing subscriptions with explicit timing-safe API shape. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] | Implement `pause/3` + `pause_immediately/3`, validate lifecycle opts, preserve typed hydration and seam shape. [CITED: https://developer.paddle.com/api-reference/subscriptions/pause-subscription; VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `test/paddle/subscriptions_test.exs`] |
| SUB-06 | Add resume surface for paused subscriptions with default immediate behavior and state/error passthrough. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] | Implement `resume/3` with `effective_from` + `on_resume`, map provider state behavior, keep seam unchanged. [CITED: https://developer.paddle.com/api-reference/subscriptions/resume-subscription/; CITED: https://developer.paddle.com/errors/subscriptions/subscription_missing_payment_method_cannot_resume; CITED: https://developer.paddle.com/errors/subscriptions/subscription_continuing_existing_billing_period_not_allowed/] |
</phase_requirements>

## Summary

Phase 10 planning is primarily a **requirements correction + mutation-surface completion** phase, not a direct-create feature phase. Current locked context rejects `Paddle.Subscriptions.create/2` and replaces SUB-04 with transaction-driven recurring-start behavior, aligned to Paddle's current official model that subscriptions are created indirectly through checkout or billed manual transactions. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; CITED: https://developer.paddle.com/api-reference/subscriptions/overview; CITED: https://developer.paddle.com/api-reference/transactions/create-transaction]

The implementation work should stay concentrated in `Paddle.Subscriptions` and reuse existing Phase 5/8 primitives: ID/path validation, typed nested hydration (`scheduled_change`, `management_urls`), `Paddle.Http.request/4` error normalization, and explicit request-option boundaries. The largest technical risk is option leakage (`Keyword.merge([json: body], opts)`) for lifecycle opts; planner tasks should force explicit separation of lifecycle vs request opts and explicit rejection of unsupported `idempotency_key:` on pause/resume. [VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `lib/paddle/http.ex`; VERIFIED: `.planning/phases/08-reliability-primitives/08-CONTEXT.md`; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

Testing scope is clear and bounded: extend adapter-backed subscription tests for pause/resume request/response/error behavior, add a stricter subscription struct-shape regression that fails on added/removed/renamed fields, update seam docs (`guides/accrue-seam.md`) to include pause/resume and remove stale out-of-scope wording, and keep existing seam boundary tests green. [VERIFIED: `test/paddle/subscriptions_test.exs`; VERIFIED: `test/paddle/subscription_test.exs`; VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `guides/accrue-seam.md`]

**Primary recommendation:** Plan Phase 10 as three slices: (1) SUB-04 correction/docs/tests around transaction-driven start, (2) `pause/3` + `pause_immediately/3`, (3) `resume/3` + seam/struct regression hardening. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

## Project Constraints (from AGENTS.md)

- `AGENTS.md` is not present in project root, so there are no additional project-local agent directives to enforce beyond existing planning artifacts. [VERIFIED: filesystem check]
- No project-local `.codex/skills/` or `.agents/skills/` directories exist, so no additional project skill rules apply. [VERIFIED: filesystem check]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Recurring subscription start (corrected SUB-04) | API / Backend | Webhook/Event Processing | Start call is `POST /transactions`; subscription materialization is asynchronous and confirmed via webhooks + canonical fetch. [CITED: https://developer.paddle.com/api-reference/transactions/create-transaction; CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-created/] |
| Pause subscription | API / Backend | Database/Storage (consumer-side state) | SDK submits `POST /subscriptions/{id}/pause`, then consumer reconciles state/events externally. [CITED: https://developer.paddle.com/api-reference/subscriptions/pause-subscription] |
| Resume subscription | API / Backend | Webhook/Event Processing | Resume may charge immediately and emits follow-on transaction events; reconciliation is event-driven. [CITED: https://developer.paddle.com/api-reference/subscriptions/resume-subscription/; CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-resumed/] |
| Seam lock preservation (`%Paddle.Subscription{}`) | API / Backend (typed mapping) | Documentation | Struct field contract is in code + seam guide; new provider fields must stay in `raw_data`. [VERIFIED: `lib/paddle/subscription.ex`; VERIFIED: `guides/accrue-seam.md`] |
| Retry/idempotency boundary | API / Backend transport layer | — | `idempotency_key` and per-call `retry` are enforced at HTTP boundary; lifecycle APIs must not widen this vocabulary. [VERIFIED: `lib/paddle/http.ex`; VERIFIED: `.planning/phases/08-reliability-primitives/08-CONTEXT.md`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req` | Locked `0.5.17` (latest `0.5.18` released 2026-05-20) | HTTP transport, retries, adapter-backed testing | Already wired in client and transport (`Paddle.Client`, `Paddle.Http`) and phase work extends existing path. [VERIFIED: Hex.pm via `mix hex.info req`; VERIFIED: `mix.exs`; VERIFIED: `lib/paddle/client.ex`; VERIFIED: `lib/paddle/http.ex`] |
| `telemetry` | Locked `1.4.1` (latest `1.4.2` released 2026-05-11) | Request instrumentation on `Req` client | Existing client pipeline already attaches telemetry; no new instrumentation framework needed. [VERIFIED: Hex.pm via `mix hex.info telemetry`; VERIFIED: `mix.exs`; VERIFIED: `lib/paddle/client.ex`] |
| `Paddle.Http.request/4` (local transport primitive) | Repo local | Idempotency header handling, retry passthrough, response/error normalization | Single chokepoint for request options and error mapping; phase should reuse, not bypass. [VERIFIED: `lib/paddle/http.ex`] |
| `Paddle.Subscriptions` (resource module) | Repo local | Public pause/resume API and typed hydration | Existing module already handles IDs, path encoding, and nested hydration patterns used by cancel/get/list. [VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `test/paddle/subscriptions_test.exs`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jason` | Locked `1.4.4` (latest stable `1.4.5` released 2026-05-05) | JSON decode in adapter-backed request assertions | Keep for test request-body assertions (`decode_json_body/1`) and no new JSON library additions. [VERIFIED: Hex.pm via `mix hex.info jason`; VERIFIED: `test/paddle/subscriptions_test.exs`] |
| `ExUnit` / adapter closures | Elixir stdlib | Deterministic offline contract tests | Standard for endpoint path/body assertions and error passthrough checks in this repo. [VERIFIED: `test/paddle/subscriptions_test.exs`; VERIFIED: `test/paddle/seam_test.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Correcting SUB-04 to transaction-driven start | Add `Paddle.Subscriptions.create/2` wrapper | Rejected because official Paddle model says direct create does not exist; wrapper would be a misleading seam. [CITED: https://developer.paddle.com/api-reference/subscriptions/overview; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] |
| Named pause functions (`pause/3`, `pause_immediately/3`) | Single `pause/3` with mode opt | Rejected safety-wise; increases call-site ambiguity already avoided by `cancel`/`cancel_immediately`. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; VERIFIED: `lib/paddle/subscriptions.ex`] |
| Single `resume/3` with default immediate | `resume_immediately/*` + `resume_at/*` variants | Rejected seam bloat for one provider operation. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] |

**Installation:**
```bash
# No new external dependencies are required for Phase 10.
mix deps.get
```

**Version verification (Hex ecosystem):**
```bash
mix hex.info req
mix hex.info telemetry
mix hex.info jason
```

## Package Legitimacy Audit

No new external package installation is required for this phase, so the package legitimacy gate is not triggered. [VERIFIED: `mix.exs`; VERIFIED: phase scope in `10-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none (no new package additions) | — | — | — | — | — | Not applicable |

**Packages removed due to slopcheck [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Recurring Start (corrected SUB-04)

Consumer App
  -> Paddle.Transactions.create/3
    -> Paddle.Http.request/4 -> Req -> POST /transactions
      -> Paddle returns transaction (+ checkout.url for automatic collection)
        -> Customer completes checkout OR invoice is billed
          -> Paddle emits subscription.created (includes transaction_id)
            -> Consumer correlates event + transaction_id/subscription_id
              -> Paddle.Subscriptions.get/2
                -> typed %Paddle.Subscription{} (+ raw_data escape hatch)
```

```text
Pause/Resume Mutation Flow

Consumer App
  -> Paddle.Subscriptions.pause/3 | pause_immediately/3 | resume/3
    -> validate subscription_id + lifecycle opts + request opts split
      -> Paddle.Http.request/4 (retry only; reject idempotency_key)
        -> Req -> POST /subscriptions/{id}/pause|resume
          -> Paddle returns updated subscription payload
            -> build_subscription/1 hydrates scheduled_change + management_urls
              -> {:ok, %Paddle.Subscription{... raw_data: full payload}}
```

### Recommended Project Structure

```text
lib/
└── paddle/
    ├── subscriptions.ex                 # add pause/resume public functions and private body/opts normalizers
    ├── subscription.ex                  # locked top-level struct shape (unchanged fields)
    └── subscription/
        ├── scheduled_change.ex          # locked nested struct
        └── management_urls.ex           # locked nested struct

test/
└── paddle/
    ├── subscriptions_test.exs           # adapter-backed pause/resume transport + validation + passthrough tests
    ├── subscription_test.exs            # strict struct-shape regression (no added/removed/renamed fields)
    └── seam_test.exs                    # boundary behavior still green, no payload over-freezing

guides/
├── accrue-seam.md                       # public seam listing and out-of-scope update
└── getting-started.md                   # recurring-start truth + lifecycle narrative alignment
```

### Pattern 1: Timing-Safe Named Mutation APIs
**What:** Keep distinct function names for materially different billing timing semantics. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]  
**When to use:** Any lifecycle mutation where immediate vs scheduled behavior affects charges or irreversibility. [CITED: https://developer.paddle.com/api-reference/subscriptions/pause-subscription; CITED: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription/]  
**Example:**
```elixir
# Source: local pattern in lib/paddle/subscriptions.ex + 10-CONTEXT decisions
def pause(%Client{} = client, subscription_id, opts \\ []) do
  do_pause(client, subscription_id, "next_billing_period", opts)
end

def pause_immediately(%Client{} = client, subscription_id, opts \\ []) do
  do_pause(client, subscription_id, "immediately", opts)
end
```

### Pattern 2: Resource-Local Nested Hydration + raw_data Preservation
**What:** Build top-level struct with `Http.build_struct/2`, then explicitly hydrate selected nested locked structs while preserving full provider payload in `raw_data`. [VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `guides/accrue-seam.md`]  
**When to use:** Endpoints returning nested objects whose dot-access is part of public DX (`scheduled_change`, `management_urls`). [VERIFIED: `.planning/milestones/archived-phases/05-subscriptions-management/05-CONTEXT.md`]  
**Example:**
```elixir
# Source: lib/paddle/subscriptions.ex
subscription = Http.build_struct(Subscription, data)

subscription =
  case data["scheduled_change"] do
    sc when is_map(sc) -> %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}
    _ -> subscription
  end
```

### Pattern 3: Strict Opt Boundary (lifecycle opts vs request opts)
**What:** Parse lifecycle behavior opts separately from transport opts; allow `retry`, reject unsupported `idempotency_key` for pause/resume. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; VERIFIED: `.planning/phases/08-reliability-primitives/08-CONTEXT.md`]  
**When to use:** Any public function that accepts both domain behavior flags and HTTP options. [VERIFIED: `lib/paddle/http.ex`]  
**Example:**
```elixir
# Source: recommended boundary from 10-CONTEXT D-20..D-23
{request_opts, lifecycle_opts} = split_pause_resume_opts(opts)
assert_no_idempotency_key!(request_opts)
Http.request(client, :post, path, json: body, retry: Keyword.get(request_opts, :retry))
```

### Anti-Patterns to Avoid

- **Fake `Subscriptions.create/2`:** Misrepresents provider semantics and creates future migration debt. [CITED: https://developer.paddle.com/api-reference/subscriptions/overview]
- **Single polymorphic pause API with `effective_from` user opt:** Reintroduces dangerous call-site ambiguity for destructive billing behavior. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]
- **Blind `Keyword.merge([json: body], opts)` in pause/resume:** Leaks lifecycle keys into `Req.request/2` and weakens seam vocabulary control. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; VERIFIED: `lib/paddle/http.ex`]
- **Struct pattern test that only matches known keys:** Does not fail when new fields are silently added; use explicit key-set comparison for locked field regression. [VERIFIED: `test/paddle/subscription_test.exs`] [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Direct subscription creation abstraction | Custom orchestration API `Subscriptions.create/2` that pretends provider supports direct create | `Paddle.Transactions.create/3` + webhook correlation + `Subscriptions.get/2` | Matches Paddle lifecycle truth; avoids long-term contract lie. [CITED: https://developer.paddle.com/api-reference/subscriptions/overview; CITED: https://developer.paddle.com/api-reference/transactions/create-transaction; CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-created/] |
| Custom HTTP retry framework for this phase | New retry middleware with per-endpoint knobs | Existing Req transient retry policy + per-call `retry` override | Already implemented, tested, and constrained by v1.2 vocabulary. [VERIFIED: `lib/paddle/client.ex`; VERIFIED: `test/paddle/http_test.exs`; VERIFIED: `.planning/phases/08-reliability-primitives/08-CONTEXT.md`] |
| New schema layer for nested subscription payloads | Deep typed mapping for opaque provider subtrees | Locked top-level structs + selective nested hydration + `raw_data` | Preserves seam stability while remaining forward-compatible with provider payload growth. [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `lib/paddle/subscriptions.ex`] |

**Key insight:** Existing seam discipline already solved the hard forward-compat problem (`raw_data` + selected locked fields); Phase 10 should extend that discipline, not replace it. [VERIFIED: `guides/accrue-seam.md`]

## Common Pitfalls

### Pitfall 1: Planning against stale SUB-04 wording
**What goes wrong:** Planner builds tasks for `Paddle.Subscriptions.create/2` even though provider has no direct create operation. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/ROADMAP.md`]  
**Why it happens:** REQUIREMENTS/ROADMAP text predates Phase 10 discuss correction. [VERIFIED: `.planning/STATE.md`; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]  
**How to avoid:** Treat 10-CONTEXT decisions as source of truth and add explicit roadmap/requirements correction task. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]  
**Warning signs:** Plan mentions implementing `Subscriptions.create/2` or idempotency on subscription mutations. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

### Pitfall 2: Lifecycle option leakage into transport opts
**What goes wrong:** `resume_at`, `on_resume`, or `effective_from` leak into `Req.request/2` options due to broad merge. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]  
**Why it happens:** Existing create functions use `Keyword.merge([json: body], opts)` safely for create, tempting reuse in mutation functions with mixed opt types. [VERIFIED: `lib/paddle/transactions.ex`; VERIFIED: `lib/paddle/customers.ex`]  
**How to avoid:** Explicitly split and allowlist lifecycle opts and request opts; hard-reject unsupported keys (`idempotency_key`). [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]  
**Warning signs:** Tests need to assert `retry` but cannot assert rejection of unexpected keys. [ASSUMED]

### Pitfall 3: Weak struct-shape regression
**What goes wrong:** Tests still pass if `%Paddle.Subscription{}` gains new locked fields silently. [VERIFIED: `test/paddle/subscription_test.exs`] [ASSUMED]  
**Why it happens:** Pattern matching on explicit keys in maps/structs does not assert absence of extra keys. [ASSUMED]  
**How to avoid:** Add key-set assertion against `Map.keys(%Paddle.Subscription{})` minus `:__struct__`. [ASSUMED]  
**Warning signs:** Seam guide and struct diverge without failing tests. [ASSUMED]

### Pitfall 4: Misinterpreting pause/resume success states
**What goes wrong:** Caller assumes pause always returns `status: "paused"` or resume always indicates no further billing events. [CITED: https://developer.paddle.com/api-reference/subscriptions/pause-subscription; CITED: https://developer.paddle.com/api-reference/subscriptions/resume-subscription/]  
**Why it happens:** Scheduled changes and immediate-charge behavior are state-dependent. [CITED: https://developer.paddle.com/api-reference/subscriptions/pause-subscription; CITED: https://developer.paddle.com/api-reference/subscriptions/resume-subscription/]  
**How to avoid:** Assert and document `scheduled_change` semantics + webhook reconciliation requirements. [CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-resumed/; CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-created/]  
**Warning signs:** Business logic triggers entitlements on local response only, with no webhook/canonical fetch follow-up. [ASSUMED]

## Code Examples

Verified patterns from official sources and this codebase:

### Transaction-driven recurring start (SUB-04 corrected)
```elixir
# Source: .planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md + Paddle docs
{:ok, transaction} =
  Paddle.Transactions.create(client, attrs,
    idempotency_key: "accrue:checkout:#{checkout_id}:attempt:#{attempt}"
  )

checkout_url = transaction.checkout.url
# complete checkout / invoice flow, correlate subscription.created transaction_id
{:ok, subscription} = Paddle.Subscriptions.get(client, subscription_id)
```

### Existing mutation request shape pattern to extend
```elixir
# Source: lib/paddle/subscriptions.ex (cancel pattern)
defp do_cancel(client, subscription_id, effective_from) do
  with :ok <- validate_subscription_id(subscription_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, cancel_path(subscription_id),
           json: %{"effective_from" => effective_from}
         ) do
    {:ok, build_subscription(data)}
  end
end
```

### Adapter-backed endpoint contract test pattern
```elixir
# Source: test/paddle/subscriptions_test.exs
client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/subscriptions/sub_01/cancel"
    assert decode_json_body(request.body) == %{"effective_from" => "next_billing_period"}
    {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
  end)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plan directly around `Paddle.Subscriptions.create/2` for SUB-04 | Treat recurring start as transaction-driven flow (`Transactions.create` -> checkout/invoice -> webhook correlation -> `Subscriptions.get`) | 2026-05-30 discuss/context correction | Prevents provider-model mismatch and wrong API surface expansion. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; CITED: https://developer.paddle.com/api-reference/subscriptions/overview] |
| Subscription mutation surface only had cancel/cancel_immediately | Add pause/resume with explicit timing semantics and state-aware docs/tests | Phase 10 scope (pending implementation) | Closes Accrue lifecycle gap without widening locked struct fields. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`] |
| Struct regression relies on explicit pattern field list | Add key-set regression asserting zero added/removed/renamed locked fields | Phase 10 contract hardening requirement | Catches accidental seam drift that current pattern may miss. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] [ASSUMED] |

**Deprecated/outdated:**

- Direct-create assumption for Paddle subscriptions in current REQUIREMENTS/ROADMAP text is outdated and must be corrected in planning/execution artifacts. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing `%Subscription{...}` pattern tests do not strictly fail on added struct keys without key-set checks. | Common Pitfalls, State of the Art | Could miss seam drift despite passing tests. |
| A2 | Planner should split Phase 10 into three slices (SUB-04 correction, pause, resume) for best execution flow. | Summary | Suboptimal sequencing if repository constraints favor a different slice order. |
| A3 | `Map.keys(%Paddle.Subscription{})` key-set assertion is the best low-complexity seam regression form. | Common Pitfalls | Could choose a different strictness mechanism in implementation. |

## Open Questions (RESOLVED)

1. **Where should SUB-04 correction be codified first: REQUIREMENTS, ROADMAP, or both in the same plan wave?**
   - RESOLVED: The SUB-04 correction was codified during planning in `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/PROJECT.md`. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/PROJECT.md`]
   - RESOLVED: Phase 10 execution now treats those planning files as corrected preconditions rather than execution-batch targets, and Plan `10-01` locks the corrected recurring-start seam in tests/docs instead of reopening planning-file edits. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-01-PLAN.md`]

2. **Should seam boundary test (`test/paddle/seam_test.exs`) gain explicit pause/resume journey steps now or stay minimal and rely on module tests?**
   - RESOLVED: Yes. Plan `10-03` adds explicit pause/resume journey steps at the public seam boundary while keeping assertions limited to typed public behavior and `raw_data` presence. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-03-PLAN.md`; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`]
   - RESOLVED: Detailed request/response payload coverage stays in `test/paddle/subscriptions_test.exs`, and the `%Paddle.Subscription{}` struct-shape regression stays in `test/paddle/subscription_test.exs`. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-03-PLAN.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile/tests for phase tasks | ✓ | 1.19.5 | — |
| Mix | Test execution / formatting / compile checks | ✓ | 1.19.5 | — |
| Req dependency graph | HTTP adapter-backed tests + transport behavior | ✓ | locked `0.5.17` | — |
| Paddle API key (`PADDLE_API_KEY`) | Optional live/sandbox manual smoke tests | ✗ | — | Use offline adapter-backed tests (current standard) |

**Missing dependencies with no fallback:**

- None for planning/execution of adapter-backed Phase 10 tasks.

**Missing dependencies with fallback:**

- `PADDLE_API_KEY` missing; fallback is full adapter-backed coverage (already standard in repo tests). [VERIFIED: env var check; VERIFIED: `test/paddle/subscriptions_test.exs`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | SDK consumes API key auth via `%Paddle.Client{}`; no end-user auth surface in this phase. [VERIFIED: `lib/paddle/client.ex`] [ASSUMED] |
| V3 Session Management | no | No session issuance/rotation logic in this SDK phase. [VERIFIED: phase scope in `10-CONTEXT.md`] [ASSUMED] |
| V4 Access Control | yes | Enforce provider-side permission expectations (`subscription.write` for pause/resume, `transaction.write` for start flow) in docs and error handling. [CITED: https://developer.paddle.com/api-reference/subscriptions/pause-subscription; CITED: https://developer.paddle.com/api-reference/subscriptions/resume-subscription/; CITED: https://developer.paddle.com/api-reference/transactions/create-transaction] |
| V5 Input Validation | yes | Validate IDs and lifecycle opts at SDK boundary; reject unsupported opts explicitly. [VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`] |
| V6 Cryptography | no | No new cryptographic behavior in Phase 10 mutation work. [VERIFIED: phase scope in `10-CONTEXT.md`] [ASSUMED] |

### Known Threat Patterns for Elixir SDK + Paddle API stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported opt injection into transport layer (`idempotency_key`, lifecycle keys) | Tampering | Strict opt allowlisting/splitting + explicit `ArgumentError` on disallowed keys. [VERIFIED: `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`; VERIFIED: `lib/paddle/http.ex`] |
| Path/ID misuse on subscription mutations | Tampering | Reuse `validate_subscription_id/1` + `URI.encode/2` path segment encoding. [VERIFIED: `lib/paddle/subscriptions.ex`] |
| Incorrect trust in local mutation response without event reconciliation | Repudiation / Integrity | Document webhook + canonical fetch reconciliation for created/resumed flows. [CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-created/; CITED: https://developer.paddle.com/webhooks/subscriptions/subscription-resumed/] |
| Silent suppression of provider state errors | Information Disclosure / Integrity | Preserve `%Paddle.Error{}` passthrough, including request_id/code, in mutation calls. [VERIFIED: `lib/paddle/http.ex`; VERIFIED: `test/paddle/subscriptions_test.exs`; CITED: https://developer.paddle.com/errors/subscriptions/subscription_missing_payment_method_cannot_resume] |

## Sources

### Primary (HIGH confidence)

- `lib/paddle/subscriptions.ex`, `lib/paddle/http.ex`, `lib/paddle/transactions.ex`, `lib/paddle/subscription.ex`, `test/paddle/subscriptions_test.exs`, `test/paddle/subscription_test.exs`, `test/paddle/seam_test.exs`, `guides/accrue-seam.md`, `guides/getting-started.md`, `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - current repo truth and locked phase decisions.
- https://developer.paddle.com/api-reference/subscriptions/ - direct-create prohibition, scheduled changes, management_urls guidance.
- https://developer.paddle.com/api-reference/transactions/create-transaction/ - transaction creation semantics, checkout URL, subscription materialization trigger.
- https://developer.paddle.com/api-reference/subscriptions/pause-subscription/ - pause endpoint contract and request fields.
- https://developer.paddle.com/api-reference/subscriptions/resume-subscription/ - resume endpoint contract, immediate-charge semantics, allowed states.
- https://developer.paddle.com/webhooks/subscriptions/subscription-created/ - transaction_id correlation and no `management_urls` in payload.
- https://developer.paddle.com/webhooks/subscriptions/subscription-resumed/ - immediate billing/event behavior on resume.
- https://developer.paddle.com/api-reference/about/rate-limiting/ - 429/Retry-After handling context for retry behavior.
- https://developer.paddle.com/errors/subscriptions/subscription_missing_payment_method_cannot_resume/ - concrete resume state error.
- https://developer.paddle.com/errors/subscriptions/subscription_continuing_existing_billing_period_not_allowed/ - concrete `on_resume` state error.

### Secondary (MEDIUM confidence)

- Hex package registry metadata via `mix hex.info req`, `mix hex.info telemetry`, `mix hex.info jason` for locked/latest version and release-date verification.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - validated against live repository files and Hex registry outputs.
- Architecture: HIGH - locked by Phase 10 CONTEXT decisions plus direct Paddle endpoint docs.
- Pitfalls: MEDIUM - most are directly evidenced; a few test-strictness implications are implementation inferences.

**Research date:** 2026-05-30  
**Valid until:** 2026-06-29 (30 days; API behavior and roadmap text are actively evolving)
