# Technology Stack: v1.1 Accrue Seam Hardening

**Project:** oarlock (Paddle Elixir SDK)
**Milestone:** v1.1
**Researched:** 2026-04-29
**Overall confidence:** HIGH — all conclusions drawn from direct code inspection of the existing
test suite and production modules.

---

## No New Dependencies Required for v1.1

The existing stack covers all three deliverables. No additions to `mix.exs` are needed.

---

## Itemized Rationale

### (a) `Paddle.Transactions.get/2`

No new dependency. This is a pure structural copy of `Paddle.Subscriptions.get/2`
(`lib/paddle/subscriptions.ex:13–18`):

- Same `Http.request/4` call pattern via `Paddle.Http`.
- Same `Http.build_struct/2` hydration for `%Paddle.Transaction{}` and nested
  `%Paddle.Transaction.Checkout{}` (both structs already exist).
- Same `validate_transaction_id/1` guard (mirrors `validate_subscription_id/1`).
- Tests follow the exact pattern in `test/paddle/subscriptions_test.exs` using
  `Req.new(adapter: fn ... end)` inline adapters — no fixture files, no extra libs.

The `transaction_payload/0` helper in `test/paddle/transactions_test.exs` already
provides the full shape of a `%Paddle.Transaction{}` response (including the nested
`checkout` map). The `get/2` tests will reuse this payload directly.

### (b) End-to-End Accrue Seam Integration Test (SEAM-01)

No new dependency. The existing `Req` adapter pattern is fully sufficient for a
multi-step seam test.

**Why the adapter pattern scales to multi-step tests:**

Each call in the seam path gets its own `client_with_adapter/1` scope. The test
composes six independent adapter-backed `%Paddle.Client{}` values — one per
resource call — chained via `with` or sequential assertions in a single ExUnit test
body. The adapter closure captures and returns the pre-canned response for that
step. No shared state, no process isolation issues. This is the same pattern used
across all 23 Phase 5 subscription tests (`test/paddle/subscriptions_test.exs`).

**Webhook step (step 4 — `transaction.completed`):**

No new fixture tooling is needed. `test/paddle/webhooks_test.exs` already
demonstrates the deterministic approach:

1. Build a raw JSON string inline (e.g., `raw_body = ~s({...transaction.completed
   payload...})`).
2. Derive the HMAC-SHA256 signature deterministically using the private
   `signature/3` helper pattern already in that test file (`:crypto.mac/4`).
3. Call `Webhooks.verify_signature/4` with a pinned `now:` timestamp and
   `Webhooks.parse_event/1`.

The `transaction.completed` event payload is structurally identical in shape to
the patterns used in Phase 2 — the `%Paddle.Event{}` struct captures `event_type`
and `data` (raw map). No additional fields on `transaction.completed` require new
struct hydration at the webhook layer; `data` stays as `raw_data` by design.

**Why a richer fixture/replay tool is NOT warranted:**

Tools like `ExVCR` or `Bypass` exist to record/replay real HTTP traffic or stand
up a mock server process. This project does not make live HTTP calls in tests by
design (per the comment at line 4 of `test/paddle/subscriptions_test.exs`). The
`Req` adapter is a function — there is no HTTP process to intercept. `ExVCR` would
add cassette file management overhead with zero benefit. `Bypass` would add a
supervision tree and port management for a pattern already solved inline.

The seam test's only coordination requirement is passing IDs between steps (e.g.,
`transaction_id` returned in step 3, used in step 5's subscription fixture). This
is satisfied by binding the adapter response to a local variable — no inter-process
state needed.

### (c) Consumer-Facing Seam Surface Doc (SEAM-02)

No new dependency. Pure ExDoc with a guide page is the right choice.

**Recommended approach:** A single `guides/consumer-contract.md` file added to
`mix.exs` extras, rendered by `ex_doc` (already part of the established CI matrix
per Phase 1 research). This produces a page under the "Guides" section in
HexDocs — standard Elixir library practice for consumer-facing documentation.

The `.cheatmd` format (`@cheatmd`) is purpose-built for cheatsheets (two-column
grids). It is visually appropriate if the doc is primarily a quick-reference table.
A plain `.md` guide page is better for the prose + table mix that SEAM-02 calls
for (function signatures, stability tiers, explicit "not on roadmap" callouts).
Use a standard guide page.

**Why mkdocs / typedoc-equivalent is NOT appropriate:**

This is a pure Elixir library. External doc sites (mkdocs, docusaurus) introduce a
build pipeline, a separate output artifact, and diverge from where Elixir consumers
expect to find docs (HexDocs). The content is already in the codebase — `@doc`,
`@moduledoc`, and `@spec` annotations. ExDoc renders this correctly without a
second toolchain.

### Dev/CI Tools (`mix_audit`, Contract-Test Linters)

No new dependency.

- **`mix_audit`** — useful for hex vulnerability scanning, but this is a new
  library milestone adding no new hex deps (only code + a guide file). Adding
  `mix_audit` to CI is a valid future step for the project in general, but it
  does not unlock anything for v1.1 and should be a separate backlog entry if
  desired.
- **Contract-test linters** — no Elixir-ecosystem tool in this category applies
  to the oarlock surface (these exist for HTTP API schemas like OpenAPI). The
  seam integration test (SEAM-01) IS the contract test; ExUnit assertions on typed
  structs serve that role directly.
- **`doctor`** (doc coverage) — legitimate long-term addition, but no gap in v1.1
  justifies adding it now. All public functions already carry `@doc` and `@spec`
  from v1.0.

---

## Current Locked Stack (Reference)

| Technology | Version (mix.lock) | Role |
|------------|--------------------|------|
| Elixir | ~> 1.19 | Language |
| req | 0.5.17 | HTTP client + test adapter |
| jason | 1.4.4 | JSON (req transitive dep, used in tests) |
| telemetry | 1.4.1 | Telemetry events |
| finch | 0.21.0 | HTTP transport (req transitive dep) |
| ExUnit | stdlib | Testing |
| ExDoc | (CI, not in mix.exs) | Documentation |
| Credo | (CI, not in mix.exs) | Linting |
| Dialyzer | (CI, not in mix.exs) | Static analysis |

---

## Sources

- Direct inspection: `mix.exs`, `mix.lock`, `test/paddle/subscriptions_test.exs`,
  `test/paddle/transactions_test.exs`, `test/paddle/webhooks_test.exs`,
  `lib/paddle/subscriptions.ex`
- Project context: `.planning/PROJECT.md`, `.planning/BACKLOG.md`
