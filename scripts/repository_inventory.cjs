#!/usr/bin/env node
"use strict";

const path = require("node:path");
const {
  collectRepositorySnapshot,
  evaluateRepositoryInventory,
  exitCodeFor,
  readBoundedRepositoryFile,
  renderHuman,
  renderJson,
} = require("./lib/repository_truth.cjs");

const HELP = `Usage: node scripts/repository_inventory.cjs [--json] [--help]

Collect a read-only inventory of the current repository and every Git-registered
worktree. Observed facts remain separate from proposed dispositions. This command
never cleans, prunes, unlocks, resets, restores, stashes, or repairs repository state.

Options:
  --json  Render deterministic JSON from the same evaluated result as human output
  --help  Show this help

Exit status:
  0  healthy or entirely covered by current intentional-state claims
  1  policy error such as unknown, stale, or ambiguous ownership
  2  incomplete or unsafe collection, including unreadable Git or registry data
`;

function readRegistry(root, registryPath, options = {}) {
  const record = readBoundedRepositoryFile(root, registryPath, {
    ...options,
    maximumBytes: options.maximumBytes || 1024 * 1024,
  });
  try {
    return JSON.parse(record.content);
  } catch (_error) {
    throw new Error("ownership registry contains invalid JSON");
  }
}

function repositoryArtifact(root, candidate) {
  const relative = path.relative(root, path.resolve(candidate));
  if (relative && relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative)) {
    return relative.split(path.sep).join("/");
  }
  return path.resolve(candidate);
}

function main(argv = process.argv.slice(2), options = {}) {
  const unknown = argv.filter((argument) => !["--json", "--help"].includes(argument));
  if (argv.includes("--help")) {
    (options.stdout || process.stdout).write(HELP);
    return 0;
  }
  if (unknown.length > 0) {
    (options.stderr || process.stderr).write(`Unknown option: ${unknown.join(", ")}\n${HELP}`);
    return 2;
  }

  const snapshot = collectRepositorySnapshot({ cwd: options.cwd || process.cwd(), ...(options.collectOptions || {}) });
  const repositoryRoot = snapshot.repository.root || path.resolve(options.cwd || process.cwd());
  const registryPath = options.registryPath || path.join(repositoryRoot, ".planning/repository-ownership.json");
  const registryArtifact = repositoryArtifact(repositoryRoot, registryPath);
  let registry = null;
  try {
    registry = readRegistry(repositoryRoot, registryPath, {
      ...(options.registryReadOptions || {}),
      maximumBytes: options.maximumRegistryBytes
        || (options.registryReadOptions && options.registryReadOptions.maximumBytes)
        || 1024 * 1024,
    });
  } catch (error) {
    snapshot.collectionErrors.push({
      code: "RINV_REGISTRY_UNREADABLE",
      artifact: registryArtifact,
      field: "registry",
      actual: null,
      evidence: error.message,
    });
  }
  const result = evaluateRepositoryInventory(snapshot, registry);
  (options.stdout || process.stdout).write(argv.includes("--json") ? renderJson(result) : renderHuman(result));
  return exitCodeFor(result);
}

if (require.main === module) process.exitCode = main();

module.exports = { HELP, main, readRegistry };
