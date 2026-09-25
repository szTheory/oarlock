---
phase: 33-deterministic-green-ci
status: provisional
samples: 1
---

# Phase 33 Hosted CI Baseline

## Observation Status

One successful hosted full-contract timing observation is available on draft PR #6. Remote `main` remains `fb3d9a185f104194e85987541519a6168e0b568c`; its June 2026 CI run failed without a proof artifact. The candidate PR branch spans roughly 400 commits beyond `origin/main`, so it still needs scope review before merge.

## Baseline and Target

- Observed sample: 1 (warm hosted caches; no cold-run sample)
- Candidate head SHA: `0230bf1aa398838da2637b674d88195ea9d9797f`
- PR merge SHA tested by GitHub: `f0c5f42583f63c9440051948a32d06851fca7f76`
- Run: [36058660703, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36058660703), created `2026-09-24T21:00:38Z`, completed `2026-09-24T21:02:05Z`
- Queue: 2s; aggregate elapsed: 87s; CI critical path: 85s; summed runner time: 4.38 minutes
- Lane durations: mix test 64s; static analysis 27s; demo PostgreSQL 59s; package smoke 21s; optional dependencies 25s; planning truth 11s; quality 38s; CI contract 18s
- Toolchain: OTP 28.1, Elixir 1.19.5-otp-28, Node 22.23.2, Hex 2.5.1, Rebar 3.25.1, Linux/X64
- Root lock digest: `59672b2c05ec9c133bdc0094b9b8a8cee810ee0e0964ec61f57ae15c6961d09e`; demo lock digest: `291f4552fa4b20ceaa01d595409b807d1cefe63b151680a79d4dcb778f271eca`
- Cache state: all observed root deps, optional deps, demo deps, and Dialyzer PLTs were warm/cache hits.
- Provisional feedback targets: critical path under 120s and summed runner time under 6 minutes. These leave headroom over one warm sample; revisit after several runs and at least one cold-cache observation.

Do not claim performance gains from this single sample. Re-measure every
workflow change and add cold-cache evidence when practical. Resume measurement with:

```sh
node scripts/ci_timing.cjs --sha "$CI_BASELINE_SHA" --json
```

The timing summarizer and fixture tests are implemented in `scripts/ci_timing.cjs`
and `scripts/ci_timing.test.cjs`; they do not substitute for hosted evidence.
