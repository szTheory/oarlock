---
status: complete
phase: 33-deterministic-green-ci
source: 33-01-SUMMARY.md, 33-02-SUMMARY.md, 33-03-SUMMARY.md, 33-04-SUMMARY.md
started: 2026-09-26T02:46:43Z
updated: 2026-09-26T02:48:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Failed-lane proof remains explicit
expected: A failed required lane produces a valid, explicitly unverified proof document.
result: pass
source: automated
coverage_id: D1

### 2. Exact-SHA monitor requires matching evidence
expected: Hosted acceptance requires the matching run, job set, attempt, and retained proof artifact.
result: pass
source: automated
coverage_id: D2

### 3. Required quality lane is present
expected: Strict Credo, ExDoc, and Hex advisory audit are required CI checks.
result: pass
source: automated
coverage_id: D1

### 4. Quality lane is bound into hosted proof
expected: Quality checks are included in exact-SHA proof creation and monitoring.
result: pass
source: automated
coverage_id: D2

### 5. CI inputs and trust boundaries are controlled
expected: Runner, service, toolchain, timeout, permissions, and cache policies are statically checked and pass hosted CI.
result: pass
source: automated
coverage_id: D1

### 6. CI timing baseline is measured honestly
expected: Exact-run timing records use the stated methodology and disclose that the provisional target remains unmet.
result: pass
source: automated
coverage_id: D2

### 7. Candidate acceptance binds exact SHA and artifact
expected: Candidate acceptance requires all required jobs and retained proof to match the tested SHA.
result: pass
source: automated
coverage_id: D1

### 8. Protected main has current exact-SHA proof
expected: Main requires the CI contract and its exact current commit has a successful retained proof artifact.
result: pass
source: automated
coverage_id: D2

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Automated Evidence

- `node --test scripts/ci_proof.test.cjs scripts/ci_monitor.test.cjs scripts/ci_timing.test.cjs scripts/ci_workflow_contract.test.cjs scripts/ci_remote_gate.test.cjs` — 41 passed.
- `mix test test/paddle/error_test.exs test/paddle/inspection_safety_test.exs` — 18 passed.
- `actionlint .github/workflows/ci.yml` — passed.
- `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json` — verified current main SHA `1f2b3aa19ddfe7d8f6aaa0683df73af76abb06c5`, all eight required jobs, exact run attempt, retained artifact/digest, and required ruleset.
- The full workflow evidence matrix is recorded in `33-VERIFICATION.md`; the provisional CI feedback target remains explicitly unmet and is not reported as an acceptance failure.

## Gaps

[none]
