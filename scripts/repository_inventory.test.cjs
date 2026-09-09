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
const {
  collectRepositorySnapshot,
  evaluateRepositoryInventory,
  exitCodeFor,
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
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-inventory-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  run("git", ["init", "-b", "main", root]);
  fs.writeFileSync(path.join(root, "tracked.txt"), "baseline\n");
  run("git", ["add", "tracked.txt"], { cwd: root });
  run("git", ["commit", "-m", "fixture"], { cwd: root });
  return root;
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
        ahead: 1,
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

test("tracer: collector observes the dirty main worktree", (t) => {
  const root = makeRepository(t);
  fs.writeFileSync(path.join(root, "untracked with space.txt"), "dirty\n");
  const snapshot = collectRepositorySnapshot({ cwd: root, now: () => new Date("2026-09-09T00:00:00.000Z") });

  assert.equal(snapshot.repository.root, root);
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
