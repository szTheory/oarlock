# Phase 2: Webhook Verification - Research

**Researched:** 2026-04-28
**Domain:** Paddle webhook verification and event parsing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from project docs and prior phases)

### Locked Decisions
- Keep webhook verification as pure functions in the SDK, not framework middleware.
- Verify against the raw request body exactly as received.
- Avoid Phoenix or Ecto coupling in the core library.
- Preserve the existing SDK style: explicit structs, `{:ok, value}` / `{:error, error}` boundaries, and async-safe tests.

### the agent's Discretion
- Exact public error shape for verification failures.
- Internal helper module layout under `lib/paddle/`.
- Whether parsing returns a plain `%Paddle.Event{}` or wraps `data` more deeply for future typed dispatch.

### Deferred Ideas (OUT OF SCOPE)
- Phoenix/Plug helpers for request body extraction and webhook middleware.
- Per-event typed payload structs beyond the generic event envelope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WEB-01 | Pure function signature verification (`Paddle.Webhooks.verify_signature/4`). | Implement manual verification from Paddle's `Paddle-Signature` header using raw body, `ts`, and one-or-more `h1` values. |
| WEB-02 | Support configurable timestamp tolerance (default 5s) and multiple `h1` signatures. | Default tolerance should be five seconds, reject stale/future timestamps beyond tolerance, and accept any matching `h1` during secret rotation. |
| WEB-03 | Event parsing into typed structs (`Paddle.Webhooks.parse_event/1`). | Build a generic `%Paddle.Event{}` envelope with `event_id`, `event_type`, `notification_id`, `occurred_at`, `data`, and `raw_data`. |
</phase_requirements>

## Summary

Paddle signs webhooks with the `Paddle-Signature` header. Official docs say the header includes a Unix timestamp (`ts`) and at least one `h1` signature; more than one `h1` may be present during secret rotation. Verification is computed by concatenating `ts`, a colon, and the **raw** request body, then hashing that payload with HMAC-SHA256 using the endpoint secret key. Paddle explicitly warns not to transform the body before verification, and its SDKs use a default five-second timestamp tolerance.

For this SDK, the cleanest plan is to split the phase into two implementation surfaces:
1. `Paddle.Webhooks` for header parsing, timestamp/tolerance checks, signed payload construction, HMAC generation, and timing-safe signature comparison.
2. `Paddle.Event` plus parsing helpers for decoding verified JSON payloads into a generic event envelope while preserving raw payload data for forward compatibility.

## External Source Notes

Official Paddle docs checked on 2026-04-28:
- Signature verification docs: `developer.paddle.com/webhooks/signature-verification`
- Event entity overview: `developer.paddle.com/api-reference/events/overview`
- Webhooks overview: `developer.paddle.com/webhooks/overview`

Key confirmed facts from those docs:
- The header format includes `ts=...` and one or more `h1=...` values.
- Secret rotation may produce multiple `h1` values.
- The signed payload is `"{ts}:{raw_body}"`.
- Verification uses HMAC-SHA256 with the endpoint secret key.
- Paddle recommends a default five-second tolerance.
- Webhook payloads include `event_id`, `event_type`, `occurred_at`, `notification_id`, and `data`.

## Existing Codebase Fit

### Current reusable patterns
- `Paddle.Http.build_struct/2` already establishes the SDK pattern of mapping known fields while preserving `raw_data`.
- `Paddle.Error` shows the current preference for explicit structs over opaque error tuples.
- Existing tests are focused, async-safe ExUnit modules with adapter-free unit coverage where possible.

### Gaps that planning must address
- There is currently no `Paddle.Webhooks` module.
- There is currently no `Paddle.Event` struct.
- No helper exists yet for hex decoding, secure comparison, or header parsing.
- `Paddle` top-level module is still placeholder scaffolding and does not need to be expanded for this phase unless documentation exposure becomes useful.

## Recommended Module Shape

### `lib/paddle/event.ex`
- Define `%Paddle.Event{event_id, event_type, occurred_at, notification_id, data, raw_data}`.
- Reuse the `raw_data` convention instead of introducing a new raw field name for events.

### `lib/paddle/webhooks.ex`
- `verify_signature(raw_body, signature_header, secret_key, opts \\ [])`
- `parse_event(raw_body)`
- Private helpers for:
  - parsing `Paddle-Signature`
  - normalizing and validating `ts`
  - enforcing tolerance with injectable current time for testability
  - building `"{ts}:{raw_body}"`
  - computing HMAC-SHA256 hex digest
  - timing-safe comparison against each `h1`

## Behavioral Recommendations

### Signature header parsing
- Parse the header as semicolon-separated key/value pairs.
- Support repeated `h1=` segments and collect all of them.
- Reject missing `ts`, missing `h1`, empty header, malformed key/value pairs, and non-integer timestamps.

### Timestamp handling
- Default tolerance to 5 seconds.
- Allow override via `opts[:tolerance]`.
- For deterministic tests, allow `opts[:now]` as a Unix timestamp.
- Treat timestamps older than tolerance as invalid.
- Also reject timestamps too far in the future; otherwise replay protection is asymmetric.

### Signature comparison
- Compute the expected lowercase hex digest from HMAC-SHA256.
- Compare against every provided `h1`.
- Use a constant-time comparison primitive to avoid leaking partial-match timing.
- Normalize candidate hex strings only enough to compare safely; do not silently accept malformed lengths or encodings.

### Return shape
- Prefer explicit SDK-style tuples:
  - `:ok` or `{:ok, metadata}` on verification success
  - `{:error, reason}` on failure
- If the planner keeps `verify_signature/4` as boolean-returning for API simplicity, it should still isolate internal failure reasons for tests.

### Event parsing
- Decode JSON from the raw body only after signature verification passes in application usage.
- `parse_event/1` should stay independent and just parse payload structure.
- Require the top-level keys `event_id`, `event_type`, `occurred_at`, `notification_id`, and `data`.
- Preserve the full decoded map in `raw_data`.
- Keep `data` as a map for now; typed event-specific structs belong in later phases.

## Test Strategy

### Unit tests for `verify_signature/4`
- Accepts a valid header/body/signing secret combination.
- Accepts when any one of multiple `h1` values matches.
- Rejects when no signature matches.
- Rejects when body changes even if whitespace changes only.
- Rejects stale timestamps beyond default tolerance.
- Rejects future timestamps beyond tolerance.
- Accepts custom tolerance override.
- Rejects malformed headers: missing `ts`, missing `h1`, non-numeric `ts`, empty `h1`.

### Unit tests for `parse_event/1`
- Parses a representative Paddle webhook JSON body into `%Paddle.Event{}`.
- Preserves `data` and `raw_data`.
- Returns an error for invalid JSON.
- Returns an error for structurally incomplete payloads.

### Recommended fixture approach
- Build signed payloads directly in tests with `:crypto.mac/4`.
- Keep fixtures inline or in small helpers; no HTTP adapters or network calls are needed.

## Pitfalls To Convert Into Plan Tasks

1. Using parsed JSON instead of the raw body for verification will break signatures.
2. Handling only a single `h1` will fail secret-rotation scenarios.
3. Using naive `==` string comparison is weaker than timing-safe comparison.
4. Omitting an injectable clock makes timestamp tolerance hard to test.
5. Treating all decoded event fields as optional weakens the event envelope contract.

## Planning Implications

- This phase likely needs at least one plan for the event struct/parsing surface and one for signature verification logic/tests.
- Verification logic is strong TDD material because the behavior is pure and has crisp input/output rules.
- Acceptance criteria should check exact public functions, exact struct fields, and targeted test commands rather than broad `mix test` only.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick run command | `mix test test/paddle/webhooks_test.exs test/paddle/event_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| WEB-01 | Manual signature verification | unit | `mix test test/paddle/webhooks_test.exs` |
| WEB-02 | Tolerance and multi-signature behavior | unit | `mix test test/paddle/webhooks_test.exs` |
| WEB-03 | Event envelope parsing | unit | `mix test test/paddle/event_test.exs` |
