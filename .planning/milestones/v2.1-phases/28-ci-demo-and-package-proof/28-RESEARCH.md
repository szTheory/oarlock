# Phase 28: CI, Demo, and Package Proof - Research

**Researched:** 2026-06-24
**Domain:** Elixir/Mix/Hex release-readiness CI, Phoenix demo CI, optional dependencies
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### CI Job Shape
- **D-01:** Keep Phase 28 proof in the existing `.github/workflows/ci.yml` so release readiness remains contributor-facing and runs on normal PRs/pushes.
- **D-02:** Add separate named jobs instead of stuffing demo, package, and optional-dependency proof into the current root jobs. Preserve the existing root `test` and `dialyzer` jobs for PROOF-01, then add distinct jobs for demo/PostgreSQL, downstream package smoke, and optional dependency proof.
- **D-03:** Do not create a separate `release-proof.yml` unless these checks become too slow for regular PRs. A release-only proof workflow would split the source of truth and weaken the "continuously proven" requirement.
- **D-04:** Prefer clear failure attribution over minimal YAML. A contributor should be able to tell whether the break is root library behavior, demo/Postgres integration, package contents, or optional dependency isolation.

### Demo CI Strictness
- **D-05:** Demo CI should be a CI-safe quality gate: `mix format --check-formatted`, `mix deps.unlock --check-unused`, `mix compile --warnings-as-errors`, and `mix test` from the `demo/` directory.
- **D-06:** Demo tests must run with a GitHub Actions PostgreSQL service container and explicit test database environment. This satisfies PROOF-02 and matches Phoenix/Ecto expectations without requiring local Docker Compose.
- **D-07:** Do not run the existing `demo` `precommit` alias verbatim in CI if it uses mutating or local-fix commands. CI should use check-mode commands and deterministic setup steps.
- **D-08:** Keep `mix assets.deploy` as optional/path-filtered or follow-up proof, not the default Phase 28 gate. The phase needs demo test proof, not production demo deployment certification. Add asset proof only if planning finds the current demo asset path is already part of the release-readiness risk.

### Downstream Package Smoke
- **D-09:** Use a local Hex artifact proof, not only a repo path dependency. Build/unpack the package artifact with Hex tooling, then compile a fresh temporary Mix app that depends on the unpacked package path.
- **D-10:** The fresh consumer should prove the package/app/module naming split explicitly: Hex package `oarlock`, OTP app `:paddle`, public modules under `Paddle.*`.
- **D-11:** The smoke should compile a tiny consumer module that calls or references stable public API such as `Paddle.Client`, `Paddle.Webhooks`, and one resource module. It should not require real Paddle credentials or network access.
- **D-12:** Do not reimplement Hex packaging rules with a custom file-copy simulation. The package proof should use Hex's own build/unpack behavior so missing `package.files`, docs, or source files fail the same way they would fail before publishing.

### Optional `plug`/`bandit` Dependency Proof
- **D-13:** Treat optional dependency proof as a two-sided contract: `Paddle.MockServer` must work when `plug` and `bandit` are present, and the core SDK must compile for downstream consumers that do not include those optional dependencies.
- **D-14:** Add an isolated no-optional-deps compile proof, ideally through the downstream smoke path, using `mix compile --no-optional-deps --warnings-as-errors` or an equivalent fresh-consumer check. Mix explicitly recommends this style for optional dependencies.
- **D-15:** Add or preserve a positive MockServer lane with `plug` and `bandit` available so Offline Mode remains executable, not merely documented.
- **D-16:** Current code has a real compile-time optional-dependency risk: `lib/paddle/mock_server.ex` uses `Plug.Router` and calls `Bandit.start_link/1`. Planning must account for this by gating optional modules, splitting the fixture, or otherwise ensuring fresh core consumers can compile without `plug`/`bandit`.
- **D-17:** Documentation should state the boundary plainly: `Paddle.MockServer` is an offline development/test fixture that requires optional `plug` and `bandit`; the core SDK, webhook verification, typed resources, and HTTP client do not require Phoenix, Ecto, Plug, or Bandit.

### Developer Experience and Proof Philosophy
- **D-18:** Keep every Phase 28 proof deterministic by default. Do not add live Paddle sandbox/provider-state CI. That remains manual, on-demand, or a future release/nightly workflow only if credentials and state management justify it.
- **D-19:** Favor boring, idiomatic Elixir tooling: `erlef/setup-beam` with `.tool-versions`, Mix/Hex commands, GitHub Postgres services, named jobs, isolated temp Mix consumers, and check-mode CI commands.
- **D-20:** The proof ladder from Phase 27 stays authoritative: root unit/contract tests prove local SDK behavior; MockServer proves deterministic offline SDK/demo wiring; Paddle sandbox checks prove real provider-state behavior only when real credentials are used; live readiness remains operator-owned.
- **D-21:** Optimize CI output for maintainers and adopters. Failures should use precise job/step names and direct command output rather than a giant release script whose failure requires archaeology.

### the agent's Discretion
- The planner may choose whether optional dependency proof lives as a separate job or as a named step inside the downstream smoke job, as long as both the positive MockServer lane and negative no-optional-deps lane are executable.
- The planner may factor repeated GitHub Actions setup through anchors, scripts, or direct YAML, whichever keeps the workflow easiest to maintain in this repo.
- The planner may include an asset smoke only if code inspection shows the demo's Phoenix asset path is likely to regress release readiness; otherwise keep it deferred.

### Deferred Ideas (OUT OF SCOPE)
- Mandatory live Paddle sandbox/provider-state CI remains out of scope. It can become a manual, nightly, or release-only workflow in a future phase if credentials, isolation, and state cleanup are solved.
- Production demo deployment, Docker release boot, or full container smoke proof is out of scope unless a later phase decides the demo itself must be certified as deployable software.
- Phoenix/Ecto helper packages, Plug adapters, admin UI, local billing mirrors, and broader Paddle endpoint expansion remain outside Phase 28.
- GSD backlog/state/audit reconciliation belongs to Phase 29.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | CI runs root library release checks: format, compile warnings-as-errors, tests, public specs, Dialyzer, and SUMMARY drift guard. | Existing `.github/workflows/ci.yml` already has root `test` and `dialyzer` jobs with those commands; preserve them and avoid combining new proof surfaces into them. [VERIFIED: codebase grep] |
| PROOF-02 | CI runs the demo test suite with PostgreSQL. | GitHub Actions supports job-level PostgreSQL service containers with `postgres` image, `POSTGRES_PASSWORD`, health checks, and `localhost` port mapping for runner jobs. [CITED: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers] |
| PROOF-03 | CI includes downstream consumer/package smoke for a fresh Mix app. | Hex `mix hex.build --unpack -o <dir>` builds and unpacks the package artifact for inspection/consumption, and local probing confirmed the current package unpacks to `/tmp/oarlock-hex-unpack`. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] [VERIFIED: local command] |
| PROOF-04 | Optional `plug`/`bandit` behavior is verified or documented. | Mix docs define optional deps as not forced on downstream consumers and recommend no-optional-deps compile proof; local fresh-consumer probe currently fails on `Plug.Router` in `Paddle.MockServer`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: local command] |
</phase_requirements>

## Summary

Phase 28 should extend the existing CI workflow with three named proof surfaces: demo/PostgreSQL, downstream package smoke, and optional-dependency proof, while preserving the existing root `test` and `dialyzer` jobs. [VERIFIED: codebase grep] The standard stack is the current repo stack: GitHub Actions, `erlef/setup-beam` pinned by commit and `.tool-versions`, Mix, Hex, Dialyxir, PostgreSQL service containers, and existing Mix aliases/commands. [VERIFIED: codebase grep] [CITED: https://github.com/erlef/setup-beam]

The main planning risk is optional dependency isolation. A root `MIX_ENV=test mix compile --no-optional-deps --warnings-as-errors` passed locally, but a fresh Mix app depending on the unpacked Hex artifact failed because `lib/paddle/mock_server.ex` expands `Plug.Router` when `plug` is absent. [VERIFIED: local command] The planner should treat that as the first implementation dependency for PROOF-03/PROOF-04, not as a CI-only YAML task. [VERIFIED: local command]

**Primary recommendation:** Add named jobs in `.github/workflows/ci.yml`: keep root gates, add `demo-postgres`, add `package-smoke`, and add explicit positive/negative optional-dependency proof after fixing or gating `Paddle.MockServer`. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Root library release gates | CI / Build | Library source | CI owns orchestration; Mix commands prove the root SDK behavior. [VERIFIED: codebase grep] |
| Demo test proof | CI / Build | Demo app + PostgreSQL service | CI owns PostgreSQL service setup; `demo/` owns Phoenix/Ecto tests and migrations. [VERIFIED: codebase grep] |
| Package artifact smoke | CI / Build | Hex/Mix package metadata | CI should build/unpack the package artifact and compile a fresh consumer. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] |
| Optional dependency boundary | Library source | CI / Docs | Source must compile for consumers without optional deps; CI proves both no-optional and MockServer-present cases. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |

## Project Constraints (from AGENTS.md)

No root `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills/`, or `.agents/skills/` was found in this workspace during research. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GitHub Actions | hosted | CI orchestration | Existing repo uses `.github/workflows/ci.yml`, PR/push triggers, concurrency, pinned actions, and Ubuntu runners. [VERIFIED: codebase grep] |
| `erlef/setup-beam` | pinned to commit for v1.24.0 | Install Erlang/Elixir from `.tool-versions` | Official README supports `version-file`; strict mode is required/checked with version files. [CITED: https://github.com/erlef/setup-beam] |
| Elixir / Mix | 1.19.5 | Compile, test, package, dependency commands | `.tool-versions` requires Elixir `1.19.5-otp-28`; local `mix --version` matches. [VERIFIED: local command] |
| Erlang/OTP | 28.1 target, local OTP 28 | BEAM runtime | `.tool-versions` requires Erlang `28.1`; local runtime reports OTP 28. [VERIFIED: local command] |
| Hex | 2.4.2 local archive | Build/unpack package artifact | `mix hex.build --unpack` is the official local package artifact mechanism. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] |
| Dialyxir | 1.4.7 locked | Static analysis | Existing CI runs `mix dialyzer`; Dialyxir docs recommend PLT caching keyed by OTP/Elixir and `mix.lock`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| PostgreSQL service container | `postgres` image | Demo Ecto test database | GitHub docs recommend service containers with health checks for database-backed jobs. [CITED: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `plug` | 1.19.2 locked root/demo | Optional MockServer router dependency | Only for positive MockServer/offline fixture proof. [VERIFIED: codebase grep] |
| `bandit` | 1.12.0 locked root/demo | Optional MockServer HTTP server dependency | Only for positive MockServer/offline fixture proof. [VERIFIED: codebase grep] |
| `req` | 0.5.17 root lock, 0.5.18 resolved in fresh consumer | Core HTTP client | Fresh consumer smoke fetches it as a non-optional dependency. [VERIFIED: local command] |
| Phoenix demo stack | Phoenix 1.8.8 locked, Postgrex 0.22.2 locked | Demo test lane | Use only inside `demo/`, not root SDK coupling. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `ci.yml` | Separate `release-proof.yml` | Rejected by locked decision D-03 because release readiness should be continuously proven on normal PR/push CI. [VERIFIED: CONTEXT.md] |
| `mix hex.build --unpack` | Custom copy of `lib`, `mix.exs`, docs | Rejected because it does not exercise Hex package `:files` behavior. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] |
| Direct `demo` `precommit` alias | Explicit check-mode commands | Rejected because `demo/mix.exs` `precommit` runs mutating `format`, not `format --check-formatted`. [VERIFIED: codebase grep] |

**Installation:** No new external packages are recommended for Phase 28; use existing Mix/Hex dependencies and GitHub Actions. [VERIFIED: codebase grep]

## Package Legitimacy Audit

The GSD package-legitimacy seam supports `npm`, `pypi`, and `crates`, but rejected `--ecosystem hex`; no Hex package legitimacy verdicts can be emitted by that seam in this session. [VERIFIED: local command] Phase 28 should not introduce new package dependencies; existing Hex dependencies are already declared in `mix.exs` / `demo/mix.exs` and resolved in lockfiles. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `req` | Hex | existing project dependency | 195,076 last 7 days | github.com/wojtekmach/req | Not seam-auditable for Hex | Existing dependency only [VERIFIED: `mix hex.info req`] |
| `plug` | Hex | existing optional dependency | 325,593 last 7 days | github.com/elixir-plug/plug | Not seam-auditable for Hex | Existing dependency only [VERIFIED: `mix hex.info plug`] |
| `bandit` | Hex | existing optional dependency | 167,669 last 7 days | github.com/mtrudel/bandit | Not seam-auditable for Hex | Existing dependency only [VERIFIED: `mix hex.info bandit`] |
| `dialyxir` | Hex | existing dev/test dependency | 150,215 last 7 days | github.com/jeremyjh/dialyxir | Not seam-auditable for Hex | Existing dependency only [VERIFIED: `mix hex.info dialyxir`] |

**Packages removed due to [SLOP] verdict:** none; no new packages proposed. [VERIFIED: codebase grep]
**Packages flagged as suspicious [SUS]:** none from the available seam; Hex ecosystem not supported by seam. [VERIFIED: local command]

## Architecture Patterns

### System Architecture Diagram

```text
push / pull_request
  -> .github/workflows/ci.yml
    -> root test job
      -> mix format --check-formatted
      -> mix deps.unlock --check-unused
      -> mix compile --warnings-as-errors
      -> mix test
      -> ./bin/check_summary_drift.sh
    -> root dialyzer job
      -> restore priv/plts cache
      -> mix typecheck.specs
      -> mix dialyzer
    -> demo-postgres job
      -> services.postgres with health check
      -> cd demo
      -> mix format --check-formatted
      -> mix deps.unlock --check-unused
      -> mix compile --warnings-as-errors
      -> mix test
    -> package-smoke job
      -> mix hex.build --unpack -o "$RUNNER_TEMP/oarlock-unpack"
      -> mix new "$RUNNER_TEMP/oarlock_consumer" --sup
      -> add {:paddle, path: "$RUNNER_TEMP/oarlock-unpack"}
      -> compile consumer module referencing Paddle.Client/Paddle.Webhooks/Paddle.Customers
      -> mix compile --warnings-as-errors
    -> optional-deps proof
      -> negative lane: fresh consumer without plug/bandit compiles
      -> positive lane: MockServer tests compile/run with plug+bandit
```

### Recommended Project Structure

```text
.github/workflows/
└── ci.yml                         # Existing workflow extended with named jobs
scripts/ or bin/
└── package_smoke.sh               # Optional only if inline YAML becomes hard to read
lib/paddle/
├── mock_server.ex                 # Gate/split optional Plug/Bandit use
└── mock_server/fixtures.ex        # Keep fixture data package-safe if MockServer remains packaged
demo/
└── test/                          # Existing Phoenix/Ecto tests run against CI PostgreSQL service
```

### Pattern 1: GitHub Actions PostgreSQL Service Job
**What:** Use a job-level `services.postgres` container with health checks and runner port mapping. [CITED: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers]
**When to use:** Demo tests that need Ecto/Postgrex against a real PostgreSQL server. [VERIFIED: codebase grep]
**Example:**
```yaml
# Source: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers
services:
  postgres:
    image: postgres
    env:
      POSTGRES_PASSWORD: postgres
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
    ports:
      - 5432:5432
```

### Pattern 2: Hex Artifact Consumer Smoke
**What:** Build and unpack the package artifact, then compile a fresh consumer using the unpacked artifact path. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html]
**When to use:** Proving package `:files`, package name `oarlock`, OTP app `:paddle`, and public `Paddle.*` modules. [VERIFIED: codebase grep]
**Example:**
```bash
# Source: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html
mix hex.build --unpack -o "$RUNNER_TEMP/oarlock-unpack"
mix new "$RUNNER_TEMP/oarlock_consumer" --sup --app oarlock_consumer
```

### Pattern 3: Optional Dependency Negative Proof
**What:** Compile from a downstream consumer that depends on the package without declaring `plug` or `bandit`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]
**When to use:** Proving optional dependency declarations are real for adopters, not just present in `mix.exs`. [VERIFIED: local command]
**Example:**
```bash
# Source: https://hexdocs.pm/mix/Mix.Tasks.Compile.html
mix compile --warnings-as-errors
```

### Anti-Patterns to Avoid
- **Calling `demo` `precommit` in CI:** It runs mutating `format`, so use explicit check-mode commands. [VERIFIED: codebase grep]
- **Path dependency only smoke:** A repo path dependency can pass while `package.files` omits required files; use Hex build/unpack. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html]
- **Root-only no-optional-deps proof:** Root compile passed locally but fresh consumer compile failed, so root-only proof misses the adopter risk. [VERIFIED: local command]
- **Live Paddle CI:** Explicitly out of scope for Phase 28. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PostgreSQL orchestration in CI | Custom Docker Compose job | GitHub Actions service containers | Service containers are the documented workflow primitive and integrate with job health checks. [CITED: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers] |
| Package contents simulation | Manual copy to temp dir | `mix hex.build --unpack` | Hex controls `:files`, package metadata, and tarball layout. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] |
| Optional-deps inference | Reading `mix.exs` only | Fresh consumer compile without optional deps | Mix optional deps are not forced downstream, so downstream compile is the real proof. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| Dialyzer cache logic | Bespoke PLT cache naming | Dialyxir documented cache keys | Dialyxir docs key PLT cache by runner OS, OTP, Elixir, and `mix.lock`. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |

**Key insight:** The planner should prove release readiness at the same boundaries adopters experience: CI jobs, PostgreSQL-backed demo tests, Hex artifact contents, and fresh consumer dependency resolution. [VERIFIED: local command]

## Common Pitfalls

### Pitfall 1: Optional Deps Compile in Root But Fail Downstream
**What goes wrong:** Root compile can pass while a fresh app fails on `Plug.Router` from `Paddle.MockServer`. [VERIFIED: local command]
**Why it happens:** Optional deps are included in the current project but not forced on downstream projects. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]
**How to avoid:** Make `Paddle.MockServer` compile only when `plug`/`bandit` are present, or split it behind a module/file arrangement that does not compile in core consumers. [VERIFIED: local command]
**Warning signs:** Fresh consumer `mix compile` reports `module Plug.Router is not loaded`. [VERIFIED: local command]

### Pitfall 2: CI Demo Uses Local-Fix Alias
**What goes wrong:** CI mutates formatting or hides the exact failing command. [VERIFIED: codebase grep]
**Why it happens:** `demo/mix.exs` `precommit` uses `format`, not `format --check-formatted`. [VERIFIED: codebase grep]
**How to avoid:** Use explicit `mix format --check-formatted`, `mix deps.unlock --check-unused`, `mix compile --warnings-as-errors`, and `mix test`. [VERIFIED: CONTEXT.md]
**Warning signs:** CI step says `mix precommit` instead of a specific check-mode command. [VERIFIED: CONTEXT.md]

### Pitfall 3: PostgreSQL Host Mismatch
**What goes wrong:** Demo tests connect to local default host while the service is only available under a different hostname/port. [CITED: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers]
**Why it happens:** GitHub service networking differs between container jobs and runner jobs. [CITED: https://docs.github.com/actions/tutorials/use-containerized-services/use-docker-service-containers]
**How to avoid:** For runner jobs, map `5432:5432` and set `DB_HOST=localhost`; `demo/config/test.exs` already reads `DB_HOST`. [VERIFIED: codebase grep]
**Warning signs:** Ecto create/migrate cannot reach `localhost:5432` or service health is not checked. [VERIFIED: codebase grep]

## Code Examples

### Fresh Consumer Module
```elixir
# Source: local probe, package identity from README/mix.exs [VERIFIED: local command]
defmodule OarlockConsumerProof.UsePaddle do
  def client_module, do: Paddle.Client
  def webhook_module, do: Paddle.Webhooks
  def resource_module, do: Paddle.Customers
end
```

### Consumer Dependency Shape
```elixir
# Source: README package identity and local unpacked artifact [VERIFIED: codebase grep]
defp deps do
  [
    {:paddle, path: System.fetch_env!("OARLOCK_UNPACKED_PATH")}
  ]
end
```

### Positive MockServer Lane
```bash
# Source: existing local test command [VERIFIED: local command]
MIX_ENV=test mix test test/paddle/mock_server_test.exs
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Release-only proof | PR/push CI proof in existing workflow | Locked for Phase 28 on 2026-06-24 | Keeps release readiness contributor-facing. [VERIFIED: CONTEXT.md] |
| Repo path smoke | Hex build/unpack smoke | Locked for Phase 28 on 2026-06-24 | Exercises real package contents. [VERIFIED: CONTEXT.md] |
| Root-only optional dependency reasoning | Fresh consumer no-optional proof plus positive MockServer proof | Mix docs current as of 2026-06-24 | Matches adopter dependency behavior. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |

**Deprecated/outdated:**
- `demo` `precommit` as CI gate: use explicit check-mode commands instead. [VERIFIED: codebase grep]
- Custom packaging simulations: use Hex artifact tooling instead. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html]

## Assumptions Log

All claims in this research were verified by codebase inspection, local command probes, or cited official docs except the implementation choice between gating vs splitting `Paddle.MockServer`, which remains a planner design decision. [VERIFIED: codebase grep]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Gating or splitting `Paddle.MockServer` are likely viable fixes. [ASSUMED] | Summary / Pitfalls | Planner may need to spike the exact Elixir conditional compilation pattern. |

## Open Questions (RESOLVED)

1. **Should `Paddle.MockServer` stay in the published package?**
   - What we know: It is currently included by `package.files` through `lib` and the unpacked artifact includes it. [VERIFIED: local command]
   - RESOLVED outcome: `Paddle.MockServer` stays available in the published package, per D-13 and D-15, but optional `plug` and `bandit` compile requirements must be isolated so fresh package consumers without those deps can compile unless they use MockServer. Plan 28-01 implements the source/docs boundary first; Plan 28-02 proves the negative fresh-consumer compile lane through the Hex artifact smoke and the positive MockServer lane with optional deps available. [VERIFIED: plan review]

2. **Should demo asset proof be included?**
   - What we know: Phase context says asset proof is optional/path-filtered or follow-up unless asset path is release-readiness risk. [VERIFIED: CONTEXT.md]
   - RESOLVED outcome: Dedicated asset proof is intentionally excluded from Phase 28 unless implementation exposes asset risk. Demo proof remains `cd demo && mix test` with a GitHub Actions PostgreSQL service plus the CI-safe demo quality gates from D-05 and D-06. [VERIFIED: plan review]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | local probes / Mix commands | yes | 1.19.5 | GitHub CI uses `.tool-versions`. [VERIFIED: local command] |
| Erlang/OTP | local probes / Mix commands | yes | OTP 28 | GitHub CI uses `.tool-versions`. [VERIFIED: local command] |
| Mix | package/demo/test commands | yes | 1.19.5 | none needed. [VERIFIED: local command] |
| Hex archive | package build/unpack | yes | 2.4.2 | `mix local.hex --force` in CI. [VERIFIED: local command] |
| PostgreSQL client | local DB diagnostics | yes | psql 14.17 | CI service container does not require local psql for Mix/Ecto tests. [VERIFIED: local command] |
| Docker | GitHub service-container model / local fallback | yes | 29.5.2 | GitHub-hosted Ubuntu runner provides service containers. [VERIFIED: local command] |
| GitHub CLI | optional workflow inspection | yes | 2.95.0 | not required. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none found for research. [VERIFIED: local command]
**Missing dependencies with fallback:** Context7 CLI/MCP unavailable; official docs were fetched through web search and cached via GSD research store. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix for root and demo. [VERIFIED: codebase grep] |
| Config file | root `test/test_helper.exs`, demo `demo/test/test_helper.exs`, demo `demo/config/test.exs`. [VERIFIED: codebase grep] |
| Quick run command | `MIX_ENV=test mix test test/paddle/mock_server_test.exs` for positive MockServer lane. [VERIFIED: local command] |
| Full suite command | `mix test` at root; `cd demo && mix test` with PostgreSQL available. [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PROOF-01 | Root release gates remain in CI | CI/static | existing `.github/workflows/ci.yml` root `test` and `dialyzer` jobs | yes [VERIFIED: codebase grep] |
| PROOF-02 | Demo tests run with PostgreSQL | CI/integration | `cd demo && mix test` with `services.postgres` and `DB_HOST=localhost` | yes, CI job missing [VERIFIED: codebase grep] |
| PROOF-03 | Fresh consumer compiles unpacked package | CI/smoke | `mix hex.build --unpack` then temp `mix new` and `mix compile --warnings-as-errors` | no script/job yet [VERIFIED: local command] |
| PROOF-04 | Optional deps positive and negative behavior | CI/smoke + unit | negative fresh consumer compile; positive `MIX_ENV=test mix test test/paddle/mock_server_test.exs` | positive exists; negative missing [VERIFIED: local command] |

### Sampling Rate
- **Per task commit:** Run the most specific command for the touched surface: root test, demo test with local Postgres, or package smoke. [VERIFIED: codebase grep]
- **Per wave merge:** Run root `mix test`, root `mix dialyzer`, demo test with PostgreSQL, and package smoke. [VERIFIED: codebase grep]
- **Phase gate:** Full CI-equivalent commands green before verification. [VERIFIED: CONTEXT.md]

### Wave 0 Gaps
- [ ] `.github/workflows/ci.yml` demo job with PostgreSQL service. [VERIFIED: codebase grep]
- [ ] Package smoke job or `bin/package_smoke.sh` helper. [VERIFIED: codebase grep]
- [ ] Optional-dependency negative proof after `Paddle.MockServer` compile boundary is fixed. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase does not add auth behavior; live Paddle credentials remain out of scope. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | Phase does not add session behavior. [VERIFIED: CONTEXT.md] |
| V4 Access Control | no | Phase changes CI/package proof only. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Preserve existing tests and compile gates; no new untrusted input parser should be added to core. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase should not alter webhook cryptography. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for CI/Package Proof

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply-chain drift through unpinned actions | Tampering | Preserve existing pinned action SHAs. [VERIFIED: codebase grep] |
| Accidental secret exposure in live provider tests | Information Disclosure | Do not add live Paddle sandbox CI in Phase 28. [VERIFIED: CONTEXT.md] |
| Package artifact omits required source/docs | Tampering | Use `mix hex.build --unpack` instead of manual copy. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] |
| Optional dependency contamination | Denial of Service | Fresh consumer compile without `plug`/`bandit`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |

## Sources

### Primary (HIGH confidence)
- Codebase inspection of `.github/workflows/ci.yml`, `mix.exs`, `demo/mix.exs`, `demo/config/test.exs`, `demo/test/test_helper.exs`, `lib/paddle/mock_server.ex`, and tests. [VERIFIED: codebase grep]
- Local command probes: `mix hex.build --unpack`, fresh consumer compile, root no-optional compile, and focused MockServer tests. [VERIFIED: local command]

### Secondary (MEDIUM confidence)
- GitHub Actions PostgreSQL service container docs: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers
- GitHub Actions service container networking docs: https://docs.github.com/actions/tutorials/use-containerized-services/use-docker-service-containers
- `erlef/setup-beam` README: https://github.com/erlef/setup-beam
- Mix deps docs: https://hexdocs.pm/mix/Mix.Tasks.Deps.html
- Mix compile docs: https://hexdocs.pm/mix/Mix.Tasks.Compile.html
- Hex build docs: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html
- Hex publish/package metadata docs: https://hex.pm/docs/publish
- Dialyxir GitHub Actions docs: https://hexdocs.pm/dialyxir/github_actions.html

### Tertiary (LOW confidence)
- None used as authoritative findings; Context7 was unavailable and official docs were fetched through web search. [VERIFIED: local command]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - derived from checked-in workflow, lockfiles, `.tool-versions`, and local version commands. [VERIFIED: codebase grep]
- Architecture: HIGH - phase decisions are locked and current workflow shape is known. [VERIFIED: CONTEXT.md]
- Pitfalls: HIGH - optional dependency failure reproduced in a fresh consumer and demo alias issue verified in `demo/mix.exs`. [VERIFIED: local command]
- External docs: MEDIUM - fetched from official docs through web search because Context7 tools/CLI were unavailable. [CITED: https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers]

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 for repo-local findings; re-check external action and Hex/Mix docs before changing pinned tool versions. [ASSUMED]
