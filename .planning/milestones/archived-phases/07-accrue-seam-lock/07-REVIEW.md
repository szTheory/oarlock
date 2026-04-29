---
phase: 07-accrue-seam-lock
reviewed: 2026-04-29T19:11:28Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - guides/accrue-seam.md
  - lib/paddle.ex
  - lib/paddle/http.ex
  - lib/paddle/http/telemetry.ex
  - test/paddle/seam_test.exs
findings:
  blocker: 0
  warning: 6
  total: 6
status: issues_found
---

# Phase 07: Code Review Report

**Reviewed:** 2026-04-29T19:11:28Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 07 ships the Accrue seam lock through (a) `guides/accrue-seam.md` as the canonical contract, (b) `@moduledoc false` on the placeholder root and the `Paddle.Http*` transport modules, and (c) a `Paddle.SeamTest` end-to-end test that drives the customer to checkout to webhook to subscription cancel flow against `Req` adapter closures.

The runtime change is safe: only docstring annotations were added to `lib/paddle.ex`, `lib/paddle/http.ex`, and `lib/paddle/http/telemetry.ex` — no `def` was demoted to `defp`, no exported function was removed, no struct shape changed. `mix compile` is clean and the full suite (111 tests) passes.

Findings concentrate on the seam test itself and on contract accuracy in the guide. The test under-asserts the locked surface it claims to pin: most documented `locked` fields on `%Paddle.Customer{}`, `%Paddle.Address{}`, `%Paddle.Transaction{}`, `%Paddle.Subscription{}`, and `%Paddle.Event{}` are not pattern-matched, so a regression that nils a locked field would slip through. The test header also overclaims coverage — three documented public functions and the `Paddle.Page.next_cursor/1` support helper are never exercised. Two smaller doc/test alignment issues round out the list. No BLOCKERs.

## Warnings

### WR-01: Seam test under-asserts locked struct fields, leaving most of the contract unpinned

**File:** `test/paddle/seam_test.exs:38-187`
**Issue:** The file header claims "pins the full oarlock surface that Accrue targets," but the assertions only bind a tiny subset of the fields the guide marks `locked`:

- `%Customer{id, email}` — 2 of 10 locked fields (line 38). `:status`, `:name`, `:marketing_consent`, `:locale`, `:custom_data`, `:created_at`, `:updated_at`, `:import_meta` are never asserted, so a regression that hydrates them as `nil` from a payload that contains them would not be caught.
- `%Address{id, customer_id}` — 2 of 14 locked fields (line 65).
- `%Transaction{id}` on create (line 93) and `%Transaction{id, customer_id, subscription_id}` on get (lines 114-119) — 1 and 3 of 15 locked fields. In particular `:status` is `locked` per the guide and the fixture distinguishes `"ready"` vs `"completed"` between the create and get calls, but neither path asserts `:status`.
- `%Event{event_id, event_type, notification_id}` — 3 of 4 locked fields (line 138). `:occurred_at` is `locked` and present in the fixture (`"2024-04-12T10:37:59Z"`) but never bound.
- `%Subscription{id, status}` — 2 of 17 locked fields (line 155).

The plan-stated goal was to replace fixture-equality `raw_data ==` checks with opacity checks while preserving the locked-surface contract. Replacing strong field equality with `is_map(raw_data)` is correct for `:raw_data`, but the locked top-level fields lost coverage at the same time. The seam test as written would still pass if `Http.build_struct/2` regressed to drop `:status`, `:occurred_at`, `:created_at`, etc.
**Fix:** For each typed struct returned in the flow, pattern-match every field the guide marks `locked`. Concretely:

```elixir
# Customer (replace the existing `%Customer{id: "ctm_seam01", email: "ada@example.com"} = customer`):
assert {:ok,
        %Customer{
          id: "ctm_seam01",
          name: "Ada Lovelace",
          email: "ada@example.com",
          marketing_consent: false,
          status: "active",
          custom_data: %{},
          locale: "en",
          created_at: "2024-04-12T10:15:30Z",
          updated_at: "2024-04-13T11:16:31Z",
          import_meta: %{}
        } = customer} = Paddle.Customers.create(...)

# Transaction get — bind :status to "completed", :currency_code, :collection_mode, :billed_at, etc.

# Event — add `occurred_at: "2024-04-12T10:37:59Z"` to the pattern.
```

Apply the same pattern to `%Address{}`, both `%Transaction{}` calls, the `%Subscription{}` from `get` and the one from `cancel`, and the `%ScheduledChange{}` and `%ManagementUrls{}` (already partly covered). This is the difference between "pins the seam" and "samples the seam."

---

### WR-02: Seam test header overclaims coverage of "the full oarlock surface that Accrue targets"

**File:** `test/paddle/seam_test.exs:1-3`
**Issue:** The comment says the test "pins the full oarlock surface that Accrue targets" with scope `customer -> address -> transaction -> webhook -> subscription get -> cancel`. However, the guide's "Public Modules" and "Support Types" sections enumerate at least seven entry points the test never exercises, and one of them is the only public way to read pagination metadata:

- `Paddle.Customers.get/2`
- `Paddle.Customers.update/3`
- `Paddle.Customers.Addresses.get/3`
- `Paddle.Customers.Addresses.list/3`
- `Paddle.Customers.Addresses.update/4`
- `Paddle.Subscriptions.list/2`
- `Paddle.Subscriptions.cancel_immediately/2`
- `Paddle.Page.next_cursor/1`
- `Paddle.Client.new!/1` (constructed inline by hand instead)

A future maintainer reading "pins the full surface" may believe the seam test is sufficient regression coverage and remove redundant per-module tests. It is not — it exercises one happy path through the most central seven calls.
**Fix:** Either (a) tighten the wording to "pins the primary Accrue happy path" (or similar) and explicitly note that per-function detail tests in `test/paddle/{customers,subscriptions,...}_test.exs` remain authoritative, or (b) extend the seam test to exercise the missing public functions. Wording change is the minimum:

```elixir
# This test pins the primary Accrue happy path through the locked oarlock seam.
# It does NOT replace per-module tests — `get/update/list` variants and
# `Paddle.Page.next_cursor/1` are covered in their dedicated test files.
```

---

### WR-03: Seam test does not exercise `Paddle.Page.next_cursor/1`, leaving a documented locked function unpinned

**File:** `test/paddle/seam_test.exs` (overall flow), `guides/accrue-seam.md:106-108`
**Issue:** The guide registers `Paddle.Page.next_cursor/1` as `locked`, and `Paddle.Page` itself has only two members (`%Paddle.Page{}` and `next_cursor/1`). Pagination is the standard mechanism for Accrue to walk subscriptions/addresses, so it is part of the seam in spirit. The seam test currently never calls a `list/*` endpoint and never invokes `Page.next_cursor/1`. Coverage exists in `test/paddle/page_test.exs` and `test/paddle/subscriptions_test.exs`, but a "seam lock" test that omits the cursor accessor is misnamed.
**Fix:** Add a list step for either `Paddle.Subscriptions.list/2` or `Paddle.Customers.Addresses.list/3` that returns a `%Paddle.Page{}` with a `next` cursor in `meta["pagination"]`, then assert:

```elixir
assert {:ok, %Paddle.Page{data: [%Subscription{} | _], meta: meta}} =
         Paddle.Subscriptions.list(list_client)

assert is_map(meta)
assert is_binary(Paddle.Page.next_cursor(%Paddle.Page{meta: meta}))
```

Alternatively, accept that the per-module tests cover this and update the seam test header per WR-02.

---

### WR-04: `subscription_payload_canceled/0` returns `status: "active"` while leaving the cancel step's status assertion ambiguous about what is being verified

**File:** `test/paddle/seam_test.exs:155-185, 308-317`
**Issue:** `subscription_payload_canceled/0` merges only `scheduled_change` and `updated_at` over `subscription_payload/0`, so `"status"` stays `"active"`. The test then asserts `%Subscription{id: "sub_seam01", status: "active", scheduled_change: %ScheduledChange{action: "cancel", ...}}`. This is not wrong — Paddle's documented behavior for `effective_from: "next_billing_period"` is to leave `status: "active"` and attach a scheduled cancel — but:

1. The neighbouring file `test/paddle/subscriptions_test.exs:31` uses the same fixture name `subscription_payload_canceled()` to assert `status == "canceled"`, indicating the two files have diverged on what "canceled" means in their fixtures.
2. The seam test never asserts the *immediate* cancel path (`Paddle.Subscriptions.cancel_immediately/2`), where `status` should flip to `"canceled"`.

Together, this reads as if the seam test is documenting "cancel returns active" as the locked behavior, which is too narrow — it locks only the deferred-cancel branch.
**Fix:** Either (a) rename the helper to `subscription_payload_with_scheduled_cancel/0` so its semantics are obvious and divergence from `subscriptions_test.exs` is explicit, or (b) add a parallel `cancel_immediately/2` step with a fixture that returns `status: "canceled"` and `canceled_at` set, so both branches of the documented cancel surface are pinned.

```elixir
defp subscription_payload_with_scheduled_cancel do
  Map.merge(subscription_payload(), %{
    "scheduled_change" => %{
      "action" => "cancel",
      "effective_at" => "2024-05-12T10:37:59.556997Z",
      "resume_at" => nil
    },
    "updated_at" => "2024-04-13T10:37:59.556997Z"
  })
end
```

---

### WR-05: Public consumer modules carry no `@moduledoc` and no `@doc`, so the contract guide is the only documentation surface

**File:** `lib/paddle/customers.ex`, `lib/paddle/customers/addresses.ex`, `lib/paddle/transactions.ex`, `lib/paddle/subscriptions.ex`, `lib/paddle/webhooks.ex`
**Issue:** The phase added `@moduledoc false` to the placeholder root and the transport modules — correct. But the modules the guide enumerates as `locked` public surface (`Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, `Paddle.Webhooks`) have neither a `@moduledoc` nor any `@doc` strings on their public functions. With ExDoc, they will still appear in generated docs (because they have no `@moduledoc false`) but each module page will be empty. A consumer arriving at `Paddle.Customers` in HexDocs sees a function list with no descriptions and no link back to `accrue-seam.md`.

This is not a regression introduced by Phase 07 — these modules were already undocumented before this phase — but Phase 07 is the contract-publication phase, which is the natural place to flag it. Leaving the public seam undocumented inside the source while publishing a separate guide creates a long-term drift risk: the next person editing `Paddle.Customers.create/2` sees no `@doc` and may change return contracts without consulting `guides/accrue-seam.md`.
**Fix:** Add at least a one-line `@moduledoc` to each of the five public modules pointing back to the guide, and a one-line `@doc` on each documented function whose return contract the guide locks. Minimum example:

```elixir
defmodule Paddle.Customers do
  @moduledoc """
  Public Paddle customers seam. See [Accrue Seam Contract](accrue-seam.md)
  for the locked return shape and stability tier.
  """

  @doc """
  Creates a customer. See `Paddle.Customer` for the locked struct shape.
  """
  def create(%Client{} = client, attrs), do: ...
end
```

If full inline docs are deferred to a later phase, file a backlog item rather than leaving the public modules silently undocumented.

---

### WR-06: Guide describes `Paddle.Page.next_cursor/1` as returning a "cursor string" but the implementation returns the full `meta["pagination"]["next"]` URL

**File:** `guides/accrue-seam.md:106-108`, `lib/paddle/page.ex:4-6`
**Issue:** The guide says `Paddle.Page.next_cursor/1` "returns the next pagination cursor string or `nil`." The implementation returns `meta["pagination"]["next"]` verbatim, and Paddle's API populates that key with an absolute URL such as `"/transactions?after=cursor_123"` (confirmed by `test/paddle/page_test.exs:22` and `test/paddle/subscriptions_test.exs:175-176`). A consumer reading "cursor string" will reasonably expect an opaque token they pass back as `after:`, not a URL they must parse to extract the `after` query parameter — which is the exact ambiguity the `additive`/`opaque` vocabulary is supposed to eliminate.
**Fix:** Either (a) tighten the guide to describe what is actually returned, or (b) change `next_cursor/1` to extract the `after` query parameter so the name matches the value. Option (a) is the lower-risk change inside 0.x:

```markdown
### `Paddle.Page.next_cursor/1`

- `Paddle.Page.next_cursor/1` returns the next-page reference forwarded
  from Paddle's `meta.pagination.next` field (currently a relative URL
  containing the `after=` query parameter), or `nil` when no further page
  exists. Tier: `locked`. The exact format of the returned string is
  `opaque`; consumers should treat it as a value to pass through, not
  parse, until oarlock pins a stable cursor token format.
```

---

_Reviewed: 2026-04-29T19:11:28Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
