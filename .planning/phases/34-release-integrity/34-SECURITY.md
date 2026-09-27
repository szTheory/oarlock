---
phase: "34"
slug: release-integrity
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 34 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| workflow_dispatch to release runner | Maintainer tag input crosses into Git and shell operations. | Tag identity |
| GitHub CI/run/artifact APIs to candidate packet | Hosted proof is authoritative only after exact identity validation. | SHA, run, attempt, jobs, retained artifact |
| Candidate packet to Hex publish environment | Registry mutation receives an organization credential only after proof and revalidation. | Candidate identity and scoped Hex API key |
| Hex registry to evidence asset | Public package observations must agree before durable success is recorded. | Metadata, checksums, fetched bytes |
| Release Please output to automatic candidate | Generated tag/version metadata is checked against the actual tagged source. | Tag, version, source SHA |
| GitHub concurrency queue to Hex side effect | The publisher rechecks mutable observations after waiting for the shared lock. | Tag, proof, package checksum, registry state |
| Verification packet to public GitHub Release asset | Checked facts become a durable public record. | Allowlisted release metadata and links |
| Repository settings API to release policy gate | Remote policy is observed rather than inferred from workflow declarations. | Tag ruleset and environment metadata |
| GitHub write token to Release asset | A write-capable token can create or update maintainer-facing evidence. | Release asset write permission |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-34-01 | Spoofing | tag and CI candidate | high | mitigate | Remote tag peel and exact-SHA run, attempt, required-job, and artifact identity checks in scripts/release_integrity.cjs; covered by focused fail-closed tests. | closed |
| T-34-02 | Tampering | package handoff and Hex bytes | high | mitigate | Independent candidate checksum and published metadata/fetched-byte checks; covered by checksum-chain tests. | closed |
| T-34-03 | Elevation of privilege | publish credential | critical | mitigate | HEX_API_KEY is mapped only to the final publish step after proof and locked revalidation in both release workflows; workflow contract tests assert the boundary. | closed |
| T-34-04 | Information disclosure | errors and evidence | medium | mitigate | Bounded diagnostics and strict release-evidence allowlist exclude secrets and raw payloads; serializer and diagnostic tests pass. | closed |
| T-34-05 | Spoofing | Release Please candidate | high | mitigate | Generated tag/version are checked against the remote peeled tag and package identity before the shared candidate gate; workflow contract tests pass. | closed |
| T-34-06 | Tampering | queued publication | high | mitigate | Both publishers share the non-canceling Hex queue and repeat source, CI, checksum, and registry checks after lock acquisition. | closed |
| T-34-07 | Denial of service | concurrent jobs | medium | mitigate | Publisher concurrency uses queue: max and cancel-in-progress: false; queue behavior is contract-tested and actionlint-checked. | closed |
| T-34-08 | Elevation of privilege | GitHub and Hex tokens | critical | mitigate | Job permissions are scoped; GitHub write permission is limited to its release/evidence job and the Hex key to the final publish step. | closed |
| T-34-09 | Tampering | package checksum chain | high | mitigate | Mix checksum, independent SHA-256, Hex API checksum, fetched tarball checksum, and package metadata must agree; focused tests pass. | closed |
| T-34-10 | Spoofing | version endpoint | medium | mitigate | Verification checks response version/checksum, fetched package bytes, package metadata, and a clean consumer instead of trusting endpoint status alone. | closed |
| T-34-11 | Tampering | ambiguous retry | critical | mitigate | Retry requires confirmed absence, exact identity revalidation, and a single bounded retry; conflicting or unobserved states fail closed. | closed |
| T-34-12 | Denial of service | delayed registry indexing | medium | mitigate | Registry absence and post-publish observations use bounded polling with explicit unobserved outcomes. | closed |
| T-34-13 | Repudiation | release manifest | high | mitigate | Versioned manifest binds repository, tag/SHA, CI run/attempt/artifact, checksums, release run, and verification timestamps. | closed |
| T-34-14 | Information disclosure | evidence serializer | high | mitigate | Serializer validates an explicit field allowlist and rejects unknown fields, raw logs, and payload-bearing values. | closed |
| T-34-15 | Tampering | tag and prior asset | high | mitigate | Live readback verifies v-tag update/deletion protection with no bypass; evidence merge rejects contradictory prior identity/checksum. | closed |
| T-34-16 | Elevation of privilege | Release write job | high | mitigate | contents: write is isolated to the Release asset job, which has no Hex API key; workflow tests assert least privilege. | closed |

All 16 plan-declared threats were checked at ASVS L1. Focused release tests passed (36/36), package smoke passed, workflow lint passed, the remote release-policy gate returned verified, and no summary reported an unregistered threat flag.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-26 | 16 | 16 | 0 | GSD orchestrator |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] threats_open: 0 confirmed
- [x] status: verified set in frontmatter

**Approval:** verified 2026-09-26
