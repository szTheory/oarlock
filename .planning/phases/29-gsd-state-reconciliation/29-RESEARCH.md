# Phase 29: gsd-state-reconciliation - Research

**Researched:** 2026-06-24
**Domain:** GSD planning-state reconciliation, markdown evidence hygiene, and project defaults
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Backlog Disposition
- **D-01:** Keep `.planning/BACKLOG.md` as the active planning queue. It should be short, scan-first, and limited to future work candidates or clearly labeled non-oarlock follow-ups.
- **D-02:** Create `.planning/BACKLOG-ARCHIVE.md` for shipped, superseded, or historical backlog entries. Preserve original backlog IDs and rationale; do not renumber B-IDs.
- **D-03:** Move shipped entries such as B-01, B-02, B-03, B-05, B-06, and B-07 to the archive as `Shipped`, with links to the phase or milestone that satisfied them.
- **D-04:** Keep B-04 active only as an `Accrue-only follow-up`. It must not be interpreted as oarlock SDK scope unless a later milestone explicitly promotes related oarlock work.
- **D-05:** Add a small status taxonomy near the top of backlog files: `Open`, `Accrue-only`, `Shipped`, `Superseded`, `Reference`. Only `Open` and explicitly selected `Accrue-only` items are candidates for new oarlock planning.

### Audit Evidence Language
- **D-06:** Use append-only errata and dated correction notes for historical planning truth. Do not silently rewrite past audits or summaries in a way that hides earlier overclaims.
- **D-07:** Add a compact canonical evidence ledger for v2.0/v2.1 planning proof, or an equivalent section in the relevant audit file, with columns for requirement, artifact, evidence class, command/proof, and caveat.
- **D-08:** Describe Phase 25 as validated via `.planning/phases/25-offline-mode-foundation/VALIDATION.md`; the standard `VERIFICATION.md` artifact was absent or non-standard. Do not imply the missing filename meant missing proof.
- **D-09:** Describe Phase 26 as MockServer-backed integration proof by default. Sandbox or live Paddle provider-state proof is available only when real credentials and provider-state checks are explicitly run and evidenced.
- **D-10:** Correct misleading wording such as "against Paddle state" with dated notes that clarify whether the state was MockServer state, sandbox state, or live provider state.

### Investigation Retention
- **D-11:** Preserve resolved investigations, but move them out of active-looking paths. Use `.planning/threads/resolved/YYYY/` for resolved threads and keep `.planning/threads/` for active threads.
- **D-12:** Add `.planning/threads/INDEX.md` with one row per thread: status, short lesson, canonical phase/context link, and reopen condition.
- **D-13:** Keep the subscription-create revalidation thread as resolved evidence. Its durable lesson is: do not add `Paddle.Subscriptions.create/2` unless current Paddle primary docs introduce a clean provider-native direct create API; recurring starts remain transaction/checkout or invoice-backed.
- **D-14:** Promote an investigation into an ADR-style decision record only when its conclusion governs public API shape, provider model, or recurring planning policy. Do not turn every small thread into an ADR.

### GSD Defaults Durability
- **D-15:** Split durable project policy from personal execution style. Project-local config should capture repo-specific judgment lenses and quality gates; user/global config should own autonomy and risk-tolerance knobs.
- **D-16:** Project-local defaults should preserve: research before planning, subagent research for gray areas, adopter-first assessment, DX/UX-first judgment, retained investigations, Nyquist validation, pattern mapping, and GSD docs/planning artifact durability.
- **D-17:** Keep autonomy controls explicit per run or user-global: `yolo`, `auto_advance`, aggressive parallelization, and model profile should not become surprising project policy for every contributor or agent.
- **D-18:** Treat `commit_docs` as permission to preserve GSD planning artifacts in repo history, not as blanket permission to auto-commit runtime code or unrelated planning edits.

### Coherent Planning Posture
- **D-19:** The overall Phase 29 strategy is active-small, archive-rich, and evidence-explicit. Future agents should encounter a small active queue first, with enough indexed history to understand why old ideas were shipped, superseded, or deliberately rejected.
- **D-20:** Follow the oarlock brand and engineering posture even in planning docs: precise, provider-native, calm, explicit about proof boundaries, and honest about unsupported scope.

### Claude's Discretion
- The planner may choose whether the canonical evidence ledger is a standalone `.planning/EVIDENCE.md` style artifact or an explicit section inside `.planning/v2.0-MILESTONE-AUDIT.md`, as long as future agents have one scan-friendly source for proof classification.
- The planner may use file moves or copied archive entries as long as old links remain understandable and historical B-IDs are preserved.
- The planner may add lightweight index templates for backlog/archive/threads if that reduces future drift without creating heavy process overhead.

### the agent's Discretion
Same as "Claude's Discretion" above; the CONTEXT.md does not contain a separate heading with this exact name. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Accrue-side `%Paddle.Error{}.raw` to `raw_data` migration remains an Accrue follow-up, not oarlock Phase 29 runtime work.
- Live Paddle sandbox/provider-state CI remains future/manual/on-demand unless a later phase solves credentials, isolation, and cleanup.
- Building a general GSD dashboard, UI, or heavy knowledge-graph system is out of scope; Phase 29 should use lightweight markdown/config artifacts.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GSD-01 | Root PROJECT, REQUIREMENTS, ROADMAP, STATE, BACKLOG, and milestone audit files agree on the current shipped state. [VERIFIED: `.planning/REQUIREMENTS.md`] | Reconcile `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/BACKLOG.md`, `.planning/MILESTONES.md`, `.planning/milestones/v2.0-*`, and `.planning/v2.0-MILESTONE-AUDIT.md` using the proof ledger and status taxonomy below. [VERIFIED: codebase grep] |
| GSD-02 | Stale investigations and backlog items are marked resolved, superseded, or explicitly moved to Accrue-side follow-up. [VERIFIED: `.planning/REQUIREMENTS.md`] | Split active backlog from `.planning/BACKLOG-ARCHIVE.md`; move resolved thread to `.planning/threads/resolved/2026/`; add `.planning/threads/INDEX.md`. [VERIFIED: codebase grep] |
| GSD-03 | v2.0 audit and Phase 25/26 validation language is reconciled with actual evidence. [VERIFIED: `.planning/REQUIREMENTS.md`] | Preserve Phase 25 proof as `VALIDATION.md`; correct Phase 26 to MockServer-backed proof unless sandbox/live evidence exists; add dated errata where historical wording overclaimed. [VERIFIED: codebase grep] |
| GSD-04 | Recurring GSD preferences for research, adopter-first assessment, DX/UX, and lesson retention are present in project/global defaults. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep supported project config keys in `.planning/config.json`; move unsupported preference prose to a committed policy/defaults note or supported global defaults; do not encode `yolo`, `auto_advance`, aggressive parallelization, or model profile as hidden project policy. [VERIFIED: local command] |
</phase_requirements>

## Summary

Phase 29 is a planning-state reconciliation phase, not an SDK/runtime implementation phase. The planner should produce a small number of documentation/config tasks that make active planning surfaces agree with shipped scope, move historical backlog/thread material into indexed archives, and classify evidence boundaries explicitly. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; VERIFIED: codebase grep]

The most important current drift is specific: `.planning/MILESTONES.md` still says Phase 26 verified upgrade/downgrade flows "against Paddle state", while `.planning/v2.0-MILESTONE-AUDIT.md` and `26-VERIFICATION.md` scope the proof to MockServer-backed integration by default. [VERIFIED: codebase grep] Phase 25 also has proof in `VALIDATION.md` rather than the standard `VERIFICATION.md`; that is a filename/artifact-standard caveat, not absence of proof. [VERIFIED: `.planning/phases/25-offline-mode-foundation/VALIDATION.md`; VERIFIED: `.planning/v2.0-MILESTONE-AUDIT.md`]

The right end state is "active-small, archive-rich, evidence-explicit": future agents see only live planning candidates first, but can follow stable IDs and indexes to understand shipped, superseded, and resolved history. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://keepachangelog.com/en/1.1.0/]

**Primary recommendation:** Plan Phase 29 as three docs/config slices: backlog/archive taxonomy, audit/evidence ledger corrections, and thread/defaults reconciliation; do not touch runtime SDK code. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

## Project Constraints (from AGENTS.md / CLAUDE.md)

No root `./AGENTS.md`, `./CLAUDE.md`, or `./.claude/CLAUDE.md` exists in the working directory. [VERIFIED: local command] A nested `demo/AGENTS.md` exists and applies to Phoenix demo work; Phase 29 is scoped to planning artifacts and should not edit demo code unless the plan is explicitly expanded. [VERIFIED: local command; VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

Actionable nested demo constraints, if a later task touches `demo/`: run `mix precommit`, prefer `Req`, follow Phoenix 1.8/HEEx/LiveView/Ecto conventions, and avoid deprecated Phoenix APIs. [VERIFIED: `demo/AGENTS.md`] These constraints are not primary for Phase 29 planning-doc edits. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Active backlog queue | Planning documentation | Git history | `.planning/BACKLOG.md` owns future work candidates; historical entries move to archive while preserving B-IDs. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Backlog archive/history | Planning documentation | Milestone log | `.planning/BACKLOG-ARCHIVE.md` owns shipped/superseded/reference backlog entries; `.planning/MILESTONES.md` should link/summarize rather than duplicate raw backlog text. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://keepachangelog.com/en/1.1.0/] |
| Evidence ledger | Planning documentation | Verification artifacts | The ledger should map requirement to artifact, evidence class, command/proof, and caveat; source artifacts remain phase validation/verification files. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Resolved investigation memory | Planning documentation | Archived thread path | `.planning/threads/INDEX.md` should route readers to resolved threads and reopen conditions; resolved files should live under `.planning/threads/resolved/YYYY/`. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Durable project GSD defaults | Project config/docs | User/global defaults | Supported shared gates belong in `.planning/config.json`; personal autonomy and risk appetite belong per-run or user-global. [VERIFIED: local command; CITED: https://git-scm.com/docs/git-config] |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Markdown planning artifacts | N/A | Source-of-truth project memory | Existing GSD system uses markdown files for PROJECT, REQUIREMENTS, ROADMAP, STATE, BACKLOG, phase context, and audits. [VERIFIED: codebase grep] |
| `git` | 2.41.0 installed | Track file moves, history, and planning artifact commits | Git provides repository-local history and config scopes used by this project. [VERIFIED: local command; CITED: https://git-scm.com/docs/git-config] |
| `rg` | 15.1.0 installed | Drift detection across planning docs | Fast recursive search is already available and should be used for wording and stale-reference checks. [VERIFIED: local command] |
| `node` + `gsd-tools.cjs` | Node v22.14.0 installed | GSD init, research, commit, config/schema inspection | `init.phase-op` and config schema inspection worked locally for Phase 29. [VERIFIED: local command] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit / Mix | Mix 1.19.5 installed | Existing repo test framework | Only needed if Phase 29 touches code or wants a smoke check that docs/config edits did not break generated checks. [VERIFIED: local command; VERIFIED: codebase grep] |
| `scripts/ci_monitor.cjs` | local script | Hosted CI evidence check | Useful only when validating Phase 28 hosted CI proof language or exact-SHA claims. [VERIFIED: `.planning/phases/28-ci-demo-and-package-proof/28-VERIFICATION.md`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.planning/BACKLOG-ARCHIVE.md` | Keep all B-IDs in `.planning/BACKLOG.md` | Rejected by locked decision D-02; active queue would remain stale-looking. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Evidence ledger inside audit | Standalone `.planning/EVIDENCE.md` | Both are allowed; standalone improves scanability across v2.0/v2.1, embedded audit keeps changes localized. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| ADR for every thread | Lightweight `.planning/threads/INDEX.md` | Locked decision D-14 rejects turning every small thread into ADR overhead. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |

**Installation:**
```bash
# No external package installation is required for Phase 29.
```

**Version verification:** No package registry versions are required because Phase 29 should not install packages. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

## Package Legitimacy Audit

No external packages should be installed for this phase. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| N/A | N/A | N/A | N/A | N/A | N/A | No package install planned. [VERIFIED: codebase grep] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package install planned]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package install planned]

## Architecture Patterns

### System Architecture Diagram

```text
Current planning artifacts
  |
  v
Inventory and classify each claim
  |
  +--> Backlog item? -----> Open / Accrue-only stays in BACKLOG
  |                         Shipped / Superseded / Reference moves to BACKLOG-ARCHIVE
  |
  +--> Evidence claim? ---> Requirement -> Artifact -> Evidence class -> Command/proof -> Caveat
  |                         Append dated errata for overclaims
  |
  +--> Investigation? ----> Active thread stays in threads/
  |                         Resolved thread moves to threads/resolved/YYYY/
  |                         INDEX.md records lesson + reopen condition
  |
  +--> GSD default? ------> Supported project policy stays in .planning/config.json
                            Personal/autonomy knobs stay per-run or user-global
```

### Recommended Project Structure

```text
.planning/
├── BACKLOG.md                    # Small active queue: Open + selected Accrue-only
├── BACKLOG-ARCHIVE.md            # Shipped, superseded, reference backlog history
├── EVIDENCE.md                   # Optional standalone proof ledger, if chosen
├── v2.0-MILESTONE-AUDIT.md       # Existing audit; may host ledger/errata instead
├── threads/
│   ├── INDEX.md                  # Thread status, lesson, canonical link, reopen condition
│   └── resolved/
│       └── 2026/
│           └── 2026-05-30-subscription-create-revalidation.md
└── phases/29-gsd-state-reconciliation/
    └── 29-RESEARCH.md
```

### Pattern 1: Active-Small, Archive-Rich Backlog
**What:** Keep `.planning/BACKLOG.md` limited to future candidates and explicitly selected Accrue-only work; move shipped/superseded/reference entries to `.planning/BACKLOG-ARCHIVE.md` with original IDs preserved. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

**When to use:** Use for B-01, B-02, B-03, B-05, B-06, and B-07 because current backlog text already marks those as shipped. [VERIFIED: `.planning/BACKLOG.md`]

**Example:**
```markdown
## Status Taxonomy

- `Open`: candidate for future oarlock planning.
- `Accrue-only`: tracked here for consumer-side memory; not oarlock SDK scope unless promoted.
- `Shipped`: satisfied by a prior phase/milestone; retained in archive only.
- `Superseded`: replaced by a newer decision or scope.
- `Reference`: historical context, not a planning candidate.
```

### Pattern 2: Evidence-Class Ledger
**What:** Add a compact ledger mapping requirement, artifact, evidence class, command/proof, and caveat. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

**When to use:** Use for v2.0/v2.1 proof boundaries, especially Phase 25 `VALIDATION.md`, Phase 26 MockServer-backed verification, Phase 27 docs truth, and Phase 28 CI/package proof. [VERIFIED: codebase grep]

**Example:**
```markdown
| Requirement | Artifact | Evidence Class | Command / Proof | Caveat |
|-------------|----------|----------------|-----------------|--------|
| ADV-01 | `.planning/phases/25-offline-mode-foundation/VALIDATION.md` | Validation artifact | Lists OFF-01..03 coverage | Non-standard filename; no `25-VERIFICATION.md` |
| ADV-02 | `.planning/phases/26-advanced-subscription-flows-e2e/26-VERIFICATION.md` | MockServer-backed integration | `mix test test/paddle/subscription_flows_test.exs` | Not sandbox/live provider-state proof unless separately evidenced |
```

### Pattern 3: Append-Only Errata
**What:** Correct historical overclaims with dated notes instead of silently replacing the old truth trail. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://sre.google/sre-book/postmortem-culture/]

**When to use:** Use where historical wording says "against Paddle state" or "via Paddle" without clarifying MockServer vs sandbox/live state. [VERIFIED: codebase grep]

**Example:**
```markdown
> **Errata, 2026-06-24:** Earlier wording described this proof as "against Paddle state."
> The evidence available in this repository is MockServer-backed integration proof.
> Sandbox/live provider-state proof requires real credentials and a separately recorded run.
```

### Pattern 4: Supported Config Plus Policy Note
**What:** Keep schema-supported GSD settings in `.planning/config.json`; preserve non-schema judgment lenses in a lightweight markdown policy/defaults note if needed. [VERIFIED: local command]

**When to use:** Use because `gsd-tools init.phase-op 29` warns that `.planning/config.json` has an unknown top-level `preferences` key. [VERIFIED: local command]

**Example:**
```json
{
  "commit_docs": true,
  "workflow": {
    "research": true,
    "research_before_questions": true,
    "nyquist_validation": true,
    "pattern_mapper": true,
    "auto_advance": false
  },
  "features": {
    "thinking_partner": true
  }
}
```

### Anti-Patterns to Avoid
- **Silent historical rewrite:** Hides why future agents saw old claims; use dated errata instead. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://sre.google/sre-book/postmortem-culture/]
- **Raw backlog dump:** Makes shipped work look actionable; archive shipped/superseded entries instead. [VERIFIED: `.planning/BACKLOG.md`; CITED: https://keepachangelog.com/en/1.1.0/]
- **Provider-state overclaim:** MockServer proof is not live Paddle state; phrase it as deterministic offline/MockServer-backed proof unless real credentials were run. [VERIFIED: `.planning/phases/26-advanced-subscription-flows-e2e/26-VERIFICATION.md`; VERIFIED: `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md`]
- **Unknown config keys as durable policy:** `preferences` is currently ignored by `gsd-tools` schema and should not be the only storage location for required defaults. [VERIFIED: local command]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Backlog status system | A complex tracker or dashboard | Markdown status taxonomy and archive | Phase scope explicitly excludes a dashboard/heavy knowledge graph. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Evidence management | Custom database or generated tool | Compact markdown ledger | Planner needs scan-friendly proof classes, not a new system. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Thread retention | ADR for every thread | `.planning/threads/INDEX.md` plus resolved folders | Locked D-14 says only promote decisions governing public API/provider model/recurring policy. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Config schema expansion | Invent arbitrary JSON keys as if they are honored | Supported GSD config keys plus explicit policy docs | Local `gsd-tools` warns unknown keys are ignored. [VERIFIED: local command] |

**Key insight:** The phase should improve information scent and proof classification, not add process machinery. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

## Runtime State Inventory

This phase is a planning-state reconciliation and file-move/config phase, so runtime/project state must be inventoried explicitly. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None found in repo scope; Phase 29 modifies markdown/config planning state only. [VERIFIED: codebase grep] | No data migration. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Live service config | No live Paddle/GitHub service config should be changed; live Paddle provider-state CI is deferred. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] | No API/service patch. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| OS-registered state | None found; no launchd/systemd/pm2/task registration is implicated by planning markdown edits. [VERIFIED: codebase grep] | None. [VERIFIED: codebase grep] |
| Secrets/env vars | No secret/env var rename is required; live credentials remain future/manual/on-demand. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://12factor.net/config] | Do not add committed secrets or live credential toggles. [CITED: https://12factor.net/config] |
| Build artifacts | None required; phase should not build SDK artifacts. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] | No reinstall/build cleanup. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |

**Nothing found in category:** All five runtime categories were checked through scope review and codebase grep; no runtime migration is required. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating `VALIDATION.md` as Missing Proof
**What goes wrong:** Phase 25 gets described as unverified because it lacks the standard `25-VERIFICATION.md` filename. [VERIFIED: `.planning/v2.0-MILESTONE-AUDIT.md`]
**Why it happens:** Older audit expectations looked for a standard filename, while the actual artifact is `.planning/phases/25-offline-mode-foundation/VALIDATION.md`. [VERIFIED: codebase grep]
**How to avoid:** Say "validated via `VALIDATION.md`; standard `VERIFICATION.md` absent/non-standard." [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
**Warning signs:** Text such as "ADV-01 remains unverified" without citing `VALIDATION.md`. [VERIFIED: `.planning/milestones/v2.0-ROADMAP.md`; VERIFIED: `.planning/milestones/v2.0-REQUIREMENTS.md`]

### Pitfall 2: Conflating MockServer with Paddle Provider State
**What goes wrong:** Future agents believe Phase 26 ran live/sandbox Paddle provider-state checks. [VERIFIED: codebase grep]
**Why it happens:** `.planning/MILESTONES.md` says "against Paddle state"; newer proof files say MockServer-backed by default. [VERIFIED: codebase grep]
**How to avoid:** Use proof ladder language: unit/contract, MockServer/offline, sandbox, live. [VERIFIED: `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md`]
**Warning signs:** Phrases such as "sandbox verified", "provider-state verified", "against Paddle state", or "via Paddle" without concrete credential-backed proof. [VERIFIED: codebase grep]

### Pitfall 3: Active Backlog Becomes Historical Archive
**What goes wrong:** Shipped B-IDs continue to look like candidate work during new milestone planning. [VERIFIED: `.planning/BACKLOG.md`]
**Why it happens:** Current `.planning/BACKLOG.md` contains shipped entries B-01, B-02, B-03, B-05, B-06, and B-07. [VERIFIED: `.planning/BACKLOG.md`]
**How to avoid:** Move shipped entries to `.planning/BACKLOG-ARCHIVE.md`; keep B-04 active as `Accrue-only`. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
**Warning signs:** Future oarlock ROADMAP generation surfaces B-01/B-02/B-03 as new SDK scope. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

### Pitfall 4: Unsupported Preferences Look Durable
**What goes wrong:** Future agents miss adopter-first/DX/research preferences because `gsd-tools` ignores the top-level `preferences` object. [VERIFIED: local command]
**Why it happens:** The current config has `preferences`, and `init.phase-op` warns unknown config keys are ignored. [VERIFIED: `.planning/config.json`; VERIFIED: local command]
**How to avoid:** Keep supported workflow keys in `.planning/config.json`; put prose judgment lenses in a supported policy file or user/global defaults. [VERIFIED: `/Users/jon/.codex/gsd-core/references/planning-config.md`; CITED: https://git-scm.com/docs/git-config]
**Warning signs:** GSD commands continue warning about unknown config keys. [VERIFIED: local command]

## Code Examples

Verified patterns from project and official sources:

### Backlog Archive Entry
```markdown
## B-01 — `Paddle.Transactions.get/2`

**Status:** Shipped
**Satisfied by:** Phase 6 / v1.1
**Archive rationale:** Historical Accrue checkout reconciliation request; no longer active oarlock SDK scope.
```

### Thread Index Entry
```markdown
| Thread | Status | Lesson | Canonical Link | Reopen Condition |
|--------|--------|--------|----------------|------------------|
| 2026-05-30 subscription-create revalidation | Resolved | Do not add `Paddle.Subscriptions.create/2`; recurring starts remain transaction/checkout or invoice-backed. | `.planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md` | Paddle primary docs introduce a clean provider-native direct subscription-create API. |
```

### Drift Probe Examples
```bash
rg -n "against Paddle state|provider-state verified|sandbox verified|live verified" .planning README.md guides demo/README.md CHANGELOG.md
rg -n "B-0[123567]" .planning/BACKLOG.md .planning/BACKLOG-ARCHIVE.md
rg -n "preferences" .planning/config.json
node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.phase-op 29
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Active backlog also stores shipped history | Active backlog plus archive with preserved IDs | Phase 29 decision, 2026-06-24 | Future planning starts from live candidates without losing traceability. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Ambiguous "Paddle state" proof | Evidence-classed proof ladder | Phase 27/29 decisions, 2026-06-24 | Avoids overclaiming MockServer proof as sandbox/live provider-state proof. [VERIFIED: `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md`; VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Resolved threads in active path | `threads/INDEX.md` plus `threads/resolved/YYYY/` | Phase 29 decision, 2026-06-24 | Keeps investigation memory searchable without making it look open. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Arbitrary `preferences` config object | Supported config keys plus policy/defaults note | Phase 29 research, 2026-06-24 | Prevents durable preferences from living only in ignored config. [VERIFIED: local command] |

**Deprecated/outdated:**
- "against Paddle state" without qualification is outdated for Phase 26 because available evidence is MockServer-backed by default. [VERIFIED: codebase grep]
- "ADV-01 remains unverified" is outdated because Phase 25 has `VALIDATION.md`; the caveat is non-standard filename. [VERIFIED: `.planning/phases/25-offline-mode-foundation/VALIDATION.md`; VERIFIED: `.planning/v2.0-MILESTONE-AUDIT.md`]
- Top-level `.planning/config.json` `preferences` as the only durable preference store is unreliable because GSD warns it is ignored. [VERIFIED: local command]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A separate policy/defaults markdown artifact is acceptable if GSD config schema cannot represent adopter-first/DX/research lenses directly. [ASSUMED] | Standard Stack / Pitfalls | Planner may need to choose an exact filename or ask whether to use global defaults instead. |

## Open Questions

1. **Where should non-schema project judgment lenses live?**
   - What we know: `.planning/config.json` top-level `preferences` is currently warned as unknown by `gsd-tools`. [VERIFIED: local command]
   - What's unclear: Whether the user prefers a project-local markdown defaults file, a global user default, or both. [ASSUMED]
   - Recommendation: Put supported gates in `.planning/config.json` and preserve prose judgment lenses in a small committed planning policy note unless the planner confirms a supported global defaults path. [VERIFIED: `/Users/jon/.codex/gsd-core/references/planning-config.md`; ASSUMED]

2. **Should the evidence ledger be standalone or embedded?**
   - What we know: Both `.planning/EVIDENCE.md` and an explicit section in `.planning/v2.0-MILESTONE-AUDIT.md` are allowed. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
   - What's unclear: Which location the planner should choose for lowest future drift. [ASSUMED]
   - Recommendation: Use standalone `.planning/EVIDENCE.md` if the plan also wants v2.1 proof classification; embed in `v2.0-MILESTONE-AUDIT.md` if keeping blast radius minimal is more important. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `rg` | Drift searches | ✓ | 15.1.0 | `grep -R`, slower. [VERIFIED: local command] |
| `git` | File moves/history and optional commit | ✓ | 2.41.0 | Manual file edits without commit, not preferred when `commit_docs` is true. [VERIFIED: local command] |
| `node` | `gsd-tools.cjs` and config validation | ✓ | v22.14.0 | None for GSD seam commands. [VERIFIED: local command] |
| `mix` | Optional smoke tests if code touched | ✓ | Mix 1.19.5 / Erlang OTP 28 | Skip for docs-only edits unless final smoke requested. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none found. [VERIFIED: local command]

**Missing dependencies with fallback:** none required for planned markdown/config reconciliation. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Markdown/config drift probes plus existing ExUnit/Mix if code-adjacent smoke is desired. [VERIFIED: codebase grep] |
| Config file | `.planning/config.json`; root `mix.exs` only for optional smoke. [VERIFIED: codebase grep] |
| Quick run command | `rg -n "against Paddle state|provider-state verified|sandbox verified|live verified|ADV-01 remains unverified" .planning README.md guides demo/README.md CHANGELOG.md` [VERIFIED: codebase grep] |
| Full suite command | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.phase-op 29 && rg -n "B-0[123567]" .planning/BACKLOG.md && rg -n "Status: resolved" .planning/threads` with expected controlled matches after updates. [VERIFIED: local command] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| GSD-01 | Core planning docs agree on shipped/open scope. [VERIFIED: `.planning/REQUIREMENTS.md`] | docs grep/manual read | `rg -n "Phase 29|GSD-0[1-4]|v2.1|Phase 27|Phase 28|Phase 25|Phase 26" .planning/PROJECT.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md .planning/MILESTONES.md .planning/v2.0-MILESTONE-AUDIT.md` | ✅ Wave 0 not needed. [VERIFIED: codebase grep] |
| GSD-02 | Stale backlog/thread items are classified and archived. [VERIFIED: `.planning/REQUIREMENTS.md`] | docs grep | `rg -n "B-0[123567]" .planning/BACKLOG.md .planning/BACKLOG-ARCHIVE.md && rg -n "subscription-create|Reopen Condition|resolved" .planning/threads` | ❌ Wave 0: `BACKLOG-ARCHIVE.md`, `threads/INDEX.md`, resolved folder. [VERIFIED: codebase grep] |
| GSD-03 | v2.0/Phase 25/26 proof wording matches evidence. [VERIFIED: `.planning/REQUIREMENTS.md`] | docs grep/manual read | `rg -n "against Paddle state|via Paddle|provider-state|VALIDATION.md|MockServer-backed|VERIFICATION.md" .planning/MILESTONES.md .planning/milestones/v2.0-*.md .planning/v2.0-MILESTONE-AUDIT.md .planning/phases/25-offline-mode-foundation/VALIDATION.md .planning/phases/26-advanced-subscription-flows-e2e/26-VERIFICATION.md` | ✅ Existing proof files; ❌ ledger/errata if standalone. [VERIFIED: codebase grep] |
| GSD-04 | Durable preferences are available in supported project/global defaults. [VERIFIED: `.planning/REQUIREMENTS.md`] | config/schema probe | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.phase-op 29 2>&1 | rg "unknown config key|preferences" -n` should have no unknown-key warning after reconciliation. | ✅ `.planning/config.json`; policy/defaults file TBD. [VERIFIED: local command] |

### Sampling Rate
- **Per task commit:** Run the focused `rg` probe for the edited surface. [VERIFIED: codebase grep]
- **Per wave merge:** Run the GSD init/config probe plus all GSD-01..04 grep commands. [VERIFIED: local command]
- **Phase gate:** Manual read-through of `PROJECT`, `REQUIREMENTS`, `ROADMAP`, `STATE`, `BACKLOG`, archive, threads index, and evidence/audit file before `$gsd-verify-work`. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]

### Wave 0 Gaps
- [ ] `.planning/BACKLOG-ARCHIVE.md` covers GSD-02. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
- [ ] `.planning/threads/INDEX.md` covers GSD-02. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
- [ ] `.planning/threads/resolved/2026/` folder and moved thread covers GSD-02. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
- [ ] Evidence ledger location chosen and created/updated covers GSD-03. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
- [ ] Supported location for prose GSD preferences chosen covers GSD-04. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase edits planning docs/config only; no auth surface. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| V3 Session Management | no | No session/runtime behavior. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| V4 Access Control | no | No app access-control code. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| V5 Input Validation | yes | Validate markdown/config edits through grep/schema probes; do not treat unchecked prose as proof. [VERIFIED: local command] |
| V6 Cryptography | no | No cryptographic implementation; do not add or expose credentials. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://12factor.net/config] |

### Known Threat Patterns for Planning-State Reconciliation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Evidence spoofing through vague proof wording | Tampering / Repudiation | Use evidence class, artifact link, command/proof, and caveat columns. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |
| Credential leakage while documenting live provider proof | Information Disclosure | Keep live Paddle sandbox/provider-state credentials out of committed docs/config; require separate evidenced runs. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`; CITED: https://12factor.net/config] |
| Scope escalation from Accrue-only backlog item | Elevation of Privilege / Tampering | Label B-04 as `Accrue-only`; do not promote to oarlock SDK scope without a future milestone decision. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md` - locked decisions, phase scope, canonical refs. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - GSD-01 through GSD-04 definitions. [VERIFIED: codebase grep]
- `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/BACKLOG.md`, `.planning/MILESTONES.md` - current planning truth and drift targets. [VERIFIED: codebase grep]
- `.planning/v2.0-MILESTONE-AUDIT.md`, Phase 25 `VALIDATION.md`, Phase 26 `26-VERIFICATION.md`, Phase 27/28 context and verification files - evidence boundary sources. [VERIFIED: codebase grep]
- `/Users/jon/.codex/gsd-core/references/planning-config.md` and config schema manifest - supported GSD config keys. [VERIFIED: local command]

### Secondary (MEDIUM confidence)
- https://keepachangelog.com/en/1.1.0/ - curated human-readable history pattern. [CITED: https://keepachangelog.com/en/1.1.0/]
- https://sre.google/sre-book/postmortem-culture/ and https://sre.google/workbook/postmortem-culture/ - factual postmortem/follow-up culture. [CITED: https://sre.google/sre-book/postmortem-culture/]
- https://git-scm.com/docs/git-config - config scope precedent. [CITED: https://git-scm.com/docs/git-config]
- https://editorconfig.org/ - committed project defaults precedent. [CITED: https://editorconfig.org/]
- https://12factor.net/config - environment/personal/runtime config boundary. [CITED: https://12factor.net/config]
- https://semver.org/ - public API claim precision. [CITED: https://semver.org/]

### Tertiary (LOW confidence)
- Assumption that a small markdown policy/defaults note is the best fallback for non-schema GSD preference prose if no supported global-default path is chosen. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no package stack; local tools and planning files verified. [VERIFIED: local command]
- Architecture: HIGH - locked decisions define artifact ownership and scope. [VERIFIED: `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md`]
- Pitfalls: HIGH - concrete drift strings and current files were found locally. [VERIFIED: codebase grep]
- External norms: MEDIUM - sourced from official/public docs via web search and cached through GSD research store. [CITED: https://keepachangelog.com/en/1.1.0/; CITED: https://sre.google/sre-book/postmortem-culture/]

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 for local planning-state findings; re-run grep/config probes if Phase 29 planning is delayed. [ASSUMED]
