# Phase 27: Public Contract & Documentation Truth - Context

**Gathered:** 2026-06-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Make adopter-facing documentation tell the truth about the SDK that already ships. This phase aligns README, Getting Started, Accrue seam contract, demo runbook, changelog, and generated docs with the current public `Paddle.*` modules, function arities, and proof boundaries. It does not add new SDK capabilities, Phoenix/Ecto integration code, live provider-state CI, or broader Paddle endpoint coverage.

</domain>

<decisions>
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

### Claude's Discretion
- Exact heading names, section ordering, and wording may be adjusted for readability as long as the contract/proof/adopter-journey decisions above hold.
- The planner may choose the lightest reliable verification mechanism for seam drift after inspecting current test and Mix task patterns.
- UI/graphic design is not directly in scope for this docs-only phase. If generated docs or README visual assets are touched, use brand-book accessibility and readability guidance; otherwise prioritize prose and examples.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 27 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — DOCS-01 through DOCS-04 requirements.
- `.planning/PROJECT.md` — Current milestone boundary and core project constraints.
- `.planning/STATE.md` — Current project position and known docs/proof drift.

### Current Public Documentation To Align
- `README.md` — First-read public package documentation.
- `guides/getting-started.md` — Main adopter journey guide.
- `guides/accrue-seam.md` — Canonical human-readable consumer contract and stability vocabulary.
- `guides/telemetry.md` — Public telemetry/debugging guide that should remain consistent with error/request docs.
- `demo/README.md` — Demo app runbook and MockServer proof boundary.
- `CHANGELOG.md` — Human release narrative and breaking/change notes.

### Prompt and Brand Research
- `prompts/oarlock-brand-book.md` — Newer brand, documentation, microcopy, accessibility, tone, and scope guidance. Prefer this over older prompt wording when they conflict.
- `prompts/oarlock-master-context.md` — Core SDK DNA: explicit clients, typed responses, CI/docs quality, secure webhooks, no framework coupling.
- `prompts/paddle-elixir-lib-deep-research.md` — Paddle Billing terminology, raw-body webhook rules, Phoenix/Plug docs strategy, ExDoc/docs/release research prompt, and SDK architecture defaults.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` — Accrue-oriented minimum SDK surface and provider-native boundary.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` — Strategic Paddle-vs-Lemon-Squeezy rationale and ecosystem lessons.

### Public Code Surface To Verify Against Docs
- `lib/paddle/client.ex` — Explicit client creation and sandbox/live/API-version behavior.
- `lib/paddle/error.ex` — Normalized error shape and raw provider data.
- `lib/paddle/webhooks.ex` — Raw-body signature verification and event parsing.
- `lib/paddle/customers.ex` — Customer public functions.
- `lib/paddle/customers/addresses.ex` — Address public functions and pagination.
- `lib/paddle/customers/portal_sessions.ex` — Customer portal session public surface.
- `lib/paddle/transactions.ex` — Transaction create/get public surface and checkout handoff.
- `lib/paddle/subscriptions.ex` — Subscription get/update/list/stream/all/cancel/pause/resume surface.
- `lib/paddle/products.ex` — Product public surface.
- `lib/paddle/prices.ex` — Price public surface.
- `lib/paddle/events.ex` — Event history public surface.
- `lib/paddle/notification_settings.ex` — Notification settings CRUD surface.
- `lib/paddle/adjustments.ex` — Adjustment/refund/credit public surface.
- `lib/paddle/mock_server.ex` — Offline development fixture that must be documented honestly.
- `lib/paddle/internal/pagination.ex` and `lib/paddle/page.ex` — Pagination behavior reflected in docs.

### Prior Decisions To Carry Forward
- `.planning/phases/26-advanced-subscription-flows-e2e/26-CONTEXT.md` — MockServer default proof, sandbox/provider-state as on-demand, pure `Paddle.Subscriptions.update/3` rather than domain helpers.
- `.planning/phases/19-notification-settings-api/19-CONTEXT.md` — Pure CRUD, pass-through provider validation, forward-compatible event names.
- `.planning/phases/17-catalog-api/17-CONTEXT.md` — Avoid eager ORM-like hydration, document provider behavior, avoid regex ID validation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Paddle.Client.new!/1`: Existing explicit client pattern for all docs examples.
- `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1`: Security-critical raw-body workflow to feature prominently.
- `Paddle.Internal.Pagination`, `Paddle.Page`, and resource `stream/*` / `all/*` helpers: Existing pagination behavior that docs must describe consistently, including lazy stream failure behavior.
- `Paddle.MockServer`: Existing offline fixture for demo/integration flows; useful proof, but not a complete Paddle clone.
- Public resource modules under `lib/paddle/*.ex`: Source of truth for shipped modules, arities, return shapes, and structs.

### Established Patterns
- Explicit `%Paddle.Client{}` passing, not global app config.
- Typed `{:ok, struct}` / `{:error, %Paddle.Error{}}` response style with `raw_data` forward-compatibility.
- Provider-native CRUD and REST-shaped functions unless Paddle exposes a real action.
- No Phoenix, Plug, or Ecto coupling in the core SDK; framework examples belong in docs/demo only.
- Mock-backed tests are deterministic local proof; sandbox/live provider behavior should not be implied unless explicitly run.

### Integration Points
- README, Getting Started, seam guide, demo README, and changelog must agree on supported modules and function arities.
- Generated ExDoc/API docs should remain consistent with guides and should not expose internals as public contract.
- Phase 28 will handle CI/demo/package proof; Phase 27 should document the proof boundary but not implement those CI gates unless a minimal docs warning check is chosen as part of docs truth.

</code_context>

<specifics>
## Specific Ideas

Research and user direction favored one coherent docs strategy:
- Hybrid contract truth: human seam guide plus code-verified inventory.
- JTBD-first docs: solve adopter jobs in order rather than listing APIs first.
- Phoenix/Plug/Ecto examples are useful, but must be marked as app-owned code.
- Proof ladder language should be reused verbatim across docs to avoid drift.
- Changelog should be concrete and bounded, not a commit log and not marketing copy.
- Brand-book guidance applies: "provider-native", "explicit", "verified", "typed", "small surface area", "honest", and no official-Paddle or Stripe-compatibility implication.

</specifics>

<deferred>
## Deferred Ideas

- CI demo, downstream package smoke test, and optional dependency verification belong to Phase 28.
- GSD backlog/state/audit reconciliation belongs to Phase 29.
- New SDK endpoints, Phoenix/Ecto helper packages, admin UI, local billing mirror, and live provider-state CI are out of scope for Phase 27.

</deferred>

---

*Phase: 27-Public Contract & Documentation Truth*
*Context gathered: 2026-06-24*
