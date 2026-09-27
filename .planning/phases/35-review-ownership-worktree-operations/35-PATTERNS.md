# Phase 35: Review, Ownership & Worktree Operations - Pattern Map

**Mapped:** 2026-09-25  
**Files analyzed:** 16 target groups (including research placeholders)  
**Analogs found:** 14 / 16 target groups have a tracked pattern source (2 have no safe analog)

The research intentionally leaves several script/test basenames and the triage-record location open. Keep those names as planning decisions; do not treat the placeholders below as chosen paths. Do not add owner routes or a private vulnerability destination without verified evidence. Research reports private vulnerability reporting disabled, so `SECURITY.md` channel wording remains gated on configuration or a verified alternative.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `CONTRIBUTING.md` | documentation | request-response | `README.md` | role-match |
| `SECURITY.md` | documentation/policy | request-response | `README.md` (voice only) | partial; private channel unresolved |
| `.github/ISSUE_TEMPLATE/config.yml` and a small set of issue form `.yml` files (exact forms TBD) | config/intake | request-response | `.github/workflows/ci.yml` (YAML conventions only) | partial |
| `.github/pull_request_template.md` | template | request-response | `README.md` (voice only) | partial |
| `.github/CODEOWNERS` (only if verified owners and paths exist) | config/routing | request-response | none | no analog; ownership evidence required |
| `.github/dependabot.yml` | config | event-driven proposals | `.github/workflows/ci.yml` | role-match |
| Maintainer dated issue/PR triage record (location and format TBD) | record/model | CRUD | `.planning/repository-ownership.json` conventions in `scripts/lib/repository_truth.cjs` | partial |
| `scripts/<triage-audit>.cjs` (name TBD) | utility/CLI | request-response + read-only remote/file I/O | `scripts/repository_inventory.cjs` | role-match |
| `scripts/<triage-audit>.test.cjs` (name TBD) | test | batch/transform | `scripts/ci_proof.test.cjs` | role-match |
| `scripts/<worktree-gate>.cjs` (name TBD) | utility/CLI | file I/O + request-response | `scripts/repository_inventory.cjs`, `scripts/lib/repository_truth.cjs` | exact for inventory evidence; partial for manifest lifecycle |
| `scripts/<worktree-gate>.test.cjs` (name TBD) | test | batch/file I/O | `scripts/repository_inventory.test.cjs` | role-match |
| `scripts/<collaboration-contract>.test.cjs` (name TBD) | test | batch/transform | `scripts/ci_proof.test.cjs` | role-match |
| `scripts/<dependabot-contract>.test.cjs` (name TBD) | test | batch/transform | `scripts/ci_proof.test.cjs` | role-match |
| `.planning/config.json` | config (preserve current value) | configuration | current file | exact existing configuration; keep `workflow.use_worktrees: false` |
| `.planning/repository-ownership.json` | registry (conditional extension only) | CRUD/record validation | `scripts/lib/repository_truth.cjs` | exact conventions; research says extend only if cleanly supported |
| `SECURITY.md` private route verification evidence | external setting, not a source file | request-response | none | no code analog; maintainer/repository setting proof required |

## Pattern Assignments

### `CONTRIBUTING.md` (documentation, request-response)

**Analog:** `README.md` (tracked; concise product boundary and evidence language)

Use the repository's direct, concrete voice and explain the SDK/demo boundary. The README describes what the SDK is responsible for and makes proof claims conditional on the evidence actually gathered.

**Voice and proof pattern** (`README.md`, lines 3-8, 28-44):

```markdown
Paddle Billing for Elixir, with a deliberately small surface.

oarlock gives you typed `Paddle.*` structs, explicit `%Paddle.Client{}` passing,
and pure-function webhook verification/parsing. It does not try to be your
billing domain model, your Phoenix integration layer, or your persistence
strategy.

Use the same proof ladder throughout an integration:
- Unit and contract tests prove local SDK behavior.
- Hosted CI proves only the exact commit and workflow rows it actually ran.
```

Contributors should get a bounded change path and evidence proportionate to change risk. Don't transplant product installation material wholesale.

### `SECURITY.md` (documentation/policy, request-response)

**Analog:** no complete analog. `README.md` is only a voice reference.

The private reporting path is an external repository setting, not inferable from source. Research says GitHub private vulnerability reporting is disabled and found no verified alternative. Keep the file/channel completion blocked until a maintainer verifies a private channel; never substitute a public issue, guessed email, or unconfigured feature.

### `.github/ISSUE_TEMPLATE/*` and `.github/pull_request_template.md` (intake/template, request-response)

**Analog:** `.github/workflows/ci.yml` for tracked GitHub YAML practices; no issue-form or PR-template analog exists.

Use a small number of versioned forms/templates. Form fields and labels are intake cues only because users can edit form output and labels can drift. The PR template should ask for one intent, scope/non-goals, relevant risk/compatibility, and proof actually run, including exact-SHA CI evidence when available. Keep evidence demands proportional to the change.

**Existing GitHub workflow YAML convention** (`.github/workflows/ci.yml`, lines 349-359):

```yaml
- name: Run clean production Node suite
  run: node --test scripts/*.test.cjs scripts/prohibitions/*.test.cjs

- name: Smoke live planning health JSON
  run: node scripts/planning_health.cjs --json
```

This is only a repo YAML/style analog, not a functional issue-form analog.

### `.github/CODEOWNERS` (config/routing, request-response)

**Analog:** none. The context explicitly requires verified owners and paths. Repository patterns do not establish who owns a path, and there is no existing tracked CODEOWNERS file. Do not add guessed accounts, teams, or broad ownership routes. If evidence remains unavailable, surface that unknown in planning rather than manufacturing a route.

### `.github/dependabot.yml` (config, event-driven proposals)

**Analog:** `.github/workflows/ci.yml` for existing GitHub configuration conventions; root and `demo/` Mix projects for the two independent dependency boundaries.

Use separate Dependabot Mix entries for `/` and `/demo`, plus the Actions ecosystem at `/`. Group only compatible routine updates inside each root/demo boundary; keep majors individually reviewable and security updates distinct and prompt. Updates remain proposals with no auto-merge. Mix production/development groups apply only where their categories match actual dependencies.

**CI contract and Hex audit** (`.github/workflows/ci.yml`, lines 392-405):

```yaml
- name: Audit Hex advisories
  if: ${{ always() }}
  run: mix hex.audit

ci-contract:
  name: CI contract
```

Route dependency proposals through this existing exact-SHA aggregate and its relevant checks; don't create another definition of green.

### Maintainer triage record (location and schema TBD; CRUD/record)

**Analog:** `.planning/repository-ownership.json` parsing and validation in `scripts/lib/repository_truth.cjs` (tracked). No issue/PR triage record currently exists.

Keep observed GitHub fields separate from maintainer decisions. Each open issue/PR needs a controlled state, owner or explicit `unknown`, scope decision, and a concrete next action. A `needs-info` decision must name missing information plus who and when will follow up. Preserve dated records; do not infer scope/owner from prose, labels, or CODEOWNERS. Research leaves the location and vocabulary to planning.

**Validated structured record pattern** (`scripts/lib/repository_truth.cjs`, lines 323-340):

```javascript
if (!registry || registry.schema_version !== SCHEMA_VERSION || !Array.isArray(registry.claims)) {
  diagnostics.push(makeDiagnostic({
    code: "RINV_REGISTRY_INVALID", severity: "error", artifact: ".planning/repository-ownership.json",
    field: "schema", expected: { schema_version: SCHEMA_VERSION, claims: "array" }, actual: registry ?? null,
    authority: ".planning/repository-ownership.json", evidence: "ownership registry failed structural validation",
    repair: "Review and correct the registry schema; do not infer ownership.", incomplete: true,
  }));
}
```

The existing registry is only an analog, not an instruction to add a second ownership source. Extend it only if the implementation demonstrates a clean fit.

### `scripts/<triage-audit>.cjs` (utility/CLI, request-response + read-only remote/file I/O)

**Analog:** `scripts/repository_inventory.cjs` (tracked; closest CLI shape)

Use an injectable `main(argv, options)` for fixture tests, explicit option validation, structured results, human/JSON output from the same result, and nonzero exit codes for incomplete/contradictory evidence.

**Imports, CLI boundary, output, and exit pattern** (`scripts/repository_inventory.cjs`, lines 4-12, 50-89):

```javascript
const path = require("node:path");
const {
  collectRepositorySnapshot,
  evaluateRepositoryInventory,
  exitCodeFor,
  renderHuman,
  renderJson,
} = require("./lib/repository_truth.cjs");

function main(argv = process.argv.slice(2), options = {}) {
  const unknown = argv.filter((argument) => !["--json", "--help"].includes(argument));
  // Validate arguments; collect and evaluate without mutation.
  const result = evaluateRepositoryInventory(snapshot, registry);
  (options.stdout || process.stdout).write(argv.includes("--json") ? renderJson(result) : renderHuman(result));
  return exitCodeFor(result);
}
if (require.main === module) process.exitCode = main();
module.exports = { HELP, main, readRegistry };
```

For GitHub access, use read-only fields and complete pagination; do not expose tokens in errors/output. A live smoke may need repository credentials, but fixture tests must remain deterministic.

### `scripts/<worktree-gate>.cjs` (utility/CLI, file I/O + request-response)

**Analog:** `scripts/lib/repository_truth.cjs` and its wrapper `scripts/repository_inventory.cjs` (tracked).

Reuse fixed-argument subprocess execution with `shell: false`, bounded buffers/timeouts, `GIT_OPTIONAL_LOCKS=0`, explicit command allowlists, and structured incompleteness. Parse porcelain `-z` output rather than human output. Bind any proposed task manifest to the observed path, branch, base SHA, and owner before reporting isolation; an unsupported or ambiguous host/manifest fails closed. Keep facts separate from intended disposition. Never remove, unlock, reset, force, or run non-dry-run prune.

**Safe subprocess pattern** (`scripts/lib/repository_truth.cjs`, lines 70-97):

```javascript
function invoke(command, args, options) {
  const runner = options.runner || spawnSync;
  return runner(command, args, {
    cwd: options.cwd,
    encoding: null,
    env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
    shell: false,
    windowsHide: true,
    maxBuffer: options.maxBuffer,
    timeout: options.timeoutMs ?? DEFAULT_SUBPROCESS_TIMEOUT_MS,
  });
}

function runGit(args, options) {
  if (!allowedGitArguments(args)) {
    throw new Error(`unsafe Git inspection command rejected: git ${args.join(" ")}`);
  }
  const result = invoke(options.gitBinary || "git", args, options);
  if (result.error || result.signal || result.status !== 0) {
    const error = result.error || new Error(result.signal
      ? `git terminated by signal ${result.signal}`
      : Buffer.from(result.stderr || []).toString("utf8").trim() || `git exited ${result.status}`);
    error.status = result.status;
    error.signal = result.signal;
    throw error;
  }
  return Buffer.isBuffer(result.stdout) ? result.stdout : Buffer.from(result.stdout || "");
}
```

**NUL-safe inventory and evidence pattern** (`scripts/lib/repository_truth.cjs`, lines 103-130, 243-320):

```javascript
records = parseWorktreeList(runGit(["worktree", "list", "--porcelain", "-z"], commandOptions));
// For each registered tree, collect status using fixed argument-array invocation:
const parsed = parseStatus(runGit(["-C", record.path, "status", "--porcelain=v2", "--branch", "-z"], commandOptions));
worktree.head = parsed.head || worktree.head;
worktree.branch = parsed.branch;
worktree.dirty = parsed.dirty;
```

The existing inventory is read-only and not a complete task lifecycle implementation. Do not enable `workflow.use_worktrees` or claim task isolation until host support, clean-entry, manifest binding, and exit evidence are established. Preserve the current false setting and all existing worktree states.

### New test files (Node built-in test runner; batch/transform and fixture I/O)

**Analog:** `scripts/ci_proof.test.cjs` (tracked), with `scripts/repository_inventory.test.cjs` for temporary Git repositories and read-only assertions.

Use `node:test`, `node:assert/strict`, temporary fixtures, explicit cleanup, table-driven invalid cases, and tests that verify unknown/missing/contradictory evidence fails closed. For the triage audit, prove no GitHub mutation; for the worktree gate, exercise odd NUL-containing paths, manifest mismatch, dirty/locked/stale/unreadable states, and zero destructive invocations. For YAML checks, validate boundaries/groups and absence of auto-merge policy. Keep exact filenames for these test files as planning choices because research uses placeholders.

**Fixture and fail-closed test pattern** (`scripts/ci_proof.test.cjs`, lines 1-7, 9-15, 41-54, 92-104):

```javascript
const assert = require("node:assert/strict");
const { mkdtempSync, mkdirSync, writeFileSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const test = require("node:test");

function fixture() {
  const dir = mkdtempSync(join(tmpdir(), "ci-proof-"));
  // Create controlled test inputs.
  return dir;
}

test("malformed identity, mismatched checkout, missing lock, or incomplete toolchain fails closed", () => {
  const dir = fixture();
  try {
    assert.throws(() => buildProof(input(dir, { testedSha: "bad" })), /SHA/);
    // assert each incomplete evidence case explicitly
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
```

**Read-only test pattern** (`scripts/repository_inventory.test.cjs`, lines 27-45, 168-184; prohibition guard: `scripts/prohibitions/repository_inventory_report_only.test.cjs`, lines 89-112):

```javascript
function makeRepository(t) {
  const container = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-inventory-"));
  t.after(() => fs.rmSync(container, { recursive: true, force: true }));
  // initialize a throwaway repo with controlled records
  return root;
}

const before = manifest(root);
const output = invokeInventory(root, []);
assert.deepEqual(manifest(root), before, "read-only command changed repository bytes");
```

### `.planning/config.json` and existing repository ownership registry (preservation)

Keep `.planning/config.json`'s `workflow.use_worktrees: false` and the current ownership registry/state untouched in planning. If code extends `scripts/lib/repository_truth.cjs`, follow its record validation and evidence separation. Research saw an existing locked linked worktree; it does not authorize cleanup.

## Shared Patterns

### Evidence and unknown handling

**Sources:** `scripts/lib/repository_truth.cjs`, lines 384-449 and 452-539.  
**Apply to:** triage audit, worktree gate, and any structured record validation.

Missing evidence stays `unknown`; overlapping claims stay `ambiguous`; stale evidence remains stale. Return observed facts, dispositions, diagnostics, and conclusion separately. A read-only audit reports gaps and contradictions but never fills fields, changes labels, assigns, or closes items.

### Safe read-only CLI behavior

**Sources:** `scripts/repository_inventory.cjs`, lines 50-89; `scripts/lib/repository_truth.cjs`, lines 70-97.  
**Apply to:** triage audit and worktree gate.

Expose testable `main` functions, validate arguments, allow-list subprocess arguments, avoid shell interpolation, bound subprocess execution, and return clear exit codes for policy errors versus incomplete collection. Keep machine output deterministic and don't include credentials or raw secrets.

### Exact-SHA dependency proof

**Source:** `.github/workflows/ci.yml`, lines 349-359 and 392-405.  
**Apply to:** Dependabot update policy and PR evidence.

Use the existing aggregate `CI contract`; the exact candidate SHA and jobs actually run determine claims of success. Keep `mix hex.audit` as Hex advisory evidence. Dependabot proposes changes; maintainers review and merge.

### Voice and product boundary

**Source:** `README.md`, lines 3-8 and 28-44.  
**Apply to:** contributor-facing docs, issue forms, and PR template.

Use short sentences, state the actual boundary between core SDK and optional Phoenix/Ecto demo, and describe proof without implying external/provider behavior that was not checked.

## No Analog Found

| File/area | Role | Data Flow | Reason |
|-----------|------|-----------|--------|
| `SECURITY.md` private reporting section | policy | request-response | Private reporting is disabled and no verified alternative channel was found. |
| `.github/CODEOWNERS` | config/routing | request-response | No verified owner/path mapping is available; do not invent one. |
| GitHub issue forms and PR template | intake/template | request-response | No existing templates/forms; only generic voice/YAML conventions apply. |
| Issue/PR triage record | record/model | CRUD | No existing maintainer disposition record; preserve location and schema as planning choices. |
| GSD task/worktree manifest lifecycle | utility/lifecycle | file I/O | Repository inventory is a read-only snapshot, not evidence that the installed GSD host supports safe task lifecycle binding. |

## Metadata

**Analog search scope:** `README.md`, `.github/workflows/`, `scripts/`, `scripts/lib/`, `scripts/prohibitions/`, root planning configuration.  
**Tracked analogs verified:** `README.md`, `.github/workflows/ci.yml`, `scripts/repository_inventory.cjs`, `scripts/lib/repository_truth.cjs`, `scripts/repository_inventory.test.cjs`, `scripts/prohibitions/repository_inventory_report_only.test.cjs`, `scripts/ci_proof.test.cjs`. Each is tracked by Git (`git ls-files -- <path>` returned the path).  
**Files scanned:** 7 primary source/config/test analogs plus the phase research/context.  
**Pattern extraction date:** 2026-09-25
