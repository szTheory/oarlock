# Phase 13: Process Guard - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement a process guard to prevent the drift between SUMMARY.md claims and the actual git state. This phase introduces a pre-commit hook and a parallel CI gate that fails if any in-progress phase SUMMARY claims files are committed while `git status --porcelain` shows dirty or untracked files.

This addresses the v1.1 audit-trail recurrence vector where summary files were committed without the corresponding codebase changes.
</domain>

<decisions>
## Implementation Decisions

Based on Elixir ecosystem best practices, great developer ergonomics (DX), and the need for speed, the following cohesive strategy is adopted:

### Hook Implementation (Speed vs. Idiom)
- **D-01:** Implement the drift check as a standalone Bash script (e.g., `bin/check_summary_drift.sh`).
- **Rationale:** While a Mix task (`mix gsd.precommit`) is idiomatic, Elixir/EVM boot time (~1-2 seconds) on *every single commit* introduces unacceptable friction. A Bash script using native Git commands executes in milliseconds, preserving the developer's momentum (principle of least surprise: "commits should be fast").
- **Logic:** The script will check `git diff --cached --name-only` for `*-SUMMARY.md`. If found, it runs `git status --porcelain`. If any unstaged or untracked files exist, it aborts the commit with a helpful error message.

### Hook Distribution and Elixir Integration
- **D-02:** Distribute the hook via an install script (`bin/install_hooks.sh`) that safely symlinks the pre-commit script to `.git/hooks/pre-commit`.
- **D-03:** Integrate into the Elixir lifecycle by adding an idiomatic `aliases` block to `mix.exs` with a `setup` task: `setup: ["deps.get", "cmd ./bin/install_hooks.sh"]`.
- **Rationale:** This is the standard Elixir ecosystem pattern (used by Phoenix and others) for bootstrapping a local environment. It requires zero mental overhead from the developer—running `mix setup` (which they already do) silently guarantees the hook is installed.

### CI Integration
- **D-04:** Add the exact same Bash script as a step in `.github/workflows/ci.yml` (e.g., in the `test` or `dialyzer` job, or as a standalone lightweight job).
- **Rationale:** Running the same script locally and in CI ensures parity and reduces maintenance. If a developer bypasses the local hook (`git commit --no-verify`), the CI gate will catch the drift using identical logic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and locked local decisions
- `.planning/ROADMAP.md` - Phase 13 goal and success criteria (PROC-01 and PROC-02).
- `.planning/MILESTONES.md` - Context on the v1.1 audit-trail recurrence vector (lines 27-30).
- `mix.exs` - Where the `setup` alias will be added.
- `.github/workflows/ci.yml` - Where the CI gate will be implemented.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The project already uses a `verify.sh` script, demonstrating that Bash scripts are an accepted pattern in this repository for tooling and CI gates.

### Established Patterns
- `mix.exs` currently lacks an `aliases` block. Adding one is purely additive and highly idiomatic.
- CI relies heavily on `ubuntu-latest` and runs simple `mix` and `run:` commands, making a bash script invocation trivial.

### Integration Points
- `bin/check_summary_drift.sh` (new)
- `bin/install_hooks.sh` (new)
- `.git/hooks/pre-commit` (symlink target)
- `mix.exs` (`defp aliases` block)
- `.github/workflows/ci.yml` (new step in existing jobs)

</code_context>

<specifics>
## Specific Ideas

- Ensure `bin/check_summary_drift.sh` provides a loud, colorful, and explicit error message, e.g.:
  `❌ ERROR: You are committing a SUMMARY.md file, but your working directory has unstaged or untracked changes.`
  `This violates the Process Guard (Phase 13). Please stage or stash your changes before committing.`

</specifics>

<deferred>
## Deferred Ideas

- None.

</deferred>
