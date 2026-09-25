# Phase 30: Close gap: DOCS-02/PROOF-02 - demo checkout handoff proof - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the narrow DOCS-02/PROOF-02 gap around the Phoenix demo checkout and
customer portal handoff proof. This phase should make the existing demo proof
credible and durable: a signed-in demo user starts a server-created Paddle
transaction checkout handoff, signed webhook processing updates local demo state,
and a customer portal action redirects to a Paddle-hosted portal URL.

This phase does not add new Paddle API breadth, live Paddle sandbox CI,
production demo deployment certification, a browser automation suite, a
Phoenix/Ecto integration package, or framework-owned billing policy in the core
SDK.

</domain>

<decisions>
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 30 title, dependency on Phase 29, and close-gap
  phase boundary.
- `.planning/REQUIREMENTS.md` — DOCS-02 and PROOF-02 definitions plus out-of-scope
  live Paddle mandatory CI boundary.
- `.planning/PROJECT.md` — Pure SDK constraints, v2.1 adopter-truth goal, and
  current shipped state.
- `.planning/STATE.md` — Phase 30 addition and current release-readiness context.
- `.planning/EVIDENCE.md` — Canonical proof ledger that Phase 30 should update.

### Prior Phase Decisions
- `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md` —
  Proof ladder, docs truth posture, and app-owned Phoenix/Ecto boundary.
- `.planning/phases/27-public-contract-documentation-truth/27-02-SUMMARY.md` —
  Demo runbook work and prior checkout/portal proof issue history.
- `.planning/phases/28-ci-demo-and-package-proof/28-CONTEXT.md` — Demo CI,
  package proof, optional dependency boundary, and deterministic proof posture.
- `.planning/phases/28-ci-demo-and-package-proof/28-02-SUMMARY.md` — Existing
  `demo-postgres`, `package-smoke`, and `optional-deps` CI job additions and
  hosted-run caveat.
- `.planning/phases/28-ci-demo-and-package-proof/28-VALIDATION.md` — Phase 28
  validation contract and demo PostgreSQL CI proof criteria.
- `.planning/phases/29-gsd-state-reconciliation/29-CONTEXT.md` — Evidence
  ledger, active-small/archive-rich posture, and no-overclaim proof language.

### Demo and CI Files
- `demo/README.md` — Demo runbook and proof-boundary language to keep aligned
  with actual proof.
- `demo/test/demo_web/integration/billing_flow_test.exs` — Existing
  PhoenixTest flow; currently the checkout proof is too weak.
- `demo/lib/demo_web/live/admin_live/index.ex` — Checkout and portal LiveView
  handoff behavior.
- `demo/assets/js/app.js` — Client hook that opens the checkout URL pushed by
  the LiveView.
- `demo/lib/demo_web/controllers/webhook_controller.ex` — Demo-owned webhook
  verification, inbox, and subscription projection.
- `demo/lib/demo_web/endpoint.ex` — Demo Phoenix endpoint and raw-body reader
  integration point.
- `demo/lib/demo_web/cache_body_reader.ex` — Demo raw-body capture helper.
- `demo/config/test.exs` — Demo PostgreSQL test configuration.
- `demo/test/test_helper.exs` — MockServer test startup and base URL override.
- `.github/workflows/ci.yml` — Existing `demo-postgres` job and CI contract.
- `bin/package_smoke.sh` — Package proof helper, relevant only to avoid
  confusing Phase 30 with package smoke scope.

### Brand and Research Prompts
- `prompts/oarlock-brand-book.md` — Newer brand source: calm, precise,
  provider-native, independent from Paddle, no app-level framework promise.
- `prompts/oarlock-master-context.md` — Core SDK DNA: explicit clients, typed
  responses, CI excellence, secure webhooks, no framework coupling.
- `prompts/paddle-elixir-lib-deep-research.md` — Paddle Billing API shape,
  webhook raw-body requirements, and Elixir SDK architecture tradeoffs.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` —
  Hosted checkout as first Accrue slice and transaction-driven recurring flow.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` —
  Strategic rationale for provider-native Paddle support over fake Stripe parity.

### External References Considered
- `https://developer.paddle.com/paddle-js/about/hosted-checkout` — Paddle
  hosted checkout URL behavior and handoff framing.
- `https://developer.paddle.com/build/customers/integrate-customer-portal` —
  Paddle customer portal links as hosted handoffs.
- `https://developer.paddle.com/api-reference/customer-portals/create-customer-portal-session`
  — Customer portal session API and temporary hosted-session semantics.
- `https://developer.paddle.com/webhooks/about/signature-verification` —
  Paddle webhook signature verification and raw-body trust boundary.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` — Direct
  LiveView test assertions for push events and redirects.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — LiveView
  `push_event/3` and redirect behavior.
- `https://hexdocs.pm/plug/Plug.Parsers.html` — Plug `body_reader` hook for
  raw request body capture.
- `https://docs.github.com/actions/using-containerized-services/creating-postgresql-service-containers`
  — GitHub Actions PostgreSQL service container pattern.
- `https://docs.stripe.com/api/customer_portal/sessions` — Successful ecosystem
  precedent for short-lived hosted customer portal sessions.
- `https://github.com/stripe-samples/checkout-one-time-payments` — Successful
  ecosystem precedent for local checkout/webhook samples separated from live
  provider-state proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `demo/test/demo_web/integration/billing_flow_test.exs`: Existing end-to-end
  PhoenixTest journey already covers login, webhook simulation, UI update, and
  portal redirect. It should be strengthened rather than replaced.
- `DemoWeb.AdminLive.Index`: Existing `subscribe_now` and `open_portal` handlers
  already use `Paddle.Transactions.create/3` and `Paddle.PortalSessions.create/2`
  with `base_url` overridden for MockServer.
- `Paddle.MockServer`: Existing deterministic local fixture supports transaction
  and portal paths without real Paddle credentials.
- `.github/workflows/ci.yml`: Existing `demo-postgres` job runs demo tests with a
  PostgreSQL service, matching PROOF-02's CI shape.
- `.planning/EVIDENCE.md`: Existing ledger is the right canonical place for
  final proof classification and caveats.

### Established Patterns
- Oarlock public docs use a proof ladder: local unit/contract tests,
  MockServer-backed demo wiring, sandbox checks only when real credentials are
  used, and live readiness owned by operators.
- Demo code can show Phoenix/Ecto patterns, but core SDK code must stay pure and
  framework-agnostic.
- CI proof should be deterministic by default and use named jobs with direct
  failure attribution.
- Historical proof corrections should be dated and explicit, not hidden by
  silent wording cleanup.

### Integration Points
- Add or adjust demo tests around checkout `push_event` and portal redirect.
- Update `demo/README.md` or related docs only if proof wording no longer
  matches behavior.
- Update `.planning/EVIDENCE.md` with the Phase 30 close-gap proof and caveat.
- Produce Phase 30 verification/summary artifacts with exact commands, local
  results, and hosted CI status when available.

</code_context>

<specifics>
## Specific Ideas

The user asked for one cohesive, research-backed recommendation across all
gray areas, considering Elixir/Phoenix/Plug/Ecto idioms, SRE/devops evidence,
successful billing-library examples, developer ergonomics, user psychology,
JTBD, UI/UX where applicable, and all relevant `prompts/` context.

The recommendation is:
- Strengthen deterministic demo proof, do not expand provider-state scope.
- Use lower-level LiveView assertions where the existing PhoenixTest flow hides
  the checkout handoff artifact.
- Keep docs/user copy provider-native and handoff-oriented.
- Keep evidence durable in `.planning/EVIDENCE.md` plus Phase 30 verification,
  not time-sensitive public documentation.
- Preserve the pure SDK boundary and avoid Cashier/admin-panel drift.

</specifics>

<deferred>
## Deferred Ideas

- Browser-level Playwright/Wallaby proof of the JavaScript checkout hook belongs
  in a future demo-UX certification phase if the demo becomes a showcased app.
- Live Paddle sandbox/provider-state CI belongs in a future release-proof phase
  only if credentials, state isolation, cleanup, and evidence retention are
  designed.
- Optional Plug/Phoenix helpers or a companion integration package are future
  work if repeated adopter mistakes prove docs are insufficient.
- Full billing UX kit, admin UI, route installer, migrations, entitlement
  policy, and local billing mirror remain outside oarlock SDK scope.

</deferred>

---

*Phase: 30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof*
*Context gathered: 2026-06-25*
