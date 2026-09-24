const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");
const test = require("node:test");

const root = join(__dirname, "..");
const workflow = readFileSync(join(root, ".github", "workflows", "ci.yml"), "utf8");
const proofWriter = readFileSync(join(__dirname, "ci_proof.cjs"), "utf8");

function jobBlock(id) {
  const start = workflow.indexOf(`  ${id}:\n`);
  assert.notEqual(start, -1, `workflow job ${id} is required`);
  const nextMatch = /\n  [a-z0-9-]+:\n/g;
  nextMatch.lastIndex = start + 4;
  const match = nextMatch.exec(workflow);
  const next = match?.index;
  return workflow.slice(start, next === -1 ? undefined : next);
}

function hasStep(job, name, command) {
  const stepStart = job.indexOf(`      - name: ${name}\n`);
  assert.notEqual(stepStart, -1, `missing named step: ${name}`);
  const next = job.indexOf("\n      - ", stepStart + 8);
  const step = job.slice(stepStart, next === -1 ? undefined : next);
  assert.match(step, command, `${name} must run its command`);
  return step;
}

const requiredLaneIds = [
  "test",
  "dialyzer",
  "demo-postgres",
  "package-smoke",
  "optional-deps",
  "planning-truth",
  "quality",
];

test("every CI-01 proof has an executable step in a required aggregate dependency", () => {
  const aggregate = jobBlock("ci-contract");
  const needsBlock = aggregate.match(/\n    needs:\n((?:      - [^\n]+\n)+)/)?.[1] || "";
  const needs = [...needsBlock.matchAll(/^      - ([a-z0-9-]+)$/gm)].map((match) => match[1]);
  for (const id of requiredLaneIds) assert.ok(needs.includes(id), `${id} must be a CI contract dependency`);

  const tests = jobBlock("test");
  hasStep(tests, "Fetch library deps", /run:\s*mix deps\.get/);
  hasStep(tests, "Check formatting", /run:\s*mix format --check-formatted/);
  hasStep(tests, "Check unused deps", /run:\s*mix deps\.unlock --check-unused/);
  hasStep(tests, "Compile (warnings as errors)", /run:\s*mix compile --warnings-as-errors/);
  hasStep(tests, "Run tests", /run:\s*mix test/);
  const dialyzer = jobBlock("dialyzer");
  hasStep(dialyzer, "Fetch library deps", /run:\s*mix deps\.get/);
  hasStep(dialyzer, "Check public specs", /run:\s*mix typecheck\.specs/);
  hasStep(dialyzer, "Run Dialyzer", /run:\s*mix dialyzer/);

  const demo = jobBlock("demo-postgres");
  assert.match(demo, /services:\s*\n\s+postgres:/);
  hasStep(demo, "Fetch demo deps", /run:\s*mix deps\.get/);
  hasStep(demo, "Check demo formatting", /run:\s*mix format --check-formatted/);
  hasStep(demo, "Check demo unused deps", /run:\s*mix deps\.unlock --check-unused/);
  hasStep(demo, "Compile demo (warnings as errors)", /run:\s*mix compile --warnings-as-errors/);
  hasStep(demo, "Run demo tests", /run:\s*mix test/);
  hasStep(jobBlock("package-smoke"), "Build and compile fresh package consumer", /run:\s*bin\/package_smoke\.sh/);
  const optional = jobBlock("optional-deps");
  hasStep(optional, "Fetch library deps", /run:\s*mix deps\.get/);
  hasStep(optional, "Prove MockServer with optional deps", /run:\s*MIX_ENV=test mix test test\/paddle\/mock_server_test\.exs/);
  hasStep(optional, "Prove fresh consumer without optional fixture deps", /run:\s*bin\/package_smoke\.sh/);

  const planning = jobBlock("planning-truth");
  for (const pattern of [
    /name: Fetch and assert historical tags/,
    /name: Derive exact history range/,
    /Run clean production Node suite/,
    /Enforce Phase 31 prohibition descriptors/,
    /Guard base-to-head planning history/,
    /Smoke live planning health JSON/,
  ]) assert.match(planning, pattern);

  const quality = jobBlock("quality");
  assert.match(quality, /name:\s+quality checks/);
  assert.match(quality, /version-file:\s*\.tool-versions/);
  assert.match(hasStep(quality, "Credo strict lint", /run:\s*mix credo --strict/), /if:\s*\$\{\{\s*always\(\)\s*\}\}/);
  assert.match(hasStep(quality, "Build ExDoc", /run:\s*mix docs/), /if:\s*\$\{\{\s*always\(\)\s*\}\}/);
  const audit = hasStep(quality, "Audit Hex advisories", /run:\s*mix hex\.audit/);
  assert.match(audit, /if:\s*\$\{\{\s*always\(\)\s*\}\}/);
  assert.doesNotMatch(audit, /continue-on-error:\s*true/, "network and advisory failures must fail the quality job");
});

test("quality proof identity is required by workflow and proof writer", () => {
  assert.match(workflow, /quality:\s*\n\s+name:\s+quality checks/);
  assert.match(proofWriter, /"quality"/);
  assert.match(workflow, /needs:[\s\S]*?- quality[\s\S]*?if:\s*\$\{\{\s*always\(\)\s*\}\}/);
});

test("proof toolchain extracts the Rebar version format emitted by rebar3", () => {
  const proof = jobBlock("ci-contract");
  const toolchain = hasStep(proof, "Install proof toolchain", /mix local\.rebar --force/);
  assert.match(toolchain, /HEX_VERSION=.*-type d -name 'hex-\*'.*-type f -name 'hex-\*\.ez'/);
  assert.match(toolchain, /REBAR_VERSION=.*version 2>&1 \| sed -nE/);
  assert.equal("rebar 3.25.1 on Erlang/OTP 28 Erts 16.1".match(/^rebar ([0-9.]+)/)?.[1], "3.25.1");
});

test("CI runners, timeouts, and cache identities stay bounded and toolchain-aware", () => {
  for (const id of [...requiredLaneIds, "ci-contract"]) {
    const job = jobBlock(id);
    assert.match(job, /runs-on: ubuntu-24\.04/, `${id} must use the stable Ubuntu runner image`);
    assert.match(job, /timeout-minutes: [1-9][0-9]*/, `${id} must have an explicit timeout`);
  }
  assert.ok(workflow.includes("key: ${{ runner.os }}-${{ hashFiles('.tool-versions') }}-library-${{ hashFiles('mix.lock') }}"));
  assert.ok(workflow.includes("key: ${{ runner.os }}-${{ hashFiles('.tool-versions') }}-demo-${{ hashFiles('demo/mix.lock') }}"));
  assert.doesNotMatch(workflow, /restore-keys:/, "dependency caches must not fall back across lock or toolchain identities");
  const pltSave = workflow.slice(workflow.indexOf("      - name: Save PLTs"), workflow.indexOf("\n  demo-postgres:"));
  assert.match(pltSave, /if: success\(\)/, "failed or cancelled analysis must not save a PLT cache");
  assert.match(workflow, /image: postgres:17(?:\s|$)/, "retain the supported PostgreSQL major for demo tests");
});

test("Credo stays development and test only and absent from runtime dependencies", () => {
  const mixExs = readFileSync(join(root, "mix.exs"), "utf8");
  assert.match(mixExs, /\{:credo, "~> 1\.7", only: \[:dev, :test\], runtime: false\}/);
});
