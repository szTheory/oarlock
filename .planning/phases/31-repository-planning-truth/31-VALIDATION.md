---
phase: "31"
slug: "repository-planning-truth"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
last_audited: "2026-09-09"
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in `node:test` on Node 22.14.0, plus the existing Mix suite |
| **Config file** | None — the built-in Node test runner requires no config |
| **Quick run command** | `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs scripts/history_integrity.test.cjs scripts/ci_monitor.test.cjs scripts/prohibitions/*.test.cjs` |
| **Full phase command** | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs && node scripts/prohibitions/enforce_phase31.cjs && node scripts/planning_health.cjs --json` |
| **Repository regression command** | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs && mix test` |
| **Estimated runtime** | 3.4 seconds for 98 Phase 31 Node tests; 2.2 seconds for all six bad/clean prohibition pairs on 2026-09-09 |

---

## Sampling Rate

- **After every Wave 1 task commit:** Run `node --test scripts/repository_inventory.test.cjs`; `scripts/planning_health.test.cjs` does not exist until Wave 2.
- **After every Wave 2-5 task commit:** Run `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs`.
- **After Wave 1 merge:** Run `node --test scripts/repository_inventory.test.cjs`.
- **After Wave 2 through Wave 5 merges:** Run `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs`.
- **After Wave 6 gap-closure tasks:** Run the task's clean test command and its paired `GSD_PROHIB_SUBJECT` known-bad command; the bad subject must fail a named assertion.
- **After Wave 7 / Plan 31-09:** Run `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`, `node scripts/prohibitions/enforce_phase31.cjs`, and `node scripts/planning_health.cjs --json`.
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds for the quick suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | REPO-01 | T-31-01, T-31-02, T-31-03 | One normalized result renders identically and leaves repository state unchanged | tracer integration | `node --test --test-name-pattern="tracer|same result|read-only" scripts/repository_inventory.test.cjs` | ✅ | ✅ green |
| 31-01-02 | 01 | 1 | REPO-01 | T-31-03, T-31-04, T-31-05 | Every registered worktree and hostile edge is collected deterministically and fail-closed | integration | `node --test scripts/repository_inventory.test.cjs` | ✅ | ✅ green |
| 31-02-01 | 02 | 2 | REPO-02, REPO-04 | T-31-06, T-31-10 | Canonical conflicts block while decoy artifacts remain inert | fixture integration | `node --test --test-name-pattern="authority|phantom|conflict|committed requirements" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-02-02 | 02 | 2 | REPO-02, REPO-04 | T-31-07, T-31-08, T-31-09 | Unsupported completion, mirror ambiguity, and concurrent reads fail without mutation | CLI integration | `node --test --test-name-pattern="diagnostic|completion|state.json|read-only|concurrent|interrupted" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-03-01 | 03 | 3 | REPO-03, REPO-04 | T-31-11, T-31-12, T-31-13, T-31-14 | History and identity contradictions are diagnosed without archive mutation or inference | fixture integration | `node --test --test-name-pattern="milestone|archive|version|publication|identity|errata" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-03-02 | 03 | 3 | REPO-03, REPO-04 | T-31-11, T-31-12 | Current navigation is reconciled while immutable archives and identity distinctions are preserved | current-repository integration | `git diff --exit-code -- .planning/milestones && node --test --test-name-pattern="current repository|milestone|archive|version|publication|read-only" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-04-01 | 04 | 4 | REPO-02, REPO-04 | T-31-15, T-31-18, T-31-19 | Intermediate-symlink, unstable, and non-regular planning authorities fail incomplete without reading external content or mutating state | CLI integration | `node --test --test-name-pattern="source boundary|concurrent snapshot|read-only interrupted" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-04-02 | 04 | 4 | REPO-01, REPO-04 | T-31-15, T-31-16, T-31-17, T-31-18, T-31-19 | Unsafe ownership registries fail incomplete, disclose no rejected payload, and preserve established exact/empty/ordering behavior | CLI integration | `node --test --test-name-pattern="ownership registry|same result|edge policy|deterministic|read-only" scripts/repository_inventory.test.cjs` | ✅ | ✅ green |
| 31-05-01 | 05 | 5 | REPO-02, REPO-04 | T-31-20, T-31-24 | Completion proof comes only from one canonical phase directory and leading frontmatter; decoys and body prose remain inert | fixture integration | `node --test --test-name-pattern="canonical completion|phantom scope|completion|authority diagnostic parity|read-only interrupted" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-05-02 | 05 | 5 | REPO-03, REPO-04 | T-31-21 | Complete integer/decimal range endpoints compare exactly; substring, malformed, extra, and reversed ranges fail without history edits | unit + fixture integration | `node --test --test-name-pattern="exact phase range|milestone archive|milestone diagnostics" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-05-03 | 05 | 5 | REPO-03, REPO-04 | T-31-22, T-31-23 | Failed tag and tagged-package Git observations retain bounded cause, exit 2, and cannot become absence or downstream mismatch | fixture integration | `node --test --test-name-pattern="git identity collection|milestone identity|milestone diagnostics|current repository" scripts/planning_health.test.cjs` | ✅ | ✅ green |
| 31-06-01 | 06 | 6 | REPO-01 | T-31-06-01, T-31-06-03 | Human and JSON inventory execution preserve tracked bytes, refs, index, worktree registration, and lock metadata; a mutating subject fails the same assertion | fail-first integration | `node --test scripts/prohibitions/repository_inventory_report_only.test.cjs && if GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/repository_inventory_mutating.cjs node --test scripts/prohibitions/repository_inventory_report_only.test.cjs; then exit 1; else exit 0; fi` | ✅ | ✅ green |
| 31-06-02 | 06 | 6 | REPO-01 | T-31-06-02, T-31-06-03 | Inferred, unsupported, stale, and incomplete ownership remains unknown/incomplete in both renderers; the inferential subject fails | fail-first integration | `node --test scripts/repository_inventory.test.cjs scripts/prohibitions/repository_inventory_transparency.test.cjs && if GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/repository_inventory_inference.cjs node --test scripts/prohibitions/repository_inventory_transparency.test.cjs; then exit 1; else exit 0; fi` | ✅ | ✅ green |
| 31-07-01 | 07 | 6 | REPO-02 | T-31-07-01, T-31-07-03 | Generated, cached, archived, historical, and same-basename decoys cannot route or complete work; a permissive subject fails | fail-first CLI integration | `node --test scripts/planning_health.test.cjs scripts/prohibitions/planning_authority.test.cjs && if GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/planning_phantom_authority.cjs node --test scripts/prohibitions/planning_authority.test.cjs; then exit 1; else exit 0; fi` | ✅ | ✅ green |
| 31-07-02 | 07 | 6 | REPO-04 | T-31-07-02, T-31-07-03 | ROADMAP/STATE conflict selects no winner, preserves completion diagnostics and every planning byte, and never applies repair data; a repairing subject fails | fail-first CLI integration | `node --test scripts/planning_health.test.cjs scripts/prohibitions/planning_repair_safety.test.cjs && if GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/planning_conflict_repair.cjs node --test scripts/prohibitions/planning_repair_safety.test.cjs; then exit 1; else exit 0; fi` | ✅ | ✅ green |
| 31-08-01 | 08 | 6 | REPO-03, REPO-04 | T-31-08-01, T-31-08-03 | Explicit base/head Git-object comparison rejects committed archive or prior-ledger rewrites, accepts valid additions, and fails incomplete observation closed | fail-first integration | `node --test scripts/history_integrity.test.cjs && GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/history_additive.json node --test scripts/history_integrity.test.cjs && if GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/history_rewrite.json node --test scripts/history_integrity.test.cjs; then exit 1; else exit 0; fi` | ✅ | ✅ green |
| 31-08-02 | 08 | 6 | REPO-03, REPO-04 | T-31-08-02 | Planning milestone, tag, peeled SHA, tagged package version, and publication evidence fail independently; an inferential subject cannot mask any field | fail-first unit | `node --test scripts/prohibitions/planning_identity.test.cjs && if GSD_PROHIB_SUBJECT=scripts/fixtures/prohibitions/planning_identity_inference.cjs node --test scripts/prohibitions/planning_identity.test.cjs; then exit 1; else exit 0; fi` | ✅ | ✅ green |
| 31-09-01 | 09 | 7 | REPO-01, REPO-02, REPO-03, REPO-04 | T-31-09-01, T-31-09-02, T-31-09-03, T-31-09-05 | Required planning-truth CI lane runs the complete Node matrix, validates all six non-vacuous bad/clean pairs, guards base/head history, and runs live planning-health JSON with read-only permissions | CI contract + smoke | `node --test scripts/ci_monitor.test.cjs scripts/prohibitions/enforce_phase31.test.cjs && node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs && node scripts/prohibitions/enforce_phase31.cjs && node scripts/planning_health.cjs --json` | ✅ | ✅ green |
| 31-09-02 | 09 | 7 | REPO-01, REPO-02, REPO-03, REPO-04 | T-31-09-01, T-31-09-04 | Aggregate and exact-SHA monitor require the named planning-truth job and reject missing, failed, or wrong-SHA evidence | integration | `node --test scripts/ci_monitor.test.cjs && node -e 'const {DEFAULT_REQUIRED_JOBS}=require("./scripts/ci_monitor.cjs"); if(!DEFAULT_REQUIRED_JOBS.includes("planning truth")) process.exit(1)'` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Wave 1 creates `scripts/repository_inventory.test.cjs` before its tracer implementation and covers REPO-01, NUL/path edges, inaccessible worktrees, ownership evidence, report parity, and no-mutation sentinels.
- [x] Wave 2 creates `scripts/planning_health.test.cjs` before its authority/completion implementation and covers REPO-02/REPO-04 authority conflicts, decoy artifacts, proof links, stable diagnostics, and no-mutation sentinels.
- [x] Wave 3 extends `scripts/planning_health.test.cjs` before history implementation with REPO-03 archive/version/identity and immutable-history cases.
- [x] Wave 4 extends both test files with repository-source boundary, external-payload redaction, incomplete-exit, and no-mutation cases for REPO-01/REPO-02/REPO-04.
- [x] Wave 5 extends `scripts/planning_health.test.cjs` with canonical completion, leading-frontmatter, exact-range, and causal Git-failure cases for REPO-02/REPO-03/REPO-04.
- [x] Wave 6 adds six subject-driven prohibition checks with known-bad and clean controls for REPO-01 through REPO-04, plus a committed base/head history guard.
- [x] Wave 7 adds fail-closed descriptor enforcement, CI workflow/monitor contract tests, and a live planning-health smoke for all four requirements.
- [x] Fixture helpers are created with their owning test files; no Wave 1 command references the Wave 2 test file.

---

## Manual-Only Verifications

All phase behaviors have automated verification. A maintainer may additionally review human-readable report clarity, but that review is not the sole proof for any requirement.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter after execution evidence exists

**Approval:** validated 2026-09-09 — 40/40 phase Node tests, 48/48 repository Node tests, and 224/224 Mix tests passed. Mix verification used installed Erlang 28.4.1 with Elixir 1.19.5-otp-28 because the user-owned `.tool-versions` currently requests unavailable Erlang 28.1.

## Validation Audit 2026-09-09

| Metric | Count |
|--------|-------|
| Gaps found | 5 |
| Resolved | 5 |
| Escalated | 0 |

The five gaps were missing task-to-command mappings for Plans 31-04 and 31-05. Their behavioral tests already existed and all passed under the commands recorded above, so no additional test file was required.

## Validation Audit 2026-09-09 — Post Gap Closure

| Metric | Count |
|--------|-------|
| Requirements re-audited | 4 |
| Gap-closure tasks mapped | 8 |
| Behavioral tests passed | 98 |
| Prohibition bad/clean pairs proved | 6/6 |
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

The remaining gap was documentation coverage: Plans 31-06 through 31-09 had executable tests and commands but no entries in this per-task map. The audit ran the complete 98-test Phase 31 Node matrix, then ran `node scripts/prohibitions/enforce_phase31.cjs`, which accepted all six production controls and observed a named, non-vacuous TAP failure from every violation fixture. A live `node scripts/planning_health.cjs --json` smoke exited 0, and `node scripts/history_integrity.cjs --base 91f892b4422d37f022ecba4b6dc2b9e68c581b5a --head HEAD --json` reported healthy with no violations. CI workflow tests also proved that missing, failed, or wrong-SHA planning-truth evidence cannot satisfy the aggregate or monitor contract. No implementation or test file required modification.
