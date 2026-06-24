---
phase: 27
slug: public-contract-documentation-truth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-24
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5; ExDoc locked at 0.40.1 |
| **Config file** | `test/test_helper.exs`; docs config in `mix.exs` |
| **Quick run command** | `mix test test/paddle/seam_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors && mix docs --warnings-as-errors` |
| **Estimated runtime** | Fast checks ~10-30 seconds; final full-suite sign-off ~30-60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix docs --warnings-as-errors` for docs-only edits.
- **After every seam/inventory/test edit:** Run `mix test test/paddle/seam_test.exs --warnings-as-errors`.
- **After every plan wave:** Run the relevant fast check first (`mix docs --warnings-as-errors` and/or `mix test test/paddle/seam_test.exs --warnings-as-errors`), then run `mix test --warnings-as-errors && mix docs --warnings-as-errors` as wave/final sign-off.
- **Before `/gsd:verify-work`:** Full suite must be green, with a manual read-through of README, Getting Started, seam contract, demo README, and changelog against DOCS-01..04.
- **Max feedback latency:** Keep per-edit feedback under 30 seconds where possible; the 30-60 second full-suite command is final sign-off, not the primary edit loop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | DOCS-01 | T-27-01 / T-27-03 | Public surface docs match live exported modules and arities | docs-truth/unit | `mix test test/paddle/seam_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 27-01-02 | 01 | 1 | DOCS-03 | T-27-04 | Webhook examples verify raw body before trusting parsed events | docs build/manual | `mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 27-02-01 | 02 | 1 | DOCS-02 | T-27-03 | Demo docs label MockServer proof as offline deterministic proof only | docs build/manual | `mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 27-02-02 | 02 | 1 | DOCS-04 | T-27-03 | No docs claim sandbox/provider-state proof without real Paddle run evidence | docs grep/manual | `mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 27-03-01 | 03 | 2 | DOCS-01, DOCS-04 | T-27-03 | Changelog and generated docs describe shipped seam without release/version overclaim | full suite | `mix test --warnings-as-errors && mix docs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend or add a docs-truth guard that compares live public `Paddle.*` inventory to `guides/accrue-seam.md`.
- [ ] Add a checklist or assertion for proof-boundary language so unsupported "sandbox verified" or "provider-state verified" claims are caught.
- [ ] Decide and encode the `Paddle.PortalSessions` classification in the seam/docs plan.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Task-based adopter journey is coherent across README and Getting Started | DOCS-01, DOCS-03 | Structure, wording, and app-owned boundary labels need human reading | Read both docs in order and confirm install -> explicit client -> customer/address -> transaction/checkout -> webhook verification -> subscription state -> cancel/manage flow is present without implying Phoenix/Ecto coupling |
| Demo runbook proof boundary is clear | DOCS-02, DOCS-04 | Proof language is semantic and can pass markdown builds while being misleading | Read `demo/README.md` and confirm MockServer, sandbox, and live readiness are separated using the phase proof ladder |
| Changelog avoids version/release overclaim | DOCS-01, DOCS-04 | Release narrative depends on wording and current milestone context | Read latest `CHANGELOG.md` entry and confirm it names docs truth work without implying a Hex major release or new runtime capability |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Per-edit feedback latency < 30s where possible; full-suite sign-off may run 30-60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
