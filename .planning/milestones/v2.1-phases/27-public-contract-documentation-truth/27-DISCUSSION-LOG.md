# Phase 27: Public Contract & Documentation Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-24
**Phase:** 27-Public Contract & Documentation Truth
**Areas discussed:** Public surface source of truth, Adopter journey emphasis, Proof boundary language, Changelog and release narrative

---

## Public Surface Source of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Manual seam guide | Keep `guides/accrue-seam.md` as the canonical contract by reviewer discipline. Human-readable, but drift-prone. | |
| Generated contract table | Generate/update the public surface from code/docs. Strong arity drift prevention, but weak at human stability vocabulary and likely overbuilt for this phase. | |
| Hybrid verified seam guide | Keep the seam guide canonical for meaning, while validating module/function/struct inventory against code. | ✓ |

**User's choice:** Discuss all with deep research; final recommendation selected the hybrid.
**Notes:** Research emphasized ExDoc/HexDocs norms, Accrue-specific stability tiers, and the risk of pretending code generation can express consumer-contract intent.

---

## Adopter Journey Emphasis

| Option | Description | Selected |
|--------|-------------|----------|
| Cold Phoenix SaaS path first | Best for likely first adopters, but risks implying framework coupling. | |
| Generic Elixir SDK reference first | Strongest for SDK boundary, but weaker activation for a Phoenix SaaS developer trying to sell a subscription. | |
| Task-based JTBD guide | Center real jobs while clearly labeling Phoenix/Plug/Ecto examples as app-owned. | ✓ |

**User's choice:** Discuss all with emphasis on great DX, principle of least surprise, user persona, and JTBD.
**Notes:** Final recommendation starts from adopter jobs: client, checkout transaction, webhook verification, canonical fetch, cancellation/management. Phoenix examples are allowed but must not become implied SDK features.

---

## Proof Boundary Language

| Option | Description | Selected |
|--------|-------------|----------|
| Soft offline language | Friendly and concise, but easy to overclaim. | |
| Balanced proof ladder | Distinguish unit/contract, MockServer, sandbox, and live responsibilities. | ✓ |
| Blunt SRE warning blocks | Strongly prevents false confidence, but can make first-read docs feel heavy if overused. | Partial |
| Sandbox-first proof language | Useful only when real sandbox checks were actually run. | |

**User's choice:** Discuss all, including DevOps/SRE trust and footguns.
**Notes:** Final recommendation uses the proof ladder everywhere, with blunt warnings only at trust boundaries.

---

## Changelog and Release Narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Concise docs-alignment bullet | Low maintenance, but too vague for adopter trust. | |
| Full adopter-truth narrative | Concrete, but risks duplicating the seam guide and sounding like marketing. | |
| Hybrid bounded narrative | Concrete changelog entry with compact surface inventory and links to canonical docs. | ✓ |

**User's choice:** Discuss all with emphasis on release truth, maintainability, and no fluff.
**Notes:** Final recommendation follows Keep-a-Changelog style, avoids commit-log noise, and keeps the detailed contract in `guides/accrue-seam.md`.

---

## Claude's Discretion

- Exact wording, heading order, and verification mechanism are left to the planner/executor as long as the context decisions hold.
- The docs-truth verification should be the lightest reliable mechanism after inspecting current Mix/test patterns.

## Deferred Ideas

- Phase 28 owns CI demo and downstream package proof.
- Phase 29 owns GSD state/audit/backlog reconciliation.
- New SDK endpoints, Phoenix/Ecto packages, admin UI, and live provider-state CI are outside this phase.
