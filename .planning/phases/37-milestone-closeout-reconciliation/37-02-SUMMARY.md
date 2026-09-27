---
phase: 37-milestone-closeout-reconciliation
plan: 02
subsystem: operations
tags: [handoff, exact-sha, git, automated-verification]
requires:
  - phase: 37-milestone-closeout-reconciliation
    plan: 01
    provides: independently verified preservation
provides:
  - Finite snapshot/payload/evidence identity protocol with schema-v2 JTBD integration
  - Candidate and final gates using exact reviewed diffs and existing remote proof authority
  - Operator finalization instructions and deterministic recurring CI coverage
affects: [37-03, 37-04]
tech-stack:
  added: []
  patterns: [externally resolved evidence SHA, exact evidence-tail review, immutable historical snapshot]
key-files:
  created: []
  modified:
    - scripts/closeout_check.cjs
    - scripts/closeout_check.test.cjs
    - scripts/fixtures/closeout_snapshot.cjs
    - scripts/jtbd_coverage.cjs
    - scripts/jtbd_coverage.test.cjs
    - docs/worktree-operations.md
key-decisions:
  - Resolve evidence commit E from Git and compare its entire payload-to-evidence diff with a private review receipt; never embed E in its own tracked contents.
  - Keep historical snapshot S independently restorable while requiring fresh live cleanliness separately.
  - Keep the candidate at one payload commit directly on the observed main base; require live open PR and distinct current-main proof.
  - Disable Git diff autoRefreshIndex explicitly so read-only verification cannot refresh the preserved index.
requirements-completed: [ORIENT-06]
coverage:
  - id: D1
    description: A real payload-to-evidence flow reaches stable clean finalization without self-referential commits.
    requirement: ORIENT-06
    verification:
      - kind: integration
        ref: scripts/closeout_check.test.cjs#finite tracer: P to evidence commit E closes cleanly and repeated read-only checks are stable
        status: pass
      - kind: integration
        ref: scripts/jtbd_coverage.test.cjs#schema-v2 handoff validates a real finite evidence commit without stale-observation churn
        status: pass
    human_judgment: false
  - id: D2
    description: Changed code, executable evidence, stale proof, omitted review, moved PR, dirty/locked/missing trees and racing writes fail closed.
    requirement: ORIENT-06
    verification:
      - kind: integration
        ref: node --test scripts/closeout_check.test.cjs scripts/jtbd_coverage.test.cjs scripts/ci_remote_gate.test.cjs
        status: pass
    human_judgment: false
  - id: D3
    description: Existing required Node CI includes deterministic closeout regressions without a new service or job.
    requirement: ORIENT-06
    verification:
      - kind: integration
        ref: node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs
        status: pass
    human_judgment: false
completed: 2026-09-27
duration: 19min
status: complete
---

# Phase 37 Plan 02: Finite Handoff Finalization

The handoff now binds immutable observation S, hosted-tested payload P and an externally resolved evidence commit E. Repeated final checks leave Git refs, index and working files unchanged.

## Evidence

- RED commit `ebb279c`: real Git payload/evidence tracer failed with exit 2; GSD returned `RED_EVIDENCE_OK`.
- Final complete Node regression: **270 passed, 0 failed**, 81.6 seconds.
- Separate recurring workflow/history contract checks: **34 passed, 0 failed**.
- A full Git-backed schema-v2 JTBD handoff passed repeatedly, then rejected an unexpected source edit.
- Existing Node CI glob already includes these tests; no workflow job, dependency or live workstation CI requirement was added.

## Deviations and Reconciliation

- The real clean-restore test exposed Git diff's index refresh. Both observation and operator harness now set `diff.autoRefreshIndex=false`; exact original index bytes are preserved across repeated checks.
- The prerequisite schema-v1 handoff implementation/tests from Phase 36 were already present but uncommitted. Their preserved, reviewed contents were adopted together with the compatible schema-v2 extension; all existing negative fixtures still pass.
- The local SUMMARY pre-commit hook requires a clean tree. Scoped metadata commits are built in a clean temporary clone **with that hook enabled**, then fast-forwarded with an exact path index. No hook bypass, blanket staging or inherited-index adoption is used.

## Boundaries and Next Work

Fixture success does not establish real hosted or workstation closeout. ORIENT-06 remains open. Continue directly with **37-03-PLAN.md**: reviewed candidate on fresh main, local candidate checks and matching hosted artifact proof.

The review already identified main-only release metadata, newer locks, pagination specs and frozen-archive revisions. Preserve those main versions; never copy the older shared branch wholesale over main. Retain the original branch and vault for provenance.
