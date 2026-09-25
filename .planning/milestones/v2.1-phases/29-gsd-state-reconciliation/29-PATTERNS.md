# Phase 29: gsd-state-reconciliation - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/BACKLOG.md` | docs | transform | `.planning/BACKLOG.md` | exact |
| `.planning/BACKLOG-ARCHIVE.md` | docs | transform + file-I/O | `.planning/BACKLOG.md` + `.planning/MILESTONES.md` | role-match |
| `.planning/MILESTONES.md` | docs | transform | `.planning/MILESTONES.md` | exact |
| `.planning/v2.0-MILESTONE-AUDIT.md` | docs | transform | `.planning/v2.0-MILESTONE-AUDIT.md` | exact |
| `.planning/EVIDENCE.md` | docs | transform | `.planning/v2.0-MILESTONE-AUDIT.md` + `26-VERIFICATION.md` | role-match |
| `.planning/milestones/v2.0-ROADMAP.md` | docs | transform | `.planning/ROADMAP.md` + `.planning/v2.0-MILESTONE-AUDIT.md` | role-match |
| `.planning/milestones/v2.0-REQUIREMENTS.md` | docs | transform | `.planning/REQUIREMENTS.md` + `.planning/v2.0-MILESTONE-AUDIT.md` | role-match |
| `.planning/threads/INDEX.md` | docs | transform + file-I/O | `.planning/threads/2026-05-30-subscription-create-revalidation.md` | role-match |
| `.planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md` | docs | file-I/O + transform | `.planning/threads/2026-05-30-subscription-create-revalidation.md` | exact |
| `.planning/config.json` | config | transform | `.planning/config.json` + GSD config reference | exact |
| `.planning/GSD-PREFERENCES.md` | docs | transform | `.planning/config.json` + `.planning/phases/29-gsd-state-reconciliation/29-RESEARCH.md` policy-note pattern | role-match |
| `.planning/PROJECT.md` | docs | transform | `.planning/PROJECT.md` | exact |
| `.planning/REQUIREMENTS.md` | docs | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/STATE.md` | docs | transform | `.planning/STATE.md` | exact |

## Pattern Assignments

### `.planning/BACKLOG.md` (docs, transform)

**Analog:** `.planning/BACKLOG.md`

**Active backlog intro pattern** (lines 1-5):
```markdown
# Backlog

Future work captured outside the current milestone. Each entry is an idea or request that should surface during next-milestone planning, not work being done now.

Promotion path: when the user is ready, an entry becomes a phase via `/gsd-new-milestone` -> `/gsd-discuss-phase` (or `/gsd-add-phase`). The entry ID (e.g. `B-01`) gets cited in the resulting phase's source-of-requirement field so the trail stays intact.
```

**Accrue-only active item pattern** (lines 80-97):
```markdown
## B-04 - Accrue migration: `%Paddle.Error{}.raw` -> `%Paddle.Error{}.raw_data`

**Source:** Phase 8 / Reliability Primitives - atomic rename landed in oarlock per D-01..D-05 (`.planning/phases/08-reliability-primitives/08-CONTEXT.md`).
**Priority:** Medium - silent runtime breakage on the Accrue side (`%Paddle.Error{raw: r}` pattern matches will fail to bind after consuming the new oarlock version).
**Status:** Open on the Accrue side only. Oarlock shipped the `raw_data` field; Accrue update is a follow-up commit on the consumer side.
```

Planner note: keep only B-04 in the active backlog, relabeled `Accrue-only`, plus the new status taxonomy. Move B-01, B-02, B-03, B-05, B-06, and B-07 to archive without renumbering.

---

### `.planning/BACKLOG-ARCHIVE.md` (docs, transform + file-I/O)

**Analogs:** `.planning/BACKLOG.md`, `.planning/MILESTONES.md`

**Archived B-ID source block pattern** (`.planning/BACKLOG.md` lines 9-26):
```markdown
## B-01 - `Paddle.Transactions.get/2`

**Source:** Accrue (`~/projects/accrue`) - checkout reconciliation flow needs to fetch a transaction by ID after creation.
**Priority:** High - small, isolated, unblocks a real downstream consumer.
**Status:** Shipped in Phase 6 / v1.1. Keep for historical trace only.

**Why it's a gap:** Phase 4 (Transactions & Hosted Checkout) executed only `Paddle.Transactions.create/2`. The retrieval surface was deliberately deferred at the time. Accrue's first slice can't reconcile checkouts without it.
```

**Archive-link pattern** (`.planning/MILESTONES.md` lines 23-28):
```markdown
### Archive

- Roadmap: `.planning/milestones/v2.0-ROADMAP.md`
- Requirements: `.planning/milestones/v2.0-REQUIREMENTS.md`
- Audit: `.planning/v2.0-MILESTONE-AUDIT.md`
- Tag: `v2.0`
```

Planner note: archive entries should preserve original B-IDs, source, rationale, and status, then add `Satisfied by:` links to the phase/milestone that shipped the work.

---

### `.planning/MILESTONES.md` (docs, transform)

**Analog:** `.planning/MILESTONES.md`

**Milestone summary pattern** (lines 7-17):
```markdown
## v2.0 Offline Mode & Advanced Billing - 2026-06-11

**Status:** Shipped
**Phases:** 25-26 (3 plans)
**Test suite at tag:** Passes locally

### Delivered

1. **Offline Mode Foundation** - Introduced `Paddle.MockServer` powered by Bandit for fully standalone offline Paddle development and testing. SDK clients can seamlessly point to the offline server via configuration.
2. **Advanced Subscription Flows E2E** - Delivered comprehensive E2E testing flows for complex upgrade and downgrade subscription scenarios, fully verifying prorations and billing cycles against Paddle state without manual intervention.
```

**Known caveat pattern** (lines 18-22):
```markdown
### Key Decisions

- Selected Bandit for the `Paddle.MockServer` foundation.
- Accepted incomplete verification (missing VERIFICATION.md) for Phase 25 as technical debt to proceed with shipping.
```

Planner note: replace or annotate line 16's "against Paddle state" language with MockServer-backed proof language. Replace line 21's "missing VERIFICATION.md" framing with "validated via `VALIDATION.md`; standard `VERIFICATION.md` absent/non-standard."

---

### `.planning/v2.0-MILESTONE-AUDIT.md` (docs, transform)

**Analog:** `.planning/v2.0-MILESTONE-AUDIT.md`

**Front matter caveat pattern** (lines 1-22):
```markdown
---
milestone: 2.0
audited: 2026-06-24T00:00:00Z
status: passed_with_caveats
scores:
  requirements: 2/2
tech_debt:
  - "Phase 25 validation exists as VALIDATION.md, not the standard VERIFICATION.md artifact."
  - "Phase 26 proof is MockServer-backed integration by default; do not describe it as live Paddle provider-state E2E unless sandbox checks are run."
nyquist:
  compliant_phases: ["25", "26"]
  overall: passed_with_caveats
---
```

**Requirements evidence table pattern** (lines 35-40):
```markdown
| ID | Description | Assigned Phase | Status | Verification Status |
|----|-------------|----------------|--------|---------------------|
| ADV-01 | Offline Mode mock server for local SDK and demo integration tests | Phase 25 | **satisfied** | passed via VALIDATION.md |
| ADV-02 | Complex upgrade/downgrade flows through MockServer-backed integration tests | Phase 26 | **satisfied** | passed |
```

**Nyquist/action table pattern** (lines 59-64):
```markdown
| Phase | VALIDATION.md | Compliant | Action |
|-------|---------------|-----------|--------|
| 25 | present | true | Standardize artifact name if desired |
| 26 | verification present | true | Keep proof language scoped to MockServer-backed integration unless sandbox checks run |
```

Planner note: add the evidence ledger here if keeping the change localized. Use dated errata rather than silent historical rewrite.

---

### `.planning/EVIDENCE.md` (optional docs, transform)

**Analogs:** `.planning/v2.0-MILESTONE-AUDIT.md`, `.planning/phases/26-advanced-subscription-flows-e2e/26-VERIFICATION.md`, `.planning/phases/25-offline-mode-foundation/VALIDATION.md`

**Observable truth table pattern** (`26-VERIFICATION.md` lines 20-30):
```markdown
| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 3 | Test flows successfully assert against deterministic subscription state without manual intervention. | VERIFIED | Test suite automatically defaults to `Paddle.MockServer`; sandbox execution is opt-in through environment flags |
| 7 | Tests are structured to run against real sandbox on demand (D-03). | VERIFIED | Tests use `PADDLE_API_KEY` and `INTEGRATION_TESTS` toggles in `setup_all`; this report does not claim sandbox execution happened by default |
```

**Required artifact table pattern** (`26-VERIFICATION.md` lines 34-40):
```markdown
| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/paddle/subscriptions.ex` | provides update/3 | VERIFIED | Substantive implementation handling `update_allowlist` |
| `lib/paddle/mock_server.ex` | provides patch "/subscriptions/:id" route | VERIFIED | Explicit `patch` match returning fixture based on `proration_billing_mode` payload |
| `test/paddle/subscription_flows_test.exs` | provides integration test cases | VERIFIED | E2E specs for `Paddle.Subscriptions.update` |
```

**Validation evidence pattern** (`VALIDATION.md` lines 6-18):
```markdown
### OFF-01: Verify `Paddle.Client` correctly respects the `:base_url` override and attempts to hit `localhost:4001` when configured.
- **Coverage**: **COVERED**
- **Evidence**: `test/paddle/client_test.exs` contains `test "new!/1 respects the :base_url option when provided"` which explicitly checks that the `req.options.base_url` configuration corresponds to the dynamically injected base URL option.
```

Planner note: if creating standalone `.planning/EVIDENCE.md`, use columns required by CONTEXT: `Requirement`, `Artifact`, `Evidence Class`, `Command / Proof`, and `Caveat`.

---

### `.planning/milestones/v2.0-ROADMAP.md` and `.planning/milestones/v2.0-REQUIREMENTS.md` (docs, transform)

**Analogs:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/v2.0-MILESTONE-AUDIT.md`

**Proof-boundary success criterion pattern** (`.planning/ROADMAP.md` lines 33-38):
```markdown
**Success Criteria:**

1. README, Getting Started, seam contract, demo runbook, and changelog agree with shipped modules and function arities.
2. Docs distinguish core SDK responsibilities from Phoenix/Ecto/provisioning responsibilities.
3. MockServer-backed proof is described honestly and not conflated with live Paddle provider-state testing.
```

**Requirement proof-boundary pattern** (`.planning/REQUIREMENTS.md` lines 10-14):
```markdown
- [x] **DOCS-01**: README, Getting Started, and seam contract accurately describe the shipped SDK surface.
- [x] **DOCS-02**: Demo app documentation explains local setup, mock auth, webhook processing, portal handoff, and Offline Mode.
- [x] **DOCS-03**: Docs distinguish core SDK responsibilities from app-owned Phoenix/Ecto/provisioning responsibilities.
- [x] **DOCS-04**: Docs state the proof boundary honestly: MockServer-backed integration is not the same as live Paddle provider-state verification.
```

Planner note: correct stale v2.0 wording found by `rg`: `v2.0-ROADMAP.md` says "Paddle state (Sandbox or Mock)" and "ADV-01 remains unverified"; update with dated correction notes that point at `VALIDATION.md` and MockServer-backed proof.

---

### `.planning/threads/INDEX.md` (docs, transform + file-I/O)

**Analog:** `.planning/threads/2026-05-30-subscription-create-revalidation.md`

**Thread metadata pattern** (lines 1-7):
```markdown
# Investigation: Phase 10 Subscription Create Revalidation

**Status:** resolved
**Created:** 2026-05-30
**Resolved:** 2026-06-24
**Owner:** Phase 10 / v2.1 adopter truth assessment
```

**Durable lesson and reopen condition pattern** (lines 25-39):
```markdown
## Resolution

Phase 10 resolved this by rejecting a direct `Paddle.Subscriptions.create/2`
surface for the current seam. The provider-native recurring-start path is:

1. create a transaction for recurring items,
2. send the customer through Paddle Checkout or manual collection,
3. verify webhook events,
4. reconcile with `Paddle.Transactions.get/2`,
5. fetch canonical subscription state with `Paddle.Subscriptions.get/2`.

The SDK now documents this as the supported path and explicitly avoids adding
`Paddle.Subscriptions.create/2`. Reopen this thread only if current Paddle
primary docs introduce a clean direct subscription-create API that fits the
provider model.
```

Planner note: create an index table with `Thread`, `Status`, `Lesson`, `Canonical Link`, and `Reopen Condition`.

---

### `.planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md` (docs, file-I/O + transform)

**Analog:** `.planning/threads/2026-05-30-subscription-create-revalidation.md`

**Move target pattern:** keep file contents intact and move from the active-looking root thread path to:
```text
.planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md
```

Planner note: after moving, any references in `.planning/threads/INDEX.md`, `.planning/research/JTBD-GAPS.md`, or phase context should resolve to the new canonical path.

---

### `.planning/config.json` (config, transform)

**Analog:** `.planning/config.json`

**Current project config pattern** (lines 1-15):
```json
{
  "mode": "yolo",
  "granularity": "coarse",
  "parallelization": true,
  "commit_docs": true,
  "model_profile": "balanced",
  "preferences": {
    "vendor_philosophy": "opinionated",
    "research_with_subagents": true,
    "idiomatic_elixir_lens": true,
    "adopter_first_done_lens": true,
    "retain_investigations": true,
    "dx_ux_first": true
  },
```

**Workflow gate pattern** (lines 15-33):
```json
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "research_before_questions": true,
    "nyquist_validation": true,
    "auto_advance": false,
    "pattern_mapper": true,
    "code_review": true,
    "code_review_depth": "standard",
    "skip_discuss": false
  },
```

**Supported GSD config reference** (`$HOME/.codex/gsd-core/references/planning-config.md` lines 27-45):
```markdown
| `commit_docs` | `true` | Whether to commit planning artifacts to git |
| `search_gitignored` | `false` | Add `--no-ignore` to broad rg searches |
| `git.branching_strategy` | `"none"` | Git branching approach: `"none"`, `"phase"`, or `"milestone"`. |
| `workflow.use_worktrees` | `true` | Whether executor agents run in isolated git worktrees. |
| `workflow.test_command` | `null` | Custom shell command run as the regression/test gate by verify-phase, execute-phase, audit-fix, and post-merge-gate. |
```

Planner note: preserve supported shared gates (`commit_docs`, `workflow.research`, `research_before_questions`, `nyquist_validation`, `pattern_mapper`). Move personal/autonomy knobs (`mode: yolo`, broad `parallelization`, `model_profile`) out of project policy unless explicitly wanted. Do not rely on unknown top-level `preferences` as the only durable store for judgment lenses.

---

### `.planning/GSD-PREFERENCES.md` (docs, transform)

**Analogs:** `.planning/config.json`, `.planning/phases/29-gsd-state-reconciliation/29-RESEARCH.md` policy-note pattern

**Policy-note pattern:** use a committed markdown note for project-local judgment lenses that are durable but not represented by supported GSD config keys. Keep it compact and explicit about the boundary between shared repo policy and personal execution style.

**Required sections:**
- Project-local defaults: research before planning, subagent research for gray areas, adopter-first assessment, DX/UX-first judgment, retained investigations, Nyquist validation, pattern mapping, and GSD planning artifact durability.
- Supported config link: point to `.planning/config.json` for schema-supported workflow gates such as `commit_docs`, `workflow.research`, `workflow.research_before_questions`, `workflow.nyquist_validation`, and `workflow.pattern_mapper`.
- Personal/global boundary: state that `yolo`, `auto_advance`, aggressive parallelization, and model profile remain per-run or user-global choices rather than surprising project policy.

Planner note: create `.planning/GSD-PREFERENCES.md` in Plan 29-03 alongside `.planning/config.json`; do not rely on a top-level `preferences` object in JSON as the only durable preference store.

---

### `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` (docs, transform)

**Analogs:** same files.

**PROJECT current-state pattern** (`.planning/PROJECT.md` lines 15-24):
```markdown
## Current State

**Shipped:** v2.0 Offline Mode & Advanced Billing on 2026-06-11 - see `.planning/milestones/v2.0-ROADMAP.md`.

oarlock now exposes a typed, documented, and resilient consumer surface including core entities, events, notification settings, support adjustments, portal sessions, and an Offline Mode mock server:
- `Paddle.MockServer` powered by Bandit for local offline development and tests.
- Complex upgrade and downgrade subscription scenarios verified through MockServer-backed integration tests, with sandbox/provider-state checks remaining optional and demand-driven.
```

**REQUIREMENTS GSD truth pattern** (`.planning/REQUIREMENTS.md` lines 22-27):
```markdown
### GSD Truth

- [ ] **GSD-01**: Root PROJECT, REQUIREMENTS, ROADMAP, STATE, BACKLOG, and milestone audit files agree on the current shipped state.
- [ ] **GSD-02**: Stale investigations and backlog items are marked resolved, superseded, or explicitly moved to Accrue-side follow-up.
- [ ] **GSD-03**: v2.0 audit and Phase 25/26 validation language is reconciled with actual evidence.
- [ ] **GSD-04**: Recurring GSD preferences for research, adopter-first assessment, DX/UX, and lesson retention are present in project/global defaults.
```

**STATE known debt/todos pattern** (`.planning/STATE.md` lines 63-73):
```markdown
### Known Technical Debt / Blockers

- Root `.planning/REQUIREMENTS.md` was missing before v2.1 planning and has been restored for the selected milestone.
- `Paddle.MockServer` is a useful offline fixture but not a complete Paddle clone; docs and planning should avoid claiming provider-state E2E unless sandbox/live verification is actually run.
- Accrue still has a consumer-side follow-up to migrate any `%Paddle.Error{}.raw` usage to `raw_data`.

### Todos

- Reconcile v2.0 audit/validation language for Phase 25 and Phase 26.
- Close or annotate stale backlog/thread entries that shipped in earlier milestones.
```

Planner note: update these root docs only enough to make them agree with the archive, evidence ledger, thread index, and config-policy outcome.

## Shared Patterns

### Status Taxonomy
**Source:** `.planning/BACKLOG.md` and Phase 29 CONTEXT decisions D-01..D-05  
**Apply to:** `.planning/BACKLOG.md`, `.planning/BACKLOG-ARCHIVE.md`

Use a small taxonomy near the top of both backlog files:
```markdown
## Status Taxonomy

- `Open`: candidate for future oarlock planning.
- `Accrue-only`: tracked for consumer-side memory; not oarlock SDK scope unless promoted by a later milestone.
- `Shipped`: satisfied by a prior phase or milestone; retained in archive only.
- `Superseded`: replaced by a newer decision or scope.
- `Reference`: historical context, not a planning candidate.
```

### Append-Only Errata
**Source:** `.planning/v2.0-MILESTONE-AUDIT.md` caveat pattern and Phase 29 decisions D-06..D-10  
**Apply to:** milestone audit, v2.0 roadmap/requirements, milestone log

Use dated notes where old wording overclaimed proof:
```markdown
> **Errata, 2026-06-24:** Earlier wording described this proof as "against Paddle state."
> The evidence available in this repository is MockServer-backed integration proof.
> Sandbox/live provider-state proof requires real credentials and a separately recorded run.
```

### Evidence Classification
**Source:** `26-VERIFICATION.md` lines 20-30 and `.planning/v2.0-MILESTONE-AUDIT.md` lines 35-40  
**Apply to:** `.planning/EVIDENCE.md` or `.planning/v2.0-MILESTONE-AUDIT.md`

```markdown
| Requirement | Artifact | Evidence Class | Command / Proof | Caveat |
|-------------|----------|----------------|-----------------|--------|
| ADV-01 | `.planning/phases/25-offline-mode-foundation/VALIDATION.md` | Validation artifact | OFF-01..03 coverage listed | Non-standard filename; no `25-VERIFICATION.md` |
| ADV-02 | `.planning/phases/26-advanced-subscription-flows-e2e/26-VERIFICATION.md` | MockServer-backed integration | `mix test test/paddle/subscription_flows_test.exs` | Not sandbox/live provider-state proof unless separately evidenced |
```

### Drift Probes
**Source:** Phase 29 RESEARCH validation architecture  
**Apply to:** phase verification plan

```bash
rg -n "against Paddle state|provider-state verified|sandbox verified|live verified|ADV-01 remains unverified" .planning README.md guides demo/README.md CHANGELOG.md
rg -n "B-0[123567]" .planning/BACKLOG.md .planning/BACKLOG-ARCHIVE.md
rg -n "preferences" .planning/config.json
node $HOME/.codex/gsd-core/bin/gsd-tools.cjs query init.phase-op 29
```

## No Analog Found

All identified files have local analogs. No runtime SDK, controller, service, model, middleware, route, component, or test source files are in scope for Phase 29.

## Metadata

**Analog search scope:** `.planning/`, `.planning/phases/25-*`, `.planning/phases/26-*`, `.planning/phases/27-*`, `.planning/phases/28-*`, `$HOME/.codex/gsd-core/references/planning-config.md`
**Files scanned:** 100+ planning artifacts via `rg --files .planning`; 16 concrete analog files read  
**Pattern extraction date:** 2026-06-24
