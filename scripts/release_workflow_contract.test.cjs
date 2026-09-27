const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");
const test = require("node:test");

const root = join(__dirname, "..");
const automatic = readFileSync(join(root, ".github", "workflows", "release-please.yml"), "utf8");
const recovery = readFileSync(join(root, ".github", "workflows", "hex-publish.yml"), "utf8");

function jobBlock(workflow, id) {
  const start = workflow.indexOf(`  ${id}:\n`);
  assert.notEqual(start, -1, `workflow job ${id} is required`);
  const nextMatch = /\n  [a-z0-9-]+:\n/g;
  nextMatch.lastIndex = start + 4;
  const next = nextMatch.exec(workflow)?.index;
  return workflow.slice(start, next === undefined ? undefined : next);
}

function namedStep(block, name) {
  const start = block.indexOf(`      - name: ${name}\n`);
  assert.notEqual(start, -1, `missing step ${name}`);
  const next = block.indexOf("\n      - ", start + 8);
  return block.slice(start, next < 0 ? undefined : next);
}

test("Release Please normalizes generated tag/version through the shared candidate gate", () => {
  const metadata = jobBlock(automatic, "release-please");
  assert.match(metadata, /release_created:/);
  assert.match(metadata, /tag_name:/);
  assert.match(metadata, /version:/);
  const candidate = jobBlock(automatic, "candidate");
  assert.match(candidate, /needs: release-please/);
  assert.match(candidate, /release_created == 'true'/);
  assert.match(candidate, /RELEASE_TAG: \$\{\{ needs\.release-please\.outputs\.tag_name \}\}/);
  assert.match(candidate, /RELEASE_VERSION: \$\{\{ needs\.release-please\.outputs\.version \}\}/);
  assert.match(namedStep(candidate, "Validate Release Please identity"), /process\.env\.RELEASE_TAG/);
  assert.match(namedStep(candidate, "Validate Release Please identity"), /process\.env\.RELEASE_VERSION/);
  assert.match(namedStep(candidate, "Prepare exact-SHA candidate"), /node scripts\/release_integrity\.cjs prepare/);
  assert.match(candidate, /release-candidate-\$\{\{ steps\.candidate\.outputs\.sha \}\}/);
});

test("automatic candidate waits a bounded time for only its generated exact SHA", () => {
  const source = readFileSync(join(__dirname, "release_integrity.cjs"), "utf8");
  assert.match(source, /attempt < 16/);
  assert.match(source, /resolved\.sha, "--repo", repository/);
  assert.match(source, /setTimeout\(resolve, 30_000\)/);
  assert.match(source, /validateCandidateProof\(candidate, resolved\.sha\)/);
});

test("automatic publication revalidates under the environment-scoped shared publisher lock", () => {
  const publish = jobBlock(automatic, "publish");
  assert.match(publish, /needs: candidate/);
  assert.match(publish, /group: hex-publish/);
  assert.match(publish, /queue: max/);
  assert.match(publish, /cancel-in-progress: false/);
  assert.match(publish, /environment: hex-production/);
  assert.match(namedStep(publish, "Revalidate locked candidate and current registry state"), /release_integrity\.cjs revalidate/);
  const secret = namedStep(publish, "Publish package");
  assert.match(secret, /HEX_API_KEY: \$\{\{ secrets\.HEX_API_KEY \}\}/);
  assert.match(secret, /mix hex\.publish --yes/);
  assert.equal((automatic.match(/HEX_API_KEY:/g) || []).length, 1);
});

test("automatic verification and GitHub evidence run after publish without the Hex key", () => {
  const verify = jobBlock(automatic, "verify-and-record");
  assert.match(verify, /needs: \[candidate, publish\]/);
  assert.match(namedStep(verify, "Verify registry metadata, served tarball, and clean consumer"), /verify-hex/);
  assert.match(verify, /package_smoke\.sh --published/);
  assert.match(namedStep(verify, "Build durable evidence packet"), /release_evidence\.cjs/);
  assert.match(verify, /permissions:\s*\n\s+contents: write/);
  assert.doesNotMatch(verify, /HEX_API_KEY/);
});

test("automatic and recovery attach evidence only after Hex byte and consumer checks", () => {
  for (const [name, workflow] of [["automatic", automatic], ["recovery", recovery]]) {
    const verify = jobBlock(workflow, "verify-and-record");
    const verifyStep = namedStep(verify, "Verify registry metadata, served tarball, and clean consumer");
    const evidenceStep = namedStep(verify, "Build durable evidence packet");
    assert.ok(verify.indexOf(verifyStep) < verify.indexOf(evidenceStep), `${name} verifies before evidence attachment`);
    assert.match(verifyStep, /verify-hex/);
    assert.match(verifyStep, /package_smoke\.sh --published/);
    assert.match(verifyStep, /record-consumer/);
    assert.match(evidenceStep, /RELEASE_RUN_ID: \$\{\{ github\.run_id \}\}/);
    assert.match(evidenceStep, /RELEASE_RUN_ATTEMPT: \$\{\{ github\.run_attempt \}\}/);
    assert.doesNotMatch(evidenceStep, /HEX_API_KEY/);
    assert.match(verify, /contents: write/);
  }
});

test("both release workflows keep the existing-tag input and exact shared publication contract", () => {
  assert.match(recovery, /workflow_dispatch:[\s\S]*inputs:[\s\S]*tag:/);
  assert.doesNotMatch(recovery, /release_version:/);
  for (const [name, workflow] of [["automatic", automatic], ["recovery", recovery]]) {
    const publish = jobBlock(workflow, "publish");
    assert.match(publish, /group: hex-publish/, `${name} must share the Hex lock`);
    assert.match(publish, /queue: max/, `${name} must use the supported maximum queue`);
    assert.match(publish, /cancel-in-progress: false/, `${name} must not cancel a publisher`);
    assert.match(publish, /environment: hex-production/);
    assert.match(namedStep(publish, "Revalidate locked candidate and current registry state"), /release_integrity\.cjs revalidate/);
  }
});

test("publish credentials and GitHub write permission stay within their operation boundaries", () => {
  for (const [name, workflow] of [["automatic", automatic], ["recovery", recovery]]) {
    const candidate = jobBlock(workflow, "candidate");
    const publish = jobBlock(workflow, "publish");
    const verify = jobBlock(workflow, "verify-and-record");
    const revalidate = namedStep(publish, "Revalidate locked candidate and current registry state");
    const publishSecret = namedStep(publish, "Publish package");

    assert.match(candidate, /permissions:\s*\n\s+contents: read\n\s+actions: read/);
    assert.match(publish, /permissions:\s*\n\s+contents: read\n\s+actions: read/);
    assert.match(verify, /permissions:\s*\n\s+contents: write\n\s+actions: read/);
    assert.ok(publish.indexOf(revalidate) < publish.indexOf(publishSecret), `${name} revalidates before publishing`);
    assert.equal((publish.match(/HEX_API_KEY:/g) || []).length, 1, `${name} has one Hex key mapping`);
    assert.match(publishSecret, /HEX_API_KEY: \$\{\{ secrets\.HEX_API_KEY \}\}/);
    assert.doesNotMatch(candidate, /HEX_API_KEY/);
    assert.doesNotMatch(verify, /HEX_API_KEY/);
    assert.doesNotMatch(workflow.replace(publish, ""), /HEX_API_KEY/);
  }

  assert.match(jobBlock(automatic, "release-please"), /permissions:\s*\n\s+contents: write\n\s+issues: write\n\s+pull-requests: write/);
  assert.match(jobBlock(automatic, "candidate"), /actions\/setup-node@[0-9a-f]{40} # v6\.5\.0[\s\S]*?node-version: 22\.14\.0/);
  assert.match(jobBlock(automatic, "candidate"), /sha512sum --check/);
  assert.match(jobBlock(recovery, "candidate"), /actions\/setup-node@[0-9a-f]{40} # v6\.5\.0[\s\S]*?node-version: 22\.14\.0/);
  assert.doesNotMatch(recovery, /node-version-file: \.nvmrc/);
});
