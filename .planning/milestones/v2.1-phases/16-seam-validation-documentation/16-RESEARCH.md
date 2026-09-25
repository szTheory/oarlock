# Phase 16: Seam Validation & Documentation - Research

**Researched:** 2026-06-09
**Domain:** API Documentation & Integration Testing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Append `Paddle.Customers.PortalSessions.create/3` right after Customer creation in `test/paddle/seam_test.exs`.
- **D-02:** Append `Paddle.Adjustments.create/2` (e.g. full refund or credit) after the Transaction is completed and verified via webhook in `test/paddle/seam_test.exs`.
- **D-03:** Add `Paddle.Customers.PortalSessions` and `Paddle.Adjustments` to the "Public Modules" section in `guides/accrue-seam.md`.
- **D-04:** Document `%Paddle.PortalSession{}` and `%Paddle.Adjustment{}` under "Locked Structs" with standard top-level fields as `locked` and `raw_data` as `locked` (contents `opaque`).

### the agent's Discretion
- Exact placement of the test assertions within the flow.
- Minor formatting choices in `guides/accrue-seam.md`.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

## Summary

This phase integrates newly created structs and functions (`Paddle.Customers.PortalSessions` and `Paddle.Adjustments`) into the core seam documentation and tests. The `guides/accrue-seam.md` file acts as the authoritative contract for consumers, and `test/paddle/seam_test.exs` continuously enforces that contract. 

**Primary recommendation:** Use existing `client_with_adapter` mocking patterns in `seam_test.exs` and closely follow the stability tier vocabulary (`locked`, `additive`, `opaque`) when documenting structs in `accrue-seam.md`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Seam Contract Documentation | Documentation | — | `guides/accrue-seam.md` is the canonical source of truth for downstream consumers. |
| End-to-End Contract Validation | Testing | — | `test/paddle/seam_test.exs` simulates the consumer integration path, ensuring the documentation matches runtime capabilities. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | ~> 1.15 | Integration Testing | Default Elixir testing framework, handles async client injection well. |
| Req | ~> 0.4.0 | HTTP Client Mocking | Used extensively in `seam_test.exs` via `Req.Response.new` and `client_with_adapter`. |
| ExDoc | ~> 0.31 | Documentation Generation | Consumes `guides/accrue-seam.md` to generate HTML docs. |

## Package Legitimacy Audit

Step 2: SKIPPED (no external packages or dependencies installed during this phase; phase involves only editing local application code and docs).

## Architecture Patterns

### Pattern 1: One-Shot Client Adapters
**What:** Each step in the `seam_test.exs` lifecycle flow receives a fresh client with a single-purpose Req adapter.
**When to use:** In continuous flow tests where you need to mock distinct sequential HTTP requests without shared state interference.
**Example:**
```elixir
adjustment_client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/adjustments"
    {request, Req.Response.new(status: 201, body: %{"data" => adjustment_payload()})}
  end)
```

### Pattern 2: Documentation Stability Tiers
**What:** The oarlock seam contract enforces a rigid distinction between `locked` (stable), `additive` (extendable), and `opaque` (untyped external data) fields.
**When to use:** When documenting `%Paddle.Adjustment{}` and `%Paddle.PortalSession{}` in `guides/accrue-seam.md`.

### Anti-Patterns to Avoid
- **Reusing Clients in Tests:** Do not reuse `customer_client` for portal sessions. Instantiate a new `client_with_adapter` for every discrete operation.
- **Leaking Internal Fields in Docs:** Do not mark complex provider maps like `items`, `totals`, or `urls` as `locked` inside their inner keys. Mark the outer field as `opaque` to prevent consumer coupling.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP Mocking | Global `meck` or `bypass` servers | `Req` custom adapter closures | Test assertions can be co-located with the request execution cleanly without global state. |
| Test Payloads | Inline map literals inside tests | Extracted payload helpers like `adjustment_payload()` | Keeps the test narrative clean and isolates fixture maintenance. |

## Common Pitfalls

### Pitfall 1: Incorrect Arity Documentation
**What goes wrong:** Documenting `create/3` or `create/4` differently than how they appear in the module docs.
**Why it happens:** Elixir's default arguments (`\\`) mask the explicit arities.
**How to avoid:** In `guides/accrue-seam.md`, use the explicit form `create(client, customer_id, attrs \\ %{}, opts \\ [])` just as other modules do.

### Pitfall 2: Forgetting to document `raw_data`
**What goes wrong:** The struct documentation lacks the `raw_data` row.
**Why it happens:** It's an internal field injected by `Http.build_struct`.
**How to avoid:** Always add `raw_data` as `locked` and its contents as `opaque` per decision D-04.

## Code Examples

### Test Integration Example
```elixir
portal_session_client =
  client_with_adapter(fn request ->
    assert request.method == :post
    assert request.url.path == "/customers/ctm_seam01/portal-sessions"
    {request, Req.Response.new(status: 201, body: %{"data" => portal_session_payload()})}
  end)

assert {:ok, %Paddle.PortalSession{urls: urls} = session} =
         Paddle.Customers.PortalSessions.create(portal_session_client, customer.id)
assert is_map(session.raw_data)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unstructured API clients | Explicit Seam Contracts | Phase 08 | Consumers rely on a single Markdown file to know what features are stable and supported. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `%Paddle.Adjustment{}` fields `items`, `totals`, and `payouts` will be documented as `opaque` because they represent nested data structures directly from the provider. | Architecture Patterns | If they should be `locked`, downstream consumers may be misled about what they can safely pattern match against. |
| A2 | `%Paddle.PortalSession{}` field `urls` will be documented as `opaque` because it is an open map of dynamic links. | Architecture Patterns | Same as A1. |

## Open Questions

None. The decisions from the context file directly address all necessary architectural considerations for the phase.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified; this phase relies purely on existing local mix environment).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Relies on existing API key mechanics in `client_with_adapter` |
| V3 Session Management | no | Handled entirely by Paddle externally (Portal Sessions) |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | Existing standard validation via `Paddle.Internal.Attrs` |
| V6 Cryptography | no | Existing Webhooks signature verification is unchanged |

### Known Threat Patterns for Elixir API Wrappers

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Leaking Tokens | Information Disclosure | The `Inspect` protocol on `%Paddle.PortalSession{}` redacts the `urls` field to prevent leaking short-lived authentication tokens in logs. |

## Sources

### Primary (HIGH confidence)
- `test/paddle/seam_test.exs` - Current test flow.
- `guides/accrue-seam.md` - Target documentation file.
- `lib/paddle/portal_session.ex` and `lib/paddle/adjustment.ex` - Struct definitions.
- `lib/paddle/customers/portal_sessions.ex` and `lib/paddle/adjustments.ex` - Module behavior definitions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir tools.
- Architecture: HIGH - Derived directly from the project's own files.
- Pitfalls: HIGH - Addressed through context directives.

**Research date:** 2026-06-09
**Valid until:** 2026-07-09
