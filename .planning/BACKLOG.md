# Backlog

Future work captured outside the current milestone. Each entry is an idea or
request that should surface during next-milestone planning, not work being done
now.

Promotion path: when the user is ready, an entry becomes a phase via
`/gsd-new-milestone` -> `/gsd-discuss-phase` (or `/gsd-add-phase`). The entry ID
(e.g. `B-04`) gets cited in the resulting phase's source-of-requirement field so
the trail stays intact.

Historical backlog entries are preserved in `.planning/BACKLOG-ARCHIVE.md`.
Shipped B-IDs remain searchable there without appearing as active oarlock scope.

## Status Taxonomy

- `Open`: candidate for future oarlock planning.
- `Accrue-only`: consumer-side follow-up tracked for context; not oarlock SDK
  scope unless a later milestone explicitly promotes related oarlock work.
- `Shipped`: satisfied by a prior phase or milestone; retained in archive only.
- `Superseded`: replaced by a newer decision or scope.
- `Reference`: historical context, not a planning candidate.

Only `Open` items and explicitly selected `Accrue-only` items are candidates for
new oarlock planning.

---

## Active Queue

### B-04 - Accrue migration: `%Paddle.Error{}.raw` -> `%Paddle.Error{}.raw_data`

**Source:** Phase 8 / Reliability Primitives - atomic rename landed in oarlock
per D-01..D-05 (`.planning/phases/08-reliability-primitives/08-CONTEXT.md`).
**Priority:** Medium - silent runtime breakage on the Accrue side
(`%Paddle.Error{raw: r}` pattern matches will fail to bind after consuming the
new oarlock version).
**Status:** Accrue-only. Oarlock shipped the `raw_data` field; Accrue update is
a follow-up commit on the consumer side.

**Why it's a gap:** The 0.x cleanup `:raw -> :raw_data` is the one breaking
change v1.2 spends from PROJECT.md's `bump-minor-pre-major: false` policy.
Pattern matches in Accrue against the previous field name will silently miss
after the version bump (see oarlock CHANGELOG `## [Unreleased]` -> `###
Breaking Changes`).

**Surface to update on Accrue side:**

- Search Accrue's codebase for `%Paddle.Error{raw: ` and `error.raw` (literal
  struct field access).
- Replace each with the new field name `:raw_data` / `error.raw_data`.
- Run Accrue's test suite to confirm.

**Sizing:** ~1 commit, ~15 minutes. Pure rename - no semantic change. Possibly
zero occurrences if Accrue never reached into the raw field; the BACKLOG entry is
low-cost insurance per RESEARCH.md A4.

**Promotion hint:** Not an oarlock phase. Handle as a one-line PR on the Accrue
side when Accrue picks up the new oarlock dependency version.

**Out of scope for B-04:** Anything beyond the rename. The new
`:network_error?` and `:retryable?` fields default to `false`; existing Accrue
code that does not pattern-match on them is unaffected.

---

## Integration Posture Reference

Two of Accrue's five prereqs do not need active backlog entries because oarlock
already meets them:

- **Pure-function webhook layer** - Phase 2 delivered `verify_signature/4` +
  `parse_event/1` + `%Paddle.Event{}` exactly as Accrue requested. No coupling
  to Phoenix/Plug. Already documented in `PROJECT.md` under Integration
  Consumers.
- **Provider-native subscription lifecycle** - direct
  `Paddle.Subscriptions.create/2` remains intentionally excluded. `update/3`,
  `pause/3`, `resume/3`, and cancellation are now part of the supported SDK
  surface; payment-method APIs beyond portal sessions/management URLs remain
  deferred.

If those positions ever shift, revisit this reference and the resolved thread
index in `.planning/threads/INDEX.md`.
