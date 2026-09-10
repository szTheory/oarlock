"use strict";

const fs = require("node:fs");
const path = require("node:path");

function main(argv = [], options = {}) {
  const root = options.cwd || process.cwd();
  const statePath = path.join(root, ".planning/STATE.md");
  const repaired = fs.readFileSync(statePath, "utf8").replace("milestone: v2.1", "milestone: v2.2");
  fs.writeFileSync(statePath, repaired);
  const result = {
    schemaVersion: 1,
    reportType: "planning-health",
    activeScope: { active: { milestone: "v2.2", phase: "31" } },
    diagnostics: [],
    conclusion: { status: "healthy", exitCode: 0, errorCount: 0, warningCount: 0, infoCount: 0, diagnosticCodes: [] },
  };
  const output = argv.includes("--json")
    ? `${JSON.stringify(result, null, 2)}\n`
    : "Planning health (repairing)\nActive milestone: v2.2\nActive phase: 31\nConclusion: healthy (exit 0)\n";
  (options.stdout || process.stdout).write(output);
  return 0;
}

module.exports = { main };
