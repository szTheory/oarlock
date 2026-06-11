# Project Roadmap

**Milestone:** v1.5 Demo App & DX Hardening
**Granularity:** Coarse
**Coverage:** 15/15 v1 requirements mapped

## Phases

- [ ] **Phase 20: Local DX & Repository Foundation** - Scaffolds isolated demo app and Docker environment
- [ ] **Phase 21: UI Scaffolding & Mock Auth** - Implements mock authentication and Petal admin dashboard
- [ ] **Phase 22: Core SaaS Checkout & Webhooks** - Integrates Paddle Checkout and validated webhook persistence
- [ ] **Phase 23: Customer Portal & Lifecycle Management** - Adds self-service portal and lifecycle webhook handling
- [ ] **Phase 24: Shift-Left E2E Testing Pipeline** - Instruments Playwright CI pipeline with webhook simulations

## Phase Details

### Phase 20: Local DX & Repository Foundation
**Goal**: Developers can run an isolated Phoenix demo application locally without port conflicts.
**Depends on**: None
**Requirements**: FND-01, FND-02, FND-03
**Success Criteria** (what must be TRUE):
  1. A Phoenix app exists in `/demo` requiring `oarlock` via path dependency.
  2. `docker-compose up` provisions PostgreSQL and Traefik routing to `demo.docker.localhost`.
  3. Demo app starts with seeded base products/prices from `priv/repo/seeds/`.
**Plans**: TBD

### Phase 21: UI Scaffolding & Mock Auth
**Goal**: Users can log into a mock admin interface styled with modern UI components.
**Depends on**: Phase 20
**Requirements**: UI-01, UI-02, UI-03
**Success Criteria** (what must be TRUE):
  1. User can authenticate as a mock user without a real password.
  2. User can view a responsive admin dashboard shell utilizing Tailwind CSS and Petal Components.
  3. Dashboard follows progressive disclosure patterns.
**Plans**: TBD
**UI hint**: yes

### Phase 22: Core SaaS Checkout & Webhooks
**Goal**: Users can initiate a checkout and the application securely records the resulting subscription state.
**Depends on**: Phase 21
**Requirements**: CHK-01, CHK-02, CHK-03
**Success Criteria** (what must be TRUE):
  1. User can open the Paddle hosted checkout overlay from the pricing page.
  2. Demo app successfully receives and cryptographically verifies webhooks from Paddle.
  3. Successful checkout webhooks automatically link the `paddle_customer_id` to the mock `user_id` in the local Ecto database.
**Plans**: TBD
**UI hint**: yes

### Phase 23: Customer Portal & Lifecycle Management
**Goal**: Users can manage their subscription securely via the Paddle Customer Portal.
**Depends on**: Phase 22
**Requirements**: PRT-01, PRT-02
**Success Criteria** (what must be TRUE):
  1. Authenticated user can generate and navigate to a secure Customer Portal session.
  2. Upgrades, downgrades, or cancellations made in the Portal correctly update the local database via webhook events.
**Plans**: TBD
**UI hint**: yes

### Phase 24: Shift-Left E2E Testing Pipeline
**Goal**: The demo application is automatically tested end-to-end to prevent regressions.
**Depends on**: Phase 23
**Requirements**: E2E-01, E2E-02, E2E-03, E2E-04
**Success Criteria** (what must be TRUE):
  1. Playwright tests can navigate the application UI via `phoenix_test`.
  2. Tests can programmatically fire valid signed webhooks into the app to simulate Paddle callbacks.
  3. CI pipeline executes these tests successfully against the Dockerized database without sandbox conflicts.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 20. Local DX & Repository Foundation | 0/0 | Not started | - |
| 21. UI Scaffolding & Mock Auth | 0/0 | Not started | - |
| 22. Core SaaS Checkout & Webhooks | 0/0 | Not started | - |
| 23. Customer Portal & Lifecycle Management | 0/0 | Not started | - |
| 24. Shift-Left E2E Testing Pipeline | 0/0 | Not started | - |
