---
phase: "33"
slug: "deterministic-green-ci"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 33 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub event and job results → proof artifact | Untrusted run metadata becomes durable CI evidence | SHA, run/attempt, toolchain, lock digests, job outcomes |
| Hosted run/artifact → local monitor | Remote evidence is checked against the requested candidate or current main | Run identity, jobs, proof artifact, digest |
| Runner/tool/container source → CI execution | External actions, images, and installers execute in CI | Workflow code and build inputs |
| Low-trust pull request → trusted cache | Restored cache contents may cross into trusted main builds | Dependency/build cache data |
| Maintainer credentials → repository rules | Authenticated metadata may create a required-check rule | Branch ruleset configuration |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-33-01 | Tampering | `ci_proof.cjs` | high | mitigate | Validates SHA/run/attempt/job identities and checked-out lockfile digests | closed |
| T-33-02 | Spoofing | `ci_monitor.cjs` | high | mitigate | Matches run, attempt, proof artifact, digest, and hosted job results | closed |
| T-33-03 | Information disclosure | Proof artifact | medium | mitigate | Emits an allowlisted set of non-secret evidence fields | closed |
| T-33-04 | Denial of service | Artifact download | medium | mitigate | Bounds subprocess deadlines/output and rejects oversized artifacts | closed |
| T-33-05 | Tampering | Credo dependency | high | mitigate | Pins reviewed Hex package/version/checksum and scopes Credo to dev/test | closed |
| T-33-06 | Tampering | Workflow aggregate | high | mitigate | Contract tests bind named CI checks to all required aggregate dependencies | closed |
| T-33-07 | Repudiation | Hex audit result | medium | mitigate | Aggregate proof records the quality lane result; it does not separately retain the audit step's outcome or cause | open — below high threshold (non-blocking) |
| T-33-08 | Tampering | Actions and service image | high | mitigate | Full-SHA action pins, digest-pinned service image, and policy contract tests | closed |
| T-33-09 | Elevation of privilege | Cache restore | high | mitigate | Pull requests restore only; trusted main pushes alone write runtime/lock-scoped caches | closed |
| T-33-10 | Denial of service | CI jobs | medium | mitigate | Per-job timeouts use observed duration with headroom | closed |
| T-33-11 | Repudiation | Timing report | medium | mitigate | Timing binds run/SHA/timestamps and classifies missing data explicitly | closed |
| T-33-12 | Spoofing | Hosted run lookup | high | mitigate | Gate binds requested SHA, run, attempt, jobs, proof, artifact and digest | closed |
| T-33-13 | Tampering | Main branch rule | high | mitigate | Hosted evidence records no prior ruleset/classic protection; the new effective rule is limited to `CI contract`, has no bypass actors, and is read back after creation | closed |
| T-33-14 | Repudiation | Hosted evidence file | medium | mitigate | Dated hosted evidence retains rule identity/source, run URL, SHA, artifact digest, and lane outcomes | closed |
| T-33-15 | Information disclosure | Hosted evidence | medium | mitigate | Proof schema allowlists public run identifiers, hashes, versions, timings, and job outcomes | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-26 | 15 | 14 | 1 non-blocking | GSD security auditor; evidence cross-checked against `33-CI-HOSTED.md` and live GitHub rule readback |

## Sign-Off

- [x] All threats have a disposition
- [x] No accepted risks were introduced
- [x] `threats_open: 0` confirmed at the configured `high` block threshold
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-26. T-33-07 remains a documented medium-severity evidence limitation below the blocking threshold; improving per-step audit provenance can be considered if later evidence shows recurring operational value.
