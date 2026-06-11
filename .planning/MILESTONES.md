# Milestones Log

Chronological record of shipped milestones. Newest first.

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

### Archive

- Roadmap: `.planning/ROADMAP.md`
- Requirements: `.planning/REQUIREMENTS.md`
- Audit: `.planning/v1.5-MILESTONE-AUDIT.md`
- Tag: `v1.5`

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

### Archive

- Roadmap: `.planning/milestones/v1.3-ROADMAP.md`
- Requirements: `.planning/milestones/v1.3-REQUIREMENTS.md`
- Tag: `v1.3`

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

---
