# Phase 28: CI, Demo, and Package Proof - Context

**Gathered:** 2026-06-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Continuously prove release readiness for the root SDK, the Phoenix demo, fresh downstream package consumption, and the optional `plug`/`bandit` boundary around `Paddle.MockServer`. This phase strengthens CI and package proof only. It does not add new Paddle API breadth, live Paddle sandbox CI, production demo deployment certification, Phoenix/Ecto coupling in the core SDK, or GSD state reconciliation.

</domain>

<decisions>
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

### Claude's Discretion
- The planner may choose whether optional dependency proof lives as a separate job or as a named step inside the downstream smoke job, as long as both the positive MockServer lane and negative no-optional-deps lane are executable.
- The planner may factor repeated GitHub Actions setup through anchors, scripts, or direct YAML, whichever keeps the workflow easiest to maintain in this repo.
- The planner may include an asset smoke only if code inspection shows the demo's Phoenix asset path is likely to regress release readiness; otherwise keep it deferred.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 28 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — PROOF-01 through PROOF-04 requirements and out-of-scope boundary for live Paddle sandbox mandatory CI.
- `.planning/PROJECT.md` — Current milestone goal, pure SDK constraints, and adopter-truth positioning.
- `.planning/STATE.md` — Current project state and known blocker that demo proof is not yet fully wired into CI.

### Prior Decisions To Carry Forward
- `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md` — Proof ladder, docs truth, MockServer/sandbox/live boundary, and Phase 28 deferral.
- `.planning/phases/26-advanced-subscription-flows-e2e/26-CONTEXT.md` — MockServer as default deterministic proof; real sandbox checks on demand.
- `.planning/phases/19-notification-settings-api/19-CONTEXT.md` — Provider-native, pass-through, minimal-surface API philosophy.

### Existing CI, Package, and Demo Files
- `.github/workflows/ci.yml` — Existing root library and Dialyzer CI gates to preserve and extend with named jobs.
- `.github/workflows/hex-publish.yml` — Existing publish workflow; useful for avoiding duplicate or conflicting release proof.
- `.github/workflows/release-please.yml` — Existing release automation; do not create split-brain release proof without reason.
- `mix.exs` — Package metadata, `package.files`, optional `plug`/`bandit` deps, Dialyzer config, and root aliases.
- `demo/mix.exs` — Phoenix demo dependencies, aliases, path dependency on the root SDK, and current local `precommit` behavior.
- `demo/config/test.exs` — Demo test database and Phoenix test configuration.
- `demo/test/test_helper.exs` — MockServer startup behavior in demo tests.
- `demo/test/demo_web/integration/billing_flow_test.exs` — Existing MockServer-backed demo integration proof.
- `lib/paddle/mock_server.ex` — Optional Plug/Bandit fixture with compile-time optional dependency risk.
- `test/paddle/mock_server_test.exs` — Existing positive MockServer behavior proof.
- `bin/check_summary_drift.sh` — Existing SUMMARY drift guard required by PROOF-01.

### Prompt and Research Context
- `prompts/oarlock-brand-book.md` — Preferred voice and positioning: steady, provider-native, explicit, honest, no official-Paddle implication. Use for docs wording if touched.
- `prompts/oarlock-master-context.md` — Core SDK DNA: explicit client passing, typed responses, CI/CD excellence, secure webhooks, no framework coupling.
- `prompts/paddle-elixir-lib-deep-research.md` — Prior research on Paddle Billing, Hex package posture, webhook raw-body rules, and strong CI/release expectations.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` — Accrue-oriented SDK boundary and proof strategy.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` — Strategic rationale for a thin provider-native Paddle SDK rather than an app framework.

### External Primary References
- `https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers` — GitHub Actions PostgreSQL service container pattern.
- `https://hexdocs.pm/mix/1.18.1/Mix.Tasks.Deps.html` — Mix optional dependency semantics and `--no-optional-deps --warnings-as-errors` guidance.
- `https://hex.pm/docs/publish` — Hex publishing metadata and package `:files` behavior.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html` — Hex package fetch/diff behavior; useful context for artifact-oriented package proof.
- `https://hexdocs.pm/dialyxir/github_actions.html` — Dialyzer GitHub Actions cache and output guidance.
- `https://github.com/erlef/setup-beam` — BEAM version setup used by current CI.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml`: Already has root `test` and `dialyzer` jobs covering format, unused deps, warnings-as-errors compile, tests, public specs, Dialyzer, and SUMMARY drift.
- `erlef/setup-beam` with `.tool-versions`: Existing strict BEAM setup pattern should be reused for all new jobs.
- `demo/mix.exs`: Contains demo aliases and dependencies needed for a Phoenix/Ecto/Postgres CI lane.
- `demo/test/test_helper.exs`: Starts `Paddle.MockServer`, so the demo CI lane also functions as a positive optional-dependency proof when demo deps are present.
- `mix.exs` package metadata: Provides the `package.files` boundary that the downstream smoke test must prove through Hex build/unpack.

### Established Patterns
- Root SDK checks are already split into fast behavior checks and static analysis. Preserve that shape.
- The project prefers deterministic MockServer-backed proof over live provider-state CI.
- Core SDK must remain Phoenix/Ecto-free; Phoenix examples and demo code are allowed outside core.
- Public package identity is `oarlock`, OTP app is `:paddle`, and modules are `Paddle.*`.
- CI should use check-mode commands rather than local developer aliases that mutate files or perform setup intended for a workstation.

### Integration Points
- Add jobs or steps to `.github/workflows/ci.yml`.
- Add focused scripts only if they make the Hex artifact smoke or optional-deps proof clearer than inline YAML.
- Update README/demo docs only as needed to state the `Paddle.MockServer` optional dependency boundary and the CI proof ladder.
- If optional module gating is required, changes will likely touch `lib/paddle/mock_server.ex`, `mix.exs`, and MockServer tests.

</code_context>

<specifics>
## Specific Ideas

The user asked for research-backed, cohesive one-shot recommendations across all gray areas, with emphasis on idiomatic Elixir/Phoenix/Mix/Hex practice, lessons from other ecosystems, strong developer experience, principle of least surprise, and keeping every decision aligned with the project vision.

The resulting strategy is one coherent release-readiness posture:
- Regular CI is the truth, not a late release-only workflow.
- Each proof surface gets a named job so failures are legible.
- The demo is treated as adopter-facing evidence, so it gets real Postgres-backed tests and basic quality checks.
- The downstream smoke tests what a real Hex consumer cares about: the built package artifact, not just the repo checkout.
- Optional dependencies are proved both positively and negatively, so `Paddle.MockServer` remains useful without contaminating the core SDK.

</specifics>

<deferred>
## Deferred Ideas

- Mandatory live Paddle sandbox/provider-state CI remains out of scope. It can become a manual, nightly, or release-only workflow in a future phase if credentials, isolation, and state cleanup are solved.
- Production demo deployment, Docker release boot, or full container smoke proof is out of scope unless a later phase decides the demo itself must be certified as deployable software.
- Phoenix/Ecto helper packages, Plug adapters, admin UI, local billing mirrors, and broader Paddle endpoint expansion remain outside Phase 28.
- GSD backlog/state/audit reconciliation belongs to Phase 29.

</deferred>

---

*Phase: 28-CI, Demo, and Package Proof*
*Context gathered: 2026-06-24*
