---
phase: 07-accrue-seam-lock
plan: "01"
subsystem: testing
tags: [seam, accrue, contract-test, exunit, adapter, raw_data, opaque, locked, elixir]

# Dependency graph
requires:
  - phase: 07-accrue-seam-lock
    provides: Plan 02 canonical seam guide (guides/accrue-seam.md) defining the locked/additive/opaque vocabulary, closed enumerated public surface, support-type boundary, and `:raw_data` escape-hatch policy
  - phase: 06-transactions-retrieval
    provides: Paddle.Transactions.get/2 surface that the seam test exercises end to end
  - phase: 05-subscriptions-management
    provides: Paddle.Subscriptions.get/2 and cancel/2 with hydrated %ScheduledChange{} and %ManagementUrls{} structs
  - phase: 04-transactions-hosted-checkout
    provides: Paddle.Transactions.create/2 returning %Transaction{} with hydrated %Checkout{}
  - phase: 03-core-entities-customers-addresses
    provides: Paddle.Customers.create/2 and Paddle.Customers.Addresses.create/3 returning typed %Customer{}/%Address{}
  - phase: 02-webhook-verification
    provides: Paddle.Webhooks.verify_signature/4 and parse_event/1 with %Paddle.Event{} envelope
  - phase: 01-core-transport-client-setup
    provides: %Paddle.Client{} value, Req-adapter test seam, and tagged-tuple response convention
provides:
  - Adapter-backed end-to-end seam contract test that proves the documented Accrue journey without live network access
  - Executable proof that guides/accrue-seam.md and Paddle's public surface stay in lockstep
  - Forward-compat policy expressed as test code: locked tuple/struct boundary plus is_map/1 escape-hatch presence checks for every :raw_data field
affects: [accrue, future seam additions, hexdocs, future plan-level threat models]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Semantic-contract seam test: pattern-match only locked tuple/struct fields plus typed nested structs (Checkout, ManagementUrls, ScheduledChange); use is_map/1 for documented :raw_data escape hatches; never freeze full provider payloads or undocumented nested map keys"
    - "One-shot adapter closures keep the seam test deterministic and offline; each public call gets its own client to avoid adapter reuse"
    - "Cross-step continuation drives subscription IDs from the locked typed seam (fetched_transaction.subscription_id) instead of opaque webhook event.data nested keys"

key-files:
  created:
    - .planning/phases/07-accrue-seam-lock/07-01-SUMMARY.md
  modified:
    - test/paddle/seam_test.exs

key-decisions:
  - "Per D-04 and D-05, the parsed %Paddle.Event{} match locks only the four envelope fields (event_id, event_type, occurred_at, notification_id) — the previously asserted nested data: %{...} pattern was dropped because guides/accrue-seam.md classifies Event :data as opaque."
  - "Per the plan's escape-hatch guidance, the next subscription ID flows from the locked transaction seam (fetched_transaction.subscription_id) instead of event.data[\"subscription_id\"], keeping the seam test independent of opaque webhook payload shape while preserving the existing operation order."
  - "Task 2 was an audit-only step: no forbidden support-type assertions (Paddle.Client.new!, %Paddle.Page{}, Page.next_cursor, %Paddle.Error{}, pause/resume/update) were ever introduced during the Task 1 refactor, so no file changes were required. No empty commit was created; the audit's evidence is the rg/test verification recorded below."

patterns-established:
  - "Pattern 1: Guide-first contract testing — guides/accrue-seam.md is the source of truth, and the seam test asserts only what the guide marks `locked` while treating every `opaque` surface (provider payloads, event :data, every :raw_data contents) as presence-only via is_map/1."
  - "Pattern 2: Cross-step continuation through locked typed fields — when a later step needs an ID from an earlier step's response, derive it from a top-level locked struct field rather than from an opaque forwarded map."
  - "Pattern 3: Narrow seam scope — support-type guarantees (Paddle.Client.new!/1, %Paddle.Page{}, Page.next_cursor/1, %Paddle.Error{}) live exclusively in their existing focused tests; the seam file remains the single end-to-end SEAM-01 proof and never absorbs them."

requirements-completed: [SEAM-01]

# Metrics
duration: 2min
completed: 2026-04-29
---

# Phase 07 Plan 01: Lock Accrue Seam Contract Test Summary

**Seam test refactored so it now executes the documented Accrue journey end-to-end and freezes only the locked tuple/struct boundary plus `is_map/1` escape-hatch presence — full raw payload equality and opaque nested-key equality are gone.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-29T19:03:24Z
- **Completed:** 2026-04-29T19:05:39Z
- **Tasks:** 2 (Task 2 audit-only — no file changes required)
- **Files modified:** 1 (`test/paddle/seam_test.exs`)

## Accomplishments

- Rewrote every assertion in `test/paddle/seam_test.exs` so it freezes only documented locked guarantees from `guides/accrue-seam.md`. Six full-payload or opaque-nested-key equality assertions were replaced with `is_map/1` escape-hatch presence checks: `customer.raw_data`, `address.raw_data`, `transaction.checkout.raw_data`, `fetched_transaction.checkout.raw_data`, `event.raw_data`, and `canceled_subscription.scheduled_change.raw_data`.
- Narrowed the parsed `%Paddle.Event{}` match to its four locked envelope fields (`event_id`, `event_type`, `occurred_at`, `notification_id`). The previously asserted `data: %{"id" => ..., "subscription_id" => ..., "checkout" => %{...}}` nested-key block was dropped because the canonical seam guide marks `:data` as `opaque`.
- Switched the next-step subscription ID from the opaque `event.data["subscription_id"]` to the locked typed seam value `fetched_transaction.subscription_id`. The same `"sub_seam01"` value still flows through the test but now reaches the subscription get call through a `locked` field instead of an `opaque` map key.
- Audited the seam file (Task 2) for scope creep against forbidden support-type assertions — `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, `%Paddle.Error{}`, `pause(`, `resume(`, `update(` — and confirmed none were present. Support-type coverage continues to live in `client_test.exs`, `page_test.exs`, and `error_test.exs`.
- Preserved every contract that must stay locked: the seven-step operation order (D-02), per-step request-path and request-body assertions inside one-shot adapter closures, typed nested structs `%Paddle.Transaction.Checkout{}`, `%Paddle.Subscription.ManagementUrls{}`, and `%Paddle.Subscription.ScheduledChange{}`, `async: false`, and the no-network test posture.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the seam assertions to freeze only the documented contract per D-01 through D-05** — `614171d` (test)
2. **Task 2: Preserve the narrow seam by keeping support-type coverage in focused tests, not in the end-to-end path** — _no commit, audit-only_ (no forbidden patterns were present after Task 1; verification proof recorded in this SUMMARY)

**Plan metadata:** _final commit follows this SUMMARY's creation; see Self-Check below._

## Files Created/Modified

- `test/paddle/seam_test.exs` — refactored every payload-equality assertion to `is_map/1` escape-hatch checks; narrowed the `%Paddle.Event{}` match to locked envelope fields; rerouted the subscription get continuation through `fetched_transaction.subscription_id`. The single-test, async-false, one-shot-adapter, request-path/body-assert structure is unchanged. Helper closures and fixture functions remain in place to keep the file self-contained.

## Decisions Made

- **Drop the nested `Event.data` pattern match (D-04, D-05).** The plan only explicitly required replacing `event.raw_data["data"]["customer_id"] == ...` with `is_map(event.raw_data)`, but D-04 forbids freezing undocumented nested map keys and the canonical guide (D-05 source of truth) marks `:data` as `opaque`. Locking `data: %{"id" => ..., "subscription_id" => ..., "checkout" => %{...}}` would have re-introduced the very ossification the plan removed elsewhere. The narrowed match keeps the four `locked` envelope fields and nothing more.
- **Drive subscription continuation from the locked transaction seam.** The plan explicitly suggested deriving the next subscription ID "from the locked transaction seam or a fixed fixture value instead of opaque webhook payload keys." Using `fetched_transaction.subscription_id` is the strongest of the two options because it also re-asserts that the typed transaction surface still carries the documented value (the existing `subscription_id: "sub_seam01"` pattern match in the get response remains the lock).
- **Task 2 is audit-only — no empty commit.** The plan's Task 2 instructions are conditional ("If any such assertions were added while refactoring, remove them"). Task 1 introduced none of the forbidden patterns, so there was nothing to remove. Per the executor protocol, no commit was created for a no-op step. The audit evidence (rg + combined `mix test`) is recorded under "Acceptance Criteria — Verified" below so reviewers can re-run it deterministically.

## Deviations from Plan

None of significance — the plan executed as written. One minor correctness adjustment beyond the literal task list, fully covered by D-04/D-05:

### Auto-fixed Issues

**1. [Rule 2 - Critical correctness] Narrowed the `%Paddle.Event{}` match to locked envelope fields only**
- **Found during:** Task 1
- **Issue:** The pre-existing `data: %{"id" => "txn_seam01", "subscription_id" => "sub_seam01", "checkout" => %{"url" => ...}}` nested-key pattern match froze undocumented opaque keys, contradicting D-04 ("must not freeze ... undocumented nested map keys") and D-05 (`guides/accrue-seam.md` classifies Event `:data` as `opaque`). The plan's literal task list only called out replacing the `event.raw_data["data"]["customer_id"]` line, but leaving the nested `data: %{...}` match in place would have re-introduced the very ossification the plan was removing elsewhere.
- **Fix:** Reduced the parsed-event match to the four locked envelope fields (`event_id`, `event_type`, `occurred_at`, `notification_id`) and pivoted the next-step subscription ID through the locked typed seam (`fetched_transaction.subscription_id`).
- **Files modified:** `test/paddle/seam_test.exs`
- **Verification:** `mix test test/paddle/seam_test.exs` passes (1 test, 0 failures); full `mix test` passes (111 tests, 0 failures).
- **Committed in:** `614171d` (Task 1 commit).

---

**Total deviations:** 1 auto-fixed (Rule 2 — guide-aligned correctness)
**Impact on plan:** Strictly tightening, not loosening. Every change is consistent with D-04 (no undocumented nested keys) and D-05 (guide is source of truth).

## Issues Encountered

None. The seam test was already passing before the refactor and continued to pass after each change.

## Acceptance Criteria — Verified

Task 1 — `is_map/1` escape-hatch presence checks (each must match exactly once):
- `rg -c 'assert is_map\(customer\.raw_data\)' test/paddle/seam_test.exs` → 1.
- `rg -c 'assert is_map\(address\.raw_data\)' test/paddle/seam_test.exs` → 1.
- `rg -c 'assert is_map\(transaction\.checkout\.raw_data\)' test/paddle/seam_test.exs` → 1.
- `rg -c 'assert is_map\(fetched_transaction\.checkout\.raw_data\)' test/paddle/seam_test.exs` → 1.
- `rg -c 'assert is_map\(event\.raw_data\)' test/paddle/seam_test.exs` → 1.
- `rg -c 'assert is_map\(canceled_subscription\.scheduled_change\.raw_data\)' test/paddle/seam_test.exs` → 1.
- `rg -n '== customer_payload\(|== address_payload\(|event\.raw_data\[|scheduled_change\.raw_data ==|checkout\.raw_data ==' test/paddle/seam_test.exs` → no matches (rg exits 1; required to be empty).

Task 1 — automated verify: `mix test test/paddle/seam_test.exs` exits 0 (1 test, 0 failures).

Task 2 — no forbidden support-type assertions in the seam file:
- `rg -n 'Paddle\.Client\.new!|Paddle\.Page|Page\.next_cursor|%Paddle\.Error\{|pause\(|resume\(|update\(' test/paddle/seam_test.exs` → no matches (rg exits 1; required to be empty).

Task 2 — combined run: `mix test test/paddle/seam_test.exs test/paddle/client_test.exs test/paddle/page_test.exs test/paddle/error_test.exs` exits 0 (9 tests, 0 failures).

Plan-level verification:
- `mix compile --warnings-as-errors` exits 0.
- Full `mix test` exits 0 (111 tests, 0 failures).

## Plan-Level Success Criteria — Verified

- `test/paddle/seam_test.exs` still executes the full Accrue path (customer create → address create → transaction create → transaction get → webhook verify → webhook parse → subscription get → subscription cancel) without live network access. ✓
- The seam test now freezes only documented locked tuple/struct behavior and `:raw_data` escape-hatch presence. ✓
- No raw payload equality or opaque nested-key equality remains in the seam file (rg confirms zero matches for the forbidden patterns). ✓
- Support-type assertions remain in the existing focused test files, not the end-to-end seam test (rg confirms zero matches in `seam_test.exs`; combined run still passes 9/9). ✓

## User Setup Required

None — no external service configuration is required for this plan.

## Self-Check

- [x] `test/paddle/seam_test.exs` exists and contains the refactored single end-to-end test (FOUND).
- [x] `.planning/phases/07-accrue-seam-lock/07-01-SUMMARY.md` exists (this file, FOUND).
- [x] Task 1 commit `614171d` exists in `git log`.
- [x] Task 2 audit verified by `rg` and combined `mix test` (no commit by design — no-op task).

## Self-Check: PASSED

## Next Phase Readiness

- SEAM-01 is now satisfied alongside the canonical guide produced by Plan 02. Phase 07 (Accrue Seam Lock) is complete: SEAM-01 (this plan) and SEAM-02 (Plan 02) both delivered, finishing milestone v1.1 (Accrue Seam Hardening).
- The seam test is intentionally narrow and forward-compatible. Future provider payload growth (new optional fields in customer/address/transaction/subscription/event) will not break it because every `:raw_data` assertion is presence-only and every typed match is restricted to the locked surface enumerated in `guides/accrue-seam.md`.
- Future Accrue-side asks should continue to be triaged into `.planning/BACKLOG.md` (per user MEMORY directive); they should not auto-insert phases here.

## Threat Flags

No new threat surface introduced. This plan only narrows the seam test to documented guarantees and removes ossifying assertions; it adds no new endpoints, no new auth/authz paths, no new file access patterns, and no schema changes. Threats T-07-01 through T-07-05 from the plan's threat register are mitigated as documented in the plan body and the Acceptance Criteria — Verified section above.

---
*Phase: 07-accrue-seam-lock*
*Plan: 01*
*Completed: 2026-04-29*
