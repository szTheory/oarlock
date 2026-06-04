# Roadmap

## Milestones

- 🚧 **v1.2 Production Surface** — Phases 8-13 (in progress)
- ✅ **v1.1 Accrue Seam Hardening** — Phases 6-7 (shipped 2026-04-29) — see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; foundational SDK surface)

## Phases

<details open>
<summary>🚧 v1.2 Production Surface (Phases 8-13) — IN PROGRESS</summary>

- [x] Phase 8: Reliability Primitives (4/4 plans) — REL-01, REL-02, REL-03 (completed 2026-05-30)
- [x] Phase 9: Pagination Ergonomics (1/1 plans) — PAGE-01 (completed 2026-05-30)
- [x] Phase 10: Subscriptions Surface Completion (3/3 plans) — SUB-04, SUB-05, SUB-06 (completed 2026-05-30)
- [x] Phase 11: Type-Safety Pass (0/5 plans) — TYPES-01, TYPES-02 (completed 2026-06-04)
- [ ] Phase 12: Documentation Pass (0/6 plans) — DOCS-01..05
- [ ] Phase 13: Process Guard (0/? plans) — PROC-01, PROC-02

</details>

<details>
<summary>✅ v1.1 Accrue Seam Hardening (Phases 6-7) — SHIPPED 2026-04-29</summary>

- [x] Phase 6: Transactions Retrieval (1/1 plans) — TXN-03
- [x] Phase 7: Accrue Seam Lock (2/2 plans) — SEAM-01, SEAM-02

</details>

<details>
<summary>✅ v1.0 MVP (Phases 1-5) — pre-archival baseline</summary>

- [x] Phase 1: Core Transport & Client Setup (3/3 plans) — CORE-01..05
- [x] Phase 2: Webhook Verification (2/2 plans) — WEB-01..03
- [x] Phase 3: Core Entities (Customers & Addresses) (3/3 plans) — CUST-01, ADDR-01
- [x] Phase 4: Transactions & Hosted Checkout (2/2 plans) — TXN-01, TXN-02
- [x] Phase 5: Subscriptions Management (3/3 plans) — SUB-01..03

</details>

## Phase Details

### Phase 8: Reliability Primitives

**Goal**: HTTP layer survives real-world Paddle production conditions — duplicate POST safety, transient failure recovery, and uniform error shape.
**Depends on**: v1.1 closed (Phase 7).
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):

  1. Every create/start public function that truthfully supports idempotency semantics (Customers, Addresses, Transactions, and the corrected Phase 10 recurring-start path through `Paddle.Transactions.create/3`) accepts an `idempotency_key:` opt; an adapter-backed test asserts the value is forwarded as the `Idempotency-Key` HTTP header.
  2. An adapter-backed test exercises a 429 response with `Retry-After: 2` and the request succeeds after the client honors the retry; a sibling test asserts no retry on 4xx other than 429 and a max-3-retry ceiling on 5xx.
  3. A simulated transient network failure (timeout / nxdomain) returns `{:error, %Paddle.Error{network_error?: true, retryable?: true}}` with the existing `:raw_data` field still present (additive change only).
  4. The full pre-existing test suite (≥111 tests at v1.1 close) continues to pass with zero failures — no v1.1 seam regression.

**Plans**: 4 plans

  - [x] 08-01-PLAN.md — Atomic rename `:raw → :raw_data` in `%Paddle.Error{}` + add explicit `false` defaults for `:network_error?` and `:retryable?` (defexception keyword-syntax migration); co-update `guides/accrue-seam.md:118` and `CHANGELOG.md` in a single commit per D-02. (Wave 1, foundation for REL-03.)
  - [x] 08-02-PLAN.md — REL-03 transport-error normalization: add `Paddle.Error.from_transport/1` (with `transport_type/1` multiclause covering D-14 taxonomy `network_timeout|network_nxdomain|network_closed|network_unknown`); refactor `Http.request/4` `{:error, %Req.TransportError{}}` arm; four adapter-backed reason-variant tests in `http_test.exs`. (Wave 2, depends on 08-01.)
  - [x] 08-03-PLAN.md — REL-01 idempotency-key plumbing: `Keyword.pop(:idempotency_key)` + `ArgumentError` validation in `Http.request/4` (Pitfall 3 ordering); add trailing `opts \\ []` to `Customers.create/3`, `Customers.Addresses.create/4`, `Transactions.create/3`; six unit tests + one integration test locking the locked v1.2 opts vocabulary `:idempotency_key + :retry`. (Wave 3, depends on 08-01 + 08-02.)
  - [x] 08-04-PLAN.md — REL-02 retry policy: add `retry: :transient, max_retries: 3` to `Paddle.Client.new!/1`; five Agent-backed retry tests in `http_test.exs` covering 5xx-then-success, 4xx-no-retry, 429-then-success, per-call `retry: false` opt-out, and max-3 ceiling; CHANGELOG entry. (Wave 4, depends on 08-01..08-03.)

### Phase 9: Pagination Ergonomics

**Goal**: Consumers iterate any list endpoint without hand-rolling cursor loops, while the locked per-resource `list/2` shape stays untouched.
**Depends on**: Phase 8 (idempotency/retry harness reused for streaming requests).
**Requirements**: PAGE-01
**Success Criteria** (what must be TRUE):

  1. `Paddle.stream/3` (or per-resource equivalent) returns an `Enumerable` that, given a fixture of three cursor pages, yields every item from every page in order and terminates cleanly.
  2. `Paddle.all/3` returns the same items as `Paddle.stream/3 |> Enum.to_list/1` for the same fixture.
  3. A regression test re-asserts that `Paddle.Subscriptions.list/2` (and at least one other locked `list/2`) still returns `{:ok, %Paddle.Page{}}` — the v1.1 locked shape is unchanged.
  4. `Paddle.Page.next_cursor/1` remains the documented cursor accessor; auto-pagination is built on top of it, not as a replacement.

**Plans**: 1 plan

  - [x] 09-01-PLAN.md — Per-resource auto-pagination helpers for subscriptions and customer addresses, backed by hidden `Paddle.Internal.Pagination`, adapter-backed stream/all/list-shape/cursor replay tests, and public docs/changelog updates. (Wave 1.)

### Phase 10: Subscriptions Surface Completion

**Goal**: Close Accrue's P0 recurring-start blocker plus P1 pause/resume blockers while preserving the v1.1 locked seam contract from `guides/accrue-seam.md`.
**Depends on**: Phase 8 (transaction idempotency + retry boundary reused by recurring-start and lifecycle mutations), Phase 9 (current subscription guide/examples remain additive).
**Requirements**: SUB-04, SUB-05, SUB-06
**Success Criteria** (what must be TRUE):

  1. `Paddle.Transactions.create/3` remains the truthful recurring-start entrypoint for recurring price items: adapter-backed tests and guides show `idempotency_key:` on the transaction create call, checkout/manual-collection completion, webhook correlation, and canonical `Paddle.Subscriptions.get/2` hydration. No public `Paddle.Subscriptions.create/2` is introduced.
  2. `Paddle.Subscriptions.pause/3` and `Paddle.Subscriptions.pause_immediately/3` return updated `%Paddle.Subscription{}` values with hydrated `:scheduled_change` / `:management_urls`, validated lifecycle opts, explicit `idempotency_key:` rejection, and retry-only request opts — adapter-backed.
  3. `Paddle.Subscriptions.resume/3` returns the updated `%Paddle.Subscription{}` with validated `:effective_from` / `:on_resume`, explicit `idempotency_key:` rejection, and adapter-backed provider-error passthrough for resume-only state failures.
  4. **Locked-seam discipline**: a struct-shape regression test confirms `%Paddle.Subscription{}` adds zero new locked fields and removes/renames zero existing locked fields. Any new data point flows through `:raw_data` (additive/opaque) per `guides/accrue-seam.md`.
  5. `guides/accrue-seam.md` is updated to list `pause/3`, `pause_immediately/3`, and `resume/3` under `Paddle.Subscriptions`, to document transaction-driven recurring start under the existing transaction seam, and to keep direct subscription creation out of the public contract.
  6. All v1.1 seam contract tests continue to pass while the public seam expands additively with pause/resume and the corrected recurring-start narrative.**Plans**: 3 plans

**Wave 1**

  - [x] 10-01-PLAN.md — Lock the corrected SUB-04 contract in transactions/seam tests and getting-started docs around transaction-driven recurring start.
  - [x] 10-02-PLAN.md — Add `Paddle.Subscriptions.pause/3` and `pause_immediately/3` with explicit lifecycle/request opt boundaries and adapter-backed pause coverage.

**Wave 2** *(blocked on Wave 1 completion)*

  - [x] 10-03-PLAN.md — Add `Paddle.Subscriptions.resume/3`, tighten `%Paddle.Subscription{}` seam regression coverage, and update the public seam guide.

### Phase 11: Type-Safety Pass

**Goal**: oarlock has machine-checked specs end-to-end so an Accrue-side type drift fails CI here, not in production.
**Depends on**: Phases 8, 9, 10 (specs cover the new public API additions: idempotency_key opt, stream/all helpers, SUB-04..06).
**Requirements**: TYPES-01, TYPES-02
**Success Criteria** (what must be TRUE):

  1. `mix dialyzer` exits 0 against an empty `.dialyzer_ignore.exs` on a fresh PLT build.
  2. Every public function across `lib/paddle/` carries a `@spec` — verified by a mechanical grep test (or equivalent script) that asserts every `def` in non-`@moduledoc false` modules has a preceding `@spec`.
  3. `mix dialyzer` runs as a required CI step in `.github/workflows/ci.yml`; a deliberately broken-spec branch in CI fails the gate.
  4. PLT cache is configured (`:dialyxir` `:plt_file` / `:plt_add_apps`) so cold-cache CI completes within a reasonable budget on the project's matrix.

**Plans**: 5 plans

Plans:
**Wave 1**

- [x] 11-01-PLAN.md — Add public `@type t` contracts and shared helper specs to the core seam-carrier modules.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 11-02-PLAN.md — Add public function specs across customer, address, transaction, subscription, and webhook resource modules.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 11-03-PLAN.md — Create the mechanical `mix typecheck.specs` gate for public-spec coverage.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 11-04-PLAN.md — Wire Dialyxir, the empty ignore baseline, and the first clean local Dialyzer pass.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 11-05-PLAN.md — Add the dedicated CI Dialyzer/spec gate and an explicit broken-spec negative-path validation.

### Phase 12: Documentation Pass

**Goal**: An outside Elixir developer can adopt oarlock from hex.pm using only the published docs — no source-reading required.
**Depends on**: Phases 8, 9, 10 (new APIs must be documented in this pass), Phase 11 (specs land first so docs reflect typed signatures).
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05
**Success Criteria** (what must be TRUE):

  1. Every public function in `lib/paddle/` has a `@doc` with at least one `## Examples` block — verified by a mechanical grep test or `mix docs --warnings-as-errors` clean run.
  2. Every public module has a `@moduledoc`; the five sealed modules (`Paddle`, `Paddle.Http`, `Paddle.Http.Telemetry`, `Paddle.Application`, `Paddle.Internal.Attrs`) keep `@moduledoc false` exactly as v1.1 SEAM-02 left them — verified by an explicit assertion test.
  3. `README.md` no longer contains the "TODO: Add description" stub at line 3; the new README has installation, quick-start (client → customer → checkout), and cross-links to `guides/getting-started.md` and `guides/accrue-seam.md`.
  4. `guides/getting-started.md` exists and is wired into `mix.exs` `:docs` extras; running `mix docs` produces an HTML page for it without warnings.
  5. `guides/telemetry.md` exists, is wired into `:docs` extras, and documents the `[:paddle, :request, :start | :stop | :exception]` events with measurement and metadata schemas matching `lib/paddle/http/telemetry.ex`.

**Plans**: 6 plans

**Wave 1**
- [x] 12-01-PLAN.md — Guides and README (DOCS-03, DOCS-04, DOCS-05)
- [x] 12-02-PLAN.md — Core SDK Struct Docs (DOCS-01, DOCS-02)
- [ ] 12-03-PLAN.md — Billing Struct Docs (DOCS-02)
- [ ] 12-04-PLAN.md — Core Controllers Docs (DOCS-01, DOCS-02)
- [ ] 12-05-PLAN.md — Billing Controllers Docs (DOCS-01, DOCS-02)

**Wave 2**
- [ ] 12-06-PLAN.md — Sealed Module Verification (DOCS-02)

**Current note:** README and `guides/getting-started.md` drafts were started during the release-truth reset before Phase 12. Phase 12 should treat them as draft inputs to audit/finalize, not as untouched work.

### Phase 13: Process Guard

**Goal**: Close the v1.1 SUMMARY/git-state drift recurrence vector (MILESTONES.md:27-30) so the next milestone cannot ship with an uncommitted-implementation audit gap.
**Depends on**: Phase 12 (docs pass populates `mix.exs` extras; guard hooks should not race with docs config) — practically can land in parallel with Phase 12 if implementation is decoupled.
**Requirements**: PROC-01, PROC-02
**Success Criteria** (what must be TRUE):

  1. A pre-commit hook (or `mix gsd.precommit` task wired into the hook) runs locally on `git commit` against an in-progress phase SUMMARY.
  2. **Synthetic SUMMARY drift case** — a SUMMARY that claims a file is committed when `git status --porcelain` shows it dirty/untracked — blocks the commit with a clear error message naming the offending file(s).
  3. Truthful SUMMARYs (every claimed-committed file is actually committed) pass through the hook without friction.
  4. The same drift check runs as a required job in `.github/workflows/ci.yml` so the guard cannot be bypassed by skipping local hooks; a deliberately drifted PR fails CI.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status   | Completed  |
|-------|-----------|----------------|----------|------------|
| 1. Core Transport & Client Setup | v1.0 | 3/3 | Complete | pre-archival |
| 2. Webhook Verification | v1.0 | 2/2 | Complete | pre-archival |
| 3. Core Entities (Customers & Addresses) | v1.0 | 3/3 | Complete | pre-archival |
| 4. Transactions & Hosted Checkout | v1.0 | 2/2 | Complete | pre-archival |
| 5. Subscriptions Management | v1.0 | 3/3 | Complete | pre-archival |
| 6. Transactions Retrieval | v1.1 | 1/1 | Complete | 2026-04-29 |
| 7. Accrue Seam Lock | v1.1 | 2/2 | Complete | 2026-04-29 |
| 8. Reliability Primitives | v1.2 | 4/4 | Complete    | 2026-05-30 |
| 9. Pagination Ergonomics | v1.2 | 1/1 | Complete    | 2026-05-30 |
| 10. Subscriptions Surface Completion | v1.2 | 3/3 | Complete    | 2026-05-30 |
| 11. Type-Safety Pass | v1.2 | 5/5 | Complete    | 2026-06-04 |
| 12. Documentation Pass | v1.2 | 2/6 | In Progress|  |
| 13. Process Guard | v1.2 | 0/? | Pending | — |

---

## Future Work — Accrue Integration

Driven by `~/projects/accrue` consuming oarlock as its Paddle backend. See `.planning/BACKLOG.md` for any prioritized entries that survive milestone close.

Per project memory, Accrue-side asks should be triaged into `BACKLOG.md` rather than auto-inserted as phases here.

## Post-v1.2 Direction

Once v1.2 is clean, green, and released, prefer this order:

1. Support operations: refunds/credits via `Paddle.Adjustments`.
2. Customer self-serve billing: smallest provider-native portal/session/payment-management surface.
3. Catalog read surface: products/prices read/list before any broad CRUD.

Do not mirror Paddle endpoints for their own sake. Promote only work tied to a real Phoenix SaaS adopter job.
