# Phase 7: Accrue Seam Lock - Discussion Log

**Date:** 2026-04-29
**Mode:** Discuss-phase with parallel advisor research
**Outcome:** Recommendations auto-locked based on explicit user preference for decisive defaults

## User Instruction

The user selected all identified gray areas and explicitly requested:
- parallel subagent research
- pros/cons/tradeoffs for each approach
- idiomatic guidance for Elixir / Plug / Ecto / Phoenix consumption contexts
- lessons from successful libraries and adjacent ecosystems
- strong developer ergonomics and least-surprise recommendations
- one-shot, coherent recommendations with minimal need for further user arbitration
- a project-wide bias toward shifting non-critical decisions left inside GSD

## Area 1: Seam test strictness

### Options considered
1. Semantic seam test on documented guarantees
2. Exhaustive literal seam test of full response shapes

### Chosen
`Semantic seam test on documented guarantees`

### Why
- Best fit for a narrow, forward-compatible Elixir SDK seam.
- Preserves additive flexibility while still locking the call flow and consumer-visible contract.
- Avoids the common SDK footgun of turning provider fixture noise into semver obligations.

## Area 2: Published contract boundary

### Options considered
1. Enumerated closed seam
2. Namespace-by-convention seam

### Chosen
`Enumerated closed seam`

### Why
- Strongest least-surprise posture for consumers.
- Matches the repo's existing curated boundary strategy.
- Prevents accidental support of internal modules or undocumented fields.

## Area 3: Field tier policy

### Options considered
1. `stable` + `passthrough`
2. `locked` + `additive` + `opaque`

### Chosen
`locked` + `additive` + `opaque`

### Why
- Best fit for the current architecture: typed fields, selective nested structs, `raw_data` escape hatches.
- Clarifies that forwarded provider blobs exist but are not key-stable.
- Keeps `not-planned` out of field-tier vocabulary.

## Area 4: Deferred surface wording

### Options considered
1. Two-bucket public wording: `out of scope for the current 0.x seam` and `intentionally excluded from core`
2. Multi-label roadmap taxonomy

### Chosen
`Two-bucket public wording`

### Why
- Minimizes public contract vocabulary drift.
- Avoids accidentally promising timing through overly nuanced labels.
- Better fit for consumer docs than for internal roadmap management.

## Cross-Cutting Preference Locked

- Future GSD work for this project should prefer decisive, researched defaults.
- Escalate only when a choice materially affects public contract, architecture, or integration posture.
- Keep recommendations coherent with idiomatic Elixir library design, strong DX, and least surprise.

## Research Inputs

- Existing repo artifacts: `guides/accrue-seam.md`, `test/paddle/seam_test.exs`, `README.md`, `mix.exs`, prior phase context files, and milestone research files.
- Parallel advisor research for:
  - seam test strictness
  - published contract boundary
  - field tier policy
  - deferred surface wording

## Resulting Direction

Phase 7 context should treat the seam guide as the canonical contract, the seam test as its executable proof, and future public-surface growth as opt-in only after it is both documented and tested.
