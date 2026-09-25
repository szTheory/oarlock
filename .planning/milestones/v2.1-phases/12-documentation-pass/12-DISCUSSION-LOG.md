# Phase 12: Documentation Pass - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 12-Documentation Pass
**Areas discussed:** Code examples depth, External linking strategy, Error documentation depth

---

## Code examples depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full end-to-end pipelines | Show client setup, call, and pattern match | ✓ |
| Raw function call | Just the raw function call for brevity | |

**User's choice:** Deep, one-shot "perfect" recommendation based on research.
**Notes:** Decided on a Hybrid Explicit approach. Module docs get the full pipeline; function docs get the call + pattern match. Always show the return tuple.

---

## External linking strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Aggressively link out | Link to official Paddle Billing API reference | ✓ |
| Explain provider concepts inline | Attempt to explain billing rules (proration, etc.) inline | |

**User's choice:** Deep, one-shot "perfect" recommendation based on research.
**Notes:** Mechanics inline, domain rules external. SDK docs explain BEAM mechanics. Every `@doc` must have a `## Related Paddle docs` section linking to the canonical provider docs.

---

## Error documentation depth

| Option | Description | Selected |
|--------|-------------|----------|
| List every possible local error atom | Document all SDK-generated validation atoms | ✓ |
| General error shape | Just document `%Paddle.Error{}` | |

**User's choice:** Deep, one-shot "perfect" recommendation based on research.
**Notes:** Exhaustive local atoms, broad provider structs. Typespecs list the union. Local validation atoms are explicitly documented in prose. Network/provider errors are summarized as `%Paddle.Error{}`.

---

## Claude's Discretion

- Exact layout of the README and guides, aligned with the Oarlock brand book and getting-started narrative.

## Deferred Ideas

None.