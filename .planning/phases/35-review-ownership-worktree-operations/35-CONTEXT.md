# Phase 35: Review, Ownership & Worktree Operations - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make one bounded repository change move through clear contribution guidance, explicit issue/PR disposition, safely isolated work, and reviewable dependency updates. This phase changes repository collaboration and GSD operational practices; it does not add SDK or Phoenix runtime features. Repeatable proof should run automatically at the earliest useful boundary when its recurring confidence justifies its runtime and upkeep. Human judgment remains for real ownership/scope decisions and external state that cannot be proven automatically.

</domain>

<decisions>
## Implementation Decisions

### Contributor guidance and review evidence (OPS-01)
- **D-01:** Use a concise root `CONTRIBUTING.md`, a small number of GitHub issue forms, a pull request template, and `SECURITY.md`. Keep each instruction focused on the contributor's job: report a reproducible problem or bounded change, show proportionate proof, and know where to report a vulnerability privately. Do not introduce an application UI or expose internal implementation detail without a user need.
- **D-02:** The PR template asks for one intent, scope/non-goals, relevant risk and compatibility impact, and the proof actually run, including the exact-SHA CI result when available. Keep evidence proportional: routine documentation changes should not face the same burden as transport, security, or dependency changes.
- **D-03:** Document private security reporting only through a verified private channel supported by repository settings. Do not invent a security email, promise an unconfigured GitHub feature, or direct vulnerability reports to public issues.
- **D-04:** Add CODEOWNERS routes only for verified people/teams and paths. Unknown ownership remains visibly unknown until evidence identifies an owner; templates and code-owner routing do not substitute for review.

### Issue and PR disposition (OPS-02)
- **D-05:** Start with versioned GitHub issue forms/templates, a concise PR template, and a compact label vocabulary. Keep item kind (bug, proposal, dependency, etc.) separate from workflow state. Each open item must expose a controlled state, an owner or explicit `unknown`, a scope decision, and a concrete next action; a `needs-info` state includes what information is needed and who/when should follow up.
- **D-06:** Preserve maintainer decisions in a readable, dated triage record associated with the issue/PR. Add a deterministic, read-only completeness audit that reports missing or contradictory dispositions. Forms and labels are useful intake cues, not authoritative or immutable data: contributors can edit form-created issue text and labels can drift.
- **D-07:** Do not infer ownership or scope from free text, auto-assign based on guesses, or auto-close items. Keep scope and ownership judgment with a maintainer. Defer a GitHub Project until actual item volume or multiple-maintainer coordination demonstrates value; it otherwise adds a second, hosted metadata plane that can drift. Safe deterministic reporting or item-linking may be automated if it has a clear proof and least-privilege boundary.

### Isolated worktree lifecycle (OPS-03)
- **D-08:** Prefer a manifest-bound task lifecycle when supported: bind the task/run to its worktree path, branch, base SHA, and owner; record clean-entry evidence; and capture exit status, diff, validation, and intended disposition before merge/removal. Fail closed if the host cannot establish the requested isolation. Do not silently fall back to a shared checkout and call it isolated.
- **D-09:** Automate bounded inventory and evidence collection; never automatically remove, unlock, force-reset, or prune a dirty, locked, stale, unreadable, or unknown worktree. Preserve unknown work and report facts separately from proposed disposition. Cleanup remains explicit and scoped to a validated task manifest. A fresh CI checkout proves CI's exact-SHA code state, not that a developer's local worktree is safe to delete.
- **D-10:** Keep the current local worktree setting and existing dirty/locked work untouched during this phase's planning. Any later enablement of worktree-per-task must be justified by a supported GSD lifecycle and safe-entry checks; do not turn a project preference into a destructive cleanup authorization.

### Dependency update flow (OPS-04)
- **D-11:** Prefer Dependabot for Mix and GitHub Actions discovery because it is native to the existing GitHub/CI surface and adds less service/configuration overhead than Renovate for this repository's current scale. Keep the root SDK and Phoenix/Ecto demo as separate update boundaries because they have separate lockfiles and different compatibility responsibilities.
- **D-12:** Group routine compatible patch/minor updates within those boundaries to reduce review noise while keeping the diff attributable. Keep major upgrades individually reviewable. Keep security updates prompt and distinct from the routine cadence; group only within a boundary where the combined change remains diagnosable. Configure Mix production/development group rules only where they correctly represent dependencies; Mix's categories do not encode every SDK-specific optional integration.
- **D-13:** Updates are proposals, never auto-merged. They must pass the same exact-SHA `CI contract`, including the relevant SDK, optional-dependency, package-smoke, demo/downstream, and security checks for the files changed. Mix/Hex audit remains the security evidence for Hex packages; a green result is claimed only for the checks actually run. Renovate remains a future option if a multi-repository or broader ecosystem policy makes its extra flexibility worthwhile.

### the agent's Discretion
- Choose the smallest file/template set and label names that satisfy OPS-01/02 without duplicating GitHub metadata.
- Choose the manifest schema and deterministic validation placement after mapping existing repository and GSD patterns.
- Tune routine update cadence and group membership from current dependency volume and CI cost, preserving the boundary, security, and exact-SHA rules above.
- There is no app UI in this phase. Apply the Oarlock voice to contributor-facing docs and templates: calm, direct, precise, developer-native, and clear about the SDK's independence from Paddle.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and project policy
- `.planning/ROADMAP.md` — Phase 35 boundary, OPS-01–04, success criteria, and phase dependencies.
- `.planning/REQUIREMENTS.md` — committed requirements and evidence expectations for OPS-01–04.
- `.planning/PROJECT.md` — project goals, consumers, and SDK boundaries.
- `.planning/GSD-PREFERENCES.md` — automation-first verification, runtime/value tradeoffs, preservation, and handoff defaults.
- `.planning/RESEARCH/ARCHITECTURE.md` — repository lifecycle plane, collaboration surfaces, worktree flow, proof boundaries, and operational patterns.
- `.planning/phases/31-repository-planning-truth/31-CONTEXT.md` — evidence-backed ownership, unknown preservation, repository truth, and destructive-operation constraints.
- `.planning/phases/32-dependency-sdk-trust-boundary/32-CONTEXT.md` — dependency isolation, compatibility proof, optional integration, and security decisions.
- `.planning/phases/34-release-integrity/34-CONTEXT.md` — exact-SHA release/CI evidence and security boundary.

### Existing implementation and product voice
- `.github/workflows/ci.yml` — existing aggregate CI contract and validations that dependency updates must use.
- `scripts/repository_inventory.cjs` and `scripts/lib/repository_truth.cjs` — reusable inventory and conservative classification patterns.
- `prompts/oarlock-milestone-roadmap-ratchet.txt` — current milestone-wide operating, proof, and shift-left direction.
- `prompts/oarlock-brand-book.md` — current available brand voice and user-facing writing guidance; no newer brandbook was found.

### Ecosystem references
- [Git worktree documentation](https://git-scm.com/docs/git-worktree) — worktree inventory, locks, safe removal, and pruning.
- [GitHub issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms) — form capabilities and their editable Markdown output.
- [Dependabot options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) and [security update grouping](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates) — Mix grouping limits, rule order, and update/security separation.
- [Elixir contribution guide](https://github.com/elixir-lang/elixir/blob/main/CONTRIBUTING.md) and [Phoenix contribution guide](https://github.com/phoenixframework/phoenix/blob/main/CONTRIBUTING.md) — ecosystem examples for issue quality, scoped contributions, and contributor orientation.
- [Mix dependency update task](https://mix.hexdocs.pm/Mix.Tasks.Deps.Update.html) and [Hex audit task](https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html) — native dependency workflow and advisory checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/repository_inventory.cjs` and `scripts/lib/repository_truth.cjs`: existing repository inventory, evidence, and conservative unknown-state patterns to inspect before adding lifecycle checks.
- `.github/workflows/ci.yml`: the stable aggregate `CI contract` and existing security/compatibility jobs; dependency updates should reuse this proof instead of creating a second definition of green.
- Root and `demo/` Mix projects: separate dependency/lockfile boundaries, so routine SDK updates must not be conflated with Phoenix/Ecto demo changes.

### Established Patterns
- Phase 31 records observed facts separately from ownership dispositions; unknown is not guessed and destructive cleanup is never inferred from stale metadata.
- Phase 32 treats lock resolution, compatibility, and online security audit as separate evidence classes.
- Phase 34 accepts publication only on exact-SHA CI and package identity evidence.
- Planning preferences favor repeatable, high-signal CI checks when recurring risk reduction pays for their runtime; human UAT is reserved for irreducibly subjective or external state.

### Integration Points
- GitHub collaboration files under `.github/` and root contributor/security documentation.
- Existing CI aggregate and its compatibility, package, demo, and Hex security checks.
- GSD task/worktree lifecycle and repository inventory scripts; current `.planning/config.json` has `workflow.use_worktrees: false`, and existing dirty/locked work must remain untouched while any lifecycle behavior is established.
</code_context>

<specifics>
## Specific Ideas

- Use the smallest conventional GitHub affordances (forms, templates, clear labels, concise contributor docs); there is no product UI or application design system to create here.
- Learn from Elixir/Phoenix contribution guidance and GitHub/Dependabot conventions, but tailor evidence to a pure Elixir SDK with an optional Plug/Bandit edge and a separate Phoenix/Ecto demo.
- Present clean-entry/exit and CI proof as distinct guarantees. Contributor-facing language should explain the action and evidence plainly rather than expose internal workflow machinery.
- Current official documentation confirms GitHub issue-form responses become editable Markdown; Dependabot Mix grouping supports production/development and SemVer rules but first-match order matters; Git worktree removal requires a clean worktree and locks prevent pruning. Preserve these footguns in implementation tests and docs.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 35. A GitHub Project or Renovate may be revisited only if actual collaboration volume or multi-repository needs justify their additional metadata/service overhead.
</deferred>

---

*Phase: 35-Review, Ownership & Worktree Operations*
*Context gathered: 2026-09-25*
