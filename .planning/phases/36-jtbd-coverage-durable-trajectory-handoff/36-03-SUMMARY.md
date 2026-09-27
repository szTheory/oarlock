---
phase: 36-jtbd-coverage-durable-trajectory-handoff
plan: 03
subsystem: planning
tags: [jtbd, handoff, exact-sha, hosted-ci]
requires:
  - phase: 36-jtbd-coverage-durable-trajectory-handoff
    plan: 02
    provides: cross-link and append-only history validation
provides:
  - dated v2.2 handoff with fresh shared and linked worktree observations
  - deterministic handoff validation for proof identity and honest closeout state
  - open Phase 36 candidate PR #21 with verified exact-event-head and tested-checkout CI proof
affects: [v2.2 closeout, future discovery]
actuals:
  tokens: 18000
  tasks: 2
  commits: 1
plan_head_before: 7ec75b0590d659a21c96e87e352f67798beb2c2d
tech-stack:
  added: []
  patterns: [exact-SHA artifact identity, read-only worktree inventory, blocked-clean-close reporting]
key-files:
  created: []
  modified:
    - .planning/v2.2-HANDOFF.md
    - scripts/jtbd_coverage.cjs
    - scripts/jtbd_coverage.test.cjs
    - .github/workflows/ci.yml
    - scripts/ci_workflow_contract.test.cjs
key-decisions:
  - Preserve the dirty shared checkout and locked linked worktree; report them as closeout blockers.
  - Record PR event head and CI merge-checkout SHA separately; require the retained artifact and run identity to match the exact candidate event head.
  - Keep the review candidate as one commit directly on observed main so the handoff checker can verify its base.
patterns-established:
  - A current hosted proof records candidate event head, run and attempt, artifact ID and digest, and the actual CI checkout SHA separately.
  - A handoff can be evidence-complete while milestone clean-close remains blocked by observed dirty or locked worktrees.
requirements-completed: [ORIENT-02, ORIENT-03, ORIENT-04, ORIENT-05, ORIENT-06]
coverage:
  - id: D1
    description: The handoff checker rejects missing or mismatched proof and false clean-close claims.
    requirement: ORIENT-06
    verification:
      - kind: unit
        ref: scripts/jtbd_coverage.test.cjs#handoff check rejects wrong SHA and historical-only proof but accepts exact current proof
        status: pass
      - kind: other
        ref: node --test scripts/ci_workflow_contract.test.cjs scripts/jtbd_coverage.test.cjs scripts/history_integrity.test.cjs
        status: pass
    human_judgment: false
  - id: D2
    description: The dated handoff records the exact candidate proof and current repository/worktree blockers.
    requirement: ORIENT-06
    verification:
      - kind: e2e
        ref: node scripts/ci_remote_gate.cjs candidate --sha c5bcc7b331640c1d1d9dc4e5289a634e5cc21994 --repo szTheory/oarlock --json
        status: pass
      - kind: other
        ref: node scripts/jtbd_coverage.cjs --check-handoff --json (incomplete only for observed dirty/locked worktrees)
        status: pass
    human_judgment: false
  - id: D3
    description: Future discovery and downstream Accrue ownership claims stay bounded by dated source evidence and explicit promotion gates.
    requirement: ORIENT-02
    verification:
      - kind: unit
        ref: scripts/jtbd_coverage.test.cjs#future discovery and Accrue source ownership judgments stay bounded until promotion evidence exists
        status: pass
      - kind: unit
        ref: scripts/ci_workflow_contract.test.cjs#integration seam, demo E2E, and package smoke stay in required CI
        status: pass
    human_judgment: false
duration: 126min
completed: 2026-09-26
status: complete
---

# Phase 36 Plan 03: Exact-SHA Handoff Summary

**The v2.2 handoff records verified exact-head CI proof for PR #21 and preserves dirty or locked work as explicit closeout blockers.**

## Performance

  - **Duration:** 3h 20m
- **Started:** 2026-09-26T21:21:08Z
- **Completed:** 2026-09-27T00:42:13Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a read-only handoff contract check for candidate SHA, PR, hosted run, retained artifact, worktree inventory, caveat, and candidate authority.
- Refreshed `.planning/v2.2-HANDOFF.md` from a new repository/worktree inventory and recorded candidate `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994`, PR #21, run 36282241303 attempt 1, and artifact 10918748960 with its digest and URL.
- Proved all eight required hosted CI lanes for the exact PR event head. The proof separately records the PR merge checkout SHA `c130cd6c731abc04dd312efc355d79eb5a48e5ab`.
- Preserved the shared checkout's 103 dirty paths and the locked linked worktree. The handoff checker returns `incomplete` only for those expected conditions; it does not claim a clean close.
- Kept future discovery records in Future Requirements and retained the v0.1.2 evidence caveat.

## Task Commits

The reviewed Phase 36 payload is represented by one direct-base commit so the candidate's parent equals the observed main base:

1. **Tasks 1–2: handoff contract, bounded candidate, and proof target** — `c5bcc7b` (`feat(36): add JTBD coverage and handoff evidence`), in the isolated candidate clone and PR #21.

No commit was made in the shared checkout; its pre-existing dirty state was preserved.

## Files Created/Modified

- `.planning/v2.2-HANDOFF.md` — dated machine-readable handoff with exact proof coordinates and observed blockers.
- `scripts/jtbd_coverage.cjs` — deterministic read-only handoff contract validation.
- `scripts/jtbd_coverage.test.cjs` — fixtures for proof identity and clean-close rejection.
- `.github/workflows/ci.yml` and `scripts/ci_workflow_contract.test.cjs` — current and legacy Hex archive discovery for the retained proof toolchain.

## Decisions Made

- Keep PR #21 open and unmerged for review.
- Report exact CI event head separately from GitHub's PR merge commit used as the test checkout.
- Keep milestone closeout blocked while the active checkout is dirty and linked worktree ownership is unresolved.

## Deviations from Plan

### Auto-fixed Issues

**1. Hex archive layout differed on the hosted runner**
- **Found during:** Task 2 (hosted proof)
- **Issue:** setup-beam installed Hex as a versioned directory (`hex-2.5.1`), while the proof step searched only for legacy `.ez` files.
- **Fix:** Accept both `hex-X.Y.Z/` directories and `hex-X.Y.Z.ez` files; pin Rebar 3.25.1 explicitly.
- **Files modified:** `.github/workflows/ci.yml`, `scripts/ci_workflow_contract.test.cjs`
- **Verification:** Both layout fixtures passed; the final full Node regression passed 213/213; hosted run 36282241303 passed all required lanes and retained the proof artifact.
- **Committed in:** `c5bcc7b`.

**2. Rebuilt the review candidate to satisfy the direct-base handoff invariant**
- **Found during:** Task 2 (live handoff verification)
- **Issue:** The hosted-proof retry branch had accumulated multiple recovery commits, while the handoff checker requires candidate `HEAD^` to equal observed `main`.
- **Fix:** Recreated the same ten reviewed paths as a single commit on the live main base, opened PR #19, then closed the superseded PR #18. No force push or merge was used.
- **Files modified:** Candidate branch identity and temporary receipt; no additional Phase 36 payload paths.
- **Verification:** Candidate parent equals base; diff paths match the reviewed manifest; PR #19 is open at the exact candidate SHA; remote CI and artifact gate pass.
- **Committed in:** `8e282ec`.

**3. Rebuilt the proof candidate after clarifying the PR merge checkout identity**
- **Found during:** Final exact-proof readback
- **Issue:** GitHub's PR event head is the candidate commit while the CI proof's `testedSha` is the temporary merge checkout SHA. The first implementation treated these identities as equal.
- **Fix:** Store and verify `hosted_proof.tested_sha` separately while retaining candidate SHA binding for PR head, run event head, artifact head, and payload.
- **Verification:** Fresh direct-base candidate `c5bcc7b` passed all 213 Node tests, 275 ExUnit tests, all eight hosted lanes, and the live artifact gate; event head `c5bcc7b` and tested checkout `c130cd6` are both recorded.
- **Committed in:** `c5bcc7b`.

**4. Preserved the shared checkout instead of committing planning metadata**
- **Found during:** Task 2 handoff refresh
- **Issue:** The shared checkout contains extensive mixed dirty state, and the linked worktree is locked with unreadable owner evidence.
- **Fix:** Updated the local handoff and plan security/summary artifacts without staging or committing the shared checkout. Recorded `handoff_document_sha: unknown` and left clean-close blocked.
- **Files modified:** `.planning/v2.2-HANDOFF.md`, `36-03-SUMMARY.md`, `36-SECURITY.md`
- **Verification:** Fresh inventory shows the dirty and locked states; `--check-handoff` reports only those expected incomplete conditions.
- **Committed in:** none; preserved in the shared working tree.

---

**Total deviations:** 4 auto-fixed (hosted toolchain compatibility, direct-base candidate reconstruction, PR merge-SHA identity correction, shared-tree commit preservation).
**Impact on plan:** The exact tested payload and retained artifact are verified on PR #21. The milestone handoff remains explicitly blocked from clean close until local worktree ownership/state is resolved and the refreshed shared document is published.

## Issues Encountered

- Earlier hosted attempts failed during Rebar discovery and Hex version extraction. Pinning Rebar and accepting the runner's versioned Hex directory resolved the final proof failure.
- The first successful CI proof was attached to a candidate with a multi-commit retry history. Rebuilding the same payload as a direct-base commit produced the final proof target.

## User Setup Required

None.

## Next Phase Readiness

Phase 36's reviewed payload has exact-SHA hosted proof and remains available in open PR #21 at `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994`. PRs #19 and #20 were closed as superseded after that proof passed. On 2026-09-27, source/ownership judgments were shifted into regression contracts; the current shared checkout passes 250 Node tests, the Accrue seam (14 tests), demo billing E2E (2 tests), and package smoke. The project's GSD preference now defaults to automated UAT wherever a reproducible oracle exists. Human review remains only for externally controlled state such as review/publication and unresolved worktree ownership. The new local edits do not have hosted exact-SHA proof yet. Clean closeout remains blocked by 104 dirty paths in the shared checkout, a locked linked worktree with unreadable owner evidence, and the uncommitted refreshed handoff document. Preserve those states.

## Automation-First Verification Follow-Up (2026-09-27)

- Added a source/ownership contract test for discovery and downstream Accrue claims, including their evidence bounds and promotion gates.
- Added a CI wiring contract that protects the integration seam, demo E2E scenarios, and package smoke in the required pipeline.
- Made the repository-inventory process probe deterministic in tests so sandbox process visibility no longer makes the Node suite environment-dependent.
- Recorded automation-first verification as a durable GSD project default in `.planning/GSD-PREFERENCES.md` and removed the generic human confirmation checkpoint from the completed Phase 36 UAT.
- Validation passed locally: Node 250/250, seam 14/14, demo E2E 2/2, and package smoke. Existing hosted proof still identifies candidate `c5bcc7b`; it does not include these uncommitted follow-up edits.

---
*Phase: 36-jtbd-coverage-durable-trajectory-handoff*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Summary exists at the expected phase path.
- Candidate commit `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994` exists in the isolated candidate clone and PR #21.
- Candidate remains a single direct-base commit; shared checkout state remains uncommitted and preserved.
