---
status: complete
phase: 36-JTBD Coverage, Durable Trajectory & Handoff
source:
  - 36-01-SUMMARY.md
  - 36-02-SUMMARY.md
  - 36-03-SUMMARY.md
started: 2026-09-27T00:41:15Z
updated: 2026-09-27T16:31:16Z
---

## Current Test

[testing complete]

## Tests

### 1. Phase 36 Plan 01 / D1 — Navigate stable JTBD records through both indexes
expected: Both indexes resolve each stable ID to one complete canonical record, and the live 18-record map reports healthy.
result: pass
source: automated
coverage_id: D1
verification:
  - node --test scripts/jtbd_coverage.test.cjs (both-indexes contract passed)
  - node scripts/jtbd_coverage.cjs --json (18 records, healthy, zero diagnostics)

### 2. Phase 36 Plan 01 / D2 — Keep source and ownership claims bounded
expected: Records retain dated source paths, accountable repository ownership, explicit unknown or external adopter ownership, and evidence-backed promotion gates. No unobserved adoption is claimed.
result: pass
source: automated
coverage_id: D2
verification:
  - node --test scripts/jtbd_coverage.test.cjs (dated-source and owner-accountability cases passed)
  - node --test scripts/jtbd_coverage.test.cjs (future discovery and Accrue ownership boundary test passed)
  - node scripts/jtbd_coverage.cjs --json (live source and authority checks passed)

### 3. Phase 36 Plan 02 / D1 — Resolve links through their owning authorities
expected: JTBD references to requirements, phases, evidence, backlog, and milestone sources resolve consistently; contradictory identities produce diagnostics.
result: pass
source: automated
coverage_id: D1
verification:
  - node --test scripts/jtbd_coverage.test.cjs (future, evidence, and backlog authority test passed)
  - node scripts/jtbd_coverage.cjs --json (healthy, zero diagnostics)

### 4. Phase 36 Plan 02 / D2 — Preserve dated transition history
expected: Valid dated changes append while existing history remains byte-identical; rewrites, removals, and invalid continuity fail.
result: pass
source: automated
coverage_id: D2
verification:
  - node --test scripts/history_integrity.test.cjs (JTBD append and rejection cases passed)

### 5. Phase 36 Plan 02 / D3 — Keep justified recurring checks in required CI
expected: The CI contract requires the planning-truth proof and protects distinct seam, demo E2E, and package-smoke coverage without adding a duplicate green gate.
result: pass
source: automated
coverage_id: D3
verification:
  - node --test scripts/ci_workflow_contract.test.cjs (required aggregate and integration/seam/demo/package contract tests passed)

### 6. Phase 36 Plan 03 / D1 — Reject mismatched or historical-only handoff proof
expected: The handoff checker rejects wrong candidate identities and historical-only proof, and accepts only matching exact-target evidence.
result: pass
source: automated
coverage_id: D1
verification:
  - node --test scripts/jtbd_coverage.test.cjs (wrong-SHA, historical-proof, and exact-proof fixtures passed)

### 7. Phase 36 Plan 03 / D2 — Report current proof and worktree blockers honestly
expected: The handoff records its exact hosted candidate proof and reports the observed dirty or locked worktrees as incomplete instead of claiming clean closeout.
result: pass
source: automated
coverage_id: D2
verification:
  - node scripts/ci_remote_gate.cjs candidate --sha c5bcc7b331640c1d1d9dc4e5289a634e5cc21994 --repo szTheory/oarlock --json (run 36282241303 attempt 1 and retained artifact verified)
  - node scripts/jtbd_coverage.cjs --check-handoff --json (incomplete only for the observed dirty/locked worktrees; no stale-observation diagnostic)

### 8. Phase 36 Plan 03 / D3 — Keep future and downstream claims within evidence
expected: Future jobs remain candidates or conditional, unsupported adopter ownership remains unknown, Accrue ownership stays external, and required CI protects these boundaries.
result: pass
source: automated
coverage_id: D3
verification:
  - node --test scripts/jtbd_coverage.test.cjs (future discovery and Accrue source ownership boundary test passed)
  - node --test scripts/ci_workflow_contract.test.cjs (integration seam, demo E2E, and package smoke remain in required CI)

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None. No human UAT checkpoint remains. The linked-worktree ownership and shared-checkout disposition are separately surfaced external closeout actions, not unverified phase behavior.
