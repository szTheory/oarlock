# Phase 14: Customer Portal Sessions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-09
**Phase:** 14-Customer Portal Sessions
**Areas discussed:** Module Namespace, Function Signature, Validation Strictness, Struct Design for URLs, API Surface Scope

---

## Module Namespace

| Option | Description | Selected |
|--------|-------------|----------|
| Paddle.Customers.PortalSessions | Nested hierarchy (e.g. following Addresses) | ✓ |
| Paddle.PortalSessions | Flattened hierarchy | |

**User's choice:** Paddle.Customers.PortalSessions
**Notes:** Chosen to match the `POST /customers/{customer_id}/portal-sessions` REST route and established precedent in `Paddle.Customers.Addresses`.

---

## Function Signature

| Option | Description | Selected |
|--------|-------------|----------|
| create(client, customer_id, attrs) | Explicit customer_id param | ✓ |
| create(client, attrs) | Passing inside attrs | |

**User's choice:** `create(client, customer_id, attrs)`
**Notes:** Maps positional parameters directly to URL path parameters.

---

## Validation Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| API Rejection | Let the Paddle API reject bad payloads | ✓ |
| Local Validation | Catch errors locally | |

**User's choice:** Let the Paddle API reject bad payloads
**Notes:** The SDK should remain a thin layer. We will rely on Typespecs and guard clauses locally and normalize `400 Bad Request` errors.

---

## Struct Design for URLs

| Option | Description | Selected |
|--------|-------------|----------|
| Flat map() field | Store exact JSON shape in a map | ✓ |
| Nested Struct | e.g. Paddle.PortalSession.Urls | |

**User's choice:** Flat `urls` map in the `Paddle.PortalSession` struct (`urls: map()`).
**Notes:** Avoids struct bloat for a single deeply nested key while maintaining 100% forward compatibility.

---

## API Surface Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Limit to create/3 | Only expose create/3 | ✓ |
| Include stubs | Stub get, list, update, etc. | |

**User's choice:** Strictly limit the module to `create/3`.
**Notes:** Paddle API v1 only allows generating a portal session, no retrieval or mutation endpoints exist.

---

## Claude's Discretion

None

## Deferred Ideas

None