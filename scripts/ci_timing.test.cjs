const assert = require("node:assert/strict");
const { mkdtempSync, writeFileSync, chmodSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join } = require("node:path");
const test = require("node:test");
const { DEFAULT_REQUIRED_JOBS, observe, summarizeRun } = require("./ci_timing.cjs");

const SHA = "a".repeat(40);

function makeRun(overrides = {}) {
  const jobs = DEFAULT_REQUIRED_JOBS.map((name, index) => {
    const startMinute = name === "CI contract" ? 8 : 1;
    const durationMinutes = name === "CI contract" ? 1 : index + 1;
    return {
      name,
      status: "completed",
      conclusion: "success",
      startedAt: `2026-09-24T00:${String(startMinute).padStart(2, "0")}:00Z`,
      completedAt: `2026-09-24T00:${String(startMinute + durationMinutes).padStart(2, "0")}:00Z`,
    };
  });
  return {
    databaseId: 42,
    workflowName: "CI",
    headSha: SHA,
    status: "completed",
    conclusion: "success",
    url: "https://github.test/run/42",
    attempt: 1,
    createdAt: "2026-09-24T00:00:00Z",
    jobs,
    ...overrides,
  };
}

function withFakeGh(scenario, callback) {
  const dir = mkdtempSync(join(tmpdir(), "ci-timing-"));
  const fakeGh = join(dir, "gh");
  writeFileSync(fakeGh, `#!/usr/bin/env node
const scenario = process.env.FAKE_GH_SCENARIO;
const args = process.argv.slice(2);
if (scenario === "gh-error") { process.stderr.write("DNS unavailable"); process.exit(1); }
if (args[0] === "run" && args[1] === "list") {
  const rows = scenario === "missing" ? [] : [{ databaseId: 42, headSha: scenario === "wrong-sha" ? "b".repeat(40) : process.env.CI_TIMING_TEST_SHA }];
  process.stdout.write(JSON.stringify(rows));
} else if (args[0] === "run" && args[1] === "view") {
  const run = JSON.parse(process.env.CI_TIMING_FIXTURE);
  process.stdout.write(JSON.stringify(run));
} else { process.stderr.write("unexpected gh args"); process.exit(1); }
`);
  chmodSync(fakeGh, 0o755);
  try {
    return callback({
      ghBin: fakeGh,
      env: { ...process.env, FAKE_GH_SCENARIO: scenario, CI_TIMING_TEST_SHA: SHA, CI_TIMING_FIXTURE: JSON.stringify(makeRun()) },
    });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("fixed job timestamps produce queue, per-job, aggregate, critical path, and runner-minute totals", () => {
  const result = summarizeRun(makeRun());
  assert.equal(result.observed, true);
  assert.equal(result.queueMs, 60_000);
  assert.equal(result.aggregateElapsedMs, 9 * 60_000);
  assert.equal(result.workflowRuntimeMs, 8 * 60_000);
  assert.equal(result.criticalPathMs, 8 * 60_000);
  assert.equal(result.runnerMinutes, 29);
  assert.deepEqual(result.jobs.map((job) => job.durationMs / 60_000), [1, 2, 3, 4, 5, 6, 7, 1]);
});

test("missing jobs and incomplete or reversed timestamps remain unmeasured", () => {
  const missingJob = makeRun({ jobs: makeRun().jobs.slice(1) });
  const missing = summarizeRun(missingJob);
  assert.equal(missing.observed, false);
  assert.equal(missing.reason, "required_job_missing");
  assert.equal(missing.aggregateElapsedMs, null);

  for (const job of [
    { ...makeRun().jobs[0], startedAt: undefined },
    { ...makeRun().jobs[0], startedAt: "2026-09-24T00:03:00Z", completedAt: "2026-09-24T00:02:00Z" },
  ]) {
    const result = summarizeRun(makeRun({ jobs: [job, ...makeRun().jobs.slice(1)] }));
    assert.equal(result.observed, false);
    assert.equal(result.reason, "job_timestamps_unmeasured");
    assert.equal(result.jobs[0].durationMs, null);
  }
});

test("a successful aggregate cannot mask a failed or skipped required lane", () => {
  for (const conclusion of ["failure", "skipped"]) {
    const jobs = makeRun().jobs;
    jobs[0] = { ...jobs[0], conclusion };
    const result = summarizeRun(makeRun({ jobs }));
    assert.equal(result.observed, false);
    assert.equal(result.reason, "required_job_not_successful");
    assert.equal(result.aggregateElapsedMs, null);
  }
});

test("exact SHA observation rejects missing, mismatched, and unavailable GitHub runs", () => {
  withFakeGh("missing", (options) => {
    const result = observe({ sha: SHA }, options);
    assert.equal(result.reason, "no_ci_run_for_sha");
    assert.equal(result.runnerMinutes, null);
  });
  withFakeGh("wrong-sha", (options) => {
    const result = observe({ sha: SHA }, options);
    assert.equal(result.reason, "no_ci_run_for_sha");
  });
  withFakeGh("gh-error", (options) => {
    const result = observe({ sha: SHA }, options);
    assert.equal(result.reason, "gh_error");
    assert.match(result.message, /DNS unavailable/);
  });
});

test("exact completed successful run with required timestamps is summarized", () => {
  withFakeGh("success", (options) => {
    const result = observe({ sha: SHA, workflow: "CI" }, options);
    assert.equal(result.observed, true);
    assert.equal(result.run.id, 42);
    assert.equal(result.sha, SHA);
    assert.equal(result.criticalPathMs, 8 * 60_000);
  });
});
