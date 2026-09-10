"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  EXPECTED_IDS,
  evaluateTapRun,
  loadDescriptors,
  runEnforcement,
} = require("./enforce_phase31.cjs");

function temporaryRoot(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase31-enforcement-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  return root;
}

function write(root, relative, content = "module.exports = {};\n") {
  const target = path.join(root, relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
}

function plan(descriptors) {
  const lines = ["---", "phase_gates:", "  prohibitions:"];
  for (const descriptor of descriptors) {
    lines.push(`    - id: ${descriptor.id}`);
    for (const [key, value] of Object.entries(descriptor)) {
      if (key !== "id") lines.push(`      ${key}: ${value}`);
    }
  }
  lines.push("---", "", "<objective>fixture</objective>", "");
  return lines.join("\n");
}

function descriptor(id, suffix = id.toLowerCase()) {
  return {
    id,
    status: "resolved",
    verification: "test",
    flagged_unverified: "false",
    check_kind: "node-test",
    check_target: `checks/${suffix}.test.cjs`,
    check_violation_fixture: `fixtures/${suffix}-bad.cjs`,
    check_clean_fixture: `fixtures/${suffix}-clean.cjs`,
  };
}

function fixturePlans(t) {
  const root = temporaryRoot(t);
  const descriptors = EXPECTED_IDS.map((id) => descriptor(id));
  for (const item of descriptors) {
    write(root, item.check_target);
    write(root, item.check_violation_fixture);
    write(root, item.check_clean_fixture);
  }
  write(root, "plans/31-01-PLAN.md", plan(descriptors.slice(0, 2)));
  write(root, "plans/31-02-PLAN.md", plan(descriptors.slice(2, 4)));
  write(root, "plans/31-03-PLAN.md", plan(descriptors.slice(4)));
  return { root, planPaths: ["plans/31-01-PLAN.md", "plans/31-02-PLAN.md", "plans/31-03-PLAN.md"] };
}

function tap({ id, status, tests = 1, pass = 0, fail = 1, named = true }) {
  const marker = named ? `${id}: fixture assertion` : "unrelated assertion";
  const prefix = status === 0 ? "ok" : "not ok";
  return {
    status,
    signal: null,
    error: null,
    stdout: `${prefix} 1 - ${marker}\n1..${tests}\n# tests ${tests}\n# pass ${pass}\n# fail ${fail}\n`,
    stderr: "",
  };
}

test("happy path validates all six descriptors and proves named bad/clean TAP behavior", (t) => {
  const fixture = fixturePlans(t);
  const result = runEnforcement({
    ...fixture,
    runner(_command, _args, options) {
      const id = EXPECTED_IDS.find((candidate) => options.env.GSD_PROHIB_SUBJECT.includes(candidate.toLowerCase()));
      const clean = options.env.GSD_PROHIB_SUBJECT.endsWith("-clean.cjs");
      return tap({ id, status: clean ? 0 : 1, pass: clean ? 1 : 0, fail: clean ? 0 : 1 });
    },
  });
  assert.equal(result.descriptors.length, 6);
  assert.deepEqual(result.descriptors.map(({ id }) => id), EXPECTED_IDS);
  assert.equal(result.proofs.every(({ bad, clean }) => bad.namedFailure && clean.namedPass), true);
});

test("descriptor loading fails closed for a missing or malformed stable descriptor", (t) => {
  const fixture = fixturePlans(t);
  fs.writeFileSync(path.join(fixture.root, fixture.planPaths[2]), plan([descriptor("PROHIB-REPO-03-PRESERVATION")]));
  assert.throws(() => loadDescriptors(fixture), /missing.*PROHIB-REPO-03-IDENTITY/i);

  fs.writeFileSync(path.join(fixture.root, fixture.planPaths[2]), plan([
    descriptor("PROHIB-REPO-03-PRESERVATION"),
    { ...descriptor("PROHIB-REPO-03-IDENTITY"), status: "flagged-unverified" },
  ]));
  assert.throws(() => loadDescriptors(fixture), /status.*resolved/i);
});

test("descriptor loading rejects a missing target or fixture path", (t) => {
  const fixture = fixturePlans(t);
  fs.rmSync(path.join(fixture.root, "fixtures/prohib-repo-01-safety-bad.cjs"));
  assert.throws(() => loadDescriptors(fixture), /check_violation_fixture.*does not exist/i);
});

test("bad proof rejects a crash-only red without the named prohibition assertion", () => {
  const result = tap({ id: EXPECTED_IDS[0], status: 1, tests: 0, pass: 0, fail: 0, named: false });
  result.stderr = "SyntaxError: crashed before tests\n";
  assert.throws(() => evaluateTapRun(result, EXPECTED_IDS[0], "bad"), /non-vacuous named TAP failure/i);
});

test("bad proof rejects a toothless violation fixture that remains green", () => {
  const result = tap({ id: EXPECTED_IDS[0], status: 0, pass: 1, fail: 0 });
  assert.throws(() => evaluateTapRun(result, EXPECTED_IDS[0], "bad"), /violation fixture stayed green/i);
});

test("clean proof rejects a failing control", () => {
  const result = tap({ id: EXPECTED_IDS[0], status: 1, pass: 0, fail: 1 });
  assert.throws(() => evaluateTapRun(result, EXPECTED_IDS[0], "clean"), /clean fixture did not produce non-vacuous named TAP success/i);
});

