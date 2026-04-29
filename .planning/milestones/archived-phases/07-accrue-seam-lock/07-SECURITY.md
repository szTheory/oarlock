---
phase: 07
slug: accrue-seam-lock
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-29
---

# Phase 07 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Phase 07 is a contract/seam lockdown phase. No new endpoints, auth paths, or data flows were introduced. Threats are about contract ossification, scope creep, and accidental docs surface leakage.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| adapter-backed test → public seam | The seam test is executable proof of what consumers can safely depend on | Locked tuple/struct contract assertions |
| webhook raw body → parsed event struct | Raw provider payload crosses into a typed `%Paddle.Event{}` envelope and must not promote opaque nested keys | Envelope-level (`event_id`, `event_type`, `occurred_at`, `notification_id`) and `:raw_data` presence only |
| focused support tests → end-to-end seam test | Contract coverage stays partitioned so seam test does not imply broader public surface | Support-type assertions remain in their focused tests |
| source modules → generated docs | ExDoc converts source metadata into the published public contract; leaked modules become accidental surface area | `@moduledoc false` boundary on `Paddle.Http`, `Paddle.Http.Telemetry`, `Paddle` |
| guide text → consumer expectations | The seam guide is the canonical contract; inaccurate vocabulary misleads consumers | `locked` / `additive` / `opaque` taxonomy |
| support types → end-user API surface | Support types must be documented explicitly without promoting `%Paddle.Client{}` internals | `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, `%Paddle.Error{}` |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-07-01 | T (Tampering) | `test/paddle/seam_test.exs` | mitigate | Six `assert is_map/1` escape-hatch checks replace full payload equality (verified at lines 45, 76, 102, 125, 144, 186); zero matches for forbidden equality patterns `== customer_payload(`, `== address_payload(`, `event.raw_data[`, `scheduled_change.raw_data ==`, `checkout.raw_data ==` | closed |
| T-07-02 | I (Information Disclosure) | webhook event data handling | mitigate | `%Paddle.Event{}` match in `test/paddle/seam_test.exs:138-142` is restricted to four locked envelope fields (`event_id`, `event_type`, `notification_id`, plus the dropped nested `data:` block); flow continuation derives subscription ID from `fetched_transaction.subscription_id` (line 156), not from `event.data["subscription_id"]`; `assert is_map(event.raw_data)` at line 144 keeps contents opaque | closed |
| T-07-03 | D (Denial of Service / scope) | end-to-end seam scope | mitigate | `rg -n 'Paddle\.Client\.new!\|Paddle\.Page\|Page\.next_cursor\|%Paddle\.Error\{\|pause(\|resume(\|update('` against `test/paddle/seam_test.exs` returns zero matches; support-type coverage continues in `test/paddle/client_test.exs`, `test/paddle/page_test.exs`, `test/paddle/error_test.exs` | closed |
| T-07-04 | R (Repudiation / fidelity) | contract-proof fidelity | mitigate | `mix test test/paddle/seam_test.exs test/paddle/client_test.exs test/paddle/page_test.exs test/paddle/error_test.exs` exits 0 (9 tests, 0 failures); seam test alone also passes per 07-01-SUMMARY.md verification | closed |
| T-07-05 | E (Elevation / scope creep) | accidental seam expansion | mitigate | Seam test contains exactly the seven locked operation families (8 call sites: `Paddle.Customers.create`, `Paddle.Customers.Addresses.create`, `Paddle.Transactions.create`, `Paddle.Transactions.get`, `Webhooks.verify_signature`, `Webhooks.parse_event`, `Paddle.Subscriptions.get`, `Paddle.Subscriptions.cancel` — `subscription_id` flows through both transaction get and subscriptions get); no new public functions or undocumented nested assertions | closed |
| T-07-06 | I (Information Disclosure) | generated ExDoc API reference | mitigate | `@moduledoc false` present at `lib/paddle/http.ex:2`, `lib/paddle/http/telemetry.ex:2`, `lib/paddle.ex:2`; `rg -n 'Paddle\.Http\|Paddle\.Http\.Telemetry\|^- \[Paddle\]' doc/api-reference.md` returns zero matches | closed |
| T-07-07 | T (Tampering / vocabulary) | `guides/accrue-seam.md` field tiers | mitigate | `rg -n '`raw`\|`not-planned`' guides/accrue-seam.md` returns zero matches; `opaque` appears 14 times, `locked` 42 times, `additive` 3 times; eight `:raw_data` rows are explicitly `locked` with notes that contents are `opaque` (lines 127, 134, 143, 150, 160, 167, 174, 182) | closed |
| T-07-08 | E (Elevation / boundary) | public seam boundary | mitigate | Boundary policy sentences present in `guides/accrue-seam.md:11-12` ("Only explicitly documented modules…", "undocumented internals may change without notice"); explicit exclusion of `Paddle.Http`, `Paddle.Internal.*`, `%Paddle.Client{}` internals (`:req`), placeholder `Paddle` root listed at lines 16-22; support types (`Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, `%Paddle.Error{}`) documented under "Support Types" section starting at line 82 | closed |
| T-07-09 | R (Repudiation / docs fidelity) | docs publication fidelity | mitigate | `doc/accrue-seam.html` PRESENT; `doc/api-reference.md` lists exactly 15 supported modules (`Paddle.Address`, `Paddle.Client`, `Paddle.Customer`, `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Event`, `Paddle.Page`, `Paddle.Subscription`, `Paddle.Subscription.ManagementUrls`, `Paddle.Subscription.ScheduledChange`, `Paddle.Subscriptions`, `Paddle.Transaction`, `Paddle.Transaction.Checkout`, `Paddle.Transactions`, `Paddle.Webhooks`) plus `Paddle.Error` exception; no leaked internal modules | closed |
| T-07-10 | D (Denial of Service / drift) | contract drift between guide and tests | mitigate | Plan 02 (Wave 1, guide) committed at `9e60340` before Plan 01 (Wave 2, seam test) was finalized at `614171d` per 07-01-SUMMARY.md and 07-02-SUMMARY.md; `mix.exs:12` wires the guide as ExDoc extra; seam test asserts only what the guide marks `locked` and treats every `opaque` field as presence-only via `is_map/1` | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|

No accepted risks.

---

## Unregistered Threat Flags

Both plan SUMMARY files (`07-01-SUMMARY.md` and `07-02-SUMMARY.md`) declare under `## Threat Flags`: "No new threat surface introduced." No new endpoints, auth paths, file access patterns, or schema changes were added. No unregistered flags.

Informational note on `mix docs` warning observed during Plan 02: `documentation references module "Paddle" but it is hidden` — this is the intended behavior; the guide deliberately names the hidden placeholder module to document its exclusion. `mix docs` exits 0 and does not emit any further warnings.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-29 | 10 | 10 | 0 | gsd-security-auditor (Claude Opus 4.7) |

---

## Verification Commands (re-runnable evidence)

```sh
# T-07-01 — six is_map escape-hatch checks present, equality patterns absent
rg -c 'assert is_map\(customer\.raw_data\)' test/paddle/seam_test.exs                                # → 1
rg -c 'assert is_map\(address\.raw_data\)' test/paddle/seam_test.exs                                 # → 1
rg -c 'assert is_map\(transaction\.checkout\.raw_data\)' test/paddle/seam_test.exs                   # → 1
rg -c 'assert is_map\(fetched_transaction\.checkout\.raw_data\)' test/paddle/seam_test.exs           # → 1
rg -c 'assert is_map\(event\.raw_data\)' test/paddle/seam_test.exs                                   # → 1
rg -c 'assert is_map\(canceled_subscription\.scheduled_change\.raw_data\)' test/paddle/seam_test.exs # → 1
rg -n '== customer_payload\(|== address_payload\(|event\.raw_data\[|scheduled_change\.raw_data ==|checkout\.raw_data ==' test/paddle/seam_test.exs  # → no matches

# T-07-03/05 — forbidden support-type and mutation patterns absent from seam test
rg -n 'Paddle\.Client\.new!|Paddle\.Page|Page\.next_cursor|%Paddle\.Error\{|pause\(|resume\(|update\(' test/paddle/seam_test.exs  # → no matches

# T-07-04 — combined run passes
mix test test/paddle/seam_test.exs test/paddle/client_test.exs test/paddle/page_test.exs test/paddle/error_test.exs  # → 9 tests, 0 failures

# T-07-06/09 — internal modules hidden, docs surface clean
rg -n '@moduledoc false' lib/paddle/http.ex lib/paddle/http/telemetry.ex lib/paddle.ex             # → 3 matches
rg -n 'Paddle\.Http|Paddle\.Http\.Telemetry|^- \[Paddle\]' doc/api-reference.md                    # → no matches
test -f doc/accrue-seam.html                                                                       # → exists

# T-07-07 — guide vocabulary
rg -n '`raw`|`not-planned`' guides/accrue-seam.md                                                   # → no matches
rg -n ':raw_data.*`locked`' guides/accrue-seam.md                                                   # → 8 matches

# T-07-08 — boundary policy and support types in guide
rg -n 'Only explicitly documented modules, functions, structs, and support types are supported|undocumented .* may change without notice' guides/accrue-seam.md  # → both present
rg -n 'Paddle\.Client\.new!/1|%Paddle\.Page\{|Paddle\.Page\.next_cursor/1|%Paddle\.Error\{' guides/accrue-seam.md  # → 21 matches

# T-07-10 — exclusion buckets present, guide is ExDoc extra
rg -n 'Out of scope for the current 0\.x seam|Intentionally excluded from core' guides/accrue-seam.md  # → exactly 2
rg -n 'extras: \["guides/accrue-seam.md"\]' mix.exs                                                  # → 1 match
```

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log (none)
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-29
