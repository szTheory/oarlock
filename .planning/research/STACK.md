# Technology Stack

**Project:** oarlock — Paddle Billing SDK for Elixir

**Milestone:** v2.2 Trust, Coverage & Green Delivery

**Researched:** 2026-09-09

**Overall confidence:** MEDIUM — repository observations are direct and HIGH confidence; changing ecosystem facts were checked against primary sources but the configured research seam classifies verified web fallback evidence as MEDIUM.

## Recommendation in One Sentence

Keep the existing Elixir/Req/Mix/GitHub Actions architecture, urgently move off vulnerable Req 0.5.17, add only Credo plus built-in Hex auditing, and encode delivery discipline in pinned workflows, repository-native scripts, templates, rulesets, and provenance-bearing Markdown rather than introducing a new platform.

## Local Baseline and Immediate Risk

| Evidence observed in this repository | Confidence | Implication |
|---|---:|---|
| `mix.exs` requires `{:req, "~> 0.5.17"}` and `mix.lock` resolves 0.5.17. | HIGH | This is not merely stale: Hex lists CVE-2026-49755 (high-severity decompression-bomb DoS, fixed in 0.6.1) and CVE-2026-49756 (multipart header injection, fixed in 0.6.0). Upgrade before other SDK changes. |
| Root quality gates already include formatting, warnings-as-errors, ExUnit, custom public-spec checks, Dialyzer, package smoke, optional-dependency proof, demo/PostgreSQL proof, and a final `CI contract` job. | HIGH | Preserve these proof classes. Improve orchestration and determinism instead of replacing the stack. |
| Checkout, setup-beam, and cache are already pinned to full SHAs; `googleapis/release-please-action@v4` is not. | HIGH | Complete SHA pinning and let Dependabot propose reviewed pin updates. |
| The CI contract writes `ci-contract-proof.json` but does not upload it. Release Please can create a release and publish in a separate workflow without first consuming that exact-SHA proof. | HIGH | Persist proof and add a fail-closed exact-SHA gate before release creation and before Hex credentials are exposed. |
| Jobs use mutable `ubuntu-latest`, mutable `postgres:17`, and unversioned `mix local.hex` / `mix local.rebar`. Most `_build` cache keys omit OTP/Elixir/Mix environment. | HIGH | Pin the runner/tool/service inputs and make compiled caches toolchain- and environment-specific. |
| No `.github/dependabot.yml`, `.github/CODEOWNERS`, or PR template exists. Worktree inspection reports a modified main tree and a locked linked agent worktree. | HIGH | Add lightweight repository-native maintenance controls; classify existing work before any cleanup. |
| `.planning/PROJECT.md` already defines committed/candidate/conditional horizons and provenance expectations. | HIGH | Keep Markdown as the system of record and validate cross-links/status vocabulary in CI; do not add a planning database. |

## Recommended Stack

### Core SDK Runtime

| Technology | Target | Purpose | Why / integration point |
|---|---:|---|---|
| Elixir | retain exact `.tool-versions` value after dirty-state classification (currently 1.19.5-otp-28) | SDK implementation and Mix build | No runtime migration is needed for v2.2. The file is currently modified, so first establish whether these values are intended user work. |
| Erlang/OTP | retain exact `.tool-versions` value after classification (currently 28.1) | BEAM runtime | Existing code and CI are already designed around this pair. Compatibility breadth should be an explicit public-contract decision, not an accidental matrix expansion. |
| Req | **0.7.4 stable** (`~> 0.7.4`) | HTTP client | Upgrade in the first isolated PR. It clears both advisories affecting 0.5.17 and includes authentication redaction and retry improvements. Req 0.7 has breaking internal changes; run the root, MockServer, package-smoke, demo, and Dialyzer suites and adapt function adapters/tests deliberately. |
| telemetry | retain `~> 1.4` (latest observed 1.4.2) | Events and measurements | No extra telemetry package is needed. Fix metadata at `Paddle.Http.Telemetry` so request structs, headers, tokens, bodies, and secrets never enter emitted metadata. |

**Versioning consequence:** Hex requires SemVer and says breaking changes while package major is `0` require a minor bump. If the Req upgrade changes oarlock's supported dependency contract or observable behavior, release it as `0.2.0`; do not confuse that package version with GSD milestone `v2.2`.

### Elixir Quality and Security Tooling

| Technology | Target | Purpose | Why / integration point |
|---|---:|---|---|
| Mix / ExUnit / formatter | bundled with pinned Elixir | Compile, test, format | Keep as the authoritative fast path. Define one local/CI alias such as `mix quality` that runs deterministic gates in documented order; CI jobs may still fan out for wall-clock speed. |
| Credo | **1.7.19** (`~> 1.7`, dev/test only, `runtime: false`) | Static code-quality analysis | The one justified new Mix dependency. Establish a reviewed `.credo.exs` baseline, then gate `mix credo --strict`; avoid mass cosmetic rewrites mixed with safety fixes. |
| Dialyxir | retain **1.4.7** | Type analysis | Already current and integrated. Keep PLTs cached by OS, exact OTP, exact Elixir, and `mix.lock`. |
| ExDoc | upgrade from `~> 0.34` to **`~> 0.40`** (latest observed 0.40.3) | Package documentation | Current constraint holds the project on 0.34. Upgrade separately and make warning-free docs release evidence. |
| Hex client | pin **2.5.1** in automation | Dependency audit and publish | Replace unversioned installation with `mix local.hex 2.5.1 --force`. Run `mix hex.audit` before tasks that load the application; current Hex audits both advisories and retired packages, so no `mix_audit` dependency is needed. |
| rebar3 | pin **3.27.0** in `.tool-versions` | Erlang dependency builds | `erlef/setup-beam` reads a `rebar` entry in strict mode. Remove repeated unversioned `mix local.rebar` steps after the pinned setup is proven. |

Recommended root dependency delta:

```elixir
{:req, "~> 0.7.4"},
{:ex_doc, "~> 0.40", only: :dev, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4.7", only: [:dev, :test], runtime: false}
```

Resolve and commit exact transitive versions in `mix.lock`; requirements remain appropriately ranged for a library.

### CI and Release Infrastructure

| Technology / control | Target | Purpose | Why / integration point |
|---|---:|---|---|
| GitHub-hosted runner | `ubuntu-24.04` | Stable CI image family | Replace `ubuntu-latest` so image-family changes are intentional. Hosted patch images remain mutable, so proof must record runner/tool versions and SHA. |
| `actions/checkout` | retain pinned v6.0.2 SHA | Source checkout | Already follows GitHub's immutable full-SHA guidance. |
| `erlef/setup-beam` | retain pinned v1.24.0 SHA | Exact BEAM/rebar setup | Give each step an `id`, consume exact-version outputs in cache keys/proof, and let it install Hex/Rebar. |
| `actions/cache` | retain pinned v4.3.0 SHA | Dependency/build/PLT caches | Split source dependency cache from compiled `_build`; include job/Mix environment plus exact OTP and Elixir in compiled keys. Never use broad restore keys across incompatible toolchains. |
| `googleapis/release-please-action` | **v5.0.0, SHA `45996ed1f6d02564a971a2fa1b5860e934307cf7`** | Release PR, tag, release | Current mutable `@v4` is the only unpinned `uses:` reference. Upgrade and pin separately because v5 moves the action runtime to Node 24. |
| `actions/upload-artifact` | **v7.0.1, SHA `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`** | Durable CI contract artifact | Add only to the contract job; upload `ci-contract-proof.json` with bounded retention and a SHA-bearing name. Include run URL/ID/attempt, exact tools, job results, and lockfile hash. |
| PostgreSQL service | **17.11**, official image digest resolved during implementation | Deterministic demo proof | Replace mutable `postgres:17`; retain a human-readable tag comment beside the digest. This stays a test fixture. |
| GitHub `hex-production` environment | repository setting | Protect `HEX_API_KEY` | Move the scoped, expiring `api:write` key into an environment secret. Restrict deployments to release tags and optionally require a non-self reviewer. |

### Exact-SHA Release Topology

1. `CI` runs on PRs and pushes to `main`; all proof jobs feed one stable required check named `CI contract`.
2. `CI contract` always runs, fails on failed/skipped dependencies, writes a self-describing proof, uploads it, and emits the same data to `$GITHUB_STEP_SUMMARY`.
3. `Release Please` starts with a credential-free `quality-gate` invoking existing `scripts/ci_monitor.cjs assert-ci --sha "$GITHUB_SHA"` with `actions: read`. `release-please` must `needs: quality-gate` and run only on trusted `main` pushes; manual dispatch must name and prove an explicit SHA.
4. When Release Please creates a tag, resolve it to a commit and assert it equals the proven SHA before `publish-hex` receives the `hex-production` environment or secret.
5. `publish-hex` still builds and dry-runs the package as defense in depth, but a reduced test subset must not substitute for the canonical CI contract.
6. Apply the same monitor and ref-resolution check to `hex-publish.yml`; reduce its workflow permission from `contents: write` to `contents: read` plus `actions: read`.

Configure a `main` ruleset requiring `CI contract`, review, resolved conversations, and no force pushes. Keep write permissions only on the Release Please job; all others stay read-only.

### PR, Triage, Worktree, and Planning Controls

| Control | Implementation | Why |
|---|---|---|
| Dependency maintenance | `.github/dependabot.yml`: weekly grouped updates for `mix` at `/`, `mix` at `/demo`, and `github-actions` at `/`; cap open PRs and retain same-line version comments for action SHAs. | Covers lockfiles and action pins without another bot. Updates still require full CI and review. |
| Ownership | `.github/CODEOWNERS`: maintainer globally plus explicit ownership for `/.github/`, `/mix.exs`, `/mix.lock`, `/lib/paddle/http/`, release config, and planning governance. | Auto-requests reviewers; owning `/.github/` protects CODEOWNERS itself. |
| Small PRs | One `.github/pull_request_template.md` requiring JTBD/requirement link, scope/non-goals, risk, proof results, docs/compatibility/release impact, and clean-worktree evidence. | Preserves signal without a PR management product. |
| Triage | A small label vocabulary (`bug`, `security`, `adopter-request`, `maintenance`, `blocked`, `needs-evidence`); add issue forms only if volume justifies them. Record promotions in `.planning`. | GitHub is intake; `.planning` remains durable orientation. |
| Worktree hygiene | A report-only `bin/check_worktree_hygiene.sh` using `git status --porcelain=v1`, `git worktree list --porcelain`, and `git worktree prune --dry-run --verbose`; document add/remove/repair and lock-with-reason. | Stable Git output is scriptable. Never auto-delete, stash, reset, unlock, or prune user work. |
| Planning provenance | Keep the GSD Markdown artifacts and canonical persona/JTBD ledger. Extend the existing Node/shell drift check to validate IDs, horizon status, source, owner, proof class/link, date, and promotion/reopen condition. | Diffable and already integrated. A no-dependency validator prevents drift without a second source of truth. |

## Explicit Non-Additions

| Do not add now | Reason | Reconsider when |
|---|---|---|
| `mix_audit` | Hex 2.5.1 `mix hex.audit` covers advisories and retirements. A second task duplicates triage. | A documented coverage gap appears. |
| Sobelow in root | It targets Phoenix/web patterns; root is framework-free and its known risks need focused fixes/tests. | Threat-model the demo separately if it becomes a supported deployment. |
| SAST mega-suite, custom CodeQL/Semgrep, or a secret-scanner action | GitHub native protection, Hex audit, Credo, Dialyzer, focused tests, and review address current risks with owners. | A named threat/control gap exists. |
| OpenSSF Scorecard, custom SBOM, or custom artifact attestations | Useful for later public-contract graduation; first establish exact-SHA gating and clean proof. | Consumer/procurement evidence requires them. |
| Merge queue | GitHub recommends it for busy branches with many daily merges; current maintainer-scale traffic does not justify `merge_group` complexity. | Sustained concurrent PR traffic makes update churn measurable. |
| Renovate, Mergify, Graphite, stacked-PR tooling, or worktree manager | Dependabot, rulesets, templates, CODEOWNERS, Git, and `gh` cover current jobs. | Native controls demonstrably fail at actual scale. |
| Dockerized root dev, Nix, Bazel, Earthly, or self-hosted runners | `.tool-versions`, `mix.lock`, pinned actions, and explicit runner/service versions are sufficient. | Evidence shows a concrete reproducibility gap. |
| Planning database, external board, or knowledge graph | The need is durable provenance, not another truth source. | Markdown scale/query needs become empirically unmanageable. |
| Coverage-percentage gate | Percentage rewards incidental execution and can obscure contract gaps. | A risk-based uncovered-code policy and stable baseline exist. |

## Implementation Order

1. **Security dependency repair:** Req 0.7.4, full compatibility proof, then `mix hex.audit`.
2. **Deterministic quality:** pinned Hex/rebar/runner/PostgreSQL, Credo, ExDoc, cache keys, and measured timings.
3. **Exact-SHA delivery:** persisted proof, gated release/publish paths, protected environment, and `main` ruleset.
4. **Repository operations:** Dependabot, CODEOWNERS, PR template, triage vocabulary, and report-only worktree checks.
5. **Durable orientation:** drift validation across persona/JTBD, requirements, evidence, and horizon provenance.

Each should be a small PR or cohesive pair. Do not mix the Req security migration with formatting, release orchestration, or planning rewrites.

## Sources and Provenance

### Repository evidence (HIGH)

- `.planning/PROJECT.md`, `.planning/config.json`, `mix.exs`, `mix.lock`, `.tool-versions`; CI/release workflows; CI monitor/tests; hook installer — inspected 2026-09-09.
- `git status --short --branch` and `git worktree list --porcelain` — point-in-time local evidence from 2026-09-09, not committed truth.

### Primary external guidance (MEDIUM per confidence seam)

- [Req advisories](https://hex.pm/packages/req/advisories) and [Req 0.7.4 changelog](https://github.com/wojtekmach/req/blob/v0.7.4/CHANGELOG.md).
- [Hex audit 2.5.1](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html), [Hex 2.5.1 release](https://github.com/hexpm/hex/releases/tag/v2.5.1), and [Hex publishing](https://hex.pm/docs/publish).
- [Credo 1.7.19](https://hex.pm/packages/credo), [Credo strict usage](https://hexdocs.pm/credo/basic_usage.html), [ExDoc 0.40.3](https://hex.pm/packages/ex_doc), and [Dialyxir 1.4.7](https://hex.pm/packages/dialyxir).
- [setup-beam action definition](https://raw.githubusercontent.com/erlef/setup-beam/fc68ffb90438ef2936bbb3251622353b3dcb2f93/action.yml), [setup-beam README](https://github.com/erlef/setup-beam/blob/main/README.md), and [rebar3 3.27.0](https://github.com/erlang/rebar3/releases/tag/3.27.0).
- [GitHub Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use), [Dependabot for actions](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/auto-update-actions), and [Dependabot ecosystem support](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference).
- [GitHub environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases), and [artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations).
- [Git worktree](https://git-scm.com/docs/git-worktree), [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners), and [PR templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository).
- [PostgreSQL 17.11](https://www.postgresql.org/docs/17/release-17-11.html), [Release Please v5.0.0](https://github.com/googleapis/release-please-action/releases/tag/v5.0.0), and [upload-artifact v7.0.1](https://github.com/actions/upload-artifact/releases/tag/v7.0.1). Action SHAs were cross-checked through official Git refs/API on 2026-09-09.

## Open Questions for Phase Planning

- Confirm whether uncommitted `.tool-versions` values are intentional before treating them as the compatibility baseline.
- Spike Req 0.7.4 against function adapters, custom request steps, MockServer, and Accrue before locking the public requirement and package bump.
- Verify repository visibility/plan before requiring environment reviewers or immutable releases; availability varies.
- Measure hosted CI durations/cache hit rates and optimize the measured critical path rather than collapsing parallel jobs by intuition.
- Resolve and record the official PostgreSQL 17.11 image digest at implementation time.
