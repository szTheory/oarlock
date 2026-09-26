#!/usr/bin/env node
"use strict";

const https = require("node:https");

const API = "https://api.github.com";
const MAX_PAGES = 100;
const MAX_BODY_BYTES = 2 * 1024 * 1024;
const TIMEOUT_MS = 15_000;
const STATES = new Set(["needs-triage", "needs-info", "ready", "in-progress", "blocked"]);
const SCOPES = new Set(["in-scope", "deferred", "out-of-scope"]);
const FIELDS = ["Date", "State", "Owner", "Scope", "Next action", "Action owner", "Review by", "Information needed"];
const HELP = `Usage: node scripts/triage_audit.cjs [--json] [--inventory-only] [--help]\n\n`+
  `Read-only audit of open GitHub issues and pull requests against dated maintainer triage comments.\n`+
  `Requires GH_TOKEN or GITHUB_TOKEN with repository read access. Never mutates GitHub.\n\n`+
  `Options:\n  --json             Emit deterministic JSON\n  --inventory-only   Report disposition gaps; complete collection exits 0\n  --help             Show this help\n`;

function safeError(error) {
  const status = Number(error?.statusCode || error?.status);
  if (Number.isInteger(status) && status > 0) return `GitHub GET failed with HTTP ${status}`;
  if (error?.code === "ETIMEDOUT" || error?.code === "ESOCKETTIMEDOUT") return "GitHub GET timed out";
  if (error?.code === "ERR_BODY_TOO_LARGE") return "GitHub response exceeded the size limit";
  return "GitHub GET failed; response details were omitted";
}

function requestJson(url, options = {}) {
  return new Promise((resolve, reject) => {
    const headers = {
      accept: "application/vnd.github+json",
      "user-agent": "oarlock-triage-audit",
      "x-github-api-version": "2022-11-28",
      ...(options.token ? { authorization: `Bearer ${options.token}` } : {}),
    };
    const request = https.get(url, { headers, timeout: options.timeoutMs || TIMEOUT_MS }, (response) => {
      const chunks = [];
      let size = 0;
      response.on("data", (chunk) => {
        size += chunk.length;
        if (size > (options.maxBodyBytes || MAX_BODY_BYTES)) {
          const error = new Error("response too large");
          error.code = "ERR_BODY_TOO_LARGE";
          request.destroy(error);
          return;
        }
        chunks.push(chunk);
      });
      response.on("end", () => {
        const statusCode = response.statusCode || 0;
        if (statusCode < 200 || statusCode >= 300) {
          const error = new Error("GitHub returned a non-success status");
          error.statusCode = statusCode;
          reject(error);
          return;
        }
        try {
          const data = JSON.parse(Buffer.concat(chunks).toString("utf8"));
          resolve({ data, headers: response.headers });
        } catch (_error) {
          const error = new Error("GitHub returned invalid JSON");
          error.code = "ERR_INVALID_JSON";
          reject(error);
        }
      });
    });
    request.on("timeout", () => request.destroy(Object.assign(new Error("timeout"), { code: "ETIMEDOUT" })));
    request.on("error", reject);
  });
}

function nextLink(header, expectedPath) {
  if (!header) return null;
  for (const part of String(header).split(/,(?=\s*<)/)) {
    const match = /^\s*<([^>]+)>\s*;(.*)$/.exec(part);
    if (!match || !/(?:^|;)\s*rel="?next"?(?:;|$)/.test(`;${match[2]}`)) continue;
    const url = new URL(match[1]);
    if (url.protocol !== "https:" || url.hostname !== "api.github.com" || url.pathname !== expectedPath || url.username || url.password) {
      throw new Error("GitHub returned an unsafe pagination link");
    }
    return url.toString();
  }
  return null;
}

function validateRepository(repository) {
  if (typeof repository !== "string" || !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
    throw new Error("repository must be OWNER/NAME");
  }
  return repository;
}

async function getAllPages(initialUrl, expectedPath, get) {
  const rows = [];
  const visited = new Set();
  let url = initialUrl;
  for (let page = 0; url; page += 1) {
    if (page >= MAX_PAGES) throw new Error("GitHub pagination exceeded the page limit");
    if (visited.has(url)) throw new Error("GitHub pagination repeated a page");
    visited.add(url);
    const response = await get(url);
    const data = Array.isArray(response) ? response : response?.data;
    if (!Array.isArray(data)) throw new Error("GitHub page was not an array");
    if (data.length > 100) throw new Error("GitHub page exceeded the requested item limit");
    rows.push(...data);
    if (rows.length > 10_000) throw new Error("GitHub inventory exceeded the item limit");
    url = nextLink(response?.headers?.link || response?.headers?.Link, expectedPath);
  }
  return rows;
}

function isPullRequest(row) {
  return Object.prototype.hasOwnProperty.call(row, "pull_request");
}

function validateItem(row, repository) {
  if (!row || !Number.isSafeInteger(row.number) || row.number < 1 || !Number.isSafeInteger(row.id) || row.id < 1) {
    throw new Error("GitHub returned an item with invalid identity");
  }
  if (row.state !== "open" || row.repository_url !== `${API}/repos/${repository}`) {
    throw new Error("GitHub returned an item with inconsistent repository or state");
  }
  const kind = isPullRequest(row) ? "pull_request" : "issue";
  const expectedSegment = kind === "pull_request" ? "pull" : "issues";
  const expectedUrl = `https://github.com/${repository}/${expectedSegment}/${row.number}`;
  if (row.html_url !== expectedUrl || (kind === "pull_request" && row.pull_request?.url !== `${API}/repos/${repository}/pulls/${row.number}`)) {
    throw new Error("GitHub returned an item with inconsistent URL identity");
  }
  if (typeof row.title !== "string" || !row.title || !Number.isFinite(Date.parse(row.created_at))) {
    throw new Error("GitHub returned an item with invalid metadata");
  }
  return { number: row.number, id: row.id, kind, state: "open", title: row.title.slice(0, 300), url: expectedUrl, labels: Array.isArray(row.labels) ? row.labels.map((label) => String(label?.name || "").slice(0, 80)).slice(0, 100) : [] };
}

function hasCandidateMarker(comment) {
  return typeof comment?.body === "string" && /oarlock-triage/.test(comment.body);
}

function extractActionOwner(body) {
  if (typeof body !== "string") return null;
  const blocks = [...body.matchAll(/```oarlock-triage\s*\n([\s\S]*?)\n```/g)];
  if (blocks.length !== 1) return null;
  const matches = blocks[0][1].split(/\r?\n/)
    .map((line) => /^Action owner:\s*(.*)$/.exec(line))
    .filter(Boolean);
  if (matches.length !== 1) return null;
  const login = matches[0][1].trim();
  return /^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$/.test(login) ? login : null;
}

async function collect(repository, options = {}) {
  repository = validateRepository(repository);
  const token = options.token ?? process.env.GH_TOKEN ?? process.env.GITHUB_TOKEN ?? "";
  if (!options.get && !token) {
    return { repository, complete: false, issues: [], errors: [{ code: "TRIAGE_AUTH_UNAVAILABLE", evidence: "GH_TOKEN or GITHUB_TOKEN with read access is required" }] };
  }
  const get = options.get || ((url) => requestJson(url, { token, timeoutMs: options.timeoutMs, maxBodyBytes: options.maxBodyBytes }));
  const errors = [];
  let rows;
  try {
    const path = `/repos/${repository}/issues`;
    rows = await getAllPages(`${API}${path}?state=open&per_page=100&page=1`, path, get);
  } catch (error) {
    return { repository, complete: false, issues: [], errors: [{ code: "TRIAGE_INVENTORY_INCOMPLETE", evidence: safeError(error) }] };
  }

  const issues = [];
  const seen = new Set();
  try {
    const validated = rows.map((row) => ({ row, identity: validateItem(row, repository) }));
    for (const { identity } of validated) {
      const key = `${identity.kind}:${identity.number}`;
      if (seen.has(key)) throw new Error("GitHub returned duplicate item identities");
      seen.add(key);
    }
    for (const { row, identity } of validated) {
      const commentsPath = `/repos/${repository}/issues/${identity.number}/comments`;
      const comments = await getAllPages(`${API}${commentsPath}?per_page=100&page=1`, commentsPath, get);
      if (comments.some((comment) => !Number.isSafeInteger(comment?.id) || !Number.isFinite(Date.parse(comment?.created_at))
        || (typeof comment.body === "string" && Buffer.byteLength(comment.body, "utf8") > 32 * 1024))) {
        throw new Error("GitHub returned a comment with invalid identity");
      }
      const parsed = [];
      for (const candidate of comments.filter(hasCandidateMarker)) {
        const login = candidate.user?.login;
        if (typeof login !== "string" || !/^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$/.test(login)) {
          parsed.push({ ...candidate, author: null, permission: null, permissionError: true });
          continue;
        }
        let permission = null;
        let permissionError = false;
        try {
          const permissionPath = `/repos/${repository}/collaborators/${encodeURIComponent(login)}/permission`;
          const response = await get(`${API}${permissionPath}`);
          const data = Array.isArray(response) ? null : response?.data ?? response;
          permission = data?.permission;
          if (!new Set(["admin", "write"]).has(permission)) permissionError = false;
        } catch (_error) {
          permissionError = true;
        }
        const actionOwner = extractActionOwner(candidate.body);
        let actionOwnerPermission = null;
        let actionOwnerPermissionError = !actionOwner;
        if (actionOwner) {
          try {
            const permissionPath = `/repos/${repository}/collaborators/${encodeURIComponent(actionOwner)}/permission`;
            const response = await get(`${API}${permissionPath}`);
            const data = Array.isArray(response) ? null : response?.data ?? response;
            actionOwnerPermission = data?.permission;
            actionOwnerPermissionError = !new Set(["admin", "write"]).has(actionOwnerPermission);
          } catch (_error) {
            actionOwnerPermissionError = true;
          }
        }
        parsed.push({ ...candidate, author: login, permission, permissionError, actionOwnerPermission, actionOwnerPermissionError });
      }
      issues.push({ ...identity, comments: parsed });
    }
  } catch (error) {
    errors.push({ code: "TRIAGE_COLLECTION_INCOMPLETE", evidence: safeError(error) });
  }
  return { repository, complete: errors.length === 0 && issues.length === rows.length, issues, errors };
}

function validDate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(parsed.valueOf()) && parsed.toISOString().slice(0, 10) === value;
}

function parseDisposition(comment, permission) {
  const candidate = {
    id: comment.id,
    created_at: comment.created_at,
    body: comment.body,
    user: comment.user,
    author: comment.user?.login || comment.author || null,
    permission: permission ?? comment.permission ?? null,
    permissionError: Boolean(comment.permissionError),
    actionOwnerPermission: comment.actionOwnerPermission ?? null,
    actionOwnerPermissionError: Boolean(comment.actionOwnerPermissionError),
  };
  const body = typeof comment.body === "string" ? comment.body : "";
  const blocks = [...body.matchAll(/```oarlock-triage\s*\n([\s\S]*?)\n```/g)];
  const failures = [];
  if (candidate.permissionError) failures.push("maintainer permission could not be verified");
  if (!new Set(["admin", "write"]).has(candidate.permission)) failures.push("comment author lacks verified write or admin permission");
  if (candidate.actionOwnerPermissionError || !new Set(["admin", "write"]).has(candidate.actionOwnerPermission)) {
    failures.push("action owner lacks verified write or admin permission");
  }
  if (blocks.length !== 1) failures.push("expected exactly one complete oarlock-triage block");
  if (failures.length) return { ok: false, candidate, errors: failures };

  const fields = Object.create(null);
  for (const line of blocks[0][1].split(/\r?\n/)) {
    const match = /^([^:]+):\s*(.*)$/.exec(line);
    if (!match) {
      if (line.trim()) failures.push("triage block contains an invalid field line");
      continue;
    }
    const key = match[1].trim();
    if (!FIELDS.includes(key)) failures.push("triage block contains an unknown field");
    else if (Object.hasOwn(fields, key)) failures.push("triage block contains a duplicate field");
    else fields[key] = match[2].trim();
  }
  for (const required of FIELDS.slice(0, 7)) if (!fields[required]) failures.push(`missing ${required}`);
  if (fields.State && !STATES.has(fields.State)) failures.push("invalid State");
  if (fields.Scope && !SCOPES.has(fields.Scope)) failures.push("invalid Scope");
  if (fields.Owner && fields.Owner !== "unknown" && !/^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$/.test(fields.Owner)) failures.push("invalid Owner");
  if (fields["Action owner"] && !/^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$/.test(fields["Action owner"])) failures.push("invalid Action owner");
  if (fields.Date && !validDate(fields.Date)) failures.push("invalid Date");
  if (fields["Review by"] && !validDate(fields["Review by"])) failures.push("invalid Review by");
  if (fields.Date && fields["Review by"] && fields["Review by"] < fields.Date) failures.push("Review by precedes Date");
  if (fields.Date && candidate.created_at && fields.Date !== candidate.created_at.slice(0, 10)) failures.push("Date does not match the comment date");
  if (fields.State === "needs-info" && !fields["Information needed"]) failures.push("needs-info requires Information needed");
  if (fields["Information needed"] && fields.State !== "needs-info") failures.push("Information needed is valid only for needs-info");
  if (failures.length) return { ok: false, candidate, errors: [...new Set(failures)] };
  return {
    ok: true,
    candidate,
    disposition: {
      date: fields.Date,
      state: fields.State,
      owner: fields.Owner,
      scope: fields.Scope,
      next_action: fields["Next action"].slice(0, 240),
      action_owner: fields["Action owner"],
      review_by: fields["Review by"],
      ...(fields["Information needed"] ? { information_needed: fields["Information needed"].slice(0, 240) } : {}),
    },
  };
}

function compatible(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function evaluate(collection) {
  const errors = Array.isArray(collection?.errors) ? collection.errors.map((error) => ({ code: error.code, evidence: error.evidence })) : [];
  const items = (collection?.issues || []).map((item) => {
    const candidates = (item.comments || []).filter(hasCandidateMarker).map((comment) => parseDisposition(comment, comment.permission));
    candidates.sort((a, b) => String(a.candidate.created_at).localeCompare(String(b.candidate.created_at)) || a.candidate.id - b.candidate.id);
    const diagnostics = [];
    const cues = [];
    let selected = null;
    const newest = candidates.at(-1);
    const sameTime = newest ? candidates.filter((entry) => entry.candidate.created_at === newest.candidate.created_at) : [];
    if (!newest) diagnostics.push({ code: "TRIAGE_NO_VERIFIED_RECORD", field: "maintainer_record" });
    else if (!newest.ok) diagnostics.push({ code: "TRIAGE_INVALID_CURRENT_RECORD", field: "maintainer_record", issues: newest.errors });
    else if (sameTime.some((entry) => !entry.ok || !compatible(entry.disposition, newest.disposition))) {
      diagnostics.push({ code: "TRIAGE_CONTRADICTORY_RECORD", field: "same_timestamp_records" });
    } else selected = newest.disposition;
    if (selected) {
      const observedStateLabels = (item.labels || []).filter((label) => label.startsWith("state:"));
      const expectedStateLabel = `state:${selected.state}`;
      if (observedStateLabels.some((label) => label !== expectedStateLabel)) {
        cues.push({ code: "TRIAGE_LABEL_DRIFT", observed: observedStateLabels.sort(), expected: expectedStateLabel });
      }
    }
    const result = {
      kind: item.kind,
      number: item.number,
      title: item.title,
      url: item.url,
      labels: item.labels || [],
      disposition: selected,
      diagnostics,
      cues,
    };
    return result;
  });
  items.sort((a, b) => a.kind.localeCompare(b.kind) || a.number - b.number);
  const inventory = {
    issues: items.filter((item) => item.kind === "issue").length,
    pull_requests: items.filter((item) => item.kind === "pull_request").length,
    total: items.length,
  };
  const complete = Boolean(collection?.complete) && errors.length === 0;
  const gaps = items.filter((item) => item.diagnostics.length > 0).length;
  return {
    schema_version: 1,
    repository: collection?.repository || null,
    collection: { complete, errors },
    inventory,
    items,
    gaps,
    conclusion: complete && gaps === 0 ? "complete" : "incomplete",
  };
}

function renderHuman(report) {
  const lines = [
    `Triage audit: ${report.repository || "unknown repository"}`,
    `Collection: ${report.collection.complete ? "complete" : "incomplete"}`,
    `Open items: ${report.inventory.total} (${report.inventory.issues} issues, ${report.inventory.pull_requests} pull requests)`,
  ];
  for (const error of report.collection.errors) lines.push(`Collection error: ${error.code} — ${error.evidence}`);
  for (const item of report.items) {
    const status = item.disposition ? `${item.disposition.state}; owner ${item.disposition.owner}; ${item.disposition.scope}` : item.diagnostics.map((entry) => entry.code).join(", ");
    lines.push(`${item.kind} #${item.number}: ${status}`);
    for (const cue of item.cues || []) lines.push(`  Cue: labels ${cue.observed.join(", ")} differ from maintainer state ${cue.expected}`);
  }
  lines.push(`Conclusion: ${report.conclusion}${report.gaps ? ` (${report.gaps} disposition gaps)` : ""}`);
  return `${lines.join("\n")}\n`;
}

async function main(argv = process.argv.slice(2), options = {}) {
  const allowed = new Set(["--json", "--inventory-only", "--help"]);
  const unknown = argv.filter((argument) => !allowed.has(argument));
  if (argv.includes("--help")) {
    (options.stdout || process.stdout).write(HELP);
    return 0;
  }
  if (unknown.length) {
    (options.stderr || process.stderr).write(`Unknown option: ${unknown.join(", ")}\n${HELP}`);
    return 2;
  }
  let result;
  try {
    const repository = options.repository || process.env.GITHUB_REPOSITORY;
    result = evaluate(await collect(repository, options));
  } catch (error) {
    result = evaluate({ repository: options.repository || process.env.GITHUB_REPOSITORY || null, complete: false, issues: [], errors: [{ code: "TRIAGE_COLLECTION_INCOMPLETE", evidence: safeError(error) }] });
  }
  (options.stdout || process.stdout).write(argv.includes("--json") ? `${JSON.stringify(result, null, 2)}\n` : renderHuman(result));
  if (!result.collection.complete) return 2;
  return argv.includes("--inventory-only") || result.conclusion === "complete" ? 0 : 1;
}

if (require.main === module) main().then((code) => { process.exitCode = code; });

module.exports = { HELP, collect, evaluate, main, parseDisposition, renderHuman };
