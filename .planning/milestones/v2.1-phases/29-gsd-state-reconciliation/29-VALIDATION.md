---
phase: 29
slug: gsd-state-reconciliation
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-24
---

# Phase 29 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Markdown/config drift probes; Mix/ExUnit only if runtime code is touched |
| **Config file** | `.planning/config.json` |
| **Quick run command** | `rg -n "against Paddle state|provider-state verified|sandbox verified|live verified|ADV-01 remains unverified" .planning README.md guides demo/README.md CHANGELOG.md` |
| **Full suite command** | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.phase-op 29 && rg -n "B-0[123567]" .planning/BACKLOG.md .planning/BACKLOG-ARCHIVE.md && rg -n "subscription-create|Reopen Condition|resolved" .planning/threads` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused `rg` probe for the edited surface.
- **After every plan wave:** Run the GSD init/config probe plus all GSD-01..GSD-04 grep checks.
- **Before `/gsd:verify-work`:** Full docs/config probe set must be green or have controlled expected matches.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | GSD-01, GSD-02 | T-29-01, T-29-02 | Backlog scope cannot be misread as active shipped work | docs grep | `test -f .planning/BACKLOG-ARCHIVE.md && rg -n "Status Taxonomy|Accrue-only|B-04" .planning/BACKLOG.md && rg -n "B-01|B-02|B-03|B-05|B-06|B-07|Satisfied by:|Shipped" .planning/BACKLOG-ARCHIVE.md && ! rg -n "^## B-0[123567]" .planning/BACKLOG.md` | W0: `.planning/BACKLOG-ARCHIVE.md` | planned |
| 29-01-02 | 01 | 1 | GSD-02 | T-29-04 | Resolved investigations are findable without looking active | docs grep | `test -f .planning/threads/INDEX.md && test -f .planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md && test ! -f .planning/threads/2026-05-30-subscription-create-revalidation.md && rg -n "Reopen Condition|Paddle\\.Subscriptions\\.create/2|transaction/checkout|invoice-backed|resolved/2026/2026-05-30-subscription-create-revalidation.md" .planning/threads/INDEX.md .planning/threads/resolved/2026/2026-05-30-subscription-create-revalidation.md` | W0: `.planning/threads/INDEX.md`, `.planning/threads/resolved/2026/` | planned |
| 29-02-01 | 02 | 1 | GSD-01, GSD-03 | T-29-05, T-29-06 | Evidence claims include artifact, proof class, and caveat | docs grep/manual read | `test -f .planning/EVIDENCE.md && rg -n "Requirement \\| Artifact \\| Evidence Class \\| Command / Proof \\| Caveat|ADV-01|ADV-02|DOCS-01|PROOF-04|GSD-04|VALIDATION.md|MockServer-backed|sandbox/live" .planning/EVIDENCE.md .planning/v2.0-MILESTONE-AUDIT.md` | W0: `.planning/EVIDENCE.md` and audit errata section | planned |
| 29-02-02 | 02 | 1 | GSD-01, GSD-03 | T-29-07 | Archived milestone wording preserves caveats without overclaiming provider-state proof | docs grep | `rg -n "MockServer-backed|VALIDATION.md|EVIDENCE.md|Errata|Correction" .planning/MILESTONES.md .planning/milestones/v2.0-ROADMAP.md .planning/milestones/v2.0-REQUIREMENTS.md && ! rg -n "against Paddle state|Paddle state \\(Sandbox or Mock\\)|ADV-01 remains unverified|testing flows via Paddle" .planning/MILESTONES.md .planning/milestones/v2.0-ROADMAP.md .planning/milestones/v2.0-REQUIREMENTS.md` | Existing files | planned |
| 29-03-01 | 03 | 2 | GSD-04 | T-29-11, T-29-12 | Durable defaults are stored in supported config and explicit policy docs before requirement state is marked complete | config probe | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.plan-phase 29 2>&1 | tee /tmp/oarlock-gsd-init-phase29.txt >/dev/null; ! rg -n "unknown config key|preferences" /tmp/oarlock-gsd-init-phase29.txt && rg -n "research before planning|adopter-first|DX/UX|retained investigations|Nyquist|pattern mapping|commit_docs|auto_advance|model profile|user-global" .planning/GSD-PREFERENCES.md .planning/config.json` | W0: `.planning/GSD-PREFERENCES.md` | planned |
| 29-03-02 | 03 | 2 | GSD-01, GSD-04 | T-29-09, T-29-10 | Root planning files point to reconciled active/archive/evidence/thread/preference surfaces after config proof exists | docs grep | `rg -n "BACKLOG-ARCHIVE.md|EVIDENCE.md|threads/INDEX.md|GSD-PREFERENCES.md|GSD-01|GSD-02|GSD-03|GSD-04|29-01-PLAN.md|29-02-PLAN.md|29-03-PLAN.md" .planning/PROJECT.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md && ! rg -n "Reconcile v2.0 audit/validation language|Close or annotate stale backlog/thread entries|0/0" .planning/STATE.md .planning/ROADMAP.md` | Existing root files | planned |

---

## Wave 0 Requirements

- [x] `.planning/BACKLOG-ARCHIVE.md` - archive destination for shipped, superseded, and reference backlog entries is planned in 29-01-01.
- [x] `.planning/threads/INDEX.md` - status, lesson, canonical phase/context link, and reopen condition for threads is planned in 29-01-02.
- [x] `.planning/threads/resolved/2026/` - resolved thread destination is planned in 29-01-02.
- [x] Evidence ledger location selected as standalone `.planning/EVIDENCE.md` and planned in 29-02-01.
- [x] Supported prose GSD preferences location selected as `.planning/GSD-PREFERENCES.md` and planned in 29-03-01.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Root planning documents agree on shipped/open scope | GSD-01 | Agreement is semantic across markdown docs | Read `PROJECT`, `REQUIREMENTS`, `ROADMAP`, `STATE`, `BACKLOG`, archive, milestone audit, and evidence ledger; confirm shipped/open scope is consistent. |
| Historical errata preserves prior claim boundaries | GSD-03 | Append-only correction quality requires judgment | Verify dated notes clarify MockServer vs sandbox/live provider-state proof without deleting useful historical context. |
| Project vs personal GSD defaults boundary is correct | GSD-04 | Some preferences are schema-supported and some are prose policy | Confirm project-local config contains only supported shared gates and personal autonomy/risk knobs are not silently imposed on contributors. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planning-time validation ready; execution remains pending.
