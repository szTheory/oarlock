---
phase: 31-repository-planning-truth
plan: "02"
subsystem: planning-control-plane
tags: [planning-authority, completion-proof, read-only, diagnostics, concurrency]

requires:
  - phase: 31-repository-planning-truth
    provides: Shared diagnostics, renderers, exit taxonomy, and read-only repository inventory from Plan 01
provides:
  - Datum-specific planning authority resolution that fails closed on canonical disagreement
  - Read-only planning-health CLI with stable PAUTH, PSCOPE, PCOMP, and PMIRROR diagnostics
  - Explicit roadmap-summary-verification-requirement completion proof chain
  - Whole-snapshot identity checks that reject concurrent source changes
affects: [31-03-milestone-history, gsd-routing, phase-completion, repository-maintenance]

actuals:
  tokens: 19144
  tasks: 2
  commits: 6

tech-stack:
  added: []
  patterns: [bounded Markdown section parsing, datum-specific authority, collect-evaluate-render pipeline, pre/post file identity checks]

key-files:
  created:
    - scripts/planning_health.cjs
    - scripts/planning_health.test.cjs
  modified:
    - scripts/lib/repository_truth.cjs
    - .planning/GSD-PREFERENCES.md

key-decisions:
  - "ROADMAP supplies the active graph and STATE supplies its pointer; disagreement produces diagnostics and no selected active scope."
  - "Only checkbox requirements in the bounded current-milestone section are committed IDs; source anchors and future requirements remain inert."
  - "Completion requires explicit roadmap acceptance, every declared complete summary, substantive verification or classified caveat, and requirement/evidence linkage."
  - "The current state.json has no demonstrated repository-file consumer, so it remains non-authoritative and receives a report-only ignore/remove proposal."

patterns-established:
  - "Canonical sources are read as bounded regular in-repository files and re-statted after the whole snapshot before evaluation."
  - "Artifact presence never routes or completes work; contents must establish each required proof link."
  - "Human and JSON planning views reuse the Plan 01 diagnostic schema, renderer path, and 0/1/2 exit taxonomy."

requirements-completed: [REPO-02, REPO-04]

coverage:
  - id: D1
    description: "Maintainers and GSD workflows resolve current work only through the documented REQUIREMENTS/ROADMAP/STATE/PROJECT authority chain."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#authority and phantom scope fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Planning health blocks canonical conflicts, broken active references, unsupported completion, invalid mirrors, and inconsistent concurrent snapshots without writes."
    requirement: REPO-04
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#diagnostic, completion, state.json, read-only, concurrent, and interrupted fixtures"
        status: pass
      - kind: other
        ref: "node scripts/planning_health.cjs and --json with before/after Git manifest"
        status: pass
    human_judgment: false
  - id: D3
    description: "Human and deterministic JSON output preserve identical diagnostic codes, severities, and conclusions."
    requirement: REPO-02
    verification:
      - kind: unit
        ref: "scripts/planning_health.test.cjs#authority diagnostic parity"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-09-09
status: complete
---

# Phase 31 Plan 02: Canonical Planning Health Summary

**Read-only planning authority and completion validation with bounded parsing, stable actionable diagnostics, inert artifact decoys, and concurrent-snapshot rejection**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-09T19:07:22Z
- **Completed:** 2026-09-09T19:21:20Z
- **Tasks:** 2
- **Files modified:** 4 implementation artifacts

## Accomplishments

- Added a documented datum-by-datum authority chain and a CLI that resolves v2.2 Phase 31 only when ROADMAP and STATE agree, while ignoring archives, caches, research, summaries, and future directories for routing.
- Added distinct completion diagnostics for roadmap acceptance, each declared plan summary, substantive phase verification or classified caveat, and each requirement/evidence link.
- Added non-authoritative mirror disposition and metadata diagnostics plus final whole-snapshot identity checks that return exit 2 when a canonical source changes during collection.
- Proved human and JSON views share codes, severities, conclusions, and report-only repair proposals while repeated live runs preserve repository state.

## Task Commits

Each TDD task was committed with explicit red and green gates:

1. **Task 1 RED: authority-chain specification** - `4f26256` (test)
2. **Task 1 GREEN: canonical active-scope health path** - `f5cd8df` (feat)
3. **Task 2 RED: completion and mirror proof specification** - `110e4e2` (test)
4. **Task 2 RED expansion: whole-snapshot concurrency gate** - `77cc9b2` (test)
5. **Task 2 GREEN: completion, mirror, stale-reference, and race validation** - `2b26760` (feat)

## Files Created/Modified

- `scripts/lib/repository_truth.cjs` - Bounded planning collection, parsing, authority resolution, completion proof, mirror policy, race detection, and shared evaluation.
- `scripts/planning_health.cjs` - Thin report-only human/JSON planning-health CLI with explicit exit meanings.
- `scripts/planning_health.test.cjs` - Authority, phantom-scope, conflict, completion, mirror, concurrency, parity, and no-mutation fixture matrix.
- `.planning/GSD-PREFERENCES.md` - Shared maintainer/GSD entry command and datum-specific repository authority policy.

## Decisions Made

- Canonical disagreement blocks without choosing ROADMAP or STATE as a convenient winner; the active scope is null until the pair agrees.
- Phase artifacts are collected as bounded evidence, but only ROADMAP status and substantive proof contents can activate or complete work.
- Installed GSD query output is retained as corroboration only. Repository searches found no code path consuming `.planning/state.json` as input, despite the runtime publishing it as a disposable public contract, so the live mirror receives a warning and remains excluded from authority.
- Read consistency is checked both around individual reads and across the completed snapshot so a source changed while later files or corroboration are collected cannot yield mixed truth.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The installed GSD runtime has evolved since phase research: it now publishes a versioned `state.json` contract, but searches still found no repository-file reader. The health result therefore follows D-10's no-consumer branch and proposes an explicit ignore/remove disposition without modifying the user's current file.
- The initial race fixture checked only an individual file's read window. The fixture was tightened before the feature commit to require a final consistency pass over the whole collected snapshot.

## User Setup Required

None - no external service configuration or dependency installation is required.

## Next Phase Readiness

- Plan 31-03 can extend the same normalized snapshot and diagnostic families with immutable milestone-history navigation and additive errata checks.
- The live planning-health command is healthy with one non-blocking `PMIRROR_NO_CONSUMER` warning; disposition remains a separate reviewed action.

## Self-Check: PASSED

Both new files and both modified implementation/policy files exist. Commits `4f26256`, `f5cd8df`, `110e4e2`, `77cc9b2`, and `2b26760` are present in Git history, and the final verification passed 13/13 planning-health tests plus 14/14 repository-inventory regression tests.

---
*Phase: 31-repository-planning-truth*
*Completed: 2026-09-09*
