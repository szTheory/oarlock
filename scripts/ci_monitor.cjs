#!/usr/bin/env node

const { spawnSync } = require("node:child_process");

const DEFAULT_REQUIRED_JOBS = [
  "mix test",
  "static analysis",
  "demo PostgreSQL",
  "package smoke",
  "optional dependencies",
  "CI contract",
];

function usage() {
  return `Usage:
  node scripts/ci_monitor.cjs assert-ci --sha <sha> [options]

Commands:
  assert-ci              Wait for and verify a GitHub Actions CI run.

Options:
  --workflow <name>      Workflow name or file name. Default: CI
  --repo <owner/repo>    GitHub repository. Default: inferred by gh
  --timeout <seconds>    Max wait time. Default: 1800
  --poll <seconds>       Poll interval. Default: 20
  --required-job <name>  Required job name. Can be repeated.
  --required-jobs <csv>  Comma-separated required job names.
  --json                 Print machine-readable JSON evidence.
  --help                 Show this help.

Exit codes:
  0    CI evidence verified
  1    CI run or a required job completed unsuccessfully
  2    Blocked: no pushed run, missing auth, or invalid usage
  124  Timed out waiting for CI
`;
}

function parseArgs(argv) {
  const args = { _: [], requiredJobs: [] };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--json") {
      args.json = true;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else if (arg.startsWith("--")) {
      const key = arg.slice(2);
      const value = argv[index + 1];
      if (!value || value.startsWith("--")) {
        throw new Error(`Missing value for ${arg}`);
      }
      index += 1;

      if (key === "required-job") {
        args.requiredJobs.push(value);
      } else if (key === "required-jobs") {
        args.requiredJobs.push(
          ...value
            .split(",")
            .map((job) => job.trim())
            .filter(Boolean),
        );
      } else {
        args[key] = value;
      }
    } else {
      args._.push(arg);
    }
  }

  return args;
}

function runGh(args, options = {}) {
  const ghBin = options.ghBin || process.env.CI_MONITOR_GH_BIN || "gh";
  const result = spawnSync(ghBin, args, {
    encoding: "utf8",
    env: options.env || process.env,
  });

  if (result.error) {
    throw new GhError(`Unable to execute ${ghBin}: ${result.error.message}`, {
      status: 2,
      stderr: result.error.message,
    });
  }

  if (result.status !== 0) {
    throw new GhError(result.stderr || result.stdout || "gh command failed", {
      status: 2,
      stderr: result.stderr,
      stdout: result.stdout,
      ghStatus: result.status,
    });
  }

  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new GhError(`gh returned invalid JSON: ${error.message}`, {
      status: 2,
      stdout: result.stdout,
    });
  }
}

class GhError extends Error {
  constructor(message, details = {}) {
    super(message);
    this.name = "GhError";
    this.details = details;
  }
}

function normalizeRun(run) {
  return {
    id: run.databaseId,
    workflowName: run.workflowName,
    headSha: run.headSha,
    status: run.status,
    conclusion: run.conclusion,
    url: run.url,
    attempt: run.attempt,
    createdAt: run.createdAt,
    updatedAt: run.updatedAt,
  };
}

function findRun({ sha, workflow, repo }, options = {}) {
  const args = [
    "run",
    "list",
    "--commit",
    sha,
    "--workflow",
    workflow,
    "--limit",
    "20",
    "--json",
    "databaseId,workflowName,headSha,status,conclusion,url,attempt,createdAt,updatedAt",
  ];

  if (repo) {
    args.push("--repo", repo);
  }

  const runs = runGh(args, options);
  return runs.find((run) => run.headSha === sha && run.workflowName === workflow) || null;
}

function viewRun({ runId, repo }, options = {}) {
  const args = [
    "run",
    "view",
    String(runId),
    "--json",
    "databaseId,workflowName,headSha,status,conclusion,url,jobs",
  ];

  if (repo) {
    args.push("--repo", repo);
  }

  return runGh(args, options);
}

function jobEvidence(jobs, requiredJobs) {
  const byName = new Map(jobs.map((job) => [job.name, job]));
  const required = requiredJobs.map((name) => {
    const job = byName.get(name);
    return {
      name,
      found: Boolean(job),
      status: job ? job.status : "missing",
      conclusion: job ? job.conclusion : "missing",
      databaseId: job ? job.databaseId : undefined,
      url: job ? job.url : undefined,
    };
  });

  return {
    required,
    missing: required.filter((job) => !job.found).map((job) => job.name),
    failed: required
      .filter((job) => job.found && (job.status !== "completed" || job.conclusion !== "success"))
      .map((job) => job.name),
  };
}

async function assertCi(args, options = {}) {
  const sha = args.sha;
  if (!sha) {
    return {
      exitCode: 2,
      evidence: {
        verified: false,
        reason: "missing_sha",
        message: "Pass --sha <commit-sha>.",
      },
    };
  }

  const workflow = args.workflow || "CI";
  const requiredJobs = args.requiredJobs.length > 0 ? args.requiredJobs : DEFAULT_REQUIRED_JOBS;
  const timeoutSeconds = Number(args.timeout ?? 1800);
  const pollSeconds = Number(args.poll ?? 20);
  const repo = args.repo;
  const start = Date.now();
  let lastEvidence = null;
  let attempted = false;

  while (!attempted || Date.now() - start <= timeoutSeconds * 1000) {
    attempted = true;
    let run;
    try {
      run = findRun({ sha, workflow, repo }, options);
    } catch (error) {
      return {
        exitCode: 2,
        evidence: {
          verified: false,
          reason: "gh_error",
          message: error.message,
          details: error.details || {},
        },
      };
    }

    if (!run) {
      return {
        exitCode: 2,
        evidence: {
          verified: false,
          reason: "no_ci_run_for_sha",
          workflow,
          sha,
        },
      };
    }

    const normalizedRun = normalizeRun(run);

    if (run.status !== "completed") {
      lastEvidence = {
        verified: false,
        reason: "ci_in_progress",
        run: normalizedRun,
      };

      if (pollSeconds <= 0) {
        break;
      }
      await sleep(pollSeconds * 1000);
      continue;
    }

    const viewed = viewRun({ runId: run.databaseId, repo }, options);
    const jobs = Array.isArray(viewed.jobs) ? viewed.jobs : [];
    const jobsEvidence = jobEvidence(jobs, requiredJobs);
    const runConclusion = viewed.conclusion || run.conclusion;

    const evidence = {
      verified:
        runConclusion === "success" &&
        jobsEvidence.missing.length === 0 &&
        jobsEvidence.failed.length === 0,
      workflow,
      sha,
      run: normalizeRun({ ...run, ...viewed }),
      jobs: jobsEvidence.required,
    };

    if (!evidence.verified) {
      return {
        exitCode: 1,
        evidence: {
          ...evidence,
          reason:
            runConclusion !== "success"
              ? "workflow_not_successful"
              : jobsEvidence.missing.length > 0
                ? "required_job_missing"
                : "required_job_not_successful",
          missingJobs: jobsEvidence.missing,
          failedJobs: jobsEvidence.failed,
        },
      };
    }

    return { exitCode: 0, evidence };
  }

  return {
    exitCode: 124,
    evidence: {
      verified: false,
      reason: "timeout",
      workflow,
      sha,
      lastEvidence,
    },
  };
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function printEvidence(evidence, asJson) {
  if (asJson) {
    console.log(JSON.stringify(evidence, null, 2));
    return;
  }

  if (evidence.verified) {
    console.log(`CI verified for ${evidence.sha}: ${evidence.run.url}`);
    return;
  }

  console.error(`CI verification failed: ${evidence.reason}`);
  if (evidence.message) {
    console.error(evidence.message);
  }
}

async function main(argv = process.argv.slice(2), options = {}) {
  let args;
  try {
    args = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage());
    return 2;
  }

  if (args.help || args._.length === 0) {
    console.log(usage());
    return 0;
  }

  const command = args._[0];
  if (command !== "assert-ci") {
    console.error(`Unknown command: ${command}`);
    console.error(usage());
    return 2;
  }

  const { exitCode, evidence } = await assertCi(args, options);
  printEvidence(evidence, args.json);
  return exitCode;
}

if (require.main === module) {
  main().then((exitCode) => {
    process.exitCode = exitCode;
  });
}

module.exports = {
  DEFAULT_REQUIRED_JOBS,
  assertCi,
  jobEvidence,
  main,
  parseArgs,
};
