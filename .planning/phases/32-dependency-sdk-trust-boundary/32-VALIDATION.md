---
phase: "32"
slug: "dependency-sdk-trust-boundary"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-10"
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 / OTP 28.1 |
| **Config file** | `test/test_helper.exs`; demo `demo/test/test_helper.exs` |
| **Quick run command** | `mix test test/paddle/client_test.exs test/paddle/http_test.exs test/paddle/http/telemetry_test.exs` |
| **Full suite command** | `mix test` plus the SAFE-01 compatibility matrix below |
| **Estimated runtime** | Measure and record during Wave 0; do not invent a fixed budget |

---

## Sampling Rate

- **After every task commit:** Run the focused command for the requirement changed.
- **After every plan wave:** Run `mix test` and `mix format --check-formatted`.
- **After the dependency plan:** Run the complete compatibility matrix and online `mix hex.audit`.
- **Before `$gsd-verify-work`:** Every compatibility row and focused safety suite must be green.
- **Max feedback latency:** Record the measured focused-suite baseline during Wave 0 and keep task sampling below it plus an explained regression.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-W0-01 | TBD | 0 | SAFE-01 | T-32-01 | Req compatibility and advisory closure | integration | `mix test && mix hex.audit` | ⚠️ partial | ⬜ pending |
| 32-W0-02 | TBD | 0 | SAFE-02 | T-32-02 | Telemetry allowlist and canary absence | unit | `mix test test/paddle/http/telemetry_test.exs` | ✅ | ⬜ pending |
| 32-W0-03 | TBD | 0 | SAFE-03 | T-32-03 | Promoted and nested secret redaction | unit | `mix test test/paddle/inspection_safety_test.exs` | ❌ W0 | ⬜ pending |
| 32-W0-04 | TBD | 0 | SAFE-04 | T-32-04 | Safe-read attempt matrix and no mutation replay | unit/integration | `mix test test/paddle/http_test.exs` | ✅ extend | ⬜ pending |
| 32-W0-05 | TBD | 0 | SAFE-05 | T-32-05 | Constructor decision table and redacted failures | unit | `mix test test/paddle/client_test.exs` | ✅ extend | ⬜ pending |
| 32-W0-06 | TBD | 0 | SAFE-06 | T-32-06 | Docs/types/runtime contract agreement | contract | `mix test test/paddle/seam_test.exs` | ✅ extend | ⬜ pending |

---

## Required SAFE-01 Compatibility Matrix

- `mix test`
- focused custom/function adapter tests
- `mix test test/paddle/http/telemetry_test.exs`
- `MIX_ENV=test mix test test/paddle/mock_server_test.exs test/paddle/subscription_flows_test.exs`
- `mix dialyzer`
- `mix docs`
- `bin/package_smoke.sh`
- root package proof without optional Plug/Bandit in a clean consumer
- `(cd demo && mix precommit)`
- downstream Accrue seam command resolved from that checkout's own instructions
- online `mix hex.audit`

---

## Wave 0 Requirements

- [ ] `test/paddle/inspection_safety_test.exs` — shared recursive canary walker and public secret-bearing-value inventory.
- [ ] Extend deterministic retry adapter fixtures for method/status/transport/`Retry-After` matrices.
- [ ] Add mechanical documentation assertions for removed idempotency options, retry policy, constructor examples, evidence tiers, Req/BEAM ranges, and migration notice.
- [ ] Resolve and record the local Accrue seam command from the owning checkout's instructions.
- [ ] Measure focused and full suite runtimes for the sampling record.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex registry advisory result | SAFE-01 | Requires working registry/network access; research-time access was unavailable | With registry access restored, run `mix hex.audit`; require exit 0 and no active advisory for the resolved Req version. |
| Downstream checkout ownership | SAFE-01, SAFE-06 | Command and worktree policy belong to the sibling Accrue repository | Read its current instructions, run its declared seam command without modifying unrelated files, and record exact command/result. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency baseline is measured and recorded.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
