# Phase 35: Review, Ownership & Worktree Operations - Discussion Log

> **Audit trail only.** Decisions are captured in CONTEXT.md — this log preserves alternatives considered and research basis.

**Date:** 2026-09-25
**Phase:** 35-Review, Ownership & Worktree Operations
**Areas discussed:** Contributor guidance and review evidence; issue/PR disposition; isolated worktree lifecycle; dependency update flow

The maintainer asked for specialist research and one coherent, expert-recommended set so they would not need to arbitrate implementation options. The selections below are the agent's recommended defaults under that instruction, not verbatim user selections.

---

## Contributor guidance and review evidence (OPS-01)

| Option | Tradeoffs | Selected |
|--------|-----------|----------|
| Concise versioned docs/forms/templates, with proportional CI evidence | Low maintenance and reviewable in Git; contributors see expectations at point of work. Needs a completeness check and verified private security channel. | ✓ |
| Broad policy document and heavyweight contribution gates | Can capture edge cases but raises contributor friction and duplicates implementation detail. | |
| Let CI or code ownership alone define contribution quality | Repeatable for mechanical checks, but CI cannot decide intent/scope and CODEOWNERS routes rather than proving correctness. | |

**Decision basis:** Elixir and Phoenix contribution guidance favor reproducible reports and useful contributor orientation. For this pure SDK there is no app UI; GitHub forms, templates, and direct copy are the interaction surface. Keep security contact factual and owners verified.

## Issue and PR disposition (OPS-02)

| Option | Tradeoffs | Selected |
|--------|-----------|----------|
| Small state vocabulary plus dated triage record and read-only completeness audit | Versioned, transparent, low operational overhead; comments/labels can drift, so audit for gaps. | ✓ |
| GitHub Project as canonical issue/PR metadata | Searchable structured fields; adds a hosted source of truth, access/auto-add complexity, and potential duplication at current scale. | |
| Bot guesses owner/scope or automatically closes items | Reduces clicks but false assignment/closure erodes trust and requires broad write access. | |

**Decision basis:** GitHub issue forms improve intake but turn answers into editable Markdown and do not control all issue/PR activity. Start with bounded forms, compact labels, and explicit maintainer decisions. Never infer unknown ownership from text.

## Isolated worktree lifecycle (OPS-03)

| Option | Tradeoffs | Selected |
|--------|-----------|----------|
| Manifest-bound local lifecycle with clean-entry/exit evidence and fail-closed isolation | Supports task ownership and safe handoff; adds manifest and recovery paths; must not silently degrade to shared checkout. | ✓ |
| CI-only fresh worktrees | Strong exact-SHA build/test repeatability; says nothing about safety or ownership of local dirty/locked work. | |
| Manual documented lifecycle only | Lowest implementation cost; depends on people remembering checks and conflicts with shift-left direction as the default path. | |

**Decision basis:** Git offers machine-readable inventory, but removal/unlock/prune are state-changing. Automate scoped observation and proof; never force-remove dirty, locked, stale, or unknown work. Preserve the current local setting and existing work.

## Dependency update flow (OPS-04)

| Option | Tradeoffs | Selected |
|--------|-----------|----------|
| Dependabot for Mix and Actions; separate root/demo boundaries; group routine compatible updates; majors individually reviewed | Native to GitHub and low service burden. Group rules need careful order and broad groups can hide causality. | ✓ |
| Renovate | More package rules and cross-repository policy flexibility; adds service/onboarding/config overhead that current scale does not justify. | |
| Manual discovery only | Familiar Mix workflow, useful for intentional major upgrades; misses routine updates and advisories if used as the only discovery path. | |

**Decision basis:** Dependabot supports Mix production/development and update-type grouping; separate security-update rules have their own configuration and precedence. Preserve exact-SHA CI and Hex audit as acceptance, never auto-merge. Root SDK and demo have separate compatibility surfaces.

## Research lenses and evidence

- Four specialist research threads covered contributor guidance, issue/PR triage, worktree safety, and dependency grouping. Their findings were synthesized against OPS-01–04, Phase 31/32/34 decisions, the architecture research, project preferences, and the current brandbook/prompt files.
- Current official references reviewed: Git worktree documentation; GitHub issue-form syntax; Dependabot options and grouped security updates; Elixir and Phoenix contribution guides; Mix dependency update and Hex audit documentation.
- No application UI/graphic-design decision applies. Contributor UX is handled through clear copy, low-friction forms, predictable labels, accessibility of GitHub's standard controls, and concise success/failure diagnostics.

## the agent's Discretion

- Use the smallest effective template and label vocabulary; select concrete automation placement after source mapping.
- Tune cadence and update grouping to observed dependency/CI costs without relaxing security or exact-SHA acceptance.

## Deferred Ideas

- GitHub Project: revisit only if issue volume or multiple-maintainer coordination warrants structured hosted fields.
- Renovate: revisit only if cross-repository or broader package-policy complexity exceeds Dependabot's maintenance-light approach.
