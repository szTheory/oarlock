---
phase: 35-review-ownership-worktree-operations
plan: 02
subsystem: operations
tags: [github, contribution, security, issue-forms, triage]
requires:
  - phase: 35-review-ownership-worktree-operations
    provides: Manifest-bound worktree entry and exit evidence and operator guidance
provides:
  - Bounded contributor, bug, proposal, and pull request intake with proportional proof guidance
  - Verified private vulnerability reporting route and maintainer-owned security policy
  - Separate kind and state issue labels, with deterministic collaboration contract tests
affects: [Phase 35 OPS-01, Phase 35 OPS-02, GitHub repository operations]
actuals:
  tokens: 2593
  tasks: 2
  commits: 2
plan_head_before: 76049b0e5b5c090fe52ccc3246267f0e626d6072
tech-stack:
  added: []
  patterns: [bounded GitHub issue forms, exact-SHA proof expectations, live setting readback before documentation]
key-files:
  created:
    - CONTRIBUTING.md
    - SECURITY.md
    - .github/ISSUE_TEMPLATE/bug_report.yml
    - .github/ISSUE_TEMPLATE/change_proposal.yml
    - .github/ISSUE_TEMPLATE/config.yml
    - .github/pull_request_template.md
    - scripts/collaboration_contract.test.cjs
key-decisions:
  - "Issue forms apply kind labels only; maintainers own authoritative workflow state and disposition."
  - "Document GitHub private vulnerability reporting only after an authorized write and fresh enabled:true readback."
  - "Leave security ownership unknown until a maintainer records verified person or team ownership."
patterns-established:
  - "Require one bounded intent and proof proportional to change risk, including exact candidate SHA evidence when available."
  - "Contract-test contributor documentation, form fields, chooser routes, and absence of invented security contacts."
requirements-completed: [OPS-01, OPS-02]
coverage:
  - id: D1
    description: "Contributor guidance, bug and proposal forms, and PR template collect bounded intent and proportional exact-SHA evidence while separating intake kind from maintainer state."
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "scripts/collaboration_contract.test.cjs#contributor guidance gives a bounded change path and proportional proof"
        status: pass
      - kind: unit
        ref: "scripts/collaboration_contract.test.cjs#bug and proposal forms collect distinct bounded intent and evidence"
        status: pass
      - kind: unit
        ref: "scripts/collaboration_contract.test.cjs#pull request template asks for bounded scope, risk, and exact-SHA proof"
        status: pass
    human_judgment: false
  - id: D2
    description: "Security policy and issue chooser name a verified private route, and the requested kind/state vocabulary exists without guessed ownership."
    requirement: OPS-02
    verification:
      - kind: unit
        ref: "scripts/collaboration_contract.test.cjs#issue chooser and security policy use the verified private route"
        status: pass
      - kind: other
        ref: "GitHub GET /repos/szTheory/oarlock/private-vulnerability-reporting returned enabled:true; gh label list confirmed all eight requested labels"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-09-26
status: complete
---

# Phase 35 Plan 02: Contributor and Security Intake Summary

**Bounded GitHub contribution intake now pairs with exact-SHA proof guidance, a verified private security route, and distinct kind/state labels.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-26T12:52:00Z
- **Completed:** 2026-09-26T13:15:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added concise contributor guidance, bug and proposal forms, and a PR template that asks for one intent, bounded scope, risk, checks actually run, candidate SHA, and hosted `CI contract` evidence when available.
- Enabled GitHub private vulnerability reporting after confirming current `ADMIN` access; a fresh GET returned `enabled:true` before `SECURITY.md` and the issue chooser named the route.
- Added the requested three `kind:*` and five `state:*` labels. Forms apply only kind labels; no owner, team, or CODEOWNERS route was guessed.
- Added a Node contract test covering contributor guidance, forms, PR proof fields, the private route, and absence of invented security contacts.

## Task Commits

1. **Task 1: Publish bounded contribution, issue, and PR paths** — `a1607e6` (`docs`)
2. **Task 2: Verify the private route and lock the collaboration contract** — `6afc44e` (`feat`)

**Measured commits:** 2, measured from `76049b0e5b5c090fe52ccc3246267f0e626d6072` through `HEAD`.

## Files Created/Modified

- `CONTRIBUTING.md` — bounded change and evidence guidance, with unknown ownership made explicit.
- `SECURITY.md` — GitHub private vulnerability reporting policy, documented after live enablement readback.
- `.github/ISSUE_TEMPLATE/bug_report.yml` and `.github/ISSUE_TEMPLATE/change_proposal.yml` — required bounded issue forms with kind-only intake labels.
- `.github/ISSUE_TEMPLATE/config.yml` — issue chooser with verified private security route.
- `.github/pull_request_template.md` — scope, risk, local proof, candidate SHA, and exact-SHA hosted CI prompts.
- `scripts/collaboration_contract.test.cjs` — four contract checks for all contributor intake surfaces.

## Decisions Made

- Keep issue kind labels (`kind:bug`, `kind:proposal`, `kind:dependency`) distinct from workflow states (`state:needs-triage`, `state:needs-info`, `state:ready`, `state:in-progress`, `state:blocked`). Labels and editable forms remain intake cues; maintainer triage is authoritative.
- Enable private vulnerability reporting only after live readback confirmed repository `ADMIN` access and the setting was disabled; record the subsequent `enabled:true` response before documenting it.
- Keep owner routing unknown. No CODEOWNERS file or named security owner was created.
- Preserve `.planning/config.json` with `workflow.use_worktrees: false`.

## Deviations from Plan

None. The only test correction was making a local contract regex tolerate wrapped prose; no product scope changed.

## Automated Evidence

- `node --test scripts/collaboration_contract.test.cjs` — **passed, 4/4**.
- `git diff --check` — **passed**.
- `gh api repos/szTheory/oarlock/private-vulnerability-reporting` — **`{"enabled":true}`** after the authorized PUT.
- `gh repo view --json nameWithOwner,viewerPermission` — **`szTheory/oarlock`, `ADMIN`**.
- `gh label list --repo szTheory/oarlock` — confirmed all eight labels: `kind:bug`, `kind:proposal`, `kind:dependency`, `state:needs-triage`, `state:needs-info`, `state:ready`, `state:in-progress`, and `state:blocked`.
- The pre-existing labels `bug`, `enhancement`, and others were preserved.

## Issues Encountered

- The initial unprivileged GSD task commit could not create `.git/index.lock` due to sandbox permissions. The same scoped GSD commit command succeeded with authorized filesystem access and its configured hooks; no raw Git commit or hook bypass was used.

## User Setup Required

None. The private reporting setting and labels are configured and read back from GitHub.

## Next Phase Readiness

- Plan 02 is complete; the next runnable plan is Phase 35 Plan 03, which adds the read-only maintainer triage audit.
- A maintainer still must author actual issue/PR disposition records in Plan 05; this plan intentionally does not assign owners or decide scope.

## Self-Check: PASSED

- All seven declared artifacts exist.
- Both task commits exist and the measured count from the plan base is 2.
- The final four-test collaboration contract passed, and the live private-reporting setting and label names were read back successfully.

---
*Phase: 35-review-ownership-worktree-operations*
*Completed: 2026-09-26*
