# Project Roadmap

## Milestones

- ◼ **v2.1 Adopter Truth & Release Readiness** — Phases 27-29 (planned)
- ✅ **v2.0 Offline Mode & Advanced Billing** — Phases 25-26 (shipped 2026-06-11)
- ✅ **v1.5 Demo App & DX Hardening** — Phases 20-24 (shipped 2026-06-11)
- ✅ **v1.4 Catalog & Events** — Phases 17-19 (shipped 2026-06-10)
- ✅ **v1.3 Support & Self-Serve Surface** — Phases 14-16 (shipped 2026-06-09)
- ✅ **v1.2 Production Surface** — Phases 8-13 (shipped 2026-06-09)
- ✅ **v1.1 Accrue Seam Hardening** — Phases 6-7 (shipped 2026-04-29)

## Current Milestone: v2.1 Adopter Truth & Release Readiness

**Goal:** Make the public adopter story, GSD planning state, and release proof match what the code actually ships before adding more Paddle API breadth.

### Phase 27: Public Contract & Documentation Truth

**Goal:** A cold Phoenix SaaS adopter can understand the real supported SDK surface without reading source.
**Requirements:** DOCS-01, DOCS-02, DOCS-03, DOCS-04
**Plans:** 1/3 plans executed

Plans:
**Wave 1**

- [x] 27-01-PLAN.md — Seam docs-truth guard and canonical contract inventory.
- [ ] 27-02-PLAN.md — README, Getting Started, and demo runbook adopter truth.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 27-03-PLAN.md — Changelog narrative and final documentation consistency gate.

**Success Criteria:**

1. README, Getting Started, seam contract, demo runbook, and changelog agree with shipped modules and function arities.
2. Docs distinguish core SDK responsibilities from Phoenix/Ecto/provisioning responsibilities.
3. MockServer-backed proof is described honestly and not conflated with live Paddle provider-state testing.

### Phase 28: CI, Demo, and Package Proof

**Goal:** Release readiness is continuously proven for the library, demo, and downstream install path.
**Requirements:** PROOF-01, PROOF-02, PROOF-03, PROOF-04

**Success Criteria:**

1. CI keeps the existing library gates: format, compile warnings-as-errors, tests, public specs, Dialyzer, and SUMMARY drift guard.
2. CI runs the demo test suite with a PostgreSQL service.
3. A downstream consumer/package smoke test verifies oarlock can be depended on and compiled by a fresh Mix app.
4. Optional `plug`/`bandit` behavior is explicitly verified or documented for `Paddle.MockServer`.

### Phase 29: GSD State Reconciliation

**Goal:** Future milestone planning starts from trustworthy project state rather than stale backlog or overclaimed audits.
**Requirements:** GSD-01, GSD-02, GSD-03, GSD-04

**Success Criteria:**

1. PROJECT, REQUIREMENTS, ROADMAP, STATE, BACKLOG, milestone audit files, and investigation threads agree on shipped/open scope.
2. Shipped backlog items are marked as historical, Accrue-only, or superseded.
3. v2.0 audit/validation language is reconciled with actual evidence.
4. Recurring GSD preferences are available in project/global defaults.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 27. Public Contract & Documentation Truth | v2.1 | 1/3 | In Progress|  |
| 28. CI, Demo, and Package Proof | v2.1 | 0/0 | Planned | — |
| 29. GSD State Reconciliation | v2.1 | 0/0 | Planned | — |
| 25. Offline Mode Foundation | v2.0 | 1/1 | Complete | 2026-06-11 |
| 26. Advanced Subscription Flows E2E | v2.0 | 2/2 | Complete | 2026-06-11 |
