const assert = require("node:assert/strict");
const fs = require("node:fs");
const test = require("node:test");

const read = (file) => fs.readFileSync(file, "utf8");

test("contributor guidance gives a bounded change path and proportional proof", () => {
  const contributing = read("CONTRIBUTING.md");
  assert.match(contributing, /one issue/i);
  assert.match(contributing, /smallest example/i);
  assert.match(contributing, /checks proportionate/i);
  assert.match(contributing, /exact candidate commit SHA/i);
  assert.match(contributing, /owner is unknown/i);
  assert.match(contributing, /SECURITY\.md/);
});

test("bug and proposal forms collect distinct bounded intent and evidence", () => {
  const bug = read(".github/ISSUE_TEMPLATE/bug_report.yml");
  const proposal = read(".github/ISSUE_TEMPLATE/change_proposal.yml");

  assert.match(bug, /labels:\n  - kind:bug/);
  assert.match(bug, /id: intent/);
  assert.match(bug, /id: observed/);
  assert.match(bug, /id: reproduction/);
  assert.match(bug, /credentials, customer data, or/);
  assert.match(proposal, /labels:\n  - kind:proposal/);
  assert.match(proposal, /id: intent/);
  assert.match(proposal, /id: proposal/);
  assert.match(proposal, /id: scope/);
  assert.match(proposal, /id: rationale/);
  assert.doesNotMatch(`${bug}\n${proposal}`, /state:(needs-triage|needs-info|ready|in-progress|blocked)/);
});

test("pull request template asks for bounded scope, risk, and exact-SHA proof", () => {
  const template = read(".github/pull_request_template.md");
  assert.match(template, /single outcome/i);
  assert.match(template, /Scope and non-goals/);
  assert.match(template, /Risk and compatibility/);
  assert.match(template, /Proof actually run/);
  assert.match(template, /Candidate commit SHA/);
  assert.match(template, /CI contract.*exact SHA/i);
  assert.match(template, /Do not claim checks you did\s+not run/i);
});

test("issue chooser and security policy use the verified private route", () => {
  const chooser = read(".github/ISSUE_TEMPLATE/config.yml");
  const security = read("SECURITY.md");
  const privateRoute = "https://github.com/szTheory/oarlock/security/advisories/new";

  assert.match(chooser, /blank_issues_enabled: false/);
  assert.ok(chooser.includes(privateRoute));
  assert.ok(security.includes(privateRoute));
  assert.match(security, /Do not report a vulnerability in a public issue or pull request/i);
  assert.match(security, /does not promise a response or remediation\s+time/i);
  assert.match(security, /No person or team is named/i);
  assert.doesNotMatch(security, /[\w.+-]+@[\w.-]+\.[A-Z]{2,}/i);
  assert.doesNotMatch(security, /@(?:[a-z0-9-]+)\b/i);
});
