---
phase: 34-release-integrity
plan: 01
subsystem: release
tags: [github-actions, hex, mix, node, exact-sha]
requires:
  - phase: 33-deterministic-green-ci
    provides: Exact-SHA CI contract, required-job result, and retained proof artifact identity
provides:
  - Existing-tag recovery gate through Mix dry run, Hex byte verification, and published-version consumer compile
  - Step-scoped Hex credential access after exact-SHA proof and locked revalidation
  - Compact GitHub Release evidence packet with source, CI, checksum, and consumer facts
affects: [phase-34-02, release-integrity, hex-publishing]
actuals:
  tokens: 10145
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [Exact-tag authority, exact-SHA proof reuse, checksum-bound idempotent publication, step-scoped release credentials]
key-files:
  created:
    - scripts/release_integrity.cjs
    - scripts/release_integrity.test.cjs
    - scripts/release_evidence.cjs
  modified:
    - .github/workflows/hex-publish.yml
    - bin/package_smoke.sh
key-decisions:
  - "Accept one existing vX.Y.Z tag, peel it to a commit, and derive the package version from the tag."
  - "Require Phase 33's complete exact-SHA run, proof, required jobs, and retained artifact identity before the Hex environment is eligible."
  - "Treat an existing matching Hex checksum as idempotent success and stop on a conflicting checksum."
requirements-completed: [SHIP-01, SHIP-02, SHIP-03, SHIP-04]
coverage:
  - id: D1
    description: "Recovery validates a selected tag, exact-SHA Phase 33 proof, Mix package identity, and candidate package checksum before publication."
    requirement: SHIP-01
    verification:
      - kind: integration
        ref: "node --test scripts/release_integrity.test.cjs#fixture recovery and fail-closed cases"
        status: pass
    human_judgment: false
  - id: D2
    description: "Published Hex metadata and fetched bytes must match the candidate checksum, and a fresh consumer compiles the exact published version."
    requirement: SHIP-02
    verification:
      - kind: integration
        ref: "node --test scripts/release_integrity.test.cjs#served-byte mismatch case"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hex secret access is step-scoped after proof validation and revalidation under a shared queued publish lock."
    requirement: SHIP-03
    verification:
      - kind: unit
        ref: "node --test scripts/release_integrity.test.cjs#recovery workflow gates credential access and evidence on proof and registry verification"
        status: pass
    human_judgment: false
  - id: D4
    description: "Verified source, CI artifact, release checksum, fetched bytes, consumer result, and workflow run are attached as release evidence."
    requirement: SHIP-04
    verification:
      - kind: unit
        ref: "node --test scripts/release_integrity.test.cjs#evidence contains durable source, CI, checksum, Hex, consumer, workflow, and timestamp identity"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-09-25
status: complete
---

# Phase 34 Plan 01: Existing-Tag Release Recovery Summary

**A single existing version tag now drives exact-SHA CI validation, checksum-bound Hex recovery, clean consumer verification, and durable GitHub Release evidence.**

## Performance

- **Duration:** about 13 minutes
- **Started:** 2026-09-25T15:49:00Z
- **Completed:** 2026-09-25T16:02:31Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Replaced the manual tag-or-SHA and separately typed version inputs with one existing `vX.Y.Z` tag input. Recovery resolves its peeled SHA, checks out that exact source, derives the package version, and validates `oarlock` separately from Mix app `:paddle`.
- Required the Phase 33 exact-SHA CI contract, accepted run and attempt, all eight required jobs, and matching retained artifact ID and digest before the publish job can access its environment secret.
- Built and dry-run checked the candidate with Mix, serialized recovery through the `hex-publish` queue, revalidated the source and proof under the lock, reconciled existing Hex state, and scoped `HEX_API_KEY` to the final publish step.
- Added post-publish Hex metadata and tarball checksum verification, an exact-version clean Mix consumer mode, and a credential-free GitHub Release evidence writer.
- Added fixture coverage for the successful orchestration path and tag, source, package, CI proof, artifact, registry, byte-integrity, credential-boundary, and evidence cases.

## Task Commits

1. **Task 1: Trace one existing tag through recovery publication and evidence** — `a1a9ac7` (`feat(34-01): trace tag recovery through Hex evidence`)
2. **Task 2: Fail closed before recovery credential access** — `551aacc` (`fix(34-01): reject incomplete release proof before publish`)

## Files Created/Modified

- `.github/workflows/hex-publish.yml` — staged recovery, publish, and verify/evidence jobs with a shared lock and step-scoped Hex key.
- `scripts/release_integrity.cjs` — tag, proof, Mix, registry, checksum, and consumer verification flow.
- `scripts/release_integrity.test.cjs` — success-path and fail-closed fixtures.
- `scripts/release_evidence.cjs` — schema-versioned release evidence creation and attachment.
- `bin/package_smoke.sh` — supports compiling the exact published version in a clean consumer.

## Decisions Made

- Recovery is a retry for one protected existing tag; caller-provided versions and arbitrary commit SHAs are not accepted.
- A matching already-published checksum is idempotent success; a different checksum blocks and requires registry conflict resolution.
- The Hex credential is unavailable during candidate proof, build, dry run, registry checks, and evidence attachment.

## Deviations from Plan

None. The implementation follows the recovery scope for this plan; the automatic Release Please path remains for its later plan.

## Verification

- `node --test scripts/release_integrity.test.cjs scripts/ci_remote_gate.test.cjs` — passed, 18 tests.
- `node --check scripts/release_integrity.cjs` and `node --check scripts/release_evidence.cjs` — passed.
- `bash -n bin/package_smoke.sh` — passed.
- `actionlint -ignore 'unexpected key "queue"' .github/workflows/hex-publish.yml` — passed. The installed actionlint schema does not yet recognize the required GitHub concurrency `queue: max` field, so that specific schema diagnostic was ignored.
- `git diff --check` on all five plan files — passed.

## User Setup Required

Before a real publication, create the `hex-production` GitHub environment and add an expiring Hex organization API-write key as its `HEX_API_KEY` secret. Candidate and post-publication verification need no Hex secret.

## Next Phase Readiness

The manual recovery path is implemented and fixture-verified. The automatic Release Please path can now share the candidate identity and Hex publication contract in the next plan. This run did not perform a live publication or verify the GitHub environment secret.

## Self-Check: PASSED

- Confirmed the five declared plan files exist.
- Confirmed task commits `a1a9ac7` and `551aacc` exist.
- Measured two task commits from the persisted plan-head ledger; production changes are committed and the summary/state closeout is ready for its separate metadata commit.

---
*Phase: 34-release-integrity*
*Completed: 2026-09-25*
