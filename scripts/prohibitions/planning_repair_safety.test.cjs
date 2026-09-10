"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const PROJECT_ROOT = path.resolve(__dirname, "../..");
const DEFAULT_SUBJECT = "scripts/planning_health.cjs";

function resolveSubject() {
  const requested = process.env.GSD_PROHIB_SUBJECT || DEFAULT_SUBJECT;
  return require(path.isAbsolute(requested) ? requested : path.resolve(PROJECT_ROOT, requested));
}

function write(root, relative, content) {
  const target = path.join(root, relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
}

function makePlanningTree(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-planning-repair-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  write(root, ".planning/PROJECT.md", "# Project\n\n## Current Milestone: v2.2 Trust\n");
  write(root, ".planning/REQUIREMENTS.md", "# Requirements\n\n## v2.2 Requirements\n\n- [x] **REPO-04**: safety\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| REPO-04 | Phase 31 | Complete |\n");
  write(root, ".planning/ROADMAP.md", "# Roadmap\n\n## Milestones\n\n- 🚧 **v2.2 Trust** — active\n\n## Phases\n\n- [x] **Phase 31: Repository Truth**\n\n### Phase 31: Repository Truth\n\n**Requirements**: REPO-04\n**Plans**: 1/1 plans executed\n\n- [x] 31-01-PLAN.md — truth\n");
  write(root, ".planning/STATE.md", "---\nmilestone: v2.1\ncurrent_phase: 31\nstatus: complete\n---\n");
  write(root, ".planning/EVIDENCE.md", "# Evidence\n");
  write(root, ".planning/MILESTONES.md", "# Milestones\n");
  write(root, ".planning/config.json", "{}\n");
  write(root, ".planning/phases/31-repository-truth/31-01-PLAN.md", "# Plan\n");
  return root;
}

function capture(root) {
  const records = [];
  function walk(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) walk(absolute);
      else if (entry.isFile()) records.push([path.relative(root, absolute), fs.readFileSync(absolute).toString("base64")]);
    }
  }
  walk(path.join(root, ".planning"));
  return records.sort(([left], [right]) => left.localeCompare(right));
}

function invoke(subject, root, argv) {
  let stdout = "";
  let stderr = "";
  const status = subject.main(argv, {
    cwd: root,
    stdout: { write(value) { stdout += value; } },
    stderr: { write(value) { stderr += value; } },
    collectOptions: {
      collectCorroboration: false,
      runner: () => ({ status: 0, stdout: Buffer.alloc(0), stderr: Buffer.alloc(0) }),
    },
  });
  assert.equal(Number.isInteger(status), true, `subject must return an integer; stderr=${stderr}`);
  return { status, stdout };
}

test("PROHIB-REPO-04-SAFETY: conflicts block without applying proposed repairs", (t) => {
  const subject = resolveSubject();
  assert.equal(typeof subject.main, "function", "subject must expose main(argv, options)");
  const root = makePlanningTree(t);
  const before = capture(root);
  const human = invoke(subject, root, []);
  assert.deepEqual(capture(root), before, "human mode applied a proposed repair");
  const jsonRun = invoke(subject, root, ["--json"]);
  assert.deepEqual(capture(root), before, "JSON mode applied a proposed repair");
  const json = JSON.parse(jsonRun.stdout);
  const conflict = json.diagnostics.find(({ code }) => code === "PAUTH_MILESTONE_CONFLICT");

  assert.equal(human.status, 1, "human mode must block the authority conflict");
  assert.equal(jsonRun.status, 1, "JSON mode must block the authority conflict");
  assert.equal(json.activeScope.active, null, "no authority winner may be selected");
  assert.deepEqual({ expected: conflict.expected, actual: conflict.actual }, { expected: "v2.2", actual: "v2.1" });
  assert.match(conflict.repair, /propose/i, "repair must remain diagnostic data");
  assert.ok(json.conclusion.diagnosticCodes.includes("PCOMP_SUMMARY_MISSING"), "completion diagnostics must remain visible");
  assert.ok(json.conclusion.diagnosticCodes.includes("PCOMP_VERIFICATION_MISSING"), "verification diagnostics must remain visible");
  for (const code of json.conclusion.diagnosticCodes) assert.match(human.stdout, new RegExp(`\\b${code}\\b`), `human mode omitted ${code}`);
});
