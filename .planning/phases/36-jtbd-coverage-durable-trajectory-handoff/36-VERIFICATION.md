---
phase: 36-jtbd-coverage-durable-trajectory-handoff
verified: 2026-09-27T17:04:21Z
status: passed
score: 12/12 must-haves verified
covered_files:

  - .github/workflows/ci.yml
  - .planning/BACKLOG-ARCHIVE.md
  - .planning/BACKLOG.md
  - .planning/EVIDENCE.md
  - .planning/GSD-PREFERENCES.md
  - .planning/JTBD-COVERAGE.md
  - .planning/MILESTONES.md
  - .planning/PERSONAS.md
  - .planning/WORKFLOWS.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-01-PLAN.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-01-SUMMARY.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-02-PLAN.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-02-SUMMARY.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-03-PLAN.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-03-SUMMARY.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-RESEARCH.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-REVIEW.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-SECURITY.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-UAT.md
  - .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-VALIDATION.md
  - .planning/v2.2-HANDOFF.md
  - scripts/ci_remote_gate.cjs
  - scripts/ci_workflow_contract.test.cjs
  - scripts/history_integrity.cjs
  - scripts/history_integrity.test.cjs
  - scripts/jtbd_coverage.cjs
  - scripts/jtbd_coverage.test.cjs
  - scripts/lib/repository_truth.cjs
  - scripts/repository_inventory.cjs
  - scripts/repository_inventory.test.cjs

covered_digest: "v1:sha256:83d30fff9a82e94ec7bba66a3c56876a5d73843fb7cde8cc1947d85abb189d7c"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 11/12
  gaps_closed:
    - ORIENT-02 source and ownership judgments now have dated-source, ownership, candidate-status, promotion-gate, and CI-wiring regression assertions.
  gaps_remaining: []
  regressions: []
decision_coverage:
  honored: 9
  total: 9
  not_honored: []
---

# Phase 36: JTBD Coverage, Durable Trajectory & Handoff Verification Report

**Phase Goal:** Maintainers and future agents can understand who oarlock serves, what is proven or missing, why the roadmap points where it does, and exactly what evidence closes v2.2.
**Verified:** 2026-09-27T17:04:21Z
**Status:** passed
**Re-verification:** Yes — Phase 36’s source/ownership review is covered by executable planning-contract tests and recorded as automated UAT.

## 2026-09-27 Phase 37 scope-accounting refresh

ORIENT-06 final operational acceptance is now assigned to Phase 37, from the existing milestone audit gap. Phase 36's implementation and 8/8 automated UAT remain complete. The only covered artifact changed during planning is the canonical JTBD map: its ORIENT-06 phase link moves to 37 and an additive dated transition records why. Requirement meaning, SDK/validator implementation, earlier history rows and future-candidate scope are unchanged.

Direct inline verification of that delta: the live map is healthy (18 records, zero diagnostics), planning authority maps ORIENT-06 to Phase 37, and the focused JTBD/history/CI suites pass 49/49 with zero skipped tests. The canonical covered-file fingerprint was recomputed after these checks. No UAT or hosted CI was rerun. The timestamped live-worktree and remote-proof observations below are retained historical evidence; Phase 37 planning changes mean they must not be read as a fresh final-closeout observation. New actual closeout proof belongs to Phase 37.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A maintainer can navigate from a persona or lifecycle question through stable JTBD IDs to canonical records with capability, gap, and ownership boundaries. | ✓ VERIFIED | Candidate c5 contains the canonical 18-record map and two link-only indexes. `node scripts/jtbd_coverage.cjs --json` from the candidate reports `healthy`, 18 IDs, and no diagnostics; each index links each ID once. |
| 2 | Each decision record exposes dated sources, rationale, owner/repository, scope links, proof/evidence, freshness, non-goals, and promotion/reopen conditions. | ✓ VERIFIED | Fixture tests verify dated source paths, accountable ownership, explicit unknown/external adopter ownership, and promotion gates; the live CLI checks the complete 18-record set against source and requirement authorities. These checks keep unobserved adoption explicitly unknown rather than claiming external truth. |
| 3 | Horizon and commitment status are separate, use the full taxonomy, and dated transitions preserve earlier rationale and evidence. | ✓ VERIFIED | The canonical records have separate fields and dated transition rows. The named append-only history test passed; the related base/head check rejects rewritten or removed rows. |
| 4 | The navigation validator is executable and read-only before the record set expands. | ✓ VERIFIED | Live CLI check returned healthy. Fixture coverage exercises missing, duplicate, wrong-ID, and unsafe links and byte/Git-state preservation. |
| 5 | Cross-links among JTBD records and authoritative requirements, phases, evidence, backlog/archive, trajectory, and milestone sources produce actionable diagnostics. | ✓ VERIFIED | `scripts/jtbd_coverage.cjs` resolves the authority files and emits structured diagnostics; fixture cases cover contradictory and missing authority references. Live candidate check has zero diagnostics. |
| 6 | Unknown ownership and historical or stale evidence remain explicit; validation does not promote claims or mutate sources. | ✓ VERIFIED | Records retain unknown/external ownership where appropriate; future jobs remain outside committed phases. The fixtures exercise these classifications and read-only behavior. |
| 7 | Recurring validation is justified by measured runtime and distinct drift risk, and is wired into required planning-truth CI. | ✓ VERIFIED | `36-02-SUMMARY.md` records five timing samples and the drift rationale. CI runs `node scripts/jtbd_coverage.cjs --json` in the required planning-truth job; its contract test is in the Node test glob. |
| 8 | The handoff reports observed repository and linked-worktree state without claiming dirty or locked work is clean. | ✓ VERIFIED | The refreshed root handoff records 116 status entries and one dirty, locked linked worktree at observation time `2026-09-27T14:27:03.233Z`. A fresh `node scripts/jtbd_coverage.cjs --check-handoff --json` reports only the root and linked-worktree dirty states plus the linked lock; it reports no stale-observation diagnostic. Clean closeout remains blocked. |
| 9 | The handoff binds the candidate to its exact hosted run and artifact while separating the PR event head from the tested merge checkout. | ✓ VERIFIED | PR #21 is OPEN on `main`, unmerged, at c5bcc7b. Run 36282241303 attempt 1 succeeded with all eight required lanes; event/head SHA is c5bcc7b, tested checkout is c130cd6, and artifact 10918748960 has digest `sha256:bb04bd90cab3091c9a964887f312bbb1b5ab66183517cab5643de82b66eefa58`. The live remote gate verified these identities. |
| 10 | Open blockers, the v0.1.2 caveat, and evidence-backed discovery candidates are explicit; candidates are not represented as committed work. | ✓ VERIFIED | The refreshed handoff keeps closeout blocked, links the historical caveat to EVIDENCE, and names next-cycle candidates. The canonical records and Future Requirements keep them outside committed scope. The updated Plan 03 summary records the 104-path observation, local automation results, and the exact hosted-proof boundary. |
| 11 | The handoff checker rejects missing or mismatched proof, false clean claims, and invalid candidate scope without changing repository state. | ✓ VERIFIED | The named proof-identity fixture test passed; related fixtures cover wrong SHA, missing proof, dirty/locked states, and candidate authority. The live handoff check preserves its explicit incomplete result for the actual dirty/locked observations. |
| 12 | A status or horizon change is checked against base/head history and cannot rewrite or truncate the earlier transition sequence. | ✓ VERIFIED | `node --test --test-name-pattern='JTBD history: dated transitions append while preserving earlier rows' scripts/history_integrity.test.cjs` passed (1/1). The test creates independent Git fixtures and verifies the appended transition. |

**Score:** 12/12 truths verified (0 behavior-unverified; 0 human UAT pending).

## Automation-First Verification Follow-Up

All eight coverage entries from the three Phase 36 summaries now classify as automated. The former Plan 01 human-only source/ownership entry has targeted tests for dated citations, conservative ownership, and promotion boundaries; the checks do not infer external adoption. The required CI wiring for the seam, demo E2E, and package smoke is protected by a contract test. `.planning/GSD-PREFERENCES.md` makes repeatable automated verification the default for future phases. UAT is complete with eight automated passes and zero human checkpoints. External PR review, publication, and ambiguous worktree ownership remain explicit human or external-state boundaries.

Local follow-up evidence: the focused Phase 36 Node suites passed 49/49 tests in this verification run; the live JTBD map returned `healthy` for all 18 records. The earlier full Node suite passed 250/250, the Accrue seam passed 14/14, the demo billing E2E passed 2/2, and package smoke passed. The current handoff checker reports only the observed dirty/locked worktrees. The changes remain uncommitted in the shared checkout and are not represented by the older hosted exact-SHA run for candidate `c5bcc7b`.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.planning/JTBD-COVERAGE.md` | Canonical source-backed jobs and trajectory | ✓ VERIFIED | 18 stable records, separate horizon/status fields, dated history, evidence classes, identity, and caveats. |
| `.planning/PERSONAS.md`, `.planning/WORKFLOWS.md` | Two navigation indexes | ✓ VERIFIED | Link-only indexes; live CLI confirms all canonical IDs resolve once from both. |
| `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-VALIDATION.md` | Nyquist requirement-to-test map | ✓ VERIFIED | All phase requirements have executable coverage; no human UAT gap remains. Mutable worktree ownership is tracked separately as a closeout action. |
| `scripts/jtbd_coverage.cjs` | Bounded read-only validator and handoff checker | ✓ VERIFIED | Substantive implementation connected to repository authority reads and CLI entry point; live coverage and handoff checks exercised. |
| `scripts/jtbd_coverage.test.cjs`, `scripts/history_integrity.test.cjs` | Contract and history tests | ✓ VERIFIED | Active fixture tests cover navigation, authority contradictions, read-only behavior, exact proof, and immutable history. |
| `.github/workflows/ci.yml`, `scripts/ci_workflow_contract.test.cjs` | Required CI wiring and contract | ✓ VERIFIED | JTBD validation is in the existing required planning-truth job; CI contract verifies the wiring. |
| `.planning/v2.2-HANDOFF.md` | Fresh exact-target handoff and explicit blockers | ✓ VERIFIED | Current root copy contains PR #21 and the verified proof identities. Candidate c5's committed copy is the earlier honest pending-proof snapshot; post-run proof belongs to the refreshed root handoff, whose document SHA is explicitly unknown because it is uncommitted. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Persona index | Canonical JTBD record | Stable ID and relative anchor | WIRED | Live CLI and fixture verify unique link-to-record resolution. |
| Lifecycle index | Same canonical record | Stable ID and relative anchor | WIRED | Live CLI confirms identical complete coverage. |
| JTBD references | Requirements, roadmap, evidence, backlog/archive, milestones | Bounded authority reads and diagnostics | WIRED | Candidate CLI is healthy against the live authority set; negative fixtures cover malformed and contradictory links. |
| Base/head Git objects | JTBD transition sequence | `history_integrity.cjs` append-only comparison | WIRED | Named behavioral test passed; CI test glob includes this suite. |
| Planning-truth workflow | Live JTBD CLI and tests | Required workflow step plus existing Node glob | WIRED | Workflow contract test and hosted planning-truth lane pass. |
| Fresh inventory and candidate identity | Root handoff | Read-only inventory, PR lookup, remote proof gate | WIRED | Handoff check reports only explicit dirty/locked blockers; live gate confirms PR/run/artifact identity. |

## Data-Flow Trace

The deliverables are Markdown planning records and validators, not rendered dynamic data. Authority values flow from repository files through bounded reads into deterministic diagnostics; no UI or database data path applies.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Candidate/source/ownership judgments stay evidence-bounded | `node --test --test-name-pattern='future discovery and Accrue source ownership judgments stay bounded' scripts/jtbd_coverage.test.cjs` | 1 targeted test passed; 15/15 JTBD coverage tests passed | ✓ PASS |
| Required CI retains the integration seam, demo E2E, and package smoke | `node --test --test-name-pattern='integration seam, demo E2E, and package smoke stay in required CI' scripts/ci_workflow_contract.test.cjs` | 1 targeted CI contract passed | ✓ PASS |
| Accrue integration seam | `mix test test/paddle/seam_test.exs` | 14 tests passed | ✓ PASS |
| Demo billing E2E flows | `cd demo && mix test test/demo_web/integration/billing_flow_test.exs` | 2 tests passed | ✓ PASS |
| Fresh packaged-consumer smoke | `bin/package_smoke.sh` | Fresh dependency consumer compiled; smoke passed | ✓ PASS |
| Complete recurring Node suite | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` | 250 tests passed | ✓ PASS |
| Append a dated transition while preserving prior history | `node --test --test-name-pattern='JTBD history: dated transitions append while preserving earlier rows' scripts/history_integrity.test.cjs` | 1 test passed | ✓ PASS |
| Recorded run/artifact identities must match live hosted proof | `node --test --test-name-pattern='handoff requires the recorded run and artifact to match live hosted proof' scripts/jtbd_coverage.test.cjs` | 1 test passed | ✓ PASS |
| Live map has complete, resolvable coverage | `node scripts/jtbd_coverage.cjs --json` (shared checkout) | 18 records, `healthy`, zero diagnostics | ✓ PASS |
| Current candidate has exact hosted proof | `node scripts/ci_remote_gate.cjs candidate --sha c5bcc7b331640c1d1d9dc4e5289a634e5cc21994 --repo szTheory/oarlock --json` | Run 36282241303 attempt 1 and retained artifact verified; eight lanes succeeded | ✓ PASS |
| Handoff accurately reports current local blockers | `node scripts/jtbd_coverage.cjs --check-handoff --json` (shared root, 2026-09-27T14:27:03.233Z observation) | `incomplete` with exactly the expected main dirty, linked dirty, and linked lock diagnostics; no stale-observation diagnostic | ✓ PASS |

## Probe Execution

No phase-declared or conventional `probe-*.sh` files were found. Not applicable.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| ORIENT-01 | 36-01 | Canonical persona/JTBD map and ownership boundary | SATISFIED | Healthy 18-record live map and both indexes resolve every ID once. |
| ORIENT-02 | 36-01, 36-02, 36-03 | Dated provenance, ownership, proof, freshness, non-goal, promotion/reopen contract | SATISFIED | Phase 36 Plan 01 D2 and Plan 03 D3 now have passing automated coverage for dated source paths, conservative ownership boundaries, non-goals, and promotion conditions; the live validator checks all records and authority mappings. No external-adoption claim is inferred. |
| ORIENT-03 | 36-01, 36-02, 36-03 | Separate horizon and commitment status | SATISFIED | Distinct fields and all seven status values are present and checked. |
| ORIENT-04 | 36-01, 36-02, 36-03 | Append-only dated transitions | SATISFIED | Named transition test passed; rewrite/truncation cases are covered. |
| ORIENT-05 | 36-01, 36-02, 36-03 | Validator detects broken and contradictory links | SATISFIED | Live validation healthy; fixture cases exercise bad authority links. |
| ORIENT-06 | 36-03; operational follow-through in Phase 37 | Handoff records state, exact proof, blockers, caveats, and candidates | IMPLEMENTATION VERIFIED; FINAL ACCEPTANCE PHASE 37 | Historical Phase 36 handoff/proof observations are retained. Phase 37 owns final clean-worktree and reconciled-candidate acceptance. |

## Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---|---|---|---|---|
| `scripts/jtbd_coverage.test.cjs` | ORIENT-01, 02, 03, 05, 06 | Enabled | None found | None found | Value and multi-step contract assertions against independently authored fixtures | Adequate |
| `scripts/history_integrity.test.cjs` | ORIENT-04 | Enabled | None found | None found | Git-object transition and rejection assertions | Adequate |
| `scripts/ci_workflow_contract.test.cjs` | ORIENT-05 | Enabled | None found | None found | Workflow/job/step identity assertions | Adequate |

## Security and Review

The final candidate review reports zero findings. The security audit closes 10 of 11 threats; T-36-03 remains one medium, non-blocking diagnostic-disclosure hardening item under the high-severity blocking threshold. No high-severity threat remains open.

## Decision Coverage

All 9 trackable decisions in `36-CONTEXT.md` are represented in shipped artifacts. The gate is warning-only and does not affect the status.

## Automated Source and Ownership Verification

The former human checkpoint is covered by the `D2` automated entry in `36-01-SUMMARY.md` and the `D3` entry in `36-03-SUMMARY.md`. Tests verify dated source paths, accountable repository ownership, explicit unknown adopter ownership, future-only status, non-goals, and promotion gates for support/finance/reconciliation/quote jobs. Separate assertions bind Accrue ownership to active backlog item B-04, preserve unconfirmed-adoption and call-site caveats, and require a named downstream owner. The read-only JTBD validator checks all 18 records' local source paths and authoritative requirement mappings; it does not claim real-world adoption absent external evidence.

The required CI contract also protects the recurring root seam test, demo E2E tests, package smoke, and planning-truth test lane. UAT records each of the eight summary coverage entries as a separate automated pass. No human UAT checkpoint remains.

## Gaps Summary

No implementation or UAT gap remains for Phase 36; the canonical verification status is `passed`. ORIENT-06 is satisfied as accurate blocker reporting. v2.2 clean closeout remains blocked by the observed dirty shared checkout and one dirty locked linked worktree; that operational state remains visible and is not misreported as clean. The candidate PR remains open and unmerged as required. This local automation update has not been pushed, so the previously recorded hosted exact-SHA proof applies to candidate `c5bcc7b` only.

---

_Verified: 2026-09-27T16:36:49Z_  
_Verifier: the agent (gsd-verifier)_
