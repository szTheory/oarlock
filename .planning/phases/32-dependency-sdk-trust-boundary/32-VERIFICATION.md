---
phase: 32-dependency-sdk-trust-boundary
verified: 2026-09-10T22:51:18Z
status: gaps_found
score: 4/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Public SDK mutation options cannot redirect a validated client's bearer credential to another origin."
    status: failed
    reason: "Public mutation functions pass caller options through to Req; an independent Customers.create/3 probe changed the effective URL to attacker.example while retaining Authorization: Bearer secret-canary."
    artifacts:
      - path: "lib/paddle/http.ex"
        issue: "Unknown request options survive context extraction and are forwarded to Req.request/2."
      - path: "lib/paddle/customers.ex"
        issue: "Caller opts are merged directly into the central request option list despite the public type allowing only :retry."
      - path: "lib/paddle/adjustments.ex"
        issue: "Same unvalidated public mutation-option pattern."
      - path: "lib/paddle/customers/addresses.ex"
        issue: "Same unvalidated public mutation-option pattern."
      - path: "lib/paddle/customers/portal_sessions.ex"
        issue: "Same unvalidated public mutation-option pattern."
      - path: "lib/paddle/notification_settings.ex"
        issue: "Same unvalidated public mutation-option pattern."
      - path: "lib/paddle/transactions.ex"
        issue: "Same unvalidated public mutation-option pattern."
    missing:
      - "Validate each public request option list as a unique keyword list containing only :retry before dispatch."
      - "Reject Req transport options such as :base_url, :auth, :headers, and :adapter before any request is sent."
      - "Add regression tests proving rejection occurs before adapter dispatch and no credential can cross to an overridden origin."
  - truth: "Ambiguous mutation outcomes always return a conservative Paddle.Error with actionable reconciliation guidance instead of crashing."
    status: failed
    reason: "Paddle.Error.from_response/2 assumes body[\"error\"] is a map. A 502 response with %{\"error\" => \"bad-shape\"} raises FunctionClauseError in Access.get/3, bypassing the documented error/ambiguity contract."
    artifacts:
      - path: "lib/paddle/error.ex"
        issue: "error_body is not type-checked before bracket access and Map.get/3 calls."
      - path: "test/paddle/error_test.exs"
        issue: "Covers non-map outer bodies but not non-map nested error values."
    missing:
      - "Normalize the nested error member to an empty map unless it is a map."
      - "Add nil/string/list/unexpected-map nested-error tests, including an ambiguous mutation status."
  - truth: "Public docs, examples, types, and migration guidance agree with tested runtime behavior."
    status: failed
    reason: "Paddle.Customers.Addresses.stream/3 documents {:ok, address}/{:error, error} elements, but the shared pagination implementation yields Address structs directly and raises on page errors. An independent one-page probe returned a bare %Paddle.Address{}."
    artifacts:
      - path: "lib/paddle/customers/addresses.ex"
        issue: "Stream example and Errors section contradict runtime enumeration semantics."
      - path: "lib/paddle/internal/pagination.ex"
        issue: "stream_next/1 emits page.data directly and raises errors, confirming the documentation mismatch."
      - path: "test/paddle/seam_test.exs"
        issue: "The contract suite does not assert this public stream example/behavior."
    missing:
      - "Document bare address elements and raised enumeration failures, or deliberately change the shared stream contract across all resources."
      - "Add a contract/doctest assertion for the documented stream element and error shape."
  - truth: "The documented compatibility and final contract proof runners complete and publish acceptance under the verifier probe contract."
    status: failed
    reason: "Both documented runners were executed with the required 30-second timeout. phase32_compatibility.sh timed out during focused-customer-adapters after its 21-second root row; phase32_contract_proof.sh timed out during its first nested matrix. Neither produced a complete acceptance receipt in the verifier run."
    artifacts:
      - path: "bin/phase32_compatibility.sh"
        issue: "The complete 13-row probe did not finish within 30 seconds in this verification process."
      - path: "bin/phase32_contract_proof.sh"
        issue: "The proof invokes two complete matrices and did not finish within 30 seconds."
    missing:
      - "Make the documented probes complete within the verification timeout or define a bounded, authoritative focused probe that can do so."
      - "Re-run both probes successfully and record fresh receipts after the blockers are fixed."
---

# Phase 32: Dependency & SDK Trust Boundary Verification Report

**Phase Goal:** SDK consumers can use oarlock without known Req advisories, credential disclosure, unsafe mutation replay, invalid client state, or misleading contract guidance.
**Verified:** 2026-09-10T22:51:18Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

The five roadmap success criteria are preserved below. Two goal-level concerns were separated from criterion 5 so credential containment and documentation truthfulness could not hide behind otherwise-correct constructor behavior.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Consumers resolve Req `~> 0.7.4`, retain supported adapter compatibility, and receive a clean Hex audit. | ✓ VERIFIED | `mix.exs` constrains `~> 0.7.4`; root and demo locks resolve 0.7.4; `mix hex.audit` reported no retired or security advisory packages; 260-test suite passed. |
| 2 | Telemetry exposes stable allowlisted facts without forbidden credentials, bodies, URLs, requests/responses, secrets, or customer canaries. | ✓ VERIFIED | `Telemetry.attach/1` projects exact keys; named retry-pair and concurrent-subscriber tests each passed; recursive canary test is active in the passing suite. |
| 3 | Every current public secret-bearing value redacts promoted and nested raw-provider secrets without mutating stored values. | ✓ VERIFIED | Named six-value inspection test passed; explicit Inspect implementations redact protected fields and `raw_data`. The inventory gate has a future-coverage warning below. |
| 4 | Safe reads retry only within documented bounds; ambiguous mutations are never blindly replayed and always return reconciliation guidance. | ✗ FAILED (BLOCKER) | Bounded/single-attempt tests pass, but malformed nested provider errors crash `from_response/2`, so the promised Paddle.Error/reconciliation result is not total. |
| 5 | Client construction rejects invalid state and preserves deliberate custom MockServer URLs. | ✓ VERIFIED | Constructor validates unique known options, credential, environment, and absolute HTTP(S) host before `Req.new/1`; full client tests passed. |
| 6 | Public mutation options cannot override the validated outbound origin or disclose the bearer credential. | ✗ FAILED (BLOCKER) | Independent probe dispatched `Paddle.Customers.create/3` to `https://attacker.example/customers` with `Authorization: Bearer secret-canary`. |
| 7 | Public docs/types/examples describe tested runtime behavior accurately. | ✗ FAILED (BLOCKER) | Address stream docs promise tuples while runtime emits bare structs and raises errors; the full proof runners also did not complete within the mandated probe timeout. |

**Score:** 4/7 truths verified (0 present, behavior-unverified)

### Plan Must-Have Resolution

| Plan | Truths | Resolution |
|---|---:|---|
| 32-01 | 3 | VERIFIED — secure dependency line, root adapter request, demo lock/audit separation. |
| 32-02 | 1 | VERIFIED — migrated adapter fixtures are active in the passing suite. |
| 32-03 | 4 | VERIFIED — constructor decision table, custom URL classification, pre-Req validation, and Client inspection. |
| 32-04 | 6 | 5 VERIFIED; 1 FAILED — malformed nested error bodies bypass the total Paddle.Error ambiguity seam. |
| 32-05 | 3 | 2 VERIFIED; 1 FAILED — mutation guidance is not total, and public mutation opts can override Req transport configuration. |
| 32-06 | 3 | 2 VERIFIED; 1 FAILED — notification create has the same option injection/error normalization gaps. |
| 32-07 | 3 | 2 VERIFIED; 1 FAILED — normal one-attempt behavior passes, but transaction mutation normalization is not total. |
| 32-08 | 4 | VERIFIED — exact schemas, per-attempt ordering, recursive absence, concurrency, and cleanup have active behavioral coverage. |
| 32-09 | 3 | 2 VERIFIED; 1 WARNING — current capability values redact correctly, but the source inventory is not structurally exhaustive per module. |
| 32-10 | 5 | 2 VERIFIED; 3 FAILED — address docs drift and both complete proof executions timed out. |
| 32-11 | 4 | 3 VERIFIED; 1 FAILED — fixtures and atomic self-test pass, but the complete matrix did not finish in the verifier window. |

## Required Artifacts

The automated artifact query reported 42/42 declared artifact checks passing at existence/substance level. Manual wiring exposed the behavioral defects below.

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| `mix.exs`, root/demo locks | Secure Req resolution | ✓ VERIFIED | All select Req 0.7.4. |
| `lib/paddle/client.ex`, client tests | Validated client trust root | ✓ VERIFIED | Substantive, invoked by all public resources, and behaviorally tested. |
| `lib/paddle/http.ex`, `lib/paddle/error.ex` | Central retry and normalization boundary | ✗ PARTIAL | Wired and substantive; unsafe Req option passthrough and non-total nested error parsing remain. |
| Resource modules Plans 05–07 | Static context, bounded reads, one-attempt mutations | ✗ PARTIAL | Normal paths are wired/tested; six public mutation option lists can inject Req options, and malformed errors defeat guidance. |
| Telemetry implementation/tests | Attempt-scoped allowlist | ✓ VERIFIED | Wired into Client Req construction and covered by exact-key, retry, concurrency, and canary tests. |
| Inspect implementations/tests | Secret-safe public representation | ⚠️ WARNING | Current values pass; inventory discovery can miss a second module in a source file. |
| README/guides/changelog/seam tests | Accurate public contract | ✗ PARTIAL | Most contract assertions pass, but address stream docs contradict shared pagination behavior. |
| Compatibility/proof scripts | Complete atomic acceptance | ✗ FAILED | Self-test passes; complete verifier executions timed out and produced no fresh receipt. |

## Key Link Verification

The automated key-link query reported 25/25 declared pattern links present. Presence did not prove safety at two links.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Public mutation APIs | `Paddle.Http.request/4` | Caller options plus internal JSON/context | ✗ UNSAFE | Caller `:base_url`, `:adapter`, `:auth`, or `:headers` can reach Req. |
| `Paddle.Http` | `Paddle.Error` | Non-2xx response normalization | ✗ PARTIAL | Connected, but non-map nested `error` values crash. |
| Client | Req | Validated constructor before Req creation | ✓ WIRED | Constructor controls initial base URL and bearer auth. |
| Resource reads | Pagination/Http | Static operation/route, cursor dispatch | ✓ WIRED | Runtime cursor remains separate from telemetry context. |
| Http telemetry | Req request/response/error steps | Pre-retry terminal instrumentation | ✓ WIRED | Ordering and per-attempt behavior covered by named tests. |
| Inspection tests | Hydration/Inspect implementations | `Http.build_struct/2` and canaries | ✓ WIRED | Current six secret-bearing values are hydrated and redacted. |
| Seam tests | Public docs/types/specs | Contract assertions | ⚠️ PARTIAL | Does not cover the inaccurate address stream contract. |

## Data-Flow Trace (Level 4)

This is a core-library phase, not a rendered-data phase. The relevant trust flows are outbound requests and public representations.

| Artifact | Data | Source → Sink | Produces Real Behavior | Status |
|---|---|---|---|---|
| `Paddle.Customers.create/3` | API key and base URL | Client Req defaults + caller opts → Req adapter | Yes, including unsafe overridden origin | ✗ FLOWING UNSAFELY |
| `Paddle.Error.from_response/2` | Provider error body | Req response → Paddle.Error | Crashes for non-map nested error | ✗ BROKEN |
| `Paddle.Http.Telemetry` | Operational metadata | request-private static context → telemetry subscriber | Exact allowlisted values | ✓ FLOWING |
| Inspect implementations | Secret-bearing values | hydrated structs → `inspect/1` | Protected fields replaced in representation | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full workspace behavior | `mix test` | 260 tests, 0 failures | ✓ PASS |
| Clean advisory result | `mix hex.audit` | No retired or security advisory packages found | ✓ PASS |
| Telemetry retry pairing | `mix test test/paddle/http/telemetry_test.exs:133` | 1 test, 0 failures | ✓ PASS |
| Telemetry subscriber isolation | `mix test test/paddle/http/telemetry_test.exs:205` | 1 test, 0 failures | ✓ PASS |
| Six-value inspection redaction | `mix test test/paddle/inspection_safety_test.exs:99` | 1 test, 0 failures | ✓ PASS |
| One-attempt mutations | `mix test test/paddle/http_test.exs:165` | 1 test, 0 failures | ✓ PASS |
| Ambiguous normal 408/5xx mutations | `mix test test/paddle/http_test.exs:282` | 1 test, 0 failures | ✓ PASS |
| Malformed nested provider error | `mix run -e '... %{\"error\" => \"bad-shape\"} ...'` | `FunctionClauseError: no function clause matching in Access.get/3` | ✗ FAIL |
| Mutation origin/credential containment | `mix run -e '... Customers.create(..., base_url: ..., adapter: ...) ...'` | URL attacker.example; auth `Bearer secret-canary` | ✗ FAIL |
| Address stream element contract | one-page adapter + `Enum.take/2` | Returned bare `%Paddle.Address{}`, not `{:ok, address}` | ✗ FAIL |

## Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Atomic receipt self-test | `bin/phase32_compatibility.sh --self-test` | Passed | ✓ PASS |
| Complete compatibility matrix | `gsd-tools run-with-timeout 30 -- env ACCRUE_CHECKOUT=../accrue bin/phase32_compatibility.sh` | Root row passed; timed out in focused customer row; no receipt | ✗ FAILED |
| Final contract proof | `gsd-tools run-with-timeout 30 -- env ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh` | Concurrent readers and self-test passed; timed out in first nested matrix | ✗ FAILED |

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| SAFE-01 | 01, 02, 10, 11 | ✓ SATISFIED (with probe gap) | Req 0.7.4 is resolved and audit is clean; tests pass. Complete acceptance scripts did not finish within verifier timeout. |
| SAFE-02 | 08, 10 | ✓ SATISFIED | Exact allowlist, recursive canaries, paired attempts, concurrency, and cleanup are behaviorally tested. |
| SAFE-03 | 03, 04, 09, 10 | ✓ SATISFIED (warning) | All current identified secret-bearing public values redact promoted/raw secrets; inventory future-exhaustiveness is weak. |
| SAFE-04 | 04, 05, 06, 07, 10 | ✗ BLOCKED | Normal retry/replay behavior passes, but malformed error envelopes crash instead of returning actionable ambiguity. |
| SAFE-05 | 03, 10 | ✓ SATISFIED | Client constructor rejects invalid state and preserves validated custom base URLs. The broader goal-level request-option credential gap remains a blocker. |
| SAFE-06 | 10 | ✗ BLOCKED | Address stream docs/examples disagree with runtime behavior; proof runners did not complete in verifier execution. |

No Phase 32 requirements are orphaned: SAFE-01 through SAFE-06 appear in plan frontmatter and REQUIREMENTS.md maps only those six to Phase 32.

## Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `test/paddle/http_test.exs` | SAFE-01, SAFE-04 | 20 | 0 | No | Behavioral | PARTIAL — strong normal retry tests, no malformed nested error or Req-option containment case. |
| `test/paddle/http/telemetry_test.exs` | SAFE-02 | 7 | 0 | No | Behavioral/exact value | PASS |
| `test/paddle/inspection_safety_test.exs` | SAFE-03 | 3 | 0 | No | Value/behavioral | WARNING — source regex is file-level and selects only the first module. |
| `test/paddle/client_test.exs` | SAFE-05 | 10 | 0 | No | Behavioral/value | PASS |
| `test/paddle/seam_test.exs` | SAFE-01–06 | 9 | 0 | No | Contract/value | PARTIAL — misses address stream semantics. |

**Disabled tests on requirements:** 0.  
**Circular expected-value generation:** 0. Receipt files are execution outputs, not expected fixtures generated by the system under test.  
**Insufficient assertions:** 3 coverage gaps: request-option containment, malformed nested provider errors, and address stream docs/runtime agreement.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/paddle/http.ex` | 40–45 | Unrecognized public options forwarded into Req | 🛑 BLOCKER | Lets callers replace transport origin/config while bearer auth remains attached. |
| `lib/paddle/error.ex` | 108–117 | Nested provider value assumed to be a map | 🛑 BLOCKER | Malformed provider/intermediary payload crashes the public error boundary. |
| `lib/paddle/customers/addresses.ex` | 229–245 | Example/error text contradicts implementation | 🛑 BLOCKER | Consumers matching documented tuples fail on successful elements and cannot receive documented error tuples. |
| `test/paddle/inspection_safety_test.exs` | 72–91 | File-level regex records only first module | ⚠️ WARNING | A later second public raw-data struct in the same file could escape inventory classification. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers and no disabled requirement tests were found in the Phase 32 implementation/test set.

## Prohibition Review

The plan prohibition entries remain marked `status: unresolved`, `verification: null`, and `flagged_unverified: true`. Current behavioral evidence supports the no-authority-inflation, no-global-config, no-auto-reconcile, telemetry allowlist/cardinality, and no-data-destruction prohibitions. Two prohibitions are observably violated: the false-certainty/error-seam prohibition is defeated by the malformed-body crash, and the split-contract prohibition is defeated by the address-stream documentation. These violations are included as blocking gaps rather than silently passed.

## Decision Coverage

All 19 trackable `32-CONTEXT.md` decisions are reported honored by the non-blocking decision-coverage query. The runtime defects above show why decision substring coverage is not behavioral proof.

## Human Verification Required

N/A — infrastructure/core-library phase with no user-facing visual elements. All relevant outcomes are programmatically testable; the unresolved items are observable code/probe failures, not manual-UAT questions.

## Deferred Items

None. Phases 33–36 cover CI authority, release integrity, operations, and trajectory/handoff; none specifically owns mutation option validation, provider-error normalization, or the incorrect address stream contract.

## Gaps Summary

Phase 32 does not achieve its stated trust-boundary goal. The current SDK can disclose a validated client's bearer credential to a caller-selected origin, malformed provider error envelopes can escape the promised ambiguity/reconciliation result by crashing, and a public stream example misstates both success and failure semantics. The phase's broad test suite remains green because it does not exercise these paths. In addition, neither complete documented proof runner finished within the verifier's required 30-second execution window, so fresh final acceptance was not produced.

---

_Verified: 2026-09-10T22:51:18Z_  
_Verifier: the agent (gsd-verifier)_
