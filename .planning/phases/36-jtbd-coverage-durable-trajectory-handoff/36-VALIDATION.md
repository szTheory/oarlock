---
phase: "36"
slug: "jtbd-coverage-durable-trajectory-handoff"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-26"
---

# Phase 36 — Validation Strategy

> Post-execution validation. Every plan task has behavior-targeted automated coverage; live authority and hosted evidence are recorded separately where fixtures cannot establish current external state.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in `node:test` for repository scripts. No SDK behavior or Elixir source change is in scope. |
| **Config file** | `.github/workflows/ci.yml`; Node tests run from the repository scripts tree. |
| **Quick run command** | `node --test scripts/jtbd_coverage.test.cjs` after Plan 01 Task 1 creates it. |
| **Full relevant suite** | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` |
| **Estimated runtime** | Measure the targeted test command during execution; keep focused checks under 30 seconds where practical. |

## Sampling Rate

- **After each implementation task:** Run the focused `node:test` file covering the changed record parser, validator rule, or navigation contract.
- **After each plan wave:** Run `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` when the wave changes repository tooling or planning contracts.
- **Before phase closeout:** Run the required local checks and obtain hosted CI proof for the exact candidate SHA. Record the run and artifact identity; a scheduled or different-SHA run is not a substitute.
- **CI integration:** Extend the existing planning-truth checks only if the plan documents recurring risk reduction that justifies the CI cost. Do not create a second definition of green.

## Plan Task → Verification Map

Every command below is specified in the corresponding task's `<automated>` field. All outcomes remain pending; these commands have not run during planning.

| Plan / task | Requirement IDs | Automated command | Dependency / intent | Status |
|-------------|-----------------|-------------------|---------------------|--------|
| 36-01 Task 1, tracer | ORIENT-01, ORIENT-02, ORIENT-03, ORIENT-05 | `node --test scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Wave 0 fixture precedes implementation. Full Node regression: 213 passed; focused JTBD suite and live 18-record map passed. Later Phase 36 coverage also tests dated sources, conservative ownership, and promotion boundaries; no external adoption is inferred. | Pass |
| 36-01 Task 2 | ORIENT-01, ORIENT-02, ORIENT-03, ORIENT-04 | `node --test scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Canonical records, both indexes, field/status axes, and dated transition behavior are exercised by fixtures; full Node regression: 213 passed. | Pass |
| 36-02 Task 1 | ORIENT-02, ORIENT-03, ORIENT-04, ORIENT-05 | `node --test scripts/jtbd_coverage.test.cjs scripts/history_integrity.test.cjs && node scripts/jtbd_coverage.cjs --json` | Cross-authority negative cases and immutable history-prefix fixtures pass in the full Node regression (213/213); live map reports zero diagnostics. | Pass |
| 36-02 Task 2 | ORIENT-05 | `node --test scripts/ci_workflow_contract.test.cjs scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Workflow contract and validator fixtures pass; measured full-map cost and existing aggregate integration are recorded in 36-02-SUMMARY.md. Exact candidate hosted CI also passed all eight required lanes. | Pass |
| 36-03 Task 1 | ORIENT-02, ORIENT-03, ORIENT-05, ORIENT-06 | `node --test scripts/jtbd_coverage.test.cjs` | Dirty/locked, wrong-SHA, missing-proof, candidate-status, and honest-handoff cases pass in the full Node regression (213/213). Fresh inventory is recorded in the handoff; unresolved state remains explicit. | Pass |
| 36-03 Task 2 | ORIENT-05, ORIENT-06 | Candidate identity receipt; `node scripts/jtbd_coverage.cjs --check-handoff --json`; and `node scripts/ci_remote_gate.cjs candidate --sha c5bcc7b331640c1d1d9dc4e5289a634e5cc21994 --repo szTheory/oarlock --json`; verify PR #21 is open on `main` at that SHA. | Candidate identity, PR #21, run 36282241303 attempt 1, all eight lanes, and retained artifact 10918748960 pass. CI event/head SHA is c5bcc7b; tested merge checkout SHA is c130cd6. The handoff check intentionally reports incomplete for observed dirty/locked worktrees. | Pass with blockers surfaced |

## Phase Requirements → Test Map

| Req ID | Behavior to verify | Test type | Planned automated command | Initial status |
|--------|--------------------|-----------|---------------------------|----------------|
| ORIENT-01 | Stable JTBD IDs resolve from the canonical records and both navigation views; missing and duplicate links are reported. | Fixture-backed contract plus live read | `node --test scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Pass |
| ORIENT-02 | Required dated provenance, owner, requirement/phase, proof, evidence, freshness, non-goal, and promotion/reopen fields are checked without inventing missing values. | Fixture-backed contract plus live read; unknown external adoption stays explicit | `node --test scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Pass; no human UAT required |
| ORIENT-03 | `short`/`mid`/`long` horizon is separate from all seven commitment status values. | Fixture-backed contract plus live read | `node --test scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Pass |
| ORIENT-04 | A dated transition can append while earlier rationale/evidence remains byte-identical; rewrite, deletion, or reordering is rejected against explicit Git objects. | Fixture-backed history contract | `node --test scripts/jtbd_coverage.test.cjs scripts/history_integrity.test.cjs && node scripts/jtbd_coverage.cjs --json` | Pass |
| ORIENT-05 | Missing, duplicate, contradictory, and unsafe cross-links yield actionable diagnostics; unknown ownership stays unknown and validation does not mutate inputs. | Fixture-backed plus live check; CI contract | `node --test scripts/ci_workflow_contract.test.cjs scripts/jtbd_coverage.test.cjs && node scripts/jtbd_coverage.cjs --json` | Pass |
| ORIENT-06 | Handoff separates observed repository/worktree state, exact target proof, blockers, caveats, and uncommitted candidates. | Fixture-backed contract plus exact-SHA hosted readback | Plan 36-03 Task 2's receipt-bound command above. | Pass; clean-close correctly blocked |

## Wave 0 Requirements

- [x] Map every generated plan task and requirement to its intended automated command. This is planning completeness only; no command has run.
- [x] Create `scripts/jtbd_coverage.test.cjs` before Plan 01 tracer implementation, with a failing end-to-end index-to-record case.
- [x] Add fixture cases before full validator implementation for missing/duplicate IDs, broken links, invalid horizon/status combinations, incomplete provenance, and contradictory ownership/evidence.
- [x] Add append-only history cases for valid dated append, rewrite/truncation, and retained prior rationale/evidence before Plan 02 history implementation.
- [x] Prove the validator is read-only by comparing fixture and repository inputs before and after diagnostics.
- [x] Add handoff fixtures for dirty/locked work, exact-SHA mismatch, missing proof, and candidate status before Plan 03 handoff checking.

## Remaining External Closure Actions (Not UAT)

| Action | Requirement | Why it remains external | Automated evidence and closure condition |
|--------|-------------|--------------------------|----------------------------------------|
| Establish authorized ownership and disposition for the dirty shared checkout and locked linked worktree; then prepare and verify the reviewed candidate SHA. | ORIENT-06 | Repository inventory can report dirty paths and lock metadata, but it cannot safely infer who owns another agent's work or authorize its disposition. | `node scripts/jtbd_coverage.cjs --check-handoff --json` reports the exact dirty/locked conditions and prevents a false clean claim. Close only after an authorized disposition, reviewed candidate, and exact-SHA hosted proof are recorded. |

Source paths, ownership categories, unknown adopter ownership, future status, and promotion gates are covered by deterministic fixtures and the live read-only validator. Those checks do not claim unobserved adoption; they enforce that it remains unknown until evidence exists. The measured runtime and recurring drift risk also justify the existing required planning-truth CI lane, whose wiring has a contract test. Neither item needs a human UAT checkpoint.

## Validation Sign-Off

- [x] Every plan task has an `<automated>` verification command or an explicit Wave 0 dependency.
- [x] Sampling continuity has no three consecutive implementation tasks without automated verification.
- [x] Wave 0 creates required tests before the behavior they cover.
- [x] No watch-mode commands are used.
- [x] Runnable automated commands state a corresponding failure condition in the plan.
- [x] Focused feedback latency is measured and recorded.
- [x] Exact-SHA hosted evidence is captured before closeout.
- [x] `nyquist_compliant: true` is set only after validation coverage is implemented and audited.

**Approval:** validated 2026-09-26; automation follow-up audited 2026-09-27. The source/owner contract is machine-checked by fixture tests and the live validator; unknown external ownership remains explicit rather than inferred. Full regression previously passed: Node 213/213 and ExUnit 275/275. Hosted CI run 36282241303 attempt 1 passed all eight required lanes and verified retained artifact 10918748960 (digest `sha256:bb04bd90cab3091c9a964887f312bbb1b5ab66183517cab5643de82b66eefa58`) for event/head SHA c5bcc7b; CI tested merge checkout SHA c130cd6. No human UAT checkpoint remains. External worktree ownership/disposition is a milestone closeout action, automatically surfaced by the handoff checker, not a test gap.

## Validation Audit 2026-09-26

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Audit 2026-09-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Human UAT checkpoints | 0 |
| External closeout actions | 1 |
