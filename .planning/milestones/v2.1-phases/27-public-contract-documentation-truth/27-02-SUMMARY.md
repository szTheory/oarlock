---
phase: 27-public-contract-documentation-truth
plan: 02
subsystem: documentation
tags: [docs, demo, phoenix, mockserver, adopter-journey]
requires:
  - phase: 27-public-contract-documentation-truth
    provides: Guarded seam inventory and proof boundary vocabulary from Plan 27-01
provides:
  - First-read README proof ladder, pagination, error, and guide links
  - Getting Started app-owned responsibility and before-live checklist
  - Demo runbook covering mock auth, webhook processing, portal handoff, Offline Mode, and proof boundary
affects: [readme, getting-started, demo-docs, release-readiness]
tech-stack:
  added: []
  patterns:
    - Task-based adopter documentation with explicit app-owned Phoenix/Ecto boundaries
    - Consistent proof ladder for unit/contract, MockServer, sandbox, and live readiness
key-files:
  created:
    - .planning/phases/27-public-contract-documentation-truth/27-02-SUMMARY.md
  modified:
    - README.md
    - guides/getting-started.md
    - demo/README.md
    - demo/lib/demo_web/live/admin_live/index.ex
key-decisions:
  - "Kept README short and link-driven while adding proof, pagination, and normalized error examples."
  - "Documented demo Phoenix/Ecto code as app-owned and kept core SDK boundaries pure."
patterns-established:
  - "Public docs should name raw-body webhook verification before parsing or trusting events."
  - "Before-live checklists separate sandbox credentials, webhook secrets, real price IDs, and live credential swaps."
requirements-completed: [DOCS-01, DOCS-02, DOCS-03, DOCS-04]
duration: 29 min
completed: 2026-06-24
status: complete
---

# Phase 27 Plan 02: First-Read and Demo Documentation Summary

**README, Getting Started, and demo runbook now describe the shipped adopter journey, app-owned boundaries, and MockServer proof limits**

## Performance

- **Duration:** 29 min
- **Started:** 2026-06-24T14:30:30Z
- **Completed:** 2026-06-24T14:59:36Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added README proof ladder, normalized `%Paddle.Error{}` handling, pagination helpers, and links to Getting Started, seam contract, telemetry, and demo docs.
- Updated Getting Started with proof boundary language, app-owned authorization/idempotency/persistence responsibilities, preferred portal session path, support/admin surfaces, and a before-live checklist.
- Replaced the generated Phoenix demo README with a real runbook covering local setup, mock auth, Offline Mode, raw-body webhook processing, portal handoff, production boundary, and before-live checklist.
- Removed an unused alias in the demo LiveView that caused `mix precommit` to fail at compile-time before reaching tests.

## Task Commits

1. **Task 1 and Task 2: Adopter and demo documentation alignment** - `ecdef6e` (`docs(27-02): align adopter and demo documentation`)

**Plan metadata:** committed separately with this summary.

## Files Created/Modified

- `README.md` - Adds proof ladder, normalized error handling, pagination examples, and guide links.
- `guides/getting-started.md` - Adds proof boundary, app-owned boundaries, portal/session guidance, and before-live checklist.
- `demo/README.md` - Adds full local/demo runbook, Offline Mode proof boundary, webhook and portal handoff sections, and before-live checklist.
- `demo/lib/demo_web/live/admin_live/index.ex` - Removes unused `Demo.Billing` alias so precommit can compile.

## Decisions Made

- Kept Phoenix/Plug/Ecto material as documentation and demo-local examples, not core SDK code.
- Documented the demo portal handoff behavior without changing the demo implementation in this docs-focused plan.

## Deviations from Plan

**1. [Rule 3 - Blocking] Removed unused demo alias**
- **Found during:** `cd demo && mix precommit`
- **Issue:** Demo compilation failed with warnings-as-errors because `Demo.Billing` was aliased but unused.
- **Fix:** Removed the unused alias from `demo/lib/demo_web/live/admin_live/index.ex`.
- **Files modified:** `demo/lib/demo_web/live/admin_live/index.ex`
- **Verification:** `mix precommit` progressed past compilation into the test suite.
- **Committed in:** `ecdef6e`

**Total deviations:** 1 auto-fixed blocking issue. **Impact:** No behavior change; the fix only removed an unused alias.

## Issues Encountered

`cd demo && mix precommit` did not fully pass. After rebuilding the stale `lazy_html` test dependency and removing the unused alias, the command reached ExUnit and failed on an existing integration expectation:

- `test/demo_web/integration/billing_flow_test.exs:59`
- Expected path: `https://sandbox-my.paddle.com/mock-portal-session`
- Actual path: `/mock-portal-session`

This appears to be demo behavior/test alignment rather than a documentation issue. It is recorded for follow-up instead of broadening this phase into demo behavior repair.

## Verification

- `mix docs --warnings-as-errors` - passed
- `rg -n "Paddle\\.Subscriptions\\.create|Stripe compatibility|official Paddle SDK|sandbox verified|provider-state verified|live verified" README.md guides/getting-started.md guides/accrue-seam.md demo/README.md CHANGELOG.md` - no matches
- `cd demo && mix precommit` - failed on existing portal redirect assertion after compile warning was fixed

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 27-03 can normalize final proof wording and add the bounded changelog entry, with one known demo precommit issue documented above.

---
*Phase: 27-public-contract-documentation-truth*
*Completed: 2026-06-24*
