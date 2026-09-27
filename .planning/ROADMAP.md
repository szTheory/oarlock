# Roadmap: Paddle Elixir SDK

## Overview

Milestone v2.2 repairs oarlock's delivery trust chain before expanding the
public API. Work proceeds from repository truth, through SDK safety and
authoritative CI, into release integrity and daily contribution operations,
then establishes a provenance-backed JTBD map and closes the remaining operational handoff gap in Phase 37. The 29
requirements in this roadmap are the complete committed scope; future horizons
remain guidance and require explicit promotion through a later discovery cycle.

## Milestones

- 🚧 **v2.2 Trust, Coverage & Green Delivery** — Phases 31-37 (active)
- ✅ **v2.1 Adopter Truth & Release Readiness** — Phases 27-30 (shipped 2026-06-25) — [archive](milestones/v2.1-ROADMAP.md)
- ✅ **v2.0 Offline Mode & Advanced Billing** — Phases 25-26 (shipped 2026-06-11) — [archive](milestones/v2.0-ROADMAP.md)
- ✅ **v1.5 Demo App & DX Hardening** — Phases 20-24 (shipped 2026-06-11) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.4 Catalog & Events** — Phases 17-19 (shipped 2026-06-10) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.3 Support & Self-Serve Surface** — Phases 14-16 (shipped 2026-06-09) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.2 Production Surface** — Phases 8-13 (shipped 2026-06-09) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 Accrue Seam Hardening** — Phases 6-7 (shipped 2026-04-29) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; phase artifacts retained)

## Phases

- [x] **Phase 31: Repository & Planning Truth** - Establish a non-destructive, authoritative account of repository state, active scope, and shipped history. (completed 2026-09-10)
- [x] **Phase 32: Dependency & SDK Trust Boundary** - Make dependency, telemetry, inspection, retry, validation, and public-contract behavior safe and truthful. (completed 2026-09-23)
- [x] **Phase 33: Deterministic Green CI** - Make one complete, measured, immutable CI contract authoritative for each exact SHA and remote main. (completed 2026-09-24)
- [x] **Phase 34: Release Integrity** - Bind every automatic and recovery publication to the accepted exact-SHA CI and package identity. (completed 2026-09-26)
- [x] **Phase 35: Review, Ownership & Worktree Operations** - Make bounded PRs, triage, ownership, dependency updates, and clean worktree handling the normal contributor path. (completed 2026-09-26)
- [x] **Phase 36: JTBD Coverage, Durable Trajectory & Handoff** - Preserve a validated capability compass, append-only provenance, and evidence-complete milestone handoff. (completed 2026-09-27)
- [ ] **Phase 37: Milestone Closeout Reconciliation** - Preserve and reconcile outstanding work, prove the exact candidate, and complete clean-worktree handoff acceptance.

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

**Plans**: 9/9 plans executed (5 original, 4 gap closure)

Plans:

- [x] 31-06-PLAN.md
- [x] 31-07-PLAN.md
- [x] 31-08-PLAN.md
- [x] 31-09-PLAN.md

**Wave 1**

- [x] 31-01-PLAN.md — Read-only all-worktree repository inventory with shared human/JSON truth.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 31-02-PLAN.md — Canonical active-scope and completion-proof planning health.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 31-03-PLAN.md — Immutable milestone-history validation and additive reconciliation.

**Wave 4** *(gap closure; blocked on Wave 3 completion)*

- [x] 31-04-PLAN.md — Repository-bounded planning and ownership source reads with fail-closed diagnostics.

**Wave 5** *(gap closure; blocked on Wave 4 completion)*

- [x] 31-05-PLAN.md — Canonical completion proof, exact phase ranges, and causal Git identity collection failures.

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

**Plans**: 16/16 plans executed (11 original, 5 gap closure; 0 pending)

Plans:
**Wave 1**

- [x] 32-01-PLAN.md — Isolate the secure Req 0.7.4 root/demo dependency migration.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 32-02-PLAN.md — Migrate the bounded adjustment/customer and catalog/event Req adapter fixture families.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 32-11-PLAN.md — Migrate remaining integration fixtures and build the fail-fast compatibility matrix with atomic acceptance.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 32-03-PLAN.md — Validate explicit client construction and align/redact its public docs, types, and inspection.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 32-04-PLAN.md — Establish bounded read retries, non-replayed mutation reconciliation, and truthful central docs/types.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 32-05-PLAN.md — Harden adjustment/customer/address/portal-session request paths and their module contracts.
- [x] 32-06-PLAN.md — Harden catalog/event/notification request paths and their module contracts.
- [x] 32-09-PLAN.md — Redact every secret-bearing public inspection boundary with aligned public types/docs.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 32-07-PLAN.md — Harden subscription/transaction/pagination paths and their module contracts.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 32-08-PLAN.md — Replace telemetry payloads with paired per-attempt allowlists and aligned module docs.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 32-10-PLAN.md — Mechanically prove runtime/docs/types agreement, isolated concurrency, interruption rejection, and the final matrix.

**Wave 10** *(gap closure; blocked on Wave 9 completion)*

- [x] 32-12-PLAN.md — Contain caller mutation options before they can replace validated client transport authority.

**Wave 11** *(gap closure; blocked on Wave 10 completion)*

- [x] 32-13-PLAN.md — Normalize malformed errors, correct stream guidance, and add bounded verifier proof without weakening full acceptance.

**Wave 12** *(gap closure; blocked on Wave 11 completion)*

- [x] 32-14-PLAN.md — Make compatibility and bounded-contract acceptance fail closed across preflight failure, timeout, signals, and nonzero termination.
- [x] 32-15-PLAN.md — Reject duplicate subscription lifecycle retry options before normalization or dispatch, independent of key order.
- [x] 32-16-PLAN.md — Bind bounded contract acceptance to exact semantic proof identities and executed docs/spec checks.

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

**Plans**: 4/4 plans executed
**Wave 1**

- [x] 33-01-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 33-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 33-03-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 33-04-PLAN.md

### Phase 34: Release Integrity

**Goal**: Release stewards can publish only the exact, fully proven package they intended, through either the automatic or recovery path.
**Depends on**: Phase 33
**Requirements**: SHIP-01, SHIP-02, SHIP-03, SHIP-04
**Success Criteria** (what must be TRUE):

  1. Automatic and recovery publishing both stop before release-secret access when the exact candidate SHA lacks an accepted complete CI contract.
  2. A release proceeds only when source SHA, tag target, package version, built artifact, and eventual published package agree.
  3. Concurrent publication attempts serialize safely, use least privilege, and the recovery path cannot bypass any automatic-path quality or identity gate.
  4. Maintainer can trace a release from exact SHA and CI run through artifact and dry-run evidence to publication and post-publish verification.

**Plans**: 6/6 plans executed (4 original, 2 gap-closure)

Plans:
**Wave 1**

- [x] 34-01-PLAN.md — Trace one existing-tag recovery release through exact-SHA proof, Mix/Hex publication, consumer verification, and evidence.

**Wave 2** *(blocked on Wave 1 completion; plans may run in parallel)*

- [x] 34-02-PLAN.md — Route Release Please through the same gate and shared queued publisher lock.
- [x] 34-03-PLAN.md — Prove checksum and fetched-package agreement and reconcile ambiguous Hex outcomes.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 34-04-PLAN.md — Attach durable release evidence, protect tags, and record remote policy and hosted proof.

**Wave 4** *(gap closure; blocking maintainer disposition)*

- [x] 34-05-PLAN.md — Record the maintainer's explicit disposition for the unrecoverable v0.1.2 history.

**Wave 5** *(blocked on Wave 4 disposition)*

- [x] 34-06-PLAN.md — Record the selected disposition, preserve the historical evidence limits, and refresh canonical phase verification.

### Phase 35: Review, Ownership & Worktree Operations

**Goal**: Contributors and maintainers can move one bounded change from clean worktree entry through owned review and explicit triage to a clean, evidenced exit.
**Depends on**: Phase 34
**Requirements**: OPS-01, OPS-02, OPS-03, OPS-04
**Success Criteria** (what must be TRUE):

  1. A contributor can find concise contribution, security-reporting, ownership, issue, and PR guidance and submit one bounded intent with proportional evidence.
  2. A maintainer can inspect every open issue or PR and see its controlled triage state, owner, scope decision, and next action.
  3. A task can enter and exit an isolated worktree through explicit cleanliness checks; dirty, locked, stale, or unknown work is reported with ownership/disposition context and never deleted automatically.
  4. Dependency updates arrive in reviewable groups and must pass the same compatibility and security contract as any other proposed change.

**Plans**: 6/6 plans complete

Plans:

- [x] 35-06-PLAN.md

**Wave 1**

- [x] 35-01-PLAN.md — Prove manifest-bound clean worktree entry and exit without cleanup.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 35-02-PLAN.md — Publish bounded contributor guidance and verified private reporting.
- [x] 35-03-PLAN.md — Audit complete open issue and PR triage read-only.
- [x] 35-04-PLAN.md — Configure reviewable Dependabot streams under exact-SHA CI.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 35-05-PLAN.md — Record live maintainer dispositions for every open item.

### Phase 36: JTBD Coverage, Durable Trajectory & Handoff

**Goal**: Maintainers and future agents can understand who oarlock serves, what is proven or missing, why the roadmap points where it does, and exactly what evidence closes v2.2.
**Depends on**: Phase 35
**Requirements**: ORIENT-01, ORIENT-02, ORIENT-03, ORIENT-04, ORIENT-05

**Closeout follow-through (2026-09-27):** Phase 36 implementation and 8/8 automated UAT remain complete. Final operational acceptance of ORIENT-06 is assigned to Phase 37 from the milestone audit; the original requirement and historical plan evidence are retained.
**Success Criteria** (what must be TRUE):

  1. Maintainer can navigate a canonical map of relevant personas and stable JTBD IDs showing situation, desired outcome, current capability, smallest gap, and SDK/app/provider ownership boundary.
  2. Every JTBD and capability decision exposes dated sources, rationale, owner/repository, requirement and phase links, proof contract, evidence, freshness trigger, non-goals, and promotion or reopen condition.
  3. Maintainer can distinguish horizon (`short`, `mid`, `long`) from status (`shipped`, `committed`, `candidate`, `conditional`, `rejected`, `external`, `superseded`) and can inspect prior states through dated append-only transitions.
  4. A validator reports broken or contradictory links among JTBD records, requirements, phases, evidence, backlog, trajectory items, and milestone archives.
  5. The v2.2 handoff records clean repository/worktree state, exact-SHA proof, unresolved blockers, accepted caveats, and evidence-based candidates without presenting future work as committed.

**Plans**: 3/3 plans executed across 3 waves

Plans:
**Wave 1**

- [x] 36-01-PLAN.md — Establish canonical JTBD records and persona/lifecycle navigation with stable provenance.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 36-02-PLAN.md — Validate cross-links and append-only history; measure recurring value before CI integration.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 36-03-PLAN.md — Create the evidence-complete v2.2 handoff and bind hosted proof to the exact candidate SHA.

### Phase 37: Milestone Closeout Reconciliation

**Goal**: Close ORIENT-06/FLOW-CLOSEOUT with recoverable outstanding work, a reviewed exact-SHA candidate, clean accounted-for worktrees, and a finite machine-verified handoff.
**Depends on**: Phase 36
**Requirements**: ORIENT-06
**Gap Closure**: Existing v2.2 milestone audit; no new feature scope.
**Success Criteria** (what must be TRUE):

  1. Every inherited index, working-tree and untracked contribution is adopted or independently preserved with verified restore evidence and a recorded disposition.
  2. A temporary-repository regression proves payload → evidence commit → stable final verification without self-referential SHA/dirty-state churn; unsafe states fail closed.
  3. A reviewed candidate covers adopted changes and has matching hosted run/attempt/artifact proof for all required lanes; current-main proof is separately current.
  4. The shared checkout and every retained linked tree are clean, unlocked and accounted for after only authorized dispositions; a clean candidate clone alone cannot satisfy this.
  5. Live final checks and canonical phase verification pass, ORIENT-06 is accepted, and the exact next command is `$gsd-audit-milestone v2.2` with no repeated completed UAT.

**Plans**: 0/4 executed; 4 planned across 4 serial waves

Plans:
**Wave 1**

- [x] 37-01-PLAN.md — Preserve, restore-check and classify outstanding work.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 37-02-PLAN.md — Make handoff finalization finite and enforce recurring regressions.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 37-03-PLAN.md — Prepare a reviewed candidate and obtain exact-SHA hosted proof.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 37-04-PLAN.md — Apply evidenced dispositions and finalize live clean-close acceptance.

## Durable Trajectory Baseline

This baseline is a revisable compass, not a release promise. The source anchors
and promotion rules live in [REQUIREMENTS.md](REQUIREMENTS.md) and the detailed
evidence lives under [research/](research/). Future discovery may change the
direction through dated transitions that retain prior rationale and evidence.

| Horizon | Status | Baseline direction | Promotion or reconsideration rule |
|---------|--------|--------------------|-----------------------------------|
| Short | `committed` in v2.2 | Phases 31-37: repository/planning truth, SDK safety, green CI, release integrity, clean contribution operations, and JTBD provenance | Replan with a dated decision retaining source, owner, rationale, impact, and prior state |
| Mid | `candidate` | Customer and transaction discovery; quote-before-mutate; bounded causal MockServer scenarios with provider proof kept distinct | Promote only for a named JTBD with current provider research, smallest coherent surface, owner, and proof contract |
| Long | `conditional` | Packaged Accrue adoption; demand-backed B2B/manual/invoice flows; deliberate public-contract graduation | Activate only when consumer adoption, support burden, maturity, procurement, or stabilization evidence justifies it |

Candidate and conditional IDs remain in `REQUIREMENTS.md` under **Future
Requirements** and are intentionally absent from the committed phase mappings.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 31. Repository & Planning Truth | v2.2 | 9/9 | Complete    | 2026-09-10 |
| 32. Dependency & SDK Trust Boundary | v2.2 | 16/16 | Complete    | 2026-09-23 |
| 33. Deterministic Green CI | v2.2 | 4/4 | Complete    | 2026-09-24 |
| 34. Release Integrity | v2.2 | 6/6 | Complete    | 2026-09-26 |
| 35. Review, Ownership & Worktree Operations | v2.2 | 6/6 | Complete   | 2026-09-26 |
| 36. JTBD Coverage, Durable Trajectory & Handoff | v2.2 | 3/3 | Complete    | 2026-09-27 |
| 37. Milestone Closeout Reconciliation | v2.2 | 2/4 | In Progress|  |

---
*Roadmap created: 2026-09-09 for milestone v2.2*
