---
phase: 31-repository-planning-truth
plan: "04"
subsystem: repository-source-trust
tags: [filesystem-containment, symlink-defense, ownership-registry, read-only, diagnostics]

requires:
  - phase: 31-repository-planning-truth
    provides: Repository inventory, planning authority collection, shared diagnostics, renderers, and exit taxonomy from Plans 01-03
provides:
  - Repository-bounded same-descriptor reader for authoritative planning and policy files
  - Fail-closed planning collection across intermediate symlinks and unstable file identities
  - Redacted incomplete ownership-registry diagnostics for unsafe source paths
affects: [31-05-completion-proof, repository-inventory, planning-health, phase-verification]

actuals:
  tokens: 5217
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns: [resolved-root containment, no-follow descriptor reads, pre-return identity validation, non-disclosing source diagnostics]

key-files:
  created: []
  modified:
    - scripts/lib/repository_truth.cjs
    - scripts/planning_health.test.cjs
    - scripts/repository_inventory.cjs
    - scripts/repository_inventory.test.cjs

key-decisions:
  - "Every authoritative repository file is accepted only after each path component, resolved containment, descriptor type, size, identity, and bytes agree on one regular in-repository file."
  - "Unsafe ownership sources produce RINV_REGISTRY_UNREADABLE with path and causal filesystem evidence only; rejected payload bytes never reach evaluation or rendering."
  - "Phase and milestone directory traversal applies the same resolved repository boundary before enumerating candidate artifacts."

patterns-established:
  - "readBoundedRepositoryFile is the single file-source trust primitive for planning documents, phase artifacts, milestone archives, mirrors, consistency checks, and ownership policy."
  - "A source-boundary failure is incomplete observation with exit 2, never an empty or ordinary policy observation."

requirements-completed: [REPO-01, REPO-02, REPO-04]

coverage:
  - id: D1
    description: "Planning authorities and ownership policy are accepted only from regular files whose resolved identity remains inside the resolved repository root."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/planning_health.test.cjs#source boundary: intermediate planning symlink exits 2 without reading external content"
        status: pass
      - kind: integration
        ref: "scripts/repository_inventory.test.cjs#ownership registry source-boundary fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Unsafe or unstable source collection produces causal incomplete diagnostics and exit 2 without disclosing rejected bytes."
    requirement: REPO-04
    verification:
      - kind: integration
        ref: "node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs (34/34 passing)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both report formats preserve one evaluated conclusion while all source checks remain report-only."
    requirement: REPO-02
    verification:
      - kind: other
        ref: "live planning-health exit 0; live inventory expected policy exit 1; milestone archive diff clean"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-09-09
status: complete
---

# Phase 31 Plan 04: Repository-Bounded Source Trust Summary

**Same-descriptor, no-follow repository reads now prevent external planning authorities and ownership registries from becoming trusted or rendered repository truth.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-09T20:42:04Z
- **Completed:** 2026-09-09T20:50:32Z
- **Tasks:** 2
- **Files modified:** 4 implementation artifacts

## Accomplishments

- Added `readBoundedRepositoryFile`, which resolves the repository root, rejects lexical escapes and every symlink/non-directory hop, enforces regular-file and size bounds, opens with no-follow semantics where available, and obtains type, identity, and bytes from one descriptor.
- Routed canonical planning documents, phase artifacts, milestone archives, mirrors, and final consistency reads through the bounded source contract; intermediate unsafe directories now yield `PAUTH_SOURCE_UNREADABLE` and exit 2.
- Anchored ownership registry loading to the collected repository root and reduced rejected-source diagnostics to repository path and causal filesystem evidence, leaving ownership unknown without copying external JSON into either renderer.
- Added adversarial direct/intermediate symlink, non-regular, oversized, replacement-race, renderer-parity, and byte-preservation coverage while retaining all prior ambiguity, empty-input, ordering, and report-only behavior.

## Task Commits

Each task followed explicit RED and GREEN gates:

1. **Task 1 RED: intermediate planning symlink specification** - `fcf1b33` (test)
2. **Task 1 GREEN: repository-bounded planning reads** - `a921db9` (feat)
3. **Task 2 RED: ownership registry source-boundary specification** - `a735963` (test)
4. **Task 2 GREEN: bounded redacted registry loading** - `32fadfb` (feat)

## Files Created/Modified

- `scripts/lib/repository_truth.cjs` - Shared bounded-file primitive plus repository-safe planning, phase, archive, mirror, and consistency collection.
- `scripts/planning_health.test.cjs` - Intermediate planning-directory symlink, external sentinel exclusion, exit taxonomy, renderer parity, and preservation proof.
- `scripts/repository_inventory.cjs` - Repository-root-anchored registry loading and redacted incomplete-source diagnostics.
- `scripts/repository_inventory.test.cjs` - Direct/intermediate symlink, non-regular, oversized, replacement-race, no-disclosure, and no-mutation regressions.

## Decisions Made

- Filesystem source trust is established from the resolved repository root through every path component and the opened descriptor; lexical containment alone is not authority.
- The descriptor identity must still match the repository path before returned bytes can participate in a snapshot, so replacements fail closed even when the descriptor itself remains readable.
- An unsafe registry is treated as absent evidence plus incomplete collection, preserving observed Git facts while preventing unsupported ownership claims.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The live repository inventory correctly remains a policy-error result because existing dirty, divergent, and locked state is still intentionally unclassified; the source-hardening changes did not mutate or conceal those facts.
- `O_NOFOLLOW` is applied where Node exposes it. The portable component walk, resolved containment checks, and opened-versus-current identity comparisons retain the fail-closed contract on platforms without that flag.

## User Setup Required

None - no dependency, service, credential, or manual filesystem change is required.

## Next Phase Readiness

- Plan 31-05 can close canonical completion-proof scoping and causal Git identity failures on top of repository-bounded inputs.
- Re-verification can now distinguish unsafe planning/registry sources as incomplete instead of accepting external bytes as repository truth.

## Self-Check: PASSED

All four modified implementation artifacts exist. Commits `fcf1b33`, `a921db9`, `a735963`, and `32fadfb` are present in Git history. The final combined Node suite passed 34/34 tests, live planning health returned healthy/0, live inventory retained its expected policy-error/1 result, and `.planning/milestones` remained byte-unchanged.

---
*Phase: 31-repository-planning-truth*
*Completed: 2026-09-09*
