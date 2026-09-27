---
id: SEED-001
status: dormant
planted: 2026-09-26
planted_during: v2.2 / Phase 35 — Review, Ownership & Worktree Operations
trigger_when: During planning of the first milestone after v2.2 closes; promote if README, adopter onboarding, or public documentation is in scope. Otherwise resurface when one of those areas becomes in scope.
scope: unknown
---

# SEED-001: Make the README a calm, reader-first introduction to Oarlock

## Why This Matters

The README is often a developer's first encounter with Oarlock. It should help each reader quickly decide whether the SDK fits, understand the job it helps with, and take the next useful step without wading through repeated, overly dense, or generic-sounding prose. A clearer first read respects readers' time, energy, and attention while making Oarlock's provider-native character and boundaries easier to remember.

## When to Surface

**Trigger:** During planning of the first milestone after v2.2 closes. Include this seed if README, adopter onboarding, or public documentation is a candidate; otherwise keep it dormant until one of those areas is in scope.

This seed will surface during `$gsd-new-milestone` when the milestone scope matches.

## Scope Estimate

**Unknown** — estimate during milestone planning after reviewing the current README, prior documentation decisions, current brand guidance, and the reference project's README. Keep implementation bounded to the README unless discovery justifies related edits.

## Breadcrumbs

- `README.md` — current first-read structure and copy.
- `prompts/oarlock-brand-book.md` — Oarlock voice, positioning, and writing guidance (v0.1, dated 2026-04-28 at capture time); check for a newer brand book before drafting and follow the newest one.
- `.planning/milestones/v2.1-phases/27-public-contract-documentation-truth/27-CONTEXT.md` — existing JTBD-first, link-driven README decisions and documentation boundaries.
- `.planning/milestones/v2.1-phases/27-public-contract-documentation-truth/27-02-SUMMARY.md` — previous README work and lessons; preserve accurate proof boundaries and avoid repeating the earlier truth-alignment pass.
- `lattice_stripe` sibling project's README — maintainer-provided reference, inspected on 2026-09-26; re-read the current version during planning rather than storing a machine-specific path here. It gives readers an early fit/scope signal, routes by intent, and then offers install and a runnable first step. Its useful navigational intent is offset by overlapping route lists, documentation ladders, and feature inventories; keep Oarlock's version shorter and remove repeated link maps. Extract principles, never its product scope or copy.

## Notes

At planning time, shape the README around its readers' jobs: understand what Oarlock is and whether it fits; install it and reach a useful first integration step; find task-specific guidance; and see app-owned responsibilities and proof limits. Carry forward Phase 27's JTBD-first, link-driven approach and accurate proof boundaries; do not repeat its public API truth-alignment pass unless current drift makes that necessary. Use direct plain language, concrete headings, short sections, generous whitespace, and a natural editorial rhythm in the spirit of UK government service writing. Keep the Oarlock brand calm, exact, honest, and developer-native. Remove generic or repetitive prose while retaining technically necessary caveats and links to deeper contracts. Review the newest brand-book guidance first. This is a writing and information-design seed, not a request to change the README during Phase 35.
