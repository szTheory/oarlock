# Phase 31: Repository & Planning Truth - Pattern Map

**Mapped:** 2026-09-09
**Files analyzed:** 8 recommended new/modified files
**Analogs found:** 8 / 8 (one partial structural match; no existing ownership-registry semantic analog)

The paths below follow the research recommendation. The exact module split is planner-selectable, but the phase needs one shared result model, two thin views, tests for both domains, a committed exception registry, and additive current-ledger repairs. `.planning/state.json` is a disposition target under D-10, not a source pattern: remove the current untracked mirror if no consumer is discovered, or retain it only as a generated/versioned mirror. Do not let it become another authority.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/lib/repository_truth.cjs` | service | transform + file-I/O | `scripts/ci_monitor.cjs` | role-match |
| `scripts/repository_inventory.cjs` | controller (CLI) | request-response | `scripts/ci_monitor.cjs` | role-match |
| `scripts/planning_health.cjs` | controller (CLI) | request-response | `scripts/ci_monitor.cjs` | role-match |
| `scripts/repository_inventory.test.cjs` | test | batch + file-I/O | `scripts/ci_monitor.test.cjs` | exact |
| `scripts/planning_health.test.cjs` | test | batch + file-I/O | `scripts/ci_monitor.test.cjs` | exact |
| `.planning/repository-ownership.json` | config | CRUD / lookup | `.planning/config.json` | partial |
| `.planning/MILESTONES.md` | model / ledger | file-I/O | `.planning/MILESTONES.md` | exact internal pattern |
| `.planning/EVIDENCE.md` | model / ledger | file-I/O | `.planning/EVIDENCE.md` | exact internal pattern |

All named analogs were verified with `git ls-files`; no ignored runtime mirror is cited.

## Pattern Assignments

### `scripts/lib/repository_truth.cjs` (service, transform + file-I/O)

**Analog:** `scripts/ci_monitor.cjs`

**CommonJS and dependency-injection pattern** (`scripts/ci_monitor.cjs`, lines 1-4 and 76-81):

```javascript
#!/usr/bin/env node

const { spawnSync } = require("node:child_process");

function runGh(args, options = {}) {
  const ghBin = options.ghBin || process.env.CI_MONITOR_GH_BIN || "gh";
  const result = spawnSync(ghBin, args, {
    encoding: "utf8",
    env: options.env || process.env,
  });
```

Copy the argument-array invocation and injectable options seam, but use `encoding: null` for NUL-delimited Git output. Add built-in `node:fs` and `node:path` imports; do not add a dependency.

**Explicit collection error pattern** (`scripts/ci_monitor.cjs`, lines 83-115):

```javascript
if (result.error) {
  throw new GhError(`Unable to execute ${ghBin}: ${result.error.message}`, {
    status: 2,
    stderr: result.error.message,
  });
}

if (result.status !== 0) {
  throw new GhError(result.stderr || result.stdout || "gh command failed", {
    status: 2,
    stderr: result.stderr,
    stdout: result.stdout,
    ghStatus: result.status,
  });
}

class GhError extends Error {
  constructor(message, details = {}) {
    super(message);
    this.name = "GhError";
    this.details = details;
  }
}
```

Use the same typed-error shape for incomplete/unreadable repository observations. Preserve command, status, stderr, artifact/worktree, and field evidence so the CLI can return the distinct incomplete-collection exit.

**Normalize first, evaluate from data** (`scripts/ci_monitor.cjs`, lines 117-129 and 169-190):

```javascript
function normalizeRun(run) {
  return {
    id: run.databaseId,
    workflowName: run.workflowName,
    headSha: run.headSha,
    status: run.status,
    conclusion: run.conclusion,
    url: run.url,
    attempt: run.attempt,
    createdAt: run.createdAt,
    updatedAt: run.updatedAt,
  };
}

function jobEvidence(jobs, requiredJobs) {
  const byName = new Map(jobs.map((job) => [job.name, job]));
  const required = requiredJobs.map((name) => {
    const job = byName.get(name);
    return {
      name,
      found: Boolean(job),
      status: job ? job.status : "missing",
      conclusion: job ? job.conclusion : "missing",
    };
  });
```

Apply this separation as `collectSnapshot(...)` followed by pure classification/validation. Normalize worktrees and paths into deterministic order before either renderer runs. Ownership registry matches add claims and proposed dispositions; they never replace Git facts.

**Structured outcome and fail-closed pattern** (`scripts/ci_monitor.cjs`, lines 192-203 and 217-240):

```javascript
if (!sha) {
  return {
    exitCode: 2,
    evidence: {
      verified: false,
      reason: "missing_sha",
      message: "Pass --sha <commit-sha>.",
    },
  };
}

try {
  run = findRun({ sha, workflow, repo }, options);
} catch (error) {
  return {
    exitCode: 2,
    evidence: {
      verified: false,
      reason: "gh_error",
      message: error.message,
      details: error.details || {},
    },
  };
}
```

Return data rather than exiting inside collectors. Recommended Phase 31 meaning: `0` means no error diagnostics, `1` means a policy/invariant error, and `2` means observation was incomplete or unsafe to interpret.

**Export seam** (`scripts/ci_monitor.cjs`, lines 355-367):

```javascript
if (require.main === module) {
  main().then((exitCode) => {
    process.exitCode = exitCode;
  });
}

module.exports = {
  DEFAULT_REQUIRED_JOBS,
  assertCi,
  jobEvidence,
  main,
  parseArgs,
};
```

Export collectors, parsers, validators, diagnostic construction, renderers, and exit-code selection so tests can exercise pure seams without spawning for every case.

---

### `scripts/repository_inventory.cjs` (controller, request-response)

**Analog:** `scripts/ci_monitor.cjs`

**CLI parsing and usage pattern** (`scripts/ci_monitor.cjs`, lines 14-37 and 39-74):

```javascript
function usage() {
  return `Usage:
  node scripts/ci_monitor.cjs assert-ci --sha <sha> [options]

Options:
  --json                 Print machine-readable JSON evidence.
  --help                 Show this help.

Exit codes:
  0    CI evidence verified
  1    CI run or a required job completed unsuccessfully
  2    Blocked: no pushed run, missing auth, or invalid usage
`;
}

function parseArgs(argv) {
  const args = { _: [], requiredJobs: [] };
  // explicit option parsing; throw on a missing value
  return args;
}
```

Keep this CLI thin: resolve args/CWD, invoke the shared library once, choose human or JSON formatting, and set the returned exit code. Document read-only behavior and the exit taxonomy in usage.

**One result, two output views** (`scripts/ci_monitor.cjs`, lines 311-326):

```javascript
function printEvidence(evidence, asJson) {
  if (asJson) {
    console.log(JSON.stringify(evidence, null, 2));
    return;
  }

  if (evidence.verified) {
    console.log(`CI verified for ${evidence.sha}: ${evidence.run.url}`);
    return;
  }

  console.error(`CI verification failed: ${evidence.reason}`);
}
```

Unlike the analog, both Phase 31 views must expose the same ordered diagnostics and stable codes. No collection, filtering, classification, or severity logic belongs in the format branch.

**Main/exit handling** (`scripts/ci_monitor.cjs`, lines 328-358):

```javascript
async function main(argv = process.argv.slice(2), options = {}) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 2;
  }

  const { exitCode, evidence } = await assertCi(args, options);
  printEvidence(evidence, args.json);
  return exitCode;
}
```

No auth/guard convention applies; this is a local read-only CLI. Its safety guard is an allowlist of inspection-only Git commands (`worktree list --porcelain -z`, `status --porcelain=v2 --branch -z`, explicit ref queries, and `worktree prune --dry-run --verbose`).

---

### `scripts/planning_health.cjs` (controller, request-response)

**Analog:** `scripts/ci_monitor.cjs`

Reuse the inventory CLI patterns above from `scripts/ci_monitor.cjs` lines 14-74, 311-358: parse `--json`/`--help`, perform exactly one shared-library evaluation, render that result, and assign `process.exitCode`. The planning CLI must not call GSD mutation handlers. If it reports a repair, emit a supported next command or proposed patch as diagnostic data only.

**Stable result mapping pattern** (`scripts/ci_monitor.cjs`, lines 264-292):

```javascript
const evidence = {
  verified:
    runConclusion === "success" &&
    jobsEvidence.missing.length === 0 &&
    jobsEvidence.failed.length === 0,
  workflow,
  sha,
  run: normalizeRun({ ...run, ...viewed }),
  jobs: jobsEvidence.required,
};

if (!evidence.verified) {
  return {
    exitCode: 1,
    evidence: {
      ...evidence,
      reason: "required_job_not_successful",
    },
  };
}
```

For Phase 31, build diagnostics with at least `code`, `severity`, `artifact`, `field`, `expected`, `actual`, `authority`, `evidence`, and `repair`; warnings/intentional exceptions also carry owner and revisit metadata. Sort them deterministically before deriving both output formats and the exit code.

---

### `scripts/repository_inventory.test.cjs` (test, batch + file-I/O)

**Analog:** `scripts/ci_monitor.test.cjs`

**Built-in test stack** (`scripts/ci_monitor.test.cjs`, lines 1-8):

```javascript
const assert = require("node:assert/strict");
const { mkdtempSync, writeFileSync, chmodSync, rmSync, readFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join } = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");
```

Use temporary real Git repositories/worktrees for porcelain behavior, plus injected runners for inaccessible/error branches.

**Fixture lifecycle and guaranteed cleanup** (`scripts/ci_monitor.test.cjs`, lines 10-15 and 79-107):

```javascript
function makeFakeGh(scenario) {
  const dir = mkdtempSync(join(tmpdir(), "ci-monitor-"));
  const fakeGh = join(dir, "gh");

  return {
    dir,
    env: { ...process.env },
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}

function runMonitor(scenario, extraArgs = []) {
  const fake = makeFakeGh(scenario);
  try {
    return spawnSync(process.execPath, [script, "assert-ci", "--json", ...extraArgs], {
      encoding: "utf8",
      env: fake.env,
    });
  } finally {
    fake.cleanup();
  }
}
```

Do not reuse a user's repository as a destructive fixture. Capture refs/index/worktree administrative state before and after both human and JSON invocations and assert equality.

**CLI contract assertions** (`scripts/ci_monitor.test.cjs`, lines 110-148):

```javascript
test("assert-ci exits 0 with exact SHA and all required jobs successful", () => {
  const result = runMonitor("success");
  assert.equal(result.status, 0);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.verified, true);
});

test("assert-ci fails when a required job is missing", () => {
  const result = runMonitor("missing-job");
  assert.equal(result.status, 1);
  assert.equal(JSON.parse(result.stdout).reason, "required_job_missing");
});
```

Cover every registered worktree, dirty/renamed paths with spaces and newlines, upstream divergence, locked/prunable evidence, live/dead PID evidence, exact registry matching, unknown ownership, expired claims, deterministic ordering, output parity, exit `2` on incomplete observation, and no mutation.

---

### `scripts/planning_health.test.cjs` (test, batch + file-I/O)

**Analog:** `scripts/ci_monitor.test.cjs`

Reuse `scripts/ci_monitor.test.cjs` lines 1-8 for the built-in stack, lines 10-107 for isolated fixture lifecycle, and lines 110-155 for status-plus-JSON assertions. Build small planning fixture matrices rather than mutating root planning files.

Required cases: ROADMAP/STATE agreement; disagreement as blocking; archives/caches/summaries/future phase directories as inert decoys; source-anchor IDs excluded from requirements; broken archive links; omitted milestone entries; frozen archive contradictions producing errata guidance; planning milestone/tag/SHA/package/publication identities kept separate; unsupported completion claims; deterministic diagnostics; human/JSON code-and-conclusion parity; and before/after no-write sentinels.

---

### `.planning/repository-ownership.json` (config, CRUD / lookup)

**Analog:** `.planning/config.json` (structure only)

**Committed local JSON convention** (`.planning/config.json`, lines 1-13):

```json
{
  "granularity": "coarse",
  "commit_docs": true,
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "pattern_mapper": true
  }
}
```

Copy the committed, two-space-indented JSON data-file convention. Do not copy its general settings schema. The ownership registry needs explicit schema/version metadata and narrow selectors, with each claim containing owner, provenance, confidence, revisit date, and proposed disposition. It stores no observed dirty/branch/lock facts and must never infer ownership from branch/path naming.

This is only a structural analog; no existing repository file implements evidence-backed ownership exceptions. Use the Phase 31 research schema/decisions for semantics and test missing, stale, expired, and ambiguous records fail closed.

---

### `.planning/MILESTONES.md` (model / ledger, file-I/O)

**Analog:** `.planning/MILESTONES.md` (existing entries and correction style)

**Identity and archive block** (`.planning/MILESTONES.md`, lines 7-11 and 30-35):

```markdown
## v2.1 Adopter Truth & Release Readiness (Shipped: 2026-06-25)

**Status:** ✅ Shipped
**Phases:** 27-30 (4 phases, 10 plans, 22 tasks)
**Test suite at tag:** Local release-proof gates passed; hosted GitHub Actions exact-SHA proof remains deferred until pushed/PR CI runs.

### Archive

- Roadmap: `.planning/milestones/v2.1-ROADMAP.md`
- Requirements: `.planning/milestones/v2.1-REQUIREMENTS.md`
- Audit: `.planning/milestones/v2.1-MILESTONE-AUDIT.md`
- Tag: `v2.1`
```

Add the missing v1.2 and v1.4 current-index entries and repair v1.5 navigation to immutable archive targets. Keep planning milestone, Git tag, tag target/source SHA, `mix.exs` package version, and publication status as separately labeled identities rather than deriving one from another.

**Additive correction precedent** (`.planning/MILESTONES.md`, lines 55-64):

```markdown
### Correction - 2026-06-24

Earlier v2.0 wording implied Phase 26 provider-state verification. The canonical evidence ledger is `.planning/EVIDENCE.md`: ADV-02 is MockServer-backed integration proof unless sandbox/live Paddle provider-state evidence is separately recorded.

### Archive

- Roadmap: `.planning/milestones/v2.0-ROADMAP.md`
- Requirements: `.planning/milestones/v2.0-REQUIREMENTS.md`
- Audit: `.planning/v2.0-MILESTONE-AUDIT.md`
- Tag: `v2.0`
```

Use dated corrections in the current ledger. Never edit frozen milestone snapshots to make their historical wording agree with current interpretation.

---

### `.planning/EVIDENCE.md` (model / ledger, file-I/O)

**Analog:** `.planning/EVIDENCE.md` (existing evidence table and proof-class rules)

**Evidence row schema** (`.planning/EVIDENCE.md`, lines 5-10):

```markdown
## v2.0 and v2.1 Requirement Evidence

| Requirement | Artifact | Evidence Class | Command / Proof | Caveat |
|-------------|----------|----------------|-----------------|--------|
| ADV-01 | `.planning/phases/25-offline-mode-foundation/VALIDATION.md` | Phase validation artifact | Lists OFF-01 through OFF-03 coverage ... | Validated via non-standard `VALIDATION.md`; the standard `25-VERIFICATION.md` filename is absent ... |
```

Append corrections/evidence rather than rewriting existing proof claims. New history reconciliation should link the preserved historical artifact and record the corrected interpretation plus exact identity fields where known.

**Proof-boundary rules** (`.planning/EVIDENCE.md`, lines 24-29):

```markdown
## Proof-Class Rules

- `VALIDATION.md` can be real proof even when a standard `VERIFICATION.md` filename is absent. The caveat is artifact-standard drift, not missing evidence.
- MockServer-backed integration proof demonstrates deterministic local SDK/demo behavior. It does not prove Paddle sandbox/live provider state.
- Sandbox/live provider-state proof requires real credentials, isolated provider state, and a separately recorded command or run artifact.
- Planning reconciliation evidence proves repository memory and release posture, not new SDK runtime behavior.
```

Extend this style with milestone-history correction rules; do not let artifact presence alone satisfy completion.

## Shared Patterns

### Read-only, argument-array process execution

**Sources:** `scripts/ci_monitor.cjs` lines 76-107; `bin/check_summary_drift.sh` lines 13-20 (behavioral precedent)

`scripts/ci_monitor.cjs` supplies the safe Node invocation/error pattern. `bin/check_summary_drift.sh` demonstrates the repository's existing inspect-then-fail behavior:

```bash
if [ -n "$(git status --porcelain)" ]; then
    git status --porcelain
    exit 1
fi
```

Phase 31 supersedes the shell parser for repository inventory, but preserves its non-mutating and fail-closed intent. Never call `prune` without `--dry-run`, or call `unlock`, `remove`, `reset`, `restore`, `clean`, `stash`, or GSD mutation handlers.

### Same result for human and JSON

**Source:** `scripts/ci_monitor.cjs` lines 311-326

Apply to both CLIs. Collection and severity decisions happen once; renderers only format. Tests compare stable diagnostic codes, severity, affected artifact/field, expected/actual conclusions, authority, and exit status across formats.

### Error handling and status taxonomy

**Source:** `scripts/ci_monitor.cjs` lines 83-115, 192-240, 264-305

Apply to shared collectors and both CLIs. Represent expected failures as structured results. Reserve thrown typed errors for collection/process failures, catch them at the evaluation boundary, and retain details. No authentication pattern applies.

### Deterministic normalization

**Source:** `scripts/ci_monitor.cjs` lines 117-190

Apply to Git observations, ownership matches, planning invariants, and diagnostics. Convert external records to a declared internal shape, preserve observed facts separately from disposition claims, and sort arrays before rendering/serialization.

### Additive historical correction

**Sources:** `.planning/MILESTONES.md` lines 55-64; `.planning/EVIDENCE.md` lines 24-29

Apply to all REPO-03 repairs. Current navigation and ledgers may change; archived milestone roadmaps and requirements remain immutable. Corrections must be dated and point back to the preserved historical record.

## No Exact Analog Found

| File | Role | Data Flow | Reason / Fallback |
|------|------|-----------|-------------------|
| `.planning/repository-ownership.json` | config | CRUD / lookup | `.planning/config.json` provides only formatting/location convention. Use D-03/D-04 and RESEARCH.md for owner, provenance, confidence, revisit date, selector, and disposition semantics. |

## Scope Boundaries for Planning

- Treat `.planning/state.json` according to D-10: first demonstrate a consumer. If none exists, remove the untracked file or ignore the generating source; if retained, test atomic regeneration and include source/schema version. Never read it as authority.
- Do not edit `.planning/milestones/v*-ROADMAP.md` or `v*-REQUIREMENTS.md` to normalize history. If immutable v1.5 archive material must be recovered from a tag, create/recover a truthful frozen target and update current navigation; do not redirect the index to mutable root files.
- Do not patch the installed `/Users/jon/.codex/gsd-core` runtime. GSD read-only queries may corroborate results; repository documents own their specified data.
- Phase 31 reports proposed patches/commands only. Any separate repair task must use supported handlers and record a dated correction.

## Metadata

**Analog search scope:** tracked files under `scripts/`, `bin/`, and `.planning/`; canonical Phase 31 inputs and current authority documents
**Files scanned:** 344 files under `scripts/`, `bin/`, and `.planning/`
**Strong analogs used:** `scripts/ci_monitor.cjs`, `scripts/ci_monitor.test.cjs`, `bin/check_summary_drift.sh`, `.planning/MILESTONES.md`, `.planning/EVIDENCE.md`; `.planning/config.json` used only as a structural JSON convention
**Pattern extraction date:** 2026-09-09
