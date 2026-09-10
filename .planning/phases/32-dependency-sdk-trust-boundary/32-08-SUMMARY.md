---
phase: 32-dependency-sdk-trust-boundary
plan: "08"
subsystem: sdk-observability-trust-boundary
tags: [elixir, req, telemetry, retries, redaction, concurrency]

requires:
  - phase: 32-dependency-sdk-trust-boundary
    provides: Central request-local retry and static context contracts from Plan 04
  - phase: 32-dependency-sdk-trust-boundary
    provides: Resource-owned literal operation/route labels from Plans 05, 06, and 07
provides:
  - One paired start and terminal telemetry event for every physical request attempt
  - Exact low-cardinality measurement and metadata projections with no transport objects
  - Recursive canary, retry-topology, concurrency, and subscriber-cleanup proofs
affects: [32-10-public-contract, sdk-observability, retry-diagnostics, subscriber-safety]

actuals:
  tokens: 4959
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns: [request-private attempt state, pre-retry terminal instrumentation, exact telemetry allowlist, recursive absence proof]

key-files:
  created: []
  modified:
    - lib/paddle/http/telemetry.ex
    - test/paddle/http/telemetry_test.exs

key-decisions:
  - "Prepend response and error telemetry steps ahead of Req retry while retaining an appended request-start step, so every recursive physical attempt emits one complete pair."
  - "Normalize exception outcomes to transport_error, http_error, or exception and response results to ok/error without exposing modules, messages, reasons, responses, or request state."
  - "Use request-private attempt/start state plus process-owned test subscribers so concurrent requests retain independent sequences and deterministic handler cleanup."

patterns-established:
  - "Telemetry derives only method, sanitized host, attempt, and resource-owned operation/route context; terminal events add only status/result or normalized error_class/result."
  - "Safety tests walk measurements and metadata recursively, fail closed on forbidden transport structs, and reject unique secret-bearing canaries at any depth."

requirements-completed: [SAFE-02]

coverage:
  - id: D1
    description: "Every success, provider failure, transport exception, two-attempt success, and four-attempt terminal read emits one exact start-to-terminal pair per physical attempt."
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "mix test test/paddle/http/telemetry_test.exs --trace"
        status: pass
    human_judgment: false
  - id: D2
    description: "Telemetry measurements and metadata recursively exclude request, response, exception, credential, URL/query, ID, header, body, customer, and raw_data content under retries and concurrency."
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "test/paddle/http/telemetry_test.exs#all outcomes recursively exclude transport objects and secret-bearing canaries"
        status: pass
      - kind: unit
        ref: "test/paddle/http/telemetry_test.exs#parallel subscribers receive independent pairs and detach deterministically"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-10
status: complete
---

# Phase 32 Plan 08: Attempt-Scoped Telemetry Safety Summary

**Paddle telemetry now emits one exact, low-cardinality start/terminal pair per physical Req attempt while recursively excluding all secret-bearing transport state.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-09-10T22:10:07Z
- **Completed:** 2026-09-10T22:17:31Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Preserved the three public Paddle request event names while replacing full request/response/exception payloads with exact per-outcome allowlists.
- Moved response/error telemetry ahead of Req retry consumption and stored attempt/start timing in request-private state, producing ordered pairs for two- and four-attempt reads.
- Added recursive canary and forbidden-struct proofs across success and exception outcomes plus independent parallel subscriber sequences and deterministic detachment.
- Documented exact event measurements, metadata keys, native monotonic duration units, result semantics, normalized error classes, and forbidden payloads.

## Task Commits

1. **Task 1 RED: Specify attempt-scoped telemetry contract** — `a158017` (test)
2. **Task 1 GREEN: Emit safe telemetry per attempt** — `7a4ba68` (feat)
3. **Task 2 RED: Prove telemetry isolation and absence** — `373a066` (test)
4. **Task 2 GREEN: Complete telemetry safety contract** — `599682a` (feat)

## Files Created/Modified

- `lib/paddle/http/telemetry.ex` — Owns attempt-local timing, pre-retry terminal hooks, normalized result/error values, and strict subscriber projections.
- `test/paddle/http/telemetry_test.exs` — Pins exact keys, paired retry attempts, recursive absence, concurrent subscriber ownership, cleanup, and module documentation.

## Decisions Made

- Kept start after Req request preparation so the emitted host is the resolved sanitized host, while prepending both terminal steps ahead of Req's built-in retry step.
- Used one private `%{attempt, started_at}` value carried by the Req request across recursive retries; no telemetry correlation field or transport container is exposed.
- Classified exceptions into three fixed atoms and HTTP responses into fixed `:ok`/`:error` results, preventing exception types, messages, reasons, or provider payloads from increasing cardinality.

## Automated Evidence

- `mix format --check-formatted` — exit 0.
- `mix test test/paddle/http/telemetry_test.exs --trace` — 7 tests, 0 failures.
- Full runtime corpus excluding the explicitly Plan 32-10-owned `test/paddle/seam_test.exs` — 251 tests, 0 failures.
- Full `mix test` — 257 tests ran with three failures in `test/paddle/seam_test.exs`, all explicitly owned by pending Plan 32-10: stale transaction idempotency usage, stale `Paddle.Error` arity inventory, and the sealed-module list that must admit Telemetry's intentional D-18 documentation.

## TDD Gate Compliance

- Task 1 RED commit `a158017` failed 4/4 tests on unsafe payload keys, post-retry terminal ordering, and missing physical-attempt pairs; GREEN commit `7a4ba68` passed 4/4.
- Task 2 RED commit `373a066` passed its recursive/concurrency probes but failed the mechanical normalized-value documentation assertion; GREEN commit `599682a` passed the complete 7/7 telemetry suite.
- Each task has a test commit followed by a feature commit, and the final focused and runtime regression gates were run after the last production change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reconciled visible state after dependency-ordered execution**

- **Found during:** Plan close-out
- **Issue:** `state.advance-plan` moved the visible pointer to Plan 11 and `state.update-progress` skipped the unscoped in-progress phase, although disk truth shows 10/11 Phase 32 plans complete and Plan 10 as the sole remainder.
- **Fix:** Aligned the current plan, latest activity, completed-plan count, progress percentage, and operator next step with summaries and ROADMAP.
- **Files modified:** `.planning/STATE.md`
- **Committed in:** Plan metadata commit

---

**Total deviations:** 1 auto-fixed blocking metadata reconciliation.
**Impact on plan:** No production scope changed; visible planning state now agrees with the authoritative summary count and dependency order. The scheduled Plan 32-10 public-contract migration remains recorded in `deferred-items.md` rather than modified early.

## Known Stubs

None. No TODOs, FIXMEs, skipped tests, placeholder behavior, hardcoded empty UI values, or unwired data sources were introduced.

## Threat Flags

None. The changed code closes the planned Req transport-to-subscriber disclosure/cardinality boundary and introduces no new endpoint, auth path, file access pattern, or schema trust boundary.

## Issues Encountered

- The broad suite retains three scheduled Plan 32-10 seam failures. Plan 32-10 explicitly owns `test/paddle/seam_test.exs`, depends on Plan 32-08, and defines the telemetry schema/public-inventory migration, so those assertions were left as its RED gate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 32-10 can now mechanically align the telemetry guide and compiled public inventory with the exact runtime schema proven here.
- SAFE-02 has focused subscriber-boundary proof across all terminal outcomes, bounded retries, recursive sensitive-value absence, and concurrency.

## Self-Check: PASSED

- Both implementation/test artifacts and this summary exist on disk.
- Task commits `a158017`, `7a4ba68`, `373a066`, and `599682a` are present in Git history.
- Focused telemetry tests, formatting, and the 251-test runtime corpus outside Plan 32-10's explicit contract-test ownership passed after the final production change.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-10*
