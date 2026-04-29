---
phase: 07-accrue-seam-lock
verified: 2026-04-29T19:25:00Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  is_re_verification: false
---

# Phase 07: Accrue Seam Lock — Verification Report

**Phase Goal:** "Lock the Accrue-facing seam for v1.1" — both SEAM-01 (executable contract test) and SEAM-02 (canonical seam guide + sealed docs surface).
**Verified:** 2026-04-29T19:25:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

Phase 07 delivers exactly what its goal demands. SEAM-01 lands an adapter-backed end-to-end seam test (`test/paddle/seam_test.exs`) that drives the full documented Accrue flow without live network access and freezes only the documented locked surface plus `is_map/1` escape-hatch presence checks. SEAM-02 publishes `guides/accrue-seam.md` as the canonical contract using the locked/additive/opaque vocabulary, hides `Paddle`, `Paddle.Http`, and `Paddle.Http.Telemetry` from `doc/api-reference.md` via `@moduledoc false`, and produces `doc/accrue-seam.html`. All five plan commits (`9e60340`, `49f8f39`, `33d52c3`, `614171d`, `670123a`) are present in `git log`. The seam test passes, the combined seam + support-type tests pass, and the full 111-test suite is green with `mix compile --warnings-as-errors`.

### Observable Truths

| # | Truth (source plan) | Status | Evidence |
| - | ------------------- | ------ | -------- |
| 1 | SEAM-01 T1: Seam test proves the documented customer → address → transaction create/get → webhook verify/parse → subscription get → cancel flow without live network access. | VERIFIED | `test/paddle/seam_test.exs` lines 38-184: 8 sequenced assertions calling `Paddle.Customers.create`, `Paddle.Customers.Addresses.create`, `Paddle.Transactions.create`, `Paddle.Transactions.get`, `Webhooks.verify_signature`, `Webhooks.parse_event`, `Paddle.Subscriptions.get`, `Paddle.Subscriptions.cancel`. Six per-step `client_with_adapter` closures (lines 25, 48, 79, 105, 147, 165) wire `Req.new(adapter: ...)` so no socket is opened. `mix test test/paddle/seam_test.exs` passes (1 test, 0 failures). |
| 2 | SEAM-01 T2: Seam test asserts only the closed public tuple/struct boundary and documented locked fields, not full payload equality or undocumented nested keys. | VERIFIED | `grep '== customer_payload\(\|== address_payload\(\|event\.raw_data\[\|scheduled_change\.raw_data ==\|checkout\.raw_data =='` returns 0 matches in `test/paddle/seam_test.exs`. Each return is matched at the `{:ok, %Struct{...}}` boundary plus typed nested struct heads (`%Checkout{url: ...}`, `%ManagementUrls{...}`, `%ScheduledChange{action: ...}`). |
| 3 | SEAM-01 T3: Seam test keeps `:raw_data` as a documented escape hatch by proving presence, while leaving its nested contents opaque. | VERIFIED | All six required `is_map/1` assertions present exactly once: `customer.raw_data` (line 45), `address.raw_data` (line 76), `transaction.checkout.raw_data` (line 102), `fetched_transaction.checkout.raw_data` (line 125), `event.raw_data` (line 144), `canceled_subscription.scheduled_change.raw_data` (line 186). |
| 4 | SEAM-01 T4: Support-type coverage stays in the existing focused tests instead of bloating the end-to-end seam path. | VERIFIED | `grep 'Paddle\.Client\.new!\|Paddle\.Page\|Page\.next_cursor\|%Paddle\.Error\{\|pause(\|resume(\|update('` returns 0 matches in `test/paddle/seam_test.exs`. Combined run `mix test test/paddle/seam_test.exs test/paddle/client_test.exs test/paddle/page_test.exs test/paddle/error_test.exs` passes 9/9. |
| 5 | SEAM-02 T1: The Accrue seam guide is the canonical published contract and uses the locked vocabulary `locked`, `additive`, and `opaque`. | VERIFIED | `guides/accrue-seam.md` Stability Vocabulary section (lines 24-39) defines all three tiers exactly. `grep -c` results: `locked` 42 matches, `additive` 3 matches, `opaque` 14 matches. Deprecated `` `raw` `` and `` `not-planned` `` tier vocabulary returns 0 matches. |
| 6 | SEAM-02 T2: Guide explicitly enumerates the closed public seam: entry modules, support types, locked structs, and exclusion buckets. | VERIFIED | Public Modules section (lines 41-79) lists `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, `Paddle.Webhooks`. Support Types section (lines 81-118) names `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, `%Paddle.Error{}` (21 mentions across guide). Both required exclusion buckets present exactly once: "Out of scope for the current 0.x seam" (line 184) and "Intentionally excluded from core" (line 198). Boundary-policy phrases match: "Only explicitly documented modules, functions, structs, and support types are supported" (line 11) and "undocumented internals may change without notice" (line 12). |
| 7 | SEAM-02 T3: Generated docs publish the seam guide while excluding internal modules and the placeholder root `Paddle` module from the consumer API surface. | VERIFIED | `doc/accrue-seam.html` exists (32,666 bytes) with `<h1>Accrue Seam Contract</h1>` rendered. `doc/api-reference.md` contains exactly 15 supported public-module entries plus `Paddle.Error` exception (16 total). `grep 'Paddle\.Http\|Paddle\.Http\.Telemetry\|^- \[Paddle\]' doc/api-reference.md` returns 0 matches. `mix.exs` retains `extras: ["guides/accrue-seam.md"]` (line 12). |
| 8 | SEAM-02 T4: Guide documents `:raw_data` as a locked escape hatch whose contents are opaque, not as an additive field. | VERIFIED | 8 `:raw_data` rows tagged `locked` across all struct tables (Customer 127, Address 134, Transaction 143, Checkout 150, Subscription 160, ScheduledChange 167, ManagementUrls 174, Event 182). Stability Vocabulary section (line 38) explicitly states "`:raw_data` field on each locked struct is itself `locked`; only the contents of `:raw_data` are `opaque`." |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `test/paddle/seam_test.exs` | Semantic contract test for the Accrue-facing seam | VERIFIED | 318 lines, single `Paddle.SeamTest` module, `async: false`, one `test "locks the Accrue seam across the customer, checkout, webhook, and subscription flow"` driving 8 public calls; six `Req`-adapter closures gate request method/path/body; passes deterministically. |
| `guides/accrue-seam.md` | Canonical consumer contract guide | VERIFIED | 207 lines, exact structure: Boundary Policy, Stability Vocabulary, Public Modules, Support Types, Locked Structs, two exclusion buckets. |
| `lib/paddle/http.ex` | Internal transport module hidden from published docs | VERIFIED | Line 2: `@moduledoc false`. Public functions `request/4` and `build_struct/2` retained; runtime untouched (full suite passes). |
| `lib/paddle/http/telemetry.ex` | Internal telemetry hook module hidden from published docs | VERIFIED | Line 2: `@moduledoc false`. `attach/1` and three telemetry steps unchanged. |
| `lib/paddle.ex` | Placeholder root module hidden from published docs | VERIFIED | Line 2: `@moduledoc false`; `hello/0` carries `@doc false` (line 4). Function still returns `:world`; existing doctest passes. |
| `doc/accrue-seam.html` (generated) | Published seam guide | VERIFIED | File exists; contains `<title>Accrue Seam Contract — paddle v0.1.0</title>` and `<h1>Accrue Seam Contract</h1>`. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `test/paddle/seam_test.exs` | `guides/accrue-seam.md` | Guide-defined public modules, field tiers, support boundaries | WIRED | Test exercises only the 5 public entry modules enumerated in the guide; every typed-struct match maps to a guide-tagged `locked` row; every `:raw_data` assertion uses `is_map/1` matching the guide's "locked field, opaque contents" policy. |
| `test/paddle/seam_test.exs` | `lib/paddle/webhooks.ex` | `verify_signature/4` and `parse_event/1` remain pure tuple-returning functions | WIRED | Lines 130-142 call `Webhooks.verify_signature(@transaction_completed_body, header, @seam_secret, now: @seam_timestamp)` and `Webhooks.parse_event(@transaction_completed_body)`, both asserting the exact `{:ok, ...}` tuple shapes the guide locks. Pure (no client/adapter). |
| `guides/accrue-seam.md` | `doc/accrue-seam.html` | ExDoc extras publication wired through `mix.exs` | WIRED | `mix.exs:12` `extras: ["guides/accrue-seam.md"]` present; `doc/accrue-seam.html` regenerated with the published title "Accrue Seam Contract". |
| `lib/paddle/http.ex` (and siblings) | `doc/api-reference.md` | `@moduledoc false` suppresses internal modules from generated API reference | WIRED | All 3 modules tagged; regenerated `doc/api-reference.md` shows neither `Paddle`, `Paddle.Http`, nor `Paddle.Http.Telemetry`. |

### Data-Flow Trace (Level 4)

Phase 07 produces a contract test, a guide, generated docs, and 3 `@moduledoc false` annotations. None of the artifacts render dynamic data at runtime, so Level 4 trace is N/A — the seam test itself IS the data-flow trace for the public seam, and it passes.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Seam test executes documented Accrue flow without network | `mix test test/paddle/seam_test.exs` | 1 test, 0 failures | PASS |
| Seam + focused support-type tests still pass together (narrow seam) | `mix test test/paddle/seam_test.exs test/paddle/client_test.exs test/paddle/page_test.exs test/paddle/error_test.exs` | 9 tests, 0 failures | PASS |
| Full suite green (no regressions) | `mix test` | 111 tests, 0 failures | PASS |
| Clean compile | `mix compile --warnings-as-errors` | exit 0 | PASS |
| `is_map(...)` escape-hatch assertions present 6 times in seam test | `grep -c "assert is_map(...)"` for each of the 6 documented hatches | 1 each (6/6) | PASS |
| No fixture-equality assertions in seam test | `grep '== customer_payload(\|== address_payload(\|event.raw_data[\|scheduled_change.raw_data ==\|checkout.raw_data =='` | 0 matches | PASS |
| No support-type creep in seam test | `grep 'Paddle\.Client\.new!\|Paddle\.Page\|Page\.next_cursor\|%Paddle\.Error{\|pause(\|resume(\|update('` | 0 matches | PASS |
| Guide vocabulary correct | `grep -c "locked\|additive\|opaque"` and absence of `` `raw` ``/`` `not-planned` `` | locked 42, additive 3, opaque 14, deprecated tiers 0 | PASS |
| Both exclusion buckets present exactly once | `grep "Out of scope for the current 0\.x seam\|Intentionally excluded from core"` | 2 matches | PASS |
| All 3 internal modules hidden | `grep '@moduledoc false' lib/paddle/http.ex lib/paddle/http/telemetry.ex lib/paddle.ex` | 3 matches | PASS |
| API reference excludes internals | `grep 'Paddle\.Http\|Paddle\.Http\.Telemetry\|^- \[Paddle\]' doc/api-reference.md` | 0 matches | PASS |
| API reference lists exactly 15 public modules | `grep -c '^- \[Paddle\.' doc/api-reference.md` | 15 | PASS |
| Generated guide HTML present | `test -f doc/accrue-seam.html` | exists, 32,666 bytes, title rendered | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SEAM-01 | 07-01 | Lock the end-to-end Accrue seam with an adapter-backed contract test covering customer creation, address creation, transaction create/get, webhook verify/parse, subscription get, and subscription cancel. | SATISFIED | `test/paddle/seam_test.exs` proves all 8 operations adapter-backed; passes deterministically; `.planning/REQUIREMENTS.md` already marked `[x]`. Truths 1-4 above. |
| SEAM-02 | 07-02 | Publish a consumer-facing seam contract guide enumerating public modules, locked structs, field tiers, and explicitly deferred surfaces. | SATISFIED | `guides/accrue-seam.md` is the canonical guide; `doc/accrue-seam.html` published; internal modules hidden; `.planning/REQUIREMENTS.md` already marked `[x]`. Truths 5-8 above. |

No orphaned requirements: phase 7 maps SEAM-01 + SEAM-02 in ROADMAP, and both plans declare them in `requirements:` frontmatter. Both are checked off in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

Scoped scan over phase 07's 5 modified files (`test/paddle/seam_test.exs`, `guides/accrue-seam.md`, `lib/paddle.ex`, `lib/paddle/http.ex`, `lib/paddle/http/telemetry.ex`). No TODO/FIXME/XXX/HACK/PLACEHOLDER markers. No empty stub returns (`return null` etc.) — `Paddle.hello/0` returning `:world` is the legitimate placeholder behavior intentionally hidden via `@doc false`. No console-log-only handlers. The seam test's `defp customer_payload`/`address_payload`/`transaction_payload`/`subscription_payload`/`subscription_payload_canceled` helpers are fixture builders for adapter responses — not stubs of production code paths.

### Quality Observations from Code Review (07-REVIEW.md — 0 blockers, 6 warnings)

The published code review flags 0 blockers and 6 warnings. Per the verification scope ("note them in the verification report's quality observations but do not treat warnings as gap-causing unless they directly contradict a `must_haves.truth`"), each warning was checked against the plans' truths. None contradicts a must-have truth, but they are documented here for transparency:

- **WR-01** — Seam test under-asserts locked struct fields (e.g., `:status`, `:occurred_at`, `:created_at` not bound). Does not contradict SEAM-01 truth 2 ("asserts only the closed public tuple/struct boundary and documented locked fields") because the truth requires assertions to *be* on the locked surface, not to *cover* every locked field. The seam test pins a sample of the locked surface; per-module test files own per-field coverage.
- **WR-02** — Header comment says "pins the full oarlock surface that Accrue targets" but seven public functions (`Paddle.Customers.get/2`, `Customers.update/3`, `Addresses.get/3`, `Addresses.list/3`, `Addresses.update/4`, `Subscriptions.list/2`, `Subscriptions.cancel_immediately/2`) are not exercised. SEAM-01 plan scope is limited to the seven-step Accrue happy path (D-02), so this is a documentation-clarity issue, not a goal-achievement gap.
- **WR-03** — `Paddle.Page.next_cursor/1` is not invoked in the seam test. Plan SEAM-01 truth 4 explicitly keeps support-type coverage out of the seam path; coverage lives in `test/paddle/page_test.exs` and `test/paddle/subscriptions_test.exs`.
- **WR-04** — `subscription_payload_canceled/0` keeps `status: "active"` (deferred-cancel branch). Plan SEAM-01 only locks the `cancel/2` path with `effective_from: "next_billing_period"`; immediate cancel is per-module-test territory.
- **WR-05** — Public consumer modules (`Paddle.Customers`, etc.) carry no `@moduledoc` strings. SEAM-02 truth 3 only requires *internal* modules to be hidden; it does not require *public* modules to carry inline docstrings. Quality concern, not a gap.
- **WR-06** — Guide describes `Paddle.Page.next_cursor/1` as returning a "cursor string" while the implementation forwards a relative URL. This is a documentation-precision flag against `guides/accrue-seam.md` line 108. Does not contradict any phase-07 must-have truth (SEAM-02 truth 1-4 do not cover precise wording of the next_cursor description). Worth fixing in a follow-up; not gap-causing here.

The `mix docs` informational warning ("documentation references module 'Paddle' but it is hidden") is intentional — the guide explicitly names the hidden placeholder root module by design (cf. `guides/accrue-seam.md` line 20).

### Human Verification Required

None. Every must-have truth is programmatically verified via grep + behavioral spot-checks (test runs, mix docs output, generated `doc/api-reference.md` inspection). Visual rendering of `doc/accrue-seam.html` is optional polish; the structural assertions confirm the guide is published with the correct title and the API reference excludes the right modules.

### Gaps Summary

No gaps blocking the phase goal. SEAM-01 and SEAM-02 are both fully delivered and locked in by code, tests, the canonical guide, and the regenerated docs surface. The 6 code-review warnings flag legitimate quality observations (especially WR-01 — sample-vs-pin coverage and WR-06 — next_cursor wording) that the team should consider addressing in a follow-up backlog item, but they do not contradict any plan-defined must-have truth and the verification-scope instruction explicitly excludes them from being treated as gap-causing.

---

_Verified: 2026-04-29T19:25:00Z_
_Verifier: Claude (gsd-verifier)_
