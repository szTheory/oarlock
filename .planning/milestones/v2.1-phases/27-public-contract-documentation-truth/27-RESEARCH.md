# Phase 27: Public Contract & Documentation Truth - Research

**Researched:** 2026-06-24
**Domain:** Elixir SDK public documentation, ExDoc guides, Paddle Billing proof boundaries
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Public Surface Source of Truth
- **D-01:** Use a hybrid contract approach. Keep `guides/accrue-seam.md` as the human-readable canonical consumer contract, but verify its module/function/struct inventory against live code during the docs pass.
- **D-02:** The seam guide owns stability vocabulary, exclusions, and Accrue-facing interpretation. Generated or code-scanned inventory may validate arities and fields, but must not replace the prose contract.
- **D-03:** Downstream planning should include a repeatable docs-truth check: inventory public `Paddle.*` modules/functions/struct fields, compare them to `guides/accrue-seam.md`, and run docs with warnings treated as failures where the project supports it.
- **D-04:** Do not build a broad docs generator in this phase. A lightweight Mix task, script, checklist, or focused test is acceptable if it prevents seam/arity drift without making the docs unreadable.

### Adopter Journey and Documentation Structure
- **D-05:** Structure public docs around task-based jobs-to-be-done, not a raw API inventory first. The primary journey is: install and create an explicit client, create or map customer/address data as needed, create a transaction/checkout URL, verify webhooks from the raw body, fetch canonical subscription state, and cancel or manage subscriptions.
- **D-06:** Use Phoenix/Plug/Ecto examples where they help the likely cold Phoenix SaaS adopter, but label them clearly as app-owned code. Oarlock documents how to fit into a Phoenix app; it does not become a Phoenix, Plug, Ecto, route, migration, or billing-framework package.
- **D-07:** Keep backend implementation details hidden unless they are fundamental to correct use. Raw-body webhook handling, sandbox/live separation, endpoint secrets, and persistence boundaries are fundamental and should be explicit. Internal transport details and implementation guts should stay out of first-read docs.
- **D-08:** README should give a short, concrete taste of client creation, checkout handoff, webhook verification, error handling, pagination, and supported surface, then link to task guides and the seam contract rather than duplicating every detail.

### Proof Boundary Language
- **D-09:** Adopt a consistent proof ladder across docs: unit/contract tests prove local SDK behavior; `Paddle.MockServer` proves deterministic offline SDK/demo wiring; Paddle sandbox checks prove real provider-state behavior when actually run; live mode remains operator-owned readiness before charging customers.
- **D-10:** Be blunt at trust boundaries without making every page sound like an incident runbook. Use wording equivalent to: MockServer is a development fixture, not a complete Paddle clone, and mock-backed tests do not prove Paddle will create, retry, order, or deliver real provider state.
- **D-11:** Never write "sandbox verified", "provider-state verified", or similar release claims unless that exact verification was run with real Paddle credentials. Prefer "MockServer-backed", "offline", or "deterministic local proof" when that is what happened.
- **D-12:** Getting Started and demo docs should include a compact "before live mode" checklist: real price IDs, sandbox checkout, webhook destination/secret, raw-body signature verification, event idempotency, environment-specific credentials, and final live credential swap.

### Changelog and Release Narrative
- **D-13:** Use a hybrid changelog entry: concise, human-readable, and concrete enough for adopters. It should name that README, Getting Started, Accrue seam contract, demo runbook, and changelog now describe the shipped seam.
- **D-14:** Include a bounded surface inventory in the changelog once, then point readers to `guides/accrue-seam.md` for the canonical contract and to task guides for flows. Do not duplicate the whole seam contract in `CHANGELOG.md`.
- **D-15:** Follow a Keep-a-Changelog style: group user-visible changes by type, keep the latest/unreleased material easy to scan, call out breaking details explicitly, and avoid commit-log noise or marketing language.
- **D-16:** Avoid v2.1/Hex version confusion. v2.1 is a planning milestone; public release notes should not imply a Hex major release or a new runtime feature unless that is true.

### Voice, UX, and Developer Experience
- **D-17:** Follow the newer `prompts/oarlock-brand-book.md` for docs tone and brand rules. The voice should be direct, calm, precise, developer-native, and honest about unsupported scope.
- **D-18:** Use provider-native Paddle language rather than fake Stripe parity. Explain Paddle-specific transaction/checkout, subscription, portal, adjustment, notification setting, and webhook behavior directly.
- **D-19:** Make the safe path obvious: verified webhooks before parsing/trusting events, explicit sandbox/live clients, normalized errors with raw provider data for debugging, and clear app-owned persistence boundaries.
- **D-20:** Favor examples that are copy-pasteable, realistic, and small. Show `{:ok, result}` / `{:error, %Paddle.Error{}}`, explicit `%Paddle.Client{}` passing, and task-sized snippets over abstract architecture prose.

### the agent's Discretion
- Exact heading names, section ordering, and wording may be adjusted for readability as long as the contract/proof/adopter-journey decisions above hold.
- The planner may choose the lightest reliable verification mechanism for seam drift after inspecting current test and Mix task patterns.
- UI/graphic design is not directly in scope for this docs-only phase. If generated docs or README visual assets are touched, use brand-book accessibility and readability guidance; otherwise prioritize prose and examples.

### Deferred Ideas (OUT OF SCOPE)

- CI demo, downstream package smoke test, and optional dependency verification belong to Phase 28.
- GSD backlog/state/audit reconciliation belongs to Phase 29.
- New SDK endpoints, Phoenix/Ecto helper packages, admin UI, local billing mirror, and live provider-state CI are out of scope for Phase 27.
</user_constraints>

## Summary

Phase 27 should plan a documentation truth pass over existing shipped code, not a capability build. The repository already has public docs, generated ExDoc output, an Accrue seam guide, demo docs, and tests; the risk is drift between those artifacts and the live `Paddle.*` surface. [VERIFIED: codebase grep + mix introspection]

The highest-value planning move is a lightweight public inventory check: enumerate documented public modules, functions, arities, and structs from live code; compare them to `guides/accrue-seam.md`, README, Getting Started, demo runbook, and changelog; then run `mix docs --warnings-as-errors` and `mix test --warnings-as-errors`. Those commands passed locally on 2026-06-24. [VERIFIED: local command output]

Proof language must use a consistent ladder: local unit/contract tests, `Paddle.MockServer` offline proof, real Paddle sandbox checks only when credentials were actually used, and operator-owned live readiness. Paddle's official webhook docs require exact raw bodies and endpoint-specific secrets, while Paddle's subscription docs say subscriptions cannot be created directly. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] [CITED: https://developer.paddle.com/api-reference/subscriptions]

**Primary recommendation:** Plan one focused docs alignment wave plus one lightweight contract-drift guard; do not add new SDK modules, broad docs generation, Phoenix/Ecto integration, or live provider-state CI. [VERIFIED: 27-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public SDK surface truth | API / Backend | Documentation | Live Elixir modules define callable behavior; docs must describe that behavior accurately. [VERIFIED: mix introspection] |
| Adopter task journey | Documentation | API / Backend | README and guides should explain how consumers sequence existing calls without moving domain ownership into the SDK. [VERIFIED: 27-CONTEXT.md] |
| Phoenix/Plug raw-body guidance | Documentation | Frontend Server / SSR | Raw-body capture is app-owned Plug/Phoenix setup; the core SDK exposes pure verification functions. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| Demo runbook proof boundary | Documentation | API / Backend | Demo docs describe how `Paddle.MockServer` exercises local wiring without claiming provider-state proof. [VERIFIED: demo/README.md + lib/paddle/mock_server.ex] |
| Changelog release narrative | Documentation | — | The changelog should summarize user-visible docs truth and bounded surface changes without duplicating the full seam. [CITED: https://keepachangelog.com/en/1.1.0/] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | README, Getting Started, and seam contract accurately describe the shipped SDK surface. | Use live `Paddle.*` inventory and compare against README, `guides/getting-started.md`, and `guides/accrue-seam.md`. [VERIFIED: mix introspection] |
| DOCS-02 | Demo app documentation explains local setup, mock auth, webhook processing, portal handoff, and Offline Mode. | `demo/README.md` already covers Phoenix shell, mock auth, portal handoff, offline MockServer, and integration tests; planner should verify those claims against demo code and proof boundary wording. [VERIFIED: demo/README.md grep] |
| DOCS-03 | Docs distinguish core SDK responsibilities from app-owned Phoenix/Ecto/provisioning responsibilities. | Phase context locks pure SDK boundaries; Plug docs support raw-body examples as app-owned configuration. [VERIFIED: 27-CONTEXT.md] [CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| DOCS-04 | Docs state the proof boundary honestly: MockServer-backed integration is not the same as live Paddle provider-state verification. | Paddle docs distinguish real webhook and subscription provider behavior; local MockServer is a development fixture in code/docs. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] [VERIFIED: lib/paddle/mock_server.ex] |
</phase_requirements>

## Project Constraints (from AGENTS.md / CLAUDE.md)

No root `AGENTS.md`, root `CLAUDE.md`, or `.claude/CLAUDE.md` was present in `/Users/jon/projects/oarlock` during research. [VERIFIED: shell listing]

`demo/AGENTS.md` exists and applies when editing demo code or demo-facing docs. It requires `mix precommit` when finishing demo changes, prefers `Req` over `httpoison`/`tesla`/`:httpc`, and includes Phoenix 1.8, HEEx, Tailwind v4, Ecto, and test conventions. [VERIFIED: demo/AGENTS.md]

For Phase 27 docs-only planning, the planner should not create new Phoenix UI, routes, schemas, migrations, or demo features; if demo docs are updated, ensure examples do not contradict demo-local Phoenix/Ecto conventions. [VERIFIED: 27-CONTEXT.md + demo/AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, OTP 28 | Compile, test, introspect modules, generate docs | Current local runtime for this repo; all validation commands ran on it. [VERIFIED: local command output] |
| ExDoc | locked 0.40.1; registry latest 0.40.3 on 2026-06-24 | Generate HexDocs-style API docs and guide extras | Current `mix.exs` already uses ExDoc extras for README, changelog, license, and guides; `mix docs --warnings-as-errors` is supported and passed. [VERIFIED: mix.exs + mix help docs + Hex registry] |
| ExUnit | bundled with Elixir 1.19.5 | Public contract and docs-truth guard tests | Existing suite has 219 tests and a seam test; `mix test --warnings-as-errors` passed. [VERIFIED: local command output] |
| `Code.fetch_docs/1` | Elixir standard API | Inspect generated documentation chunks for modules/functions | Existing `check_docs.exs`, `check_examples.exs`, and seam test already use documentation metadata patterns. [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `Req` | locked 0.5.17; registry latest 0.6.2 on 2026-06-24 | Existing SDK HTTP client | Mention only as current implementation detail where relevant; do not expose internals as first-read docs. [VERIFIED: mix deps + mix hex.info] |
| `Plug` | optional dependency locked 1.19.2; registry latest 1.20.1 on 2026-06-24 | Demo MockServer and Phoenix raw-body documentation context | Use in docs as app-owned Phoenix/Plug setup, not as core SDK coupling. [VERIFIED: mix deps + mix hex.info] [CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| `Paddle.MockServer` | local module | Deterministic offline fixture for demo/test flows | Use for local proof language only; do not conflate with live provider-state verification. [VERIFIED: lib/paddle/mock_server.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing ExDoc extras + focused tests | Broad docs generator | A generator would add maintenance surface and conflicts with D-04; a focused inventory guard is enough. [VERIFIED: 27-CONTEXT.md] |
| `Code.fetch_docs/1` / module introspection | Markdown-only grep | Markdown grep misses arity/default-function expansion and documented modules; introspection catches live code. [VERIFIED: mix introspection] |
| MockServer proof language | "Sandbox verified" claims | Sandbox/provider claims require real credentials and provider execution; local mock proof is deterministic but narrower. [VERIFIED: 27-CONTEXT.md] |

**Installation:**

No new packages should be installed for Phase 27. Existing project dependencies are sufficient. [VERIFIED: mix.exs + local validation]

**Version verification:** Versions above were verified with `mix deps`, `mix hex.info ex_doc`, `mix hex.info plug`, `mix hex.info req`, `elixir --version`, and `mix --version` on 2026-06-24. [VERIFIED: local command output]

## Package Legitimacy Audit

No new external packages are recommended for this phase. [VERIFIED: research conclusion]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No install planned. [VERIFIED: research conclusion] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new package recommendations]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new package recommendations]

## Architecture Patterns

### System Architecture Diagram

```text
Live Elixir code
  -> module/function/struct inventory
  -> compare with guides/accrue-seam.md
  -> align README + Getting Started + demo README + CHANGELOG
  -> generate ExDoc extras
  -> run warnings-as-errors docs/test gate

Adopter request flow in docs
  -> explicit Paddle.Client
  -> customer/address
  -> transaction checkout URL
  -> raw-body webhook verification
  -> event parsing + app-owned persistence/provisioning
  -> subscription fetch/lifecycle/portal operations
```

This diagram reflects the locked documentation flow and existing public SDK modules. [VERIFIED: 27-CONTEXT.md + mix introspection]

### Recommended Project Structure

```text
README.md                         # first-read summary and links
CHANGELOG.md                      # human release narrative
guides/getting-started.md         # adopter task journey
guides/accrue-seam.md             # canonical human contract
guides/telemetry.md               # request telemetry guide
demo/README.md                    # Phoenix demo runbook and proof boundary
test/paddle/seam_test.exs         # existing seam contract behavior test
check_docs.exs / check_examples.exs # existing docs metadata scripts
mix.exs                           # ExDoc extras and docs configuration
```

All listed files exist in the repository. [VERIFIED: file listing]

### Pattern 1: Hybrid Human Contract Plus Live Inventory

**What:** Keep `guides/accrue-seam.md` as the contract prose, but validate the module/function/struct inventory against loaded `Paddle.*` modules. [VERIFIED: 27-CONTEXT.md]

**When to use:** Use for DOCS-01 and changelog bounded inventory checks. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
modules = [
  Paddle.Customers,
  Paddle.Customers.Addresses,
  Paddle.Customers.PortalSessions,
  Paddle.Transactions,
  Paddle.Subscriptions,
  Paddle.Products,
  Paddle.Prices,
  Paddle.Events,
  Paddle.NotificationSettings,
  Paddle.Adjustments,
  Paddle.Webhooks
]

for mod <- modules do
  {mod, mod.__info__(:functions)}
end
```

Source: local Mix introspection pattern used during research. [VERIFIED: local command output]

### Pattern 2: Docs Build as a Gate

**What:** Use the existing ExDoc task with warnings as failures. [VERIFIED: mix help docs]

**When to use:** Use after guide and README edits to catch broken local references and documentation warnings. [VERIFIED: local command output]

**Example:**

```bash
mix docs --warnings-as-errors
```

Source: local `mix help docs`; command passed on 2026-06-24. [VERIFIED: local command output]

### Pattern 3: Proof Ladder Text Reuse

**What:** Use the same compact proof ladder in README, Getting Started, demo README, and changelog. [VERIFIED: 27-CONTEXT.md]

**When to use:** Use whenever docs mention MockServer, sandbox, live mode, integration proof, or provider-state behavior. [VERIFIED: 27-CONTEXT.md]

**Example wording:**

```text
MockServer-backed tests prove deterministic local SDK/demo wiring. They do not
prove Paddle will create, retry, order, or deliver real provider state. Run a
real sandbox checkout and webhook verification before live mode.
```

Source: wording derived from locked D-09 through D-12. [VERIFIED: 27-CONTEXT.md]

### Anti-Patterns to Avoid

- **Raw API inventory as first-read docs:** It violates the task-based adopter journey decision; use inventory as a contract appendix/check, not the entry point. [VERIFIED: 27-CONTEXT.md]
- **"Sandbox verified" without evidence:** Locked decisions prohibit this unless real Paddle credentials were used in that exact verification. [VERIFIED: 27-CONTEXT.md]
- **Phoenix/Ecto helper drift:** Examples may show app-owned code, but core SDK docs must not imply routes, schemas, migrations, or provisioning are provided. [VERIFIED: 27-CONTEXT.md]
- **Documenting `Paddle.MockServer` as a Paddle clone:** The module is a standalone Plug router development fixture with limited routes. [VERIFIED: lib/paddle/mock_server.ex]
- **Ignoring `Paddle.PortalSessions`:** The module currently exists and is documented, while the seam guide prefers `Paddle.Customers.PortalSessions`; planner must decide whether to document it as supported/legacy/compat or hide/deprecate it in scope. [VERIFIED: lib/paddle/portal_sessions.ex + guides/accrue-seam.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs generation | Custom static docs generator | Existing ExDoc extras and `mix docs --warnings-as-errors` | ExDoc is already configured and supports extras/warnings gates. [VERIFIED: mix.exs + mix help docs] |
| Public function inventory | Regex-only Markdown scan | Live module introspection plus `Code.fetch_docs/1` where docs metadata matters | Live introspection sees expanded default arities and real exported functions. [VERIFIED: local command output] |
| Raw-body webhook framework helper | New Plug/Phoenix package | Documentation snippet using Plug `:body_reader` as app-owned code | Plug already supports a raw-body reader hook; Phase 27 excludes new integration code. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| Provider-state proof | Local mock behavior claims | Explicit proof ladder with separate sandbox/live wording | Paddle provider behavior requires real Paddle systems; MockServer is deterministic local proof only. [VERIFIED: 27-CONTEXT.md] |
| Subscription creation abstraction | Fake `Paddle.Subscriptions.create` docs | Transaction/checkout or manually collected transaction flow | Paddle says subscriptions cannot be created directly. [CITED: https://developer.paddle.com/api-reference/subscriptions] |

**Key insight:** The phase is about making the published contract match reality; new abstractions would create more surface to verify and more ways to drift. [VERIFIED: 27-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Default Arity Drift

**What goes wrong:** Docs list only `create/4` while Elixir exports `create/2`, `create/3`, and `create/4` due defaults. [VERIFIED: mix introspection]

**Why it happens:** Documentation prose often describes canonical usage, while Elixir default arguments create multiple callable arities. [VERIFIED: mix introspection]

**How to avoid:** Inventory exported functions and intentionally decide how the seam contract represents default arities. [VERIFIED: research conclusion]

**Warning signs:** README, seam guide, generated docs, and `__info__(:functions)` disagree. [VERIFIED: local inventory]

### Pitfall 2: Portal Session Namespace Split

**What goes wrong:** `Paddle.PortalSessions.create/2` remains visible in generated docs while the seam guide names `Paddle.Customers.PortalSessions.create/2..4` as the supported path. [VERIFIED: lib/paddle/portal_sessions.ex + guides/accrue-seam.md]

**Why it happens:** An older or alternate resource module was not hidden when the scoped module was added. [ASSUMED]

**How to avoid:** Planner should add a human decision task: either include `Paddle.PortalSessions` in the bounded contract, mark it legacy/compat, or hide/deprecate it with tests updated accordingly. [VERIFIED: research conclusion]

**Warning signs:** Demo or MockServer tests call `Paddle.PortalSessions.create/2` while public docs steer users to `Paddle.Customers.PortalSessions`. [VERIFIED: test/paddle/mock_server_test.exs]

### Pitfall 3: MockServer Proof Overclaim

**What goes wrong:** Docs imply local mock tests prove Paddle sandbox/live provider behavior. [VERIFIED: 27-CONTEXT.md]

**Why it happens:** "Integration test" can mean local integration or external provider integration. [ASSUMED]

**How to avoid:** Use "MockServer-backed", "offline", and "deterministic local proof" for local tests; reserve "sandbox verified" for real Paddle credential runs. [VERIFIED: 27-CONTEXT.md]

**Warning signs:** Phrases like "provider-state verified" appear without a dated sandbox/live run. [VERIFIED: 27-CONTEXT.md]

### Pitfall 4: Raw Body Hidden in Framework Prose

**What goes wrong:** Docs show webhook parsing after Phoenix has parsed JSON, which breaks Paddle signature verification. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/]

**Why it happens:** Most web frameworks parse JSON before handlers unless configured otherwise. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html]

**How to avoid:** Show verification before trust/parsing and cite Plug `:body_reader` as app-owned setup. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html]

**Warning signs:** Example handlers call `parse_event/1` before `verify_signature/4`, or pass decoded params instead of the raw body. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from local code and official docs:

### Public Surface Inventory

```elixir
for module <- [
      Paddle.Customers,
      Paddle.Customers.Addresses,
      Paddle.Customers.PortalSessions,
      Paddle.Transactions,
      Paddle.Subscriptions,
      Paddle.Products,
      Paddle.Prices,
      Paddle.Events,
      Paddle.NotificationSettings,
      Paddle.Adjustments,
      Paddle.Webhooks
    ] do
  IO.inspect({module, module.__info__(:functions)})
end
```

Source: research introspection against loaded application modules. [VERIFIED: local command output]

### Raw Body Capture in Plug/Phoenix Docs

```elixir
defmodule CacheBodyReader do
  def read_body(conn, opts) do
    with {:ok, body, conn} <- Plug.Conn.read_body(conn, opts) do
      conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
      {:ok, body, conn}
    end
  end
end

plug Plug.Parsers,
  parsers: [:urlencoded, :json],
  body_reader: {CacheBodyReader, :read_body, []},
  json_decoder: Jason
```

Source: official Plug.Parsers documentation shows `:body_reader` for raw body access. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html]

### Webhook Verification Before Parsing

```elixir
with {:ok, :verified} <-
       Paddle.Webhooks.verify_signature(raw_body, signature_header, secret),
     {:ok, event} <- Paddle.Webhooks.parse_event(raw_body) do
  {:ok, event}
end
```

Source: existing README and Getting Started examples follow this shape. [VERIFIED: README.md + guides/getting-started.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct subscription-create mental model | Transaction/checkout or invoice creates subscriptions, then reconcile via webhooks and fetches | Verified against Paddle docs on 2026-06-24 | Docs should not invent `Paddle.Subscriptions.create/*`. [CITED: https://developer.paddle.com/api-reference/subscriptions] |
| Mock/local integration proof phrased as provider proof | Proof ladder separating unit/contract, MockServer, sandbox, and live readiness | Locked for Phase 27 on 2026-06-24 | Docs must be precise about what was actually proven. [VERIFIED: 27-CONTEXT.md] |
| Commit-log-like changelog entries | Human-readable grouped changelog with `Unreleased`, change types, and ISO dates | Keep a Changelog 1.1.0 | Phase entry should be concise and user-visible. [CITED: https://keepachangelog.com/en/1.1.0/] |
| Parsed webhook params in app handlers | Exact raw request body before parsing/transformation | Paddle and Plug docs current on 2026-06-24 | Phoenix examples must show app-owned raw-body capture. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] [CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |

**Deprecated/outdated:**

- Public docs implying direct subscription creation are outdated for this SDK and Paddle Billing. [CITED: https://developer.paddle.com/api-reference/subscriptions]
- Public docs implying Oarlock is official Paddle software or Stripe-compatible conflict with the brand book. [VERIFIED: prompts/oarlock-brand-book.md]
- Public docs using v2.1 as a Hex release number conflict with the planning-vs-release distinction in the phase context and changelog. [VERIFIED: 27-CONTEXT.md + CHANGELOG.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Paddle.PortalSessions` is likely an older or alternate module that was not hidden when the scoped module was added. | Common Pitfalls | Planner might choose the wrong remediation; requires maintainer confirmation before hiding/deprecating. |
| A2 | Frameworks usually parse JSON before handlers unless configured otherwise. | Common Pitfalls | Low; official Paddle and Plug docs still justify raw-body guidance even if framework defaults vary. |
| A3 | "Integration test" ambiguity is a common source of proof overclaiming. | Common Pitfalls | Low; locked decisions already require explicit proof ladder language. |

## Open Questions (RESOLVED)

1. **RESOLVED: What should happen to `Paddle.PortalSessions`?**
   - What we know: It is exported and documented as `create/2`; tests call it in the MockServer test; the seam guide lists `Paddle.Customers.PortalSessions`. [VERIFIED: lib/paddle/portal_sessions.ex + test/paddle/mock_server_test.exs + guides/accrue-seam.md]
   - Resolution: Plan 27-01 classifies `Paddle.PortalSessions.create/2` as a legacy compatibility surface because it ships and is documented, while keeping `Paddle.Customers.PortalSessions.create/2`, `create/3`, and `create/4` as the preferred Accrue/new-integration seam. [VERIFIED: 27-01-PLAN.md]
   - Follow-through: README, seam guide, generated docs, tests, and changelog must agree on that compatibility wording before Phase 27 completes. [VERIFIED: 27-01-PLAN.md + 27-03-PLAN.md]

2. **RESOLVED: Should docs-truth checking live in a Mix task, ExUnit test, or script?**
   - What we know: `Mix.Tasks.Typecheck.Specs`, `check_docs.exs`, `check_examples.exs`, and `test/paddle/seam_test.exs` already demonstrate local patterns. [VERIFIED: codebase grep]
   - Resolution: Plan 27-01 uses the lightest durable option: extend `test/paddle/seam_test.exs` with an explicit live public inventory guard and proof-boundary wording assertions. No broad docs generator, new Mix task, or new dependency is planned. [VERIFIED: 27-01-PLAN.md]
   - Follow-through: Use `mix test test/paddle/seam_test.exs --warnings-as-errors` as the fast seam feedback path, with `mix docs --warnings-as-errors` and the full suite reserved for docs and final sign-off gates. [VERIFIED: 27-VALIDATION.md + 27-03-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | compile/test/docs | yes | 1.19.5 | none needed. [VERIFIED: local command output] |
| Mix | compile/test/docs | yes | 1.19.5 | none needed. [VERIFIED: local command output] |
| Erlang/OTP | Elixir runtime | yes | 28 | none needed. [VERIFIED: local command output] |
| ExDoc | docs generation | yes | locked 0.40.1 | none needed. [VERIFIED: mix deps] |
| Git | status/commit docs | yes | 2.41.0 | none needed. [VERIFIED: local command output] |
| Docker | demo docs may mention container setup | yes | 29.5.2 | Not required for Phase 27 docs validation. [VERIFIED: local command output] |

**Missing dependencies with no fallback:** none found for Phase 27. [VERIFIED: environment audit]

**Missing dependencies with fallback:** none found for Phase 27. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5. [VERIFIED: local command output] |
| Config file | `test/test_helper.exs`. [VERIFIED: file listing] |
| Quick run command | `mix test test/paddle/seam_test.exs --warnings-as-errors`. [VERIFIED: test file exists] |
| Full suite command | `mix test --warnings-as-errors && mix docs --warnings-as-errors`. [VERIFIED: both commands passed locally] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-01 | README, Getting Started, and seam contract match live SDK surface | unit/docs-truth | `mix test test/paddle/seam_test.exs --warnings-as-errors` plus proposed inventory guard | partial; Wave 0 should add/extend guard. [VERIFIED: test exists] |
| DOCS-02 | Demo README describes setup, mock auth, webhook processing, portal handoff, Offline Mode | docs smoke/manual review | `mix docs --warnings-as-errors` plus grep/manual checklist | docs exist; specific automated assertion missing. [VERIFIED: demo/README.md] |
| DOCS-03 | Docs separate SDK from Phoenix/Ecto/provisioning ownership | docs smoke/manual review | `mix docs --warnings-as-errors` plus checklist for banned claims | docs exist; automated assertion missing. [VERIFIED: guides + README] |
| DOCS-04 | Docs distinguish MockServer proof from live Paddle provider-state proof | docs smoke/manual review | `mix docs --warnings-as-errors` plus grep for proof terms | docs exist; automated assertion missing. [VERIFIED: demo/README.md + README.md] |

### Sampling Rate

- **Per task commit:** `mix docs --warnings-as-errors` for docs edits; add `mix test test/paddle/seam_test.exs --warnings-as-errors` when seam inventory/test files are touched. [VERIFIED: commands available]
- **Per wave merge:** `mix test --warnings-as-errors && mix docs --warnings-as-errors`. [VERIFIED: commands passed locally]
- **Phase gate:** Full suite green before `$gsd-verify-work`; include a manual read-through of README, Getting Started, seam contract, demo README, and changelog against DOCS-01..04. [VERIFIED: requirements]

### Wave 0 Gaps

- [ ] Add or extend a docs-truth guard that compares live public inventory to `guides/accrue-seam.md`. [VERIFIED: 27-CONTEXT.md]
- [ ] Add a checklist or assertion for proof-boundary terms so "sandbox verified" cannot appear without evidence. [VERIFIED: 27-CONTEXT.md]
- [ ] Decide and encode the `Paddle.PortalSessions` classification. [VERIFIED: local inventory]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Docs should distinguish Paddle API keys and endpoint secrets by environment; do not log or hardcode secrets. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |
| V3 Session Management | limited | Customer portal URLs should be treated as temporary operational links, not durable app state. [VERIFIED: guides/getting-started.md + lib/paddle/portal_session.ex] |
| V4 Access Control | yes | Docs must say app owns signed-in authorization, provisioning, entitlements, and local persistence. [VERIFIED: 27-CONTEXT.md] |
| V5 Input Validation | yes | Webhook docs must verify raw body before parsing/trusting events. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |
| V6 Cryptography | yes | Use existing `Paddle.Webhooks.verify_signature/4`; do not hand-roll new crypto in docs except explaining Paddle's official algorithm. [VERIFIED: lib/paddle/webhooks.ex] [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |

### Known Threat Patterns for Elixir SDK Docs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Spoofed webhook accepted after JSON parsing | Spoofing / Tampering | Preserve raw body, verify `Paddle-Signature`, then parse event. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |
| Sandbox/live secret mix-up | Information Disclosure / Tampering | Use environment-specific clients and endpoint secrets; docs must label sandbox/live separation. [VERIFIED: 27-CONTEXT.md] |
| Mock proof mistaken for provider proof | Repudiation | Use proof ladder and avoid provider-state claims unless real Paddle run occurred. [VERIFIED: 27-CONTEXT.md] |
| App grants access before verified event | Elevation of Privilege | Docs should make verification and event idempotency part of the before-live checklist. [VERIFIED: 27-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- Local code inventory via `mix run` module introspection - public functions and struct fields. [VERIFIED: local command output]
- `mix help docs`, `mix docs --warnings-as-errors`, `mix test --warnings-as-errors` - local validation commands and results. [VERIFIED: local command output]
- `mix.exs`, `README.md`, `guides/getting-started.md`, `guides/accrue-seam.md`, `demo/README.md`, `CHANGELOG.md`, `lib/paddle/*.ex`, `test/paddle/seam_test.exs`. [VERIFIED: codebase grep]
- `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`. [VERIFIED: required files read]

### Secondary (MEDIUM confidence)

- ExDoc / local task docs - `mix docs --warnings-as-errors`, extras configuration. [VERIFIED: mix help docs] [CITED: https://hexdocs.pm/ex_doc/]
- Plug.Parsers official docs - `:body_reader` raw-body capture pattern. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html]
- Paddle official webhook docs - raw body, signature header, endpoint secret, HMAC/tolerance guidance. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/]
- Paddle official subscription API docs - subscriptions cannot be created directly. [CITED: https://developer.paddle.com/api-reference/subscriptions]
- Keep a Changelog 1.1.0 - human changelog structure and `Unreleased` guidance. [CITED: https://keepachangelog.com/en/1.1.0/]

### Tertiary (LOW confidence)

- Assumptions about the historical origin of `Paddle.PortalSessions` and common terminology ambiguity are marked in the Assumptions Log. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified against local runtime, `mix deps`, and Hex registry output. [VERIFIED: local command output]
- Architecture: HIGH - phase scope and codebase shape are explicit and internally consistent except for `Paddle.PortalSessions`. [VERIFIED: 27-CONTEXT.md + local inventory]
- Pitfalls: MEDIUM - main pitfalls are verified locally or from official docs; historical cause of namespace split is assumed. [VERIFIED: local inventory] [ASSUMED]

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 for local docs patterns; re-check Paddle and Hex docs sooner if provider docs or dependency versions change. [ASSUMED]
