# Phase 15: Adjustments - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-09
**Phase:** 15-Adjustments
**Areas discussed:** Signature: Positional args vs Attrs, Partial Adjustments Helper vs Raw Attrs

---

## Signature: Positional args vs Attrs

| Option | Description | Selected |
|--------|-------------|----------|
| Signature: Positional args vs Attrs | Should `action` (refund/credit) and `reason` be required positional arguments e.g., `create(client, action, reason, attrs)`, or just part of the `attrs` map `create(client, attrs)`? | |
| One-shot perfect recommendation | Research using subagents/context to provide idiomatic, cohesive, best-practice recommendations for DX and architecture. | ✓ |

**User's choice:** One-shot perfect recommendation
**Notes:** The user requested a perfect, one-shot set of recommendations incorporating deep research, Elixir/Plug/Ecto/Phoenix idioms (like `stripity_stripe`), and great developer ergonomics. Claude provided the recommendation to stick to `create(client, attrs)` since `action` and `reason` are body payload elements, not URL path parameters. Positional arguments should be reserved for path parameters. The user accepted this recommendation.

---

## Partial Adjustments Helper vs Raw Attrs

| Option | Description | Selected |
|--------|-------------|----------|
| Partial Adjustments Helper vs Raw Attrs | Should the SDK provide a dedicated helper like `create_partial(client, items, attrs)` or just let the caller build the `items` array and pass it via the standard `create` `attrs` map? | |
| One-shot perfect recommendation | Research using subagents/context to provide idiomatic, cohesive, best-practice recommendations for DX and architecture. | ✓ |

**User's choice:** One-shot perfect recommendation
**Notes:** The user requested a perfect, one-shot set of recommendations incorporating deep research and Elixir idioms. Claude provided the recommendation to use raw `attrs` combined with strict Dialyzer typespecs instead of building a dedicated helper. This aligns with the "data in, data out" philosophy and prevents SDK runtime bloat while providing excellent autocomplete DX in editors. The user accepted this recommendation.

---

## Claude's Discretion

The exact Typespec layout and structure to achieve maximum editor autocomplete support for the nested `items` array.

## Deferred Ideas

None
