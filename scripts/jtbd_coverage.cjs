#!/usr/bin/env node
"use strict";

const path = require("node:path");
const fs = require("node:fs");
const { spawnSync } = require("node:child_process");
const { collectRepositorySnapshot, readBoundedRepositoryFile } = require("./lib/repository_truth.cjs");

const SCHEMA_VERSION = 1;
const HORIZONS = new Set(["short", "mid", "long"]);
const STATUSES = new Set(["shipped", "committed", "candidate", "conditional", "rejected", "external", "superseded"]);
const REQUIRED_FIELDS = [
  "actor", "situation", "outcome", "capability", "smallest_gap", "boundary", "source", "owner", "adopter_owner",
  "rationale", "requirement_phase", "proof", "evidence", "freshness", "non_goal", "promotion",
  "horizon", "commitment_status", "trajectory_group", "backlog_archive",
  "evidence_class", "evidence_identity", "evidence_caveat",
];
const SOURCES = Object.freeze({
  canonical: ".planning/JTBD-COVERAGE.md",
  personas: ".planning/PERSONAS.md",
  workflows: ".planning/WORKFLOWS.md",
  requirements: ".planning/REQUIREMENTS.md",
  roadmap: ".planning/ROADMAP.md",
  evidence: ".planning/EVIDENCE.md",
  backlog: ".planning/BACKLOG.md",
  backlogArchive: ".planning/BACKLOG-ARCHIVE.md",
  milestones: ".planning/MILESTONES.md",
});

const HELP = `Usage: node scripts/jtbd_coverage.cjs [--json] [--check-handoff] [--help]

Validate stable JTBD records and both link-only navigation indexes without
changing repository files, Git refs, index, or worktree metadata.

Options:
  --json  Render deterministic JSON from the same evaluated result as human output
  --check-handoff  Validate the dated v2.2 handoff against canonical sources and fresh worktree inventory
  --help  Show this help

Exit status:
  0  records and both indexes agree
  1  an actionable coverage or navigation error was found
  2  a required source is missing, unsafe, or incomplete
`;

function compareText(left, right) {
  return String(left ?? "").localeCompare(String(right ?? ""), "en", { sensitivity: "variant" });
}

function gitRoot(cwd, options) {
  const runner = options.runner || spawnSync;
  const result = runner("git", ["-C", cwd, "rev-parse", "--show-toplevel"], {
    encoding: "utf8",
    env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
    shell: false,
    windowsHide: true,
    timeout: 10_000,
  });
  if (result.error || result.signal || result.status !== 0) {
    throw new Error("could not resolve a Git repository root");
  }
  return path.resolve(result.stdout.trim());
}

function runBoundedCommand(runner, command, args, timeout) {
  const result = runner(command, args, {
    encoding: "utf8",
    env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
    shell: false,
    windowsHide: true,
    timeout,
  });
  if (result.error || result.signal || result.status !== 0) throw new Error("read-only identity command failed");
  return String(result.stdout || "").trim();
}

function observeCandidateCheckout(candidateClone, options = {}) {
  if (options.readCandidateIdentity) return options.readCandidateIdentity(candidateClone);
  if (typeof candidateClone !== "string" || !path.isAbsolute(candidateClone)) throw new Error("candidate clone path must be absolute");
  const stat = fs.lstatSync(candidateClone);
  if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("candidate clone must be a real directory");
  const runner = options.runner || spawnSync;
  const git = (...args) => runBoundedCommand(runner, "git", ["-C", candidateClone, ...args], 10_000);
  return {
    head: git("rev-parse", "HEAD"),
    parent: git("rev-parse", "HEAD^") ,
    branch: git("branch", "--show-current"),
    remote: git("remote", "get-url", "origin"),
  };
}

function observePullRequest(repository, number, options = {}) {
  if (options.readPullRequest) return options.readPullRequest(repository, number);
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository) || !Number.isInteger(number) || number < 1) {
    throw new Error("repository or pull request identity is invalid");
  }
  const runner = options.runner || spawnSync;
  const output = runBoundedCommand(runner, "gh", [
    "pr", "view", String(number), "--repo", repository,
    "--json", "headRefOid,state,baseRefName,mergedAt",
  ], 20_000);
  const data = JSON.parse(output);
  return {
    head_sha: data.headRefOid,
    state: data.state,
    base: data.baseRefName,
    merged_at: data.mergedAt,
  };
}

function observeHostedProof(target, repository, options = {}) {
  if (Object.prototype.hasOwnProperty.call(options, "liveHostedProof")) return options.liveHostedProof;
  const runner = options.hostedProofRunner || spawnSync;
  const result = runner(process.execPath, [
    path.join(__dirname, "ci_remote_gate.cjs"), "candidate", "--sha", target,
    "--repo", repository, "--json",
  ], {
    encoding: "utf8",
    env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
    shell: false,
    windowsHide: true,
    timeout: 120_000,
    maxBuffer: 2 * 1024 * 1024,
  });
  if (result.error || result.signal) return { observed: false, verified: false, reason: "remote_gate_unavailable" };
  try { return JSON.parse(String(result.stdout || "")); }
  catch { return { observed: false, verified: false, reason: "remote_gate_invalid_response" }; }
}

function liveHostedProofMatches(hosted, target, live) {
  const run = live?.run;
  const proof = live?.proof;
  const artifact = live?.artifact;
  const runId = String(hosted.run_id);
  const attempt = Number(hosted.attempt);
  const recordedTestedSha = String(hosted.tested_sha || "");
  const expectedUrl = `https://github.com/${hosted.repository}/actions/runs/${runId}`;
  return live?.observed === true && live?.verified === true
    && /^[0-9a-f]{40}$/i.test(recordedTestedSha)
    && live.sha?.toLowerCase() === target.toLowerCase()
    && live.eventHeadSha?.toLowerCase() === target.toLowerCase()
    && live.testedSha?.toLowerCase() === recordedTestedSha.toLowerCase()
    && live.workflow === hosted.workflow
    && String(run?.id) === runId && run?.attempt === attempt
    && run?.workflowName === hosted.workflow && run?.headSha?.toLowerCase() === target.toLowerCase()
    && proof?.verified === true && String(proof.runId) === runId && proof.runAttempt === attempt
    && proof.eventHeadSha?.toLowerCase() === target.toLowerCase()
    && proof.testedSha?.toLowerCase() === recordedTestedSha.toLowerCase()
    && artifact?.verified === true && artifact.name === `ci-proof-${runId}-${attempt}`
    && String(artifact.id) === String(hosted.artifact_id)
    && artifact.digest?.toLowerCase() === String(hosted.digest).toLowerCase()
    && String(artifact.runId) === runId
    && artifact.headSha?.toLowerCase() === target.toLowerCase()
    && hosted.url === expectedUrl && (!run.url || run.url === expectedUrl);
}

function makeDiagnostic(code, artifact, field, expected, actual, severity = "error") {
  return { code, severity, artifact, field, expected, actual };
}

function adopterOwnerStatus(value) {
  const owner = String(value || "").trim();
  if (/^unknown(?:\b|[;:])/i.test(owner)) return "unknown";
  if (/^not applicable(?:\b|[;:])/i.test(owner)) return "not_applicable";
  if (/^external:[a-z0-9][a-z0-9-]*$/i.test(owner)) return "external";
  if (/^named:\s*\S/i.test(owner)) return "named";
  return "invalid";
}

function splitMarkdownRow(line) {
  const trimmed = line.trim();
  if (!trimmed.startsWith("|")) return [];
  return trimmed.slice(1, trimmed.endsWith("|") ? -1 : undefined).split("|").map((cell) => cell.trim());
}

function parseTable(lines, expectedHeaders) {
  const start = lines.findIndex((line) => line.trim().startsWith("|"));
  if (start < 0 || start + 1 >= lines.length) return { rows: [], start: -1 };
  const headers = splitMarkdownRow(lines[start]).map((header) => header.toLowerCase().replace(/\s+/g, "_"));
  if (expectedHeaders && expectedHeaders.some((header, index) => headers[index] !== header)) {
    return { rows: [], start };
  }
  const rows = [];
  for (let index = start + 2; index < lines.length && lines[index].trim().startsWith("|"); index += 1) {
    const values = splitMarkdownRow(lines[index]);
    if (values.every((value) => /^:?-{3,}:?$/.test(value))) continue;
    const row = {};
    headers.forEach((header, column) => { row[header] = values[column] ?? ""; });
    rows.push(row);
  }
  return { rows, start };
}

function normalizeValue(value) {
  return String(value ?? "").trim().replace(/^`|`$/g, "");
}

function isCalendarDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || "")) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(parsed.valueOf()) && parsed.toISOString().slice(0, 10) === value;
}

function parseRecords(content, artifact, diagnostics) {
  const headings = [...content.matchAll(/^## (JTBD-[A-Z0-9-]+)\s*$/gm)];
  const records = new Map();
  for (let index = 0; index < headings.length; index += 1) {
    const id = headings[index][1];
    const start = headings[index].index + headings[index][0].length;
    const next = content.slice(start).search(/^## /m);
    const end = next < 0 ? content.length : start + next;
    const body = content.slice(start, end);
    const fieldsText = body.split(/^### Status history\s*$/mi, 1)[0];
    const lines = fieldsText.split(/\r?\n/);
    const table = parseTable(lines, ["field", "value"]);
    const fields = {};
    if (table.start < 0) {
      diagnostics.push(makeDiagnostic("JTBD_FIELDS_TABLE_MISSING", artifact, id, "a Field/Value table", "no field table"));
    } else {
      for (const row of table.rows) {
        const key = normalizeValue(row.field).toLowerCase().replace(/\s+/g, "_");
        if (!key) continue;
        if (Object.prototype.hasOwnProperty.call(fields, key)) {
          diagnostics.push(makeDiagnostic("JTBD_FIELD_DUPLICATE", artifact, `${id}.${key}`, "one value", "duplicate field"));
        } else fields[key] = normalizeValue(row.value);
      }
    }
    const historyPart = body.split(/^### Status history\s*$/mi)[1] || "";
    const historyLines = historyPart.split(/\r?\n/);
    const historyHeader = splitMarkdownRow(historyLines.find((line) => line.trim().startsWith("|")) || "")
      .map((header) => header.toLowerCase().replace(/\s+/g, "_"));
    const history = historyHeader.length
      ? parseTable(historyLines, historyHeader).rows
      : [];
    if (records.has(id)) {
      diagnostics.push(makeDiagnostic("JTBD_DUPLICATE_ID", artifact, id, "one canonical heading", "duplicate heading"));
    }
    records.set(id, { id, artifact, fields, history });
  }
  if (headings.length === 0) diagnostics.push(makeDiagnostic("JTBD_RECORDS_MISSING", artifact, "records", "at least one JTBD-* heading", "none"));
  return records;
}

function parseIndex(content, artifact, records, diagnostics) {
  const counts = {};
  const linkPattern = /\[([^\]]*)\]\(([^)\s]+)\)/g;
  for (const match of content.matchAll(linkPattern)) {
    const label = match[1];
    const href = match[2];
    const fragmentAt = href.indexOf("#");
    const targetPath = fragmentAt < 0 ? href : href.slice(0, fragmentAt);
    const fragment = fragmentAt < 0 ? "" : href.slice(fragmentAt + 1);
    const labelId = label.match(/JTBD-[A-Z]+-[0-9]{2}/)?.[0] || "";
    const targetId = fragment ? fragment.toUpperCase() : "";
    if (!labelId && !targetId) continue;

    const relative = path.posix.normalize(targetPath || ".");
    if (relative !== "JTBD-COVERAGE.md" || targetPath.startsWith("/") || relative.startsWith("../") || /^(?:https?:|file:)/i.test(targetPath)) {
      diagnostics.push(makeDiagnostic("JTBD_INDEX_TARGET_UNSAFE", artifact, labelId || targetId || "link", "relative link to JTBD-COVERAGE.md", href));
      continue;
    }
    if (!/^JTBD-[A-Z0-9-]+$/.test(targetId)) {
      diagnostics.push(makeDiagnostic("JTBD_INDEX_TARGET_INVALID", artifact, labelId || "link", "stable JTBD ID fragment", href));
      continue;
    }
    if (labelId && labelId !== targetId) {
      diagnostics.push(makeDiagnostic("JTBD_INDEX_LINK_LABEL", artifact, targetId, targetId, labelId));
    }
    if (!records.has(targetId)) {
      diagnostics.push(makeDiagnostic("JTBD_INDEX_TARGET_MISSING", artifact, targetId, "existing canonical record", href));
      continue;
    }
    counts[targetId] = (counts[targetId] || 0) + 1;
  }
  for (const id of records.keys()) {
    const count = counts[id] || 0;
    if (count === 0) diagnostics.push(makeDiagnostic("JTBD_INDEX_LINK_MISSING", artifact, id, "one link to the canonical heading", 0));
    else if (count > 1) diagnostics.push(makeDiagnostic("JTBD_INDEX_LINK_DUPLICATE", artifact, id, "one link to the canonical heading", count));
  }
  return Object.fromEntries(Object.entries(counts).sort(([left], [right]) => compareText(left, right)));
}

function validateRecords(records, artifact, diagnostics) {
  for (const record of records.values()) {
    for (const field of REQUIRED_FIELDS) {
      const value = record.fields[field];
      if (!value) diagnostics.push(makeDiagnostic("JTBD_REQUIRED_FIELD_MISSING", artifact, `${record.id}.${field}`, "explicit value or unknown", "missing"));
    }
    const { fields, history, id } = record;
    if (fields.horizon && !HORIZONS.has(fields.horizon)) diagnostics.push(makeDiagnostic("JTBD_HORIZON_INVALID", artifact, `${id}.horizon`, [...HORIZONS].sort(), fields.horizon));
    if (fields.commitment_status && !STATUSES.has(fields.commitment_status)) diagnostics.push(makeDiagnostic("JTBD_STATUS_INVALID", artifact, `${id}.commitment_status`, [...STATUSES].sort(), fields.commitment_status));
    if (fields.trajectory_group && fields.horizon && fields.commitment_status && fields.trajectory_group !== `${fields.horizon}/${fields.commitment_status}`) {
      diagnostics.push(makeDiagnostic("JTBD_TRAJECTORY_MISMATCH", artifact, `${id}.trajectory_group`, `${fields.horizon}/${fields.commitment_status}`, fields.trajectory_group));
    }
    if (!/\b\d{4}-\d{2}-\d{2}\b/.test(fields.source || "")) diagnostics.push(makeDiagnostic("JTBD_SOURCE_DATE_MISSING", artifact, `${id}.source`, "dated source reference", fields.source || "missing"));
    if (!/\b(?:oarlock|external:[a-z0-9][a-z0-9-]*)\b/i.test(fields.owner || "")) {
      diagnostics.push(makeDiagnostic("JTBD_OWNER_ACCOUNTABILITY_MISSING", artifact, `${id}.owner`, "Oarlock repository owner or named external owner", "unaccountable owner identity"));
    }
    const adopterStatus = adopterOwnerStatus(fields.adopter_owner);
    if (adopterStatus === "invalid") {
      diagnostics.push(makeDiagnostic("JTBD_ADOPTER_OWNER_UNCLASSIFIED", artifact, `${id}.adopter_owner`, "unknown, not applicable, external:<owner>, or named:<owner>", "unclassified adopter owner"));
    }
    if (history.length === 0) diagnostics.push(makeDiagnostic("JTBD_HISTORY_MISSING", artifact, `${id}.history`, "one dated initial transition", 0));
    for (const [index, transition] of history.entries()) {
      const row = index + 1;
      if (!isCalendarDate(transition.date)) {
        diagnostics.push(makeDiagnostic("JTBD_HISTORY_DATE_INVALID", artifact, `${id}.history.${row}.date`, "valid YYYY-MM-DD date", transition.date || "missing"));
      }
      for (const field of ["prior_horizon", "new_horizon", "prior_status", "new_status", "source", "owner", "rationale", "evidence", "evidence_class", "caveat"]) {
        if (!transition[field]) diagnostics.push(makeDiagnostic("JTBD_HISTORY_FIELD_MISSING", artifact, `${id}.history.${row}.${field}`, "explicit provenance value", "missing"));
      }
      if (transition.prior_horizon && transition.prior_horizon !== "unknown" && !HORIZONS.has(transition.prior_horizon)) {
        diagnostics.push(makeDiagnostic("JTBD_HISTORY_HORIZON_INVALID", artifact, `${id}.history.${row}.prior_horizon`, ["unknown", ...[...HORIZONS].sort()], transition.prior_horizon));
      }
      if (transition.prior_status && transition.prior_status !== "unknown" && !STATUSES.has(transition.prior_status)) {
        diagnostics.push(makeDiagnostic("JTBD_HISTORY_STATUS_INVALID", artifact, `${id}.history.${row}.prior_status`, ["unknown", ...[...STATUSES].sort()], transition.prior_status));
      }
      if (transition.new_horizon && !HORIZONS.has(transition.new_horizon)) diagnostics.push(makeDiagnostic("JTBD_HISTORY_HORIZON_INVALID", artifact, `${id}.history.${row}.new_horizon`, [...HORIZONS].sort(), transition.new_horizon));
      if (transition.new_status && !STATUSES.has(transition.new_status)) diagnostics.push(makeDiagnostic("JTBD_HISTORY_STATUS_INVALID", artifact, `${id}.history.${row}.new_status`, [...STATUSES].sort(), transition.new_status));
      if (index > 0) {
        const previous = history[index - 1];
        if (transition.prior_horizon !== previous.new_horizon || transition.prior_status !== previous.new_status) {
          diagnostics.push(makeDiagnostic("JTBD_HISTORY_CONTINUITY", artifact, `${id}.history.${row}`, `${previous.new_horizon}/${previous.new_status}`, `${transition.prior_horizon}/${transition.prior_status}`));
        }
        if (isCalendarDate(transition.date) && isCalendarDate(previous.date) && transition.date <= previous.date) {
          diagnostics.push(makeDiagnostic("JTBD_HISTORY_ORDER_INVALID", artifact, `${id}.history.${row}.date`, `after ${previous.date}`, transition.date));
        }
      }
    }
    const last = history[history.length - 1];
    if (last && fields.horizon && fields.commitment_status && (last.new_horizon !== fields.horizon || last.new_status !== fields.commitment_status)) {
      diagnostics.push(makeDiagnostic("JTBD_HISTORY_CURRENT_MISMATCH", artifact, `${id}.history`, `${fields.horizon}/${fields.commitment_status}`, `${last.new_horizon}/${last.new_status}`));
    }
  }
}

function fieldPaths(value) {
  return String(value || "").split(/;\s*/).map(normalizeValue).filter(Boolean);
}

function parseRequirementAuthorities(requirements, roadmap) {
  const committed = new Map();
  const future = new Set();
  const traceability = new Map();
  const futureAt = requirements.search(/^## Future Requirements\s*$/mi);
  const traceAt = requirements.search(/^## Traceability\s*$/mi);
  const committedText = requirements.slice(0, futureAt < 0 ? (traceAt < 0 ? undefined : traceAt) : futureAt);
  for (const match of committedText.matchAll(/^-\s*\[([ xX])\]\s*\*\*([A-Z][A-Z0-9-]+)\*\*/gm)) {
    committed.set(match[2], match[1].toLowerCase() === "x");
  }
  if (futureAt >= 0) {
    const futureText = requirements.slice(futureAt + "## Future Requirements".length, traceAt > futureAt ? traceAt : undefined);
    for (const match of futureText.matchAll(/^\s*[-*]\s*\*\*([A-Z][A-Z0-9-]+)\*\*/gm)) future.add(match[1]);
  }
  if (traceAt >= 0) {
    for (const row of parseTable(requirements.slice(traceAt).split(/\r?\n/), ["requirement", "phase", "status"]).rows) {
      const id = normalizeValue(row.requirement);
      if (id) traceability.set(id, { phase: normalizeValue(row.phase), status: normalizeValue(row.status) });
    }
  }
  const phaseHeadings = new Set([...roadmap.matchAll(/^### Phase\s+(\d+)\s*:/gm)].map((match) => Number(match[1])));
  return { committed, future, traceability, phaseHeadings };
}

function validateCrossLinks(root, records, sources, diagnostics, options = {}) {
  const requiredAuthorities = ["requirements", "roadmap", "evidence", "backlog", "backlogArchive", "milestones"];
  if (requiredAuthorities.some((name) => !sources[name])) return;
  const authorities = parseRequirementAuthorities(sources.requirements, sources.roadmap);
  const readFile = options.readRepositoryFile || readBoundedRepositoryFile;
  let phaseDirectories;
  try {
    const planningRoot = path.join(root, ".planning");
    const phaseRoot = path.join(planningRoot, "phases");
    const planningStat = fs.lstatSync(planningRoot);
    const phasesStat = fs.lstatSync(phaseRoot);
    if (!planningStat.isDirectory() || planningStat.isSymbolicLink() || !phasesStat.isDirectory() || phasesStat.isSymbolicLink()) {
      throw new Error("planning phase namespace must be a real in-repository directory");
    }
    phaseDirectories = fs.readdirSync(phaseRoot, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name);
  } catch (error) {
    diagnostics.push(makeDiagnostic("JTBD_PHASE_AUTHORITY_INCOMPLETE", ".planning/phases", "directories", "readable phase inventory", error.message, "incomplete"));
    return;
  }
  const checkLocalPath = (artifact, field) => {
    const normalized = path.posix.normalize(artifact);
    if (normalized !== artifact || artifact.startsWith("/") || artifact.startsWith("../") || /^(?:https?:|file:)/i.test(artifact)) {
      diagnostics.push(makeDiagnostic("JTBD_REFERENCE_UNSAFE", SOURCES.canonical, field, "repository-relative regular file", artifact));
      return false;
    }
    try {
      readFile(root, artifact, { maximumBytes: 2 * 1024 * 1024 });
      return true;
    } catch (error) {
      diagnostics.push(makeDiagnostic("JTBD_REFERENCE_MISSING", SOURCES.canonical, field, "existing bounded regular repository file", `${artifact}: ${error.message}`));
      return false;
    }
  };
  const checkDatedSources = (id, sourceText) => {
    const entries = String(sourceText || "").split(/;\s*/).map((value) => value.trim()).filter(Boolean);
    if (entries.length === 0) {
      diagnostics.push(makeDiagnostic("JTBD_SOURCE_REFERENCE_MISSING", SOURCES.canonical, `${id}.source`, "dated source entries resolving to planning authority files", "none"));
      return;
    }
    for (const [index, entry] of entries.entries()) {
      const dated = entry.match(/^(\d{4}-\d{2}-\d{2}):\s*(.*)$/);
      if (!dated || !isCalendarDate(dated[1])) {
        diagnostics.push(makeDiagnostic("JTBD_SOURCE_DATE_INVALID", SOURCES.canonical, `${id}.source.${index + 1}`, "valid date followed by a local planning source", "invalid dated source entry"));
        continue;
      }
      const paths = [...dated[2].matchAll(/\.planning\/[A-Za-z0-9_.\/-]+/g)].map((match) => match[0]);
      if (paths.length === 0) {
        diagnostics.push(makeDiagnostic("JTBD_SOURCE_REFERENCE_MISSING", SOURCES.canonical, `${id}.source.${index + 1}`, "at least one bounded .planning source path", "no local authority path"));
        continue;
      }
      for (const [pathIndex, artifact] of paths.entries()) checkLocalPath(artifact, `${id}.source.${index + 1}.${pathIndex + 1}`);
    }
  };
  for (const record of records.values()) {
    const { fields, id } = record;
    checkDatedSources(id, fields.source);
    const referenceTokens = fields.requirement_phase.split(";").map((item) => item.trim()).filter(Boolean);
    let resolvedAuthorityCount = 0;
    const hasResolvableFutureReference = referenceTokens.some((item) => {
      const future = item.match(/^([A-Z][A-Z0-9-]*)@Future Requirements$/);
      return Boolean(future && authorities.future.has(future[1])
        && !authorities.committed.has(future[1]) && !authorities.traceability.has(future[1]));
    });
    for (const token of referenceTokens) {
      if (token === "no committed phase mapping") {
        if (!hasResolvableFutureReference && !referenceTokens.some((item) => /^([A-Z][A-Z0-9-]*)@Future Requirements$/.test(item))) {
          diagnostics.push(makeDiagnostic("JTBD_REQUIREMENT_REFERENCE_INVALID", SOURCES.canonical, `${id}.requirement_phase`, "explanatory note only alongside a resolvable Future Requirements reference", token));
        }
        continue;
      }
      const backlog = token.match(/^(B-\d{2})@(BACKLOG(?:-ARCHIVE)?\.md)$/);
      if (backlog) {
        const [, backlogId, target] = backlog;
        const authority = target === "BACKLOG.md" ? sources.backlog : sources.backlogArchive;
        if (!new RegExp(`\\b${backlogId}\\b`).test(authority)) {
          diagnostics.push(makeDiagnostic("JTBD_BACKLOG_REFERENCE_MISSING", SOURCES.canonical, `${id}.requirement_phase.${backlogId}`, `entry in ${target}`, backlogId));
        } else resolvedAuthorityCount += 1;
        continue;
      }
      const requirement = token.match(/^([A-Z][A-Z0-9-]*)@(Phase \d+|Future Requirements)$/);
      if (!requirement) {
        diagnostics.push(makeDiagnostic("JTBD_REQUIREMENT_REFERENCE_INVALID", SOURCES.canonical, `${id}.requirement_phase`, "REQ-ID@Phase N, REQ-ID@Future Requirements, B-NN@BACKLOG.md, or the exact explanatory note", token));
        continue;
      }
      const [, requirementId, target] = requirement;
      if (target === "Future Requirements") {
        if (!authorities.future.has(requirementId) || authorities.committed.has(requirementId) || authorities.traceability.has(requirementId)) {
          diagnostics.push(makeDiagnostic("JTBD_REQUIREMENT_HORIZON_MISMATCH", SOURCES.canonical, `${id}.requirement_phase.${requirementId}`, "only in Future Requirements and absent from committed traceability", target));
        } else {
          resolvedAuthorityCount += 1;
        }
        continue;
      }
      const phaseMatch = target.match(/^Phase (\d+)$/);
      const phaseNumber = Number(phaseMatch[1]);
      const mapped = authorities.traceability.get(requirementId);
      if (!authorities.committed.has(requirementId) || authorities.future.has(requirementId) || !mapped) {
        diagnostics.push(makeDiagnostic("JTBD_REQUIREMENT_REFERENCE_MISSING", SOURCES.canonical, `${id}.requirement_phase.${requirementId}`, "committed requirement with traceability row", target));
        continue;
      }
      let resolved = true;
      if (mapped.phase !== `Phase ${phaseNumber}`) {
        diagnostics.push(makeDiagnostic("JTBD_PHASE_MAPPING_MISMATCH", SOURCES.canonical, `${id}.requirement_phase.${requirementId}`, mapped.phase, target));
        resolved = false;
      }
      if (!authorities.phaseHeadings.has(phaseNumber)) {
        diagnostics.push(makeDiagnostic("JTBD_ROADMAP_PHASE_MISSING", SOURCES.roadmap, `${id}.${requirementId}`, `Phase ${phaseNumber} heading`, "missing"));
        resolved = false;
      }
      if (resolved) resolvedAuthorityCount += 1;
      const matches = phaseDirectories.filter((name) => name.startsWith(`${phaseNumber}-`));
      // The roadmap is the phase identity authority. A roadmap phase can be
      // planned before its directory exists, and archived phases can live
      // outside .planning/phases. When a live directory is present, reject
      // ambiguous duplicate identities.
      if (matches.length > 1) {
        diagnostics.push(makeDiagnostic("JTBD_PHASE_DIRECTORY_MISMATCH", ".planning/phases", `${id}.${requirementId}`, "zero or one live directory for a roadmap phase", matches));
      }
    }
    if (resolvedAuthorityCount === 0) diagnostics.push(makeDiagnostic("JTBD_REQUIREMENT_REFERENCE_MISSING", SOURCES.canonical, `${id}.requirement_phase`, "at least one resolvable requirement, roadmap phase, or backlog authority reference", referenceTokens));
    for (const match of fields.backlog_archive.matchAll(/\b(B-\d{2})\b/g)) {
      const backlogId = match[1];
      const claimedActive = /BACKLOG\.md(?!-ARCHIVE)/.test(fields.backlog_archive);
      const authority = claimedActive ? sources.backlog : sources.backlogArchive;
      if (!new RegExp(`\\b${backlogId}\\b`).test(authority)) {
        diagnostics.push(makeDiagnostic("JTBD_BACKLOG_ARCHIVE_MISMATCH", SOURCES.canonical, `${id}.backlog_archive.${backlogId}`, claimedActive ? ".planning/BACKLOG.md entry" : ".planning/BACKLOG-ARCHIVE.md entry", backlogId));
      }
    }
    const evidencePaths = fieldPaths(fields.evidence).filter((item) => item.startsWith(".planning/") || item.startsWith(".github/") || item.startsWith("scripts/") || item.startsWith("test/") || item.startsWith("lib/"));
    const validEvidencePaths = evidencePaths.filter((artifact) => checkLocalPath(artifact, `${id}.evidence`));
    for (const artifact of evidencePaths) {
      const milestone = artifact.match(/^\.planning\/milestones\/(v[0-9]+(?:\.[0-9]+)*)-/i);
      if (milestone && !new RegExp(`\\b${milestone[1]}\\b`, "i").test(sources.milestones)) {
        diagnostics.push(makeDiagnostic("JTBD_MILESTONE_IDENTITY_MISSING", SOURCES.milestones, `${id}.evidence`, `known milestone ${milestone[1]}`, artifact));
      }
    }
    if (fields.evidence_identity.startsWith("external:")) {
      if (!["external", "candidate", "conditional"].includes(fields.commitment_status)) {
        diagnostics.push(makeDiagnostic("JTBD_EVIDENCE_IDENTITY_MISMATCH", SOURCES.canonical, `${id}.evidence_identity`, "external identity only for external or uncommitted status", fields.evidence_identity));
      }
    } else {
      checkLocalPath(fields.evidence_identity, `${id}.evidence_identity`);
      if (!validEvidencePaths.includes(fields.evidence_identity)) {
        diagnostics.push(makeDiagnostic("JTBD_EVIDENCE_IDENTITY_UNLINKED", SOURCES.canonical, `${id}.evidence_identity`, "one path listed in evidence", fields.evidence_identity));
      }
    }
    const classText = fields.evidence_class.toLowerCase();
    if (fields.commitment_status === "shipped" && !/(verification|test|contract|hosted|release|planning|validation)/.test(classText)) {
      diagnostics.push(makeDiagnostic("JTBD_EVIDENCE_CLASS_MISMATCH", SOURCES.canonical, `${id}.evidence_class`, "recognized proof class supporting a shipped capability", fields.evidence_class));
    }
    if (/(exact.s?ha|hosted|package)/.test(fields.proof.toLowerCase()) && /^(?:historical|stale|legacy)(?:\s|[-:])/.test(classText)) {
      diagnostics.push(makeDiagnostic("JTBD_HISTORICAL_PROOF_AS_CURRENT", SOURCES.canonical, `${id}.evidence_class`, "current exact-SHA/package proof identity", fields.evidence_class));
    }
  }
}

function evaluate(root, options = {}) {
  const diagnostics = [];
  const sources = {};
  for (const [key, relativePath] of Object.entries(SOURCES)) {
    try {
      const loaded = (options.readRepositoryFile || readBoundedRepositoryFile)(root, relativePath, { maximumBytes: 1024 * 1024 });
      sources[key] = loaded.content;
    } catch (error) {
      diagnostics.push(makeDiagnostic("JTBD_SOURCE_UNREADABLE", relativePath, "source", "bounded regular repository file", error.message, "incomplete"));
    }
  }
  const records = sources.canonical ? parseRecords(sources.canonical, SOURCES.canonical, diagnostics) : new Map();
  if (sources.canonical) validateRecords(records, SOURCES.canonical, diagnostics);
  if (sources.canonical) validateCrossLinks(root, records, sources, diagnostics, options);
  const indexCounts = {
    personas: sources.personas ? parseIndex(sources.personas, SOURCES.personas, records, diagnostics) : {},
    workflows: sources.workflows ? parseIndex(sources.workflows, SOURCES.workflows, records, diagnostics) : {},
  };
  diagnostics.sort((left, right) => compareText(left.code, right.code) || compareText(left.artifact, right.artifact) || compareText(left.field, right.field));
  const incomplete = diagnostics.some((item) => item.severity === "incomplete");
  const status = incomplete ? "incomplete" : diagnostics.length ? "error" : "healthy";
  return {
    schema_version: SCHEMA_VERSION,
    kind: "jtbd-coverage",
    status,
    repository: { root },
    record_ids: [...records.keys()].sort(compareText),
    ownership: [...records.values()].sort((left, right) => compareText(left.id, right.id)).map(({ id, fields }) => ({
      id,
      repository_owner: /\bexternal:[a-z0-9][a-z0-9-]*\b/i.test(fields.owner || "") ? "repository_and_external" : "repository",
      adopter_owner: adopterOwnerStatus(fields.adopter_owner),
    })),
    index_counts: indexCounts,
    diagnostics,
  };
}

function evaluateHandoff(root, options = {}) {
  const diagnostics = [];
  const handoffPath = ".planning/v2.2-HANDOFF.md";
  const readFile = options.readRepositoryFile || readBoundedRepositoryFile;
  const readText = (relativePath, label) => {
    try {
      return readFile(root, relativePath, { maximumBytes: 2 * 1024 * 1024 }).content;
    } catch (error) {
      diagnostics.push(makeDiagnostic("HANDOFF_SOURCE_INCOMPLETE", relativePath, label, "bounded regular repository file", error.message, "incomplete"));
      return null;
    }
  };
  const content = readText(handoffPath, "document");
  const canonical = readText(SOURCES.canonical, "candidate authority");
  const evidence = readText(SOURCES.evidence, "accepted caveat authority");
  const requirements = readText(SOURCES.requirements, "future requirement authority");
  const roadmap = readText(SOURCES.roadmap, "phase authority");
  let data = null;
  if (content) {
    const match = content.match(/<!-- HANDOFF_DATA_BEGIN -->\s*```json\s*([\s\S]*?)\s*```\s*<!-- HANDOFF_DATA_END -->/);
    if (!match) diagnostics.push(makeDiagnostic("HANDOFF_DATA_MISSING", handoffPath, "machine record", "bounded JSON record between handoff markers", "missing"));
    else {
      try { data = JSON.parse(match[1]); }
      catch (error) { diagnostics.push(makeDiagnostic("HANDOFF_DATA_INVALID", handoffPath, "machine record", "valid JSON object", error.message)); }
    }
  }
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    diagnostics.sort((left, right) => compareText(left.code, right.code) || compareText(left.artifact, right.artifact) || compareText(left.field, right.field));
    return { schema_version: SCHEMA_VERSION, kind: "jtbd-handoff", status: diagnostics.some((item) => item.severity === "incomplete") ? "incomplete" : "error", repository: { root }, diagnostics };
  }
  const incomplete = (code, field, expected, actual) => diagnostics.push(makeDiagnostic(code, handoffPath, field, expected, actual, "incomplete"));
  const error = (code, field, expected, actual) => diagnostics.push(makeDiagnostic(code, handoffPath, field, expected, actual));
  const requireString = (field) => {
    const value = data[field];
    if (typeof value !== "string" || !value.trim()) error("HANDOFF_FIELD_MISSING", field, "non-empty string", value ?? "missing");
    return typeof value === "string" ? value.trim() : "";
  };
  const shaPattern = /^[0-9a-f]{40}$/i;
  const repository = requireString("repository");
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
    error("HANDOFF_REPOSITORY_INVALID", "repository", "owner/repository identity", repository);
  }
  requireString("branch");
  if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z$/.test(requireString("observed_at"))) {
    error("HANDOFF_OBSERVATION_DATE_INVALID", "observed_at", "UTC ISO-8601 timestamp", data.observed_at ?? "missing");
  }
  for (const field of ["observed_head_sha", "tested_payload_sha", "handoff_document_sha"]) {
    const value = requireString(field);
    if (value !== "unknown" && !shaPattern.test(value)) error("HANDOFF_SHA_INVALID", field, "40-character commit SHA or explicit unknown", value);
  }
  for (const field of ["candidate_sha", "main_base_sha"]) {
    const value = requireString(field);
    if (value !== "unknown" && !shaPattern.test(value)) error("HANDOFF_SHA_INVALID", field, "40-character commit SHA or explicit unknown", value);
  }
  requireString("candidate_clone");
  requireString("candidate_branch");
  if (data.candidate_sha !== "unknown" && data.tested_payload_sha !== "unknown" && data.candidate_sha !== data.tested_payload_sha) {
    error("HANDOFF_CANDIDATE_SHA_MISMATCH", "candidate_sha", data.tested_payload_sha, data.candidate_sha);
  }
  if (!Array.isArray(data.source_links) || data.source_links.length === 0) error("HANDOFF_SOURCES_MISSING", "source_links", "one or more local authority paths", data.source_links ?? "missing");
  else {
    for (const artifact of data.source_links) {
      if (typeof artifact !== "string" || !artifact.startsWith(".planning/")) {
        error("HANDOFF_SOURCE_UNSAFE", "source_links", "repository-relative .planning authority path", artifact);
        continue;
      }
      try { readFile(root, artifact, { maximumBytes: 2 * 1024 * 1024 }); }
      catch (failure) { incomplete("HANDOFF_SOURCE_INCOMPLETE", `source_links.${artifact}`, "existing bounded regular authority file", failure.message); }
    }
    for (const required of [SOURCES.canonical, SOURCES.evidence, SOURCES.requirements, SOURCES.roadmap]) {
      if (!data.source_links.includes(required)) error("HANDOFF_SOURCE_LINK_MISSING", "source_links", required, data.source_links);
    }
  }

  let records = new Map();
  if (canonical) records = parseRecords(canonical, SOURCES.canonical, diagnostics);
  const authorities = requirements && roadmap ? parseRequirementAuthorities(requirements, roadmap) : null;
  if (!Array.isArray(data.candidate_ids) || data.candidate_ids.length === 0) error("HANDOFF_CANDIDATES_MISSING", "candidate_ids", "one or more canonical candidate/conditional JTBD IDs", data.candidate_ids ?? "missing");
  else {
    const seen = new Set();
    for (const id of data.candidate_ids) {
      if (typeof id !== "string" || seen.has(id)) {
        error("HANDOFF_CANDIDATE_DUPLICATE", "candidate_ids", "unique canonical JTBD IDs", id);
        continue;
      }
      seen.add(id);
      const record = records.get(id);
      if (!record) {
        error("HANDOFF_CANDIDATE_MISSING", `candidate_ids.${id}`, "existing canonical JTBD record", id);
        continue;
      }
      const requirementId = id.replace(/^JTBD-/, "");
      const futureClaims = record.fields.requirement_phase.split(/;\s*/).map((item) => item.trim()).filter((item) => item.endsWith("@Future Requirements"));
      if (!["candidate", "conditional"].includes(record.fields.commitment_status)
        || !futureClaims.includes(`${requirementId}@Future Requirements`)
        || /@Phase\s+\d+/.test(record.fields.requirement_phase)) {
        error("HANDOFF_CANDIDATE_COMMITMENT_INVALID", `candidate_ids.${id}`, "candidate or conditional status mapped only to Future Requirements", `${record.fields.commitment_status}; ${record.fields.requirement_phase}`);
      }
      if (!authorities) {
        incomplete("HANDOFF_REQUIREMENT_AUTHORITY_INCOMPLETE", `candidate_ids.${id}`, "readable REQUIREMENTS and ROADMAP authorities", "unavailable");
      } else if (!authorities.future.has(requirementId) || authorities.committed.has(requirementId) || authorities.traceability.has(requirementId)) {
        error("HANDOFF_CANDIDATE_AUTHORITY_MISMATCH", `candidate_ids.${id}`, "matching requirement present only in Future Requirements", requirementId);
      }
      if (futureClaims.some((claim) => {
        const futureId = claim.slice(0, -"@Future Requirements".length);
        return !authorities?.future.has(futureId) || authorities?.committed.has(futureId) || authorities?.traceability.has(futureId);
      })) {
        error("HANDOFF_CANDIDATE_AUTHORITY_MISMATCH", `candidate_ids.${id}`, "all Future Requirements claims resolve only to Future Requirements", "contradictory requirement authority");
      }
    }
  }

  const caveats = Array.isArray(data.accepted_caveats) ? data.accepted_caveats : [];
  const retainedHistorical = caveats.some((item) => typeof item?.text === "string"
    && /v0\.1\.2/i.test(item.text) && /candidate/i.test(item.text)
    && /(?:release-evidence\.json|exact candidate bytes)/i.test(item.text)
    && item.source === SOURCES.evidence);
  if (!retainedHistorical || !evidence?.includes("v0.1.2")) {
    error("HANDOFF_HISTORICAL_CAVEAT_MISSING", "accepted_caveats", "v0.1.2 candidate-byte/evidence-asset caveat linked to .planning/EVIDENCE.md", caveats);
  }

  let inventory = options.inventory;
  if (!inventory) {
    try { inventory = (options.collectRepositorySnapshot || collectRepositorySnapshot)(root, options.inventoryOptions || {}); }
    catch (failure) { incomplete("HANDOFF_INVENTORY_INCOMPLETE", "worktrees", "fresh read-only repository inventory", failure.message); }
  }
  const actualTrees = inventory?.facts?.worktrees || inventory?.worktrees;
  const observedTrees = data.worktrees;
  if (!Array.isArray(actualTrees) || !Array.isArray(observedTrees)) {
    incomplete("HANDOFF_WORKTREE_INVENTORY_INCOMPLETE", "worktrees", "complete observed and current worktree arrays", { observed: observedTrees, current: actualTrees });
  } else {
    const actualByPath = new Map(actualTrees.map((tree) => [tree.path, tree]));
    const observedByPath = new Map(observedTrees.filter((tree) => tree && typeof tree.path === "string").map((tree) => [tree.path, tree]));
    if (actualByPath.size !== observedTrees.length || actualByPath.size !== observedByPath.size
      || [...actualByPath.keys()].some((pathName) => !observedByPath.has(pathName))) {
      error("HANDOFF_WORKTREE_INVENTORY_MISMATCH", "worktrees", [...actualByPath.keys()].sort(compareText), [...observedByPath.keys()].sort(compareText));
    }
    for (const [treePath, current] of actualByPath) {
      const observed = observedByPath.get(treePath);
      if (!observed) continue;
      const currentDirty = Array.isArray(current.dirty) ? current.dirty.length : null;
      const currentDirtyPaths = Array.isArray(current.dirty) ? current.dirty.map((item) => item.path).sort(compareText) : null;
      const observedDirtyPaths = Array.isArray(observed.dirty_paths) ? [...observed.dirty_paths].sort(compareText) : null;
      const observedDirty = observed.dirty_status === "dirty" ? "dirty" : observed.dirty_status === "clean" ? "clean" : "unknown";
      if (observed.head !== current.head || observed.branch !== (current.branch || "detached")
        || observed.lock !== (current.lock || null)
        || observedDirty !== (currentDirty === null ? "unknown" : currentDirty > 0 ? "dirty" : "clean")
        || (currentDirty !== null && (observed.dirty_count !== currentDirty
          || !observedDirtyPaths || JSON.stringify(observedDirtyPaths) !== JSON.stringify(currentDirtyPaths)))) {
        incomplete("HANDOFF_WORKTREE_OBSERVATION_STALE", `worktrees.${treePath}`, "current head, branch, lock, and dirty state", { observed, current: { head: current.head, branch: current.branch || "detached", lock: current.lock || null, dirty_count: currentDirty } });
      }
      if (!Number.isInteger(observed.dirty_count) || observed.dirty_count < 0) {
        error("HANDOFF_DIRTY_COUNT_INVALID", `worktrees.${treePath}.dirty_count`, "non-negative integer from fresh inventory", observed.dirty_count ?? "missing");
      }
      if (!Array.isArray(observed.dirty_paths) || observed.dirty_paths.length !== observed.dirty_count) {
        error("HANDOFF_DIRTY_PATHS_INVALID", `worktrees.${treePath}.dirty_paths`, "every observed dirty path exactly once", { dirty_count: observed.dirty_count, dirty_paths: observed.dirty_paths ?? "missing" });
      }
      if (typeof observed.owner !== "string" || !observed.owner.trim()
        || typeof observed.disposition !== "string" || !observed.disposition.trim()
        || typeof observed.evidence !== "string" || !observed.evidence.trim()) {
        error("HANDOFF_WORKTREE_DISPOSITION_MISSING", `worktrees.${treePath}`, "owner, disposition, and evidence", observed);
      }
      if (observedDirty === "dirty") incomplete("HANDOFF_WORKTREE_NOT_CLEAN", `worktrees.${treePath}.dirty_status`, "dirty state reported and closeout blocked", observed.dirty_count);
      else if (observedDirty === "unknown") incomplete("HANDOFF_WORKTREE_STATUS_UNKNOWN", `worktrees.${treePath}.dirty_status`, "clean or dirty state from fresh inventory", observed.dirty_status);
      if (observed.lock) incomplete("HANDOFF_WORKTREE_LOCKED", `worktrees.${treePath}.lock`, "unlocked or explicitly blocked disposition", observed.lock);
    }
  }

  const hosted = data.hosted_proof;
  if (!hosted || typeof hosted !== "object") {
    incomplete("HANDOFF_PROOF_PENDING", "hosted_proof", "exact-target hosted run and retained artifact identity", hosted ?? "missing");
  } else if (hosted.status !== "passed") {
    incomplete("HANDOFF_PROOF_PENDING", "hosted_proof.status", "passed exact-target CI proof", hosted.status ?? "missing");
  } else {
    const target = data.tested_payload_sha;
    if (!shaPattern.test(target) || hosted.head_sha !== target || hosted.event_head_sha !== target
      || (data.pull_request && data.pull_request.head_sha !== target)) {
      error("HANDOFF_PROOF_SHA_MISMATCH", "hosted_proof.head_sha", target, { head_sha: hosted.head_sha, event_head_sha: hosted.event_head_sha, pr_head_sha: data.pull_request?.head_sha });
    }
    if (hosted.repository !== data.repository || !hosted.workflow || !shaPattern.test(String(hosted.tested_sha)) || !/^\d+$/.test(String(hosted.run_id))
      || !Number.isInteger(Number(hosted.attempt)) || Number(hosted.attempt) < 1) {
      error("HANDOFF_PROOF_IDENTITY_MISSING", "hosted_proof", "repository, workflow, tested SHA, numeric run and positive attempt", hosted);
    }
    if (!/^(?:\d+|[A-Za-z0-9._-]+)$/.test(String(hosted.artifact_id))
      || !/^sha256:[0-9a-f]{64}$/i.test(String(hosted.digest))
      || !/^https:\/\//i.test(String(hosted.url))) {
      error("HANDOFF_ARTIFACT_IDENTITY_MISSING", "hosted_proof", "artifact ID, SHA-256 digest, and HTTPS run/artifact URL", hosted);
    }
    const proofClass = String(hosted.proof_class || "").toLowerCase();
    if (!proofClass.includes("hosted") || !proofClass.includes("exact-sha") || !proofClass.includes("artifact")
      || /historical|stale|legacy/.test(proofClass)) {
      error("HANDOFF_PROOF_CLASS_STALE", "hosted_proof.proof_class", "current hosted exact-SHA artifact proof class", hosted.proof_class ?? "missing");
    }
    try {
      const liveProof = observeHostedProof(target, data.repository, options);
      if (!liveHostedProofMatches(hosted, target, liveProof)) {
        if (liveProof?.observed === true) {
          error("HANDOFF_HOSTED_PROOF_LIVE_MISMATCH", "hosted_proof", "live exact-SHA CI run, required lanes, proof artifact, and all recorded identities agree", {
            observed: liveProof.observed === true,
            verified: liveProof.verified === true,
            reason: typeof liveProof.reason === "string" && /^[a-z0-9_]{1,64}$/.test(liveProof.reason) ? liveProof.reason : "identity_mismatch",
          });
        } else {
          incomplete("HANDOFF_HOSTED_PROOF_LIVE_INCOMPLETE", "hosted_proof", "read-only live exact-SHA CI and artifact verification", {
            observed: false,
            reason: typeof liveProof?.reason === "string" && /^[a-z0-9_]{1,64}$/.test(liveProof.reason) ? liveProof.reason : "observation_unavailable",
          });
        }
      }
    } catch (failure) {
      const failureName = typeof failure?.name === "string" && /^[A-Za-z]+$/.test(failure.name) ? failure.name : "Error";
      incomplete("HANDOFF_HOSTED_PROOF_LIVE_INCOMPLETE", "hosted_proof", "read-only live exact-SHA CI and artifact verification", `observation failed (${failureName})`);
    }
    if (!data.pull_request || data.pull_request.state !== "open" || data.pull_request.base !== "main") {
      error("HANDOFF_PULL_REQUEST_IDENTITY_INVALID", "pull_request", "open PR targeting main", data.pull_request ?? "missing");
    }
    if (data.candidate_sha !== target) error("HANDOFF_CANDIDATE_SHA_MISMATCH", "candidate_sha", target, data.candidate_sha ?? "missing");
    try {
      const candidate = observeCandidateCheckout(data.candidate_clone, options);
      const expectedRemotes = [
        `https://github.com/${data.repository}`,
        `https://github.com/${data.repository}.git`,
        `git@github.com:${data.repository}`,
        `git@github.com:${data.repository}.git`,
      ];
      const remoteMatches = expectedRemotes.includes(candidate.remote);
      if (candidate.head !== target || candidate.branch !== data.candidate_branch || candidate.parent !== data.main_base_sha || !remoteMatches) {
        error("HANDOFF_CANDIDATE_CHECKOUT_MISMATCH", "candidate_clone", "candidate HEAD, parent, branch, and origin matching the tested PR target", "candidate checkout identity mismatch");
      }
    } catch {
      incomplete("HANDOFF_CANDIDATE_CHECKOUT_INCOMPLETE", "candidate_clone", "readable real candidate checkout at the tested SHA", "identity unavailable");
    }
    try {
      const livePullRequest = observePullRequest(data.repository, Number(data.pull_request?.number), options);
      if (livePullRequest.head_sha !== target || livePullRequest.state !== "OPEN"
        || livePullRequest.base !== "main" || livePullRequest.merged_at) {
        error("HANDOFF_PULL_REQUEST_LIVE_MISMATCH", "pull_request", "live open unmerged PR on main at the tested SHA", "live pull request identity mismatch");
      }
    } catch {
      incomplete("HANDOFF_PULL_REQUEST_LIVE_INCOMPLETE", "pull_request", "read-only live PR head/state/base observation", "live identity unavailable");
    }
  }
  const hasBlockers = Array.isArray(data.open_blockers) && data.open_blockers.length > 0;
  const observedDirtyOrLocked = Array.isArray(observedTrees) && observedTrees.some((tree) => tree.dirty_status !== "clean" || tree.lock);
  if (data.clean_close_claim === true && (observedDirtyOrLocked || hosted?.status !== "passed" || hasBlockers)) {
    error("HANDOFF_FALSE_CLEAN_CLAIM", "clean_close_claim", "false while work is dirty/locked, blockers remain, or exact proof is open", true);
  }
  if (data.clean_close_claim !== true && data.closeout_status === "complete") {
    error("HANDOFF_CLOSEOUT_STATUS_MISMATCH", "closeout_status", "blocked/pending when clean close is not asserted", data.closeout_status);
  }
  if (data.clean_close_claim !== true && !hasBlockers) {
    incomplete("HANDOFF_BLOCKER_MISSING", "open_blockers", "one explicit blocker for each unresolved closeout condition", data.open_blockers ?? "missing");
  }
  diagnostics.sort((left, right) => compareText(left.code, right.code) || compareText(left.artifact, right.artifact) || compareText(left.field, right.field));
  const hasErrors = diagnostics.some((item) => item.severity === "error");
  const hasIncomplete = diagnostics.some((item) => item.severity === "incomplete");
  return {
    schema_version: SCHEMA_VERSION,
    kind: "jtbd-handoff",
    status: hasErrors ? "error" : hasIncomplete ? "incomplete" : "healthy",
    repository: { root },
    observed_at: data.observed_at,
    tested_payload_sha: data.tested_payload_sha,
    handoff_document_sha: data.handoff_document_sha,
    diagnostics,
  };
}

function renderHandoffHuman(result) {
  const lines = ["JTBD handoff check (read-only)", `Repository: ${result.repository.root}`, `Tested payload: ${result.tested_payload_sha || "unknown"}`, "Diagnostics:"];
  if (result.diagnostics.length === 0) lines.push("- none");
  for (const item of result.diagnostics) lines.push(`- [${item.severity}] ${item.code} ${item.artifact}.${item.field} expected=${JSON.stringify(item.expected)} actual=${JSON.stringify(item.actual)}`);
  lines.push(`Conclusion: ${result.status}`);
  return `${lines.join("\n")}\n`;
}

function renderHuman(result) {
  const lines = ["JTBD coverage (read-only)", `Repository: ${result.repository.root}`, `Records: ${result.record_ids.length}`];
  const unknownAdopterOwners = (result.ownership || []).filter((item) => item.adopter_owner === "unknown").map((item) => item.id);
  lines.push(`Adopter ownership explicitly unknown: ${unknownAdopterOwners.length ? unknownAdopterOwners.join(", ") : "none"}`);
  if (result.diagnostics.length === 0) lines.push("Diagnostics: none");
  else {
    lines.push("Diagnostics:");
    for (const item of result.diagnostics) {
      lines.push(`- [${item.severity}] ${item.code} ${item.artifact}.${item.field} expected=${JSON.stringify(item.expected)} actual=${JSON.stringify(item.actual)}`);
    }
  }
  lines.push(`Conclusion: ${result.status}`);
  return `${lines.join("\n")}\n`;
}

function renderJson(result) {
  return `${JSON.stringify(result, null, 2)}\n`;
}

function exitCodeFor(result) {
  if (result.status === "incomplete") return 2;
  return result.status === "healthy" ? 0 : 1;
}

function main(argv = process.argv.slice(2), options = {}) {
  const allowed = new Set(["--json", "--help", "--check-handoff"]);
  const unknown = argv.filter((argument) => !allowed.has(argument));
  const stdout = options.stdout || process.stdout;
  const stderr = options.stderr || process.stderr;
  if (argv.includes("--help")) {
    stdout.write(HELP);
    return 0;
  }
  if (unknown.length) {
    stderr.write(`Unknown option: ${unknown.join(", ")}\n${HELP}`);
    return 2;
  }
  let result;
  try {
    const root = options.root ? path.resolve(options.root) : gitRoot(path.resolve(options.cwd || process.cwd()), options);
    result = argv.includes("--check-handoff") ? evaluateHandoff(root, options) : evaluate(root, options);
  } catch (error) {
    result = {
      schema_version: SCHEMA_VERSION,
      kind: "jtbd-coverage",
      status: "incomplete",
      repository: { root: path.resolve(options.cwd || process.cwd()) },
      record_ids: [],
      index_counts: { personas: {}, workflows: {} },
      diagnostics: [makeDiagnostic("JTBD_REPOSITORY_UNRESOLVED", ".", "root", "resolved Git repository", error.message, "incomplete")],
    };
  }
  stdout.write(argv.includes("--json") ? renderJson(result) : argv.includes("--check-handoff") ? renderHandoffHuman(result) : renderHuman(result));
  return exitCodeFor(result);
}

if (require.main === module) process.exitCode = main();

module.exports = {
  HELP,
  REQUIRED_FIELDS,
  STATUSES,
  HORIZONS,
  evaluate,
  evaluateHandoff,
  main,
  parseIndex,
  parseRecords,
  renderHuman,
  renderHandoffHuman,
  renderJson,
};
