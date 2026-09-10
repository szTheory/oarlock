---
phase: 32-dependency-sdk-trust-boundary
plan: "04"
subsystem: sdk-transport-trust-boundary
tags: [elixir, req, retries, ambiguity, inspect-redaction]

requires:
  - phase: 32-dependency-sdk-trust-boundary
    provides: Req 0.7.4 request adapter compatibility and validated explicit clients from Plans 01, 02, 11, and 03
provides:
  - Request-local GET/HEAD retry policy with an exact four-attempt ceiling and transient allowlist
  - One-attempt mutation policy with pre-dispatch rejection of replay-enabling overrides and unsupported idempotency keys
  - Additive Paddle.Error ambiguity, reconciliation, request-correlation, and raw-data inspection contracts
affects: [32-05-resource-context, 32-06-resource-context, 32-07-resource-context, 32-08-telemetry, 32-10-public-contract]

actuals:
  tokens: 10855
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns: [request-local Req retry callback, static request context, consumer-owned reconciliation, total Inspect projection]

key-files:
  created: []
  modified:
    - lib/paddle/client.ex
    - lib/paddle/http.ex
    - lib/paddle/internal/pagination.ex
    - lib/paddle/error.ex
    - test/paddle/client_test.exs
    - test/paddle/http_test.exs
    - test/paddle/error_test.exs

key-decisions:
  - "Own retry eligibility in Paddle.Http with a request-local Req callback: only GET/HEAD retry the exact transient allowlist, with three retries/four attempts and a 60000 ms cap only for 429 Retry-After."
  - "Treat every mutation transport failure and terminal mutation HTTP 408/5xx response as ambiguous and non-retryable while preserving the established {:error, %Paddle.Error{}} seam."
  - "Expose only static operation, optional resource ID, provider request ID, and the fixed lookup/webhook/provider-dashboard reconciliation actions; never replay or auto-reconcile mutations."

patterns-established:
  - "Paddle.Http removes static context before Req dispatch and stores it in immutable request-private state, keeping operation/route labels separate from dynamic cursor URLs."
  - "Paddle.Error body meta.request_id takes precedence over x-request-id, and Inspect redacts raw_data wholesale without mutating stored evidence."

requirements-completed: [SAFE-03, SAFE-04]

coverage:
  - id: D1
    description: "Eligible GET/HEAD failures retry only the exact status/transport allowlist and stop after four attempts; mutations and retry-disabled reads execute once."
    requirement: SAFE-04
    verification:
      - kind: unit
        ref: "mix test test/paddle/client_test.exs test/paddle/http_test.exs --trace"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mutation ambiguity remains a non-retryable Paddle.Error with independent operation/resource context and consumer-owned reconciliation actions."
    requirement: SAFE-04
    verification:
      - kind: unit
        ref: "mix test test/paddle/http_test.exs test/paddle/error_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Paddle.Error inspection redacts arbitrary raw_data canaries while preserving stored error evidence and body-first provider request correlation."
    requirement: SAFE-03
    verification:
      - kind: unit
        ref: "test/paddle/error_test.exs#context-aware constructors and Inspect"
        status: pass
      - kind: other
        ref: "mix dialyzer"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-09-10
status: complete
---

# Phase 32 Plan 04: Safe Retry and Mutation Ambiguity Summary

**Safe reads now use an exact bounded request-local retry policy, while mutations execute once and surface uncertain provider state through secret-safe, consumer-reconcilable `%Paddle.Error{}` values.**

## Performance

- **Duration:** 9 minutes
- **Started:** 2026-09-10T21:12:32Z
- **Completed:** 2026-09-10T21:21:21Z
- **Tasks:** 2
- **Files modified:** 7
- **Focused retry gate:** 30 tests, 0 failures
- **Focused ambiguity gate:** 32 tests, 0 failures
- **Dialyzer:** 0 errors, 0 skipped, 0 unnecessary skips

## Accomplishments

- Removed the client-wide unsafe `retry: :transient` policy and made `Paddle.Http` decide retry eligibility for each immutable request.
- Restricted retries to GET/HEAD plus HTTP 408/429/500/502/503/504 or transport timeout/econnrefused/closed, with exactly three retries and a 60000 ms 429-only `Retry-After` cap.
- Rejected mutation `retry: true`, duplicate/invalid retry controls, and unsupported `idempotency_key` before adapter dispatch.
- Added context-aware pagination and request-private static operation/route/resource context without mixing it with dynamic cursor dispatch URLs.
- Extended `Paddle.Error` with additive ambiguity, operation, resource, and reconciliation fields while preserving the public outer tuple and existing constructor delegates.
- Preferred provider body `meta.request_id` over the response header and replaced arbitrary `raw_data` rendering with the stable `[REDACTED]` projection.
- Proved repeat and parallel mutation calls remain one-attempt, deterministic, and context-local with no automatic replay or provider-state repair.

## Task Commits

1. **Task 1 RED: Safe-read retry and concurrency matrix** — `7b55a28` (test)
2. **Task 1 GREEN: Central bounded retry policy** — `458d0fb` (feat)
3. **Task 2 RED: Mutation ambiguity and inspection contract** — `1547c9e` (test)
4. **Task 2 GREEN: Context-aware Paddle.Error normalization** — `8503e7a` (feat)

## Files Created/Modified

- `lib/paddle/client.ex` — Removes global transient retries and documents central safe-read ownership and unsupported idempotency.
- `lib/paddle/http.ex` — Validates controls before dispatch, owns the exact retry callback/ceiling, stores static request context, and normalizes terminal outcomes contextually.
- `lib/paddle/internal/pagination.ex` — Adds `next_page/4` for static context while retaining the temporary `/3` compatibility delegate.
- `lib/paddle/error.ex` — Adds ambiguity/reconciliation fields, context-aware constructors, body-first request IDs, and total raw-data redaction.
- `test/paddle/client_test.exs` — Confirms constructed Req state has retries disabled until the central request policy is applied.
- `test/paddle/http_test.exs` — Covers method/status/transport/override matrices, bounded delay decisions, repeated mutation calls, and parallel isolation.
- `test/paddle/error_test.exs` — Covers constructor precedence/defaults, allowed reconciliation atoms, and raw-data inspection canaries.

## Decisions Made

- A read-side 429 callback returns a bounded explicit delay only when `Retry-After` is present; every other eligible class uses Req's configured/default delay controller, so 503 cannot adopt provider delay headers.
- Mutation ambiguity is determined from the immutable request method plus a transport failure or terminal 408/5xx response. It never changes the `{:error, %Paddle.Error{}}` family and always forces `retryable?: false`.
- Context values are consumed and type-validated before Req dispatch. Only operation/resource are copied to the public error; route remains request-private for telemetry and never becomes reconciliation guidance.

## Verification

- `mix test test/paddle/client_test.exs test/paddle/http_test.exs --trace` — 30 tests, 0 failures.
- `mix test test/paddle/http_test.exs test/paddle/error_test.exs` — 32 tests, 0 failures.
- `mix dialyzer` — 0 errors, 0 skipped, 0 unnecessary skips.
- `mix format --check-formatted` — exit 0.
- `git diff --check` — exit 0.
- `mix test` — executed as a forward-integration probe; 236 tests ran with 13 expected transition failures owned by Plans 32-05 through 32-07 and 32-10 (resource fixtures still assert the removed idempotency/old mutation-retry contract, later-page fixtures do not yet opt out of retries, and the seam inventory has not yet admitted the planned public docs/constructor arities).

## TDD Gate Compliance

- Task 1 RED commit `7b55a28` failed five policy assertions against the prior global transient behavior; GREEN commit `458d0fb` passed the complete client/HTTP gate.
- Task 2 RED commit `1547c9e` failed at compilation because the additive error fields and context-aware constructors did not exist; GREEN commit `8503e7a` passed all 32 focused HTTP/error tests.
- Both task histories contain an explicit `test` commit followed by a `feat` commit, and all refactoring occurred after the RED evidence was captured.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reconciled visible state after SDK handlers advanced authoritative counters**

- **Found during:** Plan close-out
- **Issue:** `state.update-progress` intentionally skipped the unscoped in-progress phase, leaving the visible progress, latest activity, completed-plan prose, and operator next step stale after authoritative counters advanced.
- **Fix:** Aligned the human-readable state sections to 14/20 completed plans, 70% progress, Plan 04 as the latest activity, and Plan 05 as the next dependency-ordered action.
- **Files modified:** `.planning/STATE.md`
- **Commit:** Plan metadata commit

---

**Total deviations:** 1 auto-fixed blocking metadata reconciliation.
**Impact on plan:** No production scope changed; visible planning state now agrees with authoritative counters and realized plan order.

## Known Stubs

None. Empty collections in tests are concrete request/provider fixtures, and empty-string comparisons in implementation are validation predicates; no TODOs, FIXMEs, skipped tests, placeholder values, or unwired data sources were introduced.

## Issues Encountered

- Context7 was unavailable through MCP and the local `ctx7` CLI was not installed. The implementation used the selected Req 0.7.4 dependency source as the version-authoritative retry callback reference.
- The broad suite is intentionally transitional after the central contract changed. Its 13 failures map directly to the resource migrations in Plans 32-05/06/07 and compiled public-contract migration in Plan 32-10; the exact Plan 32-04 gates and Dialyzer are green.

## User Setup Required

None.

## Next Phase Readiness

- Plans 32-05 through 32-07 can now attach literal operation/route/resource context, remove resource option types for idempotency, and update mutation/read fixtures against one central policy.
- Plan 32-08 can consume request-private operation/route context for allowlisted telemetry without reading dynamic cursor URLs.
- Plan 32-10 must update seam documentation and compiled public inventory assertions after the resource migrations make the broad suite coherent again.

## Self-Check: PASSED

- All seven realized implementation/test artifacts and this summary exist on disk.
- Task commits `7b55a28`, `458d0fb`, `1547c9e`, and `8503e7a` are present in Git history.
- Both focused plan gates, Dialyzer, formatting, and diff checks passed after the final implementation change.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-10*
