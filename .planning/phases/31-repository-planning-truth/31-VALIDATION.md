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
| **Quick run command** | Wave 1: `node --test scripts/repository_inventory.test.cjs`; Waves 2-3: `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs` |
| **Full suite command** | `node --test scripts/*.test.cjs && mix test` |
| **Estimated runtime** | To be measured during Wave 0 |

---

## Sampling Rate

- **After every Wave 1 task commit:** Run `node --test scripts/repository_inventory.test.cjs`; `scripts/planning_health.test.cjs` does not exist until Wave 2.
- **After every Wave 2-3 task commit:** Run `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs`.
- **After Wave 1 merge:** Run `node --test scripts/repository_inventory.test.cjs`.
- **After Wave 2 and Wave 3 merges:** Run `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs`.
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds for the quick suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | REPO-01 | T-31-01, T-31-02, T-31-03 | One normalized result renders identically and leaves repository state unchanged | tracer integration | `node --test --test-name-pattern="tracer|same result|read-only" scripts/repository_inventory.test.cjs` | ❌ W1 | ⬜ pending |
| 31-01-02 | 01 | 1 | REPO-01 | T-31-03, T-31-04, T-31-05 | Every registered worktree and hostile edge is collected deterministically and fail-closed | integration | `node --test scripts/repository_inventory.test.cjs` | ❌ W1 | ⬜ pending |
| 31-02-01 | 02 | 2 | REPO-02, REPO-04 | T-31-06, T-31-10 | Canonical conflicts block while decoy artifacts remain inert | fixture integration | `node --test --test-name-pattern="authority|phantom|conflict|committed requirements" scripts/planning_health.test.cjs` | ❌ W2 | ⬜ pending |
| 31-02-02 | 02 | 2 | REPO-02, REPO-04 | T-31-07, T-31-08, T-31-09 | Unsupported completion, mirror ambiguity, and concurrent reads fail without mutation | CLI integration | `node --test --test-name-pattern="diagnostic|completion|state.json|read-only|concurrent|interrupted" scripts/planning_health.test.cjs` | ❌ W2 | ⬜ pending |
| 31-03-01 | 03 | 3 | REPO-03, REPO-04 | T-31-11, T-31-12, T-31-13, T-31-14 | History and identity contradictions are diagnosed without archive mutation or inference | fixture integration | `node --test --test-name-pattern="milestone|archive|version|publication|identity|errata" scripts/planning_health.test.cjs` | ❌ W3 | ⬜ pending |
| 31-03-02 | 03 | 3 | REPO-03, REPO-04 | T-31-11, T-31-12 | Current navigation is reconciled while immutable archives and identity distinctions are preserved | current-repository integration | `git diff --exit-code -- .planning/milestones && node --test --test-name-pattern="current repository|milestone|archive|version|publication|read-only" scripts/planning_health.test.cjs` | ❌ W3 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Wave 1 creates `scripts/repository_inventory.test.cjs` before its tracer implementation and covers REPO-01, NUL/path edges, inaccessible worktrees, ownership evidence, report parity, and no-mutation sentinels.
- [ ] Wave 2 creates `scripts/planning_health.test.cjs` before its authority/completion implementation and covers REPO-02/REPO-04 authority conflicts, decoy artifacts, proof links, stable diagnostics, and no-mutation sentinels.
- [ ] Wave 3 extends `scripts/planning_health.test.cjs` before history implementation with REPO-03 archive/version/identity and immutable-history cases.
- [ ] Fixture helpers are created with their owning test files; no Wave 1 command references the Wave 2 test file.

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
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence exists

**Approval:** pending
