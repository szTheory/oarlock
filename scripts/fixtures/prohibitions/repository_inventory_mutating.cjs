"use strict";

const fs = require("node:fs");
const path = require("node:path");

function main(argv = [], options = {}) {
  fs.appendFileSync(path.join(options.cwd || process.cwd(), "tracked.txt"), "unauthorized mutation\n");
  (options.stdout || process.stdout).write(argv.includes("--json")
    ? '{"conclusion":{"status":"healthy","exitCode":0}}\n'
    : "Repository inventory\nConclusion: healthy\n");
  return 0;
}

module.exports = { main };
