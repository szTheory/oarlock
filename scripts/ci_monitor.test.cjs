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
  ["planning truth", "success"],
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
  if (scenario === "hung") Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0);
  if (scenario === "missing-run") write([]);
  else if (scenario === "wrong-sha") write([run("completed", "success", "def456")]);
  else if (scenario === "in-progress") write([run("in_progress", null)]);
  else write([run("completed", scenario === "failed-workflow" ? "failure" : "success")]);
  process.exit(0);
}

if (args[0] === "run" && args[1] === "view") {
  if (scenario === "view-error") {
    process.stderr.write("view unavailable");
    process.exit(1);
  } else if (scenario === "failed-job") write({ ...run("completed", "success"), jobs: jobs({ "package smoke": "failure" }) });
  else if (scenario === "failed-planning-truth") write({ ...run("completed", "success"), jobs: jobs({ "planning truth": "failure" }) });
  else if (scenario === "missing-planning-truth") write({ ...run("completed", "success"), jobs: jobs().filter((job) => job.name !== "planning truth") });
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

function runMonitor(scenario, extraArgs = [], asJson = true) {
  const fake = makeFakeGh(scenario);
  try {
    return spawnSync(
      process.execPath,
      [script, "assert-ci", "--sha", "abc123", "--workflow", "CI", "--timeout", "5", "--poll", "0", ...(asJson ? ["--json"] : []), ...extraArgs],
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
  assert.equal(evidence.jobs.length, 7);
});

test("assert-ci accepts a workflow file selector when GitHub returns its display name", () => {
  const result = runMonitor("success", ["--workflow", "ci.yml"]);
  assert.equal(result.status, 0);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.workflow, "ci.yml");
  assert.equal(evidence.run.workflowName, "CI");
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

test("assert-ci fails when planning truth is missing for the exact SHA", () => {
  const result = runMonitor("missing-planning-truth");
  assert.equal(result.status, 1);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.reason, "required_job_missing");
  assert.deepEqual(evidence.missingJobs, ["planning truth"]);
});

test("assert-ci fails when planning truth failed for the exact SHA", () => {
  const result = runMonitor("failed-planning-truth");
  assert.equal(result.status, 1);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.reason, "required_job_not_successful");
  assert.deepEqual(evidence.failedJobs, ["planning truth"]);
});

test("assert-ci reports completed-run lookup errors as blocked evidence", () => {
  const jsonResult = runMonitor("view-error");
  assert.equal(jsonResult.status, 2);
  assert.equal(JSON.parse(jsonResult.stdout).reason, "gh_error");
  assert.match(JSON.parse(jsonResult.stdout).message, /view unavailable/);

  const humanResult = runMonitor("view-error", [], false);
  assert.equal(humanResult.status, 2);
  assert.match(humanResult.stderr, /CI verification failed: gh_error/);
  assert.match(humanResult.stderr, /view unavailable/);
  assert.doesNotMatch(humanResult.stderr, /\n\s+at /);
});

test("assert-ci rejects non-finite, negative, and excessive timing options", () => {
  for (const args of [
    ["--timeout", "NaN"],
    ["--timeout", "Infinity"],
    ["--timeout", "-1"],
    ["--poll", "NaN"],
    ["--poll", "Infinity"],
    ["--poll", "-1"],
    ["--poll", "3601"],
  ]) {
    const result = runMonitor("success", args);
    assert.equal(result.status, 2, args.join(" "));
    assert.equal(JSON.parse(result.stdout).reason, "invalid_usage", args.join(" "));
  }
});

test("assert-ci times out when the run is still in progress", () => {
  const started = Date.now();
  const result = runMonitor("in-progress", ["--timeout", "0.5", "--poll", "3600"]);
  assert.equal(result.status, 124);
  assert.equal(JSON.parse(result.stdout).reason, "timeout");
  assert.ok(Date.now() - started < 1500, "sleep must not exceed the remaining deadline");
});

test("assert-ci bounds a hung gh subprocess by the remaining deadline", () => {
  const started = Date.now();
  const result = runMonitor("hung", ["--timeout", "0.1"]);
  assert.equal(result.status, 2);
  const evidence = JSON.parse(result.stdout);
  assert.equal(evidence.reason, "gh_error");
  assert.equal(evidence.details.timedOut, true);
  assert.ok(evidence.details.timeoutMs <= 100);
  assert.ok(Date.now() - started < 1000, "hung gh must be terminated by the deadline");
});

test("ci workflow defines an always-running contract over required proof jobs", () => {
  const workflow = readFileSync(join(__dirname, "..", ".github", "workflows", "ci.yml"), "utf8");
  const contractIndex = workflow.indexOf("  ci-contract:");
  assert.notEqual(contractIndex, -1);

  const contract = workflow.slice(contractIndex);
  assert.match(contract, /name:\s+CI contract/);
  assert.match(contract, /if:\s+\$\{\{\s*always\(\)\s*\}\}/);

  for (const job of ["test", "dialyzer", "demo-postgres", "package-smoke", "optional-deps", "planning-truth"]) {
    assert.match(contract, new RegExp(`- ${job}`));
  }
  assert.match(contract, /const required = \[[^\]]*"planning-truth"[^\]]*\]/s);
  assert.match(contract, /sha:\s*process\.env\.GITHUB_SHA_VALUE/);
  assert.match(contract, /required_jobs:\s*jobs/);
});

test("ci workflow defines the exact required planning-truth lane", () => {
  const workflow = readFileSync(join(__dirname, "..", ".github", "workflows", "ci.yml"), "utf8");
  const start = workflow.indexOf("  planning-truth:");
  const end = workflow.indexOf("\n  ci-contract:", start);
  assert.notEqual(start, -1, "planning-truth job id is required");
  assert.notEqual(end, -1, "planning-truth must be a separate job before the aggregate");
  const lane = workflow.slice(start, end);

  assert.match(workflow, /permissions:\s*\n\s+contents:\s+read/);
  assert.match(lane, /name:\s+planning truth/);
  assert.match(lane, /fetch-depth:\s+0/);
  assert.match(lane, /spawnSync\("git"/);
  assert.match(lane, /run\(\["fetch"/);
  assert.match(lane, /refs\/tags\/\*:refs\/tags\/\*/);
  assert.match(lane, /v1\.1/);
  assert.match(lane, /v1\.2/);
  assert.match(lane, /v1\.3/);
  assert.match(lane, /v1\.4/);
  assert.match(lane, /v2\.0/);
  assert.match(lane, /v2\.1/);
  assert.match(lane, /v1\.5/);
  assert.match(lane, /merge-base/);
  assert.match(lane, /github\.event\.before/);
  assert.match(lane, /node --test scripts\/\*\.test\.cjs scripts\/prohibitions\/\*\.test\.cjs/);
  assert.match(lane, /node scripts\/prohibitions\/enforce_phase31\.cjs/);
  assert.match(lane, /node scripts\/history_integrity\.cjs.*--base.*--head/s);
  assert.match(lane, /node scripts\/planning_health\.cjs --json/);
});
