---
phase: 32-dependency-sdk-trust-boundary
verified: 2026-09-25T21:35:05Z
status: passed
score: 11/11 must-haves verified
covered_files: [".planning/phases/32-dependency-sdk-trust-boundary/32-01-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-01-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-02-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-02-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-03-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-03-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-04-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-04-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-05-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-05-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-06-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-06-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-07-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-07-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-08-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-08-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-09-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-09-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-10-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-10-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-11-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-11-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-12-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-12-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-13-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-13-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-14-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-14-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-15-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-15-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-16-PLAN.md",".planning/phases/32-dependency-sdk-trust-boundary/32-16-SUMMARY.md",".planning/phases/32-dependency-sdk-trust-boundary/32-REVIEW.md",".planning/phases/32-dependency-sdk-trust-boundary/deferred-items.md",".tool-versions","CHANGELOG.md","README.md","bin/phase32_compatibility.sh","bin/phase32_contract_proof.sh","demo/README.md","demo/mix.lock","guides/accrue-seam.md","guides/getting-started.md","guides/telemetry.md","lib/paddle/adjustments.ex","lib/paddle/client.ex","lib/paddle/customers.ex","lib/paddle/customers/addresses.ex","lib/paddle/customers/portal_sessions.ex","lib/paddle/error.ex","lib/paddle/events.ex","lib/paddle/http.ex","lib/paddle/http/telemetry.ex","lib/paddle/internal/pagination.ex","lib/paddle/notification_setting.ex","lib/paddle/notification_settings.ex","lib/paddle/portal_session.ex","lib/paddle/portal_sessions.ex","lib/paddle/prices.ex","lib/paddle/products.ex","lib/paddle/subscription/management_urls.ex","lib/paddle/subscriptions.ex","lib/paddle/transaction/checkout.ex","lib/paddle/transactions.ex","mix.exs","mix.lock","test/paddle/adjustments_test.exs","test/paddle/client_test.exs","test/paddle/customers/addresses_test.exs","test/paddle/customers/portal_sessions_test.exs","test/paddle/customers_test.exs","test/paddle/error_test.exs","test/paddle/events_test.exs","test/paddle/http/telemetry_test.exs","test/paddle/http_test.exs","test/paddle/inspection_safety_test.exs","test/paddle/notification_settings_test.exs","test/paddle/portal_session_test.exs","test/paddle/prices_test.exs","test/paddle/products_test.exs","test/paddle/seam_test.exs","test/paddle/subscriptions_test.exs","test/paddle/transactions_test.exs","test/support/phase32_proof_formatter.ex","test/test_helper.exs"]
covered_digest: "v1:sha256:4619c4a9c80aec54382bfb5cf48363e39ff1a914e8112c9e6eb7cb1ec55b9a67"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/11
  gaps_closed:
    - "Bounded SAFE-06 receipt executes isolated docs build and exactly three docs/spec proofs before success."
    - "Bounded compatibility proof selects and validates exact semantic test identities instead of unstable source locations."
  gaps_remaining: []
  regressions: []
advisory: []
---

# Phase 32: Dependency & SDK Trust Boundary Verification Report

**Phase Goal:** SDK consumers can use oarlock without known Req advisories, credential disclosure, unsafe mutation replay, invalid client state, or misleading contract guidance.
**Verified:** 2026-09-25T21:35:05Z
**Status:** passed
**Re-verification:** Yes — after Plan 32-16 gap closure

## Goal Achievement

The five roadmap success criteria and both carried-forward verification gaps are checked below. The nine truths that passed the 2026-09-11 verification received regression checks; the two failed truths received full artifact, wiring, and runtime-evidence checks. Plan 32-16's three task contracts are also checked in the final two rows and in the linked artifact/test tables.

**Current evidence replay (2026-09-25T21:35:05Z):** `node $HOME/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 30 -- env ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh --verify` completed successfully twice in succession (26.5s and 22.7s). Both runs passed 14 tagged tests with zero failures, the isolated docs build and exactly three docs/spec proofs, compatibility receipt self-tests, online Hex audit, receipt and drift gates; SAFE-01 through SAFE-06 passed and a local receipt was emitted. An initial cold run reached the same proof output but the outer wrapper returned 124 at 30s during compilation; the following two full invocations passed within the bound. Each invocation printed a tar warning because the already-deleted `.planning/HANDOFF.json` path remains in Git's tracked path list; the isolated input manifests, proof gates, and receipts nevertheless completed successfully. This bounded replay does not rerun or supersede the full 13-row compatibility matrix; the last full-matrix evidence remains historical evidence recorded in Plan 32-10.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Consumers install the compatibility-tested Req release, pass the supported matrix, and get a clean advisory audit. | ✓ VERIFIED | `mix.exs` requires `~> 0.7.4`; root and demo lockfiles resolve Req 0.7.4. The current bounded run emitted `online-hex-audit=passed` / “No retired packages found.” The prior 32-10 summary records two complete 13-row matrices, including root, demo, package, downstream Accrue, Dialyzer, and audit rows. Current runner still contains the full 13-row path; Plan 32-16 changes only bounded selection and explicitly retains it. The full matrix was not rerun in this verification, so its evidence remains dated provenance rather than a new hosted or current full-matrix claim. |
| 2 | Telemetry emits stable allowlisted facts while sensitive canaries remain absent. | ✓ VERIFIED | Current bounded run executed the telemetry allowlist proof. Existing telemetry implementation retains per-attempt start/terminal events, allowlisted metadata, concurrency/isolation and canary cases; the earlier verification's telemetry truth passed and the underlying runtime module was not changed by Plan 32-16. |
| 3 | Every inventoried public secret-bearing struct redacts promoted and nested provider secrets. | ✓ VERIFIED | The current bounded run executed `safe_03_recursive_inspect_redaction`; the named test iterates all six capability-bearing values and asserts promoted, nested, and transport canaries plus `[REDACTED]`. Inventory and Inspect protocol wiring remain in the production structs and `inspection_safety_test.exs`. |
| 4 | Safe reads retry within documented bounds; ambiguous mutations are not replayed and return reconciliation guidance. | ✓ VERIFIED | Current bounded run executed the ambiguity, retry-option, retry-decision, and address-stream proofs. Earlier passing behavior tests cover exactly-one mutation attempts, concurrent request-local retry state, bounded retryable statuses/transport errors, and guidance. Static route context and cursor forwarding remain wired through resources, `Paddle.Http`, and pagination. |
| 5 | Client construction rejects invalid state, custom MockServer URLs work, and public contract guidance matches behavior. | ✓ VERIFIED | Current bounded run executed custom-base-URL validation plus all three docs/spec proofs. Constructor validation and secret-safe errors remain implemented in `Paddle.Client`; earlier passing tests cover blank credentials, environment/options/URL validation, and pre-dispatch rejection. The docs builder and exact docs/spec proofs now run in isolated byte-identical readers before the bounded SAFE-06 verdict. |
| 6 | Bounded SAFE-06 evidence is earned by executed docs/spec checks. | ✓ VERIFIED | Two consecutive current `--verify` runs completed inside the 30-second wrapper with isolated docs build and exactly three docs/spec tests; receipt finalization follows both children and their identity/count checks. One earlier cold attempt timed out at the wrapper after compilation, so only the two subsequent exit-0 runs are counted as passes. |
| 7 | Bounded compatibility proof identifies the intended tests and verifies execution before publishing. | ✓ VERIFIED | Two current `--verify` runs each reported 14 tests, 0 failures. Runtime ID/module/name triples and exact counts matched; receipt reported `proof_count=14` and manifest digest `8e4bff6a39b9954acce1b1ddf8ac53294f8da12a5fa08410e7d60880fc0d3252`. Source manifest validates seven test files and rejects line selectors. |
| 8 | Bounded receipt lifecycle rejects interrupted/failed runs and completes within its deadline. | ✓ VERIFIED | `bin/phase32_contract_proof.sh --self-test-termination` passed. Two current `--verify` runs completed inside the 30-second wrapper and finalized only after child/audit/drift checks. |
| 9 | Subscription pause/resume lifecycle rejects duplicate retry options before normalization or dispatch regardless of option order. | ✓ VERIFIED | Plan 32-15's prior direct regression passed; the implementation and named test remain present and unmodified by Plan 32-16. |
| 10 | Caller-supplied request options cannot replace validated client transport authority. | ✓ VERIFIED | Plan 32-12's prior tests and verification passed; current HTTP/client authority guards remain present and unchanged in the gap-closure round. |
| 11 | Malformed error normalization and stream/docs guidance preserve the tested public contract. | ✓ VERIFIED | Current `mix test test/paddle/error_test.exs` passed 14/14; the bounded verifier also passed the selected ambiguity proof, address stream proof, and all three docs/spec contract tests. |

**Score:** 11/11 plan-level must-haves verified (the previous nine passing truths plus the two closed gaps); roadmap success criteria: 5/5. Behavior-unverified: 0.

### Historical gap provenance

The two findings below were real, observed blockers in the 2026-09-11 report. They are retained here as history and are closed based on current source and actual proof runs; the old report's failure evidence is not represented as current status.

| Historical finding | Original evidence | Current disposition |
|---|---|---|
| CR-01: bounded SAFE-06 claimed docs/spec proof without running the docs builder and docs assertions. | `run_verify` omitted both; old receipt printed SAFE-06 pass. | Closed. Isolated builder and exactly three tagged docs/spec tests now run, with child statuses, event identities, and exact count checked before finalization. Independent current proof passed. |
| WR-02: eleven `file:line` selectors could silently run unrelated ExUnit tests. | An out-of-range location selector exited zero after running an unrelated test. | Closed. Bounded selection uses canonical semantic IDs and runtime `{id,module,name}` event triples, exact manifest/count equality, and a deterministic digest. Self-tests reject swapped, missing, duplicate, unexpected, partial, excess, or failing evidence. |

### Required Artifacts

| Artifact group | Exists / substantive | Wired / evidence | Status |
|---|---|---|---|
| Req declarations and lockfiles (`mix.exs`, `mix.lock`, `demo/mix.lock`) | Present; Req 0.7.4 pinned | Root/demo compatibility paths and online audit remain separate gates | ✓ VERIFIED |
| SDK trust boundary (`lib/paddle/{client,http,error}.ex`, telemetry, resources, pagination, secret-bearing structs) | Production implementation and tests are substantive | Public resources route through validated client/HTTP, telemetry allowlist and Inspect protocols are exercised; previous passing truths get regression checks | ✓ VERIFIED |
| `bin/phase32_compatibility.sh` | Substantive full and bounded modes | Bounded mode validates source IDs, runtime triples, count, failures, receipt; full mode retains 13 rows | ✓ VERIFIED |
| `bin/phase32_contract_proof.sh` | Substantive isolated-reader orchestration | Isolated docs build and docs/spec test reader gate receipt completion; subordinate bounded receipt required | ✓ VERIFIED |
| `test/support/phase32_proof_formatter.ex`, `test/test_helper.exs` | Observer records only tagged static test identities when bounded events path is configured | Invoked by bounded runs only; normal tests retain ordinary behavior | ✓ VERIFIED |
| Requirement-linked tests and public docs/types/specs | Active tests; no disabled requirement tests found | Tests connect behavioral contracts to compiled/public documentation | ✓ VERIFIED |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Resource functions | `Paddle.Http.request/4` | validated client plus operation/route context | ✓ WIRED | Phase 32 runtime tests and module call paths exercise the SDK request seam. |
| Retry policy | Mutation/read dispatch | method-aware Req retry callback and normalized errors | ✓ WIRED | Retry-decision and ambiguous-mutation tests passed in the current bounded run; other prior-passed retry truths were regression-checked. |
| Telemetry hooks | Subscriber payloads | per-physical-attempt start and terminal events | ✓ WIRED | Current allowlist test passed; no request/response/body or raw customer data is emitted by the allowlist. |
| Public secret-bearing structs | `Inspect` output | total redacting implementations | ✓ WIRED | Current recursive inspection proof passed against the six-value inventory and canaries. |
| Bounded compatibility selector | ExUnit completed-test events | tag → formatter → canonical triples/count → receipt | ✓ WIRED | Actual 14-test execution passed exact manifest validation. |
| Bounded contract runner | Isolated docs/spec reader and compatibility receipt | wait for both readers and require successful child status before `VERIFY_COMPLETE` | ✓ WIRED | Current `--verify` passed, receipt finalized only after gates. |
| Full compatibility mode | root/demo/package/downstream/Dialyzer/audit checks | `--full` matrix runner | ✓ WIRED | Full 13-row implementation remains present and structurally separate; latest historical full-matrix evidence is from Plan 32-10. |

### Data-Flow Trace (Level 4)

SDK response values flow from Req responses into normalized `Paddle.Error` and resource structs; telemetry values are constructed from allowlisted operation metadata, status/error class, and attempt timing rather than carrying the request/response object. Secret-capable raw provider values remain stored but their Inspect projection is redacted. Bounded proof events contain only static `{proof_id, module, test_name}` identities; they do not capture fixtures, credentials, or test payloads. No dynamic UI rendering or database-backed artifact is part of this library phase.

| Artifact | Data source → sink | Produces real data | Status |
|---|---|---|---|
| SDK resource/error values | Req response → resource/error normalization | Yes | ✓ FLOWING |
| Telemetry | request-local allowlisted facts → telemetry subscriber | Yes; canary assertions passed | ✓ FLOWING |
| Inspect | stored public struct fields → redacting Inspect projection | Real struct values; secrets suppressed | ✓ CONTAINED |
| Proof receipt | actual ExUnit/doc child events and audit status → atomic receipt | Yes; exact identities/count and child completion checked | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Compatibility selector self-tests | `bash bin/phase32_compatibility.sh --self-test` | Passed | ✓ PASS |
| Receipt interruption handling | `bash bin/phase32_contract_proof.sh --self-test-termination` | Passed | ✓ PASS |
| Shell syntax and whitespace | `bash -n bin/phase32_compatibility.sh bin/phase32_contract_proof.sh && git diff --check` | Passed | ✓ PASS |
| Bounded full contract | `node $HOME/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 30 -- env ACCRUE_CHECKOUT=../accrue bin/phase32_contract_proof.sh --verify` | Passed; isolated docs/spec proof, 14 tests / 0 failures, online audit, receipt and drift gates; digest matches recorded repeated runs | ✓ PASS |
| Stable bounded manifest | receipt and runtime event manifest | `proof_count=14`; digest `8e4bff6a39b9954acce1b1ddf8ac53294f8da12a5fa08410e7d60880fc0d3252` | ✓ PASS |

The first in-sandbox `--verify` attempt could not start Mix because the sandbox denied Mix.PubSub's local TCP socket (`:eperm`). The same proof was then run with the required sandbox allowance and passed; this was an environment restriction, not an SDK/proof failure.

### Requirements Coverage

Every SAFE requirement is mapped to Phase 32 and claimed by one or more plans. No mapped SAFE requirement is orphaned. `REQUIREMENTS.md` currently marks SAFE-01 through SAFE-06 complete, with matching “Complete” traceability rows.

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| SAFE-01 | 01, 02, 10, 11, 13, 14, 16 | ✓ SATISFIED | Req 0.7.4 root/demo lock state; current online Hex audit and bounded dependency proof; Plan 32-10 records two complete 13-row full compatibility matrices. The current bounded receipt explicitly does not replace full-matrix or hosted CI authority. |
| SAFE-02 | 08, 10, 13, 16 | ✓ SATISFIED | Allowlisted per-attempt telemetry implementation and current selected allowlist/canary test; prior complete concurrency proof regression-checked. |
| SAFE-03 | 03, 09, 10, 13, 16 | ✓ SATISFIED | Six-value public inspection inventory, recursive canaries, and current selected redaction test. |
| SAFE-04 | 04–07, 10, 12, 13, 15, 16 | ✓ SATISFIED | Current ambiguous mutation, public retry option, deterministic retry, and stream proofs; prior resource/lifecycle matrix evidence remains valid. |
| SAFE-05 | 03, 10, 12, 13, 16 | ✓ SATISFIED | Client constructor guards and custom MockServer URL proof; prior validation-table and pre-dispatch rejection tests remain active. |
| SAFE-06 | 10, 13, 14, 16 | ✓ SATISFIED | Isolated docs build and three exact docs/spec test identities passed before current bounded receipt publication. |

### Test Quality Audit

| Test area | Active | Disabled | Circular oracle | Assertion level | Verdict |
|---|---:|---:|---:|---|---|
| SAFE-01 dependency/compatibility | Yes | 0 found | 0 found | Integration/status and audit | ✓ PASS |
| SAFE-02 telemetry | Yes | 0 found | 0 found | Exact payload, pairing, canary and concurrency assertions | ✓ PASS |
| SAFE-03 Inspect | Yes | 0 found | 0 found | Value-level canary absence and redaction marker | ✓ PASS |
| SAFE-04 retry/mutation | Yes | 0 found | 0 found | Attempt counts, exact result/context and retry decision table | ✓ PASS |
| SAFE-05 client validation | Yes | 0 found | 0 found | Valid/invalid input and no-dispatch assertions | ✓ PASS |
| SAFE-06 docs/spec and receipt | Yes | 0 found | 0 found | Exact compiled contract assertions and observed runtime manifest | ✓ PASS |

No disabled-test patterns were found under `test/`. No circular expected-value generator was found; the only `File.write!` match is the bounded proof formatter, which writes observed static runtime test identities and does not import or generate expected SDK values. Assertion coverage includes value and multi-step behavior checks, not existence-only claims.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|---|---|---|---|
| None in current phase implementation/test paths | No unreferenced `TBD`, `FIXME`, or `XXX`; no stub markers affecting SDK behavior | — | No blocking anti-pattern found |

### Decision Coverage

`node $HOME/.codex/gsd-core/bin/gsd-tools.cjs query check.decision-coverage-verify .planning/phases/32-dependency-sdk-trust-boundary .planning/phases/32-dependency-sdk-trust-boundary/32-CONTEXT.md` returned `honored: 19`, `total: 19`, `not_honored: []`. Plan 32-16 additionally preserves the bounded-local versus full/package/hosted/provider evidence tiers (D-19); its current docs contract proof passed. Decision coverage remains non-blocking.

### Advisory (New Scope, Unevidenced)

None. Re-verification found no new-scope blocker or unevidenced concern requiring advisory treatment.

### Human Verification Required

N/A — this is a library/infrastructure phase with no user-facing UI or external service UX. Runtime behaviors relevant to these acceptance criteria have automated evidence. This phase does not claim hosted CI, sandbox-provider, live-provider, publication, or release verification; those belong to later evidence tiers/phases.

### Deferred Items

No Phase 32 deferred items remain. Phase 31 cross-phase UAT debt remains in Phase 31's UAT/debug artifacts and is explicitly retained as required input to Phase 33 planning; it is not silently closed by this Phase 32 verification.

### Planning and provenance notes

- The 2026-09-11 `gaps_found` report remains the provenance for CR-01 and WR-02; it is superseded for current status by this report.
- `32-10-SUMMARY.md` records two complete 13-row full-matrix receipts. The current independent run was the bounded verifier, not a full matrix rerun. It also prints that bounded evidence does not replace full acceptance.
- `32-16-SUMMARY.md` reports two final successful bounded receipts with identical count/digest. This verifier independently reproduced one successful final bounded run.
- The current bounded replay passed after Plan 32-16. `ROADMAP.md` now lists all 16 Phase 32 plans as executed, and SAFE-01..06 traceability agrees with `REQUIREMENTS.md`. The full compatibility matrix remains dated evidence from Plan 32-10 and was not rerun in this replay.
- No evidence here establishes hosted CI green on an exact remote SHA, live Paddle/provider behavior, package publication, or release readiness.

---

_Verified: 2026-09-25T21:35:05Z_
_Verifier: the agent (gsd-verifier)_
