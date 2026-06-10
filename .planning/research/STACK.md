# Stack Research

**Domain:** Elixir SDK for Paddle Billing (Catalog & Events)
**Researched:** 2026-06-09 (Current Milestone)
**Confidence:** HIGH

## Recommended Stack

No new dependencies are required for the v1.4 Catalog & Events milestone. The existing core stack is 100% sufficient for the required features.

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Req** | `~> 0.5.17` | HTTP Transport & JSON Parsing | Built-in JSON decoding (`jason`), retry mechanisms, and telemetry. Perfectly handles standard REST endpoints for Products, Prices, and Events. |
| **Elixir** | `~> 1.19` | Language & Types | Built-in `Stream` for auto-pagination. Standard `String.t()` for raw dates (to avoid timezone coupling). |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Telemetry** | `~> 1.4` | Observability | Already integrated via `Req`. Use to emit events when Catalog queries or Event history fetches complete. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Dialyxir** | Static typing | Ensures the new struct definitions for `Paddle.Products` and `Paddle.Prices` are perfectly typed. |
| **ExDoc** | Documentation | Used to expose the new read-only surface and Accrue seam guides. |

## Installation

No changes to `mix.exs` needed.

```bash
# Existing dependencies remain unchanged
# {:req, "~> 0.5.17"}
# {:telemetry, "~> 1.4"}
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **Standard Req GET** | Server-Sent Events / WebSockets | Only if Paddle offered an event streaming API, but Paddle Billing v1 Events (`/events`) is a standard paginated JSON REST endpoint. |
| **Pure Structs** | Ecto Schemas | Only if we were building a full framework-coupled application. Since this is a pure SDK consumed by Accrue, Ecto must be avoided. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Cachex / Nebulex** | The SDK must remain a pure transport layer. Caching catalog data (which rarely changes) is the responsibility of the consumer application (e.g., Accrue). Adding caching to the SDK introduces hidden state and memory overhead. | Let consumers implement their own caching on top of `Paddle.Products.list/2`. |
| **Ecto** | Violates the explicit constraint: "No Phoenix or Ecto coupling." The SDK must not manage database persistence. | Pure Elixir structs (`%Paddle.Product{}`, `%Paddle.Price{}`) with a `:raw_data` escape hatch. |
| **NimbleCSV** | Paddle's catalog does not rely on CSV exports. The v1 API uses standard JSON objects for Products and Prices. | Built-in Jason decoding provided by `Req`. |

## Stack Patterns by Variant

**If adding query parameters (e.g., `include=product` on Prices):**
- Use `Req`'s `params:` keyword list in the request options.
- Because `Req` safely encodes URLs and integrates natively with the existing `Paddle.Client`.

**If handling pagination for Events:**
- Use the existing `Paddle.Page.next_cursor/1` and `stream/*` helpers.
- Because Paddle's `/events` endpoint uses the exact same cursor-based pagination as Customers and Transactions.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `oarlock` | Paddle API v1 | Must strictly adhere to the v1 Catalog model (Products and Prices). Do not introduce legacy "Paddle Classic" concepts. |

## Sources

- `.planning/PROJECT.md` — Verified constraint: pure functional library without UI, database, or Phoenix/Ecto coupling.
- [Paddle API Docs (Products/Prices)](https://developer.paddle.com/api-reference/products/list-products) — Verified that Catalog API is pure REST/JSON and requires no special handling.
- [Paddle API Docs (Events)](https://developer.paddle.com/api-reference/events/list-events) — Verified that Events API is standard cursor-paginated REST, not SSE or WebSockets.

---
*Stack research for: Catalog & Events (v1.4)*
*Researched: 2026-06-09*
