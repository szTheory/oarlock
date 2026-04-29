# Feature Landscape — v1.1 Accrue Seam Hardening

**Domain:** Elixir Paddle Billing SDK — milestone v1.1
**Researched:** 2026-04-29
**Confidence:** HIGH (all claims grounded in codebase reads + Paddle API docs)

---

## Deliverable A — `Paddle.Transactions.get/2`

**Complexity:** Small
**Landing files:**
- `lib/paddle/transactions.ex` — add `get/2` function
- `test/paddle/transactions_test.exs` — add `describe "get/2"` block

### Table Stakes

| Feature | Why Expected | Notes |
|---------|--------------|-------|
| `GET /transactions/{id}` — returns `{:ok, %Paddle.Transaction{}}` | Mirrors `Subscriptions.get/2`; Accrue needs it for checkout reconciliation | Pattern is exact: `with :ok <- validate_transaction_id(id), {:ok, %{"data" => data}} <- Http.request(client, :get, transaction_path(id)), do: {:ok, build_transaction(data)}` |
| Hydrate `%Transaction.Checkout{}` when `data["checkout"]` is a map | `build_transaction/1` already exists in `transactions.ex:35-44`; reuse verbatim | Checkout is present on GET response exactly as it is on create; no difference in shape |
| Validate transaction ID (nil / blank / non-binary returns `{:error, :invalid_transaction_id}`) | All existing get/2 functions validate before dispatching HTTP | Blank/whitespace/integer/nil — exact same pattern as `validate_subscription_id/1` at `subscriptions.ex:76-80` |
| URL-encode path segment via `URI.encode/2` | Defensive; `subscriptions.ex:96` does this — copy the pattern | `"/transactions/#{encode_path_segment(id)}"` |
| 404 → `{:error, %Paddle.Error{code: "entity_not_found"}}` | `Http.request` already converts non-2xx via `Error.from_response/1`; no extra code needed | Test fixture: status 404, body with `error.code = "entity_not_found"`, assert `%Error{status_code: 404}` |
| Transport exception passthrough (`%Req.TransportError{}`) | Same as every other resource function | Adapter returns `%Req.TransportError{reason: :timeout}` |
| Adapter-backed tests, no live network | Project constraint | `async: true`, `Req.new(adapter: fn ...)` exactly as in `subscriptions_test.exs` |

### Differentiators

| Feature | Value | Notes |
|---------|-------|-------|
| Assert `subscription_id` field threads through | Accrue uses this to correlate transactions to subscriptions | Include in happy-path fixture; document in test comment |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| `include=` query params on GET | Paddle supports `include=address,customer,business,discount,...` but Accrue only needs the base transaction entity. No caller-visible API for `include`. Introduces unnecessary API surface. |
| `Paddle.Transactions.list/2` in this milestone | B-01 is explicitly scoped to retrieval only. List is deferred. |
| Separate `build_transaction/1` — already exists | Do NOT duplicate; call the existing private function from the new `get/2`. |

### Paddle API Notes (HIGH confidence, verified via developer.paddle.com)

- Endpoint: `GET /transactions/{transaction_id}`
- Response shape: `{"data": { ...transaction fields... }}` — identical envelope to subscriptions
- `checkout` key present in data when transaction has checkout details; `nil`/absent when none
- `status` is `"completed"` for paid transactions; `"ready"` for pending
- Standard error envelope: `{"error": {"type": ..., "code": ..., "detail": ..., "errors": [...]}}`
- The `include` parameter supports: `address`, `adjustment`, `adjustments_totals`, `business`, `customer`, `discount`, `available_payment_methods` — none needed for Accrue's slice

---

## Deliverable B — End-to-End Seam Integration Test

**Complexity:** Medium
**Landing file:** `test/paddle/seam_integration_test.exs` (new file)
**Dependencies:** Deliverable A must land first (test step 3.5 optionally calls `Transactions.get/2`)

### Table Stakes

| Feature | Why Expected | Notes |
|---------|--------------|-------|
| Single `test` block, single fixture set | B-02 spec is explicit: "single test, single fixture set" | No `describe`, no fixture chaining across multiple tests — one sequential `test "full Accrue seam contract path" do ... end` |
| Each step uses its own inline adapter | Prevents state leak between steps; matches existing adapter pattern | Each step creates `client_with_adapter(fn request -> ... end)` independently — same helper as used in other test files |
| Step 1: `Customers.create/2` → assert `%Paddle.Customer{id: "ctm_seam"}` | Pins that customer create is reachable | Inline fixture payload |
| Step 2: `Customers.Addresses.create/3` → assert `%Paddle.Address{id: "add_seam"}` | Pins address scoped to that customer | Inline fixture payload |
| Step 3: `Transactions.create/2` → assert `transaction.checkout.url` is a non-empty string | Core Accrue checkout flow | Existing `transaction_payload()` shape; status `"ready"`, checkout present |
| Step 3.5: `Transactions.get/2` → assert same transaction struct returns | Closes B-01 reconciliation loop | Only include after Deliverable A lands; adapter returns same transaction payload |
| Step 4: Webhook verify + parse — `transaction.completed` event | Pins the webhook seam Accrue relies on | See signature production below |
| Step 5: `Subscriptions.get/2` → assert `%Paddle.Subscription{id: "sub_seam"}` | Pins subscription lookup from completed txn | Inline fixture payload with `subscription_id: "sub_seam"` |
| Step 6: `Subscriptions.cancel/2` → assert `%Subscription{status: "active", scheduled_change: %ScheduledChange{action: "cancel"}}` | Exercises cancellation seam | Same payload shape as `subscription_payload_active_with_scheduled_change()` |
| `async: false` | Sequential steps; safer even though adapters are isolated | Explicit comment explaining why |

### Webhook Signature Production (HIGH confidence — derived from `webhooks_test.exs:110-117`)

The test helper in `webhooks_test.exs` already demonstrates the producer side:

```elixir
defp signature_header(raw_body, secret, timestamp) do
  "ts=#{timestamp};h1=#{signature(timestamp, raw_body, secret)}"
end

defp signature(timestamp, raw_body, secret) do
  :crypto.mac(:hmac, :sha256, secret, "#{timestamp}:#{raw_body}")
  |> Base.encode16(case: :lower)
end
```

Copy this private helper verbatim into `seam_integration_test.exs`. Do NOT extract it to a shared module — keep it co-located for readability. The seam test is documentation as much as a test.

**`transaction.completed` fixture shape** (verified via Paddle docs):

```elixir
@seam_timestamp 1_700_000_000
@seam_secret "pdl_ntfset_seam_secret"

def webhook_raw_body do
  Jason.encode!(%{
    "event_id" => "evt_seam_01",
    "event_type" => "transaction.completed",
    "occurred_at" => "2024-04-12T10:37:59Z",
    "notification_id" => "ntf_seam_01",
    "data" => %{
      "id" => "txn_seam",
      "status" => "completed",
      "customer_id" => "ctm_seam",
      "subscription_id" => "sub_seam",
      "checkout" => %{"url" => "https://checkout.paddle.com/checkout/txn_seam"},
      "currency_code" => "USD",
      "collection_mode" => "automatic"
    }
  })
end
```

Pass `now: @seam_timestamp` to `verify_signature/4` to bypass clock skew.

### Differentiators

| Feature | Value | Notes |
|---------|-------|-------|
| Module-level comment explaining test purpose | Future readers treat this as contract documentation | "This test pins the full oarlock surface that Accrue targets..." |
| Inline fixture IDs like `"ctm_seam"`, `"sub_seam"` | Traceable across steps; self-documenting | Consistent prefix makes seam fixtures visually distinct |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Fixture files (`.json`, `priv/test/`) | Extra indirection; B-02 spec says inline responses. Keep all data in the test file. |
| Live/sandbox network calls | Project-wide rule; no `@tag :integration` |
| `setup_all` / shared state between assertions | Defeats the point; each step should fail independently if the contract breaks |
| Testing `Transactions.list/2` or subscription mutations | Out of v1.1 scope per PROJECT.md |

---

## Deliverable C — Consumer-Facing Seam Surface Doc

**Complexity:** Small
**Landing file:** `guides/consumer-contract.md` (new file)
**Dependencies:** Deliverable A and B complete (so all listed functions exist)

### Format Decision

**Use `guides/consumer-contract.md` rendered as an ExDoc extras page.** Rationale:

1. `mix.exs` has no ExDoc dependency yet — when added, `extras: ["guides/consumer-contract.md"]` is one line. The file is readable as plain Markdown even before ExDoc is wired.
2. A `guides/` file is the ExDoc convention for non-module narrative content (same pattern as Phoenix, Oban, Req all use).
3. A top-level `CONSUMER_CONTRACT.md` would require consumers to find it via GitHub; ExDoc renders it in the package docs on HexDocs automatically.
4. `@moduledoc` on individual modules captures per-function docs; the seam doc captures the cross-cutting "what does Accrue care about" view, which belongs in a guide, not a module.

**Stability tier vocabulary** (derived from Elixir community practice and oarlock's existing PROJECT.md language):

| Tier | Meaning |
|------|---------|
| **locked** | No removals or renames without a major version bump. Field additions are safe. |
| **additive** | New fields or functions may appear in minor releases; nothing is removed. |
| **experimental** | May change in any release; not safe to depend on in production code. |
| **not-planned** | Explicitly out of scope; do not design around it. |

### Table Stakes

| Feature | Why Expected | Notes |
|---------|--------------|-------|
| Per-module function signature table: `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, `Paddle.Webhooks` | Accrue needs to know what to call | One table per module: function, arity, return type |
| Per-struct field table with stability tier: `%Paddle.Transaction{}`, `%Paddle.Transaction.Checkout{}`, `%Paddle.Subscription{}`, `%Paddle.Subscription.ScheduledChange{}`, `%Paddle.Subscription.ManagementUrls{}`, `%Paddle.Event{}` | B-03 spec is explicit | Field name, type note, tier (locked / additive) |
| Explicit "not planned" callouts: subscription mutations (`update`, `pause`, `resume`), payment-method portals, refunds, marketplaces | Prevents Accrue from designing around absent features | Match PROJECT.md Out of Scope list |
| Note on `raw_data` field on all structs | This is the forward-compat contract | "Field additions to the Paddle API will appear here before being promoted to named fields." |
| Note on `%Paddle.Error{}` shape | Accrue pattern-matches on `code` | `type`, `code`, `message`, `status_code`, `request_id` |

### Differentiators

| Feature | Value | Notes |
|---------|-------|-------|
| Link from `README.md` to the guide | Discoverability | One-liner in README: "See [Consumer Contract](guides/consumer-contract.md) for the Accrue-facing seam." |
| ExDoc extras wired in `mix.exs` | Guide shows up on HexDocs | Requires adding `ex_doc` dev dep and setting `docs: [extras: [...]]` |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Generating the doc from typespecs or macros | This is a docs-only file; no new code. PROJECT.md says "purely a rendered surface map." |
| Documenting internal modules (`Paddle.Http`, `Paddle.Internal.*`) | These are not part of the consumer seam |
| Stability tiers beyond the four named above | More tiers adds confusion without value for a small library |
| Duplicating function docs already in `@moduledoc` / `@doc` | The guide is a summary/index, not a replacement for HexDocs module pages |

---

## Feature Dependencies

```
Deliverable A (Transactions.get/2)
  └─ must land before Deliverable B (seam test uses Transactions.get/2 in Step 3.5)

Deliverable B (seam integration test)
  └─ should land before Deliverable C (doc lists functions that exist)
  └─ the two can merge in the same phase; B is just the natural ordering

Deliverable C (consumer contract doc)
  └─ no code dependency; can be drafted in parallel, merged after A+B
```

## MVP Scope

All three deliverables are MVP for v1.1. Nothing is deferred.

| Deliverable | MVP? | Rationale |
|-------------|------|-----------|
| `Transactions.get/2` | Yes | Unblocks Accrue checkout reconciliation |
| Seam integration test | Yes | Defends the contract; B-02 explicitly deprioritized subscription mutations so this is tractable |
| Consumer contract doc | Yes (small) | B-03 is 0.5 day docs-only; bundle into Phase 7 alongside B-02 |

**Defer:** `Transactions.list/2`, subscription mutations, payment-method portals. None are in v1.1.
