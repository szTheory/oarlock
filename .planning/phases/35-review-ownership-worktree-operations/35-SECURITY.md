---
phase: "35"
slug: review-ownership-worktree-operations
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 35 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub issues and pull requests to maintainer triage | Public intake and editable labels do not establish ownership or disposition. | Item identity, dated maintainer comments, collaborator permission |
| GitHub read API to triage report | Remote collection may be incomplete or inconsistent and must not be presented as complete. | Paginated items, comments, permissions, allowlisted diagnostics |
| Local Git metadata to worktree lifecycle evidence | Repository paths, refs, environment, and worktree state are untrusted observations. | Canonical path, branch, base, HEAD, status, lock state |
| Dependabot proposal to merge decision | Dependency metadata and workflow claims require review against the exact candidate SHA. | Lockfile boundary, changed files, required CI jobs, Hex audit |
| Repository administration settings to contributor guidance | Security routes and automation are documented only after authorized writes and live readback. | Private reporting, vulnerability alerts, automated security fixes |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-35-01 | Tampering | manifest and worktree identity | high | mitigate | Fixed-argument NUL-safe Git observations validate owner, path, branch, base, and HEAD; regression coverage rejects inherited and supplied `GIT_*` redirection. | closed |
| T-35-02 | Denial of service | worktree cleanup | high | mitigate | The lifecycle CLI is report-only; tests verify it never removes, unlocks, resets, or prunes worktrees. Unknown and unreadable states block clean claims. | closed |
| T-35-03 | Information disclosure | CLI diagnostics | medium | mitigate | Output is bounded to identity/status evidence and excludes file contents and credentials; renderer and CLI contracts cover the boundary. | closed |
| T-35-04 | Information disclosure | security reporting | high | mitigate | Private vulnerability reporting was enabled after authorization and reads back `enabled:true`; public issue intake and the security policy direct reports to that verified route. | closed |
| T-35-05 | Spoofing | ownership guidance | medium | mitigate | Documentation leaves routing unknown until person/team access is verified; no CODEOWNERS entry or guessed security contact is present. | closed |
| T-35-06 | Repudiation | PR proof claim | medium | mitigate | The PR template asks for commands/results, candidate SHA, risk, and hosted run link; documentation requires observed exact-SHA evidence. | closed |
| T-35-07 | Spoofing | maintainer triage record | high | mitigate | Triage verifies the comment author and any action owner through separate current collaborator-permission reads; regression tests reject imitation and insufficient permission. | closed |
| T-35-08 | Tampering | incomplete pagination and record drift | high | mitigate | The collector exhausts pagination and rejects inconsistent identities, malformed or contradictory current records, and incomplete collection. | closed |
| T-35-09 | Information disclosure | audit diagnostics | medium | mitigate | Diagnostics use bounded allowlisted metadata and omit raw comment prose, issue bodies, and credentials; redaction is covered by tests. | closed |
| T-35-10 | Tampering | dependency proposal | high | mitigate | Dependabot keeps root/demo lockfile boundaries separate and routes changes through exact-SHA CI and Hex advisory checks. | closed |
| T-35-11 | Spoofing | CI evidence | high | mitigate | Maintainer guidance binds the PR head to the hosted run and artifact identity; exact-head and merge-SHA CI evidence is retained for PR #4. | closed |
| T-35-12 | Elevation of privilege | automated merge | medium | mitigate | No auto-merge workflow is added; the Dependabot contract rejects an automatic merge path. | closed |
| T-35-13 | Repudiation | live triage decisions | medium | mitigate | Dated links to maintainer-authored decisions are recorded in the live baseline; audit output does not substitute labels or form content. | closed |
| T-35-14 | Spoofing | unknown owner and scope | high | mitigate | The final live audit requires verified permission and explicit owner, scope, state, and next action; all current items have a valid disposition. | closed |
| T-35-15 | Information disclosure | baseline record | medium | mitigate | The retained baseline records item IDs and disposition evidence without copying issue/PR bodies, credentials, or private vulnerability contents. | closed |
| T-35-16 | Denial of service | disabled hosted security updates | high | mitigate | Vulnerability alerts return HTTP 204 and automated security fixes read back `true`; the settings are currently enabled. | closed |

All 16 plan-declared threats were checked at ASVS L1 against the plans, summaries, implementation, contract tests, live settings, and the clean 16-file code review. No unregistered threat flag appears in the plan summaries. The fresh authenticated triage audit completed with no disposition gaps. Local process inspection is denied by this sandbox (`ps` returns `EPERM`); the inventory collector reports the observation as unreadable and fails closed, and this known environment limitation is recorded in 35-VALIDATION.md.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-26 | 16 | 16 | 0 | GSD orchestrator |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-26 at ASVS L1. The post-review local fixes still require exact-candidate hosted CI before phase completion; no hosted success is claimed for that uncommitted diff.
