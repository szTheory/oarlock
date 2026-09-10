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
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-planning-authority-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  write(root, ".planning/PROJECT.md", "# Project\n\n## Current Milestone: v2.2 Trust\n");
  write(root, ".planning/REQUIREMENTS.md", "# Requirements\n\n## v2.2 Requirements\n\n- [x] **REPO-02**: routing\n\n## Traceability\n\n| Requirement | Phase | Status |\n|---|---|---|\n| REPO-02 | Phase 31 | Complete |\n");
  write(root, ".planning/ROADMAP.md", "# Roadmap\n\n## Milestones\n\n- 🚧 **v2.2 Trust** — active\n\n## Phases\n\n- [x] **Phase 31: Repository Truth**\n\n### Phase 31: Repository Truth\n\n**Requirements**: REPO-02\n**Plans**: 1/1 plans executed\n\n- [x] 31-01-PLAN.md — truth\n");
  write(root, ".planning/STATE.md", "---\nmilestone: v2.2\ncurrent_phase: 31\nstatus: complete\n---\n");
  write(root, ".planning/EVIDENCE.md", "# Evidence\n");
  write(root, ".planning/MILESTONES.md", "# Milestones\n");
  write(root, ".planning/config.json", "{}\n");
  write(root, ".planning/phases/31-repository-truth/31-01-PLAN.md", "# Plan\n");
  write(root, ".planning/state.json", "{\"milestone\":\"v9.9\",\"current_phase\":\"99\",\"status\":\"complete\"}\n");
  write(root, ".planning/research/.cache/31-01-SUMMARY.md", "---\nstatus: complete\n---\n");
  write(root, ".planning/milestones/v9.9-ROADMAP.md", "# Archived decoy\n");
  write(root, ".planning/phases/30-old/30-VERIFICATION.md", "---\nstatus: passed\n---\n");
  write(root, ".planning/phases/99-decoy/31-01-SUMMARY.md", "---\nstatus: complete\n---\n");
  write(root, ".planning/phases/99-decoy/31-VERIFICATION.md", "---\nstatus: passed\n---\nREPO-02\n");
  return root;
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

test("PROHIB-REPO-02-TRANSPARENCY: decoys cannot route or complete canonical work", (t) => {
  const subject = resolveSubject();
  assert.equal(typeof subject.main, "function", "subject must expose main(argv, options)");
  const root = makePlanningTree(t);
  const human = invoke(subject, root, []);
  const jsonRun = invoke(subject, root, ["--json"]);
  const json = JSON.parse(jsonRun.stdout);

  assert.equal(human.status, 1, "human mode must reject proof-free completion");
  assert.equal(jsonRun.status, 1, "JSON mode must reject proof-free completion");
  assert.deepEqual(json.activeScope.active, { milestone: "v2.2", phase: "31" }, "decoy state must not acquire routing authority");
  assert.ok(json.conclusion.diagnosticCodes.includes("PCOMP_SUMMARY_MISSING"), "decoy summary must not complete the canonical plan");
  assert.ok(json.conclusion.diagnosticCodes.includes("PCOMP_VERIFICATION_MISSING"), "decoy verification must not prove the canonical phase");
  for (const code of json.conclusion.diagnosticCodes) assert.match(human.stdout, new RegExp(`\\b${code}\\b`), `human mode omitted ${code}`);
});
