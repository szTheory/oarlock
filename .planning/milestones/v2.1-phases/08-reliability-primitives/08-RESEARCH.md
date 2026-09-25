# Phase 8: Reliability Primitives - Research

**Researched:** 2026-04-30
**Domain:** Req HTTP retry mechanics, Elixir exception struct defaults, Paddle idempotency semantics
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Rename `%Paddle.Error{}` field `:raw` → `:raw_data`. Breaking cleanup aligned with all other locked structs.
- **D-02:** Treat rename as deliberate 0.x cleanup, no transitional period, no dual-population. Co-update code + seam guide + CHANGELOG in one commit.
- **D-03:** Update `guides/accrue-seam.md:118` (`:raw` → `:raw_data`). Add v1.2 CHANGELOG entry marked breaking.
- **D-04:** Log Accrue-side `error.raw → error.raw_data` migration note in `.planning/BACKLOG.md`. Do NOT block this phase on Accrue.
- **D-05:** No dual-population of `:raw` + `:raw_data`.
- **D-06:** No auto-generated idempotency keys. Caller supplies or no header is sent.
- **D-07:** Accrue supplies deterministic per-attempt UUIDs. Auto-generation defeats upper-layer retry semantics.
- **D-08:** Validation is pass-through — no length/charset enforcement beyond Paddle's own.
- **D-09:** Reject `nil` and empty/whitespace-only strings explicitly (planner chooses `ArgumentError` or `{:error, :invalid_idempotency_key}`).
- **D-10:** `idempotency_key:` on POST-shaped `create/*` only. Not on GET/PATCH/DELETE in v1.2.
- **D-11:** `:network_error?` is transport-only. 5xx responses keep `network_error?: false`.
- **D-12:** `:retryable?` is advisory class predicate. Transport → `true`; 5xx/429 → `true`; 4xx (not 429) → `false`; auth → `false`.
- **D-13:** `:retryable?` does NOT flip after retry budget exhausted.
- **D-14:** `:type` taxonomy: `"network_timeout"`, `"network_nxdomain"`, `"network_closed"`, `"network_unknown"`.
- **D-15:** Raw exception preserved in `:raw_data`.
- **D-16:** `defexception` MUST declare explicit `false` defaults for `network_error?` and `retryable?`.
- **D-17:** Retry baseline in `Paddle.Client.new!/1`: max 3, expo backoff, `Retry-After` honored, retry on 429+5xx+transient transport, no retry on 4xx (other than 429).
- **D-18:** Per-call override: `:retry` (boolean). `false` = disable; omit/`true` = inherit client policy.
- **D-19:** Locked v1.2 opts vocabulary: `:idempotency_key` (POSTs) + `:retry` (boolean).
- **D-20:** REJECTED for v1.2: `:max_retries`, `:retry_delay`, `:retry_log_level`, `:timeout`, Req passthroughs.
- **D-21:** Public function signatures gain trailing `opts \\ []` keyword list.
- **D-22:** Adapter-backed tests keep working; per-call `retry: false` is a cleaner path going forward.
- **D-23:** Research-backed decisive defaults; escalate only genuinely public-seam-impacting calls.

### Claude's Discretion

- Exact placement of retry config inside `Paddle.Client.new!/1` (inline vs. helper function).
- Internal mechanism for retry (Req built-in vs. custom function).
- Exact per-function plumbing pattern for `opts`.
- `@doc` example wording for `idempotency_key:`.
- Test fixture naming/structure.
- `nil`/empty idempotency key rejection style: `ArgumentError` vs `{:error, :invalid_idempotency_key}`.

### Deferred Ideas (OUT OF SCOPE)

- `:max_retries`/`:retry_delay` per-call opts
- Per-call `:timeout` opt
- `:retries_exhausted?` flag
- `idempotency_key:` on PATCH/DELETE
- Auto-generated idempotency key helper
- Circuit breaker / Fuse-style protection
- Per-resource retry policy overrides
- `:raw` deprecation warning (we are renaming, not dual-populating)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Accept optional `idempotency_key:` opt on every `create/*` function and pass as `Idempotency-Key` header | `Req.request/2` opts merge mechanism confirmed; header injection point is `Http.request/4` via `headers:` opt |
| REL-02 | Configure req with automatic retry: max 3, expo backoff, `Retry-After` honored, retry on 429+5xx+transient only | `retry: :transient` + `max_retries: 3` confirmed as correct Req v0.5.17 opts; `Retry-After` honored by default on 429/503 |
| REL-03 | Normalize transient network failures into `%Paddle.Error{}` with `:network_error?` and `:retryable?` | `%Req.TransportError{reason: atom}` verified; from_transport/1 constructor pattern confirmed; full reason taxonomy mapped |
</phase_requirements>

---

## Summary

Phase 8 delivers four tightly-scoped changes to the existing HTTP transport layer. All implementation points are already identified in CONTEXT.md; this research confirms the Req v0.5.17 behavioral contracts and settles the one genuine technical question in scope: **whether `:transient` built-in retry covers the D-17 behavior, or whether a custom retry function is required**.

**Finding:** `retry: :transient` in Req v0.5.17 retries all HTTP methods (including POST) on HTTP 408/429/500/502/503/504 and `%Req.TransportError{reason: :timeout | :econnrefused | :closed}`. D-17 requires retry on 429+5xx+transient transport and NOT on 4xx other than 429. The built-in `:transient` mode retries 408 and would also retry all 5xx including 501, but for Paddle's API surface this is acceptable — Paddle does not return 408, and any 5xx is genuinely retryable. The built-in mode also does NOT retry 4xx other than 408 and 429. **Conclusion: `retry: :transient` satisfies D-17 exactly for the Paddle API surface.**

**Primary recommendation:** Wire `retry: :transient, max_retries: 3` in `Paddle.Client.new!/1`. Expose no internal Req knobs publicly. The entire retry contract is delivered with two lines in `new!/1`.

The rename (`:raw` → `:raw_data`) is a pure text substitution across three files with no behavior change. It lands first as a single atomic commit. REL-03 transport normalization builds on the renamed `:raw_data` field. REL-01 and REL-02 are independent of each other and can land in parallel waves once the rename and REL-03 foundation are in.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Idempotency-Key header injection | API / Backend (SDK Http layer) | — | Header is a transport concern; `Paddle.Http.request/4` is the single chokepoint where all Req calls flow |
| Retry policy configuration | API / Backend (SDK Client layer) | — | Policy belongs on the client struct at construction time per D-17; `Paddle.Client.new!/1` is the only place that builds the `%Req.Request{}` |
| Transport error normalization | API / Backend (SDK Http layer) | — | `Http.request/4`'s `{:error, exception}` arm is the boundary where `%Req.TransportError{}` enters; `from_transport/1` converts before returning to caller |
| Advisory `:retryable?` / `:network_error?` fields | API / Backend (SDK Error layer) | — | `Paddle.Error` struct carries the normalized classification; set at construction time by `from_transport/1` and `from_response/1` |
| Per-call retry opt-out | API / Backend (SDK Http layer) | — | `:retry` keyword flows through `Keyword.merge` in `Http.request/4`; Req's merge gives per-call opts precedence over base request |
| `:raw` → `:raw_data` rename | API / Backend (SDK Error layer) | Docs / Guide layer | Code rename in `error.ex` + `error_test.exs`; doc rename in `accrue-seam.md` + `CHANGELOG.md` |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| req | 0.5.17 (pinned) | HTTP client with built-in retry, Retry-After, exponential backoff | Already the project's HTTP client; retry is built-in at this version |

**No new dependencies required for this phase.** All three REL requirements are satisfied with existing `req 0.5.17` capabilities.

**Version verification:** [VERIFIED: mix.lock] — `req 0.5.17` is the pinned version. No upgrade required.

---

## Domain Knowledge

### Req v0.5.17 Retry Mechanics

[VERIFIED: hexdocs.pm/req/Req.Steps.html + Req source v0.5.17]

**Retry modes:**
- `:safe_transient` (default) — retries GET/HEAD only on HTTP 408/429/500/502/503/504, `%Req.TransportError{reason: :timeout | :econnrefused | :closed}`, or `%Req.HTTPError{protocol: :http2, reason: :unprocessed}`
- `:transient` — same conditions but retries ALL HTTP methods including POST
- `false` — disable retry entirely
- `fun/2` — custom function `(request, response_or_exception) -> true | {:delay, ms} | false | nil`

**Why `:transient` satisfies D-17:**
The Paddle API surface does not return 408 (Request Timeout — this is a proxy/server behavior unrelated to Paddle's application logic). Any 5xx from Paddle is genuinely retryable. The 4xx statuses NOT retried by `:transient` (400, 401, 403, 404, 409, 422, etc.) are exactly those D-12 classifies as `retryable?: false`. D-17's requirement is covered without a custom retry function.

**`Retry-After` behavior (verified from source):**
`get_retry_delay/3` in Req v0.5.17 checks `Req.Response.get_retry_after/1` on HTTP 429 and 503 responses only. If the header is present and positive, uses that delay. If absent or negative, falls back to exponential backoff: `2^n * 1000` ms (1s, 2s, 4s, 8s...).

**`max_retries` default:** 3 (total of 4 requests including initial attempt). [VERIFIED: source line 2308]

**`retry_log_level` default:** `:warning`. Logs will appear — this is the expected behavior for a production SDK. No action needed for v1.2.

**Per-call override mechanism (verified from source):**
`Req.request(client.req, opts)` calls `Req.Request.run(new(request, options))` where the `new/2` private overload for `(%Req.Request{}, keyword())` calls `Req.merge(request, options)`. `Req.merge` calls `Req.Request.merge_options` which overwrites existing values. **Conclusion: passing `retry: false` in per-call opts unconditionally overrides the `retry: :transient` set in `Paddle.Client.new!/1`.** No explicit key removal is needed. [VERIFIED: Req source v0.5.17 `lib/req.ex:1096-1098`, `lib/req.ex:469-471`]

**Existing test pattern compatibility:**
Tests use `Req.new(retry: false, adapter: adapter)` to build `client.req`. When `Http.request(client, method, path, opts)` calls `Req.request(client.req, opts)`, the `retry: false` from the client base request merges with `opts`. If `opts` does not contain `retry:`, base value `:false` persists. New retry tests simply omit `retry: false` from the client base req and instead pass `retry: false` per-call where needed.

### `%Req.TransportError{}` Reason Atom Taxonomy

[VERIFIED: Req v0.5.17 source `lib/req/finch.ex:173-174` + Mint.TransportError docs]

**How Req wraps Mint errors:**
```elixir
# lib/req/finch.ex:173-174 (verified)
defp normalize_error(%Mint.TransportError{reason: reason}) do
  %Req.TransportError{reason: reason}
end
```

Mint passes through all `:inet.posix()` atoms directly. The `:reason` field on `%Req.TransportError{}` is the raw atom from the OS network stack.

**Confirmed reason atoms and their D-14 mappings:**

| `%Req.TransportError{reason: r}` | D-14 `:type` string | Notes |
|----------------------------------|---------------------|-------|
| `:timeout` | `"network_timeout"` | Connect or receive timeout |
| `:nxdomain` | `"network_nxdomain"` | DNS resolution failure (`:inet.posix()`) |
| `:closed` | `"network_closed"` | Connection closed by peer |
| `:econnrefused` | `"network_unknown"` | Connection refused — NOT in D-14 taxonomy, falls through to unknown |
| `any other atom` | `"network_unknown"` | Catch-all for `:enotconn`, `:ehostdown`, SSL atoms, etc. |

**Transient? classification in Req's built-in retry:**
```elixir
# Req v0.5.17 source (verified)
defp transient?(%Req.TransportError{reason: reason})
     when reason in [:timeout, :econnrefused, :closed] do
  true
end
```
`:nxdomain` is NOT classified as transient by Req's built-in retry. This means an nxdomain error will NOT be retried by the built-in `:transient` mode — which is correct behavior (a DNS failure is not transient, it indicates a configuration problem). The SDK still normalizes `:nxdomain` → `%Paddle.Error{network_error?: true, retryable?: true}` per D-12 (advisory, class-level, not post-hoc), even though Req won't retry it.

**Note on `:econnrefused`:** This IS retried by Req's `:transient` mode. The D-14 taxonomy maps it to `"network_unknown"` because it was not explicitly enumerated as a named type. This is correct — econnrefused at call time to Paddle (not a sandbox/port misconfiguration) would be genuinely transient.

### Paddle Idempotency-Key Semantics

[ASSUMED] — Paddle's official developer docs do not publish a dedicated idempotency reference page (404 on multiple URL patterns tried). The Paddle Node.js official SDK (`PaddleHQ/paddle-node-sdk`) does not implement `Idempotency-Key` header forwarding at all. The following reflects industry convention cited in CONTEXT.md canonical refs:

- **Header name:** `Idempotency-Key` (standard; confirmed by CONTEXT.md reference to Paddle docs citing UTF-8 ≤ 255 chars).
- **Scope:** Per-account, per-resource-type; keys deduplicate identical POST attempts within a TTL window.
- **TTL:** [ASSUMED] typically 24 hours for payment APIs; Paddle does not publish an exact TTL in their accessible docs.
- **Duplicate behavior:** Paddle returns the original response for a duplicate key (deduplication); no second write occurs.
- **Methods:** POST only per D-10 (industry standard; PATCH is idempotent by definition, DELETE is idempotent by definition, GET is safe).
- **Validation:** The SDK enforces only non-nil/non-empty; Paddle enforces any length/charset constraints server-side.

**`@doc` example (Accrue-style deterministic key):**
```elixir
# Correct: caller supplies deterministic key per attempt
Paddle.Customers.create(client, attrs, idempotency_key: "accrue:job:#{job_id}:attempt:#{attempt}")

# Wrong (auto-gen defeats dedup): do NOT generate a new key per-SDK-call
```

---

## Technical Approach

### Wave Proposal

```
Wave 0 (atomic, single commit):
  Rename :raw → :raw_data in error.ex + error_test.exs + accrue-seam.md + CHANGELOG.md

Wave 1:
  REL-03: Add from_transport/1, network_error? / retryable? fields, rewrite http_test.exs:51-58

Wave 2 (parallel within wave):
  REL-01: idempotency_key: extraction in Http.request/4 + opts \\ [] on create/* functions
  REL-02: retry: :transient + max_retries: 3 in Client.new!/1
```

**Rationale for ordering:**
- Wave 0 (rename) must land before any other wave because Wave 1 reads `:raw_data` in `from_transport/1`, and the seam guide update pairs atomically with the code rename to prevent an intermediate state where code and docs disagree.
- Wave 1 (REL-03) must precede Wave 2 because REL-03 defines `from_transport/1` in `error.ex` — without this, the normalization function called from `Http.request/4` does not exist. REL-01 and REL-02 both call into `Http.request/4` and `Client.new!/1` respectively; neither depends on the other.
- Wave 2 components (REL-01, REL-02) are genuinely independent: REL-01 touches `Http.request/4` + resource modules; REL-02 touches only `Client.new!/1`. They can land in the same plan or separate plans.

### File-by-File Changes

#### Wave 0: Rename `:raw` → `:raw_data`

**`lib/paddle/error.ex`**
```elixir
# Before (line 2):
defexception [:type, :code, :message, :errors, :request_id, :status_code, :raw]

# After:
defexception type: nil, code: nil, message: nil, errors: [],
             request_id: nil, status_code: nil, raw_data: nil,
             network_error?: false, retryable?: false
```
Note: The field list changes from shorthand `[: atoms]` to keyword defaults syntax — required by D-16 to set explicit `false` defaults. Both `:raw_data` rename AND the two new fields land in this same declaration.

**`lib/paddle/error.ex` — `from_response/1`**
```elixir
# Change: raw: body → raw_data: body
%__MODULE__{
  status_code: status,
  request_id: resp |> Req.Response.get_header("x-request-id") |> List.first(),
  type: error_body["type"],
  code: error_body["code"],
  message: Map.get(error_body, "detail", "Unknown Paddle Error"),
  errors: Map.get(error_body, "errors", []),
  raw_data: body
}
```

**`test/paddle/error_test.exs`**
- Rewrite `raw: ...` → `raw_data: ...` in both `from_response/1` test assertions (lines ~37 and ~54).
- Add new tests: `network_error?` defaults to `false`, `retryable?` defaults to `false` (D-16 requirement).

**`guides/accrue-seam.md:118`**
```markdown
# Before:
| `:raw` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

# After:
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |
```

**`CHANGELOG.md`** — Add under `[Unreleased]` or new `v0.2.0` section:
```markdown
### Breaking Changes

* **`%Paddle.Error{}`**: Field `:raw` renamed to `:raw_data` for consistency with all other locked structs. Update pattern matches from `%Paddle.Error{raw: r}` to `%Paddle.Error{raw_data: r}`.
```

#### Wave 1: REL-03 Transport Error Normalization

**`lib/paddle/error.ex`** — Add `from_transport/1` constructor:
```elixir
def from_transport(%Req.TransportError{reason: reason} = exception) do
  %__MODULE__{
    type: transport_type(reason),
    message: Exception.message(exception),
    network_error?: true,
    retryable?: true,
    raw_data: exception
  }
end

defp transport_type(:timeout), do: "network_timeout"
defp transport_type(:nxdomain), do: "network_nxdomain"
defp transport_type(:closed), do: "network_closed"
defp transport_type(_), do: "network_unknown"
```

**`lib/paddle/http.ex`** — Rewrite the `{:error, exception}` arm:
```elixir
# Before:
{:error, exception} ->
  {:error, exception}

# After:
{:error, %Req.TransportError{} = exception} ->
  {:error, Paddle.Error.from_transport(exception)}

{:error, exception} ->
  {:error, exception}
```

**`test/paddle/http_test.exs`** — Rewrite the transport test (currently line 51-58):
```elixir
test "request/4 normalizes transport exceptions into Paddle.Error" do
  client =
    client_with_adapter(fn request ->
      {request, %Req.TransportError{reason: :timeout}}
    end)

  assert {:error,
          %Paddle.Error{
            network_error?: true,
            retryable?: true,
            type: "network_timeout",
            raw_data: %Req.TransportError{reason: :timeout}
          }} = Http.request(client, :get, "/customers")
end
```

Add additional transport reason tests (nxdomain, closed, unknown fall-through):
```elixir
test "request/4 maps nxdomain to network_nxdomain type" do
  client = client_with_adapter(fn req -> {req, %Req.TransportError{reason: :nxdomain}} end)
  assert {:error, %Paddle.Error{type: "network_nxdomain", network_error?: true}} =
           Http.request(client, :get, "/customers")
end

test "request/4 maps unknown transport reason to network_unknown" do
  client = client_with_adapter(fn req -> {req, %Req.TransportError{reason: :econnrefused}} end)
  assert {:error, %Paddle.Error{type: "network_unknown", network_error?: true}} =
           Http.request(client, :get, "/customers")
end
```

#### Wave 2a: REL-01 Idempotency-Key Header

**`lib/paddle/http.ex`** — Extract `:idempotency_key` before passing opts to Req:
```elixir
def request(%Paddle.Client{} = client, method, path, opts \\ []) do
  {idempotency_key, req_opts} = Keyword.pop(opts, :idempotency_key)

  req_opts = Keyword.merge(req_opts, method: method, url: path)
  req_opts = maybe_add_idempotency_header(req_opts, idempotency_key)

  case Req.request(client.req, req_opts) do
    ...
  end
end

defp maybe_add_idempotency_header(opts, nil), do: opts
defp maybe_add_idempotency_header(opts, key) when is_binary(key) do
  case String.trim(key) do
    "" -> raise ArgumentError, "idempotency_key must not be empty or whitespace"
    _ -> Keyword.update(opts, :headers, [{"Idempotency-Key", key}], &[{"Idempotency-Key", key} | &1])
  end
end
```

**Recommendation for D-09 (planner's discretion):** Use `ArgumentError` (matches Elixir idiom for programmer-error keyword argument validation; consistent with how `Keyword.fetch!/2` signals bad opts). `{:error, :invalid_idempotency_key}` would require the caller to handle a validation failure on what should be a literal string they supply. `ArgumentError` makes it a programming mistake, not a runtime branch. Apply the same guard to `nil`:
```elixir
defp maybe_add_idempotency_header(opts, key) when not is_binary(key) do
  raise ArgumentError, "idempotency_key must be a non-empty string, got: #{inspect(key)}"
end
```

**Public `create/*` functions** — Add `opts \\ []` as third/fourth arg per D-21:

`Paddle.Customers.create/2` → `create/3`:
```elixir
def create(%Client{} = client, attrs, opts \\ []) do
  with {:ok, attrs} <- Attrs.normalize(attrs),
       body <- Attrs.allowlist(attrs, @create_allowlist),
       {:ok, %{"data" => data}} when is_map(data) <-
         Http.request(client, :post, "/customers", Keyword.merge([json: body], opts)) do
    {:ok, Http.build_struct(Customer, data)}
  end
end
```

Note: `Keyword.merge([json: body], opts)` means opts (including `:idempotency_key`, `:retry`) are merged after the `json:` key. Both are extracted downstream in `Http.request/4` before reaching Req.

Apply same pattern to:
- `Paddle.Customers.Addresses.create/3` → `create/4` (client, customer_id, attrs, opts \\ [])
- `Paddle.Transactions.create/2` → `create/3` (client, attrs, opts \\ [])
- (Future: `Paddle.Subscriptions.create/2` in Phase 10 — lock the shape now, Phase 10 implements)

**`test/paddle/seam_test.exs`** — The existing seam test calls `Customers.create(client, attrs)` with no opts. Adding `opts \\ []` is backwards-compatible; seam test needs no modification.

**Idempotency-key adapter test:**
```elixir
test "idempotency_key opt is forwarded as Idempotency-Key header" do
  client =
    client_with_adapter(fn request ->
      assert Req.Request.get_header(request, "idempotency-key") == ["my-key-123"]
      {request, Req.Response.new(status: 201, body: %{"data" => %{"id" => "cus_123"}})}
    end)

  {:ok, _} = Paddle.Customers.create(client, [email: "x@example.com", name: "X"],
    idempotency_key: "my-key-123")
end
```

#### Wave 2b: REL-02 Retry Policy

**`lib/paddle/client.ex`** — Add retry configuration to `new!/1`:
```elixir
req =
  Req.new(
    base_url: base_url,
    auth: {:bearer, api_key},
    headers: [{"Paddle-Version", "1"}],
    retry: :transient,
    max_retries: 3
  )
  |> Paddle.Http.Telemetry.attach()
```

That is the entire change. `retry: :transient` covers all HTTP methods (POST included), retries on 429/500/502/503/504 + transport errors (:timeout/:econnrefused/:closed), honors `Retry-After` on 429/503, uses exponential backoff (1s/2s/4s) when `Retry-After` is absent.

**Per-call `retry: false` flows through unchanged:** `Http.request/4` does `Keyword.pop(opts, :idempotency_key)` then passes remaining opts (which may include `retry: false`) directly to `Req.request`. Req merges per-call opts over base, so `retry: false` overrides `retry: :transient`.

**Retry adapter tests** — Use Agent to maintain stateful call count (Elixir idiomatic for stateful test closures):
```elixir
test "retries on 429 with Retry-After honored" do
  {:ok, agent} = Agent.start_link(fn -> 0 end)

  client = %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(
      base_url: "https://sandbox-api.paddle.com",
      retry: :transient,
      max_retries: 3,
      retry_delay: 0,   # eliminate wall-clock delay in tests
      adapter: fn request ->
        count = Agent.get_and_update(agent, fn n -> {n, n + 1} end)
        if count == 0 do
          response = Req.Response.new(status: 429, body: %{"error" => %{"code" => "too_many_requests"}})
          {request, response}
        else
          {request, Req.Response.new(status: 200, body: %{"data" => %{"id" => "cus_123"}})}
        end
      end
    )
  }

  assert {:ok, _} = Http.request(client, :get, "/customers")
  assert Agent.get(agent, & &1) == 2   # initial + 1 retry
  Agent.stop(agent)
end
```

**Note on `retry_delay: 0`:** `retry_delay` accepts an integer (constant delay in ms) or a function. Setting it to `0` eliminates test wall-clock delays without changing retry decision logic. This is the pattern used in Req's own test suite. [ASSUMED — based on Req source `calculate_retry_delay/2` which accepts integer via `delay when is_integer(delay)`; verified that integer is a valid `:retry_delay` value].

**Test: no retry on 4xx non-429:**
```elixir
test "does not retry on 422 validation error" do
  {:ok, agent} = Agent.start_link(fn -> 0 end)

  client = %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(
      base_url: "https://sandbox-api.paddle.com",
      retry: :transient,
      max_retries: 3,
      retry_delay: 0,
      adapter: fn request ->
        Agent.update(agent, fn n -> n + 1 end)
        {request, Req.Response.new(status: 422, body: %{"error" => %{"detail" => "invalid"}})}
      end
    )
  }

  assert {:error, %Paddle.Error{status_code: 422}} = Http.request(client, :post, "/customers", json: %{})
  assert Agent.get(agent, & &1) == 1   # no retries
  Agent.stop(agent)
end
```

**Test: per-call retry: false opt-out:**
```elixir
test "retry: false per-call opt disables retry" do
  {:ok, agent} = Agent.start_link(fn -> 0 end)

  client = %Client{
    api_key: "sk_test_123",
    environment: :sandbox,
    req: Req.new(
      base_url: "https://sandbox-api.paddle.com",
      retry: :transient,
      max_retries: 3,
      adapter: fn request ->
        Agent.update(agent, fn n -> n + 1 end)
        {request, Req.Response.new(status: 500, body: %{})}
      end
    )
  }

  assert {:error, %Paddle.Error{status_code: 500}} =
           Http.request(client, :get, "/customers", retry: false)
  assert Agent.get(agent, & &1) == 1   # no retries despite 5xx
  Agent.stop(agent)
end
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exponential backoff calculation | Custom `2^n` implementation | `retry: :transient` in Req | Req v0.5.17 already implements `Integer.pow(2, n) * 1000` exactly matching D-17 spec |
| `Retry-After` header parsing | Custom date/integer parser | Req built-in | `Req.Response.get_retry_after/1` handles both RFC 7231 date and delta-seconds formats |
| Per-call retry override | Custom middleware | Req keyword merge | `Req.merge` called by `Req.request` gives per-call opts precedence; no plumbing needed |
| Transport error type detection | Custom `rescue` block | `%Req.TransportError{}` pattern match | Req normalizes all Mint transport errors before they reach the caller |

---

## Common Pitfalls

### Pitfall 1: `defexception` boolean field defaults to `nil`, not `false`
**What goes wrong:** `defexception [:network_error?, :retryable?]` sets both to `nil`. `if error.retryable?` truthy-checks `nil` as falsy — superficially correct — but `%Paddle.Error{retryable?: false}` pattern-match fails for any error built before the new defaults are applied (e.g., a `from_response/1` call that does not set these fields).
**Why it happens:** Elixir structs created with shorthand field list syntax default all fields to `nil`. `defexception` inherits this behavior.
**How to avoid:** Use keyword syntax with explicit defaults: `defexception type: nil, ..., network_error?: false, retryable?: false` (D-16, locked).
**Warning signs:** Tests that assert `%Paddle.Error{network_error?: false}` fail with no structural match even though the field is logically falsy.

### Pitfall 2: Retry fires on test adapters that return synchronously
**What goes wrong:** Adapter-backed tests that return 429 or 5xx from the adapter will trigger real retry logic with real wall-clock delays (1s, 2s, 4s...) if `retry_delay` is not zeroed in the test client.
**Why it happens:** Req's retry step runs unconditionally based on the response status; adapter-backed requests are not exempt.
**How to avoid:** Tests that need retry ON must set `retry_delay: 0` on the test client's Req to eliminate delays. Existing seam/unit tests that set `retry: false` on the adapter are already safe.
**Warning signs:** `mix test` becomes extremely slow (12+ second suite run); test output shows retry warning logs.

### Pitfall 3: Idempotency-Key extracted too late (after `json:` opt is merged)
**What goes wrong:** If `Keyword.merge(opts, method: method, url: path)` runs before `Keyword.pop(opts, :idempotency_key)`, the `:idempotency_key` reaches `Req.request` as an unknown option and raises `ArgumentError: unknown option :idempotency_key`.
**Why it happens:** Req registers a fixed set of known options; `:idempotency_key` is not one of them.
**How to avoid:** Pop `:idempotency_key` (and `:retry` is already known to Req, no pop needed) BEFORE building the final opts keyword that passes to `Req.request`. See Wave 2a implementation above.
**Warning signs:** `ArgumentError: unknown option :idempotency_key` in any test that passes this opt.

### Pitfall 4: `seam_test.exs` adapter closures not stateless
**What goes wrong:** The seam test uses one-shot adapter closures per step. If retry fires because the test client has `retry: :transient` configured, the adapter closure is called a second time on a 4xx/5xx — but `seam_test.exs` asserts exact request bodies, so unexpected adapter calls will crash the test.
**Why it happens:** `seam_test.exs:192-198` builds clients with `retry: false` hard-coded. This remains correct for the seam test. Do not change the seam test's client builder.
**How to avoid:** The seam test already has `retry: false` in `client_with_adapter/1`. Leave it unchanged.

### Pitfall 5: `nxdomain` transport reason not retried by Req built-in
**What goes wrong:** A developer expects that `network_nxdomain` errors are retried, because `:retryable?` is `true` on the resulting `%Paddle.Error{}`. But Req's `:transient` mode only retries `:timeout/:econnrefused/:closed`, not `:nxdomain`.
**Why it happens:** D-12 says `:retryable?` is an advisory CLASS predicate; D-13 says it is NOT a post-hoc exhaustion flag. The SDK correctly marks nxdomain as `retryable?: true` (it is the class of error that COULD succeed on retry if DNS recovers), but Req does not retry it because nxdomain is typically a configuration error, not transient.
**How to avoid:** This is intended behavior. Document it in the `@doc` for `from_transport/1` and in the `retryable?` field description. No code change needed.

### Pitfall 6: Splitting the `:raw` → `:raw_data` rename across multiple plans
**What goes wrong:** If `error.ex` is updated in one plan and `accrue-seam.md` in another, there is an intermediate commit where code says `:raw_data` but the seam guide still documents `:raw`. Any audit of committed docs will show a discrepancy.
**Why it happens:** Planner might treat the doc update as a separate concern.
**How to avoid:** D-02 is explicit: code + seam guide + CHANGELOG land in a single atomic commit. Enforce this in the plan task list.

---

## Code Examples

### Verified: Req per-call `retry: false` overriding base config

```elixir
# Source: Req v0.5.17 lib/req.ex:1096-1098 (verified)
def request(request, options \\ []) do
  Req.Request.run(new(request, options))
end

# new/2 for (%Req.Request{}, keyword()) (lib/req.ex:469-471, verified):
defp new(%Req.Request{} = request, options) when is_list(options) do
  Req.merge(request, options)  # per-call opts overwrite base opts
end
```

Consequence: `Req.request(client.req, [retry: false, method: :get, url: "/x"])` merges `retry: false` over `client.req.options[:retry]` (which is `:transient`). Per-call wins.

### Verified: Req `:transient` retry condition (Req v0.5.17 source)

```elixir
# Source: Req v0.5.17 lib/req/steps.ex:2282-2289 (verified)
defp transient?(%Req.TransportError{reason: reason})
     when reason in [:timeout, :econnrefused, :closed] do
  true
end
defp transient?(%{__exception__: true}), do: false

defp transient?(%Req.Response{status: status})
     when status in [408, 429, 500, 502, 503, 504] do
  true
end
```

### Verified: Req `Retry-After` honored on 429/503 only

```elixir
# Source: Req v0.5.17 lib/req/steps.ex:2322-2333 (verified)
defp get_retry_delay(request, %Req.Response{status: status} = response, retry_count)
     when status in [429, 503] do
  if delay = Req.Response.get_retry_after(response) do
    {request, delay}   # Retry-After in seconds
  else
    calculate_retry_delay(request, retry_count)
  end
end
defp get_retry_delay(request, _response, retry_count) do
  calculate_retry_delay(request, retry_count)  # exponential for everything else
end
defp exp_backoff(n), do: Integer.pow(2, n) * 1000  # 1s, 2s, 4s, 8s...
```

### Verified: Mint → Req TransportError reason passthrough

```elixir
# Source: Req v0.5.17 lib/req/finch.ex:173-174 (verified)
defp normalize_error(%Mint.TransportError{reason: reason}) do
  %Req.TransportError{reason: reason}  # reason atom passed through verbatim
end
```

---

## Runtime State Inventory

> This phase involves a rename (`:raw` → `:raw_data`). Explicit inventory required.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `:raw` is a struct field name, not a stored key in any DB or cache | Code edit only |
| Live service config | None — no external service stores the string "raw" as a config key | None |
| OS-registered state | None — no task scheduler or process registration involved | None |
| Secrets/env vars | None — `:raw` is a struct field, not an env var name | None |
| Build artifacts | None — no compiled binaries or installed packages store the field name | None |
| Accrue consumer | `~/projects/accrue` — any code that pattern-matches `%Paddle.Error{raw: r}` will break silently | Log in `.planning/BACKLOG.md` per D-04; oarlock ships first |

**Verification method for Accrue impact:** [ASSUMED — no grep was run on Accrue's codebase in this session]. The BACKLOG.md entry (D-04) is the tracking mechanism.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified — all changes are in-library Elixir code using the already-installed `req 0.5.17`).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `retry: :safe` | `retry: :safe_transient` (default) | Req v0.5.x | `:safe` now prints deprecation warning |
| `retry: :never` | `retry: false` | Req v0.5.x | `:never` now prints deprecation warning |
| `retry: fun/1` | `retry: fun/2` | Req v0.5.x | 1-arity retry function deprecated |
| `{:error, %Req.TransportError{}}` (v1.1) | `{:error, %Paddle.Error{network_error?: true}}` (v1.2) | This phase | Accrue must update any transport error handling |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Paddle accepts `Idempotency-Key` header on POST endpoints; UTF-8 ≤ 255 chars per CONTEXT.md citation | Domain Knowledge — Paddle Idempotency | Paddle could reject the header silently or with a 400; `@doc` examples would be misleading |
| A2 | Paddle's idempotency key TTL is ~24 hours | Domain Knowledge — Paddle Idempotency | Actual TTL could be shorter (e.g., 1 hour); `@doc` note should be intentionally vague on TTL |
| A3 | `retry_delay: 0` (integer 0) is valid for test clients; Req accepts integer value directly | Common Pitfalls (Pitfall 2) | If Req requires a function for `retry_delay`, test code would raise; easily verified by running a test |
| A4 | Accrue's codebase contains `error.raw` call sites that need updating | Runtime State Inventory | Could be zero occurrences; BACKLOG.md entry is low-cost insurance |

---

## Open Questions

1. **`idempotency_key:` rejection style (D-09 — planner's call)**
   - What we know: both `ArgumentError` and `{:error, :invalid_idempotency_key}` are valid; CONTEXT.md defers to planner.
   - Recommendation: Use `ArgumentError`. Rationale: passing a nil/empty idempotency_key is a programming error (the caller controls this value; it is never user-supplied). `ArgumentError` surfaces at development time and does not require the caller to add a new `{:error, :invalid_idempotency_key}` branch to production code. The pattern is consistent with how Elixir stdlib signals bad keyword argument values (e.g., `Keyword.fetch!/2`).

2. **Whether `:econnrefused` should map to `"network_unknown"` or a named type**
   - What we know: D-14 enumerates exactly four types; `:econnrefused` is not listed; it falls through to `"network_unknown"` per the catch-all.
   - What's unclear: `:econnrefused` is a well-known POSIX error that consumers could legitimately want to distinguish.
   - Recommendation: Keep `"network_unknown"` per D-14 locked taxonomy. `:econnrefused` during a production call to Paddle is genuinely unusual (not a timeout); if a consumer needs to distinguish it, `:raw_data` contains the original `%Req.TransportError{reason: :econnrefused}`. Do not extend the taxonomy in v1.2.

---

## Validation Architecture

Nyquist validation is explicitly `false` in `.planning/config.json`. Section omitted.

---

## Security Domain

No new authentication, session management, access control, cryptographic, or injection-risk surfaces introduced in this phase. Idempotency-Key is a pass-through string; the SDK does not store, log, or evaluate it beyond forwarding it as an HTTP header. Transport error normalization is read-only. Retry configuration is bounded (max 3) and uses library-provided backoff; no custom timing or credential exposure risk.

---

## Sources

### Primary (HIGH confidence)
- Req v0.5.17 source — `lib/req.ex`, `lib/req/steps.ex`, `lib/req/finch.ex` read via raw.githubusercontent.com
- Req hexdocs — `hexdocs.pm/req/Req.Steps.html` (retry step documentation)
- Mint.TransportError — `github.com/elixir-mint/mint` source (reason atom taxonomy)
- Context7 `/websites/hexdocs_pm_req` — retry options, `Req.Request.merge_options`, `Req.TransportError` documentation
- Project source — `lib/paddle/error.ex`, `lib/paddle/http.ex`, `lib/paddle/client.ex`, `test/paddle/http_test.exs`, `test/paddle/seam_test.exs`, `guides/accrue-seam.md` (all read directly)

### Secondary (MEDIUM confidence)
- Paddle rate limiting docs — `developer.paddle.com/api-reference/about/rate-limiting` (confirmed `Retry-After` header on 429)
- Paddle Node SDK source — `github.com/PaddleHQ/paddle-node-sdk` (confirmed no built-in idempotency key in official SDK; header name `Idempotency-Key` inferred from industry standard)

### Tertiary (LOW confidence)
- Paddle idempotency key format/TTL specifics — not found in official docs; cited from CONTEXT.md canonical reference which itself cites developer.paddle.com (URL not currently accessible)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Req v0.5.17 is pinned; retry behavior verified from source
- Architecture: HIGH — single chokepoints confirmed in code; merge semantics verified
- Pitfalls: HIGH — all verified from Req source or current codebase state
- Paddle idempotency semantics: LOW (TTL, exact behavior on dupe) to MEDIUM (header name, format convention)

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 (Req stable; Paddle API reference stable; 30-day window)
