# Phase 36: JTBD Coverage, Durable Trajectory & Handoff - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Give maintainers and future agents a durable, evidence-backed view of who Oarlock serves, what is proven or missing, why the roadmap points where it does, and what evidence closes v2.2. Establish a canonical map of relevant personas and stable JTBD IDs, source-backed capability decisions, separate horizon and commitment status, append-only decision history, deterministic cross-link validation, and an exact-SHA/evidence-complete milestone handoff. Keep this phase within repository-local planning and documentation; it does not add SDK endpoints, Phoenix UI, Ecto persistence, provider behavior, or new commitments beyond the roadmap.

</domain>

<decisions>
## Implementation Decisions

### Persona boundary and coverage
- **D-01:** Use a layered persona map. Name direct Oarlock audiences (adopter engineers, downstream SDK maintainers such as Accrue, and project maintainers/future planners) distinctly from evidence-backed external actors and jobs. Include external jobs only with a dated source, accountable owner/repository, and explicit `external`, `candidate`, or other applicable status. Support, finance, and reconciliation operators remain candidates until adopter evidence supports promotion. Treat Paddle as a provider boundary, not a human persona; do not infer demand or transfer app/provider work into the SDK.
- **D-02:** Each canonical record must answer the reader's who/what/where/when/why: actor and situation; desired outcome; current Oarlock capability and smallest gap; SDK/app/provider owner; dated source and rationale; requirement/phase links; proof contract and evidence; freshness trigger; non-goals; and promotion/reopen condition. Keep stable IDs and existing status semantics from the requirement/research baseline.

### Maintainer reading path
- **D-03:** Provide two concise entry points over one canonical JTBD record set: a persona view for “who has this job?” and a lifecycle/job view for “where does the workflow succeed or stop?” Both views link by stable JTBD ID. They must not duplicate or independently own rationale, status, transition history, or evidence; the validator should detect broken index-to-record links.
- **D-04:** Optimize the repository documentation for fast scanning, direct links, plain-text reading, and assistive navigation. Use descriptive headings, descriptive link text, and relative links. Keep copy calm, exact, and developer-native per the current available Oarlock brand book. This is a documentation information architecture, not a product interface or design system.

### Evidence freshness, automation, and history
- **D-05:** Use source-specific freshness triggers. Revisit repository facts when their authoritative planning/source files or mapped phase/requirement state changes; refresh provider and ecosystem claims when upstream contracts/versions change and before promotion; bind hosted CI/package proof to the exact SHA and artifact identity; refresh mutable hosted/external settings when a current-state claim is needed and no dependable event signal exists.
- **D-06:** Apply a maximum age only to mutable external claims that can change silently and need to be current for an operational decision. Do not impose a blanket calendar expiry that causes unchanged local, MockServer, hosted, or provider evidence to be rerun without distinct risk reduction. A scheduled check is advisory evidence about the commit it actually observed; it does not replace exact-SHA proof for a different target.
- **D-07:** Preserve old evidence as dated history with its class, identity, source, caveat, and freshness rule. Stale or unavailable evidence remains historical/unknown until new proof exists; it never silently satisfies a current gate. Local/unit, MockServer, package/downstream, hosted CI, sandbox, and live-provider proof remain distinct.
- **D-08:** Keep cross-link validation deterministic, actionable, read-only, and conservative with unknown or incomplete ownership. It reports broken or contradictory relationships and never repairs or promotes records automatically. Put repeatable high-signal validation into the existing CI contract when its recurring risk reduction justifies runtime and maintenance; human review is reserved for judgment or external state automation cannot observe.
- **D-09:** Preserve the required dated append-only status transitions and the full horizon/status taxonomy already locked in ROADMAP, REQUIREMENTS, and research. Status changes retain prior state, rationale, and evidence; editing current prose must not erase the reason for earlier decisions.

### the agent's Discretion
- Choose the smallest record/index file layout that keeps one canonical source and provides both navigation paths.
- Reuse or extend the existing read-only planning-health/diagnostic patterns after mapping their authority boundaries; choose parser and test organization without introducing a database, new service, Phoenix coupling, or unnecessary dependencies.
- Define precise source-change triggers and any narrowly justified external-state maximum ages from current primary evidence. State how each trigger is detected and what evidence closes it.
- Integrate deterministic link/provenance checks into the existing CI contract only when measurement and risk analysis support the recurring cost; never create a parallel definition of green.
- Keep v2.2 handoff evidence factual and exact: repository/worktree disposition, exact-SHA proof, open blockers, accepted caveats, and evidence-based candidates. Do not present future candidates as commitments.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, authority, and committed requirements
- `.planning/PROJECT.md` — Pure SDK boundary, adopter, non-goals, and milestone direction.
- `.planning/ROADMAP.md` — Phase 36 goal, dependencies, success criteria, trajectory baseline, and current milestone graph.
- `.planning/REQUIREMENTS.md` — ORIENT-01 through ORIENT-06, required fields, status/horizon distinction, append-only history, validator links, and exact-SHA handoff.
- `.planning/STATE.md` — Current execution pointer, milestone state, accepted caveats, and next-action continuity.
- `.planning/GSD-PREFERENCES.md` — Repository planning authority, conservative unknown handling, shift-left verification, exact-SHA evidence, and context-safe handoff defaults.
- `.planning/BACKLOG.md` and `.planning/BACKLOG-ARCHIVE.md` — Active scope versus archived/resolved work; do not reactivate historical entries by presence alone.
- `.planning/MILESTONES.md` and `.planning/RETROSPECTIVE.md` — Shipped-history navigation and prior workflow lessons.
- `.planning/EVIDENCE.md` — Proof classes, current release/CI facts, historical corrections, and accepted v0.1.2 limitation.

### JTBD, scope evidence, and architecture
- `.planning/research/FEATURES.md` — Relevant personas, canonical record fields, status definitions, trajectory baseline, anti-features, and promotion rules.
- `.planning/research/JTBD-GAPS.md` — Existing adopter job coverage and lifecycle gaps; last reviewed 2026-05-30, so revalidate external/provider claims before promotion.
- `.planning/research/ARCHITECTURE.md` — Ownership boundaries and planning/repository control-plane architecture.
- `.planning/research/PITFALLS.md` — Candidate-as-promise, rewritten-history, endpoint-breadth, and evidence-boundary failure modes.
- `.planning/research/SUMMARY.md` — Milestone sequence, phase rationale, confidence, and durable trajectory.
- `.planning/phases/35-review-ownership-worktree-operations/35-CONTEXT.md` — Maintainer-facing DX, no-guess ownership, automation/runtime tradeoffs, and preservation rules.
- `.planning/phases/34-release-integrity/34-CONTEXT.md` — Exact-SHA proof, release evidence identity, and separation of publication from artifact proof.
- `.planning/seeds/SEED-001-reader-first-readme.md` — Deferred public README refresh seed; this phase covers internal planning orientation only.

### Existing validator and CI patterns
- `scripts/planning_health.cjs` — Read-only planning diagnostic CLI and human/JSON output contract.
- `scripts/lib/repository_truth.cjs` — Existing authority and conservative classification logic to inspect before adding traceability validation.
- `scripts/planning_health.test.cjs` — Fixtures for missing, contradictory, duplicate, stale, and incomplete evidence; tests for no mutation and diagnostic parity.
- `.github/workflows/ci.yml` — Existing aggregate CI contract; extend its authoritative proof rather than creating a second green definition.

### Voice and external conventions
- `prompts/oarlock-milestone-roadmap-ratchet.txt` — Current milestone rules: evidence-led personas, dated transitions, bounded scope, automation, and complete handoff.
- `prompts/oarlock-brand-book.md` — Only brand book found; calm, precise, honest, concise developer-native writing and accessible documentation guidance.
- [Phoenix contexts](https://phoenix.hexdocs.pm/contexts.html) — Phoenix is the app's web interface; consuming applications own their application contexts and behavior.
- [ExDoc groups and page options](https://ex-doc.hexdocs.pm/ExDoc.html) — Elixir documentation grouping and navigation conventions.
- [GitHub README and relative-link guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes) — Clone-friendly links and repository-document navigation.
- [W3C headings guidance](https://www.w3.org/WAI/tutorials/page-structure/headings/) — Logical headings aid in-page navigation and assistive technology.
- [GitHub Actions workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) — Event/SHA semantics and schedule caveats to consider when describing freshness checks.

No external product specification or ADR was supplied. Current Paddle or ecosystem behavior used to promote a candidate must be checked against authoritative, current sources during Phase 36 research.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/planning_health.cjs`, `scripts/lib/repository_truth.cjs`, and `scripts/planning_health.test.cjs`: read-only snapshot, structured diagnostics, conservative authority resolution, JSON/human parity, and fixture-based protection against false authority.
- `.planning/EVIDENCE.md` and the milestone archive ledgers: existing durable evidence classification and history patterns.
- `.github/workflows/ci.yml`: canonical required CI aggregate for running high-signal deterministic planning checks.

### Established Patterns
- `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `PROJECT.md`, `MILESTONES.md`, and `EVIDENCE.md` have distinct owners; secondary artifacts corroborate but do not silently replace canonical authority.
- Unknown ownership, absent tags, missing package proof, and stale evidence remain unknown or historical; tools report facts separately from proposals and never infer a winner.
- CI and release claims require exact source identity. MockServer proof, package proof, hosted CI, sandbox, and live-provider proof answer different questions.
- Existing planning health checks are report-only and preserve files, refs, index, and worktree metadata.

### Integration Points
- Phase 36's canonical JTBD/trajectory records and linked indexes under `.planning/`.
- Requirement/phase/evidence/backlog/archive references validated by a deterministic repository check.
- Existing CI aggregate and Phase 35's repository-state/handoff evidence; Phase 36's final handoff must report observed state at the time it is created.
</code_context>

<specifics>
## Specific Ideas

- **Next GSD action:** `$gsd-plan-phase 36`. Research-before-planning remains enabled; do not use `--skip-research`.
- Preserve `persona → JTBD → capability/gap → requirement/phase → proof/evidence` traceability with distinct fields for actor, owning repo, horizon, and commitment status.
- Use persona and lifecycle navigation to answer who, what, where, when, why, and next action without repeating the canonical record.
- Use event triggers for versioned repository facts and exact target changes; use a bounded age only for mutable external state without reliable change notifications.
- Keep records short, linked, plain-text friendly, and accessible through semantic headings and descriptive links. There is no application UI, design system, or Ecto storage surface in this phase.
- Human verification is reserved for irreducible judgment or external state; deterministic link, scope, and proof-contract checks should run at the earliest useful boundary when their recurring value justifies the cost.
</specifics>

<deferred>
## Deferred Ideas

- Refreshing the public README according to `.planning/seeds/SEED-001-reader-first-readme.md` belongs in a later milestone when README/adopter onboarding is in scope. Do not fold it into Phase 36's internal planning map.
- Support, finance, and reconciliation operator capability work remains candidate until sourced adopter evidence, current provider research, an owner, a bounded surface, and a proof contract justify promotion.
- No open todos matched Phase 36 during discussion.

</deferred>

---

*Phase: 36-jtbd-coverage-durable-trajectory-handoff*
*Context gathered: 2026-09-26*
