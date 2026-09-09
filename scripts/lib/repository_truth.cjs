"use strict";

const fs = require("node:fs");
const os = require("node:os");
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
  if (!/^(?:RINV|PAUTH|PSCOPE|PCOMP|PMIRROR|PHIST|PARCHIVE|PIDENT)_[A-Z0-9_]+$/.test(fields.code)) {
    throw new TypeError(`invalid repository truth diagnostic code: ${fields.code}`);
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
  if (args.length === 3 && args[0] === "for-each-ref" && args[1] === "--format=%(refname:short)%00%(objectname)%00%(*objectname)%00" && args[2] === "refs/tags") return true;
  if (args.length === 2 && args[0] === "show" && /^[^:\0]+:mix\.exs$/.test(args[1])) return true;
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
    env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" },
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
      const match = /^1 (\S{2}) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) ([\s\S]*)$/.exec(token);
      if (!match) throw new Error(`malformed porcelain-v2 ordinary record: ${token}`);
      status.dirty.push({
        kind: "ordinary",
        path: match[8],
        originalPath: null,
        index: match[1][0],
        worktree: match[1][1],
      });
    } else if (token.startsWith("2 ")) {
      const match = /^2 (\S{2}) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) ([\s\S]*)$/.exec(token);
      if (!match || index + 1 >= tokens.length) throw new Error(`malformed porcelain-v2 rename record: ${token}`);
      const originalPath = index + 1 < tokens.length ? decode(tokens[index + 1]) : null;
      index += 1;
      status.dirty.push({ kind: "rename", path: match[9], originalPath, index: match[1][0], worktree: match[1][1] });
    } else if (token.startsWith("u ")) {
      const match = /^u (\S{2}) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) ([\s\S]*)$/.exec(token);
      if (!match) throw new Error(`malformed porcelain-v2 unmerged record: ${token}`);
      status.dirty.push({ kind: "unmerged", path: match[10], originalPath: null, index: match[1][0], worktree: match[1][1] });
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
    repository: { root: null, commonDir: null, pruneDryRun: null },
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

  try {
    const pruneOutput = decode(runGit(["worktree", "prune", "--dry-run", "--verbose"], commandOptions));
    snapshot.repository.pruneDryRun = pruneOutput.split(/\r?\n/).filter((line) => line.length > 0);
  } catch (error) {
    snapshot.collectionErrors.push(collectionError({ artifact: snapshot.repository.root, field: "pruneDryRun", actual: null, evidence: error.message }));
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
    const selector = claim && claim.selector;
    const selectorKeys = selector && typeof selector === "object" ? Object.keys(selector).sort() : [];
    const dirtySelector = selector && selector.kind === "dirty_path"
      && ["main", "linked"].includes(selector.worktree_role)
      && typeof selector.path === "string" && selector.path.length > 0
      && JSON.stringify(selectorKeys) === JSON.stringify(["kind", "path", "worktree_role"]);
    const worktreeSelector = selector && ["worktree_lock", "worktree_prunable", "branch_divergence"].includes(selector.kind)
      && typeof selector.worktree_path === "string" && path.isAbsolute(selector.worktree_path)
      && JSON.stringify(selectorKeys) === JSON.stringify(["kind", "worktree_path"]);
    const selectorValid = dirtySelector || worktreeSelector;
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

function selectorMatches(selector, observation) {
  if (!selector || selector.kind !== observation.kind) return false;
  if (observation.kind === "dirty_path") {
    return selector.worktree_role === observation.worktree.role && selector.path === observation.dirty.path;
  }
  return selector.worktree_path === observation.worktree.path;
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

  if (snapshot && Array.isArray(snapshot.worktrees) && snapshot.worktrees.length === 0) {
    diagnostics.push(makeDiagnostic({
      code: "RINV_COLLECTION_INCOMPLETE", severity: "error", artifact: snapshot.repository && snapshot.repository.root ? snapshot.repository.root : "repository snapshot",
      field: "worktrees", expected: "at least the main Git worktree", actual: [], authority: "git worktree list --porcelain -z",
      evidence: "Git repository collection returned no worktree records", repair: "Inspect Git administrative metadata, then re-run inventory.", incomplete: true,
    }));
  }

  function classifyObservation(observation) {
    const matching = validRegistry ? registry.claims.filter((claim) => selectorMatches(claim && claim.selector, observation)) : [];
    const { artifact } = observation;
    if (matching.length > 1) {
      dispositions.push({ artifact, kind: observation.kind, state: "ambiguous", proposed_disposition: null, claims: matching.map((claim) => structuredClone(claim)) });
      diagnostics.push(makeDiagnostic({
        code: "RINV_AMBIGUOUS_CLAIM", severity: "error", artifact, field: observation.field,
        expected: "exactly one current evidence-backed claim", actual: matching.length,
        authority: ".planning/repository-ownership.json", evidence: "multiple exact selectors matched the same observation",
        repair: "Remove or narrow overlapping claims after owner review.",
      }));
      return;
    }
    if (matching.length === 0) {
      dispositions.push({ artifact, kind: observation.kind, state: "unknown", owner: "unknown", provenance: null, confidence: null, revisit_at: null, proposed_disposition: null });
      diagnostics.push(makeDiagnostic({
        code: observation.unknownCode, severity: "error", artifact, field: observation.field,
        expected: "one current evidence-backed claim", actual: observation.actual,
        authority: ".planning/repository-ownership.json", evidence: observation.evidence,
        repair: observation.repair,
      }));
      return;
    }

    const claim = matching[0];
    if (Date.parse(claim.revisit_at) < observedAt) {
      dispositions.push({ artifact, kind: observation.kind, state: "stale", owner: claim.owner, provenance: claim.provenance, confidence: claim.confidence, revisit_at: claim.revisit_at, proposed_disposition: claim.proposed_disposition });
      diagnostics.push(makeDiagnostic({
        code: "RINV_STALE_CLAIM", severity: "error", artifact, field: "revisit_at",
        expected: "current review date", actual: claim.revisit_at, authority: ".planning/repository-ownership.json",
        evidence: claim.provenance, repair: "Ask the recorded owner to renew or retire the claim.", owner: claim.owner, revisit_at: claim.revisit_at,
      }));
      return;
    }

    dispositions.push({ artifact, kind: observation.kind, state: "intentional", owner: claim.owner, provenance: claim.provenance, confidence: claim.confidence, revisit_at: claim.revisit_at, proposed_disposition: claim.proposed_disposition });
    diagnostics.push(makeDiagnostic({
      code: "RINV_INTENTIONAL_STATE", severity: "info", artifact, field: observation.field,
      expected: "evidence-backed intentional state", actual: claim.proposed_disposition,
      authority: ".planning/repository-ownership.json", evidence: claim.provenance,
      repair: "No automatic action; revisit the claim by its recorded date.", owner: claim.owner, revisit_at: claim.revisit_at,
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
      classifyObservation({
        kind: "dirty_path", worktree, dirty, artifact: `${worktree.path}:${dirty.path}`, field: "ownership",
        actual: "unknown", unknownCode: "RINV_UNKNOWN_STATE",
        evidence: "no exact selector matched this observed dirty path",
        repair: "Record owner evidence and a finite revisit date before cleanup.",
      });
    }

    if ((worktree.ahead || 0) > 0 || (worktree.behind || 0) > 0) {
      classifyObservation({
        kind: "branch_divergence", worktree, artifact: `${worktree.path}:branch-divergence`, field: "ahead/behind",
        actual: { ahead: worktree.ahead, behind: worktree.behind }, unknownCode: "RINV_BRANCH_DIVERGED",
        evidence: "the observed branch differs from its configured upstream",
        repair: "Review the commits and record an owned disposition before synchronizing branches.",
      });
    }
    if (worktree.lock) {
      classifyObservation({
        kind: "worktree_lock", worktree, artifact: `${worktree.path}:lock`, field: "lock",
        actual: worktree.lock, unknownCode: "RINV_UNKNOWN_LOCK",
        evidence: worktree.processEvidence ? JSON.stringify(worktree.processEvidence) : worktree.lock,
        repair: "Identify the lock owner and record evidence before any unlock action.",
      });
    }
    if (worktree.prunable) {
      classifyObservation({
        kind: "worktree_prunable", worktree, artifact: `${worktree.path}:prunable`, field: "prunable",
        actual: worktree.prunable, unknownCode: "RINV_PRUNABLE_WORKTREE",
        evidence: "Git reports this registered worktree as prunable",
        repair: "Confirm ownership and record a reviewed disposition; this inventory never prunes.",
      });
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

const PLANNING_DOCUMENTS = Object.freeze([
  ".planning/PROJECT.md",
  ".planning/REQUIREMENTS.md",
  ".planning/ROADMAP.md",
  ".planning/STATE.md",
  ".planning/MILESTONES.md",
  ".planning/EVIDENCE.md",
  ".planning/config.json",
]);

function markdownSection(markdown, heading) {
  const pattern = new RegExp(`^## ${heading}\\s*$`, "mi");
  const match = pattern.exec(markdown);
  if (!match) return "";
  const start = match.index + match[0].length;
  const remainder = markdown.slice(start);
  const next = /^##\s+/m.exec(remainder);
  return next ? remainder.slice(0, next.index) : remainder;
}

function parseCommittedRequirements(markdown) {
  const committed = markdownSection(String(markdown || ""), "v[^\\n]+ Requirements");
  const requirements = [];
  const checkbox = /^\s*[-*]\s+\[([ xX])\]\s+\*\*([A-Z][A-Z0-9]*-\d+)\*\*\s*:\s*(.+)$/gm;
  let match;
  while ((match = checkbox.exec(committed)) !== null) {
    requirements.push({ id: match[2], complete: match[1].toLowerCase() === "x", description: match[3].trim() });
  }
  requirements.sort((left, right) => compareText(left.id, right.id));

  const traceability = [];
  const traceSection = markdownSection(String(markdown || ""), "Traceability");
  for (const line of traceSection.split(/\r?\n/)) {
    const row = /^\|\s*([A-Z][A-Z0-9]*-\d+)\s*\|\s*Phase\s+([0-9.]+)\s*\|\s*([^|]+?)\s*\|$/.exec(line);
    if (row) traceability.push({ id: row[1], phase: row[2], status: row[3].trim() });
  }
  traceability.sort((left, right) => compareText(left.id, right.id));
  return { requirements, traceability };
}

function parseFrontmatter(markdown) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/.exec(String(markdown || ""));
  const values = {};
  if (!match) return values;
  for (const line of match[1].split(/\r?\n/)) {
    const field = /^([a-zA-Z0-9_]+):\s*(.*?)\s*$/.exec(line);
    if (field) values[field[1]] = field[2].replace(/^['"]|['"]$/g, "");
  }
  return values;
}

function parseRoadmap(markdown) {
  const content = String(markdown || "");
  const milestones = markdownSection(content, "Milestones");
  const activeMilestones = [];
  for (const line of milestones.split(/\r?\n/)) {
    const row = /^\s*[-*]\s+🚧\s+\*\*([^\s*]+)(?:\s+[^*]*)?\*\*/.exec(line);
    if (row) activeMilestones.push(row[1]);
  }

  const phases = [];
  const phaseSection = markdownSection(content, "Phases");
  const phasePattern = /^\s*[-*]\s+\[([ xX])\]\s+\*\*Phase\s+([0-9.]+)\s*:\s*([^*]+)\*\*/gm;
  let phaseMatch;
  while ((phaseMatch = phasePattern.exec(phaseSection)) !== null) {
    phases.push({ number: phaseMatch[2], name: phaseMatch[3].trim(), complete: phaseMatch[1].toLowerCase() === "x", requirements: [], plans: [] });
  }

  for (const phase of phases) {
    const escaped = phase.number.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const heading = new RegExp(`^### Phase ${escaped}(?::[^\\n]*)?\\s*$`, "m");
    const headingMatch = heading.exec(content);
    if (!headingMatch) continue;
    const remainder = content.slice(headingMatch.index + headingMatch[0].length);
    const next = /^###\s+/m.exec(remainder);
    const details = next ? remainder.slice(0, next.index) : remainder;
    const requirements = /^\*\*Requirements\*\*:\s*(.+)$/m.exec(details);
    if (requirements) phase.requirements = requirements[1].split(",").map((value) => value.trim()).filter(Boolean).sort(compareText);
    const planPattern = /^\s*[-*]\s+\[([ xX])\]\s+([0-9]+-[0-9]+-PLAN\.md)\b/gm;
    let planMatch;
    while ((planMatch = planPattern.exec(details)) !== null) phase.plans.push({ file: planMatch[2], complete: planMatch[1].toLowerCase() === "x" });
  }
  return { activeMilestones, phases };
}

function parseShippedMilestones(markdown) {
  const shipped = [];
  for (const line of markdownSection(String(markdown || ""), "Milestones").split(/\r?\n/)) {
    const match = /^\s*[-*]\s+✅\s+\*\*(v[^\s*]+)\s+([^*]+)\*\*\s+—\s+Phases\s+([0-9.]+)-([0-9.]+)\s+\(shipped\s+([0-9]{4}-[0-9]{2}-[0-9]{2})\)(?:\s+—\s+\[archive\]\(([^)]+)\))?/.exec(line);
    if (match) shipped.push({ planningMilestone: match[1], name: match[2].trim(), phases: `${match[3]}-${match[4]}`, shipped: match[5], roadmapLink: match[6] || null, preArchive: false });
    const exception = /^\s*[-*]\s+✅\s+\*\*(v[^\s*]+)\s+([^*]+)\*\*\s+—\s+Phases\s+([0-9.]+)-([0-9.]+)\s+\(shipped pre-archival;/.exec(line);
    if (exception) shipped.push({ planningMilestone: exception[1], name: exception[2].trim(), phases: `${exception[3]}-${exception[4]}`, shipped: "pre-archival", roadmapLink: null, preArchive: true });
  }
  return shipped.sort((left, right) => compareText(left.planningMilestone, right.planningMilestone));
}

function milestoneBlocks(markdown) {
  const blocks = new Map();
  const pattern = /^##\s+(v[^\s]+)\s+([^\n]*)$/gm;
  const matches = [...String(markdown || "").matchAll(pattern)];
  for (let index = 0; index < matches.length; index += 1) {
    const start = matches[index].index;
    const end = index + 1 < matches.length ? matches[index + 1].index : String(markdown || "").length;
    blocks.set(matches[index][1], String(markdown || "").slice(start, end));
  }
  return blocks;
}

function readPackageVersion(root, ref = null, options = {}) {
  const evidence = ref ? `git show ${ref}:mix.exs` : "mix.exs";
  try {
    let content;
    if (ref) content = decode(runGit(["show", `${ref}:mix.exs`], { cwd: root, maxBuffer: options.maximumBytes || DEFAULT_MAX_BUFFER, ...options }));
    else content = fs.readFileSync(path.join(path.resolve(root), "mix.exs"), "utf8");
    const match = /^\s*@version\s+"([^"]+)"\s*$/m.exec(content);
    return match
      ? { value: match[1], evidence, status: "known" }
      : { value: null, evidence: `${evidence}: @version declaration absent`, status: "unknown" };
  } catch (error) {
    return { value: null, evidence: `${evidence}: ${error.message}`, status: "unknown" };
  }
}

function collectTagIdentities(root, options = {}) {
  let output;
  try {
    output = runGit(["for-each-ref", "--format=%(refname:short)%00%(objectname)%00%(*objectname)%00", "refs/tags"], {
      cwd: root, maxBuffer: options.maximumBytes || DEFAULT_MAX_BUFFER, ...options,
    });
  } catch (error) {
    return [];
  }
  const identities = [];
  for (const record of decode(output).split(/\r?\n/).filter(Boolean)) {
    const [tag, objectSha, peeled] = record.split("\0");
    if (!tag || !objectSha) continue;
    const peeledSha = peeled || objectSha;
    const version = readPackageVersion(root, tag, options);
    identities.push({ tag, sourceSha: peeledSha, declaredPackageVersion: version.value, publicationStatus: "unknown" });
  }
  return identities.sort((left, right) => compareText(left.tag, right.tag));
}

function historyDiagnostic(fields) {
  return diagnostic(fields);
}

function fieldFromBlock(block, label) {
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = new RegExp(`^(?:-\\s+)?(?:\\*\\*)?${escaped}:(?:\\*\\*)?\\s*(.+)$`, "mi").exec(block || "");
  return match ? match[1].trim() : null;
}

function inlineValue(value) {
  if (!value) return null;
  if (/^unknown\b/i.test(value)) return null;
  const code = /`([^`]+)`/.exec(value);
  return code ? code[1] : value.replace(/[.;]$/, "").trim();
}

function correctionRecorded(evidence, milestone) {
  return new RegExp(`${milestone.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}[^\\n]*(?:archive|status|correction|erratum)`, "i").test(evidence || "");
}

function validateMilestoneHistory(snapshot) {
  if (!snapshot || !snapshot.milestoneArchives || !Array.isArray(snapshot.tagIdentities)) return [];
  const diagnostics = [];
  const roadmap = parseShippedMilestones(planningDocument(snapshot, ".planning/ROADMAP.md"));
  const blocks = milestoneBlocks(planningDocument(snapshot, ".planning/MILESTONES.md"));
  const evidence = planningDocument(snapshot, ".planning/EVIDENCE.md");
  const tags = new Map(snapshot.tagIdentities.map((identity) => [identity.tag, identity]));
  const archivePaths = new Set(Object.keys(snapshot.milestoneArchives));
  const warningFields = { owner: "maintainer", revisit_at: "before the next milestone close" };

  for (const expected of roadmap) {
    const block = blocks.get(expected.planningMilestone);
    if (!block) {
      diagnostics.push(historyDiagnostic({ code: "PHIST_INDEX_ENTRY_MISSING", severity: "error", artifact: ".planning/MILESTONES.md", field: expected.planningMilestone, expected: "shipped milestone index entry", actual: null, authority: ".planning/ROADMAP.md + .planning/MILESTONES.md", evidence: `ROADMAP advertises ${expected.planningMilestone} as shipped`, repair: `Propose adding ${expected.planningMilestone} to the mutable .planning/MILESTONES.md index from preserved archives.` }));
      continue;
    }
    const actualPhases = fieldFromBlock(block, "Phases");
    if (!actualPhases || !actualPhases.includes(expected.phases)) diagnostics.push(historyDiagnostic({ code: "PHIST_PHASE_RANGE_MISMATCH", severity: "error", artifact: ".planning/MILESTONES.md", field: `${expected.planningMilestone}.phases`, expected: expected.phases, actual: actualPhases, authority: ".planning/ROADMAP.md", evidence: `ROADMAP shipped range is ${expected.phases}`, repair: "Propose correcting only the mutable milestone index after reviewing the archived roadmap." }));
    if (!/\*\*Status:\*\*\s*✅\s*Shipped/i.test(block)) diagnostics.push(historyDiagnostic({ code: "PHIST_SHIPPED_STATUS_CONTRADICTION", severity: "error", artifact: ".planning/MILESTONES.md", field: `${expected.planningMilestone}.status`, expected: "Shipped", actual: fieldFromBlock(block, "Status"), authority: ".planning/ROADMAP.md", evidence: `${expected.planningMilestone} is advertised as shipped`, repair: "Propose correcting only the mutable current index; preserve archived wording and cite it in EVIDENCE.md." }));

    if (expected.preArchive) {
      diagnostics.push(historyDiagnostic({ code: "PHIST_PREARCHIVE_EXCEPTION", severity: "info", artifact: ".planning/MILESTONES.md", field: expected.planningMilestone, expected: "explicit pre-archive exception", actual: "phase artifacts retained; archive absent", authority: ".planning/MILESTONES.md", evidence: "v1.0 predates formal milestone archiving", repair: "No repair; retain this visible historical exception." }));
      continue;
    }

    for (const kind of ["Roadmap", "Requirements"]) {
      const raw = fieldFromBlock(block, kind);
      const target = inlineValue(raw);
      const field = `${expected.planningMilestone}.${kind.toLowerCase()}Link`;
      if (!target) {
        diagnostics.push(historyDiagnostic({ code: "PARCHIVE_LINK_MISSING", severity: "error", artifact: ".planning/MILESTONES.md", field, expected: `.planning/milestones/${expected.planningMilestone}-${kind.toUpperCase()}.md`, actual: null, authority: ".planning/MILESTONES.md + immutable archives", evidence: `${kind} navigation is absent`, repair: "Propose adding the tracked immutable archive link to the mutable index." }));
      } else {
        const resolved = path.resolve(snapshot.root, target);
        const root = path.resolve(snapshot.root);
        if (resolved !== root && !resolved.startsWith(`${root}${path.sep}`)) diagnostics.push(historyDiagnostic({ code: "PARCHIVE_LINK_ESCAPE", severity: "error", artifact: ".planning/MILESTONES.md", field, expected: "repository-bounded immutable archive", actual: target, authority: ".planning/MILESTONES.md", evidence: "normalized link target escapes the repository root", repair: "Propose a repository-relative immutable archive link; do not follow the escaped target." }));
        else if (!target.startsWith(".planning/milestones/")) diagnostics.push(historyDiagnostic({ code: "PARCHIVE_MUTABLE_LINK", severity: "error", artifact: ".planning/MILESTONES.md", field, expected: ".planning/milestones/* immutable snapshot", actual: target, authority: ".planning/MILESTONES.md", evidence: "root planning authorities are mutable", repair: "Propose redirecting the mutable index to its tracked frozen archive; do not edit the archive." }));
        else if (!archivePaths.has(target)) diagnostics.push(historyDiagnostic({ code: "PARCHIVE_LINK_BROKEN", severity: "error", artifact: ".planning/MILESTONES.md", field, expected: "existing tracked archive", actual: target, authority: ".planning/MILESTONES.md + immutable archives", evidence: "archive target is absent from the bounded snapshot", repair: "Propose correcting the mutable index to an existing tracked archive." }));
      }
    }

    const archiveRequirement = snapshot.milestoneArchives[`.planning/milestones/${expected.planningMilestone}-REQUIREMENTS.md`] || "";
    if (/\b(?:IN PROGRESS|Pending)\b/i.test(archiveRequirement)) {
      diagnostics.push(historyDiagnostic({ code: "PHIST_ARCHIVE_STATUS_CONTRADICTION", severity: "warning", artifact: `.planning/milestones/${expected.planningMilestone}-REQUIREMENTS.md`, field: "historical status wording", expected: "preserve byte-for-byte and correct additively", actual: "archive wording conflicts with shipped history", authority: ".planning/EVIDENCE.md", evidence: "frozen requirements snapshot retains its original incomplete wording", repair: `Append a dated ${expected.planningMilestone} correction to .planning/EVIDENCE.md while preserving the archive bytes.`, ...warningFields }));
      if (!correctionRecorded(evidence, expected.planningMilestone)) diagnostics.push(historyDiagnostic({ code: "PHIST_CORRECTION_REFERENCE_MISSING", severity: "error", artifact: ".planning/EVIDENCE.md", field: expected.planningMilestone, expected: "dated additive archive-status correction", actual: null, authority: ".planning/EVIDENCE.md", evidence: "contradictory frozen wording has no current-ledger correction", repair: `Append a dated correction citing .planning/milestones/${expected.planningMilestone}-REQUIREMENTS.md without changing it.` }));
    }

    const statedTag = inlineValue(fieldFromBlock(block, "Git tag"));
    const statedSha = inlineValue(fieldFromBlock(block, "Source SHA"));
    const statedVersion = inlineValue(fieldFromBlock(block, "Declared Hex package version"));
    const publication = fieldFromBlock(block, "Publication status");
    if (!statedTag) diagnostics.push(historyDiagnostic({ code: "PIDENT_TAG_UNKNOWN", severity: "warning", artifact: ".planning/MILESTONES.md", field: `${expected.planningMilestone}.gitTag`, expected: "local tag or explicit unknown", actual: fieldFromBlock(block, "Git tag"), authority: "local Git refs", evidence: "no local tag identity is asserted", repair: "Revisit when independent tag evidence is available; do not create or fetch refs from health tooling.", ...warningFields }));
    else {
      const identity = tags.get(statedTag);
      if (!identity || identity.sourceSha !== statedSha) diagnostics.push(historyDiagnostic({ code: "PIDENT_TAG_SHA_MISMATCH", severity: "error", artifact: ".planning/MILESTONES.md", field: `${expected.planningMilestone}.sourceSha`, expected: identity ? identity.sourceSha : "existing local tag", actual: statedSha, authority: "local Git refs", evidence: identity ? `peeled ${statedTag} target` : `${statedTag} is absent locally`, repair: "Propose updating only the mutable identity record from local refs; never fetch or mutate refs here." }));
      if (identity && identity.declaredPackageVersion !== statedVersion) diagnostics.push(historyDiagnostic({ code: "PIDENT_PACKAGE_VERSION_MISMATCH", severity: "error", artifact: ".planning/MILESTONES.md", field: `${expected.planningMilestone}.declaredPackageVersion`, expected: identity.declaredPackageVersion, actual: statedVersion, authority: `${statedTag}:mix.exs`, evidence: "package version is parsed independently from the tagged source", repair: "Propose correcting the mutable identity record; do not infer it from the milestone or tag name." }));
    }
    if (!publication || /^unknown\b/i.test(publication)) diagnostics.push(historyDiagnostic({ code: "PIDENT_PUBLICATION_UNKNOWN", severity: "info", artifact: ".planning/MILESTONES.md", field: `${expected.planningMilestone}.publicationStatus`, expected: "independent registry evidence or explicit unknown", actual: publication || null, authority: "publication registry evidence", evidence: "a local tag and package declaration do not prove publication", repair: "No repair unless independent publication evidence becomes available." }));
  }
  diagnostics.sort((left, right) => compareText(left.artifact, right.artifact) || compareText(left.code, right.code));
  return diagnostics;
}

function diagnostic(fields) {
  return makeDiagnostic(fields);
}

function planningDocument(snapshot, relativePath) {
  return snapshot && snapshot.documents && snapshot.documents[relativePath]
    ? snapshot.documents[relativePath].content
    : "";
}

function resolveActiveScope(snapshot) {
  const diagnostics = [];
  const roadmap = parseRoadmap(planningDocument(snapshot, ".planning/ROADMAP.md"));
  const state = parseFrontmatter(planningDocument(snapshot, ".planning/STATE.md"));
  const committed = parseCommittedRequirements(planningDocument(snapshot, ".planning/REQUIREMENTS.md"));
  const roadmapMilestone = roadmap.activeMilestones.length === 1 ? roadmap.activeMilestones[0] : null;
  const stateMilestone = state.milestone || null;

  if (roadmap.activeMilestones.length !== 1) {
    diagnostics.push(diagnostic({
      code: "PAUTH_ACTIVE_MILESTONE_AMBIGUOUS", severity: "error", artifact: ".planning/ROADMAP.md", field: "active milestone",
      expected: "exactly one active milestone", actual: roadmap.activeMilestones,
      authority: ".planning/ROADMAP.md", evidence: "ROADMAP milestone list must identify one active graph",
      repair: "Propose a ROADMAP.md patch that marks exactly one milestone active; do not apply it here.",
    }));
  } else if (!stateMilestone || stateMilestone !== roadmapMilestone) {
    diagnostics.push(diagnostic({
      code: "PAUTH_MILESTONE_CONFLICT", severity: "error", artifact: ".planning/ROADMAP.md + .planning/STATE.md", field: "active milestone",
      expected: roadmapMilestone, actual: stateMilestone,
      authority: ".planning/ROADMAP.md + .planning/STATE.md", evidence: `ROADMAP=${roadmapMilestone}; STATE=${stateMilestone}`,
      repair: "Review the canonical documents and propose a supported state/roadmap patch; no winner was selected.",
    }));
  }

  const phase = roadmap.phases.find(({ number }) => number === state.current_phase);
  if (!state.current_phase || !phase) {
    diagnostics.push(diagnostic({
      code: "PSCOPE_PHASE_NOT_IN_ROADMAP", severity: "error", artifact: ".planning/ROADMAP.md + .planning/STATE.md", field: "current phase",
      expected: roadmap.phases.map(({ number }) => number), actual: state.current_phase || null,
      authority: ".planning/ROADMAP.md + .planning/STATE.md", evidence: `STATE pointer ${state.current_phase || "missing"} is not a member of the ROADMAP graph`,
      repair: "Propose a supported state pointer or ROADMAP graph patch after maintainer review; do not infer from directories.",
    }));
  } else if (phase.complete && state.status !== "complete") {
    diagnostics.push(diagnostic({
      code: "PSCOPE_PHASE_STATUS_CONFLICT", severity: "error", artifact: ".planning/ROADMAP.md + .planning/STATE.md", field: "phase status",
      expected: "STATE complete when ROADMAP phase is complete", actual: { roadmap: "complete", state: state.status || null },
      authority: ".planning/ROADMAP.md + .planning/STATE.md", evidence: `Phase ${phase.number} status disagrees across canonical documents`,
      repair: "Propose a supported state/roadmap status patch after reviewing completion proof.",
    }));
  }

  const committedIds = new Set(committed.requirements.map(({ id }) => id));
  if (phase) {
    for (const requirement of phase.requirements) {
      if (!committedIds.has(requirement)) diagnostics.push(diagnostic({
        code: "PAUTH_REQUIREMENT_NOT_COMMITTED", severity: "error", artifact: ".planning/ROADMAP.md", field: "phase requirements",
        expected: [...committedIds].sort(compareText), actual: requirement,
        authority: ".planning/REQUIREMENTS.md", evidence: `Phase ${phase.number} maps ${requirement}, which is absent from the bounded committed section`,
        repair: "Propose a REQUIREMENTS.md promotion or ROADMAP.md mapping correction with provenance.",
      }));
    }
  }

  diagnostics.sort((left, right) => compareText(left.code, right.code) || compareText(left.artifact, right.artifact));
  const active = diagnostics.some(({ severity }) => severity === "error") || !phase || !roadmapMilestone
    ? null
    : { milestone: roadmapMilestone, phase: state.current_phase };
  return { active, phase: phase || null, roadmap, state, committedRequirements: committed, diagnostics };
}

function identityFor(stat) {
  return { dev: String(stat.dev), ino: String(stat.ino), size: stat.size, mtimeMs: stat.mtimeMs };
}

function sameIdentity(left, right) {
  return left.dev === right.dev && left.ino === right.ino && left.size === right.size && left.mtimeMs === right.mtimeMs;
}

function sourceBoundaryError(message, artifact) {
  const error = new Error(`source boundary: ${message}`);
  error.code = "SOURCE_BOUNDARY";
  error.artifact = artifact;
  return error;
}

function boundedPath(root, relativeOrAbsolutePath, expectedType) {
  const resolvedRoot = fs.realpathSync(path.resolve(root));
  const absolute = path.isAbsolute(relativeOrAbsolutePath)
    ? path.resolve(relativeOrAbsolutePath)
    : path.resolve(resolvedRoot, relativeOrAbsolutePath);
  const artifact = path.isAbsolute(relativeOrAbsolutePath)
    ? path.relative(resolvedRoot, absolute) || "."
    : relativeOrAbsolutePath;
  if (absolute !== resolvedRoot && !absolute.startsWith(`${resolvedRoot}${path.sep}`)) {
    throw sourceBoundaryError("candidate escapes the resolved repository root", artifact);
  }

  const components = path.relative(resolvedRoot, absolute).split(path.sep).filter(Boolean);
  let cursor = resolvedRoot;
  for (let index = 0; index < components.length; index += 1) {
    cursor = path.join(cursor, components[index]);
    const stat = fs.lstatSync(cursor);
    const relative = path.relative(resolvedRoot, cursor) || ".";
    if (stat.isSymbolicLink()) throw sourceBoundaryError(`symbolic link component rejected at ${relative}`, relative);
    const isFinal = index === components.length - 1;
    if (!isFinal && !stat.isDirectory()) throw sourceBoundaryError(`non-directory path component rejected at ${relative}`, relative);
    if (isFinal && expectedType === "directory" && !stat.isDirectory()) throw sourceBoundaryError(`expected a repository directory at ${relative}`, relative);
    if (isFinal && expectedType === "file" && !stat.isFile()) throw sourceBoundaryError(`expected a regular repository file at ${relative}`, relative);
  }

  const resolvedCandidate = fs.realpathSync(absolute);
  if (resolvedCandidate !== resolvedRoot && !resolvedCandidate.startsWith(`${resolvedRoot}${path.sep}`)) {
    throw sourceBoundaryError("resolved candidate escapes the resolved repository root", artifact);
  }
  return { artifact, resolvedRoot, absolute, resolvedCandidate };
}

function readBoundedRepositoryFile(root, relativeOrAbsolutePath, options = {}) {
  const maximumBytes = options.maximumBytes || DEFAULT_MAX_BUFFER;
  const candidate = boundedPath(root, relativeOrAbsolutePath, "file");
  const noFollow = typeof fs.constants.O_NOFOLLOW === "number" ? fs.constants.O_NOFOLLOW : 0;
  let descriptor;
  try {
    descriptor = fs.openSync(candidate.absolute, fs.constants.O_RDONLY | noFollow);
    const opened = fs.fstatSync(descriptor);
    if (!opened.isFile()) throw sourceBoundaryError(`opened source is not a regular file at ${candidate.artifact}`, candidate.artifact);
    if (opened.size > maximumBytes) throw sourceBoundaryError(`source exceeds ${maximumBytes} bytes at ${candidate.artifact}`, candidate.artifact);

    const currentBeforeRead = boundedPath(candidate.resolvedRoot, candidate.absolute, "file");
    const beforeRead = fs.lstatSync(currentBeforeRead.absolute);
    const openedIdentity = identityFor(opened);
    if (!sameIdentity(openedIdentity, identityFor(beforeRead))) {
      throw sourceBoundaryError(`source identity changed before descriptor read at ${candidate.artifact}`, candidate.artifact);
    }
    if (typeof options.afterOpen === "function") {
      options.afterOpen(candidate.artifact, candidate.absolute, descriptor, options.context);
    }

    const content = fs.readFileSync(descriptor, options.encoding === null ? undefined : (options.encoding || "utf8"));
    if (typeof options.afterRead === "function") {
      options.afterRead(candidate.artifact, candidate.absolute, options.context);
    }

    const currentAfterRead = boundedPath(candidate.resolvedRoot, candidate.absolute, "file");
    const afterRead = fs.lstatSync(currentAfterRead.absolute);
    if (!sameIdentity(openedIdentity, identityFor(afterRead))) {
      throw sourceBoundaryError(`source identity changed during descriptor read at ${candidate.artifact}`, candidate.artifact);
    }
    return { content, identity: openedIdentity, resolvedPath: candidate.resolvedCandidate };
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
  }
}

function readPlanningFile(root, relativePath, options, snapshot) {
  return readBoundedRepositoryFile(root, relativePath, { ...options, context: snapshot });
}

function listPhaseArtifacts(root) {
  const base = path.join(root, ".planning", "phases");
  if (!fs.existsSync(base)) return [];
  boundedPath(root, base, "directory");
  const artifacts = [];
  for (const phase of fs.readdirSync(base, { withFileTypes: true })) {
    const phasePath = path.join(base, phase.name);
    if (phase.isSymbolicLink()) throw sourceBoundaryError(`symbolic link component rejected at .planning/phases/${phase.name}`, `.planning/phases/${phase.name}`);
    if (!phase.isDirectory()) continue;
    boundedPath(root, phasePath, "directory");
    for (const entry of fs.readdirSync(phasePath, { withFileTypes: true })) {
      if (entry.isFile() || entry.isSymbolicLink() || (!entry.isDirectory() && /(?:-PLAN|-SUMMARY|-VERIFICATION)\.md$|^VALIDATION\.md$/.test(entry.name))) {
        artifacts.push(path.posix.join(".planning/phases", phase.name, entry.name));
      }
    }
  }
  return artifacts.sort(compareText);
}

function collectMilestoneArchives(root, options, snapshot) {
  const base = path.join(root, ".planning", "milestones");
  const archives = {};
  if (!fs.existsSync(base)) return archives;
  try {
    boundedPath(root, base, "directory");
  } catch (error) {
    snapshot.collectionErrors.push({ code: "PAUTH_SOURCE_UNREADABLE", artifact: error.artifact || ".planning/milestones", field: "artifact names", expected: "bounded repository directory", actual: null, evidence: error.message, incomplete: true });
    return archives;
  }
  for (const entry of fs.readdirSync(base, { withFileTypes: true })) {
    if (!/^v[^/]+-(?:ROADMAP|REQUIREMENTS)\.md$/.test(entry.name)) continue;
    const relativePath = path.posix.join(".planning/milestones", entry.name);
    try {
      const record = readPlanningFile(root, relativePath, options, snapshot);
      archives[relativePath] = record.content;
      snapshot.artifactIdentities[relativePath] = record.identity;
    } catch (error) {
      snapshot.collectionErrors.push({ code: "PAUTH_SOURCE_UNREADABLE", artifact: relativePath, field: "content", expected: "bounded immutable archive", actual: null, evidence: error.message, incomplete: true });
    }
  }
  return archives;
}

function phaseArtifactContents(root, artifacts, options, snapshot) {
  const contents = {};
  for (const relativePath of artifacts) {
    if (!/(?:-PLAN|-SUMMARY|-VERIFICATION)\.md$|\/VALIDATION\.md$/.test(relativePath)) continue;
    try {
      const record = readPlanningFile(root, relativePath, options, snapshot);
      contents[relativePath] = record.content;
      snapshot.artifactIdentities[relativePath] = record.identity;
    } catch (error) {
      snapshot.collectionErrors.push({ code: "PAUTH_SOURCE_UNREADABLE", artifact: relativePath, field: "content", expected: "bounded regular in-repository file", actual: null, evidence: error.message, incomplete: true });
    }
  }
  return contents;
}

function verifyPlanningConsistency(root, snapshot, options) {
  if (typeof options.beforeConsistencyCheck === "function") options.beforeConsistencyCheck(snapshot);
  const identities = [
    ...Object.entries(snapshot.documents).map(([relativePath, record]) => [relativePath, record.identity]),
    ...Object.entries(snapshot.artifactIdentities),
    ...(snapshot.mirror.exists && snapshot.mirror.identity ? [[".planning/state.json", snapshot.mirror.identity]] : []),
  ];
  for (const [relativePath, initialIdentity] of identities) {
    let finalIdentity = null;
    try {
      finalIdentity = readBoundedRepositoryFile(root, relativePath, { maximumBytes: options.maximumBytes, encoding: null }).identity;
    } catch (error) {
      snapshot.collectionErrors.push({ code: "PSCOPE_SNAPSHOT_CHANGED", artifact: relativePath, field: "identity", expected: initialIdentity, actual: null, evidence: error.message, incomplete: true });
      continue;
    }
    if (!sameIdentity(initialIdentity, finalIdentity) && !snapshot.collectionErrors.some((error) => error.code === "PSCOPE_SNAPSHOT_CHANGED" && error.artifact === relativePath)) {
      snapshot.collectionErrors.push({ code: "PSCOPE_SNAPSHOT_CHANGED", artifact: relativePath, field: "identity", expected: initialIdentity, actual: finalIdentity, evidence: "source identity changed before the whole-snapshot consistency check", incomplete: true });
    }
  }
}

function collectMirror(root, options, snapshot) {
  const relativePath = ".planning/state.json";
  const absolute = path.join(root, relativePath);
  const consumerEvidence = Array.isArray(options.mirrorConsumerEvidence) ? [...options.mirrorConsumerEvidence] : [];
  if (!fs.existsSync(absolute)) return { exists: false, content: null, identity: null, consumerEvidence };
  try {
    const record = readPlanningFile(root, relativePath, options, snapshot);
    return { exists: true, content: record.content, identity: record.identity, consumerEvidence };
  } catch (error) {
    snapshot.collectionErrors.push({ code: "PMIRROR_UNREADABLE", artifact: relativePath, field: "content", expected: "bounded regular disposable mirror", actual: null, evidence: error.message, incomplete: true });
    return { exists: true, content: null, identity: null, consumerEvidence };
  }
}

function collectGsdCorroboration(root, options) {
  if (options.collectCorroboration === false) return [];
  if (Array.isArray(options.corroboration)) return structuredClone(options.corroboration);
  const tool = options.gsdTools || process.env.GSD_TOOLS || path.join(os.homedir(), ".codex", "gsd-core", "bin", "gsd-tools.cjs");
  if (!fs.existsSync(tool)) return [{ query: "runtime", status: "unavailable", output: null }];
  const entries = [];
  for (const query of ["planning.inspect", "drift-guard.phase-status"]) {
    const args = [tool, "query", query];
    if (query === "drift-guard.phase-status") args.push("31");
    const result = (options.runner || spawnSync)(process.execPath, args, { cwd: root, encoding: "utf8", shell: false, maxBuffer: options.maximumBytes });
    entries.push({ query, status: result.status, output: result.status === 0 ? String(result.stdout || "").trim() : String(result.stderr || "").trim() });
  }
  return entries;
}

function collectPlanningSnapshot(root, options = {}) {
  const resolvedRoot = fs.realpathSync(path.resolve(root || process.cwd()));
  const settings = { maximumBytes: options.maximumBytes || DEFAULT_MAX_BUFFER, ...options };
  const snapshot = {
    schemaVersion: SCHEMA_VERSION,
    root: resolvedRoot,
    generatedAt: (settings.now ? settings.now() : new Date()).toISOString(),
    documents: {},
    phaseArtifacts: [],
    artifactContents: {},
    artifactIdentities: {},
    corroboration: [],
    mirror: { exists: false, content: null, identity: null, consumerEvidence: [] },
    milestoneArchives: {},
    tagIdentities: [],
    collectionErrors: [],
  };
  for (const relativePath of PLANNING_DOCUMENTS) {
    try {
      snapshot.documents[relativePath] = readPlanningFile(resolvedRoot, relativePath, settings, snapshot);
    } catch (error) {
      snapshot.collectionErrors.push({ code: "PAUTH_SOURCE_UNREADABLE", artifact: relativePath, field: "content", expected: "bounded regular in-repository file", actual: null, evidence: error.message, incomplete: true });
    }
  }
  snapshot.milestoneArchives = collectMilestoneArchives(resolvedRoot, settings, snapshot);
  snapshot.tagIdentities = collectTagIdentities(resolvedRoot, settings);
  try {
    snapshot.phaseArtifacts = listPhaseArtifacts(resolvedRoot);
    snapshot.artifactContents = phaseArtifactContents(resolvedRoot, snapshot.phaseArtifacts, settings, snapshot);
  } catch (error) {
    snapshot.collectionErrors.push({ code: "PAUTH_SOURCE_UNREADABLE", artifact: error.artifact || ".planning/phases", field: "artifact names", expected: "bounded repository directory", actual: null, evidence: error.message, incomplete: true });
  }
  snapshot.mirror = collectMirror(resolvedRoot, settings, snapshot);
  snapshot.corroboration = collectGsdCorroboration(resolvedRoot, settings);
  verifyPlanningConsistency(resolvedRoot, snapshot, settings);
  return snapshot;
}

function resolveCanonicalPhaseDirectory(snapshot, phaseNumber) {
  const prefix = `${String(phaseNumber)}-`;
  const directories = new Set();
  for (const artifact of snapshot && Array.isArray(snapshot.phaseArtifacts) ? snapshot.phaseArtifacts : []) {
    const match = /^\.planning\/phases\/([^/]+)\//.exec(artifact);
    if (match && match[1].startsWith(prefix)) directories.add(`.planning/phases/${match[1]}`);
  }
  const matches = [...directories].sort(compareText);
  if (matches.length === 1) return { status: "resolved", directory: matches[0], matches };
  return { status: matches.length === 0 ? "missing" : "ambiguous", directory: null, matches };
}

function canonicalPhaseDirectoryDiagnostic(resolution, phaseNumber) {
  const missing = resolution.status === "missing";
  return diagnostic({
    code: missing ? "PSCOPE_CANONICAL_PHASE_DIRECTORY_MISSING" : "PSCOPE_CANONICAL_PHASE_DIRECTORY_AMBIGUOUS",
    severity: "error",
    artifact: ".planning/phases",
    field: `phase ${phaseNumber} directory`,
    expected: `exactly one bounded ${phaseNumber}-* directory`,
    actual: resolution.matches,
    authority: ".planning/ROADMAP.md + bounded phase inventory",
    evidence: missing
      ? `No bounded phase directory matches active Phase ${phaseNumber}`
      : `Multiple bounded phase directories match active Phase ${phaseNumber}`,
    repair: "Propose restoring one unambiguous canonical phase directory; do not select proof from decoys.",
    incomplete: true,
  });
}

function artifactForPlan(snapshot, phaseDirectory, planFile, suffix) {
  const target = planFile.replace(/-PLAN\.md$/, suffix);
  const artifact = `${phaseDirectory}/${target}`;
  return (snapshot.phaseArtifacts || []).includes(artifact) ? artifact : null;
}

function completionDiagnostic(code, artifact, field, expected, actual, authority, evidence, repair) {
  return diagnostic({ code, severity: "error", artifact, field, expected, actual, authority, evidence, repair });
}

function validateCompletionProof(snapshot, phaseNumber) {
  const diagnostics = [];
  const resolution = resolveCanonicalPhaseDirectory(snapshot, phaseNumber);
  if (resolution.status !== "resolved") return [canonicalPhaseDirectoryDiagnostic(resolution, phaseNumber)];
  const phaseDirectory = resolution.directory;
  const roadmap = parseRoadmap(planningDocument(snapshot, ".planning/ROADMAP.md"));
  const requirements = parseCommittedRequirements(planningDocument(snapshot, ".planning/REQUIREMENTS.md"));
  const evidence = planningDocument(snapshot, ".planning/EVIDENCE.md");
  const phase = roadmap.phases.find(({ number }) => number === String(phaseNumber));
  if (!phase || !phase.complete) diagnostics.push(completionDiagnostic(
    "PCOMP_ROADMAP_NOT_ACCEPTED", ".planning/ROADMAP.md", "phase acceptance", "checked accepted phase", phase ? "not accepted" : "missing phase",
    ".planning/ROADMAP.md", `Phase ${phaseNumber} lacks explicit ROADMAP acceptance`, "Propose a ROADMAP acceptance patch only after all proof links pass.",
  ));

  for (const plan of phase ? phase.plans : []) {
    const expectedSummary = plan.file.replace(/-PLAN\.md$/, "-SUMMARY.md");
    const summaryArtifact = artifactForPlan(snapshot, phaseDirectory, plan.file, "-SUMMARY.md");
    if (!summaryArtifact) {
      const expectedArtifact = `${phaseDirectory}/${expectedSummary}`;
      diagnostics.push(completionDiagnostic(
        "PCOMP_SUMMARY_MISSING", `.planning/phases/${phaseNumber}`, "plan summary", expectedSummary, expectedArtifact,
        ".planning/ROADMAP.md + phase plan set", `Declared plan ${plan.file} has no corresponding summary`, "Propose executing the declared plan and writing its canonical summary; presence is not synthesized.",
      ));
      continue;
    }
    const summaryContent = snapshot.artifactContents && snapshot.artifactContents[summaryArtifact];
    const summaryStatus = String(parseFrontmatter(summaryContent).status || "").trim().toLowerCase();
    if (!summaryContent || summaryStatus !== "complete") diagnostics.push(completionDiagnostic(
      "PCOMP_SUMMARY_UNPROVEN", summaryArtifact, "summary status", "frontmatter status: complete", summaryContent ? "missing complete status" : "unread content",
      summaryArtifact, `Summary filename exists for ${plan.file} but does not carry substantive completion metadata`, "Propose correcting the summary only after re-running its verification.",
    ));
  }

  const verificationPath = `${phaseDirectory}/${phaseNumber}-VERIFICATION.md`;
  const validationPath = `${phaseDirectory}/VALIDATION.md`;
  const verificationArtifact = (snapshot.phaseArtifacts || []).includes(verificationPath) ? verificationPath
    : (snapshot.phaseArtifacts || []).includes(validationPath) ? validationPath : null;
  const verificationContent = verificationArtifact && snapshot.artifactContents ? snapshot.artifactContents[verificationArtifact] : "";
  const verificationMetadata = parseFrontmatter(verificationContent);
  const verificationStatus = String(verificationMetadata.status || verificationMetadata.result || verificationMetadata.verdict || "").trim().toLowerCase();
  const verificationPassed = ["pass", "passed", "complete", "verified"].includes(verificationStatus);
  const acknowledgedCaveat = new RegExp(`Phase\\s+${String(phaseNumber).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}[^\\n]*(?:accepted|acknowledged)[^\\n]*caveat`, "i").test(evidence);
  if (!verificationArtifact) diagnostics.push(completionDiagnostic(
    "PCOMP_VERIFICATION_MISSING", `.planning/phases/${phaseNumber}`, "phase verification", `${phaseNumber}-VERIFICATION.md or classified caveat`, null,
    ".planning/EVIDENCE.md + phase verification", "No phase verification artifact or explicitly classified caveat was found", "Propose running phase verification and recording its result in EVIDENCE.md.",
  ));
  else if (!verificationPassed && !acknowledgedCaveat) diagnostics.push(completionDiagnostic(
    "PCOMP_VERIFICATION_UNPROVEN", verificationArtifact, "verification status", "explicit pass or classified acknowledged caveat", "filename present without passing content",
    ".planning/EVIDENCE.md + phase verification", "Verification artifact presence alone does not prove success", "Propose re-running verification and recording an explicit status or reviewed caveat.",
  ));

  const requirementById = new Map(requirements.requirements.map((entry) => [entry.id, entry]));
  const traceById = new Map(requirements.traceability.map((entry) => [entry.id, entry]));
  for (const requirementId of phase ? phase.requirements : []) {
    const requirement = requirementById.get(requirementId);
    const trace = traceById.get(requirementId);
    const linked = new RegExp(`\\b${requirementId.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(evidence)
      && (new RegExp(`\\b${requirementId.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(verificationContent || "") || acknowledgedCaveat);
    if (!requirement || !requirement.complete || !trace || trace.phase !== String(phaseNumber) || !/^complete$/i.test(trace.status) || !linked) {
      diagnostics.push(completionDiagnostic(
        "PCOMP_REQUIREMENT_UNLINKED", ".planning/REQUIREMENTS.md + .planning/EVIDENCE.md", requirementId,
        { committed: true, complete: true, phase: String(phaseNumber), evidence: true },
        { committed: Boolean(requirement), complete: Boolean(requirement && requirement.complete), phase: trace && trace.phase, status: trace && trace.status, evidence: linked },
        ".planning/REQUIREMENTS.md + .planning/EVIDENCE.md", `${requirementId} is not linked through committed scope, traceability, and proof`,
        "Propose completing or correcting the requirement/evidence linkage after proof review.",
      ));
    }
  }
  return diagnostics.sort((left, right) => compareText(left.code, right.code) || compareText(left.field, right.field));
}

function activeArtifactDiagnostics(snapshot, activeScope) {
  if (!activeScope.active || !activeScope.phase) return [];
  const resolution = resolveCanonicalPhaseDirectory(snapshot, activeScope.phase.number);
  if (resolution.status !== "resolved") return [canonicalPhaseDirectoryDiagnostic(resolution, activeScope.phase.number)];
  const phaseDirectory = resolution.directory;
  const diagnostics = [];
  for (const plan of activeScope.phase.plans) {
    const planArtifact = `${phaseDirectory}/${plan.file}`;
    const planExists = (snapshot.phaseArtifacts || []).includes(planArtifact);
    if (!planExists) diagnostics.push(diagnostic({
      code: "PSCOPE_ACTIVE_PLAN_MISSING", severity: "error", artifact: `.planning/phases/${activeScope.phase.number}`, field: "declared plan",
      expected: plan.file, actual: null, authority: ".planning/ROADMAP.md", evidence: `Active ROADMAP phase declares ${plan.file}, but the bounded phase inventory cannot find it`,
      repair: "Propose restoring the referenced plan or correcting the ROADMAP declaration; do not route from other files.",
    }));
    const summary = artifactForPlan(snapshot, phaseDirectory, plan.file, "-SUMMARY.md");
    if (!plan.complete && summary) diagnostics.push(diagnostic({
      code: "PSCOPE_STALE_ACTIVE_SUMMARY", severity: "warning", artifact: summary, field: "plan status",
      expected: "ROADMAP plan checked before summary contributes completion evidence", actual: "summary present for unchecked plan",
      authority: ".planning/ROADMAP.md", evidence: "Summary presence is inert and cannot complete its plan",
      repair: "Review the plan proof and propose a ROADMAP status patch or retire the stale summary.",
    }));
  }
  return diagnostics;
}

function mirrorDiagnostics(snapshot, activeScope) {
  const mirror = snapshot && snapshot.mirror;
  if (!mirror || !mirror.exists) return [];
  if (!Array.isArray(mirror.consumerEvidence) || mirror.consumerEvidence.length === 0) return [diagnostic({
    code: "PMIRROR_NO_CONSUMER", severity: "warning", artifact: ".planning/state.json", field: "disposition",
    expected: "demonstrated repository-file consumer or no mirror", actual: "mirror present without demonstrated consumer",
    authority: ".planning/STATE.md + .planning/ROADMAP.md", evidence: "Repository and installed-runtime searches found no code path that reads this file as input",
    repair: "Propose an explicit ignore or remove action for the disposable mirror; this command does not apply either action.",
  })];
  let value;
  try {
    value = JSON.parse(mirror.content);
  } catch (error) {
    return [diagnostic({
      code: "PMIRROR_METADATA_INVALID", severity: "error", artifact: ".planning/state.json", field: "schema",
      expected: { contract: "1.0.0", flavor: "core" }, actual: null, authority: "installed GSD state contract",
      evidence: error.message, repair: "Propose an atomic regeneration through the supported GSD publisher; never repair inline.",
    })];
  }
  if (value.contract !== "1.0.0" || value.flavor !== "core" || !Array.isArray(value.phases)) return [diagnostic({
    code: "PMIRROR_METADATA_INVALID", severity: "error", artifact: ".planning/state.json", field: "schema",
    expected: { contract: "1.0.0", flavor: "core", phases: "array" }, actual: { contract: value.contract, flavor: value.flavor, phases: Array.isArray(value.phases) ? "array" : typeof value.phases },
    authority: "installed GSD state contract", evidence: mirror.consumerEvidence.join("; "),
    repair: "Propose an atomic regeneration through the supported GSD publisher; never repair inline.",
  })];
  const expectedMilestone = activeScope.active && activeScope.active.milestone;
  if (expectedMilestone && !String(value.milestone || "").startsWith(expectedMilestone)) return [diagnostic({
    code: "PMIRROR_CONTENT_MISMATCH", severity: "error", artifact: ".planning/state.json", field: "milestone",
    expected: expectedMilestone, actual: value.milestone || null, authority: ".planning/ROADMAP.md + .planning/STATE.md",
    evidence: mirror.consumerEvidence.join("; "), repair: "Propose atomically regenerating the disposable mirror from canonical Markdown owners.",
  })];
  return [];
}

function evaluatePlanningHealth(snapshot) {
  const activeScope = resolveActiveScope(snapshot);
  const diagnostics = [...activeScope.diagnostics, ...activeArtifactDiagnostics(snapshot, activeScope), ...mirrorDiagnostics(snapshot, activeScope), ...validateMilestoneHistory(snapshot)];
  const completionClaimed = activeScope.phase && (activeScope.phase.complete || activeScope.state.status === "complete");
  const canonicalPhase = activeScope.phase && resolveCanonicalPhaseDirectory(snapshot, activeScope.phase.number);
  if (completionClaimed && canonicalPhase.status === "resolved") diagnostics.push(...validateCompletionProof(snapshot, activeScope.phase.number));
  for (const error of Array.isArray(snapshot && snapshot.collectionErrors) ? snapshot.collectionErrors : []) {
    diagnostics.push(diagnostic({
      code: error.code, severity: "error", artifact: error.artifact, field: error.field,
      expected: error.expected, actual: error.actual, authority: error.artifact,
      evidence: error.evidence, repair: "Restore a stable readable canonical source, then re-run planning health.", incomplete: true,
    }));
  }
  diagnostics.sort((left, right) => compareText(left.artifact, right.artifact) || compareText(left.code, right.code));
  const result = { schemaVersion: SCHEMA_VERSION, reportType: "planning-health", generatedAt: snapshot && snapshot.generatedAt, activeScope, diagnostics, conclusion: null };
  const code = exitCodeFor(result);
  result.conclusion = {
    status: code === 0 ? "healthy" : code === 1 ? "policy-error" : "incomplete",
    exitCode: code,
    errorCount: diagnostics.filter(({ severity }) => severity === "error").length,
    warningCount: diagnostics.filter(({ severity }) => severity === "warning").length,
    infoCount: diagnostics.filter(({ severity }) => severity === "info").length,
    diagnosticCodes: diagnostics.map(({ code: diagnosticCode }) => diagnosticCode),
  };
  return result;
}

function escapeTerminal(value) {
  return String(value).replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g, (character) => `\\u${character.codePointAt(0).toString(16).padStart(4, "0")}`);
}

function renderHuman(result) {
  if (result && result.reportType === "planning-health") {
    const active = result.activeScope && result.activeScope.active;
    const lines = [
      "Planning health (read-only)",
      `Active milestone: ${escapeTerminal(active ? active.milestone : "unresolved")}`,
      `Active phase: ${escapeTerminal(active ? active.phase : "unresolved")}`,
      "Diagnostics:",
    ];
    if (result.diagnostics.length === 0) lines.push("- none");
    for (const item of result.diagnostics) {
      lines.push(`- [${item.severity}] ${item.code} ${escapeTerminal(item.artifact)}.${escapeTerminal(item.field)} expected=${escapeTerminal(JSON.stringify(item.expected))} actual=${escapeTerminal(JSON.stringify(item.actual))} authority=${escapeTerminal(item.authority)} evidence=${escapeTerminal(item.evidence)}; repair=${escapeTerminal(item.repair)}`);
    }
    lines.push(`Conclusion: ${result.conclusion.status} (exit ${result.conclusion.exitCode}; codes=${result.conclusion.diagnosticCodes.join(",") || "none"})`);
    return `${lines.join("\n")}\n`;
  }
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
  collectTagIdentities,
  collectPlanningSnapshot,
  collectRepositorySnapshot,
  evaluatePlanningHealth,
  evaluateRepositoryInventory,
  exitCodeFor,
  makeDiagnostic,
  parseCommittedRequirements,
  parseStatus,
  parseWorktreeList,
  renderHuman,
  renderJson,
  readBoundedRepositoryFile,
  readPackageVersion,
  resolveActiveScope,
  resolveCanonicalPhaseDirectory,
  validateCompletionProof,
  validateMilestoneHistory,
};
