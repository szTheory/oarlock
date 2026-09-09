# Project Research Summary

**Project:** oarlock — Paddle Billing SDK for Elixir
**Milestone:** v2.2 Trust, Coverage & Green Delivery
**Domain:** SDK stewardship, delivery integrity, and durable planning provenance
**Researched:** 2026-09-09
**Confidence:** MEDIUM overall; HIGH for repository facts and MEDIUM for changing ecosystem recommendations

## Executive Summary

Oarlock is a deliberately narrow, framework-independent Elixir SDK whose quality depends as much on trustworthy stewardship as endpoint coverage. The research identifies a broken trust chain rather than generic cleanup: local and remote state diverge, planning artifacts disagree about the active milestone, worktree ownership is unclear, release automation can outrun complete CI, and current SDK behavior can expose credentials or replay ambiguous mutations. The most urgent dependency finding is Req 0.5.17, affected by two 2026 advisories; move to 0.7.4 in an isolated, compatibility-proved change.

Retain the existing Elixir/Req/Mix/GitHub Actions architecture and strengthen its seams. First establish repository and planning truth without deleting unclassified work. Then repair the SDK trust boundary: allowlisted telemetry, secret-safe inspection, stable client validation, safe-read retry defaults, and honest compatibility guidance. Preserve parallel proof classes while making one persisted `CI contract` the exact-SHA gate for protected `main`, releases, recovery publishing, and the evidence ledger. Add proportional PR, ownership, triage, dependency, and worktree controls after those underlying truths are stable.

Durable orientation is a milestone deliverable. A canonical persona/JTBD record and separate trajectory artifact must link source, rationale, owner, horizon, commitment status, requirement/phase, proof class, evidence, freshness, and promotion/reopen conditions. The revisable baseline is: v2.2 trust work is **short-term committed**; operational discovery, quote-before-mutate, and causal provider proof are **mid-term candidates**; packaged Accrue adoption, demand-backed B2B expansion, and public-contract graduation are **long-term conditional**. Changes require dated, append-only transitions that retain prior rationale. Broad Paddle endpoint mirroring is not v2.2 scope.

## Key Findings

Detailed evidence remains in [STACK.md](STACK.md), [FEATURES.md](FEATURES.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [PITFALLS.md](PITFALLS.md).

### Recommended Stack

Keep the pure-library architecture and add only controls that close identified risks.

**Core technologies:**

- **Elixir and Erlang/OTP:** retain the intended exact `.tool-versions` pair after classifying its current uncommitted change; compatibility breadth must be deliberate.
- **Req 0.7.4:** upgrade first from vulnerable 0.5.17 and prove adapters, custom steps, MockServer, package smoke, demo, Dialyzer, and downstream compatibility.
- **Mix, ExUnit, formatter, Dialyxir 1.4.7:** remain the deterministic quality core; document one local quality alias while CI fans proof out.
- **Hex 2.5.1 and rebar3 3.27.0:** pin automation and run built-in `mix hex.audit`; do not add duplicate audit tooling.
- **Credo 1.7.19:** the one justified new root quality dependency, introduced with a reviewed baseline rather than a cosmetic rewrite.
- **ExDoc 0.40.x:** upgrade separately and require warning-free docs evidence.
- **GitHub Actions:** use `ubuntu-24.04`, full-SHA-pinned actions, toolchain-aware caches, a resolved PostgreSQL 17.11 digest, persisted proof, and least-privilege permissions.
- **Release Please 5.0.0 / upload-artifact 7.0.1:** pin verified SHAs; Release Please must consume exact-SHA CI rather than define weaker green.
- **Repository-native governance:** Dependabot, CODEOWNERS, concise templates, report-only worktree checks, and validated Markdown provenance.

If the Req migration changes the dependency contract or observable behavior, use the appropriate pre-1.0 SemVer minor release. GSD milestone `v2.2` is not the Hex package version.

### Expected Features

**Must have (v2.2 table stakes):**

- Non-destructive repository, remote, PR, and worktree reconciliation with owner/disposition.
- One authoritative active-milestone model and explicit planning artifact precedence.
- Req vulnerability remediation with compatibility proof and dependency audit.
- Credential-safe telemetry/inspection, including nested `raw_data` and one-shot URLs/secrets.
- Provider-aligned retries: safe reads may retry; ambiguous mutations require reconciliation, not blind replay.
- Stable client/environment/base-URL validation that preserves custom MockServer use.
- Documentation, types, examples, migration notes, compatibility policy, and runtime behavior in agreement.
- Deterministic, measured CI retaining root, static, demo, package, optional-dependency, and planning proof.
- Protected hosted-green `main`; exact-SHA `CI contract` consumed by automatic and recovery releases.
- Focused PR, ownership, triage, dependency-update, and clean worktree entry/exit contracts.
- Canonical persona/JTBD provenance with immutable IDs and separate horizon/status axes.
- Typed evidence classes and freshness rules for local, MockServer, hosted, sandbox, live, package, and release proof.

**Should have (after the basic trust chain):**

- Bidirectional drift checks across JTBD, requirements, phases, evidence, backlog, and archives.
- Decision-preserving promotion, demotion, supersession, rejection, and reopen histories.
- Proof-aware summaries tied to exact-SHA CI artifacts and sentinel-based safety regression tests.
- A measured hosted CI critical-path budget and read-only repository/planning health reporting.
- Package attestation only after an end-to-end consumer verification path is proven.

**Defer beyond v2.2:**

- Mid-term candidates: customer/transaction discovery, quote-before-mutate pricing/proration, and bounded causal MockServer/provider scenarios.
- Long-term conditional: packaged Accrue adoption, demand-backed business/manual-collection/invoice flows, formal compatibility/deprecation/BEAM guarantees, and richer release provenance.
- Merge queues, mandatory independent approval, SBOM/Scorecard expansion, external planning systems, and heavyweight build/security/worktree platforms require observed need.

**Anti-features:** broad endpoint mirroring; Phoenix/Ecto/entitlement behavior in core; destructive cleanup; giant mixed PRs; mutable privileged actions; reduced release subsets called full proof; and roadmap candidates written as promises.

### Architecture Approach

Use five cooperating control planes around the SDK. Planning truth scopes work; repository lifecycle makes changes reversible/reviewable; SDK trust seams own safe behavior; CI aggregates proof for one SHA; release holds the credential boundary and consumes only accepted proof. Promotion is explicit: source observation → JTBD/gap → requirement → phase/change → proof → shipped history. Directory presence, generated caches, research, and summaries never independently authorize scope or prove completion.

**Major components:**

1. **Planning truth:** `PROJECT.md` holds scope; new `TRAJECTORY.md` holds revisable horizons; new `JTBD-COVERAGE.md` holds persona/job/gap/provenance; `REQUIREMENTS.md` defines accepted scope; `ROADMAP.md`/`STATE.md` locate execution; `EVIDENCE.md` and archives retain proof/history.
2. **Repository lifecycle:** classified worktrees, clean entry/exit, one bounded branch/PR per intent, ownership, and triage.
3. **SDK trust:** `Paddle.Client` validates/redacts; `Paddle.Http` owns method-aware retries; telemetry emits safe facts; secret-bearing structs redact promoted/raw fields.
4. **CI proof:** independent jobs prove distinct concerns; stable `CI contract` uploads SHA/run/toolchain/lockfile conclusions.
5. **Release integrity:** CI is checked before release creation and secret access; tag commit, gated SHA, package version, and proof agree.

### Critical Pitfalls

1. **Secrets leak through telemetry, `Inspect`, or `raw_data`:** use allowlists and realistic canary tests.
2. **Mutation retries duplicate/obscure state:** default to safe reads and typed ambiguous outcomes with reconciliation guidance.
3. **Publishing outruns CI:** bind merge, release, recovery, and package evidence to the same full SHA.
4. **Cleanup destroys work:** inventory owner/base/status/lock/disposition; unknown, dirty, or locked blocks removal.
5. **Planning drift creates phantom scope/completion:** define precedence, validate invariants, and never let summaries substitute for proof.
6. **Cancellation/token behavior erases proof:** cancel obsolete PR runs only, serialize releases, and test automation triggers.
7. **Mega-changes hide risk:** isolate dependency, toolchain, release, behavior, and planning changes into ordered PRs.

## Implications for Roadmap

Use six phases. Numbers continue from the last shipped phase; names below are semantic inputs.

### Phase 1: Repository & Planning Truth

**Rationale:** Later work depends on a real base and authoritative artifacts. Current planning contradictions, divergence, dirty files, stale PRs, and a locked worktree make this prerequisite.

**Delivers:** classified repository/worktree/branch/PR inventory; non-destructive dispositions; reconciled history/current state; artifact precedence; initial trajectory/JTBD schemas; consistency guard; sourced requirements.

**Addresses:** repository reconciliation, provenance, horizon/status separation, and evidence classes.

**Avoids:** destructive cleanup, directory-presence routing, summaries as proof, and lost rationale.

### Phase 2: Dependency & SDK Trust Boundary

**Rationale:** Known dependency, credential, and mutation risks must close before automation certifies the SDK. Req migration and retry policy stay separate reviewable plans.

**Delivers:** Req 0.7.4/audit; allowlisted telemetry; safe inspection including `raw_data`; client validation; safe-read retry matrix; ambiguous-mutation behavior; migration/compatibility/version guidance; safety tests.

**Addresses:** adopter, downstream maintainer, reliability, and security operator jobs.

**Avoids:** credential escape, mutation replay, cosmetic idempotency, brittle validation, and upgrade bundling.

### Phase 3: Deterministic Green CI

**Rationale:** Once source and SDK contracts stabilize, CI can become authoritative while retaining all proof classes.

**Delivers:** pinned inputs; Credo/ExDoc; audited caches; measured critical path; uploaded CI proof; exact-SHA monitor; protected required `CI contract`; hosted-green current `main` evidence.

**Addresses:** deterministic fast CI, evidence classification, and maintainable dependency updates.

**Avoids:** speed by skipped proof, incompatible caches, canceled main evidence, and branch/newest-run shortcuts.

### Phase 4: Release Integrity

**Rationale:** Publishing must consume Phase 3's exact-SHA contract, not approximate it.

**Delivers:** pre-release quality gate; tag/SHA/version/package agreement; recovery parity; serialized publishing; least-privilege Hex environment where supported; dry-run/post-publish evidence; fail-before-secret behavior.

**Addresses:** release-steward trust and package provenance foundations.

**Avoids:** release races, arbitrary-SHA recovery, weaker release-local green, and excess permissions.

### Phase 5: Review, Ownership & Worktree Operations

**Rationale:** Governance should institutionalize a demonstrated trust chain, not mask absent controls.

**Delivers:** `CONTRIBUTING.md`, proportional CODEOWNERS, PR/issue templates, triage vocabulary, existing-PR disposition, Dependabot grouping, report-only worktree health, and small-PR lifecycle.

**Addresses:** contributor/reviewer jobs, ownership, dependency maintenance, and clean worktrees.

**Avoids:** governance theater, ownerless templates, stale bot PRs, forced cleanup, and mega-PRs.

### Phase 6: JTBD Coverage, Durable Trajectory & Exact-SHA Handoff

**Rationale:** The vocabulary begins in Phase 1, then is finalized against actual implementation/proof so it remains operational rather than aspirational.

**Delivers:** stable persona/JTBD IDs; bidirectional requirement/phase/evidence links; append-only transitions; explicit horizons; freshness/promotion/reopen triggers; drift guard; exact-SHA milestone evidence; clean documented handoff.

**Addresses:** project-steward/future-planner jobs and consumer-backed capability promotion.

**Avoids:** candidates becoming commitments, endpoint mirroring, overwritten rationale, stale proof, and unsupported completion claims.

### Phase Ordering Rationale

- Truth/preservation precede cleanup and requirements.
- SDK risk precedes certification so green CI proves repaired behavior.
- CI precedes release because publication consumes its exact-SHA proof.
- Contribution governance follows demonstrated technical controls.
- Trajectory starts early but closes last against real evidence.
- Each phase uses narrow ordered plans/PRs; never bundle Req, retries, toolchains, release wiring, and planning rewrites.

### Durable Trajectory Baseline

This is a compass, not a release promise.

| Horizon | Status | Direction | Promotion/reconsideration rule |
|---|---|---|---|
| Short | `committed` v2.2 | Repository/planning truth; Req/SDK safety; green CI; exact-SHA release; PR/triage/worktree discipline; JTBD provenance | Replan through a dated decision retaining source, rationale, owner, impact, and prior state |
| Mid | `candidate` | Customer/transaction discovery; quote-before-mutate; bounded causal mock and separate provider proof | Promote for a named job with current API research, smallest surface, owner, and proof contract |
| Long | `conditional` | Packaged Accrue adoption; demand-backed B2B/manual/invoice work; public-contract graduation | Activate on consumer adoption, support burden, maturity, procurement need, or stabilization decision |

Horizon and status remain separate. Transitions retain source date, rationale, evidence, non-goals, owner/repository, freshness, and promotion/reopen condition. Use `rejected`, `external`, and `superseded` when appropriate so discarded or out-of-scope signal stays discoverable.

### Research Flags

**Needs deeper phase research:**

- **Phase 2:** spike Req compatibility; inventory mutation/idempotency surfaces and Accrue use; verify provider guarantees before choosing removal/deprecation/correction.
- **Phase 3:** inspect hosted runs/rulesets; measure duration/flakes/caches; resolve action/container digests at implementation.
- **Phase 4:** verify environment/reviewer/ruleset availability, automation-token behavior, and Hex attestation boundaries.
- **Phase 6:** validate JTBD completeness against Accrue and a cold-adopter journey before promoting v2.3 candidates.

**Standard patterns, focused repository inspection sufficient:**

- **Phase 1:** Git porcelain inventory, append-only corrections, and invariant validation.
- **Phase 5:** templates, CODEOWNERS, Dependabot, triage, and report-only worktree checks, after confirming owners/capacity.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | MEDIUM | Repository facts are HIGH; versions/advisories/platform guidance are official but classified MEDIUM by the research seam. |
| Features | MEDIUM | Personas and gaps are well grounded; completeness across future adopters needs validation. |
| Architecture | HIGH/MEDIUM | Boundaries are observed; hosting capability and scaling choices are changeable. |
| Pitfalls | HIGH/MEDIUM | Paths are evidenced; harms are reachable risks, not asserted incidents. |

**Overall confidence:** MEDIUM. Ordering and v2.2 boundaries are strong; platform facts and compatibility choices require phase-local validation.

### Gaps to Address

- Classify `.tool-versions` and locked worktree ownership before baseline/removal decisions.
- Spike Req across adapters, MockServer, package consumer, demo, Dialyzer, and Accrue.
- Verify operation-specific Paddle mutation semantics and public `idempotency_key` consumers.
- Query actual rulesets, hosting features, environments, reviewers, CI history, and automation credential mode.
- Measure median/tail CI duration and cache behavior before setting a numeric budget.
- Choose readable, mechanically checked Markdown without duplicating planning authority.
- Keep attestation optional until it maps cleanly to Hex and consumer verification.
- Validate future JTBD candidates against real adopter evidence before promotion.

## Sources

### Primary repository evidence (HIGH confidence)

- `.planning/PROJECT.md`, `STATE.md`, `ROADMAP.md`, `MILESTONES.md`, `EVIDENCE.md`, `GSD-PREFERENCES.md`, `BACKLOG.md`, archives, threads, and phase artifacts.
- `mix.exs`, `mix.lock`, `.tool-versions`, root/demo tests, package-smoke and optional-dependency checks.
- `lib/paddle/client.ex`, `http.ex`, `http/telemetry.ex`, `notification_setting.ex`, and `portal_session.ex`.
- `.github/workflows/ci.yml`, `release-please.yml`, `hex-publish.yml`, and `scripts/ci_monitor.cjs`.
- Git porcelain and authenticated GitHub run/PR/protection observations captured 2026-09-09; local HEAD is not hosted proof.

### Official external guidance (MEDIUM confidence through configured seam)

- [Req advisories](https://hex.pm/packages/req/advisories), [Req changelog](https://github.com/wojtekmach/req/blob/v0.7.4/CHANGELOG.md), and [retry options](https://req.hexdocs.pm/Req.Steps.html#retry/1-request-options).
- [Paddle SDK patterns](https://developer.paddle.com/sdks/libraries/), [authentication](https://developer.paddle.com/api-reference/about/authentication/), [rate limiting](https://developer.paddle.com/api-reference/about/rate-limiting/), and [versioning](https://developer.paddle.com/api-reference/about/versioning/).
- [Hex audit](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html), [Hex publishing](https://hex.pm/docs/publish), and official package pages for Credo, ExDoc, and Dialyxir.
- [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [Actions security](https://docs.github.com/en/actions/reference/security/secure-use), [artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data), [environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), and [attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations).
- [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners), [templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests), and [Dependabot](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference).
- [Git worktree](https://git-scm.com/docs/git-worktree), [Git status](https://git-scm.com/docs/git-status), [Elixir Inspect](https://hexdocs.pm/elixir/Inspect.html), and [OpenSSF checks](https://github.com/ossf/scorecard/blob/main/docs/checks.md).

---

*Research completed: 2026-09-09*
*Ready for roadmap: yes*
