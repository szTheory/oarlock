---
phase: 32-dependency-sdk-trust-boundary
plan: "15"
subsystem: sdk-safety
tags: [elixir, exunit, subscriptions, retries, mutation-safety]

requires:
  - phase: 32-dependency-sdk-trust-boundary
    provides: Method-aware retry and one-attempt ambiguous-mutation contracts
provides:
  - Order-independent duplicate `:retry` rejection for every public subscription lifecycle mutation
  - Zero-dispatch regression coverage for conflicting retry options
affects: [safe-04, subscription-lifecycle, retry-policy]

actuals:
  tokens: 657
  tasks: 2
  commits: 4
plan_head_before: 9154b74d31ce4afb7528ba6614160ef0de200dd6

tech-stack:
  added: []
  patterns: [resource-local pre-normalization validation, table-driven zero-dispatch mutation tests]

key-files:
  created: []
  modified:
    - lib/paddle/subscriptions.ex
    - test/paddle/subscriptions_test.exs

key-decisions:
  - "Validate duplicate lifecycle retry keys before Keyword.pop/2 so contradictory caller authority cannot be order-collapsed or dispatched."
  - "Use static retry-only ArgumentError text and a shared private guard across scheduled pause, immediate pause, and resume."

patterns-established:
  - "Mutation option uniqueness belongs at each resource normalization boundary before body construction and request-option merging."

requirements-completed: [SAFE-04]

coverage:
  - id: D1
    description: "Pause, immediate pause, and resume reject both conflicting retry orders before transport, with zero adapter attempts."
    requirement: SAFE-04
    verification:
      - kind: unit
        ref: "test/paddle/subscriptions_test.exs#rejects duplicate retry options before lifecycle dispatch in either order"
        status: pass
    human_judgment: false
  - id: D2
    description: "Existing valid lifecycle body, restrictive retry, and ambiguous one-attempt contracts remain intact."
    requirement: SAFE-04
    verification:
      - kind: integration
        ref: "mix test test/paddle/http_test.exs test/paddle/subscriptions_test.exs test/paddle/seam_test.exs"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-11
status: complete
---

# Phase 32 Plan 15: Lifecycle Retry Uniqueness Summary

**Subscription pause and resume mutations now reject contradictory duplicate retry configuration before normalization or a physical request, while retaining the existing one-attempt reconciliation contract.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-11T03:19:00Z
- **Completed:** 2026-09-11T03:24:13Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added one private, resource-local uniqueness guard before every pause and resume `Keyword.pop/2` boundary.
- Added a public, table-driven regression matrix for both contradictory retry orders across scheduled pause, immediate pause, and resume.
- Preserved legal lifecycle option validation, static request context, one-attempt mutation behavior, and ambiguous-error reconciliation guidance.

## Task Commits

1. **Task 1 RED: Pin duplicate pause retry rejection** — `35ff0f9` (test)
2. **Task 1 GREEN: Reject duplicate pause retry options** — `1def022` (feat)
3. **Task 2 RED: Extend duplicate retry coverage to resume** — `2bd9fa7` (test)
4. **Task 2 GREEN: Reject duplicate resume retry options** — `9e21494` (feat)

## Files Created/Modified

- `lib/paddle/subscriptions.ex` — Rejects repeated `:retry` entries before pause/resume body normalization and dispatch.
- `test/paddle/subscriptions_test.exs` — Covers both conflicting retry orders through every public pause/resume variant with a fail-on-dispatch adapter and attempt counter.

## Decisions Made

- Repeated `:retry` is rejected by one shared private guard before `Keyword.pop/2`, preventing list order from silently selecting mutation policy.
- The validation error uses only static wording and the `retry` key, so caller-provided values cannot appear in the error.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The GSD `tdd-red-evidence` checker parses Node TAP output and cannot classify ExUnit output. Direct ExUnit RED runs failed in the named target test due to an attempted physical request; each matching test-only commit precedes its implementation commit.

## TDD Gate Compliance

- Task 1 RED: `mix test test/paddle/subscriptions_test.exs --trace` failed in the named pause target because a duplicate retry option reached the adapter; the focused resource suite passed after the guard was added.
- Task 2 RED: the same command failed in the named lifecycle target because duplicate resume options reached the adapter; the resource and central/resource/seam suites passed after the shared guard was applied to resume.
- No refactor commit was required; the final implementation is the minimal shared pre-normalization seam.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `test/paddle/subscriptions_test.exs` is already included in the focused Phase 32 compatibility matrix, so this duplicate-order regression participates in future SAFE-04 evidence.

## Self-Check: PASSED

- Both modified implementation/test artifacts and this canonical summary exist on disk.
- All four RED/GREEN task commits are present in Git history.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-11*
