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
- **Adopter evidence before breadth:** prioritize demonstrated consumer jobs, provider truth, security, reliability, compatibility, and DX over endpoint count or activity. Treat industry examples as lenses for concrete SDK needs, not a reason to add application policy or speculative scope.
- **Automation-first, shift-left verification:** default to zero human UAT for behavior that can be proven reproducibly. Put unit, seam, integration, end-to-end, smoke, contract, downstream/demo, and CI checks at the earliest useful boundary when they provide recurring risk reduction that justifies their runtime and maintenance cost. Hand off to a human only for irreducible external state or subjective judgment; document why it cannot be automated, what automated evidence was gathered, and the remaining closure criterion.
- **High signal per runtime:** choose tests and CI checks for distinct risk reduction; cover relevant success, error, and boundary behavior; use property-based testing for selected high-value invariants. Measure CI cost and streamline redundant or low-value checks without removing required proof.
- **Keep `main` green:** after every merge or direct update, verify required CI against the exact current `main` SHA. If it fails, prioritize diagnosis and repair before merging more work or releasing; a prior green run and local success do not prove the current head.
- **Milestone closeout:** leave changes reviewable, PRs dispositioned, required `main` CI green, docs and planning current, and worktrees clean. Release promptly when adopter-facing value and project release policy warrant it; a milestone alone does not require a release.
- **Craft and privacy:** favor idiomatic, clear, self-documenting code and docs, stopping when complexity exceeds likely value. Apply relevant 12-factor principles and keep secrets, personal data, customer data, and private paths out of public Git; use only synthetic fixtures and non-reversible local-only fingerprints when necessary.
- **Context-safe handoff:** before recommending the next GSD command, ensure committed planning artifacts preserve decisions, provenance, evidence, blockers, and the exact next action needed after context reset.

These additions were recorded on 2026-09-23 from the maintainer's Oarlock milestone-roadmap direction, adapted from `prompts/oarlock-milestone-roadmap-ratchet.txt`. They extend the existing preferences and do not promote or replace roadmap candidates.

On 2026-09-24, the maintainer clarified that repeatable verification should be automated and shifted into CI by default, with human UAT reserved for the narrow cases automation cannot reliably cover.

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
