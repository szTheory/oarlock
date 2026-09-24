---
phase: 33-deterministic-green-ci
plan: 03
subsystem: ci
tags: [github-actions, cache, reproducible-builds, timing]
requires:
  - phase: 33-02
    provides: Required CI proof matrix and aggregate contract
provides:
  - Exact-run hosted timing baseline with sample count and provisional feedback target
  - Controlled runner, service, Node, Hex, Rebar, timeout, and cache identities
  - Static checks for immutable action pins, cache trust boundaries, and unchanged CI proof lanes
affects: [phase-33-hosted-acceptance, main-ci]
actuals:
  tokens: 5000
  tasks: 2
  commits: 4
tech-stack:
  added: [actions/setup-node v6.5.0]
  patterns: [Successful-main-only cache writes, lock/runtime/architecture-aware cache keys, checksum-verified Rebar installer]
key-files:
  modified:
    - .github/workflows/ci.yml
    - scripts/ci_workflow_contract.test.cjs
    - scripts/ci_monitor.test.cjs
    - .planning/phases/33-deterministic-green-ci/33-CI-BASELINE.md
key-decisions:
  - "Set explicit timeouts from observed hosted job durations with generous headroom; keep the feedback target provisional until steady-state cache data exists."
  - "Allow pull requests to restore caches but only let successful pushes to main save shared executable caches."
  - "Key dependency and PLT caches by OS, architecture, BEAM toolchain, Mix environment, tool-version file, and the relevant lockfile."
  - "Pin PostgreSQL by manifest digest, Node to .tool-versions, Hex to 2.5.1, and Rebar 3.25.1 by verified SHA-512."
patterns-established:
  - "Keep hosted cache hit/miss and exact-SHA timing evidence together; never claim a target is met from a cold PR sample."
requirements-completed: [CI-02, CI-03]
coverage:
  - id: D1
    description: The workflow controls runner/service/toolchain identity, timeouts, least privilege, and cache trust.
    requirement: CI-02
    verification:
      - kind: unit
        ref: "node --test scripts/ci_workflow_contract.test.cjs"
        status: pass
      - kind: static
        ref: "actionlint .github/workflows/ci.yml"
        status: pass
      - kind: hosted
        ref: "run 36062578662; all eight required jobs passed"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact-SHA timing records an observed baseline and later comparisons with target methodology.
    requirement: CI-03
    verification:
      - kind: unit
        ref: "node --test scripts/ci_timing.test.cjs"
        status: pass
      - kind: hosted
        ref: "node scripts/ci_timing.cjs --sha e75a3b1fd8b9bb86b30602f4c36c97cb60b26d97 --run-id 36062578662 --repo szTheory/oarlock --json"
        status: pass
    human_judgment: false
duration: 42min
completed: 2026-09-24
status: complete
---

# Phase 33 Plan 03: Reproducible, Measured CI Summary

**CI now uses controlled inputs and trusted-main cache writes, with an exact-SHA baseline and explicit comparison evidence.**

## Performance

- **Duration:** 42 min
- **Started:** 2026-09-24T20:58Z
- **Completed:** 2026-09-24T21:40Z
- **Tasks:** 2
- **Hosted samples:** 4 successful exact-SHA runs; latest cold PR sample misses root, demo, and PLT caches
- **Feedback target:** provisional and unmet (under 120s critical path and under 6 runner minutes)

## Accomplishments

- Added explicit timeouts to all eight required jobs, based on observed hosted lane durations with generous cold-run headroom.
- Standardized on `ubuntu-24.04`, digest-pinned the PostgreSQL 17 manifest, and activated Node 22.14.0 from `.tool-versions` using a full-SHA-pinned setup-node action.
- Replaced mutable Hex/Rebar installs with Hex 2.5.1 and Rebar 3.25.1; verify the Rebar 3.25.1 official release binary with SHA-512 before installation.
- Made dependency/PLT restores explicit and keyed them by OS, architecture, OTP, Elixir, Mix environment, `.tool-versions`, and relevant lock digest. Only successful `main` pushes can save these caches.
- Preserved all eight required jobs in the aggregate and added static policy coverage for action pins, runner labels, timeouts, digests, cache identity, trust conditions, and project Node version.
- Recorded one initial warm sample and three later successful comparisons. The later samples exceeded the provisional target; cache logs on the latest candidate explicitly showed PR-ref cache misses because no trusted-main cache had yet been populated.

## Hosted Evidence

- Initial full-contract baseline: run `36058660703`, candidate `0230bf1aa398838da2637b674d88195ea9d9797f`, 85s critical path / 4.38 summed runner minutes.
- Latest successful full-contract check: run [36062578662](https://github.com/szTheory/oarlock/actions/runs/36062578662), candidate `e75a3b1fd8b9bb86b30602f4c36c97cb60b26d97`, tested PR merge SHA `d55fb19dfc70896300a0668716e43c2a13a7b4fb`, 198s critical path / 8.27 summed runner minutes.
- Latest proof artifact: `ci-proof-36062578662-1`, ID `10834714346`, digest `sha256:56c299864264ff3a97d1787dc97448a1e6bef6362a4bc6a519362534848eaee8`.
- Exact-SHA gate accepted the latest candidate and artifact. Main protection/current-main verification remains Plan 04 work.

## Task Commits

1. Baseline/runner/cache/acceptance controls: `b62db8c`, `4939bdd`
2. Installer pins and hosted timeout fixture correction: `5f76e4b`, `e75a3b1`

## Verification

- `actionlint .github/workflows/ci.yml`: passed.
- `node --test scripts/ci_monitor.test.cjs scripts/ci_workflow_contract.test.cjs scripts/ci_remote_gate.test.cjs scripts/ci_timing.test.cjs`: 33 tests passed.
- Hosted exact-SHA gate: `verified: true`; all eight jobs passed on run `36062578662`.

## Limitations

The feedback target is not met. The current successful PR run was cold because cache saves are intentionally restricted to main; compare again after an authorized, reviewed main path has populated the shared caches. Plan 04 still must resolve the broad PR history and verify the effective main rule and current-main proof.
