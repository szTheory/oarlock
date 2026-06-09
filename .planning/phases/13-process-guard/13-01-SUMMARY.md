---
phase: 13-process-guard
plan: 01
subsystem: Process
tags:
  - process
  - git-hooks
  - ci
  - tool-chain
dependency_graph:
  requires: []
  provides:
    - "Git pre-commit hook to prevent drift between SUMMARY and working tree"
  affects:
    - "mix.exs setup alias"
    - "CI test workflow"
tech_stack:
  added:
    - Bash (shell scripting)
  patterns:
    - Local Git pre-commit hooks
    - CI drift verification
key_files:
  created:
    - bin/check_summary_drift.sh
    - bin/install_hooks.sh
  modified:
    - mix.exs
    - .github/workflows/ci.yml
key_decisions:
  - "Used `git status --porcelain | grep -E '^(.[^ ])'` to robustly identify untracked or unstaged modifications while safely ignoring staged-only files."
  - "Included the hook installation as a `mix setup` step to ensure developers receive it during normal project initialization."
metrics:
  duration: 12m
  completed_date: 2026-06-09
---

# Phase 13 Plan 01: Process Guard Summary

Implemented a process guard to prevent drift between phase SUMMARY claims and actual git state by adding a fast bash-based pre-commit hook, an automatic installer via `mix setup`, and a parallel CI gate.

## Key Changes

- Created `bin/check_summary_drift.sh` to fail git commits containing a `SUMMARY.md` if the working tree has untracked or unstaged modifications. In CI, it validates the entire working tree is clean.
- Created `bin/install_hooks.sh` to cleanly symlink the check script to `.git/hooks/pre-commit` relative to the hook directory.
- Wired hook installation into `mix.exs` via the `setup` alias.
- Added a `Check for SUMMARY/git-state drift` step to `.github/workflows/ci.yml` after tests.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
- `bin/check_summary_drift.sh` and `bin/install_hooks.sh` found.
- All tasks successfully committed.
