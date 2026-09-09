"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const SCHEMA_VERSION = 1;
const DEFAULT_MAX_BUFFER = 4 * 1024 * 1024;
const DIAGNOSTIC_SEVERITIES = new Set(["error", "warning", "info"]);
const REQUIRED_DIAGNOSTIC_FIELDS = [
  "code", "severity", "artifact", "field", "expected", "actual",
  "authority", "evidence", "repair",
];

function compareText(left, right) {
  return String(left ?? "").localeCompare(String(right ?? ""), "en", { sensitivity: "variant" });
}

function makeDiagnostic(fields) {
  for (const field of REQUIRED_DIAGNOSTIC_FIELDS) {
    if (!Object.prototype.hasOwnProperty.call(fields, field) || fields[field] === undefined) {
      throw new TypeError(`diagnostic field ${field} is required`);
    }
  }
  if (!DIAGNOSTIC_SEVERITIES.has(fields.severity)) {
    throw new TypeError(`unsupported diagnostic severity: ${fields.severity}`);
  }
  if (!/^RINV_[A-Z0-9_]+$/.test(fields.code)) {
    throw new TypeError(`invalid repository inventory diagnostic code: ${fields.code}`);
  }

  return {
    code: fields.code,
    severity: fields.severity,
    artifact: fields.artifact,
    field: fields.field,
    expected: fields.expected,
    actual: fields.actual,
    authority: fields.authority,
    evidence: fields.evidence,
    repair: fields.repair,
    ...(fields.owner === undefined ? {} : { owner: fields.owner }),
    ...(fields.revisit_at === undefined ? {} : { revisit_at: fields.revisit_at }),
    ...(fields.incomplete === undefined ? {} : { incomplete: Boolean(fields.incomplete) }),
  };
}

function allowedGitArguments(args) {
  if (!Array.isArray(args) || args.some((value) => typeof value !== "string")) return false;
  if (args.length === 3 && args[0] === "worktree" && args[1] === "list" && args[2] === "--porcelain") return true;
  if (args.length === 4 && args[0] === "worktree" && args[1] === "list" && args[2] === "--porcelain" && args[3] === "-z") return true;
  if (args.length === 4 && args[0] === "worktree" && args[1] === "prune" && args[2] === "--dry-run" && args[3] === "--verbose") return true;
  if (args.length === 2 && args[0] === "rev-parse" && ["--show-toplevel", "--git-common-dir", "--git-dir"].includes(args[1])) return true;
  if (args.length >= 3 && args[0] === "-C") {
    const command = args.slice(2);
    if (command.length === 3 && command[0] === "status" && command[1] === "--porcelain=v2" && command[2] === "--branch") return true;
    if (command.length === 4 && command[0] === "status" && command[1] === "--porcelain=v2" && command[2] === "--branch" && command[3] === "-z") return true;
    if (command.length === 3 && command[0] === "rev-parse" && command[1] === "--verify") return true;
    if (command.length === 4 && command[0] === "rev-list" && command[1] === "--left-right" && command[2] === "--count") return true;
  }
  return false;
}

function invoke(command, args, options) {
  const runner = options.runner || spawnSync;
  return runner(command, args, {
    cwd: options.cwd,
    encoding: null,
    shell: false,
    windowsHide: true,
    maxBuffer: options.maxBuffer,
  });
}

function runGit(args, options) {
  if (!allowedGitArguments(args)) {
    throw new Error(`unsafe Git inspection command rejected: git ${args.join(" ")}`);
  }
  const result = invoke(options.gitBinary || "git", args, options);
  if (result.error || result.status !== 0) {
    const error = result.error || new Error(Buffer.from(result.stderr || []).toString("utf8").trim() || `git exited ${result.status}`);
    error.status = result.status;
    error.signal = result.signal;
    throw error;
  }
  return Buffer.isBuffer(result.stdout) ? result.stdout : Buffer.from(result.stdout || "");
}

function decode(buffer) {
  return buffer.toString("utf8");
}

function parseWorktreeList(buffer) {
  const records = [];
  let record = null;
  for (const tokenBuffer of splitNul(buffer)) {
    const token = decode(tokenBuffer);
    if (token === "") {
      if (record) records.push(record);
      record = null;
      continue;
    }
    const separator = token.indexOf(" ");
    const field = separator === -1 ? token : token.slice(0, separator);
    const value = separator === -1 ? true : token.slice(separator + 1);
    if (field === "worktree") {
      if (record) records.push(record);
      record = { path: value, head: null, branchRef: null, detached: false, bare: false, lock: null, prunable: null };
      continue;
    }
    if (!record) throw new Error(`worktree field ${field} appeared before worktree path`);
    if (field === "HEAD") record.head = value;
    else if (field === "branch") record.branchRef = value;
    else if (field === "detached") record.detached = true;
    else if (field === "bare") record.bare = true;
    else if (field === "locked") record.lock = value === true ? "locked (reason not supplied)" : value;
    else if (field === "prunable") record.prunable = value === true ? "prunable (reason not supplied)" : value;
  }
  if (record) records.push(record);
  return records;
}

function splitNul(buffer) {
  const tokens = [];
  let start = 0;
  for (let index = 0; index < buffer.length; index += 1) {
    if (buffer[index] === 0) {
      tokens.push(buffer.subarray(start, index));
      start = index + 1;
    }
  }
  if (start < buffer.length) tokens.push(buffer.subarray(start));
  return tokens;
}

function parseStatus(buffer) {
  const status = {
    head: null,
    branch: null,
    upstream: null,
    ahead: null,
    behind: null,
    detached: false,
    dirty: [],
  };
  const tokens = splitNul(buffer);
  for (let index = 0; index < tokens.length; index += 1) {
    const token = decode(tokens[index]);
    if (token === "") continue;
    if (token.startsWith("# branch.oid ")) status.head = token.slice(13);
    else if (token.startsWith("# branch.head ")) {
      const branch = token.slice(14);
      status.detached = branch === "(detached)";
      status.branch = status.detached ? null : branch;
    } else if (token.startsWith("# branch.upstream ")) status.upstream = token.slice(18);
    else if (token.startsWith("# branch.ab ")) {
      const match = /^# branch\.ab \+(\d+) -(\d+)$/.exec(token);
      if (!match) throw new Error(`malformed branch divergence record: ${token}`);
      status.ahead = Number(match[1]);
      status.behind = Number(match[2]);
    } else if (token.startsWith("1 ")) {
      const fields = token.split(" ", 9);
      status.dirty.push({
        kind: "ordinary",
        path: token.slice(fields.slice(0, 8).join(" ").length + 1),
        originalPath: null,
        index: fields[1][0],
        worktree: fields[1][1],
      });
    } else if (token.startsWith("2 ")) {
      const fields = token.split(" ", 10);
      const dirtyPath = token.slice(fields.slice(0, 9).join(" ").length + 1);
      const originalPath = index + 1 < tokens.length ? decode(tokens[index + 1]) : null;
      index += 1;
      status.dirty.push({ kind: "rename", path: dirtyPath, originalPath, index: fields[1][0], worktree: fields[1][1] });
    } else if (token.startsWith("u ")) {
      const fields = token.split(" ", 11);
      status.dirty.push({ kind: "unmerged", path: token.slice(fields.slice(0, 10).join(" ").length + 1), originalPath: null, index: fields[1][0], worktree: fields[1][1] });
    } else if (token.startsWith("? ")) {
      status.dirty.push({ kind: "untracked", path: token.slice(2), originalPath: null, index: "?", worktree: "?" });
    } else if (token.startsWith("! ")) {
      status.dirty.push({ kind: "ignored", path: token.slice(2), originalPath: null, index: "!", worktree: "!" });
    }
  }
  status.dirty.sort(compareDirty);
  return status;
}

function compareDirty(left, right) {
  return compareText(left.path, right.path)
    || compareText(left.kind, right.kind)
    || compareText(left.originalPath, right.originalPath)
    || compareText(left.index, right.index)
    || compareText(left.worktree, right.worktree);
}

function processEvidence(lockReason, options) {
  if (!lockReason) return null;
  const match = /(?:^|\W)pid\s+(\d+)(?:\W|$)/i.exec(lockReason);
  if (!match) return { pid: null, state: "unparseable", evidence: lockReason };
  const pid = Number(match[1]);
  const runner = options.runner || spawnSync;
  const result = runner(options.psBinary || "ps", ["-p", String(pid), "-o", "pid="], {
    encoding: null,
    shell: false,
    windowsHide: true,
    maxBuffer: options.maxBuffer,
  });
  if (result.error) return { pid, state: "unreadable", evidence: result.error.message };
  return {
    pid,
    state: result.status === 0 && decode(Buffer.from(result.stdout || [])).trim() === String(pid) ? "live" : "dead",
    evidence: `ps -p ${pid} -o pid= exited ${result.status}`,
  };
}

function collectionError({ artifact, field, actual, evidence }) {
  return { code: "RINV_COLLECTION_INCOMPLETE", artifact, field, actual, evidence };
}

function collectRepositorySnapshot(options = {}) {
  const cwd = path.resolve(options.cwd || process.cwd());
  const maxBuffer = options.maxBuffer || DEFAULT_MAX_BUFFER;
  const commandOptions = { ...options, cwd, maxBuffer };
  const snapshot = {
    schemaVersion: SCHEMA_VERSION,
    generatedAt: (options.now ? options.now() : new Date()).toISOString(),
    repository: { root: null, commonDir: null },
    worktrees: [],
    collectionErrors: [],
  };

  try {
    snapshot.repository.root = decode(runGit(["rev-parse", "--show-toplevel"], commandOptions)).trim();
    const commonDir = decode(runGit(["rev-parse", "--git-common-dir"], commandOptions)).trim();
    snapshot.repository.commonDir = path.resolve(cwd, commonDir);
  } catch (error) {
    snapshot.collectionErrors.push(collectionError({ artifact: cwd, field: "repository", actual: null, evidence: error.message }));
    return snapshot;
  }

  let records;
  try {
    records = parseWorktreeList(runGit(["worktree", "list", "--porcelain", "-z"], commandOptions));
  } catch (error) {
    snapshot.collectionErrors.push(collectionError({ artifact: snapshot.repository.root, field: "worktrees", actual: null, evidence: error.message }));
    return snapshot;
  }

  const canonicalMain = path.resolve(snapshot.repository.root);
  for (const record of records) {
    const worktree = {
      path: record.path,
      role: path.resolve(record.path) === canonicalMain ? "main" : "linked",
      head: record.head,
      branch: record.branchRef ? record.branchRef.replace(/^refs\/heads\//, "") : null,
      upstream: null,
      ahead: null,
      behind: null,
      detached: record.detached,
      bare: record.bare,
      lock: record.lock,
      prunable: record.prunable,
      processEvidence: processEvidence(record.lock, commandOptions),
      dirty: [],
      collectionErrors: [],
    };

    if (!record.path || !record.head) {
      worktree.collectionErrors.push(collectionError({ artifact: record.path || "worktree", field: !record.path ? "path" : "head", actual: null, evidence: "required worktree-list field absent" }));
    } else if (!fs.existsSync(record.path) || record.bare) {
      if (!record.bare) worktree.collectionErrors.push(collectionError({ artifact: record.path, field: "status", actual: null, evidence: "registered worktree path is inaccessible" }));
    } else {
      try {
        const parsed = parseStatus(runGit(["-C", record.path, "status", "--porcelain=v2", "--branch", "-z"], commandOptions));
        worktree.head = parsed.head || worktree.head;
        worktree.branch = parsed.branch;
        worktree.upstream = parsed.upstream;
        worktree.ahead = parsed.ahead;
        worktree.behind = parsed.behind;
        worktree.detached = parsed.detached || worktree.detached;
        worktree.dirty = parsed.dirty;
      } catch (error) {
        worktree.collectionErrors.push(collectionError({ artifact: record.path, field: "status", actual: null, evidence: error.message }));
      }
    }
    snapshot.worktrees.push(worktree);
  }

  snapshot.worktrees.sort((left, right) => compareText(left.path, right.path) || compareText(left.head, right.head));
  return snapshot;
}

function registryDiagnostics(registry) {
  const diagnostics = [];
  if (!registry || registry.schema_version !== SCHEMA_VERSION || !Array.isArray(registry.claims)) {
    diagnostics.push(makeDiagnostic({
      code: "RINV_REGISTRY_INVALID", severity: "error", artifact: ".planning/repository-ownership.json",
      field: "schema", expected: { schema_version: SCHEMA_VERSION, claims: "array" }, actual: registry ?? null,
      authority: ".planning/repository-ownership.json", evidence: "ownership registry failed structural validation",
      repair: "Review and correct the registry schema; do not infer ownership.", incomplete: true,
    }));
    return diagnostics;
  }
  registry.claims.forEach((claim, index) => {
    const required = ["selector", "owner", "provenance", "confidence", "revisit_at", "proposed_disposition"];
    const missing = required.filter((field) => !claim || claim[field] === null || claim[field] === undefined || claim[field] === "");
    const selectorValid = claim && claim.selector && claim.selector.kind === "dirty_path"
      && ["main", "linked"].includes(claim.selector.worktree_role)
      && typeof claim.selector.path === "string" && claim.selector.path.length > 0;
    if (missing.length || !selectorValid || !["low", "medium", "high"].includes(claim && claim.confidence) || Number.isNaN(Date.parse(claim && claim.revisit_at))) {
      diagnostics.push(makeDiagnostic({
        code: "RINV_CLAIM_INVALID", severity: "error", artifact: `.planning/repository-ownership.json#claims[${index}]`,
        field: "claim", expected: "complete exact selector and evidence metadata", actual: claim ?? null,
        authority: ".planning/repository-ownership.json", evidence: missing.length ? `missing fields: ${missing.join(", ")}` : "invalid selector, confidence, or revisit date",
        repair: "Replace the claim with a reviewed exact claim; do not broaden the selector.", incomplete: true,
      }));
    }
  });
  return diagnostics;
}

function evaluateRepositoryInventory(snapshot, registry, options = {}) {
  const diagnostics = [];
  const dispositions = [];
  const validRegistry = registry && registry.schema_version === SCHEMA_VERSION && Array.isArray(registry.claims);
  diagnostics.push(...registryDiagnostics(registry));
  const observedAt = new Date(snapshot && snapshot.generatedAt ? snapshot.generatedAt : (options.now ? options.now() : new Date())).getTime();

  if (!snapshot || !snapshot.repository || !Array.isArray(snapshot.worktrees) || !Array.isArray(snapshot.collectionErrors)) {
    diagnostics.push(makeDiagnostic({
      code: "RINV_COLLECTION_INCOMPLETE", severity: "error", artifact: "repository snapshot", field: "snapshot",
      expected: "normalized repository snapshot", actual: snapshot ?? null, authority: "Git porcelain",
      evidence: "required snapshot fields are absent", repair: "Re-run the inventory after restoring readable Git metadata.", incomplete: true,
    }));
  }

  for (const error of snapshot && Array.isArray(snapshot.collectionErrors) ? snapshot.collectionErrors : []) {
    diagnostics.push(makeDiagnostic({
      code: error.code || "RINV_COLLECTION_INCOMPLETE", severity: "error", artifact: error.artifact,
      field: error.field, expected: "complete readable observation", actual: error.actual,
      authority: "Git porcelain", evidence: error.evidence, repair: "Restore read access or Git metadata, then re-run inventory.", incomplete: true,
    }));
  }

  for (const worktree of snapshot && Array.isArray(snapshot.worktrees) ? snapshot.worktrees : []) {
    for (const error of Array.isArray(worktree.collectionErrors) ? worktree.collectionErrors : []) {
      diagnostics.push(makeDiagnostic({
        code: error.code || "RINV_COLLECTION_INCOMPLETE", severity: "error", artifact: error.artifact,
        field: error.field, expected: "complete readable worktree observation", actual: error.actual,
        authority: "Git porcelain", evidence: error.evidence, repair: "Restore read access or Git metadata, then re-run inventory.", incomplete: true,
      }));
    }

    if (!worktree || worktree.path == null || worktree.head == null || !Array.isArray(worktree.dirty)) {
      diagnostics.push(makeDiagnostic({
        code: "RINV_COLLECTION_INCOMPLETE", severity: "error", artifact: worktree && worktree.path ? worktree.path : "worktree",
        field: "required facts", expected: "path, HEAD, and dirty records", actual: worktree ?? null,
        authority: "Git porcelain", evidence: "normalized worktree contains null required fields",
        repair: "Re-run after Git can report the complete worktree record.", incomplete: true,
      }));
      continue;
    }

    for (const dirty of worktree.dirty) {
      const matching = validRegistry
        ? registry.claims.filter((claim) => claim && claim.selector
          && claim.selector.kind === "dirty_path"
          && claim.selector.worktree_role === worktree.role
          && claim.selector.path === dirty.path)
        : [];
      const artifact = `${worktree.path}:${dirty.path}`;
      if (matching.length > 1) {
        dispositions.push({ artifact, state: "ambiguous", proposed_disposition: null, claims: matching.map((claim) => ({ ...claim })) });
        diagnostics.push(makeDiagnostic({
          code: "RINV_AMBIGUOUS_CLAIM", severity: "error", artifact, field: "ownership",
          expected: "exactly one current evidence-backed claim", actual: matching.length,
          authority: ".planning/repository-ownership.json", evidence: "multiple exact selectors matched the same observation",
          repair: "Remove or narrow overlapping claims after owner review.",
        }));
      } else if (matching.length === 1) {
        const claim = matching[0];
        const revisitAt = Date.parse(claim.revisit_at);
        if (revisitAt < observedAt) {
          dispositions.push({ artifact, state: "stale", owner: claim.owner, provenance: claim.provenance, confidence: claim.confidence, revisit_at: claim.revisit_at, proposed_disposition: claim.proposed_disposition });
          diagnostics.push(makeDiagnostic({
            code: "RINV_STALE_CLAIM", severity: "error", artifact, field: "revisit_at",
            expected: "current review date", actual: claim.revisit_at, authority: ".planning/repository-ownership.json",
            evidence: claim.provenance, repair: "Ask the recorded owner to renew or retire the claim.", owner: claim.owner, revisit_at: claim.revisit_at,
          }));
        } else {
          dispositions.push({ artifact, state: "intentional", owner: claim.owner, provenance: claim.provenance, confidence: claim.confidence, revisit_at: claim.revisit_at, proposed_disposition: claim.proposed_disposition });
          diagnostics.push(makeDiagnostic({
            code: "RINV_INTENTIONAL_STATE", severity: "info", artifact, field: "ownership",
            expected: "evidence-backed intentional state", actual: claim.proposed_disposition,
            authority: ".planning/repository-ownership.json", evidence: claim.provenance,
            repair: "No automatic action; revisit the claim by its recorded date.", owner: claim.owner, revisit_at: claim.revisit_at,
          }));
        }
      } else {
        dispositions.push({ artifact, state: "unknown", owner: "unknown", provenance: null, confidence: null, revisit_at: null, proposed_disposition: null });
        diagnostics.push(makeDiagnostic({
          code: "RINV_UNKNOWN_STATE", severity: "error", artifact, field: "ownership",
          expected: "one current evidence-backed claim", actual: "unknown", authority: ".planning/repository-ownership.json",
          evidence: "no exact selector matched this observed dirty path", repair: "Record owner evidence and a finite revisit date before cleanup.",
        }));
      }
    }
  }

  dispositions.sort((left, right) => compareText(left.artifact, right.artifact) || compareText(left.state, right.state) || compareText(left.owner, right.owner));
  diagnostics.sort((left, right) => compareText(left.artifact, right.artifact) || compareText(left.code, right.code) || compareText(JSON.stringify(left.actual), JSON.stringify(right.actual)) || compareText(left.evidence, right.evidence));
  const facts = {
    repository: snapshot && snapshot.repository ? structuredClone(snapshot.repository) : null,
    worktrees: snapshot && Array.isArray(snapshot.worktrees) ? structuredClone(snapshot.worktrees) : [],
  };
  const result = {
    schemaVersion: SCHEMA_VERSION,
    generatedAt: snapshot && snapshot.generatedAt ? snapshot.generatedAt : null,
    repository: facts.repository,
    worktrees: facts.worktrees.map(({ path: worktreePath, role, head, branch, detached, lock, prunable }) => ({ path: worktreePath, role, head, branch, detached, lock, prunable })),
    facts,
    dispositions,
    diagnostics,
    conclusion: null,
  };
  const exitCode = exitCodeFor(result);
  result.conclusion = {
    status: exitCode === 0 ? "healthy" : exitCode === 1 ? "policy-error" : "incomplete",
    exitCode,
    errorCount: diagnostics.filter(({ severity }) => severity === "error").length,
    warningCount: diagnostics.filter(({ severity }) => severity === "warning").length,
    infoCount: diagnostics.filter(({ severity }) => severity === "info").length,
    diagnosticCodes: diagnostics.map(({ code }) => code),
  };
  return result;
}

function exitCodeFor(result) {
  const diagnostics = result && Array.isArray(result.diagnostics) ? result.diagnostics : [];
  if (diagnostics.some((diagnostic) => diagnostic.severity === "error" && diagnostic.incomplete === true)) return 2;
  if (diagnostics.some((diagnostic) => diagnostic.severity === "error")) return 1;
  return 0;
}

function escapeTerminal(value) {
  return String(value).replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g, (character) => `\\u${character.codePointAt(0).toString(16).padStart(4, "0")}`);
}

function renderHuman(result) {
  const lines = [
    "Repository inventory (read-only)",
    `Repository: ${escapeTerminal(result.repository && result.repository.root)}`,
    `Worktrees: ${result.worktrees.length}`,
  ];
  for (const worktree of result.facts.worktrees) {
    lines.push(`- ${escapeTerminal(worktree.path)} [${escapeTerminal(worktree.role)}] branch=${escapeTerminal(worktree.branch ?? "detached")} head=${escapeTerminal(worktree.head)} upstream=${escapeTerminal(worktree.upstream ?? "none")} ahead=${escapeTerminal(worktree.ahead ?? "unknown")} behind=${escapeTerminal(worktree.behind ?? "unknown")} lock=${escapeTerminal(worktree.lock ?? "none")} prunable=${escapeTerminal(worktree.prunable ?? "no")}`);
    for (const dirty of worktree.dirty) lines.push(`  dirty ${escapeTerminal(dirty.kind)} ${escapeTerminal(dirty.path)}`);
  }
  lines.push("Diagnostics:");
  if (result.diagnostics.length === 0) lines.push("- none");
  for (const diagnostic of result.diagnostics) {
    lines.push(`- [${diagnostic.severity}] ${diagnostic.code} ${escapeTerminal(diagnostic.artifact)}: ${escapeTerminal(diagnostic.evidence)}; repair=${escapeTerminal(diagnostic.repair)}`);
  }
  lines.push(`Conclusion: ${result.conclusion.status} (exit ${result.conclusion.exitCode}; codes=${result.conclusion.diagnosticCodes.join(",") || "none"})`);
  return `${lines.join("\n")}\n`;
}

function renderJson(result) {
  return `${JSON.stringify(result, null, 2)}\n`;
}

module.exports = {
  collectRepositorySnapshot,
  evaluateRepositoryInventory,
  exitCodeFor,
  makeDiagnostic,
  parseStatus,
  parseWorktreeList,
  renderHuman,
  renderJson,
};
