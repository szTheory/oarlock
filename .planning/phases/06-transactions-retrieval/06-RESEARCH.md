# Phase 6: Transactions Retrieval - Research

**Researched:** 2026-04-29 [VERIFIED: system clock]
**Domain:** Elixir Paddle transaction retrieval seam hardening [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase inspection + official Paddle docs + passing local tests]

<user_constraints>
## User Constraints (from CONTEXT.md)

`06-CONTEXT.md` exists and is copied verbatim below. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md]

### Locked Decisions
- **D-01:** Expose Phase 6 through a narrow `Paddle.Transactions.get/2` only. Do not add `list/2`, `include` params, helper wrappers, or alternate return shapes in this phase.
- **D-02:** `get/2` must return the existing `%Paddle.Transaction{}` entity, not a retrieval-specific wrapper or a second transaction shape.
- **D-03:** Reuse the existing transaction builder and the existing `%Paddle.Transaction.Checkout{}` carve-out so the canonical access path remains `transaction.checkout.url` for both create and get flows.
- **D-04:** Do not promote additional nested transaction payloads to typed structs in Phase 6. `items`, `details`, `payments`, and other nested maps remain lightweight/raw exactly as in Phase 4.
- **D-05:** Keep local validation lightweight and stable: reject only nil, blank, whitespace-only, and non-binary transaction IDs with `{:error, :invalid_transaction_id}`.
- **D-06:** Do not add regex/prefix validation for Paddle IDs. The SDK should not locally overfit to current upstream ID formats or become stricter than Paddle itself.
- **D-07:** Preserve the existing SDK tuple boundary unchanged after local validation:
  - API failures remain `{:error, %Paddle.Error{}}`
  - transport failures remain `{:error, exception}`
- **D-08:** Do not wrap, translate, or normalize upstream Paddle errors beyond the existing `%Paddle.Error{}` boundary already owned by `Paddle.Http`.
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
- **D-12:** Keep create/get transaction behavior symmetrical wherever possible. A developer should learn one transaction entity surface and reuse it across both flows.
- **D-13:** Prefer decisive, researched defaults over reopening narrow implementation questions. For work at this layer, only escalate choices that materially change the public seam or project direction.

### Claude's Discretion
- Exact function placement within `lib/paddle/transactions.ex`, so long as it follows the existing resource-module ordering style.
- Exact fixture contents beyond the locked assertions above, provided they exercise checkout hydration and error propagation clearly.
- Exact wording of docs/typespecs/comments, so long as they reinforce the existing explicit-client, typed-tuple contract.

### Deferred Ideas (OUT OF SCOPE)
- `Paddle.Transactions.list/2`
- Retrieval-time `include` params or related-entity enrichment
- Additional typed nested transaction structs beyond `%Paddle.Transaction.Checkout{}`
- Alternate helpers or convenience wrappers around transaction retrieval
- Any broader transaction lifecycle or mutation surface beyond the current create/get seam
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TXN-03 | Fetch a transaction by ID via `Paddle.Transactions.get/2`, returning a typed `%Paddle.Transaction{}` with hydrated checkout data. [VERIFIED: .planning/REQUIREMENTS.md] | Use `GET /transactions/{transaction_id}` through `Paddle.Http.request/4`, reuse `build_transaction/1`, keep lightweight ID validation, and cover the locked adapter-backed assertions in `test/paddle/transactions_test.exs`. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs; CITED: https://developer.paddle.com/api-reference/transactions/get-transaction] |
</phase_requirements>

## Summary

Phase 6 is a narrow resource-read seam, not a new subsystem. The standard implementation is to mirror `Paddle.Subscriptions.get/2`: validate a binary ID lightly, URL-encode it as a path segment, call `Paddle.Http.request/4`, and map the `"data"` envelope into the already locked `%Paddle.Transaction{}` shape with `%Paddle.Transaction.Checkout{}` hydration when `checkout` is a map. [VERIFIED: lib/paddle/subscriptions.ex; lib/paddle/transactions.ex; lib/paddle/http.ex; CITED: https://developer.paddle.com/api-reference/transactions/get-transaction]

The current workspace already appears to implement that contract. `lib/paddle/transactions.ex` contains `get/2`, `validate_transaction_id/1`, and `transaction_path/1`; `test/paddle/transactions_test.exs` contains focused adapter-backed `get/2` coverage for path, encoding, invalid IDs, API errors, and transport errors; and `test/paddle/seam_test.exs` already exercises `Paddle.Transactions.get/2` inside the broader Accrue seam. The targeted Phase 6 test file passes locally with `17 tests, 0 failures` as of 2026-04-29. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs; test/paddle/seam_test.exs; local command `mix test test/paddle/transactions_test.exs`]

The planning implication is straightforward: start by reconciling artifact state with repository state. If the current implementation is accepted, Phase 6 planning should focus on verification, docs/typespec polish if missing, and release/readiness alignment rather than re-specifying code that already satisfies the locked decisions. If the workspace changes before execution, retain the same seam contract and only plan the missing deltas. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/transactions.ex; test/paddle/transactions_test.exs; test/paddle/seam_test.exs]

**Primary recommendation:** Plan Phase 6 as a symmetry-preserving `get/2` seam on top of the existing transaction builder, and treat the current workspace as likely ahead-of-plan pending final review/reconciliation. [VERIFIED: lib/paddle/transactions.ex; lib/paddle/subscriptions.ex; test/paddle/transactions_test.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Validate transaction ID input | API / Backend [VERIFIED: lib/paddle/transactions.ex] | — | `Paddle.Transactions.get/2` rejects nil, blank, whitespace-only, and non-binary IDs before dispatch. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs] |
| Encode transaction ID into request path | API / Backend [VERIFIED: lib/paddle/transactions.ex] | — | The resource module owns path construction with `URI.encode/2` before calling transport. [VERIFIED: lib/paddle/transactions.ex] |
| Execute `GET /transactions/{id}` | API / Backend [VERIFIED: lib/paddle/transactions.ex; lib/paddle/http.ex] | CDN / Static [VERIFIED: architecture reasoning from codebase boundary] | Resource modules call `Paddle.Http.request/4`, which is the single HTTP execution boundary. [VERIFIED: lib/paddle/http.ex] |
| Normalize Paddle success/error tuples | API / Backend [VERIFIED: lib/paddle/http.ex] | — | `Paddle.Http.request/4` turns 2xx into `{:ok, body}`, non-2xx into `{:error, %Paddle.Error{}}`, and transport issues into `{:error, exception}`. [VERIFIED: lib/paddle/http.ex; CITED: https://developer.paddle.com/api-reference/about/errors] |
| Hydrate typed transaction + checkout structs | API / Backend [VERIFIED: lib/paddle/transactions.ex; lib/paddle/http.ex] | — | `build_transaction/1` reuses `Http.build_struct/2` and only promotes `checkout` into `%Paddle.Transaction.Checkout{}`. [VERIFIED: lib/paddle/transactions.ex; lib/paddle/transaction.ex; lib/paddle/transaction/checkout.ex] |
| Contract testing of retrieval seam | API / Backend [VERIFIED: test/paddle/transactions_test.exs] | — | The project uses inline `Req` adapters inside ExUnit rather than live HTTP or mock servers. [VERIFIED: test/paddle/transactions_test.exs; test/paddle/subscriptions_test.exs; CITED: https://hexdocs.pm/req/Req.html] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` runtime, project constraint `~> 1.19` [VERIFIED: local command `elixir --version`; mix.exs] | SDK implementation language and ExUnit host. [VERIFIED: mix.exs] | The repo is already implemented as a pure Elixir library and Phase 6 requires no language change. [VERIFIED: mix.exs; .planning/PROJECT.md] |
| `req` | `0.5.17`, published 2026-01-05 [VERIFIED: mix.lock; `mix hex.info req`; `https://hex.pm/api/packages/req`] | HTTP client and test adapter seam. [VERIFIED: mix.exs; mix.lock; CITED: https://hexdocs.pm/req/Req.html] | The project already standardizes on `Req` for transport, retries, JSON, and inline adapter-backed tests. [VERIFIED: mix.exs; lib/paddle/http.ex; test/paddle/transactions_test.exs] |
| ExUnit | Bundled with Elixir `1.19.5` [VERIFIED: local command `mix --version`; test files] | Resource contract tests. [VERIFIED: test/paddle/transactions_test.exs] | Existing resource tests use ExUnit consistently, and Phase 6 requires focused adapter-backed unit coverage rather than new infrastructure. [VERIFIED: test/paddle/transactions_test.exs; test/paddle/subscriptions_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `telemetry` | `1.4.1`, published 2026-03-09 [VERIFIED: mix.lock; `mix hex.info telemetry`; `https://hex.pm/api/packages/telemetry`] | Existing transport/observability dependency. [VERIFIED: mix.exs; mix.lock] | Keep as inherited infrastructure through `Req`; no Phase 6-specific telemetry code is needed. [VERIFIED: lib/paddle/http.ex; CITED: https://hexdocs.pm/req/Req.html] |
| `ex_doc` | `0.40.1`, published 2026-01-31 [VERIFIED: mix.lock; `mix hex.info ex_doc`; `https://hex.pm/api/packages/ex_doc`] | Docs generation for already-present guides support. [VERIFIED: mix.exs] | Relevant only if the planner adds docs polish around the retrieval seam; not required to implement `get/2`. [VERIFIED: mix.exs; guides/] |
| `jason` | `1.4.4` locked transitively through `Req` [VERIFIED: mix.lock] | JSON decode in tests and HTTP body handling through `Req`. [VERIFIED: test/paddle/transactions_test.exs; mix.lock] | Reuse for test payload/body assertions; do not introduce alternate JSON tooling. [VERIFIED: test/paddle/transactions_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline `Req` adapter closures for tests [VERIFIED: test/paddle/transactions_test.exs; test/paddle/subscriptions_test.exs] | `Bypass` or cassette/replay tooling [ASSUMED] | The locked phase decisions explicitly reject new test infrastructure, and the existing inline adapter pattern already covers path, body, and error assertions cleanly. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; test/paddle/transactions_test.exs] |
| Reusing `%Paddle.Transaction{}` for create and get [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/transaction.ex] | A retrieval-specific wrapper [ASSUMED] | A second shape would break the Phase 4/Phase 6 symmetry the user already locked. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/transactions.ex] |

**Installation:** Existing dependencies already cover Phase 6. [VERIFIED: mix.exs; mix.lock]

```bash
mix deps.get
```

**Version verification:** [VERIFIED: `mix hex.info req`; `mix hex.info telemetry`; `mix hex.info ex_doc`; `https://hex.pm/api/packages/req`; `https://hex.pm/api/packages/telemetry`; `https://hex.pm/api/packages/ex_doc`]

```bash
mix hex.info req
mix hex.info telemetry
mix hex.info ex_doc
curl -s https://hex.pm/api/packages/req
```

## Architecture Patterns

### System Architecture Diagram

```text
Caller
  -> Paddle.Transactions.get(client, transaction_id)
    -> validate_transaction_id/1
      -> invalid? yes -> {:error, :invalid_transaction_id}
      -> invalid? no
        -> transaction_path/1 + URI.encode/2
          -> Paddle.Http.request(client, :get, "/transactions/{encoded_id}")
            -> Req adapter / real HTTP transport
              -> 2xx {"data": transaction_map}
                -> build_transaction/1
                  -> Http.build_struct(Paddle.Transaction, data)
                  -> checkout map present? yes -> Http.build_struct(Paddle.Transaction.Checkout, checkout)
                  -> checkout map absent? no extra promotion
                -> {:ok, %Paddle.Transaction{}}
              -> non-2xx response
                -> Paddle.Error.from_response/1
                -> {:error, %Paddle.Error{}}
              -> transport exception
                -> {:error, exception}
```

The data flow above matches both the local implementation and the upstream Paddle envelope. [VERIFIED: lib/paddle/transactions.ex; lib/paddle/http.ex; CITED: https://developer.paddle.com/api-reference/transactions/get-transaction; CITED: https://developer.paddle.com/api-reference/about/errors]

### Recommended Project Structure

```text
lib/
├── paddle/transactions.ex          # Public transaction resource functions, including get/create
├── paddle/transaction.ex           # Canonical transaction struct
├── paddle/transaction/checkout.ex  # Nested checkout struct carve-out
└── paddle/http.ex                  # Shared transport and struct-building boundary

test/
└── paddle/transactions_test.exs    # Focused adapter-backed retrieval/create contract tests
```

The recommended structure is already present in the workspace. [VERIFIED: lib/paddle/transactions.ex; lib/paddle/transaction.ex; lib/paddle/transaction/checkout.ex; lib/paddle/http.ex; test/paddle/transactions_test.exs]

### Pattern 1: Sibling-Resource Symmetry

**What:** Model `Paddle.Transactions.get/2` exactly after `Paddle.Subscriptions.get/2`: same explicit `%Paddle.Client{}` argument, same lightweight path-argument validation, same encoded path helper, same `Paddle.Http.request/4` tuple boundary. [VERIFIED: lib/paddle/subscriptions.ex; lib/paddle/transactions.ex]

**When to use:** Any new single-entity retrieval function under a resource module that returns one typed struct from Paddle's `"data"` envelope. [VERIFIED: lib/paddle/subscriptions.ex; .planning/PROJECT.md]

**Example:**

```elixir
# Source: local code pattern in lib/paddle/transactions.ex and lib/paddle/subscriptions.ex
def get(%Client{} = client, transaction_id) do
  with :ok <- validate_transaction_id(transaction_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :get, transaction_path(transaction_id)) do
    {:ok, build_transaction(data)}
  end
end
```

### Pattern 2: Reuse Existing Builder for Typed Hydration

**What:** Call the existing `build_transaction/1` function for both create and get so `checkout` hydration and `raw_data` behavior stay identical across flows. [VERIFIED: lib/paddle/transactions.ex]

**When to use:** Any transaction response from Paddle that should land on the canonical `%Paddle.Transaction{}` surface without promoting additional nested maps. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/transactions.ex]

**Example:**

```elixir
# Source: local code pattern in lib/paddle/transactions.ex
defp build_transaction(data) when is_map(data) do
  transaction = Http.build_struct(Transaction, data)

  case data["checkout"] do
    checkout_data when is_map(checkout_data) ->
      %{transaction | checkout: Http.build_struct(Checkout, checkout_data)}

    _ ->
      transaction
  end
end
```

### Anti-Patterns to Avoid

- **Adding retrieval-only knobs like `include` or `list/2`:** Paddle supports `include` at the HTTP API level, but the phase explicitly defers any caller-visible enrichment surface. [CITED: https://developer.paddle.com/api-reference/transactions/get-transaction; VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md]
- **Over-validating transaction IDs locally:** The user explicitly locked out regex or prefix validation beyond nil/blank/non-binary checks. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md]
- **Promoting extra nested transaction payloads to structs:** `items`, `details`, `payments`, and similar nested objects stay raw in this phase. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/transaction.ex]
- **Introducing new test infrastructure:** The repo already uses inline `Req` adapters and the phase explicitly forbids live tests, cassette tools, and mock servers. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; test/paddle/transactions_test.exs; CITED: https://hexdocs.pm/req/Req.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP execution + non-2xx normalization [VERIFIED: lib/paddle/http.ex] | Per-resource custom error parsing [ASSUMED] | `Paddle.Http.request/4` [VERIFIED: lib/paddle/http.ex] | The project already centralizes success/error tuple handling there, and Phase 6 must preserve that boundary. [VERIFIED: lib/paddle/http.ex; .planning/phases/06-transactions-retrieval/06-CONTEXT.md] |
| Transaction field mapping [VERIFIED: lib/paddle/transactions.ex; lib/paddle/http.ex] | A second retrieval mapper [ASSUMED] | `build_transaction/1` + `Http.build_struct/2` [VERIFIED: lib/paddle/transactions.ex; lib/paddle/http.ex] | Reuse keeps create/get symmetry and preserves `raw_data` consistently. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs] |
| Retrieval test harness [VERIFIED: test/paddle/transactions_test.exs] | New mock server or cassette layer [ASSUMED] | Inline `Req.new(adapter: fn ... end)` [VERIFIED: test/paddle/transactions_test.exs; test/paddle/subscriptions_test.exs; CITED: https://hexdocs.pm/req/Req.html] | The existing adapter seam already provides full path/body/error observability with less complexity. [VERIFIED: test/paddle/transactions_test.exs] |

**Key insight:** This phase is intentionally thin because the complexity already lives in the locked transport boundary and the existing transaction builder. Hand-rolled alternatives mostly create drift against the contract the user already approved. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/http.ex; lib/paddle/transactions.ex]

## Common Pitfalls

### Pitfall 1: Validation Drift on the Public Error Atom

**What goes wrong:** The implementation returns a different local validation atom such as `:invalid_id` or rejects more cases than the locked seam allows. [VERIFIED: .planning/research/PITFALLS.md; .planning/phases/06-transactions-retrieval/06-CONTEXT.md]
**Why it happens:** Retrieval helpers often get copied from memory rather than from the sibling resource pattern. [VERIFIED: lib/paddle/subscriptions.ex; .planning/research/PITFALLS.md]
**How to avoid:** Mirror `validate_subscription_id/1` structure exactly, but return `:invalid_transaction_id`. [VERIFIED: lib/paddle/subscriptions.ex; lib/paddle/transactions.ex]
**Warning signs:** Tests for nil, empty string, whitespace-only string, and non-binary IDs are missing or failing. [VERIFIED: test/paddle/transactions_test.exs]

### Pitfall 2: Checkout Hydration Regresses on GET

**What goes wrong:** `checkout` comes back as a plain map or `checkout.raw_data` points at the transaction root instead of the nested checkout payload. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; test/paddle/transactions_test.exs]
**Why it happens:** A planner or implementer maps the top-level transaction struct but forgets to reuse `build_transaction/1`. [VERIFIED: lib/paddle/transactions.ex]
**How to avoid:** Route both create and get through the same private builder and assert the nested `raw_data` explicitly in tests. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs]
**Warning signs:** `transaction.checkout` is `%{}` or `transaction.checkout.raw_data == transaction.raw_data`. [VERIFIED: test/paddle/transactions_test.exs]

### Pitfall 3: Path Encoding Gets Skipped

**What goes wrong:** Reserved characters in transaction IDs are sent unescaped, producing the wrong request path. [VERIFIED: test/paddle/transactions_test.exs]
**Why it happens:** Implementers interpolate raw IDs into the path string instead of following the subscription helper pattern. [VERIFIED: lib/paddle/subscriptions.ex; lib/paddle/transactions.ex]
**How to avoid:** Keep the private `encode_path_segment/1` helper and test a reserved-character ID. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs]
**Warning signs:** A test ID like `"txn/with?reserved"` produces `/transactions/txn/with?reserved` instead of `/transactions/txn%2Fwith%3Freserved`. [VERIFIED: test/paddle/transactions_test.exs]

### Pitfall 4: Planning Ignores That the Workspace Is Already Ahead

**What goes wrong:** The planner creates implementation tasks that duplicate code already present in the branch, increasing rework risk and muddying verification. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs; test/paddle/seam_test.exs]
**Why it happens:** GSD phase artifacts lag behind active coding in the working tree. [VERIFIED: git status; .planning/STATE.md]
**How to avoid:** Make the first plan step a reconciliation pass against the current branch and downgrade implementation work to review/verification if no delta remains. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs]
**Warning signs:** The branch already has `get/2`, passing retrieval tests, and seam coverage before `06-PLAN.md` exists. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs; test/paddle/seam_test.exs]

## Code Examples

Verified patterns from the current codebase and official Paddle contract:

### Transaction Retrieval Entry Point

```elixir
# Source: lib/paddle/transactions.ex
def get(%Client{} = client, transaction_id) do
  with :ok <- validate_transaction_id(transaction_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :get, transaction_path(transaction_id)) do
    {:ok, build_transaction(data)}
  end
end
```

This example matches Paddle's documented `GET /transactions/{transaction_id}` envelope and the local sibling-resource pattern. [VERIFIED: lib/paddle/transactions.ex; CITED: https://developer.paddle.com/api-reference/transactions/get-transaction]

### Focused Adapter-Backed Contract Test

```elixir
# Source: test/paddle/transactions_test.exs
client =
  client_with_adapter(fn request ->
    assert request.method == :get
    assert request.url.path == "/transactions/txn_01"
    assert request.body == nil

    {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
  end)

assert {:ok, %Transaction{} = transaction} = Transactions.get(client, "txn_01")
assert %Checkout{} = transaction.checkout
assert transaction.checkout.raw_data == response_data["checkout"]
```

This is the standard local testing idiom for resource seams in this project. [VERIFIED: test/paddle/transactions_test.exs; test/paddle/subscriptions_test.exs; CITED: https://hexdocs.pm/req/Req.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| v1.0 exposed transaction creation but left transaction retrieval as a gap for Accrue. [VERIFIED: .planning/PROJECT.md; .planning/STATE.md] | v1.1 Phase 6 closes that gap with `Paddle.Transactions.get/2` on the same typed transaction surface. [VERIFIED: .planning/PROJECT.md; .planning/REQUIREMENTS.md; lib/paddle/transactions.ex] | Milestone v1.1, opened 2026-04-29. [VERIFIED: .planning/STATE.md; .planning/PROJECT.md] | Consumers can reconcile created transactions and later completed transactions without switching response shapes. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; test/paddle/seam_test.exs] |
| A retrieval helper might have introduced `include` controls or alternate wrappers. [ASSUMED] | The locked current approach is a narrow `get/2` only, with no `include` params or extra struct promotion in the SDK surface. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md] | Locked by Phase 6 context on 2026-04-29. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md] | The public seam stays small and easy for Accrue to depend on. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md] |

**Deprecated/outdated:**
- Planning as if transaction retrieval does not exist in the branch is already outdated in the current workspace. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs; test/paddle/seam_test.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Bypass` or cassette/replay tooling are the main realistic alternatives to inline `Req` adapter closures for this kind of test. [ASSUMED] | Standard Stack / Alternatives Considered | Low; the plan still should not adopt them because the locked phase decisions already forbid new test infrastructure. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md] |
| A2 | A retrieval-specific wrapper is the main alternative to reusing `%Paddle.Transaction{}`. [ASSUMED] | Standard Stack / Alternatives Considered | Low; the user already locked the canonical entity surface. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md] |
| A3 | Per-resource custom error parsing and second retrieval mappers are the likely hand-rolled alternatives implementers might reach for. [ASSUMED] | Don't Hand-Roll | Low; the recommended plan is still anchored to verified local abstractions. [VERIFIED: lib/paddle/http.ex; lib/paddle/transactions.ex] |

## Open Questions

1. **Should Phase 6 be planned as implementation work or as reconciliation/verification work?**
   - What we know: The branch already contains `Paddle.Transactions.get/2`, focused retrieval tests, and seam coverage that calls the function. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs; test/paddle/seam_test.exs]
   - What's unclear: Whether the planner should treat those changes as accepted scope or as pre-plan draft work subject to revision. [VERIFIED: git status; absence of `06-PLAN.md`]
   - Recommendation: Make the first plan step a branch reconciliation checkpoint; if no contract delta is found, shift Phase 6 tasks toward review, polish, and release readiness. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile/test Phase 6 code [VERIFIED: mix.exs] | ✓ [VERIFIED: local command `elixir --version`] | `1.19.5` [VERIFIED: local command `elixir --version`] | — |
| Mix | Running tests and dependency inspection [VERIFIED: local commands used in this research] | ✓ [VERIFIED: local command `mix --version`] | `1.19.5` [VERIFIED: local command `mix --version`] | — |
| Node.js | Auxiliary tooling used during research only, not for Phase 6 delivery [VERIFIED: local command `node --version`] | ✓ [VERIFIED: local command `node --version`] | `v22.14.0` [VERIFIED: local command `node --version`] | Not required for planner execution. [VERIFIED: phase scope + mix-based project] |

**Missing dependencies with no fallback:**
- None identified for Phase 6 planning or execution. [VERIFIED: local environment audit; phase scope]

**Missing dependencies with fallback:**
- None identified. [VERIFIED: local environment audit]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Authentication is provided by the existing explicit `%Paddle.Client{}` bearer-token setup, not changed by Phase 6. [VERIFIED: .planning/PROJECT.md; mix.exs] |
| V3 Session Management | no [VERIFIED: phase scope] | This SDK phase has no user session concept. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | no [VERIFIED: phase scope] | Phase 6 only forwards an authenticated client request to Paddle; no local authorization matrix is introduced. [VERIFIED: lib/paddle/transactions.ex; .planning/PROJECT.md] |
| V5 Input Validation | yes [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; lib/paddle/transactions.ex] | Lightweight validation for nil/blank/non-binary IDs plus URL-encoding before interpolation. [VERIFIED: lib/paddle/transactions.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | No new cryptographic code is added in transaction retrieval. [VERIFIED: lib/paddle/transactions.ex] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path injection via reserved characters in transaction IDs [VERIFIED: test/paddle/transactions_test.exs] | Tampering [ASSUMED] | URL-encode the path segment with `URI.encode(id, &URI.char_unreserved?/1)` and test a reserved-character ID. [VERIFIED: lib/paddle/transactions.ex; test/paddle/transactions_test.exs] |
| Unexpected widening of accepted local IDs beyond the locked seam [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md] | Tampering [ASSUMED] | Keep validation intentionally minimal and defer true ID validity to Paddle. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; CITED: https://developer.paddle.com/api-reference/about/paddle-ids] |
| Error-shape drift that hides Paddle request metadata from callers [VERIFIED: lib/paddle/http.ex; test/paddle/transactions_test.exs] | Repudiation [ASSUMED] | Preserve `%Paddle.Error{}` unchanged from `Paddle.Http` so status code, request ID, and upstream code survive. [VERIFIED: lib/paddle/http.ex; test/paddle/transactions_test.exs; CITED: https://developer.paddle.com/api-reference/about/errors] |

## Sources

### Primary (HIGH confidence)
- `lib/paddle/transactions.ex` - current `get/2`, path encoding, validation, and transaction builder reuse. [VERIFIED: codebase file]
- `test/paddle/transactions_test.exs` - focused adapter-backed retrieval contract coverage. [VERIFIED: codebase file]
- `test/paddle/seam_test.exs` - current seam test already calling `Paddle.Transactions.get/2`. [VERIFIED: codebase file]
- `lib/paddle/subscriptions.ex` - sibling `get/2` pattern that Phase 6 should mirror. [VERIFIED: codebase file]
- `lib/paddle/http.ex` - central tuple/error boundary and struct builder. [VERIFIED: codebase file]
- `https://developer.paddle.com/api-reference/transactions/get-transaction` - upstream transaction retrieval endpoint, path parameter, optional `include`, transaction fields, and `checkout` behavior. [CITED: official docs]
- `https://developer.paddle.com/api-reference/about/errors` - upstream error envelope and HTTP failure model. [CITED: official docs]
- `https://developer.paddle.com/api-reference/about/paddle-ids` - current Paddle ID format reference and why local prefix validation should stay deferred. [CITED: official docs]
- `https://hexdocs.pm/req/Req.html` - official `Req` request option and adapter documentation. [CITED: official docs]
- `https://hex.pm/api/packages/req` - current `req` version and publish timestamp. [CITED: official registry]
- `https://hex.pm/api/packages/telemetry` - current `telemetry` version and publish timestamp. [CITED: official registry]
- `https://hex.pm/api/packages/ex_doc` - current `ex_doc` version and publish timestamp. [CITED: official registry]

### Secondary (MEDIUM confidence)
- `.planning/PROJECT.md` - milestone framing and consumer seam intent. [VERIFIED: project doc]
- `.planning/REQUIREMENTS.md` - `TXN-03` requirement text. [VERIFIED: project doc]
- `.planning/STATE.md` - current milestone status and backlog origin for Phase 6. [VERIFIED: project doc]
- `.planning/research/PITFALLS.md` - previously captured failure modes that align with the current branch. [VERIFIED: project doc]

### Tertiary (LOW confidence)
- None beyond the assumptions logged above. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependency choice is required and current versions were verified against Hex plus the local lockfile. [VERIFIED: mix.exs; mix.lock; `mix hex.info req`; `https://hex.pm/api/packages/req`]
- Architecture: HIGH - the relevant modules, tests, and sibling-resource patterns are present in the current branch and align with Paddle's official endpoint contract. [VERIFIED: lib/paddle/transactions.ex; lib/paddle/subscriptions.ex; test/paddle/transactions_test.exs; CITED: https://developer.paddle.com/api-reference/transactions/get-transaction]
- Pitfalls: HIGH - the main risks are directly observable from the locked decisions and from the current contract tests. [VERIFIED: .planning/phases/06-transactions-retrieval/06-CONTEXT.md; test/paddle/transactions_test.exs; .planning/research/PITFALLS.md]

**Research date:** 2026-04-29 [VERIFIED: system clock]
**Valid until:** 2026-05-29 for codebase-local findings; re-check official Paddle and Hex sources sooner if package versions or API docs change. [VERIFIED: source types and their volatility]
