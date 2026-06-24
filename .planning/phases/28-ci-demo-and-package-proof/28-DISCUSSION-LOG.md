# Phase 28: CI, Demo, and Package Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-24
**Phase:** 28-CI, Demo, and Package Proof
**Areas discussed:** CI job shape, Demo CI strictness, Downstream package smoke, Optional dependency proof

---

## CI Job Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Extend existing jobs | Smallest YAML diff, but creates long mixed-purpose jobs and poor failure attribution. | |
| Split into separate jobs in existing `ci.yml` | Keeps one contributor-facing CI workflow while isolating root, demo, package, and optional-dep proof surfaces. | ✓ |
| Dedicated release-proof workflow | Keeps regular CI lean, but risks release-proof split-brain and stale checks. | |

**User's choice:** Discuss all; requested research-backed one-shot recommendations.
**Notes:** Advisor research recommended one CI workflow with separate named jobs. This best satisfies continuous proof while keeping failures easy to interpret.

---

## Demo CI Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| PostgreSQL-backed `demo` tests only | Narrowly satisfies PROOF-02 with the least CI surface. | |
| CI-safe demo quality gate | Run format check, unused-deps check, compile warnings-as-errors, and PostgreSQL-backed tests. | ✓ |
| Add `mix assets.deploy` smoke | Adds production asset/digest proof, but increases flakiness and exceeds the explicit phase requirement unless assets are a known risk. | |
| Full demo release/container smoke | Certifies the demo as deployable software, but over-scopes release readiness for the SDK. | |

**User's choice:** Discuss all; requested cohesive recommendation.
**Notes:** Recommendation avoids running the local `demo` precommit alias verbatim because CI should use check-mode commands.

---

## Downstream Package Smoke

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh Mix app with repo path dependency | Simple and useful, but does not prove package artifact contents. | |
| Custom package-file simulation | Can assert allowlisted files, but reimplements Hex behavior and can drift. | |
| Local Hex build/unpack plus fresh consumer compile | Uses Hex tooling to prove package contents and fresh-consumer compile behavior. | ✓ |

**User's choice:** Discuss all; requested package/DX and ecosystem lessons.
**Notes:** Recommendation mirrors successful ecosystem pack-and-consume smoke patterns from Hex/npm/Ruby/Python: prove the artifact users install, not only the source tree.

---

## Optional Dependency Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Compile/test with optional deps present | Proves MockServer works, but not that core consumers can omit optional deps. | |
| Prove core SDK works without optional deps | Protects the pure SDK boundary, but does not prove MockServer behavior. | |
| Document boundary only | Useful, but insufficient as executable release proof. | |
| Positive optional lane plus negative core lane plus docs boundary | Proves MockServer works when extras are present, proves core SDK compiles without them, and explains the boundary. | ✓ |

**User's choice:** Discuss all; requested deep recommendation with principle of least surprise.
**Notes:** `lib/paddle/mock_server.ex` currently uses `Plug.Router` and `Bandit.start_link/1`, so downstream planning must account for compile-time optional dependency risk.

---

## Claude's Discretion

- Exact YAML factoring, script placement, and whether optional-dep proof is a separate job or a named downstream-smoke step are left to planner discretion.
- Asset smoke is discretionary only if code inspection shows it belongs to release-readiness risk.

## Deferred Ideas

- Mandatory live Paddle sandbox/provider-state CI.
- Production demo deployment or Docker release certification.
- Phoenix/Ecto helper packages, Plug adapters, admin UI, and app-level billing framework features.
- GSD state reconciliation, which belongs to Phase 29.
