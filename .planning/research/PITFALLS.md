# Domain Pitfalls: Milestone v1.1 — Accrue Seam Hardening

**Domain:** Elixir SDK extension + seam integration test + consumer contract doc
**Researched:** 2026-04-29
**Confidence:** HIGH — grounded in current repo source and test patterns

---

## A. `Paddle.Transactions.get/2` (Phase 6)

### A-1: Validation error atom mismatched with `Subscriptions.get/2`
**What goes wrong:** `Subscriptions.get/2` returns `{:error, :invalid_subscription_id}`. A copy-paste
implementation returns `{:error, :invalid_id}` or `{:error, :invalid_transaction_id}` — different
enough to silently fail pattern-matches in Accrue code.
**Why it happens:** The atom is embedded in a private guard that nobody reads against the existing module.
**Prevention:** Phase 6 plan must explicitly state the error atom is `:invalid_transaction_id` (mirrors
the `_subscription_id` suffix convention) and include a test case:
`assert {:error, :invalid_transaction_id} = Transactions.get(client, nil)` in
`test/paddle/transactions_test.exs`.

### A-2: `checkout` silently dropped on GET response
**What goes wrong:** `Transactions.create/2` returns `checkout.url` from the POST because the fixture
includes `"checkout"`. A GET response from Paddle for a completed transaction also has a `"checkout"`
key — but if the `get/2` implementer copies the happy-path test fixture from `create/2` and omits
`"checkout"`, the field arrives as `nil` instead of `%Checkout{}`. Accrue's reconciliation reads
`transaction.checkout.url` and crashes.
**Why it happens:** `build_transaction/1` already exists in `lib/paddle/transactions.ex` and handles
the checkout case, but only if the fixture contains a non-nil `"checkout"` map. A bare-fixture test
never exercises the hydration branch.
**Prevention:** Phase 6 test in `test/paddle/transactions_test.exs` must include a fixture where
`"checkout"` is a map **and** assert `assert %Checkout{url: url} = transaction.checkout` (not just
`assert transaction.checkout != nil`). The existing `build_transaction/1` private helper in
`lib/paddle/transactions.ex` must be reused — do not write a second builder.

### A-3: `checkout.raw_data` clobbered when reusing `build_transaction/1`
**What goes wrong:** `Http.build_struct/2` (line 28 of `lib/paddle/http.ex`) overwrites `:raw_data`
with the **top-level** data map. The nested `%Checkout{}` must receive `data["checkout"]` as its
`:raw_data`, not the transaction root. If the implementer calls
`Http.build_struct(Checkout, data)` instead of `Http.build_struct(Checkout, data["checkout"])`,
`checkout.raw_data` contains the full transaction payload — a forward-compat footgun Accrue will
trip on when it traverses raw fields.
**Prevention:** Phase 6 test must assert `assert transaction.checkout.raw_data == response_data["checkout"]`
(mirrors line 50 of `test/paddle/transactions_test.exs`). This assertion already exists for `create/2`;
a `get/2` test must repeat it explicitly.

### A-4: Forgetting to `alias Paddle.Client` — wrong guard on `get/2` head
**What goes wrong:** `Transactions.get/2` signature written as `def get(client, transaction_id)` without
the `%Client{} = client` guard that every other public function has. Passes dialyzer during happy-path
testing but breaks the explicit-client pattern that Accrue relies on for multi-tenant dispatch.
**Prevention:** Phase 6 plan must show the function head as
`def get(%Client{} = client, transaction_id)` and list `alias Paddle.Client` as a required addition
to the top of `lib/paddle/transactions.ex`.

---

## B. Seam Integration Test (Phase 7)

### B-1: HMAC fixture goes stale when `verify_signature/4` tolerates a fixed timestamp
**What goes wrong:** The webhook step computes a fixed HMAC in the test fixture using the
`signature_header/3` helper pattern from `test/paddle/webhooks_test.exs` (line 110). If the verifier
is called without the `now:` option override, `System.os_time(:second)` is used, the timestamp in the
fixture is seconds-old, and the test fails with `:stale_timestamp` the next day.
**Why it happens:** `@now` pinning (line 6, `webhooks_test.exs`) is local to that describe block and
not carried over to the seam test automatically.
**Prevention:** Phase 7 seam test MUST call
`Webhooks.verify_signature(raw_body, header, @secret, now: @ts)` where `@ts` is the same integer used
to build the fixture header. Add a comment in the seam test file:
`# @ts must match the ts= segment in the fixture header — do not use wall clock`.

### B-2: Req.Test stub state leaks between steps because adapters are per-`Req.new`
**What goes wrong:** Each step in the seam test creates its own `client_with_adapter/1` inline closure.
If a step's adapter does not return and another step's adapter handles its request, the assert in the
second step passes against wrong data — silent cross-step contamination.
**Why it happens:** The per-adapter closure pattern (all tests in the repo) is safe when each adapter
handles exactly one request. In a multi-step test with sequential calls, the wrong adapter can consume
the wrong request if two `client` values share adapter state.
**Prevention:** Each step in the seam test must use a **separate** `client` binding with its own
`client_with_adapter/1` call — never reuse a `client` across two steps. Add a comment at the top of
the seam test: `# Each step uses its own client — adapters are one-shot closures, never reuse`.

### B-3: Multi-step fixture chain where step N silently absorbs step N+1's request
**What goes wrong:** If a single `client` is used for two sequential calls (e.g. `Customers.create` and
`Addresses.create`), the adapter closure for the first call captures both requests if the function
returns without fully exhausting its request. The second call returns a stale response from the first
fixture, and assertions pass with wrong struct types.
**Prevention:** Same as B-2. Additionally, Phase 7 must assert the resource type at each step:
`assert {:ok, %Customer{}} = ...`, `assert {:ok, %Address{}} = ...`, etc. Never assert only
`{:ok, _}` in the seam test.

### B-4: Assertions too tight — any non-breaking Paddle field addition breaks the test
**What goes wrong:** The seam test pattern-matches exact fixture maps: `assert subscription == %{...}`
or uses `^response_data` with a full literal. Any new field Paddle adds to a response that the fixture
doesn't include causes a match failure, defeating the point of a stability test.
**Prevention:** Phase 7 seam test must use struct-field assertions for the locked contract fields only:
`assert subscription.status == "active"`, `assert transaction.checkout.url =~ "https://"`. The
`raw_data` field provides the escape hatch. Never pattern-match the full fixture map at the seam level.

### B-5: Assertions too loose — test passes when the contract has broken
**What goes wrong:** The opposite of B-4: assertions like `assert is_struct(transaction)` or
`assert {:ok, _} = result` pass even if `transaction.checkout` is `nil` or `subscription.id` is
missing — meaning a hydration regression is invisible.
**Prevention:** Phase 7 seam test must assert each locked field named in `PROJECT.md`'s "Locked struct
surfaces" section. Minimum per step:
- Customer step: `assert customer.id =~ "ctm_"`
- Address step: `assert address.customer_id == customer.id`
- Transaction step: `assert %Checkout{url: url} = transaction.checkout; assert is_binary(url)`
- Webhook step: `assert %Event{event_type: "transaction.completed"} = event`
- Subscription get step: `assert %Subscription{id: sub_id} = subscription; assert is_binary(sub_id)`
- Cancel step: `assert subscription.status in ["canceled", "active"]` (scheduled cancel is valid)

### B-6: Seam test inadvertently exercises subscription mutations (scope creep)
**What goes wrong:** While writing the `cancel/2` step, a planner adds `Subscriptions.update/3` or
`Subscriptions.pause/3` to "make the test more realistic." These functions don't exist; the test fails
compilation, but worse, the reviewer conflates the failure with a real seam bug.
**Prevention:** Phase 7 plan must list the exact six functions under test (B-02 path from BACKLOG.md)
and include a "NOT in scope" callout: `update/3`, `pause/3`, `resume/3` are explicitly excluded. Any
phase 7 test file must pass `mix credo --strict` before merge.

---

## C. Consumer-Facing Seam Surface Doc (Phase 7)

### C-1: Documenting unstable mid-tier struct fields as locked
**What goes wrong:** `%Paddle.Transaction{}` has `:details` and `:payments` which are raw maps copied
from the API response with no nested struct hydration and no `raw_data` on the sub-map itself. If the
doc marks these fields as "locked", Accrue writes code against `transaction.details["totals"]["subtotal"]`
and that path breaks silently when Paddle changes the nested structure.
**Prevention:** Phase 7 doc (`guides/accrue-seam.md` or equivalent) must assign fields a stability
tier. Tier definitions:
- **locked** — typed struct with `:raw_data` (e.g. `:id`, `:status`, `checkout.url`)
- **additive** — present as raw data; new sub-keys safe, removals breaking
- **raw** — forwarded from API, no contract (`:details`, `:payments`, `:items` on Transaction)
The doc must not promote `:details` or `:payments` above **raw** tier.

### C-2: Listing private functions or aliasing internal modules
**What goes wrong:** ExDoc surfaces `Paddle.Internal.Attrs` if it is not marked `@moduledoc false`.
A doc pass that lists "all public modules" may inadvertently document `Paddle.Internal.*`, leading
Accrue to call `Paddle.Internal.Attrs.normalize/1` directly.
**Prevention:** Phase 7 must verify `@moduledoc false` is set on every `Paddle.Internal.*` module
before generating the doc. Add a CI step: `mix docs` must not include any module whose name contains
`Internal` in the rendered output.

### C-3: Documentation rot — doc diverges from `defstruct` field list
**What goes wrong:** The doc lists `:invoice_number` as a locked field on `%Paddle.Transaction{}`.
A future phase removes or renames it. The doc is not regenerated, Accrue reads the doc, codes against
`:invoice_number`, and gets `nil` at runtime.
**Prevention:** Phase 7 must add at least one ExDoc doctest in `lib/paddle/transaction.ex` that
asserts the struct fields directly:
```elixir
iex> Map.keys(%Paddle.Transaction{}) -- [:__struct__]
[:id, :status, ...]
```
This doctest runs in `mix test` and fails immediately if a field is added or removed without updating
the test. An alternative: add a contract test in `test/paddle/transaction_test.exs` that asserts
`Map.keys(%Transaction{})` matches the documented field list exactly.

### C-4: Implying retry or SLA guarantees the library doesn't offer
**What goes wrong:** The seam surface doc says "Paddle.Http retries on transient failures." The current
`Req` client is configured with `retry: false` in all tests (confirmed in `client_with_adapter/1`
across every test file). If `retry:` is enabled in production clients, behavior differs from the doc;
if it is not, the statement is wrong.
**Prevention:** Phase 7 doc must say "no retry behavior is enforced by the SDK; configure `retry:`
on the `Req` instance you pass to `Paddle.Client.new!/1` if desired." Never state SLAs, timeouts, or
retry counts that the library does not pin.

### C-5: Stability-tier vocabulary mismatch between oarlock doc and what Accrue assumes
**What goes wrong:** oarlock doc uses "additive" for fields where Accrue team reads "additive" to mean
"we won't break it," but oarlock means "new keys safe; removal is a major bump." Both are true, but
the ambiguity causes Accrue to encode logic against unstable nested keys.
**Prevention:** Phase 7 doc must include a one-paragraph "Stability vocabulary" section:
> **locked** — field present and typed in all versions of this minor series; removal is a major bump.
> **additive** — new sub-keys may appear without a bump; existing keys will not be removed within a minor series.
> **raw** — forwarded from the Paddle API; no contract; inspect `raw_data` instead.

---

## D. Accrue Release Coordination (Phase 6 + Phase 7)

### D-1: Phase 6 ships code but no Hex release; Accrue is blocked waiting
**What goes wrong:** `Transactions.get/2` lands in `main`. Accrue's `mix.exs` pins
`{:oarlock, "~> 1.0"}` (or a git sha). Without a published `1.1.0` release on Hex, Accrue cannot
consume the new function even though the code exists.
**Prevention:** Phase 6 execution plan must include a "release gate" task:
1. Bump `version` in `mix.exs` to `1.1.0`.
2. Tag `v1.1.0` on `main`.
3. Run `mix hex.publish`.
The plan must be blocked from marking Phase 6 complete until the Hex publish step is done.
The `BACKLOG.md` entry for B-01 must note the Hex version it shipped in.

### D-2: `"~> 1.0"` version constraint in Accrue rejects `1.1.0`
**What goes wrong:** `~> 1.0` in Elixir/Mix means ">=1.0.0 and <2.0.0" — `1.1.0` IS accepted.
However, if Accrue pinned `"~> 1.0.0"` (patch-level), it means ">=1.0.0 and <1.1.0", which rejects
`1.1.0`. This distinction is easy to miss when reading the lockfile.
**Prevention:** Before tagging `v1.1.0`, check `~/projects/accrue/mix.exs` for the oarlock version
constraint. If it is `"~> 1.0.0"`, coordinate the bump to `"~> 1.1"` or `">= 1.1.0"` with the
Accrue team before publishing. Document the check as a step in Phase 6's release task.

### D-3: Seam test scope creep pulls in subscription mutations via fixture
**What goes wrong:** To make the seam test fixture look "production-realistic," a planner adds a
subscription with `scheduled_change: %{action: "pause"}` in the fixture — implying `pause/3` is a
real function. Or a comment in the test file says "TODO: add pause step." Accrue reads the comment,
files an issue, and the planner adds `pause/3` mid-phase.
**Prevention:** Phase 7 seam test fixture must only contain `action: "cancel"` in any
`scheduled_change` map (already in the existing subscription fixtures). The test file header comment
must include:
```
# Scope: customer → address → transaction → webhook → subscription get → cancel.
# Subscription mutations (update/pause/resume) are OUT OF SCOPE for v1.1.
```

---

## Phase Assignment Summary

| Pitfall | Phase |
|---------|-------|
| A-1: validation atom mismatch | 6 |
| A-2: checkout silently nil on GET | 6 |
| A-3: checkout.raw_data clobbered | 6 |
| A-4: missing %Client{} guard | 6 |
| B-1: HMAC fixture stale timestamp | 7 |
| B-2: Req adapter state leaks between steps | 7 |
| B-3: adapter absorbs wrong step's request | 7 |
| B-4: assertions too tight | 7 |
| B-5: assertions too loose | 7 |
| B-6: subscription mutation scope creep | 7 |
| C-1: unstable fields marked locked | 7 |
| C-2: Internal modules in public doc | 7 |
| C-3: doc rot / field list divergence | 7 |
| C-4: implied retry/SLA guarantee | 7 |
| C-5: stability-tier vocabulary mismatch | 7 |
| D-1: no Hex release after code ships | 6 |
| D-2: Accrue `~> 1.0.0` constraint rejects 1.1.0 | 6 |
| D-3: mutation scope creep via fixture comment | 7 |
