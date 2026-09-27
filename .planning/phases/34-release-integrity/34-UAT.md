---
status: complete
phase: 34-release-integrity
source:
  - 34-01-SUMMARY.md
  - 34-02-SUMMARY.md
  - 34-03-SUMMARY.md
  - 34-04-SUMMARY.md
started: 2026-09-26T12:15:49Z
updated: 2026-09-26T12:15:49Z
---

## Current Test

[testing complete]

## Tests

### 1. Existing-tag recovery validates exact source and complete CI proof
expected: Recovery accepts only the selected protected tag, its peeled source SHA, and the complete exact-SHA CI contract before candidate publication.
result: pass
source: automated
coverage_id: 34-01-D1
verification: focused release tests

### 2. Package bytes, Hex metadata, and consumer identity are checked together
expected: Candidate checksum, Hex metadata, fetched package bytes, embedded package identity, and exact-version consumer checks reject mismatches.
result: pass
source: automated
coverage_id: 34-01-D2
verification: focused release tests and local package smoke

### 3. Hex credentials stay behind proof and publisher revalidation
expected: HEX_API_KEY is available only to the final publish step after exact proof, lock acquisition, and revalidation.
result: pass
source: automated
coverage_id: 34-01-D3
verification: focused release tests and actionlint workflow checks

### 4. Release evidence records verified identities without secrets
expected: The evidence packet binds source, CI artifact, checksums, package verification, and workflow attempt while excluding credentials and raw payloads.
result: pass
source: automated
coverage_id: 34-01-D4
verification: focused release tests

### 5. Release Please uses the shared exact-SHA candidate gate
expected: Generated release tag and version outputs are normalized through the same candidate proof and package preparation path as recovery.
result: pass
source: automated
coverage_id: 34-02-D1
verification: focused release tests

### 6. Automatic and recovery publishers share a safe queue
expected: Both publishing paths serialize without cancellation, revalidate under the shared lock, and scope Hex credentials to the publish step.
result: pass
source: automated
coverage_id: 34-02-D2
verification: focused release tests and actionlint workflow checks

### 7. Candidate checksum chain rejects inconsistent bytes
expected: Mix output, an independent SHA-256, Hex metadata, fetched bytes, and package identity are compared as one integrity chain.
result: pass
source: automated
coverage_id: 34-03-D1-fixtures
verification: focused release tests

### 8. Ambiguous publication outcomes fail closed
expected: Matching, absent, conflicting, and unobserved registry states are distinguished; a retry occurs only after bounded absence and identity revalidation.
result: pass
source: automated
coverage_id: 34-03-D2
verification: focused release tests and local package smoke

### 9. Release evidence schema and prior attempts are protected
expected: Evidence serialization accepts only the versioned allowlist, preserves compatible attempts, and rejects contradictory source or checksum fields.
result: pass
source: automated
coverage_id: 34-04-D1
verification: focused release tests

### 10. Live release-tag policy is effective
expected: Read-only GitHub policy checks confirm v-tag update/deletion protection, no bypass actors, and the configured production environment without accessing secrets.
result: pass
source: automated
coverage_id: 34-04-D2
verification: node scripts/release_remote_gate.cjs szTheory/oarlock

### 11. Hosted main proof is current and publication status is honest
expected: The exact current main SHA has a passing required CI contract and retained proof artifact, while the evidence ledger identifies actual Hex publication proof as pending.
result: pass
source: automated
coverage_id: 34-04-D3
verification: node scripts/ci_remote_gate.cjs main --json

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.

## Deferred Follow-Ups

- item: actual Hex publication proof
  condition: "First qualifying operator-approved release exists."
  idea: "Capture actual Hex metadata, served tarball checksum, and published-version consumer proof."
  recorded_in: .planning/EVIDENCE.md
  completion_gate: false
