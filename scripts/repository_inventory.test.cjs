"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");

const PROJECT_ROOT = path.resolve(__dirname, "..");
const CLI = path.join(__dirname, "repository_inventory.cjs");
const { main: inventoryMain } = require("./repository_inventory.cjs");
const {
  collectRepositorySnapshot,
  evaluateRepositoryInventory,
  exitCodeFor,
  parseStatus,
  parseWorktreeList,
  renderHuman,
  renderJson,
} = require("./lib/repository_truth.cjs");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    encoding: options.encoding === undefined ? "utf8" : options.encoding,
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: "Inventory Test",
      GIT_AUTHOR_EMAIL: "inventory@example.test",
      GIT_COMMITTER_NAME: "Inventory Test",
      GIT_COMMITTER_EMAIL: "inventory@example.test",
      ...options.env,
    },
    maxBuffer: 4 * 1024 * 1024,
  });

  if (options.allowFailure !== true && result.status !== 0) {
    throw new Error(
      `${command} ${args.join(" ")} failed (${result.status}): ${String(result.stderr)}`,
    );
  }

  return result;
}

function makeRepository(t) {
  const container = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-inventory-"));
  const root = path.join(container, "repository");
  t.after(() => fs.rmSync(container, { recursive: true, force: true }));
  run("git", ["init", "-b", "main", root]);
  fs.writeFileSync(path.join(root, "tracked.txt"), "baseline\n");
  fs.mkdirSync(path.join(root, ".planning"), { recursive: true });
  fs.writeFileSync(path.join(root, ".planning/repository-ownership.json"), JSON.stringify(registryFor([])));
  run("git", ["add", "tracked.txt", ".planning/repository-ownership.json"], { cwd: root });
  run("git", ["commit", "-m", "fixture"], { cwd: root });
  return root;
}

function invokeInventory(root, argv, options = {}) {
  let stdout = "";
  let stderr = "";
  const status = inventoryMain(argv, {
    cwd: root,
    stdout: { write(value) { stdout += value; } },
    stderr: { write(value) { stderr += value; } },
    ...options,
  });
  return { status, stdout, stderr };
}

function normalizeGeneratedAt(result) {
  return { ...result, generatedAt: "<generated>" };
}

function registryFor(paths) {
  return {
    schema_version: 1,
    claims: paths.map((dirtyPath) => ({
      selector: {
        kind: "dirty_path",
        worktree_role: "main",
        path: dirtyPath,
      },
      owner: "fixture-owner",
      provenance: "repository inventory integration fixture",
      confidence: "high",
      revisit_at: "2099-01-01",
      proposed_disposition: "preserve",
    })),
  };
}

function manifest(root) {
  const gitDir = run("git", ["rev-parse", "--git-dir"], { cwd: root }).stdout.trim();
  const absoluteGitDir = path.resolve(root, gitDir);
  const files = [];

  function walk(directory, relative = "") {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const childRelative = path.join(relative, entry.name);
      const child = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        walk(child, childRelative);
      } else if (entry.isFile()) {
        files.push([
          childRelative,
          crypto.createHash("sha256").update(fs.readFileSync(child)).digest("hex"),
        ]);
      }
    }
  }

  walk(root);
  return {
    head: run("git", ["rev-parse", "HEAD"], { cwd: root }).stdout.trim(),
    refs: run("git", ["show-ref"], { cwd: root }).stdout,
    index: crypto.createHash("sha256").update(fs.readFileSync(path.join(absoluteGitDir, "index"))).digest("hex"),
    files: files.sort((left, right) => left[0].localeCompare(right[0])),
  };
}

test("tracer: one evaluated inventory drives human and JSON truth", () => {
  const snapshot = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git" },
    worktrees: [
      {
        path: "/fixture",
        role: "main",
        head: "a".repeat(40),
        branch: "main",
        upstream: "origin/main",
        ahead: 0,
        behind: 0,
        detached: false,
        bare: false,
        lock: null,
        prunable: null,
        processEvidence: null,
        dirty: [{ kind: "modified", path: ".tool-versions", originalPath: null, index: ".", worktree: "M" }],
        collectionErrors: [],
      },
    ],
    collectionErrors: [],
  };
  const result = evaluateRepositoryInventory(snapshot, registryFor([".tool-versions"]));
  const json = JSON.parse(renderJson(result));
  const human = renderHuman(result);

  assert.deepEqual(json.facts, result.facts);
  assert.deepEqual(json.dispositions, result.dispositions);
  assert.deepEqual(json.diagnostics.map(({ code, severity }) => ({ code, severity })), result.diagnostics.map(({ code, severity }) => ({ code, severity })));
  assert.deepEqual(json.conclusion, result.conclusion);
  assert.match(human, new RegExp(`Conclusion: ${result.conclusion.status}`));
  for (const diagnostic of result.diagnostics) assert.match(human, new RegExp(diagnostic.code));
  assert.equal(exitCodeFor(result), 0);
  assert.equal(result.facts.worktrees[0].dirty[0].path, ".tool-versions");
  assert.equal(result.dispositions[0].owner, "fixture-owner");
});

test("same result: unknown and overlapping ownership fail closed", () => {
  const snapshot = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git" },
    worktrees: [{
      path: "/fixture", role: "main", head: "b".repeat(40), branch: "main",
      upstream: null, ahead: null, behind: null, detached: false, bare: false,
      lock: null, prunable: null, processEvidence: null,
      dirty: [{ kind: "untracked", path: "unknown.txt", originalPath: null, index: "?", worktree: "?" }],
      collectionErrors: [],
    }],
    collectionErrors: [],
  };

  const unknown = evaluateRepositoryInventory(snapshot, registryFor([]));
  assert.equal(exitCodeFor(unknown), 1);
  assert.ok(unknown.diagnostics.some(({ code }) => code === "RINV_UNKNOWN_STATE"));

  const claim = registryFor(["unknown.txt"]).claims[0];
  const ambiguous = evaluateRepositoryInventory(snapshot, { schema_version: 1, claims: [claim, { ...claim }] });
  assert.equal(exitCodeFor(ambiguous), 1);
  assert.ok(ambiguous.diagnostics.some(({ code }) => code === "RINV_AMBIGUOUS_CLAIM"));
});

test("ownership registry: invalid claims cannot classify observations", () => {
  const snapshot = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git" },
    worktrees: [{
      path: "/fixture", role: "main", head: "b".repeat(40), branch: "main",
      upstream: null, ahead: null, behind: null, detached: false, bare: false,
      lock: null, prunable: null, processEvidence: null,
      dirty: [{ kind: "untracked", path: "unknown.txt", originalPath: null, index: "?", worktree: "?" }],
      collectionErrors: [],
    }],
    collectionErrors: [],
  };
  const malformed = registryFor(["unknown.txt"]);
  malformed.claims[0].owner = { name: "not a string" };
  malformed.claims[0].proposed_disposition = { action: "preserve" };
  const result = evaluateRepositoryInventory(snapshot, malformed);
  assert.ok(result.diagnostics.some(({ code }) => code === "RINV_CLAIM_INVALID"));
  assert.ok(result.diagnostics.some(({ code }) => code === "RINV_UNKNOWN_STATE"));
  assert.equal(result.dispositions[0].state, "unknown");
});

test("read-only: both CLI formats preserve repository bytes", (t) => {
  const root = makeRepository(t);
  fs.appendFileSync(path.join(root, "tracked.txt"), "dirty\n");
  const before = manifest(root);

  const human = run(process.execPath, [CLI], { cwd: root, allowFailure: true });
  const between = manifest(root);
  const json = run(process.execPath, [CLI, "--json"], { cwd: root, allowFailure: true });
  const after = manifest(root);

  assert.equal(human.status, 1);
  assert.equal(json.status, 1);
  assert.deepEqual(between, before);
  assert.deepEqual(after, before);
  assert.equal(JSON.parse(json.stdout).conclusion.exitCode, 1);
});

test("ownership registry: symlinked external JSON exits 2 without disclosure", (t) => {
  for (const intermediate of [false, true]) {
    const root = makeRepository(t);
    const external = path.join(path.dirname(root), intermediate ? "external-policy" : "external-registry.json");
    const registryPath = intermediate
      ? path.join(root, ".planning/policy/repository-ownership.json")
      : path.join(root, ".planning/repository-ownership.json");
    const sentinel = intermediate ? "INTERMEDIATE-REGISTRY-SECRET" : "DIRECT-REGISTRY-SECRET";
    const externalRegistry = registryFor([".planning/repository-ownership.json"]);
    externalRegistry.claims[0].owner = sentinel;

    if (intermediate) {
      fs.mkdirSync(external, { recursive: true });
      fs.writeFileSync(path.join(external, "repository-ownership.json"), JSON.stringify(externalRegistry));
      fs.symlinkSync(external, path.join(root, ".planning/policy"), "dir");
    } else {
      fs.rmSync(registryPath);
      fs.writeFileSync(external, JSON.stringify(externalRegistry));
      fs.symlinkSync(external, registryPath);
    }

    const before = fs.readFileSync(intermediate ? path.join(external, "repository-ownership.json") : external, "utf8");
    for (const argv of [[], ["--json"]]) {
      const invocation = invokeInventory(root, argv, { registryPath });
      assert.equal(invocation.status, 2);
      assert.match(invocation.stdout, /RINV_REGISTRY_UNREADABLE/);
      assert.doesNotMatch(invocation.stdout, new RegExp(sentinel));
      assert.doesNotMatch(invocation.stderr, new RegExp(sentinel));
      if (argv.includes("--json")) {
        const result = JSON.parse(invocation.stdout);
        assert.equal(result.conclusion.status, "incomplete");
        assert.equal(result.dispositions.every(({ owner }) => owner === "unknown"), true);
      }
    }
    assert.equal(fs.readFileSync(intermediate ? path.join(external, "repository-ownership.json") : external, "utf8"), before);
  }
});

test("ownership registry: non-regular, oversized, and replaced sources fail incomplete", (t) => {
  const root = makeRepository(t);
  const directory = path.join(root, ".planning/registry-directory");
  fs.mkdirSync(directory);
  const nonRegular = invokeInventory(root, ["--json"], { registryPath: directory });
  assert.equal(nonRegular.status, 2);
  assert.match(nonRegular.stdout, /RINV_REGISTRY_UNREADABLE/);

  const registryPath = path.join(root, ".planning/repository-ownership.json");
  const oversized = invokeInventory(root, ["--json"], { registryPath, maximumRegistryBytes: 8 });
  assert.equal(oversized.status, 2);
  assert.match(oversized.stdout, /RINV_REGISTRY_UNREADABLE/);

  const replacement = path.join(root, ".planning/replacement.json");
  fs.writeFileSync(replacement, JSON.stringify({ ...registryFor([]), secret: "REPLACEMENT-SECRET" }));
  const replaced = invokeInventory(root, ["--json"], {
    registryPath,
    registryReadOptions: {
      afterOpen() {
        fs.renameSync(replacement, registryPath);
      },
    },
  });
  assert.equal(replaced.status, 2);
  assert.match(replaced.stdout, /RINV_REGISTRY_UNREADABLE/);
  assert.doesNotMatch(replaced.stdout, /REPLACEMENT-SECRET/);
});

test("tracer: collector observes the dirty main worktree", (t) => {
  const root = makeRepository(t);
  fs.writeFileSync(path.join(root, "untracked with space.txt"), "dirty\n");
  const snapshot = collectRepositorySnapshot({ cwd: root, now: () => new Date("2026-09-09T00:00:00.000Z") });

  assert.equal(snapshot.repository.root, fs.realpathSync(root));
  assert.equal(snapshot.worktrees.length, 1);
  assert.equal(snapshot.worktrees[0].role, "main");
  assert.ok(snapshot.worktrees[0].dirty.some(({ path: dirtyPath }) => dirtyPath === "untracked with space.txt"));
});

test("tracer: CLI help documents report-only behavior and exit meanings", () => {
  const help = run(process.execPath, [CLI, "--help"], { cwd: PROJECT_ROOT });
  assert.match(help.stdout, /read-only/i);
  assert.match(help.stdout, /0.*healthy/s);
  assert.match(help.stdout, /1.*policy/s);
  assert.match(help.stdout, /2.*incomplete/s);
});

test("all worktrees: collector preserves spaces, newlines, detached state, locks, and process evidence", (t) => {
  const root = makeRepository(t);
  const container = path.dirname(root);
  const livePath = path.join(container, "linked space");
  const deadPath = path.join(container, "linked\ndead");
  const unknownPath = path.join(container, "linked\tunknown");

  run("git", ["worktree", "add", "-b", "live-lock", livePath], { cwd: root });
  run("git", ["worktree", "add", "-b", "dead-lock", deadPath], { cwd: root });
  run("git", ["worktree", "add", "-b", "unknown-lock", unknownPath], { cwd: root });
  run("git", ["-C", deadPath, "checkout", "--detach"], { cwd: root });
  run("git", ["worktree", "lock", "--reason", `fixture owner (pid ${process.pid})`, livePath], { cwd: root });
  run("git", ["worktree", "lock", "--reason", "fixture owner (pid 99999999)", deadPath], { cwd: root });
  run("git", ["worktree", "lock", "--reason", "fixture owner without process id", unknownPath], { cwd: root });
  fs.writeFileSync(path.join(livePath, "dirty with space.txt"), "dirty\n");

  const before = manifest(root);
  const snapshot = collectRepositorySnapshot({ cwd: root, now: () => new Date("2026-09-09T00:00:00.000Z") });
  const after = manifest(root);

  assert.deepEqual(after, before);
  assert.ok(Array.isArray(snapshot.repository.pruneDryRun));
  assert.equal(snapshot.worktrees.length, 4);
  assert.equal(new Set(snapshot.worktrees.map(({ path: worktreePath }) => worktreePath)).size, 4);
  assert.ok(snapshot.worktrees.some(({ path: worktreePath }) => worktreePath === fs.realpathSync(livePath)));
  assert.ok(snapshot.worktrees.some(({ path: worktreePath }) => worktreePath.includes("\n")));
  assert.ok(snapshot.worktrees.some(({ path: worktreePath }) => worktreePath.includes("\t")));
  assert.equal(snapshot.worktrees.find(({ path: worktreePath }) => worktreePath === fs.realpathSync(deadPath)).detached, true);
  assert.equal(snapshot.worktrees.find(({ path: worktreePath }) => worktreePath === fs.realpathSync(livePath)).processEvidence.state, "live");
  assert.equal(snapshot.worktrees.find(({ path: worktreePath }) => worktreePath === fs.realpathSync(deadPath)).processEvidence.state, "dead");
  assert.equal(snapshot.worktrees.find(({ path: worktreePath }) => worktreePath === fs.realpathSync(unknownPath)).processEvidence.state, "unparseable");
});

test("hostile paths: porcelain parsers preserve rename pairs and control characters", () => {
  const original = "old\tname\n.txt";
  const renamed = "new name.txt";
  const status = Buffer.from(
    `# branch.oid ${"c".repeat(40)}\0# branch.head main\0# branch.upstream origin/main\0# branch.ab +2 -3\0`
      + `2 R. N... 100644 100644 100644 ${"d".repeat(40)} ${"e".repeat(40)} R100 ${renamed}\0${original}\0`
      + `? untracked\tline\n.txt\0`,
  );
  const parsed = parseStatus(status);
  assert.equal(parsed.ahead, 2);
  assert.equal(parsed.behind, 3);
  assert.deepEqual(parsed.dirty.find(({ kind }) => kind === "rename"), {
    kind: "rename", path: renamed, originalPath: original, index: "R", worktree: ".",
  });
  assert.ok(parsed.dirty.some(({ path: dirtyPath }) => dirtyPath === "untracked\tline\n.txt"));

  const records = parseWorktreeList(Buffer.from(`worktree /tmp/main\0HEAD ${"a".repeat(40)}\0branch refs/heads/main\0\0worktree /tmp/linked\nname\0HEAD ${"b".repeat(40)}\0detached\0locked reason\twith controls\0prunable missing gitdir\0\0`));
  assert.equal(records.length, 2);
  assert.equal(records[1].path, "/tmp/linked\nname");
  assert.equal(records[1].lock, "reason\twith controls");
  assert.equal(records[1].prunable, "missing gitdir");
});

test("hostile paths: ordinary modified records retain only the exact path", () => {
  const modifiedPath = "tracked file\twith newline\n.txt";
  const status = parseStatus(Buffer.from(
    `# branch.oid ${"2".repeat(40)}\0# branch.head main\0`
      + `1 .M N... 100644 100644 100644 ${"3".repeat(40)} ${"4".repeat(40)} ${modifiedPath}\0`,
  ));
  assert.deepEqual(status.dirty, [{
    kind: "ordinary", path: modifiedPath, originalPath: null, index: ".", worktree: "M",
  }]);
});

test("hostile paths: malformed dirty porcelain fails closed", () => {
  assert.throws(() => parseStatus(Buffer.from("1 malformed\0")), /malformed porcelain-v2 ordinary record/);
  assert.throws(() => parseStatus(Buffer.from("2 R. incomplete\0")), /malformed porcelain-v2 rename record/);
  assert.throws(() => parseStatus(Buffer.from(`# branch.oid ${"a".repeat(40)}\0# branch.head main\0future record\0`)), /unsupported porcelain-v2 record/);
  assert.throws(() => parseStatus(Buffer.from(`# branch.oid ${"a".repeat(40)}\0`)), /branch headers are incomplete/);
});

test("edge policy: empty state is valid while null observations and bounded output fail incomplete", (t) => {
  const empty = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git", pruneDryRun: [] },
    worktrees: [{
      path: "/fixture", role: "main", head: "f".repeat(40), branch: "main",
      upstream: null, ahead: null, behind: null, detached: false, bare: false,
      lock: null, prunable: null, processEvidence: null, dirty: [], collectionErrors: [],
    }],
    collectionErrors: [],
  };
  assert.equal(exitCodeFor(evaluateRepositoryInventory(empty, { schema_version: 1, claims: [] })), 0);

  const incomplete = structuredClone(empty);
  incomplete.worktrees[0].head = null;
  assert.equal(exitCodeFor(evaluateRepositoryInventory(incomplete, { schema_version: 1, claims: [] })), 2);

  const root = makeRepository(t);
  const bounded = collectRepositorySnapshot({ cwd: root, maxBuffer: 1 });
  assert.equal(exitCodeFor(evaluateRepositoryInventory(bounded, { schema_version: 1, claims: [] })), 2);
  assert.ok(bounded.collectionErrors.length > 0);
});

test("edge policy: unclassified divergence, lock, and prunable observations remain visible and blocking", () => {
  const snapshot = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git", pruneDryRun: ["would prune"] },
    worktrees: [{
      path: "/fixture", role: "main", head: "5".repeat(40), branch: "main",
      upstream: "origin/main", ahead: 2, behind: 1, detached: false, bare: false,
      lock: "owner (pid 99999999)", prunable: "gitdir missing",
      processEvidence: { pid: 99999999, state: "dead", evidence: "ps exited 1" },
      dirty: [], collectionErrors: [],
    }],
    collectionErrors: [],
  };
  const result = evaluateRepositoryInventory(snapshot, { schema_version: 1, claims: [] });
  assert.equal(exitCodeFor(result), 1);
  assert.ok(result.diagnostics.some(({ code }) => code === "RINV_BRANCH_DIVERGED"));
  assert.ok(result.diagnostics.some(({ code }) => code === "RINV_UNKNOWN_LOCK"));
  assert.ok(result.diagnostics.some(({ code }) => code === "RINV_PRUNABLE_WORKTREE"));
  assert.ok(result.dispositions.every(({ proposed_disposition }) => proposed_disposition === null));
});

test("edge policy: an exact current lock claim records evidence without overwriting the lock fact", () => {
  const snapshot = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture", commonDir: "/fixture/.git", pruneDryRun: [] },
    worktrees: [{
      path: "/fixture", role: "main", head: "6".repeat(40), branch: "main",
      upstream: null, ahead: null, behind: null, detached: false, bare: false,
      lock: "fixture owner", prunable: null,
      processEvidence: { pid: null, state: "unparseable", evidence: "fixture owner" },
      dirty: [], collectionErrors: [],
    }],
    collectionErrors: [],
  };
  const registry = {
    schema_version: 1,
    claims: [{
      selector: { kind: "worktree_lock", worktree_path: "/fixture" },
      owner: "fixture-owner", provenance: "reviewed fixture lock", confidence: "high",
      revisit_at: "2099-01-01", proposed_disposition: "preserve",
    }],
  };
  const result = evaluateRepositoryInventory(snapshot, registry);
  assert.equal(exitCodeFor(result), 0);
  assert.equal(result.facts.worktrees[0].lock, "fixture owner");
  assert.equal(result.dispositions[0].owner, "fixture-owner");
});

test("deterministic: repeated collection and both renderers retain ordered conclusions", (t) => {
  const root = makeRepository(t);
  fs.writeFileSync(path.join(root, "zeta.txt"), "z\n");
  fs.writeFileSync(path.join(root, "alpha.txt"), "a\n");
  const registry = registryFor(["zeta.txt", "alpha.txt"]);
  const fixedClock = () => new Date("2026-09-09T00:00:00.000Z");

  const first = evaluateRepositoryInventory(collectRepositorySnapshot({ cwd: root, now: fixedClock }), registry);
  const second = evaluateRepositoryInventory(collectRepositorySnapshot({ cwd: root, now: fixedClock }), registry);
  assert.deepEqual(normalizeGeneratedAt(first), normalizeGeneratedAt(second));
  assert.equal(renderJson(first), renderJson(second));
  assert.equal(renderHuman(first), renderHuman(second));
  assert.deepEqual(first.conclusion.diagnosticCodes, JSON.parse(renderJson(first)).conclusion.diagnosticCodes);
  assert.deepEqual(first.dispositions.map(({ artifact }) => artifact), [...first.dispositions.map(({ artifact }) => artifact)].sort());
});

test("unsafe renderer input is visibly escaped without changing JSON facts", () => {
  const snapshot = {
    schemaVersion: 1,
    generatedAt: "2026-09-09T00:00:00.000Z",
    repository: { root: "/fixture\u001b[31m", commonDir: "/fixture/.git", pruneDryRun: [] },
    worktrees: [{
      path: "/fixture\u001b[31m", role: "main", head: "1".repeat(40), branch: "main\nspoof",
      upstream: null, ahead: null, behind: null, detached: false, bare: false,
      lock: null, prunable: null, processEvidence: null, dirty: [], collectionErrors: [],
    }],
    collectionErrors: [],
  };
  const result = evaluateRepositoryInventory(snapshot, { schema_version: 1, claims: [] });
  assert.doesNotMatch(renderHuman(result), /\u001b/);
  assert.match(renderHuman(result), /\\u001b/);
  assert.equal(JSON.parse(renderJson(result)).facts.repository.root, "/fixture\u001b[31m");
});
