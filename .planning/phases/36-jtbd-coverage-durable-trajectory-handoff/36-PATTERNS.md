# Phase 36: JTBD Coverage, Durable Trajectory & Handoff - Pattern Map

**Mapped:** 2026-09-26  
**Files analyzed:** 8 proposed/likely files (4 candidate docs, 3 existing scripts, 1 conditional workflow)  
**Analogs found:** 8 / 8

> File layout is not locked. The three navigation documents below are candidate paths from RESEARCH.md, not confirmed existing files. Keep one canonical record owner; indexes should link by stable JTBD ID. A dedicated handoff filename is also unresolved, so update the existing authoritative handoff/state artifact unless planning chooses a new path.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/JTBD-COVERAGE.md` (candidate canonical record/trajectory file) | model / documentation | CRUD (append-only decision history) | `.planning/REQUIREMENTS.md`, `.planning/EVIDENCE.md` | role-match |
| `.planning/PERSONAS.md` (candidate link-only index) | documentation / index | request-response navigation | `.planning/research/FEATURES.md` | role-match |
| `.planning/WORKFLOWS.md` (candidate link-only index) | documentation / index | request-response navigation | `.planning/research/JTBD-GAPS.md` | role-match |
| `.planning/v2.2-HANDOFF.md` (possible new handoff; path undecided) | documentation / report | snapshot / request-response | `.planning/EVIDENCE.md`, `.planning/STATE.md` | role-match |
| `scripts/planning_health.cjs` (existing; possible CLI extension) | controller / CLI | request-response | same file | exact |
| `scripts/lib/repository_truth.cjs` (existing; possible validator/snapshot extension) | service / utility | transform, file-I/O | same file | exact |
| `scripts/planning_health.test.cjs` (existing; likely fixture coverage extension) | test | transform / file-I/O | same file | exact |
| `.github/workflows/ci.yml` (existing; integration only if justified) | config / workflow | event-driven | same file | exact |

## Pattern Assignments

### `.planning/JTBD-COVERAGE.md` (candidate canonical record/trajectory file)

**Analog:** `.planning/REQUIREMENTS.md` and `.planning/EVIDENCE.md` (both tracked).

Use a stable-ID table/section structure with descriptive headings and relative links. Keep status/horizon, ownership, source/rationale, proof class/evidence, freshness trigger, and append-only transitions in one canonical record. Do not make the persona/workflow indexes additional authorities.

**Evidence ledger structure** (`.planning/EVIDENCE.md`, lines 5-17):

```markdown
## v2.0 and v2.1 Requirement Evidence

| Requirement | Artifact | Evidence Class | Command / Proof | Caveat |
|-------------|----------|----------------|-----------------|--------|
| ADV-01 | `.planning/phases/25-offline-mode-foundation/VALIDATION.md` | Phase validation artifact | Lists OFF-01 through OFF-03 coverage ... | Validated via non-standard `VALIDATION.md`; ... |
```

Carry over the explicit proof class and caveat columns. For JTBD records add the fields demanded by ORIENT-01/02, and preserve previous status decisions with dated rationale/evidence instead of overwriting them.

### `.planning/PERSONAS.md` (candidate link-only index)

**Analog:** `.planning/research/FEATURES.md` (tracked; exact index layout remains a planner decision).

This index should answer “who has this job?” and point to canonical IDs, not copy status, rationale, transitions, or evidence. Use direct, descriptive links and semantic headings. Classify direct Oarlock audiences separately from evidence-backed external actors and candidates; the source research says external jobs need dated provenance and accountable owner/repository.

**Index/link pattern:** use descriptive heading sections and repository-relative artifact links as in `.planning/EVIDENCE.md` lines 9-20; the ledger links individual requirements to their supporting artifacts and states the evidence class/caveat alongside the reference. Keep this persona view shorter and link-only to avoid duplicated mutable facts.

### `.planning/WORKFLOWS.md` (candidate link-only lifecycle index)

**Analog:** `.planning/research/JTBD-GAPS.md` (tracked).

Organize by lifecycle/job question (“where does work succeed or stop?”), then link each row to the same canonical JTBD ID used by PERSONAS.md. Reuse descriptive headings and relative links. Gap descriptions may summarize the navigation label, but rationale, status, transition history, and evidence remain only in the canonical record.

### `.planning/v2.2-HANDOFF.md` (possible new handoff; filename/path undecided)

**Analog:** `.planning/STATE.md` for current pointer/continuity and `.planning/EVIDENCE.md` for classified proof and caveats.

Treat this as a dated snapshot report, not a new planning authority. Record exact target SHA, observed repository/worktree disposition, hosted proof identity, open blockers, accepted caveats, and evidence-backed candidates. State is time-sensitive: capture it at handoff creation. RESEARCH.md says this checkout's current dirty state is research-time only, so do not copy those observations into the eventual handoff as completion facts.

### `scripts/planning_health.cjs` (existing CLI; possible extension)

**Analog:** `scripts/planning_health.cjs` (tracked, lines 1-30, 32-50).

**Imports and CLI contract** (lines 4-10, 12-30):

```javascript
const {
  collectPlanningSnapshot,
  evaluatePlanningHealth,
  exitCodeFor,
  renderHuman,
  renderJson,
} = require("./lib/repository_truth.cjs");

const HELP = `Usage: node scripts/planning_health.cjs [--json] [--help]
...
This command has no repair/apply mode. Diagnostic repair fields are inert proposals.
`;
```

**Core and errors** (lines 32-50): `main(argv, options)` validates arguments, collects a snapshot, evaluates it, writes either human or JSON output, and returns the shared exit code. Follow that injectable `cwd`/stream/options pattern for any new entry point; reject unknown flags and keep diagnostics report-only. Prefer extending this CLI only if the existing planning-health authority boundary fits the new JTBD checks.

### `scripts/lib/repository_truth.cjs` (existing snapshot/validator library; possible extension)

**Analog:** `scripts/lib/repository_truth.cjs` (tracked, lines 1109-1178, 1749-1819).

**Safe file I/O** (lines 1109-1138, 1155-1177):

```javascript
if (absolute !== resolvedRoot && !absolute.startsWith(`${resolvedRoot}${path.sep}`)) {
  throw sourceBoundaryError("candidate escapes the resolved repository root", artifact);
}
// Each path component is lstat'ed; symlinks and non-directory intermediates fail.
...
const noFollow = typeof fs.constants.O_NOFOLLOW === "number" ? fs.constants.O_NOFOLLOW : 0;
descriptor = fs.openSync(candidate.absolute, fs.constants.O_RDONLY | noFollow);
```

Reuse bounded, repository-root-confined reads; do not create a permissive second authority resolver. Any JTBD validation should consume canonical snapshot documents and report ambiguous/unknown ownership conservatively.

**Evaluation and output contract** (lines 1749-1778, 1784-1819):

```javascript
function evaluatePlanningHealth(snapshot) {
  const activeScope = resolveActiveScope(snapshot);
  const diagnostics = [...activeScope.diagnostics, ...activeArtifactDiagnostics(snapshot, activeScope), ...mirrorDiagnostics(snapshot, activeScope), ...validateMilestoneHistory(snapshot)];
  // Collection errors become diagnostics; output is sorted deterministically.
  diagnostics.sort((left, right) => compareText(left.artifact, right.artifact) || compareText(left.code, right.code));
  ...
}

function renderJson(result) {
  return `${JSON.stringify(result, null, 2)}\n`;
}
```

Keep diagnostics deterministic and actionable, preserve human/JSON parity, and never mutate records or auto-promote/repair them.

### `scripts/planning_health.test.cjs` (existing fixture tests)

**Analog:** `scripts/planning_health.test.cjs` (tracked, lines 1-89, 331-341, 815-845, 862-879).

**Fixture setup** (lines 58-71):

```javascript
function writeFixture(files = planningDocuments()) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "planning-health-"));
  for (const [relative, content] of Object.entries(files)) {
    const target = path.join(root, relative);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content);
  }
  return root;
}
```

Add focused cases for unknown/duplicate JTBD IDs, bad index targets, missing provenance/proof fields, independent horizon/status taxonomies, and history preservation. Existing tests also check human/JSON diagnostic parity (lines 331-341), symlink boundary safety (815-845), and no file mutation (862-879); mirror those guarantees if validator code is extended. Use `node:test` and built-ins, no new package.

### `.github/workflows/ci.yml` (conditional integration)

**Analog:** `.github/workflows/ci.yml` (tracked, lines 349-359; aggregate lines 441-472).

```yaml
- name: Run clean production Node suite
  run: node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs
...
- name: Smoke live planning health JSON
  run: node scripts/planning_health.cjs --json
```

Add a new check to the existing aggregate only if the plan establishes repeatable risk reduction that justifies its recurring runtime/maintenance cost. Do not create a parallel green definition. A scheduled run is evidence for its observed SHA only; it cannot stand in for exact-target handoff proof.

## Shared Patterns

### Authority and unknowns

**Source:** `scripts/lib/repository_truth.cjs` lines 1109-1177 and existing ownership rules in `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md`.  
**Apply to:** validator, canonical records, and handoff.

Use bounded repository reads; resolve authority only from designated source files. Missing, stale, incomplete, or contradictory inputs remain explicitly unknown/historical and produce diagnostics rather than automatic winner selection.

### Evidence identity and history

**Source:** `.planning/EVIDENCE.md` lines 7-29.  
**Apply to:** canonical JTBD records and handoff.

Keep proof classes distinct (unit/local, MockServer, package/downstream, hosted CI, sandbox, live provider); state source, identity, caveat, and freshness trigger. Exact-SHA hosted/package proof must name the observed SHA/artifact; do not turn scheduled evidence into proof for another target.

### Deterministic read-only diagnostics

**Source:** `scripts/planning_health.cjs` lines 12-45; `scripts/lib/repository_truth.cjs` lines 1749-1819; tests lines 331-341 and 862-879.  
**Apply to:** any validator extension and its tests.

Reports have a shared evaluation result for human and JSON views, deterministic diagnostic ordering, stable actionable codes, and no repository mutation.

## No Analog Found

No fully equivalent end-to-end JTBD coverage map or paired persona/lifecycle indexes exist. The candidate documentation paths should derive their content schema from Phase 36 requirements and research, using the linked ledgers/research files only for format patterns.

## Metadata

**Analog search scope:** `.planning/`, `scripts/`, `.github/workflows/`  
**Files scanned:** 8 analog locations, selected after direct path/line inspection  
**Tracked-source gate:** all named source analogs were confirmed by `git ls-files`; untracked Phase 36 research was not treated as an existing codebase analog.  
**Pattern extraction date:** 2026-09-26
