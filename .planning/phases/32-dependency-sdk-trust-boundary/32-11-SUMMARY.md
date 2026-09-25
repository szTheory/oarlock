---
phase: 32-dependency-sdk-trust-boundary
plan: "11"
subsystem: dependency-trust-boundary
tags: [elixir, req, compatibility, shell, downstream, hex-audit]

requires:
  - phase: 32-dependency-sdk-trust-boundary
    provides: Req 0.7.4 dependency floor and module-adapter tracer from Plan 01
  - phase: 32-dependency-sdk-trust-boundary
    provides: Eight warning-free resource adapter fixtures from Plan 02
provides:
  - Req 0.7 module adapters for the remaining subscription, transaction, seam, and telemetry fixtures
  - Named 13-row SAFE-01 compatibility matrix with atomic no-drift acceptance receipt
  - Failure and interruption self-test proving partial runs cannot publish acceptance
affects: [sdk-http-safety, telemetry, documentation-contract, downstream-accrue, release-trust]

actuals:
  tokens: 3760
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: [module-backed Req test adapters, named fail-fast matrix rows, atomic acceptance receipt, tracked-diff fingerprint]

key-files:
  created:
    - bin/phase32_compatibility.sh
  modified:
    - test/paddle/subscriptions_test.exs
    - test/paddle/transactions_test.exs
    - test/paddle/seam_test.exs
    - test/paddle/http/telemetry_test.exs

key-decisions:
  - "Use the established request-private module-adapter pattern independently in each remaining compatibility-sensitive fixture, preserving every existing assertion."
  - "Treat acceptance as a 13-row fail-fast local matrix whose receipt is atomically renamed only after every row and tracked-diff equality pass."
  - "Propagate the root's selected ASDF Elixir and Erlang versions into isolated package and sibling Accrue Mix projects without modifying either consumer."

patterns-established:
  - "Compatibility rows execute directly under set -euo pipefail, record names and durations, and never infer success from log text."
  - "A matrix acceptance artifact is published only from a same-directory temporary file after total success and repository no-drift verification."

requirements-completed: [SAFE-01]

coverage:
  - id: D1
    description: "All remaining compatibility-sensitive fixtures use Req 0.7 module adapters without changing subscription, transaction, seam, or telemetry behavior."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/paddle/subscriptions_test.exs test/paddle/transactions_test.exs test/paddle/seam_test.exs test/paddle/http/telemetry_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "One named fail-fast matrix proves root, focused, MockServer, Dialyzer, docs, package, demo, Accrue, and online-audit compatibility without tracked-file drift."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "ACCRUE_CHECKOUT=../accrue bin/phase32_compatibility.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Nonzero and interrupted partial runs cannot publish acceptance, while a complete run atomically publishes exactly one receipt."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "bin/phase32_compatibility.sh --self-test"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-10
status: complete
---

# Phase 32 Plan 11: Req Compatibility Matrix Summary

**Req 0.7 compatibility now spans every tracked adapter fixture and a 13-row fail-fast matrix that publishes acceptance only after complete, non-mutating local success.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-09-10T20:52:57Z
- **Completed:** 2026-09-10T20:59:53Z
- **Tasks:** 2
- **Files modified:** 5
- **Final matrix:** 13 named rows in 23 seconds on the final warm run

## Accomplishments

- Migrated subscription, transaction, public seam, and telemetry fixtures from deprecated Req function adapters to supported module adapters while retaining 74 existing behavioral tests.
- Added one repository-relative, fail-fast compatibility command spanning the 224-test root suite, every focused adapter family, telemetry, MockServer flows, Dialyzer, docs, an isolated package consumer without optional Plug/Bandit, demo precommit, downstream Accrue, and the live Hex audit.
- Added an isolated self-test proving failed and killed partial runs leave no receipt and complete runs create exactly one.
- Fingerprinted the root tracked diff before and after all rows and published the final receipt by same-directory atomic rename only when the fingerprints matched.

## Task Commits

1. **Task 1: Migrate the remaining integration and contract fixtures** — `11f1107` (test)
2. **Task 2: Codify the full compatibility matrix and atomic acceptance contract** — `394274b` (chore)

## Files Created/Modified

- `test/paddle/subscriptions_test.exs` — Routes deterministic standard and retry callbacks through a Req module adapter.
- `test/paddle/transactions_test.exs` — Routes transaction fixtures through the supported request-private adapter contract.
- `test/paddle/seam_test.exs` — Preserves the full Accrue/public contract flow under a Req module adapter.
- `test/paddle/http/telemetry_test.exs` — Preserves start/stop/exception event assertions under a Req module adapter.
- `bin/phase32_compatibility.sh` — Runs the named compatibility matrix, no-drift gate, atomic receipt publisher, and interruption self-test.

## Decisions Made

- Each fixture owns its nested adapter module rather than adding a new shared test-support abstraction outside the plan boundary.
- Root and focused Elixir commands use both compiler and test-loader `--warnings-as-errors` flags and propagate their exit status directly; the runner does not inspect or reinterpret logs.
- The matrix receipt records only the commit, timestamp, tracked-diff digest, row names, and durations. It remains local D-03/D-04 evidence and claims no hosted, publication, or release authority.
- Isolated package and Accrue commands inherit the repository-selected ASDF BEAM versions because neither temporary/sibling Mix project is beneath the root `.tool-versions` discovery path.

## Verification

- Fixture gate: 74 tests, 0 failures, with no Req function-adapter deprecation output.
- Root matrix row: 224 tests, 0 failures.
- Focused rows: 20 HTTP tests, 39 customer/adjustment tests, 26 catalog/notification tests, 71 subscription/transaction/seam tests, and 3 telemetry tests; all passed.
- MockServer/subscription flow row: 12 tests, 0 failures.
- Dialyzer: 0 errors, 0 skipped, 0 unnecessary skips.
- Demo precommit: 25 tests, 0 failures.
- Downstream Accrue seam: 3 tests, 0 failures from `../accrue/accrue`.
- Online audit: `No retired or security advisory packages found`.
- Final receipt names commit `394274b`, records 13 passed rows, and records the empty tracked-diff SHA-256 before atomic publication.

## TDD Gate Compliance

- Before migration, the exact 74-test gate preserved all behavior but emitted Req 0.7's function-adapter deprecation repeatedly, establishing the plan-defined compatibility RED condition.
- After migrating adapter construction only, the same command passed 74/74 without the deprecation warning.
- No production behavior or assertion meaning changed; this task's RED/GREEN seam was the compatibility fixture contract itself.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Propagated the selected BEAM toolchain into isolated Mix projects**

- **Found during:** Task 2 package-smoke and downstream Accrue rows
- **Issue:** ASDF refused to invoke `mix` after each row changed into a temporary or sibling project outside the root `.tool-versions` discovery tree.
- **Fix:** Read the already-selected Elixir and Erlang versions from the root `.tool-versions` and passed them as `ASDF_ELIXIR_VERSION` and `ASDF_ERLANG_VERSION` only to those two subprocesses.
- **Files modified:** `bin/phase32_compatibility.sh`
- **Verification:** The isolated package consumer compiled successfully, the owning Accrue project passed 3/3 focused tests, and the complete 13-row matrix exited 0.
- **Committed in:** `394274b`

**2. [Rule 3 - Blocking] Reconciled state handler output**

- **Found during:** Plan close-out
- **Issue:** `state.update-progress` skipped the visible progress field, while state prose retained the Plan 02 activity, 11-plan completion count, unresolved Req 0.5 concern, and Plan 11 as the next action after authoritative counters and summaries advanced.
- **Fix:** Aligned visible progress and prose to 12/20 completed plans, recorded Plan 11 as the latest activity, replaced the resolved Req concern with the remaining hosted-proof boundary, and pointed execution to dependency-ordered Plan 32-03.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE frontmatter and prose agree on 12 completed plans and 60% progress, ROADMAP records 3/11 Phase 32 plans complete, and the next runnable dependency is Plan 32-03.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 2 auto-fixed blocking issues.
**Impact on plan:** The compatibility scope is unchanged; the runner executes the requested isolated consumers under the same tracked toolchain without modifying either consumer checkout, and planning metadata reflects the realized completion state.

## Known Stubs

None. The five realized files contain no placeholder behavior, skipped tests, or unwired data.

## Issues Encountered

- Hex reported that the cached authentication session had expired, then continued anonymously. Public package resolution and `mix hex.audit` both completed successfully, so no authentication gate was required.
- Existing retry tests intentionally emit runtime Logger warning events while exercising 429/503 behavior. Compiler and test-loader warnings remain promoted to errors; the Req adapter deprecation is absent.

## User Setup Required

None. The required Accrue checkout, PostgreSQL test service, and Hex registry access were available.

## Next Phase Readiness

- SAFE-01 compatibility and advisory evidence is complete for local execution, so later Phase 32 plans can change retry, telemetry, inspection, and public-contract behavior against this baseline.
- This receipt remains local evidence only; hosted exact-SHA CI and publication/release authority remain owned by later phases.

## Self-Check: PASSED

- All five realized implementation artifacts and this summary exist on disk.
- Task commits `11f1107` and `394274b` are present in Git history.
- The final acceptance receipt names commit `394274b` and records all 13 rows.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-10*
