# Phase 8: Reliability Primitives - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 08-reliability-primitives
**Areas discussed:** Error :raw vs :raw_data, Idempotency-Key default policy, Network/HTTP error taxonomy, Per-call retry opt-out

---

## Discussion Mode

User requested research-backed decisive recommendations across all four selected gray areas (per `feedback_decisive_research.md`). Four parallel `gsd-advisor-researcher` subagents ran research; recommendations were synthesized into a single coherent proposal and locked by user with "Lock all four" selection. No iterative back-and-forth was needed.

---

## Error :raw vs :raw_data

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `:raw` | Treat REQUIREMENTS REL-03 wording as a typo. Fix REQUIREMENTS.md + ROADMAP.md success criterion #3 to say `:raw`. Honors v1.1 seam-lock rule. `%Paddle.Error{}` stays asymmetric vs other locked structs until v2 normalizes. | |
| Rename `:raw` → `:raw_data` | One-line breaking change to `%Paddle.Error{}`. Update `guides/accrue-seam.md:118`. Accrue (only consumer) needs one-line update. Honors REQUIREMENTS literal text; technically violates "rename = breaking" rule but acceptable in 0.x. | ✓ |
| Add `:raw_data`, keep `:raw` | Dual-populate both fields with identical data. Soft-deprecate `:raw`. Zero breakage. Cost: API carries two fields with identical content forever (or until major-bump cleanup). | |

**User's choice:** Rename (Option B), as part of the all-four lock-in.

**Notes:** Research surfaced that the dominant ecosystem signal is **internal consistency within a single SDK**, not any specific name. Dual-populate is universally regretted (Stripe-Ruby `http_body`/`response`, Twilio-Ruby overlapping fields). 0.x release-please is configured `bump-minor-pre-major: false` (commit `c73b71b`) — exactly the policy intended for this kind of cleanup. Accrue migration cost is one line.

---

## Idempotency-Key Default Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Forward nothing | Stripe-style. SDK forwards no `Idempotency-Key` header when caller doesn't supply one. Caller fully responsible for opting in. | ✓ |
| Auto-generate UUID per call | Always-on idempotency. SDK generates fresh UUID v4 per call, caller can override. AWS-style precedent for `ClientToken`. | |
| Require it | Loud failure if caller doesn't supply one. `{:error, :missing_idempotency_key}`. Forces consumers to think about idempotency. | |

**User's choice:** Forward nothing (Option A), as part of the all-four lock-in.

**Notes:** Research showed that the documented SDK footgun pattern is auto-generation across upper-layer retries: when Accrue's Oban worker re-invokes the call, oarlock would generate a NEW UUID per attempt — Paddle sees novel keys and dedup breaks at exactly the moment it's needed most. The retry layer that owns the decision is the only layer that can safely own the key. Validation is pass-through, but `nil`/empty rejected loudly to prevent silent empty headers.

---

## Network/HTTP Error Taxonomy

This area broke into three sub-questions. All three locked together as a coherent taxonomy.

### Q1: `:network_error?` scope

| Option | Description | Selected |
|--------|-------------|----------|
| Transport-only (A1) | `:network_error?: true` only for `%Req.TransportError{}` / `%Mint.TransportError{}`. 5xx stays `network_error?: false` with `:status_code` set. | ✓ |
| Transport + 5xx (A2) | Broader "transient infrastructure" semantics. 503 returns `network_error?: true`. | |

### Q2: `:retryable?` semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Advisory class predicate (B1) | Reflects the *kind* of error, not SDK retry budget. Stable across attempts. | ✓ |
| Post-hoc exhaustion (B2) | `:retryable?` flips to `false` after SDK exhausts its internal retry budget. | |
| Both via two flags (B3) | Keep `:retryable?` advisory and add separate `:retries_exhausted?`. | |

### Q3: Raw exception preservation

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve in `:raw_data` (C1) | Store original `%Req.TransportError{}` for forensics; set `:type` to stable taxonomy string. | ✓ |
| Drop raw (C2) | `:type` + `:message` carry enough; raw exception dropped. | |

**User's choice:** A1 + B1 + C1, as part of the all-four lock-in.

**Notes:** Research cited Stripe Ruby (`APIConnectionError` vs `APIError` distinct classes), AWS v3 (`$fault: 'client'|'server'` never conflated with transport), gRPC (advisory retryable list). The split between "we never reached Paddle" and "Paddle replied with a problem" is load-bearing for Accrue's on-call diagnostics. Critical Elixir gotcha surfaced by research: `defexception` defaults to `nil`, not `false` — explicit `network_error?: false, retryable?: false` defaults are required to avoid pattern-match footguns.

---

## Per-Call Retry Opt-Out

| Option | Description | Selected |
|--------|-------------|----------|
| Client-level only | `Paddle.Client.new!(retry: false)` configures the client; all calls inherit. To get different behavior, build a second client. | |
| Client baseline + per-call override | Per-call `retry: false` opt overrides client config. | ✓ |
| Per-call only | All retry config in opts; no client-level baseline. | |

**User's choice:** Client + per-call (Option B), as part of the all-four lock-in.

**Notes:** Stripe Ruby/Node, ex_aws, AWS SDK v3, and Req itself all land here. Twilio-node's client-only model is a known anti-pattern (twilio/twilio-node#936 = users requesting the missing per-request hook). Locked vocabulary: only `:idempotency_key` + `:retry` (boolean). Explicitly rejected: `:max_retries`, `:retry_delay`, `:timeout`, `:retry_log_level` — these leak Req internals into the locked seam. Adding fields later is non-breaking; contracting is breaking.

---

## Claude's Discretion

- Exact placement of retry config inside `Paddle.Client.new!/1` — `Req.new` opts directly vs. helper function.
- Internal retry mechanism — `req`'s built-in `retry: :transient` as starting point, custom function only if `Retry-After` semantics demand.
- Exact `opts` plumbing arity — `create(client, attrs, opts)` vs. inside `attrs` — but public surface MUST end with `opts \\ []` as third arg.
- Wording of `@doc` examples (must include Accrue-style deterministic-key example).
- Test fixture naming, as long as adapter-backed coverage matches ROADMAP.md success criteria.
- Whether `nil`/empty `idempotency_key:` rejection returns `{:error, :invalid_idempotency_key}` (existing tuple style) or raises `ArgumentError` (programmer-error kwlist style).
- Exact `:type` taxonomy string for unmapped `%Req.TransportError{}` reasons (defaulted to `"network_unknown"`).

## Deferred Ideas

- `:max_retries` / `:retry_delay` per-call opts (rejected for v1.2; additive when needed)
- Per-call `:timeout` opt (out for v1.2)
- `:retries_exhausted?` flag (out for v1.2 per D-13)
- Idempotency-Key on PATCH/DELETE (out for v1.2 per D-10)
- Auto-generated idempotency keys via `Paddle.Idempotency.generate/0` opt-in helper
- Circuit breaker / `Fuse`-style protection (separate concern)
- Per-resource retry policy overrides (rejected as kitchen-sink)
- `:raw` deprecation warning (N/A — we're renaming, not dual-populating)
