# Phase 29: GSD State Reconciliation - Context

**Gathered:** 2026-06-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile oarlock's GSD planning state so future milestone planning starts from trustworthy project memory. This phase updates planning artifacts only: active backlog, historical backlog/archive trail, resolved investigation/thread handling, v2.0 audit and validation language, and durable GSD preferences. It does not add SDK runtime surface, public API breadth, adopter-facing feature docs beyond planning truth, live Paddle provider-state CI, or Accrue implementation changes.

</domain>

<decisions>
## Implementation Decisions

### Backlog Disposition
- **D-01:** Keep `.planning/BACKLOG.md` as the active planning queue. It should be short, scan-first, and limited to future work candidates or clearly labeled non-oarlock follow-ups.
- **D-02:** Create `.planning/BACKLOG-ARCHIVE.md` for shipped, superseded, or historical backlog entries. Preserve original backlog IDs and rationale; do not renumber B-IDs.
- **D-03:** Move shipped entries such as B-01, B-02, B-03, B-05, B-06, and B-07 to the archive as `Shipped`, with links to the phase or milestone that satisfied them.
- **D-04:** Keep B-04 active only as an `Accrue-only follow-up`. It must not be interpreted as oarlock SDK scope unless a later milestone explicitly promotes related oarlock work.
- **D-05:** Add a small status taxonomy near the top of backlog files: `Open`, `Accrue-only`, `Shipped`, `Superseded`, `Reference`. Only `Open` and explicitly selected `Accrue-only` items are candidates for new oarlock planning.

### Audit Evidence Language
- **D-06:** Use append-only errata and dated correction notes for historical planning truth. Do not silently rewrite past audits or summaries in a way that hides earlier overclaims.
- **D-07:** Add a compact canonical evidence ledger for v2.0/v2.1 planning proof, or an equivalent section in the relevant audit file, with columns for requirement, artifact, evidence class, command/proof, and caveat.
- **D-08:** Describe Phase 25 as validated via `.planning/phases/25-offline-mode-foundation/VALIDATION.md`; the standard `VERIFICATION.md` artifact was absent or non-standard. Do not imply the missing filename meant missing proof.
- **D-09:** Describe Phase 26 as MockServer-backed integration proof by default. Sandbox or live Paddle provider-state proof is available only when real credentials and provider-state checks are explicitly run and evidenced.
- **D-10:** Correct misleading wording such as "against Paddle state" with dated notes that clarify whether the state was MockServer state, sandbox state, or live provider state.

### Investigation Retention
- **D-11:** Preserve resolved investigations, but move them out of active-looking paths. Use `.planning/threads/resolved/YYYY/` for resolved threads and keep `.planning/threads/` for active threads.
- **D-12:** Add `.planning/threads/INDEX.md` with one row per thread: status, short lesson, canonical phase/context link, and reopen condition.
- **D-13:** Keep the subscription-create revalidation thread as resolved evidence. Its durable lesson is: do not add `Paddle.Subscriptions.create/2` unless current Paddle primary docs introduce a clean provider-native direct create API; recurring starts remain transaction/checkout or invoice-backed.
- **D-14:** Promote an investigation into an ADR-style decision record only when its conclusion governs public API shape, provider model, or recurring planning policy. Do not turn every small thread into an ADR.

### GSD Defaults Durability
- **D-15:** Split durable project policy from personal execution style. Project-local config should capture repo-specific judgment lenses and quality gates; user/global config should own autonomy and risk-tolerance knobs.
- **D-16:** Project-local defaults should preserve: research before planning, subagent research for gray areas, adopter-first assessment, DX/UX-first judgment, retained investigations, Nyquist validation, pattern mapping, and GSD docs/planning artifact durability.
- **D-17:** Keep autonomy controls explicit per run or user-global: `yolo`, `auto_advance`, aggressive parallelization, and model profile should not become surprising project policy for every contributor or agent.
- **D-18:** Treat `commit_docs` as permission to preserve GSD planning artifacts in repo history, not as blanket permission to auto-commit runtime code or unrelated planning edits.

### Coherent Planning Posture
- **D-19:** The overall Phase 29 strategy is active-small, archive-rich, and evidence-explicit. Future agents should encounter a small active queue first, with enough indexed history to understand why old ideas were shipped, superseded, or deliberately rejected.
- **D-20:** Follow the oarlock brand and engineering posture even in planning docs: precise, provider-native, calm, explicit about proof boundaries, and honest about unsupported scope.

### Claude's Discretion
- The planner may choose whether the canonical evidence ledger is a standalone `.planning/EVIDENCE.md` style artifact or an explicit section inside `.planning/v2.0-MILESTONE-AUDIT.md`, as long as future agents have one scan-friendly source for proof classification.
- The planner may use file moves or copied archive entries as long as old links remain understandable and historical B-IDs are preserved.
- The planner may add lightweight index templates for backlog/archive/threads if that reduces future drift without creating heavy process overhead.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 29 goal and success criteria.
- `.planning/REQUIREMENTS.md` — GSD-01 through GSD-04 requirements.
- `.planning/PROJECT.md` — Current milestone boundary, pure SDK constraints, and next-work posture.
- `.planning/STATE.md` — Current state and known GSD truth tasks.
- `.planning/config.json` — Existing workflow preferences and knobs to reconcile.

### Backlog and Milestone State
- `.planning/BACKLOG.md` — Current backlog entries and status text to split into active/archive surfaces.
- `.planning/MILESTONES.md` — Historical milestone log that should link to archived backlog items without becoming a raw backlog dump.
- `.planning/v2.0-MILESTONE-AUDIT.md` — Existing v2.0 audit caveats and evidence language.
- `.planning/milestones/v2.0-ROADMAP.md` — Archived v2.0 roadmap context.
- `.planning/milestones/v2.0-REQUIREMENTS.md` — Archived v2.0 requirement mapping.

### Validation and Verification Artifacts
- `.planning/phases/25-offline-mode-foundation/VALIDATION.md` — Phase 25 proof artifact with non-standard filename.
- `.planning/phases/26-advanced-subscription-flows-e2e/26-VERIFICATION.md` — Phase 26 MockServer-backed verification wording.
- `.planning/phases/27-public-contract-documentation-truth/27-CONTEXT.md` — Proof ladder and documentation truth decisions.
- `.planning/phases/28-ci-demo-and-package-proof/28-CONTEXT.md` — CI/package proof posture and Phase 29 deferral.
- `.planning/phases/28-ci-demo-and-package-proof/28-VALIDATION.md` — Recent validation artifact to keep proof language consistent.

### Threads and Research
- `.planning/threads/2026-05-30-subscription-create-revalidation.md` — Resolved investigation that should be indexed/archived with its durable lesson.
- `.planning/research/JTBD-GAPS.md` — Prior maintainer/adopter gaps including subscription-create revalidation context.
- `.planning/research/SUMMARY.md` — Prior research context for DX and demo posture.

### Prompt and Brand Context
- `prompts/oarlock-brand-book.md` — Current brand voice and positioning: steady, provider-native, explicit, honest, no official Paddle implication.
- `prompts/oarlock-master-context.md` — Core SDK DNA: explicit clients, typed responses, CI excellence, secure webhooks, no framework coupling.
- `prompts/paddle-elixir-lib-deep-research.md` — Prior research on Paddle Billing, Elixir SDK shape, proof strategy, and footguns.
- `prompts/accrue-paddle-sdk-minimum-surface-for-phase-1-2026-04-28.md` — Accrue-oriented minimum surface and provider-native recurring-start boundary.
- `prompts/accrue-second-processor-provider-recommendation-2026-04-28.md` — Strategic Paddle-vs-alternative provider context.

### External References Considered
- `https://keepachangelog.com/en/1.1.0/` — Human-oriented changelog/release history norms; supports keeping user-facing history curated rather than using it as a raw backlog.
- `https://sre.google/workbook/postmortem-culture/` — Append-only, factual, blameless evidence and follow-up culture for audit corrections.
- `https://semver.org/` — Precision around public API and release claims.
- `https://git-scm.com/docs/git-config` — Local/global/project config precedent for splitting shared policy from personal execution style.
- `https://editorconfig.org/` — Project-committed defaults precedent for shared style/policy.
- `https://12factor.net/config` — Boundary between code/project policy and environment/runtime-specific configuration.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/config.json`: Already contains many intended project lenses (`research_with_subagents`, `adopter_first_done_lens`, `retain_investigations`, `dx_ux_first`, `nyquist_validation`, `pattern_mapper`) and should be refined rather than invented from scratch.
- `.planning/BACKLOG.md`: Already has explicit status labels for shipped and Accrue-side work; Phase 29 should reorganize, not rediscover, the truth.
- `.planning/v2.0-MILESTONE-AUDIT.md`: Already states the two key caveats; Phase 29 should make those caveats canonical and consistent across stale wording.
- `.planning/threads/2026-05-30-subscription-create-revalidation.md`: Already has `Status: resolved` and a clear resolution; Phase 29 should improve information scent by moving/indexing it.

### Established Patterns
- Oarlock favors provider-native, demand-driven scope and avoids fake Stripe parity.
- Deterministic MockServer proof is valuable but must not be described as live Paddle provider-state proof.
- Planning artifacts are treated as durable project state and should be committed when generated by GSD workflows.
- Historical corrections should be explicit and dated, not cosmetic.

### Integration Points
- Update `.planning/BACKLOG.md` and create `.planning/BACKLOG-ARCHIVE.md`.
- Update `.planning/threads/` layout and add `.planning/threads/INDEX.md`.
- Update `.planning/v2.0-MILESTONE-AUDIT.md`, `.planning/MILESTONES.md`, and any Phase 25/26 proof wording that overclaims evidence.
- Update `.planning/config.json` or add explanatory comments/docs where supported by the project format, keeping personal automation knobs out of durable repo policy.

</code_context>

<specifics>
## Specific Ideas

The user asked for one cohesive, research-backed recommendation across all gray areas, with subagent research, pros/cons/tradeoffs, examples, ecosystem lessons, Elixir/Phoenix/Plug/Ecto library norms where applicable, developer ergonomics, principle of least surprise, and project vision alignment.

The resulting strategy is:
- Active backlog stays small and future-oriented.
- Historical work remains preserved, searchable, and linked, but not in the active planning queue.
- Audit truth is append-only and evidence-classified, especially around MockServer vs sandbox/live Paddle proof.
- Resolved investigations become indexed memory with reopen conditions, not active-looking work.
- Project-local defaults encode oarlock quality policy; personal/global defaults encode autonomy and execution appetite.

UI/UX considerations are indirect for this phase: the "interface" is the maintainer/agent planning surface. Optimize information scent, scanability, status clarity, and low surprise. Hide process guts from future milestone planning unless they are necessary evidence boundaries.

</specifics>

<deferred>
## Deferred Ideas

- Accrue-side `%Paddle.Error{}.raw` to `raw_data` migration remains an Accrue follow-up, not oarlock Phase 29 runtime work.
- Live Paddle sandbox/provider-state CI remains future/manual/on-demand unless a later phase solves credentials, isolation, and cleanup.
- Building a general GSD dashboard, UI, or heavy knowledge-graph system is out of scope; Phase 29 should use lightweight markdown/config artifacts.

</deferred>

---

*Phase: 29-GSD State Reconciliation*
*Context gathered: 2026-06-24*
