# Phase 11: Type-Safety Pass - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Add machine-checked typespec coverage across oarlock's public Elixir SDK surface, then make that coverage enforceable through Dialyzer and CI.

This phase is a safety and developer-experience pass over the existing public surface. It should make Accrue-facing type drift fail inside oarlock before it reaches production, while preserving the project's small, provider-native shape. It does not add new Paddle API resources, change public function behavior, widen request option vocabulary, or turn oarlock into a framework-style integration package.

In scope:
- Add `@spec` annotations to every public function across `lib/paddle/`.
- Add useful `@type` / `@typep` aliases where they clarify public contracts or private implementation boundaries.
- Add Dialyxir, a clean empty-ignore baseline, PLT configuration, and a required CI gate.
- Add a mechanical public-spec coverage check so future public functions cannot land without specs.

Out of scope:
- New Paddle endpoint support, new public helper namespaces, or new runtime behavior.
- Broad OpenAPI code generation or schema validation.
- Credo adoption, documentation examples, README/guides pass, or public module-doc cleanup; those belong to Phase 12 unless required to keep Phase 11 checks green.
- Phoenix, Plug, Ecto, LiveView, database, or app-level integration code.

</domain>

<decisions>
## Implementation Decisions

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

- Exact module placement for shared aliases, if any. Prefer colocated module-local aliases unless repetition becomes noisy.
- Exact field types for volatile provider payloads, as long as the public seam stays useful and forward-compatible.
- Exact AST implementation of `mix typecheck.specs`, as long as it is deterministic, formatter-friendly, and reports actionable file/function failures.
- Exact CI cache stanza shape, as long as it isolates Dialyzer PLTs and keeps the job required.
- Whether to spec hidden internal modules opportunistically for Dialyzer quality, even if the mechanical public-spec gate excludes them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and active requirement

- `.planning/PROJECT.md` - v1.2 production-surface goal, pure SDK constraints, typed resource promise, locked Accrue seam, and no Phoenix/Ecto coupling.
- `.planning/REQUIREMENTS.md` - TYPES-01 and TYPES-02 requirements plus traceability table.
- `.planning/ROADMAP.md` - Phase 11 goal and success criteria, including empty Dialyzer baseline, public spec coverage, CI gate, and PLT cache.
- `.planning/STATE.md` - Current milestone state and Phase 11 readiness.

### Prior phase context

- `.planning/phases/08-reliability-primitives/08-CONTEXT.md` - Locked request option vocabulary, create-only idempotency boundary, normalized `%Paddle.Error{}` shape, and decisive-default preference.
- `.planning/phases/09-pagination-ergonomics-0-plans/09-CONTEXT.md` - Resource-module-first public helpers, `stream/*` lazy raising behavior, `all/*` tagged tuple behavior, and additive seam discipline.
- `.planning/phases/10-subscriptions-surface-completion/10-CONTEXT.md` - Pause/resume option vocabulary, explicit `idempotency_key:` rejection on lifecycle mutations, `%Paddle.Subscription{}` shape preservation, and subscription-start provider truth.

### Prompt corpus and project vision

- `prompts/oarlock-master-context.md` - Core DNA: explicit client passing, typed responses, CI/CD excellence including Dialyzer, secure pure webhooks, and no framework coupling.
- `prompts/paddle-elixir-lib-deep-research.md` - Original SDK research: prefer plain data structs, typespecs, documented params, normalized errors, predictable result tuples, explicit clients, and raw response escape hatches.
- `prompts/oarlock-brand-book.md` - Product voice and DX principles: provider-native, explicit, small, typed resources, clean errors, honest behavior, and developer-respectful docs.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` - Accrue minimum surface and typed/raw provider data needs.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` - Rationale for a serious Paddle SDK with typed resources, verified request/response contracts, webhook parsing, and maintainable long-term evolution.

### Existing code and CI surfaces

- `mix.exs` - Add Dialyxir dependency and `dialyzer:` project configuration; consider adding aliases only if they improve local workflow without hiding commands.
- `.github/workflows/ci.yml` - Add dedicated required Dialyzer/spec-coverage job with PLT cache.
- `.tool-versions` - Source of the current Elixir/OTP baseline for CI and cache keying.
- `lib/paddle/client.ex` - Public client constructor and `%Paddle.Client{}` type.
- `lib/paddle/error.ex` - Public error exception shape, retry/network fields, and response/transport constructors.
- `lib/paddle/page.ex` - Public page struct and `next_cursor/1` accessor.
- `lib/paddle/customers.ex` - Public customer create/get/update surface and create opts.
- `lib/paddle/customers/addresses.ex` - Public address create/get/list/stream/all/update surface, nested IDs, and pagination helper contracts.
- `lib/paddle/transactions.ex` - Public transaction get/create surface and start-flow `idempotency_key:` contract.
- `lib/paddle/subscriptions.ex` - Public subscription get/list/stream/all/cancel/pause/resume surface and lifecycle opts.
- `lib/paddle/webhooks.ex` - Public webhook verification and parsing surface.
- `lib/paddle/*.ex` and `lib/paddle/**/*.ex` - Full function scan target for `@spec` coverage.
- `test/paddle/seam_test.exs` - Accrue-facing contract test that should benefit from clearer public specs without changing behavior.

### Ecosystem references for planning research

- `https://hexdocs.pm/elixir/typespecs.html` - Elixir `@type`, `@typep`, `@opaque`, and `@spec` semantics.
- `https://hexdocs.pm/dialyxir/readme.html` - Dialyxir setup, ignore file behavior, and common project configuration.
- `https://hexdocs.pm/dialyxir/github_actions.html` - Dialyxir GitHub Actions and PLT caching guidance.
- `https://hexdocs.pm/mix/Mix.Task.html` - Mix task conventions for implementing `mix typecheck.specs`.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - Mature Elixir precedent for typed callbacks, opts-last APIs, and tagged results.
- `https://hexdocs.pm/plug/Plug.html` - Plug precedent for small composable APIs and explicit types without app-level coupling.
- `https://hexdocs.pm/req/Req.html` - Req retry/request option semantics that inform public option specs.
- `https://hexdocs.pm/stripity_stripe/Stripe.Error.html` - Typed SDK error precedent with provider/raw detail preservation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `%Paddle.Client{}` is already the explicit client context; public specs should consistently accept `Paddle.Client.t()` after adding its struct type.
- `%Paddle.Error{}` is already a `defexception` with normalized HTTP/transport fields; type it as both exception and public error return.
- `%Paddle.Page{}` plus `Paddle.Page.next_cursor/1` already defines pagination contract; specs should preserve current `next` reference behavior.
- Resource modules already isolate public surfaces: `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, and `Paddle.Webhooks`.
- `Paddle.Internal.Attrs` and `Paddle.Internal.Pagination` are hidden helpers that can receive private specs without becoming public API.

### Established Patterns

- Public functions take `%Paddle.Client{}` explicitly; no global application config.
- Eager public calls return `{:ok, struct_or_page}` or `{:error, atom | %Paddle.Error{}}`.
- Public create/start functions accept trailing opts; request options are intentionally narrow.
- Lazy streams return item enumerables and may raise during consumption if a later page fails.
- Tests are adapter-backed and assert public structs/selected fields rather than full provider fixtures.
- The root `Paddle` module and internal transport modules are sealed with `@moduledoc false`; public seam lives in resource modules and structs.

### Integration Points

- Add `@type t` definitions to all public structs in `lib/paddle/*.ex` and nested struct modules.
- Add `@spec` annotations immediately before public functions in resource modules and public struct helpers.
- Add `lib/mix/tasks/typecheck.specs.ex` or equivalent for mechanical public-spec coverage.
- Add `.dialyzer_ignore.exs`, Dialyxir config in `mix.exs`, and CI cache/job entries in `.github/workflows/ci.yml`.
- Update tests only where needed to support the coverage task or lock important type-related behavior.

</code_context>

<specifics>
## Specific Ideas

Preferred spec shapes:

```elixir
@type customer_id :: String.t()
@type request_opt :: {:idempotency_key, String.t()} | {:retry, boolean()}

@spec create(Paddle.Client.t(), map() | keyword(), [request_opt()]) ::
        {:ok, Paddle.Customer.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
```

```elixir
@type subscription_id :: String.t()
@type pause_opt ::
        {:resume_at, DateTime.t() | String.t()}
        | {:on_resume, :start_new_billing_period | :continue_existing_billing_period | String.t()}
        | {:retry, boolean()}

@spec pause(Paddle.Client.t(), subscription_id(), [pause_opt()]) ::
        {:ok, Paddle.Subscription.t()}
        | {:error, Paddle.Error.t() | :invalid_subscription_id | :invalid_resume_at | :invalid_on_resume}
```

```elixir
@spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
@spec all(Paddle.Client.t(), map() | keyword()) ::
        {:ok, [Paddle.Subscription.t()]} | {:error, Paddle.Error.t() | :invalid_params}
```

Preferred enforcement shape:

```elixir
# .dialyzer_ignore.exs
[]
```

```elixir
dialyzer: [
  plt_file: {:no_warn, "priv/plts/project.plt"},
  plt_core_path: "priv/plts/core.plt",
  ignore_warnings: ".dialyzer_ignore.exs",
  list_unused_filters: true
]
```

Add CI steps that run both:

```bash
mix typecheck.specs
mix dialyzer
```

</specifics>

<deferred>
## Deferred Ideas

- Broad Elixir/OTP Dialyzer matrix - defer until release policy requires cross-version type compatibility.
- Credo adoption or custom Credo check - separate quality-tooling decision; not needed for Phase 11.
- OpenAPI-generated specs or schema validation - useful future conformance work, but too broad for this type-safety pass.
- Documentation examples for every public function - Phase 12 owns docs completeness.
- Public request/command structs for mutation attrs/options - rejected for Phase 11 unless future API growth proves keyword opts are no longer clear.

</deferred>

---

*Phase: 11-Type-Safety Pass*
*Context gathered: 2026-05-30*
