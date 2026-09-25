---
phase: "31"
slug: "repository-planning-truth"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-09"
---

# Phase 31 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Git/process/filesystem output → normalizer | Local repository observations are untrusted and may be malformed, hostile, or incomplete. | Paths, refs, porcelain bytes, lock/process evidence, file contents |
| Ownership/planning authorities → classifier | Human claims and planning documents may be stale, contradictory, oversized, symlinked, or concurrently changed. | Ownership claims, roadmap/state/requirements, summaries, verification evidence |
| Normalized diagnostics → terminal/JSON consumers | Crafted values must not spoof human output or diverge from machine-readable conclusions. | Escaped human text and raw-safe JSON facts |
| Current index/ledger → immutable archives | Repairs may update current navigation and append corrections but must preserve frozen snapshots. | Milestone links, identity fields, dated evidence corrections |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-31-01 | Tampering / Elevation of Privilege | Git subprocess boundary | high | mitigate | Inspection-only argument arrays, `GIT_OPTIONAL_LOCKS=0`, bounded buffers, and repository no-mutation integration tests | closed |
| T-31-02 | Spoofing / Information Disclosure | Human renderer | medium | mitigate | Terminal controls are visibly escaped while JSON retains raw-safe facts; renderer parity is tested | closed |
| T-31-03 | Tampering / Repudiation | Ownership classifier | medium | mitigate | Versioned exact selectors, provenance/confidence/revisit fields, expiry checks, and blocking ambiguity diagnostics | closed |
| T-31-04 | Denial of Service | Git/file collectors | medium | mitigate | Bounded subprocess/file reads convert malformed, unreadable, or truncated input into incomplete exit-2 diagnostics | closed |
| T-31-05 | Information Disclosure | Registered linked worktrees | low | accept | Reporting is restricted to paths Git explicitly registers and does not recursively inspect unrelated directories | closed |
| T-31-06 | Tampering / Elevation of Privilege | Authority resolver | high | mitigate | Datum-specific authorities reject disagreement; cache and artifact decoys cannot promote scope or completion | closed |
| T-31-07 | Repudiation | Completion validator | high | mitigate | Completion requires explicit roadmap, summary, verification/evidence, and requirement proof links | closed |
| T-31-08 | Tampering | Repair reporting | high | mitigate | Repair values remain inert rendered data; no apply flag exists and before/after manifests prove read-only behavior | closed |
| T-31-09 | Denial of Service / Tampering | Concurrent planning reads | medium | mitigate | Bounded reads and pre/post file identities reject mixed snapshots with an incomplete-result exit | closed |
| T-31-10 | Information Disclosure | Planning reference traversal | medium | mitigate | Resolved targets must stay within the repository; escaping or broken targets are reported and never followed | closed |
| T-31-11 | Tampering / Repudiation | Archived milestone history | high | mitigate | Tests snapshot archive bytes; repairs touch only the mutable index and append dated evidence corrections | closed |
| T-31-12 | Spoofing / Repudiation | Milestone/package/publication identity | high | mitigate | Milestone, tag, peeled SHA, tagged package version, and publication status are sourced independently and retain unknowns | closed |
| T-31-13 | Information Disclosure | Archive/link resolver | medium | mitigate | Archive targets are repository-bounded; escaped targets are diagnosed without traversal | closed |
| T-31-14 | Denial of Service | History enumeration | low | accept | Enumeration is limited to the small tracked milestone set with bounded reads and collection-error diagnostics | closed |
| T-31-15 | Tampering / Elevation of Privilege | Repository file reader and planning traversal | high | mitigate | Resolved-root containment, regular-file checks, no-follow descriptor reads, and pre-return identity validation reject symlink and swap attacks | closed |
| T-31-16 | Information Disclosure | Ownership registry diagnostics and renderers | high | mitigate | Rejected registry payload bytes never enter evaluation or rendering; tests assert external secret sentinels are absent from human and JSON output | closed |
| T-31-17 | Tampering / Repudiation | Registry-to-ownership classification | high | mitigate | Ownership claims are accepted only from the bounded versioned registry; any source-boundary failure leaves ownership unknown with an incomplete result | closed |
| T-31-18 | Denial of Service | Bounded authoritative file reads | medium | mitigate | Size bounds are enforced before allocation and oversized or non-regular sources produce causal incomplete diagnostics | closed |
| T-31-19 | Repudiation | Gap-closure report-only execution | low | accept | Before/after mutation sentinels and archive diffs prove the diagnostic paths remain read-only and expose no state-changing command | closed |
| T-31-20 | Spoofing / Elevation of Privilege | Completion artifact selection | high | mitigate | Completion evidence is accepted only from exact paths beneath one bounded canonical phase directory and from leading YAML frontmatter | closed |
| T-31-21 | Tampering / Repudiation | Milestone phase-range validation | high | mitigate | Complete normalized range endpoints are compared exactly, including adversarial integer and decimal regression cases | closed |
| T-31-22 | Repudiation | Git identity collection | high | mitigate | Failed Git observations preserve command, status, and causal evidence, suppress dependent conclusions, and force incomplete exit 2 | closed |
| T-31-23 | Information Disclosure | Git error diagnostics | medium | mitigate | Subprocess evidence is bounded and sanitized while retaining only the command, status, and cause required for repair | closed |
| T-31-24 | Denial of Service | Artifact and frontmatter parsing | low | accept | Repository-bounded size limits constrain inputs and leading-frontmatter parsing is linear over the accepted bytes | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-31-01 | T-31-05 | Complete local worktree visibility requires showing Git-registered paths; collection stays repository-scoped and read-only. | Phase 31 threat model | 2026-09-09 |
| AR-31-02 | T-31-14 | The tracked milestone corpus is repository-bounded and small; existing read bounds and diagnostics limit malformed input. | Phase 31 threat model | 2026-09-09 |
| AR-31-03 | T-31-19 | Read-only execution is continuously guarded by mutation sentinels and immutable-history diffs; no apply path exists. | Phase 31 gap-closure threat model | 2026-09-09 |
| AR-31-04 | T-31-24 | Strict leading-frontmatter parsing runs only after repository-bounded reads constrain the accepted input size. | Phase 31 gap-closure threat model | 2026-09-09 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-09 | 14 | 14 | 0 | GSD secure-phase L1 evidence audit |
| 2026-09-09 | 24 | 24 | 0 | GSD secure-phase gap-closure L1 evidence refresh |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-09
