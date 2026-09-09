---
phase: 31-repository-planning-truth
plan: "05"
subsystem: planning-proof-and-history
tags: [canonical-phase, frontmatter, phase-range, git-identity, incomplete-diagnostics]

requires:
  - phase: 31-repository-planning-truth
    provides: Repository-bounded planning snapshot and source trust from Plan 31-04
provides:
  - Canonical active-phase directory resolution for completion proof
  - Leading-frontmatter-only summary and verification status validation
  - Exact normalized milestone phase-range comparison
  - Failure-aware Git tag and tagged-package identity collection
affects: [planning-health, milestone-history, completion-verification, phase-31-verification]

actuals:
  tokens: 8244
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns: [canonical path construction, leading YAML metadata, exact endpoint normalization, structured subprocess failure]

key-files:
  created: []
  modified:
    - scripts/lib/repository_truth.cjs
    - scripts/planning_health.test.cjs

key-decisions:
  - "Completion proof is accepted only from exact paths beneath one resolved active-phase directory and from scalar status fields in leading YAML frontmatter."
  - "Milestone ranges compare complete normalized endpoint identities while retaining the documented parenthetical count annotation shape."
  - "Git observation failure is incomplete evidence with bounded command/status/cause details, never successful absence or an inferred identity mismatch."

patterns-established:
  - "resolveCanonicalPhaseDirectory is the authority boundary for active plan, summary, and verification artifacts."
  - "Collection errors suppress downstream conclusions whose observation premise did not succeed."

requirements-completed: [REPO-02, REPO-03, REPO-04]

coverage:
  - id: D1
    description: "Same-basename decoys, body-only status text, and ambiguous active-phase directories cannot establish completion proof."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#canonical completion"
        status: pass
    human_judgment: false
  - id: D2
    description: "Milestone history compares exact integer or decimal phase-range endpoints and preserves frozen archives."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#exact phase range"
        status: pass
    human_judgment: false
  - id: D3
    description: "Failed Git ref or tagged-file observation produces causal incomplete diagnostics and exit 2 without misleading identity conclusions."
    requirement: REPO-04
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#git identity collection"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-09-09
status: complete
---

# Phase 31 Plan 05: Canonical Completion and Failure-Aware History Summary

**Planning health now accepts completion and milestone identity only from canonical structured evidence, while failed Git observations preserve their cause and fail closed with exit 2.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-09T21:00:43Z
- **Completed:** 2026-09-09T21:08:31Z
- **Tasks:** 3
- **Files modified:** 2 implementation artifacts

## Accomplishments

- Added `resolveCanonicalPhaseDirectory` and routed active plan, summary, verification, and stale-summary lookup through exact paths beneath the one bounded active phase directory.
- Replaced whole-document completion regexes with leading YAML frontmatter parsing, leaving same-basename decoys and Markdown body status text inert.
- Added `parsePhaseRange` for exact integer and decimal endpoint comparison, rejecting substring, malformed, reversed, prefixed, and arbitrary suffixed values.
- Refined tag and tagged `mix.exs` collection into identities plus structured collection errors, retaining bounded command, status, stderr/cause evidence and suppressing unsupported downstream mismatch conclusions.
- Removed the unused hard-coded `drift-guard.phase-status 31` corroboration query.

## Task Commits

Each task followed explicit RED and GREEN gates:

1. **Task 1 RED: canonical completion adversarial specification** - `e6f443f` (test)
2. **Task 1 GREEN: canonical phase and leading-frontmatter proof** - `9b04a64` (feat)
3. **Task 2 RED: exact phase-range specification** - `7de5b2f` (test)
4. **Task 2 GREEN: normalized endpoint comparison** - `76a1575` (feat)
5. **Task 3 RED: failed Git identity observation specification** - `ad86cf8` (test)
6. **Task 3 GREEN: structured incomplete Git collection** - `2f77566` (feat)

## Files Created/Modified

- `scripts/lib/repository_truth.cjs` - Canonical phase resolution, strict completion metadata, exact range parsing, structured Git collection failures, and premise-aware history diagnostics.
- `scripts/planning_health.test.cjs` - Decoy/body/ambiguity, exact-range, failed-ref, failed-tagged-file, parity, exit-2, and repository regression coverage.

## Decisions Made

- Completion proof uses constructed canonical repository-relative paths; basename coincidence never supplies authority.
- Only `status`, `result`, or `verdict` scalars from a leading delimited frontmatter block can establish completion.
- Parenthetical phase/plan count annotations already used by the mutable milestone index are accepted as the documented field shape, but arbitrary prefix/suffix text and extra range material remain invalid.
- Git command failures carry their causal observation record into the shared collection-error path, and evaluators do not invent absence or mismatch claims from the failed premise.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved documented milestone range annotations**
- **Found during:** Task 3 full current-repository regression
- **Issue:** The first exact-range implementation rejected the repository's existing `8-13 (6 phases, 21 plans)` field shape even though its complete endpoint pair was exact.
- **Fix:** Accepted one bounded parenthetical count annotation after the complete range while continuing to reject arbitrary suffixes, prefixes, extra ranges, malformed endpoints, and reversals; added direct parser coverage.
- **Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
- **Commit:** `2f77566`

## Issues Encountered

- None remaining. The live planning-health command returns healthy/0 with four warnings and eight informational records representing explicit historical caveats and unknown publication evidence.

## User Setup Required

None - no dependency, service, credential, ref update, or planning-history migration is required.

## Next Phase Readiness

- Phase 31's six reproduced repository/planning truth blockers are covered across Plans 31-04 and 31-05.
- REPO-02, REPO-03, and REPO-04 now have executable adversarial proof for canonical completion, exact history, causal incomplete collection, renderer parity, and non-mutation.

## Self-Check: PASSED

Both modified implementation artifacts and this summary exist. Commits `e6f443f`, `9b04a64`, `7de5b2f`, `76a1575`, `ad86cf8`, and `2f77566` are present in Git history. The combined Node suite passed 40/40 tests, live planning health returned healthy/0 with no errors, and `.planning/milestones`, `.planning/MILESTONES.md`, and `.planning/EVIDENCE.md` remained unchanged by implementation.

---
*Phase: 31-repository-planning-truth*
*Completed: 2026-09-09*
