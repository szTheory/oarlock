---
phase: 05-subscriptions-management
plan: "01"
subsystem: api
tags: [paddle, subscriptions, structs, entity-contract, tdd]

# Dependency graph
requires:
  - phase: 04-transactions-hosted-checkout
    provides: "Paddle.Http.build_struct/2 shallow-mapper precedent and Paddle.Transaction/Paddle.Transaction.Checkout entity-plus-nested-struct shape"
provides:
  - "%Paddle.Subscription{} flat 24-field entity struct (D-15, D-16) with raw_data last"
  - "%Paddle.Subscription.ScheduledChange{} 4-field nested struct exposing the canonical scheduled_change.effective_at DX path (D-18)"
  - "%Paddle.Subscription.ManagementUrls{} 3-field nested struct exposing the customer-portal cancel link (D-18)"
  - "Frozen executable contract tests (7) covering the empty-struct surface, build_struct/2 round-trip with shallow-mapper preservation, and the manual-collection update_payment_method: nil case"
affects: [05-02-resource-module, 05-03-resource-tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Plan-1 entity contract isolation: typed structs land in their own plan ahead of the resource module (mirrors Phase 4's 04-01 precedent)"
    - "Two-test shape per nested struct: empty-struct field assertion + Http.build_struct/2 round-trip with an extra ignored key"
    - "raw_data: ^data pin guarantees verbatim preservation of unknown payload branches"

key-files:
  created:
    - "lib/paddle/subscription.ex (Paddle.Subscription struct module, 28 lines)"
    - "lib/paddle/subscription/scheduled_change.ex (Paddle.Subscription.ScheduledChange struct module, 3 lines)"
    - "lib/paddle/subscription/management_urls.ex (Paddle.Subscription.ManagementUrls struct module, 3 lines)"
    - "test/paddle/subscription_test.exs (7 contract tests across 3 describe blocks, 176 lines)"
  modified: []

key-decisions:
  - "Followed Paddle.Transaction precedent verbatim — struct-only modules with no @moduledoc, no typespecs, no convenience helpers (D-25 decisive default)"
  - "Field order locked to D-16 with :raw_data last, matching every existing entity (Customer, Transaction, Address)"
  - "ScheduledChange.action and Subscription.status remain raw strings — no atom conversion (D-21)"
  - "No nested-struct hydration logic in this plan — that's a Plan 2 (resource module) concern via per-resource post-processing (D-22)"

patterns-established:
  - "Three-describe-block test layout: %Subscription{}, %Subscription.ScheduledChange{}, %Subscription.ManagementUrls{}"
  - "Pitfall 5 coverage: explicit assertion of update_payment_method: nil paired with non-nil cancel: URL pins manual-collection contract"
  - "Shallow-mapper discipline test: include 'ignored_key' => 'kept in raw only' in the input payload, assert raw_data: ^data to prove un-promoted keys land only in raw_data"

requirements-completed:
  - SUB-01
  - SUB-02
  - SUB-03

# Metrics
duration: 3min
completed: 2026-04-29
---

# Phase 5 Plan 1: Subscription Entity Contract Summary

**Locked the typed `%Paddle.Subscription{}` 24-field entity surface plus `%Paddle.Subscription.ScheduledChange{}` and `%Paddle.Subscription.ManagementUrls{}` nested structs ahead of the Plan 2 resource module via 7 executable contract tests (TDD RED → GREEN).**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-29T15:21:43Z
- **Completed:** 2026-04-29T15:24:11Z
- **Tasks:** 2
- **Files created:** 4 (3 lib + 1 test)
- **Files modified:** 0

## Accomplishments

- `%Paddle.Subscription{}` now exists as a flat 24-field struct in `lib/paddle/subscription.ex` matching the exact D-16 field order with `:raw_data` last.
- `%Paddle.Subscription.ScheduledChange{}` exposes `[:action, :effective_at, :resume_at, :raw_data]` (D-18) — gives consumers the dot-accessible `subscription.scheduled_change.effective_at` DX path.
- `%Paddle.Subscription.ManagementUrls{}` exposes `[:update_payment_method, :cancel, :raw_data]` (D-18) and explicitly handles the manual-collection null `update_payment_method` case (Pitfall 5).
- 7 ExUnit contract tests in `test/paddle/subscription_test.exs` freeze all three struct surfaces and prove `Paddle.Http.build_struct/2` round-trips the documented top-level keys while preserving the full payload in `raw_data`.
- Full repo test suite remains green (1 doctest + 82 tests, 0 failures).

## Task Commits

Each task was committed atomically following TDD RED → GREEN cadence:

1. **Task 1: Add executable contract tests** — `f24e533` (test)
2. **Task 2: Implement struct modules** — `e1d67dc` (feat)

_TDD plan-level gate sequence verified: a `test(...)` commit (RED, `f24e533`) precedes the `feat(...)` commit (GREEN, `e1d67dc`). REFACTOR was not needed — struct-only modules have no logic to clean up._

## Files Created/Modified

- `lib/paddle/subscription.ex` — `Paddle.Subscription` struct with the 24-field allowlist from D-16; mirrors `lib/paddle/transaction.ex` shape with no docs/typespecs/helpers.
- `lib/paddle/subscription/scheduled_change.ex` — `Paddle.Subscription.ScheduledChange` 4-field nested struct mirroring `lib/paddle/transaction/checkout.ex` shape.
- `lib/paddle/subscription/management_urls.ex` — `Paddle.Subscription.ManagementUrls` 3-field nested struct.
- `test/paddle/subscription_test.exs` — 3 describe blocks × 7 tests: 2 for `%Subscription{}` (empty-struct shape + `build_struct/2` round-trip), 2 for `%ScheduledChange{}`, 3 for `%ManagementUrls{}` (the third pins Pitfall 5).

## Decisions Made

- **Followed Paddle.Transaction precedent verbatim.** No `@moduledoc`, no typespecs, no `Access` behavior, no `Jason.Encoder` derivations on any of the three modules — keeps the entity contract surface minimal and consistent with existing entities.
- **Action/status enum strings stay as raw strings (D-21).** No atom conversion at the struct boundary; the test for `ScheduledChange.action == "cancel"` pins this behavior.
- **No nested-struct hydration in this plan.** `Http.build_struct/2` is shallow, so the round-trip test for `%Subscription{}` asserts `:scheduled_change` and `:management_urls` as the raw string-keyed maps that `build_struct/2` leaves them as. Hydration into typed structs is the Plan 2 (resource module) responsibility per D-22.

## Deviations from Plan

None — plan executed exactly as written. Both tasks executed in TDD order, all 7 tests passed on the GREEN run, all acceptance criteria verified.

## Issues Encountered

- On the first `mix test` invocation, dependencies were not yet fetched in this fresh worktree (`req`, `telemetry`, etc.). Resolved by running `mix deps.get` once; this is expected fresh-worktree behavior, not a deviation.
- `mix format --check-formatted` flags a pre-existing formatting issue in `lib/paddle/customers.ex:13` (a long line). This is **out of scope** for Plan 1 (per scope-boundary rule — pre-existing, not caused by this task's changes). New files in this plan are formatted correctly. Logged here for future awareness.

## Verification

All `<verification>` block commands pass:

| Command                                                                                          | Result               |
| ------------------------------------------------------------------------------------------------ | -------------------- |
| `mix test test/paddle/subscription_test.exs`                                                     | 7 tests, 0 failures  |
| `mix compile --warnings-as-errors`                                                               | exits 0              |
| `mix format --check-formatted` (new files only)                                                  | exits 0              |
| `grep -n 'defmodule Paddle.Subscription do' lib/paddle/subscription.ex`                          | matches line 1       |
| `grep -n 'defstruct \[:action, :effective_at, :resume_at, :raw_data\]' .../scheduled_change.ex`  | matches line 2       |
| `grep -n 'defstruct \[:update_payment_method, :cancel, :raw_data\]' .../management_urls.ex`      | matches line 2       |
| `grep -c '^    :' lib/paddle/subscription.ex`                                                    | returns `24`         |
| Full repo `mix test`                                                                             | 82 tests, 0 failures |

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The typed entity surface needed by Plan 2 (resource module `Paddle.Subscriptions`) is locked. Plan 2 can now safely:
  - `alias Paddle.Subscription`, `Paddle.Subscription.ScheduledChange`, `Paddle.Subscription.ManagementUrls`
  - Call `Http.build_struct(Subscription, data)` for top-level field promotion
  - Implement per-resource `build_subscription/1` post-processing that converts the `data["scheduled_change"]` map into `%ScheduledChange{}` and the `data["management_urls"]` map into `%ManagementUrls{}` (mirroring `Paddle.Transactions.build_transaction/1` from Plan 4)
- Plan 3 (resource tests) can compose fixture builders that emit the canonical Paddle subscription envelope and round-trip them through Plan 2's resource functions.
- No blockers. No deferred items.

## TDD Gate Compliance

- **RED gate:** `f24e533` — `test(05-01): add failing contract tests for Paddle.Subscription and nested structs`
- **GREEN gate:** `e1d67dc` — `feat(05-01): implement Paddle.Subscription entity and nested struct modules`
- **REFACTOR gate:** N/A (struct-only modules; no logic to refactor)

Both required gates present in git log. Plan-level TDD discipline satisfied.

## Self-Check: PASSED

- FOUND: lib/paddle/subscription.ex
- FOUND: lib/paddle/subscription/scheduled_change.ex
- FOUND: lib/paddle/subscription/management_urls.ex
- FOUND: test/paddle/subscription_test.exs
- FOUND commit: f24e533 (RED)
- FOUND commit: e1d67dc (GREEN)

---

_Phase: 05-subscriptions-management_
_Plan: 01_
_Completed: 2026-04-29_
