# JTBD Coverage and Durable Trajectory

This file is the canonical job and capability decision record. Persona and lifecycle
indexes are navigation only; they link here and do not own status, rationale, history,
or evidence. IDs are permanent anchors even when a title or wording changes.

## Horizon and commitment vocabulary

Horizon and commitment are independent axes. Horizon is `short`, `mid`, or `long`.
Commitment is `shipped`, `committed`, `candidate`, `conditional`, `rejected`,
`external`, or `superseded`. A distant horizon is not a promise, and a short
horizon does not imply shipped work. Every decision change appends a dated row to
that record's Status history table.

## Trajectory baseline

| Horizon | Status baseline | Meaning | Promotion or reconsideration |
|---------|-----------------|---------|-------------------------------|
| short | shipped or committed | Current v2.2 SDK trust and stewardship work | Replan with dated source, owner, rationale, impact, and prior state. |
| mid | candidate | Customer and transaction discovery, quote preview, bounded MockServer coverage | Promote only for a named job, current provider research, smallest coherent surface, owner, and proof contract. |
| long | conditional or external | Accrue adoption and demand-backed contract expansion | Activate only when consumer, support, maturity, or procurement evidence justifies it. |

The controlled status vocabulary remains complete even when no current job has a
particular status. `rejected` records a considered direction that should not proceed;
`superseded` preserves a decision replaced by a dated successor.

## JTBD-ADOPT-01

| Field | Value |
|-------|-------|
| actor | Adopter engineer |
| situation | When adding Paddle Billing to an Elixir application |
| outcome | I need a typed, documented SDK boundary so I can integrate without guessing provider behavior. |
| capability | Oarlock documents and tests its supported billing operations, client configuration, errors, and proof limits. |
| smallest_gap | Application persistence, entitlement policy, and live provider setup remain outside the SDK. |
| boundary | Oarlock owns the typed request seam; the application owns persistence and policy; Paddle owns provider behavior. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock maintainers |
| adopter_owner | unknown; persona: adopter engineer |
| rationale | Keep the SDK narrow and let adopters distinguish shipped behavior from app and provider responsibilities. |
| requirement_phase | SAFE-04@Phase 32; SAFE-06@Phase 32; ORIENT-01@Phase 36; ORIENT-02@Phase 36 |
| proof | Focused contract tests and exact-SHA hosted CI; provider-state claims need separately recorded sandbox or live evidence. |
| evidence | .planning/EVIDENCE.md; .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_class | Phase verification and local contract proof |
| evidence_identity | .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_caveat | Local and MockServer checks do not establish live provider state. |
| freshness | Refresh when the public SDK contract, requirement mapping, or proof identity changes. |
| non_goal | Does not promise application-owned billing policy or live-provider verification. |
| promotion | Reopen when a named adopter needs an SDK capability beyond the documented typed seam. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none; no distinct active backlog item owns this shipped job |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record the existing supported adopter seam without widening product scope. | .planning/EVIDENCE.md | Local, hosted, MockServer, and provider proof classes remain distinct. |

## JTBD-RELIABILITY-01

| Field | Value |
|-------|-------|
| actor | Application reliability engineer |
| situation | When a Paddle read or mutation times out or receives a transient response |
| outcome | I need bounded read retries and clear ambiguous-mutation guidance so I can avoid duplicate billing actions. |
| capability | Oarlock retries the documented safe read set and returns reconciliation guidance for ambiguous mutations. |
| smallest_gap | The application still owns its reconciliation workflow and any customer-facing recovery policy. |
| boundary | Oarlock classifies transport behavior; the application owns workflow recovery; Paddle owns final transaction state. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock maintainers for transport; adopter application for recovery |
| adopter_owner | unknown; persona: application team |
| rationale | Avoid automatic replay of mutations whose provider outcome is uncertain. |
| requirement_phase | SAFE-04@Phase 32; ORIENT-02@Phase 36 |
| proof | Retry and ambiguous-outcome fixtures plus exact-SHA hosted CI; provider state requires separate sandbox or live readback. |
| evidence | .planning/EVIDENCE.md; .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_class | Phase verification and local retry contract proof |
| evidence_identity | .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_caveat | Local fixtures do not establish live provider state. |
| freshness | Refresh when retry rules, provider guidance, or the public error contract changes. |
| non_goal | Does not guarantee mutation success or automatically reconcile provider state. |
| promotion | Reopen for a named retry or recovery gap backed by current provider guidance and a safe proof contract. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none; no distinct active backlog item owns this shipped job |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Preserve the bounded read and mutation safety contract. | .planning/EVIDENCE.md | MockServer and local tests do not establish live provider state. |

## JTBD-SECURITY-01

| Field | Value |
|-------|-------|
| actor | Security and privacy operator |
| situation | When credentials, payloads, or request metadata pass through logs, errors, or inspection |
| outcome | I need sensitive values excluded from observable SDK surfaces so I can reduce accidental disclosure. |
| capability | Oarlock redacts credential-bearing structs and emits allowlisted transport telemetry. |
| smallest_gap | Deployments still own log access, retention, and application-level secret handling. |
| boundary | Oarlock controls its structs and telemetry; adopters control deployment policy and logs. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock maintainers for SDK surfaces; adopter for deployment controls |
| adopter_owner | unknown; persona: application security owner |
| rationale | Secret safety must be demonstrated by tests rather than assumed from caller discipline. |
| requirement_phase | SAFE-02@Phase 32; SAFE-03@Phase 32; ORIENT-02@Phase 36 |
| proof | Sentinel-secret inspection and telemetry fixtures plus exact-SHA hosted CI. |
| evidence | .planning/EVIDENCE.md; .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_class | Phase verification and security fixture proof |
| evidence_identity | .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_caveat | SDK fixtures do not certify downstream logs. |
| freshness | Refresh when a public struct, telemetry event, error payload, or log path changes. |
| non_goal | Does not certify adopter infrastructure or its retention controls. |
| promotion | Reopen when a new secret-bearing SDK surface lacks an explicit redaction contract. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none; no distinct active backlog item owns this shipped job |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Keep tested credential and payload boundaries visible. | .planning/EVIDENCE.md | SDK fixtures do not certify downstream logs. |

## JTBD-CONTRIBUTOR-01

| Field | Value |
|-------|-------|
| actor | Contributor |
| situation | When proposing a bounded SDK or repository change |
| outcome | I need clear ownership and proof expectations so I can submit a reviewable change. |
| capability | The repository provides contribution, security, issue, PR, and worktree guidance. |
| smallest_gap | A contributor still needs to state the concrete user impact and run the checks relevant to the change. |
| boundary | Repository guidance governs contribution flow; contributors own their proposal and evidence; maintainers decide acceptance. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock maintainers |
| adopter_owner | not applicable; repository contribution role |
| rationale | Proportional evidence and one bounded intent make small-project review practical. |
| requirement_phase | OPS-01@Phase 35; OPS-03@Phase 35; ORIENT-02@Phase 36 |
| proof | Documentation and workflow contract checks on the exact candidate SHA. |
| evidence | .planning/REQUIREMENTS.md; .github/ISSUE_TEMPLATE/change_proposal.yml; .github/pull_request_template.md |
| evidence_class | Contribution workflow contract and planning evidence |
| evidence_identity | .github/pull_request_template.md |
| evidence_caveat | Maintainers retain acceptance authority. |
| freshness | Refresh when contribution policy, ownership routes, or worktree procedures change. |
| non_goal | Does not promise an independent reviewer or automatic acceptance. |
| promotion | Reopen when contributor feedback identifies a repeated unclear or unsafe step. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none; no distinct active backlog item owns this shipped job |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record the existing bounded contribution path. | .planning/EVIDENCE.md | The maintainer retains acceptance authority. |

## JTBD-REVIEW-01

| Field | Value |
|-------|-------|
| actor | Reviewer and maintainer |
| situation | When deciding whether a proposed change is correct, in scope, and ready |
| outcome | I need intent, risk, ownership, and proof in one reviewable change so I can make a grounded decision. |
| capability | Issue triage and PR guidance state scope, status, owner, next action, and evidence expectations. |
| smallest_gap | Review judgment remains human and may be constrained by independent reviewer availability. |
| boundary | Contributors provide context; maintainers own triage and merge decisions; CI supplies only its defined machine evidence. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock maintainers |
| adopter_owner | not applicable; repository review role |
| rationale | Triage and review need explicit ownership without creating unsupported process promises. |
| requirement_phase | OPS-01@Phase 35; OPS-02@Phase 35; ORIENT-02@Phase 36 |
| proof | Issue/PR contract fixtures and exact-SHA required CI evidence. |
| evidence | .planning/REQUIREMENTS.md; .github/ISSUE_TEMPLATE/change_proposal.yml; .github/pull_request_template.md |
| evidence_class | Review workflow contract and planning evidence |
| evidence_identity | .github/pull_request_template.md |
| evidence_caveat | Reviewer availability is not guaranteed. |
| freshness | Refresh when triage taxonomy, PR requirements, or review policy changes. |
| non_goal | Does not require a merge queue or guarantee an independent reviewer. |
| promotion | Reopen if contributor volume or incidents demonstrate a need for stronger review routing. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none; no distinct active backlog item owns this shipped job |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Preserve an explicit, proportional review path. | .planning/EVIDENCE.md | Reviewer availability is not guaranteed. |

## JTBD-RELEASE-01

| Field | Value |
|-------|-------|
| actor | Release steward |
| situation | When publishing a package or recovering an interrupted release |
| outcome | I need tag, package, artifact, and exact-SHA CI identities to agree so I can publish traceable bytes. |
| capability | Release automation gates publication on the required exact-SHA contract and records package identity evidence. |
| smallest_gap | Historical releases retain their own caveats and are not retroactively upgraded by current controls. |
| boundary | Oarlock controls source and workflow; GitHub provides hosted run/artifact state; Hex serves published package bytes. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock release maintainers |
| adopter_owner | not applicable; repository release role |
| rationale | Publication is accepted only when source, run, artifact, and package identities can be reconciled. |
| requirement_phase | CI-04@Phase 33; CI-05@Phase 33; SHIP-01@Phase 34; SHIP-04@Phase 34; ORIENT-02@Phase 36 |
| proof | Release gate and retained artifact identity for the exact source SHA; package/API readback for publication claims. |
| evidence | .planning/EVIDENCE.md; .github/workflows/hex-publish.yml; .github/workflows/release-please.yml |
| evidence_class | Release workflow contract and historical evidence record |
| evidence_identity | .planning/EVIDENCE.md |
| evidence_caveat | v0.1.2 exact candidate bytes and durable evidence remain unresolved. |
| freshness | Refresh for each candidate SHA, workflow attempt, artifact, tag, or published package. |
| non_goal | Does not erase pre-control release caveats or infer package bytes from a tag name. |
| promotion | Reopen on an identity mismatch, missing artifact, or release path that bypasses the contract. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none; no distinct active backlog item owns this shipped job |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock release maintainers | Record the v2.2 release integrity contract with its historical exceptions intact. | .planning/EVIDENCE.md | The v0.1.2 exception has no recovered candidate bytes or evidence asset. |

## JTBD-STEWARD-01

| Field | Value |
|-------|-------|
| actor | Project steward and future planner |
| situation | When scope changes or a milestone closes |
| outcome | I need to distinguish capability, horizon, commitment, and proof so I can revise direction without losing its history. |
| capability | Phase 36 commits to one canonical JTBD record set, link-only indexes, cross-reference validation, and an evidence-bounded handoff. |
| smallest_gap | The new map and checks are committed scope until implementation, review, and exact-SHA evidence are complete. |
| boundary | Oarlock owns repository planning records; source owners own external facts; maintainers decide promotion. |
| source | 2026-09-09: .planning/PROJECT.md; 2026-09-26: .planning/ROADMAP.md, .planning/REQUIREMENTS.md |
| owner | oarlock maintainers |
| adopter_owner | not applicable; repository planning role |
| rationale | One authority and dated transitions prevent indexes or horizon labels from becoming accidental commitments. |
| requirement_phase | ORIENT-01@Phase 36; ORIENT-02@Phase 36; ORIENT-03@Phase 36; ORIENT-04@Phase 36; ORIENT-05@Phase 36; ORIENT-06@Phase 37 |
| proof | Validator fixtures, live read-only checks, byte-prefix history checks, and the exact candidate handoff proof when available. |
| evidence | .planning/ROADMAP.md; .planning/REQUIREMENTS.md |
| evidence_class | Planning research and phase plan evidence |
| evidence_identity | .planning/ROADMAP.md |
| evidence_caveat | The map describes planning authority and does not prove implementation completion. |
| freshness | Refresh when an authority, phase mapping, status, proof identity, or source-specific freshness event changes. |
| non_goal | This planning record does not implement future candidate SDK features. |
| promotion | Continue only after each decision has named evidence, owner, boundary, and acceptance proof. |
| horizon | short |
| commitment_status | committed |
| trajectory_group | short/committed |
| backlog_archive | none; Phase 36 is committed requirement scope |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | short | unknown | committed | .planning/REQUIREMENTS.md | oarlock maintainers | Phase 36 is mapped committed v2.2 scope. | .planning/phases/36-jtbd-coverage-durable-trajectory-handoff/36-01-PLAN.md | Plan intent is not completion proof. |
| 2026-09-27 | short | short | committed | committed | .planning/REQUIREMENTS.md | oarlock maintainers | Completed Phase 36 implementation is retained; the audited ORIENT-06 operational acceptance gap is assigned to Phase 37. | .planning/phases/37-milestone-closeout-reconciliation/37-CONTEXT.md | Phase 37 is planned, not accepted closeout; requirement meaning and future scope are unchanged. |

## JTBD-ACCRUE-01

| Field | Value |
|-------|-------|
| actor | Downstream SDK and library maintainer at Accrue |
| situation | When consuming a packaged Oarlock release in a real Paddle-backed flow |
| outcome | I need a stable, verified dependency path so I can use one Paddle seam inside the downstream abstraction. |
| capability | Oarlock publishes its package under its own release contract; Accrue adoption is a separate repository job. |
| smallest_gap | A named Accrue adopter, packaged vertical-slice proof, and downstream migration owner must be established. |
| boundary | Oarlock owns its package; Accrue owns its adapter and migration; Paddle owns provider behavior. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md and .planning/BACKLOG.md |
| owner | external:accrue for adoption; oarlock maintainer for discovery |
| adopter_owner | external:accrue |
| rationale | Keep consumer-side integration external until an owner and real adoption evidence exist. |
| requirement_phase | ACCRUE-01@Future Requirements; B-04@BACKLOG.md; no committed phase mapping |
| proof | Named Accrue maintainer, exact package/version, and one real Paddle-backed vertical slice with retained result. |
| evidence | .planning/BACKLOG.md; .planning/research/FEATURES.md |
| evidence_class | External adoption boundary and active backlog reference |
| evidence_identity | .planning/BACKLOG.md |
| evidence_caveat | Cross-repository adoption has not been independently confirmed. |
| freshness | Recheck at each proposed promotion and when the Accrue seam or package identity changes. |
| non_goal | Does not claim that Accrue has adopted the current package or that provider proof exists. |
| promotion | Promote only with named downstream owner, current consumer evidence, and a bounded acceptance contract. |
| horizon | long |
| commitment_status | conditional |
| trajectory_group | long/conditional |
| backlog_archive | B-04 in .planning/BACKLOG.md; cross-repository adoption remains externally owned |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | long | unknown | conditional | .planning/REQUIREMENTS.md | external:accrue | Keep package adoption conditional on a named consumer and vertical-slice proof. | .planning/BACKLOG.md | No downstream adoption proof is asserted. |

## JTBD-ACCRUE-02

| Field | Value |
|-------|-------|
| actor | Accrue maintainer |
| situation | When migrating downstream code that refers to the old Paddle error raw field |
| outcome | I need the owning repository to migrate against the published contract so I can keep its adapter compiling. |
| capability | Oarlock exposes its own `raw_data` contract; Accrue-side migration is not controlled here. |
| smallest_gap | The Accrue owner must confirm actual call sites, migration scope, and release compatibility. |
| boundary | Oarlock owns the public type; external:accrue owns call-site migration and downstream tests. |
| source | 2026-09-09: .planning/REQUIREMENTS.md; 2026-09-26: .planning/BACKLOG.md |
| owner | external:accrue; Oarlock discovery owner is a maintainer |
| adopter_owner | external:accrue |
| rationale | A downstream migration must not be represented as an Oarlock source change. |
| requirement_phase | ACCRUE-02@Future Requirements; B-04@BACKLOG.md; no committed phase mapping |
| proof | Named downstream owner, exact migrated call sites, and consumer tests against a pinned Oarlock release. |
| evidence | .planning/BACKLOG.md; .planning/REQUIREMENTS.md |
| evidence_class | External adoption boundary and active backlog reference |
| evidence_identity | .planning/BACKLOG.md |
| evidence_caveat | Downstream transaction behavior remains owned by Accrue. |
| freshness | Recheck when Accrue's public dependency or relevant call sites change. |
| non_goal | Does not claim that Accrue's repository or call sites were modified. |
| promotion | Promote only when Accrue identifies the owner and confirms the concrete migration scope. |
| horizon | long |
| commitment_status | external |
| trajectory_group | long/external |
| backlog_archive | B-04 in .planning/BACKLOG.md; downstream disposition remains with Accrue |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | long | unknown | external | .planning/REQUIREMENTS.md | external:accrue | Preserve the downstream repository ownership boundary. | .planning/BACKLOG.md | The current call-site inventory is unknown. |

## JTBD-DISC-01

| Field | Value |
|-------|-------|
| actor | Support or reconciliation operator |
| situation | When investigating a billing outcome without already knowing a Paddle customer ID |
| outcome | I need safe customer discovery so I can find the relevant provider record. |
| capability | Oarlock has no committed discovery operation for this job. |
| smallest_gap | A named adopter, privacy boundary, provider-supported query, and bounded pagination proof are unknown. |
| boundary | Oarlock may own a narrow API seam; the adopter owns support access and case policy; Paddle owns records. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md DISC-01 |
| owner | oarlock maintainer for discovery; adopter owner unknown |
| adopter_owner | unknown |
| rationale | Keep this discoverable without advertising an unbuilt operator capability. |
| requirement_phase | DISC-01@Future Requirements; no committed phase mapping |
| proof | Current official provider documentation, a named adopter job, bounded pagination fixtures, and a privacy review. |
| evidence | .planning/research/FEATURES.md; .planning/REQUIREMENTS.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/research/FEATURES.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | At-use refresh of official provider API/version guidance before promotion. |
| non_goal | Does not claim customer search exists or that an external operator owns this job. |
| promotion | Promote only with a named adopter, current provider source, least-data contract, and acceptance proof. |
| horizon | mid |
| commitment_status | candidate |
| trajectory_group | mid/candidate |
| backlog_archive | none; candidate is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | mid | unknown | candidate | .planning/REQUIREMENTS.md | oarlock maintainer for discovery | Retain as a candidate pending named adopter evidence. | .planning/research/FEATURES.md | 2026-05-30 research is not current provider proof. |

## JTBD-DISC-02

| Field | Value |
|-------|-------|
| actor | Support, finance, or reconciliation operator |
| situation | When explaining a transaction without already knowing its provider transaction ID |
| outcome | I need bounded transaction discovery so I can reconcile the reported outcome. |
| capability | Oarlock has no committed transaction discovery operation for this job. |
| smallest_gap | A named adopter, least-data query, provider behavior, and paging contract remain unverified. |
| boundary | Oarlock may own a typed read; the adopter owns access and reconciliation policy; Paddle owns transaction state. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md DISC-02 |
| owner | oarlock maintainer for discovery; adopter owner unknown |
| adopter_owner | unknown |
| rationale | Keep a useful operator direction as a candidate until the job and owner are evidenced. |
| requirement_phase | DISC-02@Future Requirements; no committed phase mapping |
| proof | Current official provider documentation, named adopter evidence, paging fixtures, and a privacy review. |
| evidence | .planning/research/FEATURES.md; .planning/REQUIREMENTS.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/research/FEATURES.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | At-use refresh of provider documentation and version behavior before promotion. |
| non_goal | Does not claim transaction discovery is implemented or available to operators. |
| promotion | Promote only with named adopter, current provider source, bounded data access, and testable acceptance. |
| horizon | mid |
| commitment_status | candidate |
| trajectory_group | mid/candidate |
| backlog_archive | none; candidate is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | mid | unknown | candidate | .planning/REQUIREMENTS.md | oarlock maintainer for discovery | Keep transaction discovery conditional on source and adopter evidence. | .planning/research/FEATURES.md | Historical discovery research is not current provider proof. |

## JTBD-QUOTE-01

| Field | Value |
|-------|-------|
| actor | SaaS integrator |
| situation | When a supported billing change may alter price or proration |
| outcome | I need a quote before mutation so I can explain the expected amount before committing. |
| capability | Oarlock does not commit to a quote or proration preview operation. |
| smallest_gap | Current provider API stability, a named consumer job, and the smallest safe typed seam are unverified. |
| boundary | Oarlock may expose a provider operation; the application owns display and consent; Paddle computes provider amounts. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md QUOTE-01 |
| owner | oarlock maintainer for discovery; adopter owner unknown |
| adopter_owner | unknown |
| rationale | Pricing previews are useful only when provider semantics and consumer need are current. |
| requirement_phase | QUOTE-01@Future Requirements; no committed phase mapping |
| proof | Current official provider documentation, a named adopter workflow, decimal/rounding semantics, and mutation-boundary fixtures. |
| evidence | .planning/research/FEATURES.md; .planning/REQUIREMENTS.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/research/FEATURES.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | Recheck official provider version and quote semantics immediately before promotion. |
| non_goal | Does not promise a numeric threshold, rounding rule, or quote operation. |
| promotion | Promote only with a named consumer, current provider contract, and explicit precision proof. |
| horizon | mid |
| commitment_status | candidate |
| trajectory_group | mid/candidate |
| backlog_archive | none; candidate is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | mid | unknown | candidate | .planning/REQUIREMENTS.md | oarlock maintainer for discovery | Keep quote preview uncommitted until provider semantics and a consumer are verified. | .planning/research/FEATURES.md | No numeric behavior is inferred from research prose. |

## JTBD-MOCK-01

| Field | Value |
|-------|-------|
| actor | Offline SDK adopter |
| situation | When exercising a documented flow without Paddle credentials |
| outcome | I need selected causal mock behavior so I can test integration handling deterministically. |
| capability | Oarlock has a MockServer test fixture, but broader causal-flow coverage is not a committed feature. |
| smallest_gap | Which flows and error envelopes matter to a named adopter is not yet established. |
| boundary | Oarlock owns only its documented fixture; adopters own their application scenarios; live Paddle remains separate. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md MOCK-01 |
| owner | oarlock maintainer for discovery; adopter owner unknown |
| adopter_owner | unknown |
| rationale | Expand offline fixtures only for supported flows with concrete test value. |
| requirement_phase | MOCK-01@Future Requirements; no committed phase mapping |
| proof | Named flows, explicit state transitions, realistic error fixtures, and consumer-tested examples. |
| evidence | .planning/EVIDENCE.md; .planning/REQUIREMENTS.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/REQUIREMENTS.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | Refresh with public SDK operations, mock contract, or adopter test needs. |
| non_goal | Does not represent the live Paddle API or establish provider-state proof. |
| promotion | Promote only for named offline-supported jobs and a bounded fixture contract. |
| horizon | mid |
| commitment_status | candidate |
| trajectory_group | mid/candidate |
| backlog_archive | none; candidate is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | mid | unknown | candidate | .planning/REQUIREMENTS.md | oarlock maintainer for discovery | Keep new mock scenarios tied to supported flows and adopter evidence. | .planning/EVIDENCE.md | Existing MockServer proof is local fixture evidence only. |

## JTBD-MOCK-02

| Field | Value |
|-------|-------|
| actor | SDK adopter and test maintainer |
| situation | When deciding whether a provider flow can be exercised offline |
| outcome | I need an explicit MockServer support boundary so I can avoid confusing mock, sandbox, and live proof. |
| capability | Existing evidence distinguishes MockServer behavior from provider-state verification. |
| smallest_gap | A supported and unsupported flow inventory for MockServer is not yet committed. |
| boundary | Oarlock documents fixture limits; adopters own test selection; Paddle owns external provider state. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md MOCK-02 |
| owner | oarlock maintainers; adopter owner unknown |
| adopter_owner | unknown |
| rationale | A clear list prevents local fixture success from being described as provider verification. |
| requirement_phase | MOCK-02@Future Requirements; no committed phase mapping |
| proof | Documentation inventory cross-checked against fixture tests and separate proof classes. |
| evidence | .planning/EVIDENCE.md; .planning/REQUIREMENTS.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/REQUIREMENTS.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | Refresh when MockServer behavior or the set of public flows changes. |
| non_goal | Does not convert offline fixture output into sandbox or live evidence. |
| promotion | Promote with a verified flow inventory and tests that fail when documentation drifts. |
| horizon | mid |
| commitment_status | candidate |
| trajectory_group | mid/candidate |
| backlog_archive | none; candidate is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | mid | unknown | candidate | .planning/REQUIREMENTS.md | oarlock maintainers | Preserve a proof-boundary documentation candidate. | .planning/EVIDENCE.md | Existing proof classes remain separate. |

## JTBD-API-01

| Field | Value |
|-------|-------|
| actor | Application integrator |
| situation | When a named billing workflow needs payment-method capability beyond current portal sessions |
| outcome | I need only the provider operations required by that workflow so I can avoid endpoint-parity surface. |
| capability | Current scope stays with tested portal and management URL flows. |
| smallest_gap | No named adopter need beyond the current seam has been established. |
| boundary | Oarlock owns a justified typed operation; application owns presentation and policy; Paddle owns available operations. |
| source | 2026-09-09: .planning/REQUIREMENTS.md API-01 and .planning/research/FEATURES.md |
| owner | oarlock maintainer for discovery; adopter owner unknown |
| adopter_owner | unknown |
| rationale | Payment-method additions are demand-driven rather than endpoint parity. |
| requirement_phase | API-01@Future Requirements; no committed phase mapping |
| proof | Named consumer, current official provider contract, smallest typed operation, and compatibility tests. |
| evidence | .planning/REQUIREMENTS.md; .planning/EVIDENCE.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/REQUIREMENTS.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | At-use provider documentation refresh and before each promotion decision. |
| non_goal | Does not promise a new payment-method API. |
| promotion | Promote only when an adopter job proves the current seam insufficient. |
| horizon | long |
| commitment_status | conditional |
| trajectory_group | long/conditional |
| backlog_archive | none; conditional item is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | long | unknown | conditional | .planning/REQUIREMENTS.md | oarlock maintainer for discovery | Defer until a named consumer demonstrates the smallest missing capability. | .planning/EVIDENCE.md | Current portal sessions remain the documented boundary. |

## JTBD-API-02

| Field | Value |
|-------|-------|
| actor | Business billing integrator |
| situation | When a named consumer needs invoice, business, or manual-collection workflows |
| outcome | I need the smallest supported operation so I can complete that real workflow without broad SDK mirroring. |
| capability | No v2.2 commitment adds these broader billing flows. |
| smallest_gap | Consumer demand, provider contract, and proof scope are unverified. |
| boundary | Oarlock may own provider transport; applications own billing policy and persistence; Paddle owns provider behavior. |
| source | 2026-09-09: .planning/REQUIREMENTS.md API-02 and .planning/research/FEATURES.md |
| owner | oarlock maintainer for discovery; adopter owner unknown |
| adopter_owner | unknown |
| rationale | Keep business and manual collection flows demand-driven. |
| requirement_phase | API-02@Future Requirements; no committed phase mapping |
| proof | Named adopter workflow, current provider source, explicit ownership boundary, and focused integration fixtures. |
| evidence | .planning/REQUIREMENTS.md; .planning/EVIDENCE.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/REQUIREMENTS.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | Recheck current provider version and consumer need before promotion. |
| non_goal | Does not commit to invoice, entitlement, persistence, or manual collection APIs. |
| promotion | Promote only for one evidenced adopter job with a bounded compatibility contract. |
| horizon | long |
| commitment_status | conditional |
| trajectory_group | long/conditional |
| backlog_archive | none; conditional item is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | long | unknown | conditional | .planning/REQUIREMENTS.md | oarlock maintainer for discovery | Do not add broader flows without a real consumer job. | .planning/EVIDENCE.md | No named adopter is recorded. |

## JTBD-API-03

| Field | Value |
|-------|-------|
| actor | Project maintainer |
| situation | When considering product and price writes, marketplace features, reporting, or simulations |
| outcome | I need a demand-backed boundary so I can avoid unsupported endpoint parity. |
| capability | The current milestone explicitly defers broad endpoint mirroring and new API breadth. |
| smallest_gap | No named consumer evidence justifies expanding these surfaces. |
| boundary | Oarlock owns only promoted SDK APIs; applications and provider own their respective business logic and state. |
| source | 2026-09-09: .planning/REQUIREMENTS.md API-03 and .planning/PROJECT.md |
| owner | oarlock maintainers |
| adopter_owner | unknown |
| rationale | Reject undirected surface growth while retaining a dated path to reconsider evidence. |
| requirement_phase | API-03@Future Requirements; no committed phase mapping |
| proof | A named job, current provider source, scope review, and explicit acceptance contract. |
| evidence | .planning/REQUIREMENTS.md; .planning/PROJECT.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/REQUIREMENTS.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | Revisit only when a named adopter need or provider contract changes. |
| non_goal | Does not propose or deliver product/price writes, marketplace/connect, reports, or simulations. |
| promotion | Promote a specific operation only after evidence disproves the current narrow boundary. |
| horizon | long |
| commitment_status | conditional |
| trajectory_group | long/conditional |
| backlog_archive | none; conditional item is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | long | unknown | conditional | .planning/REQUIREMENTS.md | oarlock maintainers | Retain demand as the promotion rule rather than infer general demand. | .planning/PROJECT.md | This is not a rejection of later evidence-backed work. |

## JTBD-STABLE-01

| Field | Value |
|-------|-------|
| actor | Downstream adopter and project maintainer |
| situation | When real consumers depend on the public API over multiple releases |
| outcome | I need deliberate compatibility and reproducible release guarantees so I can upgrade predictably. |
| capability | Current project rules preserve a narrow typed seam and explicit release proof; deliberate contract graduation is future scope. |
| smallest_gap | Real consumer maturity, support burden, and migration evidence have not established a graduation point. |
| boundary | Oarlock owns its public contract; consumers own migration timing; release evidence binds published identity. |
| source | 2026-09-09: .planning/REQUIREMENTS.md STABLE-01; 2026-09-26: .planning/PROJECT.md |
| owner | oarlock maintainers with named downstream consumers |
| adopter_owner | unknown |
| rationale | A stable contract should follow observed adoption and support needs, not precede them. |
| requirement_phase | STABLE-01@Future Requirements; no committed phase mapping |
| proof | Named real consumers, compatibility policy, tested migration path, and reproducible exact-SHA package evidence. |
| evidence | .planning/REQUIREMENTS.md; .planning/EVIDENCE.md |
| evidence_class | Future requirement planning reference |
| evidence_identity | .planning/REQUIREMENTS.md |
| evidence_caveat | Candidate or conditional planning evidence does not establish shipped behavior or external adoption. |
| freshness | Revisit when consumer count, support burden, or compatibility incidents materially change. |
| non_goal | Does not claim a broad stability guarantee or semantic version policy beyond current project statements. |
| promotion | Promote only with consumer evidence, support owner, deprecation policy, and reproducible release proof. |
| horizon | long |
| commitment_status | conditional |
| trajectory_group | long/conditional |
| backlog_archive | none; conditional item is tracked in Future Requirements |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|--------|
| 2026-09-26 | unknown | long | unknown | conditional | .planning/REQUIREMENTS.md | oarlock maintainers | Wait for real adoption and support evidence before graduating the contract. | .planning/EVIDENCE.md | Existing package controls do not imply a broader compatibility promise. |
