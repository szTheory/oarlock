# Phase 32: Dependency & SDK Trust Boundary - Context

**Gathered:** 2026-09-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing SDK trust boundary safe and truthful: move off the vulnerable Req line with compatibility proof, constrain telemetry and inspection to non-secret information, make retries method-aware, surface ambiguous mutation outcomes for reconciliation, validate client construction, and align the public contract with tested behavior. This phase may change existing dependency and SDK behavior with migration guidance, but it does not add Paddle endpoint breadth, make hosted CI authoritative (Phase 33), or publish releases (Phase 34).

</domain>

<decisions>
## Implementation Decisions

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

### Agent's Discretion
- Exact helper/module boundaries, telemetry metadata key names, route-normalization representation, and test-file organization are open as long as the allowlist and absence guarantees hold.
- The exact finite `Retry-After` cap, backoff/jitter calculation, and normalized error taxonomy are left to phase research and planning; all must remain deterministic under tests and within the attempt/time bounds above.
- The exact `%Paddle.Error{}` field names for ambiguity and reconciliation are flexible, provided the existing tuple/struct return contract remains intact and Dialyzer/public docs agree.
- Research must verify operation-specific current Paddle idempotency guarantees before the planner chooses the concrete removal or retention list; lack of explicit provider proof means removal.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current scope and routing
- `.planning/PROJECT.md` — Pure-library boundary, explicit client model, current milestone direction, stable Accrue seam, and deferred endpoint breadth.
- `.planning/REQUIREMENTS.md` — Canonical SAFE-01 through SAFE-06 requirements and v2.2 out-of-scope boundaries.
- `.planning/ROADMAP.md` — Phase 32 goal, dependency, success criteria, and separation from CI/release phases.
- `.planning/STATE.md` — Current execution pointer, accumulated decisions, vulnerable Req concern, and remote-proof caveats.

### Milestone research and provider-risk rationale
- `.planning/research/SUMMARY.md` — Recommended Phase 32 ordering, Req target, compatibility matrix, and deeper-research flags.
- `.planning/research/STACK.md` — Dependency/advisory baseline, proposed Req constraint, Hex audit choice, and compatibility/versioning implications.
- `.planning/research/FEATURES.md` — Adopter, reliability, and security jobs plus observable safety-contract outcomes and anti-features.
- `.planning/research/ARCHITECTURE.md` — Ownership boundaries among `Paddle.Client`, `Paddle.Http`, telemetry, inspection protocols, and resource modules.
- `.planning/research/PITFALLS.md` — Concrete credential leakage, mutation replay, false-idempotency, dependency-upgrade, and validation failure modes.

### Existing dependency and runtime seams
- `mix.exs` — Current Req constraint, public package metadata, docs configuration, and dependency surface.
- `mix.lock` — Root Req 0.5.17 baseline and exact transitive dependency graph.
- `demo/mix.exs` — Demo consumer dependency contract.
- `demo/mix.lock` — Independently resolved demo Req baseline that must migrate coherently.
- `.tool-versions` — Intended BEAM toolchain input; inspect but do not overwrite the pre-existing user modification.
- `bin/package_smoke.sh` — Existing packaged-consumer proof path.
- `test/paddle/seam_test.exs` — Locked Accrue/public contract and documentation seam proof.
- `test/paddle/mock_server_test.exs` — Offline adapter/server behavior that the Req migration must preserve.
- `test/paddle/subscription_flows_test.exs` — MockServer-backed lifecycle integration proof.

### SDK safety implementation
- `lib/paddle/client.ex` — Current unvalidated client construction, global Req retry configuration, bearer credential storage, and telemetry attachment point.
- `lib/paddle/http.ex` — Central request path, idempotency-header handling, error normalization, and struct hydration with `raw_data`.
- `lib/paddle/http/telemetry.ex` — Current lifecycle events that expose full transport objects.
- `lib/paddle/notification_setting.ex` — Public endpoint secret duplicated into `raw_data` without custom inspection.
- `lib/paddle/portal_session.ex` — Existing redaction precedent that still leaves secret-capable `raw_data` visible.
- `lib/paddle/subscription/management_urls.ex` — Public authenticated management URLs requiring inclusion in the secret-bearing-value inventory.
- `lib/paddle/transaction/checkout.ex` — Public checkout URL value requiring classification by the inspection inventory.
- `lib/paddle/error.ex` — Existing normalized public error struct to extend for ambiguous mutation guidance.
- `test/paddle/client_test.exs` — Existing constructor/default/custom-URL contract tests.
- `test/paddle/http_test.exs` — Current all-method retry and idempotency-header behavior plus attempt-count fixtures.
- `test/paddle/http/telemetry_test.exs` — Existing event contract tests to convert to allowlist/canary assertions.
- `test/paddle/portal_session_test.exs` — Existing promoted-URL redaction proof to extend through nested `raw_data`.

### Public contract documentation
- `README.md` — Primary installation, explicit-client, safety, and guide-navigation claims.
- `guides/getting-started.md` — Copied client, retry/idempotency, and app-owned reconciliation examples.
- `guides/telemetry.md` — Public telemetry event and metadata contract.
- `guides/accrue-seam.md` — Downstream stable-seam and compatibility vocabulary.
- `CHANGELOG.md` — Consumer-visible migration and behavior-change record.

No external product specification or ADR was supplied for this phase. Current provider/library claims must be revalidated from official documentation during phase research rather than copied from milestone research without checking.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Paddle.Http.request/4`: one central request boundary already normalizes transport/provider outcomes and can enforce method-aware retry invariants.
- `Paddle.Http.Telemetry.attach/1`: existing Req request/response/error step hooks preserve event integration points while allowing metadata projection to be replaced.
- `Inspect` for `Paddle.PortalSession`: established custom-inspection shape and `[REDACTED]` convention to generalize safely.
- `%Paddle.Error{}` and `from_transport/1`: stable tuple/struct error surface that can carry an explicit ambiguous-outcome classification without inventing a new return family.
- Existing adapter/Agent-based retry tests: deterministic attempt counting already exists and can become the verb/status/failure matrix.

### Established Patterns
- The SDK uses explicit clients, pure functions, typed structs, and `{:ok, value} | {:error, %Paddle.Error{}}`; safety changes should preserve those integration patterns.
- Provider responses retain `raw_data` for forward compatibility. Secret-bearing values therefore need a deliberate inspection boundary rather than mutation/removal of stored raw payloads.
- Resource modules declare request option types and forward to `Paddle.Http`; public option cleanup must cover types, validation, docs, and every mutation call site together.
- MockServer proof is intentionally offline and bounded. It validates SDK behavior but cannot establish live Paddle idempotency semantics.

### Integration Points
- `Paddle.Client.new!/1` currently sets `retry: :transient` and `max_retries: 3` for every method, stores the API key twice (promoted field and Req auth), and accepts blank keys or arbitrary environments.
- `Paddle.Http.Telemetry` currently emits whole `%Req.Request{}` and `%Req.Response{}` values, making authorization headers, bodies, and signed URLs reachable by subscribers.
- `Paddle.Http.build_struct/2` duplicates provider values into promoted fields and `raw_data`; redaction tests must use provider-built values rather than hand-built structs without raw payloads.
- Root and demo resolve different vulnerable Req 0.5.x versions, so both lockfiles and consumer behavior belong in the dependency migration proof.
- The working tree already contains unrelated user-owned changes (`.tool-versions`, `.gsd/`, `.planning/research/.cache/`, and `.planning/state.json`); plans must preserve them and avoid treating cleanup as Phase 32 work.

</code_context>

<specifics>
## Specific Ideas

- Keep the telemetry event names stable while replacing unsafe metadata, so subscribers have a focused schema migration rather than an event-topology rewrite.
- Prefer normalized route/operation labels over raw paths so resource IDs, query values, and signed URL material cannot become high-cardinality telemetry.
- Use one visible `[REDACTED]` convention and keep stored data unchanged; safety applies at inspection/telemetry boundaries, not by destroying provider payloads.
- A base URL supplied without an environment is the compatibility path for MockServer and should resolve to an honest `:custom` client rather than a mislabeled sandbox client.
- An ambiguous mutation error should tell consumers to reconcile via safe retrieval, webhook state, or provider tooling—not to retry automatically.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 32. Hosted exact-SHA CI authority remains Phase 33, and release gating/publication remains Phase 34.

</deferred>

---

*Phase: 32-dependency-sdk-trust-boundary*
*Context gathered: 2026-09-10*
