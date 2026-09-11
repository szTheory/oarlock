---
phase: 32-dependency-sdk-trust-boundary
plan: "14"
subsystem: verification
tags: [bash, elixir, receipts, tdd, retry-policy, dependency-trust]

requires:
  - phase: 32-dependency-sdk-trust-boundary
    provides: Full 13-row compatibility matrix, bounded verifier, and SAFE evidence contracts from Plan 13
provides:
  - Full compatibility receipts invalidated before failing Accrue preflight checks
  - Bounded contract receipt candidates promoted only by a successful process exit
  - Deterministic cold scoped evidence with byte-identical concurrent-read checks
affects: [phase-32-verification, safe-01, safe-06, release-trust]

actuals:
  tokens: 3697
  tasks: 2
  commits: 4
plan_head_before: 90722268761f739bd9a5fa0eb86981fac9f74fcd

tech-stack:
  added: []
  patterns: [preflight-first receipt invalidation, exit-finalized same-directory candidates, deterministic line-scoped evidence]

key-files:
  created: []
  modified:
    - bin/phase32_compatibility.sh
    - bin/phase32_contract_proof.sh
    - test/paddle/http_test.exs
    - test/paddle/seam_test.exs

key-decisions:
  - "A full compatibility attempt revokes a prior local receipt before validating the Accrue checkout, so failed prerequisites cannot preserve stale acceptance."
  - "Bounded proof candidates are written privately and atomically renamed only by an EXIT finalizer after every check completes successfully."
  - "The bounded suite uses direct retry-decision evidence and selected no-sleep contracts; the full suite retains physical four-attempt behavior and both complete matrices."

patterns-established:
  - "Acceptance artifacts are invalidated at attempt start and published only at the final successful completion boundary."
  - "Fast local evidence stays explicitly subordinate to the full matrix, downstream, and hosted/provider authority tiers."

requirements-completed: [SAFE-01, SAFE-06]

coverage:
  - id: D1
    description: "A missing or invalid full-mode Accrue preflight removes a seeded stale compatibility receipt before matrix execution."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "bin/phase32_compatibility.sh --self-test"
        status: pass
      - kind: unit
        ref: "test/paddle/seam_test.exs#Phase 32 full receipt invalidation precedes every Accrue preflight"
        status: pass
    human_judgment: false
  - id: D2
    description: "Bounded contract candidates are removed on termination and only an EXIT-zero finalizer publishes the receipt."
    requirement: SAFE-06
    verification:
      - kind: integration
        ref: "bin/phase32_contract_proof.sh --self-test-termination"
        status: pass
      - kind: unit
        ref: "test/paddle/seam_test.exs#Phase 32 bounded contract receipt finalizes only from successful exit"
        status: pass
    human_judgment: false
  - id: D3
    description: "Cold bounded proof keeps all SAFE verdicts, audit, no-drift checks, and deterministic retry evidence within the 30-second wrapper."
    requirement: SAFE-06
    verification:
      - kind: integration
        ref: "run-with-timeout 30 -- env ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh --verify (11.6s, 13.8s)"
        status: pass
      - kind: unit
        ref: "test/paddle/http_test.exs#retry decisions are deterministic, safe-read-only, and cap only 429 Retry-After"
        status: pass
    human_judgment: false
  - id: D4
    description: "The full 13-row compatibility matrix and two-equal-manifest contract proof remain complete and separate from bounded evidence."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "ACCRUE_CHECKOUT=../accrue bin/phase32_compatibility.sh --full"
        status: pass
      - kind: integration
        ref: "ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh --full"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-09-11
status: complete
---

# Phase 32 Plan 14: Receipt Lifecycle and Bounded Contract Proof Summary

**Full and bounded Phase 32 receipts now fail closed: stale full acceptance is revoked before preflight, while bounded proof publishes only after a successful final process exit.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-09-11T02:59:40Z
- **Completed:** 2026-09-11T03:15:52Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added real full-path missing and invalid Accrue preflight probes that seed then prove removal of stale compatibility receipts.
- Reworked bounded proof receipt handling around a unique same-directory candidate, EXIT-zero finalization, signal/nonzero cleanup, and a deterministic termination probe.
- Replaced bounded real retry waits with direct retry-decision coverage and line-scoped, cold-build test selection while retaining full retry and two-manifest authority checks.

## Task Commits

1. **Task 1 RED: Pin stale full receipt preflight regression** — `cbf9e8e` (test)
2. **Task 1 GREEN: Invalidate full receipt before preflight** — `1265e53` (fix)
3. **Task 2 RED: Pin premature bounded receipt finalization** — `c50e50e` (test)
4. **Task 2 GREEN: Finalize bounded receipts only on successful exit** — `1eb54ce` (fix)

## Files Created/Modified

- `bin/phase32_compatibility.sh` — Revokes stale full receipts before preflight and selects deterministic bounded evidence with isolated cold builds.
- `bin/phase32_contract_proof.sh` — Stages unique verifier candidates, finalizes only from EXIT zero, and proves termination cleanup.
- `test/paddle/http_test.exs` — Directly checks safe-read retry decisions and Retry-After capping without waiting.
- `test/paddle/seam_test.exs` — Guards full preflight invalidation and bounded receipt finalization structure.

## Decisions Made

- Receipts are current-run evidence only: any failed prerequisite, signal, timeout, or nonzero exit removes acceptance instead of preserving a prior pass.
- Bounded verification is intentionally faster but retains explicit local-only wording and does not substitute for full matrices, downstream checks, hosted CI, sandbox, live-provider, release, or publication proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Propagated real full-preflight failure before matrix execution**
- **Found during:** Task 1 self-test
- **Issue:** Calling the preflight helper inside an `if` context could suppress `errexit` and allow the matrix to continue after a failed preflight.
- **Fix:** Explicitly returned the failed preflight status from `run_matrix`.
- **Files modified:** `bin/phase32_compatibility.sh`
- **Verification:** `bin/phase32_compatibility.sh --self-test`
- **Committed in:** `1265e53`

**2. [Rule 1 - Bug] Removed real retry sleeps from bounded evidence selection**
- **Found during:** Task 2 cold-wrapper verification
- **Issue:** A selected later-page retry test introduced exponential wall-clock delays into the bounded verifier.
- **Fix:** Kept direct retry-decision coverage and replaced that selection with a no-dispatch validation contract; physical retries remain in the ordinary/full suite.
- **Files modified:** `bin/phase32_compatibility.sh`
- **Verification:** Two cold 30-second wrappers completed in 11.6s and 13.8s.
- **Committed in:** `1eb54ce`

---

**Total deviations:** 2 auto-fixed Rule 1 bugs.
**Impact on plan:** Both fixes enforce the stated fail-closed and boundedness contracts without expanding authority or scope.

## Issues Encountered

- Hex reported an expired optional authentication session but continued anonymously; both online `mix hex.audit` checks completed cleanly, so no authentication gate was required.

## TDD Gate Compliance

- Task 1 RED failed on the missing full-preflight receipt markers before the receipt ordering implementation; its GREEN self-test and seam guard pass.
- Task 2 RED failed on the missing termination/finalizer markers before the exit-finalization implementation; its GREEN termination probe, retry/seam tests, and wrappers pass.

## Known Stubs

None.

## User Setup Required

None - the sibling Accrue checkout and public Hex registry were available.

## Next Phase Readiness

- SAFE-01 and SAFE-06 now have fresh fail-closed local receipt evidence plus preserved complete-matrix proof.
- Plan 32-15 can proceed independently with its mutation option-boundary work.

## Self-Check: PASSED

- All four implementation/test artifacts and the canonical summary exist on disk.
- All four RED/GREEN task commits are present in Git history.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-11*
