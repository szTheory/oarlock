# Phase 9: Pagination Ergonomics (0/? plans) - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Add ergonomic auto-pagination over the existing Paddle list endpoints so consumers can iterate across all result pages without hand-rolling cursor loops.

This phase is additive. The existing per-resource `list/*` functions stay locked and continue returning `{:ok, %Paddle.Page{}}` or `{:error, reason}`. Auto-pagination is built on top of `Paddle.Page.next_cursor/1`; it does not replace that accessor, change `%Paddle.Page{}` fields, introduce Phoenix/Ecto coupling, or broaden the Paddle resource surface.

Current in-scope list endpoints:
- `Paddle.Subscriptions.list(client, params \\ [])`
- `Paddle.Customers.Addresses.list(client, customer_id, params \\ [])`

</domain>

<decisions>
## Implementation Decisions

### Public helper surface

- **D-01:** Use per-resource public helpers, not top-level `Paddle.stream/3` / `Paddle.all/3`. PAGE-01's "or per-resource equivalents" branch is selected because the root `Paddle` module is currently sealed with `@moduledoc false`, while resource modules are the documented public seam.
- **D-02:** Add these public functions in Phase 9:
  - `Paddle.Subscriptions.stream(client, params \\ [])`
  - `Paddle.Subscriptions.all(client, params \\ [])`
  - `Paddle.Customers.Addresses.stream(client, customer_id, params \\ [])`
  - `Paddle.Customers.Addresses.all(client, customer_id, params \\ [])`
- **D-03:** Do not add public `Paddle.stream/3`, public `Paddle.all/3`, or public `Paddle.Pagination` in Phase 9. Generic callback APIs such as `Paddle.Pagination.stream(client, fun, params)` are less discoverable, awkward for scoped endpoints, and would create a new abstraction callers must learn before using pagination.
- **D-04:** Back the per-resource helpers with a hidden shared implementation, probably `Paddle.Internal.Pagination` with `@moduledoc false`, so every current and future list endpoint gets identical pagination semantics without duplicating cursor/error logic.
- **D-05:** Future list endpoints should add colocated `stream` / `all` helpers alongside their `list` functions when they become public. Do not expose one generic public helper as a substitute for per-resource discoverability.

### Stream and eager-all error contract

- **D-06:** `stream/*` returns a lazy `Enumerable` of resource structs. It must not yield tagged tuples and must not yield `%Paddle.Page{}` values. Consumers should be able to pipe it through normal `Stream` / `Enum` operations as a stream of `%Paddle.Subscription{}` or `%Paddle.Address{}` values.
- **D-07:** If a later page fetch fails during stream enumeration, the stream raises. Raise `%Paddle.Error{}` directly for normalized Paddle/transport failures. For local validation atoms such as `:invalid_params` or `:invalid_customer_id`, raise `ArgumentError` with the atom and context in the message.
- **D-08:** `all/*` returns the project's normal tagged style: `{:ok, items}` on complete success or `{:error, atom | %Paddle.Error{}}` on the first failed page. It must not return a partial list on error.
- **D-09:** On success, `all/*` and `stream/*` are equivalent: `{:ok, items} = all(...)` should produce the same item order as `stream(...) |> Enum.to_list()`.
- **D-10:** Document that stream failures can happen after earlier items have already been yielded. Callers doing side effects inside stream consumption need idempotent processing or explicit `try` / `rescue`. Document that `all/*` is convenient but can load large accounts into memory.
- **D-11:** Do not introduce `stream!/*` in Phase 9. Although bang naming is normally attractive for raising behavior, PAGE-01 explicitly calls for `stream`, and Elixir stream APIs commonly return lazy enumerables that may raise when consumed.

### Cursor replay semantics

- **D-12:** Keep `Paddle.Page.next_cursor/1` behavior unchanged. It returns Paddle's `meta.pagination.next` string when present, not just an `after` ID.
- **D-13:** Stop pagination using `page.meta["pagination"]["has_more"] == true`, not by checking whether `Paddle.Page.next_cursor(page)` is non-nil. Paddle returns `next` even when `has_more` is false, so `next_cursor != nil` is not a safe continuation condition.
- **D-14:** Treat Paddle's `meta.pagination.next` as the authoritative replay reference for subsequent pages because it contains the original query parameters plus the next `after` cursor. Do not reconstruct the next request by only merging an extracted `after` value into the caller's original params.
- **D-15:** Normalize absolute `next` URLs to `path?query` before dispatch. The client's configured Req base URL must continue to decide sandbox vs live; a returned absolute URL must not override `%Paddle.Client{}` environment/base-url behavior.
- **D-16:** Implement subsequent-page fetching through an internal callback/fetcher that can accept the normalized `path?query` and reuse the resource's page mapper. This preserves filters, sort order, future Paddle query params, and nested endpoint paths without changing public `list/*` signatures.
- **D-17:** Do not change `Paddle.Page.next_cursor/1` to return only the cursor ID. Current code and tests already treat it as a next-page URL/reference, and changing it would break the documented seam.

### Test and documentation requirements

- **D-18:** Add adapter-backed three-page tests proving each helper yields every item in order and terminates cleanly.
- **D-19:** Add equivalence tests proving `all/*` returns the same ordered items as `stream/* |> Enum.to_list()` on success.
- **D-20:** Add regression tests re-asserting `Paddle.Subscriptions.list/2` and `Paddle.Customers.Addresses.list/3` still return `{:ok, %Paddle.Page{}}`.
- **D-21:** Add failure-mode tests:
  - page-2 `%Paddle.Error{}` causes `stream/* |> Enum.to_list()` to raise and `all/*` to return `{:error, error}`;
  - validation errors from the initial list call are returned by `all/*` and raised as `ArgumentError` by `stream/*`;
  - `Enum.take(stream, 1)` does not fetch all pages.
- **D-22:** Add cursor replay tests for absolute `next` URLs, relative `next` URLs, preserved filters/query, nested customer-address paths, and `has_more: false` with a non-nil `next`.

### the agent's Discretion

- Exact internal helper shape: `Paddle.Internal.Pagination`, private resource functions, or another hidden equivalent are all acceptable if the public behavior above is locked.
- Exact exception message wording for atom validation failures.
- Whether `all/*` shares lower-level fetch functions with `stream/*` or uses a separate tagged reducer, as long as `all/*` never relies on rescuing avoidable internal exceptions for normal control flow.
- Whether to add private helpers such as `has_more?/1` or `next_page_path/1`. Do not expose them publicly in Phase 9 unless planning proves there is no cleaner internal path.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and active requirement

- `.planning/PROJECT.md` - v1.2 production-surface goal; pagination ergonomics as a target feature; pure Elixir SDK constraints; Accrue consumer framing.
- `.planning/REQUIREMENTS.md` - PAGE-01 wording and requirement that existing per-resource `list/2` shape stays locked.
- `.planning/ROADMAP.md` - Phase 9 goal and success criteria, including three-page stream fixture, `all/*` equivalence, list-shape regression, and `Paddle.Page.next_cursor/1` preservation.
- `.planning/STATE.md` - Current milestone position; Phase 09 is next after completed Phase 08.

### Prior locked decisions

- `.planning/phases/08-reliability-primitives/08-CONTEXT.md` - locked opts vocabulary, retry/error behavior, decisive-defaults preference, and current `%Paddle.Error{}` shape.
- `.planning/milestones/archived-phases/05-subscriptions-management/05-CONTEXT.md` - `Paddle.Subscriptions.list/2` shape, list filter policy, `%Paddle.Page{}` return contract, and resource-module conventions.
- `.planning/milestones/archived-phases/07-accrue-seam-lock/07-CONTEXT.md` - closed public seam, support-type policy for `%Paddle.Page{}` and `Paddle.Page.next_cursor/1`, and no undocumented public namespace creep.
- `.planning/milestones/archived-phases/01-core-transport-client-setup/01-DISCUSSION-LOG.md` - original manual cursor decision and deferred stream helper context.

### User-provided prompt context

- `prompts/paddle-elixir-lib-deep-research.md` - project vision: best idiomatic Elixir Paddle SDK, excellent DX, predictable API design, no Phoenix/Ecto coupling, pagination helpers after core surfaces.
- `prompts/oarlock-master-context.md` - core DNA: explicit client passing, typed responses, standard `{:ok, struct} | {:error, %Paddle.Error{}}`, `%Paddle.Page{}` for list endpoints.
- `prompts/oarlock-brand-book.md` - Oarlock positioning: small, provider-native, explicit, stable, developer-native; pagination helpers are part of the promised integration primitives.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` - pagination helper identified as minimum reusable SDK surface.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` - base provider client should include pagination helpers without becoming Phoenix/Ecto/app-opinionated.
- `.planning/research/JTBD-GAPS.md` - pagination ergonomics called out as low-value repetition that becomes visible in backoffice tooling.

### Existing code and docs to modify or preserve

- `lib/paddle.ex` - currently sealed root module; do not add public top-level pagination helpers in Phase 9.
- `lib/paddle/page.ex` - `%Paddle.Page{}` and `Paddle.Page.next_cursor/1`; preserve existing behavior and build on it.
- `lib/paddle/subscriptions.ex` - add `stream/2` and `all/2`; refactor or reuse current list-page mapping without changing `list/2`.
- `lib/paddle/customers/addresses.ex` - add `stream/3` and `all/3`; handle nested customer-address path replay.
- `lib/paddle/http.ex` - transport chokepoint for normalized `%Paddle.Error{}` responses; likely used by internal next-page fetches.
- `lib/paddle/client.ex` - Req base URL lives on the client; absolute `next` URLs must not bypass it.
- `lib/paddle/error.ex` - `%Paddle.Error{}` is a `defexception` and can be raised by lazy streams.
- `guides/accrue-seam.md` - update public seam docs only if Phase 9 intentionally promotes the new helpers into the documented seam; keep `Paddle.Page.next_cursor/1` wording precise.
- `guides/getting-started.md` - update pagination example to show the new per-resource helpers after implementation.
- `test/paddle/page_test.exs` - preserve current `next_cursor/1` behavior; add has-more/next footgun coverage if planner chooses to centralize it here.
- `test/paddle/subscriptions_test.exs` - add stream/all happy path, equivalence, laziness, error, and list-shape regression tests.
- `test/paddle/customers/addresses_test.exs` - same coverage for nested customer-scoped addresses.

### External references

- `https://developer.paddle.com/api-reference/about/pagination/` - Paddle pagination semantics; `next` URL contains original query parameters plus `after`; `has_more` controls continuation.
- `https://developer.paddle.com/api-reference/subscriptions/list-subscriptions/` - Paddle subscriptions list filters, `after`, `per_page`, and pagination response shape.
- `https://developer.paddle.com/api-reference/addresses/list-addresses/` - Paddle customer-address list pagination and nested endpoint shape.
- `https://developer.paddle.com/api-reference/transactions/list-transactions/` - confirms `next` URL semantics and that `next` can be present even when `has_more` is false.
- `https://hexdocs.pm/elixir/Stream.html` - Elixir streams are lazy enumerables; computation happens when consumed.
- `https://hexdocs.pm/elixir/Enumerable.html` - `Enumerable.reduce/3` continuation semantics; no native producer error channel.
- `https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2` - ecosystem precedent for a lazy `stream` API that may raise while consuming.
- `https://hexdocs.pm/elixir/URI.html` - use standard URI parsing/query utilities for next URL normalization; avoid ad hoc string slicing.
- `https://docs.stripe.com/api/pagination/auto` - successful payment SDK precedent for auto-pagination as iterator/enumerable over list calls.
- `https://github.com/stripe/stripe-node#auto-pagination` - warns that eager array helpers must be bounded to avoid runaway memory use.
- `https://github.com/stripe/stripe-go` - successful SDK precedent for client-based list iteration with errors surfaced during iteration.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Paddle.Page.next_cursor/1` already extracts Paddle's next-page reference from `meta.pagination.next`; it is the accessor Phase 9 must build on.
- `Paddle.Subscriptions.list/2` already validates params, allowlists list filters, calls `/subscriptions`, hydrates nested subscription structs, and returns `%Paddle.Page{}`.
- `Paddle.Customers.Addresses.list/3` already validates customer ID and params, calls `/customers/{id}/addresses`, hydrates addresses, and returns `%Paddle.Page{}`.
- `Paddle.Http.request/4` already normalizes non-2xx and transport failures into project-level error shapes after Phase 8.
- `%Paddle.Error{}` is an exception struct, so lazy stream failures can raise it directly without inventing a second error type.

### Established Patterns

- Public API is resource-module first: `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, `Paddle.Webhooks`.
- Public functions take `%Paddle.Client{}` explicitly and avoid global app config.
- Success values are typed structs or `%Paddle.Page{}`; errors are tagged tuples for eager calls.
- Internal modules can exist under `Paddle.Internal.*` with `@moduledoc false`; the public seam should stay closed and enumerated.
- Tests use adapter-backed `Req` clients, not live Paddle calls or external mock servers.

### Integration Points

- Add a hidden pagination engine that accepts an initial page fetch and a next-page fetcher/mapper. Resource modules should call it from their new public `stream` and `all` functions.
- Existing `list/*` functions may be refactored to share private page-fetch/build functions, but their public signatures and return values must not change.
- The next-page fetch path needs to call `Http.request/4` with a normalized relative `path?query`, then run the same mapping logic as the first page.

</code_context>

<specifics>
## Specific Ideas

- Preferred public examples:

  ```elixir
  Paddle.Subscriptions.stream(client, status: ["active"])
  |> Stream.map(& &1.id)
  |> Enum.take(100)

  {:ok, subscriptions} = Paddle.Subscriptions.all(client, status: ["active"])

  Paddle.Customers.Addresses.stream(client, "ctm_01", per_page: 100)
  |> Enum.to_list()
  ```

- Documentation should explicitly say `all/*` is for bounded result sets and scripts; `stream/*` is for backfills, exports, and early-stop workflows.
- The first implementation should keep pagination sequential. Do not prefetch pages concurrently in Phase 9; Paddle cursor order, retries, and side-effect safety matter more than speculative throughput.
- If the planner adds an internal normalizer, prefer standard `URI.parse/1` and query-preserving path reconstruction over manual string slicing.

</specifics>

<deferred>
## Deferred Ideas

- Public top-level `Paddle.stream/3` and `Paddle.all/3` - rejected for Phase 9 because the root module is sealed and callback-shaped APIs are worse DX for scoped endpoints.
- Public `Paddle.Pagination` or `%Paddle.Paginator{}` - defer unless future endpoint volume makes per-resource wrappers unmanageable.
- Public `Paddle.Page.has_more?/1` - not needed for Phase 9; use has-more internally first.
- `pages/*` helpers that stream `%Paddle.Page{}` values - maybe useful for metadata-aware exports later, but out of scope for PAGE-01's item iteration goal.
- Concurrent page prefetching, rate-limit aware backpressure controls, and custom pagination retry knobs - defer; Phase 8 retry policy is the reliability baseline.

</deferred>

---

*Phase: 09-pagination-ergonomics-0-plans*
*Context gathered: 2026-05-30*
