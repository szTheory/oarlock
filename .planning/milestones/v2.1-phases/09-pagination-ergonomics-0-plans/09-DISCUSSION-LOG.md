# Phase 9: Pagination Ergonomics (0/? plans) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 09-Pagination Ergonomics (0/? plans)
**Areas discussed:** Public helper surface, Stream error contract, Cursor replay semantics

---

## Public helper surface

| Option | Description | Selected |
|--------|-------------|----------|
| Top-level helpers | `Paddle.stream(client, &Paddle.Subscriptions.list/2, params)` / `Paddle.all(...)`; one generic entry point but conflicts with sealed root module and awkward scoped endpoints. | |
| Per-resource helpers | `Paddle.Subscriptions.stream/2`, `Paddle.Subscriptions.all/2`, `Paddle.Customers.Addresses.stream/3`, `Paddle.Customers.Addresses.all/3`; colocated with existing list functions. | yes |
| Public `Paddle.Pagination` | Generic public pagination namespace backed by callbacks. Avoids root module but adds a new abstraction and callback DX burden. | |
| Page-centric helper | Start from `%Paddle.Page{}` and require caller-provided fetch callbacks. Similar to Stripe list-object shape but too much wiring for oarlock's current page struct. | |
| Paginator struct/protocol | Dedicated paginator object implementing `Enumerable`. Strong state model but too much public surface for Phase 9. | |

**User's choice:** User asked for all areas to be researched by subagents and for one cohesive recommendation set so they would not have to choose routine API shape.
**Locked recommendation:** Per-resource public helpers backed by a hidden shared pagination helper.
**Notes:** The GSD advisor role was unavailable in this Codex account due a rejected model override, so the research was rerun with inherited-model subagents. The public-helper subagent recommended per-resource helpers because `Paddle` is `@moduledoc false`, the seam guide enumerates resource modules, and colocating helpers beside `list/*` is the best DX.

---

## Stream error contract

| Option | Description | Selected |
|--------|-------------|----------|
| Raising item stream plus tagged eager `all` | `stream/*` yields resource structs and raises on later-page failure; `all/*` returns `{:ok, items}` or `{:error, reason}`. | yes |
| Tagged item stream | Stream yields `{:ok, item}` and maybe later `{:error, error}`. Avoids exceptions but breaks normal item-stream expectations. | |
| Page stream | Stream yields `%Paddle.Page{}` values and callers flatten. Preserves metadata but does not remove pagination work. | |
| Only `all` | Eager tagged helper only. Simpler errors but loses lazy/early-stop workflows and violates Phase 9 goal. | |
| `stream!` plus tagged `stream` | Bang API raises; non-bang yields tags. More semantically pure but too much public surface and contradicts PAGE-01 naming. | |

**User's choice:** User delegated the decision to research-backed synthesis.
**Locked recommendation:** `stream/*` returns a clean lazy enumerable of resource structs and raises on page-fetch errors during enumeration; `all/*` preserves the tagged tuple style.
**Notes:** Research found that Elixir streams are lazy enumerables, not error-aware result channels. Ecto, File streams, Stripe SDKs, AWS paginators, and Octokit all support the split between lazy iteration and eager collection helpers, with failures surfacing during iteration. Document partial side-effect risk for stream consumers and memory risk for `all/*`.

---

## Cursor replay semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Parse and merge only `after` | Extract `after` from `next` and re-call `list/*` with original params. Simple but can lose server-preserved filters/future params and creates encoding footguns. | |
| Call absolute `next` URL directly | Treat Paddle's `next` as authoritative. Correct query semantics but risks bypassing the client base URL/environment. | |
| Change `next_cursor/1` to cursor ID | Make the helper return only an ID. Breaks current code/tests and loses filters. | |
| Internal next-URL callback | Resource modules reuse a hidden fetcher that accepts normalized `path?query` and maps pages. | yes |
| Recommended hybrid | Read `Page.next_cursor/1`, continue only if `has_more == true`, canonicalize the next URL to `path?query`, then fetch/map through hidden resource-aware code. | yes |

**User's choice:** User delegated the decision to research-backed synthesis.
**Locked recommendation:** Use Paddle's `meta.pagination.next` as the authoritative replay reference, but normalize absolute URLs to relative `path?query` so the `%Paddle.Client{}` base URL remains authoritative.
**Notes:** Paddle returns `next` even when `has_more` is false, so pagination must stop on `has_more`, not `next_cursor != nil`. Do not change `Paddle.Page.next_cursor/1`; preserve it as the documented next-reference accessor.

---

## the agent's Discretion

- Exact hidden pagination helper structure and private function names.
- Exact exception message wording for validation atoms raised by `stream/*`.
- Whether `all/*` shares lower-level fetch functions with `stream/*` or uses a separate tagged reducer.
- Exact test fixture organization as long as the context's behavior and regression coverage are satisfied.

## Deferred Ideas

- Public top-level `Paddle.stream/3` / `Paddle.all/3`.
- Public `Paddle.Pagination` or `%Paddle.Paginator{}`.
- Public `Paddle.Page.has_more?/1`.
- `pages/*` helpers that stream `%Paddle.Page{}` values.
- Concurrent page prefetch, pagination-specific retry knobs, and custom backpressure controls.
