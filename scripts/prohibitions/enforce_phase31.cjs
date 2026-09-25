#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const EXPECTED_IDS = Object.freeze([
  "PROHIB-REPO-01-SAFETY",
  "PROHIB-REPO-01-TRANSPARENCY",
  "PROHIB-REPO-02-TRANSPARENCY",
  "PROHIB-REPO-04-SAFETY",
  "PROHIB-REPO-03-PRESERVATION",
  "PROHIB-REPO-03-IDENTITY",
]);

const DEFAULT_PLAN_PATHS = Object.freeze([
  ".planning/phases/31-repository-planning-truth/31-01-PLAN.md",
  ".planning/phases/31-repository-planning-truth/31-02-PLAN.md",
  ".planning/phases/31-repository-planning-truth/31-03-PLAN.md",
]);

const REQUIRED_FIELDS = Object.freeze([
  "status",
  "verification",
  "flagged_unverified",
  "check_kind",
  "check_target",
  "check_violation_fixture",
  "check_clean_fixture",
]);

const PATH_FIELDS = Object.freeze([
  "check_target",
  "check_violation_fixture",
  "check_clean_fixture",
]);

const MAX_PLAN_BYTES = 1024 * 1024;
const MAX_TAP_BYTES = 4 * 1024 * 1024;
const TEST_TIMEOUT_MS = 30_000;

class EnforcementError extends Error {
  constructor(message, details = {}) {
    super(message);
    this.name = "EnforcementError";
    this.details = details;
  }
}

function resolveRegularFile(root, requested, field) {
  if (typeof requested !== "string" || requested.length === 0 || path.isAbsolute(requested)) {
    throw new EnforcementError(`${field} must be a non-empty repository-relative path`);
  }
  const rootReal = fs.realpathSync(root);
  const candidate = path.resolve(rootReal, requested);
  if (candidate !== rootReal && !candidate.startsWith(`${rootReal}${path.sep}`)) {
    throw new EnforcementError(`${field} escapes the repository: ${requested}`);
  }
  let real;
  try {
    real = fs.realpathSync(candidate);
  } catch (error) {
    throw new EnforcementError(`${field} does not exist: ${requested}`, { cause: error.code });
  }
  if (real !== rootReal && !real.startsWith(`${rootReal}${path.sep}`)) {
    throw new EnforcementError(`${field} resolves outside the repository: ${requested}`);
  }
  if (!fs.statSync(real).isFile()) {
    throw new EnforcementError(`${field} is not a regular file: ${requested}`);
  }
  return real;
}

function readBounded(root, requested) {
  const absolute = resolveRegularFile(root, requested, "plan path");
  const stat = fs.statSync(absolute);
  if (stat.size > MAX_PLAN_BYTES) {
    throw new EnforcementError(`plan path exceeds ${MAX_PLAN_BYTES} bytes: ${requested}`);
  }
  return fs.readFileSync(absolute, "utf8");
}

function parseDescriptors(markdown, source) {
  const descriptors = [];
  let inProhibitions = false;
  let current = null;

  for (const line of markdown.split(/\r?\n/)) {
    if (!inProhibitions) {
      if (line === "  prohibitions:") inProhibitions = true;
      continue;
    }
    if (line === "---" || (/^  [a-z_][a-z0-9_]*:\s*$/.test(line) && line !== "  prohibitions:")) break;

    const idMatch = line.match(/^    - id:\s*(\S+)\s*$/);
    if (idMatch) {
      current = { id: idMatch[1], source };
      descriptors.push(current);
      continue;
    }
    const fieldMatch = line.match(/^      ([a-z_]+):\s*(.*?)\s*$/);
    if (fieldMatch && current) current[fieldMatch[1]] = fieldMatch[2].replace(/^(["'])(.*)\1$/, "$2");
  }

  if (!inProhibitions) throw new EnforcementError(`prohibitions block missing from ${source}`);
  return descriptors;
}

function loadDescriptors(options = {}) {
  const root = path.resolve(options.root || path.resolve(__dirname, "../.."));
  const planPaths = options.planPaths || DEFAULT_PLAN_PATHS;
  const descriptors = planPaths.flatMap((planPath) => parseDescriptors(readBounded(root, planPath), planPath));
  const byId = new Map();

  for (const descriptor of descriptors) {
    if (byId.has(descriptor.id)) throw new EnforcementError(`duplicate prohibition descriptor: ${descriptor.id}`);
    byId.set(descriptor.id, descriptor);
  }

  const missing = EXPECTED_IDS.filter((id) => !byId.has(id));
  const unexpected = [...byId.keys()].filter((id) => !EXPECTED_IDS.includes(id));
  if (missing.length > 0) throw new EnforcementError(`missing stable prohibition descriptors: ${missing.join(", ")}`);
  if (unexpected.length > 0) throw new EnforcementError(`unexpected prohibition descriptors: ${unexpected.join(", ")}`);

  return EXPECTED_IDS.map((id) => {
    const descriptor = byId.get(id);
    for (const field of REQUIRED_FIELDS) {
      if (!Object.hasOwn(descriptor, field) || descriptor[field] === "") {
        throw new EnforcementError(`${id} is missing ${field}`);
      }
    }
    if (descriptor.status !== "resolved") throw new EnforcementError(`${id} status must be resolved`);
    if (descriptor.verification !== "test") throw new EnforcementError(`${id} verification must be test`);
    if (descriptor.flagged_unverified !== "false") throw new EnforcementError(`${id} flagged_unverified must be false`);
    if (descriptor.check_kind !== "node-test") throw new EnforcementError(`${id} check_kind must be node-test`);

    const resolved = { ...descriptor };
    for (const field of PATH_FIELDS) resolved[`${field}_absolute`] = resolveRegularFile(root, descriptor[field], field);
    return resolved;
  });
}

function tapCount(output, name) {
  const match = output.match(new RegExp(`^# ${name} (\\d+)\\s*$`, "m"));
  return match ? Number(match[1]) : null;
}

function evaluateTapRun(result, id, mode) {
  const stdout = typeof result.stdout === "string" ? result.stdout : Buffer.from(result.stdout || "").toString("utf8");
  const tests = tapCount(stdout, "tests");
  const pass = tapCount(stdout, "pass");
  const fail = tapCount(stdout, "fail");
  const escapedId = id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const namedFailure = new RegExp(`^\\s*not ok \\d+ - .*${escapedId}`, "m").test(stdout);
  const namedPass = new RegExp(`^\\s*ok \\d+ - .*${escapedId}`, "m").test(stdout);

  if (result.error || result.signal) {
    throw new EnforcementError(`${id} ${mode} fixture subprocess failed before a valid TAP result`);
  }
  if (mode === "bad") {
    if (result.status === 0) throw new EnforcementError(`${id} violation fixture stayed green`);
    if (!(tests > 0 && fail > 0 && namedFailure)) {
      throw new EnforcementError(`${id} bad fixture did not produce a non-vacuous named TAP failure`);
    }
  } else if (!(result.status === 0 && tests > 0 && pass > 0 && fail === 0 && namedPass)) {
    throw new EnforcementError(`${id} clean fixture did not produce non-vacuous named TAP success`);
  }

  return { status: result.status, tests, pass, fail, namedFailure, namedPass };
}

function runDescriptor(descriptor, root, runner) {
  function invoke(subject, mode) {
    const result = runner(process.execPath, ["--test", descriptor.check_target_absolute], {
      cwd: root,
      encoding: "utf8",
      env: { ...process.env, GSD_PROHIB_SUBJECT: subject },
      maxBuffer: MAX_TAP_BYTES,
      timeout: TEST_TIMEOUT_MS,
      shell: false,
    });
    return evaluateTapRun(result, descriptor.id, mode);
  }

  return {
    id: descriptor.id,
    bad: invoke(descriptor.check_violation_fixture_absolute, "bad"),
    clean: invoke(descriptor.check_clean_fixture_absolute, "clean"),
  };
}

function runEnforcement(options = {}) {
  const root = path.resolve(options.root || path.resolve(__dirname, "../.."));
  const descriptors = loadDescriptors({ root, planPaths: options.planPaths });
  const runner = options.runner || spawnSync;
  const proofs = descriptors.map((descriptor) => runDescriptor(descriptor, root, runner));
  return { descriptors, proofs };
}

function main() {
  try {
    const result = runEnforcement();
    for (const proof of result.proofs) {
      process.stdout.write(`${proof.id}: bad fixture named TAP red; clean fixture named TAP green\n`);
    }
    process.stdout.write(`Phase 31 prohibition enforcement passed (${result.proofs.length}/${EXPECTED_IDS.length}).\n`);
    return 0;
  } catch (error) {
    process.stderr.write(`Phase 31 prohibition enforcement failed: ${error.message}\n`);
    return 1;
  }
}

if (require.main === module) process.exitCode = main();

module.exports = {
  DEFAULT_PLAN_PATHS,
  EXPECTED_IDS,
  EnforcementError,
  evaluateTapRun,
  loadDescriptors,
  main,
  parseDescriptors,
  runEnforcement,
};
