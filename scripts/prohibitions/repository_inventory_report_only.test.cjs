"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");

const PROJECT_ROOT = path.resolve(__dirname, "../..");
const DEFAULT_SUBJECT = "scripts/repository_inventory.cjs";

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    encoding: options.encoding === undefined ? "utf8" : options.encoding,
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: "Inventory Prohibition",
      GIT_AUTHOR_EMAIL: "inventory-prohibition@example.test",
      GIT_COMMITTER_NAME: "Inventory Prohibition",
      GIT_COMMITTER_EMAIL: "inventory-prohibition@example.test",
      GIT_OPTIONAL_LOCKS: "0",
    },
    maxBuffer: 4 * 1024 * 1024,
  });
  if (options.allowFailure !== true && result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed (${result.status}): ${String(result.stderr)}`);
  }
  return result;
}

function resolveSubject() {
  const requested = process.env.GSD_PROHIB_SUBJECT || DEFAULT_SUBJECT;
  return require(path.isAbsolute(requested) ? requested : path.resolve(PROJECT_ROOT, requested));
}

function makeRepository(t) {
  const container = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-report-only-"));
  const root = path.join(container, "repository");
  t.after(() => fs.rmSync(container, { recursive: true, force: true }));
  run("git", ["init", "-b", "main", root]);
  fs.mkdirSync(path.join(root, ".planning"));
  fs.writeFileSync(path.join(root, "tracked.txt"), "tracked baseline\n");
  fs.writeFileSync(path.join(root, ".planning/repository-ownership.json"), JSON.stringify({ schema_version: 1, claims: [] }));
  run("git", ["add", "tracked.txt", ".planning/repository-ownership.json"], { cwd: root });
  run("git", ["commit", "-m", "fixture"], { cwd: root });
  fs.appendFileSync(path.join(root, "tracked.txt"), "preserved dirty byte\n");
  return root;
}

function hashFile(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function administrativeLocks(commonDir) {
  const locks = [];
  function walk(directory) {
    if (!fs.existsSync(directory)) return;
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const child = path.join(directory, entry.name);
      if (entry.isDirectory()) walk(child);
      else if (entry.isFile() && (entry.name === "locked" || entry.name.endsWith(".lock"))) {
        locks.push([path.relative(commonDir, child), hashFile(child)]);
      }
    }
  }
  walk(commonDir);
  return locks.sort((left, right) => left[0].localeCompare(right[0]));
}

function repositoryState(root) {
  const commonDirOutput = run("git", ["rev-parse", "--git-common-dir"], { cwd: root }).stdout.trim();
  const commonDir = path.resolve(root, commonDirOutput);
  const tracked = run("git", ["ls-files", "-z"], { cwd: root, encoding: null }).stdout
    .toString("utf8").split("\0").filter(Boolean)
    .map((file) => [file, fs.existsSync(path.join(root, file)) ? hashFile(path.join(root, file)) : null]);
  return {
    tracked,
    refs: run("git", ["for-each-ref", "--format=%(refname)%00%(objectname)%00"], { cwd: root, encoding: null }).stdout.toString("hex"),
    head: fs.readFileSync(path.join(commonDir, "HEAD"), "utf8"),
    index: hashFile(path.join(commonDir, "index")),
    worktrees: run("git", ["worktree", "list", "--porcelain", "-z"], { cwd: root, encoding: null }).stdout.toString("hex"),
    locks: administrativeLocks(commonDir),
  };
}

function invoke(subject, root, argv) {
  let stdout = "";
  let stderr = "";
  const status = subject.main(argv, {
    cwd: root,
    stdout: { write(value) { stdout += value; } },
    stderr: { write(value) { stderr += value; } },
  });
  assert.equal(Number.isInteger(status), true, `subject must return an integer exit code; stderr=${stderr}`);
  assert.equal(stdout.length > 0, true, "subject must render an inventory conclusion");
}

test("PROHIB-REPO-01-SAFETY: inventory subjects preserve repository and worktree state", (t) => {
  const subject = resolveSubject();
  assert.equal(typeof subject.main, "function", "subject must expose main(argv, options)");
  const root = makeRepository(t);
  const before = repositoryState(root);

  invoke(subject, root, []);
  assert.deepEqual(repositoryState(root), before, "human inventory mode changed repository state");

  invoke(subject, root, ["--json"]);
  assert.deepEqual(repositoryState(root), before, "JSON inventory mode changed repository state");
});
