---
phase: "32"
slug: "dependency-sdk-trust-boundary"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-10"
validated: "2026-09-10"
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
| 32-W0-01 | 32-11 | 3 | SAFE-01 | T-32-01, T-32-05 | Req compatibility and advisory closure | integration | `ACCRUE_CHECKOUT=../accrue bin/phase32_compatibility.sh --verify` | ✅ | ✅ green |
| 32-W0-02 | 32-08 | 8 | SAFE-02 | T-32-20, T-32-21 | Telemetry allowlist and canary absence | unit | `mix test test/paddle/http/telemetry_test.exs` | ✅ | ✅ green |
| 32-W0-03 | 32-09 | 6 | SAFE-03 | T-32-23, T-32-24 | Promoted and nested secret redaction | unit | `mix test test/paddle/inspection_safety_test.exs` | ✅ | ✅ green |
| 32-W0-04 | 32-04, 32-15 | 5, 12 | SAFE-04 | T-32-10, T-32-11, T-32-29 | Safe-read attempt matrix, no mutation replay, and duplicate lifecycle retry rejection | unit/integration | `mix test test/paddle/http_test.exs test/paddle/subscriptions_test.exs` | ✅ | ✅ green |
| 32-W0-05 | 32-03 | 4 | SAFE-05 | T-32-07, T-32-08 | Constructor decision table and redacted failures | unit | `mix test test/paddle/client_test.exs` | ✅ | ✅ green |
| 32-W0-06 | 32-10, 32-13, 32-14 | 9, 12 | SAFE-06 | T-32-25, T-32-26, T-32-34, T-32-35 | Docs/types/runtime agreement plus fail-closed concurrent, interrupted, and bounded/full receipt acceptance | contract | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 30 -- env ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh --verify` | ✅ | ✅ green |

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

- [x] Plan 32-09 creates `test/paddle/inspection_safety_test.exs` with the shared recursive canary walker and public secret-bearing-value inventory.
- [x] Plan 32-04 extends deterministic retry adapter fixtures for method/status/transport/`Retry-After` matrices.
- [x] Plan 32-10 adds mechanical documentation assertions for removed idempotency options, retry policy, constructor examples, evidence tiers, Req/BEAM ranges, and migration notice.
- [x] Plan 32-11 runs and records `(cd "$ACCRUE_CHECKOUT/accrue" && mix test test/accrue/billing/subscription_projection_provider_test.exs)` from the owning checkout's Mix instructions.
- [x] Plans 32-01/02/11 measure focused and full suite runtimes for the sampling record; Plans 32-10/13 record the final comparison and isolated concurrency/interruption proofs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | All Phase 32 requirements have executable automated checks. Registry and sibling-checkout prerequisites fail closed in the compatibility runners. | — |

---

## Validation Sign-Off

- [ ] All tasks have stable, identity-checked automated verification; the bounded docs/spec proof and line-based selector gaps remain open.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency baseline is measured and recorded.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** partial — gap closure required

## Validation Audit 2026-09-10

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

- `mix test` passed with 272 tests and 0 failures.
- `bin/phase32_compatibility.sh --verify` passed its 72-test bounded suite, online Hex audit, no-drift gate, six-SAFE mapping, and atomic receipt publication.
- The initial `bin/phase32_contract_proof.sh --verify` exceeded its contractual 30-second wrapper on three consecutive runs. The runner duplicated both the seam reader and docs build in each isolated snapshot even though the plan requires one of each concurrently.
- The proof runner now assigns the isolated seam reader and isolated docs build to separate byte-identical snapshots. Three consecutive fresh 30-second-wrapped runs passed in 22.50s, 21.11s, and 20.89s, each preserving concurrent input equality, interruption/partial receipt rejection, compatibility receipt validation, six-SAFE mapping, tracked no-drift, and atomic contract receipt publication.

## Validation Audit 2026-09-10 (Gap Closure)

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 0 |
| Escalated | 2 |

- Plan 32-14 added stale-receipt preflight and abnormal-termination self-tests, then passed two cold bounded wrappers in 11.6s and 13.8s, the full 13-row compatibility matrix, and the double-manifest contract proof.
- Plan 32-15 added both-order duplicate `:retry` rejection coverage for pause and resume with zero adapter dispatch; 48 focused subscription tests and the 85-test HTTP/subscription/seam selection passed.
- Final verification found that the bounded SAFE-06 receipt claims docs/spec proof without executing it, so that evidence row is not fully covered.
- Final verification also proved that `file:line` selectors can pass while selecting an unintended ExUnit test; stable tags or a dedicated proof file plus selection-count validation are required.
