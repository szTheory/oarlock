---
phase: "36"
slug: "jtbd-coverage-durable-trajectory-handoff"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 36 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| Repository Markdown -> JTBD parser | Links and headings may be malformed or point outside the repository. | Planning text, paths, IDs |
| Research and archives -> current decision record | Historical claims may be mistaken for current provider proof or committed work. | Sources, ownership claims, evidence |
| Repository links -> authoritative planning files | A syntactically valid link can still point to a non-authoritative or unsafe source. | Links, requirement authority |
| Base/head Git objects -> transition verifier | Current prose can conceal removal of old decisions. | Historical rows and transitions |
| CI workflow -> milestone evidence | A passing run can omit the new map check or target another SHA. | Workflow results, commit SHA, artifacts |
| Local Git/worktree state -> handoff | Mutable state may differ from a planning-time or earlier execution snapshot. | Branch, worktree, index, lock state |
| Hosted CI metadata/artifact -> handoff | A green run for another SHA or missing artifact can be mistaken for target proof. | PR, run, artifact identity |
| Historical evidence -> next discovery | A caveat or candidate can be recast as verified current capability. | Release caveats and candidate status |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-36-01 | Tampering | Markdown source reader | high | mitigate | Bounded, contained, no-follow reads reject unsafe paths and duplicate IDs. | closed |
| T-36-02 | Spoofing | Candidate/actor claims | high | mitigate | Dated source paths, accountable repository ownership, and explicit adopter ownership classifications are validated. | closed |
| T-36-03 | Information disclosure | Diagnostic output | medium | mitigate | Diagnostics use bounded source processing, but may still expose a source-derived unsafe link `href` or diagnostic `actual` value. | open — below high threshold (non-blocking) |
| T-36-04 | Tampering | Cross-link reader | high | mitigate | Canonical planning sources are enforced, unsafe targets and contradictions rejected, and unknown ownership reported. | closed |
| T-36-05 | Repudiation | Transition history | high | mitigate | Base/head comparison requires byte-identical prefixes and dated append continuity. | closed |
| T-36-06 | Elevation of privilege | Candidate scope classification | high | mitigate | Future Requirements and ROADMAP authority are checked before committed claims pass. | closed |
| T-36-07 | Denial of service | Repository Markdown parser | medium | mitigate | Reads are size-bounded and diagnostics are deterministically ordered. | closed |
| T-36-08 | Spoofing | Exact-SHA hosted evidence | high | mitigate | Successful handoff proof checks candidate checkout, live PR, hosted run SHA, required jobs, and retained artifact identity. | closed |
| T-36-09 | Tampering | Repository/worktree disposition | high | mitigate | Fresh inventory is compared against the handoff; dirty, locked, stale, or unknown state prevents clean close. | closed |
| T-36-10 | Repudiation | Historical release caveat | medium | mitigate | The handoff checker requires the dated v0.1.2 caveat to cite EVIDENCE and rejects its absence. | closed |
| T-36-11 | Elevation of privilege | Next-cycle candidate status | high | mitigate | Candidate IDs are checked against Future Requirements authority and rejected if committed or traceable elsewhere. | closed |

T-36-03 remains an open medium-severity hardening item. Under the configured `block_on: high` policy it is non-blocking and excluded from `threats_open`; the diagnostic values are source-derived, but do not affect authorization or repository writes.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Candidate SHA | Threats Total | Closed | Open | Run By |
|---|---|---:|---:|---:|---|
| 2026-09-26 | `1cdb790c19f9c37b914d86e4d657162999a661b0` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `3f3e6b281c07991c97e1295c01919f7095db8536` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `04d00b2c859e3cb44e56a7e060445dcd8bb5905f` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `52b93b88f0491ea539288b12d4a5360c4a675e93` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `a9527a0f8ec8ad81b057ae8c42612c70f66d1fb2` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `140cdb9bfbfef7438617a1c7d5b1b5b74d5de080` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `bb2822e350a21f6e9bc9f7d70b06b6e0150ee6f3` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `8e282ec5f9955d68d7068bc27651ccda474528bd` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |
| 2026-09-26 | `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994` | 11 | 10 | 1 | gsd-security-auditor; orchestrator recorded result |

An earlier audit of candidate `8e282ec5f9955d68d7068bc27651ccda474528bd` verified that the hosted job explicitly pins Rebar 3.25.1, records it in the proof, handles both current Hex version directories and legacy `.ez` archives, and keeps the exact-SHA checks. That candidate passed run `36278712627`, attempt `1`, with artifact `10917718772`; this entry is retained as audit history. The final c5 candidate is covered by the updated audit below.

The final candidate `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994` was re-audited after the PR event-head/tested-checkout distinction was made explicit. Hosted proof passed in run `36282241303`, attempt `1`; the event/head SHA is `c5bcc7b331640c1d1d9dc4e5289a634e5cc21994`, and the CI-tested merge checkout SHA is `c130cd6c731abc04dd312efc355d79eb5a48e5ab`. Retained artifact `10918748960` has digest `sha256:bb04bd90cab3091c9a964887f312bbb1b5ab66183517cab5643de82b66eefa58`. All eight required hosted lanes passed. The final audit remains 11 total, 10 closed, and one open medium-severity non-blocking finding (T-36-03); there are no open high-severity threats.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed (`block_on: high`; T-36-03 is medium)
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-26
