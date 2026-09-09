# Requirements: oarlock v2.2 Trust, Coverage & Green Delivery

**Defined:** 2026-09-09
**Core Value:** Provide a production-quality, idiomatic Elixir SDK for Paddle
Billing as a pure, standalone foundation for Accrue's second-processor strategy.

## Source Anchors

The requirement provenance below is part of the milestone contract. Detailed
claims, local evidence, external sources, confidence, and open questions remain
in the linked research files.

| ID | Source | Role |
|----|--------|------|
| USER-2026-09-09 | Milestone direction confirmed in the `$gsd-new-milestone` conversation | Requires complete relevant JTBD coverage, high quality across dimensions, green main, fast CI/CD, clean worktrees, reviewable PRs, triage, and durable planning signal |
| RES-SUMMARY | `.planning/research/SUMMARY.md` | Synthesized findings, ordering, confidence, and durable trajectory baseline |
| RES-STACK | `.planning/research/STACK.md` | Dependency, tooling, CI, release, and governance recommendations with primary provenance |
| RES-FEATURES | `.planning/research/FEATURES.md` | Table stakes, differentiators, anti-features, JTBD record shape, and horizon semantics |
| RES-ARCH | `.planning/research/ARCHITECTURE.md` | Planning, repository, SDK trust, CI, release, and evidence control-plane boundaries |
| RES-PITFALLS | `.planning/research/PITFALLS.md` | Project-specific failure modes, detection, prevention, and phase ownership |
| SHIPPED-V2.1 | `.planning/milestones/v2.1-REQUIREMENTS.md` and `.planning/EVIDENCE.md` | Shipped proof plus future requirements carried forward without silently promoting them |

## v2.2 Requirements

### Repository and Planning Truth

**Source basis:** USER-2026-09-09, RES-SUMMARY, RES-ARCH, RES-PITFALLS

- [ ] **REPO-01**: Maintainer can run a read-only inventory that reports every dirty path, branch divergence, linked worktree, lock state, owner, and proposed disposition before cleanup occurs.
- [ ] **REPO-02**: Maintainer and GSD tooling use one documented authority chain for active scope; archives, caches, summaries, and directory presence cannot independently make shipped work appear active.
- [ ] **REPO-03**: Maintainer can navigate a complete milestone history whose shipped status, requirements, archive links, planning identifiers, and package-version semantics agree.
- [ ] **REPO-04**: Maintainer can run a planning-health check that detects stale active artifacts, broken references, archive contradictions, and unproven completion claims without mutating files.

### Dependency and SDK Trust

**Source basis:** USER-2026-09-09, RES-STACK, RES-FEATURES, RES-ARCH, RES-PITFALLS

- [ ] **SAFE-01**: SDK consumer can install a compatibility-tested Req release that resolves the known advisories, while `mix hex.audit` passes.
- [ ] **SAFE-02**: Telemetry subscriber receives stable allowlisted metadata without request/response objects, API credentials, bodies, signed URLs, secrets, or raw customer data.
- [ ] **SAFE-03**: Inspecting any public secret-bearing struct redacts secrets from both promoted fields and nested raw provider payloads.
- [ ] **SAFE-04**: Safe reads use bounded, documented retry behavior, while ambiguous mutations are not blindly replayed and instead return actionable reconciliation guidance.
- [ ] **SAFE-05**: Client construction rejects blank credentials, unsupported environments, and invalid configuration while preserving deliberate custom-base-URL MockServer use.
- [ ] **SAFE-06**: Public documentation, examples, types, support claims, retry guidance, and migration notes agree with tested runtime behavior.

### Deterministic Green CI

**Source basis:** USER-2026-09-09, RES-STACK, RES-FEATURES, RES-ARCH, RES-PITFALLS

- [ ] **CI-01**: Every proposed change runs the complete required proof contract: formatting, dependency checks, warnings, tests, public specs, Dialyzer, Credo, ExDoc, vulnerability audit, demo/PostgreSQL, package smoke, optional-dependency proof, and planning guards.
- [ ] **CI-02**: CI uses reviewed immutable inputs, controlled runners and toolchains, runtime-aware caches, explicit timeouts, and least-privilege permissions.
- [ ] **CI-03**: Maintainer can see measured CI critical-path evidence and a baseline-derived feedback target; speed improvements cannot remove required proof.
- [ ] **CI-04**: Remote `main` is protected by a stable aggregate check proving the exact commit SHA, and current main has recorded hosted-green evidence.
- [ ] **CI-05**: Every authoritative CI run produces a durable proof summary containing SHA, run identity, toolchains, lockfile identity, and each required lane's outcome.

### Release Integrity

**Source basis:** USER-2026-09-09, RES-STACK, RES-FEATURES, RES-ARCH, RES-PITFALLS

- [ ] **SHIP-01**: Automatic and recovery publishing both fail before accessing release secrets unless the exact release SHA passed the complete required CI contract.
- [ ] **SHIP-02**: Release automation verifies agreement among source SHA, tag, package version, built artifact, and published package.
- [ ] **SHIP-03**: Publishing is serialized, least-privileged, and recovery follows the same quality and identity contract as automatic release.
- [ ] **SHIP-04**: Maintainer can trace every release to durable evidence for its exact SHA, CI run, artifact, dry run, publication, and post-publish verification.

### PR, Triage, and Worktree Operations

**Source basis:** USER-2026-09-09, RES-STACK, RES-FEATURES, RES-ARCH, RES-PITFALLS

- [ ] **OPS-01**: Contributor receives concise contribution, security-reporting, ownership, issue, and PR guidance that requires one bounded intent and proportional evidence.
- [ ] **OPS-02**: Maintainer can disposition every existing or new issue and PR with a controlled triage state, owner, scope decision, and next action.
- [ ] **OPS-03**: Each task can use an isolated worktree with clean-entry and clean-exit checks; dirty, locked, stale, or unknown work is reported and never deleted automatically.
- [ ] **OPS-04**: Dependency updates arrive as grouped, reviewable PRs that run the same compatibility and security contract as other changes.

### JTBD Coverage and Durable Trajectory

**Source basis:** USER-2026-09-09, RES-SUMMARY, RES-FEATURES, RES-ARCH, RES-PITFALLS, SHIPPED-V2.1

- [ ] **ORIENT-01**: Maintainer can view a canonical coverage map of relevant personas and stable JTBD IDs, including situation, desired outcome, current capability, smallest gap, and SDK/app/provider ownership boundary.
- [ ] **ORIENT-02**: Every JTBD and capability decision records dated sources, rationale, owner or repository, requirement and phase links, proof contract, evidence, freshness trigger, non-goals, and promotion or reopen condition.
- [ ] **ORIENT-03**: Maintainer can view a canonical trajectory that separates `short`/`mid`/`long` horizon from `shipped`/`committed`/`candidate`/`conditional`/`rejected`/`external`/`superseded` status.
- [ ] **ORIENT-04**: Planning changes append dated status transitions while retaining previous rationale and evidence instead of silently rewriting history.
- [ ] **ORIENT-05**: A validator detects broken or inconsistent links among JTBD records, requirements, phases, evidence, backlog entries, trajectory items, and milestone archives.
- [ ] **ORIENT-06**: Milestone handoff records clean repository and worktree status, exact-SHA proof, remaining blockers, accepted caveats, and evidence-based candidates for the next discovery cycle.

## Future Requirements

These requirements remain discoverable but are not commitments in v2.2.
Promotion requires a named persona/JTBD, current provider research, the smallest
coherent SDK surface, an owner, and a proof contract.

### Mid-term Candidates

- **DISC-01**: Support or reconciliation operator can discover customers without already knowing a Paddle customer ID.
- **DISC-02**: Support, finance, or reconciliation operator can list and page through transactions without already knowing a transaction ID.
- **QUOTE-01**: SaaS integrator can preview pricing or proration before committing a supported billing mutation, if the current Paddle API exposes a stable seam.
- **MOCK-01**: MockServer models selected, documented offline-supported flows with realistic error envelopes, pagination, and causal state transitions.
- **MOCK-02**: MockServer documentation clearly lists supported and unsupported endpoints and keeps MockServer, sandbox, and live proof distinct.

### Long-term Conditional

- **ACCRUE-01**: Accrue consumes a packaged oarlock release through one real Paddle-backed vertical slice.
- **ACCRUE-02**: Accrue-side `%Paddle.Error{}.raw` references are migrated to `raw_data` in the owning repository.
- **API-01**: Payment-method capabilities are added only if a named consumer job needs them beyond portal sessions and management URLs.
- **API-02**: Business, invoice, or manual-collection flows are added only if a named consumer job needs them.
- **API-03**: Product/price writes, marketplace/connect, reports, and simulations remain demand-driven rather than becoming an endpoint-parity program.
- **STABLE-01**: Maintainer can deliberately graduate the public contract with explicit compatibility, deprecation, supported BEAM, migration, and reproducible release guarantees when real consumers justify stabilization.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Broad Paddle endpoint mirror | Conflicts with the consumer-backed scope boundary and creates unsupported maintenance surface. |
| New Paddle API breadth during v2.2 | This milestone repairs the trust chain and establishes evidence for later promotion decisions. |
| Phoenix, Ecto, entitlement, persistence, or support-policy ownership in core | These remain application responsibilities; the library stays framework-independent. |
| Destructive automatic cleanup | Dirty or locked work may belong to users or concurrent agents; automation reports and explicit reviewed disposition changes state. |
| One giant make-everything-green change | Dependency, behavior, CI, release, operations, and planning risks require bounded, reviewable changes. |
| CI acceleration by dropping proof | Speed is measured and optimized while the complete proof contract remains intact. |
| External planning service as sole authority | Repository-local context and provenance must remain available to future agents and archived milestones. |
| Mandatory merge queue or independent approval now | Enable only when concurrency and reviewer availability demonstrate the need. |
| Artifact attestation as a v2.2 commitment | Evaluate only after exact-SHA CI and release identity work end to end with Hex distribution. |

## Traceability

Phase mapping is populated during roadmap creation. Each committed requirement
must map to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | TBD | Pending |
| REPO-02 | TBD | Pending |
| REPO-03 | TBD | Pending |
| REPO-04 | TBD | Pending |
| SAFE-01 | TBD | Pending |
| SAFE-02 | TBD | Pending |
| SAFE-03 | TBD | Pending |
| SAFE-04 | TBD | Pending |
| SAFE-05 | TBD | Pending |
| SAFE-06 | TBD | Pending |
| CI-01 | TBD | Pending |
| CI-02 | TBD | Pending |
| CI-03 | TBD | Pending |
| CI-04 | TBD | Pending |
| CI-05 | TBD | Pending |
| SHIP-01 | TBD | Pending |
| SHIP-02 | TBD | Pending |
| SHIP-03 | TBD | Pending |
| SHIP-04 | TBD | Pending |
| OPS-01 | TBD | Pending |
| OPS-02 | TBD | Pending |
| OPS-03 | TBD | Pending |
| OPS-04 | TBD | Pending |
| ORIENT-01 | TBD | Pending |
| ORIENT-02 | TBD | Pending |
| ORIENT-03 | TBD | Pending |
| ORIENT-04 | TBD | Pending |
| ORIENT-05 | TBD | Pending |
| ORIENT-06 | TBD | Pending |

**Coverage:**

- v2.2 requirements: 29 total
- Mapped to phases: 0
- Unmapped: 29 (roadmap pending)

---
*Requirements defined: 2026-09-09*
*Last updated: 2026-09-09 after milestone requirements approval*
