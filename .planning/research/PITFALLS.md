# Domain Pitfalls

**Domain:** Trustworthy stewardship of an existing Elixir SDK: security, delivery, worktrees, review, and durable JTBD/provenance planning
**Project:** oarlock / Paddle Elixir SDK
**Milestone:** v2.2 Trust, Coverage & Green Delivery
**Researched:** 2026-09-09
**Overall confidence:** HIGH for repository facts; MEDIUM for changing external behavior verified in official primary documentation

## Executive Warning

The highest-risk mistake is treating v2.2 as generic cleanup. The repository already contains concrete trust failures: a prior SUMMARY claimed code that had not been committed; root planning identifies v2.2 as active while `ROADMAP.md` says there is no active milestone; local `main` is 155 commits ahead of `origin/main`; GitHub reports `main` is unprotected; two old PRs remain open; and a linked agent worktree remains locked. These are not cosmetic inconsistencies. They show that claims, source state, hosted proof, and release automation can diverge.

The second critical mistake is preserving the current retry/idempotency story as safe. oarlock configures Req with `retry: :transient`, which retries all HTTP methods, while Paddle's official SDK guidance says arbitrary client-supplied idempotency keys are not supported and warns that a timed-out create may already have succeeded. Safety work must change runtime behavior and public claims together.

## Critical Pitfalls

### Pitfall 1: Credentials and one-shot secrets escape through structs, telemetry, and `raw_data`

**What goes wrong:** API keys, portal-session URLs, notification endpoint secrets, request bodies, or sensitive response fields reach logs, telemetry handlers, crash reports, or developer inspection output.

**Why it happens:** Redaction is treated as a property of one promoted field instead of an end-to-end data-flow boundary. `Paddle.Http.Telemetry` emits whole `%Req.Request{}` values on start/stop/error and a whole `%Req.Response{}` on stop. `%Paddle.Client{}` contains both `api_key` and a Req request configured with bearer auth. `%Paddle.NotificationSetting{}` exposes `endpoint_secret_key` and preserves it again in `raw_data`. `%Paddle.PortalSession{}` replaces promoted `urls` during inspection but still prints `raw_data`, which can contain those same authenticated URLs.

**Consequences:** Credential compromise, unauthorized API access, customer portal session hijacking, webhook forgery, and secret retention in observability systems.

**Warning signs:**

- Telemetry metadata contains `request`, `response`, `headers`, `body`, or `raw_data` without an allowlist.
- Redaction tests construct structs without realistic `raw_data`.
- `inspect/1` of a client, notification setting, or provider-built portal session contains a canary.

**Prevention:** In **SDK Safety & Contract Truth**, define allowlisted telemetry containing method, sanitized route, status, duration, attempt count, and normalized error class—never request/response structs or bodies. Implement deny-by-default `Inspect` behavior for every credential- or secret-bearing struct, including nested raw payloads. Add canary tests for all telemetry outcomes and sensitive structs.

**Detection / proof:** Attach a telemetry handler and recursively assert unique canaries are absent; inspect provider-built structs with secrets duplicated in promoted and `raw_data` fields; run docs-truth guards.

**Fact vs inference:** Metadata and struct contents are repository facts. Exploit impact is a security inference. Elixir officially supports `Inspect` `:only`/`:except` to hide private fields.

**Provenance:** `lib/paddle/http/telemetry.ex`, `lib/paddle/client.ex`, `lib/paddle/notification_setting.ex`, `lib/paddle/portal_session.ex`, `lib/paddle/http.ex`; [Elixir Inspect](https://hexdocs.pm/elixir/Inspect.html); [Paddle authentication](https://developer.paddle.com/api-reference/about/authentication/). Confidence: HIGH/MEDIUM.

### Pitfall 2: Automatic mutation retries create duplicate or ambiguous provider state

**What goes wrong:** A POST/PATCH/DELETE succeeds at Paddle, its response is lost, and Req repeats it. A caller receives an error or second result without knowing the first operation's state.

**Why it happens:** `Paddle.Client.new!/1` sets `retry: :transient` globally. Req documents that `:transient` retries all HTTP methods; `:safe_transient` limits HTTP-response retries to GET/HEAD. oarlock also exposes `idempotency_key` for creates, but Paddle says arbitrary operations do not support client-supplied idempotency keys. A mock asserting header presence is not provider deduplication proof.

**Consequences:** Duplicate creates, charges or credits; repeated lifecycle mutation; and a misleading reliability guarantee that downstream Accrue may trust.

**Warning signs:** any mutation inherits `:transient`; tests prove only header presence; 5xx/timeout tests do not model “provider committed, response lost”; docs call a mutation idempotent solely because a key is accepted.

**Prevention:** In **SDK Safety & Contract Truth**, default automatic retry to safe reads. Make mutation replay opt-in only where current Paddle docs establish safe semantics; otherwise return a typed ambiguous-outcome error with reconciliation guidance. Honor `Retry-After` on 429 without replaying unsafe mutations. Deprecate, remove, or relabel unsupported `idempotency_key` options with migration notes.

**Detection / proof:** A method-by-status retry matrix covers every verb; adapter tests prove no automatic mutation replay; docs contain no unsupported provider guarantee; sandbox/provider proof is required before claiming deduplication.

**Fact vs inference:** Req and Paddle behavior are verified facts. Duplicate effects are reachable risks Paddle explicitly warns about, not observed incidents.

**Provenance:** `lib/paddle/client.ex`, resource option types, HTTP tests; [Req retry options](https://req.hexdocs.pm/Req.Steps.html#retry/1-request-options); [Paddle SDK retry/idempotency guidance](https://developer.paddle.com/sdks/libraries/); [Paddle rate limiting](https://developer.paddle.com/api-reference/about/rate-limiting/). Confidence: HIGH/MEDIUM.

### Pitfall 3: Publishing outruns the full exact-SHA CI contract

**What goes wrong:** A tag and Hex package are produced from a SHA that never passed the same complete contract expected of normal CI.

**Why it happens:** `release-please.yml` runs independently on pushes to `main`. Its publish job depends only on Release Please and reruns compile, library tests, version check, and Hex dry-run; it does not require `ci-contract`, Dialyzer/specs, demo PostgreSQL, package-smoke, optional-dependency proof, or SUMMARY drift. Manual recovery has the same weaker subset. GitHub reports no branch protection/ruleset. The last hosted remote-main push (`fb3d9a1`) shows CI failed while independent Release Please succeeded on that SHA.

**Consequences:** False-green release status, broken optional/demo/downstream behavior, unverifiable provenance, and painful recovery after distribution.

**Warning signs:** publish `needs` omits the canonical contract; release and CI run concurrently for one SHA; manual recovery accepts a ref/version without full-gate evidence; “CI green” lacks SHA, run URL, attempt, and job results.

**Prevention:** In **Green CI & Release Integrity**, use one immutable source SHA as the join key. Protect `main`; require the uniquely named `CI contract` from GitHub Actions on the latest relevant SHA; prevent bypass; use strict checks or merge queue if warranted. Publish only after successful full-contract evidence for the tag's resolved SHA. Reuse the same gate for automated and recovery paths. Serialize publishing and retain dry-run/package evidence. Use a dedicated expiring least-privilege Hex key.

**Detection / proof:** A deliberately failed required job blocks merge and publish; tests reject missing/stale/mismatched/skipped/failed SHA evidence; the ledger links hosted run and package verification for the same SHA.

**Fact vs inference:** Workflow topology, remote run results, and absent protection are facts. No bad package publication is asserted.

**Provenance:** workflow YAML; GitHub protection API checked 2026-09-09; [failed main CI](https://github.com/szTheory/oarlock/actions/runs/27216688735); [same-SHA Release Please](https://github.com/szTheory/oarlock/actions/runs/27216687066); [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches); [Hex publishing](https://hex.pm/docs/publish). Confidence: HIGH.

### Pitfall 4: Cancellation and automation-token behavior erase proof or skip CI

**What goes wrong:** A needed main run is canceled, a release is interrupted by a later push, or an automation-authored PR/tag fails to trigger required checks.

**Why it happens:** `ci.yml` uses `cancel-in-progress: true` for every ref, including main. Release Please also cancels in-progress work despite publication side effects. GitHub documents that events created by `GITHUB_TOKEN` generally do not create new workflow runs; this repository's optional PAT makes behavior configuration-dependent.

**Consequences:** Missing exact-SHA proof, release PRs without CI, partially executed automation, and risky manual retries.

**Prevention:** In **Green CI & Release Integrity**, cancel obsolete PR-head CI only; never cancel main evidence or publish side effects. Queue releases. Assert credential mode and a deterministic trigger contract for automation PRs. If merge queue is later enabled, add `merge_group` to CI triggers.

**Detection / proof:** Static workflow tests cover triggers, concurrency, token mode, and `needs`; an automated PR fixture produces the required check; the SHA monitor treats canceled/skipped/missing as unverified.

**Provenance:** workflows and `scripts/ci_monitor.cjs`; [GitHub workflow triggering](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow); [GitHub concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency); [required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks). Confidence: HIGH/MEDIUM.

### Pitfall 5: “Cleanup” destroys unclassified work or preserves hidden worktree state forever

**What goes wrong:** Unknown local changes are deleted, a completed agent worktree stays locked, a branch is assumed available while checked out elsewhere, or work begins from an undocumented dirty base.

**Why it happens:** Cleanliness is treated as a destructive command instead of classification. At research time, `main` is 155 commits ahead of `origin/main`; active agents have modified research/toolchain files; untracked planning state exists; and `.claude/worktrees/agent-ae2a0ae67dfb5008f` is locked at an older branch. Intentional concurrent work and residue look alike without owner/base/purpose metadata.

**Consequences:** Lost work, mixed commits, branch collisions, irreproducible PRs, and cleanup fear that lets residue accumulate.

**Warning signs:** unclean entry; lock with unknown owner/process/purpose; `--force`, manual directory deletion, or broad restore proposed before inventory; PR mixes planning, runtime, toolchain, and unrelated fixes.

**Prevention:** Make **Repository & Planning Truth** first. Capture status porcelain, worktree porcelain, branch/base SHA, ahead/behind, process liveness, owner, and disposition. Classify every path/worktree as active/preserve, commit, handoff, archive, ignore, remove, or repair. Never force-remove an unclean/locked worktree without a recoverable snapshot and ownership decision. Establish clean-entry/exit gates.

**Detection / proof:** Commit before/after manifests; every retained worktree has owner/reason/revisit date; every removal was clean or has a recovery reference; main exits clean after concurrent work finishes.

**Fact vs inference:** Current inventory is fact. Whether the linked worktree is abandoned is unknown and must not be inferred from age or lock alone.

**Provenance:** Git porcelain commands observed 2026-09-09; [Git worktree](https://git-scm.com/docs/git-worktree). Confidence: HIGH.

### Pitfall 6: Planning files disagree and summaries become stronger evidence than Git

**What goes wrong:** Agents route from stale files, archived work looks active, requirements close with local-only proof, or a SUMMARY is believed despite absent commits.

**Why it happens:** Files duplicate state without precedence/invariants. `PROJECT.md` and `STATE.md` say v2.2 is active while `ROADMAP.md` says “No active milestone.” `STATE.md` still says to start the next milestone. `MILESTONES.md` omits v1.2 and v1.4 although `ROADMAP.md` lists them. History records a Phase 7 SUMMARY claiming implementation/docs that remained uncommitted until retroactive repair.

**Consequences:** Lost signal, phantom completion, repeated research, roadmap churn, and release/audit claims based on a state that never existed.

**Prevention:** In **Repository & Planning Truth**, define canonical ownership per datum and machine-check cross-file invariants. Use append-only corrections. A summary may point to proof but cannot be proof itself. Record requirement → phase/plan → commit/SHA → proof class → command/run URL → caveat. Check status/HEAD immediately before completion summaries.

**Detection / proof:** Planning integrity fails on milestone disagreement, missing log entries, dangling IDs/evidence paths, stale transitions, and uncommitted implementation claims.

**Provenance:** root planning artifacts and v1.1 audit trail in `MILESTONES.md`. Confidence: HIGH.

## Moderate Pitfalls

### Pitfall 7: Candidate horizons silently become commitments

**What goes wrong:** Mid-/long-term ideas are read as promised scope, inserted into near-term phases, or judged overdue.

**Prevention:** In **JTBD Coverage & Durable Trajectory**, give each item an immutable ID and status (`committed`, `candidate`, `conditional`, `rejected`, `superseded`, `shipped`), horizon, source/date, persona/JTBD, rationale, owner/repository, proof, non-goals, freshness trigger, and promotion/reopen condition. Append status transitions rather than overwriting them. Only current milestone requirements are commitments.

**Warning signs:** “will” for work absent from requirements; candidate lacks named job or proof; old rationale disappears after reprioritization.

**Detection / proof:** Schema rejects entries without status/provenance; roadmap visually separates statuses; history stays discoverable.

**Provenance:** `PROJECT.md` horizons, `BACKLOG.md` taxonomy, `threads/INDEX.md`, user direction on 2026-09-09. Confidence: HIGH.

### Pitfall 8: Endpoint mirroring substitutes breadth for job coverage

**What goes wrong:** Paddle resources are added because they exist, expanding compatibility burden without improving a validated adopter job.

**Prevention:** In **JTBD Coverage & Durable Trajectory**, require a persona/job, source evidence, ownership boundary, existing-seam gap, and acceptance proof before promotion. Preserve anti-features: no Classic, framework/database coupling, app-owned entitlements/provisioning, or direct subscription create without provider-native API. Promote operational discovery only with adopter evidence.

**Warning signs:** endpoint count as success; generated CRUD without workflow evidence; “parity” without a consumer.

**Detection / proof:** Every public addition maps to a JTBD ID and consumer evidence; unmapped additions fail roadmap review.

**Provenance:** `PROJECT.md`, `GSD-PREFERENCES.md`, resolved subscription-create thread. Confidence: HIGH.

### Pitfall 9: Dependency upgrades are bundled, weakly reviewed, or reduce reproducibility

**What goes wrong:** Runtime, Hex deps, actions, service images, and installers change together; failures cannot be attributed; mutable tags/latest installers change behavior without a source diff.

**Prevention:** In **Green CI & Release Integrity**, inventory all update surfaces, then batch by risk: tooling/dev patch-minor, runtime patch-minor, direct runtime deps, majors, publishing infrastructure. Isolate lockfile diffs and run package-smoke/optional proof. Add dependency review where eligible. Continue full-SHA action pins and pin Release Please too; record readable versions beside SHAs. Deliberately address Hex/Rebar installers and `postgres:17`. Never combine dependency churn with retry semantics.

**Warning signs:** one PR changes `.tool-versions`, both lockfiles, actions, and runtime code; cache restores across incompatible dimensions; mutable major action; latest installer during release.

**Detection / proof:** Dependency PR records versions, advisories, lockfile review, compatibility matrix, rollback, and exact gates; CI verifies toolchain availability early.

**Fact vs inference:** Most actions are SHA-pinned, Release Please is `@v4`, PostgreSQL is `postgres:17`, and tool installers fetch during runs. Actual variability must be measured.

**Provenance:** workflows/lockfiles; [GitHub dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-review); [GitHub action SHA guidance](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax); [Actions threat protection](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats); [Hex publishing](https://hex.pm/docs/publish). Confidence: HIGH/MEDIUM.

### Pitfall 10: PR/triage policy becomes ceremony—or remains absent

**What goes wrong:** Mixed PRs remain unreviewable, stale PRs have no next action, sensitive files lack accountable review, or heavyweight rules block a single maintainer without adding assurance.

**Why it happens:** No PR template, CODEOWNERS, issue templates, or visible triage contract was found. GitHub shows two open PRs from June 2026 and no issues; one is a failing Release Please PR. Boilerplate alone will not resolve ownership.

**Prevention:** In **Review, Ownership & Triage**, require a concise PR contract: intent/persona/JTBD or issue, bounded change, risk, compatibility/security/release impact, non-goals, exact commands/hosted run, rollback. Give every open item type, priority, owner, state, next action, and close/revisit condition. Use CODEOWNERS only where a real eligible reviewer exists. Prefer small dependency-ordered PRs to one cleanup mega-PR.

**Detection / proof:** Every open PR has disposition; real PR validates review/check configuration; stale automation PRs close/supersede with provenance.

**Provenance:** `.github/` and authenticated GitHub inventory, 2026-09-09; [PR #4](https://github.com/szTheory/oarlock/pull/4); [PR #5](https://github.com/szTheory/oarlock/pull/5); [protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches). Confidence: HIGH.

### Pitfall 11: Client validation fixes break legitimate mock/custom use

**What goes wrong:** Empty keys, unsupported environments, or malformed URLs fail late today; an overcorrection later rejects MockServer/custom adapters or hard-codes a credential format Paddle may change.

**Prevention:** In **SDK Safety & Contract Truth**, validate stable invariants only: nonblank key, known environment atom, absolute HTTP(S) URL, consistent defaults, and documented custom/mock escape hatch. Do not embed a brittle full key regex. Separate construction validation from network authentication and keep errors redacted.

**Warning signs:** `environment: :anything` maps to sandbox; blank key constructs; custom URL becomes impossible; errors print the secret.

**Detection / proof:** Table tests cover sandbox/live/custom and invalid inputs; canaries never appear; MockServer remains green.

**Provenance:** `lib/paddle/client.ex`; project MockServer constraint; [Paddle authentication](https://developer.paddle.com/api-reference/about/authentication/). Confidence: HIGH/MEDIUM.

## Minor Pitfalls

### Pitfall 12: Fast CI is achieved by deleting independent proof

**What goes wrong:** Dialyzer, demo, package-smoke, optional-dependency, or planning-integrity gates are removed solely to reduce duration.

**Prevention:** Optimize queue time, caches, duplicated setup, and critical path first. Preserve parallel proof and require one lightweight contract job. Measure median/tail duration before changes.

**Detection:** Optimization PR includes timing evidence and an unchanged or explicitly superseded proof matrix.

### Pitfall 13: Local, MockServer, hosted, sandbox, and live evidence collapse into “verified”

**What goes wrong:** Local proof is overstated as provider/release proof, or dismissed despite its valid class.

**Prevention:** Retain typed evidence classes; every claim names class, SHA, environment, command/run, timestamp, result, and caveat. Never strengthen evidence through wording.

**Detection:** Evidence lint rejects bare “verified”; docs truth preserves the proof ladder.

## Phase-Specific Warnings

| Milestone phase topic | Likely pitfall | Mandatory mitigation / exit evidence |
|---|---|---|
| Repository & Planning Truth (first) | Destroy concurrent work; infer lock means abandoned; contradictory history | Inventory/classify every dirty path, branch, remote delta, PR, and worktree; reconcile canonical state with append-only errata; planning integrity passes |
| SDK Safety & Contract Truth | Partial redaction; unsafe all-method retries; false idempotency guarantee | Allowlisted telemetry; Inspect tests including `raw_data`; safe-read retry matrix; ambiguous mutation contract; compatibility/docs migration together |
| Green CI & Release Integrity | Publish before full exact-SHA proof; cancellation; bot PR skips CI; dependency mega-upgrade | Protected main; authoritative required contract; full-gate tag-SHA dependency; serialized publish; recovery parity; staged upgrades; hosted failure proof |
| Review, Ownership & Triage | Templates without ownership; cleanup mega-PR; stale bots | Minimal PR contract; maintainer-compatible review; triaged open work; explicit owners/next actions; small sequenced PRs |
| JTBD Coverage & Durable Trajectory | Candidate read as promise; endpoint mirroring; overwritten rationale | Canonical persona/JTBD/provenance registry; status/horizon semantics; promotion/reopen rules; append-only status history |
| Milestone verification/close | Local green mistaken for hosted green; SUMMARY treated as proof | Exact source SHA and hosted jobs; package/tag/version agreement; clean worktrees/planning invariants; then summarize/archive |

## Recommended Ordering

1. **Repository & Planning Truth** — establish actual state/evidence before changing or deleting anything.
2. **SDK Safety & Contract Truth** — close credential and mutation risks before public breadth.
3. **Green CI & Release Integrity** — enforce the repaired contract at merge/publish; split upgrades.
4. **Review, Ownership & Triage** — institutionalize clean worktrees, small PRs, ownership, and queue discipline.
5. **JTBD Coverage & Durable Trajectory** — encode short/mid/long compass once state/status/evidence vocabulary is stable.
6. **Exact-SHA milestone verification** — prove the chain before shipping v2.2.

## Deeper Phase Research Flags

- **Retry migration:** inventory every mutation's retry/idempotency API, provider semantics, compatibility impact, and Accrue usage before choosing deprecation versus breaking correction.
- **Release gate:** verify whether rulesets, branch protection, reusable workflows, merge queue, and attestations fit repository plan/ownership. Do not design around unavailable features.
- **Dependency reproducibility:** measure installer/action/container variability and cache correctness before choosing pins.
- **JTBD completeness:** validate persona and operational-discovery candidates against Accrue and a cold-adopter journey before v2.3 promotion.

## Sources

### Repository-primary (HIGH)

- `.planning/PROJECT.md`, `STATE.md`, `ROADMAP.md`, `MILESTONES.md`, `EVIDENCE.md`, `GSD-PREFERENCES.md`, `BACKLOG.md`, `threads/INDEX.md`, `RETROSPECTIVE.md`
- `.github/workflows/ci.yml`, `release-please.yml`, `hex-publish.yml`, `scripts/ci_monitor.cjs`
- `lib/paddle/client.ex`, `http.ex`, `http/telemetry.ex`, `notification_setting.ex`, `portal_session.ex`
- Git porcelain and authenticated GitHub protection/run/PR queries observed 2026-09-09

### Current official primary documentation (MEDIUM through fallback provider)

- [Paddle shared SDK patterns](https://developer.paddle.com/sdks/libraries/)
- [Paddle authentication](https://developer.paddle.com/api-reference/about/authentication/)
- [Paddle rate limiting](https://developer.paddle.com/api-reference/about/rate-limiting/)
- [Paddle versioning](https://developer.paddle.com/api-reference/about/versioning/)
- [Req retry options](https://req.hexdocs.pm/Req.Steps.html#retry/1-request-options)
- [Elixir Inspect](https://hexdocs.pm/elixir/Inspect.html)
- [Git worktree](https://git-scm.com/docs/git-worktree)
- [GitHub workflow triggering](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)
- [GitHub concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency)
- [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)
- [GitHub dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-review)
- [GitHub Actions threat protection](https://docs.github.com/en/code-security/tutorials/secure-your-organization/protect-against-threats)
- [Hex publishing](https://hex.pm/docs/publish)

## Confidence Notes

- Repository findings are HIGH because they come from tracked files, Git porcelain, and authenticated GitHub queries.
- External behavior is MEDIUM under the GSD seam because Brave and Context7 were unavailable; official primary documents were retrieved with the web-search fallback and cross-checked against local behavior.
- No duplicate charge, credential incident, or bad Hex publication is claimed to have occurred. These are reachable risks, not observed incidents.
