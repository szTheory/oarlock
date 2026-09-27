# Phase 37: Milestone Closeout Reconciliation — Context

Captured: 2026-09-27. Source: the maintainer requested a concrete plan to close the remaining gap before auditing v2.2, authorized following recommendations, and required automated verification and a specific forward-moving GSD command.

## Boundary

Close the existing ORIENT-06 / FLOW-CLOSEOUT operational gap. Phase 36's three delivered plans and eight automated UAT passes remain complete. Phase 37 owns final operational acceptance of ORIENT-06; it does not add a thirtieth requirement or restart Phases 31–36.

<decisions>

### Locked decisions

- **D-01:** Preserve every staged, unstaged, untracked, deleted, and linked-worktree contribution before reconciliation. Classify content using Git objects, phase artifacts, candidate comparisons, and ownership evidence. Unknown authorship is not a prohibition on read-only investigation or safe copying; it is not permission to discard work either.
- **D-02:** Automate repeatable verification. Use real temporary repositories, negative fixtures, and the existing required Node CI lane. Do not add a new live-machine CI dependency or ask for repeat UAT.
- **D-03:** Prepare a bounded, reviewed candidate from explicit paths/content on a fresh main base. Reuse existing reviewed content by equality/ancestry; never infer that older hosted proof covers changed bytes. Keep candidate event SHA, tested merge SHA, document commit, and current-main proof distinct.
- **D-04:** Closeout requires an honest clean state for the shared checkout and every linked tree. A clean isolated clone alone does not discharge this. No blanket add/reset/clean, force push, fabricated owner, or unlocking based on a PID alone. Preserve unknown work and ask only for an irreducible, concrete disposition after all safe preparation is finished.
- **D-05:** Make handoff finalization finite: bind an immutable observed snapshot to a tested payload, verify any later evidence-only commit by exact allowlist/diff, and perform a final read-only live check. Never require a tracked file to embed its own future commit SHA or predict a future clean state.
- **D-06:** Keep v0.1.2 accepted historical exceptions and all future candidate/conditional JTBD scope unchanged. Phase 37 does not merge release PRs, publish a package, archive the milestone, or turn optional debt into new required scope.
- **D-07:** Persist resume receipts after each wave. Completed plans are skipped on resume; refresh only facts invalidated by changed bytes, SHAs, or worktree state. Audit only after the closeout guard passes. Exact next command after planning: `$gsd-execute-phase 37`.

### Implementation discretion

- Four serial plans separate preservation, the handoff identity fix, candidate proof, and final disposition/evidence.
- Extend existing collectors and proof readers. A small read-only closeout checker may compose them; do not build an automated deletion service or a general backup platform.
- Safe preservation and candidate preparation may proceed while an ownership question is unresolved. The unresolved action remains a named gate, never a blanket stop on independent tasks.
- Existing authorization is reused. This planning request does not resolve an unknown concurrent owner's rights or grant blanket disposal/merge permission.

</decisions>

## Starting evidence (historical observations, refresh during execution)

- Root HEAD `7ec75b0590d659a21c96e87e352f67798beb2c2d`; 116 default porcelain entries before Phase 37 planning, including mixed index/worktree versions. Directory aggregation means this is not an all-files count.
- One dirty locked linked tree, branch `worktree-agent-ae2a0ae67dfb5008f`, HEAD `56296a20841fc22a3bc232923d0e4589cfd9c4cb`; untracked `08-01-SUMMARY.md`. Lock names PID 44442. Earlier process inspection was denied, which proves neither liveness nor abandonment.
- PR #21 candidate `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994`, base `8905febdb55342aa07590bf6c108b079a1e12af0`, retained hosted run `36282241303/1`, artifact `10918748960`. These identify old evidence, not the next candidate.
- `.planning/v2.2-MILESTONE-AUDIT.md` has one operational gap; its 109-path count predates later bookkeeping. No new audit was run to create this phase.

## Deferred

SEED-001 README work, future provider surfaces, historical release reconstruction, speculative CI optimization, and unrelated open PR implementation remain outside this phase.
