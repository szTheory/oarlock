---
phase: 30
slug: close-gap-docs-02-proof-02-demo-checkout-handoff-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-25
---

# Phase 30 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix.LiveViewTest, PhoenixTest |
| **Config file** | `demo/config/test.exs` |
| **Quick run command** | `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs` |
| **Full suite command** | `cd demo && mix precommit` |
| **Estimated runtime** | ~60-180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs`
- **After every plan wave:** Run `cd demo && mix precommit`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | DOCS-02/PROOF-02 | T-30-01 | Checkout proof cannot pass without an `open_checkout` event containing the MockServer checkout URL. | LiveView integration | `cd demo && mix test test/demo_web/live/admin_live_test.exs` | W0 | pending |
| 30-01-02 | 01 | 1 | DOCS-02/PROOF-02 | T-30-02 | Portal proof asserts authenticated hosted portal redirect from active subscription state. | LiveView integration | `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs` | W0 | pending |
| 30-02-01 | 02 | 2 | DOCS-02/PROOF-02 | - | Public docs and evidence ledger state deterministic MockServer proof and do not overclaim hosted/live CI. | source/docs | `rg "DOCS-02|PROOF-02|Phase 30|hosted CI|MockServer" .planning/EVIDENCE.md demo/README.md README.md guides` | W0 | pending |
| 30-02-02 | 02 | 2 | DOCS-02/PROOF-02 | - | Demo regression and precommit suite pass with the strengthened checkout/portal proof. | full suite | `cd demo && mix precommit` | W0 | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `demo/test/demo_web/integration/billing_flow_test.exs` already exists.
- `demo/test/support/conn_case.ex` already provides Phoenix connection/test setup.
- `demo/test/test_helper.exs` already starts `Paddle.MockServer` and configures demo test clients.
- No new test framework or dependency is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hosted GitHub Actions status for the final SHA | PROOF-02 | Hosted CI only exists after the branch is pushed; local planning/execution cannot truthfully claim it. | If a pushed run exists, record exact SHA, job name, status, and run URL in Phase 30 summary/verification artifacts and `.planning/EVIDENCE.md`; otherwise record the explicit hosted-CI caveat. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-25
