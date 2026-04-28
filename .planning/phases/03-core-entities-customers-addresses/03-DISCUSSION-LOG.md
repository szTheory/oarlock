# Phase 3: Core Entities (Customers & Addresses) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 03-core-entities-customers-addresses
**Areas discussed:** Public API shape, Customer struct surface, Address flow and scoping, Request ergonomics

---

## Public API Shape

| Option | Description | Selected |
|--------|-------------|----------|
| `Paddle.Customers.*` + `Paddle.Addresses.*` | Resource modules, but addresses remain top-level despite customer ownership | |
| `Paddle.Customers.*` + `Paddle.Customers.Addresses.*` | Resource modules with nested customer-owned address namespace | ✓ |
| Flat `Paddle.*` facade | Single kitchen-sink public module with domain functions | |
| Generated endpoint-style API | OpenAPI/operation-shaped public surface | |

**User's choice:** One-shot researched recommendation accepted.
**Notes:** Selected the nested resource-module shape because it best matches Paddle's ownership model, scales cleanly to future subresources, and minimizes surprise.

---

## Customer Struct Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Common typed fields + `raw_data` | Promote high-value fields to struct keys and preserve full payload | ✓ |
| Thin raw wrapper | Mostly opaque map with minimal struct surface | |
| Aggressively typed full schema | Broad field/nested modeling across the entire API shape | |

**User's choice:** One-shot researched recommendation accepted.
**Notes:** `%Paddle.Customer{}` and `%Paddle.Address{}` should both follow the same pattern: common top-level fields, `raw_data`, selective nested modeling only when worth the maintenance.

---

## Address Flow and Scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit customer-scoped address APIs | Customer ID is a required path argument for list/create/get/update | ✓ |
| Flat address APIs with `customer_id` filter/payload | Address operations look top-level and customer scope is embedded | |
| Dual public APIs | Expose both nested and flat shapes | |

**User's choice:** One-shot researched recommendation accepted.
**Notes:** Keep list semantics honest: address pagination is always "for this customer," not a global address listing.

---

## Request Ergonomics

| Option | Description | Selected |
|--------|-------------|----------|
| Plain maps/keywords + light normalization | Thin request layer, minimal local validation, close to remote API | ✓ |
| Typed request builders | Separate input structs/builders for request payloads | |
| Heavy local validation/coercion | SDK owns substantial business-rule validation | |

**User's choice:** One-shot researched recommendation accepted.
**Notes:** Preserve PATCH semantics, keep attrs in snake_case, avoid builder DSLs and hidden coercions.

---

## the agent's Discretion

- Exact first-pass field inventory for `%Paddle.Customer{}` and `%Paddle.Address{}`.
- Whether `import_meta` starts as a map or a tiny nested struct.
- Internal helper layout for attr normalization and list/struct mapping.

## Deferred Ideas

None.
