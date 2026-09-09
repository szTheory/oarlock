# Phase 26: Advanced Subscription Flows E2E - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Automated E2E test suite for complex upgrade and downgrade subscription scenarios, ensuring the SDK can handle mutations (via the new `Paddle.Subscriptions.update` surface) and properly deserialize complex nested payloads like `scheduled_change`.
</domain>

<decisions>
## Implementation Decisions

### 1. Test Environment (Sandbox vs Mock Server)
- **D-01:** **Use `Paddle.MockServer` as the default for E2E tests.** Keeping tests offline and fast is idiomatic for Elixir library development.
- **D-02:** Build minimal "happy path" stubs for the specific upgrade/downgrade payloads in the mock server. We will *not* attempt to recreate Paddle's complex proration engine in the mock. The mock just returns the expected JSON for a successful upgrade/downgrade.
- **D-03:** Tests should be structured so they can run against the real sandbox on demand (e.g. `@tag :integration`), but default to the mock.

### 2. SDK Surface Expansion
- **D-04:** **Implement pure CRUD `Paddle.Subscriptions.update/3`.** Do not introduce domain helpers like `upgrade/2` or `downgrade/2`.
- **D-05:** This perfectly aligns with `oarlock`'s design principle: pure REST mapping with no framework coupling. The domain logic of upgrade/downgrade belongs in the consuming application (`Accrue`), not `oarlock`.

### 3. Downgrade Behavior (Test Granularity)
- **D-06:** **Verify both immediate and scheduled changes.** The E2E tests must cover an immediate upgrade (items change immediately, triggering proration) and a scheduled downgrade (proration billing_cycle is set to next_billing_period).
- **D-07:** The scheduled downgrade test MUST explicitly assert that the `scheduled_change` struct is populated on the returned subscription, proving the SDK correctly serializes and deserializes this complex nested struct.

### Claude's Discretion
- The specific test file layout and descriptor naming.
- How to structure the `@moduledoc` on `Paddle.Subscriptions.update/3` to guide developers towards proper usage.
- The exact mock payload structures required to simulate the upgrade/downgrade responses.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope and Architecture
- `.planning/ROADMAP.md` — Phase 26 goal and success criteria.
- `.planning/REQUIREMENTS.md` — Active ADV-02 requirement.
- `.planning/research/ARCHITECTURE.md` — Struct mappings and forward compatibility rules.
- `.planning/research/STACK.md` — Req, JSON, and telemetry boundaries.

### Prior Phase Context
- `.planning/phases/25-offline-mode-foundation/25-CONTEXT.md` — The foundation for `Paddle.MockServer`.
- `guides/accrue-seam.md` — Reference for Accrue's integration contracts and locked structures.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Paddle.MockServer`: Used to intercept Req calls in tests without external network hits.
- `%Paddle.Client{}`: The explicit client struct for all API calls.
- `Paddle.Http`: The core transport module (`request/4`, `build_struct/2`).

### Established Patterns
- **Pure REST wrappers:** `update/3` takes `(client, id, params)` just like `Customers.update/3`.
- **Typed Responses:** Returning `{:ok, struct}` or `{:error, %Paddle.Error{}}` with `raw_data` preserving the unmapped fields.
- **Tests:** Using `client_with_adapter` or `Paddle.MockServer` for simulated responses.

### Integration Points
- `lib/paddle/subscriptions.ex` — Needs the `update/3` function added.
- `test/paddle/subscriptions_test.exs` — Direct tests for `update/3`.
- `test/paddle/mock_server_test.exs` or `test/paddle/seam_test.exs` — Where the E2E mock scenarios will be added.
</code_context>

<specifics>
## Specific Ideas

The decisions above are "deep, cohesive, one-shot recommendations" based on idiomatic Elixir/Req patterns and Paddle API behavior. By choosing to use `Paddle.MockServer` for speed and reliability, and providing a pure `update/3` function instead of complex custom actions, we stick strictly to the vision of a "pure, standalone foundation" and avoid domain leaks.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>