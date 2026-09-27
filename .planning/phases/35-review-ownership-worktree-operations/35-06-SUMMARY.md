---
phase: 35-review-ownership-worktree-operations
plan: 06
subsystem: review-operations
tags: [github, ci, candidate-provenance, triage, worktree]
requires:
  - phase: 35-review-ownership-worktree-operations
    provides: Reviewed contributor, triage, dependency, and worktree operational contracts
provides:
  - Exact-allowlist isolated candidate PR with complete hosted CI proof for its exact head
  - Phase 35 validation and verification evidence for the post-review fixes
affects: [OPS-01, OPS-02, OPS-03, OPS-04, phase-35-closeout]
actuals:
  tokens: 27730
  tasks: 2
  commits: 1
plan_head_before: 9eb5c14aa5cc362ac9262fea1044975a9505cebf
tech-stack:
  added: []
  patterns: [fresh-main independent clone, exact-path candidate allowlist, retained event-bound CI proof]
key-files:
  created:
    - .planning/phases/35-review-ownership-worktree-operations/35-06-SUMMARY.md
  modified:
    - .planning/phases/35-review-ownership-worktree-operations/35-VALIDATION.md
    - .planning/phases/35-review-ownership-worktree-operations/35-VERIFICATION.md
decisions:
  - "Publish the reviewed 16-file closure from a fresh clone at live main SHA 9eb5c14aa5cc362ac9262fea1044975a9505cebf; keep the shared checkout and index untouched."
  - "At plan completion, leave PR #8 open after exact-head CI proof pending the maintainer's disposition; later merge only after explicit authorization and green candidate CI."
metrics:
  duration: 9min
  completed: 2026-09-26
status: complete
requirements-completed: [OPS-01, OPS-02, OPS-03, OPS-04]
---

# Phase 35 Plan 06: Exact Candidate CI Gap Closure Summary

**The reviewed triage and worktree fixes were merged after the exact PR head and resulting main commit both passed the complete hosted CI contract with retained, identity-verified proof artifacts.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-26T15:24:40Z
- **Completed:** 2026-09-26T15:33:56Z
- **Tasks:** 2
- **Files modified in candidate:** 16

## Accomplishments

- Read live repository identity and confirmed `main` remained at `9eb5c14aa5cc362ac9262fea1044975a9505cebf`; created a fresh independent clone under `/private/tmp` and based the isolated branch directly on that SHA.
- Copied and committed exactly the reviewed 16-path allowlist as candidate `889d091def2dd9e62c92f1e7401ab10d387cc77e`. The staged diff check passed, the PR-template final extra blank line was trimmed as specified, and history integrity passed.
- Focused contract tests passed 32/32. `node scripts/planning_health.cjs --json` reported healthy with exit 0. The earlier feasibility rehearsal's full Node run had the known sandbox-only `ps` EPERM fixture limitation (187/188); the hosted run for this candidate passed.
- Opened [PR #8](https://github.com/szTheory/oarlock/pull/8), targeting `main`; its head equals the candidate SHA. It was open when Plan 06 completed and was later merged after the authorized exact-head CI gate passed.
- Hosted [CI run 36251913054, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36251913054) completed successfully. All eight required jobs passed. The event head is the candidate SHA; the tested SHA is GitHub's PR merge commit `6320adb14cf2e893283cfb3090866bdf0493581d`.
- The candidate gate returned `verified: true`, with retained artifact `ci-proof-36251913054-1` (ID `10909960844`, digest `sha256:d5718da4376788e031a13fdf2a4f43c54974d30771c6f69a311432485d658035`) bound to run 36251913054, attempt 1, and the exact candidate head.
- After the maintainer explicitly authorized merging when CI was green, PR #8 merged at `8905febdb55342aa07590bf6c108b079a1e12af0`. Exact-current-main run [36255786569, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36255786569) passed all eight required jobs and the `CI contract`; the required-check ruleset was present. The main proof gate returned `verified: true` for the exact merge SHA and retained artifact `ci-proof-36255786569-1` (ID `10910592092`, digest `sha256:c728e0835f02e6117f6f55f50ed7aca53e1949e04add6a86b0688dcb0b877820`).
- Updated Phase 35's hosted-CI validation entry and reran the normal Phase 35 goal verifier to close only the candidate-CI truth. The existing 13/13 UAT was not repeated. Phase 34 release-byte identity and durable-evidence work remains separate and open in `.planning/EVIDENCE.md`.

## Candidate Commit

1. **Task 1: Publish isolated reviewed payload and prove exact PR head** — `889d091` (`fix(35-06)`, full SHA `889d091def2dd9e62c92f1e7401ab10d387cc77e`).

The candidate commit count is measured as 1 from `plan_head_before` in the private clone. No shared-checkout files were staged or committed.

## Files Created or Updated

- `.planning/phases/35-review-ownership-worktree-operations/35-06-SUMMARY.md` — candidate, CI, and closure record.
- `.planning/phases/35-review-ownership-worktree-operations/35-VALIDATION.md` — updated hosted-candidate evidence only.
- `.planning/phases/35-review-ownership-worktree-operations/35-VERIFICATION.md` — refreshed goal-level verification for the candidate-CI gap.
- The isolated candidate contains exactly the 16 files named in `35-06-PLAN.md`; no planning files, workflow definitions, Phase 34 evidence, release files, or SDK runtime files entered its diff.

## Decisions Made

- Use an independent clone rooted at freshly verified live main; do not draw candidate history or staged content from the shared checkout.
- At plan completion, keep PR #8 open pending a separate maintainer disposition. The maintainer later explicitly authorized merge contingent on green exact-head CI; that condition passed, so the PR was merged and exact-main CI was verified.
- Preserve Phase 34's release evidence issue as a distinct open item and do not repeat the completed Phase 35 UAT.

## Deviations from Plan

None. The PR template received only the plan-specified final blank-line trim. The candidate identity handoff was stored in a mode-0600 private file and validated against the clone before each exact-SHA verification.

## Issues Encountered

- An initial private-clone helper invocation used an invalid path for the PR-template cleanup and stopped before staging. The path was corrected; the allowlist and diff checks then passed. The shared checkout was not changed by this issue.
- The final ordered gate's first local schema assertion expected an `artifact.attempt` property that the established gate does not emit; the run attempt is bound by the artifact name and the proof/run metadata. I corrected the assertion against the already-fetched gate result, confirmed the exact PR head and state, then removed the identity file. The hosted candidate gate was fetched once.

## User Setup Required

None.

## Next Phase Readiness

The Phase 35 exact-candidate hosted CI gap and PR disposition are closed. PR #8 merged at `8905febdb55342aa07590bf6c108b079a1e12af0`, and exact-main CI plus its retained artifact passed. Phase 34 release-byte identity and durable proof remain open in `.planning/EVIDENCE.md` and are being gap-planned separately.

## Post-Plan Merge Follow-Up

On 2026-09-26, the maintainer authorized merging PR #8 after green CI. The exact candidate check was green before merge; the resulting main commit then passed all eight required jobs, `CI contract`, and exact-SHA artifact verification. No local branch, index, or staged workspace changes were used for the merge.

---
*Phase: 35-review-ownership-worktree-operations*
*Completed: 2026-09-26*

## Self-Check: PASSED

The summary, validation, and verification files exist. Candidate commit `889d091def2dd9e62c92f1e7401ab10d387cc77e` exists in the isolated clone, is based directly on `9eb5c14aa5cc362ac9262fea1044975a9505cebf`, and has a clean 16-file diff check. Merge `8905febdb55342aa07590bf6c108b079a1e12af0` passed exact-main CI with retained proof.
