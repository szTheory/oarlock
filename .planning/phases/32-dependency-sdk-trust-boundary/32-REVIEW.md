---
phase: 32-dependency-sdk-trust-boundary
reviewed: 2026-09-11T02:17:18Z
depth: standard
files_reviewed: 46
files_reviewed_list:
  - CHANGELOG.md
  - README.md
  - bin/phase32_compatibility.sh
  - bin/phase32_contract_proof.sh
  - demo/README.md
  - guides/accrue-seam.md
  - guides/getting-started.md
  - guides/telemetry.md
  - lib/paddle/adjustments.ex
  - lib/paddle/client.ex
  - lib/paddle/customers.ex
  - lib/paddle/customers/addresses.ex
  - lib/paddle/customers/portal_sessions.ex
  - lib/paddle/error.ex
  - lib/paddle/events.ex
  - lib/paddle/http.ex
  - lib/paddle/http/telemetry.ex
  - lib/paddle/internal/pagination.ex
  - lib/paddle/notification_setting.ex
  - lib/paddle/notification_settings.ex
  - lib/paddle/portal_session.ex
  - lib/paddle/portal_sessions.ex
  - lib/paddle/prices.ex
  - lib/paddle/products.ex
  - lib/paddle/subscription/management_urls.ex
  - lib/paddle/subscriptions.ex
  - lib/paddle/transaction/checkout.ex
  - lib/paddle/transactions.ex
  - mix.exs
  - test/paddle/adjustments_test.exs
  - test/paddle/client_test.exs
  - test/paddle/customers/addresses_test.exs
  - test/paddle/customers/portal_sessions_test.exs
  - test/paddle/customers_test.exs
  - test/paddle/error_test.exs
  - test/paddle/events_test.exs
  - test/paddle/http/telemetry_test.exs
  - test/paddle/http_test.exs
  - test/paddle/inspection_safety_test.exs
  - test/paddle/notification_settings_test.exs
  - test/paddle/portal_session_test.exs
  - test/paddle/prices_test.exs
  - test/paddle/products_test.exs
  - test/paddle/seam_test.exs
  - test/paddle/subscriptions_test.exs
  - test/paddle/transactions_test.exs
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 32: Code Review Report

**Reviewed:** 2026-09-11T02:17:18Z
**Depth:** standard
**Files Reviewed:** 46
**Status:** issues_found

## Summary

The Phase 32 implementation and its gap-closure commits were reviewed against the declared summary scope and the committed diff from `aef4c2f`. Generated lockfiles and the unrelated `.tool-versions` working-tree change were excluded from substantive review. The full suite passes with 272 tests, and shell syntax plus the compatibility receipt self-test pass, but those checks miss three release-blocking contract defects: a failed full matrix can leave an old passing receipt in place, the bounded verifier remains too close to its deadline and has timed out on a fresh run, and subscription lifecycle parsing can silently accept duplicate `:retry` options. The custom Inspect implementations also emit malformed struct-like syntax.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: [BLOCKER] A failed full compatibility run can leave a stale passing receipt

**File:** `bin/phase32_compatibility.sh:165-180`

**Issue:** `run_matrix` validates `ACCRUE_CHECKOUT` before deleting `phase32-compatibility.receipt`. If an earlier run published a passing receipt and a later invocation fails either preflight check, the old acceptance artifact remains visible. This was reproduced with a pre-existing receipt and an empty `ACCRUE_CHECKOUT`: the script exited 2 while the receipt still contained `phase32_compatibility=passed`. Any consumer that watches the documented receipt path can therefore mistake a failed or incomplete current run for fresh full-matrix acceptance.

**Fix:** Delete or quarantine the destination receipt immediately on entry to `--full`, before every preflight that can fail. Keep publication as the final same-directory atomic rename, and extend `--self-test` to seed a stale receipt, fail preflight, and assert that no acceptance receipt remains.

### CR-02: [BLOCKER] The bounded contract verifier does not reliably satisfy its 30-second contract

**File:** `bin/phase32_contract_proof.sh:166-180`

**Issue:** The verifier sequentially runs the isolated reader/docs pair, the receipt self-test, and the compatibility verifier. Although the latest concurrency change reduces duplicated work, the compatibility verifier still selects whole test files with real jittered retry waits (`bin/phase32_compatibility.sh:41-50`). A fresh review run under the exact 30-second wrapper was terminated during the bounded suite and published no contract receipt; a subsequent warm run passed at 28 seconds. A two-second warm-run margin is not a reliable bounded proof and contradicts the validated claim that this command consistently completes within 30 seconds.

**Fix:** Remove wall-clock retry sleeps from the verifier path by injecting a zero-delay test retry configuration while testing the retry decision separately, or select narrowly tagged/line-addressed contract tests instead of complete time-bearing files. Require meaningful margin under the 30-second wrapper across cold consecutive runs before treating the receipt as automated SAFE-06 evidence.

### CR-03: [BLOCKER] Subscription pause/resume silently collapse duplicate retry options

**File:** `lib/paddle/subscriptions.ex:478-489`

**Issue:** `normalize_pause_opts/1` and the equivalent `normalize_resume_opts/1` at lines 550-562 use `Keyword.pop/2`, which removes all occurrences while returning only the first value. This bypasses `Paddle.Http`'s duplicate-retry rejection. `[retry: false, retry: true]` reaches dispatch as `retry: false`, while the reversed list raises for `retry: true`; behavior therefore depends on ordering instead of rejecting ambiguous caller configuration consistently. The Phase 32 trust-boundary contract explicitly rejects duplicate request options elsewhere.

**Fix:** Count or fetch all `:retry` values before removing the key and raise a key-only `ArgumentError` unless zero or one value is present. Apply the same validation to pause and resume, and add regression cases for both conflicting orders that assert zero adapter dispatches.

## Warnings

### WR-01: [WARNING] Custom Inspect output is not valid struct syntax

**File:** `lib/paddle/client.ex:213-226`

**Issue:** The Phase 32 Inspect implementations concatenate a struct prefix with `to_doc/2` applied to a keyword list. They render values such as `%Paddle.Client{[api_key: "[REDACTED]", ...]}` and `%Paddle.Transaction.Checkout{[raw_data: "[REDACTED]", ...]}`. The brackets make this neither ordinary struct inspection nor valid Elixir struct syntax, degrading logs and copy/paste debugging across all six new implementations (`Paddle.Client`, `Paddle.Error`, `Paddle.NotificationSetting`, `Paddle.PortalSession`, `Paddle.Subscription.ManagementUrls`, and `Paddle.Transaction.Checkout`). Existing tests check redaction canaries but do not validate the representation shape.

**Fix:** Render the redacted key/value pairs with `Inspect.Algebra.container_doc/6` (or an equivalent struct-aware formatter) so the result is `%Module{field: value, ...}` while still honoring the caller's Inspect options. Add exact-shape assertions for one multi-field and one all-redacted struct.

---

_Reviewed: 2026-09-11T02:17:18Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
