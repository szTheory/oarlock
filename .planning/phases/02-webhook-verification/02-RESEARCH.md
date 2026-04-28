# Phase 2: Webhook Verification - Research

**Researched:** 2026-04-28
**Domain:** Paddle webhook signature verification and event envelope parsing
**Confidence:** HIGH

## User Constraints

No phase `CONTEXT.md` exists for Phase 2. The planner should treat the following project documents as the active constraint source: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and Phase 1 research/summaries. [VERIFIED: local codebase grep]

- Build pure library functions only; do not add Phoenix, Plug parser integrations, or database coupling in the core SDK. [VERIFIED: .planning/PROJECT.md]
- Implement `Paddle.Webhooks.verify_signature/4` and `Paddle.Webhooks.parse_event/1` for strict raw-body webhook handling. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Match Phase 2 scope to `WEB-01`, `WEB-02`, and `WEB-03` only. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Preserve the Phase 1 project patterns: explicit tuple-style outcomes, raw payload retention, and reuse of established helper modules where they fit. [VERIFIED: .planning/phases/01-core-transport-client-setup/01-RESEARCH.md] [VERIFIED: .planning/phases/01-core-transport-client-setup/01-03-SUMMARY.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WEB-01 | Pure function signature verification (`Paddle.Webhooks.verify_signature/4`). [VERIFIED: .planning/REQUIREMENTS.md] | Use a raw-body verifier that parses `Paddle-Signature`, computes HMAC over `"{ts}:{raw_body}"`, and returns deterministic success/failure tuples without requiring `%Paddle.Client{}`. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/PaddleSignature.py] |
| WEB-02 | Support configurable timestamp tolerance (default 5s) and multiple `h1` signatures. [VERIFIED: .planning/REQUIREMENTS.md] | Collect all `h1` values from the header, default tolerance to `5`, and test replay-window failures explicitly. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/Verifier.py] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-php-sdk/main/src/Notifications/PaddleSignature.php] |
| WEB-03 | Event parsing into typed structs (`Paddle.Webhooks.parse_event/1`). [VERIFIED: .planning/REQUIREMENTS.md] | Decode verified JSON into a generic `%Paddle.Event{}` envelope first, preserving `raw_data` and leaving event-specific typed notification structs for a later phase. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/example_webhook_unmarshal_test.go] [VERIFIED: .planning/phases/01-core-transport-client-setup/01-03-SUMMARY.md] |
</phase_requirements>

## Summary

Paddle webhook verification is a pure cryptographic boundary, not an HTTP client concern. The implementation should live in a dedicated `Paddle.Webhooks` module with no dependency on `%Paddle.Client{}` and no framework integrations. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: .planning/PROJECT.md]

The decisive implementation detail is raw-body exactness: Paddle signs the literal request bytes prefixed with the Unix timestamp as `"{ts}:{raw_body}"`. Re-encoding JSON, trimming whitespace, or verifying a decoded map instead of the original body will produce false negatives. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts]

Paddle’s own SDK ecosystem is inconsistent at the edges. The Python and PHP SDKs both iterate all `h1` signatures and default timestamp variance to `5` seconds, while the current Go and Node helpers simplify parts of the header handling. Because this phase explicitly requires multiple `h1` support, the plan should follow Paddle’s webhook spec and the stricter multi-signature SDK implementations rather than the simplified helpers. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/PaddleSignature.py] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-php-sdk/main/src/Notifications/PaddleSignature.php] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/webhook_verifier.go] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/notifications/helpers/webhooks-validator.ts]

**Primary recommendation:** Implement `Paddle.Webhooks.verify_signature/4` as a pure `:ok | {:error, reason}` verifier over `(raw_body, signature_header, secret_key, opts)`, back it with `:crypto.mac/4` plus constant-time comparison, and implement `parse_event/1` as a separate `Jason.decode/1` + `%Paddle.Event{}` envelope builder that preserves `raw_data`. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] [VERIFIED: https://hexdocs.pm/jason/Jason.html] [VERIFIED: .planning/phases/01-core-transport-client-setup/01-03-SUMMARY.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Parse `Paddle-Signature` header | API / Backend | — | Verification happens on the server where the webhook request is received. [CITED: https://developer.paddle.com/webhooks/signature-verification] |
| Compute and compare HMAC | API / Backend | — | The secret key must stay server-side, and the comparison is a backend cryptographic concern. [CITED: https://developer.paddle.com/webhooks/signature-verification] |
| Enforce timestamp tolerance | API / Backend | — | Replay protection depends on server time and request admission policy. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/Verifier.py] |
| Parse webhook JSON into `%Paddle.Event{}` | API / Backend | — | The event envelope is backend domain data derived from the verified body. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/example_webhook_unmarshal_test.go] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` (OTP) | `28` in the local environment. [VERIFIED: `elixir -e 'IO.puts(System.otp_release())'`] | HMAC-SHA256 and constant-time binary comparison. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] | Use the Erlang standard library instead of adding Plug or custom crypto helpers. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] |
| `jason` | `1.4.4` stable, published `2024-07-26T17:51:45.963093Z`. [VERIFIED: npm registry] | Decode raw webhook JSON for `%Paddle.Event{}` parsing. [VERIFIED: https://hexdocs.pm/jason/Jason.html] | The project should depend on `Jason` directly instead of relying on Req’s transitive decoder. [ASSUMED] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `req` | `0.5.17`, published `2026-01-05T21:11:49.802995Z`. [VERIFIED: npm registry] | Existing project dependency and pattern source. [VERIFIED: mix.exs] | Reuse only its project conventions here; Phase 2 should not make HTTP requests. [VERIFIED: .planning/PROJECT.md] |
| `telemetry` | `1.4.1`, published `2026-03-09T09:46:08.718347Z`. [VERIFIED: npm registry] | Existing project dependency. [VERIFIED: mix.exs] | No new telemetry is required for pure webhook verification in this phase. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:crypto.hash_equals/2` | `Plug.Crypto.secure_compare/2` | Adding Plug would violate the project’s no-framework-coupling direction for the core SDK. [VERIFIED: .planning/PROJECT.md] [VERIFIED: https://hexdocs.pm/plug_crypto/Plug.Crypto.html] |
| `Jason.decode/1` | manual JSON parsing | Hand-rolled JSON parsing would add failure modes for no gain. [VERIFIED: https://hexdocs.pm/jason/Jason.html] |

**Installation:**
```bash
mix deps.get
```

If `Jason` is added as a direct dependency, use: [ASSUMED]
```bash
mix hex.info jason
```

## Architecture Patterns

### System Architecture Diagram

```text
[Incoming HTTP webhook request]
          |
          v
[Framework layer captures raw body bytes]
          |
          v
[Paddle.Webhooks.verify_signature/4]
  - parse ts and all h1 values
  - enforce tolerance against now
  - HMAC "{ts}:{raw_body}" with secret
  - constant-time compare against any h1
          |
          +---- invalid ----> {:error, reason}
          |
          v
[Paddle.Webhooks.parse_event/1]
  - Jason.decode/1
  - validate required top-level keys
  - build %Paddle.Event{raw_data: ...}
          |
          v
[Consumer app handles verified event]
```

### Recommended Project Structure

```text
lib/paddle/
├── event.ex          # Generic webhook envelope struct
├── webhooks.ex       # Pure signature verification + event parsing
├── error.ex          # Existing API error type; do not overload for local webhook failures
└── http.ex           # Existing raw_data struct builder reusable by parse_event/1

test/paddle/
├── event_test.exs
└── webhooks_test.exs
```

### Pattern 1: Keep Verification and Parsing Separate

**What:** Verify raw bytes first, then parse JSON second. [CITED: https://developer.paddle.com/webhooks/signature-verification]

**When to use:** Always for webhook handling, including test fixtures. [CITED: https://developer.paddle.com/webhooks/signature-verification]

**Example:**
```elixir
# Source: Paddle spec + Erlang crypto docs
def verify_signature(raw_body, signature_header, secret_key, opts \\ []) when is_binary(raw_body) do
  tolerance = Keyword.get(opts, :tolerance, 5)
  now = Keyword.get(opts, :now, System.system_time(:second))

  with {:ok, %{timestamp: ts, signatures: signatures}} <- parse_signature_header(signature_header),
       :ok <- validate_timestamp(ts, now, tolerance),
       expected <- :crypto.mac(:hmac, :sha256, secret_key, "#{ts}:#{raw_body}"),
       true <- Enum.any?(signatures, &secure_hex_compare(&1, expected)) do
    :ok
  else
    false -> {:error, :invalid_signature}
    {:error, _} = error -> error
  end
end
```

### Pattern 2: Reuse `Paddle.Http.build_struct/2` for the Event Envelope

**What:** The current codebase already has a struct builder that maps known string keys and preserves `raw_data`. [VERIFIED: lib/paddle/http.ex]

**When to use:** For `%Paddle.Event{}` only; do not use it for signature header parsing. [VERIFIED: lib/paddle/http.ex]

**Example:**
```elixir
# Source: local Paddle.Http pattern
def parse_event(raw_body) when is_binary(raw_body) do
  with {:ok, data} <- Jason.decode(raw_body),
       :ok <- validate_event_envelope(data) do
    {:ok, Paddle.Http.build_struct(Paddle.Event, data)}
  else
    {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
    {:error, _} = error -> error
  end
end
```

### Anti-Patterns to Avoid

- **Verifying decoded JSON instead of the raw body:** This breaks signature validation when whitespace or key ordering changes. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts]
- **Using `%Paddle.Client{}` or `Paddle.Http.request/4` in verification:** Webhook verification is local computation and does not call Paddle’s API. [VERIFIED: .planning/PROJECT.md]
- **Overloading `%Paddle.Error{}` for verification failures:** `%Paddle.Error{}` is shaped around Paddle API response bodies, not local crypto or JSON validation errors. [VERIFIED: lib/paddle/error.ex]
- **Typing nested event `data` into dozens of structs in Phase 2:** The roadmap only requires a generic `%Paddle.Event{}` envelope now. [VERIFIED: .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HMAC-SHA256 | custom hashing code | `:crypto.mac/4` | The runtime already ships the correct primitive. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] |
| Constant-time comparison | `==` on hex strings | `:crypto.hash_equals/2` on decoded binaries | String equality leaks timing and length behavior. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] |
| JSON decoding | custom parser | `Jason.decode/1` | Jason already returns structured errors and is standard in Elixir JSON workflows. [VERIFIED: https://hexdocs.pm/jason/Jason.html] |
| Event envelope field mapping | ad hoc per-field copying | `Paddle.Http.build_struct/2` | The helper already preserves `raw_data` and matches the project’s forward-compatibility pattern. [VERIFIED: lib/paddle/http.ex] [VERIFIED: .planning/phases/01-core-transport-client-setup/01-03-SUMMARY.md] |

**Key insight:** The risky parts of this phase are raw-body capture, header parsing, and replay protection. The plan should spend its complexity budget there, not on transport reuse or premature event-type expansion. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: .planning/ROADMAP.md]

## Common Pitfalls

### Pitfall 1: The request body gets transformed before verification

**What goes wrong:** Signature verification fails for legitimate requests. [CITED: https://developer.paddle.com/webhooks/signature-verification]

**Why it happens:** Frameworks often decode JSON before user code sees the body, and re-encoding changes whitespace or key order. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts]

**How to avoid:** Make raw-body capture a documented integration requirement and test verification with literal string fixtures, not maps. [CITED: https://developer.paddle.com/webhooks/signature-verification]

**Warning signs:** A fixture passes before parsing but fails after `Jason.encode!/1` round-trips it. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts]

### Pitfall 2: Only one `h1` value is considered

**What goes wrong:** Signature rotation scenarios can fail even when one provided signature is valid. [CITED: https://developer.paddle.com/webhooks/signature-verification]

**Why it happens:** Some SDK helpers flatten the header instead of collecting every `h1` value. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/notifications/helpers/webhooks-validator.ts] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/webhook_verifier.go]

**How to avoid:** Parse the header into `timestamp` plus `signatures :: [binary]`, then accept if any signature matches. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/PaddleSignature.py] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-php-sdk/main/src/Notifications/PaddleSignature.php]

**Warning signs:** Tests cover duplicate `h1` values but never cover mixed valid/invalid `h1` sets. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts]

### Pitfall 3: Timestamp checks are not testable or are underspecified

**What goes wrong:** Replay-protection logic becomes flaky in tests or silently diverges from the intended 5-second window. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/Verifier.py]

**Why it happens:** Time is read directly from the system clock with no seam for tests. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/Verifier.py]

**How to avoid:** Accept `now:` in the options for deterministic tests and default to `System.system_time(:second)` only at the public boundary. [ASSUMED]

**Warning signs:** Tests require sleeps, monkeypatching, or broad time windows to pass. [ASSUMED]

### Pitfall 4: `%Paddle.Event{}` tries to be an exhaustive typed event model too early

**What goes wrong:** Phase 2 expands into dozens of event-specific modules and stalls. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/pkg/paddlenotification/shared.go]

**Why it happens:** Paddle has a large event surface, and their SDKs generate many event-specific types. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/notifications/helpers/types.ts] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/pkg/paddlenotification/shared.go]

**How to avoid:** Keep `%Paddle.Event{}` generic with `data :: map()` plus `raw_data`, and defer typed event modules to a later phase if they become necessary. [VERIFIED: .planning/ROADMAP.md]

**Warning signs:** New plan tasks start enumerating all Paddle event kinds. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/notifications/helpers/types.ts]

## Code Examples

Verified patterns from official sources:

### Parse all `h1` values from the signature header
```elixir
# Source: Paddle webhook spec, Python SDK, PHP SDK
defp parse_signature_header(header) when is_binary(header) do
  parts =
    header
    |> String.split(";")
    |> Enum.map(&String.split(&1, "=", parts: 2))

  timestamp =
    Enum.find_value(parts, fn
      ["ts", value] -> Integer.parse(value)
      _ -> nil
    end)

  signatures =
    for ["h1", value] <- parts, value != "", do: value

  case timestamp do
    {ts, ""} when signatures != [] -> {:ok, %{timestamp: ts, signatures: signatures}}
    _ -> {:error, :invalid_signature_header}
  end
end
```

### Build the HMAC over `"{ts}:{raw_body}"`
```elixir
# Source: Paddle docs and official SDK implementations
payload = "#{timestamp}:#{raw_body}"
digest = :crypto.mac(:hmac, :sha256, secret_key, payload)
```

### Parse a generic event envelope first
```elixir
# Source: Paddle Go SDK webhook unmarshal example
defmodule Paddle.Event do
  defstruct [:event_id, :event_type, :occurred_at, :notification_id, :data, :raw_data]
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Verify decoded JSON or middleware-normalized bodies | Verify the exact raw request bytes | Current Paddle webhook guidance. [CITED: https://developer.paddle.com/webhooks/signature-verification] | Raw-body capture must be a documented integration requirement. [CITED: https://developer.paddle.com/webhooks/signature-verification] |
| Framework crypto helpers in the core library | OTP `:crypto` primitives in a pure SDK | Current project direction plus OTP availability. [VERIFIED: .planning/PROJECT.md] [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] | No new Plug/Phoenix dependency is needed. [VERIFIED: .planning/PROJECT.md] |
| Full event-type expansion up front | Generic event envelope first | Paddle’s own examples initially unmarshal only a small envelope before branching. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/example_webhook_unmarshal_test.go] | Phase 2 can stay small and implementation-ready. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**

- Verifying a reconstructed JSON body is outdated for Paddle webhooks because signature validity depends on the exact original bytes. [CITED: https://developer.paddle.com/webhooks/signature-verification]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Jason` should be added as a direct dependency even if Req already pulls it transitively. | Standard Stack | Low. The implementation still works if the project intentionally relies on Req’s transitive dependency, but direct declaration is the safer packaging choice. |
| A2 | Pure-function ergonomics are best served by a `now:` option for tests rather than clock mocking. | Common Pitfalls | Low. Tests can still be written another way, but this is the cleanest plan shape for deterministic verification. |
| A3 | No new telemetry should be added in Phase 2 because the functions are local and side-effect-light. | Standard Stack | Low. If the team wants instrumentation later, it can be added without changing the verification core. |

## Open Questions

1. **Should unknown key/value pairs in `Paddle-Signature` be rejected or ignored?**
   - What we know: Python and PHP reject unknown keys, Node ignores at least some extras, and the phase requirements only require `ts` plus multiple `h1` support. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/PaddleSignature.py] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-php-sdk/main/src/Notifications/PaddleSignature.php] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/notifications/helpers/webhooks-validator.ts]
   - What's unclear: Paddle’s public spec page does not explicitly state the required behavior for unrelated header parts. [CITED: https://developer.paddle.com/webhooks/signature-verification]
   - Recommendation: Choose fail-closed on malformed `ts` or missing `h1`, but treat unknown extra keys as an explicit implementation decision in the plan so tests lock the behavior. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | SDK implementation and tests | ✓ | `1.19.5` [VERIFIED: local shell] | — |
| `mix` | Dependency and test workflow | ✓ | `1.19.5` [VERIFIED: local shell] | — |
| OTP `:crypto` | HMAC and constant-time compare | ✓ | `28` [VERIFIED: `elixir -e 'IO.puts(System.otp_release())'`] | — |

**Missing dependencies with no fallback:**

- None. [VERIFIED: local shell]

**Missing dependencies with fallback:**

- None. [VERIFIED: local shell]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Webhook verification is message authenticity, not user auth. [CITED: https://developer.paddle.com/webhooks/signature-verification] |
| V3 Session Management | no | No session state is introduced in this phase. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | no | The module validates webhook authenticity but does not grant user/resource access. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Validate header shape, timestamp parseability, required event envelope keys, and JSON decode outcomes. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://hexdocs.pm/jason/Jason.html] |
| V6 Cryptography | yes | Use `:crypto.mac/4` and `:crypto.hash_equals/2`; never hand-roll comparison logic. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replay attack via stale webhook | Replay / Spoofing | Enforce default 5-second tolerance and test out-of-window rejection. [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/Verifier.py] |
| Raw-body transformation before verification | Tampering | Verify the original bytes before any JSON decode or normalization. [CITED: https://developer.paddle.com/webhooks/signature-verification] |
| Timing leak in signature comparison | Information Disclosure | Compare decoded digests with a constant-time primitive. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] |
| Malformed JSON after successful signature verification | Denial of Service | Keep parsing separate and return a structured parse error without crashing. [VERIFIED: https://hexdocs.pm/jason/Jason.html] |

## Sources

### Primary (HIGH confidence)

- `https://developer.paddle.com/webhooks/signature-verification` - header format, raw-body requirement, `h1` semantics, timestamp verification guidance.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/Verifier.py` - default 5-second variance and verification flow.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-python-sdk/main/paddle_billing/Notifications/PaddleSignature.py` - multi-`h1` parsing and constant-time digest comparison.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-php-sdk/main/src/Notifications/Verifier.php` - default variance behavior in another official SDK.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-php-sdk/main/src/Notifications/PaddleSignature.php` - header parsing and hash verification in another official SDK.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/example_webhook_unmarshal_test.go` - generic envelope-first parsing pattern.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-go-sdk/main/webhook_verifier.go` - another official verifier implementation that highlights ecosystem divergence.
- `https://www.erlang.org/doc/apps/crypto/crypto.html` - `:crypto.mac/4` and `:crypto.hash_equals/2`.
- `https://hexdocs.pm/jason/Jason.html` - `Jason.decode/1` error contract.

### Secondary (MEDIUM confidence)

- `https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/notifications/helpers/webhooks-validator.ts` - useful for spotting simplified header handling that should not drive the Phase 2 implementation.
- `https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts` - proves raw-body exactness and fixture-driven failure cases.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - OTP crypto primitives, Jason docs, and local dependency versions were verified directly. [VERIFIED: https://www.erlang.org/doc/apps/crypto/crypto.html] [VERIFIED: https://hexdocs.pm/jason/Jason.html] [VERIFIED: mix.exs]
- Architecture: HIGH - The architecture follows the public Paddle webhook spec, project constraints, and current local module boundaries. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: .planning/PROJECT.md]
- Pitfalls: HIGH - The main failure modes are evidenced by Paddle guidance and official SDK tests. [CITED: https://developer.paddle.com/webhooks/signature-verification] [VERIFIED: https://raw.githubusercontent.com/PaddleHQ/paddle-node-sdk/main/src/__tests__/notifications/webhooks-validator.node.test.ts]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
