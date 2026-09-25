# Phase 32: Dependency & SDK Trust Boundary - Research

**Researched:** 2026-09-10
**Domain:** Elixir SDK dependency, transport, telemetry, inspection, and public-contract trust boundaries
**Confidence:** HIGH for repository behavior; MEDIUM for current external contracts

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Req upgrade and compatibility proof
- **D-01:** Target Req 0.7.4 as the secure compatibility floor with a `~> 0.7.4` constraint. Phase research may select a newer compatible 0.7 patch only after confirming the same advisory and compatibility properties.
- **D-02:** Make the root/demo dependency and lockfile migration an isolated first plan. Do not mix the dependency delta with retry, telemetry, inspection, or client-validation behavior changes.
- **D-03:** Accept the upgrade only after the supported matrix passes: root tests and custom/function adapters, telemetry steps, MockServer and subscription flows, demo, package smoke, optional-dependency behavior, Dialyzer, generated docs, and the downstream Accrue seam.
- **D-04:** Use the built-in `mix hex.audit` task as the dependency-advisory proof. Do not add duplicate audit tooling. Record any dependency-floor or observable behavior impact in migration/version guidance; actual release gating and publication stay in later phases.

### Telemetry and inspection safety
- **D-05:** Preserve the public event names `[:paddle, :request, :start]`, `:stop`, and `:exception`, but replace the current request/response metadata with a strict allowlist.
- **D-06:** Telemetry may expose only low-cardinality operational facts: HTTP method, normalized operation/route, sanitized host, status or normalized error class, result, attempt count, and monotonic duration. Raw URLs or query values, IDs, `%Req.Request{}`, `%Req.Response{}`, exceptions, headers, bodies, credentials, signed URLs, customer data, and `raw_data` are forbidden.
- **D-07:** Inventory every public value capable of carrying an API credential, endpoint secret, authenticated/signed URL, or an equivalent value copied into a provider payload. `%Paddle.Client{}`, `%Paddle.NotificationSetting{}`, and `%Paddle.PortalSession{}` are the known minimum, not an exhaustive list.
- **D-08:** Inspection is deny-by-default for secret-bearing values. Promoted secrets use one stable `[REDACTED]` marker, and `raw_data` is redacted wholesale wherever it can duplicate or introduce secrets; do not rely on field-name filtering to make arbitrary nested provider data safe.
- **D-09:** Safety tests use unique canaries and recursively prove their absence from every telemetry outcome and every inspected secret-bearing value, including realistic nested `raw_data` and transport state.

### Retry, idempotency, and ambiguity semantics
- **D-10:** Only safe reads (`GET`/`HEAD`) may retry automatically, and only for documented transient transport failures and retryable HTTP responses. `POST`, `PATCH`, `PUT`, and `DELETE` default to one attempt.
- **D-11:** Preserve the current ceiling of three retries (four total attempts) for eligible reads. Honor `Retry-After` for read-side `429` responses only within a documented finite cap; prove exact attempt counts and terminal outcomes.
- **D-12:** A per-call retry option may disable or further restrict retries but may not opt a mutation back into unsafe automatic replay. Unsupported enabling combinations must fail clearly before dispatch rather than being silently ignored.
- **D-13:** Retain `idempotency_key` only on operations whose current Paddle contract explicitly proves support and replay semantics. Where that proof is absent, remove the misleading option/types with migration guidance; sending a header is never treated as deduplication evidence.
- **D-14:** Preserve the public `{:error, %Paddle.Error{}}` shape for ambiguous mutation failures. Add an explicit non-retryable ambiguity/reconciliation signal with safe operation, resource, and provider request identifiers when available, plus lookup/webhook/provider-state guidance. Never attach credentials or request bodies to that guidance.

### Client validation and public contract truth
- **D-15:** Keep explicit `%Paddle.Client{}` construction and `new!/1`; do not introduce global application configuration. Validate known options, a nonblank binary API key, `:sandbox | :live | :custom`, and an absolute HTTP(S) base URL with a host. Do not hard-code a full Paddle credential regex.
- **D-16:** Preserve existing base-URL-only MockServer usage by inferring `:custom` when a noncanonical URL is supplied without an environment. `environment: :custom` requires a base URL; explicit `:sandbox`/`:live` paired with a conflicting noncanonical URL is invalid.
- **D-17:** Invalid construction fails immediately and consistently with `ArgumentError`. Messages identify the invalid option but never interpolate an API key, credentialized URL, or other secret input.
- **D-18:** Update README, Getting Started, telemetry and Accrue seam guides, module docs/types, examples, changelog, and migration notes from one tested runtime contract. Mechanically guard retry/idempotency claims, validation examples, supported BEAM and Req ranges, evidence boundaries, and pre-1.0 compatibility impact.
- **D-19:** Documentation must distinguish local/unit, MockServer, package/downstream, sandbox, hosted CI, and live-provider evidence. No provider idempotency or compatibility guarantee may be claimed from a mock or header-presence test alone.

### the agent's Discretion
- Exact helper/module boundaries, telemetry metadata key names, route-normalization representation, and test-file organization are open as long as the allowlist and absence guarantees hold.
- The exact finite `Retry-After` cap, backoff/jitter calculation, and normalized error taxonomy are left to phase research and planning; all must remain deterministic under tests and within the attempt/time bounds above.
- The exact `%Paddle.Error{}` field names for ambiguity and reconciliation are flexible, provided the existing tuple/struct return contract remains intact and Dialyzer/public docs agree.
- Research must verify operation-specific current Paddle idempotency guarantees before the planner chooses the concrete removal or retention list; lack of explicit provider proof means removal.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 32. Hosted exact-SHA CI authority remains Phase 33, and release gating/publication remains Phase 34.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SAFE-01 | SDK consumer can install a compatibility-tested Req release that resolves the known advisories, while `mix hex.audit` passes. | Isolated dependency plan, official advisory ranges, full local compatibility matrix, hard audit gate. |
| SAFE-02 | Telemetry subscriber receives stable allowlisted metadata without request/response objects, API credentials, bodies, signed URLs, secrets, or raw customer data. | Attempt-scoped span pattern, static operation metadata, recursive canary tests. |
| SAFE-03 | Inspecting any public secret-bearing struct redacts secrets from both promoted fields and nested raw provider payloads. | Public-value inventory and deny-by-default inspection pattern. |
| SAFE-04 | Safe reads use bounded, documented retry behavior, while ambiguous mutations are not blindly replayed and instead return actionable reconciliation guidance. | Req 0.7 retry semantics, custom bounded classifier, removal of unsupported idempotency, error extension. |
| SAFE-05 | Client construction rejects blank credentials, unsupported environments, and invalid configuration while preserving deliberate custom-base-URL MockServer use. | Constructor truth table and secret-safe validation pattern. |
| SAFE-06 | Public documentation, examples, types, support claims, retry guidance, and migration notes agree with tested runtime behavior. | Contract-first docs inventory and mechanical seam assertions. |
</phase_requirements>

## Summary

Phase 32 should be planned as five ordered slices: (1) an isolated Req/lockfile compatibility migration, (2) validated client construction, (3) method-aware retries plus ambiguity/idempotency cleanup, (4) telemetry and inspection containment, and (5) contract documentation and the complete proof matrix. The repository currently pins Req `"~> 0.5.17"`, while the explicit client installs `retry: :transient` with `max_retries: 3`, meaning mutation replay is possible today. [VERIFIED: mix.exs:40-48; lib/paddle/client.ex:55-76]

Req 0.7.4's documented `:safe_transient` policy retries only GET/HEAD for HTTP 408, 429, 500, 502, 503, and 504; transport reasons `:timeout`, `:econnrefused`, and `:closed`; and HTTP/2 `:unprocessed` and `:pool_not_available`. Its default maximum is three retries/four attempts. [CITED: https://req.hexdocs.pm/Req.Steps.html#retry/1] That default is not sufficient by itself: Req also honors `Retry-After` for 503 and does not impose this phase's finite 429-only cap, so Oarlock needs a custom policy at the central HTTP boundary. [CITED: https://req.hexdocs.pm/Req.Steps.html#retry/1]

Paddle's SDK guidance explicitly says client-supplied idempotency keys are not supported for arbitrary operations and directs callers to retrieve/list provider state after an uncertain create. Therefore remove `idempotency_key` from every current public option/type/call path; do not retain any operation on header-presence evidence. [CITED: https://developer.paddle.com/sdks/libraries/] Paddle documents 429 with `Retry-After` and a normal platform limit of 60 seconds, making 60,000 ms a defensible finite cap for safe reads. [CITED: https://developer.paddle.com/api-reference/about/rate-limiting/]

**Primary recommendation:** Centralize request policy in `Paddle.Http`, make method/operation context explicit and non-secret, and require the full D-03 matrix plus online `mix hex.audit` before accepting the dependency slice.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Client validation | SDK boundary (`Paddle.Client`) | HTTP transport | Invalid state must fail before Req construction or dispatch. |
| Retry and ambiguity | HTTP transport (`Paddle.Http`) | Resource modules | The central boundary knows method/outcome; resources supply normalized operation context. |
| Telemetry projection | HTTP transport instrumentation | Resource modules | Attempt lifecycle belongs around transport; resource modules supply static labels. |
| Safe inspection | Public value modules | HTTP hydration | Each public struct owns its representation; hydration supplies realistic `raw_data`. |
| Contract truth | Docs/types/tests | Package/downstream seams | Claims must be derived from and mechanically checked against behavior. |

```text
Caller
  -> Paddle.Client.new! (validate; classify sandbox/live/custom)
  -> Resource function (static operation + normalized route label)
  -> Paddle.Http.request (validate retry option and method)
       -> attempt start telemetry (allowlist only)
       -> Req transport
       -> read transient? --yes--> bounded delay -> next attempt (max four total)
       -> mutation uncertainty? --yes--> non-retryable Paddle.Error + reconciliation
       -> terminal stop/exception telemetry (allowlist only)
  -> hydrated public value -> deny-by-default Inspect projection
```

## Project Constraints (from AGENTS.md)

No repository-root `AGENTS.md`, `.codex/AGENTS.md`, or `CLAUDE.md` was present. The demo-local instructions require using the already included Req client, running `mix precommit` for demo completion, reading Mix task help, avoiding `mix deps.clean --all`, and using targeted tests while debugging. [VERIFIED: demo/AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Req | `~> 0.7.4` | HTTP transport and retry hooks | Locked secure floor; 0.7.4 was published 2026-08-26 and is outside both explicit affected ranges below. [CITED: https://hex.pm/packages/req/0.7.4] |
| telemetry | existing `~> 1.4` | Stable SDK lifecycle events | Existing dependency and public event contract. [VERIFIED: mix.exs:40-48; lib/paddle/http/telemetry.ex:4-37] |
| Hex audit task | installed Hex (`mix hex.audit`) | Advisory and retirement gate | Official task exits nonzero when vulnerable or retired dependencies are found. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html] |

No new package is needed. The known Req multipart header-injection advisory affects `>= 0.5.3 and < 0.6.0`; the decompression-bomb advisory affects `>= 0.1.0 and < 0.6.1`. Req 0.7.4 is beyond both declared upper bounds. [CITED: https://hex.pm/packages/req/advisories]

**Installation:** change the root constraint to `{:req, "~> 0.7.4"}`, regenerate both root and demo locks from an authenticated/current Hex registry, and commit the two lock deltas in the isolated first plan. [VERIFIED: mix.exs:40-48; demo/mix.exs:61-69]

## Package Legitimacy Audit

The GSD package-legitimacy seam supports npm, PyPI, and crates, not Hex; it cannot issue an `OK` verdict for an Elixir package. [VERIFIED: local `gsd_run query package-legitimacy check` usage response] Compensating evidence is the official Hex package page, official Req documentation/source, the existing repository dependency, and the mandated `mix hex.audit` acceptance gate. [CITED: https://hex.pm/packages/req/0.7.4]

| Package | Registry | Published | Source Repo | Verdict | Disposition |
|---|---|---|---|---|---|
| `req` | Hex | 2026-08-26 | `github.com/wojtekmach/req` | N/A — Hex unsupported by seam | Approved only at locked 0.7.4 floor, subject to full matrix and online audit. |

**Packages removed due to SLOP verdict:** none.  
**Packages flagged as suspicious:** none. No new package is introduced.

## Architecture Patterns

### Recommended Project Structure

```text
lib/paddle/
├── client.ex                    # constructor validation and safe Inspect
├── http.ex                      # method-aware policy, operation context, normalization
├── http/telemetry.ex            # attempt spans and allowlisted projection
├── error.ex                     # ambiguity/reconciliation fields
└── public value modules         # secret-aware Inspect implementations
test/paddle/
├── client_test.exs
├── http_test.exs
├── http/telemetry_test.exs
├── inspection_safety_test.exs   # cross-struct recursive canaries
└── seam_test.exs                # contract/doc drift guards
```

### Pattern 1: Policy at the central request seam

Resource modules must pass method plus static `operation`/`route` metadata into `Paddle.Http.request/4`; never derive a telemetry label by logging the runtime URL. The current central path already owns dispatch, idempotency-header injection, error normalization, and `raw_data` hydration. [VERIFIED: lib/paddle/http.ex:4-63]

Use a custom Req retry callback that returns false for every non-GET/HEAD request; retries only the official Req transient set for reads; clamps a 429 `Retry-After` delay to 60,000 ms; uses deterministic bounded delays for all other eligible failures; and retains `max_retries: 3`. [CITED: https://req.hexdocs.pm/Req.Steps.html#retry/1] Validate per-call retry options before calling Req: `false` disables; enabling on mutation raises `ArgumentError`; a read may retain or further restrict the client policy.

### Pattern 2: One telemetry span per physical attempt

The public names are exactly `[:paddle, :request, :start]`, `[:paddle, :request, :stop]`, and `[:paddle, :request, :exception]`. [VERIFIED: lib/paddle/http/telemetry.ex:11-34] Track a private attempt counter and monotonic start value on the Req request; emit terminal telemetry before Req's retry step consumes a transient result. Telemetry's span convention uses system time at start and monotonic duration on stop/exception. [CITED: https://hexdocs.pm/telemetry/readme.html#spans]

Allowlisted metadata should be limited to method, static operation, normalized route, URI host, status/error class, result, and attempt. Measurements should be `system_time` at start and native-unit `duration` at stop/exception. Never include the request, response, exception, URL/path/query, identifiers, headers, bodies, or raw values.

### Pattern 3: Deny-by-default inspection

Custom Inspect implementations must replace sensitive promoted fields and the entire secret-capable `raw_data` container with the literal `"[REDACTED]"`; do not recursively search field names. The minimum exact repository fields are:

- Client: `api_key`, `environment`, `base_url`, `req`. [VERIFIED: lib/paddle/client.ex:25-33]
- NotificationSetting: `destination`, `endpoint_secret_key`, `raw_data`. [VERIFIED: lib/paddle/notification_setting.ex:15-39]
- PortalSession: `urls`, `raw_data`; its current implementation redacts only `urls`. [VERIFIED: lib/paddle/portal_session.ex:13-46]
- Subscription.ManagementUrls: `update_payment_method`, `cancel`, `raw_data`. [VERIFIED: lib/paddle/subscription/management_urls.ex:15-21]
- Transaction.Checkout: `url`, `raw_data`. [VERIFIED: lib/paddle/transaction/checkout.ex:15-20]
- Error: `raw_data`, which may be a map or transport exception. [VERIFIED: lib/paddle/error.ex:32-52]

Paddle describes portal and subscription management URLs as temporary authenticated links that should not be cached, and returns a notification endpoint secret used for signature verification. [CITED: https://developer.paddle.com/api-reference/customer-portals/; https://developer.paddle.com/api-reference/subscriptions/; https://developer.paddle.com/api-reference/notification-settings/create-notification-setting/]

Also audit every public struct containing `raw_data` during implementation: `Paddle.Address`, `Paddle.Adjustment`, `Paddle.Customer`, `Paddle.Error`, `Paddle.Event`, `Paddle.NotificationSetting`, `Paddle.PortalSession`, `Paddle.Price`, `Paddle.Product`, `Paddle.Subscription`, `Paddle.Subscription.ManagementUrls`, `Paddle.Subscription.ScheduledChange`, `Paddle.Transaction`, and `Paddle.Transaction.Checkout` are the current verbatim module inventory. [VERIFIED: lib/paddle/address.ex:15-49; lib/paddle/adjustment.ex:14-48; lib/paddle/customer.ex:14-40; lib/paddle/error.ex:32-52; lib/paddle/event.ex:10-19; lib/paddle/notification_setting.ex:15-39; lib/paddle/portal_session.ex:13-29; lib/paddle/price.ex:16-54; lib/paddle/product.ex:18-44; lib/paddle/subscription.ex:21-73; lib/paddle/subscription/management_urls.ex:15-21; lib/paddle/subscription/scheduled_change.ex:17-24; lib/paddle/transaction.ex:20-64; lib/paddle/transaction/checkout.ex:15-20] For arbitrary provider payloads that can introduce a capability token or credential, redact `raw_data` wholesale; ordinary customer data is not necessarily a credential but must never enter telemetry.

### Pattern 4: Constructor decision table

The exact environment union is `:sandbox | :live | :custom`; canonical URLs are `"https://sandbox-api.paddle.com"` and `"https://api.paddle.com"`. [VERIFIED: lib/paddle/client.ex:25-30; lib/paddle/client.ex:59-64]

| Inputs | Result |
|---|---|
| nonblank binary key; no environment/base URL | sandbox canonical URL |
| base URL only; absolute HTTP(S) with host | infer `:custom` |
| explicit `:custom` plus valid base URL | custom client |
| explicit sandbox/live without URL | matching canonical URL |
| blank/nonbinary key, unknown/duplicate option, unsupported environment, relative/non-HTTP URL, custom without URL, or canonical environment with conflicting URL | secret-safe `ArgumentError` before Req construction |

Do not directly expose `Keyword.validate!/2` errors because its documented exception includes the keyword input; compute invalid/duplicate key names and raise a replacement message that never includes option values. [CITED: https://hexdocs.pm/elixir/Keyword.html#validate!/2] `URI.new/1` validates syntax but still requires explicit checks for HTTP(S) scheme and nonblank host. [CITED: https://hexdocs.pm/elixir/URI.html#new/1]

### Anti-Patterns to Avoid

- Appending an `Idempotency-Key` header and calling the operation idempotent.
- Configuring Req `:transient`, which retries unsafe methods.
- Using Req's default safe retry without constraining 503 `Retry-After` or total wait.
- Emitting transport structs and relying on subscriber discipline.
- Testing only rendered `inspect/1`; canaries must also prove raw telemetry terms contain no forbidden payload.
- Parsing dynamic URLs to invent route labels; the resource call site already knows the operation.
- Reporting a successful MockServer run as live-provider or hosted-CI evidence.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| HTTP retry plumbing | A separate retry loop | Req retry callback/steps plus Oarlock classifier | Preserves one transport pipeline and exposes each physical attempt. |
| URI parsing | String-prefix URL validation | `URI.new/1` plus explicit scheme/host rules | Handles syntax centrally. |
| Advisory scanner | New dependency/tool | `mix hex.audit` | Locked official Hex gate. |
| Secret discovery by key names | Recursive field-name filter | Explicit struct allowlists and wholesale raw container replacement | Unknown provider nesting defeats name filters. |
| Mutation deduplication | SDK-generated idempotency keys | Provider-state reconciliation | Paddle does not promise arbitrary client-supplied keys. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | None — the dependency/SDK changes do not rename persisted keys or schemas. [VERIFIED: Phase 32 boundary in 32-CONTEXT.md] | None. |
| Live service config | None — no Paddle dashboard or hosted configuration change is in scope. [VERIFIED: 32-CONTEXT.md D-19/deferred boundary] | None. |
| OS-registered state | None — no services/tasks are registered by the library. [VERIFIED: mix.exs:33-37] | None. |
| Secrets/env vars | Existing API key inputs remain; no secret name or value migration is required. [VERIFIED: lib/paddle/client.ex:25-33] | Do not print/read real values; use canaries. |
| Build artifacts | Root/demo lock resolutions and compiled Req artifacts reflect the old line. [VERIFIED: mix.exs:40-48; demo/mix.exs:61-69] | Regenerate locks and recompile normally; do not use broad `mix deps.clean --all`. |

## Common Pitfalls

### Retry steps can collapse attempt telemetry

Req reruns its request pipeline and can halt response/error processing while retrying. [CITED: https://raw.githubusercontent.com/wojtekmach/req/v0.7.4/lib/req/steps.ex] If Oarlock's terminal step is ordered after retry, multiple starts may produce only one terminal event. Put terminal instrumentation before retry and prove paired event counts for every attempt.

### Ambiguity is not retryability

For mutation transport failures and uncertain 408/5xx outcomes, return a non-retryable `%Paddle.Error{}` with an explicit ambiguity flag and reconciliation information. Paddle error responses include `meta.request_id`; the current implementation only reads the `x-request-id` header. [CITED: https://developer.paddle.com/api-reference/about/errors/] [VERIFIED: lib/paddle/error.ex:60-72] Parse the provider body request identifier with a safe existing-header fallback, and include only operation/resource/provider request IDs—not bodies or credentials.

### Req 0.7 adapter compatibility warnings

A local temporary path override to official Req 0.7.4 compiled the library and ran `224 tests, 0 failures`, but function adapters emitted deprecation warnings. [VERIFIED: local compatibility probe, 2026-09-10] Treat this as discovery, not acceptance: migrate test adapters to the supported adapter shape in the isolated dependency plan and then run the entire D-03 matrix.

### Inspect fallback can leak

Elixir warns that if a custom Inspect implementation raises, it may fall back to a raw representation. [CITED: https://hexdocs.pm/elixir/Inspect.html] Keep implementations total and simple, and test realistic provider-built structs with nested canaries rather than only hand-built happy paths.

## Code Examples

### Central policy skeleton

```elixir
# Source semantics: https://req.hexdocs.pm/Req.Steps.html#retry/1
# Exact safe methods: GET/HEAD. Exact response set: 408,429,500,502,503,504.
# Exact transport set: timeout,econnrefused,closed. Exact maximum: 3 retries.
def retry_decision(request, response_or_exception) do
  # Return false for mutations; for eligible reads return false/true/{:delay, ms}.
  # Clamp only a 429 Retry-After delay to 60_000 ms.
end
```

### Secret-safe validation error

```elixir
# Never interpolate `opts` or a rejected value.
raise ArgumentError, "invalid option: base_url"
```

### Recursive absence assertion

Tests should place a different unique canary in authorization state, URL/query, body, response, exception, each promoted secret field, and nested `raw_data`; recursively walk maps, structs, tuples, and lists and fail if any canary binary is found. Also assert the exact allowed metadata-key set and reject `%Req.Request{}`, `%Req.Response{}`, and exceptions structurally.

## State of the Art

| Old/current approach | Required approach | Impact |
|---|---|---|
| Req 0.5.x | Req `~> 0.7.4` | Clears explicit advisory ranges; requires adapter compatibility migration and audit. |
| `retry: :transient` globally | custom safe-read policy | Mutations become single-attempt; reads remain bounded. |
| arbitrary idempotency header | remove public option | Honest migration note; reconciliation replaces false guarantee. |
| telemetry transport objects | strict projection | Stable names, intentionally breaking metadata schema. |
| partial PortalSession redaction | cross-struct deny-by-default inspection | Protects promoted and nested secret-bearing values. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None. Recommendations are grounded in locked decisions, opened repository sources, or cited primary documentation. | — | — |

## Open Questions (RESOLVED)

1. **Which idempotency options remain?** None. Paddle supplies no operation-specific replay contract for the current Oarlock methods and explicitly disclaims arbitrary client-supplied keys; remove all current occurrences.
2. **What Retry-After cap should the planner use?** 60,000 ms for read-side 429 only; all other retries use deterministic bounded delays and four total attempts.
3. **Which values require inspection protection?** The explicit capability-bearing minimum listed above, plus wholesale `raw_data` redaction wherever arbitrary provider data can duplicate or introduce such a value.
4. **Does the local advisory command currently prove SAFE-01?** No. The local Hex registry lookup failed because authentication/registry access was unavailable, and offline mode had no cached Req entry. This is resolved as a hard execution checkpoint: restore registry access and require pasted successful `mix hex.audit` output before accepting Plan 1; do not infer a pass from missing data.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Erlang | all validation | yes | 28.1 | — |
| Elixir/Mix | all validation | yes | 1.19.5 | — |
| Hex | dependency/audit | installed, registry unavailable in research session | 2.5.1 | None for final audit; restore access. |
| PostgreSQL | demo tests | yes/running | client 14.17 | — |
| Docker | optional service proof | yes | 29.5.2 | Local PostgreSQL is already reachable. |
| Dialyzer task | type gate | yes | project dependency | — |
| ExDoc task | docs gate | yes | project dependency | — |
| Accrue checkout | downstream seam | yes | local sibling checkout | Run its documented seam command; do not broaden API scope. |

The intended local toolchain is exactly `erlang 28.1`, `elixir 1.19.5-otp-28`, and `nodejs 22.14.0`; preserve the user's existing `.tool-versions` modification. [VERIFIED: .tool-versions:1-3]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit on Elixir 1.19.5 |
| Config file | `test/test_helper.exs`; demo `demo/test/test_helper.exs` |
| Quick run | `mix test test/paddle/client_test.exs test/paddle/http_test.exs test/paddle/http/telemetry_test.exs` |
| Full suite | `mix test` plus the D-03 commands below |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SAFE-01 | Req upgrade compatibility/advisory | integration | `mix test && mix hex.audit` | Partial; Wave 0 adds matrix script/checklist |
| SAFE-02 | allowlisted per-attempt telemetry | unit | `mix test test/paddle/http/telemetry_test.exs` | Yes, rewrite assertions |
| SAFE-03 | promoted/nested secret redaction | unit | `mix test test/paddle/inspection_safety_test.exs` | No — Wave 0 |
| SAFE-04 | read attempt matrix and mutation ambiguity | unit/integration | `mix test test/paddle/http_test.exs` | Yes, extend |
| SAFE-05 | constructor decision table | unit | `mix test test/paddle/client_test.exs` | Yes, extend |
| SAFE-06 | types/docs/runtime agreement | contract | `mix test test/paddle/seam_test.exs` | Yes, extend |

### Required compatibility matrix

Run, record, and keep failures attributable: `mix test`; focused custom/function adapter tests; telemetry tests; `MIX_ENV=test mix test test/paddle/mock_server_test.exs test/paddle/subscription_flows_test.exs`; `mix dialyzer`; `mix docs`; `bin/package_smoke.sh`; root tests without optional Plug/Bandit in a clean packaged consumer; `(cd demo && mix precommit)`; the downstream Accrue seam; then online `mix hex.audit`. The package smoke script builds an unpacked Hex artifact, creates a fresh consumer, and compiles with warnings as errors. [VERIFIED: bin/package_smoke.sh:5-78]

### Sampling Rate

- **Per task commit:** the focused requirement command in the map.
- **Per wave merge:** `mix test` and `mix format --check-formatted`.
- **Dependency plan gate:** complete D-03 matrix and online `mix hex.audit`.
- **Phase gate:** all matrix rows green; docs claim only the evidence tier actually run.

### Wave 0 Gaps

- [ ] `test/paddle/inspection_safety_test.exs` — shared recursive canary walker and public-struct inventory.
- [ ] Add deterministic retry adapter fixtures for method/status/transport/Retry-After matrices.
- [ ] Add mechanical doc assertions for removed idempotency, retry policy, constructor examples, evidence tiers, Req/BEAM ranges, and migration notice.
- [ ] Define the local Accrue seam command in the plan from that checkout's own instructions.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no direct auth implementation | Validate presence/type of caller-supplied bearer key; redact storage/inspection. |
| V3 Session Management | no application sessions | Treat provider portal/management URLs as authenticated capabilities and redact. |
| V4 Access Control | provider-owned | Do not claim authorization enforcement by the SDK. |
| V5 Input Validation | yes | Explicit keyword, environment, URI, method, and retry validation before dispatch. |
| V6 Cryptography | no new crypto | Existing webhook HMAC remains outside this phase; never hand-roll cryptography. |

Relevant ASVS 5 themes are sensitive-data classification, keeping credentials/payment data out of logs/errors, URL validation against SSRF-style abuse, and configured retry/error handling. [CITED: https://github.com/OWASP/ASVS/tree/v5.0.0/5.0/en]

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Bearer/signed URL disclosure through telemetry or Inspect | Information Disclosure | allowlist telemetry; deny-by-default Inspect; recursive canaries |
| Mutation automatic replay | Tampering | method-aware retry classifier and pre-dispatch option validation |
| False idempotency guarantee | Tampering/Repudiation | remove option and provide provider-state reconciliation |
| Credentialized or relative base URL | Spoofing/Information Disclosure | absolute HTTP(S), host, environment-conflict validation; secret-safe errors |
| Unbounded Retry-After | Denial of Service | 60-second clamp, reads only, four attempts maximum |

## Sources

### Primary (HIGH/MEDIUM confidence)

- [Req retry steps](https://req.hexdocs.pm/Req.Steps.html#retry/1) — 0.7.4 safe/transient classifier, delays, and attempt ceiling.
- [Req 0.7.4 source](https://raw.githubusercontent.com/wojtekmach/req/v0.7.4/lib/req/steps.ex) — step ordering and retry implementation.
- [Hex Req 0.7.4](https://hex.pm/packages/req/0.7.4) and [advisories](https://hex.pm/packages/req/advisories) — package provenance and affected ranges.
- [Hex audit task](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html) — authoritative audit semantics.
- [Paddle SDK libraries](https://developer.paddle.com/sdks/libraries/) — no arbitrary client idempotency; reconciliation.
- [Paddle rate limits](https://developer.paddle.com/api-reference/about/rate-limiting/) — 429/Retry-After/current normal window.
- [Paddle errors](https://developer.paddle.com/api-reference/about/errors/) — request identifier and 5xx guidance.
- [Telemetry spans](https://hexdocs.pm/telemetry/readme.html#spans), [Elixir Inspect](https://hexdocs.pm/elixir/Inspect.html), [Keyword](https://hexdocs.pm/elixir/Keyword.html#validate!/2), [URI](https://hexdocs.pm/elixir/URI.html#new/1).
- Opened repository files cited inline — exact current values and paths.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked dependency and explicit advisory ranges; audit result remains an execution gate.
- Architecture: HIGH — based on opened central seams and locked boundaries.
- Pitfalls: HIGH — reproduced Req compatibility warnings and verified primary docs.

**Research date:** 2026-09-10  
**Valid until:** 2026-10-10 for Req/Hex; recheck Paddle docs immediately before implementation because provider contracts can change.
