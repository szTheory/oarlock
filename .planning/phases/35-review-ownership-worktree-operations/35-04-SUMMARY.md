---
phase: 35-review-ownership-worktree-operations
plan: 04
subsystem: dependency-operations
tags: [dependabot, mix, github-actions, exact-sha, security-updates]
requires:
  - phase: 33-deterministic-green-ci
    provides: Exact-SHA CI contract and retained candidate proof.
provides:
  - Separate bounded Dependabot streams for root Mix, demo Mix, and GitHub Actions.
  - Fail-closed configuration and exact-SHA CI contract tests.
  - Maintainer instructions for reviewing dependency proposals and recording evidence.
affects: [35-review-ownership-worktree-operations, dependency-maintenance]
actuals:
  tokens: 2545
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 774f0d56a38e8ced4558ff1f24a816a1e67d314d
tech-stack:
  added: []
  patterns: [constrained static YAML contract, exact-SHA hosted evidence]
key-files:
  created:
    - .github/dependabot.yml
    - scripts/dependabot_contract.test.cjs
    - docs/dependency-updates.md
  modified: []
key-decisions:
  - "Keep root Mix, demo Mix, and Actions updates in separate streams; group only routine minor/patch Mix updates within each project."
  - "Enable repository vulnerability alerts and automated security fixes only after fresh admin authorization checks and verify both settings by readback."
patterns-established:
  - "Dependency update contracts assert separate lockfile boundaries, isolated security groups, major-version review, and no automatic merge path."
requirements-completed: [OPS-04]
coverage:
  - id: D1
    description: "Separate reviewable root, demo, and Actions update streams route through the complete exact-SHA CI contract."
    requirement: OPS-04
    verification:
      - kind: unit
        ref: scripts/dependabot_contract.test.cjs
        status: pass
      - kind: integration
        ref: "node --test scripts/dependabot_contract.test.cjs scripts/ci_workflow_contract.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Repository vulnerability alerts and automated security fixes are enabled for prompt security proposals."
    requirement: OPS-04
    verification:
      - kind: integration
        ref: "GET /repos/szTheory/oarlock/vulnerability-alerts (HTTP 204); GET /repos/szTheory/oarlock/automated-security-fixes (enabled=true)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Maintainers have exact-SHA and evidence recording instructions for dependency proposals."
    requirement: OPS-04
    verification:
      - kind: unit
        ref: scripts/dependabot_contract.test.cjs#maintainer procedure describes exact-SHA review and observed evidence
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-09-26
status: complete
---

# Phase 35 Plan 04: Reviewable Dependency Updates Summary

**Dependabot now separates root Mix, demo Mix, and GitHub Actions proposals, with exact-SHA CI evidence and security updates enabled.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-26T13:11:29Z
- **Completed:** 2026-09-26T13:17:21Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added weekly, bounded root Mix, demo Mix, and Actions update entries. Mix minor/patch groups remain within their lockfile boundaries; majors and Actions changes stay individually reviewable.
- Added static contract tests for grouping boundaries, major/security separation, no auto-merge, exact-SHA proof, every aggregate CI job, and `mix hex.audit`.
- Documented how maintainers inspect grouped diffs, confirm the current candidate SHA and hosted run, check relevant compatibility/security jobs, and record only observed evidence.
- Enabled vulnerability alerts and automated security fixes after confirming repository identity, admin permission, and the authenticated owner's `repo` authorization. Readbacks passed: alerts HTTP 204 and security fixes `enabled: true`.

## Task Commits

1. **Task 1: Configure separate reviewable update streams** - `add4adf` (chore)
2. **Task 2: Bind update review to exact-SHA compatibility and security proof** - `50ee0f2` (docs)

The metadata commit was not made: GSD's commit guard refused to commit a summary while unrelated shared-tree changes remain unstaged/untracked. The summary and tracking updates are preserved in the working tree/index for the orchestrator; the guard was not bypassed.

## Files Created/Modified

- `.github/dependabot.yml` - Separate weekly proposals with bounded routine and security groups.
- `scripts/dependabot_contract.test.cjs` - Configuration and aggregate-CI contract assertions.
- `docs/dependency-updates.md` - Maintainer review and evidence procedure, including live setting readbacks.

## Decisions Made

- Do not use Mix dependency-type filters because root/demo dependency categories do not reliably express this SDK's optional-integration boundary.
- Keep GitHub Actions updates ungrouped and prohibit automatic merging.
- No `.github/workflows/ci.yml` change was needed; the existing pull-request and exact-SHA aggregate already require all relevant jobs, including Hex audit.

## Deviations from Plan

None - plan executed as written. The contract test also verifies its contributor-facing review guide.

## Issues Encountered

- The first sandboxed GSD commit could not create `.git/index.lock`; rerunning the same path-scoped GSD commit with the authorized Git write escalation succeeded. It committed only the declared Plan 35-04 paths.
- An initial docs-contract assertion used wording not yet present in the guide; the contract expectation was aligned with the actual instruction and both suites passed afterward.
- GSD refused the final metadata commit because the shared tree contains unrelated unstaged/untracked work. Its refusal is preserved; no unrelated work was staged or committed.

## User Setup Required

None - hosted settings were enabled and verified during execution.

## Next Phase Readiness

- Plan 35-04 is complete. Plan 35-05 remains the next Phase 35 plan and owns the live maintainer triage checkpoint; this plan sent no messages and changed no issues or pull requests.

## Self-Check: PASSED

- All four plan artifacts exist.
- Task commits `add4adf` and `50ee0f2` are present in Git history.
- The planned files contain no TODO/FIXME/placeholder stubs.

---
*Phase: 35-review-ownership-worktree-operations*
*Completed: 2026-09-26*
