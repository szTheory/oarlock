---
phase: 28
slug: ci-demo-and-package-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-24
---

# Phase 28 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix for root library and demo |
| **Config file** | `test/test_helper.exs`, `demo/test/test_helper.exs`, `demo/config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/paddle/mock_server_test.exs` |
| **Full suite command** | `mix test`; `mix dialyzer`; `cd demo && mix test`; package smoke command from this phase's plan |
| **Estimated runtime** | ~180-360 seconds locally, longer on cold CI |

---

## Sampling Rate

- **After every task commit:** Run the most specific command for the touched surface: root tests, demo tests with PostgreSQL available, or package smoke.
- **After every plan wave:** Run root `mix test`, root `mix dialyzer`, demo `mix test` with PostgreSQL, and package smoke.
- **Before `/gsd:verify-work`:** CI-equivalent root, demo, package, and optional-dependency proof commands must be green.
- **Max feedback latency:** 10 minutes for full phase gate; under 2 minutes for focused task checks where possible.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 1 | PROOF-04 | T-28-01 | `Paddle.MockServer` compiles at the root boundary and positive MockServer behavior works with optional HTTP deps available | compile/unit | `mix compile --warnings-as-errors`; `MIX_ENV=test mix test test/paddle/mock_server_test.exs` | partial | pending |
| 28-01-02 | 01 | 1 | PROOF-04 | T-28-02 | Public docs state MockServer is an optional fixture and not live provider-state proof | docs/unit | `mix test test/paddle/seam_test.exs` | yes | pending |
| 28-02-01 | 02 | 2 | PROOF-03, PROOF-04 | T-28-07 | Package contents compile from an unpacked Hex artifact in a fresh consumer without optional `plug` or `bandit` | smoke | `bin/package_smoke.sh`; `grep -v '^#' bin/package_smoke.sh | grep -q 'mix hex.build --unpack'`; `grep -v '^#' bin/package_smoke.sh | grep -q 'OarlockConsumerProof.UsePaddle'` | no | pending |
| 28-02-02 | 02 | 2 | PROOF-01, PROOF-02, PROOF-03, PROOF-04 | T-28-04, T-28-05, T-28-06, T-28-08 | CI keeps root release gates and adds separate demo PostgreSQL, package smoke, and optional-deps jobs without live Paddle secrets | CI/static | `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/ci.yml')"`; workflow greps for `demo-postgres:`, `package-smoke:`, `optional-deps:`, `DB_HOST: localhost`, `bin/package_smoke.sh`, and `test/paddle/mock_server_test.exs` | partial | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `.github/workflows/ci.yml` demo job with PostgreSQL service.
- [ ] Package smoke job or script, likely `bin/package_smoke.sh`.
- [ ] Optional-dependency negative proof after the `Paddle.MockServer` compile boundary is fixed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub hosted runner service behavior | PROOF-02 | Local machines may not match Actions service-container networking | Inspect the CI run for the demo job and confirm PostgreSQL health checks pass before `cd demo && mix test`. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
