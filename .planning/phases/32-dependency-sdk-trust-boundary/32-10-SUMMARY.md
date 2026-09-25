---
phase: 32-dependency-sdk-trust-boundary
plan: "10"
subsystem: sdk-public-contract
tags: [elixir, req, documentation-contract, compatibility, evidence, concurrency]

requires:
  - phase: 32-dependency-sdk-trust-boundary
    provides: Req 0.7.4 compatibility, constructor validation, bounded reads, mutation ambiguity, telemetry containment, and Inspect redaction from Plans 01-09 and 11
provides:
  - Mechanically guarded secure installation, runtime, migration, telemetry, and inspection contract
  - Six-tier evidence ladder that preserves local, mock, package/downstream, sandbox, hosted-CI, and live-provider authority boundaries
  - Executable concurrent-reader, interruption, repeatability, receipt, and no-drift certification for SAFE-01 through SAFE-06
affects: [phase-33-hosted-ci, phase-34-release-publication, public-sdk-consumers, accrue]

actuals:
  tokens: 9133
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns: [documentation as tested contract, byte-identical isolated snapshots, atomic receipt comparison, evidence-tier non-inference]

key-files:
  created:
    - bin/phase32_contract_proof.sh
  modified:
    - README.md
    - guides/getting-started.md
    - guides/telemetry.md
    - guides/accrue-seam.md
    - demo/README.md
    - CHANGELOG.md
    - test/paddle/seam_test.exs

key-decisions:
  - "Describe only Elixir ~> 1.19 as supported and Elixir 1.19.5 / OTP 28.1 as the fully exercised toolchain; do not infer broader BEAM support from local success."
  - "Treat package/downstream, sandbox, hosted-CI, and live-provider results as separate evidence tiers that cannot substitute for one another."
  - "Accept the final Phase 32 contract only after byte-identical concurrent readers, interruption rejection, and two equal complete 13-row receipt manifests pass without tracked drift."

patterns-established:
  - "Public-contract assertions combine required claims, region-scoped forbidden claims, fetched docs, fetched types, and fetched specs so compilation alone cannot hide semantic drift."
  - "Compatibility acceptance is repeatable and atomic: partial runs publish nothing, while complete runs normalize timing away before comparing row/verdict manifests."

requirements-completed: [SAFE-01, SAFE-02, SAFE-03, SAFE-04, SAFE-05, SAFE-06]

coverage:
  - id: D1
    description: "Req 0.7.4 remains compatible across root, package, demo, downstream Accrue, and online audit rows."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh#two complete 13-row matrices"
        status: pass
    human_judgment: false
  - id: D2
    description: "The public telemetry guide and compiled module docs expose only the exact attempt-scoped measurement and metadata allowlist."
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "test/paddle/seam_test.exs#public documentation pins the secure dependency and runtime migration contract"
        status: pass
      - kind: integration
        ref: "bin/phase32_contract_proof.sh#telemetry-adapter"
        status: pass
    human_judgment: false
  - id: D3
    description: "Public inspection guidance and fetched docs require the stable redaction marker for every capability-bearing value."
    requirement: SAFE-03
    verification:
      - kind: unit
        ref: "test/paddle/seam_test.exs#compiled docs types and specs agree with the Phase 32 decision tables"
        status: pass
      - kind: integration
        ref: "bin/phase32_contract_proof.sh#root-suite inspection safety"
        status: pass
    human_judgment: false
  - id: D4
    description: "Docs, examples, types, and migration guidance agree on bounded safe reads and non-replayable ambiguous mutations."
    requirement: SAFE-04
    verification:
      - kind: unit
        ref: "mix test test/paddle/seam_test.exs"
        status: pass
      - kind: integration
        ref: "bin/phase32_contract_proof.sh#focused HTTP and resource rows"
        status: pass
    human_judgment: false
  - id: D5
    description: "The constructor decision table and compiled Client docs/types/specs require secret-safe pre-Req validation."
    requirement: SAFE-05
    verification:
      - kind: unit
        ref: "test/paddle/seam_test.exs#constructor and fetched Client contracts"
        status: pass
      - kind: integration
        ref: "bin/phase32_contract_proof.sh#root-suite client tests"
        status: pass
    human_judgment: false
  - id: D6
    description: "Two byte-identical concurrent readers/builds, interrupted-run rejection, and two equal complete receipts certify a non-mutating public contract."
    requirement: SAFE-06
    verification:
      - kind: integration
        ref: "ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-09-10
status: complete
---

# Phase 32 Plan 10: Public Contract and Final Matrix Summary

**Tested public SDK contract with exact retry, ambiguity, telemetry, redaction, and evidence boundaries plus repeatable atomic certification across the complete compatibility matrix**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-10T22:22:31Z
- **Completed:** 2026-09-10T22:35:47Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Replaced stale installation, idempotency, retry, telemetry, and migration claims with one mechanically tested contract tied to compiled docs, types, and specs.
- Distinguished unit/local, MockServer, package/downstream, sandbox, hosted-CI, and live-provider evidence without inflating mock or header observations into provider guarantees.
- Added an executable SAFE-06 proof that runs byte-identical isolated readers/builds concurrently, proves partial runs publish no receipt, runs the 13-row matrix twice, compares normalized receipts, and detects tracked drift.

## Task Commits

Each TDD task was committed with its red gate followed by its green outcome:

1. **Task 1 RED: Guard secure public contract migration** - `e773e4c` (test)
2. **Task 1 GREEN: Publish secure runtime migration contract** - `959e862` (docs)
3. **Task 2 RED: Guard evidence ladder and final proof contract** - `94229c7` (test)
4. **Task 2 GREEN: Certify evidence-honest final compatibility contract** - `b400cc4` (feat)

## Files Created/Modified

- `bin/phase32_contract_proof.sh` - Concurrent snapshots, interruption self-test, double compatibility matrices, normalized receipts, SAFE mapping, and no-drift proof.
- `test/paddle/seam_test.exs` - Positive/negative docs assertions plus fetched module docs, types, specs, evidence tiers, and proof-runner guards.
- `README.md` - Req/BEAM, constructor, retry, ambiguity, redaction, and proof-boundary contract.
- `guides/getting-started.md` - Removed unsupported idempotency usage and added consumer-owned ambiguity reconciliation.
- `guides/telemetry.md` - Replaced raw Req objects with the exact per-attempt schema and subscriber migration guidance.
- `guides/accrue-seam.md` - Added contextual error arities and the complete proof ladder.
- `demo/README.md` - Kept MockServer evidence bounded and separated package, hosted, sandbox, and live authority.
- `CHANGELOG.md` - Recorded the intentional pre-1.0 source and observable behavior migration.

## Decisions Made

- The supported BEAM statement mirrors `mix.exs` and separates the supported Elixir range from the one fully exercised OTP/toolchain pair.
- Timing differences in complete matrix receipts are normalized to `row=passed`; row names, count, order, and verdict remain comparison-critical.
- Phase 32 establishes local/package/downstream evidence only. Hosted workflow authority stays with Phase 33 and publication authority stays with Phase 34.

## Decision and Coverage Closure

| Decisions | Final proof |
| --- | --- |
| D-01..D-03 | Req `~> 0.7.4`, root/resource adapters, full package/demo/downstream/audit matrix |
| D-04 | Elixir `~> 1.19` support and Elixir 1.19.5 / OTP 28.1 exercised toolchain documented without broader inference |
| D-05..D-09 | Exact telemetry allowlist and stable Inspect redaction contract re-proved in the root/focused suites |
| D-10..D-17 | Four-attempt safe-read ceiling, 60,000 ms 429 cap, mutation single attempt, ambiguity context, static routes, and cursor separation bound to docs/types/specs |
| D-18 | README, guides, demo, changelog, module docs, public types, and function specs mechanically agree |
| D-19 | Six evidence tiers remain distinct; hosted and live-provider authority are explicitly outside Phase 32 |
| Every `COVERAGE.md` row | All twelve integrated request/telemetry rows and four reasoned exclusions are named by the 13-row matrix, seam contract, or D-19 non-inference boundary |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired three inherited seam transition failures**
- **Found during:** Task 1 baseline RED run
- **Issue:** The seam still sent a removed idempotency option, treated newly documented transport modules as sealed, and omitted contextual `Paddle.Error` arities.
- **Fix:** Removed the stale header/option behavior, narrowed the genuinely sealed module inventory, and added `from_response/2` plus `from_transport/2` to the public inventory and seam guide.
- **Files modified:** `test/paddle/seam_test.exs`, `guides/accrue-seam.md`
- **Verification:** `mix test test/paddle/seam_test.exs` reports 9 tests, 0 failures.
- **Committed in:** `e773e4c`, `959e862`

**2. [Rule 2 - Missing Critical] Applied the evidence ladder to every first-read proof boundary**
- **Found during:** Task 2 contract RED run
- **Issue:** The task file list centered on the seam/demo, but README and Getting Started would otherwise retain a conflicting four-tier proof boundary.
- **Fix:** Added package/downstream and hosted-CI tiers plus explicit live-provider limits to both first-read guides.
- **Files modified:** `README.md`, `guides/getting-started.md`
- **Verification:** The region-scoped proof-boundary test passes across all four public guides.
- **Committed in:** `b400cc4`

**3. [Rule 3 - Blocking] Reconciled state after dependency-ordered plan completion**
- **Found during:** Plan close-out
- **Issue:** The standard state handler advanced to already-completed Plan 11 and skipped progress recalculation because Phase 32 is not yet verifier-complete.
- **Fix:** Preserved the handler's authoritative 20-plan count while aligning the visible position, activity, progress, todo, and next-step fields with all eleven Phase 32 summaries on disk.
- **Files modified:** `.planning/STATE.md`
- **Verification:** State reports 20/20 plans, Phase 32 at 11/11, 100% execution progress, and ready for verification; ROADMAP independently reports 11/11.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical contract alignment, 1 blocking state reconciliation)
**Impact on plan:** The changes closed inherited seam drift, prevented a split public contract, and kept planning state consistent after out-of-order dependency execution; no endpoint, public symbol, or provider claim was added.

## Issues Encountered

- Hex emitted an expired optional user-authentication warning during public registry operations, but `mix hex.info`, dependency downloads, and `mix hex.audit` all completed successfully; no private resource or authentication gate was required.

## Known Stubs

None. Matches for empty values in the changed seam test are assertions of real nil/empty-header behavior, and the seam guide's “placeholder root module” wording describes an intentionally excluded module rather than unfinished work.

## Threat Flags

None. The new script performs local read/build/test execution in dedicated temporary directories and introduces no network endpoint, authentication path, schema, or new trust boundary beyond the plan's T-32-25 through T-32-27 register.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 33 can establish hosted exact-SHA workflow authority against this stable local/package contract.
- Phase 34 can handle publication and release authority after hosted evidence passes.
- No Phase 32 blocker remains; live-provider verification remains an explicit operator-owned boundary.

## Self-Check: PASSED

- Summary exists at the canonical Phase 32 path.
- All four TDD task commits (`e773e4c`, `959e862`, `94229c7`, `b400cc4`) exist in Git history.
- The Phase 32 broken-windows ledger has zero open entries after resolving the owned seam transition truth and both completed deviations.

---
*Phase: 32-dependency-sdk-trust-boundary*
*Completed: 2026-09-10*
