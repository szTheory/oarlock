---
phase: 32-dependency-sdk-trust-boundary
verified: 2026-09-11T03:43:31Z
status: gaps_found
score: 9/11 must-haves verified
covered_files: [".planning/REQUIREMENTS.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-01-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-01-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-02-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-02-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-03-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-03-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-04-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-04-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-05-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-05-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-06-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-06-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-07-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-07-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-08-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-08-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-09-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-09-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-10-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-10-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-11-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-11-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-12-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-12-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-13-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-13-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-14-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-14-SUMMARY.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-15-PLAN.md", ".planning/phases/32-dependency-sdk-trust-boundary/32-15-SUMMARY.md", ".tool-versions", "CHANGELOG.md", "README.md", "bin/phase32_compatibility.sh", "bin/phase32_contract_proof.sh", "demo/README.md", "demo/mix.lock", "guides/accrue-seam.md", "guides/getting-started.md", "guides/telemetry.md", "lib/paddle/adjustments.ex", "lib/paddle/client.ex", "lib/paddle/customers.ex", "lib/paddle/customers/addresses.ex", "lib/paddle/customers/portal_sessions.ex", "lib/paddle/error.ex", "lib/paddle/events.ex", "lib/paddle/http.ex", "lib/paddle/http/telemetry.ex", "lib/paddle/internal/pagination.ex", "lib/paddle/notification_setting.ex", "lib/paddle/notification_settings.ex", "lib/paddle/portal_session.ex", "lib/paddle/portal_sessions.ex", "lib/paddle/prices.ex", "lib/paddle/products.ex", "lib/paddle/subscription/management_urls.ex", "lib/paddle/subscriptions.ex", "lib/paddle/transaction/checkout.ex", "lib/paddle/transactions.ex", "mix.exs", "mix.lock", "test/paddle/adjustments_test.exs", "test/paddle/client_test.exs", "test/paddle/customers/addresses_test.exs", "test/paddle/customers/portal_sessions_test.exs", "test/paddle/customers_test.exs", "test/paddle/error_test.exs", "test/paddle/events_test.exs", "test/paddle/http/telemetry_test.exs", "test/paddle/http_test.exs", "test/paddle/inspection_safety_test.exs", "test/paddle/notification_settings_test.exs", "test/paddle/portal_session_test.exs", "test/paddle/prices_test.exs", "test/paddle/products_test.exs", "test/paddle/seam_test.exs", "test/paddle/subscriptions_test.exs", "test/paddle/transactions_test.exs"]
covered_digest: "v1:sha256:9433f5c9db28c2f6778182c66ac04a628866325fd6b5ab481de84300c46035e2"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/9
  gaps_closed:
    - "Failed/interrupted compatibility attempts leave no stale acceptance receipt."
    - "The bounded proof finishes within 30 seconds and publishes only on successful exit."
    - "Lifecycle mutations reject duplicate retry keys independent of order."
  gaps_remaining: []
  regressions:
    - "CR-01: bounded receipt claims docs/spec proof that run_verify never executes."
    - "WR-02: file:line selectors can greenlight unrelated tests."
gaps:
  - truth: "The bounded Phase 32 contract receipt never reports docs/spec proof unless the bounded run executes that proof."
    status: failed
    reason: "run_verify does not call the docs builder or docs-content tests but safe_verdicts emits SAFE-06=pass docs/specs."
    artifacts:
      - path: bin/phase32_contract_proof.sh
        issue: "Lines 226-257 publish a docs/spec verdict with no docs proof."
    missing:
      - "Run isolated docs/spec proof before VERIFY_COMPLETE, or remove docs/specs from the receipt verdict."
  - truth: "The bounded verifier executes the intended safety proofs by stable identity and confirms their selection before receipt publication."
    status: failed
    reason: "Eleven file:line selectors are unvalidated; an out-of-range selector exits zero after running an unrelated test."
    artifacts:
      - path: bin/phase32_compatibility.sh
        issue: "Lines 48-60 use unstable locations without selected-test identity/count validation."
    missing:
      - "Use unique ExUnit tags or a dedicated bounded-proof file and assert the active proof set."
---

# Phase 32: Dependency & SDK Trust Boundary Verification Report

**Phase Goal:** SDK consumers can use oarlock without known Req advisories, credential disclosure, unsafe mutation replay, invalid client state, or misleading contract guidance.
**Verified:** 2026-09-11T03:43:31Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 32-14 and 32-15 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Consumers install the secure Req upgrade, pass the matrix, and obtain a clean audit. | ✓ VERIFIED | Fresh `--full` receipt at `f621888`: all 13 rows passed, including 275 root tests, docs, package/demo/downstream, Dialyzer, and audit. |
| 2 | Telemetry exposes stable allowlisted facts without secret/request payload disclosure. | ✓ VERIFIED | Current targeted telemetry/core suite (55 tests) and full telemetry row passed. |
| 3 | Public secret-bearing values redact promoted and nested provider secrets. | ✓ VERIFIED | Current inspection-safety suite passed; no disabled requirement test or circular oracle found. |
| 4 | Reads retry only within bounds; mutations do not replay and provide reconciliation guidance. | ✓ VERIFIED | Current HTTP/error/subscription behavior passed in targeted and full suites. |
| 5 | Invalid clients/options reject before transport; valid custom MockServer URLs work. | ✓ VERIFIED | Current client and cross-resource authority tests passed. |
| 6 | Public docs, examples, types, retry and stream guidance match tested behavior. | ✓ VERIFIED | `MIX_ENV=dev mix docs` and direct seam tests 649/719/732 passed; full docs row passed. |
| 7 | Failed/interrupted full compatibility attempts cannot preserve stale acceptance. | ✓ VERIFIED | `phase32_compatibility.sh --self-test` passed; invalidation precedes preflight. |
| 8 | Bounded proof has 30-second margin and publishes only after successful exit. | ✓ VERIFIED | Fresh wrapped `--verify` completed in about 7 seconds; termination self-test passed. |
| 9 | Pause, pause-immediately, and resume reject duplicate `:retry` in either order before dispatch. | ✓ VERIFIED | Shared guard precedes `Keyword.pop/2`; direct zero-dispatch regression at line 806 passed. |
| 10 | Bounded receipt claims only docs/spec proof that actually executed. | ✗ FAILED (BLOCKER) | CR-01: `run_verify` never reaches docs builder/content tests yet emits `SAFE-06=pass docs/specs`. |
| 11 | Bounded proof selection is stable and confirms intended tests ran. | ✗ FAILED (BLOCKER) | WR-02: `mix test test/paddle/http_test.exs:99999 --trace` passed an unrelated line-409 test. |

**Score:** 9/11 truths verified (0 present-but-behavior-unverified)

The three carried-forward gaps are closed. The two remaining blockers are evidenced regressions in scripts modified after the previous report, so the re-verification evidence gate keeps them blocking.

### Required Artifacts

`verify.artifacts` reports 50/50 declared artifacts present and substantive. Manual wiring changes the bounded-proof artifact result.

| Artifact group | Status | Details |
|---|---|---|
| Dependency, client, HTTP/error, resource, telemetry, Inspect, subscription, and docs artifacts | ✓ VERIFIED | Current targeted behavior checks and fresh full matrix pass. |
| `bin/phase32_compatibility.sh` and `bin/phase32_contract_proof.sh` bounded paths | ✗ PARTIAL / BLOCKER | Full path is valid; bounded path has the CR-01 and WR-02 evidence-integrity defects. |

### Key Link Verification

`verify.key-links` reports 32/32 textual links. Behavior-level tracing found two broken links.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Subscription normalizers | `Paddle.Http.request/4` | Uniqueness before normalization/dispatch | ✓ WIRED | Direct regression passes. |
| Full contract proof | Docs builder and docs assertions | `run_concurrent_readers` | ✓ WIRED | Full matrix and direct docs proof pass. |
| Bounded contract proof | Docs builder and docs assertions | `run_verify` | ✗ NOT WIRED | CR-01. |
| Bounded compatibility proof | Intended proof tests | `run_bounded_mix` | ✗ UNSAFE | WR-02 line selectors are not an identity proof. |

### Data-Flow Trace (Level 4)

| Artifact | Source → Sink | Status |
|---|---|---|
| Caller mutation options | Public API → validator/normalizer → `Paddle.Http` | ✓ CONTAINED |
| Provider errors | Req response → `Paddle.Error` | ✓ FLOWING SAFELY |
| Full receipt | All completed matrix rows → atomic receipt | ✓ FLOWING SAFELY |
| Bounded SAFE-06 receipt | `run_verify` → receipt | ✗ DISCONNECTED FROM DOCS PROOF |
| Bounded test evidence | file:line selector → ExUnit result → receipt | ✗ UNASSERTED / UNSTABLE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full compatibility | `ACCRUE_CHECKOUT=../accrue bin/phase32_compatibility.sh --full` | Fresh 13/13 receipt; exit 0 | ✓ PASS |
| Full receipt lifecycle | `bash bin/phase32_compatibility.sh --self-test` | Exit 0 | ✓ PASS |
| Contract termination | `bash bin/phase32_contract_proof.sh --self-test-termination` | Exit 0 | ✓ PASS |
| Bounded proof timing | 30-second wrapped `--verify` | Exit 0 in ~7 seconds | ✓ PASS |
| Duplicate lifecycle retry | `mix test test/paddle/subscriptions_test.exs:806 --trace` | 1 table-driven test, 0 failures | ✓ PASS |
| Docs/types/stream contract | docs build + seam 649/719/732 | Build and 3 tests pass | ✓ PASS |
| Selector integrity | `mix test test/paddle/http_test.exs:99999 --trace` | Exit 0; unrelated test runs | ✗ FAIL |

### Probe Execution

| Probe | Result | Status |
|---|---|---|
| Compatibility self-test | Exit 0 | PASS |
| Contract termination self-test | Exit 0 | PASS |
| Bounded contract verifier | Exit 0, but unearned SAFE-06 claim / unstable selection | FAILED AS ACCEPTANCE EVIDENCE |
| Full compatibility matrix | Exit 0; 13 fresh rows | PASS |

### Requirements Coverage

Every SAFE ID occurs in Phase 32 plan frontmatter and maps to Phase 32 in `REQUIREMENTS.md`; none is orphaned. The checkbox display is stale for SAFE-02/03/05 but does not replace these code/test findings.

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| SAFE-01 | 01, 02, 10, 11, 13, 14 | ✓ SATISFIED | Fresh full matrix and audit. |
| SAFE-02 | 08, 10, 13 | ✓ SATISFIED | Active telemetry tests pass. |
| SAFE-03 | 03, 04, 09, 10, 13 | ✓ SATISFIED | Inspection safety tests pass. |
| SAFE-04 | 04-07, 10, 12, 13, 15 | ✓ SATISFIED | Retry/ambiguity/lifecycle checks pass. |
| SAFE-05 | 03, 10, 12, 13 | ✓ SATISFIED | Client/authority checks pass. |
| SAFE-06 | 10, 13, 14 | ✗ BLOCKED | Direct docs are correct, but bounded acceptance misleadingly claims docs/spec proof. |

### Test Quality Audit

| Test Area | Verdict |
|---|---|
| Full matrix and focused SDK suites | ✓ Active, behavioral/value assertions pass; no disabled or circular tests. |
| Docs/type/spec tests | ✓ Pass when invoked directly. |
| Bounded selection | ✗ BLOCKER — eleven unstable location selectors, no identity/count assertion. |
| Bounded orchestration | ✗ BLOCKER — active docs proof is omitted while receipt certifies it. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `bin/phase32_contract_proof.sh` | 216-257 | SAFE-06 docs/spec claim without docs proof | 🛑 BLOCKER (CR-01) | Misleading bounded acceptance receipt. |
| `bin/phase32_compatibility.sh` | 48-60 | Unvalidated `file:line` test selection | 🛑 BLOCKER (WR-02) | Wrong test can certify a required proof. |
| `bin/phase32_contract_proof.sh` | 276-318 | Termination self-test not in normal proof paths | ⚠️ WARNING (WR-01) | Direct probe passes today, but normal regression coverage is incomplete. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker exists in changed implementation files. The `placeholder` wording in the seam guide documents a deliberate module, not a stub.

### Decision Coverage

All 19 trackable `32-CONTEXT.md` decisions are honored by shipped artifacts (non-blocking).

### Advisory (New Scope, Unevidenced)

None. Both blockers are evidenced regressions, not unevidenced new-scope observations.

### Human Verification Required

N/A — SDK/foundation phase; all evaluated runtime behavior has automated evidence. The remaining work is implementation repair, not manual UAT.

### Gaps Summary

The original receipt-lifecycle, timing, and duplicate-retry defects are fixed. Phase 32 still cannot pass: the bounded contract proof labels unrun docs/spec proof as passing and lets ExUnit silently substitute an unrelated test for a missing line selector. Neither issue is specifically deferred to a later roadmap phase.

---

_Verified: 2026-09-11T03:43:31Z_
_Verifier: the agent (gsd-verifier)_
