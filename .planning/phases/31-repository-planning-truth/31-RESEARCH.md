# Phase 31: Repository & Planning Truth - Research

**Researched:** 2026-09-09
**Domain:** Read-only Git inventory, planning authority, milestone-history consistency, and actionable diagnostics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Repository inventory and classification
- **D-01:** The read-only inventory must produce both a concise human-readable report and deterministic JSON from the same underlying result.
- **D-02:** Keep observed facts separate from proposed disposition. Facts include dirty state, branch and upstream, ahead/behind counts, worktree HEAD, lock/prunable state, and process or ownership evidence. Dispositions are recommendations such as preserve, commit, hand off, ignore, repair, or remove.
- **D-03:** Ownership records include the claimed owner, provenance for that claim, confidence, and a revisit date. Anything not supported by evidence remains explicitly `unknown`.
- **D-04:** Known, intentionally preserved dirty or locked state is visible but does not fail by itself. Unclassified, unreadable, or unsafe state produces a nonzero exit.
- **D-05:** Inventory and health tooling are report-only. They may propose a disposition but cannot apply cleanup or delete, unlock, reset, restore, prune, or force-remove anything.

### Planning authority and conflict handling
- **D-06:** Canonical ownership is assigned by datum: `REQUIREMENTS.md` owns committed milestone scope; `ROADMAP.md` owns the active phase graph and requirement mapping; `STATE.md` owns the current execution pointer and session state; `PROJECT.md` owns durable project scope and constraints; `MILESTONES.md` plus archived milestone files own shipped-history navigation; `EVIDENCE.md` owns proof classification and corrections.
- **D-07:** Canonical disagreements fail routing with an actionable conflict instead of silently choosing the newest file or a convenient winner.
- **D-08:** A phase directory, plan, summary, verification file, archive, cache, or research artifact never makes work active or complete by mere presence. Active status requires an explicit current-roadmap and current-state reference; completion requires the defined proof chain.
- **D-09:** Planning-health checks are read-only and show the governing authority plus a proposed patch. Repairs are separate, explicit actions that use supported GSD handlers and record a dated correction.
- **D-10:** Keep `.planning/state.json` only if a demonstrated consumer requires it. Otherwise remove or ignore it. If retained, it is an atomically regenerated, disposable mirror with source and schema/version metadata, never independent authority.

### Milestone history and health diagnostics
- **D-11:** Archived milestone snapshots remain immutable. Correct contradictions through dated errata in the current milestone/evidence ledger and repair current navigation links without rewriting what a historical snapshot originally said.
- **D-12:** Record planning milestone, Git tag, source SHA, declared Hex package version, and publication status as separate identities. Never imply that planning milestone `v2.1` means package version `2.1`; the repository currently declares package version `0.1.1`.
- **D-13:** Diagnostics use `error`, `warning`, and `info`. Errors block routing or completion. Warnings require an owner or revisit condition but do not block. Info records intentional exceptions and healthy facts.
- **D-14:** Every diagnostic is a stable actionable record containing a code, severity, affected artifact and field, expected and actual values, governing authority, evidence, and a safe next command or repair proposal.
- **D-15:** Human and JSON diagnostic views must preserve the same stable codes and conclusions so agents, CI, and maintainers cannot receive different truth from different formats.

### the agent's Discretion
- Exact command names, module boundaries, JSON field names, presentation order, and formatting are open to research and planning as long as the decisions above remain intact.
- The planner may select the implementation language and test harness that best fit the repository's existing Mix, shell, Node, and GSD tooling patterns.
- The precise invariant catalog and diagnostic code naming are flexible; it must cover all four Phase 31 requirements and the roadmap success criteria.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPO-01 | Maintainer can run a read-only inventory that reports every dirty path, branch divergence, linked worktree, lock state, owner, and proposed disposition before cleanup occurs. | Use Git's stable NUL-delimited porcelain formats, one normalized snapshot, an evidence-backed exception registry, and fixture repositories. [VERIFIED: .planning/REQUIREMENTS.md:25-32; CITED: https://git-scm.com/docs/git-worktree; CITED: https://git-scm.com/docs/git-status] |
| REPO-02 | Maintainer and GSD tooling use one documented authority chain for active scope; archives, caches, summaries, and directory presence cannot independently make shipped work appear active. | Encode D-06 as validators over the canonical documents; require ROADMAP and STATE agreement; treat GSD `planning inspect` and `drift-guard phase-status` as corroborating diagnostics. [VERIFIED: .planning/REQUIREMENTS.md:25-32; VERIFIED: /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs:93-113] |
| REPO-03 | Maintainer can navigate a complete milestone history whose shipped status, requirements, archive links, planning identifiers, and package-version semantics agree. | Validate index-to-archive links and identities, then repair only current navigation/errata; preserve frozen snapshots. [VERIFIED: .planning/REQUIREMENTS.md:25-32; VERIFIED: .planning/MILESTONES.md:1-178] |
| REPO-04 | Maintainer can run a planning-health check that detects stale active artifacts, broken references, archive contradictions, and unproven completion claims without mutating files. | Build pure invariant checks that emit a shared stable diagnostic schema to human and JSON renderers, and test both conclusions and no-write behavior. [VERIFIED: .planning/REQUIREMENTS.md:25-32; VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-40] |
</phase_requirements>

## Summary

Plan this as a small repository-native control plane, not as cleanup and not as a replacement for GSD. The core should collect one normalized repository/planning snapshot, run pure classification and invariant checks, then render that same result as human text or deterministic JSON. This directly enforces D-01, D-02, D-05, and D-15. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:16-35]

Use Node/CommonJS and `node:test`, with no new package dependency. The repository already has a tested Node CLI that uses `spawnSync`, returns structured evidence, renders JSON, and tests through fake executables and temporary directories. [VERIFIED: scripts/ci_monitor.cjs:1-107,117-189,192-240; VERIFIED: scripts/ci_monitor.test.cjs:1-108,110-169] Shell should remain only an optional entry-point wrapper; parsing NUL-delimited Git records and producing deterministic nested JSON is safer and easier to test in Node. [ASSUMED]

The current repository is a useful failing fixture, not a contract to hard-code: main is ahead of `origin/main`, both registered worktrees contain uncommitted state, the linked worktree has a lock reason whose PID is not live, `MILESTONES.md` omits v1.2 and v1.4, v1.5 links point at mutable root files, and `.planning/state.json` contradicts the current v2.2 phase graph. [VERIFIED: live commands `git status --short --branch`, `git worktree list --porcelain -z`, `git -C <worktree> status --porcelain=v2 --branch`, `ps -p 44442`, and `gsd-tools query validate health` on 2026-09-09; VERIFIED: .planning/MILESTONES.md:68-93; VERIFIED: .planning/state.json:1-42] The implementation must rediscover those facts on every run. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:89-94]

**Primary recommendation:** Create one dependency-free Node library for collection/classification/validation, two thin CLIs (`repository inventory` and `planning health`), one committed ownership/exception registry, and `node:test` fixtures; then reconcile current milestone navigation in a separate task using additive errata only. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Git/worktree observation | Repository CLI / local control plane | Git object and worktree metadata | Git is the authoritative source for worktree registration, HEAD, branch, upstream, dirty, lock, and prunable observations. [CITED: https://git-scm.com/docs/git-worktree; CITED: https://git-scm.com/docs/git-status] |
| Ownership and intentional-exception classification | Repository policy data | Repository CLI | Evidence-backed human claims must be data separate from observations and must never overwrite Git facts. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:16-21] |
| Active-scope resolution | Planning control plane | GSD query runtime | The repository documents own the datum; GSD queries are consumers/corroboration and must not promote cache or directory presence. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:23-28; VERIFIED: /Users/jon/.codex/gsd-core/workflows/next.md:12-29] |
| Shipped-history navigation | Current planning documents | Immutable milestone archives and Git refs | Current navigation may be repaired, while archived snapshots remain historical evidence. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-35] |
| Diagnostic rendering and exit status | Repository CLI / local control plane | CI and GSD routing consumers | Both views must derive from one result and preserve the same codes/conclusions. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-35] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Node.js built-ins (`child_process`, `fs`, `path`) | 22.14.0 available | Run Git with argument arrays, read canonical files, normalize and serialize results | Already used by the repository's evidence CLI; introduces no dependency. [VERIFIED: `node --version` on 2026-09-09; VERIFIED: scripts/ci_monitor.cjs:1-4,76-107] |
| `node:test` + `node:assert/strict` | Node 22.14.0 built-in | Unit, CLI, fixture-repository, and no-mutation tests | Existing repository test convention for its Node CLI. [VERIFIED: scripts/ci_monitor.test.cjs:1-8,110-169] |
| Git porcelain/plumbing | Git 2.41.0 available | Worktree enumeration, dirty records, branch/upstream, ahead/behind, refs, and dry-run prune evidence | Official formats are stable for scripts; `-z` preserves unusual path and reason data. [VERIFIED: `git --version` on 2026-09-09; CITED: https://git-scm.com/docs/git-worktree; CITED: https://git-scm.com/docs/git-status] |
| Existing GSD query runtime | installed local runtime | Corroborate current phase, planning snapshot, drift, and supported repairs | It already reads `STATE.md`/`ROADMAP.md`, exposes read-only `planning inspect`, `validate health`, `validate consistency`, and `drift-guard phase-status`, and documents supported mutation handlers separately. [VERIFIED: /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs:11-18,47-76,93-113] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Bash | 5.2.37 available | Optional executable wrapper and CI command composition | Keep wrappers thin; do not parse Git porcelain or build JSON in shell. [VERIFIED: `bash --version` on 2026-09-09; ASSUMED] |
| `git worktree prune --dry-run --verbose` | Git 2.41.0 | Add non-mutating evidence about stale administrative records | Observation only; never call prune without `--dry-run` from these tools. [CITED: https://git-scm.com/docs/git-worktree] |
| `git rev-list --left-right --count A...B` | Git 2.41.0 | Fallback divergence calculation when status does not provide usable upstream counts | Use only after explicitly resolving both refs. [CITED: https://git-scm.com/docs/git-rev-list] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Node shared model and CLIs | Bash scripts | Shell matches `check_summary_drift.sh`, but robust NUL parsing, deterministic JSON, nested diagnostics, and portable tests become fragile. [VERIFIED: bin/check_summary_drift.sh:1-38; ASSUMED] |
| Repository-specific validator | Only `gsd-tools validate health` | Existing health finds some useful issues but also flags valid project-local artifacts as unrecognized and does not implement the locked D-06/D-14 authority contract. [VERIFIED: live `gsd-tools query validate health` output on 2026-09-09] |
| One shared result with renderers | Separate human and JSON scripts | Separate implementations can drift and directly violate D-01/D-15. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:16-17,33-35] |

**Installation:** None. This phase should add no external package. [ASSUMED]

## Architecture Patterns

### System Architecture Diagram

```text
CLI args + cwd
      |
      v
resolve repository root
      |
      +-----------------------------+
      |                             |
      v                             v
Git collectors                  planning readers
(porcelain -z, refs,            (PROJECT, REQUIREMENTS,
status, worktrees, lock,        ROADMAP, STATE, MILESTONES,
process evidence)               archives, EVIDENCE)
      |                             |
      +-------------+---------------+
                    v
             normalized snapshot <----- ownership/exception registry
                    |
          +---------+----------+
          |                    |
          v                    v
 repository classifier   planning invariant engine
          |                    |
          +---------+----------+
                    v
         result {facts, dispositions, diagnostics}
                    |
            format decision
             /             \
            v               v
       human renderer    JSON renderer
             \             /
              same diagnostic codes
                    |
                    v
       exit 0 when no errors; nonzero on error/incomplete observation
```

The diagram is the recommended design, not a description of files that already exist. [ASSUMED]

### Recommended Project Structure

```text
scripts/
├── repository_inventory.cjs       # thin CLI, formatting and exit
├── planning_health.cjs             # thin CLI, formatting and exit
├── lib/
│   └── repository_truth.cjs        # collectors, normalized model, classifiers, validators
├── repository_inventory.test.cjs   # temp Git repositories and worktree fixtures
└── planning_health.test.cjs        # planning fixture matrices and CLI parity
.planning/
└── repository-ownership.json       # evidence-backed exceptions and proposed dispositions
```

These exact new paths are recommended under the agent's discretion and remain planner-selectable. [ASSUMED]

### Pattern 1: Collect Once, Validate Purely, Render Twice

**What:** Collection performs all I/O and returns a normalized object. Classification and invariant functions accept data and return data. Human and JSON renderers never recollect or reinterpret. [ASSUMED]

**When to use:** Both CLIs, especially whenever `--json` is requested. [ASSUMED]

**Example:**

```javascript
// Pattern derived from the locked same-result requirement and existing ci_monitor.cjs.
const snapshot = collectSnapshot({ cwd, runGit, readFile });
const result = evaluate(snapshot, registry);
process.stdout.write(json ? renderJson(result) : renderHuman(result));
process.exitCode = exitCodeFor(result);
```

[VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:16-21,33-35; VERIFIED: scripts/ci_monitor.cjs:192-240,313]

### Pattern 2: Stable Porcelain, NUL End-to-End

**What:** Start from `git worktree list --porcelain -z` and, for every accessible registered worktree, run `git -C <path> status --porcelain=v2 --branch -z`. Preserve byte-safe tokenization until records are parsed; do not split paths on whitespace or newline. [CITED: https://git-scm.com/docs/git-worktree; CITED: https://git-scm.com/docs/git-status]

**When to use:** Repository inventory and its tests for spaces/newlines in paths and rename records. [ASSUMED]

### Pattern 3: Evidence Is Not Ownership

**What:** Git lock reason, PID liveness, branch name, path prefix, and timestamps are observations. The registry supplies a claim only when it records owner, provenance, confidence, revisit date, and proposed disposition. Missing or stale registry coverage yields `unknown`; it never guesses from `.claude/`, process age, or branch name. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:18-20]

**When to use:** Every dirty path, locked worktree, or intentionally retained exception. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:19-20]

### Pattern 4: Authority by Datum, Conflict by Invariant

**What:** Each validator names one datum, one governing artifact, all corroborating artifacts, and whether disagreement is blocking. It never chooses the newest timestamp. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:23-29]

**Minimum invariant catalog:**

| Invariant | Governing authority | Required check |
|-----------|---------------------|----------------|
| Committed milestone scope | `REQUIREMENTS.md` | Requirement checkbox IDs and traceability map only to current ROADMAP phases; source-anchor IDs are not misparsed as requirements. [VERIFIED: .planning/REQUIREMENTS.md:7-32,121-157; VERIFIED: live `planning inspect` output on 2026-09-09] |
| Active milestone/phase graph | `ROADMAP.md` with `STATE.md` pointer | Exactly one active milestone; STATE milestone/current phase exists in ROADMAP and names the same current phase. [VERIFIED: .planning/ROADMAP.md:12-31; VERIFIED: .planning/STATE.md:1-18,29-36] |
| Durable project scope | `PROJECT.md` | Current milestone reference agrees with REQUIREMENTS/ROADMAP, while historical details do not route work. [VERIFIED: .planning/PROJECT.md:15-53] |
| Completion | Defined proof chain | A completion claim requires roadmap acceptance plus plan summaries and phase verification/evidence; presence alone is never sufficient. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:26-27; VERIFIED: /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs:106-113] |
| Shipped history | `MILESTONES.md` + archives | Every shipped milestone listed in ROADMAP has a log entry, phase range, existing archive links, tag identity, and explicit proof/publication caveat. [VERIFIED: .planning/ROADMAP.md:12-22; VERIFIED: .planning/MILESTONES.md:1-178] |
| Proof correction | `EVIDENCE.md` | Current corrections point to preserved historical snapshots and classify proof without rewriting archives. [VERIFIED: .planning/EVIDENCE.md:1-28] |
| Package identity | `mix.exs` for declared package version | Planning milestone, Git tag, tag target SHA, declared package version, and publication status remain separate fields. [VERIFIED: mix.exs:1-5,57-66; VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-35] |

### Pattern 5: Actionable Diagnostics as Data

**What:** Emit a stable record first, then format it. The proposed schema is `code`, `severity`, `artifact`, `field`, `expected`, `actual`, `authority`, `evidence`, and `repair`. Add `owner`/`revisit_at` for warnings and intentional exceptions. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-35; ASSUMED]

**Exit contract recommendation:** exit `0` when no `error` diagnostics exist, `1` for policy/invariant errors, and `2` when collection is incomplete or unsafe to interpret. [ASSUMED]

### Anti-Patterns to Avoid

- **Parsing human Git output:** `git branch -vv`, ordinary `git status`, and whitespace splitting are display formats; use stable porcelain. [CITED: https://git-scm.com/docs/git-status; CITED: https://git-scm.com/docs/git-worktree]
- **Renderer-specific logic:** no separate queries, filtering, or severity decisions in the human and JSON paths. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:16-17,33-35]
- **Age implies abandonment:** a stale lock or dead PID is evidence for review, not authorization or ownership truth. [VERIFIED: .planning/research/PITFALLS.md:90-105]
- **Archive rewrite:** do not make v1.2's archived requirement header look shipped by editing the frozen file; record the contradiction and correction in current navigation/evidence. [VERIFIED: .planning/milestones/v1.2-REQUIREMENTS.md:1-8; VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-31]
- **Delegating truth entirely to installed GSD:** its current `planning inspect` reports future mapped phases as unknown because only Phase 31 has a directory, and its generic health checker flags valid project-local artifacts. Treat those as integration signals, not the repository's whole D-06 policy. [VERIFIED: live `planning inspect` and `validate health` output on 2026-09-09]
- **Repair commands inside health:** print a proposed patch or supported handler, but never execute it. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:20-21,27-29]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Git status grammar | Ad hoc line/space parser | `git status --porcelain=v2 --branch -z` | Stable, detailed, NUL-safe machine contract. [CITED: https://git-scm.com/docs/git-status] |
| Worktree discovery | Scan `.git/worktrees` or `.claude/worktrees` as primary inventory | `git worktree list --porcelain -z` | Git owns registration and reports main, linked, detached, locked, and prunable state. [CITED: https://git-scm.com/docs/git-worktree] |
| Divergence | Count `git log` output | status `branch.ab`, or `git rev-list --left-right --count` | Git computes reachability and emits explicit counts. [CITED: https://git-scm.com/docs/git-status; CITED: https://git-scm.com/docs/git-rev-list] |
| GSD state mutation | Direct health-check edits | Supported GSD handlers in a separately reviewed repair action | The installed runtime exposes explicit state/roadmap/milestone operations; the health phase is report-only. [VERIFIED: /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs:11-18,47-76] |
| JSON serialization | String concatenation | `JSON.stringify` over normalized data | Avoid escaping/order divergence and match the existing CLI pattern. [VERIFIED: scripts/ci_monitor.cjs:313; VERIFIED: scripts/ci_monitor.test.cjs:110-148] |
| Test repository mocking only | Mock every Git response | Temporary real Git repositories plus injected runner tests | Real fixtures catch porcelain/worktree behavior; injection still covers unreadable/error branches. [ASSUMED] |

**Key insight:** Git and the planning documents already contain the facts. The implementation's job is to normalize, cross-check, classify, and explain them without acquiring mutation authority. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:7-10,16-35]

## Common Pitfalls

### Pitfall 1: Inventory Mutates While "Inspecting"

**What goes wrong:** A helpful path prunes, unlocks, removes, resets, stashes, or repairs before ownership is known. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:20-21]

**Why it happens:** Git groups read and write worktree subcommands under one executable, and generic health tools often offer repair switches. [CITED: https://git-scm.com/docs/git-worktree; VERIFIED: /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs:101-104]

**How to avoid:** Allowlist exact read commands; reject any collected command containing mutating worktree operations; test filesystem and ref snapshots before/after each CLI run. [ASSUMED]

**Warning signs:** implementation calls `prune` without `--dry-run`, `unlock`, `remove`, `reset`, `restore`, `clean`, `stash`, or a GSD mutation handler. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:20-21; CITED: https://git-scm.com/docs/git-worktree]

### Pitfall 2: Unusual Paths Corrupt the Report

**What goes wrong:** spaces, tabs, newlines, renames, or non-UTF8-ish byte sequences split one path into multiple records or change JSON/human conclusions. [CITED: https://git-scm.com/docs/git-status; CITED: https://git-scm.com/docs/git-worktree]

**How to avoid:** Use `-z`, parse Buffers/tokens deliberately, and add path-with-space and path-with-newline fixtures. [ASSUMED]

**Warning signs:** `.split("\n")`, `awk`, or whitespace tokenization touches porcelain output. [ASSUMED]

### Pitfall 3: "Known" Means Silently Allowed Forever

**What goes wrong:** a stale exception suppresses a real hazard indefinitely. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:18-20,32-34]

**How to avoid:** Require provenance, confidence, revisit date, and a narrow selector; expired or mismatched records warn or error instead of auto-matching. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:18-20,32-34]

**Warning signs:** wildcard ignores, owner inferred from path, no revisit date, or exceptions that omit the observed HEAD/path they classify. [ASSUMED]

### Pitfall 4: Generic Parser Treats Source Anchors as Requirements

**What goes wrong:** table identifiers such as source anchors become fake unmapped requirements; future phases without directories become false errors. This occurs in the current `planning inspect` output. [VERIFIED: .planning/REQUIREMENTS.md:7-21,121-157; VERIFIED: live `planning inspect` output on 2026-09-09]

**How to avoid:** Parse requirement checkbox bullets only in the committed-requirements section, then parse the traceability table separately and scope phase-directory expectations to lifecycle state. [ASSUMED]

**Warning signs:** `USER-2026-09-09` appears as a requirement, or Phases 32-36 fail merely because their directories are not created yet. [VERIFIED: .planning/REQUIREMENTS.md:13-21,127-157; VERIFIED: live `planning inspect` output on 2026-09-09]

### Pitfall 5: Historical Repair Destroys Historical Truth

**What goes wrong:** frozen archives are edited until they match current conventions, erasing what was actually shipped/recorded. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-31]

**How to avoid:** Add missing current index entries and dated errata; link the immutable contradictory artifact and name the corrected interpretation. [VERIFIED: .planning/MILESTONES.md:55-64; VERIFIED: .planning/EVIDENCE.md:24-28]

**Warning signs:** Phase 31 edits any `.planning/milestones/v*-ROADMAP.md` or `*-REQUIREMENTS.md` to normalize wording rather than adding a current correction. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-31]

### Pitfall 6: Planning Milestone Equals Package Version

**What goes wrong:** a planning tag such as `v2.1` is presented as Hex version `2.1`. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:31-32]

**How to avoid:** Model separate identity fields and source each from its authority. Current `mix.exs` says verbatim:

`DATA_K7P4M2QX_START @version "0.1.1" DATA_K7P4M2QX_END` [VERIFIED: mix.exs:1-5]

The current tag inventory has planning tags `v1.1` through `v2.1`, while tag snapshots declare package `0.1.0` at v1.1 and `0.1.1` from v1.2 through v2.1. [VERIFIED: live `git for-each-ref` and `git show <tag>:mix.exs` on 2026-09-09]

## Code Examples

### Byte-Safe Git Invocation

```javascript
// Source: https://nodejs.org/api/child_process.html and official Git porcelain docs
const result = spawnSync("git", ["-C", worktreePath, "status", "--porcelain=v2", "--branch", "-z"], {
  encoding: null,
  maxBuffer: 16 * 1024 * 1024,
});
```

The command uses an argument array, not a shell string; the buffer remains byte-oriented until the NUL-delimited parser consumes it. [CITED: https://nodejs.org/api/child_process.html; CITED: https://git-scm.com/docs/git-status]

### One Diagnostic, Two Views

```javascript
// Source: locked Phase 31 diagnostic contract
function diagnostic(fields) {
  return Object.freeze({ ...fields });
}

function render(result, format) {
  return format === "json"
    ? `${JSON.stringify(result, null, 2)}\n`
    : renderHumanFromSameResult(result);
}
```

Diagnostic field names in the final implementation are under the agent's discretion; the required semantic contents come from D-14. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:32-35; ASSUMED]

### No-Mutation Test Shape

```javascript
// Source: existing node:test pattern in scripts/ci_monitor.test.cjs
test("inventory is read-only", () => {
  const before = captureRefsIndexAndWorktreeFiles(repo);
  const result = runInventory(repo, ["--json"]);
  const after = captureRefsIndexAndWorktreeFiles(repo);
  assert.equal(result.status, 0);
  assert.deepEqual(after, before);
});
```

The helper details are planner-selected, but a before/after mutation sentinel is required because D-05 is behavioral, not merely a code-review claim. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:20-21; ASSUMED]

## State of the Art

| Old / Current Weak Approach | Required Phase 31 Approach | Impact |
|-----------------------------|----------------------------|--------|
| `git status --porcelain` only in `check_summary_drift.sh` | Repository-wide and all-worktree normalized inventory using porcelain v2 and worktree porcelain | Adds branch/upstream/divergence, worktree, lock, ownership, and disposition while retaining fail-closed behavior. [VERIFIED: bin/check_summary_drift.sh:13-38; CITED: https://git-scm.com/docs/git-status; CITED: https://git-scm.com/docs/git-worktree] |
| Phase/directory presence influences generic inspection | Explicit ROADMAP + STATE current reference, with directory presence only as corroborating evidence | Prevents phantom active/completed work. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:24-28] |
| Generic GSD health emits repository-agnostic W019 warnings | Repository policy validator distinguishes canonical local ledgers from unknown artifacts | Makes diagnostics actionable for oarlock without weakening generic GSD. [VERIFIED: live `validate health` output on 2026-09-09; VERIFIED: .planning/PROJECT.md:25-30] |
| Historical identity collapsed into milestone/tag prose | Separate planning milestone, tag, source SHA, package version, publication status | Prevents false release semantics. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:30-35] |

**Deprecated/outdated:**

- `.planning/state.json` as an independent or merged authority: no demonstrated file consumer was found; installed GSD's `state json` command reads `STATE.md` and emits JSON. Plan removal/ignore unless implementation discovers a real consumer. [VERIFIED: repository and installed-runtime `rg` on 2026-09-09; VERIFIED: /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs:11-18; VERIFIED: /Users/jon/.codex/gsd-core/workflows/next.md:12-29]
- Root `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` as v1.5 archive targets: those files are now mutable v2.2 authorities, so current `MILESTONES.md` links are not historical navigation. [VERIFIED: .planning/MILESTONES.md:68-93; VERIFIED: .planning/ROADMAP.md:1-45; VERIFIED: .planning/REQUIREMENTS.md:1-32]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Use Node/CommonJS and `node:test` for both CLIs. | Summary / Standard Stack | Planner may choose shell or Mix and lose reuse of the repository's existing structured-CLI fixtures. |
| A2 | Add a committed `.planning/repository-ownership.json` registry. | Architecture Patterns | Another schema/path may fit GSD better; exact location needs planner confirmation. |
| A3 | Use exit codes 0/1/2 for clean-or-warning / policy error / incomplete collection. | Architecture Patterns | Downstream CI/GSD consumers may require a different nonzero taxonomy. |
| A4 | Temporary real Git repositories are practical in Node tests. | Don't Hand-Roll / Validation | Platform-specific worktree or path behavior may require injected fixtures in addition. |

## Open Questions (RESOLVED)

1. **Ownership/exception registry — RESOLVED:** Store repository-local claims in the committed `.planning/repository-ownership.json` registry selected by Plan 31-01. The registry is versioned policy data beside the planning authorities, uses exact selectors, and records `owner`, `provenance`, `confidence`, `revisit_at`, and `proposed_disposition`. It never caches or overrides observed Git/process facts; absent, stale, or ambiguous evidence resolves to `unknown` and a nonzero diagnostic as required by D-03/D-04. [ASSUMED; planned in 31-01]

2. **Phase-completion proof chain — RESOLVED:** Plan 31-02 implements four mandatory links for every completion claim: (a) the current ROADMAP marks the phase accepted/complete, (b) every plan declared for that phase has its corresponding summary, (c) phase verification/evidence records success or an explicitly classified acknowledged caveat, and (d) every phase requirement is linked to that proof/evidence. Presence of a directory, plan, summary, verification filename, cache, research artifact, or archive satisfies none of these links by itself. `validateCompletionProof(snapshot, phase)` emits a distinct stable `PCOMP_*` diagnostic for each missing or contradictory link, and any error blocks completion/routing. [ASSUMED; planned in 31-02]

3. **GSD routing integration — RESOLVED:** Keep enforcement repository-local. Plan 31-02 adds `node scripts/planning_health.cjs` as the shared read-only entry and documents in `.planning/GSD-PREFERENCES.md` that maintainers and repository-operating GSD agents run it before routing or asserting completion. Exit 1 policy/authority errors and exit 2 incomplete/unsafe snapshots block those actions; warnings and info remain visible but non-blocking according to D-13. Existing installed GSD read-only queries are corroborating evidence only, and Phase 31 does not patch or replace the installed global GSD runtime. [ASSUMED; planned in 31-02]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | CLIs and tests | ✓ | 22.14.0 | Mix task or Bash, not recommended. [VERIFIED: `node --version` on 2026-09-09] |
| Git | Repository inventory and fixture repositories | ✓ | 2.41.0 | None; phase fundamentally inspects Git state. [VERIFIED: `git --version` on 2026-09-09] |
| Bash | Optional wrappers / existing CI composition | ✓ | 5.2.37 | Invoke Node directly. [VERIFIED: `bash --version` on 2026-09-09] |
| GSD runtime | Corroborating planning queries and supported repair suggestions | ✓ | runtime identity available through installed `gsd-tools.cjs` | Direct document parsing for report-only validation. [VERIFIED: successful `planning inspect`, `validate health`, `validate consistency`, and `drift-guard phase-status` queries on 2026-09-09] |

**Missing dependencies with no fallback:** None observed. [VERIFIED: environment probes on 2026-09-09]

**Missing dependencies with fallback:** None observed. [VERIFIED: environment probes on 2026-09-09]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node built-in `node:test`, Node 22.14.0. [VERIFIED: scripts/ci_monitor.test.cjs:1-8; VERIFIED: `node --version` on 2026-09-09] |
| Config file | none — built-in runner needs no config. [VERIFIED: existing repository file inventory and scripts/ci_monitor.test.cjs:1-8] |
| Quick run command | `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs` [ASSUMED] |
| Full suite command | `node --test scripts/*.test.cjs && mix test` [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPO-01 | Every registered worktree, dirty path, upstream/divergence, lock/prunable evidence, ownership, and disposition is present; human/JSON conclusions match; no writes occur. | integration with temporary Git repositories | `node --test scripts/repository_inventory.test.cjs` | ❌ Wave 0 [ASSUMED] |
| REPO-02 | Current milestone and phase resolve only from the authority chain; archive/cache/directory decoys cannot activate work; canonical disagreement blocks. | fixture-matrix unit/integration | `node --test scripts/planning_health.test.cjs --test-name-pattern="authority|phantom|conflict"` | ❌ Wave 0 [ASSUMED] |
| REPO-03 | All milestones have consistent index entries, phase ranges, archive links, tag/SHA/package/publication identities; frozen contradictions produce errata guidance. | fixture-matrix plus current-repo smoke | `node --test scripts/planning_health.test.cjs --test-name-pattern="milestone|archive|version"` | ❌ Wave 0 [ASSUMED] |
| REPO-04 | Stale active artifacts, broken references, archive contradictions, and unsupported completion claims produce stable actionable diagnostics and nonzero status without writes. | unit/CLI integration | `node --test scripts/planning_health.test.cjs --test-name-pattern="diagnostic|completion|read-only"` | ❌ Wave 0 [ASSUMED] |

### Sampling Rate

- **Per task commit:** `node --test scripts/repository_inventory.test.cjs scripts/planning_health.test.cjs` [ASSUMED]
- **Per wave merge:** `node --test scripts/*.test.cjs && mix test` [ASSUMED]
- **Phase gate:** both CLIs pass synthetic fixtures, intentionally report the current known exceptions, and the full suite is green before `$gsd-verify-work`. [ASSUMED]

### Wave 0 Gaps

- [ ] `scripts/repository_inventory.test.cjs` — covers REPO-01, NUL/path edge cases, inaccessible worktrees, dead/live PID evidence, registry expiry, human/JSON parity, and no-mutation sentinels. [ASSUMED]
- [ ] `scripts/planning_health.test.cjs` — covers REPO-02 through REPO-04, decoy artifacts, broken links, immutable archive contradictions, completion proof, version identity, deterministic ordering, and no-mutation sentinels. [ASSUMED]
- [ ] Shared fixture helpers for temporary repositories and planning trees. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Local read-only tooling introduces no authentication surface. [VERIFIED: phase boundary in .planning/phases/31-repository-planning-truth/31-CONTEXT.md:6-10] |
| V3 Session Management | no | No session or browser state is introduced. [VERIFIED: phase boundary in .planning/phases/31-repository-planning-truth/31-CONTEXT.md:6-10] |
| V4 Access Control | yes, local filesystem boundary | Resolve repo root, read only registered worktrees/canonical planning files, never elevate or mutate, and surface unreadable state as an error. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:18-21] |
| V5 Input Validation | yes | Treat Git output, paths, lock reasons, branch names, JSON registry fields, and Markdown text as untrusted data; parse bounded formats, validate schemas, sanitize terminal control characters, and never interpolate into a shell. [CITED: https://git-scm.com/docs/git-status; CITED: https://git-scm.com/docs/git-worktree; ASSUMED] |
| V6 Cryptography | no | No cryptographic primitive or secret handling is required. [VERIFIED: phase boundary in .planning/phases/31-repository-planning-truth/31-CONTEXT.md:6-10] |

### Known Threat Patterns for Local Repository Tooling

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Branch/path/lock reason injects terminal escapes or fake diagnostic text | Spoofing / Information display tampering | Escape control characters in human output and use `JSON.stringify` for JSON. [ASSUMED] |
| Shell interpolation executes a crafted path or ref | Tampering / Elevation | `spawnSync("git", args)` with argument arrays and no shell. [VERIFIED: scripts/ci_monitor.cjs:76-82; CITED: https://nodejs.org/api/child_process.html] |
| Symlink or Markdown link escapes repository boundary | Information disclosure | Normalize link targets; for planning references, report external/out-of-root targets instead of following them automatically. Registered Git worktrees are the explicit exception and must come from Git porcelain. [ASSUMED] |
| Health tool silently repairs or deletes | Tampering / Repudiation | Read-command allowlist, before/after mutation tests, and separate reviewed repair workflow. [VERIFIED: .planning/phases/31-repository-planning-truth/31-CONTEXT.md:20-21,27-29] |
| Huge/corrupt output exhausts memory | Denial of service | Explicit subprocess `maxBuffer`, bounded file sizes, error diagnostics on truncation/unreadability. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/31-repository-planning-truth/31-CONTEXT.md` — locked behavior, authority, history, diagnostic, and non-mutation contracts. [VERIFIED]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` — current scope and routing authorities. [VERIFIED]
- `.planning/MILESTONES.md`, `.planning/EVIDENCE.md`, and `.planning/milestones/*` — shipped-history/index/archive contradictions and additive correction precedent. [VERIFIED]
- `bin/check_summary_drift.sh`, `scripts/ci_monitor.cjs`, and `scripts/ci_monitor.test.cjs` — existing fail-closed shell and structured Node CLI/test patterns. [VERIFIED]
- Installed `gsd-tools.cjs` and workflows — actual GSD authority consumers, queries, drift handling, and supported mutation seams. [VERIFIED]
- Live Git/GSD/environment probes on 2026-09-09 — current inventory seeds and tool availability. [VERIFIED]

### Secondary (MEDIUM confidence)

- [Git worktree documentation](https://git-scm.com/docs/git-worktree) — stable porcelain, NUL mode, locked/prunable semantics, and prune dry-run. [CITED]
- [Git status documentation](https://git-scm.com/docs/git-status) — stable porcelain v1/v2, NUL mode, upstream and ahead/behind headers. [CITED]
- [Git rev-list documentation](https://git-scm.com/docs/git-rev-list) — left/right reachability counts. [CITED]
- [Node child_process documentation](https://nodejs.org/api/child_process.html) — argument-array subprocess execution. [CITED]

### Tertiary (LOW confidence)

- Planner-selected filenames, registry schema, exit-code partition, and fixture implementation details are recommendations marked `[ASSUMED]`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against current repository patterns, installed runtimes, and official Git docs.
- Architecture: HIGH — locked decisions dictate the snapshot/classify/diagnose/render separation; only exact filenames remain discretionary.
- Pitfalls: HIGH — current repository and installed GSD queries reproduce the key failure modes, and official Git docs define the stable parsing path.

**Research date:** 2026-09-09
**Valid until:** 2026-10-09; re-run live inventory immediately before implementation because repository/worktree facts are point-in-time.
