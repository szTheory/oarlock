# Phase 10: subscriptions-surface-completion - Pattern Map

**Mapped:** 2026-05-30  
**Files analyzed:** 8  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/paddle/subscriptions.ex` | service | request-response | `lib/paddle/subscriptions.ex` | exact |
| `test/paddle/subscriptions_test.exs` | test | request-response | `test/paddle/subscriptions_test.exs` | exact |
| `test/paddle/subscription_test.exs` | test | transform | `test/paddle/subscription_test.exs` | exact |
| `test/paddle/seam_test.exs` | test | event-driven | `test/paddle/seam_test.exs` | exact |
| `guides/accrue-seam.md` | config | transform | `guides/accrue-seam.md` | exact |
| `guides/getting-started.md` | utility | event-driven | `guides/getting-started.md` | exact |
| `.planning/REQUIREMENTS.md` *(planning-time corrected precondition; not execution batch file)* | config reference | planning precondition | `.planning/REQUIREMENTS.md` | exact |
| `.planning/ROADMAP.md` *(planning-time corrected precondition; not execution batch file)* | config reference | planning precondition | `.planning/ROADMAP.md` | exact |

These two `.planning/*.md` entries are included as reference inputs because the SUB-04 wording correction was already landed during planning. They are not Phase 10 execution-batch files and therefore do not belong in any Phase 10 plan `files_modified` list.

## Pattern Assignments

### `lib/paddle/subscriptions.ex` (service, request-response)

**Analog:** `lib/paddle/subscriptions.ex`

**Imports + module shape** (`lib/paddle/subscriptions.ex:1-8`):
```elixir
defmodule Paddle.Subscriptions do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange
```

**Mutation pattern (named timing split)** (`lib/paddle/subscriptions.ex:45-64`):
```elixir
def cancel(%Client{} = client, subscription_id) do
  do_cancel(client, subscription_id, "next_billing_period")
end

def cancel_immediately(%Client{} = client, subscription_id) do
  do_cancel(client, subscription_id, "immediately")
end

defp do_cancel(client, subscription_id, effective_from) do
  with :ok <- validate_subscription_id(subscription_id),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(
           client,
           :post,
           cancel_path(subscription_id),
           json: %{"effective_from" => effective_from}
         ) do
    {:ok, build_subscription(data)}
  end
end
```

**Hydration pattern (nested typed structs + `raw_data`)** (`lib/paddle/subscriptions.ex:66-84`):
```elixir
defp build_subscription(data) when is_map(data) do
  subscription = Http.build_struct(Subscription, data)

  subscription =
    case data["scheduled_change"] do
      sc when is_map(sc) ->
        %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}
      _ ->
        subscription
    end

  case data["management_urls"] do
    mu when is_map(mu) ->
      %{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}
    _ ->
      subscription
  end
end
```

**Validation + path encoding pattern** (`lib/paddle/subscriptions.ex:101-105`, `lib/paddle/subscriptions.ex:118-121`):
```elixir
defp validate_subscription_id(id) when is_binary(id) do
  if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
end

defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}

defp subscription_path(id), do: "/subscriptions/#{encode_path_segment(id)}"
defp cancel_path(id), do: subscription_path(id) <> "/cancel"
defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

---

### `test/paddle/subscriptions_test.exs` (test, request-response)

**Analog:** `test/paddle/subscriptions_test.exs`

**Test module + aliases** (`test/paddle/subscriptions_test.exs:5-14`):
```elixir
defmodule Paddle.SubscriptionsTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Page
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange
  alias Paddle.Subscriptions
```

**Adapter-backed request contract pattern** (`test/paddle/subscriptions_test.exs:409-415`, `test/paddle/subscriptions_test.exs:499-504`):
```elixir
client_with_adapter(fn request ->
  assert request.method == :post
  assert request.url.path == "/subscriptions/sub_01/cancel"
  assert decode_json_body(request.body) == %{"effective_from" => "next_billing_period"}
  {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
end)
```

```elixir
client_with_adapter(fn request ->
  assert request.method == :post
  assert request.url.path == "/subscriptions/sub_01/cancel"
  assert decode_json_body(request.body) == %{"effective_from" => "immediately"}
  {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
end)
```

**Validation/error expectations** (`test/paddle/subscriptions_test.exs:444-451`, `test/paddle/subscriptions_test.exs:473-490`, `test/paddle/subscriptions_test.exs:532-535`):
```elixir
assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, nil)
assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, "")
assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, "   ")
assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, 42)
```

```elixir
assert {:error,
        %Error{
          status_code: 422,
          request_id: "req_lock",
          type: "request_error",
          code: "subscription_locked_pending_changes",
          message: "Subscription is locked due to pending changes"
        }} = Subscriptions.cancel(client, "sub_01")

assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
         Subscriptions.cancel(client, "sub_01")
```

**Reusable helpers pattern** (`test/paddle/subscriptions_test.exs:578-590`):
```elixir
defp client_with_adapter(adapter) do
  %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
  }
end

defp decode_json_body(body) do
  body
  |> IO.iodata_to_binary()
  |> Jason.decode!()
end
```

---

### `test/paddle/subscription_test.exs` (test, transform)

**Analog:** `test/paddle/subscription_test.exs`

**Struct-shape regression baseline pattern** (`test/paddle/subscription_test.exs:10-37`):
```elixir
assert %Subscription{
         id: nil,
         status: nil,
         customer_id: nil,
         ...
         import_meta: nil,
         raw_data: nil
       } = %Subscription{}
```

**Hydration + `raw_data` retention pattern** (`test/paddle/subscription_test.exs:39-114`):
```elixir
assert %Subscription{
         id: "sub_01",
         ...
         raw_data: ^data
       } = Http.build_struct(Subscription, data)
```

**Nested struct mapping pattern** (`test/paddle/subscription_test.exs:124-137`, `test/paddle/subscription_test.exs:147-173`):
```elixir
assert %ScheduledChange{
         action: "cancel",
         effective_at: "2024-05-12T10:37:59.556997Z",
         resume_at: nil,
         raw_data: ^data
       } = Http.build_struct(ScheduledChange, data)
```

```elixir
assert %ManagementUrls{
         update_payment_method: ".../update-payment-method",
         cancel: ".../cancel",
         raw_data: ^data
       } = Http.build_struct(ManagementUrls, data)
```

---

### `test/paddle/seam_test.exs` (test, event-driven)

**Analog:** `test/paddle/seam_test.exs`

**Seam-journey test structure** (`test/paddle/seam_test.exs:23-43`, `test/paddle/seam_test.exs:93-101`, `test/paddle/seam_test.exs:127-143`, `test/paddle/seam_test.exs:155-189`):
```elixir
test "locks the Accrue seam across the customer, checkout, webhook, and subscription flow" do
  ...
  assert {:ok, %Transaction{id: "txn_seam01"} = transaction} =
           Paddle.Transactions.create(transaction_create_client, ...)
  assert %Checkout{url: checkout_url} = transaction.checkout
  ...
  assert {:ok, :verified} = Webhooks.verify_signature(...)
  assert {:ok, %Event{event_type: "transaction.completed"} = event} = Webhooks.parse_event(...)
  ...
  assert {:ok, %Subscription{id: "sub_seam01", status: "active"} = subscription} =
           Paddle.Subscriptions.get(subscription_get_client, fetched_transaction.subscription_id)
  ...
  assert {:ok, %Subscription{scheduled_change: %ScheduledChange{action: "cancel"}}} =
           Paddle.Subscriptions.cancel(cancel_client, subscription.id)
end
```

**Request assertion style for subscription endpoints** (`test/paddle/seam_test.exs:149-171`):
```elixir
assert request.url.path == "/subscriptions/sub_seam01"
...
assert request.url.path == "/subscriptions/sub_seam01/cancel"
assert decode_json_body(request.body) == %{"effective_from" => "next_billing_period"}
```

---

### `guides/accrue-seam.md` (config, transform)

**Analog:** `guides/accrue-seam.md`

**Closed-seam policy pattern** (`guides/accrue-seam.md:10-22`):
```markdown
The published seam is **closed and explicitly enumerated**.
Only explicitly documented modules, functions, structs, and support types are supported as part of this seam.
...
- Any function not listed in the **Public Modules** or **Support Types** sections below.
```

**Public subscriptions function list pattern** (`guides/accrue-seam.md:71-79`):
```markdown
### `Paddle.Subscriptions`

- `get(client, subscription_id)` ...
- `list(client, params \\ [])` ...
- `stream(client, params \\ [])` ...
- `all(client, params \\ [])` ...
- `cancel(client, subscription_id)` ...
- `cancel_immediately(client, subscription_id)` ...
```

**Locked subscription field contract pattern** (`guides/accrue-seam.md:156-164`):
```markdown
### `%Paddle.Subscription{}`
| `:id`, `:status`, ... `:import_meta` | `locked` | Typed top-level subscription fields. |
| `:scheduled_change` | `locked` | Hydrated `%Paddle.Subscription.ScheduledChange{}` when present. |
| `:management_urls` | `locked` | Hydrated `%Paddle.Subscription.ManagementUrls{}` when present. |
| `:items`, `:current_billing_period`, ... | `opaque` | Forwarded provider data... |
| `:raw_data` | `locked` | Forward-compat escape hatch... |
```

**Out-of-scope section to update** (`guides/accrue-seam.md:188-200`):
```markdown
## Out of scope for the current 0.x seam
...
- Subscription mutations beyond cancel: `update`, `pause`, `resume`.
```

---

### `guides/getting-started.md` (utility, event-driven)

**Analog:** `guides/getting-started.md`

**Transaction-first recurring-start narrative** (`guides/getting-started.md:26-39`, `guides/getting-started.md:85-93`, `guides/getting-started.md:138-141`):
```markdown
Most teams do not start with "create a subscription."
...
3. Create a transaction for the price you want to sell.
4. Send the user to Paddle Checkout.
5. Verify the webhook when Paddle tells you payment completed.
```

```elixir
{:ok, transaction} =
  Paddle.Transactions.create(client,
    customer_id: customer.id,
    address_id: address.id,
    items: [%{price_id: "pri_monthly_123", quantity: 1}]
  )
```

**Current subscription operations section pattern** (`guides/getting-started.md:182-235`):
```markdown
## Job 4: Inspect or End an Existing Subscription
...
{:ok, subscription} = Paddle.Subscriptions.get(client, subscription_id)
...
{:ok, subscription} = Paddle.Subscriptions.cancel(client, subscription_id)
{:ok, subscription} = Paddle.Subscriptions.cancel_immediately(client, subscription_id)
```

**Direct-create truth statement pattern** (`guides/getting-started.md:265-269`):
```markdown
subscriptions are normally created indirectly through checkout or invoicing
flows, not by calling a direct "create subscription" API.
```

---

### `.planning/REQUIREMENTS.md` (config reference, planning precondition)

**Analog:** `.planning/REQUIREMENTS.md`

Planning note: this file was already corrected pre-execution to reflect the transaction-driven SUB-04 truth. Phase 10 plans read it as a locked precondition and do not schedule it as an execution artifact.

**Requirement bullet structure pattern** (`.planning/REQUIREMENTS.md:15`, `.planning/REQUIREMENTS.md:25-27`):
```markdown
- [x] **REL-01**: ...
- [ ] **SUB-04**: ...
- [ ] **SUB-05**: ...
- [ ] **SUB-06**: ...
```

**Traceability table update pattern** (`.planning/REQUIREMENTS.md:77-85`):
```markdown
| Requirement | Phase | Status  | Notes |
|-------------|-------|---------|-------|
| SUB-04      | 10    | Pending | ... |
| SUB-05      | 10    | Pending | ... |
| SUB-06      | 10    | Pending | ... |
```

---

### `.planning/ROADMAP.md` (config reference, planning precondition)

**Analog:** `.planning/ROADMAP.md`

Planning note: this file was already corrected pre-execution alongside `.planning/REQUIREMENTS.md`. Its entries inform Phase 10 execution, but no current Phase 10 plan claims it in `files_modified`.

**Phase details/success criteria structure pattern** (`.planning/ROADMAP.md:71-81`):
```markdown
### Phase 10: Subscriptions Surface Completion
**Goal**: ...
**Depends on**: ...
**Requirements**: SUB-04, SUB-05, SUB-06
**Success Criteria** (what must be TRUE):
  1. ...
  2. ...
  3. ...
```

**Milestone phase checklist pattern** (`.planning/ROADMAP.md:14-19`):
```markdown
- [ ] Phase 10: Subscriptions Surface Completion (0/? plans) — SUB-04, SUB-05, SUB-06
```

## Shared Patterns

### Request Opt Boundary (Phase 8 reliability carry-forward)
**Sources:** `lib/paddle/http.ex:4-9`, `lib/paddle/http.ex:25-50`, `.planning/phases/08-reliability-primitives/08-CONTEXT.md:64-70`  
**Apply to:** `lib/paddle/subscriptions.ex`, `test/paddle/subscriptions_test.exs`, seam/docs updates
```elixir
idempotency_key_present? = Keyword.has_key?(opts, :idempotency_key)
{idempotency_key, opts} = Keyword.pop(opts, :idempotency_key)
opts = maybe_add_idempotency_header(opts, idempotency_key, idempotency_key_present?)
```
Planner note: keep create/start-flow-only idempotency semantics; pause/resume should split lifecycle opts from request opts and support only `retry:` request override.

### Retry Baseline + Per-Call Override
**Sources:** `lib/paddle/client.ex:15-21`, `test/paddle/http_test.exs:254-265`  
**Apply to:** lifecycle mutation calls and tests
```elixir
Req.new(..., retry: :transient, max_retries: 3)
...
Http.request(client, :get, "/customers", retry: false)
```

### ID Validation + Path Encoding
**Sources:** `lib/paddle/subscriptions.ex:101-105`, `lib/paddle/subscriptions.ex:118-121`, `lib/paddle/customers/addresses.ex:96-104`, `lib/paddle/customers/addresses.ex:117`  
**Apply to:** pause/resume path construction and invalid-ID tests
```elixir
if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
...
URI.encode(id, &URI.char_unreserved?/1)
```

### Typed Hydration + `raw_data` Preservation
**Sources:** `lib/paddle/subscriptions.ex:66-84`, `lib/paddle/http.ex:52-63`, `test/paddle/subscription_test.exs:39-114`  
**Apply to:** pause/resume success responses and seam tests
```elixir
subscription = Http.build_struct(Subscription, data)
%{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}
%{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}
```

### Adapter-Backed Endpoint Tests
**Sources:** `test/paddle/subscriptions_test.exs:409-415`, `test/paddle/subscriptions_test.exs:444-451`, `test/paddle/subscriptions_test.exs:473-490`, `test/paddle/subscriptions_test.exs:578-590`  
**Apply to:** new pause/resume tests and transaction-driven start acceptance tests
```elixir
client_with_adapter(fn request ->
  assert request.method == :post
  assert request.url.path == "/subscriptions/sub_01/cancel"
  assert decode_json_body(request.body) == %{"effective_from" => "..."}
  {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
end)
```

### Seam Test Discipline (Public Boundary Only)
**Sources:** `test/paddle/seam_test.exs:23-190`, `guides/accrue-seam.md:10-22`, `guides/accrue-seam.md:41-79`  
**Apply to:** seam updates for added public functions; no full payload freeze
```elixir
assert {:ok, %Subscription{id: "sub_seam01", status: "active"}} = Paddle.Subscriptions.get(...)
assert {:ok, %Subscription{scheduled_change: %ScheduledChange{action: "cancel"}}} =
         Paddle.Subscriptions.cancel(...)
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/paddle/`, `test/paddle/`, `guides/`, `.planning/`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-30
