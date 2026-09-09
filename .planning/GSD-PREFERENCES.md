# GSD Preferences and Policy

**Purpose:** Preserve oarlock's recurring GSD planning preferences in supported project artifacts without relying on ignored config keys or silently imposing personal execution style on every future contributor.

## Supported Project Defaults

`.planning/config.json` owns schema-supported shared workflow gates for this repository:

- `commit_docs: true` preserves GSD planning artifacts in repo history. It does not grant blanket permission to auto-commit runtime code, unrelated planning edits, secrets, or generated noise.
- `workflow.research: true` and `workflow.research_before_questions: true` keep research before planning as the default posture.
- `workflow.plan_check: true`, `workflow.verifier: true`, and `workflow.code_review: true` keep planned work reviewable before it is treated as done.
- `workflow.nyquist_validation: true` keeps validation pressure on claims, evidence, and edge cases.
- `workflow.pattern_mapper: true` keeps pattern mapping available before changing established project behavior.
- `workflow.use_worktrees: false` is an explicit local execution choice for this project while Phase 29 is reconciling state in the main working tree.

## Project Judgment Lenses

Future GSD planning for oarlock should keep these lenses visible:

- **Research before planning:** read current project artifacts, source evidence, and relevant provider docs before asking the user to choose a direction.
- **Subagent research for gray areas:** when the question involves provider behavior, ecosystem norms, or ambiguous scope, gather independent research before locking the plan.
- **Adopter-first assessment:** judge "done" by what a cold Phoenix SaaS adopter can understand and safely use, not only by whether code compiles.
- **DX/UX-first judgment:** prefer clear names, small surfaces, predictable setup, and honest error boundaries over feature breadth.
- **Retained investigations:** preserve resolved research in indexed planning memory with clear reopen conditions instead of deleting useful lessons.
- **Nyquist validation:** make proof boundaries explicit, especially MockServer-backed evidence versus sandbox/live Paddle provider-state evidence.
- **Pattern mapping:** align new plans with oarlock's provider-native, pure SDK, explicit-client, typed-response patterns before introducing new abstractions.

## Personal and User-Global Boundaries

These knobs are personal execution style, per-run risk appetite, or user-global configuration. They should not be hidden as repo policy:

- `yolo` / interactive mode selection.
- `workflow.auto_advance`.
- Aggressive parallelization choices.
- `model_profile` or model routing preferences.

Use those when invoking GSD if they match the current operator's intent, but do not treat them as shared project requirements. Shared project policy belongs in supported config keys and this document.

## Scope Boundary

This file describes GSD planning behavior only. It does not change oarlock runtime scope, Paddle Billing API support, Accrue-side responsibilities, or release proof requirements.

## Repository and planning truth authority

Before routing repository work or asserting that a phase is complete, maintainers
and repository-operating GSD agents run:

```sh
node scripts/planning_health.cjs
```

The command is report-only: it has no apply or repair flag, and every reported
repair is an inert proposed patch or supported GSD action for separate review.
Exit 1 blocks on a policy conflict; exit 2 blocks on an incomplete or changing
snapshot. `--json` renders the same diagnostic codes, severities, and conclusion.

Authority is assigned per datum:

| Datum | Canonical owner | Role of other artifacts |
|---|---|---|
| Committed milestone requirements | `.planning/REQUIREMENTS.md` bounded current-milestone section | Source anchors, future requirements, caches, and generated files are not committed IDs |
| Active phase graph and requirement mapping | `.planning/ROADMAP.md` | Phase directories, plans, summaries, research, and archives are inert evidence |
| Current execution pointer and session | `.planning/STATE.md` | A pointer must name a member of the ROADMAP graph; disagreement blocks with no selected winner |
| Durable project scope and constraints | `.planning/PROJECT.md` | It supplies context but does not override the execution pointer |
| Shipped-history navigation | `.planning/MILESTONES.md` plus immutable milestone archives | Current ledgers may add dated corrections; frozen snapshots are not rewritten |
| Proof classification and corrections | `.planning/EVIDENCE.md` | A filename alone does not prove acceptance or completion |
| Disposable machine mirror | `.planning/state.json` when published by the installed GSD runtime | Versioned corroboration only; never routing or completion authority |

Installed GSD read-only queries corroborate this repository-local chain. They do
not supersede it, and generated/cached/archived artifact presence never activates
or completes work.
