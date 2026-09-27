#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const RULESET_URL = (repository) => `https://github.com/${repository}/settings/rules`;
const ENV_URL = (repository) => `https://github.com/${repository}/settings/environments`;
const REQUIRED_RULES = ["update", "deletion"];

function validRepository(repository) {
  return typeof repository === "string" && /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository);
}

function inspectRuleset(ruleset) {
  if (!ruleset || ruleset.target !== "tag" || ruleset.enforcement !== "active") return false;
  if (!Array.isArray(ruleset.bypass_actors) || ruleset.bypass_actors.length !== 0) return false;
  const refs = ruleset.conditions?.ref_name;
  if (!Array.isArray(refs?.include) || !refs.include.includes("refs/tags/v*") || !Array.isArray(refs.exclude) || refs.exclude.length > 0) return false;
  const types = new Set((ruleset.rules || []).map((rule) => rule?.type));
  return REQUIRED_RULES.every((rule) => types.has(rule));
}

function workflowUsesEnvironment(workflowText) {
  const sources = Array.isArray(workflowText) ? workflowText : [workflowText];
  return sources.length >= 2 && sources.every((source) => typeof source === "string" && /^\s{4}environment:\s*hex-production\s*$/m.test(source));
}

function evaluatePolicy({ rulesets, environments, workflowText, repository }) {
  if (!validRepository(repository)) return {
    observed: false, verified: false, reason: "invalid_repository", expected: "owner/repository", observedIdentity: repository || "missing",
    nextStep: "Pass the GitHub owner/repository name and rerun readback.",
  };
  const matching = Array.isArray(rulesets) ? rulesets.find((ruleset) => inspectRuleset(ruleset)) : null;
  const environment = Array.isArray(environments) ? environments.find((item) => item?.name === "hex-production" && Number.isSafeInteger(item.id) && item.id > 0) : null;
  const workflowReady = workflowUsesEnvironment(workflowText);
  const gaps = [];
  if (!matching) gaps.push("no active tag ruleset covers refs/tags/v* with update and deletion restrictions and no bypass actors");
  if (!environment) gaps.push("the hex-production environment is missing or unreadable");
  if (!workflowReady) gaps.push("both release workflows must reference hex-production");
  const settings = RULESET_URL(repository);
  const environmentsPage = ENV_URL(repository);
  const verified = gaps.length === 0;
  return {
    observed: Array.isArray(rulesets) && Array.isArray(environments),
    verified,
    reason: verified ? null : gaps.join("; "),
    expected: "active refs/tags/v* ruleset blocks update and deletion with no bypass; configured hex-production environment used by both workflows",
    observedIdentity: verified ? `ruleset ${matching.id}; environment ${environment.id}` : gaps.join("; "),
    tagRuleset: matching ? { id: matching.id, name: matching.name, target: matching.target, enforcement: matching.enforcement } : null,
    environment: environment ? { id: environment.id, name: environment.name, protectionRuleCount: (environment.protection_rules || []).length } : null,
    rulesetUrl: settings,
    environmentUrl: environmentsPage,
    nextStep: verified ? "Keep this readback with the exact-SHA CI proof; rerun it after any settings change." : `Configure the missing policy in ${settings} or ${environmentsPage}, then rerun release policy readback.`,
  };
}

function ghJson(endpoint, options = {}) {
  const result = spawnSync(options.ghBin || process.env.RELEASE_REMOTE_GATE_GH_BIN || "gh", ["api", endpoint], {
    encoding: "utf8",
    env: options.env || process.env,
    timeout: options.timeoutMs || 15_000,
    maxBuffer: 2 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) throw new Error("GitHub readback failed; confirm repository metadata read access and retry.");
  try { return JSON.parse(result.stdout); } catch { throw new Error("GitHub readback returned invalid JSON; retry when the API is available."); }
}

async function observePolicy(repository, adapters = {}) {
  if (!validRepository(repository)) return evaluatePolicy({ repository });
  const result = { observed: false, verified: false, reason: "github_readback_unavailable", expected: "ruleset and environment metadata", observedIdentity: "unavailable", rulesetUrl: RULESET_URL(repository), environmentUrl: ENV_URL(repository), nextStep: "Confirm GitHub repository metadata read access, then rerun the read-only policy gate." };
  try {
    const getRulesets = adapters.getRulesets || (async () => ghJson(`repos/${repository}/rulesets?includes_parents=true`));
    const getRuleset = adapters.getRuleset || (async (id) => ghJson(`repos/${repository}/rulesets/${id}`));
    const getEnvironment = adapters.getEnvironment || (async (name) => ghJson(`repos/${repository}/environments/${encodeURIComponent(name)}`));
    const [listed, environment] = await Promise.all([getRulesets(), getEnvironment("hex-production")]);
    const details = await Promise.all((Array.isArray(listed) ? listed : []).map((item) => getRuleset(item.id)));
    let workflowText = adapters.workflowText;
    if (workflowText === undefined) {
      workflowText = ["release-please.yml", "hex-publish.yml"].map((file) => fs.readFileSync(path.join(__dirname, "..", ".github", "workflows", file), "utf8"));
    }
    const evaluated = evaluatePolicy({ rulesets: details, environments: [environment], workflowText, repository });
    return { ...evaluated, observed: true };
  } catch (error) {
    return { ...result, error: error.message };
  }
}

async function main() {
  const repository = process.argv[2] || process.env.GH_REPO || process.env.GITHUB_REPOSITORY;
  const result = await observePolicy(repository);
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
  if (!result.verified) process.exitCode = 1;
}

if (require.main === module) main().catch(() => {
  process.stderr.write("Release policy readback failed; confirm GitHub repository metadata read access and retry.\n");
  process.exitCode = 1;
});

module.exports = { evaluatePolicy, inspectRuleset, observePolicy, workflowUsesEnvironment };
