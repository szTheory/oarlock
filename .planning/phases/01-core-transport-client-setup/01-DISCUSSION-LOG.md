# Phase 1: Core Transport & Client Setup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 1-Core Transport & Client Setup
**Areas discussed:** Client Initialization, Error Struct Shape, Pagination Interface, Telemetry & Logging

---

## Client Initialization

| Option | Description | Selected |
|--------|-------------|----------|
| Strict Explicit Passing | `Paddle.Client.new(api_key: "...")` only. No `Application.get_env`. | ✓ |
| Global Fallbacks | Allow `Application.get_env` fallbacks if explicit keys are missing. | |

**User's choice:** Strict Explicit Passing
**Notes:** Decided via deep research by subagents. Explicit passing guarantees multi-tenancy, avoids global state toxicity, and enables `async: true` testing.

---

## Error Struct Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Exact Mirror | Map exactly to Paddle JSON (`%{type, code, detail, meta: %{request_id}}`). | |
| Ecto-Style | Map to Ecto-like keyword lists (`[customer_id: ["is required"]]`). | |
| Hybrid Idiomatic Wrapper | Keep Paddle terminology but extract `request_id` and `status_code` to top level. | ✓ |

**User's choice:** Hybrid Idiomatic Wrapper
**Notes:** Decided via deep research by subagents. Retains 1:1 parity with docs while offering excellent DX for logging and pattern matching. Includes `Exception` behavior.

---

## Pagination Interface

| Option | Description | Selected |
|--------|-------------|----------|
| Manual `next()` Cursor | Return `{:ok, %Paddle.Page{}}` with a `next_cursor/1` helper. | ✓ |
| Elixir Streams | Provide `Stream` wrappers for automatic lazy evaluation. | |

**User's choice:** Manual `next()` Cursor
**Notes:** Decided via deep research by subagents. Establishes a rock-solid HTTP primitive without the hidden complexity of lazy Streams. Stream support deferred to Phase 2.

---

## Telemetry & Logging

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in `req` Telemetry | Rely on `[:req, :request, ...]`. | |
| Custom Domain Telemetry | Emit custom `[:paddle, :request, ...]` events using a `Req.Step`. | ✓ |

**User's choice:** Custom Domain Telemetry
**Notes:** Decided via deep research by subagents. Provides targeted observability without forcing users to filter global HTTP traffic.

---

## Claude's Discretion

- Internal module structure (e.g., `Paddle.Request`).
- Telemetry payload struct details.

## Deferred Ideas

- Elixir Stream wrapper for pagination (`Paddle.stream!/1`).
- Phoenix/Plug integration helpers.