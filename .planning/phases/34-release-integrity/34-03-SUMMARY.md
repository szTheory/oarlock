---
phase: 34-release-integrity
plan: 03
subsystem: release
tags: [hex, package-integrity, checksum, consumer-proof]
requires:
  - phase: 34-release-integrity
    provides: Candidate packet and post-lock publisher revalidation
provides:
  - Deterministic Mix package checksum parity before publication and locked revalidation
  - Strict Hex API, fetched tarball, package metadata, and exact-version consumer verification
  - Checksum-based reconciliation for matching, absent, conflicting, and unobserved publish outcomes
affects: [phase-34-release-integrity, hex-publishing, package-smoke]
actuals:
  tokens: 9497
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [independent package checksum proof, bounded Hex observation, exact-version published consumer]
key-files:
  created: []
  modified: [scripts/release_integrity.cjs, scripts/release_integrity.test.cjs, bin/package_smoke.sh]
key-decisions:
  - "Require the Hex 2.5.1 reported package checksum, independent tarball SHA-256, Hex API checksum, and fetched bytes to match exactly."
  - "Treat malformed or unavailable Hex observations as unobserved; only repeated bounded 404 responses permit an absent state."
  - "Retry an ambiguous publish once only after matching absent state and complete tag/SHA/version/checksum revalidation."
requirements-completed: [SHIP-02, SHIP-03]
coverage:
  - id: D1
    description: Mix build output, independent tarball SHA-256, API checksum, fetched bytes, and package identity form one checked chain.
    requirement: SHIP-02
    verification:
      - kind: unit
        ref: scripts/release_integrity.test.cjs#pinned Mix build exposes an outer checksum equal to an independent SHA-256
        status: pass
      - kind: unit
        ref: scripts/release_integrity.test.cjs#validates API checksum, fetched tarball bytes, and unpacked package identity as one chain
        status: pass
    human_judgment: true
    rationale: The first qualifying live release must confirm the exact Hex API metadata and served tarball chain; no release was manufactured for this plan.
  - id: D2
    description: Fresh published-version consumer and ambiguous-publish fixtures fail closed on conflicting or unknown state.
    requirement: SHIP-03
    verification:
      - kind: unit
        ref: scripts/release_integrity.test.cjs#after an unclear publish, matching checksum is idempotent and absent retries only after revalidation
        status: pass
      - kind: integration
        ref: bash bin/package_smoke.sh
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-09-25
status: complete
commits: 2
plan_head_before: a4083b5ce22260af524249931b2a3ae421633264
---

# Phase 34 Plan 03: Hex Package Identity and Safe Retry Summary

**The release path now checks deterministic Hex package bytes against API and repository observations, compiles a clean exact-version consumer, and refuses unsafe publish retries.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-09-25T16:15:00Z
- **Completed:** 2026-09-25T16:34:02Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Built the package with `mix hex.build --output`, compared Hex’s reported outer checksum to an independent SHA-256, validated embedded package name/version, and repeated the build after dry run to prove deterministic output.
- Rebuilt and rechecked the checksum under the publisher lock; publication preflight now distinguishes a matching release, confirmed absence, conflict, and unobserved registry state.
- After publication, verification now requires exact API version/checksum, fetched repository tarball checksum, embedded package identity, and successful fresh consumer compilation before evidence is recorded.
- Updated published consumer mode to fetch and hash the served package and depend on exactly `{:paddle, "== X.Y.Z", hex: :oarlock}`. The existing local unpacked artifact mode remains available.
- Added fixtures for checksum mismatches, malformed responses, transient absence, ambiguous upload results, retry revalidation, and sanitized incident links.

## Task Commits

1. **Task 1: Prove candidate-to-Hex checksum agreement and consumer installability** - `eec0cba` (feat)
2. **Task 2: Reconcile ambiguous Hex outcomes without changing published bytes** - `5a73b3e` (fix)

## Files Created/Modified

- `scripts/release_integrity.cjs` - builds and validates the candidate, checks served release bytes, polls registry state, and gates retries on exact identity.
- `scripts/release_integrity.test.cjs` - covers package checksum and state-transition behavior.
- `bin/package_smoke.sh` - validates the fetched published archive and compiles a fresh exact-version consumer while preserving local mode.

## Decisions Made

- Hex 2.5.1 reports the outer tarball SHA-256 as lowercase hexadecimal; execution confirmed it exactly matches an independent SHA-256 of `mix hex.build --output` bytes.
- A malformed or unavailable registry response is `unobserved`. A release is `absent` only after four bounded 404 observations.
- An ambiguous publish that remains absent can be retried once only after full identity revalidation and a second absent observation. A matching checksum is idempotent success; conflict or unobserved state never uploads.
- The temporary consumer copies project `.tool-versions` and uses a private temporary `HEX_HOME` so its compile is reproducible and does not write the operator’s shared Hex cache.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Made temporary consumer use the pinned toolchain and isolated Hex cache**
- **Found during:** Task 2 verification
- **Issue:** The local package smoke path failed after entering its temporary directory because it had no `.tool-versions`; a subsequent attempt also hit a denied write to the operator’s shared Hex cache.
- **Fix:** Copy the project `.tool-versions` into the consumer and point `HEX_HOME` at the temporary work directory.
- **Files modified:** `bin/package_smoke.sh`, `scripts/release_integrity.test.cjs`
- **Verification:** `bash bin/package_smoke.sh` passed, including dependency fetch and compile with warnings as errors.
- **Committed in:** `5a73b3e`

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Improved reproducibility and kept consumer verification within its temporary workspace.

## Issues Encountered

- The first local smoke run could not resolve the Mix version after changing into the temporary consumer. The second reached Hex but its global cache write was denied. Both were resolved by the temporary workspace changes above.
- Verified on the workflow’s pinned Hex 2.5.1 in an isolated `MIX_HOME`: the reported outer checksum and independent file SHA-256 were identical (`687234c4bf4728dbca5710f2a169366766339940a7df99c196b679572966bf29`) for the local 0.1.1 build. This validates checksum representation, not a live publication.

## Deferred Issues

- The first qualifying live release must still record its exact Hex API release metadata and served tarball checksum. No release was created or published for this plan; local fixtures and build bytes are not a substitute for that hosted observation.

## User Setup Required

None beyond the `hex-production` environment secret already described in Plan 34-01.

## Next Phase Readiness

The package byte chain, exact-version consumer, and retry decisions are fixture-verified, including with Hex 2.5.1 for local checksum parity. Live Hex package verification remains contingent on the next qualifying release.

## Self-Check: PASSED

- Summary and all three declared plan files exist.
- Task commits `eec0cba` and `5a73b3e` exist in repository history.
- The persisted plan ledger measures 2 task commits from `a4083b5ce22260af524249931b2a3ae421633264`.

---
*Phase: 34-release-integrity*
*Completed: 2026-09-25*
