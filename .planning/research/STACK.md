# Stack Research

**Domain:** Customer Portal Sessions and Adjustments (Elixir SDK)
**Researched:** 2026-06-09
**Confidence:** HIGH

## Recommended Stack

No new stack additions are required. The new Customer Portal Sessions and Adjustments features utilize standard JSON over HTTP REST endpoints and fit perfectly into the project's existing architecture.

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir | ~> 1.19 | Core language | Existing project requirement. |
| `req` | ~> 0.5.17 | HTTP Client | Zero-dependency HTTP client with built-in JSON parsing, retries, and telemetry. Fully sufficient for interacting with the new Paddle API endpoints. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| *None* | N/A | No new libraries needed | The new features rely entirely on existing standard JSON REST endpoints (`POST /adjustments`, `POST /customers/{id}/portal-sessions`). The current HTTP and struct validation stack is fully capable of handling these payloads. |

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `dialyxir` | Static typing | Ensures the new structs (`%Paddle.Adjustment{}`, `%Paddle.Customer.PortalSession{}`) have valid typespecs, maintaining the strong typing guarantees of the SDK. |

## Installation

```bash
# Core
# No new dependencies needed, utilize existing mix.exs dependencies:
# {:req, "~> 0.5.17"}
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Plain Elixir Structs | `Ecto.Changeset` / Data validation libraries | Using `Ecto` could provide robust validation for adjustment reasons and partial item amounts. However, `oarlock` specifically avoids `ecto` coupling to remain pure and framework-agnostic. We will continue using explicitly mapped typed structs (e.g. `%Paddle.Adjustment{}`). |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Phoenix Framework | The SDK should remain a pure HTTP client. Coupling UI or frontend session redirection into the core library limits portability. | Native Elixir modules returning `{:ok, struct}` containing the URL strings (e.g. `urls.general.overview`) for the consuming client application to handle and redirect appropriately. |
| Ecto / Database state | The SDK should not attempt to manage state, track local adjustment totals, or sync refund status to a database. | Stateless API calls. The consumer app (like Accrue) will handle local persistence and business logic on top of the raw data. |

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `req` | Built-in JSON parser | Ensure `req` is correctly returning the deeply nested JSON map structures for `urls` in Customer Portal sessions. |

## Sources

- `ctx7 docs "/websites/developer_paddle"` — Verified `POST /customers/{customer_id}/portal-sessions` requires only standard JSON requests and returns a structured URL object. (Confidence: HIGH)
- `ctx7 docs "/websites/developer_paddle"` — Verified `POST /adjustments` and its associated list/get endpoints are standard JSON HTTP interfaces (handling `action: "refund" | "credit"` and an `items` array). (Confidence: HIGH)
- `.planning/PROJECT.md` — Verified constraint: "No framework or database integration code in the core library." (Confidence: HIGH)

---
*Stack research for: Customer Portal Sessions and Adjustments*
*Researched: 2026-06-09*
