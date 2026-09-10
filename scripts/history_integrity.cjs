#!/usr/bin/env node
"use strict";

const { spawnSync } = require("node:child_process");

const MAX_BUFFER = 4 * 1024 * 1024;
const TIMEOUT_MS = 15_000;
const ARCHIVE_PREFIX = ".planning/milestones/";
const EVIDENCE_PATH = ".planning/EVIDENCE.md";

class ObservationError extends Error {}

function git(args, options = {}) {
  const result = (options.runner || spawnSync)(options.gitBinary || "git", args, {
    cwd: options.cwd || process.cwd(),
    encoding: null,
    env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
    shell: false,
    windowsHide: true,
    maxBuffer: options.maxBuffer || MAX_BUFFER,
    timeout: options.timeout || TIMEOUT_MS,
  });
  if (result.error || result.status !== 0) {
    const cause = result.error
      ? result.error.message
      : Buffer.from(result.stderr || []).toString("utf8").trim() || `git exited ${result.status}`;
    throw new ObservationError(`git ${args.join(" ")} failed: ${cause}`);
  }
  return Buffer.isBuffer(result.stdout) ? result.stdout : Buffer.from(result.stdout || "");
}

function resolveRevision(revision, options) {
  if (!revision || revision.includes("\0")) throw new ObservationError("base and head revisions are required");
  return git(["rev-parse", "--verify", `${revision}^{commit}`], options).toString("utf8").trim();
}

function assertCompleteHistory(options) {
  const shallow = git(["rev-parse", "--is-shallow-repository"], options).toString("utf8").trim();
  if (shallow !== "false") throw new ObservationError("shallow repository cannot provide complete base/head evidence");
}

function listArchivePaths(revision, options) {
  return git(["ls-tree", "-r", "-z", "--name-only", revision, "--", ARCHIVE_PREFIX], options)
    .toString("utf8").split("\0").filter(Boolean).sort();
}

function readObject(revision, artifact, options, required = true) {
  try {
    return git(["show", `${revision}:${artifact}`], options);
  } catch (error) {
    if (!required) return null;
    throw error;
  }
}

function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
}

function validCorrectionRow(line) {
  if (!/^\s*\|.*\|\s*$/.test(line)) return false;
  const cells = line.split("|").slice(1, -1).map((cell) => cell.trim());
  return cells.length >= 7
    && validDate(cells[0])
    && /^v\S+$/.test(cells[1])
    && cells.slice(2).every((cell) => cell.length > 0)
    && cells.slice(2).some((cell) => /\b(?:correction|erratum)\b/i.test(cell));
}

function compareEvidence(baseContent, headContent) {
  if (!headContent.subarray(0, baseContent.length).equals(baseContent)) {
    return { valid: false, additions: [], reason: "base ledger bytes are missing, modified, or reordered" };
  }

  let suffix = headContent.subarray(baseContent.length).toString("utf8");
  if (suffix.length > 0 && baseContent.length > 0 && baseContent[baseContent.length - 1] !== 0x0a) {
    if (!suffix.startsWith("\n")) {
      return { valid: false, additions: [], reason: "appended ledger content does not begin at a newline boundary" };
    }
    suffix = suffix.slice(1);
  }
  const additions = suffix.split("\n");
  if (additions.at(-1) === "") additions.pop();
  const invalid = additions.filter((line) => !validCorrectionRow(line));
  if (invalid.length > 0) return { valid: false, additions, reason: "added ledger content is not a valid dated correction row" };
  return { valid: true, additions, reason: null };
}

function inspectHistory(baseRevision, headRevision, options = {}) {
  const result = { status: "healthy", base: null, head: null, violations: [], additions: [] };
  try {
    assertCompleteHistory(options);
    result.base = resolveRevision(baseRevision, options);
    result.head = resolveRevision(headRevision, options);
    git(["merge-base", "--is-ancestor", result.base, result.head], options);

    const basePaths = listArchivePaths(result.base, options);
    const headPaths = new Set(listArchivePaths(result.head, options));
    for (const artifact of basePaths) {
      const before = readObject(result.base, artifact, options);
      const after = headPaths.has(artifact) ? readObject(result.head, artifact, options) : null;
      if (!after || !before.equals(after)) {
        result.violations.push({
          code: "HIST_FROZEN_ARCHIVE_CHANGED",
          artifact,
          change: after ? "modified" : "deleted-or-renamed",
        });
      }
    }
    result.additions = [...headPaths].filter((artifact) => !basePaths.includes(artifact)).sort();

    const baseEvidence = readObject(result.base, EVIDENCE_PATH, options, false);
    const headEvidence = readObject(result.head, EVIDENCE_PATH, options, false);
    if (baseEvidence && !headEvidence) {
      result.violations.push({ code: "HIST_EVIDENCE_NOT_APPEND_ONLY", artifact: EVIDENCE_PATH, change: "deleted" });
    } else if (baseEvidence && headEvidence) {
      const comparison = compareEvidence(baseEvidence, headEvidence);
      if (!comparison.valid) result.violations.push({
        code: "HIST_EVIDENCE_NOT_APPEND_ONLY", artifact: EVIDENCE_PATH, change: "rewritten", reason: comparison.reason,
      });
    } else if (!baseEvidence && headEvidence) {
      const initial = compareEvidence(Buffer.alloc(0), headEvidence);
      if (!initial.valid) result.violations.push({
        code: "HIST_EVIDENCE_NOT_APPEND_ONLY", artifact: EVIDENCE_PATH, change: "invalid-new-ledger", reason: initial.reason,
      });
    }
  } catch (error) {
    result.status = "incomplete";
    result.error = error instanceof ObservationError ? error.message : `history observation failed: ${error.message}`;
    return result;
  }
  if (result.violations.length > 0) result.status = "violated";
  result.violations.sort((left, right) => left.artifact.localeCompare(right.artifact) || left.code.localeCompare(right.code));
  return result;
}

function parseArguments(argv) {
  const parsed = { base: null, head: null, json: false };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--json") parsed.json = true;
    else if (argument === "--base" && index + 1 < argv.length) parsed.base = argv[++index];
    else if (argument === "--head" && index + 1 < argv.length) parsed.head = argv[++index];
    else throw new ObservationError(`unsupported or incomplete argument: ${argument}`);
  }
  if (!parsed.base || !parsed.head) throw new ObservationError("usage: history_integrity.cjs --base <sha> --head <sha> [--json]");
  return parsed;
}

function render(result, json) {
  if (json) return `${JSON.stringify(result, null, 2)}\n`;
  const lines = [`History integrity: ${result.status}`, `Base: ${result.base || "unobserved"}`, `Head: ${result.head || "unobserved"}`];
  for (const violation of result.violations) lines.push(`${violation.code} ${violation.artifact}: ${violation.change}`);
  for (const artifact of result.additions) lines.push(`HIST_ARCHIVE_ADDED ${artifact}`);
  if (result.error) lines.push(`HIST_OBSERVATION_INCOMPLETE: ${result.error}`);
  return `${lines.join("\n")}\n`;
}

function main(argv = process.argv.slice(2), options = {}) {
  let parsed;
  try {
    parsed = parseArguments(argv);
  } catch (error) {
    (options.stderr || process.stderr).write(`${error.message}\n`);
    return 2;
  }
  const result = inspectHistory(parsed.base, parsed.head, { ...options, cwd: options.cwd || process.cwd() });
  (options.stdout || process.stdout).write(render(result, parsed.json));
  return result.status === "healthy" ? 0 : result.status === "violated" ? 1 : 2;
}

if (require.main === module) process.exitCode = main();

module.exports = { compareEvidence, inspectHistory, main, validCorrectionRow };
