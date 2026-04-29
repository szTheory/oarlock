# Architecture Patterns

**Project:** oarlock — milestone v1.1 (Accrue Seam Hardening)
**Researched:** 2026-04-29
**Confidence:** HIGH — based on direct code inspection of the v1.0 surface

---

## (a) `Paddle.Transactions.get/2`

### Placement in `lib/paddle/transactions.ex`

Insert `get/2` between line 7 (`def create/2`) and the first private function (`defp build_body`).
This mirrors `Paddle.Subscriptions` exactly: `get/2` appears at line 13, before `list/2`, before privates.
Idiomatic order in this codebase is public CRUD reads before writes before privates.

```
def get(%Paddle.Client{} = client, transaction_id) ...   ← INSERT HERE (after create/2)
def create(%Paddle.Client{} = client, attrs) ...
defp build_body ...
```

### Implementation pattern — no new private helpers needed

`Subscriptions.get/2` is the direct template:

```elixir
def get(%Paddle.Client{} = client, transaction_id) do
  with :ok <- validate_transaction_id(transaction_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :get, "/transactions/#{URI.encode(transaction_id, &URI.char_unreserved?/1)}") do
    {:ok, build_transaction(data)}
  end
end

defp validate_transaction_id(id) when is_binary(id) do
  if String.trim(id) == "", do: {:error, :invalid_transaction_id}, else: :ok
end

defp validate_transaction_id(_id), do: {:error, :invalid_transaction_id}
```

`build_transaction/1` already exists (lines 35-45) and already handles the nested `:checkout`
hydration via `Http.build_struct(Checkout, checkout_data)`. No new private helper, no change
to `build_transaction/1`. The path encoding helper is an inline expression exactly matching
`encode_path_segment/1` in `subscriptions.ex` — either inline or extract a shared private helper
in `transactions.ex` (prefer inline to avoid cross-module private sharing).

### Telemetry

`Paddle.Http.request/4` (lines 2-15 of `http.ex`) is the single execution boundary. All calls
funnel through it. No telemetry hooks are instrumented inside resource modules; telemetry is
inherited transparently from `req`'s built-in lifecycle. `get/2` inherits this identically to
`create/2`. No new telemetry setup is needed. Confidence: HIGH (direct inspection of `http.ex`).

---

## (b) End-to-end Seam Integration Test

### Location decision

**Recommended:** `test/paddle/seam_test.exs`

Rationale:
- All existing tests live in `test/paddle/` and run in a single `mix test` invocation with
  `async: true`. The seam test must NOT use `async: true` (step-to-step state flows through
  shared adapter closures) — but ExUnit supports mixed async/sync files in the same directory.
- `test/integration/` (option 2) would require `--include integration` tagging to run at all,
  creating a second test discipline that CI must maintain. The seam test is not slow (adapter-
  backed, no live network) and should run on every PR.
- `test/paddle/integration/accrue_seam_test.exs` (option 3) adds a namespace subdirectory for
  no structural benefit; the module would still be `Paddle.AccruSeamTest` or similar.

The seam test is fast enough to be a first-class test, not a separate integration suite.

### Adapter chaining — no brittle `setup_all`

The 6 steps are sequential but each is an independent `Req` call routed through its own
`client_with_adapter/1` call. The correct pattern is a single `test "full seam path"` block
(not multiple tests with shared `setup`) that builds a fresh adapter for each step:

```elixir
test "Accrue seam: customer → address → transaction → webhook → subscription get → cancel" do
  # Step 1 — Customers.create
  customer_client = client_with_adapter(fn req ->
    assert req.url.path == "/customers"
    {req, Req.Response.new(status: 201, body: %{"data" => customer_fixture()})}
  end)
  assert {:ok, %Paddle.Customer{id: "ctm_seam"}} = Paddle.Customers.create(customer_client, ...)

  # Step 2 — Addresses.create
  address_client = client_with_adapter(fn req ->
    assert req.url.path == "/customers/ctm_seam/addresses"
    {req, Req.Response.new(status: 201, body: %{"data" => address_fixture()})}
  end)
  assert {:ok, %Paddle.Address{id: "add_seam"}} = Paddle.Customers.Addresses.create(address_client, "ctm_seam", ...)

  # ... etc.
end
```

Each step uses a freshly constructed `client_with_adapter` closure — no global state, no
`Req.Test.stub` registry, no `setup_all`. This is consistent with every existing test in the
codebase (direct adapter injection, never a named stub process). Do NOT introduce `Req.Test.stub`
or a named test process; those require `async: false` + global process registration and are
inconsistent with the existing adapter pattern.

### Deterministic IDs

Use hardcoded strings with a seam-specific prefix:
- `"ctm_seam01"`, `"add_seam01"`, `"txn_seam01"`, `"sub_seam01"`, `"evt_seam01"`

Do NOT use generated IDs (e.g., `UUID.generate/0`). Generated IDs require correlation across
fixture builders, create non-deterministic test output, and add a dependency. The prefix `_seam`
makes grep-ability instant. Hardcoded strings are the existing convention (all unit tests use
`"ctm_01"`, `"sub_01"`, etc.).

### Webhook fixture — inline HMAC, no helper module

The webhook step requires a raw-body string and a matching `Paddle-Signature` header. The
correct approach is to inline the HMAC computation in the test, borrowing the private helper
pattern from `test/paddle/webhooks_test.exs`:

```elixir
@seam_webhook_secret "pdl_ntfset_seam_secret"
@seam_now 1_700_000_001

defp seam_webhook_header(raw_body),
  do: "ts=#{@seam_now};h1=#{:crypto.mac(:hmac, :sha256, @seam_webhook_secret, "#{@seam_now}:#{raw_body}") |> Base.encode16(case: :lower)}"
```

Do NOT create a `Paddle.Webhooks.Test` module or `test/support/webhook_fixtures.ex`. Reasons:
- `Paddle.Webhooks.Test` would pollute the public namespace with a test-only module.
- A `test/support/` helper module would be shared infrastructure for one test; inline is simpler.
- `webhooks_test.exs` already established the inline `signature_header/3` + `signature/3` pattern
  as the idiomatic approach. The seam test should follow it.

The raw body for the webhook step is a deterministic JSON string (hardcoded, not `Jason.encode!`
of a map, because JSON encoding is non-deterministic for map keys). Define it as a module
attribute: `@txn_completed_body ~s({"event_id":"evt_seam01","event_type":"transaction.completed",...})`.

### Idempotency of the cancel step

The cancel step is adapter-backed (not live), so it is inherently idempotent — the adapter
closure always returns the pre-defined fixture. No teardown is needed. The test comment should
note: "adapter-backed; no live API state is mutated." This is consistent with the Phase 5
comment at the top of `subscriptions_test.exs` warning against live cancellations.

---

## (c) Consumer-Facing Seam Surface Doc

### Location decision

**Recommended:** `guides/accrue-seam.md`

Rationale:
- ExDoc `extras:` renders any `.md` file placed under `guides/` when the entry is added to
  `mix.exs`. This is the idiomatic ExDoc location — the `guides/` dir does not exist yet but
  is the standard convention for rendered non-API narrative pages.
- `lib/paddle/_seam.ex` with `@moduledoc` would be rendered but creates a phantom module in
  the public API namespace, polluting `mix docs` output with a non-functional module.
- `pages/CONSUMER_CONTRACT.md` is an equally valid alternative but `guides/` maps better to
  ExDoc's own naming convention and allows future guide additions (getting-started, phoenix-plug,
  etc.) without renaming the directory.

### ExDoc integration — `mix.exs` changes required

`mix.exs` currently has no `docs:` key (confirmed by inspection). To render the guide, add to
`project/0`:

```elixir
def project do
  [
    ...
    docs: [
      extras: ["guides/accrue-seam.md"],
      groups_for_extras: [
        "Integration Guides": ~r/guides\//
      ]
    ]
  ]
end
```

Also add `{:ex_doc, "~> 0.34", only: :dev, runtime: false}` to `deps/0` if not already
present (not currently in `mix.exs` deps). Confirm with `mix deps.get` before Phase 8 plan
execution.

### Single doc vs per-module split

Use a **single `guides/accrue-seam.md`** document. The consumer contract is about the
*combined seam*, not individual modules. Splitting into five per-module files creates five
navigation entries for what is a single consumer story. The single file should have H2 sections
per resource module (`## Paddle.Customers`, `## Paddle.Transactions`, etc.) which ExDoc renders
as anchor links.

### Relationship to `PROJECT.md`

`PROJECT.md → Integration Consumers` is already the authoritative living record of the seam
and evolves at phase transitions. `guides/accrue-seam.md` is a rendered snapshot of that
section, formatted for a library consumer reading the generated docs. The two serve different
audiences — `PROJECT.md` is internal planning state; `guides/accrue-seam.md` is published
artifact. They should stay in sync but are not the same file.

---

## Build Order and Dependencies

```
Phase 6: Paddle.Transactions.get/2
  └─ lib/paddle/transactions.ex — add get/2 after create/2, add validate_transaction_id/1
  └─ test/paddle/transactions_test.exs — add describe "get/2" block (4 tests: happy path,
     404, :invalid_transaction_id, transport exception)
  └─ No new files.

Phase 7: End-to-end seam integration test
  └─ DEPENDS ON Phase 6: the seam test should exercise Transactions.get/2 at step 3b
     (fetch the transaction just created, asserting %Transaction{checkout: %Checkout{url: _}})
     If Phase 6 is absent, Transactions.get/2 can't appear in the path — the test would be
     incomplete as a seam demonstration. Phase 7 is blocked on Phase 6.
  └─ test/paddle/seam_test.exs — NEW FILE, single test, async: false
  └─ No new lib files.

Phase 8: Consumer-facing seam surface doc
  └─ INDEPENDENT of Phases 6 and 7 in terms of code, but should reflect the complete surface
     (including Transactions.get/2). Ordering: after Phase 6, can run in parallel with Phase 7.
  └─ guides/accrue-seam.md — NEW FILE
  └─ mix.exs — add docs: key with extras/groups_for_extras
  └─ Verify :ex_doc is in deps.
```

**Dependency graph:** Phase 6 → Phase 7. Phase 8 → after Phase 6 (content-complete), can
overlap Phase 7. Tightest dependency is 6 → 7.

---

## Component Boundaries (unchanged from v1.0, confirmed)

| Component | File | v1.1 changes |
|-----------|------|--------------|
| HTTP execution boundary | `lib/paddle/http.ex` | None |
| Transaction resource | `lib/paddle/transactions.ex` | Add `get/2`, `validate_transaction_id/1` |
| Transaction struct | `lib/paddle/transaction.ex` | None |
| Checkout struct | `lib/paddle/transaction/checkout.ex` | None |
| Seam test | `test/paddle/seam_test.exs` | New file |
| Consumer doc | `guides/accrue-seam.md` | New file |
| Build config | `mix.exs` | Add `docs:` key |

---

## Sources

- Direct inspection: `lib/paddle/transactions.ex`, `lib/paddle/subscriptions.ex`,
  `lib/paddle/http.ex`, `test/paddle/subscriptions_test.exs`,
  `test/paddle/transactions_test.exs`, `test/paddle/webhooks_test.exs`,
  `test/test_helper.exs`, `mix.exs`
- `.planning/PROJECT.md`, `.planning/BACKLOG.md`
- ExDoc extras convention: HIGH confidence from existing documentation patterns in similar
  Elixir libraries; no ExDoc config currently in `mix.exs` to contradict.
