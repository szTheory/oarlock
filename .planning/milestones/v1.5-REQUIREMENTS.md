# Requirements: oarlock Demo App

**Defined:** 2026-06-10
**Core Value:** A production-quality, idiomatic Elixir SDK for Paddle Billing (`paddle_sdk`) serving as a pure, standalone foundation for Accrue's "second processor" strategy.

## v1 Requirements

### Demo App Foundation

- [ ] **FND-01**: Demo app generated in `/demo` using Phoenix 1.7+ without Umbrella coupling (uses `{:oarlock, path: "../"}`)
- [ ] **FND-02**: Docker Compose setup with Traefik to route `demo.docker.localhost` and avoid port 4000/5432 conflicts
- [ ] **FND-03**: Seed script structure (`priv/repo/seeds/`) established for deterministic scenarios (e.g., standard products/prices)

### UI Scaffolding & Mock Auth

- [ ] **UI-01**: Tailwind CSS and Petal Components integrated for Admin Dashboard
- [ ] **UI-02**: Mock User authentication plug established (avoids complex real auth)
- [ ] **UI-03**: Admin dashboard shell implemented following GDS (uk.gov) progressive disclosure principles

### Core SaaS Checkout & Webhooks

- [ ] **CHK-01**: Paddle SaaS Checkout overlay triggered from Demo App pricing page
- [ ] **CHK-02**: Webhook endpoint implemented in Demo App with strict signature verification
- [ ] **CHK-03**: Local Ecto DB mapping correctly links mock `user_id` to `paddle_customer_id` upon successful checkout webhook

### Customer Portal

- [ ] **PRT-01**: User can open Paddle Customer Portal via SDK-generated session
- [ ] **PRT-02**: Subscription lifecycle changes via Portal are reflected in local DB via webhooks

### Shift-Left E2E Testing Pipeline

- [ ] **E2E-01**: Playwright integrated via `phoenix_test` for browser automation
- [ ] **E2E-02**: Ecto SQL Sandbox configured to share connection between Phoenix requests and Playwright tests
- [ ] **E2E-03**: Programmatic webhook payloads generated in tests to simulate Paddle callbacks locally
- [ ] **E2E-04**: CI pipeline updated to run Demo App E2E tests in GitHub Actions

## v2 Requirements

### Offline Mode & Advanced Billing
- **ADV-01**: Fully standalone Offline Mode mock server
- **ADV-02**: Complex upgrade/downgrade E2E testing flows

## Out of Scope

| Feature | Reason |
|---------|--------|
| Custom user registration | Boilerplate distraction; MoR focus is on Paddle. |
| Custom tax/invoice logic | Paddle is Merchant of Record, we must avoid recreating Accrue's abstractions. |
| Umbrella App structure | Bleeds root `oarlock` config into Phoenix app, misrepresenting real-world DX. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 20 | Pending |
| FND-02 | Phase 20 | Pending |
| FND-03 | Phase 20 | Pending |
| UI-01 | Phase 21 | Pending |
| UI-02 | Phase 21 | Pending |
| UI-03 | Phase 21 | Pending |
| CHK-01 | Phase 22 | Pending |
| CHK-02 | Phase 22 | Pending |
| CHK-03 | Phase 22 | Pending |
| PRT-01 | Phase 23 | Pending |
| PRT-02 | Phase 23 | Pending |
| E2E-01 | Phase 24 | Pending |
| E2E-02 | Phase 24 | Pending |
| E2E-03 | Phase 24 | Pending |
| E2E-04 | Phase 24 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-10*
*Last updated: 2026-06-11 after v1.5 roadmap creation*
