#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {
  collectRepositorySnapshot,
  evaluateRepositoryInventory,
  exitCodeFor,
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

function readRegistry(registryPath, maximumBytes = 1024 * 1024) {
  const stat = fs.statSync(registryPath);
  if (stat.size > maximumBytes) throw new Error(`ownership registry exceeds ${maximumBytes} bytes`);
  return JSON.parse(fs.readFileSync(registryPath, "utf8"));
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
  const registryPath = options.registryPath || path.resolve(__dirname, "../.planning/repository-ownership.json");
  let registry = null;
  try {
    registry = readRegistry(registryPath, options.maximumRegistryBytes);
  } catch (error) {
    snapshot.collectionErrors.push({
      code: "RINV_REGISTRY_UNREADABLE",
      artifact: registryPath,
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
