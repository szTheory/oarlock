# Roadmap: Paddle Elixir SDK

## Overview

Milestone v2.2 repairs oarlock's delivery trust chain before expanding the
public API. Work proceeds from repository truth, through SDK safety and
authoritative CI, into release integrity and daily contribution operations,
then closes with a provenance-backed JTBD map and exact-SHA handoff. The 29
requirements in this roadmap are the complete committed scope; future horizons
remain guidance and require explicit promotion through a later discovery cycle.

## Milestones

- 🚧 **v2.2 Trust, Coverage & Green Delivery** — Phases 31-36 (active)
- ✅ **v2.1 Adopter Truth & Release Readiness** — Phases 27-30 (shipped 2026-06-25) — [archive](milestones/v2.1-ROADMAP.md)
- ✅ **v2.0 Offline Mode & Advanced Billing** — Phases 25-26 (shipped 2026-06-11) — [archive](milestones/v2.0-ROADMAP.md)
- ✅ **v1.5 Demo App & DX Hardening** — Phases 20-24 (shipped 2026-06-11) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.4 Catalog & Events** — Phases 17-19 (shipped 2026-06-10) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.3 Support & Self-Serve Surface** — Phases 14-16 (shipped 2026-06-09) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.2 Production Surface** — Phases 8-13 (shipped 2026-06-09) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 Accrue Seam Hardening** — Phases 6-7 (shipped 2026-04-29) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; phase artifacts retained)

## Phases

- [ ] **Phase 31: Repository & Planning Truth** - Establish a non-destructive, authoritative account of repository state, active scope, and shipped history.
- [ ] **Phase 32: Dependency & SDK Trust Boundary** - Make dependency, telemetry, inspection, retry, validation, and public-contract behavior safe and truthful.
- [ ] **Phase 33: Deterministic Green CI** - Make one complete, measured, immutable CI contract authoritative for each exact SHA and remote main.
- [ ] **Phase 34: Release Integrity** - Bind every automatic and recovery publication to the accepted exact-SHA CI and package identity.
- [ ] **Phase 35: Review, Ownership & Worktree Operations** - Make bounded PRs, triage, ownership, dependency updates, and clean worktree handling the normal contributor path.
- [ ] **Phase 36: JTBD Coverage, Durable Trajectory & Handoff** - Preserve a validated capability compass, append-only provenance, and evidence-complete milestone handoff.

## Phase Details

### Phase 31: Repository & Planning Truth

**Goal**: Maintainers and GSD workflows can begin work from one accurate, non-destructive view of repository state, active scope, and project history.
**Depends on**: Phase 30 (shipped)
**Requirements**: REPO-01, REPO-02, REPO-03, REPO-04
**Success Criteria** (what must be TRUE):

  1. Maintainer can run one read-only inventory and see dirty paths, branch divergence, every linked worktree and lock, known ownership, and proposed disposition before any state changes.
  2. Maintainer and GSD routing identify the same active milestone from the documented authority chain; archives, caches, summaries, and old phase directories cannot create phantom active work.
  3. Maintainer can navigate a continuous milestone history whose shipped status, phase range, archive links, planning identifiers, and package-version semantics agree.
  4. Maintainer can run a non-mutating planning-health check and receive actionable failures for stale active artifacts, broken references, archive contradictions, or completion claims without proof.

**Plans**: 3 plans

Plans:
**Wave 1**

- [ ] 31-01-PLAN.md — Read-only all-worktree repository inventory with shared human/JSON truth.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 31-02-PLAN.md — Canonical active-scope and completion-proof planning health.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 31-03-PLAN.md — Immutable milestone-history validation and additive reconciliation.

### Phase 32: Dependency & SDK Trust Boundary

**Goal**: SDK consumers can use oarlock without known Req advisories, credential disclosure, unsafe mutation replay, invalid client state, or misleading contract guidance.
**Depends on**: Phase 31
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04, SAFE-05, SAFE-06
**Success Criteria** (what must be TRUE):

  1. SDK consumers can install the compatibility-tested Req upgrade, pass the supported adapter/MockServer/demo/package/downstream matrix, and obtain a clean `mix hex.audit` result.
  2. Telemetry subscribers receive stable allowlisted operational facts while credential, body, signed-URL, request/response, secret, and raw customer canaries remain absent.
  3. Inspecting every public secret-bearing value redacts both promoted secrets and equivalent values nested in raw provider payloads.
  4. Safe reads retry only within documented bounds; ambiguous mutations are not blindly replayed and instead return enough guidance for a consumer to reconcile provider state.
  5. Client construction rejects blank credentials, unsupported environments, and invalid options while valid custom MockServer base URLs continue to work, and public docs/types/examples describe that tested behavior accurately.

**Plans**: TBD

### Phase 33: Deterministic Green CI

**Goal**: Contributors and maintainers can rely on a complete, fast, reproducible CI contract that proves one exact commit and keeps remote main green.
**Depends on**: Phase 32
**Requirements**: CI-01, CI-02, CI-03, CI-04, CI-05
**Success Criteria** (what must be TRUE):

  1. Every proposed change reports one required aggregate result covering formatting, dependencies, warnings, tests, public specs, Dialyzer, Credo, ExDoc, audit, demo/PostgreSQL, package smoke, optional-dependency proof, and planning guards.
  2. A maintainer can inspect the run and verify immutable reviewed inputs, controlled runners/toolchains, runtime-aware caches, explicit timeouts, and least-privilege permissions.
  3. A maintainer can see critical-path duration and the baseline-derived feedback target, with every required proof lane still represented after performance changes.
  4. The stable aggregate check protects remote `main`, and the current main commit has durable hosted-green evidence for its exact SHA.
  5. Every authoritative run publishes a durable summary containing exact SHA, run identity, toolchains, lockfile identity, and each required lane's conclusion.

**Plans**: TBD

### Phase 34: Release Integrity

**Goal**: Release stewards can publish only the exact, fully proven package they intended, through either the automatic or recovery path.
**Depends on**: Phase 33
**Requirements**: SHIP-01, SHIP-02, SHIP-03, SHIP-04
**Success Criteria** (what must be TRUE):

  1. Automatic and recovery publishing both stop before release-secret access when the exact candidate SHA lacks an accepted complete CI contract.
  2. A release proceeds only when source SHA, tag target, package version, built artifact, and eventual published package agree.
  3. Concurrent publication attempts serialize safely, use least privilege, and the recovery path cannot bypass any automatic-path quality or identity gate.
  4. Maintainer can trace a release from exact SHA and CI run through artifact and dry-run evidence to publication and post-publish verification.

**Plans**: TBD

### Phase 35: Review, Ownership & Worktree Operations

**Goal**: Contributors and maintainers can move one bounded change from clean worktree entry through owned review and explicit triage to a clean, evidenced exit.
**Depends on**: Phase 34
**Requirements**: OPS-01, OPS-02, OPS-03, OPS-04
**Success Criteria** (what must be TRUE):

  1. A contributor can find concise contribution, security-reporting, ownership, issue, and PR guidance and submit one bounded intent with proportional evidence.
  2. A maintainer can inspect every open issue or PR and see its controlled triage state, owner, scope decision, and next action.
  3. A task can enter and exit an isolated worktree through explicit cleanliness checks; dirty, locked, stale, or unknown work is reported with ownership/disposition context and never deleted automatically.
  4. Dependency updates arrive in reviewable groups and must pass the same compatibility and security contract as any other proposed change.

**Plans**: TBD

### Phase 36: JTBD Coverage, Durable Trajectory & Handoff

**Goal**: Maintainers and future agents can understand who oarlock serves, what is proven or missing, why the roadmap points where it does, and exactly what evidence closes v2.2.
**Depends on**: Phase 35
**Requirements**: ORIENT-01, ORIENT-02, ORIENT-03, ORIENT-04, ORIENT-05, ORIENT-06
**Success Criteria** (what must be TRUE):

  1. Maintainer can navigate a canonical map of relevant personas and stable JTBD IDs showing situation, desired outcome, current capability, smallest gap, and SDK/app/provider ownership boundary.
  2. Every JTBD and capability decision exposes dated sources, rationale, owner/repository, requirement and phase links, proof contract, evidence, freshness trigger, non-goals, and promotion or reopen condition.
  3. Maintainer can distinguish horizon (`short`, `mid`, `long`) from status (`shipped`, `committed`, `candidate`, `conditional`, `rejected`, `external`, `superseded`) and can inspect prior states through dated append-only transitions.
  4. A validator reports broken or contradictory links among JTBD records, requirements, phases, evidence, backlog, trajectory items, and milestone archives.
  5. The v2.2 handoff records clean repository/worktree state, exact-SHA proof, unresolved blockers, accepted caveats, and evidence-based candidates without presenting future work as committed.

**Plans**: TBD

## Durable Trajectory Baseline

This baseline is a revisable compass, not a release promise. The source anchors
and promotion rules live in [REQUIREMENTS.md](REQUIREMENTS.md) and the detailed
evidence lives under [research/](research/). Future discovery may change the
direction through dated transitions that retain prior rationale and evidence.

| Horizon | Status | Baseline direction | Promotion or reconsideration rule |
|---------|--------|--------------------|-----------------------------------|
| Short | `committed` in v2.2 | Phases 31-36: repository/planning truth, SDK safety, green CI, release integrity, clean contribution operations, and JTBD provenance | Replan with a dated decision retaining source, owner, rationale, impact, and prior state |
| Mid | `candidate` | Customer and transaction discovery; quote-before-mutate; bounded causal MockServer scenarios with provider proof kept distinct | Promote only for a named JTBD with current provider research, smallest coherent surface, owner, and proof contract |
| Long | `conditional` | Packaged Accrue adoption; demand-backed B2B/manual/invoice flows; deliberate public-contract graduation | Activate only when consumer adoption, support burden, maturity, procurement, or stabilization evidence justifies it |

Candidate and conditional IDs remain in `REQUIREMENTS.md` under **Future
Requirements** and are intentionally absent from the committed phase mappings.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 31. Repository & Planning Truth | v2.2 | 0/3 | Not started | - |
| 32. Dependency & SDK Trust Boundary | v2.2 | 0/TBD | Not started | - |
| 33. Deterministic Green CI | v2.2 | 0/TBD | Not started | - |
| 34. Release Integrity | v2.2 | 0/TBD | Not started | - |
| 35. Review, Ownership & Worktree Operations | v2.2 | 0/TBD | Not started | - |
| 36. JTBD Coverage, Durable Trajectory & Handoff | v2.2 | 0/TBD | Not started | - |

---
*Roadmap created: 2026-09-09 for milestone v2.2*
