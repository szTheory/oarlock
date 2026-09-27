---
phase: 34-release-integrity
verified: 2026-09-27T13:55:05Z
status: passed
score: 9/9 must-haves verified
covered_files:
  - .github/workflows/hex-publish.yml
  - .github/workflows/release-please.yml
  - .planning/EVIDENCE.md
  - .planning/phases/34-release-integrity/34-01-PLAN.md
  - .planning/phases/34-release-integrity/34-01-SUMMARY.md
  - .planning/phases/34-release-integrity/34-02-PLAN.md
  - .planning/phases/34-release-integrity/34-02-SUMMARY.md
  - .planning/phases/34-release-integrity/34-03-PLAN.md
  - .planning/phases/34-release-integrity/34-03-SUMMARY.md
  - .planning/phases/34-release-integrity/34-04-PLAN.md
  - .planning/phases/34-release-integrity/34-04-SUMMARY.md
  - .planning/phases/34-release-integrity/34-05-PLAN.md
  - .planning/phases/34-release-integrity/34-05-SUMMARY.md
  - .planning/phases/34-release-integrity/34-06-PLAN.md
  - .planning/phases/34-release-integrity/34-06-SUMMARY.md
  - bin/package_smoke.sh
  - scripts/release_evidence.cjs
  - scripts/release_evidence.test.cjs
  - scripts/release_integrity.cjs
  - scripts/release_integrity.test.cjs
  - scripts/release_remote_gate.cjs
  - scripts/release_remote_gate.test.cjs
  - scripts/release_workflow_contract.test.cjs
covered_digest: "v1:sha256:a4ba8e6b5f77746ebd5b27057f30d91461bbc8c2076d53dd8c4d5452a532b1e1"
behavior_unverified: 0
overrides_applied: 2
overrides:
  - must_have: "The v0.1.2 release proves agreement among its source SHA, tag, package version, candidate artifact, and published package bytes."
    reason: "The original v0.1.2 candidate artifact is unavailable; candidate-to-served-byte identity remains unproven, so this maintainer accepts the pre-control exception without claiming byte verification."
    accepted_by: "project maintainer"
    accepted_at: "2026-09-26T17:45:16Z"
  - must_have: "The published v0.1.2 release has a versioned release-evidence.json asset created after byte and clean-consumer verification."
    reason: "The original v0.1.2 historical workflow evidence is unavailable; the release still has no evidence asset, so this maintainer accepts the pre-control exception without claiming durable evidence."
    accepted_by: "project maintainer"
    accepted_at: "2026-09-26T17:45:16Z"
re_verification:
  previous_status: gaps_found
  previous_score: 7/9
  gaps_closed:
    - "The v0.1.2 release proves agreement among its source SHA, tag, package version, candidate artifact, and published package bytes. (accepted as a scoped historical exception; byte identity remains unproven)"
    - "The published v0.1.2 release has a versioned release-evidence.json asset created after byte and clean-consumer verification. (accepted as a scoped historical exception; no asset exists)"
  gaps_remaining: []
  regressions: []
---

# Phase 34: Release Integrity Verification Report

**Phase Goal:** Release stewards can publish only the exact, fully proven package they intended, through either the automatic or recovery path.
**Verified:** 2026-09-27T13:55:05Z
**Status:** passed
**Re-verification:** Yes — after the two gap-closure plans and explicit maintainer disposition.

## 2026-09-27 fingerprint-boundary correction

Phase 37 planning changed only ORIENT-06 routing in the shared requirements file. All four SHIP requirement statements, completion markers and Phase 34 traceability rows were compared with their pre-planning text and are unchanged. Per GSD-PREFERENCES.md, the shared requirement-status ledger is excluded from this phase's whole-file fingerprint; the requirement crosswalk below and phase plans retain its acceptance meaning. The canonical digest was recomputed over the remaining release-owned implementation/evidence. This is a fingerprint-scope correction, not a new release proof, repeated UAT or a change to either accepted historical exception. The verification timestamp and retained test/proof results remain historical.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Automatic and recovery publishing stop before release-secret access when the exact candidate SHA lacks the complete accepted CI contract. | ✓ VERIFIED | Both current workflows put candidate preparation and exact-SHA proof checks before the `publish` job, then revalidate under the shared lock before the sole step-scoped `HEX_API_KEY` mapping. Focused workflow and release tests are present and contain assertions for this boundary. Previously recorded test results were not rerun, per Plan 34-06. |
| 2 | The v0.1.2 release proves agreement among its source SHA, tag, package version, candidate artifact, and published package bytes. | PASSED (override) | The accepted A disposition is scoped to this historical v0.1.2 truth. Its original candidate artifact is unavailable; the tagged rebuild checksum differs from the Hex API/fetched-tarball checksum. Candidate-to-served-byte identity remains unproven. Accepted by project maintainer at 2026-09-26T17:45:16Z. |
| 3 | Concurrent publication attempts serialize safely, use least privilege, and recovery cannot bypass the automatic path's quality or identity gate. | ✓ VERIFIED | Both workflows use the same non-canceling `hex-publish` queue, revalidate after acquiring it, scope the Hex key to the publish step, and place GitHub evidence writes in a separate credential-free job. Prior workflow contract tests remain present with explicit parity, permission, and secret-boundary assertions. |
| 4 | The published v0.1.2 release has a versioned release-evidence.json asset created after byte and clean-consumer verification. | PASSED (override) | The GitHub Release still has no `release-evidence.json`; its historical workflow did not run candidate-byte/consumer verification or evidence attachment. The accepted A disposition is scoped to this historical truth and does not establish durable evidence. Accepted by project maintainer at 2026-09-26T17:45:16Z. |
| 5 | Release Please and manual recovery normalize their inputs through the same exact-SHA release gate. | ✓ VERIFIED | Current automatic candidate setup validates Release Please tag/version and invokes `release_integrity.cjs prepare`; recovery also invokes that shared command. Both jobs consume the same candidate outputs and common publish/revalidate contract. |
| 6 | Checksum conflicts and ambiguous publish outcomes cannot silently overwrite or advance a published Hex version. | ✓ VERIFIED | Current implementation classifies matching, absent, conflicting, and unobserved registry states; retries require absent state and identity revalidation. Regression sanity checks found these branches and corresponding test cases in source. No tests were rerun. |
| 7 | Effective tag policy and the production environment are observed remotely without reading secrets. | ✓ VERIFIED | `.planning/EVIDENCE.md` records the read-only policy observation, ruleset, environment binding, and exact-main proof. The current remote-gate implementation reads GitHub metadata and workflow source; it has no secret read or settings write path. No remote query was made during this verification. |
| 8 | The evidence ledger distinguishes fixture, hosted CI, and actual publication proof without overstating what v0.1.2 proves. | ✓ VERIFIED | The ledger records the v0.1.2 tag/SHA, Hex API and fetched-byte checksum, different tagged rebuild checksum, absent Release asset, and the maintainer-accepted pre-control exception. It explicitly says identity remains unproven and no later release can prove it retroactively. |
| 9 | Blocked releases report expected/observed identity and a safe next step. | ✓ VERIFIED | `release_integrity.cjs` rejection paths include expected/observed values and actionable next steps; remote-policy rejection results do the same. Prior focused tests remain present for identity mismatches and sanitized diagnostics. |

**Score:** 9/9 truths verified, including 2 PASSED (override) items (0 present, behavior-unverified).

The roadmap's four success criteria are covered by truths 1–4. The two overrides are limited to the historical v0.1.2 claims; current release controls remain strict for future releases.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scripts/release_integrity.cjs` and `scripts/release_integrity.test.cjs` | Candidate, proof, package, registry, and retry gates | ✓ VERIFIED | Both substantive files remain present (367 and 350 lines). Source includes exact candidate proof validation, independent candidate checksum checks, served Hex checksum checks, registry-state handling, and retry revalidation. Tests contain fixture cases for mismatches, conflicts, unobserved states, and retries. |
| `scripts/release_evidence.cjs` and `scripts/release_evidence.test.cjs` | Strict versioned evidence manifest and rejection rules | ✓ VERIFIED | Both substantive files remain present (178 and 80 lines). The builder enforces matching candidate/API/fetched checksums and a schema-v1 allowlist; tests cover missing/malformed/mismatched proof and contradictory prior evidence. |
| `scripts/release_remote_gate.cjs` and its tests | Read-only remote tag/environment policy check | ✓ VERIFIED | Both substantive files remain present (101 and 71 lines). Source checks active tag protections, environment existence, and both workflow bindings; its observer uses metadata reads. |
| `.github/workflows/release-please.yml` and `.github/workflows/hex-publish.yml` | Automatic and recovery paths share exact checks and safe publication boundaries | ✓ VERIFIED | Both workflows remain substantive (202 and 160 lines). Candidate → publish → verify/evidence dependencies, shared lock, least-privilege scopes, post-lock revalidation, and step-scoped Hex key remain wired. |
| `bin/package_smoke.sh` | Local and published-package consumer verification | ✓ VERIFIED | Substantive 108-line script hashes the fetched package against the expected checksum, checks package name/version, then compiles a fresh published-version consumer with warnings as errors. Historical v0.1.2 consumer success proves installability only. |
| `.planning/EVIDENCE.md` | Accurate proof-class ledger | ✓ VERIFIED | Records actual v0.1.2 facts and the accepted exception without claiming candidate-byte identity or an evidence asset. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Candidate proof and package identity | Hex publishing credential | Workflow candidate dependency and locked revalidation | ✓ WIRED | Both publish jobs depend on candidate and run `release_integrity.cjs revalidate` before the only Hex-key step. |
| Candidate bytes | Hex metadata and fetched tarball | `release_integrity.cjs` verification | ✓ WIRED for future qualifying releases | Source compares candidate checksum, API checksum, independently fetched bytes, package metadata, and consumer result before reporting verified. This does not repair v0.1.2's missing candidate bytes. |
| Published package | Clean downstream consumer | Published tarball → `bin/package_smoke.sh --published` | ✓ WIRED | Both workflow evidence jobs run package verification and `record-consumer` before building the durable evidence packet. |
| Post-publish verification | Durable release evidence asset | Workflow → `release_evidence.cjs` | ✓ WIRED for future qualifying releases | Evidence job follows byte and consumer checks and has GitHub contents write permission without the Hex key. The v0.1.2 historical asset is still absent. |
| Automatic and recovery paths | Shared publisher and candidate identity gates | Both workflows → `release_integrity.cjs` | ✓ WIRED | Both definitions share candidate preparation, queued lock, and locked revalidation. |
| Remote settings readback | Release policy acceptance | `release_remote_gate.cjs` → GitHub metadata | ✓ WIRED | Read-only source path and previously recorded readback remain present; this verification made no remote call. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `scripts/release_integrity.cjs` | Candidate package checksum | Pinned Mix build output and independent SHA-256 | Yes for an actual candidate run | ✓ FLOWING |
| `scripts/release_integrity.cjs` | Published checksum and package identity | Hex API plus fetched tarball bytes and unpacked metadata | Yes for an actual verification run | ✓ FLOWING |
| `scripts/release_evidence.cjs` | Versioned release manifest | Validated candidate packet and post-publish verification values | Yes for qualifying future releases | ✓ FLOWING |
| v0.1.2 release history | Candidate checksum and evidence asset | Original candidate artifact unavailable; Release asset absent | No historical candidate checksum or manifest is available | PASSED (override; facts remain unproven) |

## Behavioral Spot-Checks

The original Plan 34-06 verification did not run tests, CI, UAT, registry requests, or release mutations, as its scope requires. For this validation refresh, the deterministic local release suite was run from the shared checkout; it made no registry request, GitHub request, secret access, CI invocation, publication, or release change. Phase 34 UAT remains recorded at 11/11 and was not rerun.

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Candidate identity and registry conflicts fail closed | `node --test scripts/release_integrity.test.cjs` within the focused suite | Exact-SHA, identity mismatch, conflict, unobserved registry state, and retry-revalidation fixtures passed | ✓ PASS |
| Evidence rejects missing or contradictory proof | `node --test scripts/release_evidence.test.cjs` within the focused suite | Missing, malformed, mismatched, and contradictory proof fixtures passed | ✓ PASS |
| Workflow credential and evidence ordering | `node --test scripts/release_workflow_contract.test.cjs` within the focused suite | Automatic and recovery job dependency, permission, and credential boundaries passed | ✓ PASS |

## Probe Execution

No Phase 34 probe is declared in the plans or success criteria; no probe was run.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SHIP-01 | 34-01, 34-02, 34-04 | Exact-SHA complete CI proof before release secrets | ✓ SATISFIED | Current workflow wiring and the prior focused workflow evidence. |
| SHIP-02 | 34-01, 34-03, 34-04, 34-05, 34-06 | Agreement of source, tag, package version, candidate artifact, and published bytes | PASSED (scoped historical override) | Applies only to the unavailable v0.1.2 candidate bytes. The mismatch remains unproven; current checks remain strict for future releases. |
| SHIP-03 | 34-01, 34-02, 34-03, 34-04 | Serialized least-privileged publishing and shared automatic/recovery gates | ✓ SATISFIED | Current workflows share the lock and credential boundary; source and prior focused contract evidence remain. |
| SHIP-04 | 34-01, 34-04, 34-05, 34-06 | Durable evidence for exact SHA, CI, artifact, dry run, publication, and verification | PASSED (scoped historical override) | Applies only to the absent v0.1.2 asset. Current workflow and schema create future evidence only after checks; no asset exists for v0.1.2. |

No additional REQUIREMENTS.md entries map to Phase 34. The normal phase-completion transition now records SHIP-01 through SHIP-04 as Complete. SHIP-02 and SHIP-04 completion reflects the two accepted, historically scoped overrides; it does not establish v0.1.2 candidate-byte identity or create its missing evidence asset.

## Decision Coverage

All 11 trackable Phase 34 CONTEXT.md decisions are honored by shipped artifacts (non-blocking gate; no missing decisions).

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No debt markers, placeholders, empty implementations, or stubs found in scoped implementation files. CLI `console.log` calls emit expected JSON/status output. | — | None. |

## Human Verification Required

None. Phase 34 UAT is already recorded as 11/11. The maintainer explicitly resolved the two historical disposition questions; their evidence limitations remain stated above.

## Gaps Summary

The two historical v0.1.2 findings are accepted only through the two exact overrides authorized by the maintainer's A choice at `2026-09-26T17:45:16Z`. The original candidate bytes are unavailable and the candidate-to-served-byte identity remains unproven. The v0.1.2 GitHub Release still has no `release-evidence.json`. Neither fact is technically verified or repaired by this disposition. Current automatic and recovery workflows retain strict candidate, checksum, consumer, and evidence gates for future releases. All other prior Phase 34 truths passed quick regression checks, and no regression was found.

The decision-coverage gate reports 11/11 decisions honored. This refresh ran the focused local release tests only; it did not run CI or UAT, query the registry or release settings, access secrets, alter a release, or change release implementation files.

After the prior verification, `.planning/EVIDENCE.md` gained the dated ORIENT-01 through ORIENT-06 completion links and `.planning/REQUIREMENTS.md` plus `.planning/ROADMAP.md` were reconciled. SHIP-01 through SHIP-04 remain complete, with the same two scoped historical exceptions. The current canonical fingerprint is `v1:sha256:de1d76f90d9b7c976c72bfd00c0e3c9f3a28aa1750e2991d5c2025db07006b2a`. The focused deterministic release suite passed 36/36; Phase 34 UAT remains recorded as complete at 11/11 and was not repeated.

---

_Verified: 2026-09-27T13:55:05Z_  
_Verifier: the agent (gsd-verifier)_
