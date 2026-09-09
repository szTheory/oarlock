# Architecture Patterns: Trust, Coverage & Green Delivery

**Project:** oarlock / Paddle Elixir SDK
**Domain:** SDK stewardship, delivery integrity, and durable planning provenance
**Researched:** 2026-09-09
**Overall confidence:** HIGH for repository observations; MEDIUM for current ecosystem recommendations verified through official GitHub and Git documentation

## Recommended Architecture

Treat v2.2 as five cooperating control planes around the existing pure SDK. Do not create a new application or move runtime behavior into CI/planning code.

```text
planning truth ──scopes──> repository change ──runs──> CI contract
      │                         │                       │
      │                         ├──changes──> SDK trust seams
      │                         │                       │
      └──records rationale      └──PR/worktree policy  └──exact-SHA proof
                                                               │
                                                               v
                                                     release gate + publish
                                                               │
                                                               v
                                                        evidence ledger
```

1. **Planning truth plane** owns what is active, why it exists, what evidence supports it, and how short-/mid-/long-term candidates change status.
2. **Repository lifecycle plane** owns clean worktree entry/exit, branch ownership, reviewable PRs, CODEOWNERS, and issue triage.
3. **SDK trust plane** owns credential-safe inspection/telemetry, client validation, and retry/idempotency semantics inside existing `Paddle.Client` and `Paddle.Http` seams.
4. **CI proof plane** owns a single aggregate `CI contract` check and a persisted proof document bound to the workflow run's exact SHA.
5. **Release plane** may publish only the exact commit already accepted by the CI proof plane; it has the only Hex credential boundary.

The central rule is **promotion, not duplication**: a source observation becomes a JTBD gap, then an active requirement, then a phase, then implementation proof, then shipped history. Each transition links backward. Research, backlog, archived phases, and generated caches must never become active scope merely because a scanner found their files.

## Verified Current State

These are direct repository or GitHub observations made on 2026-09-09, not proposed design:

- `.planning/STATE.md` says v2.2 is in planning, while `.planning/ROADMAP.md` still says no milestone is active. `.planning/state.json` is untracked and carries completed prior-milestone phases under the v2.2 field. Active routing therefore has contradictory inputs.
- Local `main` is 155 commits ahead of `origin/main`. No hosted run can prove current local HEAD until selected changes are pushed.
- The main worktree has a user modification to `.tool-versions`; an additional Claude worktree is registered and locked. These must be classified, not force-cleaned.
- `.github/workflows/ci.yml` fans out five jobs and aggregates them in `CI contract`. That job writes `ci-contract-proof.json`, but does not upload or otherwise persist it.
- `.github/workflows/release-please.yml` runs on the same `main` push as CI and can tag/release/publish after only its own compile/test/dry-run subset. It has no dependency on the matching `CI contract` result.
- `.github/workflows/hex-publish.yml` accepts a tag **or commit SHA**, reruns a subset, and can publish without exact-SHA CI evidence. Its checked-in steps need repository read, not the declared `contents: write`.
- `Paddle.Http.Telemetry` emits entire `Req.Request` values; `%Paddle.Client{}` retains both the API key and bearer-configured request. `Paddle.NotificationSetting` lacks custom inspection despite carrying `endpoint_secret_key` and raw provider data.
- Retries are enabled on the shared `Req` client before method/idempotency context is applied per call. The mutation safety decision is implicit rather than SDK-owned.

## Component Boundaries

| Component | Responsibility | Owns | Must Not Own |
|-----------|----------------|------|--------------|
| `Paddle.Client` | Validate configuration; construct transport; expose a safe public client value | Environment/base URL validation, redacted inspection, request defaults | Resource mutation policy or plaintext credential telemetry |
| `Paddle.Http` | Execute requests and normalize outcomes | Method-aware retry decision, idempotency header, safe metadata | Endpoint response hydration |
| `Paddle.Http.Telemetry` | Emit bounded lifecycle facts | Method, sanitized route/host, status/error class, duration/attempt | Requests, headers, bodies, keys, secrets, signed URLs |
| Public resource modules | Validate resource arguments and hydrate typed structs | Provider-native endpoint contracts | CI/release or app-owned billing workflows |
| Safe inspection protocols | Prevent disclosure at logs/console boundaries | Redaction for client, notification settings, secret URL structs | Mutation of stored values |
| CI fan-out jobs | Prove one concern each in parallel | Root tests, static analysis, demo, package consumer, optional deps | Release credentials or publishing |
| `CI contract` job | Aggregate mandatory results for one SHA | Stable required-check name, proof JSON, run/SHA/job conclusions | Reimplementation of each suite |
| `scripts/ci_monitor.cjs` | Resolve hosted evidence by exact SHA | Run selection, required job assertions, URL/SHA evidence | Newest-run or branch-name shortcuts |
| Release Please workflow | Release metadata/tag after exact-SHA CI | Release PR, tag identity, gated SHA handoff | Independent weaker definition of green |
| Hex publish job/environment | Package verification and irreversible publish | Hex credential, tag/version/SHA checks, dry-run, publish | PR code or an unproved arbitrary SHA |
| Planning canonical set | Describe intent, active work, evidence, history | Roles below | Generated caches as authority |
| GitHub collaboration surface | Collect actionable input/review context | Issue forms, PR template, CODEOWNERS, CONTRIBUTING | Replacing GSD requirements/roadmap/evidence |

## Planning Artifact Ownership

Future GSD routing should respect these explicit roles rather than infer state from directory presence.

| Artifact | Canonical role | Mutation rule | Routing authority |
|----------|----------------|---------------|-------------------|
| `.planning/PROJECT.md` | Durable scope, constraints, consumers, key decisions | Update at transitions with rationale | Context only |
| `.planning/TRAJECTORY.md` **(new)** | Baseline short/mid/long direction | Append status transitions; retain rationale and promotion/reopen conditions | Candidate orientation only |
| `.planning/JTBD-COVERAGE.md` **(new)** | Persona → job → capability/gap → source → proof | Stable IDs; update coverage/evidence links, never recycle IDs | Discovery input only until promoted |
| `.planning/REQUIREMENTS.md` | Active milestone contract | Selected, testable v2.2 requirements only | Yes: committed scope |
| `.planning/ROADMAP.md` | Active milestone phase graph plus horizon/history links | Exactly one current-milestone section | Yes, with `STATE.md` |
| `.planning/STATE.md` | Human-readable execution pointer | Derived from accepted roadmap and actual completion | Yes: current position |
| `.planning/state.json` | Machine-readable cache/mirror | Regenerate atomically or omit; never merge old discovery into a new milestone | No independent authority |
| `.planning/EVIDENCE.md` | Cross-milestone proof ledger | Append proof/additive corrections with SHA/run/class/caveat | Evidence lookup only |
| `.planning/BACKLOG.md` | Open/explicitly consumer-side candidates | Promotion retains ID in requirement source | Candidate input only |
| `.planning/BACKLOG-ARCHIVE.md` | Shipped/superseded/reference memory | Append-only except corrections | Never active |
| `.planning/MILESTONES.md` | Shipped milestone index | Add shipped record and archive/evidence links | Never active |
| `.planning/milestones/*` | Frozen roadmap/requirements/audit snapshots | Immutable; correct through ledger/dated erratum | Never active |
| `.planning/phases/*` | Phase-local decisions/plans/proof | Active only when current roadmap/state references it | Conditional on explicit current reference |
| `.planning/research/*` | Dated planning input | Replace only on deliberate research cycle | Never active by itself |
| `.planning/threads/INDEX.md` | Investigation index/reopen conditions | Preserve resolved links/status | Never active unless explicitly reopened |

Every trajectory/JTBD row should carry:

```text
stable ID | horizon/status | persona | JTBD | source type + locator + observed date
capability/gap | owning repo | rationale | promotion/reopen condition
requirement/phase link (if promoted) | evidence link (if proved) | last reviewed
```

Use only `committed`, `candidate`, `conditional`, `shipped`, and `superseded`. Append a dated transition note on status change rather than overwriting the original source/rationale.

## Exact-SHA Change-to-Release Flow

```text
clean classified worktree
  → narrow branch + PR context
  → parallel CI for candidate commit
  → CI contract aggregates every mandatory job
  → branch protection requires "CI contract" for latest SHA
  → merge to main
  → main CI proves merged github.sha and uploads proof JSON
  → release verifies successful CI run headSha == release SHA
  → Release Please creates tag/release from that SHA
  → publish asserts tag^{commit} == gated SHA
  → package dry-run → protected Hex environment → publish → index check
  → EVIDENCE.md records SHA, version/tag, run URL, proof class, caveat
```

### CI contract design

- Keep the existing fan-out for fast feedback.
- Keep one stable aggregate name, `CI contract`, and require it. Its `needs` list is the executable definition of green.
- Generate proof even on failure, then upload `ci-contract-proof.json` with `if: always()` and bounded retention. Include SHA, event, ref, workflow/run/attempt IDs, repository, and all required results.
- Do not treat a branch/tag/newest run/local test as hosted exact-SHA proof. The monitor must match `headSha` and emit the run URL.
- If merge queue is later adopted, add `merge_group` before enabling it; GitHub says required Actions checks otherwise will not run for merge groups.

### Release gate design

Add a small `await-main-ci` job to `release-please.yml` using the existing monitor against `${{ github.sha }}` with `actions: read`; make Release Please depend on it. This preserves `push: main` and removes the current release/CI race.

If a release is created, pass the gated SHA explicitly. Before exposing `HEX_API_KEY`, fetch tags and assert:

```text
resolved tag commit == gated main SHA == successful CI run headSha
```

Retain compile/version/package dry-run checks, but do not claim that subset replaces the CI contract. Put `HEX_API_KEY` behind a named GitHub environment where available, minimize publish permissions to `contents: read`, and keep PR CI secret-free.

Manual recovery should accept an existing release tag, resolve it to a commit, require a successful exact-SHA CI contract, verify `mix.exs` version, then publish. Remove arbitrary untagged SHA publishing unless a separate emergency policy authorizes it.

GitHub documents that most events created with `GITHUB_TOKEN` do not start another workflow. Release Please PR updates therefore need an explicitly tested credential path (fine-grained token/GitHub App), or a documented maintainer approval step for token-created PR runs. Do not assume chained CI happened because release automation succeeded.

## Worktree and PR Lifecycle

```text
inventory → classify → isolate → implement → verify → PR → merge/close → clean → remove → prune dry-run
```

1. **Inventory:** Parse `git worktree list --porcelain -z`; record branch, HEAD, lock/prunable state, tracked/untracked changes, upstream, owner/purpose.
2. **Classify:** `active`, `preserve-user-work`, `ready-to-remove`, `stale-metadata`, or `unknown`. Unknown/dirty/locked blocks cleanup.
3. **Isolate:** Once main is reconciled, enable worktree-per-change in supported GSD config and create one narrow branch per plan/PR.
4. **Entry gate:** Start from intended base SHA with no unrelated modifications. Preserve pre-existing work in its original tree.
5. **Exit gate:** Tests pass; status is empty except explicitly documented generated artifacts; branch is pushed/retained intentionally; evidence is linked.
6. **Removal:** Use `git worktree remove` for clean completed trees and `git worktree prune --dry-run --verbose` before pruning metadata. Understand/unlock locks explicitly; never routine double-force.

The PR template should require problem/JTBD/source, bounded change/non-goals, risk, proof commands, exact-SHA CI link, docs/compatibility effect, secret/retry review, and worktree cleanup. Issue forms should capture persona/job, evidence, owning repository, and acceptance proof. CODEOWNERS routes review; it is not proof by itself.

## SDK Trust Seams

### Safe metadata projection

Telemetry should emit an allowlist, not transport structs:

```elixir
%{method: :get, route: "/transactions/:id", host: "api.paddle.com",
  status: 200, result: :ok, attempt: 1}
```

Use monotonic duration for elapsed time. Tests must prove API keys, authorization/idempotency headers, bodies, endpoint secrets, and signed Paddle URLs are absent from start/stop/exception events.

### Inspection boundary

Add custom `Inspect` for `%Paddle.Client{}` and `%Paddle.NotificationSetting{}`. Redact both `endpoint_secret_key` and any secret-bearing duplicate in `raw_data`. Reuse the existing portal-session redaction pattern.

### Mutation-aware retry policy

Centralize eligibility in `Paddle.Http` using method plus idempotency context. Safe reads may retry transient failures. Mutations default to no automatic retry unless explicitly safe or protected by a valid idempotency key under the provider contract. Resource modules declare supported options; HTTP owns the final invariant and attempt-count tests.

### Client validation

Validate non-empty keys, supported environments, absolute HTTP(S) base URLs, and coherent custom-base semantics before constructing Req. Keep explicit clients and pure-library boundaries unchanged.

## New Files vs Modified Files

### New

| File | Purpose | Dependency |
|------|---------|------------|
| `.planning/TRAJECTORY.md` | Durable horizons with transition provenance | Planning ownership contract |
| `.planning/JTBD-COVERAGE.md` | Persona/job/gap/proof matrix | Stable taxonomy/source IDs |
| `CONTRIBUTING.md` | Worktree, branch, PR, test, cleanup lifecycle | Reconciled repository |
| `.github/CODEOWNERS` | Responsibility/review routing | Confirm real owners |
| `.github/pull_request_template.md` | Change/JTBD/proof/risk context | PR contract |
| `.github/ISSUE_TEMPLATE/bug.yml` | Reproducible defect intake | Triage taxonomy |
| `.github/ISSUE_TEMPLATE/capability.yml` | Persona/JTBD/provenance intake | JTBD schema |
| `.github/ISSUE_TEMPLATE/config.yml` | Chooser/contact policy | Issue forms |
| `bin/check_worktree_state.sh` (or tested equivalent) | Read-only inventory and clean entry/exit checks | Classification rules |
| Tests for repository/provenance guards | Prevent unsafe cleanup and active/archive contamination | Schemas/scripts first |

### Modified

| File | Change | Dependency |
|------|--------|------------|
| `.planning/ROADMAP.md` | Add v2.2 phases; link trajectory/history; remove inactive drift | Requirements accepted |
| `.planning/STATE.md` | Point only to v2.2/current step | Roadmap accepted |
| `.planning/state.json` | Regenerate as mirror or remove from routing | Precedence decided |
| `.planning/PROJECT.md` | Link JTBD/trajectory and durable decisions | New planning files |
| `.planning/EVIDENCE.md` | Generalize and append exact-SHA schema | CI proof contract |
| `.planning/GSD-PREFERENCES.md` / `config.json` | Enable/document worktrees and scan precedence after cleanup | Lifecycle validated |
| `.github/workflows/ci.yml` | Persist proof and keep stable aggregate gate | CI contract tests |
| `scripts/ci_monitor.cjs` + test | Exact SHA/run URL/attempt/jobs; reject ambiguity | Proof schema |
| `.github/workflows/release-please.yml` | Await main CI, hand off gated SHA, least privilege | Hosted CI proof |
| `.github/workflows/hex-publish.yml` | Tag-only recovery and exact-SHA gate | Release contract |
| `lib/paddle/http/telemetry.ex` | Allowlisted metadata and duration | Safety tests |
| `lib/paddle/client.ex` | Validation/redacted inspection | Client tests |
| `lib/paddle/http.ex` | Method/idempotency-aware retries | Retry matrix |
| `lib/paddle/notification_setting.ex` | Secret-safe inspection/raw data | Inspect tests |
| Guides/changelog/seam docs | State safety/retry/compatibility truth | Runtime complete |

## Dependency-Aware Build Order

### 1. Repository truth and planning compass

Reconcile roadmap/state/cache; inventory/classify every worktree and dirty path; repair milestone links; define artifact precedence; create trajectory/JTBD schemas. This is first because cleanup and all later planning depend on knowing what is user work and authoritative scope.

**Exit proof:** a consistency guard rejects today's contradictions; each dirty/locked tree has an owner/disposition; v2.2 requirements cite sources; horizons stay discoverable without becoming phases.

### 2. SDK trust boundary

Write failing tests for safe telemetry/inspection, validation, and mutation retries; implement narrow changes in existing seams; update public contract docs after behavior stabilizes.

**Exit proof:** secret absence and retry attempt counts are proved; downstream seam remains green.

### 3. Deterministic CI and exact-SHA evidence

Preserve parallel jobs, establish/persist the aggregate contract, update the monitor, push a narrow branch, and capture hosted proof. This converts local confidence to auditable GitHub state.

**Exit proof:** one hosted URL shows all mandatory jobs and aggregate success for the exact SHA; uploaded proof matches; required-check setting is verified/documented.

### 4. Release integrity and collaboration contracts

Wire both release paths to exact-SHA CI, protect/minimize publication, and add CODEOWNERS/templates/CONTRIBUTING/triage. Release depends on trustworthy CI.

**Exit proof:** mismatched/unproved SHA fails before secret access; matching candidate reaches dry-run; PR/issue context preserves provenance; cleanup is shown without force.

### 5. Milestone reconciliation and durable handoff

Update coverage/trajectory with evidence, append run coordinates, close/promote candidates explicitly, and run the contamination guard before archiving.

**Exit proof:** fresh progress routing sees genuine active work only; shipped/superseded rationale remains searchable; main and retained worktrees have documented clean state.

## Patterns to Follow

- **One executable quality contract:** the aggregate CI job is required; fan-out can evolve behind it.
- **Immutable evidence coordinates:** store repository, SHA, workflow/run/attempt, URL, job results, verified time, proof class, caveat.
- **Append-only provenance:** preserve source and all horizon status transitions.
- **Least-privilege separation:** PR CI reads without secrets; release metadata and Hex publish have separate minimal permissions.
- **Reversible operations:** inventory/dry-run first; preserve unknown work; use supported worktree remove/prune/repair.

## Anti-Patterns to Avoid

| Anti-pattern | Failure | Replacement |
|--------------|---------|-------------|
| Parallel unequal definitions of green | Release can pass while required CI fails | Release consumes exact-SHA aggregate CI; adds package dry-run |
| Newest-run/branch-name evidence | Proof binds wrong code during races/divergence | Compare full SHAs at every handoff |
| Raw transport telemetry | Credentials/customer data reach handlers | Documented allowlist |
| Directory-presence routing | Stale/shipped files become active work | Explicit current roadmap/state references only |
| Destructive cleanliness | Unclassified user work is lost | Classify/preserve, then remove clean trees |
| Unversioned roadmap wish list | Candidates silently become promises | Separate active roadmap from cross-linked trajectory |

## Scale and Change-Volume Considerations

| Concern | Current scale | More contributors/PRs | Public maturity |
|---------|---------------|-----------------------|-----------------|
| CI | Parallel fan-out + aggregate | Add merge-group trigger only with queue | Compatibility matrix + provenance |
| Worktrees | Owner/disposition per tree | Automated inventory/ownership TTL | Maintainer cleanup policy |
| Triage | Two forms + small labels | Review SLA and owning repo | Security/deprecation intake |
| Planning | Stable Markdown IDs | Generated views, never new authority | Publish support/deprecation history |
| Evidence | Run URL + SHA + class | Reviewed automated ledger proposals | Attest consumer release artifacts |

Artifact attestations are a later fit for an actual release package/download. GitHub advises attesting consumer artifacts rather than frequent test-only output, so first persist CI proof and close the SHA gate.

## Sources and Confidence

### Primary repository evidence — HIGH

- Required planning files, three workflows, monitor script, SDK transport/telemetry/client, and secret-bearing structs inspected 2026-09-09.
- Local Git status/worktree/local-remote counts and hosted run list inspected 2026-09-09. A successful feature-branch run at SHA `44bf2823c8f11614700eeaa645e74c8bd88fd081` and historical main failure at `fb3d9a185f104194e85987541519a6168e0b568c` do not prove current local HEAD.

### Official ecosystem sources — MEDIUM

The configured seam fetched official sources through Brave; `classify-confidence --provider brave --verified` returned MEDIUM.

- [Required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) — latest-SHA requirement and merge-group trigger.
- [Protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) — checks, reviews, strictness, merge queue.
- [Workflow artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data) — retention and digest behavior.
- [Artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) — provenance contents and usage boundary.
- [Triggering workflows](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow) — `GITHUB_TOKEN` chaining behavior.
- [Compromised runners](https://docs.github.com/en/actions/concepts/security/compromised-runners) — secret/untrusted-code boundary.
- [git-worktree](https://git-scm.com/docs/git-worktree) — inventory, lock, remove, prune dry-run, repair.
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) — location and review routing.
- [Issue and PR templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests) — standardized intake.

## Open Questions for Phase Discussion

- Confirm real GitHub user/team handles for CODEOWNERS.
- Confirm repository support for required checks/environments and whether merge queue is warranted.
- Decide whether `state.json` is a tested versioned mirror or omitted; it cannot stay ambiguous.
- Verify Paddle's current idempotency guarantees per mutation before locking retry defaults.
- Confirm protected-environment/reviewer support for Hex publication; exact-SHA gating remains required either way.
