---
phase: 04-transactions-hosted-checkout
plan: "02"
subsystem: payments
tags: [paddle, transactions, hosted-checkout, resource-module, tdd]

# Dependency graph
requires:
  - phase: 01-core-transport-client-setup
    provides: Paddle.Http.request/4 transport boundary plus Paddle.Http.build_struct/2 shallow top-level mapper used to hydrate the transaction and checkout structs
  - phase: 03-core-entities-customers-addresses
    provides: Established resource-module pattern (normalize_attrs / allowlist_attrs / validate_id pipeline + adapter-backed tests) mirrored by Paddle.Customers and Paddle.Customers.Addresses
  - phase: 04-transactions-hosted-checkout
    plan: "01"
    provides: Paddle.Transaction struct (20-field surface + raw_data) and Paddle.Transaction.Checkout struct ({:url, :raw_data}) — the typed surface this plan now wires through the create resource module
provides:
  - Paddle.Transactions.create/2 hosted-checkout bridge that forwards only the Phase 4 curated body shape (customer_id, address_id, items, optional custom_data, optional checkout.url, internal "collection_mode" => "automatic") to POST /transactions
  - Private build_transaction/1 hydration that replaces the shallow checkout map produced by Paddle.Http.build_struct/2 with %Paddle.Transaction.Checkout{} so transaction.checkout.url is a guaranteed dot-access contract
  - Adapter-backed contract coverage in test/paddle/transactions_test.exs that pins method, path, exact JSON body, allowlist behavior, exact validation tuples, %Paddle.Transaction.Checkout{} hydration, %Paddle.Error{} passthrough, and Req.TransportError passthrough
affects:
  - Phase 4 hosted-checkout integration: Paddle.Transactions.create/2 is now the public entry point that returns transaction.checkout.url for end-to-end checkout flows
  - Phase 5 subscriptions: the same map | keyword normalization + allowlist + adapter test pattern is the blueprint for future Paddle.Subscriptions resource module

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Resource module with strict create-only allowlist plus dedicated per-field validation tuples (`:invalid_customer_id`, `:invalid_address_id`, `:invalid_items`, `:invalid_checkout`) layered on top of the established `:invalid_attrs` envelope."
    - "Internal-constant body keys: SDK forces `\"collection_mode\" => \"automatic\"` and ignores any caller-supplied collection_mode to keep a single decisive happy path (D-18/D-19)."
    - "Nested-struct hydration helper: `build_transaction/1` calls `Paddle.Http.build_struct(Transaction, data)` then replaces `:checkout` with `Paddle.Http.build_struct(Checkout, data[\"checkout\"])` when the response includes a checkout map, instead of broadening the shared `build_struct/2` into a recursive mapper."
    - "TDD red/green discipline applied at the resource-module layer: nine adapter-backed tests pin the contract before any implementation lines exist."

key-files:
  created:
    - lib/paddle/transactions.ex
    - test/paddle/transactions_test.exs
  modified: []

key-decisions:
  - "Force `\"collection_mode\" => \"automatic\"` as an internal SDK constant — caller-supplied collection_mode is silently dropped from the body, satisfying D-18/D-19's decisive-defaults rule and keeping the public surface to a single ready hosted-checkout path."
  - "Validate identifiers and items with exact per-field error tuples (`:invalid_customer_id`, `:invalid_address_id`, `:invalid_items`, `:invalid_checkout`) instead of a generic `:invalid_attrs` for non-blank-id failures, so callers can branch on which field is wrong without reading the response body."
  - "Hydrate nested checkout in a private `build_transaction/1` helper inside the resource module rather than extending `Paddle.Http.build_struct/2` into a recursive mapper — keeps the shared mapper minimal and confines the nested-struct policy decision to the transaction module."
  - "Drop `discount_id`, `billing_period`, caller `collection_mode`, `invoice_id`, `currency_code`, and `business_id` at body-build time, eliminating the leak surface for unsupported transaction branches (manual collection, draft, invoice-only) called out in T-04-05."

patterns-established:
  - "Resource-create body curation pattern: `with normalize_attrs -> validate_<id> -> validate_items -> validate_checkout -> build_body -> Http.request -> build_<entity>` — reusable for Phase 5 Subscriptions and any future strict-shape resource."
  - "Per-field validation tuple pattern: each first-class identifier or required nested branch gets its own `:invalid_<field>` atom, layered before the generic `:invalid_attrs` envelope check."
  - "Nested-struct hydration helper pattern: `build_<entity>/1` private function wraps `Http.build_struct/2` and post-processes documented nested branches into their dedicated structs (in this plan, `Paddle.Transaction.Checkout`)."

requirements-completed: [TXN-01, TXN-02]

# Metrics
duration: 2.5min
completed: 2026-04-29
---

# Phase 04 Plan 02: Transactions Resource - Hosted Checkout Bridge Summary

**Implemented `Paddle.Transactions.create/2` as the strict ready hosted-checkout bridge: only Phase 4 curated attrs cross the boundary into POST /transactions, exact per-field validation tuples fire before dispatch, and `transaction.checkout.url` is a dot-accessible `%Paddle.Transaction.Checkout{}` contract on success.**

## Performance

- **Duration:** ~2.5 min
- **Started:** 2026-04-29T02:20:46Z
- **Completed:** 2026-04-29T02:23:13Z
- **Tasks:** 2
- **Files created:** 2
- **Files modified:** 0

## Accomplishments

- Created `lib/paddle/transactions.ex` with a single public function `create(%Paddle.Client{} = client, attrs)` that:
  - Normalizes `map | keyword` attrs through the same `normalize_attrs / normalize_map_keys` pipeline used by `Paddle.Customers` and `Paddle.Customers.Addresses` and returns `{:error, :invalid_attrs}` for any other container.
  - Validates `customer_id` and `address_id` as nonblank binaries, returning the exact tuples `{:error, :invalid_customer_id}` / `{:error, :invalid_address_id}`.
  - Validates `items` as a non-empty list whose entries are maps with a nonblank binary `price_id` and a present `quantity`, normalizing them to `%{"price_id" => ..., "quantity" => ...}` and returning `{:error, :invalid_items}` for any other shape.
  - Validates optional `checkout` as either `%{"url" => url}` or `%{url: url}` with a nonblank binary `url`, normalizing to `%{"url" => url}` and returning `{:error, :invalid_checkout}` otherwise.
  - Builds the request body containing only `customer_id`, `address_id`, `items`, optional `custom_data`, optional `checkout` (with only `url`), and the internal constant `"collection_mode" => "automatic"`. Unsupported caller attrs (`discount_id`, `billing_period`, caller `collection_mode`, `invoice_id`, `currency_code`, `business_id`) are silently dropped.
  - Dispatches through `Paddle.Http.request(client, :post, "/transactions", json: body)` and unwraps the local `%{"data" => data}` envelope.
  - Hydrates the response with a private `build_transaction/1` helper that calls `Paddle.Http.build_struct(Transaction, data)` and then replaces `:checkout` with `Paddle.Http.build_struct(Checkout, data["checkout"])` when `data["checkout"]` is a map, so `transaction.checkout.url` works as documented.
  - Preserves existing `%Paddle.Error{}` and `%Req.TransportError{}` tuples unchanged from `Paddle.Http.request/4`.
- Created `test/paddle/transactions_test.exs` with nine adapter-backed tests covering:
  1. Happy-path POST `/transactions` with the exact JSON body (asserts `address_id`, `checkout.url`, `collection_mode = automatic`, `custom_data`, `customer_id`, and `items` as the only keys).
  2. Hosted-checkout response hydration: asserts `transaction.checkout.url == "https://approved.example.com/checkout?_ptxn=txn_01"` through the nested `%Paddle.Transaction.Checkout{}` struct, plus `transaction.checkout.raw_data == data["checkout"]` and `transaction.raw_data == data`.
  3. Allowlist enforcement: caller-supplied `discount_id`, `billing_period`, `invoice_id`, `currency_code`, `business_id`, and `collection_mode: "manual"` are absent or overridden in the posted body; the body's `collection_mode` is exactly `"automatic"`.
  4. `{:error, :invalid_attrs}` for non-map / non-keyword / nil / list-of-non-tuples / number containers.
  5. `{:error, :invalid_customer_id}` for missing, nil, blank-string, whitespace-only, and non-binary `customer_id`.
  6. `{:error, :invalid_address_id}` for missing, nil, blank-string, whitespace-only, and non-binary `address_id`.
  7. `{:error, :invalid_items}` for missing items, empty list, non-list (string and map), missing `price_id`, blank `price_id`, nil `price_id`, missing `quantity`, and non-map item entries.
  8. `{:error, :invalid_checkout}` for `checkout` as a string, `%{url: nil}`, `%{url: ""}`, `%{url: "   "}`, empty map, and non-binary url.
  9. Non-2xx responses surface as `%Paddle.Error{}` and `Req.TransportError` exceptions surface unchanged.
- Confirmed no regressions: `mix test` went from `1 doctest, 63 tests, 0 failures` baseline to `1 doctest, 72 tests, 0 failures` after Task 2 GREEN, with the plan-specified `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs` reporting `13 tests, 0 failures`.
- Confirmed all four plan acceptance grep checks pass:
  - `grep -n 'def create(%Paddle.Client{} = client, attrs)' lib/paddle/transactions.ex` -> `6:  def create(%Paddle.Client{} = client, attrs) do`
  - `grep -n 'collection_mode' lib/paddle/transactions.ex` -> `24:      "collection_mode" => "automatic"`
  - `grep -n 'Paddle.Transaction.Checkout' lib/paddle/transactions.ex` -> `4:  alias Paddle.Transaction.Checkout`
  - `grep -n '"/transactions"' lib/paddle/transactions.ex` -> `14:           Http.request(client, :post, "/transactions", json: body) do`

## Task Commits

Each task was committed atomically following TDD discipline:

1. **Task 1 (RED): Add failing adapter-backed tests for `Paddle.Transactions.create/2`** — `862e92f` (test)
2. **Task 2 (GREEN): Implement `Paddle.Transactions.create/2` strict hosted-checkout path** — `c0026d4` (feat)

No REFACTOR commit was needed — the resource module was already in its minimal idiomatic shape (single `with` chain, small private helpers, reused normalization style from `Paddle.Customers`).

**Plan metadata commit:** added in the post-summary metadata commit by the executor (this file).

## Files Created/Modified

- `lib/paddle/transactions.ex` — `Paddle.Transactions` resource module exposing `create/2` only, with strict body curation, lightweight per-field validation, optional custom_data/checkout passthrough, internal `"collection_mode" => "automatic"` constant, and private `build_transaction/1` nested-checkout hydration helper.
- `test/paddle/transactions_test.exs` — 9 adapter-backed tests pinning method, path, exact request body, hosted-checkout URL hydration, allowlist behavior, exact validation tuples, and `%Paddle.Error{}` / `Req.TransportError` passthrough.

## Decisions Made

- **`"collection_mode" => "automatic"` is an SDK-internal constant**, not a forwarded caller field. The public API has one decisive ready hosted-checkout path with no mode flag, no draft fallback, and no alternate wrapper return shape, satisfying D-18/D-19. A test specifically asserts that input `collection_mode: "manual"` still results in the posted body containing `"collection_mode" => "automatic"`.
- **Per-field validation tuples** (`:invalid_customer_id`, `:invalid_address_id`, `:invalid_items`, `:invalid_checkout`) layered before the generic `:invalid_attrs` envelope check. This is a tighter contract than `Paddle.Customers.create/2`'s envelope-only validation, and is justified because Phase 4 has more required nested branches that callers will routinely get wrong.
- **Nested checkout hydration in a private resource-module helper** rather than extending `Paddle.Http.build_struct/2` into a recursive mapper. This keeps the shared transport mapper minimal (and shared with all entities), and confines the "checkout is a dot-accessible struct" policy decision to `Paddle.Transactions`, matching the precedent set in 04-PATTERNS.md.
- **Dropped unsupported caller attrs at body-build time** (not at validation time). They normalize through `normalize_map_keys` so they survive the keyword/map normalization step, but they are simply not threaded into the final body in `build_body/5`. This is the same allowlist pattern `Paddle.Customers` uses, applied with a hard-coded curated body shape instead of a `~w(...)` allowlist constant — appropriate because the Phase 4 body has fixed, named slots (no enumerable list of optional caller fields).
- **Items normalization is strict and lossy**: each accepted item becomes exactly `%{"price_id" => price_id, "quantity" => quantity}`. Any extra item-level keys callers might pass (e.g. `proration`, `recurring_interval`, etc.) are silently dropped, matching the Phase 4 "single obvious happy path" decision and avoiding leak of unsupported item-level branches into the request body.
- **Checkout normalization accepts both `%{"url" => url}` and `%{url: url}`** because the resource module already accepts `map | keyword` at the top level — symmetric atom/string acceptance keeps the developer experience consistent. The output is always normalized to string-keyed `%{"url" => url}` so the JSON body and downstream `build_struct/2` mapping both see the canonical key.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Acceptance Criteria Compliance] Inlined `%Paddle.Client{}` pattern in `def create/2` head**
- **Found during:** Task 2 verification (post-implementation)
- **Issue:** The initial GREEN implementation used `alias Paddle.Client` and pattern-matched `def create(%Client{} = client, attrs)`, which compiles and passes all tests, but the plan's first acceptance criterion is an exact-string match: `lib/paddle/transactions.ex` defines `def create(%Paddle.Client{} = client, attrs)`. The aliased form failed `grep -n 'def create(%Paddle.Client{} = client, attrs)' lib/paddle/transactions.ex`.
- **Fix:** Removed `alias Paddle.Client` and inlined the fully-qualified `%Paddle.Client{}` pattern in the function head. No behavior change. Re-ran `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs` -> `13 tests, 0 failures`. Re-ran the grep -> match found at line 6.
- **Files modified:** `lib/paddle/transactions.ex`
- **Commit:** Folded into the Task 2 GREEN commit `c0026d4` before the commit was made (the fix happened during Task 2 verification, before the file was added to the index).

No other deviations. The plan's two TDD tasks (RED then GREEN) were executed in order with no Rule 2 (missing critical functionality) or Rule 3 (blocking issues) auto-fixes triggered. No architectural Rule 4 questions arose. No additional files were touched beyond the two the plan called out (`lib/paddle/transactions.ex`, `test/paddle/transactions_test.exs`).

## Issues Encountered

- **`mix deps.get` required at start.** The worktree had a fresh checkout where `_build` and `deps` were not yet populated for the test environment, so the initial `mix test` baseline run failed with "Unchecked dependencies for environment test". Resolved with a single `mix deps.get` (no version changes — `mix.lock` was unchanged for `req`, `telemetry`, `finch`, `jason`, `mime`, `mint`, `nimble_options`, `nimble_pool`, `hpax`). This is a worktree provisioning concern, not a code issue.
- **Expected RED-phase failures** (`** (UndefinedFunctionError) function Paddle.Transactions.create/2 is undefined`) appeared exactly as planned; all nine tests failed with the same module-not-available message.
- **Acceptance-criterion compliance gap on the function head** — see Deviations -> Auto-fixed Issues above. Caught and fixed before the GREEN commit was finalized.

## TDD Gate Compliance

- **RED gate:** `862e92f test(04-02): add failing adapter-backed tests for Paddle.Transactions.create/2` — test file added, `mix test test/paddle/transactions_test.exs` failed with `9 tests, 9 failures`, all `UndefinedFunctionError` for `Paddle.Transactions.create/2`. Verified that no implementation lines existed at this commit (`ls lib/paddle/transactions*` returned no matches).
- **GREEN gate:** `c0026d4 feat(04-02): implement Paddle.Transactions.create/2 strict hosted-checkout path` — `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs` -> `13 tests, 0 failures`; full `mix test` -> `1 doctest, 72 tests, 0 failures`.
- **REFACTOR gate:** not needed; the module is already minimal — single `with` chain, small private helpers, idiomatic reuse of the `normalize_attrs / normalize_map_keys` pattern from `Paddle.Customers`. No duplication or smell to clean up.

## Threat Mitigations

| Threat ID | Component | Mitigation Implemented |
|-----------|-----------|------------------------|
| T-04-05 | `Paddle.Transactions.create/2` request shaping | `build_body/5` constructs the body from named slots only — `customer_id`, `address_id`, `items`, optional `custom_data`, optional `checkout` (with only `url`), and the internal constant `"collection_mode" => "automatic"`. No iteration over caller attrs into the body, so unsupported branches (`discount_id`, `billing_period`, `invoice_id`, `currency_code`, `business_id`, caller `collection_mode`) cannot leak. Verified by the "drops unsupported caller attrs and forces automatic collection mode" test. |
| T-04-06 | identifier and nested attr validation | `validate_customer_id/1`, `validate_address_id/1`, `validate_items/1`, and `validate_checkout/1` all return exact tuples before any `Paddle.Http.request/4` call, blocking blank/missing/malformed inputs at the SDK boundary. Verified by five dedicated test groups. |
| T-04-07 | response checkout mapping | `build_transaction/1` post-processes `data["checkout"]` into `%Paddle.Transaction.Checkout{}` whenever it is a map, so callers always see a typed dot-accessible struct rather than a leaked string-key map. Verified by the happy-path test asserting `transaction.checkout.url` and `%Paddle.Transaction.Checkout{}` pattern matching. |
| T-04-08 | public API stability | Method (`:post`), path (`/transactions`), exact JSON body shape, exact validation tuples, `%Paddle.Error{}` passthrough, and `Req.TransportError` passthrough are all locked in adapter-backed tests in `test/paddle/transactions_test.exs`. |

## User Setup Required

- **Paddle dashboard configuration is still required for real hosted-checkout flows** (per the plan's `user_setup` block):
  - Set a default payment link domain for the Paddle account used in manual verification (Paddle Dashboard -> Checkout / Payment Links settings).
  - Approve any domain that will be passed through `checkout.url` overrides (Paddle Dashboard -> Checkout domains).
- These are real-API integration prerequisites only — the SDK itself is fully covered by adapter-backed tests in this plan and does not require any environment variables, secrets, or runtime services to run `mix test`.

## Next Phase Readiness

- **Phase 4 hosted-checkout bridge is complete.** TXN-01 ("create recurring transaction returning hosted checkout URL") and TXN-02 ("Return hosted checkout URLs from transaction creation") are both satisfied end-to-end now: the typed entity surface from 04-01 is wired through `Paddle.Transactions.create/2`, and `transaction.checkout.url` is a contract-locked `%Paddle.Transaction.Checkout{}` field.
- **Phase 5 Subscriptions** can directly mirror the resource-module pattern locked here (`normalize_attrs -> validate_<id> -> validate_items -> build_body -> Http.request -> build_<entity>` with adapter-backed tests asserting exact request bodies).
- **No outstanding deferred items.** No `deferred-items.md` entries were added during this plan.

## Self-Check: PASSED

Created files (verified to exist):
- FOUND: lib/paddle/transactions.ex
- FOUND: test/paddle/transactions_test.exs

Commits (verified in git log):
- FOUND: 862e92f (test(04-02): add failing adapter-backed tests for Paddle.Transactions.create/2)
- FOUND: c0026d4 (feat(04-02): implement Paddle.Transactions.create/2 strict hosted-checkout path)

Verification commands (all PASS):
- `mix test test/paddle/transaction_test.exs test/paddle/transactions_test.exs` -> `13 tests, 0 failures`
- `mix test` (full suite) -> `1 doctest, 72 tests, 0 failures` (was 63 before this plan -> +9 transaction-resource tests)
- `grep -n 'def create(%Paddle.Client{} = client, attrs)' lib/paddle/transactions.ex` -> `6:  def create(%Paddle.Client{} = client, attrs) do`
- `grep -n 'collection_mode' lib/paddle/transactions.ex` -> `24:      "collection_mode" => "automatic"`
- `grep -n 'Paddle.Transaction.Checkout' lib/paddle/transactions.ex` -> `4:  alias Paddle.Transaction.Checkout`

---
*Phase: 04-transactions-hosted-checkout*
*Plan: 02*
*Completed: 2026-04-29*
