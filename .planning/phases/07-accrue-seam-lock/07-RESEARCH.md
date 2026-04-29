# Phase 7: Accrue Seam Lock - Research

**Researched:** 2026-04-29
**Domain:** Elixir consumer-contract hardening for the Accrue-facing Paddle seam [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`]
**Confidence:** HIGH [VERIFIED: repo audit + official Elixir/ExDoc docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: copied verbatim from `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md` [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`]

### Locked Decisions
- **D-01:** The seam test should be a semantic contract test, not a full-fixture equality test.
- **D-02:** The seam test must lock the sequence of public operations and the documented tuple/struct boundary across the full path: customer create, address create, transaction create/get, webhook verify/parse, subscription get, subscription cancel.
- **D-03:** Assertions should focus on published, consumer-relevant guarantees: named public functions, locked struct fields, selected nested typed structs, normalized error/tuple behavior where applicable, and the presence of `raw_data` escape hatches.
- **D-04:** The seam test must not freeze incidental upstream payload trivia, full raw payload equality, undocumented nested map keys, or every optional field returned by Paddle.
- **D-05:** The seam guide is the source of truth for what the seam test is allowed to freeze. If a field or behavior is not documented as part of the supported seam, the seam test should not implicitly promote it into the contract.
- **D-06:** The published seam is closed and enumerated, not namespace-by-convention. Only explicitly named modules, functions, structs, and support types belong to the supported consumer contract.
- **D-07:** The public seam should explicitly include the consumer entry modules already in use: `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, and `Paddle.Webhooks`.
- **D-08:** Seam-adjacent support types that consumers reasonably depend on should also be documented explicitly: `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, and `%Paddle.Error{}`.
- **D-09:** Internal modules and implementation details are not part of the consumer contract even if they are visible in source or generated docs. This includes `Paddle.Http`, `Paddle.Internal.*`, `%Paddle.Client{}` internals such as `req`, and any undocumented helper functions.
- **D-10:** The seam guide should state clearly that undocumented modules, functions, fields, and internal implementation details are outside the supported contract and may change without notice inside the minor series.
- **D-11:** Adopt a three-tier field policy for the seam guide: `locked`, `additive`, and `opaque`.
- **D-12:** `locked` applies to typed top-level struct fields, narrow nested typed structs that are part of the documented seam, and other fields consumers may safely pattern-match and depend on.
- **D-13:** `additive` applies only where the documented contract intentionally allows growth without breaking existing meaning. It should not be used as a vague synonym for "forwarded from Paddle."
- **D-14:** `opaque` replaces the current `raw` wording for forwarded provider data whose internal shape is not part of the typed seam. Consumers may inspect it defensively, but must not depend on key-level stability.
- **D-15:** The `:raw_data` field itself is part of the locked seam as an escape hatch, but the contents of `raw_data` are `opaque`.
- **D-16:** `not-planned` is not a field tier. It belongs in scope/deferred language only, not in struct field tables.
- **D-17:** The public guide should use two high-level exclusion buckets only:
  - `Out of scope for the current 0.x seam` for product/API surfaces that may be added later but are not supported now.
  - `Intentionally excluded from core` for concerns that do not belong in this library's architectural boundary, such as Phoenix/Ecto coupling.
- **D-18:** Avoid public-facing taxonomy like `deferred`, `not in this minor series`, and `not planned` when describing unsupported surface area in the guide. Those terms create unnecessary roadmap promises and vocabulary drift.
- **D-19:** Reserve deprecation language for already-supported public APIs only. Unsupported or excluded surfaces should not be described as deprecated.
- **D-20:** For this project, GSD should prefer decisive, ecosystem-grounded defaults and shift low-level decision-making left into research, planning, and implementation whenever the choice does not materially alter the product direction or public seam.
- **D-21:** Escalate only genuinely high-impact choices to the user: public-contract changes, architectural-boundary shifts, or anything that would meaningfully change Accrue's integration posture.
- **D-22:** Recommendations should stay coherent with idiomatic Elixir library design, least surprise, forward compatibility, strong DX, and the repo's existing "narrow typed seam over broad upstream surface" strategy.

### Claude's Discretion
- Exact wording in `guides/accrue-seam.md`, so long as it preserves the locked decisions above.
- Exact assertion style in `test/paddle/seam_test.exs`, so long as it remains semantic and contract-oriented rather than fixture-ossifying.
- Exact placement of seam-policy notes in README, ExDoc, and inline docs.
- Whether to explicitly add a short glossary in the guide to define `locked`, `additive`, `opaque`, `out of scope`, and `intentionally excluded from core`.

### Deferred Ideas (OUT OF SCOPE)
None beyond the already documented unsupported surface areas. This discussion stayed within the Phase 7 boundary and locked how to present and protect the seam rather than adding new capability.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEAM-01 | Lock the end-to-end Accrue seam with an adapter-backed contract test covering customer creation, address creation, transaction create/get, webhook verify/parse, subscription get, and subscription cancel. | Keep `test/paddle/seam_test.exs` as a single adapter-backed semantic contract test; do not expand it into fixture-equality or live-network coverage [VERIFIED: `test/paddle/seam_test.exs`; CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html] |
| SEAM-02 | Publish a consumer-facing seam contract guide enumerating public modules, locked structs, field tiers, and explicitly deferred surfaces. | Update `guides/accrue-seam.md`, `mix.exs`, and published docs so the guide is canonical, vocabulary matches D-11..D-19, support types from D-08 are documented, and internal modules are not published as part of the consumer contract [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `mix.exs`; VERIFIED: `doc/api-reference.md`; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html; CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
</phase_requirements>

## Summary

Phase 7 is not greenfield work. The repo already contains the intended seam artifacts: `test/paddle/seam_test.exs` exercises the full customer -> address -> transaction create/get -> webhook verify/parse -> subscription get -> cancel path and passes without live network access because each step uses a `Req` adapter closure inside an explicit `%Paddle.Client{}` test client [VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `mix test test/paddle/seam_test.exs`]. The core planning job is to refine and freeze, not invent [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].

The largest implementation gap is documentation alignment, not test coverage. The current seam guide still uses `raw` and `not-planned` vocabulary, marks `:raw_data` as `additive`, omits the D-08 support types, and does not state the two public exclusion buckets required by the locked decisions [VERIFIED: `guides/accrue-seam.md` lines 5-125; VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`]. Separately, generated ExDoc output currently publishes `Paddle.Http`, `Paddle.Http.Telemetry`, and the placeholder root `Paddle` module in `doc/api-reference.*`, which contradicts the closed enumerated seam boundary in D-06 and D-09 [VERIFIED: `doc/api-reference.md`; VERIFIED: `doc/Paddle.Http.md`; VERIFIED: `lib/paddle.ex`; CITED: https://hexdocs.pm/elixir/writing-documentation.html; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html].

**Primary recommendation:** Plan Phase 7 as two tightly-coupled slices: first harden the canonical seam guide and ExDoc publishing boundary, then trim the seam test so it freezes only what the guide explicitly promises [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`; VERIFIED: `test/paddle/seam_test.exs`].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| End-to-end seam contract execution | API / Backend | — | The seam test exercises Elixir library functions and tuple/struct boundaries; there is no browser or database tier involved [VERIFIED: `test/paddle/seam_test.exs`] |
| Consumer contract publication | Frontend Server (SSR) | API / Backend | ExDoc turns module docs and guide markdown into published docs, while the underlying API surface still lives in Elixir modules [VERIFIED: `mix.exs`; VERIFIED: `doc/index.html`; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html] |
| Public-surface curation | API / Backend | Frontend Server (SSR) | Which modules/functions/structs are supported is a library-boundary decision; ExDoc only reflects that decision in the published output [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Internal-module suppression from published docs | Frontend Server (SSR) | API / Backend | The effective control point is documentation metadata and ExDoc configuration, even though the modules still exist in source [VERIFIED: `doc/api-reference.md`; CITED: https://hexdocs.pm/elixir/writing-documentation.html; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / ExUnit | 1.19.5 | Contract-style seam test and pattern-matching assertions | ExUnit is built into Elixir and its assertion model fits semantic tuple/struct pinning better than snapshot testing [VERIFIED: `elixir --version`; CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html] |
| ExDoc | 0.40.1 | Publish the seam guide and generate consumer docs | ExDoc extras are the standard way to publish guide pages and hide modules with `@moduledoc false` or module filtering [VERIFIED: `mix.lock`; CITED: https://hex.pm/packages/ex_doc/versions; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Req | 0.5.17 | Adapter-backed request stubbing for no-network seam coverage | Use the existing one-shot adapter closure pattern for all seam-test HTTP steps instead of introducing a mocking library [VERIFIED: `mix.lock`; VERIFIED: `test/paddle/seam_test.exs`; CITED: https://hex.pm/packages/req/versions] |
| Telemetry | 1.4.1 | Existing client instrumentation carried through `%Paddle.Client{}` creation | Keep as-is; Phase 7 should not add new observability infrastructure [VERIFIED: `mix.lock`; VERIFIED: `lib/paddle/client.ex`; CITED: https://hex.pm/packages/telemetry/versions] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Req adapter closures | Mox or a custom HTTP mock layer | Adds a new test abstraction for no gain because the repo already uses direct adapter closures successfully [VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `.planning/research/STACK.md`] |
| Semantic tuple/struct assertions | Full fixture or snapshot equality | Snapshot-style locking would violate D-01 and D-04 by freezing incidental provider payload trivia [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html] |
| ExDoc guide + filtered module surface | README-only contract notes | README links are useful for discovery, but they do not solve generated API-surface leakage or provide a canonical published seam page [VERIFIED: `README.md`; VERIFIED: `doc/api-reference.md`; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html] |

**Installation:** existing dependencies are already sufficient; no new package should be added for Phase 7 [VERIFIED: `mix.exs`; VERIFIED: `mix.lock`]

```bash
mix deps.get
```

**Version verification:** `ex_doc` 0.40.1 was published on January 31, 2026; `req` 0.5.17 was published on January 5, 2026; `telemetry` 1.4.1 was published on March 9, 2026 [VERIFIED: `mix.lock`; CITED: https://hex.pm/packages/ex_doc/versions; CITED: https://hex.pm/packages/req/versions; CITED: https://hex.pm/packages/telemetry/versions].

## Architecture Patterns

### System Architecture Diagram

```text
guide markdown ----------------------> ExDoc config ----------------------> published consumer docs
      |                                       |                                      |
      v                                       v                                      v
explicit seam policy -------------> module include/exclude rules --------> public contract boundary
      |
      v
seam test assertions -----> public functions -----> typed structs / tuples -----> no-network proof
                                    |
                                    v
                             Req adapter closures
```

All data flow for Phase 7 starts from the locked seam policy in `07-CONTEXT.md`, moves into `guides/accrue-seam.md`, and then constrains what `test/paddle/seam_test.exs` is allowed to freeze [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`; VERIFIED: `test/paddle/seam_test.exs`].

### Recommended Project Structure

```text
guides/
  accrue-seam.md          # canonical consumer contract
lib/
  paddle/*.ex             # public modules and struct definitions
  paddle/internal/*.ex    # hidden implementation modules
test/paddle/
  seam_test.exs           # canonical end-to-end seam proof
```

The planner should treat the guide and seam test as a single contract subsystem, not as independent docs and test tasks [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `.planning/ROADMAP.md`].

### Pattern 1: Guide-First Contract Lock
**What:** Document the supported modules, functions, structs, field tiers, and excluded areas first, then ensure the seam test only asserts those documented guarantees [VERIFIED: D-05 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**When to use:** Whenever the phase goal is public-contract freezing rather than new feature delivery [VERIFIED: `.planning/ROADMAP.md`].
**Example:**
```elixir
# Source: test/paddle/seam_test.exs
assert {:ok, %Transaction{id: "txn_seam01"} = transaction} =
         Paddle.Transactions.create(client, attrs)

assert %Checkout{url: checkout_url} = transaction.checkout
assert checkout_url == "https://checkout.paddle.com/checkout/txn_seam01"
```
[VERIFIED: `test/paddle/seam_test.exs`]

### Pattern 2: Adapter-Backed Semantic Contract Test
**What:** Use explicit `%Paddle.Client{}` values with one-shot `Req.new(adapter: fun)` closures so every public operation is executed through the real library boundary without network access [VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `lib/paddle/client.ex`].
**When to use:** For end-to-end consumer seam coverage that should still remain deterministic and fast [VERIFIED: `mix test test/paddle/seam_test.exs`].
**Example:**
```elixir
# Source: test/paddle/seam_test.exs
%Client{
  api_key: "sk_test_123",
  environment: :sandbox,
  req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
}
```
[VERIFIED: `test/paddle/seam_test.exs`]

### Pattern 3: Hide Internal Modules Explicitly
**What:** Internal modules should be hidden from docs with `@moduledoc false` and, if needed, reinforced with ExDoc module filtering [CITED: https://hexdocs.pm/elixir/writing-documentation.html; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html].
**When to use:** When the project has helper modules that must exist in source but must not appear in the published consumer contract [VERIFIED: D-09 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**Example:**
```elixir
defmodule MyApp.Hidden do
  @moduledoc false
end
```
[CITED: https://hexdocs.pm/elixir/writing-documentation.html]

### Anti-Patterns to Avoid
- **Fixture ossification:** Do not assert full payload equality for transactions, subscriptions, or events; lock only named consumer guarantees [VERIFIED: D-01..D-04 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
- **Vocabulary drift:** Do not keep `raw` and `not-planned` in the public guide; Phase 7 is locked to `locked`, `additive`, `opaque`, plus the two exclusion buckets [VERIFIED: `guides/accrue-seam.md`; VERIFIED: D-11..D-19 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
- **Documentation-by-visibility:** Do not rely on "it is in generated docs, so it is public"; D-06 makes the seam explicitly enumerated instead [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `doc/api-reference.md`].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| No-network seam harness | A bespoke mock transport layer | Existing `Req` adapter closures | The current pattern already exercises real request building and response handling while staying deterministic [VERIFIED: `test/paddle/seam_test.exs`; CITED: https://hex.pm/packages/req/versions] |
| Consumer contract publication | A custom docs index or manual HTML | ExDoc extras plus module-hiding controls | ExDoc already publishes the guide and supports excluding hidden modules [VERIFIED: `mix.exs`; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html; CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Contract freezing | Snapshotting full structs/maps | ExUnit pattern matches and targeted equality checks | Pattern matches lock the intended tuple/struct seam without turning additive provider payload changes into false breakages [CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html; VERIFIED: `test/paddle/seam_test.exs`] |

**Key insight:** Phase 7 should reuse the repo’s existing Elixir patterns and tighten scope boundaries; adding new infrastructure would create more surface area than value [VERIFIED: `.planning/research/STACK.md`; VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].

## Common Pitfalls

### Pitfall 1: The guide and seam test freeze different contracts
**What goes wrong:** The test starts asserting behavior that is not documented, or the guide promises fields/functions the seam test never proves [VERIFIED: D-05 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**Why it happens:** Docs and tests get edited independently because they live in different directories [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `test/paddle/seam_test.exs`].
**How to avoid:** Plan doc and test changes together and review every seam assertion against the guide section it proves [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**Warning signs:** New assertions appear for nested provider payload keys that are absent from the guide [VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `guides/accrue-seam.md`].

### Pitfall 2: Published docs leak internal modules
**What goes wrong:** Consumers see `Paddle.Http` or helper modules in API reference pages and treat them as supported [VERIFIED: `doc/api-reference.md`; VERIFIED: `doc/Paddle.Http.md`].
**Why it happens:** ExDoc publishes modules unless they are hidden or filtered out [CITED: https://hexdocs.pm/elixir/writing-documentation.html; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html].
**How to avoid:** Add `@moduledoc false` to internal modules and validate the generated `doc/api-reference.md` output after `mix docs` [CITED: https://hexdocs.pm/elixir/writing-documentation.html; VERIFIED: `mix docs`; VERIFIED: `doc/api-reference.md`].
**Warning signs:** `doc/api-reference.md` lists `Paddle.Http`, `Paddle.Http.Telemetry`, or placeholder modules not named in the guide [VERIFIED: `doc/api-reference.md`; VERIFIED: `lib/paddle.ex`].

### Pitfall 3: `raw_data` gets documented with the wrong tier
**What goes wrong:** Consumers infer that the `:raw_data` field itself can disappear or change tier semantics because it is labeled `additive` instead of `locked` [VERIFIED: `guides/accrue-seam.md` lines 46-115; VERIFIED: D-15 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**Why it happens:** The guide currently conflates the existence of the escape hatch with the mutability of its contents [VERIFIED: `guides/accrue-seam.md`].
**How to avoid:** Document `:raw_data` as a locked field whose contents are `opaque` [VERIFIED: D-14..D-15 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**Warning signs:** Field tables use `additive` for every `:raw_data` row or continue using `raw` in nested-field rows [VERIFIED: `guides/accrue-seam.md`].

### Pitfall 4: Support types get omitted because they are not in the seam path
**What goes wrong:** `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, and `%Paddle.Error{}` are left undocumented even though D-08 makes them part of the supported seam [VERIFIED: D-08 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
**Why it happens:** The current seam guide focuses on the main resource modules and structs only [VERIFIED: `guides/accrue-seam.md`].
**How to avoid:** Add a dedicated support-types section and rely on existing focused tests rather than expanding the end-to-end seam path [VERIFIED: `test/paddle/client_test.exs`; VERIFIED: `test/paddle/page_test.exs`; VERIFIED: `test/paddle/error_test.exs`].
**Warning signs:** The guide claims a closed enumerated seam but omits types consumers already depend on [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].

## Code Examples

Verified patterns from official sources and the current repo:

### Semantic pattern matching for contract assertions
```elixir
# Source: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html
assert match?([%{id: id} | _] when is_integer(id), records)
```
[CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html]

### Hiding internal modules from docs
```elixir
# Source: https://hexdocs.pm/elixir/writing-documentation.html
defmodule MyApp.Hidden do
  @moduledoc false
end
```
[CITED: https://hexdocs.pm/elixir/writing-documentation.html]

### Support-type coverage that should stay out of the seam path
```elixir
# Source: test/paddle/page_test.exs
page = %Paddle.Page{data: [], meta: %{"pagination" => %{"next" => "/transactions?after=cursor_123"}}}
assert Paddle.Page.next_cursor(page) == "/transactions?after=cursor_123"
```
[VERIFIED: `test/paddle/page_test.exs`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Namespace-by-convention public surface | Closed enumerated seam in a canonical guide | Locked on 2026-04-29 during Phase 7 discussion | Consumers depend only on explicitly documented modules, functions, structs, and support types [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`] |
| `raw` / `not-planned` public vocabulary | `opaque` plus two exclusion buckets | Locked on 2026-04-29 during Phase 7 discussion | Reduces roadmap ambiguity and makes field-tier semantics precise [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`] |
| Visible source modules imply public availability | Hidden internal modules and explicit docs boundary | Standard Elixir documentation guidance; applicable now | Generated docs stop advertising unsupported internals [CITED: https://hexdocs.pm/elixir/writing-documentation.html; CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html] |

**Deprecated/outdated:**
- `raw` as a field-tier label is outdated for this phase because D-14 replaces it with `opaque` [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`].
- `not-planned` as public guide taxonomy is outdated for this phase because D-16..D-18 replace it with explicit exclusion buckets [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`].

## Exact Planning Gaps

1. The seam test already satisfies the required path and passes locally; planning should focus on refinement, not creation from scratch [VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `mix test test/paddle/seam_test.exs`].
2. The guide vocabulary is misaligned with locked decisions at lines 5-10 and throughout the field tables, so the public contract currently documents the wrong policy [VERIFIED: `guides/accrue-seam.md`].
3. The guide omits D-08 support types: `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, and an explicit `%Paddle.Error{}` support-type entry instead of only an error-fields appendix [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `lib/paddle/client.ex`; VERIFIED: `lib/paddle/page.ex`; VERIFIED: `lib/paddle/error.ex`].
4. Generated docs currently publish `Paddle.Http`, `Paddle.Http.Telemetry`, and `Paddle` in API reference output, so the published consumer contract is not yet sealed [VERIFIED: `doc/api-reference.md`; VERIFIED: `doc/Paddle.Http.md`; VERIFIED: `doc/Paddle.Http.Telemetry.md`; VERIFIED: `doc/Paddle.md`].
5. Existing focused tests already cover the D-08 support types, so the planner should not widen the seam test to cover pagination and client bootstrapping unless the goal is specifically to replace those focused tests, which Phase 7 does not require [VERIFIED: `test/paddle/client_test.exs`; VERIFIED: `test/paddle/page_test.exs`; VERIFIED: `test/paddle/error_test.exs`; VERIFIED: `.planning/ROADMAP.md`].

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited in this session [VERIFIED: repo audit + official docs].

## Resolved Questions

1. **Placeholder root `Paddle` module outcome**
   - Decision: hide `lib/paddle.ex` from published docs with `@moduledoc false`; do not expand it into a package-overview module in Phase 7 and do not rely on it as part of the supported seam [VERIFIED: D-06 and D-09 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
   - Why: the current module is still the generated `hello/0` placeholder, and publishing it would keep advertising a non-seam entry point in `doc/api-reference.md` [VERIFIED: `lib/paddle.ex`; VERIFIED: `doc/api-reference.md`].
   - Planning impact: Plan 02 should treat `lib/paddle.ex` exactly like `Paddle.Http` and `Paddle.Http.Telemetry` for docs-surface suppression [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-02-PLAN.md`].

2. **Guide glossary scope**
   - Decision: keep the guide vocabulary lightweight and inline. Retain the existing vocabulary section, but do not add a separate glossary block unless execution shows the rewritten guide still leaves `additive`, `opaque`, or the exclusion buckets ambiguous [VERIFIED: D-11..D-18 in `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
   - Why: the current guide already has a vocabulary section, and CONTEXT.md leaves the exact wording and glossary depth to implementation discretion [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`].
   - Planning impact: Plan 02 should rewrite the existing vocabulary section in place instead of introducing a second terminology structure unless that becomes necessary during docs review [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-02-PLAN.md`].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, `mix docs` | ✓ | 1.19.5 | — |
| Erlang/OTP | Elixir runtime | ✓ | 28 | — |
| ExDoc | Published seam guide generation | ✓ | 0.40.1 | `mix deps.get` if missing from local deps |
| Req | No-network adapter-backed seam test | ✓ | 0.5.17 | none; phase assumes existing dep |

Availability above was verified with `elixir --version`, `mix test test/paddle/seam_test.exs`, `mix docs`, and `mix.lock` [VERIFIED: local command audit].

**Missing dependencies with no fallback:**
- None [VERIFIED: local command audit].

**Missing dependencies with fallback:**
- None [VERIFIED: local command audit].

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 7 does not add auth flows; it documents an SDK seam [VERIFIED: `.planning/ROADMAP.md`] |
| V3 Session Management | no | No session state exists in this library seam [VERIFIED: repo architecture audit] |
| V4 Access Control | no | No authorization layer is added in this phase [VERIFIED: `.planning/ROADMAP.md`] |
| V5 Input Validation | yes | Preserve existing ID/attr validation and avoid widening accepted shapes in seam-facing APIs [VERIFIED: `lib/paddle/customers.ex`; VERIFIED: `lib/paddle/customers/addresses.ex`; VERIFIED: `lib/paddle/transactions.ex`; VERIFIED: `lib/paddle/subscriptions.ex`; VERIFIED: `lib/paddle/webhooks.ex`] |
| V6 Cryptography | yes | Webhook verification already uses HMAC-SHA256 and constant-time digest comparison through `:crypto` [VERIFIED: `lib/paddle/webhooks.ex`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook signature bypass through altered body or weak comparison | Spoofing / Tampering | Keep `verify_signature/4` pure, raw-body based, and backed by seam/focused tests; do not normalize the raw body before verification [VERIFIED: `lib/paddle/webhooks.ex`; VERIFIED: `test/paddle/seam_test.exs`; VERIFIED: `test/paddle/webhooks_test.exs`] |
| Internal implementation dependence by consumers | Information Disclosure | Hide internal modules from docs and explicitly document unsupported internals [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `doc/api-reference.md`; CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Over-broad contract freezing that blocks safe upstream additions | Denial of Service to delivery velocity | Limit seam assertions to documented locked fields and use `opaque` for provider-controlled nested maps [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: `guides/accrue-seam.md`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md` - locked Phase 7 decisions and scope [VERIFIED: local file]
- `test/paddle/seam_test.exs` - current seam path, assertion style, and no-network adapter pattern [VERIFIED: local file]
- `guides/accrue-seam.md` - current published seam guide and vocabulary gaps [VERIFIED: local file]
- `mix.exs` and `mix.lock` - current docs wiring and resolved dependency versions [VERIFIED: local files]
- `doc/api-reference.md`, `doc/Paddle.Http.md`, `doc/Paddle.Http.Telemetry.md`, `doc/Paddle.md` - proof that generated docs currently expose internal or placeholder modules [VERIFIED: local files]
- https://hexdocs.pm/elixir/writing-documentation.html - official Elixir guidance for hiding internal modules with `@moduledoc false` [CITED: https://hexdocs.pm/elixir/writing-documentation.html]
- https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html - official ExDoc docs for extras and `:filter_modules` behavior [CITED: https://hexdocs.pm/ex_doc/0.38.1/Mix.Tasks.Docs.html]
- https://hexdocs.pm/ex_unit/ExUnit.Assertions.html - official ExUnit assertion guidance for semantic pattern matching [CITED: https://hexdocs.pm/ex_unit/ExUnit.Assertions.html]

### Secondary (MEDIUM confidence)
- https://hex.pm/packages/ex_doc/versions - ExDoc version and publish date verification [CITED: https://hex.pm/packages/ex_doc/versions]
- https://hex.pm/packages/req/versions - Req version and publish date verification [CITED: https://hex.pm/packages/req/versions]
- https://hex.pm/packages/telemetry/versions - Telemetry version and publish date verification [CITED: https://hex.pm/packages/telemetry/versions]

### Tertiary (LOW confidence)
- None [VERIFIED: all external claims were verified against official docs or registry pages].

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase uses existing pinned dependencies, locally verified toolchain output, and official Hex package/version pages [VERIFIED: `mix.lock`; VERIFIED: local command audit; CITED: https://hex.pm/packages/ex_doc/versions; CITED: https://hex.pm/packages/req/versions; CITED: https://hex.pm/packages/telemetry/versions]
- Architecture: HIGH - the seam boundary and artifact responsibilities are directly specified in `07-CONTEXT.md` and visible in current repo structure [VERIFIED: `.planning/phases/07-accrue-seam-lock/07-CONTEXT.md`; VERIFIED: repo audit]
- Pitfalls: HIGH - the concrete mismatches are already present in the current guide and generated docs output [VERIFIED: `guides/accrue-seam.md`; VERIFIED: `doc/api-reference.md`]

**Research date:** 2026-04-29
**Valid until:** 2026-05-29 [ASSUMED]
