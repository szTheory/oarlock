---
phase: "32"
slug: "dependency-sdk-trust-boundary"
status: draft
nyquist_compliant: true
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
| 32-W0-01 | 32-11 | 3 | SAFE-01 | T-32-01, T-32-05 | Req compatibility and advisory closure | integration | `ACCRUE_CHECKOUT=../accrue bin/phase32_compatibility.sh` | ⚠️ Plans 32-01/02/11 | ⬜ pending |
| 32-W0-02 | 32-08 | 8 | SAFE-02 | T-32-20, T-32-21 | Telemetry allowlist and canary absence | unit | `mix test test/paddle/http/telemetry_test.exs` | ✅ extend | ⬜ pending |
| 32-W0-03 | 32-09 | 6 | SAFE-03 | T-32-23, T-32-24 | Promoted and nested secret redaction | unit | `mix test test/paddle/inspection_safety_test.exs` | ❌ Plan 32-09 | ⬜ pending |
| 32-W0-04 | 32-04 | 5 | SAFE-04 | T-32-10, T-32-11 | Safe-read attempt matrix and no mutation replay | unit/integration | `mix test test/paddle/http_test.exs` | ✅ extend | ⬜ pending |
| 32-W0-05 | 32-03 | 4 | SAFE-05 | T-32-07, T-32-08 | Constructor decision table and redacted failures | unit | `mix test test/paddle/client_test.exs` | ✅ extend | ⬜ pending |
| 32-W0-06 | 32-10 | 9 | SAFE-06 | T-32-25, T-32-26 | Docs/types/runtime contract agreement plus isolated concurrency/interruption acceptance | contract | `mix test test/paddle/seam_test.exs &amp;&amp; ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh` | ✅ extend + create proof runner | ⬜ pending |

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

- [ ] Plan 32-09 creates `test/paddle/inspection_safety_test.exs` with the shared recursive canary walker and public secret-bearing-value inventory.
- [ ] Plan 32-04 extends deterministic retry adapter fixtures for method/status/transport/`Retry-After` matrices.
- [ ] Plan 32-10 adds mechanical documentation assertions for removed idempotency options, retry policy, constructor examples, evidence tiers, Req/BEAM ranges, and migration notice.
- [ ] Plan 32-11 runs and records `(cd "$ACCRUE_CHECKOUT/accrue" && mix test test/accrue/billing/subscription_projection_provider_test.exs)` from the owning checkout's Mix instructions.
- [ ] Plans 32-01/02/11 measure focused and full suite runtimes for the sampling record; Plan 32-10 records the final comparison and isolated concurrency/interruption proofs.

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
