"use strict";

// Explicit capture/restore harness shared by synthetic tests and the local
// operator. Never invoked by closeout_check, CI, or a cleanup command.
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
const { indexObjects } = require("../closeout_check.cjs");
const { parseWorktreeList } = require("../lib/repository_truth.cjs");
const digest = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
function git(root, args, input) {
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith("GIT_")));
  const safeArgs = args[0] === "diff" ? ["-c", "diff.autoRefreshIndex=false", ...args] : args;
  const r = spawnSync("git", safeArgs, { cwd: root, input, env: { ...env, GIT_OPTIONAL_LOCKS: "0", GIT_AUTHOR_NAME: "Closeout Fixture", GIT_AUTHOR_EMAIL: "fixture@example.test", GIT_COMMITTER_NAME: "Closeout Fixture", GIT_COMMITTER_EMAIL: "fixture@example.test" }, maxBuffer: 64 * 1024 * 1024, timeout: 60000 });
  if (r.error || r.status !== 0) throw new Error(`capture Git operation failed: ${args[0]}`);
  return r.stdout;
}
function put(vault, bytes) {
  const sha = digest(bytes), file = path.join(vault, "blobs", sha);
  if (!fs.existsSync(file)) fs.writeFileSync(file, bytes, { mode: 0o600, flag: "wx" });
  return sha;
}
function capture(root, vault, receiptId, observe) {
  if (!/^[a-z0-9-]+$/.test(receiptId)) throw new Error("invalid receipt ID");
  const resolvedRoot = fs.realpathSync(root);
  const trees = parseWorktreeList(git(root, ["worktree", "list", "--porcelain", "-z"]));
  const destination = path.resolve(vault);
  if (trees.some(t => destination === t.path || destination.startsWith(`${t.path}${path.sep}`))) throw new Error("vault must be external");
  fs.mkdirSync(vault, { mode: 0o700, recursive: true });
  if (fs.lstatSync(vault).isSymbolicLink() || (fs.statSync(vault).mode & 0o077)) throw new Error("vault must be private");
  for (const dir of ["blobs", "receipts", "bundles", "restored"]) {
    const location = path.join(vault, dir);
    fs.mkdirSync(location, { mode: 0o700, recursive: true });
    if (fs.realpathSync(location) !== location || (fs.statSync(location).mode & 0o077)) throw new Error("unsafe vault directory");
  }
  const before = observe(root);
  const bundle = `bundles/${receiptId}.bundle`;
  git(root, ["bundle", "create", path.join(vault, bundle), "--all", ...trees.map(t => t.head)]);
  const snapshot = { schema_version: 1, receipt_id: receiptId, source_root: resolvedRoot, observed: before, bundle, bundle_sha256: digest(fs.readFileSync(path.join(vault, bundle))), restored: [] };
  for (let i = 0; i < before.trees.length; i++) {
    const tree = before.trees[i];
    for (const bytes of indexObjects(tree.path, tree.index_entries).values()) put(vault, bytes);
    put(vault, fs.readFileSync(git(tree.path, ["rev-parse", "--path-format=absolute", "--git-path", "index"]).toString().trim()));
    put(vault, git(tree.path, ["diff", "--binary", "--no-ext-diff"]));
    put(vault, git(tree.path, ["diff", "--cached", "--binary", "--no-ext-diff"]));
    for (const entry of tree.files) {
      if (entry.type === "missing") continue;
      const file = path.join(tree.path, entry.path);
      put(vault, entry.type === "symlink" ? Buffer.from(fs.readlinkSync(file)) : fs.readFileSync(file));
    }
    const restored = `restored/${receiptId}-${i}`;
    const target = path.join(vault, restored);
    git(vault, ["clone", "--no-checkout", path.join(vault, bundle), target]);
    git(target, ["checkout", "--detach", tree.head]);
    const objectIds = [...new Set(tree.index_entries.map(entry => entry.oid))];
    const existing = git(target, ["cat-file", "--batch-check"], `${objectIds.join("\n")}\n`).toString().trim().split("\n");
    const missing = new Set(existing.filter(line => line.endsWith(" missing")).map(line => line.split(" ")[0]));
    for (const entry of tree.index_entries.filter(entry => missing.has(entry.oid))) {
      const oid = git(target, ["hash-object", "-w", "--no-filters", path.join(vault, "blobs", entry.sha256)]).toString().trim();
      if (oid !== entry.oid) throw new Error("restored object mismatch");
    }
    // Retain the exact index including selection, flags and conflict stages.
    fs.copyFileSync(path.join(vault, "blobs", tree.index_sha256), path.join(target, ".git/index"));
    const headPaths = git(target, ["ls-tree", "-r", "--name-only", "-z", tree.head]).toString().split("\0").filter(Boolean);
    for (const relative of headPaths) fs.rmSync(path.join(target, relative), { force: true });
    for (const entry of tree.files) {
      if (entry.type === "missing") continue;
      const file = path.join(target, entry.path);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      const bytes = fs.readFileSync(path.join(vault, "blobs", entry.sha256));
      if (entry.type === "symlink") fs.symlinkSync(bytes.toString(), file);
      else { fs.writeFileSync(file, bytes); fs.chmodSync(file, entry.mode); }
    }
    snapshot.restored.push({ tree_id: tree.id, path: restored });
  }
  if (JSON.stringify(observe(root)) !== JSON.stringify(before)) throw new Error("source changed during capture");
  const bytes = Buffer.from(`${JSON.stringify(snapshot)}\n`);
  fs.writeFileSync(path.join(vault, "receipts", `${receiptId}.json`), bytes, { mode: 0o600, flag: "wx" });
  fs.writeFileSync(path.join(vault, "receipts", `${receiptId}.sha256`), digest(bytes), { mode: 0o600, flag: "wx" });
  return snapshot;
}
module.exports = { capture, git, digest };
