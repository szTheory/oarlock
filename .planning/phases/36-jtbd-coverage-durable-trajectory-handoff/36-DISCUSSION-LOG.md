# Phase 36: JTBD Coverage, Durable Trajectory & Handoff - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 36-JTBD Coverage, Durable Trajectory & Handoff
**Areas discussed:** Persona boundary, maintainer reading path, evidence freshness and revalidation

---

## Persona boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Direct audiences only | Cover adopters, downstream maintainers, and Oarlock maintainers; express app/provider responsibilities in ownership fields. | |
| Layered audiences | Include direct audiences and evidence-backed external jobs; keep owner and candidate/external status explicit. | ✓ |

**User's choice:** “Adopt the recommendations.”
**Notes:** Keep support, finance, and reconciliation roles as candidates until evidence supports promotion. Paddle is a provider boundary, not a human persona.

---

## Maintainer reading path

| Option | Description | Selected |
|--------|-------------|----------|
| Persona-first index | Find jobs by the actor who experiences them. | |
| Lifecycle-first index | Follow end-to-end jobs and identify capability gaps along the workflow. | |
| Dual linked indexes | Offer both entry points over one canonical record source. | ✓ |

**User's choice:** “Adopt the recommendations.”
**Notes:** Keep rationale, status history, and evidence in canonical records; indexes link by stable JTBD ID.

---

## Evidence freshness and revalidation

| Option | Description | Selected |
|--------|-------------|----------|
| Event-triggered only | Revalidate when a cited source or target changes. | |
| Fixed cadence | Recheck all evidence on a recurring schedule. | |
| Source-specific hybrid | Use source events by default and a maximum age only for mutable external facts without dependable change signals. | ✓ |

**User's choice:** “Adopt the recommendations.”
**Notes:** Preserve historical evidence and exact identity; old proof cannot silently satisfy a changed current gate.

---

## the agent's Discretion

- Choose the smallest repository-local record and index layout that maintains a single source of truth.
- Select deterministic, read-only validation and tests; place high-signal checks in the existing CI contract when recurring value justifies the cost.
- Revalidate current external claims before any candidate promotion.

## Deferred Ideas

- `.planning/seeds/SEED-001-reader-first-readme.md` remains a later-milestone README/adopter-onboarding task.
- Future operational API capabilities remain candidates pending adopter evidence and a proof-backed promotion decision.
