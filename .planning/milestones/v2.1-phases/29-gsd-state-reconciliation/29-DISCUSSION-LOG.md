# Phase 29: GSD State Reconciliation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-24
**Phase:** 29-GSD State Reconciliation
**Areas discussed:** Backlog Disposition, Audit Evidence Language, Investigation Retention, GSD Defaults Durability

---

## Backlog Disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Active-only `BACKLOG.md` plus `BACKLOG-ARCHIVE.md` | Keeps future planning queue clean while preserving original B-IDs, rationale, and historical trace in a separate archive. | ✓ |
| Single `BACKLOG.md` with active section first and history below | Least file churn, but shipped entries still inflate the active backlog surface. | |
| Status-in-place taxonomy only | Fastest migration, but resolved work can still look like future scope. | |
| Move shipped entries only into milestones/audits | Strong active backlog signal, but loses detailed backlog rationale and B-ID lookup quality. | |

**User's choice:** Discuss all and use research/subagents to produce a cohesive recommendation.
**Notes:** The selected recommendation keeps active backlog scan-first, archives shipped/superseded entries without renumbering, and labels B-04 as Accrue-only.

---

## Audit Evidence Language

| Option | Description | Selected |
|--------|-------------|----------|
| Append-only errata plus evidence taxonomy | Honest audit trail; avoids silent history rewrites while giving future agents exact proof vocabulary. | ✓ |
| Canonical evidence ledger | One scan-friendly table for requirements, artifacts, evidence class, commands, and caveats. | ✓ |
| Dated in-place corrections | Corrects misleading stale prose where humans and agents already read it. | ✓ |
| Rename/copy Phase 25 `VALIDATION.md` to `VERIFICATION.md` | Standardizes artifact naming, but risks duplicate evidence drift if copied blindly. | |
| Leave history unchanged | Lowest churn, but fails the GSD-03 goal and allows overclaims to recur. | |

**User's choice:** Discuss all and use research/subagents to produce a cohesive recommendation.
**Notes:** The selected recommendation is a hybrid: append-only errata, a small evidence ledger, and dated corrections for misleading wording. Phase 26 must say MockServer-backed unless sandbox/live proof was actually run.

---

## Investigation Retention

| Option | Description | Selected |
|--------|-------------|----------|
| Keep resolved threads in active path with status headers | Minimal disruption, but weak information scent. | |
| Archive resolved threads under `threads/resolved/YYYY/` plus `threads/INDEX.md` | Preserves evidence while making open vs resolved visible from path and index. | ✓ |
| Promote durable conclusions into ADR-style records | Useful for API/provider model decisions, but too heavy for every thread. | ✓ |
| Fold only the lesson into state/project docs | Fast to consume, but loses investigation trail and conflicts with retained-investigation preference. | |

**User's choice:** Discuss all and use research/subagents to produce a cohesive recommendation.
**Notes:** Use archive-plus-index by default. Promote only durable public API/provider model decisions to ADR-style records.

---

## GSD Defaults Durability

| Option | Description | Selected |
|--------|-------------|----------|
| All defaults project-local | Durable project memory, but can overfit and surprise contributors with autonomy defaults. | |
| Split project-local quality policy from user/global execution style | Project owns durable process facts; user/global owns autonomy and risk tolerance. | ✓ |
| Mostly global/user defaults | Good for one maintainer, but loses project memory for future agents. | |
| Per-phase prompts only | Explicit, but repeats known preferences and lets lessons decay. | |

**User's choice:** Discuss all and use research/subagents to produce a cohesive recommendation.
**Notes:** Project-local defaults should capture research-first, adopter-first, DX/UX, retained investigations, Nyquist validation, pattern mapping, and planning artifact durability. Autonomy knobs such as `yolo` and `auto_advance` should remain explicit per run or user-global.

---

## Claude's Discretion

- Exact file layout for the evidence ledger is left to the planner as long as one scan-friendly canonical proof surface exists.
- The planner may choose file moves or copied archive entries if links remain clear and B-IDs are preserved.
- The planner may add lightweight indexes/templates if they reduce future drift without heavy process overhead.

## Deferred Ideas

- Accrue-side `%Paddle.Error{}.raw` to `raw_data` migration remains outside oarlock Phase 29.
- Live Paddle sandbox/provider-state CI remains future/manual/on-demand.
- A GSD dashboard or heavyweight knowledge system is out of scope.
