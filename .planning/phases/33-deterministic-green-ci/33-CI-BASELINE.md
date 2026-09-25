---
phase: 33-deterministic-green-ci
status: provisional
samples: 7
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

## Subsequent Hosted Observations

These later successful runs are comparison data. The provisional target is not
met; do not describe the workflow changes as a speed improvement.

| Candidate SHA | Run | Critical path | Runner minutes | Notes |
|---|---|---:|---:|---|
| `b62db8c65b19fd874c856c55fe8391e8116913aa` | [36060015833](https://github.com/szTheory/oarlock/actions/runs/36060015833), attempt 1 | 200s | 8.23 | Successful all-lane proof; first bounded-runner/toolchain-aware cache-key pass. Cache hit/miss not captured. |
| `4939bddaa78e3027a014d10137191fd1dcefb27b` | [36061010940](https://github.com/szTheory/oarlock/actions/runs/36061010940), attempt 1 | 210s | 8.97 | Successful all-lane proof after digest-pinning PostgreSQL, enabling project Node, and separating main-only cache writes. Cache hit/miss not captured. |
| `e75a3b1fd8b9bb86b30602f4c36c97cb60b26d97` | [36062578662](https://github.com/szTheory/oarlock/actions/runs/36062578662), attempt 1 | 198s | 8.27 | Successful all-lane proof with pinned Hex/Rebar and setup-node v6.5.0; observed root/demo/PLT caches missed on the PR ref (no shared main cache exists yet). |
| `4cb3a3b23d934fbc56dd370b50f6582337c2510c` | [36063394878](https://github.com/szTheory/oarlock/actions/runs/36063394878), attempt 1 | 229s | 9.05 | Successful all-lane proof after adding the Plan 33-03 summary and checking the roadmap; root/demo/PLT caches again missed on the PR ref. |

The later elapsed times exceed the 85s initial warm sample. The latest PR runs
explicitly recorded cache misses for root deps, demo deps, and Dialyzer PLTs
because trusted-main cache writes had not yet occurred. The current main run
below passed and can seed the shared cache. Keep the 120s/6-minute targets as
unmet goals; compare again after a warm post-main candidate without treating
the current main run as a steady-state cost measurement.

| Candidate SHA | Run | Critical path | Runner minutes | Notes |
|---|---|---:|---:|---|
| `580c1c836232e712b31e49913c694af9e1ca123e` | [36077014434](https://github.com/szTheory/oarlock/actions/runs/36077014434), attempt 1 | 213s | 8.68 | Successful exact-SHA candidate proof; 95s queue. Shared main cache was not yet seeded. |
| `0db804c18eaea751d19e662d020f770d53cefc57` | [36077488230](https://github.com/szTheory/oarlock/actions/runs/36077488230), attempt 1 | 206s | 8.87 | Successful exact-current-main proof and first trusted-main cache writer; 2s queue. |

Both final observations passed all eight required jobs and retained exact-SHA
proof artifacts. Neither met the provisional <120s/<6-minute target. The main
run's cache-save steps now provide the basis for a subsequent warm comparison.

Do not claim performance gains from this single sample. Re-measure every
workflow change and add cold-cache evidence when practical. Resume measurement with:

```sh
node scripts/ci_timing.cjs --sha "$CI_BASELINE_SHA" --json
```

The timing summarizer and fixture tests are implemented in `scripts/ci_timing.cjs`
and `scripts/ci_timing.test.cjs`; they do not substitute for hosted evidence.
