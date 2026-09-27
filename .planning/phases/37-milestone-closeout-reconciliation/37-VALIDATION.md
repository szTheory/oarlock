---
phase: "37"
slug: milestone-closeout-reconciliation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 37 — Validation Strategy

Planning contract only; no implementation or live closure result is claimed.

## Infrastructure and sampling

Node's built-in runner plus real temporary Git repositories; existing Mix and hosted eight-lane proof remain authoritative for the candidate. Quick command after each code task: `node --test scripts/closeout_check.test.cjs scripts/jtbd_coverage.test.cjs`. Full candidate command: `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs && mix test`. Run the three live closeout stages at their corresponding boundaries. New fixtures must be bounded and measured (target under 30 seconds locally); network CI waits are separate, bounded observations. Do not repeat full suites after evidence-only changes unless the allowlist check fails.

## Per-task verification map

| Task | Wave | Requirement | Threat | Automated oracle | Exists | State |
|---|---|---|---|---|---|---|
| 37-01-1 | 1 | ORIENT-06 | T-37-01/02 | `node --test scripts/closeout_check.test.cjs scripts/repository_inventory.test.cjs scripts/worktree_lifecycle.test.cjs` — real restoration and negative fixtures | New test created first in task | pending |
| 37-01-2 | 1 | ORIENT-06 | T-37-01/02 | `node scripts/closeout_check.cjs --stage preservation --manifest .planning/phases/37-milestone-closeout-reconciliation/37-CLOSEOUT.json --json` | depends on 37-01-1 | pending |
| 37-02-1 | 2 | ORIENT-06 | T-37-03/04 | `node --test scripts/closeout_check.test.cjs scripts/jtbd_coverage.test.cjs scripts/ci_remote_gate.test.cjs` — payload→evidence→stable final check | extends Wave 1 | pending |
| 37-02-2 | 2 | ORIENT-06 | T-37-03/04 | `node --test scripts/closeout_check.test.cjs scripts/ci_workflow_contract.test.cjs scripts/history_integrity.test.cjs` | existing + Wave 1 | pending |
| 37-03-1 | 3 | ORIENT-06 | T-37-05 | full Node/Mix suite at candidate; planning/JTBD/history guards and relevant seam/demo/package commands | existing | pending |
| 37-03-2 | 3 | ORIENT-06 | T-37-06 | closeout checker `--stage candidate` invoking existing hosted candidate/main gates | depends on 37-02-1 | pending |
| 37-04-1 | 4 | ORIENT-06 | T-37-07 | preservation + candidate stages and exact transaction evidence | depends on prior waves | pending |
| 37-04-2 | 4 | ORIENT-06 | T-37-07 | conditional authority decision, skipped when existing authority suffices; not UAT | external action only | conditional |
| 37-04-3 | 4 | ORIENT-06 | T-37-08 | final closeout stage + live handoff + planning health after evidence commit | depends on prior waves | pending |

## Wave 0

37-01-1 creates the first restoration tracer before the checker implementation. Existing runner and Git fixture patterns suffice; no new framework/install is required. 37-02-1 first reproduces the handoff commit loop before implementing its fix.

## Human-only verification

None. Unknown worktree ownership/disposal permission may require a concrete operator decision after all automated evidence exists. That decision cannot be replaced by a test and does not require the user to perform UAT.

## Completion sign-off

- [x] Every implementation task has an automated oracle and prerequisite tests.
- [x] No three consecutive tasks lack an automated check; conditional authority is separate.
- [x] No watch-mode or no-op commands; deterministic fixtures use the existing CI lane.
- [ ] Actual fixtures, live candidate/main proof and final clean-worktree receipt pass.
- [ ] Final summaries and validation results precede canonical verification.
- [ ] Mark validated/compliant only after execution evidence exists.
