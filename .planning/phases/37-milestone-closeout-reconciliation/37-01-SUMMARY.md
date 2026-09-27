---
phase: 37-milestone-closeout-reconciliation
plan: 01
subsystem: operations
tags: [preservation, git, restore, automated-verification]
requires: []
provides:
  - Complete source and index census with independently verified private restores
  - Reviewed disposition groups covering inherited root and linked work
  - Report-only preservation gate and unsafe-input regression fixtures
affects: [37-02, 37-03, 37-04]
tech-stack:
  added: []
  patterns: [content-addressed private snapshots, independent Git restores, immutable receipt IDs]
key-files:
  created:
    - scripts/closeout_check.cjs
    - scripts/closeout_check.test.cjs
    - scripts/fixtures/closeout_snapshot.cjs
    - .planning/phases/37-milestone-closeout-reconciliation/37-CLOSEOUT.json
    - .planning/phases/37-milestone-closeout-reconciliation/37-RECONCILIATION.md
  modified: []
key-decisions:
  - Retain original index bytes and every working-file version separately; a Git bundle alone is insufficient.
  - Keep capture as an explicitly invoked external operator harness; the checker has no cleanup or capture action.
  - Retain the unique linked Phase 08 summary externally instead of replacing the frozen archive.
requirements-completed: [ORIENT-06]
coverage:
  - id: D1
    description: Both index and working states restore independently, including linked work, binary/mode changes, symlinks, deletions and nested untracked files.
    requirement: ORIENT-06
    verification:
      - kind: integration
        ref: scripts/closeout_check.test.cjs#tracer: independent restore preserves both index and worktree versions for every tree
        status: pass
    human_judgment: false
  - id: D2
    description: Omission, corruption, unsafe paths, unsupported/unreadable sources and concurrent changes fail closed.
    requirement: ORIENT-06
    verification:
      - kind: integration
        ref: node --test scripts/closeout_check.test.cjs scripts/repository_inventory.test.cjs scripts/worktree_lifecycle.test.cjs
        status: pass
    human_judgment: false
  - id: D3
    description: Actual inherited source versions have independently verified durable preservation before reconciliation.
    requirement: ORIENT-06
    verification:
      - kind: other
        ref: node scripts/closeout_check.cjs --stage preservation --manifest .planning/phases/37-milestone-closeout-reconciliation/37-CLOSEOUT.json --json (receipt wave1-preservation-v2)
        status: pass
    human_judgment: false
completed: 2026-09-27
duration: 24min
status: complete
---

# Phase 37 Plan 01: Independently Restorable Preservation

Two source trees were captured and independently restored in an operator-private durable vault. All original index selections remain intact; no source was cleaned, reset, unlocked or removed.

## Evidence

- RED: real temporary-Git restore tracer failed on preservation exit 2; GSD returned `RED_EVIDENCE_OK`.
- GREEN: preservation/inventory/lifecycle suite **45 passed, 0 failed** (32.4 seconds after final code changes).
- Live preservation: `passed`, two trees, `restored: true`, `cleanup_authorized: false`; receipt `wave1-preservation-v2`.
- Explicit comparison confirmed the inherited index unchanged after owned Phase 37 task commits.
- Commits: `76f7079` (RED/scaffold), `e2baa70` (guard); subsequent plan closeout commit includes bounded restore improvement and this receipt index.

## Reconciliation

The expanded census found 177 outstanding root entries before receipt documents: 58 local generated/cache entries are proposed for external preservation. Thirteen source entries already equal both observed main and the older candidate. Runtime and planning groups remain reviewed adoption candidates. The unique linked summary is preserved separately. PID 44442 was absent in a successful host process lookup, and its lock/summary date to 2026-04-30; fresh ownership/liveness checks remain mandatory before final disposition.

## Deviations from Plan

- Added `scripts/fixtures/closeout_snapshot.cjs` so the exact capture/restore operator harness is exercised by the real-repository tests. It has no automatic invocation and never mutates source checkouts.
- A bounded object-write timeout interrupted the first real restore. The revised harness reuses bundle objects and writes only missing staged blobs from verified files. Tests now include empty and larger binary files; the second full live capture/restore passed. Partial first-attempt material remains private and is not accepted evidence.

## Resume and Boundaries

The private vault is selected through `OARLOCK_CLOSEOUT_VAULT`; its location and receipt coordinate are retained in the operator-private resume record. Capture is a timestamped observation: later owned edits are expected to differ and require a new receipt before their disposition. Plan 02 will distinguish historical preservation from current final cleanliness.

ORIENT-06 final acceptance remains open until all four plans and phase verification pass. Continue directly with **37-02-PLAN.md**; do not repeat Phase 36 UAT or the completed preservation tracer unless its implementation changes.
