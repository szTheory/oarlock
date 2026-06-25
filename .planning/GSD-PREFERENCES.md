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
