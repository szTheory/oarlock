---
phase: "32"
slug: "dependency-sdk-trust-boundary"
status: verified
# threats_open counts only OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: "2026-09-10"
verified: "2026-09-10"
---

# Phase 32 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hex registry → generated locks | External package metadata becomes executable dependency state. | Package versions, checksums, and advisory state |
| Caller options → SDK client/request state | Caller-controlled configuration can affect authority, routing, retries, and transport. | Credentials, origins, headers, adapters, retry policy |
| Provider HTTP → public SDK values | Untrusted provider responses become errors, telemetry, structs, and inspection output. | Customer data, request metadata, raw provider payloads |
| SDK runtime → observability and documentation | Runtime behavior is represented outside the request path. | Allowlisted telemetry, public contracts, examples, evidence receipts |
| Local/isolated/downstream verification → acceptance receipts | Multiple proof environments determine whether the release boundary is accepted. | Test outcomes, durations, file-state digests, atomic receipts |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-32-01 | Tampering | Dependency and lock state | high | mitigate | Req floor and matching root/demo locks; compatibility matrix and `mix hex.audit`. | closed |
| T-32-02 | Repudiation | Dependency acceptance evidence | medium | mitigate | Exact versions plus separately named compile, compatibility, audit, and duration records. | closed |
| T-32-03 | Denial of Service | Registry-dependent verification | low | accept | Registry failure blocks acceptance and cannot publish a clean receipt; documented as AR-32-01. | closed |
| T-32-04 | Tampering | Req adapter fixture migration | medium | mitigate | Module-backed adapters retained across every migrated test family and matrix row. | closed |
| T-32-05 | Repudiation | Compatibility matrix receipts | high | mitigate | Named rows preserve status and duration; receipt publishes only after total success. | closed |
| T-32-06 | Tampering | Partial/interrupted matrix | high | mitigate | Killed/nonzero self-tests reject receipts; tracked-file equality and atomic rename enforced. | closed |
| T-32-07 | Spoofing | Environment/base URL resolution | high | mitigate | Canonical environment/URL coherence is validated before Req construction. | closed |
| T-32-07A | Information Disclosure | Downstream/audit commands | low | accept | Fixed command labels/results only; credentials are not printed; documented as AR-32-02. | closed |
| T-32-08 | Information Disclosure | Constructor errors and Client Inspect | high | mitigate | Static errors and wholesale API key, URL, and Req redaction with secret-canary tests. | closed |
| T-32-09 | Tampering | Duplicate/unknown client options | medium | mitigate | Duplicate and unknown keys are rejected before transport state exists. | closed |
| T-32-10 | Tampering | Mutation retry policy | critical | mitigate | Central method gate and pre-dispatch override rejection; all mutation verbs remain one attempt. | closed |
| T-32-11 | Denial of Service | Read retries and Retry-After | high | mitigate | Exact transient allowlist, four-attempt ceiling, and 60-second 429-only cap. | closed |
| T-32-12 | Repudiation | Ambiguous mutation results | high | mitigate | Conservative error includes safe correlation, operation/resource identity, and reconciliation actions. | closed |
| T-32-13 | Information Disclosure | Error raw data and inspection | high | mitigate | Raw provider data remains stored but is wholly redacted from Inspect and guidance. | closed |
| T-32-14 | Information Disclosure | Resource route metadata | high | mitigate | Literal normalized operation/routes exclude runtime IDs, filters, and cursors. | closed |
| T-32-15 | Tampering | Customer-family mutations | high | mitigate | Idempotency options removed; single-attempt ambiguity asserted across mutation surfaces. | closed |
| T-32-16 | Information Disclosure | Catalog/notification route context | high | mitigate | Static route labels and tests exclude runtime identifiers and secret destinations. | closed |
| T-32-17 | Tampering | Notification mutations | high | mitigate | Central one-attempt policy and ambiguity assertions cover create/update/delete. | closed |
| T-32-18 | Tampering | Subscription/transaction mutations | critical | mitigate | Every lifecycle mutation variant dispatches once and returns non-retryable ambiguity. | closed |
| T-32-19 | Information Disclosure | Pagination telemetry context | high | mitigate | Cursor URL stays dispatch-only while literal originating labels propagate separately. | closed |
| T-32-20 | Information Disclosure | Telemetry payloads | critical | mitigate | Exact allowlist projection and recursive forbidden-struct/secret-canary assertions. | closed |
| T-32-21 | Repudiation | Retry attempt topology | medium | mitigate | Ordered start/terminal event pairs, explicit attempt counts, and concurrency isolation tests. | closed |
| T-32-22 | Denial of Service | Telemetry cardinality | medium | mitigate | Static operation/routes and sanitized host exclude path/query/body/runtime identifiers. | closed |
| T-32-23 | Information Disclosure | Public Inspect implementations | critical | mitigate | Exhaustive protected-field inventory and unique provider-hydrated canaries cover every public type. | closed |
| T-32-24 | Tampering | Stored forward-compatible raw data | medium | mitigate | Inspection is proven term-preserving and does not alter hydration. | closed |
| T-32-25 | Repudiation | Public contract/evidence ladder | high | mitigate | Mechanical positive and negative assertions bind claims to tested behavior and evidence tiers. | closed |
| T-32-26 | Tampering | Concurrent/interrupted/final evidence | high | mitigate | Byte-identical isolated readers/builds, interruption rejection, canonical full receipts, and no drift. | closed |
| T-32-27 | Information Disclosure | Documentation examples | medium | mitigate | Synthetic placeholders and negative checks reject credentialized URLs and raw telemetry examples. | closed |
| T-32-28 | Spoofing / Information Disclosure | Mutation request options | critical | mitigate | Shared validator rejects origin/auth/header/adapter options before merge or dispatch. | closed |
| T-32-29 | Tampering | Duplicate/malformed retry options | high | mitigate | Only one unique boolean `:retry` entry is accepted. | closed |
| T-32-30 | Information Disclosure | Validation errors | high | mitigate | Static text and option names only; secret values are excluded by canary tests. | closed |
| T-32-31 | Denial of Service | Malformed option containers | medium | mitigate | Invalid shapes immediately raise before request work. | closed |
| T-32-32 | Denial of Service / Repudiation | Malformed provider error envelopes | high | mitigate | Arbitrary nested shapes normalize to conservative public errors for ambiguous mutations. | closed |
| T-32-33 | Repudiation | Address stream documentation | high | mitigate | Compiled docs are bound to direct-element and raised-exception behavior tests. | closed |
| T-32-34 | Tampering | Compatibility/contract receipts | high | mitigate | Atomic complete-only publication, interruption self-test, exact SAFE rows, and no-drift equality. | closed |
| T-32-35 | Repudiation | Bounded versus full evidence | high | mitigate | Distinct modes/receipts prevent bounded proof from replacing the full 13-row matrix. | closed |
| T-32-36 | Information Disclosure | Verifier logs and errors | medium | mitigate | Synthetic inputs plus telemetry/Inspect canaries run inside the bounded suite. | closed |
| T-32-37 | Information Disclosure / Repudiation | Inspection source inventory | high | mitigate | Module-scoped AST inventory requires every raw-data-bearing public struct to be classified. | closed |

*Only open threats at or above the configured `high` threshold count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-32-01 | T-32-03 | A Hex registry outage may delay verification, but the fail-closed runner cannot misrepresent it as a clean dependency audit. | Phase 32 plan 32-01 | 2026-09-10 |
| AR-32-02 | T-32-07A | Downstream/audit proof records fixed labels and outcomes only; provider credentials remain outside the acceptance receipt and logs. | Phase 32 plan 32-11 | 2026-09-10 |

*These plan-time accepted risks do not resurface as open findings in future audits unless their controls change.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-10 | 38 | 38 | 0 | gsd-security-auditor |

Fresh audit evidence: 70 focused security tests passed with 0 failures; the compatibility interruption/failure self-test passed; `mix hex.audit` reported no retired or security-advisory packages. No implementation files were modified by the audit.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer).
- [x] Accepted risks are documented in the Accepted Risks Log.
- [x] `threats_open: 0` confirmed at the configured high-severity threshold.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-09-10
