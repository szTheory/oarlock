"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");

const { main } = require("./worktree_lifecycle.cjs");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: "Worktree Lifecycle Test",
      GIT_AUTHOR_EMAIL: "worktree@example.test",
      GIT_COMMITTER_NAME: "Worktree Lifecycle Test",
      GIT_COMMITTER_EMAIL: "worktree@example.test",
      ...options.env,
    },
    maxBuffer: 1024 * 1024,
  });
  if (options.allowFailure !== true && result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed (${result.status}): ${result.stderr}`);
  }
  return result;
}

function fixture(t, linkedName = "task tree with space") {
  const container = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-worktree-lifecycle-"));
  const root = path.join(container, "repository");
  const linked = path.join(container, linkedName);
  t.after(() => fs.rmSync(container, { recursive: true, force: true }));
  run("git", ["init", "-b", "main", root]);
  fs.writeFileSync(path.join(root, "tracked.txt"), "baseline\n");
  run("git", ["add", "tracked.txt"], { cwd: root });
  run("git", ["commit", "-m", "fixture baseline"], { cwd: root });
  const base = run("git", ["rev-parse", "HEAD"], { cwd: root }).stdout.trim();
  run("git", ["worktree", "add", "-b", "task/example", linked, base], { cwd: root });
  return { container, root, linked, base };
}

function invoke(argv, options = {}) {
  let stdout = "";
  let stderr = "";
  const status = main(argv, {
    cwd: options.cwd,
    stdout: { write(value) { stdout += value; } },
    stderr: { write(value) { stderr += value; } },
    ...options,
  });
  return { status, stdout, stderr };
}

function manifestFor({ linked, base }, overrides = {}) {
  return {
    schema_version: 1,
    task_id: "task-123",
    owner: "maintainer@example.test",
    worktree_path: linked,
    branch: "refs/heads/task/example",
    base_sha: base,
    ...overrides,
  };
}

function writeJson(file, value) {
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
  return file;
}

function capture(root, argv, options = {}) {
  return invoke(argv, { cwd: root, ...options });
}

test("tracer: a dedicated clean worktree enters and exits with manifest-bound evidence", (t) => {
  const state = fixture(t);
  const manifestPath = writeJson(path.join(state.container, "manifest.json"), manifestFor(state));
  const entry = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"]);
  assert.equal(entry.status, 0, entry.stderr || entry.stdout);
  const entryResult = JSON.parse(entry.stdout);
  assert.equal(entryResult.status, "clean");
  assert.equal(entryResult.facts.task_id, "task-123");
  assert.equal(entryResult.facts.owner, "maintainer@example.test");
  assert.equal(entryResult.facts.worktree_path, fs.realpathSync(state.linked));
  assert.equal(entryResult.facts.branch, "refs/heads/task/example");
  assert.equal(entryResult.facts.base_sha, state.base);
  assert.equal(entryResult.facts.head_sha, state.base);
  assert.deepEqual(entryResult.facts.dirty, []);

  fs.writeFileSync(path.join(state.linked, "tracked.txt"), "task change\n");
  run("git", ["add", "tracked.txt"], { cwd: state.linked });
  run("git", ["commit", "-m", "task change"], { cwd: state.linked });
  const head = run("git", ["rev-parse", "HEAD"], { cwd: state.linked }).stdout.trim();
  const receiptPath = writeJson(path.join(state.container, "entry.json"), entryResult);
  const validationPath = writeJson(path.join(state.container, "validation.json"), {
    schema_version: 1,
    validations: [{ command: "npm test -- --run", result: "pass", sha: head }],
  });
  const exit = capture(state.root, [
    "exit", "--manifest", manifestPath, "--owner", "maintainer@example.test",
    "--entry-receipt", receiptPath, "--validation", validationPath,
    "--disposition", "merge-review", "--json",
  ]);
  assert.equal(exit.status, 0, exit.stderr || exit.stdout);
  const exitResult = JSON.parse(exit.stdout);
  assert.equal(exitResult.status, "clean");
  assert.equal(exitResult.facts.head_sha, head);
  assert.equal(exitResult.facts.base_sha, state.base);
  assert.equal(exitResult.facts.validation[0].sha, head);
  assert.equal(exitResult.proposed_disposition, "merge-review");
  assert.match(exitResult.facts.diff.summary, /tracked\.txt/);
  assert.equal(exitResult.facts.cleanup_authorized, false);
});

test("paths with spaces and newlines remain exact identities", (t) => {
  const state = fixture(t, "task tree\nwith newline");
  const manifestPath = writeJson(path.join(state.container, "manifest.json"), manifestFor(state));
  const entry = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"]);
  assert.equal(entry.status, 0, entry.stderr || entry.stdout);
  assert.equal(JSON.parse(entry.stdout).facts.worktree_path, fs.realpathSync(state.linked));
});

test("Git observations ignore inherited repository, index, and object redirection variables", (t) => {
  const state = fixture(t);
  const manifestPath = writeJson(path.join(state.container, "manifest.json"), manifestFor(state));
  const other = path.join(state.container, "other-repository");
  run("git", ["init", other]);
  const redirected = {
    GIT_DIR: path.join(other, ".git"),
    GIT_WORK_TREE: other,
    GIT_COMMON_DIR: path.join(other, ".git"),
    GIT_INDEX_FILE: path.join(state.container, "wrong.index"),
    GIT_OBJECT_DIRECTORY: path.join(state.container, "wrong-objects"),
    GIT_ALTERNATE_OBJECT_DIRECTORIES: path.join(state.container, "wrong-alternates"),
    GIT_CEILING_DIRECTORIES: state.container,
    GIT_PREFIX: "redirected/",
  };
  const calls = [];
  const runner = (command, args, options) => {
    calls.push({ command, args, cwd: options.cwd, env: options.env });
    return spawnSync(command, args, options);
  };

  const result = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"], {
    runner,
    env: redirected,
  });

  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.equal(JSON.parse(result.stdout).status, "clean");
  assert.ok(calls.length > 0);
  for (const call of calls) {
    assert.equal(call.command, "git");
    assert.ok(call.cwd === fs.realpathSync(state.linked) || call.args[0] === "-C" && call.args[1] === fs.realpathSync(state.linked), "Git command must be anchored to the observed worktree");
    for (const name of Object.keys(redirected)) assert.equal(Object.hasOwn(call.env, name), false, `${name} must not reach Git`);
  }
});

test("operator guide preserves host, authorization, and exact-SHA boundaries", () => {
  const guide = fs.readFileSync(path.join(__dirname, "../docs/worktree-operations.md"), "utf8");
  for (const text of [
    "workflow.use_worktrees` set to `false`",
    "does not create or clean worktrees",
    "automatic `git worktree remove`, unlock, reset, or prune",
    "separate, explicit decision by the worktree owner",
    "Before changing GSD's worktree-per-task preference",
    "proves only the exact SHA",
    "On 2026-09-26",
    "locked linked tree",
  ]) assert.ok(guide.includes(text), `operator guide should include: ${text}`);
});

test("invalid and ambiguous identity evidence fails closed", (t) => {
  const state = fixture(t);
  const manifestPath = path.join(state.container, "manifest.json");
  const cases = [
    ["owner mismatch", manifestFor(state), "someone-else@example.test", /owner/],
    ["wrong branch", manifestFor(state, { branch: "refs/heads/other" }), "maintainer@example.test", /branch/],
    ["stale base SHA", manifestFor(state, { base_sha: "f".repeat(40) }), "maintainer@example.test", /base SHA/],
    ["primary shared checkout", manifestFor(state, { worktree_path: state.root }), "maintainer@example.test", /primary shared/],
    ["missing worktree", manifestFor(state, { worktree_path: path.join(state.container, "missing") }), "maintainer@example.test", /missing or unreadable/],
  ];
  for (const [name, manifest, owner, expected] of cases) {
    writeJson(manifestPath, manifest);
    const result = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", owner, "--json"]);
    assert.notEqual(result.status, 0, name);
    assert.match(JSON.parse(result.stderr).diagnostics[0].message, expected, name);
  }
});

test("locked, prunable, duplicate, and unreadable Git observations block entry", (t) => {
  const state = fixture(t);
  const manifestPath = writeJson(path.join(state.container, "manifest.json"), manifestFor(state));
  const baseRunner = (command, args, options) => spawnSync(command, args, options);
  const assertBlocked = (name, runner, expected) => {
    const result = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"], { runner });
    assert.notEqual(result.status, 0, name);
    assert.match(JSON.parse(result.stderr).diagnostics[0].message, expected, name);
  };

  run("git", ["worktree", "lock", "--reason", "fixture lock", state.linked], { cwd: state.root });
  assertBlocked("locked tree", baseRunner, /locked/);
  run("git", ["worktree", "unlock", state.linked], { cwd: state.root });

  const injectRecord = (marker) => (command, args, options) => {
    const result = baseRunner(command, args, options);
    if (args[0] === "worktree" && args[1] === "list") {
      const raw = Buffer.from(result.stdout);
      const last = raw.lastIndexOf(Buffer.from("\0\0"));
      const altered = Buffer.concat([raw.subarray(0, last), Buffer.from(`\0${marker}\0\0`), raw.subarray(last + 2)]);
      return { ...result, stdout: altered };
    }
    return result;
  };
  assertBlocked("prunable tree", injectRecord("prunable stale metadata"), /prunable/);
  assertBlocked("duplicate tree identity", (command, args, options) => {
    const result = baseRunner(command, args, options);
    if (args[0] === "worktree" && args[1] === "list") return { ...result, stdout: Buffer.concat([result.stdout, result.stdout]) };
    return result;
  }, /duplicate Git worktree/);
  assertBlocked("unreadable Git process", (command, args, options) => {
    if (args[0] === "worktree" && args[1] === "list") return { error: Object.assign(new Error("sandbox process denied"), { code: "EPERM" }) };
    return baseRunner(command, args, options);
  }, /EPERM/);
});

test("dirty worktree and incomplete exit evidence never produce a clean receipt", (t) => {
  const state = fixture(t);
  const manifestPath = writeJson(path.join(state.container, "manifest.json"), manifestFor(state));
  const entry = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"]);
  assert.equal(entry.status, 0, entry.stderr || entry.stdout);
  const entryPath = writeJson(path.join(state.container, "entry.json"), JSON.parse(entry.stdout));
  fs.writeFileSync(path.join(state.linked, "untracked.txt"), "uncommitted\n");
  const dirty = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"]);
  assert.notEqual(dirty.status, 0);
  assert.match(JSON.parse(dirty.stderr).diagnostics[0].message, /dirty/);
  fs.rmSync(path.join(state.linked, "untracked.txt"));

  fs.writeFileSync(path.join(state.linked, "tracked.txt"), "task change\n");
  run("git", ["add", "tracked.txt"], { cwd: state.linked });
  run("git", ["commit", "-m", "task change"], { cwd: state.linked });
  const head = run("git", ["rev-parse", "HEAD"], { cwd: state.linked }).stdout.trim();
  const validationPath = path.join(state.container, "validation.json");
  const baseArgs = ["exit", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--entry-receipt", entryPath, "--validation", validationPath, "--disposition", "retain", "--json"];
  for (const evidence of [
    { schema_version: 1, validations: [] },
    { schema_version: 1, validations: [{ command: "mix test", result: "unknown", sha: head }] },
    { schema_version: 1, validations: [{ command: "mix test", result: "pass", sha: "a".repeat(40) }] },
  ]) {
    writeJson(validationPath, evidence);
    const result = capture(state.root, baseArgs);
    assert.notEqual(result.status, 0);
    assert.equal(JSON.parse(result.stderr).status, "blocked");
  }
  writeJson(validationPath, { schema_version: 1, validations: [{ command: "mix test", result: "pass", sha: head }] });
  const malformedEntryPath = writeJson(path.join(state.container, "malformed-entry.json"), { schema_version: 1, kind: "worktree-entry", status: "clean", facts: {} });
  const malformed = capture(state.root, [...baseArgs.slice(0, 6), malformedEntryPath, ...baseArgs.slice(7)]);
  assert.notEqual(malformed.status, 0);
  assert.match(JSON.parse(malformed.stderr).diagnostics[0].message, /entry receipt/);
});

test("lifecycle runner never calls a destructive worktree command or writes task evidence", (t) => {
  const state = fixture(t);
  const manifestPath = writeJson(path.join(state.container, "manifest.json"), manifestFor(state));
  const calls = [];
  const runner = (command, args, options) => {
    calls.push({ command, args });
    return spawnSync(command, args, options);
  };
  const result = capture(state.root, ["entry", "--manifest", manifestPath, "--owner", "maintainer@example.test", "--json"], { runner });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const entryPath = writeJson(path.join(state.container, "entry.json"), JSON.parse(result.stdout));
  fs.writeFileSync(path.join(state.linked, "tracked.txt"), "committed task result\n");
  run("git", ["add", "tracked.txt"], { cwd: state.linked });
  run("git", ["commit", "-m", "task result"], { cwd: state.linked });
  const head = run("git", ["rev-parse", "HEAD"], { cwd: state.linked }).stdout.trim();
  const validationPath = writeJson(path.join(state.container, "validation.json"), {
    schema_version: 1,
    validations: [{ command: "node --test", result: "pass", sha: head }],
  });
  const beforeRoot = run("git", ["status", "--porcelain=v2", "--branch", "-z"], { cwd: state.root, encoding: null }).stdout;
  const beforeLinked = run("git", ["-C", state.linked, "status", "--porcelain=v2", "--branch", "-z"], { cwd: state.root, encoding: null }).stdout;
  calls.length = 0;
  const exit = capture(state.root, [
    "exit", "--manifest", manifestPath, "--owner", "maintainer@example.test",
    "--entry-receipt", entryPath, "--validation", validationPath,
    "--disposition", "remove-review", "--json",
  ], { runner });
  assert.equal(exit.status, 0, exit.stderr || exit.stdout);
  assert.equal(JSON.parse(exit.stdout).facts.cleanup_authorized, false);
  assert.ok(calls.length > 0);
  assert.ok(calls.every(({ command }) => command === "git"));
  assert.ok(calls.every(({ args }) => !["remove", "unlock", "reset", "prune", "restore", "stash", "force"].some((word) => args.includes(word))));
  assert.deepEqual(run("git", ["status", "--porcelain=v2", "--branch", "-z"], { cwd: state.root, encoding: null }).stdout, beforeRoot);
  assert.deepEqual(run("git", ["-C", state.linked, "status", "--porcelain=v2", "--branch", "-z"], { cwd: state.root, encoding: null }).stdout, beforeLinked);
  assert.deepEqual(fs.readdirSync(state.container).sort(), ["entry.json", "manifest.json", "repository", "task tree with space", "validation.json"].sort());
});
