"use strict";

const fs = require("node:fs");
const path = require("node:path");

function main(argv = [], options = {}) {
  const root = options.cwd || process.cwd();
  const mirror = JSON.parse(fs.readFileSync(path.join(root, ".planning/state.json"), "utf8"));
  const result = {
    schemaVersion: 1,
    reportType: "planning-health",
    activeScope: { active: { milestone: mirror.milestone, phase: String(mirror.current_phase) } },
    diagnostics: [],
    conclusion: { status: "healthy", exitCode: 0, errorCount: 0, warningCount: 0, infoCount: 0, diagnosticCodes: [] },
  };
  const output = argv.includes("--json")
    ? `${JSON.stringify(result, null, 2)}\n`
    : `Planning health (permissive)\nActive milestone: ${mirror.milestone}\nActive phase: ${mirror.current_phase}\nConclusion: healthy (exit 0)\n`;
  (options.stdout || process.stdout).write(output);
  return 0;
}

module.exports = { main };
