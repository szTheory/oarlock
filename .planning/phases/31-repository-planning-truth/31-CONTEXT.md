# Phase 31: Repository & Planning Truth - Context

**Gathered:** 2026-09-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one accurate, non-destructive view of repository state, active scope, and shipped history. This phase delivers read-only repository inventory, an explicit planning authority chain, reconciled milestone navigation, and non-mutating planning-health diagnostics. It may classify and propose dispositions or repairs, but it must not delete unclassified work, perform general cleanup, or absorb the CI, release, PR, triage, and worktree-lifecycle controls owned by later phases.

</domain>

<decisions>
## Implementation Decisions

### Repository inventory and classification
- **D-01:** The read-only inventory must produce both a concise human-readable report and deterministic JSON from the same underlying result.
- **D-02:** Keep observed facts separate from proposed disposition. Facts include dirty state, branch and upstream, ahead/behind counts, worktree HEAD, lock/prunable state, and process or ownership evidence. Dispositions are recommendations such as preserve, commit, hand off, ignore, repair, or remove.
- **D-03:** Ownership records include the claimed owner, provenance for that claim, confidence, and a revisit date. Anything not supported by evidence remains explicitly `unknown`.
- **D-04:** Known, intentionally preserved dirty or locked state is visible but does not fail by itself. Unclassified, unreadable, or unsafe state produces a nonzero exit.
- **D-05:** Inventory and health tooling are report-only. They may propose a disposition but cannot apply cleanup or delete, unlock, reset, restore, prune, or force-remove anything.

### Planning authority and conflict handling
- **D-06:** Canonical ownership is assigned by datum: `REQUIREMENTS.md` owns committed milestone scope; `ROADMAP.md` owns the active phase graph and requirement mapping; `STATE.md` owns the current execution pointer and session state; `PROJECT.md` owns durable project scope and constraints; `MILESTONES.md` plus archived milestone files own shipped-history navigation; `EVIDENCE.md` owns proof classification and corrections.
- **D-07:** Canonical disagreements fail routing with an actionable conflict instead of silently choosing the newest file or a convenient winner.
- **D-08:** A phase directory, plan, summary, verification file, archive, cache, or research artifact never makes work active or complete by mere presence. Active status requires an explicit current-roadmap and current-state reference; completion requires the defined proof chain.
- **D-09:** Planning-health checks are read-only and show the governing authority plus a proposed patch. Repairs are separate, explicit actions that use supported GSD handlers and record a dated correction.
- **D-10:** Keep `.planning/state.json` only if a demonstrated consumer requires it. Otherwise remove or ignore it. If retained, it is an atomically regenerated, disposable mirror with source and schema/version metadata, never independent authority.

### Milestone history and health diagnostics
- **D-11:** Archived milestone snapshots remain immutable. Correct contradictions through dated errata in the current milestone/evidence ledger and repair current navigation links without rewriting what a historical snapshot originally said.
- **D-12:** Record planning milestone, Git tag, source SHA, declared Hex package version, and publication status as separate identities. Never imply that planning milestone `v2.1` means package version `2.1`; the repository currently declares package version `0.1.1`.
- **D-13:** Diagnostics use `error`, `warning`, and `info`. Errors block routing or completion. Warnings require an owner or revisit condition but do not block. Info records intentional exceptions and healthy facts.
- **D-14:** Every diagnostic is a stable actionable record containing a code, severity, affected artifact and field, expected and actual values, governing authority, evidence, and a safe next command or repair proposal.
- **D-15:** Human and JSON diagnostic views must preserve the same stable codes and conclusions so agents, CI, and maintainers cannot receive different truth from different formats.

### Agent's Discretion
- Exact command names, module boundaries, JSON field names, presentation order, and formatting are open to research and planning as long as the decisions above remain intact.
- The planner may select the implementation language and test harness that best fit the repository's existing Mix, shell, Node, and GSD tooling patterns.
- The precise invariant catalog and diagnostic code naming are flexible; it must cover all four Phase 31 requirements and the roadmap success criteria.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current scope and routing
- `.planning/PROJECT.md` — Durable SDK scope, constraints, current milestone direction, and planning boundaries.
- `.planning/REQUIREMENTS.md` — Canonical v2.2 requirements; Phase 31 owns REPO-01 through REPO-04.
- `.planning/ROADMAP.md` — Canonical active phase graph and Phase 31 goal, dependency, and success criteria.
- `.planning/STATE.md` — Current execution pointer, accumulated decisions, and known repository-state concerns.
- `.planning/GSD-PREFERENCES.md` — Repository-specific GSD policy, including research posture and the current worktree setting.
- `.planning/config.json` — Supported project workflow settings; do not infer policy from ignored global keys.

### Repository and planning truth research
- `.planning/research/SUMMARY.md` — v2.2 ordering, trust-chain findings, and Phase 31 deliverable summary.
- `.planning/research/ARCHITECTURE.md` — Planning artifact ownership table, inventory/classification model, and control-plane boundaries.
- `.planning/research/PITFALLS.md` — Non-destructive cleanup and phantom-scope failure modes with required mitigations.

### History and proof
- `.planning/MILESTONES.md` — Current shipped-milestone index, correction precedent, and known navigation gaps.
- `.planning/EVIDENCE.md` — Canonical proof ledger and append-only correction model.
- `.planning/milestones/v2.1-ROADMAP.md` — Most recent frozen roadmap snapshot.
- `.planning/milestones/v2.1-REQUIREMENTS.md` — Most recent frozen requirements snapshot and shipped requirement identities.

### Existing enforcement and derived state
- `bin/check_summary_drift.sh` — Existing fail-closed guard and Git-status reporting pattern to reuse or supersede deliberately.
- `.planning/state.json` — Current untracked contradictory mirror; inspect consumers before retaining it.

No external product specification or ADR was supplied for this phase. The repository-local sources above are canonical.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/check_summary_drift.sh`: existing shell guard that reports dirty paths and blocks unsupported completion claims; useful as a behavioral and testing precedent.
- GSD query handlers in the installed runtime: supported state and roadmap mutations already exist and should be used by any explicit repair flow instead of direct ad hoc edits.
- `.planning/EVIDENCE.md` and correction entries in `.planning/MILESTONES.md`: established additive correction patterns for proof and shipped history.

### Established Patterns
- The repository prefers deterministic local proof, stable machine-readable contracts, explicit evidence boundaries, and fail-closed behavior for unsupported claims.
- Planning documents are committed, while generated or cached artifacts do not gain authority merely because they exist.
- Existing user or concurrent-agent work is preserved. Unknown, dirty, or locked work blocks destructive action until ownership and disposition are explicit.

### Integration Points
- Repository inspection must cover the main worktree and every record returned by `git worktree list --porcelain -z`, plus stable Git status and branch/upstream data for each accessible tree.
- Planning validation connects `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `MILESTONES.md`, archived milestone files, phase artifacts, and `EVIDENCE.md` according to the authority chain above.
- The current baseline includes a modified `.tool-versions`, untracked `.planning/research/.cache/` and `.planning/state.json`, local `main` ahead of `origin/main`, and a locked linked agent worktree. Treat these as inventory seeds only; implementation must re-run read-only discovery rather than hard-code this snapshot.
- Milestone-history reconciliation must account for missing v1.2 and v1.4 index entries and the v1.5 archive links currently pointing at reused root files.

</code_context>

<specifics>
## Specific Ideas

- The human report and JSON output are two views of one result, not independently implemented truth paths.
- Reports should distinguish an intentionally preserved exception from an unresolved hazard; clean does not simply mean `git status` is empty.
- Repair guidance should identify the authoritative value and show a proposed change while leaving mutation to an explicit reviewed action.
- Historical version records should make the current `v2.1` planning/tag versus `0.1.1` package-version distinction unmistakable.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 31-repository-planning-truth*
*Context gathered: 2026-09-09*
