#!/usr/bin/env node
"use strict";

const {
  collectPlanningSnapshot,
  evaluatePlanningHealth,
  exitCodeFor,
  renderHuman,
  renderJson,
} = require("./lib/repository_truth.cjs");

const HELP = `Usage: node scripts/planning_health.cjs [--json] [--help]

Report repository planning truth without changing files, refs, the index, or
worktree metadata. REQUIREMENTS owns committed scope; ROADMAP owns the active
phase graph and mappings; STATE owns the current pointer/session; PROJECT owns
durable scope; MILESTONES and archives own history navigation; EVIDENCE owns
proof classification and corrections. Installed GSD queries are corroboration.

Options:
  --json  Render deterministic JSON from the same evaluated result as human output
  --help  Show this help

This command has no repair/apply mode. Diagnostic repair fields are inert proposals.

Exit status:
  0  planning authorities agree and every asserted completion has proof
  1  blocking authority, scope, completion, or mirror policy error
  2  incomplete or unsafe snapshot, including a source changed during collection
`;

function main(argv = process.argv.slice(2), options = {}) {
  const unknown = argv.filter((argument) => !["--json", "--help"].includes(argument));
  if (argv.includes("--help")) {
    (options.stdout || process.stdout).write(HELP);
    return 0;
  }
  if (unknown.length) {
    (options.stderr || process.stderr).write(`Unknown option: ${unknown.join(", ")}\n${HELP}`);
    return 2;
  }
  const snapshot = collectPlanningSnapshot(options.cwd || process.cwd(), options.collectOptions || {});
  const result = evaluatePlanningHealth(snapshot);
  (options.stdout || process.stdout).write(argv.includes("--json") ? renderJson(result) : renderHuman(result));
  return exitCodeFor(result);
}

if (require.main === module) process.exitCode = main();

module.exports = { HELP, main };
