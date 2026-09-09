---
phase: 31-repository-planning-truth
plan: "03"
subsystem: planning-history
tags: [milestones, git-tags, package-identity, immutable-archives, diagnostics]

requires:
  - phase: 31-repository-planning-truth
    provides: Shared planning snapshot, actionable diagnostics, renderers, and authority chain from Plans 01-02
provides:
  - Complete shipped-milestone navigation with immutable archive links and explicit pre-archive handling
  - Separate planning milestone, local Git tag, peeled SHA, declared package version, and publication status identities
  - PHIST, PARCHIVE, and PIDENT diagnostics with additive correction guidance
affects: [phase-34-release-integrity, milestone-close, planning-health, repository-maintenance]

actuals:
  tokens: 9055
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns: [bounded archive collection, argument-array Git identity reads, additive evidence corrections, immutable history snapshots]

key-files:
  created: []
  modified:
    - scripts/lib/repository_truth.cjs
    - scripts/planning_health.test.cjs
    - .planning/MILESTONES.md
    - .planning/EVIDENCE.md

key-decisions:
  - "Milestone, tag, peeled source SHA, tagged mix.exs package declaration, and publication status remain separately sourced identities; unknown is never inferred."
  - "Frozen archive contradictions produce warnings and dated EVIDENCE corrections, while only the mutable MILESTONES index is repaired."
  - "v1.0 remains an explicit pre-archive exception and v1.5 retains an explicit missing-local-tag caveat."

patterns-established:
  - "History validation normalizes repository-bounded links but never follows targets outside the repository."
  - "Every history diagnostic uses the shared actionable schema and both output formats reuse the same ordered result."

requirements-completed: [REPO-03, REPO-04]

coverage:
  - id: D1
    description: "Every shipped milestone in the current ROADMAP has a truthful current-index entry with immutable archive navigation or an explicit pre-archive exception."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#current repository milestone history is reconciled and archive bytes stay immutable"
        status: pass
      - kind: other
        ref: "git diff --exit-code -- .planning/milestones"
        status: pass
    human_judgment: false
  - id: D2
    description: "Planning milestone, Git tag, source SHA, declared package version, and publication status remain separate and preserve unknown values."
    requirement: REPO-03
    verification:
      - kind: unit
        ref: "scripts/planning_health.test.cjs#milestone identity: tag, peeled SHA, package version, and publication remain separate"
        status: pass
      - kind: integration
        ref: "node scripts/planning_health.cjs --json (exit 0; zero history errors)"
        status: pass
    human_judgment: false
  - id: D3
    description: "History contradictions emit stable actionable diagnostics with identical human/JSON conclusions and additive repair proposals."
    requirement: REPO-04
    verification:
      - kind: unit
        ref: "scripts/planning_health.test.cjs#milestone archive and milestone diagnostics fixture matrix"
        status: pass
      - kind: other
        ref: "node --test scripts/planning_health.test.cjs (17/17 passing)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-09-09
status: complete
---

# Phase 31 Plan 03: Immutable Milestone History Summary

**Read-only milestone-history validation with repaired current navigation, byte-preserved archives, separate release identities, and dated additive evidence corrections**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-09T19:28:05Z
- **Completed:** 2026-09-09T19:39:28Z
- **Tasks:** 2
- **Files modified:** 4 implementation and planning artifacts

## Accomplishments

- Added stable PHIST, PARCHIVE, and PIDENT checks for missing entries, phase/status contradictions, broken/mutable/escaped links, correction coverage, and independently sourced release identity fields.
- Restored v1.2 and v1.4 to the current shipped index, redirected v1.5 to immutable archives, and labeled all shipped records without implying package publication from planning or Git evidence.
- Appended dated v1.2, v1.4, and v1.5 correction evidence while leaving every `.planning/milestones/` byte unchanged.
- Proved human and JSON output parity, read-only behavior, archive immutability, and a live planning-health result with zero history errors.

## Task Commits

Each TDD task was committed with explicit red and green gates:

1. **Task 1 RED: milestone history specifications** - `fc4cacd` (test)
2. **Task 1 GREEN: history and identity validators** - `231b897` (feat)
3. **Task 2 RED: live reconciliation and archive immutability proof** - `a181a9d` (test)
4. **Task 2 GREEN: mutable index and additive evidence reconciliation** - `8cf8bf1` (feat)

## Files Created/Modified

- `scripts/lib/repository_truth.cjs` - Bounded archive and local-tag collection, tagged package parsing, history validators, and shared diagnostic integration.
- `scripts/planning_health.test.cjs` - Identity, archive-edge, correction, parity, live-repository, and archive-byte fixture proof.
- `.planning/MILESTONES.md` - Complete shipped navigation and independently labeled release identity fields.
- `.planning/EVIDENCE.md` - Dated correction ledger and explicit milestone identity proof rules.

## Decisions Made

- Local refs are observed through `git for-each-ref` and tagged `mix.exs` through `git show`; health tooling never fetches, creates, or changes refs.
- Publication status remains unknown without independent registry evidence, including for v2.1 where the planning/tag identity is `v2.1` and the declared package version is `0.1.1`.
- Contradictory frozen requirement headings remain visible as owned warnings; corrections live in the current EVIDENCE ledger and current navigation only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved record boundaries in local tag identity collection**
- **Found during:** Task 2 (live repository reconciliation)
- **Issue:** Git's formatted ref records include newline separators; treating the whole output as only NUL tokens could prefix later tag names with a newline and associate fields incorrectly.
- **Fix:** Parse each formatted record first, then split its NUL-delimited fields and use the peeled SHA when present.
- **Files modified:** `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`
- **Verification:** Identity fixture plus the live current-repository smoke test passed.
- **Committed in:** `8cf8bf1`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fix was required for correct identity reporting and remained within the planned tag collector.

## Issues Encountered

- The repository has no local `v1.5` tag and the v1.1 tag lacks a parseable `@version` declaration. Both remain explicit unknowns rather than inferred identities.
- The v1.2 and v1.5 frozen requirements snapshots retain incomplete wording. Planning health reports these as non-blocking, owned contradictions backed by dated correction rows.

## User Setup Required

None - no external service configuration or dependency installation is required.

## Next Phase Readiness

- Phase 32 can begin from a complete, navigable shipped-history index with no REPO-03 error.
- Phase 34 can reuse the independently sourced milestone/tag/SHA/package/publication model when enforcing release identity.
- Intentional warnings remain visible for frozen archive wording, the absent local v1.5 tag, and the non-authoritative `state.json` mirror.

## Self-Check: PASSED

All four modified artifacts and this summary exist, and commits `fc4cacd`, `231b897`, `a181a9d`, and `8cf8bf1` are present in Git history.

---
*Phase: 31-repository-planning-truth*
*Completed: 2026-09-09*
