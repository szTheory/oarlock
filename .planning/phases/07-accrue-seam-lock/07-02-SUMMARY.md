---
phase: 07-accrue-seam-lock
plan: "02"
subsystem: docs
tags: [exdoc, accrue, seam, contract, moduledoc-false, elixir]

# Dependency graph
requires:
  - phase: 07-accrue-seam-lock
    provides: Phase 07 locked decisions D-06..D-19 (closed enumerated seam, locked/additive/opaque vocabulary, two exclusion buckets, support types)
  - phase: 06-transactions-retrieval
    provides: Paddle.Transactions.get/2 surface that the seam guide enumerates as locked
  - phase: 05-subscriptions-management
    provides: Subscription public surface and nested ScheduledChange/ManagementUrls structs documented as locked
  - phase: 04-transactions-hosted-checkout
    provides: Transaction/Checkout typed surface documented as locked
  - phase: 03-core-entities-customers-addresses
    provides: Customer/Address typed surface documented as locked
  - phase: 02-webhook-verification
    provides: Webhooks public functions and Event envelope documented as locked
  - phase: 01-core-transport-client-setup
    provides: Paddle.Client, Paddle.Page, Paddle.Error support types documented in the seam guide
provides:
  - Canonical published Accrue seam contract guide using locked/additive/opaque vocabulary
  - Closed enumerated public docs surface (15 supported modules + Paddle.Error exception)
  - Hidden internal modules (Paddle.Http, Paddle.Http.Telemetry, placeholder Paddle root) excluded from doc/api-reference.md
  - Explicit boundary policy stating undocumented internals may change without notice in 0.x
  - D-08 support-type documentation (Paddle.Client.new!/1, %Paddle.Page{}, Paddle.Page.next_cursor/1, %Paddle.Error{})
  - Two exclusion buckets: "Out of scope for the current 0.x seam" and "Intentionally excluded from core"
affects: [accrue, hexdocs, public-api, future seam additions, future plan-level threat models]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@moduledoc false suppression for internal/placeholder modules (matches existing Paddle.Internal.Attrs pattern)"
    - "Guide-first canonical seam contract; README remains a lightweight pointer"

key-files:
  created:
    - guides/accrue-seam.md
    - .planning/phases/07-accrue-seam-lock/07-02-SUMMARY.md
  modified:
    - lib/paddle/http.ex
    - lib/paddle/http/telemetry.ex
    - lib/paddle.ex

key-decisions:
  - "Replace `raw` and `not-planned` field-tier vocabulary with the locked `locked`/`additive`/`opaque` taxonomy across the entire guide (D-11..D-14, D-16)."
  - "Document `:raw_data` rows as `locked` with `opaque` contents on every struct table (D-15)."
  - "Add an explicit boundary policy paragraph stating the seam is closed and only documented modules, functions, structs, and support types are supported (D-06, D-09, D-10)."
  - "Add a dedicated Support Types section covering Paddle.Client.new!/1, %Paddle.Page{}, Paddle.Page.next_cursor/1, and %Paddle.Error{} (D-08)."
  - "Replace the single `Not Planned` section with two buckets: `Out of scope for the current 0.x seam` and `Intentionally excluded from core` (D-17..D-19)."
  - "Hide the placeholder `Paddle` root module with `@moduledoc false` and `@doc false` on `hello/0`; runtime behavior preserved, doctest extraction degrades gracefully (resolves Resolved Question 1 from 07-RESEARCH.md)."

patterns-established:
  - "Pattern 1: Canonical guide + closed published surface — guide enumerates the seam; ExDoc only publishes modules consistent with that enumeration."
  - "Pattern 2: Internal module suppression via @moduledoc false matches the existing Paddle.Internal.Attrs precedent without introducing ExDoc :filter_modules configuration."
  - "Pattern 3: README stays a pointer — the canonical contract lives in guides/accrue-seam.md, not duplicated in README.md."

requirements-completed: [SEAM-02]

# Metrics
duration: 4min
completed: 2026-04-29
---

# Phase 07 Plan 02: Publish Accrue Seam Contract & Seal Docs Surface

**Canonical Accrue seam guide rewritten to the locked `locked`/`additive`/`opaque` vocabulary plus an explicit closed-enumeration boundary, and `Paddle.Http`, `Paddle.Http.Telemetry`, and the placeholder `Paddle` root module are hidden from `doc/api-reference.md` via `@moduledoc false`.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-29T18:55:30Z
- **Completed:** 2026-04-29T18:59:12Z
- **Tasks:** 2
- **Files modified:** 4 (1 created in `guides/`, 3 modified in `lib/`)

## Accomplishments

- Rewrote `guides/accrue-seam.md` end-to-end so its vocabulary, boundary statement, support-type section, struct field tiers, and exclusion buckets exactly match Phase 07 decisions D-06 through D-19. The `:raw_data` field is now `locked` on every struct row with notes calling its contents `opaque`; `additive` is reserved for places the seam explicitly allows growth (notably `:errors` and `:meta` pagination metadata).
- Added an explicit closed-enumeration boundary policy stating that `Paddle.Http`, `Paddle.Internal.*`, `%Paddle.Client{}` internals such as `:req`, the placeholder root `Paddle` module, and any function not enumerated in the guide are outside the supported seam and may change without notice inside 0.x.
- Documented D-08 support types — `Paddle.Client.new!/1`, `%Paddle.Page{}` (with `:data` `locked` and `:meta` `additive`), `Paddle.Page.next_cursor/1`, and `%Paddle.Error{}` — as part of the seam without expanding the seam test path or promoting `%Paddle.Client{}` internals.
- Hid the three leaked modules from the published API surface by adding `@moduledoc false` to `lib/paddle/http.ex`, `lib/paddle/http/telemetry.ex`, and `lib/paddle.ex`. Runtime behavior is unchanged (`Paddle.Http.request/4`, `Paddle.Http.build_struct/2`, the telemetry attachment pipeline, and `Paddle.hello/0` still behave identically; full `mix test` passes 111 tests with 0 failures).
- Verified that regenerated `doc/api-reference.md` lists exactly the 15 supported public modules plus the `Paddle.Error` exception (16 total entries), `doc/accrue-seam.html` is published, and the seam guide remains wired through the existing `extras: ["guides/accrue-seam.md"]` block in `mix.exs`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite `guides/accrue-seam.md` to match D-06 through D-19** — `9e60340` (docs)
2. **Task 2: Hide leaked internal modules from the generated docs surface** — `49f8f39` (feat)

_(Final metadata commit will follow this SUMMARY's creation; see Self-Check below.)_

## Files Created/Modified

- `guides/accrue-seam.md` — rewritten in place: locked/additive/opaque vocabulary, explicit boundary policy, Support Types section, `:raw_data` rows reclassified as `locked` with `opaque` contents, two exclusion buckets.
- `lib/paddle/http.ex` — added `@moduledoc false` (no behavioral changes to `request/4` or `build_struct/2`).
- `lib/paddle/http/telemetry.ex` — added `@moduledoc false` (no behavioral changes to `attach/1` or telemetry steps).
- `lib/paddle.ex` — added `@moduledoc false`; replaced the placeholder docstring on `hello/0` with `@doc false`. The function still returns `:world` and the existing `test "greets the world"` test continues to pass.

## Decisions Made

- **Tier classification of `%Paddle.Page{}.meta`** — chose `additive` (not `opaque`) because `Paddle.Page.next_cursor/1` is a stable accessor that consumers should depend on; the underlying map is allowed to grow but is not provider-opaque the way `:items` or `:data` payloads are.
- **Tier classification of `%Paddle.Error{}.errors`** — kept as `additive` (forwarded detail entries may grow without breaking) and reclassified `:raw` as `locked` with `opaque` contents to match the new escape-hatch policy applied to every other struct's `:raw_data` row.
- **Placeholder `Paddle` root module** — followed Resolved Question 1 in `07-RESEARCH.md`: hide it rather than expand it into a package-overview module. Added `@doc false` to `hello/0` so the placeholder's iex example does not appear under a hidden module. The `doctest Paddle` line in `test/paddle_test.exs` continues to run cleanly with zero examples extracted (verified by full `mix test`).
- **README** — left untouched; the existing pointer "For the Accrue-facing integration surface, see [Accrue Seam Contract](guides/accrue-seam.md)" still resolves correctly to the rewritten guide whose top-level heading is unchanged (`# Accrue Seam Contract`).

## Deviations from Plan

None of significance — the plan executed exactly as written. The following minor adjustment was needed to keep the boundary-policy acceptance regex matchable on a single line:

### Auto-fixed Issues

**1. [Rule 1 - Bug] Boundary policy sentence wrapped across two lines defeated the acceptance regex**
- **Found during:** Task 1 verification
- **Issue:** Initial draft put a soft line break between "Only explicitly" and "documented modules…", so `rg -n 'Only explicitly documented modules, functions, structs, and support types are supported' guides/accrue-seam.md` returned no matches because ripgrep is line-oriented.
- **Fix:** Reflowed the boundary paragraph so each canonical sentence sits on a single line. Content is unchanged; only whitespace.
- **Files modified:** `guides/accrue-seam.md`
- **Verification:** Both required boundary phrases now match exactly once each via `rg -n`.
- **Committed in:** `9e60340` (Task 1 commit; the reflow happened before staging).

---

**Total deviations:** 1 auto-fixed (1 bug — verification regex compatibility)
**Impact on plan:** Cosmetic only; no scope creep. Boundary statement wording matches the locked decisions verbatim.

## Issues Encountered

- **`mix docs` warning:** `documentation references module "Paddle" but it is hidden` — the new boundary section explicitly mentions the hidden placeholder `Paddle` root module by name in a bullet list. This is the desired behavior (the guide is documenting the exclusion), and the warning is informational; `mix docs` exits 0 and the seam guide renders. Left as-is.

## Acceptance Criteria — Verified

Task 1 (`guides/accrue-seam.md`):
- `rg -n '`opaque`' guides/accrue-seam.md` → 14 matches (≥3 required).
- `! rg -n '`raw`|`not-planned`' guides/accrue-seam.md` → exits 1 (no matches; required).
- `rg -n 'Paddle\.Client\.new!/1|%Paddle\.Page\{|Paddle\.Page\.next_cursor/1|%Paddle\.Error\{' guides/accrue-seam.md` → 21 matches (≥4 required).
- `rg -n 'Out of scope for the current 0\.x seam|Intentionally excluded from core' guides/accrue-seam.md` → 2 matches (exactly 2 required).
- `rg -n ':raw_data.*`locked`' guides/accrue-seam.md` → 8 matches (≥6 required).
- Boundary sentences: both required policy phrases match exactly once.

Task 2 (`@moduledoc false` and regenerated docs):
- `rg -n '@moduledoc false' lib/paddle/http.ex lib/paddle/http/telemetry.ex lib/paddle.ex` → 3 matches (exactly 3 required).
- `mix docs` → exits 0.
- `test -f doc/accrue-seam.html` → exits 0.
- `! rg -n 'Paddle\.Http|Paddle\.Http\.Telemetry|^- \[Paddle\]' doc/api-reference.md` → exits 1 (no matches; required).
- The 16 expected entries (15 supported modules + `Paddle.Error`) all present.
- `^- [Paddle.` line count = 15 (exact match required).
- `Accrue Seam Contract` appears in `doc/accrue-seam.md`.
- `extras: ["guides/accrue-seam.md"]` appears once in `mix.exs`.

Plan-level verification:
- `mix docs` succeeded.
- Full `mix test` passes 111 tests with 0 failures.
- `mix compile --warnings-as-errors` succeeded.

## User Setup Required

None — no external service configuration is required for this plan.

## Self-Check

- [x] `guides/accrue-seam.md` exists (FOUND).
- [x] `lib/paddle/http.ex`, `lib/paddle/http/telemetry.ex`, and `lib/paddle.ex` modified (FOUND in `git log`).
- [x] Task 1 commit `9e60340` exists in `git log`.
- [x] Task 2 commit `49f8f39` exists in `git log`.

## Self-Check: PASSED

## Next Phase Readiness

- Phase 07 Plan 01 (the adapter-backed end-to-end seam test, `test/paddle/seam_test.exs`) was already executed in a prior session and is locked in by the canonical guide produced here. The published seam now matches what the seam test asserts: same enumerated public modules, same locked struct surfaces, same support types treated outside the end-to-end path, and `:raw_data` documented consistently as a locked escape hatch with opaque contents.
- Phase 07 itself is now complete: SEAM-01 (the seam test) and SEAM-02 (this plan) are both delivered, finishing milestone v1.1 (Accrue Seam Hardening).
- Future Accrue-side asks should continue to be triaged into `.planning/BACKLOG.md` (per user MEMORY directive); they should not auto-insert phases here.

## Threat Flags

No new threat surface introduced. This plan only narrows the published consumer contract by hiding internal modules and clarifying vocabulary; it adds no new endpoints, no new auth/authz paths, no new file access patterns, and no schema changes. T-07-06 through T-07-10 from the plan's threat register are mitigated as documented in the plan body.

---
*Phase: 07-accrue-seam-lock*
*Plan: 02*
*Completed: 2026-04-29*
