---
phase: 31-repository-planning-truth
verified: 2026-09-09T20:05:56Z
status: gaps_found
score: 10/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
unverified_prohibitions: 6
gaps:
  - truth: "Repository inventory and planning authorities are repository-bounded, evidence-backed, and fail closed on unsafe source paths."
    status: failed
    reason: "Intermediate symlinks let canonical planning documents resolve outside the repository, and the ownership registry reader follows an arbitrary symlink. External planning content and ownership claims are therefore accepted as repository truth."
    artifacts:
      - path: "scripts/lib/repository_truth.cjs"
        issue: "readPlanningFile checks lexical containment and only the final path entry; intermediate symlinks are followed."
      - path: "scripts/repository_inventory.cjs"
        issue: "readRegistry uses statSync/readFileSync without symlink, realpath-containment, regular-file, or same-descriptor checks."
    missing:
      - "Resolve and enforce real repository containment for canonical files and traversed planning directories."
      - "Open/fstat/read one no-follow regular-file descriptor for planning sources and the ownership registry."
      - "Add intermediate-symlink and registry-symlink fail-closed tests."
  - truth: "Archives, caches, summaries, and unrelated phase directories cannot create completion proof or healthy routing."
    status: failed
    reason: "Completion artifacts are selected globally by basename and completion status is matched anywhere in Markdown. Same-named files in an unrelated phase directory, or body-only status lines without YAML frontmatter, produce a fully healthy completion result."
    artifacts:
      - path: "scripts/lib/repository_truth.cjs"
        issue: "artifactForPlan and verification lookup use global endsWith searches; summary/verification checks use multiline regexes over entire documents."
      - path: "scripts/planning_health.test.cjs"
        issue: "The phantom test uses unrelated basenames and does not exercise same-basename evidence injection or body-only status text."
    missing:
      - "Resolve exactly one canonical directory for the phase and scope every plan, summary, and verification lookup to it."
      - "Parse and validate only leading YAML frontmatter status fields."
      - "Add adversarial same-basename-decoy and no-frontmatter completion tests."
  - truth: "Milestone history detects exact phase-range contradictions."
    status: failed
    reason: "The phase-range validator uses substring matching, so expected range 8-13 is accepted inside contradictory value 18-130."
    artifacts:
      - path: "scripts/lib/repository_truth.cjs"
        issue: "validateMilestoneHistory compares actualPhases.includes(expected.phases) instead of exact normalized endpoints."
      - path: "scripts/planning_health.test.cjs"
        issue: "History fixtures do not test prefix/suffix ranges that contain the expected range as a substring."
    missing:
      - "Parse normalized phase endpoints and compare the complete range exactly."
      - "Add an adversarial 8-13 versus 18-130 regression test."
  - truth: "Planning health distinguishes incomplete Git identity collection from a real history contradiction and exits 2 with actionable evidence."
    status: failed
    reason: "collectTagIdentities silently returns an empty list when tag enumeration fails, and readPackageVersion turns git-show failures into ordinary unknown values. Planning health then emits policy mismatches or unknowns with exit 1 instead of an incomplete-snapshot diagnostic and exit 2."
    artifacts:
      - path: "scripts/lib/repository_truth.cjs"
        issue: "Git identity failures are swallowed at lines 633-645 and never enter snapshot.collectionErrors."
      - path: "scripts/planning_health.test.cjs"
        issue: "Identity tests cover successful Git reads only; no failed enumeration or failed tag-content read is asserted."
    missing:
      - "Propagate structured Git identity collection errors into the planning snapshot with incomplete: true."
      - "Reserve an empty tag list and unknown package version for successful absence, not failed observation."
      - "Add failed for-each-ref and git-show tests proving exit 2 and cause-preserving diagnostics."
---

# Phase 31: Repository & Planning Truth Verification Report

**Phase Goal:** Maintainers and GSD workflows can begin work from one accurate, non-destructive view of repository state, active scope, and project history.
**Verified:** 2026-09-09T20:05:56Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Roadmap success criteria are listed first, followed by the non-duplicate PLAN truth contracts.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Maintainer can run one read-only inventory and see dirty paths, divergence, all linked worktrees/locks, ownership, and dispositions before changes. | ✗ FAILED | The live CLI reports the requested fields and did not change Git status, but `readRegistry` follows an arbitrary symlink and accepts external claims as repository ownership (`scripts/repository_inventory.cjs:30-33`). |
| 2 | Maintainer and GSD routing identify the same active milestone; inert artifacts cannot create phantom work. | ✗ FAILED | An in-memory adversarial snapshot containing only `31-*` proof files under `.planning/phases/99-decoy/` returned no completion diagnostics. Global basename lookup at `repository_truth.cjs:972-975,1011-1012,1049` grants unrelated directories proof authority. |
| 3 | Maintainer can navigate continuous history whose status, phase range, archive links, planning IDs, and package semantics agree. | ✗ FAILED | `validateMilestoneHistory` accepted `18-130` for expected `8-13`; tag-collection failures are also silently converted to absence/unknown (`repository_truth.cjs:623-654,695-696`). |
| 4 | Planning health is non-mutating and produces actionable failures for stale artifacts, broken references, archive contradictions, and unproven completion. | ✗ FAILED | The CLI is non-mutating, but same-basename decoys and body-only `status: complete/passed` text yielded zero completion diagnostics; intermediate symlink sources and failed Git inspection also do not fail as incomplete. |
| 5 | D-01: One normalized inventory result drives human and JSON. | ✓ VERIFIED | CLI evaluates once and selects a renderer (`repository_inventory.cjs:47-62`); tracer/parity tests pass. |
| 6 | D-02: Observed facts remain separate from proposed dispositions. | ✓ VERIFIED | `evaluateRepositoryInventory` builds distinct facts/dispositions, and active tests assert observation preservation. |
| 7 | D-03: Ownership metadata is evidence-backed; unsupported claims remain unknown. | ✗ FAILED | Exact claim metadata exists, but an external JSON file reached via a registry symlink is accepted as a supported claim. |
| 8 | D-04: Intentional state remains visible/non-failing; unknown, unreadable, or unsafe state exits nonzero. | ✗ FAILED | Ordinary unknown/stale/ambiguous cases are tested, but unsafe symlink-backed ownership is accepted instead of rejected. |
| 9 | D-05: Inventory is report-only and does not change repository/worktree state. | ✓ VERIFIED | Focused read-only tests pass; live before/after Git-status hashes were identical. Git operations are argument-array allowlisted. |
| 10 | D-13/D-14/D-15 inventory diagnostics are stable, actionable, classified, and equivalent across views. | ✓ VERIFIED | Diagnostic schema validation, deterministic ordering, renderer parity, and hostile terminal escaping tests pass. |
| 11 | D-06: Planning health names and enforces the canonical owner for each datum. | ✗ FAILED | `readPlanningFile` follows intermediate symlinks, so externally stored content is labeled as repository canonical authority (`repository_truth.cjs:819-833`). |
| 12 | D-07: Canonical disagreements block without choosing a winner. | ✓ VERIFIED | Authority-conflict test passes and `resolveActiveScope` returns `active: null` with both values. |
| 13 | D-08: Merely present archives/caches/phase artifacts cannot activate or complete work. | ✗ FAILED | Same-basename artifacts from an unrelated directory complete a phase; body status lines also substitute for structured proof. |
| 14 | D-09: Health reports authority and inert repair proposals without applying repair. | ✓ VERIFIED | CLI exposes no repair/apply option, diagnostic repairs are data, and live/test manifests remain unchanged. |
| 15 | D-10: state.json is non-authoritative unless a demonstrated versioned consumer requires it. | ✓ VERIFIED | Mirror data does not influence active scope; no-consumer and invalid-metadata tests pass. |
| 16 | D-13/D-14/D-15 authority/completion diagnostics share stable actionable human/JSON conclusions. | ✓ VERIFIED | Existing conflict/completion/parity tests pass for covered cases, and all records use `makeDiagnostic`. |
| 17 | D-11: Frozen history remains byte-unchanged; corrections are additive. | ✓ VERIFIED | `git diff --exit-code -- .planning/milestones` passes; current EVIDENCE contains dated correction rows and tests preserve archive bytes. |
| 18 | D-12: Milestone, tag, source SHA, package version, and publication are separately sourced identities. | ✗ FAILED | The nominal model has five fields, but failed tag enumeration becomes an empty list and failed tagged-file reads become ordinary unknowns, conflating observation failure with actual absence. |
| 19 | D-13: History diagnostics correctly classify contradictions, caveats, and healthy exceptions. | ✗ FAILED | A Git observation failure is misreported downstream as an ordinary tag/policy mismatch rather than incomplete collection. |
| 20 | D-14: Every history diagnostic preserves the actual evidence and safe proposal. | ✗ FAILED | Swallowed `for-each-ref`/`git show` errors lose the causal evidence and therefore cannot provide the correct actionable repair. |
| 21 | D-15: Human and JSON history views preserve identical ordered codes/conclusions. | ✓ VERIFIED | Shared evaluated result and renderers are wired; parity tests and live JSON inspection pass. |

**Score:** 10/21 truths verified (0 present-but-behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scripts/lib/repository_truth.cjs` | Shared inventory/planning/history collection and evaluation | ⚠️ SUBSTANTIVE + WIRED, DEFECTIVE | 1,185 lines and all exports exist, but four reproduced fail-open/false-conclusion defects reside here. |
| `scripts/repository_inventory.cjs` | Read-only inventory CLI | ⚠️ SUBSTANTIVE + WIRED, DEFECTIVE | CLI is runnable and read-only; registry loading follows arbitrary symlinks. |
| `scripts/repository_inventory.test.cjs` | Inventory integration/no-mutation proof | ✓ VERIFIED | 388 lines; active behavioral tests pass with no skips. Missing registry-symlink regression coverage is a quality warning. |
| `.planning/repository-ownership.json` | Versioned exact ownership claims | ✓ VERIFIED | Schema and required claim metadata are present; loader boundary remains defective. |
| `scripts/planning_health.cjs` | Read-only planning-health CLI | ✓ VERIFIED | Thin collect/evaluate/render CLI, no mutation mode, live invocation exit 0 with warnings. |
| `scripts/planning_health.test.cjs` | Authority/completion/history fixture matrix | ⚠️ SUBSTANTIVE + WIRED, INCOMPLETE | 356 lines and 17 active tests pass, but the six reproduced adversarial paths are absent. |
| `.planning/GSD-PREFERENCES.md` | Documented authority chain and shared command | ✓ VERIFIED | Lines 49 and 60-67 document the command and datum owners. |
| `.planning/MILESTONES.md` | Continuous shipped-history navigation and identities | ✓ VERIFIED | v1.2/v1.4 entries and immutable archive links exist; current content is healthy under nominal collection. |
| `.planning/EVIDENCE.md` | Additive reconciliation evidence | ✓ VERIFIED | Dated v1.2/v1.4/v1.5 rows and non-inference rules exist at lines 37-45. |

**Artifacts:** 6/9 fully verified; 3 substantive/wired artifacts contain or omit blocking behavior.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `repository_inventory.cjs` | `repository_truth.cjs` | collect/evaluate once, renderer selection | ✓ WIRED | Calls at lines 47 and 61-62. |
| `repository_truth.cjs` | `repository-ownership.json` | registry classification | ⚠️ PARTIAL | Data is used without overwriting observations, but CLI loading is not repository-bounded. |
| `planning_health.cjs` | `repository_truth.cjs` | collect/evaluate once | ✓ WIRED | Calls at lines 42-44. |
| `GSD-PREFERENCES.md` | `planning_health.cjs` | maintainer/GSD entry command | ✓ WIRED | Command documented at line 49. |
| `repository_truth.cjs` | `ROADMAP.md` + `STATE.md` | active graph/pointer resolution | ⚠️ PARTIAL | Resolution logic is wired, but intermediate symlinks can replace the purported authorities. |
| `repository_truth.cjs` | `MILESTONES.md` | history validation | ⚠️ PARTIAL | Validator runs, but phase-range comparison is substring-based. |
| `MILESTONES.md` | `EVIDENCE.md` | dated correction references | ✓ WIRED | Corrections and proof limitations are explicitly linked. |
| `repository_truth.cjs` | `mix.exs`/Git tags | independent identity collection | ⚠️ PARTIAL | Successful reads flow; failures are silently downgraded to absence/unknown. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Inventory CLI | worktree facts | Git porcelain/status/prune dry-run | Yes | ✓ FLOWING |
| Inventory CLI | ownership/disposition | `.planning/repository-ownership.json` | Yes, but unsafe source containment | ⚠️ UNSAFE SOURCE |
| Planning-health CLI | active scope | ROADMAP + STATE | Yes, but intermediate symlink escape is possible | ⚠️ UNSAFE SOURCE |
| Planning-health CLI | completion proof | phase artifacts + REQUIREMENTS + EVIDENCE | Yes, but artifact directory/frontmatter boundaries are not enforced | ✗ FALSE-PROOF PATH |
| Planning-health CLI | release identities | local tags + tagged/current `mix.exs` | Only on success; failures disappear | ✗ INCOMPLETE FLOW |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase Node behavior suite | `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs` | 31/31 passed | ✓ PASS |
| Workspace Elixir regression | `ASDF_ERLANG_VERSION=28.4.1 mix test` | 224 tests, 0 failures | ✓ PASS |
| Live inventory is report-only | inventory JSON plus before/after Git-status hash | Exit 1 for five real unclassified hazards; hash unchanged | ✓ PASS |
| Live planning health | `node scripts/planning_health.cjs --json` | Exit 0; 0 errors, 4 warnings, 8 info | ✓ PASS (nominal only) |
| Same-basename decoy completion | direct `validateCompletionProof` adversarial snapshot | `[]` diagnostics from proof files under `99-decoy` | ✗ FAIL |
| Body-only completion status | direct `validateCompletionProof` adversarial snapshot | `[]` diagnostics without YAML frontmatter | ✗ FAIL |
| Intermediate planning symlink | temporary repository with `.planning` symlink outside root | External PROJECT read; no `PAUTH_SOURCE_UNREADABLE` | ✗ FAIL |
| Ownership registry symlink | `readRegistry` against symlinked external JSON | External `secret` field read | ✗ FAIL |
| Tag enumeration failure | `collectTagIdentities` with failing runner | Returned `[]`, preserving no collection error | ✗ FAIL |
| Exact phase range | expected `8-13`, actual `18-130` | No `PHIST_PHASE_RANGE_MISMATCH` | ✗ FAIL |

## Probe Execution

No phase probes were declared and no conventional `scripts/*/tests/probe-*.sh` files exist. Step 7c: N/A.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| REPO-01 | 31-01 | Read-only complete repository/worktree inventory with ownership/disposition | ✗ BLOCKED | Core Git inventory and no-mutation behavior work, but symlinked registry content is accepted as repository ownership and can disclose external JSON. |
| REPO-02 | 31-02 | One authority chain immune to phantom artifact presence | ✗ BLOCKED | Same-basename artifacts in an unrelated phase directory satisfy completion proof; intermediate symlink documents are treated as canonical. |
| REPO-03 | 31-03 | Complete navigable history with agreeing identities/semantics | ✗ BLOCKED | Phase ranges are not compared exactly and Git identity collection failure is conflated with actual absence. |
| REPO-04 | 31-02, 31-03 | Non-mutating actionable planning-health diagnostics | ✗ BLOCKED | The command is non-mutating, but invalid decoy/body proof passes and Git failures do not produce incomplete exit-2 diagnostics. |

All four requirement IDs declared across PLAN frontmatter exist in REQUIREMENTS.md and map only to Phase 31. No orphaned Phase 31 requirement IDs were found.

## Prohibition Verification

All six PLAN prohibitions remain `flagged_unverified` with no `verification` tier. The judgments below are therefore non-authoritative and require maintainer review even where automated evidence supports them.

| Prohibition | Verdict | Evidence |
|---|---|---|
| REPO-01 must not authorize alteration/discard/unlock/concealment | NON-AUTHORITATIVE PASS, FLAGGED | Git allowlist and no-mutation tests/live hash support report-only behavior. |
| REPO-01 must not present unsupported/stale/partial collection as fact | ✗ FAILED, FLAGGED | Symlinked external ownership is accepted; unsafe source provenance is not surfaced. |
| REPO-02 inert artifacts must not gain routing/completion authority | ✗ FAILED, FLAGGED | Same-basename decoy artifacts provide completion proof. |
| REPO-04 must not apply repair or conceal authority conflict to appear healthy | ✗ FAILED, FLAGGED | Repair remains inert, but body-only and decoy proof conceal absent authoritative completion and return healthy. |
| REPO-03 must not rewrite frozen archives | NON-AUTHORITATIVE PASS, FLAGGED | Archive diff is clean and tests preserve archive bytes. |
| REPO-03 must not infer package/publication from milestone/tag | NON-AUTHORITATIVE PASS, FLAGGED | Publication remains explicit unknown; however Git collection failure handling still needs repair. |

## Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `scripts/repository_inventory.test.cjs` | REPO-01 | 14 | 0 | No | Behavioral | ⚠️ Missing registry-symlink/source-boundary adversarial case |
| `scripts/planning_health.test.cjs` | REPO-02/03/04 | 17 | 0 | No | Behavioral | ⚠️ Missing same-basename decoy, body-frontmatter, intermediate-symlink, Git-failure, and exact-range adversarial cases |

**Disabled tests on requirements:** 0. **Circular expected-value generation:** 0. **Insufficient coverage areas:** 6.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/lib/repository_truth.cjs` | 972-975 | Global `endsWith` artifact selection | 🛑 Blocker | Unrelated phase directories can supply completion proof. |
| `scripts/lib/repository_truth.cjs` | 1004-1015 | Whole-document status regex | 🛑 Blocker | Body prose can impersonate YAML proof metadata. |
| `scripts/lib/repository_truth.cjs` | 819-833 | Lexical-only containment | 🛑 Blocker | Intermediate symlinks supply external canonical planning content. |
| `scripts/repository_inventory.cjs` | 30-33 | Follow-symlink stat/read pair | 🛑 Blocker | External registry JSON is read and may be disclosed. |
| `scripts/lib/repository_truth.cjs` | 623-654 | Swallowed Git inspection errors | 🛑 Blocker | Incomplete observation becomes a false policy conclusion. |
| `scripts/lib/repository_truth.cjs` | 695-696 | Substring range comparison | 🛑 Blocker | Contradictory phase ranges can pass. |
| `scripts/lib/repository_truth.cjs` | 919-931 | Hard-coded unused Phase 31 corroboration | ⚠️ Warning | Adds a future wrong-phase/process failure surface without influencing conclusions. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers and no disabled requirement-linked tests were found.

## Decision Coverage

All 15 trackable Phase 31 CONTEXT.md decisions were found in shipped artifacts by the non-blocking decision-coverage gate. The behavioral defects above show that translation into artifacts did not make every decision true.

## Human Verification Required

N/A — infrastructure/tooling phase with no user-facing elements. All goal criteria are programmatically testable. Six unresolved prohibition flags are recorded above for explicit maintainer review; they do not replace the four blocking automated gaps.

## Deferred Items

None. Phases 32-36 do not specifically own Phase 31's source containment, completion-proof scoping/frontmatter, exact milestone-range validation, or Git identity collection error handling.

## Gaps Summary

Phase 31 is not ready to proceed. Nominal tests and live commands pass their expected contracts, but independent adversarial checks reproduce all six BLOCKER hypotheses from 31-REVIEW.md. The defects cluster into four repair concerns: repository-bounded source reads, canonical completion-proof parsing, exact history comparison, and fail-closed Git identity collection. The review warning about hard-coded unused corroboration is also confirmed but does not independently block the goal.

---

_Verified: 2026-09-09T20:05:56Z_
_Verifier: the agent (gsd-verifier)_
