# Roadmap

## Milestones

- 🚧 **v1.2 Production Surface** — Phases 8-13 (in progress)
- ✅ **v1.1 Accrue Seam Hardening** — Phases 6-7 (shipped 2026-04-29) — see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; foundational SDK surface)

## Phases

<details open>
<summary>🚧 v1.2 Production Surface (Phases 8-13) — IN PROGRESS</summary>

- [ ] Phase 8: Reliability Primitives (0/4 plans) — REL-01, REL-02, REL-03
- [ ] Phase 9: Pagination Ergonomics (0/? plans) — PAGE-01
- [ ] Phase 10: Subscriptions Surface Completion (0/? plans) — SUB-04, SUB-05, SUB-06
- [ ] Phase 11: Type-Safety Pass (0/? plans) — TYPES-01, TYPES-02
- [ ] Phase 12: Documentation Pass (0/? plans) — DOCS-01..05
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
  1. Every `create/*` public function (Customers, Addresses, Transactions, and the new Subscriptions.create/2 from Phase 10) accepts an `idempotency_key:` opt; an adapter-backed test asserts the value is forwarded as the `Idempotency-Key` HTTP header.
  2. An adapter-backed test exercises a 429 response with `Retry-After: 2` and the request succeeds after the client honors the retry; a sibling test asserts no retry on 4xx other than 429 and a max-3-retry ceiling on 5xx.
  3. A simulated transient network failure (timeout / nxdomain) returns `{:error, %Paddle.Error{network_error?: true, retryable?: true}}` with the existing `:raw_data` field still present (additive change only).
  4. The full pre-existing test suite (≥111 tests at v1.1 close) continues to pass with zero failures — no v1.1 seam regression.
**Plans**: 4 plans
  - [x] 08-01-PLAN.md — Atomic rename `:raw → :raw_data` in `%Paddle.Error{}` + add explicit `false` defaults for `:network_error?` and `:retryable?` (defexception keyword-syntax migration); co-update `guides/accrue-seam.md:118` and `CHANGELOG.md` in a single commit per D-02. (Wave 1, foundation for REL-03.)
  - [x] 08-02-PLAN.md — REL-03 transport-error normalization: add `Paddle.Error.from_transport/1` (with `transport_type/1` multiclause covering D-14 taxonomy `network_timeout|network_nxdomain|network_closed|network_unknown`); refactor `Http.request/4` `{:error, %Req.TransportError{}}` arm; four adapter-backed reason-variant tests in `http_test.exs`. (Wave 2, depends on 08-01.)
  - [ ] 08-03-PLAN.md — REL-01 idempotency-key plumbing: `Keyword.pop(:idempotency_key)` + `ArgumentError` validation in `Http.request/4` (Pitfall 3 ordering); add trailing `opts \\ []` to `Customers.create/3`, `Customers.Addresses.create/4`, `Transactions.create/3`; six unit tests + one integration test locking the locked v1.2 opts vocabulary `:idempotency_key + :retry`. (Wave 3, depends on 08-01 + 08-02.)
  - [ ] 08-04-PLAN.md — REL-02 retry policy: add `retry: :transient, max_retries: 3` to `Paddle.Client.new!/1`; five Agent-backed retry tests in `http_test.exs` covering 5xx-then-success, 4xx-no-retry, 429-then-success, per-call `retry: false` opt-out, and max-3 ceiling; CHANGELOG entry. (Wave 4, depends on 08-01..08-03.)

### Phase 9: Pagination Ergonomics
**Goal**: Consumers iterate any list endpoint without hand-rolling cursor loops, while the locked per-resource `list/2` shape stays untouched.
**Depends on**: Phase 8 (idempotency/retry harness reused for streaming requests).
**Requirements**: PAGE-01
**Success Criteria** (what must be TRUE):
  1. `Paddle.stream/3` (or per-resource equivalent) returns an `Enumerable` that, given a fixture of three cursor pages, yields every item from every page in order and terminates cleanly.
  2. `Paddle.all/3` returns the same items as `Paddle.stream/3 |> Enum.to_list/1` for the same fixture.
  3. A regression test re-asserts that `Paddle.Subscriptions.list/2` (and at least one other locked `list/2`) still returns `{:ok, %Paddle.Page{}}` — the v1.1 locked shape is unchanged.
  4. `Paddle.Page.next_cursor/1` remains the documented cursor accessor; auto-pagination is built on top of it, not as a replacement.
**Plans**: TBD

### Phase 10: Subscriptions Surface Completion
**Goal**: Close Accrue's P0 (subscription create) plus P1 (pause/resume) blockers while preserving the v1.1 locked seam contract from `guides/accrue-seam.md`.
**Depends on**: Phase 8 (idempotency keys flow through `Subscriptions.create/2`).
**Requirements**: SUB-04, SUB-05, SUB-06
**Success Criteria** (what must be TRUE):
  1. `Paddle.Subscriptions.create/2` returns `{:ok, %Paddle.Subscription{}}` with hydrated `:scheduled_change` and `:management_urls` when present, and validation atoms (`{:error, :invalid_attrs}`) on bad input — adapter-backed.
  2. `Paddle.Subscriptions.pause/2` and `Paddle.Subscriptions.resume/2` each return the updated `%Paddle.Subscription{}` with `:status` and `:paused_at` reflecting the action — adapter-backed.
  3. **Locked-seam discipline**: a struct-shape regression test confirms `%Paddle.Subscription{}` adds zero new locked fields and removes/renames zero existing locked fields. Any new data point flows through `:raw_data` (additive/opaque) per `guides/accrue-seam.md`.
  4. `guides/accrue-seam.md` is updated to list `create/2`, `pause/2`, `resume/2` under `Paddle.Subscriptions` Public Modules and to remove "Subscription mutations beyond cancel" from the **Out of scope** bucket — closing the documentation/contract delta.
  5. All v1.1 seam contract tests (`test/paddle/seam_test.exs`) continue to pass without modification — the existing locked surface is untouched.
**Plans**: TBD

### Phase 11: Type-Safety Pass
**Goal**: oarlock has machine-checked specs end-to-end so an Accrue-side type drift fails CI here, not in production.
**Depends on**: Phases 8, 9, 10 (specs cover the new public API additions: idempotency_key opt, stream/all helpers, SUB-04..06).
**Requirements**: TYPES-01, TYPES-02
**Success Criteria** (what must be TRUE):
  1. `mix dialyzer` exits 0 against an empty `.dialyzer_ignore.exs` on a fresh PLT build.
  2. Every public function across `lib/paddle/` carries a `@spec` — verified by a mechanical grep test (or equivalent script) that asserts every `def` in non-`@moduledoc false` modules has a preceding `@spec`.
  3. `mix dialyzer` runs as a required CI step in `.github/workflows/ci.yml`; a deliberately broken-spec branch in CI fails the gate.
  4. PLT cache is configured (`:dialyxir` `:plt_file` / `:plt_add_apps`) so cold-cache CI completes within a reasonable budget on the project's matrix.
**Plans**: TBD

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
**Plans**: TBD

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
| 8. Reliability Primitives | v1.2 | 2/4 | In Progress|  |
| 9. Pagination Ergonomics | v1.2 | 0/? | Pending | — |
| 10. Subscriptions Surface Completion | v1.2 | 0/? | Pending | — |
| 11. Type-Safety Pass | v1.2 | 0/? | Pending | — |
| 12. Documentation Pass | v1.2 | 0/? | Pending | — |
| 13. Process Guard | v1.2 | 0/? | Pending | — |

---

## Future Work — Accrue Integration

Driven by `~/projects/accrue` consuming oarlock as its Paddle backend. See `.planning/BACKLOG.md` for any prioritized entries that survive milestone close.

Per project memory, Accrue-side asks should be triaged into `BACKLOG.md` rather than auto-inserted as phases here.
