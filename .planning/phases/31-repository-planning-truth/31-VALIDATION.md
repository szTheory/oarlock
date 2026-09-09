---
phase: "31"
slug: "repository-planning-truth"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-09"
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in `node:test` on Node 22.14.0, plus the existing Mix suite |
| **Config file** | None — the built-in Node test runner requires no config |
| **Quick run command** | `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs` |
| **Full suite command** | `node --test scripts/*.test.cjs && mix test` |
| **Estimated runtime** | To be measured during Wave 0 |

---

## Sampling Rate

- **After every task commit:** Run `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs`
- **After every plan wave:** Run `node --test scripts/*.test.cjs && mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds for the quick suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | REPO-01 | T-31-01 | Inventory remains read-only across registered worktrees | integration | `node --test scripts/repository_inventory.test.cjs` | ❌ W0 | ⬜ pending |
| 31-02-01 | 02 | 2 | REPO-02 | Decoy artifacts cannot activate work | fixture integration | `node --test scripts/planning_health.test.cjs --test-name-pattern="authority|phantom|conflict"` | ❌ W0 | ⬜ pending |
| 31-02-02 | 02 | 2 | REPO-03 | Historical contradictions are reported without rewriting archives | fixture integration | `node --test scripts/planning_health.test.cjs --test-name-pattern="milestone|archive|version"` | ❌ W0 | ⬜ pending |
| 31-02-03 | 02 | 2 | REPO-04 | Unsupported completion claims fail with stable diagnostics | CLI integration | `node --test scripts/planning_health.test.cjs --test-name-pattern="diagnostic|completion|read-only"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/repository_inventory.test.cjs` — REPO-01, NUL/path edges, inaccessible worktrees, ownership evidence, report parity, and no-mutation sentinels
- [ ] `scripts/planning_health.test.cjs` — REPO-02 through REPO-04, authority conflicts, decoy artifacts, archive/version invariants, stable diagnostics, and no-mutation sentinels
- [ ] Shared fixture helpers for temporary Git repositories and planning trees

---

## Manual-Only Verifications

All phase behaviors have automated verification. A maintainer may additionally review human-readable report clarity, but that review is not the sole proof for any requirement.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
