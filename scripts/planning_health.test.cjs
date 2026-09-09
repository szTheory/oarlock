"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  collectTagIdentities,
  collectPlanningSnapshot,
  evaluatePlanningHealth,
  parseCommittedRequirements,
  parsePhaseRange,
  resolveActiveScope,
  renderHuman,
  renderJson,
  readBoundedRepositoryFile,
  readPackageVersion,
  resolveCanonicalPhaseDirectory,
  validateCompletionProof,
  validateMilestoneHistory,
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

test("canonical completion: same-basename decoys and body-only status remain inert", () => {
  const snapshot = completedSnapshot();
  snapshot.phaseArtifacts = [
    ".planning/phases/31-repository-truth/31-01-PLAN.md",
    ".planning/phases/31-repository-truth/31-02-PLAN.md",
    ".planning/phases/99-decoy/31-01-SUMMARY.md",
    ".planning/phases/99-decoy/31-02-SUMMARY.md",
    ".planning/phases/99-decoy/31-VERIFICATION.md",
  ];
  snapshot.artifactContents = {
    ".planning/phases/99-decoy/31-01-SUMMARY.md": "---\nstatus: complete\n---\n",
    ".planning/phases/99-decoy/31-02-SUMMARY.md": "---\nstatus: complete\n---\n",
    ".planning/phases/99-decoy/31-VERIFICATION.md": "---\nstatus: passed\n---\nREPO-01 REPO-02\n",
  };
  assert.deepEqual(resolveCanonicalPhaseDirectory(snapshot, "31"), {
    status: "resolved",
    directory: ".planning/phases/31-repository-truth",
    matches: [".planning/phases/31-repository-truth"],
  });
  assert.deepEqual(validateCompletionProof(snapshot, "31").map(({ code }) => code), [
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_SUMMARY_MISSING",
    "PCOMP_SUMMARY_MISSING",
    "PCOMP_VERIFICATION_MISSING",
  ]);

  const bodyOnly = completedSnapshot();
  for (const artifact of Object.keys(bodyOnly.artifactContents)) {
    bodyOnly.artifactContents[artifact] = artifact.endsWith("VERIFICATION.md")
      ? "# Verification\n\nstatus: passed\n\nREPO-01 REPO-02\n"
      : "# Summary\n\nstatus: complete\n";
  }
  assert.deepEqual(validateCompletionProof(bodyOnly, "31").map(({ code }) => code), [
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_SUMMARY_UNPROVEN",
    "PCOMP_SUMMARY_UNPROVEN",
    "PCOMP_VERIFICATION_UNPROVEN",
  ]);
});

test("completion: failed evidence and verification rows never satisfy requirement proof", () => {
  const snapshot = completedSnapshot();
  snapshot.documents[".planning/EVIDENCE.md"].content = "# Evidence\n\n| REPO-01 | 31-VERIFICATION.md | failed |\n| REPO-02 | 31-VERIFICATION.md | pending |\n";
  snapshot.artifactContents[".planning/phases/31-repository-truth/31-VERIFICATION.md"] = "---\nstatus: passed\n---\n\n| REPO-01 | failed |\n| REPO-02 | pending |\n";
  assert.deepEqual(validateCompletionProof(snapshot, "31").map(({ code }) => code), [
    "PCOMP_REQUIREMENT_UNLINKED",
    "PCOMP_REQUIREMENT_UNLINKED",
  ]);
});

test("completion: unchecked plans remain blocking even with complete summaries", () => {
  const snapshot = completedSnapshot();
  snapshot.documents[".planning/ROADMAP.md"].content = snapshot.documents[".planning/ROADMAP.md"].content.replace("- [x] 31-02-PLAN.md", "- [ ] 31-02-PLAN.md");
  assert.ok(validateCompletionProof(snapshot, "31").some(({ code, field }) => code === "PCOMP_PLAN_NOT_ACCEPTED" && field === "plan 31-02-PLAN.md"));
});

test("canonical completion: missing or ambiguous phase directory is incomplete", () => {
  const missing = completedSnapshot();
  missing.phaseArtifacts = [".planning/phases/99-decoy/31-01-SUMMARY.md"];
  assert.equal(resolveCanonicalPhaseDirectory(missing, "31").status, "missing");
  let result = evaluatePlanningHealth(missing);
  assert.equal(result.conclusion.exitCode, 2);
  assert.ok(result.diagnostics.some(({ code, incomplete }) => code === "PSCOPE_CANONICAL_PHASE_DIRECTORY_MISSING" && incomplete));

  const ambiguous = completedSnapshot();
  ambiguous.phaseArtifacts.push(".planning/phases/31-copy/31-01-PLAN.md");
  assert.equal(resolveCanonicalPhaseDirectory(ambiguous, "31").status, "ambiguous");
  result = evaluatePlanningHealth(ambiguous);
  assert.equal(result.conclusion.exitCode, 2);
  assert.ok(result.diagnostics.some(({ code, incomplete }) => code === "PSCOPE_CANONICAL_PHASE_DIRECTORY_AMBIGUOUS" && incomplete));
});

test("completion: authority conflict does not suppress missing proof diagnostics", () => {
  const snapshot = completedSnapshot();
  snapshot.documents[".planning/STATE.md"].content = "---\nmilestone: v2.2\ncurrent_phase: 31\nstatus: executing\n---\n";
  snapshot.phaseArtifacts = [];
  snapshot.artifactContents = {};
  const result = evaluatePlanningHealth(snapshot);
  assert.ok(result.diagnostics.some(({ code }) => code === "PSCOPE_PHASE_STATUS_CONFLICT"));
  assert.ok(result.diagnostics.some(({ code, incomplete }) => code === "PSCOPE_CANONICAL_PHASE_DIRECTORY_MISSING" && incomplete));
  assert.equal(result.conclusion.exitCode, 2);
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

test("diagnostic stale active artifacts and broken current references remain actionable", () => {
  const snapshot = snapshotFrom();
  snapshot.phaseArtifacts = snapshot.phaseArtifacts.filter((name) => !name.endsWith("31-02-PLAN.md"));
  snapshot.phaseArtifacts.push(".planning/phases/31-repository-truth/31-02-SUMMARY.md");
  snapshot.artifactContents = {
    ".planning/phases/31-repository-truth/31-02-SUMMARY.md": "---\nstatus: complete\n---\n",
  };
  const result = evaluatePlanningHealth(snapshot);
  const records = Object.fromEntries(result.diagnostics.map((item) => [item.code, item]));
  assert.equal(records.PSCOPE_ACTIVE_PLAN_MISSING.severity, "error");
  assert.equal(records.PSCOPE_STALE_ACTIVE_SUMMARY.severity, "warning");
  assert.match(records.PSCOPE_ACTIVE_PLAN_MISSING.repair, /propose/i);
  assert.equal(result.conclusion.exitCode, 1);
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

test("state.json diagnostic: JSON null is controlled invalid metadata", () => {
  const snapshot = snapshotFrom();
  snapshot.mirror = { exists: true, content: "null", identity: { size: 4 }, consumerEvidence: ["fixture consumer"] };
  const result = evaluatePlanningHealth(snapshot);
  assert.ok(result.diagnostics.some(({ code }) => code === "PMIRROR_METADATA_INVALID"));
  assert.equal(result.conclusion.exitCode, 1);
});

test("state.json diagnostic: consumer mirror must exactly match canonical routing", () => {
  const snapshot = snapshotFrom();
  snapshot.mirror = {
    exists: true,
    content: JSON.stringify({
      contract: "1.0.0", flavor: "core", milestone: "v2.20",
      phases: [{ number: "31", name: "Wrong", status: "complete" }, { number: "99", name: "Extra", status: "pending" }],
    }),
    identity: { size: 100 },
    consumerEvidence: ["fixture consumer"],
  };
  const mismatches = evaluatePlanningHealth(snapshot).diagnostics.filter(({ code }) => code === "PMIRROR_CONTENT_MISMATCH");
  assert.deepEqual(mismatches.map(({ field }) => field), [
    "milestone", "phases.31.name", "phases.31.status", "phases.32", "phases.99",
  ]);
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

test("concurrent snapshot: same-length rewrite with restored mtime is detected", () => {
  const root = writeFixture();
  try {
    const roadmap = path.join(root, ".planning/ROADMAP.md");
    const original = fs.readFileSync(roadmap, "utf8");
    const originalStat = fs.statSync(roadmap);
    const snapshot = collectPlanningSnapshot(root, {
      collectCorroboration: false,
      beforeConsistencyCheck() {
        const changed = original.replace("Repository Truth", "Repository Fable");
        assert.equal(Buffer.byteLength(changed), Buffer.byteLength(original));
        fs.writeFileSync(roadmap, changed);
        fs.utimesSync(roadmap, originalStat.atime, originalStat.mtime);
      },
    });
    assert.ok(snapshot.collectionErrors.some(({ code, artifact }) => code === "PSCOPE_SNAPSHOT_CHANGED" && artifact === ".planning/ROADMAP.md"));
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("concurrent snapshot: phase namespace additions are detected", () => {
  const root = writeFixture();
  try {
    const snapshot = collectPlanningSnapshot(root, {
      collectCorroboration: false,
      beforeConsistencyCheck() {
        const duplicate = path.join(root, ".planning/phases/31-duplicate");
        fs.mkdirSync(duplicate);
        fs.writeFileSync(path.join(duplicate, "31-99-PLAN.md"), "# late plan\n");
      },
    });
    assert.ok(snapshot.collectionErrors.some(({ code, artifact, field }) => code === "PSCOPE_SNAPSHOT_CHANGED"
      && artifact === ".planning/phases" && field === "artifact namespace"));
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("source boundary: intermediate planning symlink exits 2 without reading external content", (t) => {
  const root = writeFixture();
  const container = path.dirname(root);
  const externalPhases = path.join(container, "external-phases");
  const externalPhase = path.join(externalPhases, "31-repository-truth");
  const sentinel = "EXTERNAL-PLANNING-SECRET";
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  t.after(() => fs.rmSync(externalPhases, { recursive: true, force: true }));

  fs.rmSync(path.join(root, ".planning/phases"), { recursive: true, force: true });
  fs.mkdirSync(externalPhase, { recursive: true });
  fs.writeFileSync(path.join(externalPhase, "31-01-PLAN.md"), `${sentinel}\n`);
  fs.symlinkSync(externalPhases, path.join(root, ".planning/phases"), "dir");

  const before = fs.readFileSync(path.join(externalPhase, "31-01-PLAN.md"), "utf8");
  const snapshot = collectPlanningSnapshot(root, { collectCorroboration: false });
  const result = evaluatePlanningHealth(snapshot);
  const human = renderHuman(result);
  const json = renderJson(result);

  assert.equal(result.conclusion.exitCode, 2);
  assert.equal(result.conclusion.status, "incomplete");
  assert.ok(result.diagnostics.some(({ code, artifact, evidence }) => code === "PAUTH_SOURCE_UNREADABLE"
    && artifact === ".planning/phases"
    && /boundary|symlink|repository/i.test(evidence)));
  assert.equal(JSON.stringify(snapshot).includes(sentinel), false);
  assert.equal(human.includes(sentinel), false);
  assert.equal(json.includes(sentinel), false);
  assert.deepEqual(JSON.parse(json).conclusion, result.conclusion);
  assert.equal(fs.readFileSync(path.join(externalPhase, "31-01-PLAN.md"), "utf8"), before);
});

test("source boundary: growth after open is bounded during the descriptor read", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "planning-bounded-read-"));
  try {
    fs.writeFileSync(path.join(root, "source.md"), "1234");
    assert.throws(() => readBoundedRepositoryFile(root, "source.md", {
      maximumBytes: 8,
      afterOpen(_artifact, absolute) {
        fs.appendFileSync(absolute, "56789");
      },
    }), /exceeds 8 bytes during read/);
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

function historySnapshot(overrides = {}) {
  const roadmap = `# Roadmap\n\n## Milestones\n\n- ✅ **v1.2 Production Surface** — Phases 8-13 (shipped 2026-06-09) — [archive](milestones/v1.2-ROADMAP.md)\n- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; phase artifacts retained)\n`;
  const milestones = `# Milestones Log\n\n## v1.2 Production Surface (Shipped: 2026-06-09)\n\n**Status:** ✅ Shipped\n**Phases:** 8-13\n\n### Release Identity\n\n- **Planning milestone:** \`v1.2\`\n- **Git tag:** \`v1.2\`\n- **Source SHA:** \`abc123\`\n- **Declared Hex package version:** \`0.1.1\`\n- **Publication status:** Unknown — no independent registry evidence is recorded.\n\n### Archive\n\n- Roadmap: \`.planning/milestones/v1.2-ROADMAP.md\`\n- Requirements: \`.planning/milestones/v1.2-REQUIREMENTS.md\`\n\n## v1.0 MVP — pre-archival\n\n**Status:** ✅ Shipped (not formally archived through \`/gsd-complete-milestone\`)\n**Phases:** 1-5\n\n### Release Identity\n\n- **Planning milestone:** \`v1.0\`\n- **Git tag:** Unknown — pre-archive exception.\n- **Source SHA:** Unknown — pre-archive exception.\n- **Declared Hex package version:** Unknown — pre-archive exception.\n- **Publication status:** Unknown — pre-archive exception.\n`;
  return {
    root: "/fixture",
    documents: {
      ".planning/ROADMAP.md": { content: roadmap },
      ".planning/MILESTONES.md": { content: milestones },
      ".planning/EVIDENCE.md": { content: "# Evidence\n\n| 2026-09-09 | v1.2 archive status correction | preserved archive wording |\n" },
    },
    milestoneArchives: {
      ".planning/milestones/v1.2-ROADMAP.md": "# Milestone v1.2\n\n**Status:** ✅ SHIPPED\n**Phases:** 8-13\n",
      ".planning/milestones/v1.2-REQUIREMENTS.md": "# Requirements v1.2\n\n**Status:** 🚧 IN PROGRESS\n",
    },
    tagIdentities: [{ tag: "v1.2", sourceSha: "abc123", declaredPackageVersion: "0.1.1", publicationStatus: "unknown" }],
    collectionErrors: [],
    ...overrides,
  };
}

test("milestone identity: tag, peeled SHA, package version, and publication remain separate", () => {
  const runner = (_command, args) => {
    if (args[0] === "for-each-ref") return { status: 0, stdout: Buffer.from("v1.2\0abc123\0\n") };
    if (args[0] === "show") return { status: 0, stdout: Buffer.from('defmodule Paddle.MixProject do\n  @version "0.1.1"\nend\n') };
    throw new Error(`unexpected git args: ${args.join(" ")}`);
  };
  assert.deepEqual(collectTagIdentities("/fixture", { runner }), {
    identities: [{ tag: "v1.2", sourceSha: "abc123", declaredPackageVersion: "0.1.1", publicationStatus: "unknown" }],
    collectionErrors: [],
  });
  assert.deepEqual(readPackageVersion("/fixture", "v1.2", { runner }), {
    value: "0.1.1", evidence: "git show v1.2:mix.exs", status: "known",
  });
});

test("git identity collection: for-each-ref failure exits 2 with cause", () => {
  const runner = (_command, args) => {
    assert.equal(args[0], "for-each-ref");
    return { status: 128, stdout: Buffer.alloc(0), stderr: Buffer.from("fatal: refs unavailable\n") };
  };
  const observed = collectTagIdentities("/fixture", { runner });
  assert.deepEqual(observed.identities, []);
  assert.equal(observed.collectionErrors.length, 1);
  assert.deepEqual(observed.collectionErrors[0].actual, {
    command: "git for-each-ref --format=%(refname:short)%00%(objectname)%00%(*objectname)%00 refs/tags",
    status: 128,
    stderr: "fatal: refs unavailable",
    cause: "fatal: refs unavailable",
  });

  const snapshot = snapshotFrom();
  snapshot.milestoneArchives = historySnapshot().milestoneArchives;
  snapshot.documents = { ...snapshot.documents, ...historySnapshot().documents };
  snapshot.tagIdentities = observed.identities;
  snapshot.collectionErrors.push(...observed.collectionErrors);
  const result = evaluatePlanningHealth(snapshot);
  assert.equal(result.conclusion.exitCode, 2);
  assert.ok(result.diagnostics.some(({ code, evidence }) => code === "PIDENT_TAG_COLLECTION_FAILED" && /refs unavailable/.test(evidence)));
  assert.equal(result.diagnostics.some(({ code }) => code === "PIDENT_TAG_SHA_MISMATCH"), false);
});

test("git identity collection: tagged git-show failure exits 2 with cause", () => {
  const runner = (_command, args) => {
    if (args[0] === "for-each-ref") return { status: 0, stdout: Buffer.from("v1.2\0abc123\0\n"), stderr: Buffer.alloc(0) };
    return { status: 128, stdout: Buffer.alloc(0), stderr: Buffer.from("fatal: tagged file unreadable\n") };
  };
  const observed = collectTagIdentities("/fixture", { runner });
  assert.equal(observed.identities.length, 1);
  assert.equal(observed.identities[0].packageVersionStatus, "collection-error");
  assert.equal(observed.collectionErrors.length, 1);

  const snapshot = historySnapshot({ tagIdentities: observed.identities, collectionErrors: observed.collectionErrors });
  const planning = snapshotFrom();
  Object.assign(planning, snapshot);
  planning.documents = { ...snapshotFrom().documents, ...snapshot.documents };
  const result = evaluatePlanningHealth(planning);
  assert.equal(result.conclusion.exitCode, 2);
  assert.ok(result.diagnostics.some(({ code, evidence }) => code === "PIDENT_PACKAGE_COLLECTION_FAILED" && /tagged file unreadable/.test(evidence)));
  assert.equal(result.diagnostics.some(({ code }) => code === "PIDENT_PACKAGE_VERSION_MISMATCH"), false);

  const absent = readPackageVersion("/fixture", "v1.2", {
    runner: () => ({ status: 0, stdout: Buffer.from("defmodule Fixture do\nend\n"), stderr: Buffer.alloc(0) }),
  });
  assert.equal(absent.status, "unknown");
  assert.match(absent.evidence, /declaration absent/);
});

test("milestone archive: missing, mutable, contradictory, and escaped history edges diagnose separately", () => {
  const missing = historySnapshot();
  missing.documents[".planning/MILESTONES.md"].content = missing.documents[".planning/MILESTONES.md"].content.replace(/## v1\.2[\s\S]*?(?=## v1\.0)/, "");
  assert.equal(validateMilestoneHistory(missing).some(({ code }) => code === "PHIST_INDEX_ENTRY_MISSING"), true);

  const mutable = historySnapshot();
  mutable.documents[".planning/MILESTONES.md"].content = mutable.documents[".planning/MILESTONES.md"].content.replace(".planning/milestones/v1.2-ROADMAP.md", ".planning/ROADMAP.md");
  assert.equal(validateMilestoneHistory(mutable).some(({ code }) => code === "PARCHIVE_MUTABLE_LINK"), true);

  const escaped = historySnapshot();
  escaped.documents[".planning/MILESTONES.md"].content = escaped.documents[".planning/MILESTONES.md"].content.replace(".planning/milestones/v1.2-ROADMAP.md", "../outside.md");
  assert.equal(validateMilestoneHistory(escaped).some(({ code }) => code === "PARCHIVE_LINK_ESCAPE"), true);

  const contradiction = historySnapshot();
  const diagnostic = validateMilestoneHistory(contradiction).find(({ code }) => code === "PHIST_ARCHIVE_STATUS_CONTRADICTION");
  assert.equal(diagnostic.severity, "warning");
  assert.match(diagnostic.repair, /EVIDENCE\.md/);
  assert.doesNotMatch(diagnostic.repair, /edit.*archive/i);
});

test("exact phase range: 8-13 does not match 18-130", () => {
  assert.deepEqual(parsePhaseRange("8-13"), { start: "8", end: "13", normalized: "8-13" });
  assert.deepEqual(parsePhaseRange("8.1 - 13.20"), { start: "8.1", end: "13.20", normalized: "8.1-13.20" });
  assert.deepEqual(parsePhaseRange("8-13 (6 phases, 21 plans)"), { start: "8", end: "13", normalized: "8-13" });
  for (const invalid of [null, "", "18-130 trailing", "prefix 8-13", "8-13-14", "13-8", "8..1-13", "8-"]) {
    assert.equal(parsePhaseRange(invalid), null, String(invalid));
  }

  const mismatch = historySnapshot();
  mismatch.documents[".planning/MILESTONES.md"].content = mismatch.documents[".planning/MILESTONES.md"].content.replace("**Phases:** 8-13", "**Phases:** 18-130");
  const diagnostics = validateMilestoneHistory(mismatch).filter(({ code }) => code === "PHIST_PHASE_RANGE_MISMATCH");
  assert.equal(diagnostics.length, 1);
  assert.deepEqual(diagnostics[0].expected, { start: "8", end: "13" });
  assert.deepEqual(diagnostics[0].actual, { start: "18", end: "130" });
  assert.equal(diagnostics[0].authority, ".planning/ROADMAP.md");
  assert.match(diagnostics[0].repair, /only the mutable milestone index/i);
});

test("exact phase range: equal decimal endpoints pass and malformed fields fail", () => {
  const decimalRoadmap = `# Roadmap\n\n## Milestones\n\n- ✅ **v1.2 Production Surface** — Phases 8.1-13.20 (shipped 2026-06-09) — [archive](milestones/v1.2-ROADMAP.md)\n`;
  const decimal = historySnapshot();
  decimal.documents[".planning/ROADMAP.md"].content = decimalRoadmap;
  decimal.documents[".planning/MILESTONES.md"].content = decimal.documents[".planning/MILESTONES.md"].content.replace("**Phases:** 8-13", "**Phases:** 8.1 - 13.20");
  assert.equal(validateMilestoneHistory(decimal).some(({ code }) => code === "PHIST_PHASE_RANGE_MISMATCH"), false);

  for (const invalid of ["prefix 8.1-13.20", "8.1-13.20 trailing", "8.1-13.20-14", "13.20-8.1"]) {
    const snapshot = historySnapshot();
    snapshot.documents[".planning/MILESTONES.md"].content = snapshot.documents[".planning/MILESTONES.md"].content.replace("**Phases:** 8-13", `**Phases:** ${invalid}`);
    assert.equal(validateMilestoneHistory(snapshot).filter(({ code }) => code === "PHIST_PHASE_RANGE_MISMATCH").length, 1, invalid);
  }
});

test("milestone diagnostics: five identities preserve unknowns and renderer conclusions stay identical", () => {
  const snapshot = historySnapshot();
  const healthyCodes = validateMilestoneHistory(snapshot).map(({ code }) => code);
  assert.deepEqual(healthyCodes, ["PHIST_PREARCHIVE_EXCEPTION", "PIDENT_PUBLICATION_UNKNOWN", "PHIST_ARCHIVE_STATUS_CONTRADICTION"]);
  const planning = snapshotFrom();
  Object.assign(planning, snapshot);
  planning.documents = { ...snapshotFrom().documents, ...snapshot.documents };
  const result = evaluatePlanningHealth(planning);
  const json = JSON.parse(renderJson(result));
  assert.deepEqual(json.conclusion.diagnosticCodes, result.conclusion.diagnosticCodes);
  assert.deepEqual(json.diagnostics.map(({ code }) => code), result.diagnostics.map(({ code }) => code));
  for (const code of healthyCodes) assert.match(renderHuman(result), new RegExp(code));
});

test("current repository milestone history is reconciled and archive bytes stay immutable", () => {
  const root = path.resolve(__dirname, "..");
  const archiveRoot = path.join(root, ".planning/milestones");
  const captureArchives = () => Object.fromEntries(fs.readdirSync(archiveRoot, { withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => [entry.name, fs.readFileSync(path.join(archiveRoot, entry.name)).toString("base64")])
    .sort(([left], [right]) => left.localeCompare(right)));
  const before = captureArchives();
  const snapshot = collectPlanningSnapshot(root, { collectCorroboration: false });
  const result = evaluatePlanningHealth(snapshot);
  const historyErrors = result.diagnostics.filter(({ code, severity }) => /^(?:PHIST|PARCHIVE|PIDENT)_/.test(code) && severity === "error");
  assert.deepEqual(historyErrors, []);
  assert.deepEqual(captureArchives(), before);
  const index = snapshot.documents[".planning/MILESTONES.md"].content;
  assert.match(index, /## v1\.2 Production Surface/);
  assert.match(index, /## v1\.4 Catalog & Events/);
  assert.match(index, /## v2\.1[\s\S]*?Declared Hex package version:\*\* `0\.1\.1`/);
  assert.match(index, /## v2\.1[\s\S]*?Publication status:\*\* Unknown/);
});
