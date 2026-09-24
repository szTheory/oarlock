---
phase: 33-deterministic-green-ci
status: unobserved
samples: 0
---

# Phase 33 Hosted CI Baseline

## Observation Status

No successful hosted full-contract timing observation is available. Draft PR #6 has run on exact candidate SHAs, but its completed runs failed required planning checks and the timing tool correctly returns `run_not_successful`. The latest remote `main` remains `fb3d9a185f104194e85987541519a6168e0b568c`; its June 2026 CI run failed without a proof artifact. The authorized PR branch spans roughly 400 commits beyond `origin/main`; it is not a narrow Phase 33 patch.

## Baseline and Target

- Observed samples: 0
- Queue, lane, aggregate, critical-path, and runner-minute values: unmeasured
- Feedback target: not set
- Cache state: unobserved

Do not change workflow performance inputs or claim a baseline-derived target
until the current candidate produces a successful exact-SHA run with the full
required job set and proof artifact. Resume measurement with:

```sh
node scripts/ci_timing.cjs --sha "$CI_BASELINE_SHA" --json
```

The timing summarizer and fixture tests are implemented in `scripts/ci_timing.cjs`
and `scripts/ci_timing.test.cjs`; they do not substitute for hosted evidence.
