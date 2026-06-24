# Requirements: oarlock v2.1

**Defined:** 2026-06-24
**Core Value:** A production-quality, idiomatic Elixir SDK for Paddle Billing serving as a pure, standalone foundation for Accrue's "second processor" strategy.

## v2.1 Requirements

### Adopter Truth

- [x] **DOCS-01**: README, Getting Started, and seam contract accurately describe the shipped SDK surface.
- [x] **DOCS-02**: Demo app documentation explains local setup, mock auth, webhook processing, portal handoff, and Offline Mode.
- [x] **DOCS-03**: Docs distinguish core SDK responsibilities from app-owned Phoenix/Ecto/provisioning responsibilities.
- [x] **DOCS-04**: Docs state the proof boundary honestly: MockServer-backed integration is not the same as live Paddle provider-state verification.

### Release Proof

- [x] **PROOF-01**: CI runs root library checks already expected for release: format, compile warnings-as-errors, tests, public specs, Dialyzer, and SUMMARY drift guard.
- [x] **PROOF-02**: CI runs the demo test suite with a PostgreSQL service.
- [x] **PROOF-03**: CI includes a downstream consumer/package smoke test that verifies a fresh Mix app can depend on oarlock and compile.
- [x] **PROOF-04**: Optional `plug` and `bandit` behavior is verified so consumers understand when `Paddle.MockServer` dependencies are required.

### GSD Truth

- [ ] **GSD-01**: Root PROJECT, REQUIREMENTS, ROADMAP, STATE, BACKLOG, and milestone audit files agree on the current shipped state.
- [ ] **GSD-02**: Stale investigations and backlog items are marked resolved, superseded, or explicitly moved to Accrue-side follow-up.
- [ ] **GSD-03**: v2.0 audit and Phase 25/26 validation language is reconciled with actual evidence.
- [ ] **GSD-04**: Recurring GSD preferences for research, adopter-first assessment, DX/UX, and lesson retention are present in project/global defaults.

## Future Requirements

### Offline Fidelity

- **MOCK-01**: MockServer models documented offline-supported flows with realistic error envelopes, pagination, and state transitions.
- **MOCK-02**: MockServer docs clearly list supported and unsupported endpoints.

### Accrue Consumption

- **ACCRUE-01**: Accrue consumes oarlock through one real Paddle-backed slice.
- **ACCRUE-02**: Accrue-side `%Paddle.Error{}.raw` references are migrated to `raw_data`.

### Demand-Driven API Expansion

- **API-01**: Payment-method APIs are added only if a real consumer job needs them beyond portal sessions and management URLs.
- **API-02**: Invoice/manual-collection flows are added only if a real consumer job needs them.
- **API-03**: Product/price CRUD, marketplace/connect, reports, and simulations remain demand-driven.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Broad Paddle endpoint mirror | Current recurring SaaS lifecycle coverage is already strong; new endpoint work should be consumer-driven. |
| Phoenix/Ecto framework package | Core library must remain a pure SDK. Demo code can illustrate app patterns without becoming core API. |
| Live Paddle sandbox mandatory CI | Provider-state checks can be manual/nightly; PR CI should stay deterministic by default. |
| Accrue implementation changes | Tracked as the next strategic wedge after oarlock release-readiness. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOCS-01 | Phase 27 | Complete |
| DOCS-02 | Phase 27 | Complete |
| DOCS-03 | Phase 27 | Complete |
| DOCS-04 | Phase 27 | Complete |
| PROOF-01 | Phase 28 | Complete |
| PROOF-02 | Phase 28 | Complete |
| PROOF-03 | Phase 28 | Complete |
| PROOF-04 | Phase 28 | Complete |
| GSD-01 | Phase 29 | Pending |
| GSD-02 | Phase 29 | Pending |
| GSD-03 | Phase 29 | Pending |
| GSD-04 | Phase 29 | Pending |

**Coverage:**

- v2.1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-06-24*
*Last updated: 2026-06-24 after adopter truth assessment*
