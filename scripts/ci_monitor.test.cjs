const assert = require("node:assert/strict");
const { mkdtempSync, writeFileSync, chmodSync, rmSync, readFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join } = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");

const script = join(__dirname, "ci_monitor.cjs");

function makeFakeGh(scenario) {
  const dir = mkdtempSync(join(tmpdir(), "ci-monitor-"));
  const fakeGh = join(dir, "gh");
  const stateFile = join(dir, "state.json");

  writeFileSync(
    fakeGh,
    `#!/usr/bin/env node
const fs = require("node:fs");
const scenario = process.env.FAKE_GH_SCENARIO;
const stateFile = process.env.FAKE_GH_STATE;
const args = process.argv.slice(2);
const requiredJobs = [
  ["mix test", "success"],
  ["static analysis", "success"],
  ["demo PostgreSQL", "success"],
  ["package smoke", "success"],
  ["optional dependencies", "success"],
  ["CI contract", "success"]
];

function write(value) {
  process.stdout.write(JSON.stringify(value));
}

function run(status, conclusion, sha = "abc123") {
  return {
    databaseId: 42,
    workflowName: "CI",
    headSha: sha,
    status,
    conclusion,
    url: "https://github.test/run/42",
    attempt: 1,
    createdAt: "2026-06-24T00:00:00Z",
    updatedAt: "2026-06-24T00:01:00Z"
  };
}

function jobs(overrides = {}) {
  return requiredJobs.map(([name, conclusion], index) => ({
    name,
    status: "completed",
    conclusion: overrides[name] || conclusion,
    databaseId: 100 + index,
    url: "https://github.test/job/" + (100 + index)
  }));
}

if (args[0] === "run" && args[1] === "list") {
  if (scenario === "missing-run") write([]);
  else if (scenario === "wrong-sha") write([run("completed", "success", "def456")]);
  else if (scenario === "in-progress") write([run("in_progress", null)]);
  else write([run("completed", scenario === "failed-workflow" ? "failure" : "success")]);
  process.exit(0);
}

if (args[0] === "run" && args[1] === "view") {
  if (scenario === "failed-job") write({ ...run("completed", "success"), jobs: jobs({ "package smoke": "failure" }) });
  else if (scenario === "missing-job") write({ ...run("completed", "success"), jobs: jobs().filter((job) => job.name !== "CI contract") });
  else if (scenario === "failed-workflow") write({ ...run("completed", "failure"), jobs: jobs() });
  else write({ ...run("completed", "success"), jobs: jobs() });
  process.exit(0);
}

process.stderr.write("unexpected gh args: " + args.join(" "));
process.exit(1);
`,
  );
  writeFileSync(stateFile, "{}");
  chmodSync(fakeGh, 0o755);

  return {
    dir,
    env: {
      ...process.env,
      CI_MONITOR_GH_BIN: fakeGh,
      FAKE_GH_SCENARIO: scenario,
      FAKE_GH_STATE: stateFile,
    },
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}

function runMonitor(scenario, extraArgs = []) {
  const fake = makeFakeGh(scenario);
  try {
    return spawnSync(
      process.execPath,
      [script, "assert-ci", "--sha", "abc123", "--workflow", "CI", "--timeout", "0", "--poll", "0", "--json", ...extraArgs],
      {
        encoding: "utf8",
        env: fake.env,
      },
    );
  } finally {
    fake.cleanup();
  }
}

test("assert-ci exits 0 with exact SHA and all required jobs successful", () => {
  const result = runMonitor("success");
  assert.equal(result.status, 0);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.verified, true);
  assert.equal(evidence.sha, "abc123");
  assert.equal(evidence.jobs.length, 6);
});

test("assert-ci blocks when no pushed run exists for SHA", () => {
  const result = runMonitor("missing-run");
  assert.equal(result.status, 2);
  assert.equal(JSON.parse(result.stdout).reason, "no_ci_run_for_sha");
});

test("assert-ci ignores runs for the wrong SHA", () => {
  const result = runMonitor("wrong-sha");
  assert.equal(result.status, 2);
  assert.equal(JSON.parse(result.stdout).reason, "no_ci_run_for_sha");
});

test("assert-ci fails when workflow conclusion is not success", () => {
  const result = runMonitor("failed-workflow");
  assert.equal(result.status, 1);
  assert.equal(JSON.parse(result.stdout).reason, "workflow_not_successful");
});

test("assert-ci fails when a required job is missing", () => {
  const result = runMonitor("missing-job");
  assert.equal(result.status, 1);
  assert.equal(JSON.parse(result.stdout).reason, "required_job_missing");
});

test("assert-ci fails when a required job did not pass", () => {
  const result = runMonitor("failed-job");
  assert.equal(result.status, 1);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.reason, "required_job_not_successful");
  assert.deepEqual(evidence.failedJobs, ["package smoke"]);
});

test("assert-ci times out when the run is still in progress", () => {
  const result = runMonitor("in-progress");
  assert.equal(result.status, 124);
  assert.equal(JSON.parse(result.stdout).reason, "timeout");
});

test("ci workflow defines an always-running contract over required proof jobs", () => {
  const workflow = readFileSync(join(__dirname, "..", ".github", "workflows", "ci.yml"), "utf8");
  const contractIndex = workflow.indexOf("  ci-contract:");
  assert.notEqual(contractIndex, -1);

  const contract = workflow.slice(contractIndex);
  assert.match(contract, /name:\s+CI contract/);
  assert.match(contract, /if:\s+\$\{\{\s*always\(\)\s*\}\}/);

  for (const job of ["test", "dialyzer", "demo-postgres", "package-smoke", "optional-deps"]) {
    assert.match(contract, new RegExp(`- ${job}`));
  }
});
