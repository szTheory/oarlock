---
phase: 08-reliability-primitives
plan: "03"
subsystem: http
tags: [elixir, paddle, idempotency, headers, opts, req]

requires:
  - phase: 08-reliability-primitives
    provides: Plan 08-02 normalized Http.request/4 error boundary
provides:
  - "Http.request/4 extracts :idempotency_key before Req-bound option merging"
  - "Customers.create/3, Customers.Addresses.create/4, and Transactions.create/3 accept trailing opts"
  - "Adapter-backed tests prove Idempotency-Key header forwarding, omission, and invalid-key rejection"
affects: [create-posts, accrue-retry-layer, phase-10-subscription-create]

tech-stack:
  added: []
  patterns:
    - "SDK-private opts are popped before method/url merge; remaining Req-known opts pass through"
    - "POST create functions take trailing opts \\ [] and call Keyword.merge([json: body], opts)"

key-files:
  created:
    - .planning/phases/08-reliability-primitives/08-03-SUMMARY.md
  modified:
    - lib/paddle/http.ex
    - lib/paddle/customers.ex
    - lib/paddle/customers/addresses.ex
    - lib/paddle/transactions.ex
    - test/paddle/http_test.exs
    - CHANGELOG.md

key-decisions:
  - "Explicit idempotency_key: nil raises ArgumentError, while an absent option sends no header."
  - "GET, list, patch, and delete functions keep their existing arity for this phase."
  - ":retry remains pass-through because Req already owns that option."

patterns-established:
  - "Use Keyword.has_key?/2 plus Keyword.pop/2 when absence and explicit nil have different meanings."
  - "Resource-level create opts are additive and keep existing callers working through defaults."

requirements-completed: [REL-01]

duration: 10min
completed: 2026-05-30
---

# Phase 08 Plan 03: Idempotency-Key Support Summary

**Every current public `create/*` POST can now forward caller-supplied deterministic idempotency keys as `Idempotency-Key` without leaking SDK-private opts to Req.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-30T11:47:00Z
- **Completed:** 2026-05-30T11:57:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `:idempotency_key` extraction before the `method`/`url` merge in `Paddle.Http.request/4`.
- Added validation for explicit nil, empty, whitespace-only, and non-binary idempotency keys.
- Injected `{"Idempotency-Key", key}` into request headers when a valid key is supplied.
- Added trailing `opts \\ []` to `Paddle.Customers.create/3`, `Paddle.Customers.Addresses.create/4`, and `Paddle.Transactions.create/3`.
- Added six focused idempotency tests plus an end-to-end `Paddle.Customers.create/3` header-forwarding test.
- Documented REL-01 and the v1.2 opts vocabulary in `CHANGELOG.md`.

## Task Commits

1. **Plan 08-03 implementation:** `9113570` (feat)

**Plan metadata:** final docs commit follows this SUMMARY creation.

## Files Created/Modified

- `lib/paddle/http.ex` - `Keyword.pop(opts, :idempotency_key)`, explicit-presence validation, and header injection.
- `lib/paddle/customers.ex` - `create/3` with trailing opts and merged JSON opts.
- `lib/paddle/customers/addresses.ex` - `create/4` with trailing opts and merged JSON opts.
- `lib/paddle/transactions.ex` - `create/3` with trailing opts and merged JSON opts.
- `test/paddle/http_test.exs` - idempotency unit tests and resource integration test.
- `CHANGELOG.md` - REL-01 idempotency entry.

## Decisions Made

- Used `Keyword.has_key?/2` before `Keyword.pop/2` so absent `:idempotency_key` and explicit `idempotency_key: nil` are distinguishable.
- Kept the validation loud through `ArgumentError`, matching the plan's programmer-error direction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Contract correctness] Distinguished absent idempotency_key from explicit nil**
- **Found during:** Task 1 implementation.
- **Issue:** The plan's exact helper sketch used `Keyword.pop/2` and `maybe_add_idempotency_header(opts, nil)`, which cannot distinguish an absent key from `idempotency_key: nil`. That would make the required nil-raises test impossible.
- **Fix:** Added `idempotency_key_present? = Keyword.has_key?(opts, :idempotency_key)` before the pop and used a three-argument helper. Absent option is a no-op; explicit nil raises.
- **Files modified:** `lib/paddle/http.ex`, `test/paddle/http_test.exs`.
- **Verification:** The absent-header test and explicit-nil `ArgumentError` test both pass.
- **Committed in:** `9113570`.

**Total deviations:** 1 auto-fixed contract correction.
**Impact on plan:** Strengthens the implementation to satisfy the documented behavior and tests.

## Issues Encountered

None.

## Verification

- `mix test test/paddle/http_test.exs --color` -> 15 tests, 0 failures.
- Targeted create/seam batch -> 41 tests, 0 failures.
- `mix compile --warnings-as-errors` -> exit 0.
- `mix test --color` -> 125 tests, 0 failures.
- `mix format --check-formatted` -> exit 0.
- Spot checks confirmed the three create functions use trailing opts, three `Keyword.merge([json: body], opts)` call sites exist, invalid key tests are present, and the Accrue-style deterministic key is covered.

## User Setup Required

None.

## Self-Check: PASSED

## Next Phase Readiness

Plan 08-04 can rely on `:retry` passing through the same `Http.request/4` opts path. No extra retry plumbing is needed in resource modules.

---
*Phase: 08-reliability-primitives*
*Plan: 03*
*Completed: 2026-05-30*
