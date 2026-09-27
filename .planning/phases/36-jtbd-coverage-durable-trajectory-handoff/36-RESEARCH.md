<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Refreshing the public README according to `.planning/seeds/SEED-001-reader-first-readme.md` belongs in a later milestone when README/adopter onboarding is in scope. Do not fold it into Phase 36's internal planning map.
- Support, finance, and reconciliation operator capability work remains candidate until sourced adopter evidence, current provider research, an owner, a bounded surface, and a proof contract justify promotion.
- No open todos matched Phase 36 during discussion.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ORIENT-01 | Maintainer can view a canonical coverage map of relevant personas and stable JTBD IDs, including situation, desired outcome, current capability, smallest gap, and SDK/app/provider ownership boundary. | Layered persona and canonical-record patterns; linked persona and lifecycle navigation views. |
| ORIENT-02 | Every JTBD and capability decision records dated sources, rationale, owner or repository, requirement and phase links, proof contract, evidence, freshness trigger, non-goals, and promotion or reopen condition. | Canonical record schema and source-specific freshness/proof guidance. |
| ORIENT-03 | Maintainer can view a canonical trajectory that separates `short`/`mid`/`long` horizon from `shipped`/`committed`/`candidate`/`conditional`/`rejected`/`external`/`superseded` status. | Verbatim taxonomy, distinct fields, and single-owner trajectory recommendation. |
| ORIENT-04 | Planning changes append dated status transitions while retaining previous rationale and evidence instead of silently rewriting history. | Append-only transition log pattern; preserve old evidence identity, caveat, and class. |
| ORIENT-05 | A validator detects broken or inconsistent links among JTBD records, requirements, phases, evidence, backlog entries, trajectory items, and milestone archives. | Reuse existing read-only repository-truth patterns and fixture-driven tests; validate links against authoritative owners. |
| ORIENT-06 | Milestone handoff records clean repository and worktree status, exact-SHA proof, remaining blockers, accepted caveats, and evidence-based candidates for the next discovery cycle. | Fresh exact-SHA repository/worktree inventory and proof-class-aware handoff; retain the documented v0.1.2 caveat. |
</phase_requirements>

# Phase 36: JTBD Coverage, Durable Trajectory & Handoff - Research

**Researched:** 2026-09-26  
**Domain:** Repository-local planning records, traceability validation, evidence and milestone handoff  
**Confidence:** HIGH for current in-repo authority and tooling patterns; MEDIUM for external documentation conventions

## Summary

Phase 36 is a repository-local documentation and planning-integrity phase. Make one canonical record set for jobs and capability decisions, give maintainers two short navigation paths into it, keep horizon separate from commitment status, and retain dated status/evidence history. Build deterministic checks around the existing read-only planning-health authority model and fixture test patterns. The project's configured test contract enables Nyquist validation and already includes the planning scripts suite. [VERIFIED: `.planning/config.json:1-24`] The CI workflow already runs that suite and planning-health JSON checks inside its existing aggregate, so any recurring validator should join that contract only if its risk reduction merits the ongoing cost. [VERIFIED: `.github/workflows/ci.yml:349-359`, `.github/workflows/ci.yml:396-412`, `.github/workflows/ci.yml:441-472`]

Use the current roadmap as the commitment boundary: v2.2 phases 31–36 are committed work; mid-term discovery/quote/mock candidates and long-term Accrue/API/stability work remain future, gated by named adopter evidence, current provider research, bounded surface, owner, and proof contract. [VERIFIED: `.planning/ROADMAP.md:264-282`; `.planning/REQUIREMENTS.md:84-105`] The JTBD gap research was last reviewed on 2026-05-30; revalidate external/provider claims before promoting them. [VERIFIED: `.planning/research/JTBD-GAPS.md:1-12`; `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:49-57`]

**Primary recommendation:** Use one repository-local canonical JTBD/trajectory record file with stable IDs, concise persona and lifecycle indexes, and a dated append-only transition section. Add a focused read-only validator using existing repository-truth boundaries; extend the existing planning test and CI contract only for high-signal checks. End with a freshly observed worktree and exact-SHA proof handoff.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| JTBD, trajectory, rationale, and status history | Repository planning/docs | — | These are durable planning authorities in the repository; the phase explicitly excludes a new external planning service. [VERIFIED: `.planning/REQUIREMENTS.md:107-119`; `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:5-8`] |
| Cross-reference and evidence-link validation | Repository tooling (Node CLI) | CI | Current planning health is a read-only CLI, and CI already runs planning checks. [VERIFIED: `scripts/planning_health.cjs:12-30`; `.github/workflows/ci.yml:349-359`] |
| Hosted CI/package/release evidence | GitHub Actions and release artifacts | Repository handoff ledger | A handoff documents the exact target and evidence identity; a scheduled workflow observes the default branch's latest commit and may be delayed, so it cannot establish proof for another target SHA. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows] |
| Application jobs/provider behavior | Owning adopter application or provider boundary | Oarlock planning records | Keep app/provider ownership explicit; Phoenix contexts belong to consuming applications and this phase adds no Phoenix, Ecto, or provider behavior. [CITED: https://phoenix.hexdocs.pm/contexts.html; VERIFIED: `.planning/REQUIREMENTS.md:107-119`] |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why standard |
|-------------|---------|---------|--------------|
| Markdown and relative repository links | — | Human-readable canonical planning records and navigation | Existing planning authorities are repository documents; GitHub documents relative links as clone-friendly and resolves them against the current file. [VERIFIED: `.planning/PROJECT.md:1-18`; CITED: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes] |
| Node.js built-ins and `node:test` | Node 22.14.0 in CI | Deterministic local validator and fixture tests | CI pins Node 22.14.0 and runs Node's built-in test runner for script tests; no new package is needed. [VERIFIED: `.github/workflows/ci.yml:344-359`] |
| Existing `scripts/lib/repository_truth.cjs` and `scripts/planning_health.cjs` | In-repository | Authority resolution, bounded repository reads, diagnostic output conventions | Existing tools already provide read-only authority/snapshot behavior and human/JSON diagnostics. [VERIFIED: `scripts/planning_health.cjs:12-30`; `scripts/lib/repository_truth.cjs:1109-1176`] |
| GitHub Actions `CI contract` | Existing workflow | Execute high-signal deterministic checks | Reuse the current aggregate as canonical CI green rather than introducing a second green definition. [VERIFIED: `.github/workflows/ci.yml:441-472`] |

### Supporting

| Tool/pattern | Purpose | When to use |
|--------------|---------|-------------|
| `node:test` fixtures | Exercise missing, duplicate, inconsistent, stale, and unsafe-link cases | For the new validator and output parity; current planning-health tests use fixture repositories and check that diagnostics do not mutate repository state. [VERIFIED: `scripts/planning_health.test.cjs:445-492`; `scripts/planning_health.test.cjs:815-845`] |
| W3C semantic heading guidance | Accessible document hierarchy | Use descriptive, logically nested headings for the persona and workflow paths. [CITED: https://www.w3.org/WAI/tutorials/page-structure/headings/] |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| One canonical repository record set plus link-only indexes | Separate persona and lifecycle documents that both own status/evidence | Separate owners create duplicated mutable facts and contradictory transitions; the locked decision requires one record set. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:25-31`] |
| Existing Node CLI/test/CI stack | New package, database, service, Phoenix UI, or Ecto persistence | Adds dependency and ownership surface outside phase scope, without helping repository-local traceability. [VERIFIED: `.planning/REQUIREMENTS.md:107-119`] |

**Installation:** None. Do not add external packages for a Markdown/Node validation phase. [VERIFIED: `.planning/config.json:1-24`; `.planning/REQUIREMENTS.md:107-119`]

## Package Legitimacy Audit

Not applicable: Phase 36 should install no external packages. [VERIFIED: `.planning/REQUIREMENTS.md:107-119`]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer / future agent
        │ choose a reading question
        ├── who has this job? ──> Persona index ──┐
        └── where does work stop? -> Lifecycle index ─┤
                                                    ▼ stable JTBD ID
                                      Canonical record + trajectory
                                      ├─ source, owner, rationale
                                      ├─ capability/gap and scope
                                      ├─ requirement/phase/proof links
                                      └─ dated status/evidence history
                                                    │
                           repository snapshot ────┤
                                                    ▼
                                      Read-only validator
                                      ├─ link/authority checks
                                      └─ actionable human/JSON diagnostics
                                                    │
                               existing CI contract (if justified)
                                                    ▼
                              fresh exact-SHA milestone handoff
```

This is a recommended flow derived from the locked two-index/single-record design and existing read-only CLI/CI seams. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:25-46`; `scripts/planning_health.cjs:12-30`; `.github/workflows/ci.yml:441-472`]

### Recommended Project Structure

The exact filenames are discretionary; keep them within `.planning/` and prefer the smallest layout that preserves one authority. A practical shape is:

```text
.planning/
├── JTBD-COVERAGE.md       # canonical records, trajectory, dated transitions
├── PERSONAS.md            # concise persona index; stable-ID links only
└── WORKFLOWS.md           # lifecycle/job index; stable-ID links only
scripts/
├── planning_health.cjs    # existing CLI, extend only if authority boundary fits
└── planning_health.test.cjs
```

Treat this as a recommendation, not a verified existing tree. If one file with three navigation sections is simpler and keeps canonical ownership clearer, use that instead. Keep README refresh deferred. [ASSUMED]

### Pattern 1: Canonical Record With Link-Only Views

**What:** Keep each JTBD/capability decision's rationale, owner, status, proof, and history in one stable-ID record; indexes provide short labels and links. Separate `horizon` from `status`. The existing research defines horizon exactly as “`short`, `mid`, or `long`” and status as “`shipped`, `committed`, `candidate`, `conditional`, `rejected`, `external`, `superseded`”. [VERIFIED: `.planning/research/FEATURES.md:74-108`] The same values are required in ORIENT-03. [VERIFIED: `.planning/REQUIREMENTS.md:77-82`]

**When to use:** Every persona/lifecycle navigation entry should resolve to a canonical ID and record. Preserve old status, rationale, and evidence in an append-only dated history. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:25-46`]

**Freshness pattern:** Repository facts refresh when their authoritative file or mapped requirement/phase changes; provider/version claims refresh on upstream change and before promotion; hosted CI/package proof is tied to exact SHA and artifact identity; only mutable external settings without dependable event signals receive a bounded age. A scheduled workflow observes the latest default-branch commit, can be delayed/dropped, and therefore does not prove a different SHA. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:33-40`; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows]

### Pattern 2: Conservative Read-Only Validator

**What:** Resolve authority from the existing repository snapshot, validate link targets and contradictions, report unknown/incomplete ownership without choosing a winner, and do not modify records. Existing repository-truth reads constrain paths under the repo, reject symlink traversal, and bound source reads; preserve these safeguards when extending the validator. [VERIFIED: `scripts/lib/repository_truth.cjs:1109-1176`]

**When to use:** Check record IDs and index links, requirement/phase references, evidence/backlog/archive links, duplicate ownership, malformed transitions, and proof references. Do not call a stale or absent proof current. Human review handles judgment and external state unavailable to the repository. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:37-46`; `.planning/REQUIREMENTS.md:77-82`]

**Example from existing CI contract:**

```yaml
- name: Run script tests
  run: node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs
- name: Run planning health
  run: node scripts/planning_health.cjs --json
```

These commands appear in the existing workflow; use the current aggregate and add focused coverage there only if recurring value justifies it. [VERIFIED: `.github/workflows/ci.yml:349-359`]

### Anti-Patterns to Avoid

- **Duplicated ownership:** Keep one rationale/status/history/evidence owner; persona and lifecycle views link to it. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:25-31`]
- **Candidate-as-promise:** Do not map future candidate requirements into v2.2 or treat a backlog/archive mention as current commitment. [VERIFIED: `.planning/REQUIREMENTS.md:84-105`; `.planning/ROADMAP.md:264-282`]
- **Calendar expiry for all proof:** Refresh on source events; age only silent-changing mutable external claims when currentness matters. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:33-40`]
- **Auto-repair or promotion:** Diagnostics should report contradictions, never rewrite the repository or infer a winning owner. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:37-40`]
- **Endpoint breadth as JTBD coverage:** Keep the roadmap evidence-led and consumer-backed; broad endpoint mirroring is explicitly out of scope. [VERIFIED: `.planning/REQUIREMENTS.md:107-119`; `prompts/oarlock-milestone-roadmap-ratchet.txt:7-40`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authority resolution and safe source reads | A new permissive parser that independently selects “current” planning files | Existing `repository_truth.cjs` snapshot and bounded-read helpers; extend only after mapping authority | The existing implementation has path containment and symlink protections and centralizes repository truth. [VERIFIED: `scripts/lib/repository_truth.cjs:1109-1176`] |
| Diagnostic output | New bespoke validator output with no machine interface | Existing planning-health human/JSON diagnostic contract | It is already read-only and exposes structured diagnostic output. [VERIFIED: `scripts/planning_health.cjs:12-30`] |
| Test fixtures and CI green | Parallel validation command or competing CI aggregate | `node:test` fixture patterns and current `CI contract` | Existing tests check unsafe/missing/contradictory records and workflow has an aggregate. [VERIFIED: `scripts/planning_health.test.cjs:445-492`; `.github/workflows/ci.yml:441-472`] |
| External job demand | New SDK feature commitments inferred from provider capability | Dated adopter evidence, owner, bounded surface, and proof contract before promotion | Requirements expressly keep future work uncommitted until those gates are met. [VERIFIED: `.planning/REQUIREMENTS.md:84-105`] |

**Key insight:** The hard part is authority and evidence semantics, not parsing Markdown. A validator that makes an unsupported decision can manufacture false confidence; keep it conservative, read-only, and explicit about unknowns. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:37-46`; `scripts/planning_health.test.cjs:815-845`]

## Common Pitfalls

### Pitfall 1: Treating horizon as commitment

**What goes wrong:** A mid/long trajectory item reads like committed work, or a candidate requirement becomes an implied phase promise.  
**Why it happens:** Horizon and status are compressed into one label or future requirements are read without their gating language.  
**How to avoid:** Store separate fields and preserve the exact taxonomy quoted in Pattern 1; label future requirements as uncommitted until promotion criteria are met. [VERIFIED: `.planning/REQUIREMENTS.md:77-105`]  
**Warning signs:** Candidate rows appear in current phase traceability or roadmap phase tables without owner/proof gates.

### Pitfall 2: Letting source freshness become blanket expiration

**What goes wrong:** Stable repository or MockServer proof is repeatedly rerun without a new risk signal, while truly mutable external settings remain stale.  
**Why it happens:** One TTL is applied to all evidence classes.  
**How to avoid:** Assign source-specific triggers and an age only to silent-changing external state; record what event or current-state check closes each trigger. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:33-40`]  
**Warning signs:** “Expires in N days” without a claim that changes silently or a decision that needs current state.

### Pitfall 3: Confusing scheduled evidence with exact-target proof

**What goes wrong:** A green scheduled run is reported as proof for another commit.  
**Why it happens:** Schedule semantics are ignored.  
**How to avoid:** Record the exact observed SHA and artifact identity; treat schedule output as advisory for that observed commit only. GitHub states scheduled workflows run against the latest default-branch commit and may be delayed or dropped under load. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows]  
**Warning signs:** Handoff names a green run without matching its source SHA to the handoff target.

### Pitfall 4: Reusing stale research as current provider evidence

**What goes wrong:** A candidate is promoted based on old provider capabilities or old gap analysis.  
**Why it happens:** Research presence is mistaken for currentness.  
**How to avoid:** Recheck current primary provider contract/version before promotion; the current gap research records its 2026-05-30 review date and Phase 36 explicitly requires revalidation. [VERIFIED: `.planning/research/JTBD-GAPS.md:1-12`; `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:49-57`]  
**Warning signs:** No dated source or owner/repository is attached to an external job.

### Pitfall 5: Treating historical release caveats as newly discovered failure

**What goes wrong:** The handoff erases an accepted exception or claims stronger historical proof than exists.  
**Why it happens:** Publication evidence and candidate-to-served-byte identity are conflated.  
**How to avoid:** Preserve the documented v0.1.2 exception as a caveat: publication was confirmed, while candidate-to-served-byte identity was not proven; keep it separate from evidence for current releases. [VERIFIED: `.planning/EVIDENCE.md:53-70`]  
**Warning signs:** An old exception is either omitted or converted into a claim that all artifacts have exact identity proof.

## Code Examples

No new external library example is appropriate. The relevant implementation anchor is the existing read-only CLI invocation:

```sh
node scripts/planning_health.cjs --json
```

The command is already run by CI and returns machine-oriented diagnostics; a Phase 36 validator should fit this existing boundary if extended. [VERIFIED: `scripts/planning_health.cjs:12-30`; `.github/workflows/ci.yml:349-359`]

For tests, follow fixture setup and assertions already used for duplicate, unresolved, and unsafe source links; those tests verify that unsafe symlink content is not emitted. [VERIFIED: `scripts/planning_health.test.cjs:445-492`; `scripts/planning_health.test.cjs:815-845`]

## State of the Art

| Old approach | Current approach | When changed | Impact |
|-------------|------------------|--------------|--------|
| One generic status/horizon label or duplicated persona/workflow summaries | Separate horizon and status with canonical stable-ID records and link-only views | Locked for Phase 36, 2026-09-26 | Keeps future direction discoverable without presenting it as a commitment. [VERIFIED: `.planning/REQUIREMENTS.md:77-105`; `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:25-31`] |
| Calendar expiry for all proof | Event/source-specific freshness; narrowly age mutable external state | Locked for Phase 36, 2026-09-26 | Reduces needless reruns while keeping silent-changing external claims current where needed. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:33-40`] |
| Generic versionless security-standard references | Versioned ASVS requirement references | ASVS 5.0.0 is latest stable per the OWASP project page checked this session | Security findings can be traced to a stable category/version. [CITED: https://owasp.org/projects/asvs?tab=main] |

**Deprecated/outdated:** Avoid the generic template's legacy ASVS category labels as if they were current; ASVS 5.0.0 uses V1 “Encoding and Sanitization” and V2 “Validation and Business Logic”. Cite the version in any planning/security references. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.flat.json]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A single Markdown file can comfortably contain canonical JTBD records, trajectory, and append-only transition history while remaining navigable; if not, split by stable record boundaries without duplicating ownership. | Recommended Project Structure | Chosen structure could be cumbersome; requirement is single ownership, not a particular filename. |
| A2 | Fresh external-provider research can be performed when a candidate is actually promoted; this phase's planning artifact need not make any future candidate decision. | Summary / Pitfalls | An unverified candidate might be mistaken for a current capability if provenance is not explicit. |
| A3 | Existing CI test and planning-health commands are the intended integration point for any justified new deterministic check. | Standard Stack | A future workflow structure change could require a different insertion point; the current context explicitly names this contract. |

## Open Questions (RESOLVED)

1. **Which exact Markdown file split best fits the planner's record size? (RESOLVED)** Use `.planning/JTBD-COVERAGE.md` for canonical records, trajectory, and dated transitions, with `.planning/PERSONAS.md` and `.planning/WORKFLOWS.md` as short link-only navigation views. Plans 36-01 and 36-02 use this layout. Split canonical records later only if the complete set becomes hard to scan, while preserving one authoritative home for each record and its history. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:25-31`; PLANNED: `36-01-PLAN.md`, `36-02-PLAN.md`]
2. **Which mutable hosted/external claim actually needs a maximum age? (RESOLVED)** The Phase 36 inputs do not identify a particular claim and source that warrant a numeric maximum age at planning time. Plans use source-change triggers and exact-SHA/artifact identity for versioned and hosted facts, with a current-state readback when a silently mutable external setting becomes necessary for an operational decision. Assign a bounded age only after naming that claim, its authoritative source, decision use, and refresh evidence; no blanket age applies. This is a planning rule, not a finding that every future external claim stays current. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:33-40`; PLANNED: `36-01-PLAN.md`, `36-02-PLAN.md`]
3. **Should the validator join required CI immediately? (RESOLVED)** Integration is conditional under D-08. Plan 36-02 first proves the deterministic check on the complete map, measures its runtime and maintenance cost, and records the repeated drift it prevents: orphaned JTBD links or false commitment after requirement, roadmap, evidence, backlog, or archive edits. If that recurring value justifies cost within the existing planning-truth job, add the check to that job and its single CI aggregate. Otherwise retain the focused read-only check, document the reason and revisit condition, and do not create another required green definition. No CI timing or outcome is claimed by this research artifact. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:37-40`; PLANNED: `36-02-PLAN.md`]

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Existing planning CLI and script checks | ✓ | 22.14.0 in CI | None needed for current repository workflow. [VERIFIED: `.github/workflows/ci.yml:344-359`] |
| Git | Repository and exact-SHA inspection | ✓ | 2.41.0 observed locally | None for local planning; hosted proof must come from the existing CI/release sources. |
| GitHub Actions | Hosted CI evidence and aggregate | Configured | Workflow-defined | Local checks do not substitute for exact-SHA hosted proof. [VERIFIED: `.github/workflows/ci.yml:349-359`, `.github/workflows/ci.yml:441-472`] |

**Missing dependencies with no fallback:** None identified for repository-local research/planning.  
**Missing dependencies with fallback:** None identified.

The current research-time checkout has unrelated staged, unstaged, and untracked changes, and one linked worktree is locked. This snapshot is not a Phase 36 completion handoff; capture fresh repository/worktree disposition and exact target SHA when closing the milestone. [VERIFIED: local `git status --short`, `git worktree list --porcelain`, inspected 2026-09-26; `.planning/REQUIREMENTS.md:79-82`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js built-in `node:test` for repository scripts; Mix tests remain part of the configured full suite. [VERIFIED: `.planning/config.json:1-24`; `.github/workflows/ci.yml:349-359`] |
| Config file | None required for Node's built-in runner; repository-wide workflow and config are `.github/workflows/ci.yml` and `.planning/config.json`. [VERIFIED: `.planning/config.json:1-24`] |
| Quick run command | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` (existing CI command). [VERIFIED: `.github/workflows/ci.yml:349-359`] |
| Full suite command | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs && mix test` (configured project command). [VERIFIED: `.planning/config.json:20-24`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File exists? |
|--------|----------|-----------|-------------------|--------------|
| ORIENT-01 | Stable record IDs and both indexes resolve to one canonical record | unit | `node --test scripts/planning_health.test.cjs` | Existing suite; add focused cases if validator is extended. |
| ORIENT-02 | Required provenance/proof/freshness fields are present and links resolve | unit | `node --test scripts/planning_health.test.cjs` | Existing suite; coverage for new fields is a likely Wave 0 gap. |
| ORIENT-03 | Horizon and status remain independent and values are valid | unit | `node --test scripts/planning_health.test.cjs` | Existing suite; add focused taxonomy tests. |
| ORIENT-04 | Status transitions retain dated prior rationale/evidence | unit | `node --test scripts/planning_health.test.cjs` | Existing suite; add append-only/history checks for the chosen format. |
| ORIENT-05 | Broken, duplicate, contradictory, or unsafe cross-links are reported read-only | unit/integration | `node --test scripts/planning_health.test.cjs` | Existing fixture patterns; extend only for new relationship types. |
| ORIENT-06 | Handoff names exact SHA, observed worktree/repo disposition, blockers, caveats, candidates | manual review + source-link validation | Existing configured full suite, plus human check against live handoff evidence | No dedicated handoff test can observe external hosted state by itself. |

### Sampling Rate

- **Per task commit:** Run the focused Node test file for the changed validator plus relevant fixture tests.
- **Per wave merge:** `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`.
- **Phase gate:** Run the configured full suite and obtain exact-SHA hosted CI/release evidence before final handoff. The research refresh itself did not run tests and does not create a separate validation artifact.

### Wave 0 Gaps

- [ ] Add fixture coverage for Phase 36 record/index/horizon/status/provenance relationships if the existing test suite does not cover them.
- [ ] Add tests for append-only transition preservation and “unknown”/incomplete ownership remaining diagnostic rather than auto-repaired.
- [ ] Decide from measured value whether checks belong in existing planning-health tests/CLI and the existing CI aggregate.

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not set it to false. This phase has no login, API endpoint, session, or persistence layer; the meaningful surface is parsing repository-controlled Markdown and links. [VERIFIED: `.planning/config.json:1-24`; `.planning/REQUIREMENTS.md:107-119`]

ASVS references below use OWASP ASVS 5.0.0, checked as current stable on the project page. Version-qualified category labels are V1 “Encoding and Sanitization” and V2 “Validation and Business Logic”. [CITED: https://owasp.org/projects/asvs?tab=main; https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP-ASVS-5.0.0_en.flat.json]

### Applicable ASVS Categories

| ASVS category (5.0.0) | Applies | Standard control |
|-----------------------|---------|------------------|
| V1 Encoding and Sanitization | Partial | Treat Markdown/source text as untrusted; validate/escape terminal or generated output and reject unsafe paths/links. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP-ASVS-5.0.0_en.flat.json] |
| V2 Validation and Business Logic | Yes | Validate stable IDs, allowed record relationships, required provenance fields, and status-history consistency; unknown ownership remains unknown. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP-ASVS-5.0.0_en.flat.json] |
| V4 API and Web Service | No | No API or web-service surface is added in this phase. [VERIFIED: `.planning/REQUIREMENTS.md:107-119`] |
| Authentication / session / cryptography categories | No | No user authentication, session handling, or secret storage is in scope. [VERIFIED: `.planning/REQUIREMENTS.md:107-119`] |

### Known Threat Patterns

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Traversal or symlink escapes during Markdown/source loading | Tampering / Information disclosure | Reuse bounded repository reads and reject paths outside root or through symlinks; do not shell-expand user-controlled paths. [VERIFIED: `scripts/lib/repository_truth.cjs:1109-1176`] |
| Crafted Markdown/metadata affects CLI output or becomes misleading evidence | Tampering / Repudiation | Parse narrowly, validate IDs and links, separate source facts from proposals, and keep machine/human diagnostics parity. [VERIFIED: `scripts/planning_health.cjs:12-30`; `scripts/planning_health.test.cjs:815-845`] |
| False-green from stale or mismatched hosted proof | Repudiation | Bind every proof claim to observed commit SHA and artifact identity; preserve stale/unavailable proof as historical/unknown. [VERIFIED: `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md:33-46`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-CONTEXT.md` — locked decisions, scope, authority boundaries, and freshness rules.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/EVIDENCE.md` — committed requirements, current/future trajectory, proof state, and handoff context.
- `.planning/research/FEATURES.md`, `JTBD-GAPS.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `SUMMARY.md` — existing record model, job coverage, boundaries, and failure patterns.
- `scripts/planning_health.cjs`, `scripts/lib/repository_truth.cjs`, `scripts/planning_health.test.cjs`, `.github/workflows/ci.yml` — current CLI, safe-read, fixture, and CI contracts.
- `.planning/config.json`, `.planning/GSD-PREFERENCES.md`, `.planning/BACKLOG.md`, `.planning/BACKLOG-ARCHIVE.md`, `.planning/MILESTONES.md`, `.planning/RETROSPECTIVE.md`, Phase 34/35 context, seed, and roadmap-ratchet/brand prompts — validation settings, history, constraints, and voice.

### Secondary (MEDIUM confidence)

- [GitHub README and relative links](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes) — repository-relative navigation behavior.
- [GitHub Actions workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) — schedule and commit semantics.
- [W3C page structure: headings](https://www.w3.org/WAI/tutorials/page-structure/headings/) — logical headings and assistive navigation.
- [Phoenix contexts](https://phoenix.hexdocs.pm/contexts.html) — app-context ownership boundary.
- [ExDoc](https://ex-doc.hexdocs.pm/ExDoc.html) — generated documentation grouping conventions; no ExDoc package/config is recommended for this Markdown phase.
- [OWASP ASVS project](https://owasp.org/projects/asvs?tab=main) and [ASVS 5.0.0 controls](https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP-ASVS-5.0.0_en.flat.json) — version and relevant security categories.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed from current config, scripts, and CI.
- Architecture: HIGH — phase decisions and repository source-of-truth files define boundaries.
- Pitfalls: HIGH — sourced from locked decisions and current evidence/roadmap history.
- External conventions: MEDIUM — current official documentation checked; used only for documentation/security/CI interpretation.

**Research date:** 2026-09-26  
**Valid until:** 2026-10-26 for stable repository patterns; recheck external/provider claims immediately before candidate promotion.
