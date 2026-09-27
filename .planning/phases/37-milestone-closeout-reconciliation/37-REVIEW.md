---
phase: 37-milestone-closeout-reconciliation
status: clean
depth: standard
reviewed: 2026-09-27
critical: 0
warnings: 0
resolved_findings: 4
---

# Phase 37 Code Review

Inline standard review of `scripts/closeout_check.cjs`, its Git-backed tests, the explicit `scripts/fixtures/closeout_snapshot.cjs` operator harness, schema-v2 changes in `scripts/jtbd_coverage.cjs`, and append-only evidence changes in `scripts/history_integrity.cjs`. Existing remote proof authority is reused unchanged.

| Finding | Resolution | Behavioral evidence |
|---|---|---|
| Invalid UTF-8 names could be decoded into different paths. | Reject non-round-tripping path bytes in Git and expanded filesystem census. | Negative injected Git path test; valid spaces/newlines remain covered. |
| A link inside the root could traverse an ignored symlink to an external file. | Check the resolved target as well as lexical containment; unreadable/dangling links fail closed. | Real indirect symlink escape fixture. |
| New requirement evidence could only be added by violating the old correction-row format. | Permit unique, dated, canonical requirement verification rows; preserve the entire old ledger prefix byte for byte. | Valid append passes; changed prefix, duplicate ID, bad date/link/status and arbitrary prose fail. |

Closeout behavioral suite: 19 passed, 0 failed. History suite: 29 passed, 0 failed. Review also checked bounded subprocesses and reads, private diagnostics, exact original index restoration, path-scoped candidate mapping, immutable artifact identities, source census completeness, evidence-tail allowlist and independently reviewed raw Git object mapping.

No open critical or warning finding. Live candidate and final workstation gates remain separate required acceptance steps; this review does not claim those operations have completed.

## Hosted CI integration follow-up

The first candidate run exposed a real Mix build test inside the Node-only planning job. The unchanged checksum/metadata assertions were moved to `scripts/integration/release_package.test.cjs` and wired unconditionally into required package smoke after pinned Node/BEAM setup and dependency fetch. A workflow contract proves this route and rejects Mix calls in the Node-only release unit tests. The focused routing/release suite passes; the final payload receives fresh complete local and hosted proof. No test skip, optional lane or aggregate relaxation was introduced.
