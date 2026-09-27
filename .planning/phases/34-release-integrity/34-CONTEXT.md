# Phase 34: Release Integrity - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Let release stewards publish only the exact, fully proven Oarlock package they intended through the automatic or recovery path. The release path must validate the exact candidate SHA against the complete accepted Phase 33 CI contract before the Hex publishing credential is made available; prove agreement among tag, source, package version, built package, and the package served by Hex; serialize publication safely; and retain durable, actionable evidence. Keep the public API and library behavior unchanged. This phase concerns the Oarlock Hex package release, not Paddle provider release behavior, app billing workflows, or an unrelated release dashboard.

<jtbd>
## Release Jobs and Operator Experience

- **Release steward / maintainer:** From a Release Please event or one recovery input, publish the intended version without having to understand CI internals. A failed gate should state which expected identity or evidence is missing, show the expected and observed values, and link to the relevant run. An ambiguous network result must reconcile with Hex before retrying.
- **Downstream Elixir adopter:** Install a package whose source revision passed the complete hosted CI contract and whose published package bytes match the reviewed release candidate. The package and versioned docs on Hex remain the user-facing distribution surface.
- **On-call or security reviewer:** Determine exactly which tag, commit, CI run/attempt, artifact, credential-gated publish, and Hex release/checksum produced a version, without relying on expired runner logs or an unsupported claim that local checks equal hosted proof.

Inputs originate in the automatic Release Please event or a maintainer-selected existing versioned tag. They are normalized to one immutable candidate commit and package version, checked against Phase 33 proof, built and dry-run checked, then passed to Hex. Outputs are the Hex package/docs and a durable release evidence record. There is no product UI to design; favor one recovery input, calm operator-facing action labels, concise logs, explicit safe next steps, and no internal credentials or irrelevant implementation details in errors.

</domain>

<decisions>
## Implementation Decisions

### Recovery candidate authority

- **D-01:** Recovery accepts one existing versioned release tag (the repository's `vX.Y.Z` form) as its only candidate input. Resolve it to one commit SHA and derive the package version from the tag. Do not accept an arbitrary SHA or a second independently typed version; do not create a tag in the recovery path. Protect release tags against deletion or movement. Recovery retries an already-authorized release, rather than creating a second release-authoring interface. — **Reversibility:** costly — Supporting arbitrary commits later would add a second release-intent and tag/version reconciliation path.
- **D-02:** Automatic and recovery paths normalize to the same `{tag, peeled SHA, package name, package version}` identity tuple and run the same fail-closed gate. A tag mismatch, missing tag, unexpected package name/version, stale or incomplete proof, absent required job, or mismatched SHA stops before the Hex secret is available. Derive the expected Hex version from the tag and validate it against `mix.exs`; do not trust caller input or `github.ref` alone.

### Exact-SHA proof and package identity

- **D-03:** Reuse Phase 33's accepted full `CI contract` proof for the exact peeled release SHA, including its run/attempt and retained proof artifact identity. A release-specific subset rerun, a green run on another SHA, a branch-name lookup, local green results, or a historical CI artifact cannot substitute. Automatic release waits for the exact main commit's accepted complete contract; recovery looks up the same contract for its tagged SHA.
- **D-04:** Check the full identity chain: Release Please version and tag spelling; the tag's resolved commit; exact-SHA CI proof; the package name `oarlock` (distinct from Mix app `:paddle`); `mix.exs` package version; built package metadata/checksum; Hex release version/checksum; and the fetched Hex tarball. Run the supported `mix hex.publish --dry-run` checks before credentials. Keep the normal Mix/Hex publication interface and validate that the pre-publication package checksum can be compared reliably with Hex's published checksum and retrieved tarball. Do not introduce a custom `hex_core` publisher merely to achieve build-once semantics unless research proves the supported Mix path cannot establish SHIP-02; custom publication would increase maintenance and surprise for an Elixir package maintainer.
- **D-05:** After Hex reports publication, retrieve the Hex release metadata and package tarball, compare the registry checksum to the expected package checksum, unpack/validate package name and version, and compile it from a clean downstream Mix consumer. Treat a successful version endpoint alone as insufficient evidence of package-byte agreement or installability. Capture meaningful `mix hex.publish` warnings/output so automation does not hide Hex's package guidance.

### Serialization, secrets, and recovery semantics

- **D-06:** Both workflows use one shared `hex-publish` concurrency group for the external package publication, with queued attempts and no cancellation of an in-progress publisher. Use the largest supported queue (`queue: max`) and expose that GitHub's queue limit/order is not a release-order guarantee. Revalidate the tag, exact-SHA CI identity, version, and Hex version/checksum after lock acquisition. Never let the Release Please workflow's separate metadata concurrency group stand in for this shared Hex publish lock.
- **D-07:** A missing Hex version after a confirmed failed/absent upload may be retried after revalidation. If a prior ambiguous submission already exists with the expected version and matching package checksum, record idempotent success without republishing. If the version exists with a different checksum, stop and report a release incident with expected/observed values; never overwrite, revert, or silently advance the version. Human action is limited to resolving a genuine external registry conflict or selecting a new version.
- **D-08:** Keep the Hex credential out of CI and secret-free preflight. Use an expiring Hex organization API-write key in the final publication environment, scoped to the publish step; do not expose it to tests, CI proof retrieval, artifact inspection, dry-run, or post-publish verification. Keep GitHub permissions minimal per job: read for proof/preflight/publish unless release metadata or evidence upload specifically requires write. Use environment-level secret delivery so candidate checks complete before the publishing job can access the release secret. No routine human approval is required for checks the workflow can prove reproducibly.

### Durable evidence and maintainer ergonomics

- **D-09:** After Hex package and downstream consumer verification complete, generate and attach a compact, versioned `release-evidence.json` to the corresponding GitHub Release. Include repository identity, tag, peeled SHA, package name/version, accepted CI run URL and attempt, CI proof artifact ID/digest, release workflow run, dry-run outcome, expected package checksum, Hex release URL/checksum, fetched tarball verification, downstream compile result, timestamps, and caveats. Store links, identifiers, and digests rather than duplicating large logs, package contents, credentials, or customer data.
- **D-10:** Treat the per-release manifest as the durable maintainer/adopter index and Hex's served registry metadata and package as the authority for published bytes. The recovery path must create or update the associated GitHub Release as needed and attach the same record, using a separate least-privileged GitHub-write step with no Hex secret. Do not mark a GitHub Release immutable before the post-publish manifest is attached; protect version tags from moving/deletion instead. `.planning/EVIDENCE.md` documents the evidence authority/schema and carries Phase 34 acceptance proof, while release-specific facts live beside each GitHub Release. Existing Actions artifacts and logs remain supplemental diagnostics with finite retention and cannot be the only durable trace.
- **D-11:** Use concise, plain operator language and actionable fail-closed errors: name the check, expected identity, observed identity, relevant run/tag link, and safe next step. Do not expose release credentials or make maintainers decode backend logs to determine whether a package was published. Follow Oarlock's calm, precise, developer-native brand voice. No visual design system or frontend component work applies to this phase.

### Agent's Discretion

- Exact script/module boundaries, JSON schema field names, output formatting, bounded retry/poll intervals, and implementation language remain open if they preserve the locked release contract.
- Research/planning may select the Hex-supported checksum extraction commands/API and demonstrate deterministic checksum agreement with the standard Mix publisher before fixing command details.
- Keep GitHub artifact attestations and a custom package publisher deferred unless exact Hex-served package provenance cannot be proven adequately through supported Mix/Hex checks or concrete adopter demand justifies their maintenance cost.
- Automate all repeatable release verification at the earliest useful boundary and in CI when recurring risk reduction warrants runtime/maintenance cost. Human handoff is reserved for external registry conflicts or other irreducible judgment, with automated evidence and closure criteria recorded.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current scope, requirements, and durable policy
- `.planning/PROJECT.md` — Pure Elixir SDK scope, supported consumer boundary, and project mission.
- `.planning/REQUIREMENTS.md` — SHIP-01 through SHIP-04 are the canonical committed release requirements.
- `.planning/ROADMAP.md` — Phase 34 goal, dependency, and success criteria.
- `.planning/STATE.md` — Current phase pointer and carried decisions.
- `.planning/GSD-PREFERENCES.md` — Automation-first, exact-SHA, least-surprise, proof-boundary, and context-safe handoff preferences.
- `.planning/EVIDENCE.md` — Canonical proof classification and append-only evidence precedent.
- `.planning/research/SUMMARY.md` — v2.2 ordering and research synthesis.
- `.planning/research/STACK.md` — CI, package, release, and tooling research.
- `.planning/research/FEATURES.md` — Release steward/adopter jobs, exact-SHA gate, release traceability, and provenance tradeoffs.
- `.planning/research/ARCHITECTURE.md` — Existing release gap and recommended cross-workflow gate/identity handoff.
- `.planning/research/PITFALLS.md` — Stale/wrong SHA, token-trigger, secret, race, registry, and evidence failure modes.

### Phase 33 proof contract to consume
- `.planning/phases/33-deterministic-green-ci/33-CI-HOSTED.md` — Latest exact-main acceptance and retained proof details; treat later SHA movement as requiring new observation.
- `.planning/phases/33-deterministic-green-ci/33-04-SUMMARY.md` — Completed hosted proof and main-rule outcome.
- `.github/workflows/ci.yml` — Full required CI contract and proof artifact generation.
- `scripts/ci_remote_gate.cjs` — Exact-SHA hosted acceptance query and proof validation interface.
- `scripts/ci_monitor.cjs` — Underlying exact-SHA hosted CI lookup.

### Existing publication implementation
- `.github/workflows/release-please.yml` — Automatic tag/release and Hex publication path; current independent metadata concurrency and release steps.
- `.github/workflows/hex-publish.yml` — Current manual recovery inputs, permissions, package checks, and publication path.
- `release-please-config.json` and `.release-please-manifest.json` — Tag/version generation and current release manifest baseline.
- `mix.exs` — Canonical package name, package files, Mix app name, package version, dependencies, and docs configuration.
- `mix.lock` — Resolved release build dependency identity.
- `bin/package_smoke.sh` — Existing downstream package installation/compile proof pattern.

### Project prompts and brand
- `prompts/oarlock-milestone-roadmap-ratchet.txt` — Evidence-led, bounded, adopter-first, automation-first project decision lens.
- `prompts/oarlock-brand-book.md` — Current brand voice and UX guidance; no frontend visual treatment applies here.

### External primary documentation consulted
- [Hex publishing guide](https://hex.pm/docs/publish) — Supported `mix hex.publish` path, CI API-write key guidance, post-publish consumer-test recommendation, and package warnings.
- [Hex FAQ](https://hex.pm/docs/faq) — Public package immutability and correction/revert limits.
- [Hex v2.5.1 `mix hex.publish` task](https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html) — Dry-run/build behavior and publish task options.
- [Hex package API specification](https://github.com/hexpm/specifications/blob/main/endpoints.md) and [hex_core repository/tarball API](https://hex-core.hexdocs.pm/hex_repo.html) — Release checksum and package tarball retrieval/validation.
- [GitHub Actions concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) — Cross-workflow groups, cancellation, queue capacity/order semantics.
- [GitHub Actions deployment environments](https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments) — Environment protection and delayed secret availability.
- [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) — Provenance properties and the need for consumer verification.
- [GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) — Tag/asset immutability tradeoffs.
- [Scrypath HexDocs release guide](https://hexdocs.pm/scrypath/releasing.html) — A public Elixir package example automating release/package checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci_remote_gate.cjs` and `scripts/ci_monitor.cjs`: query the exact hosted SHA, stable `CI contract` result, required jobs, and proof artifact; reuse rather than invent branch-name or latest-run selectors.
- `.github/workflows/ci.yml`: produces the existing compact exact-SHA CI proof artifact and already defines the full acceptance lanes.
- `bin/package_smoke.sh`: can inform the post-publish fresh-consumer install/compile check.
- `.planning/EVIDENCE.md`: existing record format separates proof class, source evidence, caveat, tag, declared package version, and publication status.

### Established Patterns
- Required evidence is exact-SHA, machine-verifiable, durable enough to audit, and distinct from local success; missing/ambiguous evidence blocks.
- Oarlock is a provider-native thin SDK, so release orchestration should stay explicit, small, and framework-neutral; no Phoenix, Plug, Ecto, or app billing workflow belongs in the core library.
- `.planning/EVIDENCE.md` and milestone identity rules distinguish source commit, Git tag, Mix package version, and Hex publication as separate facts.
- Phase 33 proves a hosted contract through a run/attempt and matching artifact digest; release logic can add package-specific checks without rerunning the whole suite as substitute evidence.
- The current workflows separately run a subset of tests, do not require the complete exact-SHA proof before Hex secret access, do not share one publisher lock, and do not compare the fetched Hex package checksum to the candidate package.

### Integration Points
- Release Please creates the automatic tag/release and supplies version/tag outputs; ensure its SHA and outputs are normalized and checked before publication.
- Manual `workflow_dispatch` currently accepts tag or SHA plus a separately typed version. Replace with the single existing release tag input and derive/check its package version.
- The final publish job needs the environment-scoped Hex API-write credential; secret-free proof and package preflight must finish first.
- After publishing, Hex API/repository checks verify release metadata, tarball checksum, package metadata, and fresh consumer compilation; then write durable compact release evidence.
- GitHub's shared concurrency control must serialize both workflows' external Hex side effect; Release Please's existing metadata lock does not.

</code_context>

<specifics>
## Specific Ideas

- Preserve the maintainer's explicit preference: automate repeatable verification and move high-signal checks into CI when recurring value justifies runtime and maintenance cost; do not require human UAT for deterministic release behavior.
- Make the safe operator flow one tag input; derive everything else and show checks as a small sequence with actionable failures.
- Validate from the adopter's perspective: the version visible and downloadable on Hex must match the accepted source and checksum, and a clean Mix consumer must fetch and compile it.
- Keep Hex as authority for what was published and the exact checksum; keep CI as authority for whether the SHA was accepted; join them using a compact evidence record.
- Recovery is a retry of an already-authorized tagged version. A different source/version needs a new reviewed release tag.
- Exact tarball attestation/custom publishing has stronger provenance but adds bespoke maintenance. Prefer supported Mix/Hex primitives unless a verified gap requires more machinery.

</specifics>

<deferred>
## Deferred Ideas

- Consumer-facing GitHub artifact attestations for package bytes and a custom canonical-tarball publisher — defer unless standard Mix publication cannot prove checksum agreement or concrete adopter demand supports the extra system.
- Creating release tags or choosing a new package version through the recovery workflow — belongs to release authoring and adds an unsafe second path.
- A release dashboard or frontend UI — out of scope; GitHub release surfaces and concise workflow output satisfy maintainer navigation for this phase.

</deferred>

---

*Phase: 34-release-integrity*
*Context gathered: 2026-09-25*
