#!/usr/bin/env node
"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { parseStatus, parseWorktreeList } = require("./lib/repository_truth.cjs");

const SCHEMA_VERSION = 1;
const MAX_INPUT_BYTES = 64 * 1024;
const DEFAULT_MAX_BUFFER = 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 15_000;
const DISPOSITIONS = new Set(["retain", "merge-review", "remove-review"]);
const HELP = `Usage:
  node scripts/worktree_lifecycle.cjs entry --manifest PATH --owner OWNER [--json]
  node scripts/worktree_lifecycle.cjs exit --manifest PATH --owner OWNER \\
    --entry-receipt PATH --validation PATH --disposition retain|merge-review|remove-review [--json]

This command inspects an already provisioned dedicated Git worktree. It never
creates, removes, unlocks, resets, restores, stashes, or prunes worktrees. An
exit disposition is a proposal, not cleanup authorization.

Options:
  --manifest PATH       Schema-v1 task manifest
  --owner OWNER         Operator identity; must match manifest owner
  --entry-receipt PATH  Clean entry JSON emitted by the entry command
  --validation PATH     Schema-v1 JSON with passing command/result/SHA evidence
  --disposition VALUE   retain, merge-review, or remove-review (proposal only)
  --json                Emit JSON from the same result model as human output
  --help                Show this help

Exit status: 0 clean evidence, 1 invalid or mismatched evidence, 2 incomplete observation.
`;

function compareText(left, right) {
  return String(left).localeCompare(String(right), "en", { sensitivity: "variant" });
}

function readJsonFile(file, label, maximumBytes = MAX_INPUT_BYTES) {
  const resolved = path.resolve(file);
  const stat = fs.lstatSync(resolved);
  if (!stat.isFile() || stat.isSymbolicLink()) throw new Error(`${label} must be a regular non-symlink file`);
  if (stat.size > maximumBytes) throw new Error(`${label} exceeds the ${maximumBytes}-byte limit`);
  const bytes = fs.readFileSync(resolved);
  if (bytes.length > maximumBytes) throw new Error(`${label} exceeds the ${maximumBytes}-byte limit`);
  try {
    return JSON.parse(bytes.toString("utf8"));
  } catch (_error) {
    throw new Error(`${label} is not valid JSON`);
  }
}

function invoke(command, args, options) {
  const runner = options.runner || spawnSync;
  const safeEnvironment = Object.fromEntries(
    Object.entries(process.env).filter(([name]) => !/^GIT_/i.test(name)),
  );
  const suppliedEnvironment = Object.fromEntries(
    Object.entries(options.env || {}).filter(([name]) => !/^GIT_/i.test(name)),
  );
  return runner(command, args, {
    cwd: options.cwd,
    encoding: null,
    env: { ...safeEnvironment, ...suppliedEnvironment, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
    shell: false,
    windowsHide: true,
    maxBuffer: options.maxBuffer || DEFAULT_MAX_BUFFER,
    timeout: options.timeoutMs || DEFAULT_TIMEOUT_MS,
  });
}

function runGit(args, options) {
  const allowed = [
    args.length === 4 && args[0] === "worktree" && args[1] === "list" && args[2] === "--porcelain" && args[3] === "-z",
    args.length === 2 && args[0] === "rev-parse" && args[1] === "--show-toplevel",
    args.length === 6 && args[0] === "-C" && path.isAbsolute(args[1]) && args[2] === "status" && args[3] === "--porcelain=v2" && args[4] === "--branch" && args[5] === "-z",
    args.length === 7 && args[0] === "-C" && path.isAbsolute(args[1]) && args[2] === "diff" && args[3] === "--stat" && args[4] === "--no-ext-diff" && args[5] === "--no-textconv" && /^[0-9a-f]{40}\.{3}[0-9a-f]{40}$/.test(args[6]),
  ].some(Boolean);
  if (!allowed) throw new Error("internal Git inspection command was not allowlisted");
  const result = invoke(options.gitBinary || "git", args, options);
  if (result.error || result.signal || result.status !== 0) {
    const error = result.error;
    const evidence = error && error.code
      ? `${error.code}: Git inspection could not be completed`
      : result.signal
        ? `Git inspection terminated by signal ${result.signal}`
        : `Git inspection exited with status ${result.status}`;
    throw new Error(evidence);
  }
  return Buffer.isBuffer(result.stdout) ? result.stdout : Buffer.from(result.stdout || "");
}

function decode(buffer) {
  return buffer.toString("utf8");
}

function validateManifest(manifest, operatorOwner) {
  if (!manifest || typeof manifest !== "object" || Array.isArray(manifest)) throw new Error("manifest must be a JSON object");
  if (manifest.schema_version !== SCHEMA_VERSION) throw new Error("manifest schema_version must be 1");
  if (typeof manifest.task_id !== "string" || manifest.task_id.trim() === "") throw new Error("manifest task_id must be nonempty");
  if (typeof manifest.owner !== "string" || manifest.owner.trim() === "") throw new Error("manifest owner must be nonempty");
  if (manifest.owner !== operatorOwner) throw new Error("operator owner does not match manifest owner");
  if (typeof operatorOwner !== "string" || operatorOwner.trim() === "") throw new Error("--owner must be nonempty");
  if (typeof manifest.worktree_path !== "string" || !path.isAbsolute(manifest.worktree_path)) throw new Error("manifest worktree_path must be absolute");
  if (typeof manifest.branch !== "string" || !/^refs\/heads\/[A-Za-z0-9._/-]+$/.test(manifest.branch)) throw new Error("manifest branch must be a refs/heads branch name");
  if (typeof manifest.base_sha !== "string" || !/^[0-9a-f]{40}$/.test(manifest.base_sha)) throw new Error("manifest base_sha must be a 40-character lowercase SHA");
  return {
    task_id: manifest.task_id,
    owner: manifest.owner,
    worktree_path: manifest.worktree_path,
    branch: manifest.branch,
    base_sha: manifest.base_sha,
  };
}

function observeWorktree(identity, options) {
  let canonicalPath;
  try {
    canonicalPath = fs.realpathSync(identity.worktree_path);
  } catch (_error) {
    throw new Error("manifest worktree_path is missing or unreadable");
  }
  const listBuffer = runGit(["worktree", "list", "--porcelain", "-z"], { ...options, cwd: canonicalPath });
  let worktrees;
  try {
    worktrees = parseWorktreeList(listBuffer);
  } catch (_error) {
    throw new Error("Git worktree registry is unreadable or malformed");
  }
  const byPath = worktrees.filter((tree) => {
    try { return path.resolve(tree.path) === canonicalPath; } catch (_error) { return false; }
  });
  if (byPath.length !== 1) throw new Error(byPath.length === 0
    ? "manifest worktree is not registered by Git"
    : "duplicate Git worktree records claim the manifest path");
  const record = byPath[0];
  const primaryPath = worktrees[0] && path.resolve(worktrees[0].path);
  if (canonicalPath === primaryPath) throw new Error("primary shared worktree cannot be claimed as an isolated task tree");
  if (record.lock !== null) throw new Error("worktree is locked; evidence is incomplete");
  if (record.prunable !== null) throw new Error("worktree metadata is prunable; evidence is incomplete");
  if (!record.head || !/^[0-9a-f]{40}$/.test(record.head)) throw new Error("Git worktree HEAD is missing or malformed");
  if (record.branchRef !== identity.branch) throw new Error("Git worktree branch does not match manifest");
  if (record.head !== identity.base_sha && !identity.allowAdvancedHead) {
    throw new Error("entry HEAD does not match manifest base SHA");
  }

  const statusBuffer = runGit(["-C", canonicalPath, "status", "--porcelain=v2", "--branch", "-z"], options);
  let status;
  try {
    status = parseStatus(statusBuffer);
  } catch (_error) {
    throw new Error("Git status is unreadable or malformed");
  }
  if (status.head !== record.head) throw new Error("Git status HEAD disagrees with worktree registry");
  if (status.branch !== identity.branch.slice("refs/heads/".length)) throw new Error("Git status branch does not match manifest");
  if (status.dirty.length !== 0) throw new Error("worktree is dirty; clean evidence cannot be issued");
  return { path: canonicalPath, record, status };
}

function makeResult({ status, operation, identity, observed, diagnostics = [], extraFacts = {}, proposedDisposition = null, now }) {
  const facts = identity && observed ? {
    task_id: identity.task_id,
    owner: identity.owner,
    worktree_path: observed.path,
    branch: identity.branch,
    base_sha: identity.base_sha,
    head_sha: observed.status.head,
    clean: observed.status.dirty.length === 0,
    dirty: observed.status.dirty,
    observed_at: (now ? now() : new Date()).toISOString(),
    ...extraFacts,
  } : null;
  return {
    schema_version: SCHEMA_VERSION,
    kind: operation === "entry" ? "worktree-entry" : "worktree-exit",
    status,
    diagnostics: diagnostics.slice().sort((a, b) => compareText(a.code, b.code) || compareText(a.message, b.message)),
    facts,
    proposed_disposition: proposedDisposition,
  };
}

function validateEntryReceipt(receipt, identity, observedPath) {
  if (!receipt || receipt.schema_version !== SCHEMA_VERSION || receipt.kind !== "worktree-entry" || receipt.status !== "clean") {
    throw new Error("entry receipt is missing, malformed, or not clean");
  }
  const facts = receipt.facts;
  if (!facts || facts.clean !== true || !Array.isArray(facts.dirty) || facts.dirty.length !== 0) throw new Error("entry receipt does not prove a clean worktree");
  for (const field of ["task_id", "owner", "branch", "base_sha"]) {
    if (facts[field] !== identity[field]) throw new Error(`entry receipt ${field} does not match manifest`);
  }
  if (facts.worktree_path !== observedPath) throw new Error("entry receipt worktree_path does not match current canonical path");
  if (facts.head_sha !== identity.base_sha) throw new Error("entry receipt HEAD does not match manifest base SHA");
  return facts;
}

function validateValidationEvidence(evidence, headSha) {
  if (!evidence || evidence.schema_version !== SCHEMA_VERSION || !Array.isArray(evidence.validations) || evidence.validations.length === 0) {
    throw new Error("validation evidence must contain at least one validation");
  }
  const validations = evidence.validations.map((entry) => {
    if (!entry || typeof entry.command !== "string" || entry.command.trim() === "") throw new Error("each validation requires a nonempty command");
    if (entry.result !== "pass") throw new Error("every validation result must be pass");
    if (entry.sha !== headSha) throw new Error("validation SHA does not match observed exit HEAD");
    return { command: entry.command, result: entry.result, sha: entry.sha };
  });
  return validations;
}

function execute(argv, options = {}) {
  if (argv.includes("--help")) return { code: 0, text: HELP };
  const operation = argv[0];
  if (!new Set(["entry", "exit"]).has(operation)) return { code: 2, text: HELP };
  const values = new Map();
  let json = false;
  for (let index = 1; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--json") { json = true; continue; }
    if (!["--manifest", "--owner", "--entry-receipt", "--validation", "--disposition"].includes(argument)) {
      return { code: 2, text: `Unknown option: ${argument}\n${HELP}` };
    }
    if (values.has(argument) || typeof argv[index + 1] !== "string" || argv[index + 1].startsWith("--")) {
      return { code: 2, text: `Missing or duplicate value for ${argument}\n${HELP}` };
    }
    values.set(argument, argv[index + 1]);
    index += 1;
  }
  const required = operation === "entry"
    ? ["--manifest", "--owner"]
    : ["--manifest", "--owner", "--entry-receipt", "--validation", "--disposition"];
  const missing = required.filter((key) => !values.has(key));
  if (missing.length) return { code: 2, text: `Missing required options: ${missing.join(", ")}\n${HELP}` };
  if (operation === "exit" && !DISPOSITIONS.has(values.get("--disposition"))) {
    return { code: 1, text: "Disposition must be retain, merge-review, or remove-review\n" };
  }

  try {
    const rawManifest = readJsonFile(values.get("--manifest"), "manifest");
    const identity = validateManifest(rawManifest, values.get("--owner"));
    const observed = observeWorktree({ ...identity, allowAdvancedHead: operation === "exit" }, options);
    let extraFacts = {};
    if (operation === "exit") {
      const entryReceipt = readJsonFile(values.get("--entry-receipt"), "entry receipt");
      validateEntryReceipt(entryReceipt, identity, observed.path);
      const validationEvidence = readJsonFile(values.get("--validation"), "validation evidence");
      const validation = validateValidationEvidence(validationEvidence, observed.status.head);
      const diff = decode(runGit([
        "-C", observed.path, "diff", "--stat", "--no-ext-diff", "--no-textconv",
        `${identity.base_sha}...${observed.status.head}`,
      ], options)).trim();
      extraFacts = {
        diff: { base_sha: identity.base_sha, head_sha: observed.status.head, summary: diff || "No committed changes" },
        validation,
        cleanup_authorized: false,
        entry_receipt_sha256: crypto.createHash("sha256").update(JSON.stringify(entryReceipt)).digest("hex"),
      };
    }
    return {
      code: 0,
      result: makeResult({
        status: "clean", operation, identity, observed, extraFacts,
        proposedDisposition: operation === "exit" ? values.get("--disposition") : null,
        now: options.now,
      }),
      json,
    };
  } catch (error) {
    const diagnostic = {
      code: /could not|unreadable|missing or unreadable|registry/.test(error.message) ? "observation-incomplete" : "evidence-rejected",
      message: error.message,
    };
    return {
      code: diagnostic.code === "observation-incomplete" ? 2 : 1,
      result: makeResult({ status: "blocked", operation, diagnostics: [diagnostic], proposedDisposition: operation === "exit" ? values.get("--disposition") || null : null }),
      json,
    };
  }
}

function renderHuman(result) {
  const lines = [
    `Worktree ${result.kind === "worktree-entry" ? "entry" : "exit"}: ${result.status}`,
  ];
  if (result.facts) {
    lines.push(`Task: ${result.facts.task_id}`, `Owner: ${result.facts.owner}`);
    lines.push(`Worktree: ${result.facts.worktree_path}`, `Branch: ${result.facts.branch}`);
    lines.push(`Base: ${result.facts.base_sha}`, `HEAD: ${result.facts.head_sha}`);
    lines.push(`Working tree: ${result.facts.clean ? "clean" : "dirty"}`);
    if (result.facts.diff) lines.push(`Diff: ${result.facts.diff.summary}`);
    if (result.facts.validation) lines.push(`Validations: ${result.facts.validation.length} passed at ${result.facts.head_sha}`);
  }
  for (const diagnostic of result.diagnostics) lines.push(`Blocked: ${diagnostic.message}`);
  if (result.proposed_disposition) lines.push(`Proposed disposition: ${result.proposed_disposition} (not cleanup authorization)`);
  if (result.facts && result.facts.cleanup_authorized === false) lines.push("Cleanup authorized: no");
  return `${lines.join("\n")}\n`;
}

function main(argv = process.argv.slice(2), options = {}) {
  const outcome = execute(argv, options);
  const stdout = options.stdout || process.stdout;
  const stderr = options.stderr || process.stderr;
  if (!outcome.result) {
    (outcome.code === 0 ? stdout : stderr).write(outcome.text);
    return outcome.code;
  }
  const output = outcome.json
    ? `${JSON.stringify(outcome.result, null, 2)}\n`
    : renderHuman(outcome.result);
  (outcome.code === 0 ? stdout : stderr).write(output);
  return outcome.code;
}

if (require.main === module) process.exitCode = main();

module.exports = { HELP, execute, main, renderHuman, validateManifest, validateValidationEvidence };
