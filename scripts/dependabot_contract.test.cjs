const assert = require("node:assert/strict");
const { readFileSync, readdirSync } = require("node:fs");
const { join } = require("node:path");
const test = require("node:test");
const { REQUIRED_JOBS } = require("./ci_proof.cjs");

const root = join(__dirname, "..");
const config = readFileSync(join(root, ".github", "dependabot.yml"), "utf8");
const workflow = readFileSync(join(root, ".github", "workflows", "ci.yml"), "utf8");
const proofWriter = readFileSync(join(__dirname, "ci_proof.cjs"), "utf8");

function updateEntries(source) {
  assert.match(source, /^version: 2\s+updates:\s*$/m);
  const start = source.indexOf("updates:\n");
  assert.notEqual(start, -1, "updates list is required");
  const body = source.slice(start + "updates:\n".length);
  const starts = [...body.matchAll(/^  - package-ecosystem: ([^\n]+)$/gm)];
  assert.equal(starts.length, 3, "exactly three independent update entries are required");
  return starts.map((match, index) => {
    const next = starts[index + 1]?.index ?? body.length;
    return { ecosystem: match[1], text: body.slice(match.index, next) };
  });
}

function assertEntry(entry, ecosystem, directory, withGroups) {
  assert.equal(entry.ecosystem, ecosystem);
  assert.match(entry.text, new RegExp(`^  - package-ecosystem: ${ecosystem}$`, "m"));
  assert.match(entry.text, new RegExp(`^    directory: [\"']?${directory.replaceAll("/", "\\/")}[\"']?$`, "m"));
  assert.match(entry.text, /^    schedule:\n      interval: weekly$/m);
  assert.match(entry.text, /^    open-pull-requests-limit: 5$/m);
  if (!withGroups) {
    assert.doesNotMatch(entry.text, /^    groups:$/m, `${directory} Actions must remain individually reviewable`);
    return;
  }

  const routine = entry.text.match(/^      routine:\n((?:        [^\n]*\n|          [^\n]*\n)*)/m)?.[1] || "";
  const security = entry.text.match(/^      security:\n((?:        [^\n]*\n|          [^\n]*\n)*)/m)?.[1] || "";
  assert.match(entry.text, /^    groups:$/m);
  assert.match(routine, /^        update-types:\n          - minor\n          - patch\s*$/m);
  assert.doesNotMatch(routine, /major|security-updates/);
  assert.match(security, /^        applies-to: security-updates$/m);
  assert.match(security, /^        patterns:\n          - "\*"$/m);
  assert.match(security, /^        update-types:\n          - minor\n          - patch\s*$/m);
}

function assertDependabot(source) {
  assert.doesNotMatch(source, /auto-?merge|enable-pull-request-automerge/i);
  const entries = updateEntries(source);
  assertEntry(entries[0], "mix", "/", true);
  assertEntry(entries[1], "mix", "/demo", true);
  assertEntry(entries[2], "github-actions", "/", false);
}

function jobBlock(id) {
  const start = workflow.indexOf(`  ${id}:\n`);
  assert.notEqual(start, -1, `workflow job ${id} is required`);
  const nextMatch = /\n  [a-z0-9-]+:\n/g;
  nextMatch.lastIndex = start + 4;
  const match = nextMatch.exec(workflow);
  return workflow.slice(start, match?.index ?? undefined);
}

test("Dependabot keeps Mix, demo Mix, and Actions update streams separate", () => {
  assertDependabot(config);
  assert.deepEqual(updateEntries(config).map((entry) => [entry.ecosystem, entry.text.match(/^    directory: (.+)$/m)?.[1]]), [
    ["mix", '"/"'],
    ["mix", '"/demo"'],
    ["github-actions", '"/"'],
  ]);
});

test("the contract rejects cross-boundary, major-routine, and collapsed security rules", () => {
  assert.throws(() => assertDependabot(config.replace('directory: "/demo"', 'directory: "/"')));
  assert.throws(() => assertDependabot(config.replace("          - patch\n      security:", "          - major\n      security:")));
  assert.throws(() => assertDependabot(config.replace("applies-to: security-updates", "applies-to: version-updates")));
  assert.throws(() => assertDependabot(config.replace("      security:\n", "      routine-security:\n")));
  assert.throws(() => assertDependabot(`${config}\n# auto-merge`));
});

test("dependency proposals pass through all exact-SHA CI contract jobs", () => {
  assert.match(workflow, /^  pull_request:\s*$/m);
  const aggregate = jobBlock("ci-contract");
  const needsBlock = aggregate.match(/\n    needs:\n((?:      - [^\n]+\n)+)/)?.[1] || "";
  const needs = [...needsBlock.matchAll(/^      - ([a-z0-9-]+)$/gm)].map((match) => match[1]);
  assert.deepEqual(needs, REQUIRED_JOBS);
  assert.match(aggregate, /ref: \$\{\{ github\.sha \}\}/, "aggregate checks out the candidate event SHA");
  assert.match(aggregate, /GITHUB_SHA_VALUE: \$\{\{ github\.sha \}\}/);
  assert.match(aggregate, /CHECKED_OUT_SHA_VALUE: \$\{\{ github\.sha \}\}/);
  assert.match(aggregate, /EVENT_HEAD_SHA_VALUE: \$\{\{ github\.event\.pull_request\.head\.sha \|\| github\.sha \}\}/);
  assert.match(aggregate, /run: node scripts\/ci_proof\.cjs/);
  assert.match(proofWriter, /testedSha\.toLowerCase\(\) !== checkedOutSha\.toLowerCase\(\)/);
  assert.match(proofWriter, /REQUIRED_JOBS\.map/);

  for (const id of REQUIRED_JOBS) assert.ok(needs.includes(id), `${id} remains required`);
  const quality = jobBlock("quality");
  assert.match(quality, /run: mix hex\.audit/);
  assert.match(jobBlock("test"), /run: mix test/);
  assert.match(jobBlock("optional-deps"), /Prove MockServer with optional deps/);
  assert.match(jobBlock("package-smoke"), /bin\/package_smoke\.sh/);
  assert.match(jobBlock("demo-postgres"), /run: mix test/);

  const workflowFiles = readdirSync(join(root, ".github", "workflows"));
  for (const file of workflowFiles) {
    const contents = readFileSync(join(root, ".github", "workflows", file), "utf8");
    assert.doesNotMatch(contents, /gh pr merge|enable-pull-request-automerge|auto-merge action/i,
      `${file} must not create an automatic merge path`);
  }
});

test("maintainer procedure describes exact-SHA review and observed evidence", () => {
  const guide = readFileSync(join(root, "docs", "dependency-updates.md"), "utf8");
  for (const phrase of ["exact candidate SHA", "CI contract", "mix hex.audit", "root SDK", "demo", "no auto-merge", "evidence actually observed"]) {
    assert.ok(guide.toLowerCase().includes(phrase.toLowerCase()), `guide must explain ${phrase}`);
  }
});
