# Requirements: Milestone v1.2 Production Surface

**Status:** 🚧 IN PROGRESS — defined 2026-04-29
**Goal:** Drive oarlock to genuine production-readiness as a hex package while completing the subscription surface Accrue's Phase 97+ Paddle slice will need.
**Phase numbering:** Phases 8–13 (continues from v1.1).

Approved plan: `~/.claude/plans/well-we-kind-of-federated-swing.md`.

---

## v1.2 Requirements

### Reliability primitives

- [x] **REL-01**: Accept an optional `idempotency_key:` opt on every current `create/*` function (Customers, Addresses, Transactions) and pass it through as the `Idempotency-Key` request header. *(Phase 8 complete. Phase 10's corrected recurring-start seam keeps `Paddle.Transactions.create/3` as the idempotent start surface; pause/resume do not gain `idempotency_key:`.)*
- [x] **REL-02**: Configure `req` with an automatic retry policy that respects `Retry-After`: max 3 retries with exponential backoff, retry only on 429 + 5xx + transient network errors, no retry on 4xx other than 429. *(Phase 8 complete.)*
- [x] **REL-03**: Normalize transient network failures (timeout, nxdomain, etc.) into `%Paddle.Error{}` with `:network_error?` and `:retryable?` flags. Existing `:raw_data` field on `%Paddle.Error{}` must remain — additive change only, no v1.1 seam break. *(Phase 8 complete.)*

### Pagination ergonomics

- [x] **PAGE-01**: Provide `Paddle.stream/3` and `Paddle.all/3` (or per-resource equivalents) that auto-paginate over any list endpoint by chaining `Paddle.Page.next_cursor/1`. Existing per-resource `list/2` shape stays locked. *(Phase 9.)*

### Subscriptions surface completion

- [x] **SUB-04**: Transaction-driven recurring start — use `Paddle.Transactions.create/3` for recurring price items, then complete checkout or the manual-collection flow, correlate the resulting subscription via webhooks and/or `Paddle.Transactions.get/2`, and hydrate the canonical `%Paddle.Subscription{}` with `Paddle.Subscriptions.get/2`. Do not add a public `Paddle.Subscriptions.create/2`. *(Phase 10. Closes the P0 Accrue blocker truthfully.)*
- [x] **SUB-05**: `Paddle.Subscriptions.pause/2` — pause a subscription, returning the updated `%Paddle.Subscription{}`. Reverses the v1.1 PROJECT.md "deferred mutation surface" stance for v1.2. *(Phase 10.)*
- [x] **SUB-06**: `Paddle.Subscriptions.resume/2` — resume a previously paused subscription. *(Phase 10.)*

### Type-safety pass

- [x] **TYPES-01**: Add `@spec` annotations to every public function across `lib/paddle/` (≥33 functions today, plus the Phase 10 pause/resume additions). *(Phase 11.)*
- [x] **TYPES-02**: Wire `:dialyxir` in `mix.exs` with a PLT cache configuration; establish a clean `mix dialyzer` baseline (empty `.dialyzer_ignore.exs`); add `mix dialyzer` as a CI gate in `.github/workflows/ci.yml`. *(Phase 11.)*

### Documentation pass

- [x] **DOCS-01**: Add `@doc` with at least one example to every public function across `lib/paddle/`. *(Phase 12.)*
- [x] **DOCS-02**: Add `@moduledoc` to every public module. The five modules sealed by SEAM-02 (`Paddle`, `Paddle.Http`, `Paddle.Http.Telemetry`, `Paddle.Application`, `Paddle.Internal.Attrs`) keep their `@moduledoc false` — those sealings are locked. *(Phase 12.)*
- [x] **DOCS-03**: Replace the README "TODO: Add description" stub at `README.md:3` with an installation + quick-start + cross-links structure that an outside adopter can follow without reading source. *(Phase 12; draft landed during release-truth reset, still needs Phase 12 docs audit before closing.)*
- [x] **DOCS-04**: Publish a happy-path `guides/getting-started.md` (client → customer → transaction → webhook), wired into `mix.exs` `:docs` extras. *(Phase 12; draft + docs extra landed during release-truth reset, still needs Phase 12 docs audit before closing.)*
- [x] **DOCS-05**: Publish `guides/telemetry.md` documenting the `[:paddle, :request, :start | :stop | :exception]` events emitted from `lib/paddle/http/telemetry.ex`, including measurement and metadata schemas. *(Phase 12.)*

### Process guard

- [ ] **PROC-01**: Add a pre-commit hook (or `mix gsd.precommit` task) that fails the commit if any in-progress phase SUMMARY claims files are committed but `git status --porcelain` shows them dirty/untracked. Closes the v1.1 audit-trail recurrence vector documented in `MILESTONES.md:27-30`. *(Phase 13.)*
- [ ] **PROC-02**: Add the same SUMMARY/git-state drift check as a CI step in `.github/workflows/ci.yml`, so the guard works even when contributors skip local hooks. *(Phase 13.)*

---

## Future Requirements (deferred from v1.2)

- [ ] **REFUND-01**: `Paddle.Adjustments` for refunds/credits. Accrue's Stripe path uses `create_refund/2`/`retrieve_refund/2`; oarlock has none. Highest-leverage post-v1.2 feature wedge because charging without a correction path is an incomplete support story.
- [ ] **PORTAL-01**: Smallest provider-native customer self-serve billing surface Paddle supports cleanly (portal/session/payment-management flow), without Phoenix/Ecto/UI coupling in core. Likely after REFUND-01.
- [ ] **CATALOG-01**: `Paddle.Products`, `Paddle.Prices` read/list support first. Demand-driven; avoid full catalog CRUD unless a real consumer asks.
- [ ] **NOTIF-01**: Notification Settings endpoint (carried forward from v1.1 deferred list).
- [ ] **PHX-01**: Phoenix Plug helpers for webhook parsing — explicitly out per PROJECT.md core constraints (would ship as a separate package if ever).

---

## Out of Scope (reaffirmed at v1.2 start)

- **Paddle Classic Support**: Legacy API concepts and authentication (vendor-id).
- **Phoenix/Ecto coupling**: No framework dependencies in core.
- **Payment Method Portals**: Excluded for v0.x.
- **Invoice Generation**: Excluded for v0.x.
- **Refunds**: Excluded from v1.2 (deferred to REFUND-01).
- **Marketplaces / Connect**: Excluded for v0.x.
- **Discounts, Reports, Simulations, Events list endpoint, Payment Methods**: Pure surface expansion; defer until consumer demand surfaces.
- **Property-based tests with `stream_data`**: Out of scope for v1.2 hardening; revisit if dialyzer surfaces edge cases.
- **`Paddle.Subscriptions.update/3`**: Deferred beyond Phase 10. The corrected Phase 10 scope is transaction-driven recurring start plus pause/resume only.

---

## Traceability

Coverage: 14 / 14 v1.2 requirements mapped (100%).

| Requirement | Phase | Status  | Notes |
|-------------|-------|---------|-------|
| REL-01      | 8     | Complete | `idempotency_key:` opt -> `Idempotency-Key` header on current `create/*`; Phase 10 inherits pattern for Subscriptions.create/2. |
| REL-02      | 8     | Complete | `req` retry policy honoring `Retry-After`; 429 + 5xx + transient only. |
| REL-03      | 8     | Complete | Network errors normalized to `%Paddle.Error{}` with `:network_error?` / `:retryable?` (additive). |
| PAGE-01     | 9     | Complete | `Paddle.stream/3` + `Paddle.all/3` over `Paddle.Page.next_cursor/1`; locked `list/2` shape preserved. |
| SUB-04      | 10    | Complete | Transaction-driven recurring start via `Paddle.Transactions.create/3` + checkout/manual collection + webhook/canonical fetch; no public `Paddle.Subscriptions.create/2`. |
| SUB-05      | 10    | Complete | `Paddle.Subscriptions.pause/2`. |
| SUB-06      | 10    | Complete | `Paddle.Subscriptions.resume/2`. |
| TYPES-01    | 11    | Complete | `@spec` on every public function across `lib/paddle/`. |
| TYPES-02    | 11    | Complete | `:dialyxir` wired; clean baseline; `mix dialyzer` as CI gate. |
| DOCS-01     | 12    | Complete | `@doc` + example on every public function. |
| DOCS-02     | 12    | Complete | `@moduledoc` on every public module; SEAM-02 `@moduledoc false` sealings preserved. |
| DOCS-03     | 12    | Complete | README rewrite draft exists from release-truth reset; Phase 12 must audit/finalize and keep docs warning-free. |
| DOCS-04     | 12    | Complete | `guides/getting-started.md` draft is in docs extras; Phase 12 must audit/finalize. |
| DOCS-05     | 12    | Complete | `guides/telemetry.md` published into `:docs` extras. |
| PROC-01     | 13    | Pending | Pre-commit hook for SUMMARY/git-state drift. |
| PROC-02     | 13    | Pending | Same drift check as CI step. |

---

_Created 2026-04-29 at v1.2 milestone start. Traceability filled in by roadmap creation 2026-04-29._
