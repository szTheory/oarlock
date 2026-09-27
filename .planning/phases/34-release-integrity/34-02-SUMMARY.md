---
phase: 34-release-integrity
plan: 02
subsystem: release
tags: [github-actions, hex, release-please, ci-proof]
requires:
  - phase: 34-release-integrity
    provides: Exact-tag candidate packet, proof gate, locked publisher revalidation, and evidence commands
provides:
  - Automatic Release Please releases pass through the shared exact-SHA candidate proof gate
  - Automatic and recovery Hex publishers share one non-canceling queue and post-lock revalidation
  - Job-scoped GitHub permissions and final-step-only Hex credentials are contract tested
affects: [phase-34-release-integrity, release-workflows]
actuals:
  tokens: 4769
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [shared release candidate packet, queued cross-workflow publisher lock, credential staging]
key-files:
  created: [scripts/release_workflow_contract.test.cjs]
  modified: [.github/workflows/release-please.yml, .github/workflows/hex-publish.yml]
key-decisions:
  - "Release Please remains the sole automatic release author; its generated tag and version are checked before candidate preparation."
  - "Both publishing jobs use the same hex-publish queue and rerun candidate and registry checks after acquiring it."
  - "Pin recovery Node setup to the CI Node version because the referenced .nvmrc does not exist."
requirements-completed: [SHIP-01, SHIP-03, SHIP-04]
coverage:
  - id: D1
    description: Release Please outputs are validated and sent through exact-SHA proof and candidate preparation.
    requirement: SHIP-01
    verification:
      - kind: unit
        ref: scripts/release_workflow_contract.test.cjs#Release Please normalizes generated tag/version through the shared candidate gate
        status: pass
      - kind: unit
        ref: scripts/release_workflow_contract.test.cjs#automatic candidate waits a bounded time for only its generated exact SHA
        status: pass
    human_judgment: false
  - id: D2
    description: Automatic and recovery publishers share the lock and isolate Hex credentials to publishing.
    requirement: SHIP-03
    verification:
      - kind: unit
        ref: scripts/release_workflow_contract.test.cjs#publish credentials and GitHub write permission stay within their operation boundaries
        status: pass
      - kind: other
        ref: actionlint -ignore 'unexpected key "queue"' .github/workflows/release-please.yml .github/workflows/hex-publish.yml
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-09-25
status: complete
commits: 2
plan_head_before: e122d59b3006a9beb448e5559ba482e9906db4f8
---

# Phase 34 Plan 02: Automatic and Recovery Publisher Parity Summary

**Release Please now uses the recovery candidate proof contract, and both routes serialize Hex publication behind the same post-lock revalidation and scoped credential boundary.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-25T16:01:00Z
- **Completed:** 2026-09-25T16:15:14Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced the automatic workflow’s independent release checks with the shared tag/version candidate gate, bounded exact-SHA CI proof wait, and candidate artifact.
- Matched automatic publication to recovery’s `hex-publish` queued lock and post-lock registry/proof revalidation.
- Added bounded workflow contract tests for release identity, permissions, lock parity, and Hex secret isolation.
- Pinned Node in both workflows to the CI version and pinned action; recovery no longer references a nonexistent `.nvmrc`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Route Release Please through the same checked release path** - `249d5a6` (feat)
2. **Task 2: Enforce one publisher queue and least-privileged job boundaries** - `08c3616` (fix)

## Files Created/Modified

- `scripts/release_workflow_contract.test.cjs` - verifies shared candidate proof, queue parity, permissions, and credential boundaries.
- `.github/workflows/release-please.yml` - routes generated releases through candidate, publish, and evidence jobs.
- `.github/workflows/hex-publish.yml` - pins recovery Node setup and explicitly scopes candidate permissions.

## Decisions Made

- Release Please remains the sole automatic release author; generated tag/version outputs are checked against the tag-derived package identity.
- The shared publisher lock is job scoped, queued, and non-canceling; each publisher revalidates only after lock acquisition.
- Hex credentials are mapped only in the final `mix hex.publish --yes` step. GitHub write access is isolated to Release Please metadata and evidence jobs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Removed recovery workflows’ reference to missing `.nvmrc`**
- **Found during:** Task 2
- **Issue:** Recovery candidate, publisher, and evidence jobs referenced `.nvmrc`, which is absent from the repository.
- **Fix:** Pinned setup-node to the version and action SHA used by CI (`22.14.0`, v6.5.0).
- **Files modified:** `.github/workflows/hex-publish.yml`
- **Verification:** Workflow contract tests and actionlint passed.
- **Committed in:** `08c3616`

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Aligned recovery with the pinned runtime required for workflow consistency; no unrelated changes.

## Issues Encountered

- The sandbox initially denied writes to Git metadata. After the verified root and branch checks, the task-scoped staging and normal commits succeeded with the required approval; no hook was bypassed.
- `actionlint` completed successfully with its installed version. Its ignore selector permits the GitHub Actions `queue: max` property used by this project’s required workflow contract.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Automatic and recovery workflow paths now share the same candidate packet, proof contract, publisher lock, and credential boundary. A qualifying Release Please event is still required to exercise the live GitHub and Hex service path; this plan did not create or publish a release.

## Self-Check: PASSED

- Summary and all three declared plan files exist.
- Task commits `249d5a6` and `08c3616` exist in repository history.
- The plan ledger measures 2 task commits from `e122d59b3006a9beb448e5559ba482e9906db4f8`.

---
*Phase: 34-release-integrity*
*Completed: 2026-09-25*
