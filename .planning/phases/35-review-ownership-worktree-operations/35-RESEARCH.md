# Phase 35: Review, Ownership & Worktree Operations - Research

**Researched:** 2026-09-25 America/New_York (hosted settings read back 2026-09-26 02:01 UTC, the same session as 2026-09-25 22:01 EDT)
**Domain:** GitHub collaboration, local Git worktree lifecycle, Elixir dependency maintenance
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 35. A GitHub Project or Renovate may be revisited only if actual collaboration volume or multi-repository needs justify their additional metadata/service overhead.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Contributor receives concise contribution, security-reporting, ownership, issue, and PR guidance that requires one bounded intent and proportional evidence. | GitHub issue forms and PR template affordances; CODEOWNERS access/validity constraints; verified private-reporting state; proportional proof mapped to the current CI contract. `[VERIFIED: .planning/REQUIREMENTS.md:68]` Quote: "**OPS-01**: Contributor receives concise contribution, security-reporting, ownership, issue, and PR guidance that requires one bounded intent and proportional evidence." |
| OPS-02 | Maintainer can disposition every existing or new issue and PR with a controlled triage state, owner, scope decision, and next action. | Editable form bodies and mutable labels require a separate dated maintainer-authored record plus read-only completeness audit; one open PR was observed in GitHub at research time. `[VERIFIED: .planning/REQUIREMENTS.md:69]` Quote: "**OPS-02**: Maintainer can disposition every existing or new issue and PR with a controlled triage state, owner, scope decision, and next action." |
| OPS-03 | Each task can use an isolated worktree with clean-entry and clean-exit checks; dirty, locked, stale, or unknown work is reported and never deleted automatically. | Git's stable porcelain inventory, status checks, task manifest, and manual-only cleanup gate; keep project setting unchanged until supported GSD lifecycle exists. `[VERIFIED: .planning/REQUIREMENTS.md:70]` Quote: "**OPS-03**: Each task can use an isolated worktree with clean-entry and clean-exit checks; dirty, locked, stale, or unknown work is reported and never deleted automatically." |
| OPS-04 | Dependency updates arrive as grouped, reviewable PRs that run the same compatibility and security contract as other changes. | Dependabot supports Mix and GitHub Actions grouping; preserve independent root/demo lockfile boundaries and route candidates through exact-SHA CI contract and Hex audit. `[VERIFIED: .planning/REQUIREMENTS.md:71]` Quote: "**OPS-04**: Dependency updates arrive as grouped, reviewable PRs that run the same compatibility and security contract as other changes." |
</phase_requirements>

## Summary

Use the repository's existing operational patterns: GitHub's versioned issue forms and PR template, a dated maintainer-owned triage record plus deterministic read-only audit, and the current Node-based repository tooling style for worktree checks. Keep fact gathering separate from disposition, and keep every unknown owner or worktree visible until a human resolves it. Git's porcelain worktree listing supports robust inventory; ordinary removal already refuses unclean trees, but forced removal and lock bypass remain explicitly out of automation. `[CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]` `[CITED: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners]` `[CITED: https://git-scm.com/docs/git-worktree]`

No collaboration or update configuration exists in the repository yet. At the dated hosted readback below, private vulnerability reporting was disabled, and GitHub listed one open PR and no open issues. These hosted observations can change and must be read again during execution before a settings mutation or final documentation claim. The current `.planning/config.json` has worktree mode disabled, and a linked locked worktree was visible during research; preserve both facts and require explicit evidence-backed dispositions rather than cleanup. `[VERIFIED: .planning/config.json:11]` Quote: `"use_worktrees": false`

### Hosted observation snapshot

The planning orchestrator supplied read-only GitHub observations collected on 2026-09-26 at approximately 02:01 UTC, which was 2026-09-25 at approximately 22:01 EDT (America/New_York). They are point-in-time evidence, not proof of execution-time state or authorization for an external write.

| Read-only observation | Result at that time |
|-----------------------|---------------------|
| `GET /repos/szTheory/oarlock/private-vulnerability-reporting` | `enabled:false` |
| Repository permissions readback | `admin:true`, `maintain:true`, `pull:true`, `push:true`, `triage:true` |
| `GET /repos/szTheory/oarlock/automated-security-fixes` | `enabled:false` |
| `GET /repos/szTheory/oarlock/vulnerability-alerts` | HTTP 404, “Vulnerability alerts are disabled.” |
| `gh issue list` | 0 open issues |
| `gh pr list` | 1 open PR |

The observed `admin:true` is a repository permission snapshot; any setting change still requires execution-time permission verification and a fresh GET/readback of the target setting. A successful mutation must be followed by a new GET before SECURITY.md or dependency guidance claims that the feature is enabled.

For dependency automation, use Dependabot's `mix` and `github-actions` ecosystems, keep SDK and demo manifests separate, and group routine patch/minor changes only within each compatibility boundary. Security updates stay prompt and distinct; major updates remain individually reviewable. Every proposed update continues to use the current exact-SHA `CI contract` and relevant existing checks, including `mix hex.audit`; there is no need to install a new package or establish a second definition of green. `[CITED: https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference]` `[CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates]` `[VERIFIED: .github/workflows/ci.yml:392-405]` Quote: `- name: Audit Hex advisories`, `run: mix hex.audit`, and the aggregate job `name: CI contract`.

**Primary recommendation:** Plan a small documentation/configuration slice, a deterministic triage audit, and a manifest-bound read-only worktree gate; leave actual cleanup and maintainer scope/ownership decisions human-owned. Keep `workflow.use_worktrees` false unless implementation first proves a supported GSD lifecycle that satisfies clean-entry, manifest binding, and fail-closed behavior.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Contribution, security, issue, PR guidance | Repository / GitHub | Maintainer | Files guide contributors; private reporting and team ownership depend on verified repository settings. |
| Issue/PR triage completeness | Maintainer / GitHub | Local Node tooling | Maintainer owns scope and owner; deterministic tooling can report missing or contradictory fields without assigning or closing. |
| Worktree entry/exit and inventory | Local Git / GSD host | CI | Local worktree cleanliness and ownership are local runtime state; CI can only attest its own exact-SHA checkout. |
| Dependency proposals and compatibility proof | GitHub Dependabot / CI | Maintainer | Dependabot proposes updates; aggregate CI validates exact candidate SHA; maintainers review and merge. |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Git worktree CLI | Installed 2.41.0; current upstream docs | Isolated trees and machine-readable inventory | Repository already uses Git directly and has a tested repository inventory pattern. `[VERIFIED: local git --version]` `[CITED: https://git-scm.com/docs/git-worktree]` |
| GitHub issue forms, PR templates, CODEOWNERS | GitHub-hosted; no repo config present | Intake, review context, routing | Native repository collaboration features; forms remain editable, and ownership routes require verified write access. `[CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]` |
| GitHub Dependabot | GitHub-hosted; no repo config present | Mix and Actions dependency proposals | Already selected by locked decision; supports these ecosystems and grouping controls. `[CITED: https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference]` |
| Node.js built-in test runner | Local Node v22.14.0; repo CI Node setup | Tests for audit/config/worktree contracts | Existing operational scripts and tests use `.cjs` and `node --test`; no additional package is needed. `[VERIFIED: local node --version]` `[VERIFIED: .github/workflows/ci.yml:350]` Quote: `run: node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`. |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GitHub CLI (`gh`) | Local 2.101.0 | Read-only retrieval of all open issues/PRs for triage audit | Use only read scopes; paginate/verify complete retrieval; no mutation commands in the audit. `[VERIFIED: local gh --version]` |
| Mix / Hex | Local Mix 1.19.5; Hex in CI | Dependency updates, lock resolution and advisory audit | Keep `mix deps.update` changes reviewable, then run the existing compatibility/security contract. `mix hex.audit` reports retired packages/advisories and fails when findings remain. `[VERIFIED: local mix --version]` `[CITED: https://mix.hexdocs.pm/Mix.Tasks.Deps.Update.html]` `[CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dependabot | Renovate | Deferred by locked decision; reconsider only if multi-repo or wider ecosystem policy justifies added service/configuration overhead. |
| Human-only triage inspection | Read-only deterministic completeness audit | The audit catches omissions and contradictions consistently, while leaving owner/scope judgments with maintainers. |

**Installation:** No new external package installation is recommended. GitHub features and Node/Mix tools are already part of the repository environment. Package legitimacy audit is not applicable because this phase adds no package dependency.

## Architecture Patterns

### System Architecture Diagram

```text
Contributor intent
  → issue form / PR template / security policy
  → maintainer records dated disposition (state, owner, scope, next action)
  → read-only audit reports missing / contradictory records
  → bounded task manifest binds owner + branch + base SHA + worktree path
  → clean-entry gate → implementation + proportionate local proof
  → exact-SHA CI contract + relevant security/compatibility jobs
  → maintainer review and explicit merge/close/retain decision
  → clean-exit evidence → explicit cleanup only for validated manifest

Dependabot schedule → grouped proposal within one lockfile boundary → same CI contract
```

### Recommended Project Structure

```text
CONTRIBUTING.md                     # concise scoped-change and evidence guidance
SECURITY.md                         # verified private reporting channel only
.github/
├── ISSUE_TEMPLATE/                 # small versioned intake forms + chooser config
├── pull_request_template.md         # one intent, risks, proof, exact-SHA link
├── CODEOWNERS                      # verified paths and verified owners only
└── dependabot.yml                  # Mix root/demo and GitHub Actions update boundaries
.planning/
└── repository-ownership.json       # only if existing ownership registry can extend cleanly
scripts/
├── <read-only-triage-audit>.cjs    # incomplete/contradictory issue and PR records
└── <worktree-gate>.cjs             # manifest validation and read-only entry/exit evidence
```

These script and registry names are proposed placeholders; implementation should map the exact placement onto `scripts/repository_inventory.cjs`, `scripts/lib/repository_truth.cjs`, and current ownership evidence before adding a second registry. `[VERIFIED: scripts/repository_inventory.cjs:1-20]` `[VERIFIED: scripts/lib/repository_truth.cjs:1-25]`

### Pattern 1: Triage record as the decision source

**What:** Keep issue kind labels separate from workflow state. Add a dated maintainer-authored record associated with each issue/PR containing controlled state, owner or explicit unknown, scope decision, and concrete next action. For `needs-info`, record the missing information plus a named follow-up owner and date. A read-only audit consumes complete issue/PR data and reports omissions/contradictions; it does not infer values from the title, form text, labels, or author.

**When to use:** Every currently open and newly opened issue or PR.

**Example:**

```oarlock-triage
Date: YYYY-MM-DD
State: needs-triage|needs-info|ready|in-progress|blocked
Owner: USER|unknown
Scope: in-scope|deferred|out-of-scope
Next action: TEXT
Action owner: USER
Review by: YYYY-MM-DD
```

The `needs-info` state also requires `Information needed: TEXT`. The exact controlled state, scope vocabulary, and maintainer-comment format are fixed in Resolved Planning Questions below and Plan 35-03; validate them in the audit rather than treating labels as authoritative. GitHub issue-form replies are editable Markdown, so the record must remain distinguishable as a maintainer decision. `[CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]`

### Pattern 2: Fail-closed worktree evidence gates

**What:** Bind a task/run to a validated manifest containing worktree path, branch, base SHA, owner, and entry status evidence. Gather status and registry state with bounded, NUL-safe commands; on exit capture exit status, diff summary, validation evidence, and intended disposition. Facts are emitted separately from proposed disposition. If host support, manifest, status, or owner evidence is absent/ambiguous, report unknown/incomplete and stop; do not claim isolation or invoke destructive cleanup.

**When to use:** Starting or concluding a task in a dedicated worktree and when the operator requests a worktree inventory.

**Example:**

```sh
git worktree list --porcelain -z
git -C "$TASK_WORKTREE" status --porcelain=v2 --branch -z
git worktree prune --dry-run --verbose
```

The final command is a dry run only. Do not automate `remove`, `unlock`, `reset`, force flags, or non-dry-run `prune`; route any cleanup as a separately reviewed operator decision after manifest identity, ownership, locks, status, and intended disposition are revalidated. `[CITED: https://git-scm.com/docs/git-worktree]`

### Pattern 3: Dependency PRs remain proposals

**What:** Add Dependabot entries for the root Mix project, demo Mix project, and GitHub Actions. Group patch/minor updates only within each root/demo dependency boundary; keep majors and any security-sensitive combined group separately reviewable. Mix production/development groups are only valid where they match Mix dependency classifications. Do not auto-merge. The existing aggregate CI contract is the only green authority; file changes determine which checks apply, and Hex security evidence remains `mix hex.audit`.

**When to use:** Routine compatible update discovery and prompt security update proposals.

**Example:**

```yaml
version: 2
updates:
  - package-ecosystem: "mix"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      compatible:
        update-types: ["minor", "patch"]
  - package-ecosystem: "mix"
    directory: "/demo"
    schedule:
      interval: "weekly"
    groups:
      compatible:
        update-types: ["minor", "patch"]
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

This is a shape example, not a final cadence decision; security `groups` need their own `applies-to: security-updates` rules, and the order of rules matters because the first match owns an update. `[CITED: https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference]` `[CITED: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates]`

### Anti-Patterns to Avoid

- **Treating forms or labels as triage authority:** issue form output is editable and labels drift; read a separate maintainer-authored dated disposition.
- **Guessing scope or ownership from issue prose, paths, or CODEOWNERS:** report unknown and request a human disposition.
- **Making CODEOWNERS claims for unverified accounts/teams or broad paths:** GitHub skips invalid lines and teams need explicit repository write permission.
- **Treating hosted CI checkout cleanliness as local cleanup evidence:** CI only describes its own exact-SHA checkout.
- **Removing, unlocking, force-resetting, or pruning dirty/locked/stale/unreadable/unknown worktrees:** preserve evidence, report facts, and require explicit scoped human disposition.
- **Auto-merging dependency PRs or bundling distinct root/demo compatibility contexts:** every update remains a proposal with the exact-SHA contract.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|---------|-----|
| Git worktree inventory parsing | Human-format `git worktree list` parsing or newline splitting | `git worktree list --porcelain -z` | Porcelain is stable for scripts, and NUL separators support unusual path characters. |
| Worktree deletion safety | A custom automatic cleanup rule or force-removal fallback | Git's clean removal guard plus report-only checks; explicit cleanup after validated manifest | Git's force option bypasses normal clean-state protection; lock state must remain human-owned. |
| Issue/PR field collection | Custom public application UI or duplicate hosted project board | GitHub issue forms, PR templates, and dated triage records | Native affordances keep the collaboration surface small; forms are intake only. |
| Hex security advisory audit | Custom advisory scraper or package audit package | Existing `mix hex.audit` in CI | Native Hex task provides retired-package/advisory findings and non-zero failure. |

**Key insight:** The difficult part is not collecting status; it is preserving the authority boundary between observed state, maintainer judgment, and destructive action. Reuse native Git safety checks, repository inventory patterns, GitHub collaboration features, and the existing CI aggregate instead of creating shadow metadata or a second green definition.

## Common Pitfalls

### Pitfall 1: Editable issue intake appears complete but later changes

**What goes wrong:** The audit treats form-created markdown or labels as final disposition and fails to catch missing owner/scope/action.
**Why it happens:** GitHub converts form replies to editable issue markdown; labels are mutable.
**How to avoid:** Require a dated maintainer record as the decision source; audit required fields and contradictory records read-only.
**Warning signs:** State exists only as a label; a contributor edit removes a required section; the same item shows incompatible current fields.

### Pitfall 2: Private vulnerability reporting is promised while disabled

**What goes wrong:** Vulnerability reporters follow `SECURITY.md` to a public issue or a private route that is not enabled.
**Why it happens:** `SECURITY.md` presence does not enable GitHub's private reporting feature.
**How to avoid:** The 2026-09-26 02:01 UTC GitHub API readback returned `{"enabled":false}` for private vulnerability reporting. Recheck at execution time and configure/verify a private route before documenting it; otherwise make the planning gate explicit and do not publish a fictional contact.
**Warning signs:** Docs use “Report a vulnerability” without confirming the Security Advisories control or other verified private path.

### Pitfall 3: Worktree path exists but is dirty, locked, or not the task's tree

**What goes wrong:** Entry reuses a different branch/base, or exit cleanup removes another task's state.
**Why it happens:** Path and directory presence do not bind a tree to a task; newline paths can break naive parsing; lock reason may not identify ownership.
**How to avoid:** Verify path, branch, base SHA, owner, lock/prunable fields, and status against the task manifest at both boundaries. Unknown evidence blocks isolation/cleanup.
**Warning signs:** Human-format parsing; an absent manifest; status cannot be read; any force flag appears in automated code.

### Pitfall 4: Dependabot configuration accidentally erases update separation

**What goes wrong:** A root update is grouped with demo state, production/development labels do not match Mix categories, or routine and security changes enter one unreviewable PR.
**Why it happens:** Group matching order and `applies-to` scope are easy to misconfigure; group rules are per ecosystem and security groups are separate.
**How to avoid:** Keep separate `mix` entries for `/` and `/demo`; use group-by-type only if the Mix dependency type represents this SDK's needs; define routine and security groups separately and test the YAML/config contract.
**Warning signs:** Both lockfiles change in one routine PR; a required security group lacks `applies-to: security-updates`; major updates join routine patch/minor groups.

### Pitfall 5: Green local tests substitute for hosted exact-SHA proof

**What goes wrong:** A dependency PR merges with only local tests or a subset of CI.
**Why it happens:** Local proof does not show the hosted aggregate ran against the proposed SHA, and `mix hex.audit` alone does not show compatibility.
**How to avoid:** Require the existing `CI contract` for the PR's exact candidate SHA; read the linked hosted proof and retain only claims supported by jobs actually run.
**Warning signs:** PR checklist has “tests pass” without exact SHA/run evidence or says “green” after only selected checks.

## Code Examples

### Read-only issue/PR completeness check shape

```text
for each open issue and PR returned by a complete, read-only GitHub query:
  parse maintainer-authored triage records
  report missing: state / owner / scope / next action
  report contradictions between active records
  never fill gaps, assign owners, change labels, or close items
```

Use the project’s existing Node `.cjs` scripts and `node --test` fixture pattern. Do not put auth tokens in source, command output, or diagnostics; limit GitHub access to read-only issue/PR fields and paginate until the result is complete. `[VERIFIED: scripts/repository_inventory.cjs:1-20]` `[CITED: https://docs.github.com/en/rest/issues/issues]`

### Worktree entry and exit proof shape

```sh
# First verify that the requested task manifest matches this exact tree.
git worktree list --porcelain -z
git -C "$TASK_WORKTREE" status --porcelain=v2 --branch -z
git -C "$TASK_WORKTREE" rev-parse --verify HEAD

# At exit, store status/diff/proof in the task record; never delete on this path.
git -C "$TASK_WORKTREE" status --porcelain=v2 --branch -z
git -C "$TASK_WORKTREE" diff --stat
```

Run commands without shell interpolation of manifest-controlled arguments (pass argument arrays from Node `spawnSync`, as `repository_truth.cjs` does). Use bounded buffers, timeout, optional locks disabled for read-only Git inspection, explicit error reporting, and separate proposed disposition from observed facts. `[VERIFIED: scripts/lib/repository_truth.cjs:1-72]` `[CITED: https://git-scm.com/docs/git-worktree]`

### Dependabot and Mix audit

```sh
mix deps.update req
mix hex.audit
```

The named update can still update required transitive dependencies; broad `--all` updates should be reserved for an explicitly bounded update proposal. Then require the repo's aggregate exact-SHA CI contract rather than accepting these two local commands as merge proof. `[CITED: https://mix.hexdocs.pm/Mix.Tasks.Deps.Update.html]` `[CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plain human-formatted worktree list parsing | Stable `--porcelain -z` machine output | Current Git documentation | Robust handling for unusual paths; parse structured facts rather than display text. |
| Issue templates/labels treated as final ownership | Editable intake plus explicit dated maintainer disposition | GitHub issue forms documentation | Audit durable decisions rather than assuming intake metadata is immutable. |
| One broad routine dependency batch | Scoped groups per ecosystem/directory with separate security rules | Current Dependabot configuration docs | Root SDK and demo remain independent; security updates can be timely without losing diagnosis. |
| Local green as merge evidence | CI aggregate bound to candidate SHA | Existing Phase 33/34 decisions and repo CI | Require hosted `CI contract` evidence for the exact PR revision. |

**Deprecated/outdated:** Do not use GitHub Projects as a second source of truth at this phase's current scale; defer pending evidence of volume/multi-maintainer coordination. Do not treat forms or CODEOWNERS as immutable disposition or proof.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Resolved in Phase 35 planning: Plans 35-02 and 35-03 fix the state/scope vocabulary and authoritative maintainer-comment format per D-05/D-06. | Pattern 1 / Resolved Planning Questions | Audit and label/template definitions must use the same fixed values. |
| A2 | A scheduled read-only GitHub CLI/API query with `issues:read` and `pull_requests:read` access is sufficient to enumerate all current open issues and PRs for an audit. | Code Examples | Missing pagination, access-limited records, or unsupported pull-request query semantics could yield false completeness. |
| A3 | Dependabot's weekly cadence is a starting shape, not an approved routine cadence; final cadence should follow current dependency volume and CI cost. | Pattern 3 | Too frequent schedules can create review noise; too slow a schedule delays compatible updates. |
| A4 | Resolved channel choice per D-03: Plan 35-02 uses GitHub private vulnerability reporting only after execution-time authorization and `enabled:true` readback. | Summary / Resolved Planning Questions | Without that readback, contributor security-reporting guidance cannot truthfully name the channel. |

## Resolved Planning Questions

1. **Private vulnerability channel (D-03):** Plan 35-02 adopts GitHub private vulnerability reporting as the channel, conditional on a fresh repository-setting GET, authorized enablement if still disabled, and a confirming `enabled:true` GET before SECURITY.md or the issue chooser names it. The dated disabled readback above remains an execution-time gate, not an unresolved channel choice. This follows the Phase 35 CONTEXT.md D-03 requirement for a verified private route.
2. **Triage vocabulary and record (D-05, D-06, D-07):** Plans 35-02 and 35-03 adopt separate `kind:*` and `state:*` labels, controlled states `needs-triage|needs-info|ready|in-progress|blocked`, scope values `in-scope|deferred|out-of-scope`, and a dated maintainer-authored `oarlock-triage` issue comment with owner or `unknown`, next action, action owner, and review date. The read-only audit treats the comment as authoritative and requires extra follow-up detail for `needs-info`, as required by Phase 35 CONTEXT.md D-05 through D-07.
3. **Worktree preference (D-08, D-09, D-10):** Plan 35-01 keeps `.planning/config.json` at `workflow.use_worktrees: false` and delivers manifest-bound entry/exit evidence for explicitly provisioned dedicated worktrees. Any later preference change requires demonstrated GSD host lifecycle support and safe entry checks; uncertain or locked work remains untouched. This is the Phase 35 CONTEXT.md D-08 through D-10 decision, with host capability retained as a verification gate.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Git | Worktree inventory and lifecycle | ✓ | 2.41.0 | None; installation/runtime requirement. |
| Node.js | Repository scripts and deterministic audits | ✓ | 22.14.0 | None; CI Node setup supplies hosted version. |
| Mix/Elixir | Root and demo dependency/compatibility checks | ✓ | Mix 1.19.5 / Elixir 1.19.5; OTP 28 | None for Mix-specific proof. |
| GitHub CLI | Live read-only open issue/PR collection | ✓ | 2.101.0 | GitHub REST API with read-only token and complete pagination. |
| GitHub private vulnerability reporting | Private security-report channel | ✗ at dated readback; reverify | `enabled:false` on 2026-09-26 02:01 UTC | Enable in repo settings or verify an alternative private route before publishing guidance. |
| GitHub Dependabot | Dependency update proposals | Available as repository service, not configured | — | No equivalent preferred under locked decision; configure native Dependabot. |

**Missing dependencies with no fallback:** None for local implementation/testing. Private security reporting has no verified fallback yet and blocks final SECURITY.md channel wording until a maintainer enables/configures one.

**Missing dependencies with fallback:** Private GitHub reporting disabled can be addressed by a verified alternate private channel, if one exists; none was discovered during this research.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Elixir ExUnit in root and demo; Node.js built-in test runner for scripts |
| Config file | `mix.exs`, plus CI workflow `.github/workflows/ci.yml` |
| Quick run command | `node --test scripts/<new-audit-or-worktree-test>.test.cjs` (proposed targeted fixture tests) |
| Full suite command | `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` and `mix test`; for a full hosted change gate use the exact-SHA `CI contract`. |

Current sources quote the task's authoritative existing checks: `run: node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs` at `.github/workflows/ci.yml:350`; `run: mix test` at `:73`; `run: mix hex.audit` at `:394`; `name: CI contract` at `:397`. Root Mix requires Elixir `"~> 1.19"` at `mix.exs:11`; root and demo have distinct `mix.lock` files. `[VERIFIED: .github/workflows/ci.yml:73,350,394,397]` `[VERIFIED: mix.exs:11]` Quote: `elixir: "~> 1.19"`. `[VERIFIED: mix.lock and demo/mix.lock]` Quote: separate files `mix.lock` and `demo/mix.lock`.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|-------------|----------|-----------|-------------------|-------------|
| OPS-01 | Required docs/templates exist; no unverified security route or owner is presented; issue forms and PR template have bounded intent/proof fields. | static/config contract + human external setting confirmation | `node --test scripts/<collaboration-contract>.test.cjs` | ❌ proposed Wave 0 / implementation |
| OPS-02 | Audit reports missing/contradictory state, owner, scope, or next action for every open issue and PR without writing to GitHub. | fixture unit tests + live read-only smoke | `node --test scripts/<triage-audit>.test.cjs`; operator runs audit against fully paginated open records | ❌ proposed Wave 0 / implementation |
| OPS-03 | Manifest identity, clean entry/exit, and dirty/locked/stale/unreadable/unknown blocking behavior are correct; no destructive Git commands run. | temp-repository integration + command allowlist/static test | `node --test scripts/<worktree-gate>.test.cjs` | ❌ proposed Wave 0 / implementation |
| OPS-04 | Dependabot YAML keeps ecosystems and lockfile boundaries separate; update changes invoke existing compatibility/security contract with no auto-merge. | YAML/config contract + exact-SHA hosted integration | `node --test scripts/<dependabot-contract>.test.cjs`; PR checks require exact-SHA `CI contract` | ❌ config/test added by phase |

### Sampling Rate

- **Per task commit:** Targeted Node fixture test for the changed audit/config/worktree behavior plus relevant `mix format --check-formatted` or docs checks when applicable.
- **Per wave merge:** `node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs`, `mix test`, and affected demo/package/optional checks.
- **Phase gate:** Exact candidate-SHA `CI contract` success for all required jobs before merge; no local-only evidence substitutes for hosted proof.

### Wave 0 Gaps

- [ ] Add fixtures and tests for issue/PR completeness, contradictory dated records, and proof that the audit is read-only.
- [ ] Add temporary Git repo fixtures covering NUL/odd paths, clean/dirty status, locks, stale/prunable metadata, unreadable collection, manifest mismatch, and zero destructive operations.
- [ ] Add Dependabot YAML contract checks for Mix roots, Actions, groups, security-update separation, and non-auto-merge policy.
- [ ] Resolve and verify the private security report channel before the `SECURITY.md` text is treated as complete.

## Security Domain

### Applicable ASVS Categories

OWASP lists ASVS 5.0.0 as current stable and recommends version-qualified requirement IDs because identifiers may shift between versions. This phase adds no application authentication/session/crypto surfaces; security focus is repository access, untrusted text, filesystem/command boundaries, and dependency supply chain. `[CITED: https://owasp.github.io/www-project-application-security-verification-standard/]`

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication (ASVS 4.x naming) / ASVS 5.0 Authentication chapter | No application auth surface added | GitHub access uses repository permissions and read-only audit scopes. |
| V3 Session Management (4.x) / ASVS 5.0 Session Management chapter | No application session surface added | Do not persist credentials in local manifests or logs. |
| V4 Access Control (4.x) / ASVS 5.0 Authorization chapter | Yes, operationally | Read-only GitHub scopes; owners and CODEOWNERS only after verifying actual repository write access. |
| V5 Input Validation, Sanitization and Encoding (4.x) / ASVS 5.0 Encoding and Sanitization | Yes | Parse untrusted issue text and manifest data as data; validate schema, containment, identity, and bounds before use. Never form shell commands through interpolation. |
| V6 Stored Cryptography (4.x) / ASVS 5.0 Cryptography | No new cryptographic feature | Reuse GitHub and Git credential mechanisms; don't create custom token/signature storage. |

### Known Threat Patterns for repository tooling

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Issue/PR body or triage text contains command-like/untrusted input | Tampering / Elevation | Parse as plain data; never execute text; strict schema and no free-text owner inference. |
| Malicious/odd worktree path or manifest claims another tree | Tampering / Elevation | NUL-safe parse, resolved containment, manifest/path/branch/SHA/owner consistency, bounded same-tree status reads. |
| Accidental private report disclosure | Information disclosure | Do not direct vulnerabilities to public issue forms; publish only a verified private channel. |
| GitHub token or security report content leaks through audit output | Information disclosure | Read-only least-privilege token, allowlisted diagnostic fields, redact tokens and private report body content. |
| Unsafe cleanup removes unowned work | Denial of service / Tampering | No automatic delete/unlock/force/reset/prune; unknown and locked state blocks and remains for human disposition. |
| Malicious or broken dependency update | Supply-chain tampering | Dependabot PRs never auto-merge; exact-SHA full relevant CI plus Mix/Hex audit and manual review. |

## Project Constraints (from AGENTS.md)

No root `AGENTS.md` exists. The only discovered `demo/AGENTS.md` is scoped to the demo subtree and does not govern these root/GitHub operational artifacts. No project-local `.codex/skills/` or `.agents/skills/` directory was present.

## Sources

### Primary (HIGH confidence for repository facts; official docs are cited)

- `.planning/phases/35-review-ownership-worktree-operations/35-CONTEXT.md` - locked decisions, boundaries, and canonical source references.
- `.planning/REQUIREMENTS.md` - verbatim OPS-01 through OPS-04 requirements.
- `.planning/GSD-PREFERENCES.md` - shift-left verification, exact-SHA CI, privacy, and handoff preferences.
- `.github/workflows/ci.yml`, `scripts/repository_inventory.cjs`, `scripts/lib/repository_truth.cjs` - existing CI and read-only inventory patterns.
- GitHub read-only settings and permissions readback at 2026-09-26 02:01 UTC (2026-09-25 22:01 EDT): the exact endpoint results and repository permission values are recorded in the Hosted observation snapshot above; all are unverified for execution time.
- `gh issue list` and `gh pr list` at the same readback: 0 open issues and 1 open PR; recollect for live triage.

### Secondary (MEDIUM confidence: official documentation)

- [Git worktree documentation](https://git-scm.com/docs/git-worktree) - porcelain format, locks, safe removal, prune dry-run.
- [GitHub issue forms syntax](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms) and [PR templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository) - form output and template behavior.
- [GitHub CODEOWNERS documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) - access and parsing constraints.
- [GitHub Dependabot options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) and [security update grouping](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates) - Mix ecosystem, group scope/order, and security separation.
- [Mix dependency update docs](https://mix.hexdocs.pm/Mix.Tasks.Deps.Update.html) and [Hex audit docs](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html) - native update and advisory workflows.
- [OWASP ASVS 5.0](https://owasp.github.io/www-project-application-security-verification-standard/) - current stable version and version-qualified references.

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - repository patterns are directly inspected; platform details come from current official docs.
- Architecture: MEDIUM - decisions are locked by phase context; implementation still depends on verifying host lifecycle support and external GitHub settings.
- Pitfalls: MEDIUM - GitHub, Git, Mix, Hex, and OWASP primary documentation supports the operational constraints.

**Research date:** 2026-09-25 America/New_York; external state read back 2026-09-26 02:01 UTC (2026-09-25 22:01 EDT)
**Valid until:** 2026-10-25 (or sooner if GitHub settings, GSD worktree lifecycle, or CI contract changes)
