---
status: partial
phase: 28-ci-demo-and-package-proof
source: [28-VERIFICATION.md, scripts/ci_monitor.cjs, .github/workflows/ci.yml]
started: 2026-06-24T12:56:40-04:00
updated: 2026-06-24T15:08:40-04:00
---

## Current Test

[automated verification blocked - no pushed CI run for current HEAD]

## Tests

### 1. Automated GitHub Actions CI proof for the target SHA

expected: `node scripts/ci_monitor.cjs assert-ci --sha <sha> --workflow CI --timeout 1800 --poll 20 --json` returns `verified: true` for the exact pushed SHA, with jobs `mix test`, `static analysis`, `demo PostgreSQL`, `package smoke`, `optional dependencies`, and `CI contract` all successful.
result: blocked
blocked_by: third-party
reason: "Automated verifier returned no_ci_run_for_sha for current HEAD c500052b87dfabbcfc68855ddb5193069e68fe41 at 2026-06-24T15:08:40-04:00; push the target SHA or open a PR so GitHub Actions can produce authoritative evidence."

## Summary

total: 1
passed: 0
issues: 0
pending: 0
skipped: 0
blocked: 1

## Gaps
