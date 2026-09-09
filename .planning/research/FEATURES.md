# Feature Landscape: v2.2 Trust, Coverage & Green Delivery

**Domain:** Stewardship and delivery system for a deliberately narrow open-source Elixir SDK
**Researched:** 2026-09-09
**Overall confidence:** MEDIUM — direct repository observations are paired with current official GitHub, Git, Paddle, and OpenSSF sources; the configured research confidence seam classifies verified web research as MEDIUM.
**Scope boundary:** This document describes the new stewardship capability. It does not recommend broad Paddle endpoint mirroring.

## Product Principle

The feature is not “more process.” It is a maintained chain of trust:

```text
real adopter/operator job
  → sourced capability decision
  → explicit horizon and commitment status
  → requirement and bounded change
  → reviewable PR and exact-SHA CI
  → release or archive evidence
  → discoverable history and reconsideration trigger
```

Every link must be observable. A roadmap statement without a source and status is not a commitment; a passing local command without an artifact or SHA is not hosted proof; a published package that did not pass the full release contract at its source SHA is not a trusted release.

## Relevant Personas and Jobs

| Persona | Job to be done | Observable success | Current evidence / gap |
|---------|----------------|--------------------|------------------------|
| Adopter engineer | Integrate Paddle Billing into an Elixir app without reverse-engineering raw JSON or hidden SDK behavior. | Can identify supported jobs, copy a safe flow, understand failures and proof boundaries, and upgrade without surprise. | README and Getting Started describe the narrow seam and proof ladder; contract truth still conflicts with current Paddle retry/idempotency guidance. |
| Downstream SDK/library maintainer (Accrue) | Depend on a stable typed seam while evolving a higher-level multi-processor abstraction. | Locked surfaces and breaking changes are explicit; consumer migrations and proof are linked to the originating decision. | `PROJECT.md` and `guides/accrue-seam.md` define the seam; active backlog item B-04 shows why cross-repository migrations need durable ownership and evidence. |
| Application reliability engineer | Retry or reconcile provider calls without duplicating mutations or hiding ambiguous outcomes. | Read operations retry predictably; mutations fail safely or require reconciliation; 429 handling respects provider signals. | Oarlock currently defaults Req to transient retries and exposes an `Idempotency-Key` header, while Paddle says arbitrary operations do not support client-supplied idempotency keys. |
| Security/privacy operator | Ensure credentials and short-lived secrets do not escape through logs, telemetry, exceptions, or struct inspection. | Tests prove credential-bearing headers, response secrets, portal URLs, and raw payloads are absent from inspection and telemetry. | Portal sessions redact URLs, but telemetry emits full Req request/response structures and notification settings have no custom redaction. |
| Contributor | Submit a bounded change and know exactly what evidence is expected. | Starts clean, works on an isolated branch/worktree, opens a focused PR linked to intent, and sees one authoritative required gate. | CI has broad checks, but no canonical PR template/ownership/clean-worktree contract was identified in the inspected repository. |
| Reviewer/maintainer | Decide quickly whether a change is correct, in scope, safe, and ready. | PR states persona/JTBD, requirement, risk, proof, compatibility impact, and non-goals; sensitive changes reach the right owner. | GitHub supports templates and CODEOWNERS; oarlock needs a proportional policy that works even when independent reviewers are unavailable. |
| Release steward | Publish only artifacts derived from a reviewed, green source revision. | Tag/package/version agree; the full required CI contract is successful for the exact source SHA; provenance is retained. | `ci.yml` produces a contract proof, but release workflows rerun only a subset and can publish without consuming the complete exact-SHA contract. |
| Project steward / future planner | Know what is shipped, committed, plausible, conditional, or rejected—and why. | Can trace every roadmap item to source, rationale, owner, evidence, status history, and promotion/reopen condition. | `PROJECT.md`, `BACKLOG.md`, and `EVIDENCE.md` provide useful pieces; `ROADMAP.md` still says no active milestone after v2.2 initialization and no canonical cross-file JTBD coverage record exists. |
| Support/finance/reconciliation operator | Find customers and transactions to explain or reconcile billing outcomes. | Candidate jobs stay discoverable with adopter evidence and promotion conditions, without being advertised as shipped. | Operational discovery is a mid-term candidate from milestone discovery, not v2.2 scope. |

## Table Stakes

Missing any of these means maintainers or adopters cannot trust the SDK’s development and release story.

| Feature | Why expected | Complexity | Observable behavior / acceptance signal |
|---------|--------------|------------|-----------------------------------------|
| Repository-state reconciliation without data loss | Clean delivery cannot begin by silently deleting unknown work. Git exposes stable porcelain status and explicit worktree inventory/repair/prune operations. | Medium | Every dirty/untracked path and linked worktree is classified as preserve, commit, archive, ignore, or safely remove; provenance and owner are recorded; the main worktree and completed task worktrees exit clean. |
| Protected, green `main` | The default branch is the public source of truth. GitHub can require successful status checks and reviews and prevent force-push/deletion bypass. | Medium | Direct unreviewed changes are prevented where hosting supports it; the canonical `ci-contract` check is required; current remote `main` has a successful hosted run tied to its exact SHA. |
| Deterministic, measured CI contract | “Fast CI” is meaningless without a baseline, stable inputs, and a single definition of required success. | Medium | All third-party Actions use verified full commit SHAs; BEAM versions and lockfiles are explicit; jobs run in parallel; obsolete runs cancel; critical-path duration and failure cause are recorded; optimization never silently drops a quality gate. |
| Full release gate at the source SHA | Package publication must not be weaker than PR CI. | High | Release resolves tag to immutable SHA, verifies version/tag/package agreement, requires the complete CI contract for that SHA (library, Dialyzer/specs, demo, package smoke, optional-deps), and records package verification. Manual recovery meets the same contract. |
| Credential-safe telemetry and inspection | Paddle API keys are server-side secrets. Emitting entire Req request/response structures makes accidental logging likely. | Medium | Telemetry metadata is an allowlist of non-secret values such as method, normalized route, status/error class, attempt, and duration; tests assert credentials, authorization headers, bodies, portal tokens, endpoint secrets, and sensitive `raw_data` never appear. |
| Provider-aligned retry and ambiguous-mutation safety | Paddle explicitly warns that arbitrary client-supplied idempotency keys are unsupported and that a timed-out create may already have succeeded. | High | Safe reads may retry documented transient conditions; 429 honors `Retry-After`; mutations are not automatically replayed unless proven safe; ambiguous creates return actionable reconciliation information; obsolete idempotency claims/API are migrated with compatibility and release notes. |
| Client and environment validation | Invalid or cross-environment credentials should fail near construction, not as surprising remote behavior. | Medium | Client rejects invalid environment/base-URL combinations and empty credentials; validation distinguishes official sandbox/live shapes from custom MockServer credentials without exposing keys; error behavior is documented and tested. |
| Documentation and compatibility truth | SDK behavior, docs, types, examples, changelog, package version, and provider behavior must agree. | Medium | Contract inventory/tests catch stale functions and claims; compatibility policy distinguishes additive fields, breaking struct changes, behavior changes, supported BEAM matrix, and package/GSD milestone numbering. |
| Focused PR contract | Review quality depends on context, not just a green badge. GitHub’s official guidance recommends templates to capture purpose, linked issues, and testing notes. | Low | Each PR links a requirement or triaged issue, identifies affected persona/JTBD, states risk and non-goals, reports exact verification, notes compatibility/security/release impact, and contains one coherent change. |
| Ownership and triage contract | Unowned reports and sensitive files create invisible queues and review gaps. | Medium | Every open item has a type, priority, owner, status, source, next action, and revisit/close condition; security/release/public-contract paths have an explicit accountable owner; CODEOWNERS is used only where it routes to a real reviewer. |
| Clean worktree entry/exit contract | Parallel work needs isolation that does not leave stale locks or unrelated modifications behind. | Medium | Task start records branch, base SHA, and pre-existing changes; task completion checks `git status --porcelain` and `git worktree list --porcelain`; created worktrees have owners/reasons and are removed or intentionally retained with status. |
| Canonical persona/JTBD coverage and provenance model | Endpoint counts cannot answer whether relevant adopter jobs are covered or why work was chosen. | High | One discoverable record maps persona → JTBD → capability/gap → status/horizon → requirement/phase → proof/evidence, with immutable IDs, source date, owner, rationale, non-goal, freshness, and promotion/reopen rule. |
| Explicit roadmap horizon semantics | A candidate roadmap easily becomes an accidental promise unless commitment is encoded separately from time horizon. | Medium | Every future item has both `horizon` and `commitment_status`; only accepted requirements in the active milestone are `committed`; changes append decision history rather than rewriting rationale. |
| Evidence classification and freshness | Local tests, MockServer proof, hosted CI, sandbox proof, and live provider proof establish different facts. | Medium | Each claim names evidence class, artifact, command/run URL, exact SHA where applicable, caveat, captured date, and freshness/revalidation rule; stale evidence remains historical but cannot silently satisfy a current gate. |

## Differentiators

These are unusually valuable for a small community SDK. They should be built after the table-stakes trust chain is closed, or folded into that work only when low-cost.

| Feature | Value proposition | Complexity | Observable behavior / acceptance signal |
|---------|-------------------|------------|-----------------------------------------|
| Bidirectional traceability health check | Prevents “shipped but still listed as missing,” orphan requirements, and proof without intent. | High | A deterministic check reports missing or contradictory links among persona/JTBD IDs, requirements, phases, summaries, evidence, backlog, and milestone archives; it fails only on actionable invariants. |
| Decision-preserving roadmap transitions | Lets future discovery change direction without losing the signal that motivated earlier plans. | Medium | Promotion, demotion, supersession, rejection, and reopen events retain previous status, date, author/owner, evidence, and rationale; archived items remain searchable. |
| Proof-aware PR and release summaries | Makes review and handoff faster by publishing the evidence contract in human-readable form. | Medium | CI emits a compact exact-SHA proof artifact; PR/release summaries link it and list required jobs, caveats, package result, and provider-proof boundary. |
| Safety-contract regression suite | Turns subtle logging, retry, compatibility, and raw-data rules into executable public trust. | Medium | Tests use sentinel secrets and ambiguous failures to prove no leak/no duplicate mutation; locked seam tests distinguish additive from breaking changes. |
| CI critical-path budget with trend evidence | Keeps “fast” measurable without rewarding skipped checks. | Medium | Baseline and target are recorded from hosted runs; regressions identify the slow job/cache miss; performance work preserves required proof and compares before/after exact-SHA runs. |
| Verifiable package provenance | Lets downstream users verify which workflow and commit produced an artifact. GitHub attestations bind artifacts to repository, workflow, event, and commit SHA when generated and verified. | High | A downloadable package or package manifest has an attestation; documented verification succeeds; provenance points to the same SHA that passed the release gate. Treat as a differentiator until Hex distribution integration is validated. |
| Consumer-backed capability promotion | Keeps the SDK narrow while steadily expanding relevant JTBD coverage. | Medium | A candidate becomes committed only with a named persona/job, adopter or provider evidence, clear ownership boundary, acceptance proof, and an explicit reason the existing seam is insufficient. |
| Automatic stale-worktree and planning drift report | Gives maintainers situational awareness before changes accumulate into cleanup events. | Medium | A read-only health command lists dirty/locked/prunable worktrees, ahead/behind state, stale active artifacts, unsourced roadmap items, and evidence needing refresh; it never deletes or rewrites automatically. |

## Canonical JTBD-to-Evidence Record

Use one immutable record per job/capability decision. Markdown is acceptable as the human-facing source if a small validator can parse stable headings/fields; do not introduce a database or external product merely to hold this metadata.

| Field | Required meaning |
|-------|------------------|
| `id` | Stable, never-reused identifier, e.g. `JTBD-REL-01`; titles may change without breaking links. |
| `persona` | Named actor with an ownership boundary, not “user.” |
| `job` | Situation-driven outcome statement: “When …, I need …, so I can ….” |
| `source_refs` | One or more provenance pointers: user direction, adopter issue, provider docs, repository observation, incident, research artifact, or archived decision. Include source date. |
| `capability` / `gap` | What oarlock provides now and the smallest missing outcome; explicitly name app-owned/provider-owned work. |
| `horizon` | `short`, `mid`, or `long`; describes planning distance, not certainty. |
| `commitment_status` | One of the controlled statuses below. Never infer from horizon. |
| `rationale` | Why this status and scope were chosen; include alternatives/non-goals. |
| `owner` | Accountable repo/person/role; use `external:accrue` for consumer-side work rather than pretending oarlock owns it. |
| `requirement_phase` | Requirement ID and phase when committed; empty for unpromoted candidates. |
| `proof_contract` | Acceptance criteria plus evidence class required to claim completion. |
| `evidence_refs` | Exact files, commands, hosted run URLs, package/version, and SHA as applicable. |
| `freshness` | Last reviewed date and event/time-based revalidation trigger. |
| `promotion_or_reopen` | Evidence that would promote a candidate/conditional item or reopen shipped/rejected work. |
| `status_history` | Append-only dated transitions with rationale and provenance. |

### Controlled Commitment Statuses

| Status | Meaning | Allowed roadmap language |
|--------|---------|--------------------------|
| `shipped` | Acceptance proof exists and is indexed. | “Available,” with evidence class and caveat. |
| `committed` | Accepted into the current milestone requirements and phase roadmap with owner and proof contract. | “Will deliver in v2.2,” subject to recorded replanning. |
| `candidate` | Evidence-backed plausible next work, not scheduled or promised. | “Candidate,” “explore,” or “prioritize if evidence strengthens.” |
| `conditional` | Deliberately deferred until a named trigger occurs. | “Only if/when [trigger].” |
| `rejected` | Considered and intentionally declined; rationale and reopen condition retained. | “Not planned because …; reconsider if ….” |
| `external` | Valid job owned by another repository/provider/operator. | “Tracked for context; not oarlock scope.” |
| `superseded` | Replaced by another decision or capability; linkage retained. | “Superseded by [ID].” |

**Hard rule:** `short`/`mid`/`long` and `committed`/`candidate`/`conditional` are separate axes. In the current baseline, v2.2 short-term items are committed, mid-term items are candidates, and long-term items are conditional, but future planning must change statuses explicitly rather than relying on those defaults.

## Durable Trajectory Baseline

This is a compass, not a release promise. Future milestone research may revise it through recorded status transitions.

| Horizon | Status | Baseline direction | Promotion/reconsideration condition |
|---------|--------|--------------------|-------------------------------------|
| Short | Committed: v2.2 | Repository/planning truth; credential-safe SDK core; provider-aligned retries; client/contract validation; clean PR/worktree/triage practices; green exact-SHA CI and release integrity; canonical JTBD/provenance coverage. | Replan only with a recorded blocker or stronger safety/dependency ordering; preserve original rationale and evidence. |
| Mid | Candidate | Customer and transaction discovery for support/reconciliation; quote-before-mutate pricing/proration; bounded causal MockServer scenarios and separately classified provider proof. | Promote only with a named adopter/operator job, API-current research, smallest coherent surface, owner, and proof contract. |
| Long | Conditional | Real packaged Accrue adoption; demand-backed business/manual-collection/invoice jobs; public-contract graduation with explicit compatibility, deprecation, supported BEAM, and reproducible release guarantees. | Triggered by real consumer adoption, support burden, ecosystem maturity, or a decision to stabilize the package contract; do not infer from elapsed time. |

## Anti-Features

| Anti-feature | Why avoid | Do instead |
|--------------|-----------|------------|
| Broad Paddle endpoint mirroring | Inflates maintenance and type surface without proving a relevant job; contradicts the library’s deliberately narrow seam. | Promote the smallest capability that closes a sourced adopter/operator JTBD. |
| Treating roadmap dates/horizons as commitments | Creates false promises and makes exploratory ideas look scheduled. | Store `horizon` and `commitment_status` separately and control public language by status. |
| Rewriting or deleting decision history | Loses why work existed and causes future planners to repeat research. | Append status transitions; archive while retaining fields, links, rationale, and reopen conditions. |
| Cleanup by discard/reset | Dirty files and worktrees may contain user or parallel-agent work. | Classify first, preserve provenance, and remove only explicit safe targets. Never make cleanup destructive by default. |
| One giant “make everything green” PR | Mixes SDK behavior, CI, docs, release, and planning changes; reviewers cannot isolate risk or revert safely. | Use vertical, dependency-ordered PRs with one intent and complete evidence. |
| CI speed by skipping proof | Produces fast false confidence, especially if demo/package/optional dependency checks disappear from required status. | Measure the critical path, parallelize, cache immutable inputs, cancel stale runs, and retain the full contract. |
| Release-time partial test rerun as proof of full CI | The current publish paths compile/test but do not demonstrate every required gate at the tag SHA. | Require the complete exact-SHA CI contract, then perform release-specific dry-run/publish/verification. |
| Mutable Action tags in privileged workflows | Tags can move; GitHub states a full commit SHA is the immutable reference for an Action. | Pin verified full SHAs and automate reviewed update PRs. |
| Broad write permissions for routine CI or manual recovery | A compromised action/job gets unnecessary repository power. | Default to read-only; grant narrowly scoped job-level permissions only where required. |
| Full request/response telemetry | Req structures can contain bearer credentials, request bodies, provider responses, and signed URLs. | Emit an allowlisted metadata schema and test it with sentinel secrets. |
| Global automatic retries for mutations | A timeout can hide a successful create; Paddle does not support arbitrary client idempotency keys. | Retry safe reads; return ambiguous mutation failures for reconciliation; follow documented 429 guidance. |
| Cosmetic `Idempotency-Key` support | A header the provider does not honor creates stronger duplication risk by implying safety. | Remove/deprecate unsupported behavior with migration guidance, or retain only if operation-specific current Paddle docs prove support. |
| Complete MockServer clone or calling mock proof “sandbox verified” | A clone drifts from the provider and blurs evidence classes. | Keep causal fixtures bounded to SDK contracts; record real credential-backed sandbox proof separately. |
| Phoenix/Ecto/app workflow ownership in core | Couples a pure SDK to consumer architecture and duplicates authorization, persistence, and entitlement policy. | Keep app responsibilities documented; use demos or optional adjacent packages for integration examples. |
| Mandatory merge queue or independent approval without matching project scale | Governance theater can slow a small maintainer base and make emergency recovery impossible. | Require protected status checks now; enable merge queue/independent approval when concurrency and reviewer availability justify them; record any bypass. |
| External planning system as the only source of truth | It makes repository-local provenance unavailable to future agents, contributors, and archived milestones. | Keep canonical durable records in `.planning/`; mirror to GitHub Projects only when useful. |
| Self-mutating cleanup automation | Automatic prune/delete/archive can destroy context or hide active work. | Health checks report; a maintainer performs explicit, reviewed state changes. |

## Feature Dependencies

```text
Repository inventory + non-destructive classification
  → clean-entry/exit worktree contract
  → focused PR and ownership contract

Persona/JTBD schema + status taxonomy
  → canonical coverage map
  → requirements/phase links
  → evidence freshness + bidirectional drift checks
  → durable short/mid/long trajectory

Provider-current safety research
  → telemetry/inspection redaction contract
  → retry/idempotency/client-validation contract
  → compatibility and migration truth
  → executable safety regression suite

Deterministic pinned CI
  → protected green main + exact-SHA CI proof
  → release/tag/package identity gate
  → optional artifact attestation and downstream verification
```

Cross-cutting dependency: no release-integrity claim is valid until the SDK safety changes, documentation truth, and full CI contract converge on the same source SHA.

## Recommended v2.2 Feature Slices

1. **Truth inventory and durable orientation**
   - Classify current repository/worktree state without deletion.
   - Reconcile active milestone state and milestone history.
   - Establish immutable persona/JTBD IDs, provenance fields, status taxonomy, horizon semantics, and the baseline trajectory.
   - Produces the requirement/evidence vocabulary every later slice consumes.

2. **SDK trust boundary**
   - Replace full-object telemetry with allowlisted metadata.
   - Redact credential-bearing public structs and raw payload inspection.
   - Align retries/idempotency with current Paddle guidance and provide compatibility/migration notes.
   - Validate client environment and credential inputs while preserving custom MockServer use.

3. **Clean contribution and green delivery**
   - Add clean worktree entry/exit checks, PR template, ownership map, and triage taxonomy.
   - Pin all Actions, minimize permissions, make the complete CI contract deterministic, and capture hosted exact-SHA green-main proof.
   - Measure and improve critical path without removing required evidence.

4. **Release integrity and memory health**
   - Gate both automatic and recovery publish paths on the complete exact-SHA contract.
   - Verify tag/version/package identity and persist release evidence.
   - Add focused drift checks for roadmap status, coverage links, and evidence freshness.
   - Evaluate artifact attestation only after the core release gate works.

## MVP Recommendation

Prioritize all table-stakes features needed to close the trust chain, but sequence them so each PR stays reviewable:

1. Preserve repository state and establish the coverage/provenance schema.
2. Fix credential exposure and provider-contradicting mutation safety before new API breadth.
3. Make the full exact-SHA CI contract required and restore hosted `main` green.
4. Make release publication consume that contract and retain evidence.

Defer package attestations, automated planning drift graphs, customer/transaction discovery, quote previews, and broader MockServer scenarios until the table-stakes chain is closed. They are differentiators or later-horizon candidates, not excuses to delay immediate safety and release integrity.

## Provenance and Confidence

### Local project evidence

These are direct repository observations used to scope features; paths are durable provenance anchors:

- `.planning/PROJECT.md` — v2.2 goal, short/mid/long baseline, active trust requirements, deliberate SDK boundary, and Accrue seam.
- `.planning/ROADMAP.md` — shipped history and current stale “No active milestone” statement after v2.2 initialization.
- `.planning/BACKLOG.md` — status taxonomy, promotion trail, and external Accrue B-04 ownership example.
- `.planning/EVIDENCE.md` — proof-class distinctions and the absence of hosted exact-SHA proof for prior local work.
- `README.md` and `guides/getting-started.md` — current adopter jobs, proof boundary, app/provider/SDK ownership, and documented idempotency claims.
- `lib/paddle/http/telemetry.ex` — full Req request/response structs are emitted as telemetry metadata.
- `lib/paddle/client.ex` and `lib/paddle/http.ex` — default transient retries and client-supplied `Idempotency-Key` support.
- `lib/paddle/notification_setting.ex` and `lib/paddle/portal_session.ex` — inconsistent secret-bearing inspection posture (portal URLs redacted; notification endpoint secret/raw response not redacted).
- `.github/workflows/ci.yml`, `release-please.yml`, and `hex-publish.yml` — pinned core CI Actions and CI contract exist; `release-please-action@v4` remains mutable; publish paths run only a subset of the complete CI contract.
- `git status --short` and `git worktree list --porcelain` on 2026-09-09 — modified `.tool-versions`, untracked planning state/cache, and a locked linked agent worktree were visible during research. These are observations to classify, not authorization to remove anything.

### Current primary sources

All web findings below were fetched through the configured research-plan provider, verified against official sources, and classified **MEDIUM** by the confidence seam.

- [GitHub: About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) — required checks, stale approvals, strict checks, merge queue, bypass, and force-push protections.
- [GitHub: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — full-length Action SHA pinning and privileged/untrusted workflow risks.
- [GitHub: Artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) — verifiable build provenance and the requirement that attestations be verified to provide value.
- [GitHub: Managing and standardizing pull requests](https://docs.github.com/en/pull-requests/reference/managing-and-standardizing-pull-requests) — PR templates, code ownership, and protected branch usage.
- [GitHub: Issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates) — structured contributor context and issue forms.
- [Git: `git-status`](https://git-scm.com/docs/git-status) and [Git: `git-worktree`](https://git-scm.com/docs/git-worktree) — stable porcelain status/inventory plus lock, repair, prune, and remove lifecycle.
- [Paddle: Libraries / common SDK patterns](https://developer.paddle.com/sdks/libraries/) — typed SDK expectations, webhook verification, no arbitrary client-supplied idempotency keys, reconciliation before retrying ambiguous creates, and semantic versioning.
- [Paddle: Authentication](https://developer.paddle.com/api-reference/about/authentication/) — server-side API keys are secrets; least-needed permissions, expiry, rotation, and exposure handling.
- [Paddle: Rate limiting](https://developer.paddle.com/api-reference/about/rate-limiting/) — `Retry-After` on rate-limited requests.
- [OpenSSF Scorecard checks](https://github.com/ossf/scorecard/blob/main/docs/checks.md) — branch protection, CI tests, review, pinned dependencies, token permissions, packaging, and signed-release expectations.
- [GitHub: Planning and tracking with Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects) and [archiving items automatically](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/archiving-items-automatically) — typed custom metadata, filtered roadmap/triage views, and archives that retain field data. These support the model but do not require adopting GitHub Projects as canonical storage.

## Open Questions for Phase Planning

- Determine whether removing the unsupported public `idempotency_key` option is an immediate breaking change, a deprecation path, or a pre-1.0 correction; inspect actual downstream Accrue use before deciding.
- Establish the current hosted branch-rule configuration and remote workflow results through GitHub, not repository YAML inference alone.
- Measure CI duration and flake history from hosted runs before choosing a numeric speed budget.
- Verify whether Hex package publication can practically carry or link a GitHub artifact attestation; do not commit to attestation until end-to-end consumer verification is demonstrated.
- Decide the smallest canonical storage format for the coverage map that remains readable in Markdown and mechanically checkable without duplicating `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, and `EVIDENCE.md`.
- Confirm maintainer/reviewer availability before requiring independent approvals or merge queue; branch protection and exact-SHA required checks remain mandatory regardless.
