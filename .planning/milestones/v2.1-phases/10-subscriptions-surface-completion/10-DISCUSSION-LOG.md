# Phase 10: Subscriptions Surface Completion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 10-subscriptions-surface-completion
**Areas discussed:** SUB-04 correction, Pause surface, Resume surface, Mutation opts boundary

---

## SUB-04 Correction

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `Paddle.Subscriptions.create/2` as a synthetic wrapper | Internally orchestrate transaction create, wait/poll, and subscription fetch while pretending to expose subscription creation. | |
| Correct SUB-04 to transaction-first recurring start | Treat `Paddle.Transactions.create/3` as the canonical recurring-start seam; correlate the eventual subscription through webhooks and canonical fetches. | yes |
| Add `Paddle.Subscriptions.start_checkout/3` | Put a truthful helper under the subscriptions namespace that still returns `%Paddle.Transaction{}`. | |

**User's choice:** Discuss all areas with subagent-backed research and synthesize a one-shot recommendation.

**Notes:** Paddle's current subscription overview says subscriptions cannot be created directly. The selected path keeps oarlock provider-native and avoids a Stripe-shaped fake direct subscription API. `Paddle.Subscriptions.create/2` is explicitly rejected for Phase 10.

---

## Pause Surface

| Option | Description | Selected |
|--------|-------------|----------|
| `pause/3` plus `pause_immediately/3` | Mirror the existing cancel split: `pause/3` schedules at next billing period; `pause_immediately/3` pauses now. Both accept narrow lifecycle opts. | yes |
| Single `pause/3` with `effective_from:` mode | One endpoint-shaped function with a mode option for timing. | |
| Raw provider-body passthrough | Accept a keyword/map body matching Paddle's pause request directly. | |

**User's choice:** Discuss all areas with subagent-backed research and synthesize a one-shot recommendation.

**Notes:** The selected split follows the project's Phase 5 decision that destructive or timing-sensitive lifecycle behavior deserves call-site clarity. `resume_at` and `on_resume` are supported because they are meaningful Paddle pause semantics, but raw `effective_from` remains hidden behind named functions.

---

## Resume Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate-only `resume/2` | Smallest seam; no scheduled resume or billing-period control. | |
| Single `resume/3` with opts | `resume/2` defaults to immediate; `resume/3` supports `effective_from:` and `on_resume:`. | yes |
| Separate named resume functions | Add variants like `resume_immediately/2` and `resume_at/3`. | |
| Command struct | Add a typed request struct for resume options. | |

**User's choice:** Discuss all areas with subagent-backed research and synthesize a one-shot recommendation.

**Notes:** Resume is one provider operation and the immediate default is unsurprising. Separate function variants would add public API without the safety benefit that pause/cancel get from named immediate variants.

---

## Mutation Opts Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| `idempotency_key:` plus `retry:` on all subscription POST mutations | Uniform opts on pause/resume and create-like calls. | |
| `retry:` only on pause/resume; create/start-flow keeps `idempotency_key:` | Preserve per-call retry control without creating a false idempotency guarantee for lifecycle mutations. | yes |
| No opts on pause/resume | Keep the smallest API surface and rely on client-level retry config only. | |

**User's choice:** Discuss all areas with subagent-backed research and synthesize a one-shot recommendation.

**Notes:** The selected path preserves Phase 8's create-only idempotency boundary. Pause/resume are mutation operations where per-call retry override matters, especially because resume can charge immediately, but idempotency keys on unsupported operation classes would imply safety Paddle does not promise.

---

## Research Inputs

- SUB-04 correction researcher recommended transaction-first recurring start and explicit rejection of `Paddle.Subscriptions.create/2`.
- Pause researcher recommended `pause/3` plus `pause_immediately/3`, with `resume_at` and `on_resume`.
- Resume researcher recommended a single `resume/3` with immediate default and narrow options.
- Opts-boundary researcher recommended `retry:` on pause/resume and `idempotency_key:` only on create/start-flow calls.
- Local prompt corpus reinforced the same strategy: thin provider-native SDK, transaction/checkout-driven recurring start, strong DX, no Phoenix/Ecto coupling, no fake Stripe parity.

## the agent's Discretion

- Private helper organization.
- Exact validation atom names.
- Exact docs wording.
- Exact test fixture layout.

## Deferred Ideas

- `Paddle.Subscriptions.create/2`
- `Paddle.Subscriptions.start_checkout/3`
- `Paddle.Subscriptions.update/3`
- Customer portal session helpers
- Refunds/credits through adjustments
- Broad command structs
- Idempotency keys on pause/resume
