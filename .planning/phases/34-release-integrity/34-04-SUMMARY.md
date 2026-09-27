---
phase: 34-release-integrity
plan: 04
subsystem: release-integrity
tags: [github-actions, release-evidence, rulesets, hex]
requires:
  - phase: 33-deterministic-green-ci
    provides: Exact-SHA CI proof, retained run attempt and artifact identity
  - phase: 34-release-integrity
    provides: Shared release candidate, publisher lock, Hex byte and consumer verification
provides:
  - Strict schema-v1 release evidence serializer with retained accepted attempts
  - Read-only GitHub release-tag ruleset and environment policy gate
  - Phase 34 evidence ledger with exact-main proof and honest live-publication status
affects: [release-workflows, release-operations, evidence-ledger]
actuals:
  tokens: 8394
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [Allowlisted release manifest, Read-only effective GitHub policy readback]
key-files:
  created:
    - scripts/release_evidence.test.cjs
    - scripts/release_remote_gate.cjs
    - scripts/release_remote_gate.test.cjs
  modified:
    - scripts/release_evidence.cjs
    - scripts/release_workflow_contract.test.cjs
    - .planning/EVIDENCE.md
key-decisions:
  - "Schema v1 contains only release identity, run/artifact references, checksums, verification statuses, timestamps, accepted attempts, and caveats."
  - "Remote acceptance reads ruleset and environment metadata only; policy settings and secret values are never mutated or queried."
  - "No actual Hex publication was observed, so live package proof remains pending."
patterns-established:
  - "GitHub Release evidence is built only after fetched package bytes and the clean consumer compile pass."
  - "A retry preserves compatible accepted attempt identities and fails closed on contradictory source or checksum fields."
requirements-completed: [SHIP-01, SHIP-02, SHIP-03, SHIP-04]
coverage:
  - id: D1
    description: "Serialize exact source, CI, package, and consumer proof into an allowlisted versioned GitHub Release manifest."
    requirement: SHIP-04
    verification:
      - kind: unit
        ref: "node --test scripts/release_evidence.test.cjs scripts/release_workflow_contract.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Read back active v-tag protection and the configured production environment without secret access."
    requirement: SHIP-01
    verification:
      - kind: integration
        ref: "node scripts/release_remote_gate.cjs szTheory/oarlock"
        status: pass
    human_judgment: false
  - id: D3
    description: "Record exact-main hosted proof and identify actual Hex publication proof as pending."
    requirement: SHIP-02
    verification:
      - kind: integration
        ref: "node scripts/ci_remote_gate.cjs main --json"
        status: pass
    human_judgment: true
    rationale: "No Phase 34 Hex publication occurred; only an operator-controlled release can establish live registry and served-package proof."
duration: 3h 29m
completed: 2026-09-25
status: complete
plan_head_before: 1c4d27d1781df7e66a8f5e698991fecc05b89aa9
commits: 2
---

# Phase 34 Plan 04: Durable Release Evidence Summary

**Release evidence now binds a protected version tag and exact CI artifact to verified Hex bytes, while remote policy readback records hosted acceptance without implying a live publication.**

## Performance

- **Duration:** 3h 29m, including the human GitHub configuration checkpoint
- **Started:** 2026-09-25T16:37:00Z
- **Completed:** 2026-09-25T20:06:01Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Replaced the permissive release evidence writer with schema-v1 allowlist validation for source tag/SHA, Phase 33 run/attempt/artifact identity, release workflow identity, dry run, candidate and Hex checksums, fetched bytes, clean-consumer result, timestamps, and caveats.
- Recovery preserves compatible earlier accepted attempts and refuses to replace evidence when the prior release identity or checksum contradicts the newly verified package. GitHub Release creation and upload remain after package and consumer verification in a `contents: write` job without the Hex key.
- Added a read-only remote policy gate. Live readback confirmed active ruleset `24017258` (“Protect release tags”) targets tags, includes `refs/tags/v*`, prevents update and deletion, and has no bypass actors. Environment `hex-production` exists as ID `22773295054`; both release workflows reference it. The environment currently has zero protection rules, and the plan only requires existence and workflow binding.
- Recorded exact remote-main proof separately from any release-tag identity: SHA `1f2b3aa19ddfe7d8f6aaa0683df73af76abb06c5`, CI run `36085849017` attempt 1, retained artifact `10843607663`, digest `sha256:8b29ee8031b401d9da35eb5b99e370d1bf8ac47637415208ea818aa30dfbebc4` ([run](https://github.com/szTheory/oarlock/actions/runs/36085849017)). The Phase 34 live Hex publication and corresponding Release asset remain pending.

## Task Commits

Each task was committed atomically:

1. **Task 1: Attach strict versioned release evidence** — `baf8d0b` (`feat`)
2. **Task 2: Read back release-tag policy and record hosted proof** — `730baf1` (`feat`)

**Plan metadata:** pending closeout.

## Files Created/Modified

- `scripts/release_evidence.cjs` — strict manifest construction, validation, merge, and GitHub Release attachment.
- `scripts/release_evidence.test.cjs` — positive, malformed, sensitive-field, and prior-attempt coverage.
- `scripts/release_workflow_contract.test.cjs` — ordering and credential boundary assertions for both release paths.
- `scripts/release_remote_gate.cjs` — read-only ruleset and environment metadata observation.
- `scripts/release_remote_gate.test.cjs` — effective/missing policy, API failure, and no-mutation coverage.
- `.planning/EVIDENCE.md` — SHIP-01 through SHIP-04 proof classes and acceptance pointers.

## Decisions Made

- Use a schema-versioned allowlist and compact IDs/URLs/digests; raw logs, credentials, tarball bytes, and customer data are excluded.
- Treat GitHub as the authority for effective tag and environment policy, and Hex as the authority for published bytes.
- Keep live publication pending until a real package passes registry checksum, fetched-tarball, and clean-consumer verification.

## Deviations from Plan

None. Existing workflow steps already attach evidence after byte and consumer verification, with the Hex key limited to the publish step; workflow contract tests now assert those boundaries and ordering.

## Verification

- `node --test scripts/release_evidence.test.cjs scripts/release_workflow_contract.test.cjs` — passed.
- `node --test scripts/release_remote_gate.test.cjs scripts/release_evidence.test.cjs scripts/release_workflow_contract.test.cjs` — passed (15 tests).
- `node --test scripts/ci_workflow_contract.test.cjs scripts/ci_proof.test.cjs scripts/ci_monitor.test.cjs` — passed (28 tests).
- `node scripts/release_remote_gate.cjs szTheory/oarlock` — passed live readback for the tag ruleset and environment; no secret values were queried.
- `node scripts/ci_remote_gate.cjs main --json` — passed for the exact remote-main SHA and retained proof artifact listed above.

## User Setup Required

The repository admin completed the GitHub ruleset and environment setup. Readback confirms the required tag protections and environment exist. No Hex key was created, stored, or used.

## Next Phase Readiness

Phase 34’s release flow and hosted policy have an explicit local and remote acceptance contract. Live Hex publication proof remains pending by design until an operator-controlled release is performed and its registry metadata, served tarball, clean consumer, and GitHub Release evidence asset are observed.

## Self-Check: PASSED

- Task files and tests exist at the listed paths.
- Task commits `baf8d0b` and `730baf1` exist in Git history.
- Plan commit count is measured as 2 from plan base `1c4d27d1781df7e66a8f5e698991fecc05b89aa9` to `HEAD` before metadata closeout.

---
*Phase: 34-release-integrity*
*Completed: 2026-09-25*
