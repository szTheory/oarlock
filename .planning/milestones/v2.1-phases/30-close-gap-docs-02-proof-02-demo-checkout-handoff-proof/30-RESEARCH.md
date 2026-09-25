# Phase 30: close-gap-docs-02-proof-02-demo-checkout-handoff-proof - Research

**Researched:** 2026-06-25
**Domain:** Phoenix LiveView demo proof, MockServer-backed Paddle checkout and portal handoff, documentation evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Demo Proof Target
- **D-01:** Treat the target proof as a deterministic MockServer-backed demo
  handoff, not sandbox/live provider-state proof. The proof should cover mock
  login, checkout handoff, signed webhook processing, subscription UI update,
  and customer portal handoff as one coherent Phoenix demo flow.
- **D-02:** Strengthen the checkout proof beyond "clicking Subscribe Now does
  not crash." Planning should add targeted assertions that the LiveView pushes
  an `open_checkout` event with the MockServer checkout URL returned by
  `Paddle.Transactions.create/3`.
- **D-03:** Keep the portal proof as an authenticated hosted-portal handoff.
  Assert that the active demo subscription state exposes the portal action and
  that clicking it redirects to the MockServer portal URL.
- **D-04:** Do not add Playwright, Wallaby, or browser-level JavaScript proof in
  this phase. That would prove the JS hook more directly, but it adds CI
  complexity and still does not prove real Paddle provider state.
- **D-05:** Do not add a live Paddle sandbox or nightly CI workflow in this
  phase. Real provider-state proof remains manual, release-only, or future
  work unless credentials, isolation, cleanup, and evidence capture are solved.

### Elixir/Phoenix Boundary
- **D-06:** Keep oarlock as a pure SDK. The demo owns Phoenix, Ecto, LiveView,
  raw-body capture plumbing, webhook inbox persistence, PubSub updates, and UI
  state. Do not promote demo schemas, routes, LiveViews, or persistence choices
  into the core SDK.
- **D-07:** Use PhoenixTest for the readable user journey where it fits, but use
  targeted `Phoenix.LiveViewTest` assertions for handoff internals that
  PhoenixTest abstracts away, especially `push_event/3` and redirects.
- **D-08:** Keep optional `plug`/`bandit` semantics unchanged. Phase 30 may rely
  on the demo and test dependency set having those dependencies, but it must not
  make core SDK consumers require Phoenix, Ecto, Plug, or Bandit unless they use
  `Paddle.MockServer`.
- **D-09:** Raw-body webhook verification remains a security boundary. The demo
  may show one app-owned Phoenix/Plug `body_reader` shape, but docs and tests
  should keep saying the SDK owns pure verification functions, not app routing
  or persistence policy.

### Documentation and Evidence Scope
- **D-10:** Public docs should change only where they currently overclaim or
  underspecify the handoff proof. Prefer a minimal `demo/README.md` and, only if
  necessary, `README.md` / `guides/getting-started.md` wording pass.
- **D-11:** `.planning/EVIDENCE.md` should remain the canonical requirement
  evidence ledger. Phase 30 should update the DOCS-02/PROOF-02 rows or add a
  clear Phase 30 addendum so future agents can find the final proof class,
  command, caveat, and hosted CI status.
- **D-12:** Detailed commands, local output, CI-monitor notes, and any run URL
  belong in Phase 30 verification/summary artifacts, not in public docs.
- **D-13:** Hosted GitHub Actions status must not be claimed until it is actually
  available. If no pushed run exists for the relevant SHA, record that caveat
  explicitly instead of implying hosted CI passed.
- **D-14:** Do not store noisy CI logs in the repo by default. Preserve durable
  evidence as concise summaries, commands, SHA/run URL when available, and the
  pass/fail status of named jobs.

### Handoff Language and UX/JTBD
- **D-15:** Use provider-native handoff language. Checkout copy should prefer
  "Start checkout" or "Continue to Paddle Checkout," not "Create
  subscription." Paddle creates subscriptions from completed recurring checkout
  or manual billing flows.
- **D-16:** Portal copy should prefer "Manage billing" or "Open Paddle portal,"
  not "Edit subscription here." The demo initiates a short-lived, authenticated,
  provider-hosted billing management session.
- **D-17:** The adopter JTBD is: "As a Phoenix/Elixir SaaS developer, I need to
  hand a signed-in user to Paddle for checkout or billing management, then bring
  trustworthy billing state back through verified webhooks and canonical
  fetches."
- **D-18:** If the demo LiveView is touched, keep it a quiet operational demo:
  status-first cards, clear loading/error states, accessible focus/hover states,
  dark/light behavior preserved, and no marketing hero or framework-like billing
  product shell.
- **D-19:** Hide app backend guts from the demo UI. Expose only what a user needs
  to act: whether the account is active, how to start checkout, how to manage
  billing, and when an action failed. Put implementation boundaries in docs.

### Claude's Discretion
- The planner may choose whether to split the strengthened proof into one
  integration test file or a PhoenixTest journey plus a smaller LiveViewTest
  module, as long as checkout `push_event` and portal redirect proof are direct.
- The planner may choose exact microcopy if it follows the handoff vocabulary
  above and the Oarlock brand book's calm, precise, provider-native voice.
- The planner may update only planning evidence if code inspection shows public
  docs already describe the final behavior accurately.

### the agent's Discretion
Same as "Claude's Discretion" above; the CONTEXT.md does not contain a separate heading with this exact name. [VERIFIED: .planning/phases/30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof/30-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Browser-level Playwright/Wallaby proof of the JavaScript checkout hook belongs
  in a future demo-UX certification phase if the demo becomes a showcased app.
- Live Paddle sandbox/provider-state CI belongs in a future release-proof phase
  only if credentials, state isolation, cleanup, and evidence retention are
  designed.
</user_constraints>

## Summary

Phase 30 should be planned as a narrow proof-hardening and truth-maintenance phase, not as a new SDK capability phase. [VERIFIED: .planning/phases/30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof/30-CONTEXT.md] The existing PhoenixTest file already proves login, signed webhook simulation, subscription UI update, and portal redirect at a user-journey level, but the checkout branch only proves that clicking the button keeps the session on `/admin`. [VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs] A local targeted run passed while logging `Checkout creation failed: :invalid_customer_id`, which means the current checkout proof can pass even when no `open_checkout` event is pushed. [VERIFIED: local command]

The planner should add a direct `Phoenix.LiveViewTest` checkout handoff test that signs in a demo user, mounts `/admin`, triggers the checkout button through the rendered element, and asserts `assert_push_event view, "open_checkout", %{url: "https://sandbox-checkout.paddle.com/mock-checkout-url"}` or the exact MockServer URL after implementation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] That test will likely require a small demo-code fix because `Paddle.Transactions.create/3` currently validates both `customer_id` and `address_id`, while `DemoWeb.AdminLive.Index.subscribe_now` sends only `items` and `custom_data`. [VERIFIED: lib/paddle/transactions.ex; VERIFIED: demo/lib/demo_web/live/admin_live/index.ex]

**Primary recommendation:** Plan one implementation slice: make the demo checkout request satisfy the SDK transaction contract, add direct LiveViewTest assertions for checkout `push_event` and portal redirect, update provider-native UI/docs wording only where needed, then update `.planning/EVIDENCE.md` with a Phase 30 DOCS-02/PROOF-02 addendum and exact local/hosted proof caveats. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Checkout handoff | Demo Phoenix LiveView | Core SDK transaction client | The demo owns UI event handling and app-specific customer/address IDs; the SDK owns `Paddle.Transactions.create/3` request validation and typed transaction response. [VERIFIED: demo/lib/demo_web/live/admin_live/index.ex; VERIFIED: lib/paddle/transactions.ex] |
| Checkout browser opening | Browser / JS hook | Demo LiveView | The LiveView pushes `open_checkout`; `demo/assets/js/app.js` consumes the event and calls Paddle Checkout. Browser-level proof is out of scope by locked decision D-04. [VERIFIED: demo/assets/js/app.js; VERIFIED: 30-CONTEXT.md] |
| Webhook verification | Core SDK pure functions | Demo Phoenix endpoint/controller | `Paddle.Webhooks.verify_signature/4` is the trust primitive; the demo owns Plug raw-body capture, inbox persistence, and subscription projection. [VERIFIED: demo/lib/demo_web/controllers/webhook_controller.ex; CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |
| Subscription UI state | Demo Phoenix/Ecto/PubSub | MockServer fixture input | The demo stores subscription state in `subscriptions` and broadcasts updates; this remains app-owned and not a core SDK responsibility. [VERIFIED: demo/lib/demo/billing/subscription.ex; VERIFIED: demo/lib/demo_web/controllers/webhook_controller.ex] |
| Customer portal handoff | Demo Phoenix LiveView | Core SDK portal-session client | The demo gates portal access on active local subscription state and redirects externally to the MockServer portal URL returned by the SDK call. [VERIFIED: demo/lib/demo_web/live/admin_live/index.ex; VERIFIED: lib/paddle/mock_server/fixtures.ex] |
| Evidence ledger | Planning documentation | Phase verification artifacts | `.planning/EVIDENCE.md` is the canonical proof ledger and should receive the durable proof class and caveats. [VERIFIED: .planning/EVIDENCE.md; VERIFIED: 30-CONTEXT.md] |

## Project Constraints (from AGENTS.md / CLAUDE.md)

No root `./AGENTS.md`, `./CLAUDE.md`, or `./.claude/CLAUDE.md` exists in the working directory. [VERIFIED: local command] No project-local `.claude/skills/` or `.agents/skills/` `SKILL.md` files were found. [VERIFIED: local command]

The nested `demo/AGENTS.md` applies to demo work and is relevant because Phase 30 touches `demo/`. [VERIFIED: demo/AGENTS.md] Actionable demo directives include: run `mix precommit` when done with demo changes, prefer existing `Req` for HTTP, follow Phoenix 1.8 conventions, avoid deprecated Phoenix APIs, use `Phoenix.LiveViewTest`/LazyHTML patterns for LiveView tests, reference key element IDs in tests, avoid raw HTML assertions where selectors can be used, avoid `Process.sleep/1` in tests, use Tailwind/custom CSS without inline scripts, and keep external JS hooks in `assets/js`. [VERIFIED: demo/AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 local; `.tool-versions` managed | Compile and test root/demo projects | Existing repo and CI use Mix/Elixir as the build and test system. [VERIFIED: local command; VERIFIED: .github/workflows/ci.yml] |
| Phoenix | 1.8.8 locked in demo | Demo web framework | The demo is a Phoenix app and `demo/AGENTS.md` gives Phoenix 1.8-specific rules. [VERIFIED: demo/mix.lock via `mix deps`; VERIFIED: demo/AGENTS.md] |
| Phoenix LiveView | 1.1.31 locked in demo | Admin dashboard and direct handoff assertions | `Phoenix.LiveViewTest` provides direct `assert_push_event`, `assert_redirect`, `element`, and `render_click` helpers needed for this gap. [VERIFIED: demo deps; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| PhoenixTest | declared `>= 0.4.0`, resolved 0.11.1 current Hex info | Readable user-journey tests | Existing `billing_flow_test.exs` uses PhoenixTest for login and end-to-end UI flow. [VERIFIED: demo/mix.exs; VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs] |
| Ecto SQL / Postgrex | Ecto SQL 3.14.0, Postgrex 0.22.2 locked | Demo subscription and webhook persistence | Demo tests use PostgreSQL through Ecto sandbox and Phase 28 CI has a `demo-postgres` job. [VERIFIED: demo deps; VERIFIED: demo/test/support/conn_case.ex; VERIFIED: .github/workflows/ci.yml] |
| Plug | 1.19.2 locked | Raw-body capture through `Plug.Parsers` body reader | Plug officially supports custom `body_reader` for caching request bodies before verification. [VERIFIED: demo deps; CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| Paddle.MockServer | local `Paddle.MockServer` | Deterministic checkout and portal fixture | The test helper starts MockServer on port 4448 and points demo clients at it. [VERIFIED: demo/test/test_helper.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| GitHub Actions | existing `ci.yml` | Hosted proof status | Use only to report exact SHA/job status after a pushed run exists; do not claim hosted CI without evidence. [VERIFIED: .github/workflows/ci.yml; VERIFIED: 30-CONTEXT.md] |
| `gh` | 2.95.0 local | Optional hosted run lookup | Useful for Phase 30 verification if a run URL or exact-SHA status needs to be captured. [VERIFIED: local command] |
| PostgreSQL local | psql 14.17; local `pg_isready` accepting | Local demo tests | Required by `mix test` in `demo/`; CI uses a PostgreSQL service container. [VERIFIED: local command; VERIFIED: .github/workflows/ci.yml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Phoenix.LiveViewTest` internals | PhoenixTest only | Rejected by locked decision D-07 because PhoenixTest makes the journey readable but hides the `push_event` artifact this phase must prove. [VERIFIED: 30-CONTEXT.md] |
| Deterministic MockServer proof | Live Paddle sandbox CI | Rejected by locked decisions D-01 and D-05 because provider-state proof needs credentials, isolation, cleanup, and evidence policy. [VERIFIED: 30-CONTEXT.md] |
| LiveView test assertions | Playwright or Wallaby | Rejected by locked decision D-04 because browser JS proof adds CI complexity and still does not prove real Paddle state. [VERIFIED: 30-CONTEXT.md] |

**Installation:**
```bash
# No new packages should be installed for Phase 30.
```

**Version verification:** Use existing lockfiles and `mix deps` for versions; this phase should not update dependencies. [VERIFIED: local command; VERIFIED: 30-CONTEXT.md]

## Package Legitimacy Audit

No external packages should be installed for this phase. [VERIFIED: 30-CONTEXT.md] The GSD `research-plan` and `classify-confidence` seams were unavailable in this local GSD CLI (`Unknown command`), so package-legitimacy checks are unnecessary because the recommendation is no package install. [VERIFIED: local command]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| N/A | N/A | N/A | N/A | N/A | N/A | No package install planned. [VERIFIED: codebase grep] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package install planned]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package install planned]

## Architecture Patterns

### System Architecture Diagram

```text
Signed-in demo user
  -> /admin LiveView
    -> No active subscription?
      -> "Start checkout" button
        -> handle_event("subscribe_now")
          -> build Paddle.Client with MockServer base_url
          -> Paddle.Transactions.create/3 with valid customer/address/items/custom_data
          -> MockServer POST /transactions
          -> %Paddle.Transaction{checkout.url: MockServer checkout URL}
          -> push_event("open_checkout", %{url: checkout_url})
          -> JS hook opens Paddle checkout (not browser-tested in Phase 30)
    -> Signed webhook simulation
      -> Plug body_reader captures raw body
      -> Paddle.Webhooks.verify_signature/4
      -> webhook inbox row
      -> subscription projection upsert
      -> PubSub subscription_updated
      -> LiveView renders active subscription
    -> Active subscription?
      -> "Manage billing" button
        -> handle_event("open_portal")
          -> Paddle.PortalSessions.create/2
          -> MockServer POST /customers/:id/portal-sessions
          -> redirect external: MockServer portal URL
```

### Recommended Project Structure

```text
demo/
├── lib/demo_web/live/admin_live/index.ex          # checkout/portal handoff behavior and copy
├── test/demo_web/live/admin_live_test.exs         # recommended direct LiveViewTest proof
├── test/demo_web/integration/billing_flow_test.exs # keep/adjust readable PhoenixTest journey
├── lib/demo_web/controllers/webhook_controller.ex # existing signed webhook state projection
└── README.md                                      # minimal wording update only if needed
.planning/
└── EVIDENCE.md                                    # DOCS-02/PROOF-02 Phase 30 addendum
```

### Pattern 1: Direct LiveView Handoff Assertion

**What:** Mount the authenticated admin LiveView and assert the checkout `push_event` payload after clicking the real rendered button. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**When to use:** Use for checkout because the current PhoenixTest test can pass even when `Paddle.Transactions.create/3` returns `{:error, :invalid_customer_id}`. [VERIFIED: local command]

**Example:**
```elixir
# Source: Phoenix.LiveViewTest docs and local demo route/auth shape.
import Phoenix.LiveViewTest

conn =
  conn
  |> Phoenix.ConnTest.post("/auth/login")
  |> Phoenix.ConnTest.recycle()

{:ok, view, _html} = live(conn, "/admin")

view
|> element("button", "Start checkout")
|> render_click()

assert_push_event(view, "open_checkout", %{
  url: "https://sandbox-checkout.paddle.com/mock-checkout-url"
})
```

### Pattern 2: Portal Redirect Assertion

**What:** Seed or create active demo subscription state, click the portal button, and assert the external redirect URL. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**When to use:** Use for portal proof because Paddle recommends authenticated customer portal sessions for already signed-in users and warns those sessions are temporary. [CITED: https://developer.paddle.com/build/customers/integrate-customer-portal/]

**Example:**
```elixir
# Source: Phoenix.LiveViewTest docs and local MockServer portal fixture.
{:ok, view, _html} = live(conn, "/admin")

view
|> element("button", "Manage billing")
|> render_click()

{redirect_url, _flash} = assert_redirect(view)
assert redirect_url == "https://sandbox-my.paddle.com/mock-portal-session"
```

### Pattern 3: Keep PhoenixTest as the Journey Layer

**What:** Keep the readable login -> webhook -> active UI -> portal flow in PhoenixTest, but stop relying on it for low-level `push_event` proof. [VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs]

**When to use:** Use PhoenixTest for user-facing state transitions and LiveViewTest for pushed events and redirect internals. [VERIFIED: 30-CONTEXT.md; CITED: https://hexdocs.pm/phoenix_test/PhoenixTest.html]

### Anti-Patterns to Avoid

- **Passing test with logged checkout failure:** The current checkout test passes despite `Checkout creation failed: :invalid_customer_id`; planning must make the test fail when no `open_checkout` event is emitted. [VERIFIED: local command]
- **Testing implementation by calling `handle_event/3` directly:** Use rendered elements so the test proves the template wiring and event name remain aligned. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- **Promoting demo persistence into the SDK:** Demo schemas, PubSub, raw-body reader, and routes remain app-owned. [VERIFIED: 30-CONTEXT.md]
- **Claiming hosted CI without a run:** Only record hosted GitHub Actions success after an exact relevant run exists. [VERIFIED: 30-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView pushed event assertions | Custom mailbox/protocol probing | `Phoenix.LiveViewTest.assert_push_event/4` | It is the framework helper for pushed event assertions. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| LiveView redirect assertions | Manual socket state inspection | `Phoenix.LiveViewTest.assert_redirect/2` | It captures redirect side effects from rendered events. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Webhook raw-body capture | Re-serializing parsed JSON | Plug `body_reader` plus `Paddle.Webhooks.verify_signature/4` | Paddle warns that transforming the raw body breaks signature verification. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/; CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| Hosted portal sessions | App-owned billing management UI | Paddle customer portal session URLs | Paddle describes portal sessions as hosted authenticated links for signed-in users, temporary and not cached. [CITED: https://developer.paddle.com/build/customers/integrate-customer-portal/] |
| Checkout provider simulation | Live sandbox state in PR CI | Existing `Paddle.MockServer` fixture | Locked decisions require deterministic MockServer proof for this phase. [VERIFIED: 30-CONTEXT.md] |

**Key insight:** The phase is not missing a broad E2E framework; it is missing direct assertions at the exact LiveView boundaries where the current user-journey test abstracts away failure. [VERIFIED: local command]

## Common Pitfalls

### Pitfall 1: The Checkout Button Can Fail Silently Under Current Test Coverage
**What goes wrong:** `click_button("Subscribe Now") |> assert_path("/admin")` passes even when checkout creation fails and no checkout event is sent. [VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs; VERIFIED: local command]
**Why it happens:** PhoenixTest verifies the user journey path but does not assert LiveView `push_event` payloads in the current test. [VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs]
**How to avoid:** Add `Phoenix.LiveViewTest.assert_push_event/4` after `render_click/1` against the checkout button. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
**Warning signs:** Test logs show `Checkout creation failed` while the test still passes. [VERIFIED: local command]

### Pitfall 2: Demo Checkout Request Does Not Match SDK Validation
**What goes wrong:** `Paddle.Transactions.create/3` returns `:invalid_customer_id` before MockServer receives the request. [VERIFIED: local command; VERIFIED: lib/paddle/transactions.ex]
**Why it happens:** The SDK validates `customer_id`, `address_id`, and `items`; the demo currently sends only `items` and `custom_data`. [VERIFIED: lib/paddle/transactions.ex; VERIFIED: demo/lib/demo_web/live/admin_live/index.ex]
**How to avoid:** Plan a small demo-owned fix that provides deterministic mock Paddle customer/address IDs or otherwise aligns with the SDK's transaction contract without weakening core SDK validation. [VERIFIED: lib/paddle/transactions.ex]
**Warning signs:** `Paddle.Transactions.create/3` never reaches MockServer and `assert_push_event` times out. [VERIFIED: local command]

### Pitfall 3: Portal Fixture Shape May Drift From Paddle Docs
**What goes wrong:** The local fixture uses `urls.general.url`, while current Paddle docs show `urls.general.overview`. [VERIFIED: lib/paddle/mock_server/fixtures.ex; CITED: https://developer.paddle.com/build/customers/integrate-customer-portal/]
**Why it happens:** The SDK/demo already uses its own `Paddle.PortalSession` struct and fixture shape; Phase 30 is about the existing demo proof, not broad portal API redesign. [VERIFIED: lib/paddle/portal_session.ex; VERIFIED: 30-CONTEXT.md]
**How to avoid:** Assert the current MockServer URL used by the existing demo, and only change public docs if they overclaim current Paddle field shape. [VERIFIED: lib/paddle/mock_server/fixtures.ex]
**Warning signs:** A portal test starts asserting real Paddle response fields instead of local SDK/demo behavior. [VERIFIED: 30-CONTEXT.md]

### Pitfall 4: Public Docs Become a CI Log
**What goes wrong:** Public README or demo README gets noisy local output, CI monitor details, or stale hosted-run claims. [VERIFIED: 30-CONTEXT.md]
**Why it happens:** Evidence and public documentation have different jobs. [VERIFIED: .planning/EVIDENCE.md]
**How to avoid:** Put concise durable proof classes in `.planning/EVIDENCE.md`; put commands and run status in Phase 30 verification/summary artifacts. [VERIFIED: 30-CONTEXT.md]
**Warning signs:** Public docs mention a GitHub run URL or exact command transcript. [VERIFIED: 30-CONTEXT.md]

## Code Examples

Verified patterns from official sources and local code:

### Checkout Push Event Test
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
import Phoenix.LiveViewTest

{:ok, view, _html} = live(conn, "/admin")

view
|> element("button", "Start checkout")
|> render_click()

assert_push_event(view, "open_checkout", %{url: checkout_url})
```

### External Portal Redirect Test
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
view
|> element("button", "Manage billing")
|> render_click()

{url, _flash} = assert_redirect(view)
assert url == "https://sandbox-my.paddle.com/mock-portal-session"
```

### Raw Body Reader Boundary
```elixir
# Source: https://plug.hexdocs.pm/Plug.Parsers.html
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {DemoWeb.CacheBodyReader, :read_body, []},
  json_decoder: Phoenix.json_library()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prove checkout by "button click does not crash" | Assert a concrete `open_checkout` event payload from `Paddle.Transactions.create/3` | Phase 30 planning | Prevents false-positive checkout proof. [VERIFIED: local command] |
| Treat demo proof as provider-state proof | Classify it as deterministic MockServer-backed integration proof | Phase 27-30 context | Keeps DOCS-02/PROOF-02 honest and avoids sandbox/live overclaim. [VERIFIED: .planning/EVIDENCE.md; VERIFIED: 30-CONTEXT.md] |
| Put proof details in public docs | Put durable proof class/caveat in `.planning/EVIDENCE.md` and run output in phase verification | Phase 29-30 context | Keeps public docs adopter-focused and evidence ledger scan-first. [VERIFIED: .planning/EVIDENCE.md; VERIFIED: 30-CONTEXT.md] |

**Deprecated/outdated:**
- `Subscribe Now` / `Manage Subscription` copy: Locked decisions prefer "Start checkout" or "Continue to Paddle Checkout" and "Manage billing" or "Open Paddle portal" if the LiveView is touched. [VERIFIED: 30-CONTEXT.md]
- Silent checkout path assertion: The current `assert_path("/admin")` after clicking checkout is not enough for PROOF-02 close-gap proof. [VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs; VERIFIED: local command]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| N/A | No assumptions; findings are from local code, local commands, phase context, or cited official docs. | All | N/A |

## Open Questions (RESOLVED)

1. **RESOLVED: Use deterministic demo-owned mock customer/address IDs before checkout.**
   - What we know: `Paddle.Transactions.create/3` requires `customer_id` and `address_id`; the current demo checkout request does not provide them. [VERIFIED: lib/paddle/transactions.ex; VERIFIED: demo/lib/demo_web/live/admin_live/index.ex]
   - Resolution: Phase 30 should provide deterministic demo-owned mock IDs from `DemoWeb.AdminLive.Index` or its test setup/AdminLive path when creating the MockServer checkout transaction. The IDs must be non-empty Paddle-style fixture values owned by the demo flow, not SDK defaults or relaxed validation. [VERIFIED: 30-CONTEXT.md; VERIFIED: lib/paddle/transactions.ex]
   - Implementation implication: Keep `Paddle.Transactions.create/3` validation strict; make the demo satisfy the existing contract with deterministic `customer_id` and `address_id` alongside `items` and `custom_data`. [VERIFIED: 30-CONTEXT.md]

2. **RESOLVED: Portal fixture field-name reconciliation is out of Phase 30 scope unless implementation reveals a direct bug.**
   - What we know: Local fixture and LiveView use `urls["general"]["url"]`; current Paddle docs show `urls.general.overview`. [VERIFIED: lib/paddle/mock_server/fixtures.ex; VERIFIED: demo/lib/demo_web/live/admin_live/index.ex; CITED: https://developer.paddle.com/build/customers/integrate-customer-portal/]
   - Resolution: Phase 30 should assert current local SDK/MockServer behavior and the deterministic MockServer portal URL. Do not broaden this close-gap phase into a portal response-shape redesign or public fixture rename. [VERIFIED: 30-CONTEXT.md]
   - Implementation implication: Only touch portal field naming if the planned LiveViewTest exposes a direct bug in the existing `Paddle.PortalSession` struct, MockServer fixture, or demo LiveView handoff path. Otherwise keep local SDK/MockServer semantics unchanged and document the proof boundary. [VERIFIED: 30-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Demo/root tests | Yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: local command] |
| Mix | Build/test commands | Yes | 1.19.5 | None needed. [VERIFIED: local command] |
| PostgreSQL | Demo Ecto tests | Yes locally | psql 14.17; `pg_isready` accepting | GitHub Actions `demo-postgres` service in CI. [VERIFIED: local command; VERIFIED: .github/workflows/ci.yml] |
| GitHub CLI | Optional hosted CI lookup | Yes | 2.95.0 | Manual GitHub web UI lookup. [VERIFIED: local command] |
| Node | Existing CI monitor scripts | Yes | 22.14.0 | Not needed for core Phase 30 local demo proof. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none found for planning/execution. [VERIFIED: local command]

**Missing dependencies with fallback:** none found. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest, PhoenixTest, Ecto SQL sandbox. [VERIFIED: demo/mix.exs; VERIFIED: demo/test/support/conn_case.ex] |
| Config file | `demo/config/test.exs`. [VERIFIED: demo/config/test.exs] |
| Quick run command | `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs` after adding the new LiveView test file. [VERIFIED: demo test layout] |
| Current targeted command | `cd demo && mix test test/demo_web/integration/billing_flow_test.exs --trace` passed locally with 2 tests, 0 failures, while logging checkout failure. [VERIFIED: local command] |
| Full suite command | `cd demo && mix test`; CI also runs demo format, unused deps, compile warnings-as-errors, and tests in `demo-postgres`. [VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-02 gap | Demo runbook and UI language accurately describe mock auth, checkout handoff, webhook processing, portal handoff, and proof boundary. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: demo/README.md] | docs guard/manual grep | `rg -n "Subscribe Now|Manage Subscription|provider-state|MockServer|portal handoff|checkout handoff" demo/README.md README.md guides .planning/EVIDENCE.md` | Existing docs yes; final exact guard TBD by plan. [VERIFIED: codebase grep] |
| PROOF-02 gap | CI/demo proof includes direct checkout `open_checkout` event and portal redirect proof. [VERIFIED: 30-CONTEXT.md] | LiveView integration | `cd demo && mix test test/demo_web/live/admin_live_test.exs` | No; Wave 0 should add it. [VERIFIED: codebase grep] |
| PROOF-02 journey | Mock login, signed webhook processing, subscription UI update, and portal handoff remain coherent. [VERIFIED: demo/test/demo_web/integration/billing_flow_test.exs] | PhoenixTest integration | `cd demo && mix test test/demo_web/integration/billing_flow_test.exs` | Yes. [VERIFIED: codebase grep] |
| Evidence ledger | `.planning/EVIDENCE.md` records Phase 30 proof class, command, caveat, and hosted CI status. [VERIFIED: 30-CONTEXT.md] | docs verification | `rg -n "Phase 30|DOCS-02|PROOF-02|open_checkout|hosted CI" .planning/EVIDENCE.md .planning/phases/30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof` | Ledger exists; Phase 30 addendum not yet. [VERIFIED: .planning/EVIDENCE.md] |

### Sampling Rate

- **Per task commit:** `cd demo && mix test test/demo_web/live/admin_live_test.exs test/demo_web/integration/billing_flow_test.exs` once the new file exists. [VERIFIED: demo test layout]
- **Per wave merge:** `cd demo && mix test` plus any touched docs grep. [VERIFIED: demo/mix.exs]
- **Phase gate:** Full demo suite green, root suite only if core SDK files are touched, evidence ledger updated, and hosted CI status either linked or explicitly caveated. [VERIFIED: 30-CONTEXT.md]

### Wave 0 Gaps

- [ ] `demo/test/demo_web/live/admin_live_test.exs` - direct `Phoenix.LiveViewTest` checkout `assert_push_event` and portal `assert_redirect` proof. [VERIFIED: codebase grep]
- [ ] Test helper or setup function for authenticated LiveView conn - current PhoenixTest journey logs in through UI, but direct LiveViewTest needs a concise authenticated connection setup. [VERIFIED: demo/lib/demo_web/mock_auth.ex; VERIFIED: demo/test/support/conn_case.ex]
- [ ] Demo checkout implementation alignment - current `subscribe_now` lacks SDK-required `customer_id` and `address_id`. [VERIFIED: lib/paddle/transactions.ex; VERIFIED: demo/lib/demo_web/live/admin_live/index.ex]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Demo mock auth remains app-owned and only gates local demo routes; no production auth claims. [VERIFIED: demo/lib/demo_web/mock_auth.ex; VERIFIED: demo/README.md] |
| V3 Session Management | yes | Phoenix session cookie and LiveView authenticated session are demo-owned; no SDK coupling. [VERIFIED: demo/lib/demo_web/endpoint.ex; VERIFIED: demo/lib/demo_web/router.ex] |
| V4 Access Control | yes | Portal handoff is available only after active local subscription state exists in the signed-in demo session. [VERIFIED: demo/lib/demo_web/live/admin_live/index.ex] |
| V5 Input Validation | yes | Keep SDK transaction validation strict; demo must provide valid attrs rather than weakening `Paddle.Transactions.create/3`. [VERIFIED: lib/paddle/transactions.ex] |
| V6 Cryptography | yes | Use `Paddle.Webhooks.verify_signature/4` with exact raw body; do not reimplement signature verification in Phoenix demo code. [VERIFIED: demo/lib/demo_web/controllers/webhook_controller.ex; CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |

### Known Threat Patterns for Phoenix/Paddle Handoff

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged webhook updates local billing state | Spoofing / Tampering | Verify `Paddle-Signature` against exact raw body before parsing or persisting. [CITED: https://developer.paddle.com/webhooks/about/signature-verification/] |
| Raw-body parser changes signed payload | Tampering | Plug custom `body_reader` caches body before JSON decoding. [CITED: https://plug.hexdocs.pm/Plug.Parsers.html] |
| Portal link exposed without signed-in user context | Elevation of privilege | Keep portal action behind authenticated LiveView and active local subscription state. [VERIFIED: demo/lib/demo_web/router.ex; VERIFIED: demo/lib/demo_web/live/admin_live/index.ex] |
| Cached portal URL reused | Information disclosure | Treat Paddle portal sessions as temporary and create a new session per action. [CITED: https://developer.paddle.com/build/customers/integrate-customer-portal/] |
| Overclaiming MockServer as live Paddle proof | Repudiation / process risk | Record proof class and caveat in `.planning/EVIDENCE.md`; do not claim sandbox/live provider-state proof. [VERIFIED: .planning/EVIDENCE.md; VERIFIED: 30-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof/30-CONTEXT.md` - locked scope, proof, docs, UX, and out-of-scope decisions. [VERIFIED: codebase grep]
- `demo/test/demo_web/integration/billing_flow_test.exs` - existing PhoenixTest journey and weak checkout assertion. [VERIFIED: codebase grep]
- `demo/lib/demo_web/live/admin_live/index.ex` - checkout and portal LiveView behavior. [VERIFIED: codebase grep]
- `lib/paddle/transactions.ex` - current SDK transaction validation contract. [VERIFIED: codebase grep]
- `lib/paddle/mock_server/fixtures.ex` - deterministic checkout and portal URLs. [VERIFIED: codebase grep]
- Local command: `cd demo && mix test test/demo_web/integration/billing_flow_test.exs --trace` - current tests pass while checkout logs `:invalid_customer_id`. [VERIFIED: local command]

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - LiveView test helpers for `assert_push_event`, `assert_redirect`, `element`, and `render_click`. [CITED: official docs]
- `https://hexdocs.pm/phoenix_test/PhoenixTest.html` - PhoenixTest journey helpers and behavior. [CITED: official docs]
- `https://plug.hexdocs.pm/Plug.Parsers.html` - custom `body_reader` pattern for cached raw body. [CITED: official docs]
- `https://developer.paddle.com/paddle-js/about/hosted-checkout/` - hosted checkout and transaction handoff concepts. [CITED: official docs]
- `https://developer.paddle.com/build/customers/integrate-customer-portal/` - hosted customer portal session semantics. [CITED: official docs]
- `https://developer.paddle.com/webhooks/about/signature-verification/` - raw-body signature verification requirements. [CITED: official docs]

### Tertiary (LOW confidence)

- None used. [VERIFIED: sources list]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Derived from lockfiles, Mix commands, local versions, and existing CI. [VERIFIED: local command; VERIFIED: codebase grep]
- Architecture: HIGH - Phase boundaries and tier ownership are explicit in 30-CONTEXT and local demo/core files. [VERIFIED: 30-CONTEXT.md; VERIFIED: codebase grep]
- Pitfalls: HIGH - The key pitfall was reproduced by a local passing test with checkout failure log. [VERIFIED: local command]
- External API semantics: MEDIUM - Based on current official docs fetched during research, but Paddle docs can change and local SDK fixture shape differs in one portal field. [CITED: official docs; VERIFIED: codebase grep]

**Research date:** 2026-06-25
**Valid until:** 2026-07-02 for Paddle/Phoenix docs; local code findings valid until touched.
