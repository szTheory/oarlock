# Phase 8: Reliability Primitives - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the HTTP layer survive real Paddle production conditions through three additive transport-layer primitives:

1. **Idempotency-Key plumbing (REL-01)** — every `create/*` public function (`Paddle.Customers.create/2`, `Paddle.Customers.Addresses.create/3`, `Paddle.Transactions.create/2`, future `Paddle.Subscriptions.create/2`) accepts an optional `idempotency_key:` opt and forwards it as the `Idempotency-Key` HTTP header.
2. **Automatic retry policy (REL-02)** — `req` is configured at `Paddle.Client.new!/1` to honor `Retry-After`, with max 3 retries and exponential backoff, retrying only on 429 + 5xx + transient transport errors. Per-call `retry: false` opt-out is supported.
3. **Network-error normalization (REL-03)** — transport failures (timeout, nxdomain, closed, econnrefused) are normalized into `%Paddle.Error{network_error?: true, retryable?: true}`, replacing the v1.1 behavior of leaking raw `%Req.TransportError{}` to consumers.

Plus one **factual correction**: `%Paddle.Error{}`'s forward-compat field is renamed `:raw` → `:raw_data` so the SDK is internally consistent (every other locked struct already uses `:raw_data`). REQUIREMENTS.md and ROADMAP.md success criteria already specify `:raw_data` — code, seam guide, and Accrue's call sites move to match.

**Not in scope this phase:** circuit breakers; per-call timeout overrides; `:max_retries`/`:retry_delay` knobs; pagination streaming (Phase 9); subscription mutations (Phase 10); broader observability/metrics surface beyond existing telemetry events; type specs (Phase 11); docs (Phase 12).

</domain>

<decisions>
## Implementation Decisions

### Error struct field naming (resolves REL-03 wording vs. v1.1 seam-lock conflict)

- **D-01:** Rename `%Paddle.Error{}` field `:raw` → `:raw_data`. This is the only locked struct using the asymmetric `:raw` name; renaming aligns the SDK with itself and removes a permanent pattern-matching footgun (`%{raw_data: r}` silently misses errors today).
- **D-02:** Treat the rename as a deliberate 0.x cleanup, exercising the `bump-minor-pre-major: false` policy locked in commit `c73b71b`. PROJECT.md "rename = breaking" rule and the `guides/accrue-seam.md:118` lock are both updated *together* in this phase — no transitional period, no dual-population.
- **D-03:** Update `guides/accrue-seam.md:118` to lock `:raw_data` on `%Paddle.Error{}` (not `:raw`). Add a CHANGELOG entry under v1.2 marked breaking.
- **D-04:** Coordinate the Accrue-side one-line update (`error.raw` → `error.raw_data`) — log it in `.planning/BACKLOG.md` as an Accrue migration note. Do NOT block this phase on Accrue's commit; oarlock ships first.
- **D-05:** Do NOT dual-populate `:raw` + `:raw_data`. Every dual-populated SDK precedent (Stripe-Ruby `http_body`+`response`, Twilio-Ruby's overlapping fields) is cited in postmortems as a DX wart that ships v1.0 with a deprecation already in flight.

### Idempotency-Key default policy (REL-01)

- **D-06:** When the caller does not supply `idempotency_key:`, the SDK forwards no header. No auto-generation. Paddle treats the call as non-idempotent — the caller's choice.
- **D-07:** Accrue (the primary consumer) persists deterministic per-attempt UUIDs in its Oban job queue and supplies them. SDK-side auto-generation would either be dead code or — worse — defeat upper-layer retry semantics (job restart → new UUID per call → Paddle sees novel keys → double-charge). The retry layer that owns the decision is the only layer that can safely own the key.
- **D-08:** Validation is pass-through — the SDK is no stricter than Paddle (per Phase 6 D-06). Document the typical Paddle convention in `@doc` (UTF-8 ≤ 255 chars) but do not enforce length/charset.
- **D-09:** Reject `nil` and empty/whitespace-only strings explicitly with `ArgumentError` (or a `{:error, :invalid_idempotency_key}` tuple, planner's call). Rationale: `Keyword.get(opts, :idempotency_key)` returning `nil` from a caller's bug must not silently produce an empty `Idempotency-Key:` header. Loud failure on bad input only.
- **D-10:** `idempotency_key:` is plumbed only on POST-shaped public functions (`create/*` per REL-01). Not added to GETs, PATCHes, or DELETEs in this phase. (PATCHes/DELETEs may be added later if a consumer asks; defer.)

### Network/HTTP error taxonomy (REL-03)

- **D-11:** `:network_error?` is **transport-only**. `true` ⇔ failure originated below the HTTP response layer (`%Req.TransportError{}`, `%Mint.TransportError{}`). 5xx HTTP responses keep `network_error?: false` with `:status_code` set — these are upstream Paddle issues, not network failures. Conflating them destroys the diagnostic split between "we never reached Paddle" and "Paddle replied with a problem."
- **D-12:** `:retryable?` is an **advisory class predicate** — reflects the *kind* of error, not the SDK's internal retry budget. Classification:
  - Transport failure → `retryable?: true`
  - 5xx → `retryable?: true`
  - 429 → `retryable?: true`
  - 4xx (other than 429) → `retryable?: false`
  - Auth errors (401/403) → `retryable?: false`
- **D-13:** `:retryable?` does NOT flip to `false` after the SDK exhausts its internal retry budget. The same 503 returns identical shape regardless of attempt count. Stable contract = reliable telemetry, logging, and pattern matching. If post-hoc exhaustion semantics are ever needed, add a separate `:retries_exhausted?` field; do not overload `:retryable?`.
- **D-14:** Set `:type` to a stable lowercase taxonomy string for transport failures: `"network_timeout"`, `"network_nxdomain"`, `"network_closed"`, `"network_unknown"` (pluck from `%Req.TransportError{reason: ...}`). Consumers pattern-match on `:type` for stable taxonomy; raw exception preserved for forensics.
- **D-15:** Preserve the original `%Req.TransportError{}` (or whatever the underlying exception is) in `:raw_data`. Same field that holds the upstream JSON for HTTP errors — additive reuse, no new field.
- **D-16:** **Critical Elixir gotcha — explicit defaults required.** `defexception` defaults all fields to `nil`. Must declare:

  ```elixir
  defexception type: nil, code: nil, message: nil, errors: [],
               request_id: nil, status_code: nil, raw_data: nil,
               network_error?: false, retryable?: false
  ```

  Otherwise `if error.retryable?` truthy-checks `nil` and pattern-match `%Paddle.Error{network_error?: false}` silently fails for legacy errors. Must be locked by an `error_test.exs` assertion that newly-constructed errors carry `false` defaults.

### Retry policy & per-call opt-out (REL-02)

- **D-17:** Retry baseline lives in `Paddle.Client.new!/1` — configures `req` with: max 3 retries, exponential backoff, `Retry-After` honored when present, retry on 429 + 5xx + transient transport errors only, no retry on 4xx (other than 429).
- **D-18:** Per-call override surface is **client baseline + per-call opt** (Stripe Ruby/Node, ex_aws, AWS v3, Req itself all land here). The single locked override is:
  - `:retry` (boolean) — `false` disables this call's retry; omitted/`true` inherits client policy.
- **D-19:** **Locked v1.2 opts vocabulary on every public function:** `:idempotency_key` (POSTs only) and `:retry` (boolean). Nothing else.
- **D-20:** **Explicitly REJECTED for v1.2 vocabulary:** `:max_retries`, `:retry_delay`, `:retry_log_level`, `:timeout`, full `Req.Steps`-style passthroughs. These leak Req internals into the locked seam. Adding fields later is additive (non-breaking); contracting is breaking — start narrow.
- **D-21:** Public function signatures: each `create/*` and read function gains a trailing `opts \\ []` keyword list. `Paddle.Http.request/4` already accepts `opts` (`Keyword.merge` into `Req.request`); idempotency-key extraction → header injection happens there. `:retry` flows through unchanged because Req already accepts it per call.
- **D-22:** Adapter-backed test pattern keeps working: tests still set `retry: false` on the adapter Req, AND the new per-call `:retry` opt provides a cleaner path going forward (`Paddle.Customers.create(client, attrs, retry: false)` — no client rebuild needed).

### Decision-making preference (carry-forward, reaffirmed)

- **D-23:** Continue Phase 6/7 stance — research-backed decisive defaults, escalate only genuinely public-seam-impacting calls. Phase 8 itself was discussed under this rule: the four discussed areas were the public-API decisions worth user judgment; everything else (Req retry hook implementation, exact `:type` strings beyond the four locked ones, test fixture organization, function arity placement) is shifted left into research/planning.

### Claude's Discretion

- Exact placement of retry config inside `Paddle.Client.new!/1` (e.g., raw `Req.new` opts vs. a `configure_retry/1` helper).
- Internal mechanism for retry — `Req`'s built-in `retry: :transient` is the obvious starting point; whether to subclass into a custom `:retry_log_level` / explicit retry function is a planner call.
- Exact per-function plumbing of `opts` — whether `Paddle.Customers.create(client, attrs, opts)` or `Paddle.Customers.create(client, attrs)` keeping opts inside `attrs` — but the public surface MUST end up with `opts \\ []` as the third arg per D-21 (idiomatic Elixir, doesn't pollute the attrs map).
- Wording of `@doc` examples for `idempotency_key:` (must include the Accrue-style "supply your own deterministic key per attempt" pattern).
- Test fixture naming/structure as long as adapter-backed coverage matches the success criteria in ROADMAP.md.
- Whether the rejection of `nil`/empty `idempotency_key:` returns `{:error, :invalid_idempotency_key}` (consistent with current validation tuple style) or raises `ArgumentError` (consistent with kwlist programmer-error style). Both are defensible — pick one and use it consistently.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and active requirement
- `.planning/PROJECT.md` — v1.2 milestone goal, integration-consumer framing (Accrue), `:raw_data` forward-compat invariant, "field renames are breaking" rule.
- `.planning/REQUIREMENTS.md` — REL-01, REL-02, REL-03 plus traceability table; verbatim wording of "Existing `:raw_data` field on `%Paddle.Error{}`" (which the rename in D-01 honors literally).
- `.planning/ROADMAP.md` — Phase 8 goal and four success criteria; same `:raw_data` wording in success criterion #3.
- `.planning/STATE.md` — Current milestone position; v1.2 outline.
- `.planning/BACKLOG.md` — log Accrue-side `error.raw → error.raw_data` migration note here per D-04.

### Prior locked decisions (carry-forward)
- `.planning/milestones/archived-phases/06-transactions-retrieval/06-CONTEXT.md` — D-05/D-06 (no upstream-format overfitting in validation), D-07 (existing `{:error, exception}` boundary that REL-03 is intentionally replacing), D-13 (decisive-defaults stance).
- `.planning/milestones/archived-phases/07-accrue-seam-lock/07-CONTEXT.md` — D-15 (`:raw_data` is locked seam as escape hatch — note the asymmetry this CONTEXT.md fixes), D-20/D-21/D-22 (decisive-defaults preference), D-11..D-14 (locked/additive/opaque field tier policy that the rename respects).

### Existing seam artifacts that this phase modifies
- `lib/paddle/error.ex:2` — exception field list; rename `:raw` → `:raw_data`, add `:network_error?`, `:retryable?` with explicit `false` defaults per D-16.
- `lib/paddle/http.ex:4-17` — `request/4` chokepoint where idempotency-key extraction, retry-config plumbing, and transport-error normalization all land.
- `lib/paddle/client.ex:5-23` — `new!/1` where retry policy is configured per D-17.
- `lib/paddle/customers.ex` — `create/2` adds `opts \\ []` per D-21; same shape for the other three create/* functions.
- `lib/paddle/customers/addresses.ex` — same plumbing.
- `lib/paddle/transactions.ex` — same plumbing on `create/2`.
- `lib/paddle/subscriptions.ex` — Phase 10's `create/2` will land with the same plumbing; this phase locks the shape.
- `guides/accrue-seam.md:118` — update `%Paddle.Error{}` field row from `:raw` to `:raw_data`; flag the rename in a v1.2 changelog/note section.
- `test/paddle/error_test.exs` — assert explicit `false` defaults on `network_error?` / `retryable?` per D-16.
- `test/paddle/http_test.exs:51-58` — currently asserts `{:error, %Req.TransportError{...}}`; rewrite to assert `{:error, %Paddle.Error{network_error?: true, retryable?: true, type: "network_timeout", raw_data: %Req.TransportError{...}}}`.
- `test/paddle/seam_test.exs` — verify no transport-error assertions need updating; add adapter-backed tests for retry/idempotency per success criteria.

### Paddle API references
- `https://developer.paddle.com/api-reference/about/api-versioning` — Idempotency-Key contract (Paddle docs cite UTF-8 ≤ 255 chars convention).
- `https://developer.paddle.com/api-reference/about/errors` — error envelope; `Retry-After` header semantics on 429/5xx.

### Ecosystem precedents that shaped these decisions
- `https://hexdocs.pm/req/Req.html` — Req's per-call `retry: false` override (locks D-18 implementation path).
- `https://hexdocs.pm/req/Req.Steps.html` — Req's retry step semantics; the layer Paddle.Client.new!/1 configures per D-17.
- `https://docs.stripe.com/error-low-level` — Stripe's `APIConnectionError` vs `APIError` split (precedent for D-11 transport-only `:network_error?`).
- `https://hexdocs.pm/stripity_stripe/Stripe.Error.html` — `source: :network` vs `source: :stripe` precedent for D-11; `extra.hackney_reason` precedent for raw-exception preservation in D-15.
- `https://github.com/stripe/stripe-node` — `maxNetworkRetries` per-request override (precedent for D-18 client-baseline + per-call).
- `https://hexdocs.pm/ex_aws/ExAws.html` — Elixir-native precedent for per-call `retries: [max_attempts: N]` opt.
- `https://stripe.com/blog/idempotency` — Brandur on idempotency keys (precedent for D-07 "retry layer that owns the decision owns the key").
- `https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/` — AWS Builders' Library on idempotency-key footguns (auto-gen across retries breaks dedup).
- `https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html` — AWS v3 `$retryable` advisory pattern (precedent for D-12 advisory `:retryable?`).
- `https://grpc.io/docs/guides/retry/` — gRPC retryable-status-code list (advisory class predicate precedent).
- `https://hexdocs.pm/elixir/structs.html` — struct default behavior (precedent for D-16 explicit `false` defaults gotcha).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/paddle/http.ex:4-17` `request/4` — single transport chokepoint. `Keyword.merge(opts, method: method, url: path)` already passes `opts` straight to `Req.request`. Adding `:idempotency_key` extraction (lift to header) and transport-error normalization both land here. `:retry` flows through unchanged.
- `lib/paddle/client.ex:5-23` `new!/1` — single place to attach the v1.2 retry policy on the embedded `%Req.Request{}`.
- `lib/paddle/error.ex` — already a `defexception`; existing `from_response/1` is the integration point for HTTP-error → `%Paddle.Error{}` mapping. A sibling `from_transport/1` (or similar) maps `%Req.TransportError{}` → `%Paddle.Error{}` per D-11..D-15.
- Existing adapter pattern in every `*_test.exs` (e.g., `http_test.exs:73-79`, `seam_test.exs:194-198`) — `Req.new(retry: false, adapter: fn req -> ... end)`. New retry tests need a SECOND fixture style: adapter that fails N times then succeeds, with retry left ON (mirror Req's own test patterns).

### Established Patterns
- Public functions take `%Paddle.Client{}` explicitly and return tagged tuples (`{:ok, struct} | {:error, atom | %Paddle.Error{}}`).
- Resource modules pipe normalize → allowlist → `Paddle.Http.request/4` → `build_struct/2` (see `lib/paddle/customers.ex:10-16` for the canonical shape).
- Lightweight validation only — Phase 6 D-05/D-06 standard. Idempotency-key validation follows the same rule: reject only nil/empty/non-binary; do not enforce length/charset.
- Tests are inline-adapter-backed, no live network, no mock servers.
- Locked struct fields are additive only; `:raw_data` is the documented forward-compat escape hatch on every locked entity (Customer, Address, Transaction, Subscription, Event, Page, Subscription.ScheduledChange, Subscription.ManagementUrls, Transaction.Checkout). After D-01, `%Paddle.Error{}` joins the same convention.

### Integration Points
- `Paddle.Http.request/4` is THE place for: idempotency-key header injection, retry policy attachment (already in client), and transport-error normalization. All three land in this single function.
- `Paddle.Client.new!/1` is THE place for retry baseline configuration (D-17).
- `Paddle.Error.from_response/1` already exists for HTTP errors; a parallel `Paddle.Error.from_transport/1` for `%Req.TransportError{}` keeps the boundary clean.
- Each public `create/*` plumbs `opts \\ []` → forwards to `Paddle.Http.request/4` (which already accepts opts — no signature change needed for `Http.request/4`).

</code_context>

<specifics>
## Specific Ideas

- Idempotency-key DX example for `@doc`: show the Accrue-style "deterministic key per job attempt" pattern (`"accrue:job:#{job_id}:attempt:#{attempt}"`) so consumers immediately see why auto-generation would defeat their retry layer.
- Retry policy should match `req`'s vocabulary (`retry: fun_or_atom`, `retry_delay: fun`) under the hood but expose ONLY `:retry` boolean publicly — internal flexibility, narrow public surface.
- The transport-error taxonomy strings (`"network_timeout"`, `"network_nxdomain"`, `"network_closed"`, `"network_unknown"`) should be locked by a unit test that exhaustively covers `%Req.TransportError{reason: ...}` → `:type` mapping. New transport reasons fall through to `"network_unknown"` rather than crashing.
- The `:raw → :raw_data` rename should land in a single commit on the error struct + seam guide + CHANGELOG — never split across plans, so no intermediate state ever ships with mismatched docs/code.
- Carry-forward user preference (Phase 6 D-13, Phase 7 D-20/D-21, reaffirmed in this phase as D-23): research-backed decisive defaults; reserve user judgment for genuinely public-seam-impacting calls.

</specifics>

<deferred>
## Deferred Ideas

- **`:max_retries` / `:retry_delay` per-call opts** — explicitly rejected for v1.2 vocabulary per D-20. If a consumer asks, evaluate then; additive when added.
- **Per-call `:timeout` opt** — same logic; out for v1.2.
- **`:retries_exhausted?` flag** — out for v1.2 per D-13. Add separately when a real consumer needs post-hoc exhaustion signal.
- **Idempotency-Key on PATCH/DELETE** — out for v1.2 per D-10. Paddle's API supports it but no requirement covers it; add when SUB-04..06 (Phase 10) or a future mutation phase asks.
- **Auto-generated idempotency keys behind a `Paddle.Idempotency.generate/0` opt-in helper** — defer; if needed later, can ship as a public helper without changing the default policy in D-06.
- **Circuit breaker / `Fuse`-style protection** — separate concern, not in v1.2.
- **Per-resource retry policy overrides** (e.g., "retry transactions but not subscriptions") — rejected as kitchen-sink; client-level baseline covers the 99% case.
- **`%Paddle.Error{}` `:raw` deprecation warning** — N/A because we're renaming, not dual-populating; no transitional period.

</deferred>

---

*Phase: 08-reliability-primitives*
*Context gathered: 2026-04-29*
