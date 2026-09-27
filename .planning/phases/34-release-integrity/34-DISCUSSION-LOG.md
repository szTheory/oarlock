# Phase 34: Release Integrity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `34-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 34-release-integrity
**Areas discussed:** Recovery candidate authority, Release identity chain, Publication concurrency, Durable release evidence

---

## Recovery candidate authority

| Option | Description | Selected |
|--------|-------------|----------|
| Existing versioned release tag only | One familiar release-intent input; resolve it to a commit, derive the version, and require exact accepted CI proof. | ✓ |
| Pinned SHA plus release version and matching tag | Allows recovery of tag creation but adds release-authoring permissions and another version input. | |
| Tag or SHA as interchangeable inputs | Flexible but forces normalization, conflict handling, and multiple candidate-selection branches. | |

**User's choice:** The maintainer asked for researched, coherent recommendations and had previously authorized following recommendations. Applied the recommended tag-only recovery decision.
**Notes:** Require protected version tags. No arbitrary SHA or separately typed version; recovery retries an existing authorized release.

---

## Release identity chain

| Option | Description | Selected |
|--------|-------------|----------|
| Tag and version metadata only | Low cost, but does not verify bytes in the package Hex serves. | |
| Supported Mix build/publish plus Hex checksum and fetched package verification | Preserve idiomatic Mix/Hex usage while proving the published checksum and fresh-consumer install path. | ✓ |
| Custom canonical tarball publisher and attestation | Strongest build-once provenance, with a bespoke publisher and more maintenance. | |

**User's choice:** Applied the recommended Mix/Hex path with checksum and consumer verification, conditional on validating the standard toolchain's checksum agreement.
**Notes:** Verify exact tag SHA, CI evidence, package name/version, expected artifact checksum, registry checksum, and fetched tarball metadata. Do not publish if any value disagrees. A successful version lookup by itself is insufficient.

---

## Publication concurrency

| Option | Description | Selected |
|--------|-------------|----------|
| Cancel active or pending attempt | Suitable for disposable checks; unsafe for an external side effect because publication state may be ambiguous. | |
| Fail immediately when occupied | Easy to understand but forces manual retry and risks forgotten releases. | |
| Queue, then reconcile exact package/version/checksum | One cross-workflow lock preserves attempts; after acquiring it, check whether Hex already has a matching release before retrying. | ✓ |

**User's choice:** Applied the recommendation to queue without canceling active release work.
**Notes:** Use one shared publisher group, `queue: max` where supported, and revalidate after obtaining the lock. Matching already-published package is an idempotent success; a conflicting checksum blocks for incident resolution.

---

## Durable release evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Actions logs and artifacts only | Convenient diagnostics, but finite retention and no durable summary of package identity. | |
| Compact `release-evidence.json` asset on each GitHub Release; EVIDENCE.md defines the authority/schema | Durable adopter/maintainer trace with IDs and checksums; no source-tree bot commit, duplicate logs, or package contents. Requires post-publish upload with separate GitHub write permission. | ✓ |
| GitHub Release manifest plus consumer-verifiable artifact attestation | Strong provenance surface, but adds signing/verification and requires digest equality with Hex's package. | |
| Hex package metadata only | Authoritative for registry facts, but cannot explain which CI run authorized publication or prove dry-run/post-publish checks. | |

**User's choice:** Applied a durable release-evidence manifest beside each GitHub Release, with `.planning/EVIDENCE.md` defining the authority and Phase 34 acceptance evidence.
**Notes:** Record exact tag/SHA, CI run/attempt and artifact digest, workflow, package/version, dry-run, Hex release/checksum, fetched package verification, downstream compile result, timestamps, and caveats. Keep detailed output in run logs/artifacts as supplemental evidence. Upload after post-publish checks using a separate GitHub-write step with no Hex secret; do not freeze the release before its final manifest is attached.

---

## the agent's Discretion

- Exact implementation boundaries, structured-record field names, bounded polling, and output formatting.
- Validate the standard Mix/Hex checksum comparison before choosing exact commands; escalate for a new decision only if it requires a custom publisher or materially changes the release contract.
- Use GitHub attestations only if they add consumer-verifiable assurance over Hex-served bytes beyond the simpler checksum/evidence contract.

## Deferred Ideas

- Custom canonical package publisher and consumer-verifiable attestations unless a demonstrated gap or adopter need justifies the cost.
- Recovery-created tags, arbitrary SHA publication, and a release dashboard.

## Research basis

- Three focused GSD advisor-researcher agents compared recovery authority, package identity/provenance, concurrency, and evidence retention; the orchestrator checked Hex, GitHub Actions, and project-local primary sources.
- Current project evidence and mission in `prompts/oarlock-milestone-roadmap-ratchet.txt`; current brand guidance in `prompts/oarlock-brand-book.md`. No product UI/visual design work is in Phase 34.
- External references are listed in `34-CONTEXT.md`.
