const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const test = require("node:test");
const { collect, evaluate, main, parseDisposition } = require("./triage_audit.cjs");

const REPO = "szTheory/oarlock";

function comment(id, login, body, createdAt = "2026-09-25T10:00:00Z") {
  return { id, user: { login }, body, created_at: createdAt, html_url: `https://github.com/${REPO}/issues/1#issuecomment-${id}` };
}

function record(overrides = {}) {
  const fields = {
    Date: "2026-09-25",
    State: "ready",
    Owner: "octocat",
    Scope: "in-scope",
    "Next action": "Review the proposed API change",
    "Action owner": "octocat",
    "Review by": "2026-10-02",
    ...overrides,
  };
  return ["```oarlock-triage", ...Object.entries(fields).map(([key, value]) => `${key}: ${value}`), "```"].join("\n");
}

function item(number, kind, comments = []) {
  return {
    id: number + 100,
    number,
    state: "open",
    title: `${kind} ${number}`,
    html_url: `https://github.com/${REPO}/${kind === "issue" ? "issues" : "pull"}/${number}`,
    repository_url: `https://api.github.com/repos/${REPO}`,
    created_at: "2026-09-20T10:00:00Z",
    labels: [],
    ...(kind === "pull" ? { pull_request: { url: `https://api.github.com/repos/${REPO}/pulls/${number}` } } : {}),
    _comments: comments,
  };
}

function fixtures(items, overrides = {}) {
  const calls = [];
  const pages = new Map();
  pages.set(`/repos/${REPO}/issues?state=open&per_page=100&page=1`, items.map(({ _comments, ...rest }) => rest));
  for (const row of items) {
    pages.set(`/repos/${REPO}/issues/${row.number}/comments?per_page=100&page=1`, row._comments || []);
  }
  return {
    calls,
    get: async (url) => {
      calls.push(url);
      const parsed = new URL(url, "https://api.github.com");
      const route = `${parsed.pathname}${parsed.search}`;
      if (overrides.get) {
        const overridden = await overrides.get(route, calls);
        if (overridden !== undefined) return overridden;
      }
      if (route.includes("/collaborators/")) return { permission: "write" };
      if (pages.has(route)) return pages.get(route);
      throw new Error(`unexpected GET ${route}`);
    },
  };
}

test("issue and pull request dispositions require complete paginated maintainer comments and permission evidence", async () => {
  const data = fixtures([
    item(1, "issue", [comment(101, "octocat", record())]),
    item(2, "pull", [comment(102, "octocat", record())]),
  ]);
  const result = await collect(REPO, { get: data.get });
  const report = evaluate(result);
  assert.equal(report.collection.complete, true);
  assert.deepEqual(report.inventory, { issues: 1, pull_requests: 1, total: 2 });
  assert.equal(report.items.every((entry) => entry.disposition?.state === "ready"), true);
  assert.equal(report.conclusion, "complete");
  assert.ok(data.calls.every((url) => !/POST|PATCH|PUT|DELETE/i.test(url)));
  assert.ok(data.calls.some((url) => url.includes("/collaborators/octocat/permission")));
});

test("empty complete inventory is an explicit successful zero-item result", async () => {
  const data = fixtures([]);
  const report = evaluate(await collect(REPO, { get: data.get }));
  assert.deepEqual(report.inventory, { issues: 0, pull_requests: 0, total: 0 });
  assert.equal(report.collection.complete, true);
  assert.equal(report.conclusion, "complete");
});

test("contributor imitation, issue body, and state labels do not satisfy a disposition", async () => {
  const row = item(1, "issue", [comment(11, "contributor", record())]);
  row.labels = [{ name: "state:ready" }];
  const data = fixtures([row], { get: async (route) => route.includes("/collaborators/") ? { permission: "read" } : undefined });
  const report = evaluate(await collect(REPO, { get: data.get }));
  assert.equal(report.conclusion, "incomplete");
  assert.equal(report.items[0].disposition, null);
  assert.ok(report.items[0].diagnostics.some((entry) => entry.code === "TRIAGE_INVALID_CURRENT_RECORD"));
});

test("action owners require separate verified collaborator permission", async () => {
  const body = `${record({ "Action owner": "next-owner" })}\nprivate comment prose and token ghp_never-report-this`;
  const row = item(1, "issue", [comment(11, "triage-author", body)]);
  const data = fixtures([row], {
    get: async (route) => {
      if (route.includes("/collaborators/triage-author/permission")) return { permission: "write" };
      if (route.includes("/collaborators/next-owner/permission")) return { permission: "read" };
      return undefined;
    },
  });
  const result = await collect(REPO, { get: data.get });
  const report = evaluate(result);
  assert.equal(report.collection.complete, true);
  assert.equal(report.conclusion, "incomplete");
  assert.equal(report.items[0].disposition, null);
  assert.ok(report.items[0].diagnostics[0].issues.includes("action owner lacks verified write or admin permission"));
  assert.ok(data.calls.some((url) => url.includes("/collaborators/triage-author/permission")));
  assert.ok(data.calls.some((url) => url.includes("/collaborators/next-owner/permission")));
  assert.doesNotMatch(JSON.stringify(report), /private comment prose|ghp_never-report-this/);

  const failedLookup = fixtures([row], {
    get: async (route) => {
      if (route.includes("/collaborators/next-owner/permission")) throw new Error("private response ghp_secret");
      return undefined;
    },
  });
  const failedReport = evaluate(await collect(REPO, { get: failedLookup.get }));
  assert.equal(failedReport.conclusion, "incomplete");
  assert.equal(failedReport.items[0].disposition, null);
  assert.doesNotMatch(JSON.stringify(failedReport), /private response|ghp_secret|private comment prose/);
});

test("state-label drift is reported as a cue and never overrides the dated maintainer decision", async () => {
  const row = item(1, "issue", [comment(11, "octocat", record())]);
  row.labels = [{ name: "kind:bug" }, { name: "state:blocked" }];
  const report = evaluate(await collect(REPO, { get: fixtures([row]).get }));
  assert.equal(report.conclusion, "complete");
  assert.equal(report.items[0].disposition.state, "ready");
  assert.deepEqual(report.items[0].cues, [{ code: "TRIAGE_LABEL_DRIFT", observed: ["state:blocked"], expected: "state:ready" }]);
});

test("pagination follows next links and incomplete or inconsistent pages never claim completeness", async () => {
  const row = item(1, "issue", [comment(1, "octocat", record())]);
  const data = fixtures([row], {
    get: async (route) => {
      if (route.endsWith("page=1") && route.includes("/issues?")) return {
        data: [{ ...row, _comments: undefined }],
        headers: { link: '<https://api.github.com/repos/szTheory/oarlock/issues?state=open&per_page=100&page=2>; rel="next"' },
      };
      if (route.endsWith("page=2") && route.includes("/issues?")) return { data: [], headers: {} };
      if (route.includes("/collaborators/")) return { permission: "write" };
      if (route.includes("/comments?")) return { data: row._comments, headers: {} };
      throw new Error("unavailable");
    },
  });
  const report = evaluate(await collect(REPO, { get: data.get }));
  assert.equal(report.collection.complete, true);
  assert.ok(data.calls.some((url) => url.includes("page=2")));

  const broken = await collect(REPO, { get: async () => { throw new Error("offline"); } });
  assert.equal(evaluate(broken).conclusion, "incomplete");
  assert.equal(evaluate(broken).collection.complete, false);
});

test("malformed newest triage record, equal-time conflict, and needs-info omissions fail closed", async () => {
  assert.equal(parseDisposition(comment(2, "octocat", "```oarlock-triage\nState: ready\n```"), "write").ok, false);
  const first = parseDisposition({ ...comment(4, "octocat", record()), actionOwnerPermission: "write" }, "write");
  const second = parseDisposition({ ...comment(5, "octocat", record({ State: "blocked" })), actionOwnerPermission: "write" }, "write");
  const report = evaluate({
    complete: true,
    issues: [{ number: 1, kind: "issue", state: "open", title: "A", url: "u", labels: [], comments: [first.candidate, second.candidate] }],
    errors: [],
  });
  assert.equal(report.conclusion, "incomplete");
  assert.ok(report.items[0].diagnostics.some((entry) => entry.code === "TRIAGE_CONTRADICTORY_RECORD"));
  assert.equal(parseDisposition(comment(8, "octocat", record({ State: "needs-info" })), "admin").ok, false);
  assert.equal(parseDisposition(comment(9, "octocat", record({ Date: "2026-02-30" })), "write").ok, false);
  assert.equal(parseDisposition(comment(10, "octocat", record({ Scope: "maybe" })), "write").ok, false);
  assert.equal(parseDisposition(comment(11, "octocat", record({ Owner: "" })), "write").ok, false);
  const needsInfo = comment(12, "octocat", record({ State: "needs-info", "Information needed": "Which API version?" }));
  assert.equal(parseDisposition({ ...needsInfo, actionOwnerPermission: "write" }, "admin").ok, true);
});

test("permission lookup failure, malformed pagination identity, and oversized comments are incomplete", async () => {
  const row = item(1, "issue", [comment(1, "octocat", record())]);
  const permissionFailure = fixtures([row], { get: async (route) => route.includes("/collaborators/") ? Promise.reject(new Error("private response")) : undefined });
  const permissionReport = evaluate(await collect(REPO, { get: permissionFailure.get }));
  assert.equal(permissionReport.collection.complete, true);
  assert.equal(permissionReport.conclusion, "incomplete");
  assert.ok(permissionReport.items[0].diagnostics[0].issues.includes("maintainer permission could not be verified"));

  const malformed = await collect(REPO, { get: async () => ({ data: [{}, {}], headers: {} }) });
  assert.equal(evaluate(malformed).collection.complete, false);

  const oversized = item(1, "issue", [comment(1, "octocat", "x".repeat(33 * 1024))]);
  const oversizedResult = await collect(REPO, { get: fixtures([oversized]).get });
  assert.equal(evaluate(oversizedResult).collection.complete, false);
  assert.doesNotMatch(JSON.stringify(evaluate(oversizedResult)), /x{100}/);
});

test("stable report ordering ignores source page order and diagnostics omit raw prose and credentials", async () => {
  const noisy = "private issue text and token ghp_example-secret";
  const a = item(9, "issue", [comment(9, "octocat", record())]);
  const b = item(2, "pull", [comment(2, "octocat", noisy)]);
  const left = evaluate(await collect(REPO, { get: fixtures([a, b]).get }));
  const right = evaluate(await collect(REPO, { get: fixtures([b, a]).get }));
  assert.deepEqual(left.items.map((entry) => entry.number), [9, 2]);
  assert.deepEqual(left.items, right.items);
  assert.doesNotMatch(JSON.stringify(left), /private issue text|ghp_example-secret/);
});

test("CLI inventory-only emits the shared JSON result and exits zero only for complete collection", async () => {
  let output = "";
  const code = await main(["--inventory-only", "--json"], {
    repository: REPO,
    get: fixtures([]).get,
    stdout: { write: (value) => { output += value; } },
  });
  assert.equal(code, 0);
  assert.equal(JSON.parse(output).conclusion, "complete");
  let failedOutput = "";
  const failed = await main(["--inventory-only", "--json"], {
    repository: REPO,
    get: async () => { throw new Error("offline"); },
    stdout: { write: (value) => { failedOutput += value; } },
  });
  assert.equal(failed, 2);
  assert.equal(JSON.parse(failedOutput).conclusion, "incomplete");
});

test("triage guide documents the parser contract and read-only audit behavior", () => {
  const guide = readFileSync(require("node:path").join(__dirname, "../docs/triage.md"), "utf8");
  for (const field of ["Date:", "State:", "Owner:", "Scope:", "Next action:", "Action owner:", "Review by:", "Information needed:"]) {
    assert.ok(guide.includes(field), `missing documented field ${field}`);
  }
  assert.match(guide, /write or admin permission/);
  assert.match(guide, /does not assign, label, close, or comment/);
  assert.match(guide, /--inventory-only --json/);
});
