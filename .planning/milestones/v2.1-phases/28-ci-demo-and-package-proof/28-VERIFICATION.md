---
phase: 28-ci-demo-and-package-proof
verified: 2026-06-24T13:23:02-04:00
status: automated_blocked
score: 11/11 must-haves verified
behavior_unverified: 0
overrides_applied: 0
automated_verification:
  - test: "Assert a pushed GitHub Actions CI run for the exact SHA."
    command: "node scripts/ci_monitor.cjs assert-ci --sha <sha> --workflow CI --timeout 1800 --poll 20 --json"
    expected: "The monitor returns `verified: true` with jobs `mix test`, `static analysis`, `demo PostgreSQL`, `package smoke`, `optional dependencies`, and `CI contract` all successful."
    current_status: "blocked"
    blocker: "no_ci_run_for_sha"
    observed_sha: "aae1f7a83b7630fadeae320c383314cc7786df76"
    why_not_human: "Hosted GitHub Actions remains the authority, but verification is now performed by repo automation instead of manual inspection."
---

# Phase 28: CI, Demo, and Package Proof Verification Report

**Phase Goal:** Release readiness is continuously proven for the library, demo, and downstream install path.
**Verified:** 2026-06-24T13:23:02-04:00
**Status:** automated_blocked
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CI runs on normal push and pull_request events in the existing workflow. | VERIFIED | `.github/workflows/ci.yml:8-12` defines `push` to `main` and `pull_request`. YAML parse passed. |
| 2 | CI keeps root library gates: format, compile warnings-as-errors, tests, public specs, Dialyzer, CI monitor tests, and SUMMARY drift guard. | VERIFIED | Root `test` job runs format, unused-deps, compile, CI monitor tests, SDK tests, and drift guard; `dialyzer` runs public specs and Dialyzer. |
| 3 | Demo CI runs check-mode commands from `demo/`. | VERIFIED | `demo-postgres` runs `mix format --check-formatted`, `mix deps.unlock --check-unused`, `mix compile --warnings-as-errors`, and `mix test` with `working-directory: demo` at `.github/workflows/ci.yml:157-175`; no `mix precommit` in the workflow. |
| 4 | Demo CI uses PostgreSQL service container and explicit test database environment. | VERIFIED | `.github/workflows/ci.yml:119-135` sets `MIX_ENV: test`, `DB_HOST: localhost`, `services.postgres`, port `5432:5432`, and `pg_isready` health check. `demo/config/test.exs` reads `DB_HOST`. |
| 5 | Package smoke builds and unpacks the local Hex artifact. | VERIFIED | `bin/package_smoke.sh:10-13` runs `mix hex.build --unpack --output "$UNPACKED_DIR"`; local `bin/package_smoke.sh` passed and built/unpacked `oarlock 0.1.1`. |
| 6 | Fresh downstream consumer proves package/app/module naming split. | VERIFIED | `bin/package_smoke.sh:18-44` generates `{:paddle, path: unpacked_path}`; local smoke output reports package name `oarlock` and app `paddle`. |
| 7 | Fresh downstream consumer references stable public APIs without credentials or network calls. | VERIFIED | `bin/package_smoke.sh:50-64` generates `OarlockConsumerProof.UsePaddle` referencing `Paddle.Client`, `Paddle.Webhooks`, and `Paddle.Customers` only as module/function references. |
| 8 | CI includes package-smoke job invoking the reusable script. | VERIFIED | `.github/workflows/ci.yml` defines `package-smoke` and runs `bin/package_smoke.sh`. |
| 9 | CI includes optional-deps positive and negative lanes. | VERIFIED | `.github/workflows/ci.yml` runs `MIX_ENV=test mix test test/paddle/mock_server_test.exs` and then `bin/package_smoke.sh`. |
| 10 | `Paddle.MockServer` gates optional Plug/Bandit use and remains executable when those dependencies are present. | VERIFIED | `lib/paddle/mock_server.ex:33-74` checks `Plug.Router`, `Plug.Parsers`, and `Bandit`, returns a clear `RuntimeError` tuple on absence, and only defines `Router` when all are loaded. `test/paddle/mock_server_test.exs:15-108` starts `MockServer` and exercises customers, transactions, portal sessions, subscriptions, and fallback. Focused tests passed. |
| 11 | Public docs state MockServer optional dependency boundary and do not conflate MockServer with live Paddle provider-state proof. | VERIFIED | `README.md:25-37` and `README.md:165-168` state optional `plug`/`bandit` and core SDK independence; `demo/README.md:48-77` states demo/test deps include `plug`/`bandit` and MockServer-backed tests are not live provider-state verification. |
| 12 | Hosted CI inspection is automated and exact-SHA based. | BLOCKED | `scripts/ci_monitor.cjs` asserts the exact pushed SHA and required job names through `gh`; current probe returned `no_ci_run_for_sha` because no hosted run exists for local HEAD. |

**Score:** 11/11 phase truths verified, 1 automated external proof blocked by missing hosted run.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/paddle/mock_server.ex` | Compile-safe optional dependency boundary for `Paddle.MockServer`. | VERIFIED | Exists and substantive; optional deps checked with `Code.ensure_loaded?/1`, Bandit invoked through `apply/3`, router gated behind dependency availability. |
| `test/paddle/mock_server_test.exs` | Positive MockServer proof with `plug` and `bandit` available. | VERIFIED | Exists and substantive; starts `MockServer` via alias and exercises route behavior. GSD pattern helper missed `Paddle.MockServer.start_link` because the file aliases `Paddle.MockServer`, but manual wiring verifies the call. |
| `README.md` | Root optional dependency boundary documentation. | VERIFIED | Documents proof boundary and core SDK independence from Phoenix/Ecto/Plug/Bandit. |
| `demo/README.md` | Demo MockServer optional dependency documentation. | VERIFIED | Documents demo/test optional dependencies and proof ladder. |
| `.github/workflows/ci.yml` | Named CI jobs for root, demo PostgreSQL, package smoke, and optional dependency proof. | VERIFIED | Defines `test`, `dialyzer`, `demo-postgres`, `package-smoke`, and `optional-deps`; YAML parse passed. |
| `bin/package_smoke.sh` | Reusable Hex artifact downstream consumer smoke proof. | VERIFIED | Executable smoke script builds/unpacks Hex artifact, creates fresh consumer, verifies no `plug`/`bandit` declaration, and compiles with warnings as errors. |
| `scripts/ci_monitor.cjs` | Reusable exact-SHA GitHub Actions verifier. | VERIFIED | Dependency-free Node script with fake-`gh` tests for success, blocked, failed, missing-job, timeout, and wrong-SHA cases. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `lib/paddle/mock_server.ex` | `mix.exs` | Optional dependency boundary. | VERIFIED | `mix.exs` declares `plug` and `bandit` optional; MockServer gates those modules before router definition. |
| `test/paddle/mock_server_test.exs` | `lib/paddle/mock_server.ex` | Positive `start_link` and request-response tests. | VERIFIED | Test aliases `Paddle.MockServer` and calls `MockServer.start_link(port: port)`, then exercises SDK calls against the local server. |
| `.github/workflows/ci.yml` | `bin/package_smoke.sh` | Package smoke job invokes reusable script. | VERIFIED | `package-smoke` and `optional-deps` jobs both run `bin/package_smoke.sh`. |
| `.github/workflows/ci.yml` | `demo/config/test.exs` | Demo CI sets `DB_HOST=localhost`. | VERIFIED | Workflow sets `DB_HOST: localhost`; demo test config reads `System.get_env("DB_HOST") || "localhost"`. |
| `bin/package_smoke.sh` | `mix.exs` | Hex build/unpack consumes package metadata. | VERIFIED | Script runs `mix hex.build --unpack`; smoke output lists package files and metadata from `mix.exs`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `lib/paddle/mock_server.ex` | Route responses | `Paddle.MockServer.Fixtures` through gated Plug router | Yes | VERIFIED - focused tests confirm responses are parsed into SDK structs. |
| `bin/package_smoke.sh` | Fresh consumer dependency path | `mix hex.build --unpack --output "$UNPACKED_DIR"` then `OARLOCK_UNPACKED_PATH` | Yes | VERIFIED - local package smoke compiled fresh consumer from unpacked artifact. |
| `.github/workflows/ci.yml` | CI commands and environment | GitHub Actions job definitions | Yes, as configuration | VERIFIED locally by YAML parse and source checks; hosted execution is now automated through `scripts/ci_monitor.cjs`. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| MockServer positive lane and public-doc seam tests pass. | `MIX_ENV=test mix test test/paddle/mock_server_test.exs test/paddle/seam_test.exs` | 14 tests, 0 failures. | PASS |
| Package smoke builds/unpacks Hex artifact and compiles a fresh consumer without optional fixture deps. | `bin/package_smoke.sh` | Built/unpacked `oarlock 0.1.1`; compiled `paddle` and `oarlock_consumer_proof`; package smoke proof passed. | PASS |
| Workflow parses as YAML. | `ASDF_RUBY_VERSION=system ruby -e "require 'yaml'; YAML.load_file('.github/workflows/ci.yml')"` | Exit 0. | PASS |
| CI monitor tests pass. | `node --test scripts/ci_monitor.test.cjs` | 8 tests, 0 failures. | PASS |
| Exact-SHA hosted CI evidence is unavailable until push/PR. | `node scripts/ci_monitor.cjs assert-ci --sha aae1f7a83b7630fadeae320c383314cc7786df76 --workflow CI --timeout 0 --poll 0 --json` | `verified: false`, `reason: no_ci_run_for_sha`. | BLOCKED |
| Root compile still passes warnings-as-errors. | `mix compile --warnings-as-errors` | Exit 0. | PASS |
| CI source contains required jobs and links. | `grep` checks for `demo-postgres`, `package-smoke`, `optional-deps`, `DB_HOST: localhost`, `bin/package_smoke.sh`, and `test/paddle/mock_server_test.exs` | All matched. | PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` probes or phase-declared probe scripts found. Step 7c skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PROOF-01 | `28-02-PLAN.md` | CI runs root library checks already expected for release: format, compile warnings-as-errors, tests, public specs, Dialyzer, and SUMMARY drift guard. | SATISFIED | `.github/workflows/ci.yml:49-64` and `:103-107`. |
| PROOF-02 | `28-02-PLAN.md` | CI runs the demo test suite with a PostgreSQL service. | SATISFIED | `.github/workflows/ci.yml` defines `demo-postgres`, PostgreSQL service, `DB_HOST`, and demo test commands. Hosted execution is checked by the automated CI monitor after push/PR. |
| PROOF-03 | `28-02-PLAN.md` | CI includes a downstream consumer/package smoke test that verifies a fresh Mix app can depend on oarlock and compile. | SATISFIED | `.github/workflows/ci.yml:177-194` invokes `bin/package_smoke.sh`; local script passed. |
| PROOF-04 | `28-01-PLAN.md`, `28-02-PLAN.md` | Optional `plug` and `bandit` behavior is verified so consumers understand when `Paddle.MockServer` dependencies are required. | SATISFIED | MockServer gates optional deps, docs state the boundary, tests pass positive lane, and package smoke passes negative no-optional-deps lane. |

No orphaned Phase 28 requirements found. `.planning/REQUIREMENTS.md` maps PROOF-01 through PROOF-04 to Phase 28, and all four are declared in plan frontmatter across the two plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | - | - | - | No TODO/FIXME/XXX/placeholders, hardcoded empty user-visible data, or console-only handlers found in modified phase files. |

### Automated External Verification

### 1. Hosted GitHub Actions CI Run

**Test:** Run `node scripts/ci_monitor.cjs assert-ci --sha <sha> --workflow CI --timeout 1800 --poll 20 --json` for the exact pushed SHA.
**Expected:** Jobs `mix test`, `static analysis`, `demo PostgreSQL`, `package smoke`, `optional dependencies`, and `CI contract` are present and successful.
**Current result:** Blocked with `no_ci_run_for_sha` for local HEAD `aae1f7a83b7630fadeae320c383314cc7786df76`.
**Why not human:** The hosted CI run is still external, but the repo now has an exact-SHA verifier that produces machine-readable pass/fail/blocker evidence.

### Gaps Summary

No codebase gaps found. All roadmap success criteria, PLAN must-haves, artifacts, key links, and requirement IDs are accounted for. Status is `automated_blocked` only because GitHub Actions has not produced a run for the target SHA yet.

---

_Verified: 2026-06-24T13:23:02-04:00_
_Verifier: the agent (gsd-verifier)_
