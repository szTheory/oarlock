# Phase 17: Catalog API - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 17-Catalog API
**Areas discussed:** Include param handling, Custom item warnings (CAT-05), ID validation

---

## Include param handling

| Option | Description | Selected |
|--------|-------------|----------|
| Drop 'include' | Drop 'include' from allowlists entirely (no eager hydration). | ✓ |
| Allow 'include' | Allow it but leave nested objects in `:raw_data`. | |

**User's choice:** Deep research requested; Claude selected dropping 'include'.
**Notes:** Adheres to the strict functional isolation and avoids building an Ecto-like ORM preload abstraction.

---

## Custom item warnings (CAT-05)

| Option | Description | Selected |
|--------|-------------|----------|
| @moduledoc | Just a `@moduledoc` warning. | ✓ |
| Runtime warning | Emitting a runtime `:telemetry` or `Logger` warning. | |

**User's choice:** Deep research requested; Claude selected @moduledoc warning.
**Notes:** Keep the functional layer pure, fast, and free of side-effects.

---

## ID validation

| Option | Description | Selected |
|--------|-------------|----------|
| Any String | Just pass any string ID to Paddle (typespec `String.t()`). | ✓ |
| Strict block | Strictly block non-catalog IDs in `get()` via regex. | |

**User's choice:** Deep research requested; Claude selected Any String.
**Notes:** Let Paddle API return 400/404, maximizing future-proofing.

---

## Claude's Discretion

The user specifically requested "deep, cohesive, one-shot recommendations" for gray areas emphasizing "developer ergonomics, principle of least surprise, and great UX". I applied this to the above three categories.

## Deferred Ideas

None — discussion stayed within phase scope.