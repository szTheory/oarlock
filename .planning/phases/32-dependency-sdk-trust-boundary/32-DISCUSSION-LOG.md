# Phase 32: Dependency & SDK Trust Boundary - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-10
**Phase:** 32-dependency-sdk-trust-boundary
**Mode:** `--auto` — every recommended option was selected without prompting
**Areas discussed:** Req upgrade and compatibility proof, telemetry and inspection safety, retry/idempotency/ambiguity semantics, client validation and public contract truth

---

## Req upgrade and compatibility proof

### Secure dependency target

| Option | Description | Selected |
|--------|-------------|----------|
| Req 0.7.4 compatible floor | Use `~> 0.7.4`, revalidating the exact compatible patch during phase research. | ✓ |
| Minimum patched 0.6.x | Minimize version movement while clearing the known advisory floor. | |
| Latest unconstrained | Follow the newest release without a compatibility-bounded constraint. | |

**Auto-selected choice:** Req 0.7.4 compatible floor.
**Notes:** Milestone research recommends this line because it clears both known 0.5.17 advisories and provides the intended retry/auth-redaction changes.

### Migration sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Isolated dependency migration first | Review root/demo lockfile and adapter changes before SDK behavior changes. | ✓ |
| Bundle with behavior changes | Upgrade Req and change retry/telemetry in one delta. | |
| Defer dependency migration | Change SDK behavior against the old dependency first. | |

**Auto-selected choice:** Isolated dependency migration first.
**Notes:** This keeps compatibility failures attributable and preserves the roadmap's bounded-review intent.

### Acceptance proof

| Option | Description | Selected |
|--------|-------------|----------|
| Full compatibility matrix | Root/adapters, telemetry, MockServer, demo, package, optional dependency, Dialyzer/docs, and Accrue seam. | ✓ |
| Root library only | Treat root unit tests as sufficient. | |
| Audit only | Treat advisory disappearance as sufficient. | |

**Auto-selected choice:** Full compatibility matrix.
**Notes:** `mix hex.audit` proves advisory state, not runtime or downstream compatibility.

### Audit and migration record

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in audit plus migration notes | Use `mix hex.audit` and document dependency/behavior compatibility impact. | ✓ |
| Add `mix_audit` | Introduce a second dependency-audit tool. | |
| Silent bump | Change the constraint without consumer guidance. | |

**Auto-selected choice:** Built-in audit plus migration notes.
**Notes:** Publication remains Phase 34 scope.

---

## Telemetry and inspection safety

### Event topology

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve names, replace metadata | Keep start/stop/exception subscriber topology and introduce a strict allowlist. | ✓ |
| Rename every event | Make a clean break in both names and payloads. | |
| Filter full transport objects | Continue emitting Req values after attempted redaction. | |

**Auto-selected choice:** Preserve names, replace metadata.
**Notes:** This focuses migration on the unsafe part of the contract.

### Allowed metadata

| Option | Description | Selected |
|--------|-------------|----------|
| Normalized operational facts | Method, normalized route/operation, sanitized host, result/status/error class, attempt, duration. | ✓ |
| Filtered transport metadata | Headers, URLs, request/response data after sanitization. | |
| No metadata | Preserve event names but provide no operational context. | |

**Auto-selected choice:** Normalized operational facts.
**Notes:** IDs, query values, bodies, raw exceptions, signed URLs, customer data, and transport structs remain forbidden.

### Inspection coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Inventory all public secret-bearing values | Treat current structs as minimum known cases and find every equivalent public value. | ✓ |
| Patch three known structs only | Limit work to Client, NotificationSetting, and PortalSession. | |
| Patch Client only | Redact only the obvious API credential holder. | |

**Auto-selected choice:** Inventory all public secret-bearing values.
**Notes:** Promoted values and provider `raw_data` duplicate the same secrets in several shapes.

### Nested raw payloads

| Option | Description | Selected |
|--------|-------------|----------|
| Deny-by-default `raw_data` redaction | Hide the entire raw payload on secret-bearing values with a stable marker. | ✓ |
| Recursive key-name filtering | Attempt to preserve most raw payload fields. | |
| Keep raw payload visible | Favor console debugging over disclosure prevention. | |

**Auto-selected choice:** Deny-by-default `raw_data` redaction.
**Notes:** Unique canary tests must prove absence across telemetry and inspection.

---

## Retry, idempotency, and ambiguity semantics

### Automatic retry eligibility

| Option | Description | Selected |
|--------|-------------|----------|
| Safe reads only | Permit automatic replay only for GET/HEAD transient failures. | ✓ |
| All methods with a key | Treat an idempotency header as mutation replay proof. | |
| No retries | Remove automatic retries even from safe reads. | |

**Auto-selected choice:** Safe reads only.
**Notes:** Mutations default to one attempt.

### Bound and rate-limit behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Three retries plus bounded `Retry-After` | Preserve four total attempts and cap provider-directed waiting. | ✓ |
| Unbounded `Retry-After` | Sleep for any duration returned by the provider. | |
| One retry everywhere | Use one uniform replay irrespective of method/status. | |

**Auto-selected choice:** Three retries plus bounded `Retry-After`.
**Notes:** Exact attempt counts and terminal behavior require deterministic tests.

### Mutation options

| Option | Description | Selected |
|--------|-------------|----------|
| Provider-proof gate with migration | Keep idempotency options only where current Paddle guarantees prove them. | ✓ |
| Keep and disclaim | Preserve every current option but weaken the docs. | |
| Assume keys are safe | Treat header presence as provider deduplication. | |

**Auto-selected choice:** Provider-proof gate with migration.
**Notes:** Per-call options may restrict safe retries but cannot enable unsafe mutation replay. Lack of provider proof means removal.

### Ambiguous outcomes

| Option | Description | Selected |
|--------|-------------|----------|
| Typed `%Paddle.Error{}` signal | Preserve the tuple contract and add explicit reconciliation state/guidance. | ✓ |
| New exception | Raise instead of returning the normal SDK error shape. | |
| Raw transport error | Leave callers to infer ambiguity themselves. | |

**Auto-selected choice:** Typed `%Paddle.Error{}` signal.
**Notes:** Safe resource/request identifiers and lookup/webhook guidance are useful; credentials and bodies are not.

---

## Client validation and public contract truth

### Validation scope

| Option | Description | Selected |
|--------|-------------|----------|
| Stable invariants only | Validate known options, nonblank key, known environment, and absolute HTTP(S) URL. | ✓ |
| Strict key regex | Encode current Paddle credential shapes. | |
| Fail on first request | Let invalid clients construct successfully. | |

**Auto-selected choice:** Stable invariants only.
**Notes:** Keep explicit clients and avoid brittle provider-key assumptions.

### Custom base semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Infer coherent `:custom` | Preserve base-URL-only MockServer use and reject explicit environment conflicts. | ✓ |
| Require explicit `:custom` | Break existing base-URL-only construction. | |
| Accept every combination | Continue allowing misleading environment/base URL pairs. | |

**Auto-selected choice:** Infer coherent `:custom`.
**Notes:** Explicit `:custom` requires a base URL; canonical environments cannot point at conflicting noncanonical URLs.

### Invalid-input behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Redacted `ArgumentError` | Fail consistently at `new!/1` without printing secret input. | ✓ |
| Return error tuples | Add a non-bang constructor contract. | |
| Late Req errors | Defer validation to transport execution. | |

**Auto-selected choice:** Redacted `ArgumentError`.
**Notes:** This preserves bang-constructor expectations without broadening the public API.

### Contract-truth surface

| Option | Description | Selected |
|--------|-------------|----------|
| Test-backed inventory and migration guide | Align README, guides, docs/types, examples, changelog, and proof claims. | ✓ |
| README-only patch | Leave other public surfaces to drift. | |
| Code without migration notes | Change observable behavior silently. | |

**Auto-selected choice:** Test-backed inventory and migration guide.
**Notes:** Support matrices and proof classes must reflect what the repository actually tests. Publishing remains out of scope.

---

## Agent's Discretion

- Exact helper/module boundaries and telemetry metadata key names.
- Normalized route representation and error taxonomy.
- The finite `Retry-After` cap and backoff/jitter calculation.
- Concrete `%Paddle.Error{}` ambiguity/reconciliation field names.
- Test-file organization and a newer compatible Req 0.7 patch if phase research validates it.

## Deferred Ideas

- Hosted exact-SHA CI authority remains Phase 33.
- Release gating and Hex publication remain Phase 34.
- New Paddle endpoint breadth remains outside v2.2 safety work.
