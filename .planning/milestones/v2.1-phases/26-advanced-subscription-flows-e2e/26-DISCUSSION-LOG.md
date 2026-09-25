# Phase 26: Advanced Subscription Flows E2E - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 26-Advanced Subscription Flows E2E
**Areas discussed:** Test Environment, SDK Surface Expansion, Downgrade Behavior

---

## Test Environment

| Option | Description | Selected |
|--------|-------------|----------|
| Real Sandbox | Point E2E tests at the real Paddle Sandbox | |
| MockServer | Point E2E tests at `Paddle.MockServer` with stubbed payloads | ✓ |

**User's choice:** Delegate to Claude for a cohesive recommendation ("one-shot a perfect set of recommendations").
**Notes:** Chosen MockServer as the default for fast, offline testing (idiomatic Elixir), but tests should be structured to optionally run against the real sandbox.

---

## SDK Surface Expansion

| Option | Description | Selected |
|--------|-------------|----------|
| `Subscriptions.update/3` | Pure REST CRUD implementation | ✓ |
| Domain Helpers | `upgrade/2`, `downgrade/2` custom functions | |

**User's choice:** Delegate to Claude.
**Notes:** Chosen pure CRUD `Subscriptions.update/3` to maintain pure library boundaries without Accrue domain logic leakage.

---

## Downgrade Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate | Immediate upgrade/downgrade | |
| Scheduled | Scheduled downgrade verifying `scheduled_change` struct | ✓ |

**User's choice:** Delegate to Claude.
**Notes:** Decided to verify both an immediate upgrade and a scheduled downgrade. Scheduled downgrade is critical to verify the SDK correctly deserializes the nested `scheduled_change` struct.

---

## Claude's Discretion

- Test Environment (hybrid approach chosen)
- SDK Surface Expansion (pure CRUD chosen)
- Downgrade Behavior (both immediate and scheduled chosen)
- The specific test file layout and descriptor naming
- How to structure the `@moduledoc` on `Paddle.Subscriptions.update/3`
- The exact mock payload structures required to simulate the upgrade/downgrade responses

## Deferred Ideas

None
