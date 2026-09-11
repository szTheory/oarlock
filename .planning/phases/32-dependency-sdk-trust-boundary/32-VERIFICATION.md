---
phase: 32-dependency-sdk-trust-boundary
verified: 2026-09-11T02:26:51Z
status: gaps_found
score: 6/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "Public mutation create APIs reject caller transport authority before dispatch."
    - "Malformed nested provider error envelopes normalize to conservative Paddle.Error values."
    - "Address stream documentation now matches bare-element and raised-error runtime behavior."
  gaps_remaining:
    - "The documented bounded contract proof is not reliably complete within 30 seconds."
  regressions:
    - "A failed full-matrix preflight leaves a stale passing compatibility receipt in place."
    - "Subscription pause/resume silently collapse duplicate :retry options instead of rejecting them."
gaps:
  - truth: "A failed or interrupted compatibility run cannot leave an acceptance receipt that can be mistaken for current success."
    status: failed
    reason: "run_matrix validates ACCRUE_CHECKOUT before deleting the destination receipt. A verifier probe seeded a passing receipt, invoked --full with an empty ACCRUE_CHECKOUT, observed exit 2, and found the stale passing receipt unchanged."
    artifacts:
      - path: "bin/phase32_compatibility.sh"
        issue: "FULL_RECEIPT_PATH is removed only after preflight checks at lines 168-175 can return."
    missing:
      - "Invalidate or quarantine the full receipt before every preflight capable of failing."
      - "Extend --self-test with a seeded stale receipt plus failed-preflight assertion."
  - truth: "The bounded Phase 32 contract proof reliably completes within the documented 30-second verifier budget and publishes acceptance only when the wrapped command succeeds."
    status: failed
    reason: "Three fresh exact-wrapper runs took the entire budget. Two exited zero at approximately 29.4-29.9 seconds; the third was terminated by the 30-second wrapper after printing success. The third run had already published phase32-contract-verifier.receipt, so the external command failed while an acceptance artifact remained."
    artifacts:
      - path: "bin/phase32_contract_proof.sh"
        issue: "run_verify performs concurrent compilation/docs, receipt self-test, a time-bearing 72-test bounded suite, and online audit with no reliable timeout margin; it publishes before EXIT cleanup completes."
      - path: "bin/phase32_compatibility.sh"
        issue: "run_bounded_mix includes real jittered retry waits, producing variable multi-second latency inside the fixed 30-second proof."
    missing:
      - "Remove wall-clock retry waits from bounded verifier evidence or narrow the proof to deterministic tagged/named tests while retaining independent retry-decision coverage."
      - "Require meaningful cold-run margin and ensure timeout/nonzero termination cannot leave a passing contract receipt."
  - truth: "Every public mutation option list rejects duplicate retry keys before dispatch, independent of key order."
    status: failed
    reason: "normalize_pause_opts/1 and normalize_resume_opts/1 use Keyword.pop/2, which collapses all duplicate :retry entries to the first value. Independent probes showed [retry: false, retry: true] dispatches successfully for both pause and resume, while the reversed order raises, making validation order-dependent."
    artifacts:
      - path: "lib/paddle/subscriptions.ex"
        issue: "Pause and resume normalization remove duplicate :retry entries without checking uniqueness."
      - path: "test/paddle/subscriptions_test.exs"
        issue: "Covers retry: false and unknown options, but has no duplicate-retry rejection matrix for pause/resume."
    missing:
      - "Reject more than one :retry entry before body normalization and Http dispatch for pause and resume."
      - "Add both conflicting orders for both APIs and assert zero adapter dispatches."
---

# Phase 32: Dependency & SDK Trust Boundary Verification Report

**Phase Goal:** SDK consumers can use oarlock without known Req advisories, credential disclosure, unsafe mutation replay, invalid client state, or misleading contract guidance.
**Verified:** 2026-09-11T02:26:51Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 32-12 and 32-13 gap closure

## Goal Achievement

### Observable Truths

The five roadmap success criteria remain non-negotiable. Four plan-level truths are kept separate so acceptance-artifact integrity, verifier boundedness, and complete mutation-option validation cannot hide behind otherwise-green runtime tests.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Consumers resolve Req `~> 0.7.4`, retain supported compatibility, and receive a clean Hex audit. | ✓ VERIFIED | `mix.exs`, root `mix.lock`, and `demo/mix.lock` select Req 0.7.4. Each fresh bounded run executed 72 gap-sensitive tests with 0 failures and `mix hex.audit` reported no advisory packages. A preserved 13-row receipt records a complete full matrix. |
| 2 | Telemetry exposes only stable allowlisted facts and preserves independent per-attempt event pairing under retry/concurrency. | ✓ VERIFIED | `Paddle.Http.Telemetry` projects exact measurement/metadata keys and is wired before retry consumption. The current bounded suite repeatedly passed the recursive canary, attempt-pairing, and process-owned subscriber tests. |
| 3 | Every current public secret-bearing value redacts promoted and nested raw-provider secrets without mutating stored values. | ✓ VERIFIED | Six custom Inspect implementations replace capability fields/raw containers wholesale; the AST-scoped inventory, sibling-module discovery fixture, provider hydration, recursive canaries, and immutability assertions pass in the bounded suite. |
| 4 | Safe reads retry only within documented bounds; ambiguous mutations execute once and return conservative reconciliation guidance. | ✓ VERIFIED | `Paddle.Http` method-gates the exact transient set with `max_retries: 3` and a 60,000 ms 429 cap. Malformed nested error cases normalize through `Paddle.Error`; bounded tests passed. Duplicate pause/resume input validation is separated as truth 9. |
| 5 | Client construction rejects blank credentials, unsupported environments, and invalid options while valid custom MockServer URLs work. | ✓ VERIFIED | Validation helpers execute before `Req.new/1`; current client tests in the bounded suite cover the decision table, pre-dispatch rejection, custom URL dispatch, and secret-safe failures. |
| 6 | Public docs, examples, types, retry guidance, stream semantics, evidence tiers, and migration notes agree with tested runtime behavior. | ✓ VERIFIED | Compiled seam tests pass, including direct address elements and raised enumeration errors; required/forbidden claims and fetched docs/types/specs are mechanically checked. The malformed Inspect rendering shape is a warning, not a secret-disclosure or contract contradiction. |
| 7 | Failed or interrupted full compatibility runs cannot leave stale acceptance. | ✗ FAILED (BLOCKER) | Seeded-receipt preflight probe exited 2 for missing `ACCRUE_CHECKOUT` but left `phase32_compatibility=passed` and `commit=stale` intact. |
| 8 | The bounded contract proof reliably completes within 30 seconds and only a successful wrapped command leaves acceptance. | ✗ FAILED (BLOCKER) | Exact wrapper runs finished at ~29.4s and ~29.9s, then timed out on the third run. The timed-out run had already published a passing contract receipt. |
| 9 | Every public mutation option list rejects duplicate `:retry` keys before dispatch regardless of order. | ✗ FAILED (BLOCKER) | Both pause and resume dispatched for `[retry: false, retry: true]`; reversing the entries raised `ArgumentError` without dispatch. |

**Score:** 6/9 truths verified (0 present-but-behavior-unverified)

## Required Artifacts

Automated plan-frontmatter checks report **50/50 artifacts** present and substantive. Manual wiring/behavior checks expose the three defects below.

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| Root/demo manifests and locks | Secure Req resolution | ✓ VERIFIED | Root constraint and both generated locks select Req 0.7.4. |
| `lib/paddle/client.ex` and client tests | Validated explicit client | ✓ VERIFIED | Substantive, pre-Req validation is wired, custom URLs work, and secret-bearing fields redact. |
| `lib/paddle/http.ex`, `lib/paddle/error.ex` | Central bounded retry and total ambiguity seam | ✓ VERIFIED | Exact retry policy and malformed-envelope normalization are wired and behaviorally exercised. |
| Resource modules | Static context and one-attempt mutations | ✗ PARTIAL | Normal lifecycle behavior passes, but subscription pause/resume duplicate retry validation is incomplete. |
| Telemetry implementation/tests | Attempt-scoped exact allowlist | ✓ VERIFIED | Wired into Req steps and covered by exact-key, canary, retry, concurrency, and cleanup tests. |
| Inspect implementations/tests | Secret-safe public representations | ⚠ WARNING | Redaction is effective, but all six custom Inspect implementations emit malformed struct-like syntax such as `%Paddle.Client{[api_key: ...]}`. |
| Docs/seam tests | Runtime-accurate public contract | ✓ VERIFIED | Address stream and evidence-boundary corrections are compiled and tested. |
| Compatibility/proof scripts | Fail-closed, bounded atomic acceptance | ✗ FAILED | Full preflight preserves stale success; bounded proof is deadline-fragile and can leave a receipt after wrapper termination. |

## Key Link Verification

Automated plan-frontmatter checks report **32/32 key-link patterns** present. Behavioral inspection changes two links from nominally present to unsafe.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Public create mutations | `Paddle.Http.validate_public_request_opts!/1` | Validation before normalization/merge | ✓ WIRED | Six create APIs reject transport authority and duplicate/malformed retry options before dispatch. |
| Subscription pause/resume | `Paddle.Http.request/4` | Resource-local normalization then central request policy | ✗ PARTIAL | Resource normalization collapses duplicate retry entries before central validation can see them. |
| `Paddle.Http` | `Paddle.Error` | Terminal error normalization | ✓ WIRED | Malformed nested envelopes reach conservative `Paddle.Error` values. |
| Client | Req | Preconstruction validation | ✓ WIRED | Credential/environment/base URL validation precedes `Req.new/1`. |
| Telemetry | Req request/response/error steps | Pre-retry terminal instrumentation | ✓ WIRED | Request-local attempt state and exact projections are behaviorally covered. |
| Contract proof | Compatibility verifier and receipt | Nested bounded evidence | ✗ UNSAFE | Receipt publication can precede the wrapper's final successful termination; total duration has no stable margin. |

## Data-Flow Trace (Level 4)

Phase 32 is an SDK/core-library phase with no rendered UI data. The relevant flows are authority, provider errors, telemetry, and inspection.

| Artifact | Data | Source → Sink | Status |
|---|---|---|---|
| Public create APIs | Caller request options | Public function → shared validator → Req | ✓ CONTAINED |
| Subscription pause/resume | Duplicate retry entries | Public function → `Keyword.pop/2` → central request | ✗ COLLAPSED / ORDER-DEPENDENT |
| `Paddle.Error.from_response/2` | Arbitrary provider body | Req response → typed conservative public error | ✓ FLOWING SAFELY |
| `Paddle.Http.Telemetry` | Operational request facts | Request-private static context → subscriber allowlist | ✓ FLOWING SAFELY |
| Inspect implementations | Capability-bearing structs | Hydrated stored term → redacted representation | ✓ FLOWING SAFELY (format warning) |
| Compatibility/proof scripts | Process verdict | Preconditions/tests → atomic receipt | ✗ STALE/PREMATURE ACCEPTANCE POSSIBLE |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Current workspace suite | `mix test` | 272 tests, 0 failures in the execute-phase post-merge gate | ✓ PASS |
| Prior-phase regression corpus | Node regression gate | 133 tests, 0 failures | ✓ PASS |
| Bounded SAFE corpus and audit | nested `phase32_compatibility.sh --verify` | 72 tests, 0 failures; audit clean on each verifier attempt | ✓ PASS |
| Full receipt stale on failed preflight | Seed receipt, run `--full` with empty `ACCRUE_CHECKOUT` | Exit 2; stale passing receipt remains unchanged | ✗ FAIL |
| Duplicate pause retry options | Public pause calls with both key orders | `false,true` dispatched and returned `{:ok, _}`; `true,false` raised before dispatch | ✗ FAIL |
| Duplicate resume retry options | Public resume calls with both key orders | `false,true` dispatched and returned `{:ok, _}`; `true,false` raised before dispatch | ✗ FAIL |
| Inspect representation shape | Inspect current Client and Error | `%Module{[key: value]}` malformed struct-like syntax | ⚠ WARNING |

## Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Compatibility interruption/failure self-test | nested `bin/phase32_compatibility.sh --self-test` | Passed on all three contract-verifier attempts, but does not cover stale preflight receipts | ⚠ INCOMPLETE |
| Bounded compatibility | nested exact `--verify` mode | 72 tests and online audit passed; atomic verifier receipt present | ✓ PASS |
| Bounded contract proof run 1 | exact 30-second wrapper | Exit 0 at ~29.4s; receipt present | ⚠ MARGINAL |
| Bounded contract proof run 2 | exact 30-second wrapper | Exit 0 at ~29.9s; receipt present | ⚠ MARGINAL |
| Bounded contract proof run 3 | exact 30-second wrapper | Terminated at 30s after printing success; receipt already present | ✗ FAILED |
| Full 13-row acceptance | preserved receipt from fresh Plan 13 execution | 13 named rows recorded at implementation commit; current code still passes 272 tests | ⚠ RECEIPT INTEGRITY GAP |

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| SAFE-01 | 01, 02, 10, 11, 13 | ✓ SATISFIED (receipt warning) | Req 0.7.4 is installed, bounded compatibility is green, and online audit is clean. Stale full receipts weaken evidence integrity but do not negate the actual dependency result. |
| SAFE-02 | 08, 10, 13 | ✓ SATISFIED | Exact allowlists, recursive canaries, paired attempts, concurrency, and cleanup are active in the passing bounded corpus. |
| SAFE-03 | 03, 04, 09, 10, 13 | ✓ SATISFIED (format warning) | AST inventory and six provider-hydrated redaction proofs pass; stored terms are unchanged. Inspect output shape is malformed but does not disclose secrets. |
| SAFE-04 | 04-07, 10, 12, 13 | ✗ BLOCKED | Core retry/ambiguity behavior passes, but public subscription mutation options accept duplicate retry configuration in one ordering and dispatch instead of rejecting it. |
| SAFE-05 | 03, 10, 12 | ✓ SATISFIED | Constructor validation and create-mutation authority containment are tested; deliberate custom MockServer URLs remain supported. |
| SAFE-06 | 10, 13 | ✗ BLOCKED | Public prose/runtime alignment passes, but the documented bounded proof is unreliable and can publish acceptance despite wrapper failure. |

No Phase 32 requirements are orphaned. SAFE-01 through SAFE-06 appear in plan frontmatter and REQUIREMENTS.md maps only those six to Phase 32.

## Test Quality Audit

| Test area | Linked Req | Disabled | Circular | Assertion Level | Verdict |
|---|---|---:|---|---|---|
| Dependency/compatibility and receipts | SAFE-01, SAFE-06 | 0 | No | Integration/behavioral | ✗ INCOMPLETE — self-test omits stale preflight and wrapper-termination receipt cases. |
| HTTP/error/retry | SAFE-04 | 0 | No | Behavioral/value | ✓ PASS for central policy and malformed envelopes. |
| Subscription lifecycle | SAFE-04 | 0 | No | Behavioral | ✗ INCOMPLETE — no duplicate-retry tests for pause/resume. |
| Telemetry | SAFE-02 | 0 | No | Behavioral/exact value | ✓ PASS |
| Inspection safety | SAFE-03 | 0 | No | Behavioral/value | ⚠ WARNING — redaction is strong; exact valid-struct formatting is unasserted. |
| Client construction | SAFE-05 | 0 | No | Behavioral/value | ✓ PASS |
| Public seam/docs | SAFE-01-06 | 0 | No | Contract/value | ✓ PASS for documented runtime semantics; shell text-presence checks do not prove timing reliability. |

No disabled requirement tests or circular expected-value generators were found.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `bin/phase32_compatibility.sh` | 168-179 | Receipt invalidation occurs after failing preflight | 🛑 BLOCKER | A previous success can survive a failed current run. |
| `bin/phase32_contract_proof.sh` | 166-198 | Acceptance publishes before total wrapped-process completion with deadline-fragile work | 🛑 BLOCKER | Timeout can coexist with a passing receipt. |
| `lib/paddle/subscriptions.ex` | 478-562 | `Keyword.pop/2` silently collapses duplicate `:retry` keys | 🛑 BLOCKER | Mutation option validation is inconsistent and order-dependent. |
| `lib/paddle/client.ex` and five peer Inspect implementations | 213+ | Keyword-list document wrapped in struct braces | ⚠ WARNING | Logs render malformed struct-like syntax, reducing debuggability. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers exist in the Phase 32 implementation/test scope.

## Prohibition Review

Behavioral evidence supports the no-authority-inflation, telemetry-disclosure, raw-data-destruction, automatic-reconciliation, and split-doc-contract prohibitions. The receipt-integrity and unique-option prohibitions are observably violated and are represented as blocking gaps above. No separate human-only prohibition decision can lower the `gaps_found` verdict.

## Decision Coverage

All 19 trackable `32-CONTEXT.md` decisions are reported honored by the non-blocking decision-coverage query. This is substring coverage only; the three behavioral blockers above supersede it as goal evidence.

## Human Verification Required

N/A — infrastructure/core-library phase with no user-facing visual elements. Every unresolved item was reproduced programmatically; `behavior_unverified: 0`.

## Deferred Items

None. Phases 33-36 cover hosted CI authority, release publication, contribution operations, and durable trajectory. None specifically owns Phase 32 receipt invalidation, bounded local verifier timing, or subscription option uniqueness.

## Gaps Summary

Plans 32-12 and 32-13 close the earlier credential-redirection, malformed-error, and address-stream documentation gaps. The phase still cannot pass its trust-boundary goal: failed full preflight can preserve stale acceptance, the bounded proof is not reliably bounded and can leave a passing receipt after timeout, and subscription pause/resume silently accept duplicate retry configuration in one order. The 272-test current suite and 133-test regression gate are green because they do not exercise these three paths.

---

_Verified: 2026-09-11T02:26:51Z_
_Verifier: the agent (gsd-verifier)_
