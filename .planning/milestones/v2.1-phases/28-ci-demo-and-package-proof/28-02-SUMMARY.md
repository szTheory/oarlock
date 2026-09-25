---
phase: 28-ci-demo-and-package-proof
plan: 2
subsystem: ci
tags: [github-actions, mix, hex, postgres, optional-deps]

requires:
  - phase: 28-01
    provides: MockServer optional dependency boundary
provides:
  - Reusable Hex artifact downstream consumer smoke helper
  - CI jobs for demo PostgreSQL, package smoke, and optional dependency proof
  - Fresh consumer proof for Hex package oarlock, OTP app :paddle, and Paddle.* modules
affects: [ci, release-readiness, package-proof, demo]

tech-stack:
  added: []
  patterns:
    - mix hex.build --unpack package artifact proof
    - GitHub Actions PostgreSQL service container for demo tests
    - Fresh downstream Mix app compile without optional fixture dependencies

key-files:
  created:
    - bin/package_smoke.sh
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "Kept Phase 28 release proof in the existing CI workflow with separate named jobs."
  - "Used Hex build/unpack output as the package smoke source instead of a repo path-only proof."
  - "Made optional dependency proof two-sided: MockServer positive test plus fresh consumer negative compile."

patterns-established:
  - "Package smoke scripts compile a generated consumer against the unpacked Hex artifact."
  - "Demo CI uses explicit check-mode Mix commands from demo/ and a PostgreSQL service with DB_HOST=localhost."

requirements-completed: [PROOF-01, PROOF-02, PROOF-03, PROOF-04]

duration: 25min
completed: 2026-06-24
status: complete
---

# Phase 28 Plan 2: CI Demo and Package Proof Summary

**CI now continuously proves the root gates, Phoenix demo PostgreSQL tests, Hex package downstream consumption, and the MockServer optional dependency boundary.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-06-24T16:28:00Z
- **Completed:** 2026-06-24T16:53:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `bin/package_smoke.sh`, which runs `mix hex.build --unpack`, creates a fresh supervised Mix app, depends on the unpacked artifact as `{:paddle, path: unpacked_path}`, and compiles a module referencing `Paddle.Client`, `Paddle.Webhooks`, and `Paddle.Customers`.
- Added separate `.github/workflows/ci.yml` jobs named `demo-postgres`, `package-smoke`, and `optional-deps` while preserving existing root `test` and `dialyzer` jobs and pinned action SHAs.
- Wired demo CI to a PostgreSQL service with `DB_HOST=localhost` and explicit check-mode commands from `demo/`.
- Wired optional dependency proof to run the positive MockServer test and the negative fresh-consumer package smoke.

## Task Commits

1. **Task 1: Add a Hex artifact downstream package smoke helper** - `349dbae` (feat)
2. **Task 2: Add named CI jobs for demo PostgreSQL, package smoke, and optional dependency proof** - `da3c967` (feat)

## Files Created/Modified

- `bin/package_smoke.sh` - Reusable package proof that builds/unpacks the local Hex artifact and compiles a downstream consumer without declaring optional fixture dependencies.
- `.github/workflows/ci.yml` - Adds `demo-postgres`, `package-smoke`, and `optional-deps` jobs while preserving root release gates.

## Verification

- `bin/package_smoke.sh` - passed; unpacked `oarlock` 0.1.1 and compiled the fresh consumer with warnings as errors.
- `MIX_ENV=test mix test test/paddle/mock_server_test.exs` - passed; 10 tests, 0 failures.
- `ASDF_RUBY_VERSION=system ruby -e "require 'yaml'; YAML.load_file('.github/workflows/ci.yml')"` - passed. The plain `ruby` shim has no local version configured, so system Ruby was selected through asdf for the same YAML parse command.
- Source assertions passed for `demo-postgres:`, `package-smoke:`, `optional-deps:`, `services:`, `DB_HOST: localhost`, `bin/package_smoke.sh`, `test/paddle/mock_server_test.exs`, `mix hex.build --unpack`, and `OarlockConsumerProof.UsePaddle`.
- GitHub Actions inspection: `gh run list --limit 3` succeeded, but the latest remote CI runs are from 2026-06-09 and predate these local commits, so no remote run can yet confirm the new jobs until these commits are pushed.

## Decisions Made

- Repeated setup steps in each new CI job to keep job failure attribution direct and avoid hiding proof surfaces behind a combined script.
- Used the package smoke script as the negative optional-deps lane in both `package-smoke` and `optional-deps`, keeping the proof executable locally and in CI.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- Initial workflow edit inserted the new jobs inside the Dialyzer cache step. This was corrected before commit and verified with YAML parsing and source assertions.
- Local `ruby` resolves through an asdf shim without a configured version. Verification used `ASDF_RUBY_VERSION=system ruby` to run the plan's YAML parse command with the system Ruby.

## Known Stubs

None.

## Threat Flags

None. The touched CI workflow, PostgreSQL service, Hex artifact proof, and optional-dependency boundary are all covered by the plan threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 28 now has local proof and CI definitions for PROOF-01 through PROOF-04. A pushed CI run should be inspected next to confirm the new named jobs execute in GitHub Actions.

## Self-Check: PASSED

- Found `bin/package_smoke.sh`.
- Found `.github/workflows/ci.yml`.
- Found commits `349dbae` and `da3c967` in git history.
- Stub scan found no TODO/FIXME/placeholder markers in touched files.

---
*Phase: 28-ci-demo-and-package-proof*
*Completed: 2026-06-24*
