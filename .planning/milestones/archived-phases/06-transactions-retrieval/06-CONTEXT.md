# Phase 6: Transactions Retrieval - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the Phase 4 retrieval gap by adding a single fetch-by-ID path for transactions. This phase delivers `Paddle.Transactions.get/2` using the already locked `%Paddle.Transaction{}` surface, including `%Paddle.Transaction.Checkout{}` hydration when checkout data is present. It does not expand into transaction listing, `include`-driven enrichment, alternate response shapes, broader nested struct promotion, or any new transaction mutation flows.

</domain>

<decisions>
## Implementation Decisions

### Transaction retrieval contract
- **D-01:** Expose Phase 6 through a narrow `Paddle.Transactions.get/2` only. Do not add `list/2`, `include` params, helper wrappers, or alternate return shapes in this phase.
- **D-02:** `get/2` must return the existing `%Paddle.Transaction{}` entity, not a retrieval-specific wrapper or a second transaction shape.
- **D-03:** Reuse the existing transaction builder and the existing `%Paddle.Transaction.Checkout{}` carve-out so the canonical access path remains `transaction.checkout.url` for both create and get flows.
- **D-04:** Do not promote additional nested transaction payloads to typed structs in Phase 6. `items`, `details`, `payments`, and other nested maps remain lightweight/raw exactly as in Phase 4.

### Validation and error behavior
- **D-05:** Keep local validation lightweight and stable: reject only nil, blank, whitespace-only, and non-binary transaction IDs with `{:error, :invalid_transaction_id}`.
- **D-06:** Do not add regex/prefix validation for Paddle IDs. The SDK should not locally overfit to current upstream ID formats or become stricter than Paddle itself.
- **D-07:** Preserve the existing SDK tuple boundary unchanged after local validation:
  - API failures remain `{:error, %Paddle.Error{}}`
  - transport failures remain `{:error, exception}`
- **D-08:** Do not wrap, translate, or normalize upstream Paddle errors beyond the existing `%Paddle.Error{}` boundary already owned by `Paddle.Http`.

### Verification scope
- **D-09:** Treat `get/2` as a seam contract, not a happy-path convenience. Phase 6 must add focused adapter-backed tests in `test/paddle/transactions_test.exs`.
- **D-10:** The required contract assertions are:
  - request path is `GET /transactions/{id}`
  - reserved characters in transaction IDs are URL-encoded
  - checkout payloads hydrate into `%Paddle.Transaction.Checkout{}`
  - `checkout.raw_data` preserves the nested checkout payload, not the transaction root
  - invalid IDs return `:invalid_transaction_id` without dispatching HTTP
  - API errors preserve `%Paddle.Error{}`
  - transport errors pass through unchanged
- **D-11:** Do not add live-network tests, cassette tools, mock servers, or new test infrastructure for this phase. Reuse the repo's existing inline `Req` adapter pattern.

### Seam and DX posture
- **D-12:** Keep create/get transaction behavior symmetrical wherever possible. A developer should learn one transaction entity surface and reuse it across both flows.
- **D-13:** Prefer decisive, researched defaults over reopening narrow implementation questions. For work at this layer, only escalate choices that materially change the public seam or project direction.

### the agent's Discretion
- Exact function placement within `lib/paddle/transactions.ex`, so long as it follows the existing resource-module ordering style.
- Exact fixture contents beyond the locked assertions above, provided they exercise checkout hydration and error propagation clearly.
- Exact wording of docs/typespecs/comments, so long as they reinforce the existing explicit-client, typed-tuple contract.

</decisions>

<specifics>
## Specific Ideas

- This phase should feel like the transaction-side twin of `Paddle.Subscriptions.get/2`: same tuple behavior, same explicit `%Paddle.Client{}` boundary, same "thin library, strong seam" posture.
- Successful SDKs in Elixir and adjacent ecosystems generally keep retrieval return shapes stable while letting the core entity remain the contract. The lesson to carry forward is "one obvious shape, additive later if real demand appears."
- The main footguns to avoid here are not architecture problems; they are quiet contract regressions:
  - accidentally widening the API with retrieval-only knobs
  - over-validating IDs locally
  - letting `checkout` come back as a plain map or with the wrong `raw_data`
  - relying on seam coverage alone and missing path/error regressions in the unit contract
- User preference carried into this phase: bias toward researched, cohesive defaults and minimize future discuss overhead unless a choice is genuinely public-contract-impacting.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and active requirement
- `.planning/PROJECT.md` — v1.1 goal, explicit-client SDK posture, locked Accrue seam, and out-of-scope boundaries.
- `.planning/REQUIREMENTS.md` — `TXN-03` plus cross-phase tuple/typed-struct constraints.
- `.planning/ROADMAP.md` — Phase 6 goal, success criteria, and narrow retrieval scope.
- `.planning/STATE.md` — Current milestone position and the Accrue-driven reason this phase exists.
- `.planning/BACKLOG.md` — `B-01` rationale and original promotion note for `Paddle.Transactions.get/2`.

### Prior locked decisions
- `.planning/phases/01-core-transport-client-setup/01-CONTEXT.md` — explicit `%Paddle.Client{}` passing, normalized tuple conventions, and transport boundary expectations.
- `.planning/phases/03-core-entities-customers-addresses/03-CONTEXT.md` — resource-module public API pattern, lightweight validation, and typed-entity discipline.
- `.planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md` — locked `%Paddle.Transaction{}` contract, `%Paddle.Transaction.Checkout{}` precedent, and transaction-surface curation.
- `.planning/phases/05-subscriptions-management/05-CONTEXT.md` — direct precedent for `get/2` validation and retrieval semantics on a sibling resource module.

### Milestone research and pitfalls
- `.planning/research/FEATURES.md` — deliverable framing for `Paddle.Transactions.get/2` and the intended adapter-backed coverage.
- `.planning/research/PITFALLS.md` — specific failure modes for Phase 6, especially validation atoms and checkout hydration/raw-data mistakes.
- `.planning/research/ARCHITECTURE.md` — placement and implementation-pattern guidance for `get/2`.
- `.planning/research/STACK.md` — confirms no new dependency or test tool is warranted for this phase.

### Existing seam consumers and coverage
- `test/paddle/seam_test.exs` — downstream seam expectations already exercised by Accrue's end-to-end contract path.

### Paddle API reference
- `https://developer.paddle.com/api-reference/transactions/get-transaction` — upstream transaction retrieval contract.
- `https://developer.paddle.com/api-reference/about/errors` — upstream error envelope and diagnostics.
- `https://developer.paddle.com/api-reference/about/paddle-ids` — current identifier format reference; note that local validation should not overfit to it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/paddle/transactions.ex` — already contains the transaction resource module, path helper, ID validator seam, and the private `build_transaction/1` helper used to hydrate nested checkout data.
- `lib/paddle/transaction.ex` — `%Paddle.Transaction{}` is already locked and tested as the canonical transaction entity.
- `lib/paddle/transaction/checkout.ex` — `%Paddle.Transaction.Checkout{}` already exists and is the only nested transaction struct that Phase 6 should rely on.
- `lib/paddle/http.ex` — existing request/error boundary and struct builder remain the only transport/mapping primitives needed.
- `test/paddle/transactions_test.exs` — existing create-path fixtures and assertions already cover the transaction entity and nested checkout shape.
- `test/paddle/seam_test.exs` — confirms downstream Accrue flow expects `Transactions.get/2` in the seam path.

### Established Patterns
- Public resource functions take `%Paddle.Client{}` explicitly.
- Reads validate path arguments lightly, then delegate to `Paddle.Http.request/4`.
- Success returns `{:ok, struct}`; API failures return `{:error, %Paddle.Error{}}`; transport errors surface unchanged.
- Nested typed structs are promoted only when a stable dot-access path materially improves DX.
- Tests use inline `Req` adapters with deterministic fixtures and no live network.

### Integration Points
- `Paddle.Transactions.get/2` should sit beside `create/2` in `lib/paddle/transactions.ex` and follow the same envelope-handling pattern as `Paddle.Subscriptions.get/2`.
- The private `build_transaction/1` helper is the integration seam that keeps create/get transaction hydration consistent.
- Phase 6 verification should extend `test/paddle/transactions_test.exs` rather than introducing a new test harness.

</code_context>

<deferred>
## Deferred Ideas

- `Paddle.Transactions.list/2`
- Retrieval-time `include` params or related-entity enrichment
- Additional typed nested transaction structs beyond `%Paddle.Transaction.Checkout{}`
- Alternate helpers or convenience wrappers around transaction retrieval
- Any broader transaction lifecycle or mutation surface beyond the current create/get seam

</deferred>

---

*Phase: 06-transactions-retrieval*
*Context gathered: 2026-04-29*
