"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  collectPlanningSnapshot,
  evaluatePlanningHealth,
  parseCommittedRequirements,
  resolveActiveScope,
  renderHuman,
  renderJson,
  validateCompletionProof,
} = require("./lib/repository_truth.cjs");
const { main } = require("./planning_health.cjs");

function planningDocuments(overrides = {}) {
  return {
    ".planning/PROJECT.md": "# Project\n\n## Current Milestone: v2.2 Trust\n",
    ".planning/REQUIREMENTS.md": `# Requirements\n\n## Source Anchors\n\n| ID | Source |\n| USER-2026-09-09 | conversation |\n\n## v2.2 Requirements\n\n### Repository\n\n- [ ] **REPO-02**: canonical routing\n- [x] **REPO-01**: inventory\n\n## Future Requirements\n\n- **FUTURE-01**: candidate only\n\n## Traceability\n\n| Requirement | Phase | Status |\n|-------------|-------|--------|\n| REPO-01 | Phase 31 | Complete |\n| REPO-02 | Phase 31 | Pending |\n`,
    ".planning/ROADMAP.md": `# Roadmap\n\n## Milestones\n\n- 🚧 **v2.2 Trust** — Phases 31-32 (active)\n- ✅ **v2.1 Old** — Phases 27-30 (shipped)\n\n## Phases\n\n- [ ] **Phase 31: Repository Truth** - current\n- [ ] **Phase 32: Later** - future\n\n### Phase 31: Repository Truth\n\n**Requirements**: REPO-01, REPO-02\n**Plans**: 1/2 plans executed\n\n- [x] 31-01-PLAN.md — inventory\n- [ ] 31-02-PLAN.md — planning health\n`,
    ".planning/STATE.md": `---\nmilestone: v2.2\ncurrent_phase: 31\nstatus: executing\n---\n\n# State\n`,
    ".planning/EVIDENCE.md": "# Evidence Ledger\n",
    ".planning/MILESTONES.md": "# Milestones\n",
    ".planning/config.json": "{}\n",
    ...overrides,
  };
}

function snapshotFrom(overrides = {}) {
  const documents = planningDocuments(overrides);
  return {
    schemaVersion: 1,
    root: "/fixture",
    generatedAt: "2026-09-09T00:00:00.000Z",
    documents: Object.fromEntries(Object.entries(documents).map(([name, content]) => [name, { content, identity: { size: Buffer.byteLength(content) } }])),
    phaseArtifacts: [
      ".planning/phases/31-repository-truth/31-01-PLAN.md",
      ".planning/phases/31-repository-truth/31-01-SUMMARY.md",
      ".planning/phases/31-repository-truth/31-02-PLAN.md",
    ],
    corroboration: [],
    mirror: { exists: false, content: null, identity: null, consumerEvidence: [] },
    collectionErrors: [],
  };
}

function writeFixture(files = planningDocuments()) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "planning-health-"));
  for (const [relative, content] of Object.entries(files)) {
    const target = path.join(root, relative);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content);
  }
  const phaseDir = path.join(root, ".planning/phases/31-repository-truth");
  fs.mkdirSync(phaseDir, { recursive: true });
  fs.writeFileSync(path.join(phaseDir, "31-01-PLAN.md"), "# Plan 1\n");
  fs.writeFileSync(path.join(phaseDir, "31-01-SUMMARY.md"), "---\nstatus: complete\n---\n# Summary\n");
  fs.writeFileSync(path.join(phaseDir, "31-02-PLAN.md"), "# Plan 2\n");
  return root;
}

function completedDocuments() {
  return planningDocuments({
    ".planning/REQUIREMENTS.md": `# Requirements\n\n## v2.2 Requirements\n\n- [x] **REPO-01**: inventory\n- [x] **REPO-02**: routing\n\n## Future Requirements\n\n- **FUTURE-01**: candidate\n\n## Traceability\n\n| Requirement | Phase | Status |\n|-------------|-------|--------|\n| REPO-01 | Phase 31 | Complete |\n| REPO-02 | Phase 31 | Complete |\n`,
    ".planning/ROADMAP.md": `# Roadmap\n\n## Milestones\n\n- 🚧 **v2.2 Trust** — active\n\n## Phases\n\n- [x] **Phase 31: Repository Truth**\n\n### Phase 31: Repository Truth\n\n**Requirements**: REPO-01, REPO-02\n**Plans**: 2/2 plans executed\n\n- [x] 31-01-PLAN.md — inventory\n- [x] 31-02-PLAN.md — health\n`,
    ".planning/STATE.md": "---\nmilestone: v2.2\ncurrent_phase: 31\nstatus: complete\n---\n",
    ".planning/EVIDENCE.md": "# Evidence\n\n| REPO-01 | 31-VERIFICATION.md | pass |\n| REPO-02 | 31-VERIFICATION.md | pass |\n",
  });
}

function completedSnapshot() {
  const snapshot = snapshotFrom(completedDocuments());
  snapshot.phaseArtifacts = [
    ".planning/phases/31-repository-truth/31-01-PLAN.md",
    ".planning/phases/31-repository-truth/31-01-SUMMARY.md",
    ".planning/phases/31-repository-truth/31-02-PLAN.md",
    ".planning/phases/31-repository-truth/31-02-SUMMARY.md",
    ".planning/phases/31-repository-truth/31-VERIFICATION.md",
  ];
  snapshot.artifactContents = {
    ".planning/phases/31-repository-truth/31-01-SUMMARY.md": "---\nstatus: complete\n---\n",
    ".planning/phases/31-repository-truth/31-02-SUMMARY.md": "---\nstatus: complete\n---\n",
    ".planning/phases/31-repository-truth/31-VERIFICATION.md": "---\nstatus: passed\n---\n\nREPO-01 REPO-02\n",
  };
  return snapshot;
}

test("committed requirements: bounded parser excludes source anchors and future candidates", () => {
  const parsed = parseCommittedRequirements(planningDocuments()[".planning/REQUIREMENTS.md"]);
  assert.deepEqual(parsed.requirements.map(({ id }) => id), ["REPO-01", "REPO-02"]);
  assert.deepEqual(parsed.traceability.map(({ id }) => id), ["REPO-01", "REPO-02"]);
  assert.equal(JSON.stringify(parsed).includes("USER-2026-09-09"), false);
  assert.equal(JSON.stringify(parsed).includes("FUTURE-01"), false);
});

test("authority: ROADMAP graph and STATE pointer resolve one active scope", () => {
  const scope = resolveActiveScope(snapshotFrom());
  assert.deepEqual(scope.active, { milestone: "v2.2", phase: "31" });
  assert.equal(scope.phase.name, "Repository Truth");
  assert.deepEqual(scope.phase.requirements, ["REPO-01", "REPO-02"]);
  assert.deepEqual(scope.diagnostics, []);
});

test("authority conflict: canonical disagreement blocks with both values and no selected winner", () => {
  const snapshot = snapshotFrom({
    ".planning/STATE.md": "---\nmilestone: v2.1\ncurrent_phase: 99\nstatus: executing\n---\n",
  });
  const scope = resolveActiveScope(snapshot);
  assert.equal(scope.active, null);
  assert.deepEqual(scope.diagnostics.map(({ code }) => code), ["PAUTH_MILESTONE_CONFLICT", "PSCOPE_PHASE_NOT_IN_ROADMAP"]);
  assert.deepEqual(scope.diagnostics[0].expected, "v2.2");
  assert.deepEqual(scope.diagnostics[0].actual, "v2.1");
  assert.equal(scope.diagnostics[0].authority, ".planning/ROADMAP.md + .planning/STATE.md");
});

test("phantom scope: archives, caches, summaries, and future phase directories are inert", () => {
  const baseline = resolveActiveScope(snapshotFrom());
  const withDecoys = snapshotFrom();
  withDecoys.phaseArtifacts.push(
    ".planning/phases/99-decoy/99-VERIFICATION.md",
    ".planning/phases/32-later/32-01-SUMMARY.md",
    ".planning/research/.cache/active-phase-88.json",
    ".planning/milestones/v9.9-ROADMAP.md",
  );
  assert.deepEqual(resolveActiveScope(withDecoys), baseline);
});

test("authority diagnostic parity: human and JSON expose identical codes, severities, and conclusion", () => {
  const result = evaluatePlanningHealth(snapshotFrom({
    ".planning/STATE.md": "---\nmilestone: v2.1\ncurrent_phase: 31\nstatus: executing\n---\n",
  }));
  const json = JSON.parse(renderJson(result));
  const human = renderHuman(result);
  assert.deepEqual(json.diagnostics.map(({ code, severity }) => ({ code, severity })), result.diagnostics.map(({ code, severity }) => ({ code, severity })));
  assert.deepEqual(json.conclusion, result.conclusion);
  for (const diagnostic of result.diagnostics) assert.match(human, new RegExp(`${diagnostic.severity}\\] ${diagnostic.code}`));
  assert.match(human, new RegExp(`Conclusion: ${result.conclusion.status} \\(exit ${result.conclusion.exitCode}`));
});

test("authority collection: not-yet-started mapped phases need no directory", () => {
  const root = writeFixture();
  try {
    const snapshot = collectPlanningSnapshot(root, { collectCorroboration: false });
    const result = evaluatePlanningHealth(snapshot);
    assert.equal(result.activeScope.active.phase, "31");
    assert.equal(result.diagnostics.some(({ artifact }) => artifact.includes("32-later")), false);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("completion: every declared proof link is required and a filename alone proves nothing", () => {
  const healthy = completedSnapshot();
  assert.deepEqual(validateCompletionProof(healthy, "31"), []);

  const unsupported = completedSnapshot();
  unsupported.documents[".planning/ROADMAP.md"].content = unsupported.documents[".planning/ROADMAP.md"].content.replace("- [x] **Phase 31", "- [ ] **Phase 31");
  delete unsupported.artifactContents[".planning/phases/31-repository-truth/31-02-SUMMARY.md"];
  unsupported.artifactContents[".planning/phases/31-repository-truth/31-VERIFICATION.md"] = "# Verification\n\nPending.\n";
  unsupported.documents[".planning/EVIDENCE.md"].content = "# Evidence\n";
  assert.deepEqual(validateCompletionProof(unsupported, "31").map(({ code }) => code), [
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_ROADMAP_NOT_ACCEPTED",
    "PCOMP_SUMMARY_UNPROVEN",
    "PCOMP_VERIFICATION_UNPROVEN",
  ]);
});

test("diagnostic completion: unsupported completion links produce distinct blocking records", () => {
  const snapshot = completedSnapshot();
  snapshot.phaseArtifacts = snapshot.phaseArtifacts.filter((name) => !name.endsWith("31-02-SUMMARY.md"));
  const result = evaluatePlanningHealth(snapshot);
  const missing = result.diagnostics.find(({ code }) => code === "PCOMP_SUMMARY_MISSING");
  assert.equal(result.conclusion.exitCode, 1);
  assert.equal(missing.actual, ".planning/phases/31-repository-truth/31-02-SUMMARY.md");
  assert.match(missing.repair, /propose/i);
});

test("state.json: mirror never influences authority and no consumer yields proposal only", () => {
  const snapshot = snapshotFrom();
  snapshot.mirror = {
    exists: true,
    content: JSON.stringify({ contract: "0.0.0", milestone: "v9.9", phases: [{ number: "99", status: "complete" }] }),
    identity: { size: 80 },
    consumerEvidence: [],
  };
  const result = evaluatePlanningHealth(snapshot);
  assert.deepEqual(result.activeScope.active, { milestone: "v2.2", phase: "31" });
  const mirror = result.diagnostics.find(({ code }) => code === "PMIRROR_NO_CONSUMER");
  assert.equal(mirror.severity, "warning");
  assert.match(mirror.repair, /ignore|remove/i);
});

test("state.json diagnostic: demonstrated consumer requires versioned disposable mirror metadata", () => {
  const snapshot = snapshotFrom();
  snapshot.mirror = {
    exists: true,
    content: JSON.stringify({ contract: "0.0.0", flavor: "mystery", milestone: "v9.9", phases: [] }),
    identity: { size: 80 },
    consumerEvidence: ["runtime state-contract publisher and public artifact contract"],
  };
  const result = evaluatePlanningHealth(snapshot);
  assert.equal(result.diagnostics.some(({ code }) => code === "PMIRROR_METADATA_INVALID"), true);
  assert.equal(result.conclusion.exitCode, 1);
});

test("concurrent snapshot: injected source change exits 2 instead of returning mixed truth", () => {
  const root = writeFixture();
  try {
    let changed = false;
    const snapshot = collectPlanningSnapshot(root, {
      collectCorroboration: false,
      beforeConsistencyCheck() {
        const roadmap = path.join(root, ".planning/ROADMAP.md");
        changed = true;
        fs.appendFileSync(roadmap, "\n<!-- concurrent -->\n");
      },
    });
    assert.equal(changed, true);
    const result = evaluatePlanningHealth(snapshot);
    assert.equal(result.conclusion.exitCode, 2);
    assert.equal(result.diagnostics.some(({ code }) => code === "PSCOPE_SNAPSHOT_CHANGED"), true);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("read-only interrupted CLI: both formats preserve every planning byte", () => {
  const root = writeFixture();
  fs.writeFileSync(path.join(root, ".planning/state.json"), "{\"user\":\"owned\"}\n");
  const capture = () => Object.fromEntries(fs.readdirSync(path.join(root, ".planning"), { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => {
      const absolute = path.join(entry.parentPath || entry.path, entry.name);
      return [path.relative(root, absolute), fs.readFileSync(absolute).toString("base64")];
    })
    .sort(([left], [right]) => left.localeCompare(right)));
  const before = capture();
  for (const argv of [[], ["--json"]]) {
    const output = { write() {} };
    main(argv, { cwd: root, stdout: output, stderr: output, collectOptions: { collectCorroboration: false } });
  }
  assert.deepEqual(capture(), before);
  fs.rmSync(root, { recursive: true, force: true });
});
