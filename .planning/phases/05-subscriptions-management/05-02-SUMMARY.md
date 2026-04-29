---
phase: 05-subscriptions-management
plan: "02"
subsystem: api
tags: [paddle, subscriptions, resource-module, cancellation, pagination]

# Dependency graph
requires:
  - phase: 05-subscriptions-management
    plan: "01"
    provides: "%Paddle.Subscription{}, %Paddle.Subscription.ScheduledChange{}, %Paddle.Subscription.ManagementUrls{} typed structs"
  - phase: 04-transactions-hosted-checkout
    provides: "Paddle.Transactions.build_transaction/1 per-resource nested-struct post-processing precedent"
provides:
  - "Paddle.Subscriptions resource module with exactly 4 public functions: get/2, list/2, cancel/2, cancel_immediately/2 (D-01)"
  - "Per-resource build_subscription/1 helper that hydrates data['scheduled_change'] and data['management_urls'] into the Plan-1 typed structs (D-22)"
  - "Two-named-cancel-functions API surface (cancel/2 vs cancel_immediately/2) sharing a single private do_cancel/3 helper, with the destructive-mode literal written exactly once (D-04..D-07)"
  - "11-key D-12 list/2 query allowlist with customer_id: filter satisfying SUB-02 without a separate list_for_customer/3 wrapper"
affects: [05-03-resource-tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Composite resource-module pattern: blends Paddle.Customers (get/2 + validate_X_id + URI encoding), Paddle.Customers.Addresses (list/2 + normalize_params/1), and Paddle.Transactions (build_transaction/1 nested-struct post-processing) into a single module"
    - "Two named cancel functions over a private do_cancel/3 helper: avoids the Stripe-style polymorphic-flag footgun while keeping a single transport call site (D-04, D-05, D-07)"
    - "Per-resource nested-struct hydration: Http.build_struct/2 stays shallow; build_subscription/1 chains two case blocks for scheduled_change and management_urls (D-22)"

key-files:
  created:
    - "lib/paddle/subscriptions.ex (97 lines, Paddle.Subscriptions resource module)"
  modified: []

key-decisions:
  - "Followed the plan's canonical implementation verbatim — no ad-hoc design choices (D-25)"
  - "Aliased Paddle.Client (matching customers.ex style) so all four public function heads pattern-match %Client{} = client"
  - "Two inline case blocks in build_subscription/1 chained via rebinding (mirrors transactions.ex:35-45 line-for-line) rather than introducing a put_nested_struct/4 helper"
  - "No @moduledoc, no @doc, no @spec — Phase 3/4 resource modules have none, Phase 5 follows precedent"
  - "Public cancel functions are one-line delegators; validation lives inside do_cancel/3 so the 'effective_from' literal appears exactly once (D-07 single-call-site discipline)"

requirements-completed:
  - SUB-01
  - SUB-02
  - SUB-03

# Metrics
duration: 1min
completed: 2026-04-29
---

# Phase 5 Plan 2: Paddle.Subscriptions Resource Module Summary

**Implemented `Paddle.Subscriptions` with exactly four public functions (`get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`) sharing a single private `do_cancel/3` helper, plus a per-resource `build_subscription/1` post-processor that hydrates `:scheduled_change` and `:management_urls` into the Plan-1 typed nested structs.**

## Performance

- **Duration:** ~1 min (84s)
- **Started:** 2026-04-29T15:30:20Z
- **Completed:** 2026-04-29T15:31:44Z
- **Tasks:** 1
- **Files created:** 1 (1 lib)
- **Files modified:** 0

## Accomplishments

- `lib/paddle/subscriptions.ex` (97 lines) now exposes the locked four-function public surface from D-01: `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`. Zero other public functions.
- `cancel/2` and `cancel_immediately/2` are one-line delegators to a single private `do_cancel/3` helper. The `"effective_from"` literal appears exactly once in the file (inside `do_cancel/3`), and the `"next_billing_period"` / `"immediately"` literals each appear exactly once (in their respective public delegators) — D-07 single-call-site discipline enforced at the file shape.
- `build_subscription/1` runs every entity through `Http.build_struct(Subscription, data)` for top-level field promotion, then chains two `case` blocks (one for `data["scheduled_change"]`, one for `data["management_urls"]`) to replace each nested map with the typed Plan-1 struct via `Http.build_struct/2`. The catch-all `_ ->` branch leaves the base struct's `nil` default in place when the upstream value is `null` or non-map.
- `list/2` is `def list(%Client{} = client, params \\ [])` — top-level, two-arg, no positional `customer_id`. The 11-key D-12 allowlist is defined as `@list_allowlist ~w(id customer_id address_id price_id status scheduled_change_action collection_mode next_billed_at order_by after per_page)` and applied via `Paddle.Internal.Attrs.allowlist/2`. SUB-02 is satisfied through `customer_id:` filter passing.
- Validation tuples are exact: `{:error, :invalid_subscription_id}` for blank/missing/non-binary IDs (rejects `nil`, `""`, `"   "`, integers); `{:error, :invalid_params}` for non-map/non-keyword params containers. Business errors propagate as `%Paddle.Error{}` via `Paddle.Http.request/4` unchanged. Transport exceptions (`%Req.TransportError{}`) bubble through the success-only `with` chain.
- Path encoding uses the existing `URI.encode(id, &URI.char_unreserved?/1)` one-liner from `lib/paddle/customers.ex:48` (D-24).
- `Paddle.Http.build_struct/2` is **not** extended (D-22 explicitly forbids this) — nested-struct hydration is per-resource.
- Plan 1 struct tests (`test/paddle/subscription_test.exs`) remain green: 7 tests, 0 failures. Full repo suite remains green: 1 doctest + 82 tests, 0 failures.

## Task Commits

| Task | Name                                          | Commit    | Type | Files                          |
| ---- | --------------------------------------------- | --------- | ---- | ------------------------------ |
| 1    | Implement Paddle.Subscriptions resource module | `4b4ea76` | feat | `lib/paddle/subscriptions.ex` (created, 97 lines) |

## Files Created/Modified

- `lib/paddle/subscriptions.ex` — `Paddle.Subscriptions` module aliasing `Paddle.Client`, `Paddle.Http`, `Paddle.Internal.Attrs`, `Paddle.Subscription`, `Paddle.Subscription.ManagementUrls`, `Paddle.Subscription.ScheduledChange`. Public surface: `get/2`, `list/2`, `cancel/2`, `cancel_immediately/2`. Private helpers: `do_cancel/3`, `build_subscription/1`, `validate_subscription_id/1` (2 clauses), `normalize_params/1` (3 clauses), `subscription_path/1`, `cancel_path/1`, `encode_path_segment/1`. Module attribute: `@list_allowlist` (11 keys).

## Decisions Made

- **Followed the plan's canonical implementation verbatim (D-25 decisive default).** Every line of `lib/paddle/subscriptions.ex` was specified in the plan body; no ad-hoc design choices were introduced. `mix format` produced zero diff against the written file (no formatter rewrites).
- **Aliased `Paddle.Client` rather than fully-qualifying.** Matches `lib/paddle/customers.ex:2` style; the four public function heads pattern-match `%Client{} = client` for visual consistency.
- **Two inline `case` blocks chained via rebinding in `build_subscription/1`.** Mirrors `lib/paddle/transactions.ex:35-45` line-for-line. A `put_nested_struct/4` helper would have introduced novel structure not present in any existing analog and was explicitly noted as discretionary in the plan body — chose the verbatim-precedent path.
- **No `@moduledoc`, no `@doc`, no `@spec`.** Phase 3/4 resource modules have none; Phase 5 follows the same precedent for consistency. Documentation is a separate cross-cutting concern noted in CONTEXT.md.

## Deviations from Plan

None — plan executed exactly as written. The canonical implementation was specified verbatim in the task `<action>` block; one task, one commit, all acceptance criteria green on the first verification run.

## Issues Encountered

- On the first `mix compile` invocation, dependencies were not yet fetched in this fresh worktree. Resolved by running `mix deps.get` once; expected fresh-worktree behavior, not a deviation.

## Verification

All `<verification>` block commands and all `<acceptance_criteria>` checks pass:

| Command                                                                                                                                | Result               |
| -------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| `mix compile --warnings-as-errors`                                                                                                     | exits 0              |
| `mix format --check-formatted lib/paddle/subscriptions.ex`                                                                             | exits 0              |
| `mix test test/paddle/subscription_test.exs`                                                                                           | 7 tests, 0 failures  |
| Full repo `mix test`                                                                                                                   | 1 doctest, 82 tests, 0 failures |
| `grep -c '^  def ' lib/paddle/subscriptions.ex`                                                                                        | returns `4`          |
| `grep -F 'do_cancel(client, subscription_id, "next_billing_period")' lib/paddle/subscriptions.ex`                                      | matches 1 line       |
| `grep -F 'do_cancel(client, subscription_id, "immediately")' lib/paddle/subscriptions.ex`                                              | matches 1 line       |
| `grep -cF '"effective_from"' lib/paddle/subscriptions.ex`                                                                              | returns `1` (D-07)   |
| `grep -cF '"next_billing_period"' lib/paddle/subscriptions.ex`                                                                         | returns `1`          |
| `grep -cF '"immediately"' lib/paddle/subscriptions.ex`                                                                                 | returns `1`          |
| `grep -cF '@list_allowlist' lib/paddle/subscriptions.ex`                                                                               | returns `2` (def + use) |
| `grep -F 'URI.encode(id, &URI.char_unreserved?/1)' lib/paddle/subscriptions.ex`                                                        | matches 1 line       |
| `grep -F 'list_for_customer' lib/paddle/subscriptions.ex`                                                                              | returns 0            |
| All 11 D-12 allowlist keys present in `@list_allowlist`                                                                                | yes (no MISSING)     |
| Forbidden public functions (`def update`, `def pause`, `def resume`, `def activate`, `def charge`, `def preview_update`)               | each returns 0       |
| `grep -cF 'Paddle.Http.build_struct' lib/paddle/subscriptions.ex` (fully-qualified should be 0)                                        | returns 0            |
| `grep -cF 'Http.build_struct(Subscription' lib/paddle/subscriptions.ex`                                                                | returns 1            |
| `grep -cF 'Http.build_struct(ScheduledChange' lib/paddle/subscriptions.ex`                                                             | returns 1            |
| `grep -cF 'Http.build_struct(ManagementUrls' lib/paddle/subscriptions.ex`                                                              | returns 1            |
| `grep -cF '%Paddle.Page{' lib/paddle/subscriptions.ex`                                                                                 | returns 1            |

## Threat Surface Verification

All four threat-register mitigations from the plan's `<threat_model>` are implemented in code:

| Threat ID | Mitigation in code |
| --------- | ------------------ |
| T-05-07 (path injection via subscription_id) | `validate_subscription_id/1` rejects non-binary or blank IDs with `{:error, :invalid_subscription_id}` before any HTTP call; `URI.encode(id, &URI.char_unreserved?/1)` in `encode_path_segment/1` URL-encodes reserved characters. |
| T-05-08 (filter injection via list/2 params) | `Paddle.Internal.Attrs.allowlist/2` reduces the params map to the 11 D-12 keys; `normalize_params/1` rejects non-map/non-keyword containers with `{:error, :invalid_params}`. |
| T-05-09 (accidental wrong-mode cancellation) | Two separately named public functions (`cancel/2` vs `cancel_immediately/2`); single private `do_cancel/3` writes the `"effective_from"` value once. The literal appears exactly once in the file, verified by `grep -cF '"effective_from"' lib/paddle/subscriptions.ex` returning 1. |
| T-05-10 (nested-struct shape drift) | `build_subscription/1` post-processing replaces `data["scheduled_change"]` and `data["management_urls"]` with typed `%ScheduledChange{}` / `%ManagementUrls{}` structs; verified by aliased `Http.build_struct(ScheduledChange ...)` and `Http.build_struct(ManagementUrls ...)` each appearing exactly once. |
| T-05-12 (broadening Phase 5 surface) | `grep -c '^  def '` returns exactly `4`; `def update`, `def pause`, `def resume`, `def activate`, `def charge`, `def preview_update` all return 0. |

No new threat surface introduced beyond what the plan's threat register accounted for. No threat flags.

## Known Stubs

None. All four public functions are fully implemented and wired through to `Paddle.Http.request/4` with proper validation, allowlisting, and nested-struct hydration. There are no hardcoded empty values, placeholder strings, or unimplemented branches.

## User Setup Required

None — no external service configuration required. Plan 3 will exercise these functions through adapter-backed transport tests; production callers can already use the four public functions against a real Paddle sandbox or production environment.

## Next Phase Readiness

- Plan 3 (resource tests, `test/paddle/subscriptions_test.exs`) can now compose adapter-backed tests against the locked four-function surface. The composite analog (per `05-PATTERNS.md`) is fully laid out: Plan 3 test scaffolding pulls from `test/paddle/transactions_test.exs` (POST body assertions, error propagation, transport exceptions), `test/paddle/customers_test.exs` (GET + URL encoding + validation tuples), and `test/paddle/customers/addresses_test.exs` (list pagination + allowlist forwarding + `next_cursor` assertion).
- All struct surfaces from Plan 1 (`%Subscription{}`, `%ScheduledChange{}`, `%ManagementUrls{}`) and the resource module from Plan 2 are stable. No further entity or resource-module changes are anticipated for Phase 5.
- No blockers. No deferred items.

## TDD Gate Compliance

The plan's `tdd="true"` flag is acknowledged. The plan body explicitly states "Plan 3 will add the adapter-backed transport tests; do NOT preempt that work in this plan." Plan-level TDD coverage for the public resource-module surface is therefore deferred to Plan 3 by design (a documented planning decision, not a deviation).

The Plan 1 struct contract tests in `test/paddle/subscription_test.exs` (which exercise `%Subscription{}`, `%ScheduledChange{}`, and `%ManagementUrls{}` plus `Http.build_struct/2` round-trips) remain green as the Plan 2 verification gate — Plan 2 introduces no struct-surface changes, so the Plan 1 RED/GREEN gates from commits `f24e533` (test) and `e1d67dc` (feat) cover the typed-data foundation that Plan 2's `build_subscription/1` post-processor relies on.

## Self-Check: PASSED

- FOUND: lib/paddle/subscriptions.ex
- FOUND commit: 4b4ea76 (feat)

---

_Phase: 05-subscriptions-management_
_Plan: 02_
_Completed: 2026-04-29_
