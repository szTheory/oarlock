# Phase 31: Repository & Planning Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-09-09
**Phase:** 31-repository-planning-truth
**Areas discussed:** Repository inventory and classification, Planning authority and conflicts, Milestone history and health diagnostics

---

## Repository Inventory and Classification

### Inventory output

| Option | Description | Selected |
|--------|-------------|----------|
| Human report plus JSON | Concise terminal report and deterministic machine-readable output from the same result | ✓ |
| Human report only | Simpler direct experience but no stable automation contract | |
| JSON only | Strong automation contract but poor direct usability | |

**User's choice:** Human report plus JSON.

### Classification model

| Option | Description | Selected |
|--------|-------------|----------|
| Separate facts from disposition | Preserve observations independently from proposed actions | ✓ |
| Single classification status | Combine state and recommendation into one label | |
| Facts only | Report observations without proposing a disposition | |

**User's choice:** Separate observed facts from proposed disposition.

### Ownership evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Owner with provenance and confidence | Record source, confidence, revisit date, and explicit unknowns | ✓ |
| Explicit metadata only | Record owners only from maintained metadata or lock reasons | |
| Best-effort inference | Infer ownership without separate confidence metadata | |

**User's choice:** Owner with provenance and confidence.

### Inventory exit status

| Option | Description | Selected |
|--------|-------------|----------|
| Fail only on unclassified or unsafe state | Allow known preserved dirt while failing unknown, unreadable, or risky state | ✓ |
| Fail on any dirty or locked state | Treat cleanliness as the sole pass condition | |
| Always exit successfully | Leave all failure semantics to planning health | |

**User's choice:** Fail only on unclassified, unreadable, or unsafe state.

**Notes:** The current modified, untracked, divergent, and locked items were examples only. The implementation must inspect fresh state and must not mutate it.

---

## Planning Authority and Conflicts

### Canonical ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Authority by datum | Give requirements, roadmap, state, history, and evidence distinct owners | ✓ |
| ROADMAP.md alone | Derive all planning state from the roadmap | |
| STATE.md alone | Make the execution state file primary | |

**User's choice:** Authority by datum.

### Canonical disagreement

| Option | Description | Selected |
|--------|-------------|----------|
| Fail and explain | Stop routing with exact conflicts and safe next steps | ✓ |
| Self-heal from precedence | Rewrite lower-authority state automatically | |
| Warn and continue | Choose a canonical value but permit routing | |

**User's choice:** Fail and explain. Derived caches may regenerate only after canonical inputs validate.

### Phase-directory presence

| Option | Description | Selected |
|--------|-------------|----------|
| Ignore directory presence for status | Preserve directories but require explicit current roadmap/state references | ✓ |
| Quarantine unreferenced directories | Move them out of the active phase tree | |
| Infer from artifacts | Use plans, summaries, or verification files to infer status | |

**User's choice:** Directory presence never determines active or completed status.

### Conflict repair

| Option | Description | Selected |
|--------|-------------|----------|
| Read-only check plus explicit repair | Propose the governing value and patch; apply via reviewed GSD handlers | ✓ |
| Automatic repair | Let the health check rewrite lower-authority files | |
| Detection only | Report conflicts without concrete repair guidance | |

**User's choice:** Read-only diagnosis followed by an explicit GSD-backed repair with a dated correction.

### Derived state mirror

| Option | Description | Selected |
|--------|-------------|----------|
| Keep only if required | Omit state.json unless a consumer exists; otherwise generate a source-described mirror | ✓ |
| Keep tracked | Commit the mirror and fail whenever it drifts | |
| Keep untracked | Regenerate locally without source/version metadata | |

**User's choice:** Keep `.planning/state.json` only for a demonstrated consumer.

**Notes:** Research and current GSD documentation support distinct roles for core planning files and validation on drift.

---

## Milestone History and Health Diagnostics

### Historical corrections

| Option | Description | Selected |
|--------|-------------|----------|
| Immutable snapshots plus dated errata | Preserve archives, correct the ledger, and repair current navigation | ✓ |
| Correct archives in place | Rewrite historical files to today's accepted truth | |
| Preserve and annotate only | Document contradictions without repairing navigation | |

**User's choice:** Immutable snapshots plus dated errata.

### Milestone and package identity

| Option | Description | Selected |
|--------|-------------|----------|
| Separate identities explicitly | Record milestone, tag, SHA, package version, and publication status | ✓ |
| Match future tags to Hex versions | Merge planning and package version streams | |
| Planning labels only | Exclude package identity from milestone history | |

**User's choice:** Record each identity separately and never imply equality.

### Diagnostic severity

| Option | Description | Selected |
|--------|-------------|----------|
| Error, warning, and info | Only errors block; warnings need ownership/revisit; info records facts | ✓ |
| Pass or fail only | Treat every invariant as binary | |
| Codes plus configurable policy | Let profiles decide which stable codes fail | |

**User's choice:** Error, warning, and info.

### Diagnostic record

| Option | Description | Selected |
|--------|-------------|----------|
| Stable actionable record | Include code, severity, location, expected/actual, authority, evidence, and next action | ✓ |
| Concise prose message | Provide a path and explanation without a stable schema | |
| Grouped summary | Show category counts and examples only | |

**User's choice:** Stable actionable record.

**Notes:** The current v2.1 planning/tag identity differs from the declared Hex package version `0.1.1`; history must make this distinction explicit.

---

## Agent's Discretion

No decision was explicitly delegated. Exact command names, JSON field names, implementation language, test harness, and diagnostic-code naming remain open to downstream research and planning within the locked constraints.

## Deferred Ideas

None.
