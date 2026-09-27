---
phase: "34"
slug: "release-integrity"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in `node:test`; Elixir ExUnit for Mix build and consumer integration |
| **Config file** | No separate test framework config; Node tests under `scripts/`, Elixir tests under `test/` |
| **Quick run command** | `node --test scripts/ci_remote_gate.test.cjs scripts/ci_workflow_contract.test.cjs` |
| **Full suite command** | `node --test scripts/*.test.cjs` plus the complete hosted CI contract |
| **Estimated runtime** | Under 30 seconds for focused tests; hosted contract runtime is measured separately |

---

## Sampling Rate

- **After every task commit:** Run the focused release helper and workflow contract tests.
- **After every plan wave:** Run the Node suite and the complete hosted CI contract where the wave changes release proof behavior.
- **Before `$gsd-verify-work`:** Required local suite and hosted exact-SHA proof must be green.
- **Max feedback latency:** 30 seconds for focused local tests.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | SHIP-01, SHIP-02, SHIP-03, SHIP-04 | T-34-01, T-34-02, T-34-03, T-34-04 | Existing-tag recovery tracer crosses proof, Mix/Hex, consumer, and evidence seams | fixture-backed end-to-end | `node --test scripts/release_integrity.test.cjs` | Yes | ✅ green — included in fresh 36-test local suite |
| 34-01-02 | 01 | 1 | SHIP-01 | T-34-01 | Invalid tag or incomplete exact-SHA proof fails before credential access | unit + Phase 33 regression | `node --test scripts/release_integrity.test.cjs scripts/ci_remote_gate.test.cjs` | Yes | ✅ green — focused pass recorded in 34-01 summary; local release helper re-run 2026-09-27 |
| 34-02-01 | 02 | 2 | SHIP-01, SHIP-03 | T-34-05, T-34-06 | Release Please uses the same candidate gate and bounded exact-SHA wait | workflow contract | `node --test scripts/release_workflow_contract.test.cjs scripts/ci_workflow_contract.test.cjs` | Yes | ✅ green — workflow and CI contract evidence recorded in 34-02 summary; release contract re-run 2026-09-27 |
| 34-02-02 | 02 | 2 | SHIP-03 | T-34-06, T-34-08 | Both workflows share publisher lock and step-scoped credential | workflow contract | `node --test scripts/release_workflow_contract.test.cjs` | Yes | ✅ green — included in fresh 36-test local suite |
| 34-03-01 | 03 | 2 | SHIP-02 | T-34-09, T-34-10 | Build/API/fetched-tarball checksum and clean consumer agree | unit + integration | `node --test scripts/release_integrity.test.cjs` | Yes | ✅ green — included in fresh 36-test local suite (fixture-backed; no registry query) |
| 34-03-02 | 03 | 2 | SHIP-03 | T-34-11, T-34-12 | Ambiguous registry result cannot trigger unsafe retry | state-machine unit | `node --test scripts/release_integrity.test.cjs` | Yes | ✅ green — included in fresh 36-test local suite |
| 34-04-01 | 04 | 3 | SHIP-04 | T-34-13, T-34-14 | Strict manifest is attached only after byte and consumer proof | schema + workflow contract | `node --test scripts/release_evidence.test.cjs scripts/release_workflow_contract.test.cjs` | Yes | ✅ green — included in fresh 36-test local suite |
| 34-04-02 | 04 | 3 | SHIP-01, SHIP-04 | T-34-15, T-34-16 | Remote tag/environment policy and evidence classes are observed distinctly | unit + hosted readback | `node --test scripts/release_remote_gate.test.cjs scripts/release_evidence.test.cjs scripts/release_workflow_contract.test.cjs` | Yes | ✅ green fixture tests; hosted readback remains exact historical evidence in 34-04 summary and was not rerun |

---

## Wave 0 Requirements

- [x] `scripts/release_integrity.test.cjs` — created before tracer implementation; tag normalization, package identity, exact proof, and fail-closed outcomes.
- [x] `scripts/release_workflow_contract.test.cjs` — created in 34-02-01 before automatic workflow changes; shared lock and gate, secret ordering, permissions, and queue semantics.
- [x] `scripts/release_evidence.test.cjs` — created in 34-04-01 before schema changes; manifest fields, schema version, secret-free content, and attachment ordering.
- [x] `scripts/release_remote_gate.test.cjs` — created in 34-04-02 before remote policy logic; tag ruleset and environment readback.
- [x] `bin/package_smoke.sh` has exact-version Hex consumer mode for fetched registry bytes.
- [x] Deterministic checksum parity probe for standard Mix build, dry run, and publish build under the pinned CI toolchain is covered by `release_integrity.test.cjs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm repository tag protection and `hex-production` environment configuration | SHIP-01, SHIP-03 | GitHub repository settings and secret scope are external configuration | Read back tag protection and environment rules without exposing or printing credential values. |
| Production publication authorization | SHIP-02, SHIP-04 | A real Hex publish changes the public package registry | Use an operator-controlled release after all secret-free preflight and dry-run checks pass; capture the resulting Hex metadata and fetched package evidence. |

---

## Validation Sign-Off

- [x] All implementation tasks have automated verify; Plan 34-05/06 are human disposition and bookkeeping with verifier evidence.
- [x] Sampling continuity: each plan task has a recorded automated or explicitly external verification.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Focused feedback latency under 30 seconds (fresh suite completed in 1.03 seconds).
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** validated — local deterministic release behavior is green; exact-SHA hosted and GitHub settings readback remain historical recorded evidence; v0.1.2 limitations remain under exactly two maintainer-accepted overrides.

## Validation Audit 2026-09-27

- Ran `node --test scripts/release_integrity.test.cjs scripts/release_evidence.test.cjs scripts/release_remote_gate.test.cjs scripts/release_workflow_contract.test.cjs`: 36 tests passed, 0 failed, 0 skipped, in 1.03 seconds.
- This run exercised deterministic fixture behavior only. It did not make registry/GitHub requests, access secrets, publish, modify a release, run CI, or establish new hosted evidence.
- Plan 34-04's exact-main hosted proof and read-only policy observation remain dated evidence recorded in that summary. Plan 34-05/06's two v0.1.2 overrides remain exactly scoped: original candidate-byte identity is unproven and the historical Release has no evidence asset.
