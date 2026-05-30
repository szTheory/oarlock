# Phase 11: type-safety-pass - Research

**Researched:** 2026-05-30  
**Domain:** Elixir typespec coverage + Dialyxir CI enforcement for oarlock public SDK seam  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `11-CONTEXT.md` per workflow requirement. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]

### Public typespec vocabulary

- **D-01:** Use balanced public contract types. Specs should be precise where oarlock owns the seam and intentionally permissive where Paddle owns the data shape.
- **D-02:** Public structs should expose `@type t :: %__MODULE__{...}` with field types. Do not mark core response structs `@opaque`; caller pattern matching, ElixirLS autocomplete, and guide examples are part of the intended SDK experience.
- **D-03:** Use resource-local public aliases where they clarify the seam: examples include `customer_id()`, `address_id()`, `transaction_id()`, `subscription_id()`, `request_opt()`, `pause_opt()`, and `resume_opt()`.
- **D-04:** ID aliases should be `String.t()`, not branded opaque string types. Runtime validators already enforce non-empty IDs where needed; Dialyzer cannot prove provider ID formats from plain binaries without brittle ceremony.
- **D-05:** Option specs must encode the locked public vocabulary:
  - Create/start-flow calls may accept `{:idempotency_key, String.t()}` and `{:retry, boolean()}`.
  - Pause/resume calls may accept lifecycle opts plus `{:retry, boolean()}` only.
  - `idempotency_key:` remains rejected for pause/resume and must not appear in their option specs.
- **D-06:** Public function return specs should spell out tagged results and known local validation atoms, for example `{:ok, Paddle.Subscription.t()} | {:error, Paddle.Error.t() | :invalid_subscription_id | :invalid_resume_at | :invalid_on_resume}`.
- **D-07:** Specs should not overfit all Paddle enum strings or full provider payload schemas. Keep fields such as `raw_data`, metadata maps, custom data, webhook event data, and unknown provider expansions broad enough to preserve forward compatibility.
- **D-08:** Lazy pagination helpers should spec as `Enumerable.t()`. Later-page failures that raise during enumeration belong in docs/tests, not in the return type, because Elixir typespecs do not model raised exceptions as return values.
- **D-09:** Internal helpers may use `@typep` and broader private specs. Do not create public abstractions or command structs merely to make Dialyzer output look more static.
- **D-10:** Keep local validation/error atoms stable enough for specs and tests, but do not introduce a global error-atom registry unless the planner finds repeated duplication that genuinely obscures the contracts.

### Dialyzer and CI enforcement

- **D-11:** Add `:dialyxir` as a dev/test-only dependency and configure `mix dialyzer` as a required Phase 11 verification command.
- **D-12:** Commit `.dialyzer_ignore.exs` with an empty list (`[]`). The Phase 11 baseline must be clean; do not land suppressions to make the pass appear green.
- **D-13:** Configure PLTs under `priv/plts`, using Dialyxir project/core PLT settings so the CI cache can target a stable path independent of unrelated `_build` churn.
- **D-14:** Add a dedicated `dialyzer` CI job rather than appending Dialyzer to the existing `mix test` job. Static-analysis failures should be clearly attributed, and PLT caching should not be coupled to the normal compile/test cache.
- **D-15:** Cache Dialyzer PLTs in CI using a key that includes OS, Elixir/OTP versions from `.tool-versions`, and `mix.lock`. The first cold build can be slower; subsequent runs should be predictable.
- **D-16:** Run the Dialyzer gate against the project's current `.tool-versions` baseline in Phase 11. Do not add a broad Elixir/OTP type-check matrix unless a later release policy explicitly promises cross-version type compatibility.
- **D-17:** Do not use `--ignore-exit-status`, non-blocking CI, or warning suppressions for the baseline. The phase goal is to fail here, not to collect advisory output.
- **D-18:** Add a reusable Mix task, preferably `mix typecheck.specs`, that mechanically verifies every public `def` in the intended public surface has a preceding `@spec`.
- **D-19:** The public-spec coverage check should be a Mix task, not ExUnit, shell-only grep, or Credo. It is a developer tool and CI gate with project-specific rules, and it should be easy to run locally before pushing.
- **D-20:** The coverage check should exclude sealed internal modules with `@moduledoc false` only when they are not part of the public seam. If a sealed module still has public functions used only internally, planner may choose whether to spec them, but the ROADMAP success criterion is public functions across `lib/paddle/`; do not silently skip public resource modules.

### Ecosystem and DX stance

- **D-21:** Follow the Elixir ecosystem's least-surprise pattern: explicit `@type t`, opts-last keyword lists, tagged tuple returns for eager calls, and clear exception behavior for lazy streams.
- **D-22:** Learn from mature libraries without copying their complexity. Ecto and Plug use typed structs, callbacks, and explicit option types where they aid callers, but they do not attempt to statically encode every runtime value. Stripe-style SDKs show the value of stable error/resource shapes plus raw provider escape hatches.
- **D-23:** Preserve oarlock's brand promise: typed resources, verified webhooks, clean errors, pagination helpers, and no app-level opinions. Phase 11 should make those contracts clearer to tools and humans, not widen the product.

### the agent's Discretion

Copied verbatim from `11-CONTEXT.md` per workflow requirement. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]

- Exact module placement for shared aliases, if any. Prefer colocated module-local aliases unless repetition becomes noisy.
- Exact field types for volatile provider payloads, as long as the public seam stays useful and forward-compatible.
- Exact AST implementation of `mix typecheck.specs`, as long as it is deterministic, formatter-friendly, and reports actionable file/function failures.
- Exact CI cache stanza shape, as long as it isolates Dialyzer PLTs and keeps the job required.
- Whether to spec hidden internal modules opportunistically for Dialyzer quality, even if the mechanical public-spec gate excludes them.

### Deferred Ideas (OUT OF SCOPE)

Copied verbatim from `11-CONTEXT.md` per workflow requirement. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]

- Broad Elixir/OTP Dialyzer matrix - defer until release policy requires cross-version type compatibility.
- Credo adoption or custom Credo check - separate quality-tooling decision; not needed for Phase 11.
- OpenAPI-generated specs or schema validation - useful future conformance work, but too broad for this type-safety pass.
- Documentation examples for every public function - Phase 12 owns docs completeness.
- Public request/command structs for mutation attrs/options - rejected for Phase 11 unless future API growth proves keyword opts are no longer clear.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TYPES-01 | Add `@spec` annotations to every public function across `lib/paddle/` (including Phase 10 additions). [VERIFIED: `.planning/REQUIREMENTS.md`] | Use a project Mix task (`mix typecheck.specs`) that parses modules/functions and asserts each public `def` has an immediately preceding `@spec`, excluding only sealed `@moduledoc false` internals by explicit rule. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`; CITED: https://mix.hexdocs.pm/Mix.Task.html] |
| TYPES-02 | Wire `:dialyxir` with PLT cache config, empty ignore baseline, and CI gate. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add Dialyxir config in `mix.exs`, commit `[]` in `.dialyzer_ignore.exs`, add dedicated CI job with `priv/plts` cache keyed by OS + OTP + Elixir + `mix.lock`. [CITED: https://dialyxir.hexdocs.pm/readme.html; CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
</phase_requirements>

## Summary

Phase 11 is a hardening pass, not a feature phase: the key planning target is deterministic static checks on the existing public seam so type drift fails in CI, not after release. The current repository has many public `def` functions in `lib/paddle/**` and currently no Dialyxir dependency or dialyzer CI job, so this phase should be planned as additive enforcement with zero behavior changes. [VERIFIED: `lib/paddle/**/*.ex` function scan; VERIFIED: `mix.exs`; VERIFIED: `.github/workflows/ci.yml`]

Dialyxir’s official CI guidance directly matches the phase goals: keep PLTs in `priv/plts`, cache them with runtime/version-aware keys, and split cache restore/save so cache persistence is not lost when analysis fails. The phase’s empty-ignore baseline is compatible with Dialyxir’s `.dialyzer_ignore.exs` term format and default lookup behavior. [CITED: https://dialyxir.hexdocs.pm/readme.html; CITED: https://hexdocs.pm/dialyxir/github_actions.html]

The highest planning risk is false positives and churn from an undisciplined spec sweep. Planning should enforce: spec public API first, keep provider-owned payloads broad, avoid `@opaque` on core response structs, and keep options/return contracts aligned with locked Phase 8/10 vocabularies. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`; CITED: https://elixir.hexdocs.pm/1.15/typespecs.html]

**Primary recommendation:** Plan this phase in two slices: (1) public specs + mechanical coverage gate, (2) Dialyxir baseline + dedicated CI job + PLT cache tuning. [VERIFIED: `.planning/STATE.md`; VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]

## Project Constraints (from AGENTS.md)

- `AGENTS.md` is not present in project root, so no additional project-local directives were found. [VERIFIED: filesystem check]
- No project-local `.codex/skills/` or `.agents/skills/` directories were found in this repo, so no extra skill rules are required for this phase output. [VERIFIED: filesystem check]
- `.planning/config.json` sets `workflow.nyquist_validation` to `false`; the Validation Architecture section is intentionally omitted. [VERIFIED: `.planning/config.json`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public function spec coverage (`@spec`) | API / Backend | — | Specs describe SDK API contracts on public Elixir modules under `lib/paddle/`. [VERIFIED: `lib/paddle/**/*.ex`] |
| Mechanical spec-coverage gate (`mix typecheck.specs`) | API / Backend tooling | CI/CD | Mix tasks are backend tooling and run locally/CI as static checks. [CITED: https://mix.hexdocs.pm/Mix.Task.html] |
| Dialyzer static analysis baseline | API / Backend tooling | CI/CD | Dialyxir analyzes BEAM/typespec consistency for project code and deps. [CITED: https://dialyxir.hexdocs.pm/readme.html] |
| PLT lifecycle/cache strategy | CI/CD | API / Backend tooling | PLT path and cache keys are a CI performance/reliability responsibility. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Public seam drift prevention for Accrue | CI/CD | API / Backend | Required gate runs in CI but enforces API boundary decisions in code. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dialyxir` | `1.4.7` (released 2025-11-06) | `mix dialyzer` tasking + CI integration | Official Elixir ecosystem wrapper for Dialyzer with PLT/cache/ignore support. [VERIFIED: Hex.pm via `mix hex.info dialyxir`; CITED: https://dialyxir.hexdocs.pm/readme.html] |
| Elixir typespecs (`@spec`, `@type`, `@typep`) | Language built-in (project uses Elixir `1.19.5`) | Machine-readable public contracts | Official notation used by Dialyzer and ExDoc-visible API docs. [VERIFIED: `elixir --version`; CITED: https://elixir.hexdocs.pm/1.15/typespecs.html] |
| Mix task framework (`Mix.Task`) | Language built-in | Implement `mix typecheck.specs` gate | Standard place to define deterministic project checks. [CITED: https://mix.hexdocs.pm/Mix.Task.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `actions/cache` (`restore` + `save`) | `v3` in Dialyxir example docs | Persist `priv/plts` across CI runs | Use dedicated restore/save for PLT cache so failures don’t drop new cache writes. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| `erlef/setup-beam` | Existing repo standard | Resolve OTP/Elixir versions from `.tool-versions` in CI | Keep Dialyzer runtime consistent with local baseline. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `.tool-versions`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Mix-task public-spec checker | ExUnit-only grep assertions | Less deterministic source-level checks; harder function-level diagnostics. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`] |
| Dedicated dialyzer job | Add dialyzer into `mix test` job | Blends failures and couples PLT cache with `_build` cache churn. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`] |
| Empty ignore baseline | Preloaded ignore suppressions | Hides real drift and violates success criteria. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`] |

**Installation:**
```bash
mix deps.add dialyxir --only dev,test
mix deps.get
```

**Version verification:**
```bash
mix hex.info dialyxir
```

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `dialyxir` | Hex.pm | Mature (multiple years; latest 1.4.7 on 2025-11-06) | 166,550 / 7 days | github.com/jeremyjh/dialyxir | N/A for Hex ecosystem in current `slopcheck` tool [ASSUMED] | Approved with manual Hex/docs verification |

**Packages removed due to slopcheck [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

Notes:
- `slopcheck` installed successfully, but this version supports `pypi|npm|crates.io|go|rubygems|maven|packagist` and does not support Hex.pm; no authoritative slopcheck verdict is available for Elixir packages. [VERIFIED: local `python3 -m slopcheck install --help`]
- Because package legitimacy tooling is not Hex-native here, package trust comes from official docs + Hex package metadata, not slopcheck classification. [VERIFIED: `mix hex.info dialyxir`; CITED: https://dialyxir.hexdocs.pm/readme.html]

## Architecture Patterns

### System Architecture Diagram

```text
Developer changes in lib/paddle/*
  -> Adds/updates @spec and @type contracts
    -> mix typecheck.specs (AST/module scan gate)
      -> PASS: all public defs spec'd
      -> FAIL: missing spec report (file/function/arity)
  -> mix dialyzer (Dialyxir)
    -> Uses PLTs at priv/plts/*
      -> CI restore cache by OS+OTP+Elixir+mix.lock
        -> build PLTs on miss
          -> run dialyzer
            -> PASS: merge allowed
            -> FAIL: CI gate blocks drift
```

### Recommended Project Structure
```text
lib/
├── mix/tasks/
│   └── typecheck.specs.ex   # public-function @spec coverage task
└── paddle/
    ├── *.ex                 # public structs and resources with @type/@spec
    └── **/*.ex              # nested public modules similarly covered

.dialyzer_ignore.exs         # [] baseline
mix.exs                      # dialyzer config + dependency
.github/workflows/ci.yml     # dedicated dialyzer job + PLT cache
```

### Pattern 1: Public-First Typespec Coverage
**What:** Spec every public function and public struct type in `lib/paddle/**`; private helper specs are secondary. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]  
**When to use:** SDK seam hardening where consumer correctness and drift detection matter more than full internal annotation. [VERIFIED: phase goal in `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]  
**Example:**
```elixir
# Source: locked decisions in 11-CONTEXT + Elixir typespecs docs
@type subscription_id :: String.t()
@type resume_opt ::
        {:effective_from, :immediately | DateTime.t() | String.t()}
        | {:on_resume, :start_new_billing_period | :continue_existing_billing_period | String.t()}
        | {:retry, boolean()}

@spec resume(Paddle.Client.t(), subscription_id(), [resume_opt()]) ::
        {:ok, Paddle.Subscription.t()}
        | {:error, Paddle.Error.t() | :invalid_subscription_id | :invalid_effective_from | :invalid_on_resume}
```

### Pattern 2: CI-Separated Dialyzer Job with PLT Cache
**What:** Dedicated `dialyzer` job with explicit PLT restore/build/save and final `mix dialyzer` gate. [CITED: https://hexdocs.pm/dialyxir/github_actions.html]  
**When to use:** Repositories where static-analysis failures should not be conflated with unit test failures. [VERIFIED: `.planning/phases/11-type-safety-pass/11-CONTEXT.md`]  
**Example:**
```yaml
# Source: Dialyxir GitHub Actions guide, adapted to project workflow
- name: Restore PLT cache
  uses: actions/cache/restore@v3
  with:
    key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
    path: priv/plts

- name: Create PLTs
  if: steps.plt_cache.outputs.cache-hit != 'true'
  run: mix dialyzer --plt

- name: Save PLT cache
  uses: actions/cache/save@v3
  if: steps.plt_cache.outputs.cache-hit != 'true'
  with:
    key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
    path: priv/plts
```

### Anti-Patterns to Avoid
- **Spec overfitting provider payloads:** Avoid literal enum explosions for volatile `raw_data`/metadata payloads; keep seam typed but forward-compatible. [VERIFIED: `11-CONTEXT.md`]
- **Suppressions-first dialyzer adoption:** Starting with non-empty ignore file masks real issues and violates baseline criterion. [VERIFIED: `.planning/REQUIREMENTS.md`; CITED: https://dialyxir.hexdocs.pm/readme.html]
- **CI “advisory” dialyzer mode:** `--ignore-exit-status` defeats the phase’s fail-fast goal. [CITED: https://dialyxir.hexdocs.pm/readme.html; VERIFIED: `11-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BEAM static type/dataflow analysis | Custom AST + type engine | Dialyxir + Dialyzer | Mature ecosystem tooling already solves PLT management/warnings formatting/CI flow. [CITED: https://dialyxir.hexdocs.pm/readme.html] |
| CI cache orchestration semantics | Homegrown artifact scripts | `actions/cache/restore` + `actions/cache/save` pattern from Dialyxir guide | Handles failure-safe cache persistence cleanly. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Public spec presence enforcement | Ad-hoc shell regex only | `Mix.Task` that parses modules and reports per-function misses | More reliable than line-based grep and easier for local dev/CI integration. [CITED: https://mix.hexdocs.pm/Mix.Task.html] |

**Key insight:** This phase should assemble standard Elixir tooling, not invent new type systems or bespoke CI analyzers. [VERIFIED: phase scope]

## Common Pitfalls

### Pitfall 1: Missing Specs on Default-Argument Heads
**What goes wrong:** Only one clause gets `@spec` while public default-arg wrappers are missed.  
**Why it happens:** Mechanical checks that don’t normalize arity/heads correctly.  
**How to avoid:** In `mix typecheck.specs`, map public `def` names/arity after default expansion rules and enforce one visible `@spec` per public function signature. [ASSUMED]  
**Warning signs:** Gate passes but docs still show unspecced public functions.

### Pitfall 2: Dialyzer Runtime Drift in CI
**What goes wrong:** PLTs rebuilt frequently or warnings differ between local and CI.  
**Why it happens:** Cache keys miss OTP/Elixir version components.  
**How to avoid:** Include OS + OTP + Elixir + `mix.lock` in PLT key. [CITED: https://hexdocs.pm/dialyxir/github_actions.html]  
**Warning signs:** Repeated cold PLT builds on unchanged deps.

### Pitfall 3: Over-precise Specs for Provider-owned JSON
**What goes wrong:** Frequent spec churn and false warnings when Paddle payload shape evolves.  
**Why it happens:** Encoding full external schema into local typespecs.  
**How to avoid:** Keep typed core fields; leave expansion payloads broad (`map()`/`term()`) where ownership is external. [VERIFIED: `11-CONTEXT.md`]  
**Warning signs:** Tiny upstream payload changes require broad local type rewrites.

## Code Examples

Verified patterns from official sources:

### Dialyxir Project Config (PLT + ignore baseline)
```elixir
# Source: https://dialyxir.hexdocs.pm/readme.html
def project do
  [
    dialyzer: [
      plt_file: {:no_warn, "priv/plts/project.plt"},
      plt_core_path: "priv/plts/core.plt",
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_add_apps: []
    ]
  ]
end
```

### Empty ignore baseline
```elixir
# Source: phase lock + Dialyxir ignore file format
[]
```

### Mix task skeleton
```elixir
# Source: https://mix.hexdocs.pm/Mix.Task.html
defmodule Mix.Tasks.Typecheck.Specs do
  use Mix.Task

  @shortdoc "Fails when public defs in lib/paddle are missing @spec"

  @impl Mix.Task
  def run(_args) do
    # Implementation scans project modules and exits non-zero on missing specs.
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat dialyzer as optional local hygiene | CI-required dialyzer gate with cache-aware PLT strategy | Current Dialyxir CI guidance (v1.4.x docs) | Fails drift pre-merge and keeps CI costs predictable. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Using typespecs as “compiler enforcement” | Typespecs as docs + tooling contracts (Dialyzer/ExDoc), with dynamic runtime semantics unchanged | Longstanding Elixir docs position; still current in 1.15/1.19 docs | Encourages pragmatic type contracts over static-language mimicry. [CITED: https://elixir.hexdocs.pm/1.15/typespecs.html; CITED: https://hexdocs.pm/elixir/1.19.0-rc.0/typespecs.html] |

**Deprecated/outdated:**
- Treating `string()` as Elixir UTF-8 string type is outdated; use `String.t()` for clarity. [CITED: https://elixir.hexdocs.pm/1.15/typespecs.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix typecheck.specs` should normalize default-arg heads/arity in a specific way; exact algorithm is not directly specified in official docs. | Common Pitfalls | Could produce false positives/negatives in coverage gate implementation. |
| A2 | `slopcheck` has no Hex.pm ecosystem support in current version and cannot produce authoritative verdicts for Elixir packages. | Package Legitimacy Audit | Package legitimacy process may need an alternative Hex-native checker later. |

## Open Questions

1. **How strict should the public-spec gate be for sealed-but-public utility modules?**
   - What we know: `@moduledoc false` modules may be excluded only when not part of public seam. [VERIFIED: `11-CONTEXT.md`]
   - What's unclear: Whether any currently sealed modules under `lib/paddle/` still need enforced specs for Phase 11 success.
   - Recommendation: Planner should add an explicit module allowlist/denylist decision in Wave 0 of implementation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Typespec compilation + Mix task + Dialyzer run | ✓ | 1.19.5 | — |
| Erlang/OTP | Dialyzer runtime + PLT generation | ✓ | 28 | — |
| Mix | `mix dialyzer` / custom task execution | ✓ | 1.19.5 | — |
| GitHub Actions workflow support | CI gate deployment | ✓ (repo workflow exists) | actions-based | Local `mix dialyzer` gate until CI merge |
| Hex package registry access | Installing `dialyxir` | ✓ | reachable via `mix hex.info` | none practical |

**Missing dependencies with no fallback:**
- None identified.

**Missing dependencies with fallback:**
- None identified.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (no auth-surface changes this phase) |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | Validate IDs/opts at API boundary and reflect in specs (`:invalid_*` atoms). [VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `11-CONTEXT.md`] |
| V6 Cryptography | no | Existing webhook HMAC logic unchanged this phase. [VERIFIED: `lib/paddle/webhooks.ex`] |

### Known Threat Patterns for Elixir SDK Static-Analysis Gates

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CI bypass of static checks | Tampering | Required dialyzer job in branch protection, no advisory mode. [VERIFIED: phase criteria; CITED: https://dialyxir.hexdocs.pm/readme.html] |
| Silent contract drift | Repudiation/Tampering | Mechanical spec-coverage task + dialyzer fail gate on every PR. [VERIFIED: `11-CONTEXT.md`] |
| Unsafe warning suppression | Tampering | Empty `.dialyzer_ignore.exs` baseline; require explicit review for any future additions. [VERIFIED: `11-CONTEXT.md`; CITED: https://dialyxir.hexdocs.pm/readme.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/11-type-safety-pass/11-CONTEXT.md` - locked implementation decisions, constraints, deferred scope.
- `.planning/REQUIREMENTS.md` - TYPES-01/TYPES-02 requirement text.
- `.planning/STATE.md` - current phase readiness and sequencing.
- `mix.exs`, `.github/workflows/ci.yml`, `.tool-versions`, `lib/paddle/**/*.ex` - current implementation and CI baseline.
- https://dialyxir.hexdocs.pm/readme.html - install/config, PLT/ignore behavior, CI considerations.
- https://hexdocs.pm/dialyxir/github_actions.html - recommended GitHub Actions cache/job pattern.
- https://elixir.hexdocs.pm/1.15/typespecs.html - `@type/@typep/@opaque/@spec` semantics, keyword option typing, raise semantics.
- https://mix.hexdocs.pm/Mix.Task.html - standard Mix task mechanics.

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/elixir/1.19.0-rc.0/typespecs.html - current-generation framing of typespecs vs set-theoretic types.

### Tertiary (LOW confidence)
- none.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - based on official HexDocs + direct registry query (`mix hex.info dialyxir`).
- Architecture: HIGH - directly constrained by locked CONTEXT decisions and current repo structure.
- Pitfalls: MEDIUM - most are verified from docs/context; one implementation-detail pitfall is assumption-tagged.

**Research date:** 2026-05-30  
**Valid until:** 2026-06-29
