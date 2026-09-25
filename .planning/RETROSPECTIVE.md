# Retrospective

Living notes from completed milestones.

## Milestone: v2.1 — Adopter Truth & Release Readiness

**Shipped:** 2026-06-25
**Phases:** 4 | **Plans:** 10

### What Was Built

- Public README, Getting Started, Accrue seam contract, demo runbook,
  changelog, and generated docs were aligned with the shipped SDK surface.
- `Paddle.MockServer` optional Plug/Bandit boundaries were made compile-safe
  for consumers without fixture dependencies.
- CI and local release-proof surfaces now cover root gates, demo PostgreSQL
  tests, downstream package smoke, and optional dependency proof.
- GSD state was reconciled across active backlog, archive, evidence ledger,
  resolved thread index, and durable planning preferences.
- Phase 30 added deterministic MockServer-backed demo checkout and portal
  handoff proof.

### What Worked

- Evidence-ledger rows made proof boundaries explicit and scan-friendly.
- Direct LiveView handoff assertions paired well with PhoenixTest journey tests.
- Keeping the core SDK unchanged while fixing demo-owned transaction attrs
  preserved the package boundary.

### What Was Inefficient

- Phase 28 validation state remained stale after implementation proof passed.
- Hosted GitHub Actions exact-SHA proof could not be captured from local-only
  branch state.
- The active roadmap already claimed v2.1 shipped before archival, so closeout
  required manual reconciliation.

### Patterns Established

- Public docs should distinguish MockServer-backed proof from sandbox/live
  provider-state proof every time release readiness is discussed.
- Future milestone planning should start from `.planning/BACKLOG.md`,
  `.planning/BACKLOG-ARCHIVE.md`, `.planning/EVIDENCE.md`,
  `.planning/threads/INDEX.md`, and `.planning/GSD-PREFERENCES.md`.
- Closure phases can be included in the milestone archive when they satisfy
  audit gaps after the original phase range.

### Key Lessons

- Archive commands still need review when a closure phase is added after the
  milestone header was written.
- Exact hosted CI proof should be treated as an external-state requirement and
  recorded as deferred debt unless the SHA is pushed.

## Cross-Milestone Trends

| Theme | Observation |
|-------|-------------|
| Proof boundaries | MockServer-backed proof is valuable, but docs must avoid implying sandbox/live provider-state verification. |
| Planning state | Active root files stay useful when historical detail moves into archives and ledgers. |
| Consumer focus | The SDK is strongest when new API breadth follows a real adopter job rather than endpoint mirroring. |
