# Project Roadmap

**Milestone:** v2.0 Offline Mode & Advanced Billing
**Granularity:** Coarse
**Coverage:** 2/2 v2.0 requirements mapped

## Phases

- [ ] **Phase 25: Offline Mode Foundation** - Standalone mock server for offline development and testing
- [ ] **Phase 26: Advanced Subscription Flows E2E** - Complex upgrade and downgrade testing scenarios

## Phase Details

### Phase 25: Offline Mode Foundation
**Goal**: Developers can use a standalone mock server for offline Paddle development and testing
**Depends on**: Nothing
**Requirements**: ADV-01
**Success Criteria** (what must be TRUE):
  1. Developers can run a standalone offline mode mock server locally.
  2. The mock server responds to core Paddle SDK API requests with valid simulated payloads.
  3. SDK clients can be configured to point to the offline server seamlessly via configuration.
**Plans**: TBD

### Phase 26: Advanced Subscription Flows E2E
**Goal**: Complex upgrade and downgrade subscription scenarios are fully verified via E2E testing
**Depends on**: Phase 25
**Requirements**: ADV-02
**Success Criteria** (what must be TRUE):
  1. Automated E2E test suite includes a complete upgrade flow for an active subscription.
  2. Automated E2E test suite includes a complete downgrade flow, verifying prorations and billing cycles.
  3. Test flows successfully assert against Paddle state (Sandbox or Mock) without manual intervention.
**Plans**: 2 plans
- [ ] 26-01-PLAN.md — Core update/3 and MockServer capabilities
- [ ] 26-02-PLAN.md — Advanced E2E Flow tests

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 25. Offline Mode Foundation | 1/1 | Completed | 2026-06-11 |
| 26. Advanced Subscription Flows E2E | 0/2 | Not started | - |
