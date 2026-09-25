# Phase 32 Multi-Source Coverage Audit

SOURCE | ID | Feature/Requirement | Plan | Status | Notes
--- | --- | --- | --- | --- | ---
GOAL | — | Consumers avoid known Req advisories, disclosure, unsafe replay, invalid clients, and misleading guidance | 01-11 | COVERED | Dependency proof precedes behavior; the final contract/matrix closes every boundary.
REQ | SAFE-01 | Secure compatibility-tested Req and clean Hex audit | 01, 02, 11, 10 | COVERED | Isolated locks, bounded fixture families, remaining seams, full matrix, and final repeat.
REQ | SAFE-02 | Allowlisted non-secret telemetry | 08, 10 | COVERED | Exact keys, attempt pairing, recursive canaries, concurrency, and docs.
REQ | SAFE-03 | Secret-bearing Inspect redaction | 03, 04, 09, 10 | COVERED | Client/Error plus four provider value types and exhaustive inventory.
REQ | SAFE-04 | Bounded reads; no blind mutation replay; reconciliation | 04, 05, 06, 07, 10 | COVERED | Central policy followed by every resource and pagination call site.
REQ | SAFE-05 | Client construction validation with custom MockServer compatibility | 03, 10 | COVERED | Complete constructor table, custom dispatch, and documented truth.
REQ | SAFE-06 | Runtime/docs/types/examples/migration agreement | 03-10 | COVERED | Owning plans update module docs/types; Plan 10 mechanically compares compiled docs/types to runtime tables and proves concurrency/interruption acceptance.
RESEARCH | — | Isolated Req/root/demo lock migration | 01 | COVERED | No SDK behavior change is mixed into dependency resolution.
RESEARCH | — | Req 0.7 adapter migration and D-03 matrix | 01, 02, 11, 10 | COVERED | Plan 02 owns eight homogeneous resource fixtures; Plan 11 owns four integration seams and the repeatable runner; Plan 10 performs the final rerun.
RESEARCH | — | Constructor decision table and secret-safe failures | 03 | COVERED | URI scheme/host/userinfo and environment coherence before Req construction.
RESEARCH | — | GET/HEAD exact transient set, four attempts, 60000 ms 429 cap | 04 | COVERED | Deterministic no-sleep attempt and parallel-isolation matrix.
RESEARCH | — | Remove all unsupported idempotency options | 04-07, 10 | COVERED | Central parser, resource types/tests, examples, and migration guidance.
RESEARCH | — | Mutation ambiguity in existing Paddle.Error family | 04-07, 10 | COVERED | Safe fields/guidance, preserved tuple, every mutating call site, and docs/types.
RESEARCH | — | Static operation/route context across all request modules | 04-08 | COVERED | COVERAGE.md enumerates every resource; dynamic IDs/cursors remain dispatch-only.
RESEARCH | — | Attempt-scoped allowlisted telemetry | 08 | COVERED | Terminal steps precede retry and exact event topology remains fixed.
RESEARCH | — | Deny-by-default inspection and public raw_data inventory | 03, 04, 09 | COVERED | Total projections and provider-hydrated recursive canaries.
RESEARCH | — | Evidence-honest public contract and final compatibility rerun | 10 | COVERED | Unit/mock/package/downstream/sandbox/hosted/live tiers remain distinct.
CONTEXT | D-01 | Req ~> 0.7.4 secure floor | 01, 10 | COVERED | Manifest, generated locks, audit, and public guidance.
CONTEXT | D-02 | Dependency/lock migration isolated first | 01, 02, 11 | COVERED | Plan 01 is dependency-only; Plans 02/11 prove compatibility before behavior waves.
CONTEXT | D-03 | Supported compatibility matrix | 11, 10 | COVERED | Plan 11 creates initial atomic acceptance; Plan 10 proves isolated concurrency/interruption and final two-run certification.
CONTEXT | D-04 | Built-in mix hex.audit; migration guidance; no release work | 01, 11, 10 | COVERED | No duplicate scanner, hosted authority, or publication task.
CONTEXT | D-05 | Preserve three telemetry event names | 08, 10 | COVERED | Schema migrates while topology stays fixed and documented.
CONTEXT | D-06 | Strict low-cardinality telemetry allowlist | 05-08, 10 | COVERED | Static labels at every resource plus exact-key and forbidden-term tests.
CONTEXT | D-07 | Inventory every secret-bearing public value | 03, 04, 09 | COVERED | Complete raw_data source inventory catches additions.
CONTEXT | D-08 | Stable marker and whole raw_data redaction | 03, 04, 09 | COVERED | Stored values stay unchanged.
CONTEXT | D-09 | Unique recursive canary tests | 08, 09 | COVERED | Telemetry and Inspect outcomes, including concurrency.
CONTEXT | D-10 | Safe-read-only retries; mutation one attempt | 04-07 | COVERED | Central enforcement plus every request call site.
CONTEXT | D-11 | Three retries/four attempts and finite Retry-After cap | 04, 10 | COVERED | Research-selected 60000 ms 429 cap and docs.
CONTEXT | D-12 | Retry option restricts only; invalid enabling fails | 04, 10 | COVERED | Pre-dispatch validation matrix and migration guidance.
CONTEXT | D-13 | Retain idempotency only with proof; otherwise remove | 04-07, 10 | COVERED | Research found no supported operation, so removal is exhaustive.
CONTEXT | D-14 | Preserve Paddle.Error tuple and add reconciliation | 04-07, 10 | COVERED | Safe operation/resource/request correlation only.
CONTEXT | D-15 | Explicit client/new! with validated key/options/env/URL | 03, 10 | COVERED | No global application configuration or credential regex.
CONTEXT | D-16 | Base-URL-only custom inference and coherence rules | 03, 10 | COVERED | Adapter-backed custom tracer and documented table.
CONTEXT | D-17 | Immediate secret-safe ArgumentError | 03, 10 | COVERED | Rejected-value canaries and no-dispatch assertions.
CONTEXT | D-18 | Update all public/module docs/types/examples/changelog/migration | 03-10 | COVERED | Runtime type changes and Plan 10 mechanical docs assertions.
CONTEXT | D-19 | Distinguish evidence tiers; no mock/header overclaim | 11, 10 | COVERED | Matrix evidence remains local/package/downstream; positive ladder, negative guard, and phase-boundary exclusions are mechanically tested.

## Spec-less fallback accounting

- Edge probe surfaced 8 items. Authored: three flagged unclassified assumptions (SAFE-01 Plan 01, SAFE-05 Plan 03, SAFE-03 Plan 09) plus five explicit truths (SAFE-04 idempotency and concurrency Plan 04, SAFE-02 concurrency Plan 08, SAFE-06 idempotency and concurrency Plan 10). Equality: 8 surfaced = 8 authored/flagged.
- Prohibition recall retained exactly two bespoke non-canonical items per requirement: SAFE-01 Plan 01, SAFE-05 Plan 03, SAFE-04 Plan 04, SAFE-02 Plan 08, SAFE-03 Plan 09, SAFE-06 Plan 10. All 12 are descriptor-less `status: unresolved`, `verification: null`, `flagged_unverified: true`; no `check_*` field was fabricated. Equality: 12 retained = 12 authored.
- Assumption-delta returned `detected:true` for `custom`. Plan 03 records `no-change` with primary noun `environment`: a validated noncanonical base URL derives `:custom` per D-15/D-16; it does not create another client-state model.
- Schema-gate scan found no Prisma/Drizzle/TypeORM/Sequelize/Ecto migration or other ORM schema path in phase scope; no schema-push task applies.
- API coverage is full-coverage-default for the existing outbound SDK surface. `COVERAGE.md` names every request-owning resource/shared transport row and gives a reason for every OPT-OUT; no endpoint or capability breadth is added.
- `init.plan-phase 32` surfaced Phase 31 Node-based planning/repository verify commands. Phase 32's Elixir dependency/SDK build and test story does not match those commands, so none is re-derived or falsely reused; all new commands are grounded at the tracked root/demo manifests or at paths created by an earlier Phase 32 plan.

No source item is missing. Deferred hosted-CI authority (Phase 33), publication/release gating (Phase 34), new Paddle API breadth, live provider mutation, and repository cleanup are exclusions rather than gaps.
