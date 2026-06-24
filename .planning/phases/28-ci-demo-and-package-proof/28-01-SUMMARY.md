---
phase: 28-ci-demo-and-package-proof
plan: 1
subsystem: payments
tags: [elixir, mix, paddle, optional-deps, plug, bandit, docs]

requires:
  - phase: 27-public-contract-documentation-truth
    provides: "Proof ladder language and public contract honesty for local MockServer versus live Paddle provider-state verification."
provides:
  - "Compile-safe optional dependency boundary for Paddle.MockServer."
  - "Positive MockServer route proof with plug and bandit available."
  - "Public docs explaining that plug and bandit are only required for the MockServer development/test fixture."
affects: [ci-demo-and-package-proof, package-smoke, optional-dependency-proof, public-docs]

tech-stack:
  added: []
  patterns:
    - "Optional Plug/Bandit code is compiled only when Code.ensure_loaded?/1 confirms dependencies are available."
    - "Paddle.MockServer.start_link/1 returns a clear optional-dependency error tuple when fixture dependencies are absent."

key-files:
  created:
    - .planning/phases/28-ci-demo-and-package-proof/28-01-SUMMARY.md
  modified:
    - lib/paddle/mock_server.ex
    - test/paddle/mock_server_test.exs
    - README.md
    - demo/README.md

key-decisions:
  - "Kept Paddle.MockServer as the public fixture module and moved Plug.Router routes into Paddle.MockServer.Router behind optional dependency checks."
  - "Used runtime apply/3 for Bandit.start_link/1 so downstream consumers without Bandit do not compile-expand the optional server path."
  - "Documented MockServer as a deterministic local fixture, not Paddle provider-state verification."

patterns-established:
  - "Optional fixture boundary: public wrapper module compiles always; dependency-backed router submodule compiles only when optional dependencies are present."
  - "Docs distinguish root SDK requirements from optional offline fixture requirements."

requirements-completed: [PROOF-04]

duration: 2min
completed: 2026-06-24
status: complete
---

# Phase 28 Plan 1: MockServer Optional Dependency Boundary Summary

**Paddle.MockServer now preserves offline HTTP fixture behavior with Plug/Bandit present while keeping the core SDK compile-safe for consumers that do not install those optional dependencies.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-24T16:44:40Z
- **Completed:** 2026-06-24T16:46:58Z
- **Tasks:** 2
- **Files modified:** 4 source/doc files plus this summary

## Accomplishments

- Moved the Plug router implementation into `Paddle.MockServer.Router`, compiled only when `Plug.Router`, `Plug.Parsers`, and `Bandit` are available.
- Preserved MockServer customer, transaction, portal-session, subscription, and fallback route behavior with the root test dependencies installed.
- Added focused coverage that asserts the optional dependency boundary remains gated.
- Updated root and demo docs to state that `Paddle.MockServer` requires optional `plug` and `bandit`, while core SDK modules do not require Phoenix, Ecto, Plug, or Bandit.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make Paddle.MockServer compile-safe without optional deps** - `5c2efa5` (feat)
2. **Task 2: Document the MockServer optional dependency boundary** - `5bc9cc4` (docs)

## Files Created/Modified

- `lib/paddle/mock_server.ex` - Keeps `Paddle.MockServer.start_link/1` public while gating the Plug/Bandit router behind optional dependency availability.
- `test/paddle/mock_server_test.exs` - Preserves positive MockServer route coverage and adds a source guard for optional dependency checks.
- `README.md` - States the MockServer optional `plug`/`bandit` boundary and core SDK independence from Phoenix, Ecto, Plug, and Bandit.
- `demo/README.md` - States the demo/test dependency set includes the optional dependencies needed for MockServer-backed tests.
- `.planning/phases/28-ci-demo-and-package-proof/28-01-SUMMARY.md` - Records execution results.

## Verification

- `MIX_ENV=test mix test test/paddle/mock_server_test.exs` - passed, 10 tests / 0 failures.
- `mix test test/paddle/seam_test.exs` - passed, 4 tests / 0 failures.
- `mix compile --warnings-as-errors` - passed.

## Decisions Made

- Kept the public fixture entrypoint as `Paddle.MockServer.start_link/1` and avoided a new public namespace.
- Used an internal `Paddle.MockServer.Router` module so `Plug.Router` and `Plug.Parsers` macros are not expanded when optional dependencies are missing.
- Returned `{:error, %RuntimeError{}}` with installation guidance when `start_link/1` is called without the optional fixture dependencies.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Known Stubs

None. Stub scan only found an intentional `nil` assertion in `test/paddle/mock_server_test.exs` verifying no scheduled change for immediate subscription proration.

## Threat Flags

None. The plan modified an existing local fixture boundary and docs; no new network endpoint, auth path, file access pattern, or schema boundary was introduced beyond the planned MockServer fixture surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 28-02 can use this boundary for downstream package smoke proof: fresh consumers without optional `plug`/`bandit` should not compile-expand MockServer router code, while the root project continues to prove the positive MockServer lane.

## Self-Check: PASSED

- Found `lib/paddle/mock_server.ex`
- Found `test/paddle/mock_server_test.exs`
- Found `README.md`
- Found `demo/README.md`
- Found commit `5c2efa5`
- Found commit `5bc9cc4`

---
*Phase: 28-ci-demo-and-package-proof*
*Completed: 2026-06-24*
