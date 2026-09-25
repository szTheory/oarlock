# Milestones Log

Chronological record of shipped milestones. Newest first.

---

## v2.1 Adopter Truth & Release Readiness (Shipped: 2026-06-25)

**Status:** ✅ Shipped
**Phases:** 27-30 (4 phases, 10 plans, 22 tasks)
**Test suite at tag:** Local release-proof gates passed; hosted GitHub Actions exact-SHA proof remains deferred until pushed/PR CI runs.

### Delivered

- README, Getting Started, and demo runbook now describe the shipped adopter journey, app-owned boundaries, and MockServer proof limits
- Unreleased changelog now names the public documentation truth pass without overclaiming Hex version, runtime capability, or provider-state proof
- Paddle.MockServer now preserves offline HTTP fixture behavior with Plug/Bandit present while keeping the core SDK compile-safe for consumers that do not install those optional dependencies.
- CI now continuously proves the root gates, Phoenix demo PostgreSQL tests, Hex package downstream consumption, and the MockServer optional dependency boundary.
- Active planning surfaces now expose only current candidates while shipped backlog and resolved investigation history remain searchable through archive and index files.
- Canonical v2.0/v2.1 evidence ledger with append-only audit errata and corrected MockServer proof boundaries for archived v2.0 planning docs
- Root GSD state now points to active backlog, archive, evidence, resolved-thread, and durable preference surfaces without ignored config policy.
- Deterministic Phoenix demo tests now prove MockServer checkout `open_checkout` and customer portal redirects directly.
- Demo docs and the evidence ledger now describe the strengthened MockServer-backed checkout and portal proof without hosted/live overclaims.

### Known Deferred Debt

- Hosted GitHub Actions exact-SHA proof is unavailable for local HEAD until the branch is pushed or opened as a PR.
- Phase 28 validation artifact remains stale/partial even though local implementation and proof commands passed.

### Release Identity

- **Planning milestone:** `v2.1`
- **Git tag:** `v2.1`
- **Source SHA:** `80e22f5a9846ed00bf93c82c6c1c4c376121c7fe`
- **Declared Hex package version:** `0.1.1`
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Archive

- Roadmap: `.planning/milestones/v2.1-ROADMAP.md`
- Requirements: `.planning/milestones/v2.1-REQUIREMENTS.md`
- Audit: `.planning/milestones/v2.1-MILESTONE-AUDIT.md`
- Tag: `v2.1`

---

## v2.0 Offline Mode & Advanced Billing — 2026-06-11

**Status:** ✅ Shipped
**Phases:** 25-26 (3 plans)
**Test suite at tag:** Passes locally

### Delivered

1. **Offline Mode Foundation** - Introduced `Paddle.MockServer` powered by Bandit for fully standalone offline Paddle development and testing. SDK clients can seamlessly point to the offline server via configuration.
2. **Advanced Subscription Flows E2E** - Delivered comprehensive MockServer-backed integration tests for complex upgrade and downgrade subscription scenarios, verifying deterministic prorations and billing-cycle behavior without manual intervention.

### Key Decisions

- Selected Bandit for the `Paddle.MockServer` foundation.
- Recorded Phase 25 validation in `VALIDATION.md`; the absent standard `VERIFICATION.md` filename is an artifact-standard caveat, not missing ADV-01 proof.

### Release Identity

- **Planning milestone:** `v2.0`
- **Git tag:** `v2.0`
- **Source SHA:** `0bc15ae77de0c9137ab0766ef040dbe2ca067e9c`
- **Declared Hex package version:** `0.1.1`
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Correction - 2026-06-24

Earlier v2.0 wording implied Phase 26 provider-state verification. The canonical evidence ledger is `.planning/EVIDENCE.md`: ADV-02 is MockServer-backed integration proof unless sandbox/live Paddle provider-state evidence is separately recorded.

### Archive

- Roadmap: `.planning/milestones/v2.0-ROADMAP.md`
- Requirements: `.planning/milestones/v2.0-REQUIREMENTS.md`
- Audit: `.planning/v2.0-MILESTONE-AUDIT.md`
- Tag: `v2.0`

---

## v1.5 Demo App & DX Hardening — 2026-06-11

**Status:** ✅ Shipped
**Phases:** 20-24 (5 plans)
**Test suite at tag:** Passes locally (E2E simulation integrated)

### Delivered

1. **Local DX & Repository Foundation** - Standalone `/demo` Phoenix 1.7+ project created using Docker Compose and Traefik for an isolated evaluation environment free of port collisions.
2. **UI Scaffolding & Mock Auth** - Integrated Petal Components and a frictionless mock authentication flow protecting the `/admin` boundary.
3. **Core SaaS Checkout & Webhooks** - Built backend-driven Paddle SaaS checkout. Implemented `DemoWeb.WebhookController` using a unified persistent inbox pattern, effectively securing the event ingress via `Paddle.Webhooks.verify_signature/4`.
4. **Customer Portal & Lifecycle Management** - Engineered a robust LiveView `open_portal` event invoking the newly authored `Paddle.PortalSessions.create/2`. Gracefully extended the webhook listener to ingest `subscription.canceled` and `subscription.paused` payloads identically to creation events.
5. **Shift-Left E2E Testing Pipeline** - Converted Playwright UI mandates into a deterministic Elixir-native workflow using `phoenix_test`. Constructed `DemoWeb.WebhookSimulator` to inject mathematically valid HMAC-SHA256 test payloads dynamically through the actual endpoint to confidently test the local DB persistence and real-time PubSub UI.

### Key Decisions

- Selected `phoenix_test` to verify browser logic deterministically inside ExUnit instead of provisioning an external headless framework.
- Persisted webhooks prior to evaluation (`webhook_events` schema) in accordance with the industry-standard event inbox strategy.
- Adopted the "Second Processor" standard by exclusively wrapping frontend components around server-side SDK execution instead of allowing purely frontend initialization.

### Release Identity

- **Planning milestone:** `v1.5`
- **Git tag:** Unknown — no local `v1.5` ref exists in the inspected repository.
- **Source SHA:** Unknown — no local tag target is available.
- **Declared Hex package version:** Unknown — no tagged `mix.exs` is available locally.
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Archive

- Roadmap: `.planning/milestones/v1.5-ROADMAP.md`
- Requirements: `.planning/milestones/v1.5-REQUIREMENTS.md`
- Audit: `.planning/v1.5-MILESTONE-AUDIT.md`
- Tag: `v1.5`

---

## v1.4 Catalog & Events — 2026-06-10

**Status:** ✅ Shipped
**Phases:** 17-19 (3 phases, 5 plans)
**Test suite at tag:** Local milestone proof recorded in the frozen roadmap; hosted publication proof is not recorded.

### Delivered

1. **Catalog read surface** - Typed product and price list/get APIs with the established pagination helpers.
2. **Events API** - Historical event list/get operations producing the same typed event surface used by webhooks.
3. **Notification Settings** - Full read and mutation coverage for webhook destination configuration.

### Release Identity

- **Planning milestone:** `v1.4`
- **Git tag:** `v1.4`
- **Source SHA:** `0876613656dc1bdb41e9d83ad635b962eb076605`
- **Declared Hex package version:** `0.1.1`
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Archive

- Roadmap: `.planning/milestones/v1.4-ROADMAP.md`
- Requirements: `.planning/milestones/v1.4-REQUIREMENTS.md`

---

## v1.3 Support & Self-Serve Surface — 2026-06-09

**Status:** ✅ Shipped
**Phases:** 14-16 (3 plans, 6 tasks)
**Test suite at tag:** Passes locally (see CI for total tests count)

### Delivered

1. **Customer Portal Sessions** - `Paddle.Customers.PortalSessions.create/3`
2. **Adjustments** - `Paddle.Adjustments` for full and partial refunds and credits.
3. **Seam Validation & Documentation** - Expanded `guides/accrue-seam.md` with explicit field tiers for new entities. End-to-end Accrue seam test incorporates adjustments and portal session flows.

### Key Decisions

- Avoided deeply validating `subscription_ids` for portal sessions, deferring to the API.
- Implemented custom `Inspect` protocols to redact sensitive temporary URLs.
- Instantiated distinct one-shot clients for test isolation.
- Used custom `Req` mock instead of `Tesla.Mock` for tests to match established conventions.

### Known Gaps / Audit Trail

- **No formal milestone audit (`v1.3-MILESTONE-AUDIT.md`) was produced before close.** Proceeded with archival accepting gaps as tech debt.

### Release Identity

- **Planning milestone:** `v1.3`
- **Git tag:** `v1.3`
- **Source SHA:** `5220bfe0185d28b653bf95528753154889dd680c`
- **Declared Hex package version:** `0.1.1`
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Archive

- Roadmap: `.planning/milestones/v1.3-ROADMAP.md`
- Requirements: `.planning/milestones/v1.3-REQUIREMENTS.md`
- Tag: `v1.3`

---

## v1.2 Production Surface — 2026-06-09

**Status:** ✅ Shipped
**Phases:** 8-13 (6 phases, 21 plans)
**Test suite at tag:** Local milestone audit recorded 16/16 requirements met; publication proof is not recorded.

### Delivered

1. **Reliability and pagination** - Idempotency keys, bounded retries, transport normalization, and auto-pagination helpers.
2. **Subscription lifecycle** - Transaction-driven recurring starts plus pause and resume operations.
3. **Type, documentation, and process gates** - Public specs, Dialyzer, adopter guides, and SUMMARY drift enforcement.

### Release Identity

- **Planning milestone:** `v1.2`
- **Git tag:** `v1.2`
- **Source SHA:** `fb3d9a185f104194e85987541519a6168e0b568c`
- **Declared Hex package version:** `0.1.1`
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Archive

- Roadmap: `.planning/milestones/v1.2-ROADMAP.md`
- Requirements: `.planning/milestones/v1.2-REQUIREMENTS.md`

---

## v1.1 Accrue Seam Hardening — 2026-04-29

**Status:** ✅ Shipped
**Phases:** 6-7 (3 plans, 6 tasks)
**Test suite at tag:** 111 tests, 0 failures

### Delivered

Closed the consumer-contract gaps Accrue needs to consume oarlock as its Paddle backend:

1. **TXN-03 — `Paddle.Transactions.get/2`** — fetch a transaction by ID with hydrated `%Paddle.Transaction.Checkout{}` and the same SDK tuple conventions (`{:ok, struct}` / `{:error, %Paddle.Error{}}`) used elsewhere.
2. **SEAM-01 — End-to-end Accrue seam contract test** (`test/paddle/seam_test.exs`) — single offline adapter-backed test exercising the full Accrue journey: customer create → address create → transaction create → transaction get → webhook verify/parse → subscription get → subscription cancel. Freezes only documented locked guarantees from `guides/accrue-seam.md`; uses `is_map/1` presence checks for every `:raw_data` escape hatch.
3. **SEAM-02 — Canonical seam guide** (`guides/accrue-seam.md`) — published with the `locked` / `additive` / `opaque` tier vocabulary, an explicit closed-enumeration boundary policy, a Support Types section, and two exclusion buckets ("Out of scope for the current 0.x seam" and "Intentionally excluded from core"). Internal modules (`Paddle.Http`, `Paddle.Http.Telemetry`, placeholder root `Paddle`) are hidden from generated docs via `@moduledoc false`.

### Key Decisions

- Locked field-tier vocabulary: `locked` / `additive` / `opaque` (replacing earlier `raw` / `not-planned`); `:raw_data` is `locked` on every struct row with `opaque` contents.
- Closed-enumeration boundary: only documented modules, functions, structs, and support types are supported in 0.x.
- Cross-step continuation in the seam test flows through the locked typed seam (`fetched_transaction.subscription_id`) instead of opaque `event.data["subscription_id"]`.

### Known Gaps / Audit Trail

- **No formal milestone audit (`v1.1-MILESTONE-AUDIT.md`) was produced before close.** Pre-flight `mix test` against HEAD initially failed 6 tests because the TXN-03 implementation was discovered uncommitted (Phase 6 SUMMARY had incorrectly claimed `lib/paddle/transactions.ex` was already in place). Remediation: implementation, README pointer, and `mix.exs` `:ex_doc` dep + docs config landed retroactively in commit `813438d` (`fix(06-01): commit Paddle.Transactions.get/2 implementation`); accumulated formatter reflows committed separately as `65cc23b` (`chore: mix format reflows…`); SUMMARY drift annotated retroactively in commit `4470053` (`docs(retro): correct SUMMARY drift…`). Post-remediation: 111 tests, 0 failures.
- Future phase execution should run `git status` before writing SUMMARY.md to prevent this drift category.

### Release Identity

- **Planning milestone:** `v1.1`
- **Git tag:** `v1.1`
- **Source SHA:** `4a6d25daf0fbd571fc0b2dae5ad1d99ec399f146`
- **Declared Hex package version:** Unknown — the tagged source does not contain a parseable `@version` declaration.
- **Publication status:** Unknown — no independent Hex registry evidence is recorded in the repository.

### Archive

- Roadmap: `.planning/milestones/v1.1-ROADMAP.md`
- Requirements: `.planning/milestones/v1.1-REQUIREMENTS.md`
- Tag: `v1.1`

---

## v1.0 MVP — pre-archival

**Status:** ✅ Shipped (not formally archived through `/gsd-complete-milestone`)
**Phases:** 1-5

### Delivered

Foundational SDK surface:

1. **Phase 1 — Core Transport & Client Setup** (CORE-01..05): `req`-based HTTP, explicit `%Paddle.Client{}`, typed `{:ok, struct}` / `{:error, %Paddle.Error{}}` responses, `raw_data` forward compatibility, `%Paddle.Page{}` pagination support.
2. **Phase 2 — Webhook Verification** (WEB-01..03): `Paddle.Webhooks.verify_signature/4` (multi-signature, configurable timestamp tolerance, replay protection) and `Paddle.Webhooks.parse_event/1` returning `%Paddle.Event{}`.
3. **Phase 3 — Core Entities (Customers & Addresses)** (CUST-01, ADDR-01): `Paddle.Customers` (create/get/update) and `Paddle.Customers.Addresses` (create/list/update).
4. **Phase 4 — Transactions & Hosted Checkout** (TXN-01, TXN-02): `Paddle.Transactions.create/2` returning hosted checkout URL.
5. **Phase 5 — Subscriptions Management** (SUB-01..03): `Paddle.Subscriptions` get/list/cancel/cancel_immediately with hydrated `%ScheduledChange{}` and `%ManagementUrls{}`.

No archive files were generated for v1.0 at the time. Phase artifacts retained under `.planning/phases/01..05`.

### Release Identity

- **Planning milestone:** `v1.0`
- **Git tag:** Unknown — explicit pre-archive exception.
- **Source SHA:** Unknown — explicit pre-archive exception.
- **Declared Hex package version:** Unknown — explicit pre-archive exception.
- **Publication status:** Unknown — explicit pre-archive exception.

---
