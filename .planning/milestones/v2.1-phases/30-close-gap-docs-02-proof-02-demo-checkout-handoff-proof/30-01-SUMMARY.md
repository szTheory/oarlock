---
phase: 30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof
plan: 01
subsystem: testing
tags: [phoenix-liveview, phoenix-test, mockserver, checkout, portal]
requires:
  - phase: 29-gsd-state-reconciliation
    provides: Restored evidence and planning state for v2.1 close-gap work
provides:
  - Direct LiveView checkout push-event proof for the MockServer checkout URL
  - Direct LiveView portal redirect proof for active demo subscriptions
  - Provider-native demo checkout and billing handoff labels with stable button IDs
affects: [demo, docs-evidence, DOCS-02, PROOF-02]
tech-stack:
  added: []
  patterns:
    - Phoenix.LiveViewTest assertions for pushed checkout events and external redirects
    - Demo-owned valid transaction attrs passed through the existing SDK contract
key-files:
  created:
    - demo/test/demo_web/live/admin_live_test.exs
  modified:
    - demo/lib/demo_web/live/admin_live/index.ex
    - demo/test/demo_web/integration/billing_flow_test.exs
key-decisions:
  - "Kept checkout and portal proof deterministic and MockServer-backed, with no browser automation or live Paddle dependency."
  - "Fixed the demo-owned transaction request to satisfy Paddle.Transactions.create/3 validation instead of weakening SDK validation."
patterns-established:
  - "Stable handoff controls use #start-checkout-button and #manage-billing-button for direct LiveView tests."
  - "PhoenixTest remains the readable journey; Phoenix.LiveViewTest proves handoff internals."
requirements-completed: [DOCS-02, PROOF-02]
duration: 8 min
completed: 2026-06-25
status: complete
---

# Phase 30 Plan 01: Demo Checkout and Portal Handoff Proof Summary

**Deterministic Phoenix demo tests now prove MockServer checkout `open_checkout` and customer portal redirects directly.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-25T15:48:00Z
- **Completed:** 2026-06-25T15:56:25Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `DemoWeb.AdminLiveTest` with direct `Phoenix.LiveViewTest` coverage for checkout push events and portal redirects.
- Updated `DemoWeb.AdminLive.Index` to pass deterministic `customer_id`, `address_id`, `items`, and `custom_data` into `Paddle.Transactions.create/3`.
- Updated demo handoff copy to provider-native labels: `Start checkout` and `Manage billing`.

## Task Commits

1. **Task 1: Prove checkout handoff push event** - `d9b80aa` (feat)
2. **Task 2: Prove portal handoff redirect from active subscription state** - `d9b80aa` (feat)
3. **Task 3: Run demo proof gate** - verified before summary

**Plan metadata:** pending summary commit

## Files Created/Modified

- `demo/test/demo_web/live/admin_live_test.exs` - Direct LiveView tests for MockServer checkout URL push events and hosted portal redirects.
- `demo/lib/demo_web/live/admin_live/index.ex` - Stable checkout/portal button IDs, provider-native labels, and SDK-valid transaction request attrs.
- `demo/test/demo_web/integration/billing_flow_test.exs` - PhoenixTest journey updated to the new provider-native button labels.

## Decisions Made

- Kept the core SDK unchanged; the fix belongs in the demo-owned transaction request.
- Used direct LiveView assertions for `push_event/3` and external redirects while preserving PhoenixTest for the readable end-to-end journey.

## Deviations from Plan

Task 1 and Task 2 were implemented in one commit because the stable button IDs, provider-native labels, and LiveView test module are shared by both checkout and portal proof. The resulting diff is still confined to the three files owned by Plan 01.

**Total deviations:** 1 execution-order deviation.
**Impact on plan:** No scope change; all planned acceptance criteria were verified.

## Issues Encountered

None.

## Verification

- `cd demo && mix test test/demo_web/live/admin_live_test.exs --trace` - passed, 2 tests.
- `rg -n "assert_push_event\\(view, \"open_checkout\"|mock-checkout-url|mock-portal-session|start-checkout-button|manage-billing-button" demo/test/demo_web/live/admin_live_test.exs demo/lib/demo_web/live/admin_live/index.ex` - passed.
- `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs --trace` - passed, 4 tests.
- `cd demo && mix precommit` - passed, 25 tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can update `demo/README.md` and `.planning/EVIDENCE.md` against the strengthened local proof. No hosted GitHub Actions run was captured for this local SHA during Plan 01.

---
*Phase: 30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof*
*Completed: 2026-06-25*
