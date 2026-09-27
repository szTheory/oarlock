const assert = require("node:assert/strict");
const test = require("node:test");
const { evaluatePolicy, observePolicy } = require("./release_remote_gate.cjs");

const ruleset = {
  id: 22,
  name: "Protect release tags",
  target: "tag",
  enforcement: "active",
  bypass_actors: [],
  conditions: { ref_name: { include: ["refs/tags/v*"], exclude: [] } },
  rules: [{ type: "update" }, { type: "deletion" }],
};
const environment = { id: 33, name: "hex-production", protection_rules: [] };
const workflow = [
  "jobs:\n  publish:\n    environment: hex-production\n",
  "jobs:\n  publish:\n    environment: hex-production\n",
];

test("accepts active v-tag update and deletion protection with no bypass and configured environment", () => {
  const result = evaluatePolicy({ rulesets: [ruleset], environments: [environment], workflowText: workflow, repository: "owner/repo" });
  assert.equal(result.observed, true);
  assert.equal(result.verified, true);
  assert.equal(result.tagRuleset.id, 22);
  assert.equal(result.environment.id, 33);
});

test("rejects ineffective, bypassable, or incomplete tag rules", () => {
  const variants = [
    { ...ruleset, enforcement: "disabled" },
    { ...ruleset, target: "branch" },
    { ...ruleset, bypass_actors: [{ actor_id: 1, bypass_mode: "always" }] },
    { ...ruleset, conditions: { ref_name: { include: ["refs/tags/release-*"], exclude: [] } } },
    { ...ruleset, conditions: { ref_name: { include: ["refs/tags/v*"], exclude: ["refs/tags/v1.*"] } } },
    { ...ruleset, rules: [{ type: "deletion" }] },
  ];
  for (const invalid of variants) {
    const result = evaluatePolicy({ rulesets: [invalid], environments: [environment], workflowText: workflow, repository: "owner/repo" });
    assert.equal(result.verified, false);
    assert.match(result.reason, /tag ruleset/i);
    assert.match(result.nextStep, /settings\/rules/);
  }
});

test("blocks a missing environment, missing workflow binding, and read errors without secret access", async () => {
  const missingEnvironment = evaluatePolicy({ rulesets: [ruleset], environments: [], workflowText: workflow, repository: "owner/repo" });
  assert.equal(missingEnvironment.verified, false);
  assert.match(missingEnvironment.environmentUrl, /settings\/environments/);
  const unboundWorkflow = evaluatePolicy({ rulesets: [ruleset], environments: [environment], workflowText: ["jobs: {}", "jobs: {}"], repository: "owner/repo" });
  assert.equal(unboundWorkflow.verified, false);
  const failed = await observePolicy("owner/repo", {
    getRulesets: async () => { throw new Error("403 denied"); },
    getEnvironment: async () => environment,
    getRuleset: async () => ruleset,
  });
  assert.equal(failed.observed, false);
  assert.equal(failed.verified, false);
  assert.match(failed.nextStep, /read access/i);
});

test("readback obtains rules and environment metadata only through GET observations", async () => {
  const calls = [];
  const result = await observePolicy("owner/repo", {
    getRulesets: async () => { calls.push("rulesets"); return [{ id: 22 }]; },
    getRuleset: async (id) => { calls.push(`ruleset:${id}`); return ruleset; },
    getEnvironment: async (name) => { calls.push(`environment:${name}`); return environment; },
    workflowText: workflow,
  });
  assert.equal(result.verified, true);
  assert.deepEqual(calls.sort(), ["environment:hex-production", "ruleset:22", "rulesets"]);
});
