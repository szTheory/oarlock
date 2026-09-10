---
phase: 32-dependency-sdk-trust-boundary
plan: "01"
subsystem: dependency-trust-boundary
tags: [elixir, req, hex-audit, adapter, dependency-lock]

requires:
  - phase: 31-repository-planning-truth
    provides: Repository-bounded evidence and non-inference rules
provides:
  - Req 0.7.4 root dependency floor and generated lock resolution
  - Req 0.7 module-adapter request tracer through Paddle.Http
  - Coherent demo Req 0.7.4 resolution and clean authoritative root Hex audit
affects: [32-02-compatibility-matrix, sdk-http-transport, demo-consumer, dependency-audit]

actuals:
  tokens: 5772
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns: [module-backed Req adapter, request-private test callback, generated Mix lock provenance]

key-files:
  created: []
  modified:
    - mix.exs
    - mix.lock
    - demo/mix.lock
    - test/paddle/http_test.exs

key-decisions:
  - "Use a Req 0.7 module adapter whose per-test callback is stored in request-private state, preserving deterministic async HTTP tests without deprecated function adapters."
  - "Keep compatibility, lock resolution, and the online Hex audit as separate evidence; none substitutes for hosted, publication, or release authority."
  - "Refresh only the stale root Bandit lock entry to patched 1.12.5 when the required audit exposed active advisories already permitted by the existing manifest constraint."

patterns-established:
  - "Req adapter fixtures implement run/1 and retrieve dynamic test behavior from namespaced Req.Request private state."
  - "Dependency acceptance records exact resolved versions, executable compatibility, and online advisory status independently."

requirements-completed: [SAFE-01]

coverage:
  - id: D1
    description: "The root and demo locks both resolve Req 0.7.4 from the root ~> 0.7.4 constraint."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "mix deps.get && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/paddle/http_test.exs"
        status: pass
      - kind: integration
        ref: "(cd demo && mix deps.get && mix precommit)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A supported Req module adapter returns a provider-shaped 2xx body through Paddle.Http.request/4 without changing SDK behavior."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "test/paddle/http_test.exs#request/4 returns ok tuples for 2xx responses"
        status: pass
    human_judgment: false
  - id: D3
    description: "The authoritative online root Hex audit reports no retired or advisory packages."
    requirement: SAFE-01
    verification:
      - kind: other
        ref: "mix hex.audit"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-10
status: complete
---

# Phase 32 Plan 01: Req 0.7 Dependency Tracer Summary

**Req 0.7.4 now resolves in both root and demo consumers, completes a real module-adapter request through `Paddle.Http`, and passes the authoritative root Hex audit without changing SDK behavior.**

## Performance

- **Duration:** 5 minutes
- **Started:** 2026-09-10T20:29:31Z
- **Completed:** 2026-09-10T20:34:00Z
- **Tasks:** 2
- **Files modified:** 4 implementation artifacts
- **Measured focused gate:** 2.45 seconds on the final warm run; 20 tests, 0 failures
- **Measured demo/audit gate:** 4.00 seconds on the final warm run; 25 tests, 0 failures; audit clean

## Accomplishments

- Raised the root Req constraint from `~> 0.5.17` to `~> 0.7.4` and generated a root lock resolving Req 0.7.4.
- Replaced deprecated function adapters in the focused HTTP fixture with a Req 0.7-supported module adapter while retaining per-test deterministic callbacks.
- Proved a provider-shaped 2xx response traverses the existing `Paddle.Http.request/4` public result path and kept all existing error-normalization coverage green.
- Regenerated the demo lock through its Paddle path dependency so it independently resolves Req 0.7.4.
- Obtained an online root `mix hex.audit` verdict of `No retired or security advisory packages found`.
- Preserved the user's existing `.tool-versions` modification and made no SDK retry, telemetry, inspection, constructor-validation, CI, publication, or release changes.

## Task Commits

1. **Task 1 RED: Req module-adapter compatibility tracer** — `5ea4dbc` (test)
2. **Task 1 GREEN: Req 0.7.4 manifest and generated root lock** — `fc9a001` (chore)
3. **Task 2: demo resolution and authoritative audit closure** — `ea9bf25` (chore)

## Files Created/Modified

- `mix.exs` — Sets the Req dependency floor to `~> 0.7.4` without changing dependency ordering or flags.
- `mix.lock` — Resolves Req 0.7.4 and its compatible transitive dependencies; refreshes Bandit to patched 1.12.5 for the required clean audit.
- `demo/mix.lock` — Resolves Req 0.7.4 transitively through the local Paddle path dependency.
- `test/paddle/http_test.exs` — Routes deterministic HTTP callbacks through a supported adapter module and request-private state.

## Decisions Made

- The adapter fixture uses `Paddle.HttpTest.Adapter.run/1`; dynamic closures remain isolated per request under the namespaced `:paddle_test_adapter` private key.
- Root compatibility, demo resolution, and online audit output are recorded independently. This local evidence does not establish hosted exact-SHA, publication, or release authority.
- The audit remediation updated only Bandit's generated root lock entry because the existing `~> 1.0` constraint already admitted the patched release.

## Verification

- Root tracer: `mix deps.get && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/paddle/http_test.exs` — Req 0.7.4, 20 tests, 0 failures, exit 0.
- Tracer feedback gate: the same root command was rerun before Task 2 and passed 20/20.
- Demo and advisory gate: `(cd demo && mix deps.get && mix precommit) && mix hex.audit` — 25 tests, 0 failures; `No retired or security advisory packages found`; exit 0.
- Generated locks: `mix.lock` and `demo/mix.lock` both contain Req 0.7.4 with the same package and registry checksums.
- Scope proof: `git diff --name-status aef4c2f..HEAD` contains only `mix.exs`, `mix.lock`, `demo/mix.lock`, and `test/paddle/http_test.exs`.
- User-state proof: `.tool-versions` retains only its pre-existing uncommitted Node.js line and was not included in any plan commit.

## TDD Gate Compliance

- The focused request path was green on Req 0.5.17 before fixture migration: 20 tests, 0 failures.
- RED commit `5ea4dbc` then failed the focused public request test with `FunctionClauseError` because Req 0.5.17 did not accept a module adapter.
- GREEN commit `fc9a001` resolved Req 0.7.4 and passed warnings-as-errors compilation plus all 20 focused HTTP tests.
- The tracer verification was rerun end-to-end before expanding to Task 2.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Refreshed the stale vulnerable Bandit lock entry**

- **Found during:** Task 2 authoritative online audit
- **Issue:** Root `mix.lock` retained Bandit 1.12.0, and `mix hex.audit` exited 1 for three active Bandit advisories even though patched Bandit 1.12.5 already satisfied the unchanged `~> 1.0` manifest constraint.
- **Fix:** Ran the targeted `mix deps.update bandit`, changing only the generated root lock entry to Bandit 1.12.5. No manifest constraint, application behavior, workflow, publication, or release surface changed.
- **Files modified:** `mix.lock`
- **Verification:** The exact Task 2 gate exits 0 and root `mix hex.audit` reports no retired or advisory packages.
- **Commit:** `ea9bf25`

**2. [Rule 3 - Blocking] Reconciled state handler output**

- **Found during:** Plan close-out
- **Issue:** `state.update-progress` skipped the visible progress field, leaving 100% beside the authoritative 10/20 completed-plan count, and `state.add-decision` duplicated the Phase 32 prefix supplied in each summary.
- **Fix:** Aligned visible progress to 50%, updated the completed-plan prose count to 10, removed duplicate decision prefixes, and advanced the operator next step to Plan 32-02.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE frontmatter and prose now agree on 10/20 completed plans, Plan 2 of 11 is current, and each Phase 32 decision has one prefix.
- **Commit:** Plan metadata commit

---

**Total deviations:** 2 auto-fixed issues (1 Rule 2 security issue, 1 Rule 3 close-out issue).
**Impact on plan:** The narrow lock refresh supplies the clean audit required by SAFE-01 without broad dependency cleanup or SDK behavior changes, and planning metadata reports the realized completion state consistently.

## Known Stubs

None. The changed files contain no placeholder behavior, skipped tests, or unwired mock data.

## Issues Encountered

- Hex warned that the local authentication session had expired, but all public dependency resolution and audit operations completed successfully; no authentication gate was required.
- Demo dependency resolution reports advisories in dependencies owned directly by the demo application. The plan's authoritative `mix hex.audit` runs from the root SDK lock and is clean; no demo dependency constraints were broadened in this Req-only slice.

## User Setup Required

None. Registry access was available and all required dependency and audit commands completed.

## Next Phase Readiness

- Plan 32-02 can expand from the proven Req 0.7.4 module-adapter tracer into the complete compatibility matrix.
- No retry, telemetry, inspection, constructor-validation, hosted-CI, publication, or release authority is claimed by this plan.

## Self-Check: PASSED

- All four modified implementation artifacts and this summary exist on disk.
- Task commits `5ea4dbc`, `fc9a001`, and `ea9bf25` are present in Git history.
- The manifest and both generated locks resolve the required Req 0.7.4 line.
- Final root tracer, demo precommit, and online root audit verification all passed after the last implementation change.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-10*
