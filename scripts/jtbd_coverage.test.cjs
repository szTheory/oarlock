"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");
const { HORIZONS, STATUSES, evaluateHandoff, main } = require("./jtbd_coverage.cjs");

const RECORD = `# Canonical JTBD coverage

## JTBD-ADOPT-01

| Field | Value |
|-------|-------|
| actor | Adopter engineer |
| situation | When adding Paddle Billing to an Elixir application |
| outcome | I need a typed, documented SDK boundary so I can integrate without guessing provider behavior. |
| capability | Oarlock exposes its documented customer and billing operations with typed errors. |
| smallest_gap | Application-owned persistence, entitlements, and live provider setup remain outside the SDK. |
| boundary | Oarlock owns the client and typed request seam; the application owns policy and persistence; Paddle owns provider behavior. |
| source | 2026-09-09: .planning/research/FEATURES.md; 2026-09-26: .planning/REQUIREMENTS.md |
| owner | oarlock maintainers |
| adopter_owner | unknown |
| rationale | Keep the SDK narrow and make its actual proof boundary discoverable. |
| requirement_phase | ORIENT-01@Phase 36; ORIENT-02@Phase 36 |
| proof | Contract tests plus exact-SHA hosted CI; provider-state claims need separately recorded sandbox/live evidence. |
| evidence | .planning/EVIDENCE.md; .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_class | Phase verification and planning evidence |
| evidence_identity | .planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md |
| evidence_caveat | Local and MockServer checks do not establish live provider state. |
| freshness | Refresh when the public contract, requirement mapping, or proof identity changes. |
| non_goal | Does not promise application-owned subscription storage or live-provider verification. |
| promotion | Reopen when a named adopter job needs a capability beyond the current typed seam. |
| horizon | short |
| commitment_status | shipped |
| trajectory_group | short/shipped |
| backlog_archive | none |

### Status history

| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Evidence class | Caveat |
|------|---------------|-------------|--------------|------------|--------|-------|-----------|----------|---------------|--------|
| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record existing shipped capability without widening scope. | .planning/EVIDENCE.md | Phase verification and planning evidence | Local/hosted/provider proof classes remain distinct. |
`;

const INDEX = `# Persona entry points\n\n## Adopter engineer\n\n- [JTBD-ADOPT-01](JTBD-COVERAGE.md#jtbd-adopt-01) — Integrate the typed billing seam.\n`;

const REQUIREMENTS = `# Requirements

- [x] **SAFE-04**: safe reads retry.
- [x] **SAFE-06**: public documentation aligns.
- [x] **ORIENT-01**: canonical JTBD coverage exists.
- [ ] **ORIENT-02**: provenance is complete.

## Future Requirements

- **DISC-01**: customer discovery.
- **DISC-02**: transaction discovery.
- **FUTURE-01**: candidate handoff fixture.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-04 | Phase 32 | Complete |
| SAFE-06 | Phase 32 | Complete |
| ORIENT-01 | Phase 36 | Complete |
| ORIENT-02 | Phase 36 | Pending |
`;

const ROADMAP = `# Roadmap

### Phase 32: SDK Trust

### Phase 35: Operations

### Phase 36: JTBD Coverage
`;

function repository(t, { record = RECORD, personas = INDEX, workflows = INDEX, requirements = REQUIREMENTS } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-jtbd-coverage-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const write = (relative, content) => {
    const target = path.join(root, relative);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content);
  };
  write(".planning/JTBD-COVERAGE.md", record);
  write(".planning/PERSONAS.md", personas);
  write(".planning/WORKFLOWS.md", workflows);
  write(".planning/REQUIREMENTS.md", requirements);
  write(".planning/ROADMAP.md", ROADMAP);
  write(".planning/EVIDENCE.md", "# Evidence\n\nHistorical v0.1.2 publication did not retain candidate bytes or `release-evidence.json`.\n\n`.planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md` is a phase verification artifact.\n");
  write(".planning/BACKLOG.md", "# Backlog\n\n### B-04 - Accrue migration\n");
  write(".planning/BACKLOG-ARCHIVE.md", "# Backlog Archive\n\n### B-01 - Shipped operation\n");
  write(".planning/MILESTONES.md", "# Milestones\n\n## v2.2 JTBD Coverage\n");
  write(".planning/research/FEATURES.md", "# Features\n");
  write(".planning/phases/32-dependency-sdk-trust-boundary/32-VERIFICATION.md", "# Verification\n");
  write(".planning/phases/36-jtbd-coverage/36-01-PLAN.md", "# Plan\n");
  spawnSync("git", ["init", "-b", "main", root], { encoding: "utf8" });
  return root;
}

function run(root, args = ["--json"]) {
  let stdout = "";
  let stderr = "";
  const code = main(args, {
    cwd: root,
    stdout: { write: (value) => { stdout += value; } },
    stderr: { write: (value) => { stderr += value; } },
  });
  return { code, stdout, stderr, result: args.includes("--json") ? JSON.parse(stdout) : null };
}

function handoffFixture(root, overrides = {}) {
  const sha = "a".repeat(40);
  const data = {
    schema_version: 1,
    observed_at: "2026-09-26T21:00:00Z",
    repository: "szTheory/oarlock",
    branch: "phase36-candidate",
    candidate_branch: "phase36-candidate",
    candidate_clone: path.join(os.tmpdir(), "oarlock-phase36-candidate-fixture"),
    candidate_sha: sha,
    observed_head_sha: sha,
    main_base_sha: "c".repeat(40),
    tested_payload_sha: sha,
    handoff_document_sha: sha,
    closeout_status: "complete",
    clean_close_claim: true,
    worktrees: [{ path: root, head: sha, branch: "phase36-candidate", lock: null, dirty_status: "clean", dirty_count: 0, dirty_paths: [], owner: "phase36 execution", disposition: "candidate checkout", evidence: "fresh repository inventory" }],
    hosted_proof: { status: "passed", proof_class: "hosted-exact-sha-ci-artifact", repository: "szTheory/oarlock", workflow: "CI", run_id: "12345", attempt: 1, event_head_sha: sha, artifact_id: "9876", digest: `sha256:${"b".repeat(64)}`, url: "https://github.com/szTheory/oarlock/actions/runs/12345", head_sha: sha },
    pull_request: { number: 36, state: "open", base: "main", head_sha: sha },
    open_blockers: [],
    source_links: [".planning/JTBD-COVERAGE.md", ".planning/EVIDENCE.md", ".planning/REQUIREMENTS.md", ".planning/ROADMAP.md"],
    accepted_caveats: [{ text: "v0.1.2 publication was observed, but candidate-to-served-byte identity and release-evidence.json remain unresolved.", source: ".planning/EVIDENCE.md" }],
    candidate_ids: ["JTBD-FUTURE-01"],
  };
  Object.assign(data, overrides);
  const runUrl = "https://github.com/szTheory/oarlock/actions/runs/12345";
  const liveHostedProof = {
    observed: true,
    verified: true,
    sha,
    eventHeadSha: sha,
    testedSha: sha,
    workflow: "CI",
    run: { id: 12345, workflowName: "CI", headSha: sha, attempt: 1, url: runUrl },
    proof: { testedSha: sha, eventHeadSha: sha, runId: 12345, runAttempt: 1, verified: true },
    artifact: { observed: true, verified: true, name: "ci-proof-12345-1", id: 9876, digest: `sha256:${"b".repeat(64)}`, runId: 12345, headSha: sha },
  };
  const canonical = fs.readFileSync(path.join(root, ".planning/JTBD-COVERAGE.md"), "utf8");
  fs.writeFileSync(path.join(root, ".planning/JTBD-COVERAGE.md"), `${canonical}\n## JTBD-FUTURE-01\n\n| Field | Value |\n|-------|-------|\n| commitment_status | candidate |\n| requirement_phase | FUTURE-01@Future Requirements; no committed phase mapping |\n`);
  const handoff = `# Test handoff\n\n<!-- HANDOFF_DATA_BEGIN -->\n\n\`\`\`json\n${JSON.stringify(data, null, 2)}\n\`\`\`\n\n<!-- HANDOFF_DATA_END -->\n\nSource: [Evidence ledger](EVIDENCE.md).\n`;
  writeFileForTest(root, ".planning/v2.2-HANDOFF.md", handoff);
  const worktree = ({ dirty = false, lock = null } = {}) => ({
    path: root, head: sha, branch: "phase36-candidate", lock,
    dirty: dirty ? [{ path: ".planning/v2.2-HANDOFF.md", kind: "untracked" }] : [],
  });
  return {
    data,
    inventory: { worktrees: [worktree()], facts: { worktrees: [worktree()] } },
    candidateIdentity: { head: sha, parent: data.main_base_sha, branch: data.candidate_branch, remote: "https://github.com/szTheory/oarlock.git" },
    livePullRequest: { head_sha: sha, state: "OPEN", base: "main", merged_at: null },
    liveHostedProof,
    sha,
  };
}

function handoffOptions(fixture, overrides = {}) {
  return {
    inventory: fixture.inventory,
    readCandidateIdentity: () => fixture.candidateIdentity,
    readPullRequest: () => fixture.livePullRequest,
    liveHostedProof: fixture.liveHostedProof,
    ...overrides,
  };
}

function writeFileForTest(root, relative, content) {
  const target = path.join(root, relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
}

test("both indexes resolve one stable JTBD ID to one complete canonical record", (t) => {
  const root = repository(t);
  const result = run(root);
  assert.equal(result.code, 0, result.stdout);
  assert.equal(result.result.status, "healthy");
  assert.deepEqual(result.result.record_ids, ["JTBD-ADOPT-01"]);
  assert.deepEqual(result.result.index_counts.personas, { "JTBD-ADOPT-01": 1 });
  assert.deepEqual(result.result.index_counts.workflows, { "JTBD-ADOPT-01": 1 });
});

test("missing, duplicate, wrong-ID, and unsafe navigation links are diagnosed deterministically", (t) => {
  const cases = [
    ["missing", INDEX.replace(/- \[JTBD-ADOPT-01\].*\n/, ""), "JTBD_INDEX_LINK_MISSING"],
    ["duplicate", `${INDEX}- [JTBD-ADOPT-01](JTBD-COVERAGE.md#jtbd-adopt-01) — duplicate\n`, "JTBD_INDEX_LINK_DUPLICATE"],
    ["wrong target", INDEX.replace("jtbd-adopt-01", "jtbd-missing-99"), "JTBD_INDEX_TARGET_MISSING"],
    ["unsafe target", INDEX.replace("JTBD-COVERAGE.md", "../../outside.md"), "JTBD_INDEX_TARGET_UNSAFE"],
  ];
  for (const [name, personas, code] of cases) {
    const root = repository(t, { personas });
    const result = run(root);
    assert.equal(result.code, 1, name);
    assert.ok(result.result.diagnostics.some((item) => item.code === code), name);
    assert.deepEqual(result.result.diagnostics, [...result.result.diagnostics].sort((a, b) =>
      `${a.code}:${a.artifact}:${a.field}`.localeCompare(`${b.code}:${b.artifact}:${b.field}`)));
  }
});

test("duplicate canonical IDs and incomplete or invalid status axes fail closed", (t) => {
  const duplicate = `${RECORD}\n${RECORD.replace("JTBD-ADOPT-01", "JTBD-ADOPT-01")}`;
  let root = repository(t, { record: duplicate });
  let result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_DUPLICATE_ID"));

  const incomplete = RECORD.replace("| smallest_gap | Application-owned persistence, entitlements, and live provider setup remain outside the SDK. |\n", "");
  root = repository(t, { record: incomplete });
  result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_REQUIRED_FIELD_MISSING" && item.field.endsWith(".smallest_gap")));

  const invalid = RECORD.replace("| horizon | short |", "| horizon | tomorrow |").replace("| commitment_status | shipped |", "| commitment_status | promised | ");
  root = repository(t, { record: invalid });
  result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_HORIZON_INVALID"));
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_STATUS_INVALID"));
});

test("status history requires dated, sourced transitions with continuous prior state", (t) => {
  const missingEvidence = RECORD.replace(
    "| .planning/EVIDENCE.md | Phase verification and planning evidence | Local/hosted/provider proof classes remain distinct. |",
    "|  | Phase verification and planning evidence | Local/hosted/provider proof classes remain distinct. |",
  );
  let root = repository(t, { record: missingEvidence });
  let result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_HISTORY_FIELD_MISSING" && item.field.endsWith(".evidence")));

  const brokenContinuity = RECORD.replace(
    "| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record existing shipped capability without widening scope. | .planning/EVIDENCE.md | Phase verification and planning evidence | Local/hosted/provider proof classes remain distinct. |",
    "| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record existing shipped capability without widening scope. | .planning/EVIDENCE.md | Phase verification and planning evidence | Local/hosted/provider proof classes remain distinct. |\n| 2026-09-27 | long | mid | conditional | candidate | .planning/REQUIREMENTS.md | oarlock maintainers | Keep later discovery separate. | .planning/EVIDENCE.md | Candidate research | Candidate only. |",
  );
  root = repository(t, { record: brokenContinuity });
  result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_HISTORY_CONTINUITY"));
});

test("linked requirements must map to their authoritative phase", (t) => {
  const mismapped = RECORD.replace("ORIENT-02@Phase 36", "ORIENT-02@Phase 35");
  const root = repository(t, { record: mismapped });
  const result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_PHASE_MAPPING_MISMATCH" && item.field.includes("ORIENT-02")));
});

test("requirement mappings reject unsupported targets and malformed spacing", (t) => {
  for (const [name, value] of [
    ["unsupported target", "ORIENT-01@Backlog"],
    ["spaces around mapping", "ORIENT-01 @ Phase 36"],
    ["unbacked explanatory note", "no committed phase mapping"],
  ]) {
    const root = repository(t, { record: RECORD.replace("ORIENT-01@Phase 36; ORIENT-02@Phase 36", value) });
    const result = run(root);
    assert.equal(result.code, 1, name);
    assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_REQUIREMENT_REFERENCE_INVALID"), name);
  }
});

test("status history evidence class is required", (t) => {
  const withoutEvidenceClass = RECORD.replace("| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Evidence class | Caveat |", "| Date | Prior horizon | New horizon | Prior status | New status | Source | Owner | Rationale | Evidence | Caveat |")
    .replace("| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record existing shipped capability without widening scope. | .planning/EVIDENCE.md | Phase verification and planning evidence | Local/hosted/provider proof classes remain distinct. |", "| 2026-09-26 | unknown | short | unknown | shipped | .planning/REQUIREMENTS.md | oarlock maintainers | Record existing shipped capability without widening scope. | .planning/EVIDENCE.md | Local/hosted/provider proof classes remain distinct. |");
  const root = repository(t, { record: withoutEvidenceClass });
  const result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_HISTORY_FIELD_MISSING" && item.field.endsWith(".evidence_class")));
});

test("dated source paths and accountable/adopter ownership are explicit and surfaced", (t) => {
  const cases = [
    ["unaccountable repository owner", RECORD.replace("| owner | oarlock maintainers |", "| owner | someone |"), "JTBD_OWNER_ACCOUNTABILITY_MISSING"],
    ["missing dated source path", RECORD.replace("2026-09-09: .planning/research/FEATURES.md", "2026-09-09: .planning/research/missing.md"), "JTBD_REFERENCE_MISSING"],
    ["unclassified adopter owner", RECORD.replace("| adopter_owner | unknown |", "| adopter_owner | unassigned |"), "JTBD_ADOPTER_OWNER_UNCLASSIFIED"],
  ];
  for (const [name, record, code] of cases) {
    const root = repository(t, { record });
    const result = run(root);
    assert.equal(result.code, 1, name);
    assert.ok(result.result.diagnostics.some((item) => item.code === code), name);
  }
  const root = repository(t);
  const result = run(root);
  assert.deepEqual(result.result.ownership, [{ id: "JTBD-ADOPT-01", repository_owner: "repository", adopter_owner: "unknown" }]);
});

test("roadmap headings authorize planned phases before a live phase directory exists", (t) => {
  const root = repository(t);
  fs.rmSync(path.join(root, ".planning/phases/36-jtbd-coverage"), { recursive: true });
  const result = run(root);
  assert.equal(result.code, 0, JSON.stringify(result.result.diagnostics));
});

test("duplicate live phase directories are rejected even when the roadmap phase exists", (t) => {
  const root = repository(t);
  fs.mkdirSync(path.join(root, ".planning/phases/36-duplicate"));
  const result = run(root);
  assert.equal(result.code, 1);
  assert.ok(result.result.diagnostics.some((item) => item.code === "JTBD_PHASE_DIRECTORY_MISMATCH"));
});

test("future, evidence, and backlog identities cannot contradict their owning authorities", (t) => {
  const cases = [
    ["future requirement in committed phase", RECORD.replace("ORIENT-02@Phase 36", "ORIENT-02@Future Requirements"), "JTBD_REQUIREMENT_HORIZON_MISMATCH"],
    ["missing evidence identity", RECORD.replace("32-VERIFICATION.md", "32-missing-VERIFICATION.md"), "JTBD_REFERENCE_MISSING"],
    ["unknown backlog item", RECORD.replace("| backlog_archive | none |", "| backlog_archive | B-99 in .planning/BACKLOG.md |"), "JTBD_BACKLOG_ARCHIVE_MISMATCH"],
    ["historical exact-SHA proof", RECORD.replace("Phase verification and planning evidence", "Historical proof only"), "JTBD_HISTORICAL_PROOF_AS_CURRENT"],
  ];
  for (const [name, record, code] of cases) {
    const root = repository(t, { record });
    const result = run(root);
    assert.equal(result.code, 1, name);
    assert.ok(result.result.diagnostics.some((item) => item.code === code), name);
  }
});

test("CLI and fixture checks leave repository bytes and Git state unchanged", (t) => {
  const root = repository(t);
  const watched = [
    ".planning/JTBD-COVERAGE.md",
    ".planning/PERSONAS.md",
    ".planning/WORKFLOWS.md",
  ];
  const beforeBytes = watched.map((file) => fs.readFileSync(path.join(root, file)));
  const beforeStatus = spawnSync("git", ["status", "--porcelain=v2", "--branch"], { cwd: root, encoding: "utf8" }).stdout;
  const first = run(root);
  const second = run(root, ["--json"]);
  assert.equal(first.code, 0);
  assert.equal(second.stdout, first.stdout);
  assert.deepEqual(watched.map((file) => fs.readFileSync(path.join(root, file))), beforeBytes);
  assert.equal(spawnSync("git", ["status", "--porcelain=v2", "--branch"], { cwd: root, encoding: "utf8" }).stdout, beforeStatus);
});

test("handoff check rejects dirty and locked worktree claims and missing hosted proof", (t) => {
  for (const [name, options, code] of [
    ["dirty", { dirty: true }, "HANDOFF_WORKTREE_NOT_CLEAN"],
    ["locked", { lock: "unresolved owner lock" }, "HANDOFF_WORKTREE_LOCKED"],
  ]) {
    const root = repository(t);
    const fixture = handoffFixture(root);
    const entry = { ...fixture.data.worktrees[0], dirty_status: name === "dirty" ? "dirty" : "clean", dirty_count: name === "dirty" ? 1 : 0, dirty_paths: name === "dirty" ? ["dirty.md"] : [], lock: options.lock || null };
    fixture.data.worktrees = [entry];
    fs.writeFileSync(path.join(root, ".planning/v2.2-HANDOFF.md"), `<!-- HANDOFF_DATA_BEGIN -->\n\n\`\`\`json\n${JSON.stringify(fixture.data, null, 2)}\n\`\`\`\n\n<!-- HANDOFF_DATA_END -->\n`);
    const current = { ...fixture.inventory.worktrees[0], dirty: options.dirty ? [{ path: "dirty.md", kind: "ordinary" }] : [], lock: options.lock || null };
    const result = evaluateHandoff(root, handoffOptions(fixture, { inventory: { worktrees: [current], facts: { worktrees: [current] } } }));
    assert.ok(result.diagnostics.some((item) => item.code === code), name);
    assert.notEqual(result.status, "healthy", name);
    assert.ok(result.diagnostics.some((item) => item.code === "HANDOFF_FALSE_CLEAN_CLAIM"), `${name} cannot satisfy a clean-close assertion`);
  }

  const root = repository(t);
  const fixture = handoffFixture(root, { tested_payload_sha: "unknown", hosted_proof: { status: "pending", proof_class: "unknown", repository: "szTheory/oarlock", workflow: "CI", run_id: "unknown", attempt: "unknown", event_head_sha: "unknown", artifact_id: "unknown", digest: "unknown", url: "unknown", head_sha: "unknown" }, clean_close_claim: false, closeout_status: "blocked", open_blockers: ["Exact candidate hosted proof is unavailable."] });
  const result = evaluateHandoff(root, handoffOptions(fixture));
  assert.ok(result.diagnostics.some((item) => item.code === "HANDOFF_PROOF_PENDING"));
  assert.equal(result.status, "incomplete");
});

test("handoff check rejects wrong SHA and historical-only proof but accepts exact current proof", (t) => {
  for (const [name, overrides, code] of [
    ["wrong run head", { hosted_proof: { status: "passed", proof_class: "hosted-exact-sha-ci-artifact", repository: "szTheory/oarlock", workflow: "CI", run_id: "12345", attempt: 1, event_head_sha: "c".repeat(40), artifact_id: "9876", digest: `sha256:${"b".repeat(64)}`, url: "https://github.com/szTheory/oarlock/actions/runs/12345", head_sha: "c".repeat(40) } }, "HANDOFF_PROOF_SHA_MISMATCH"],
    ["stale class", { hosted_proof: { status: "passed", proof_class: "historical-release-artifact", repository: "szTheory/oarlock", workflow: "CI", run_id: "12345", attempt: 1, event_head_sha: "a".repeat(40), artifact_id: "9876", digest: `sha256:${"b".repeat(64)}`, url: "https://github.com/szTheory/oarlock/actions/runs/12345", head_sha: "a".repeat(40) } }, "HANDOFF_PROOF_CLASS_STALE"],
  ]) {
    const root = repository(t);
    const fixture = handoffFixture(root, overrides);
    const result = evaluateHandoff(root, handoffOptions(fixture));
    assert.ok(result.diagnostics.some((item) => item.code === code), name);
  }

  const root = repository(t);
  const fixture = handoffFixture(root);
  const result = evaluateHandoff(root, handoffOptions(fixture));
  assert.equal(result.status, "healthy", JSON.stringify(result.diagnostics));
  assert.deepEqual(result.diagnostics, []);
  let jsonOutput = "";
  let humanOutput = "";
  const jsonCode = main(["--check-handoff", "--json"], { root, ...handoffOptions(fixture), stdout: { write: (value) => { jsonOutput += value; } }, stderr: { write: () => {} } });
  const humanCode = main(["--check-handoff"], { root, ...handoffOptions(fixture), stdout: { write: (value) => { humanOutput += value; } }, stderr: { write: () => {} } });
  assert.equal(jsonCode, 0);
  assert.equal(humanCode, 0);
  assert.match(humanOutput, /Conclusion: healthy/);
  assert.equal(JSON.parse(jsonOutput).diagnostics.length, result.diagnostics.length);
});

test("handoff requires the recorded run and artifact to match live hosted proof", (t) => {
  const root = repository(t);
  const fixture = handoffFixture(root);
  const tampered = {
    ...fixture.liveHostedProof,
    artifact: { ...fixture.liveHostedProof.artifact, digest: `sha256:${"c".repeat(64)}` },
  };
  const result = evaluateHandoff(root, handoffOptions(fixture, { liveHostedProof: tampered }));
  assert.ok(result.diagnostics.some((item) => item.code === "HANDOFF_HOSTED_PROOF_LIVE_MISMATCH"));

  const unavailable = handoffOptions(fixture, { liveHostedProof: undefined });
  delete unavailable.liveHostedProof;
  unavailable.hostedProofRunner = () => ({ status: 2, stdout: "", stderr: "private GitHub error details" });
  const unavailableResult = evaluateHandoff(root, unavailable);
  assert.equal(unavailableResult.status, "incomplete");
  const diagnostic = unavailableResult.diagnostics.find((item) => item.code === "HANDOFF_HOSTED_PROOF_LIVE_INCOMPLETE");
  assert.ok(diagnostic);
  assert.doesNotMatch(JSON.stringify(diagnostic), /private GitHub error details/);
});

test("handoff closure rechecks the candidate checkout, live PR, and Future Requirements authority", (t) => {
  const root = repository(t);
  const movedPr = handoffFixture(root);
  movedPr.livePullRequest = { ...movedPr.livePullRequest, head_sha: "d".repeat(40) };
  const prResult = evaluateHandoff(root, handoffOptions(movedPr));
  assert.ok(prResult.diagnostics.some((item) => item.code === "HANDOFF_PULL_REQUEST_LIVE_MISMATCH"));

  const movedClone = handoffFixture(root);
  movedClone.candidateIdentity = { ...movedClone.candidateIdentity, head: "d".repeat(40) };
  const cloneResult = evaluateHandoff(root, handoffOptions(movedClone));
  assert.ok(cloneResult.diagnostics.some((item) => item.code === "HANDOFF_CANDIDATE_CHECKOUT_MISMATCH"));

  const unbackedFuture = handoffFixture(root);
  const requirementsPath = path.join(root, ".planning/REQUIREMENTS.md");
  fs.writeFileSync(requirementsPath, fs.readFileSync(requirementsPath, "utf8").replace("- **FUTURE-01**: candidate handoff fixture.\n", ""));
  const authorityResult = evaluateHandoff(root, handoffOptions(unbackedFuture));
  assert.ok(authorityResult.diagnostics.some((item) => item.code === "HANDOFF_CANDIDATE_AUTHORITY_MISMATCH"));
});

test("live coverage includes direct actors and keeps all future jobs outside committed phase scope", (t) => {
  const project = path.resolve(__dirname, "..");
  let stdout = "";
  const code = main(["--json"], {
    root: project,
    stdout: { write: (value) => { stdout += value; } },
    stderr: { write: () => {} },
  });
  const result = JSON.parse(stdout);
  assert.equal(code, 0, stdout);
  assert.deepEqual(result.record_ids, [
    "JTBD-ACCRUE-01", "JTBD-ACCRUE-02", "JTBD-ADOPT-01", "JTBD-API-01", "JTBD-API-02", "JTBD-API-03",
    "JTBD-CONTRIBUTOR-01", "JTBD-DISC-01", "JTBD-DISC-02", "JTBD-MOCK-01", "JTBD-MOCK-02", "JTBD-QUOTE-01",
    "JTBD-RELEASE-01", "JTBD-RELIABILITY-01", "JTBD-REVIEW-01", "JTBD-SECURITY-01", "JTBD-STABLE-01", "JTBD-STEWARD-01",
  ]);
  for (const index of [result.index_counts.personas, result.index_counts.workflows]) {
    assert.deepEqual(Object.values(index), Array(18).fill(1));
  }
  assert.ok(result.ownership.some((item) => item.adopter_owner === "unknown"), "explicit unknown adopter ownership is surfaced");
  const canonical = fs.readFileSync(path.join(project, ".planning/JTBD-COVERAGE.md"), "utf8");
  assert.match(canonical, /Application reliability engineer/);
  assert.match(canonical, /Security and privacy operator/);
  assert.match(canonical, /Support, finance, or reconciliation operator/);
  assert.match(canonical, /external:accrue/);
  assert.deepEqual([...HORIZONS].sort(), ["long", "mid", "short"]);
  assert.deepEqual([...STATUSES].sort(), ["candidate", "committed", "conditional", "external", "rejected", "shipped", "superseded"]);

  const futureIds = ["DISC-01", "DISC-02", "QUOTE-01", "MOCK-01", "MOCK-02", "ACCRUE-01", "ACCRUE-02", "API-01", "API-02", "API-03", "STABLE-01"];
  for (const id of futureIds) {
    const record = canonical.split(/^## /m).find((block) => block.startsWith(`JTBD-${id}\n`));
    assert.ok(record, `missing JTBD record for future requirement ${id}`);
    assert.match(record, new RegExp(`\\| requirement_phase \\| ${id}@Future Requirements;`));
    assert.doesNotMatch(record, /@Phase\s+36/);
  }
  for (const id of ["DISC-01", "DISC-02", "QUOTE-01", "MOCK-01", "MOCK-02"]) {
    const record = canonical.split(/^## /m).find((block) => block.startsWith(`JTBD-${id}\n`));
    assert.match(record, /\| commitment_status \| candidate \|/);
    assert.match(record, /owner unknown/);
  }
});
