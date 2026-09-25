---
phase: 33-deterministic-green-ci
plan: 04
subsystem: ci
tags: [github-actions, exact-sha, proof-artifact, rulesets, timing]
requires:
  - phase: 33-03
    provides: Controlled CI inputs, cache boundaries, and hosted timing baseline
provides:
  - Exact-SHA hosted candidate and current-main acceptance with retained artifact proof
  - Active main ruleset requiring the stable CI contract check
  - Final hosted timing comparison against the provisional feedback target
affects: [phase-34-release-integrity, main-ci]
actuals:
  tokens: 24471
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [Exact-SHA GitHub run/artifact acceptance, required-check ruleset verification]
key-files:
  created:
    - .planning/phases/33-deterministic-green-ci/33-04-SUMMARY.md
  modified:
    - scripts/ci_remote_gate.cjs
    - scripts/ci_remote_gate.test.cjs
    - lib/paddle/error.ex
    - test/paddle/error_test.exs
    - test/paddle/inspection_safety_test.exs
    - .planning/phases/33-deterministic-green-ci/33-CI-HOSTED.md
    - .planning/phases/33-deterministic-green-ci/33-CI-BASELINE.md
key-decisions:
  - "Require only the existing stable CI contract check on main, with no added strict-up-to-date constraint or bypass actor."
  - "Use the normal PR merge path after a complete base-to-head review and a passing exact-SHA proof."
  - "Keep the provisional under-120-second / under-6-runner-minute target unmet until warm hosted evidence demonstrates it."
patterns-established:
  - "Verify the required main rule and exact head/tested SHA/artifact identity with one hosted acceptance command."
requirements-completed: [CI-03, CI-04, CI-05]
coverage:
  - id: D1
    description: A candidate is accepted only when all required jobs and the retained proof artifact match its exact tested SHA.
    requirement: CI-05
    verification:
      - kind: unit
        ref: "node --test scripts/ci_remote_gate.test.cjs (161 tests passed)"
        status: pass
      - kind: hosted
        ref: "run 36077014434; candidate 580c1c836232e712b31e49913c694af9e1ca123e; artifact 10839959367"
        status: pass
    human_judgment: false
  - id: D2
    description: Remote main requires CI contract and has exact-current-SHA hosted proof with measured timing.
    requirement: CI-04
    verification:
      - kind: hosted
        ref: "node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json; run 36077488230; ruleset 23970515"
        status: pass
      - kind: other
        ref: "33-CI-BASELINE.md: main critical path 206s, 8.87 runner minutes; provisional target remains unmet"
        status: pass
    human_judgment: false
duration: 50min
completed: 2026-09-25
status: complete
---

# Phase 33 Plan 04: Hosted CI and Main Protection Summary

**Remote main now requires the exact-SHA CI contract and has a retained proof artifact for its current merge commit.**

## Performance

- **Duration:** approximately 50 min
- **Started:** 2026-09-24T23:40Z
- **Completed:** 2026-09-25T00:30Z
- **Tasks:** 2
- **Files modified:** 65 candidate files, plus this local closeout record
- **Hosted candidate:** 213s critical path / 8.68 runner minutes
- **Current main:** 206s critical path / 8.87 runner minutes
- **Feedback target:** provisional and unmet (<120s critical path / <6 runner minutes)

## Accomplishments

- Reviewed PR #6's broad 410-commit history against remote main, including its Phase 31 and Phase 32 review/verification artifacts and code/test scope. The accumulated changes were coherent project work; no credential-shaped strings were found in the scan.
- Hardened the remote gate to reject incomplete/duplicate required-job sets, workflow identity mismatches, and inaccurate timing observations; it rechecks main after observation and retries if the head drifts.
- Redacted provider-controlled `message` and `errors` fields from `Paddle.Error` inspection while preserving stored values and `Exception.message/1` behavior.
- Added a repository ruleset requiring only `CI contract` on `main`; verified the effective rule and GitHub Actions integration identity.
- Merged PR #6 normally. The final main run passed all eight required lanes, matched the exact current main SHA, and retained a downloadable proof artifact.
- Updated timing comparisons; neither the candidate nor main run met the provisional target.

## Hosted Evidence

- Candidate: [run 36077014434, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36077014434); head `580c1c836232e712b31e49913c694af9e1ca123e`; tested merge SHA `74ca59097ae258329e06a2481b2e359cf952b24e`; artifact `ci-proof-36077014434-1`, ID `10839959367`, digest `sha256:1e9bfde9f0062dd9753b22d16982cb51d6f660301f03bf9985106547ecf84561`.
- Main: [run 36077488230, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36077488230); exact main/tested SHA `0db804c18eaea751d19e662d020f770d53cefc57`; artifact `ci-proof-36077488230-1`, ID `10841045079`, digest `sha256:8ad67fd8a3669401ea2a32552aecc23ea37b5c5ecaa03f85abe574107c81b752`.
- Effective ruleset: ID `23970515`, name `Require CI contract on main`, required context `CI contract`, integration ID `15368`, no bypass actors, strict up-to-date requirement disabled.
- `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json`: `observed: true`, `verified: true`.

## Task Commits

1. **Task 1: Harden hosted acceptance and provider-error inspection** — `ea74661` (`fix: harden CI proof and provider error inspection`)
2. **Task 2: Require CI contract on main and merge the reviewed candidate** — `0db804c` (GitHub merge commit for PR #6)

Supporting review commits: `a14980a` normalized workstation-home prefixes in eligible planning files; `580c1c8` restored frozen archive artifacts after the history guard rejected their modification.

## Files Created/Modified

- `scripts/ci_remote_gate.cjs` / `scripts/ci_remote_gate.test.cjs` — strict workflow/job/artifact validation and main-head drift handling.
- `lib/paddle/error.ex`, `test/paddle/error_test.exs`, `test/paddle/inspection_safety_test.exs` — provider error inspection redaction.
- `33-CI-HOSTED.md` — candidate, effective-rule, and current-main observations.
- `33-CI-BASELINE.md` — post-change hosted timings and target comparison.

## Deviations from Plan

- The broad PR review exposed provider-controlled error strings in `Inspect`; redacting them was necessary to close the SDK's established inspection-safety contract and was included with regression coverage.
- Privacy normalization initially touched 15 planning artifacts protected by the existing frozen-history guard. Those artifacts were restored exactly; normalization remains limited to active/current planning files. Published history and frozen archive blobs retain earlier workstation paths, and the original public commit history was not rewritten.
- The required main check was added with `strict_required_status_checks_policy: false`, preserving the planned minimal protection scope without introducing an additional head-freshness constraint.

## Verification

- Focused Elixir tests: 18 passed; full Elixir suite: 275 passed.
- Node CI monitor/workflow/proof/timing suite: 161 passed.
- `mix credo --strict`, `mix docs`, and `actionlint .github/workflows/ci.yml`: passed.
- Live planning health and base-to-head history integrity checks: healthy.
- Candidate and current-main hosted acceptance: all eight required jobs passed with verified retained artifacts.

## Limitations

The <120s/<6-runner-minute target remains unmet. The initial 85s warm sample remains the lowest; successful later candidates and current main ranged from 198–229s critical path and 8.23–9.05 runner minutes. A later warm candidate comparison is needed after trusted-main cache writes.

The public repository's pre-existing commit history and frozen archive blobs retain old workstation path strings. Active planning paths were normalized where the append-only archive guard allowed it; no public history rewrite was performed.

## Next Phase Readiness

Phase 34 can bind release automation to the new required main check and durable exact-SHA artifacts. Any commit that advances remote main must pass the required check; if phase-closeout documentation is merged to main, rerun the exact-current-main gate afterward.

---
*Phase: 33-deterministic-green-ci*
*Completed: 2026-09-25*
