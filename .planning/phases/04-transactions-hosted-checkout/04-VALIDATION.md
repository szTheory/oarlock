---
phase: 04
slug: transactions-hosted-checkout
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | TXN-02 | T-04-01 / T-04-03 / T-04-04 | Transaction and checkout entities expose only the locked field surface and preserve full upstream payloads in `raw_data`. | unit | `mix test test/paddle/transaction_test.exs` | ✅ | ⬜ pending |
| 04-01-02 | 01 | 1 | TXN-02 | T-04-01 / T-04-03 / T-04-04 | Struct modules match the tested contract so later resource mapping can guarantee `transaction.checkout.url`. | unit | `mix test test/paddle/transaction_test.exs` | ✅ | ⬜ pending |
| 04-02-01 | 02 | 2 | TXN-01 / TXN-02 | T-04-05 / T-04-06 / T-04-08 | Create-path tests prove exact `/transactions` request shaping, exact local validation tuples, and stable error propagation. | integration | `mix test test/paddle/transactions_test.exs` | ✅ | ⬜ pending |
| 04-02-02 | 02 | 2 | TXN-01 / TXN-02 | T-04-05 / T-04-06 / T-04-07 / T-04-08 | Implementation only forwards the curated hosted-checkout branch, hydrates nested checkout into `%Paddle.Transaction.Checkout{}`, and returns `{:ok, %Paddle.Transaction{}}`. | integration | `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure in `test/test_helper.exs` covers the phase.
- [x] Existing Req adapter test patterns in `test/paddle/customers_test.exs` and `test/paddle/customers/addresses_test.exs` can be reused directly.
- [x] No framework installation or new shared fixture layer is required before execution.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Open a returned hosted checkout link in a configured Paddle environment | TXN-02 | Checkout-link validity depends on Paddle dashboard payment-link and approved-domain setup outside the repo. | After automated tests pass, create a sandbox transaction with a valid customer, address, and recurring item, confirm `transaction.checkout.url` is present, then open the returned URL in a browser using an account with a default payment link and any override domain approved in Paddle. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-28
