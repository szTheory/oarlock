---
phase: 16-seam-validation-documentation
plan: 01
subsystem: documentation and tests
tags:
  - testing
  - docs
  - contract
requires: []
provides:
  - Documented Accrue Seam for PortalSessions and Adjustments
affects:
  - guides/accrue-seam.md
  - test/paddle/seam_test.exs
  - lib/paddle/portal_session.ex
tech-stack:
  added: []
  patterns:
    - stability tier vocabulary (locked/additive/opaque)
    - one-shot mock client adapters
key-files:
  created: []
  modified:
    - guides/accrue-seam.md
    - test/paddle/seam_test.exs
    - lib/paddle/portal_session.ex
decisions:
  - D-01: Documented internal provider details like urls, items, and totals as opaque within their respective structs to prevent consumer coupling.
  - D-02: Instantiated distinct one-shot clients for Portal Sessions and Adjustments inside the seam test to ensure stateless isolation of test stubs.
metrics:
  duration: 3
  completed-date: 2026-06-09
---

# Phase 16 Plan 01: Document and Test Accrue Seam Contract Updates Summary

The Accrue seam contract documentation and end-to-end testing surface have been extended to include `PortalSessions` and `Adjustments`. Both entities now explicitly document their stability tiers, defining top-level fields as locked and external provider blobs as opaque. End-to-end tests rigorously enforce these new contracts without leaking shared test states.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Functionality] Added missing `raw_data` field to `%Paddle.PortalSession{}`**
- **Found during:** Task 2 verification
- **Issue:** The integration test crashed on `assert is_map(portal_session.raw_data)` because the `raw_data` field was missing from the `%Paddle.PortalSession{}` struct definition. This is a canonical requirement for all locked structs in the contract.
- **Fix:** Added `:raw_data` to `defstruct` and the `@type t` definition in `lib/paddle/portal_session.ex`.
- **Files modified:** `lib/paddle/portal_session.ex`
- **Commit:** d435027
## Self-Check: PASSED
