# Requirements: Milestone v1.2 Production Surface

**Status:** 🚧 IN PROGRESS — defined 2026-04-29
**Goal:** Drive oarlock to genuine production-readiness as a hex package while completing the subscription surface Accrue's Phase 97+ Paddle slice will need.
**Phase numbering:** Phases 8–13 (continues from v1.1).

Approved plan: `~/.claude/plans/well-we-kind-of-federated-swing.md`.

---

## v1.2 Requirements

### Reliability primitives

- [x] **REL-01**: Accept an optional `idempotency_key:` opt on every current `create/*` function (Customers, Addresses, Transactions) and pass it through as the `Idempotency-Key` request header. *(Phase 8 complete. Phase 10's new Subscriptions.create/2 must copy the same opts pattern from Plan 08-03.)*
- [x] **REL-02**: Configure `req` with an automatic retry policy that respects `Retry-After`: max 3 retries with exponential backoff, retry only on 429 + 5xx + transient network errors, no retry on 4xx other than 429. *(Phase 8 complete.)*
- [x] **REL-03**: Normalize transient network failures (timeout, nxdomain, etc.) into `%Paddle.Error{}` with `:network_error?` and `:retryable?` flags. Existing `:raw_data` field on `%Paddle.Error{}` must remain — additive change only, no v1.1 seam break. *(Phase 8 complete.)*

### Pagination ergonomics

- [x] **PAGE-01**: Provide `Paddle.stream/3` and `Paddle.all/3` (or per-resource equivalents) that auto-paginate over any list endpoint by chaining `Paddle.Page.next_cursor/1`. Existing per-resource `list/2` shape stays locked. *(Phase 9.)*

### Subscriptions surface completion

- [ ] **SUB-04**: `Paddle.Subscriptions.create/2` — create a subscription, returning hydrated `%Paddle.Subscription{}`. Pure additive surface; locked seam preserved. *(Phase 10. Closes the P0 Accrue blocker.)*
- [ ] **SUB-05**: `Paddle.Subscriptions.pause/2` — pause a subscription, returning the updated `%Paddle.Subscription{}`. Reverses the v1.1 PROJECT.md "deferred mutation surface" stance for v1.2. *(Phase 10.)*
- [ ] **SUB-06**: `Paddle.Subscriptions.resume/2` — resume a previously paused subscription. *(Phase 10.)*

### Type-safety pass

- [ ] **TYPES-01**: Add `@spec` annotations to every public function across `lib/paddle/` (≥33 functions today, plus SUB-04..06 added in Phase 10). *(Phase 11.)*
- [ ] **TYPES-02**: Wire `:dialyxir` in `mix.exs` with a PLT cache configuration; establish a clean `mix dialyzer` baseline (empty `.dialyzer_ignore.exs`); add `mix dialyzer` as a CI gate in `.github/workflows/ci.yml`. *(Phase 11.)*

### Documentation pass

- [ ] **DOCS-01**: Add `@doc` with at least one example to every public function across `lib/paddle/`. *(Phase 12.)*
- [ ] **DOCS-02**: Add `@moduledoc` to every public module. The five modules sealed by SEAM-02 (`Paddle`, `Paddle.Http`, `Paddle.Http.Telemetry`, `Paddle.Application`, `Paddle.Internal.Attrs`) keep their `@moduledoc false` — those sealings are locked. *(Phase 12.)*
- [ ] **DOCS-03**: Replace the README "TODO: Add description" stub at `README.md:3` with an installation + quick-start + cross-links structure that an outside adopter can follow without reading source. *(Phase 12.)*
- [ ] **DOCS-04**: Publish a happy-path `guides/getting-started.md` (client → customer → transaction → webhook), wired into `mix.exs` `:docs` extras. *(Phase 12.)*
- [ ] **DOCS-05**: Publish `guides/telemetry.md` documenting the `[:paddle, :request, :start | :stop | :exception]` events emitted from `lib/paddle/http/telemetry.ex`, including measurement and metadata schemas. *(Phase 12.)*

### Process guard

- [ ] **PROC-01**: Add a pre-commit hook (or `mix gsd.precommit` task) that fails the commit if any in-progress phase SUMMARY claims files are committed but `git status --porcelain` shows them dirty/untracked. Closes the v1.1 audit-trail recurrence vector documented in `MILESTONES.md:27-30`. *(Phase 13.)*
- [ ] **PROC-02**: Add the same SUMMARY/git-state drift check as a CI step in `.github/workflows/ci.yml`, so the guard works even when contributors skip local hooks. *(Phase 13.)*

---

## Future Requirements (deferred from v1.2)

- [ ] **REFUND-01**: `Paddle.Adjustments` for refunds. Accrue's Stripe path uses `create_refund/2`/`retrieve_refund/2`; oarlock has none. Likely v1.3.
- [ ] **CATALOG-01**: `Paddle.Products`, `Paddle.Prices` read + create. Demand-driven; defer until a real consumer asks.
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
- **`Paddle.Subscriptions.update/3`**: Open question carried into `/gsd-discuss-phase 10`. Default disposition: include if cleanly bundleable with pause/resume; otherwise defer.

---

## Traceability

Coverage: 14 / 14 v1.2 requirements mapped (100%).

| Requirement | Phase | Status  | Notes |
|-------------|-------|---------|-------|
| REL-01      | 8     | Complete | `idempotency_key:` opt -> `Idempotency-Key` header on current `create/*`; Phase 10 inherits pattern for Subscriptions.create/2. |
| REL-02      | 8     | Complete | `req` retry policy honoring `Retry-After`; 429 + 5xx + transient only. |
| REL-03      | 8     | Complete | Network errors normalized to `%Paddle.Error{}` with `:network_error?` / `:retryable?` (additive). |
| PAGE-01     | 9     | Complete | `Paddle.stream/3` + `Paddle.all/3` over `Paddle.Page.next_cursor/1`; locked `list/2` shape preserved. |
| SUB-04      | 10    | Pending | `Paddle.Subscriptions.create/2`. Closes P0 Accrue blocker. |
| SUB-05      | 10    | Pending | `Paddle.Subscriptions.pause/2`. |
| SUB-06      | 10    | Pending | `Paddle.Subscriptions.resume/2`. |
| TYPES-01    | 11    | Pending | `@spec` on every public function across `lib/paddle/`. |
| TYPES-02    | 11    | Pending | `:dialyxir` wired; clean baseline; `mix dialyzer` as CI gate. |
| DOCS-01     | 12    | Pending | `@doc` + example on every public function. |
| DOCS-02     | 12    | Pending | `@moduledoc` on every public module; SEAM-02 `@moduledoc false` sealings preserved. |
| DOCS-03     | 12    | Pending | README rewrite (install + quick-start + cross-links), removes line-3 TODO stub. |
| DOCS-04     | 12    | Pending | `guides/getting-started.md` published into `:docs` extras. |
| DOCS-05     | 12    | Pending | `guides/telemetry.md` published into `:docs` extras. |
| PROC-01     | 13    | Pending | Pre-commit hook for SUMMARY/git-state drift. |
| PROC-02     | 13    | Pending | Same drift check as CI step. |

---

_Created 2026-04-29 at v1.2 milestone start. Traceability filled in by roadmap creation 2026-04-29._
