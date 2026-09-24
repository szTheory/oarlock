#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const { DEFAULT_REQUIRED_JOBS } = require("./ci_monitor.cjs");

const SHA_PATTERN = /^(?:[a-f0-9]{40}|[a-f0-9]{64})$/i;

function parseArgs(argv) {
  const args = { _: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--json") {
      args.json = true;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else if (arg.startsWith("--")) {
      const key = arg.slice(2);
      const value = argv[index + 1];
      if (!value || value.startsWith("--")) throw new Error(`Missing value for ${arg}`);
      args[key] = value;
      index += 1;
    } else {
      args._.push(arg);
    }
  }
  return args;
}

function ghJson(args, options = {}) {
  const result = spawnSync(options.ghBin || process.env.CI_TIMING_GH_BIN || "gh", args, {
    encoding: "utf8",
    env: options.env || process.env,
    timeout: options.timeoutMs || 15_000,
    maxBuffer: 2 * 1024 * 1024,
  });
  if (result.error) throw new Error(`Unable to observe GitHub timing data: ${result.error.message}`);
  if (result.status !== 0) {
    throw new Error(`Unable to observe GitHub timing data: ${result.stderr || result.stdout || "gh failed"}`);
  }
  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new Error(`GitHub returned invalid timing JSON: ${error.message}`);
  }
}

function viewRun(runId, repo, options = {}) {
  const args = [
    "run", "view", String(runId), "--json",
    "databaseId,workflowName,headSha,status,conclusion,url,attempt,createdAt,jobs",
  ];
  if (repo) args.push("--repo", repo);
  return ghJson(args, options);
}

function findRun({ sha, workflow, repo }, options = {}) {
  const args = [
    "run", "list", "--commit", sha, "--workflow", workflow, "--limit", "20",
    "--json", "databaseId,workflowName,headSha,status,conclusion,url,attempt,createdAt",
  ];
  if (repo) args.push("--repo", repo);
  const runs = ghJson(args, options);
  return runs.find((run) => run.headSha?.toLowerCase() === sha.toLowerCase()) || null;
}

function parseTime(value) {
  if (typeof value !== "string") return null;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function unmeasured(reason, jobs = []) {
  return {
    observed: false,
    measured: false,
    reason,
    queueMs: null,
    aggregateElapsedMs: null,
    criticalPathMs: null,
    runnerMinutes: null,
    jobs,
  };
}

function summarizeRun(run, requiredJobs = DEFAULT_REQUIRED_JOBS) {
  const timestamps = [];
  const jobsByName = new Map();
  for (const job of run.jobs || []) {
    if (jobsByName.has(job.name)) return unmeasured("duplicate_required_job", []);
    jobsByName.set(job.name, job);
  }

  const records = [];
  for (const name of requiredJobs) {
    const job = jobsByName.get(name);
    if (!job) return unmeasured("required_job_missing", [...records, { name, measured: false }]);
    if (job.status !== "completed" || job.conclusion !== "success") {
      return unmeasured("required_job_not_successful", [...records, { name, status: job.status, conclusion: job.conclusion, measured: false, durationMs: null }]);
    }

    const started = parseTime(job.startedAt);
    const completed = parseTime(job.completedAt);
    if (started === null || completed === null || completed <= started) {
      return unmeasured("job_timestamps_unmeasured", [
        ...records,
        { name, status: job.status, conclusion: job.conclusion, measured: false, durationMs: null },
      ]);
    }

    const record = {
      name,
      status: job.status,
      conclusion: job.conclusion,
      startedAt: job.startedAt,
      completedAt: job.completedAt,
      measured: true,
      durationMs: completed - started,
    };
    records.push(record);
    timestamps.push({ name, started, completed });
  }

  const created = parseTime(run.createdAt);
  const firstStart = Math.min(...timestamps.map((item) => item.started));
  const lastComplete = Math.max(...timestamps.map((item) => item.completed));
  const aggregate = timestamps.find((item) => item.name === "CI contract");
  if (created === null || firstStart < created || !aggregate) {
    return unmeasured("workflow_timestamps_unmeasured", records);
  }

  const dependencies = timestamps.filter((item) => item.name !== "CI contract");
  const latestDependency = Math.max(...dependencies.map((item) => item.completed));
  if (aggregate.started < latestDependency || aggregate.completed !== lastComplete) {
    return unmeasured("aggregate_timing_inconsistent", records);
  }

  return {
    observed: true,
    measured: true,
    reason: null,
    queueMs: firstStart - created,
    aggregateElapsedMs: lastComplete - created,
    workflowRuntimeMs: lastComplete - firstStart,
    criticalPathMs: aggregate.completed - firstStart,
    runnerMinutes: records.reduce((sum, job) => sum + job.durationMs, 0) / 60_000,
    jobs: records,
  };
}

function observe({ sha, runId, workflow = "CI", repo }, options = {}) {
  if (!sha || !SHA_PATTERN.test(sha)) {
    return { ...unmeasured("invalid_sha"), message: "Pass a full 40- or 64-character SHA." };
  }

  try {
    const listed = runId ? { databaseId: Number(runId), headSha: sha } : findRun({ sha, workflow, repo }, options);
    if (!listed) return { ...unmeasured("no_ci_run_for_sha"), sha };
    if (listed.headSha?.toLowerCase() !== sha.toLowerCase()) {
      return { ...unmeasured("run_sha_mismatch"), sha };
    }

    const run = viewRun(listed.databaseId, repo, options);
    if (run.headSha?.toLowerCase() !== sha.toLowerCase()) {
      return { ...unmeasured("run_sha_mismatch"), sha, runId: run.databaseId };
    }
    if (run.status !== "completed" || run.conclusion !== "success") {
      return { ...unmeasured("run_not_successful"), sha, runId: run.databaseId, conclusion: run.conclusion };
    }

    const timing = summarizeRun(run);
    return {
      ...timing,
      sha: run.headSha,
      run: {
        id: run.databaseId,
        attempt: run.attempt,
        workflow: run.workflowName,
        url: run.url,
        createdAt: run.createdAt,
        conclusion: run.conclusion,
      },
    };
  } catch (error) {
    return { ...unmeasured("gh_error"), sha, message: error.message };
  }
}

function usage() {
  return "Usage: node scripts/ci_timing.cjs --sha <exact-sha> [--run-id <id>] [--workflow CI] [--repo owner/repo] [--json]";
}

function main(argv = process.argv.slice(2), options = {}) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 2;
  }
  if (args.help) {
    console.log(usage());
    return 0;
  }

  const evidence = observe({
    sha: args.sha,
    runId: args["run-id"],
    workflow: args.workflow || "CI",
    repo: args.repo,
  }, options);
  console.log(JSON.stringify(evidence, null, 2));
  return evidence.observed ? 0 : 2;
}

if (require.main === module) process.exitCode = main();

module.exports = { DEFAULT_REQUIRED_JOBS, findRun, main, observe, parseArgs, summarizeRun };
