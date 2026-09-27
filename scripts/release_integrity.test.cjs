const assert = require("node:assert/strict");
const fs = require("node:fs");
const test = require("node:test");
const { runRecovery, classifyHexObservation, reconcilePublish, validatePublishedPackage, observeHexState } = require("./release_integrity.cjs");
const { buildEvidence } = require("./release_evidence.cjs");
const { buildCandidatePackage, readMixMetadata } = require("./release_integrity.cjs");

const SHA = "a".repeat(40);
const artifactDigest = `sha256:${"b".repeat(64)}`;

function fixture() {
  const events = [];
  const candidate = {
    verified: true,
    sha: SHA,
    run: { id: 42, attempt: 2, url: "https://github.com/acme/oarlock/actions/runs/42/attempts/2" },
    proof: { verified: true, testedSha: SHA, eventHeadSha: SHA, runId: 42, runAttempt: 2 },
    artifact: { name: "ci-proof-42-2", id: 9, digest: artifactDigest, runId: 42, headSha: SHA },
    jobs: ["mix test", "static analysis", "demo PostgreSQL", "package smoke", "optional dependencies", "planning truth", "quality checks", "CI contract"].map((name) => ({ name, found: true, status: "completed", conclusion: "success" })),
  };
  const adapters = {
    resolveTag: async (tag) => { events.push("resolve-tag"); return { tag, sha: SHA }; },
    checkoutSha: async () => SHA,
    mixMetadata: async () => ({ packageName: "oarlock", appName: "paddle", version: "1.2.3" }),
    observeCandidate: async () => { events.push("ci-proof"); return candidate; },
    build: async () => { events.push("build"); return { checksum: "c".repeat(64), outerChecksum: "c".repeat(64), tarballSha256: "c".repeat(64), packageName: "oarlock", packageVersion: "1.2.3", warnings: [] }; },
    dryRun: async () => { events.push("dry-run"); return { ok: true, output: "dry run ok" }; },
    inspectHex: async () => { events.push("hex-inspect"); return { version: null }; },
    revalidate: async (identity) => { events.push("retry-revalidate"); return { ...identity, verified: true }; },
    publish: async () => { events.push("publish"); return { ok: true }; },
    verifyHex: async () => { events.push("hex-verify"); return { version: "1.2.3", checksum: "c".repeat(64), fetchedChecksum: "c".repeat(64), packageMetadata: { name: "oarlock", version: "1.2.3" }, compile: true, url: "https://hex.pm/packages/oarlock/1.2.3" }; },
    writeEvidence: async () => { events.push("evidence"); return { ok: true }; },
  };
  return { events, adapters, candidate };
}

test("fixture recovery traverses exact-SHA proof, Mix, publication decision, Hex bytes, consumer, and evidence in order", async () => {
  const { events, adapters } = fixture();
  const result = await runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters);
  assert.equal(result.verified, true);
  assert.deepEqual(events, ["resolve-tag", "ci-proof", "build", "dry-run", "build", "hex-inspect", "publish", "hex-verify", "evidence"]);
  assert.equal(result.candidate.artifact.id, 9);
  assert.equal(result.evidence.candidate_sha256, "c".repeat(64));
});

test("records idempotent success without republishing a matching existing Hex package", async () => {
  const { adapters, events } = fixture();
  adapters.inspectHex = async () => { events.push("hex-inspect"); return { version: "1.2.3", checksum: "c".repeat(64) }; };
  const result = await runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters);
  assert.equal(result.verified, true);
  assert.equal(events.includes("publish"), false);
});

test("does not republish over a conflicting existing Hex checksum", async () => {
  const { adapters, events } = fixture();
  adapters.inspectHex = async () => { events.push("hex-inspect"); return { version: "1.2.3", checksum: "d".repeat(64) }; };
  await assert.rejects(runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters), /existing Hex release failed/);
  assert.equal(events.includes("publish"), false);
});

test("rejects unsafe tags before candidate or publication work", async () => {
  const { adapters, events } = fixture();
  await assert.rejects(runRecovery({ tag: "v1.2.3; touch /tmp/pwn", repository: "acme/oarlock" }, adapters), /release tag failed/);
  assert.deepEqual(events, []);
});

test("stops before publication when exact-SHA proof, run, required jobs, or artifact identity is incomplete", async () => {
  for (const mutate of [
    (candidate) => ({ ...candidate, verified: false }),
    (candidate) => ({ ...candidate, proof: { ...candidate.proof, testedSha: "b".repeat(40) } }),
    (candidate) => ({ ...candidate, proof: { ...candidate.proof, runAttempt: 1 } }),
    (candidate) => ({ ...candidate, run: { ...candidate.run, attempt: 0 } }),
    (candidate) => ({ ...candidate, artifact: { ...candidate.artifact, digest: "" } }),
    (candidate) => ({ ...candidate, artifact: { ...candidate.artifact, name: "stale-proof" } }),
    (candidate) => ({ ...candidate, artifact: { ...candidate.artifact, headSha: "b".repeat(40) } }),
    (candidate) => ({ ...candidate, jobs: candidate.jobs.slice(1) }),
    (candidate) => ({ ...candidate, jobs: [...candidate.jobs, candidate.jobs[0]] }),
    (candidate) => ({ ...candidate, jobs: candidate.jobs.map((job, index) => index ? job : { ...job, conclusion: "failure" }) }),
  ]) {
    const { adapters, events, candidate } = fixture();
    adapters.observeCandidate = async () => mutate(candidate);
    await assert.rejects(runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters), /failed/);
    assert.equal(events.includes("publish"), false);
    assert.equal(events.includes("evidence"), false);
  }
});

test("rejects mismatched tag target, checkout SHA, package identity, and fetched tarball", async () => {
  const badCases = [
    (adapters) => { adapters.resolveTag = async () => ({ tag: "v1.2.3", sha: "b".repeat(40) }); },
    (adapters) => { adapters.checkoutSha = async () => "b".repeat(40); },
    (adapters) => { adapters.mixMetadata = async () => ({ packageName: "paddle", appName: "paddle", version: "1.2.3" }); },
    (adapters) => { adapters.mixMetadata = async () => ({ packageName: "oarlock", appName: "paddle", version: "9.9.9" }); },
    (adapters) => { adapters.verifyHex = async () => ({ version: "1.2.3", checksum: "d".repeat(64), fetchedChecksum: "d".repeat(64), packageMetadata: { name: "oarlock", version: "1.2.3" }, compile: true }); },
    (adapters) => { adapters.verifyHex = async () => ({ version: "1.2.3", checksum: "c".repeat(64), fetchedChecksum: "d".repeat(64), packageMetadata: { name: "oarlock", version: "1.2.3" }, compile: false }); },
  ];
  for (const mutate of badCases) {
    const { adapters, events } = fixture();
    mutate(adapters);
    await assert.rejects(runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters), /failed/);
    assert.equal(events.includes("evidence"), false);
  }
});

test("diagnostics include the exact proof run and sanitize control characters", async () => {
  const { adapters, candidate } = fixture();
  candidate.proof.testedSha = "b".repeat(40);
  await assert.rejects(
    runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters),
    (error) => error.message.includes(candidate.run.url) && !/[\r\n\t]/.test(error.message),
  );
  const other = fixture();
  other.adapters.mixMetadata = async () => ({ packageName: "oarlock\nHEX_API_KEY=leak", appName: "paddle", version: "1.2.3" });
  await assert.rejects(runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, other.adapters), (error) => !error.message.includes("\nHEX_API_KEY"));
});

test("recovery workflow gates credential access and evidence on proof and registry verification", () => {
  const workflow = fs.readFileSync(".github/workflows/hex-publish.yml", "utf8");
  const secretIndex = workflow.indexOf("HEX_API_KEY: ${{ secrets.HEX_API_KEY }}");
  assert.notEqual(secretIndex, -1);
  assert.equal((workflow.match(/inputs:\n\s+tag:/g) || []).length, 1);
  assert.equal(workflow.includes("release_version:"), false);
  assert.match(workflow, /needs: candidate/);
  assert.match(workflow, /environment: hex-production/);
  assert.match(workflow, /group: hex-publish[\s\S]*queue: max/);
  assert.match(workflow, /id: revalidate[\s\S]*run: node scripts\/release_integrity\.cjs revalidate[\s\S]*name: Publish package/);
  assert.match(workflow, /needs: \[candidate, publish\]/);
  assert.match(workflow, /release_evidence\.cjs release-candidate\.json/);
  assert.equal(workflow.slice(0, secretIndex).includes("HEX_API_KEY"), false);
  assert.equal(workflow.slice(secretIndex).includes("HEX_API_KEY"), true);
  assert.equal((workflow.match(/HEX_API_KEY:/g) || []).length, 1);
});

test("recovery workflow gates credential access and evidence on exact proof and registry verification", () => {
  const workflow = fs.readFileSync(".github/workflows/hex-publish.yml", "utf8");
  const secretIndex = workflow.indexOf("HEX_API_KEY: ${{ secrets.HEX_API_KEY }}");
  assert.notEqual(secretIndex, -1);
  assert.equal((workflow.match(/inputs:\n\s+tag:/g) || []).length, 1);
  assert.equal(workflow.includes("release_version:"), false);
  assert.match(workflow, /needs: candidate/);
  assert.match(workflow, /environment: hex-production/);
  assert.match(workflow, /group: hex-publish[\s\S]*queue: max/);
  assert.match(workflow, /id: revalidate[\s\S]*run: node scripts\/release_integrity\.cjs revalidate[\s\S]*name: Publish package/);
  assert.match(workflow, /needs: \[candidate, publish\]/);
  assert.match(workflow, /release_evidence\.cjs release-candidate\.json/);
  assert.equal(workflow.slice(0, secretIndex).includes("HEX_API_KEY"), false);
  assert.equal(workflow.slice(secretIndex).includes("HEX_API_KEY"), true);
});

test("evidence contains durable source, CI, checksum, Hex, consumer, workflow, and timestamp identity", async () => {
  const { adapters } = fixture();
  const result = await runRecovery({ tag: "v1.2.3", repository: "acme/oarlock" }, adapters);
  const packet = {
    schema_version: 1, repository: "acme/oarlock", tag: "v1.2.3", sha: SHA, version: "1.2.3",
    checksum: "c".repeat(64), candidate: result.candidate,
    published: { ...result.published, packageName: result.published.packageMetadata.name },
    packageName: "oarlock", packageVersion: "1.2.3", dryRunOutput: result.dryRun.output,
    consumer_compile: "passed",
  };
  const evidence = buildEvidence(packet, { RELEASE_WORKFLOW_RUN: "https://github.com/acme/oarlock/actions/runs/55", RELEASE_RUN_ID: "55", RELEASE_RUN_ATTEMPT: "3" });
  assert.equal(evidence.peeled_sha, SHA);
  assert.equal(evidence.ci_artifact_id, 9);
  assert.equal(evidence.candidate_sha256, "c".repeat(64));
  assert.equal(evidence.hex_checksum, "c".repeat(64));
  assert.equal(evidence.downstream_compile, "passed");
  assert.equal(evidence.release_workflow_run_id, 55);
  assert.ok(evidence.created_at);
  assert.equal(JSON.stringify(evidence).includes("HEX_API_KEY"), false);
});

test("classifies only strict, observed release metadata into matching, absent, conflict, or unobserved", () => {
  const checksum = "c".repeat(64);
  assert.equal(classifyHexObservation("1.2.3", checksum, { version: null }).state, "absent");
  assert.equal(classifyHexObservation("1.2.3", checksum, { version: "1.2.3", checksum }).state, "matching");
  assert.equal(classifyHexObservation("1.2.3", checksum, { version: "1.2.3", checksum: "d".repeat(64) }).state, "conflict");
  assert.equal(classifyHexObservation("1.2.3", checksum, { version: "1.2.4", checksum }).state, "conflict");
  assert.equal(classifyHexObservation("1.2.3", checksum, null).state, "unobserved");
  assert.equal(classifyHexObservation("1.2.3", checksum, { version: "1.2.3", checksum: "bad" }).state, "unobserved");
});

test("validates API checksum, fetched tarball bytes, and unpacked package identity as one chain", () => {
  const checksum = "c".repeat(64);
  const valid = validatePublishedPackage({
    expectedVersion: "1.2.3",
    expectedChecksum: checksum,
    release: { version: "1.2.3", checksum },
    fetchedChecksum: checksum,
    packageMetadata: { name: "oarlock", version: "1.2.3" },
  });
  assert.equal(valid.verified, true);
  for (const mutate of [
    (value) => { value.release.checksum = "bad"; },
    (value) => { value.release.version = "1.2.4"; },
    (value) => { value.fetchedChecksum = "d".repeat(64); },
    (value) => { value.packageMetadata.name = "other"; },
    (value) => { value.packageMetadata.version = "1.2.4"; },
    (value) => { value.packageMetadata = null; },
  ]) {
    const input = {
      expectedVersion: "1.2.3", expectedChecksum: checksum,
      release: { version: "1.2.3", checksum }, fetchedChecksum: checksum,
      packageMetadata: { name: "oarlock", version: "1.2.3" },
    };
    mutate(input);
    assert.throws(() => validatePublishedPackage(input), /failed/);
  }
});

test("requires Mix outer checksum, independent file SHA-256, and package metadata to agree", () => {
  const checksum = "c".repeat(64);
  assert.equal(require("./release_integrity.cjs").validateBuild({
    checksum, outerChecksum: checksum, tarballSha256: checksum, packageName: "oarlock", packageVersion: "1.2.3",
  }, "1.2.3").checksum, checksum);
  for (const mutate of [
    (build) => { build.outerChecksum = "d".repeat(64); },
    (build) => { build.tarballSha256 = "d".repeat(64); },
    (build) => { build.packageName = "paddle"; },
    (build) => { build.packageVersion = "1.2.4"; },
  ]) {
    const build = { checksum, outerChecksum: checksum, tarballSha256: checksum, packageName: "oarlock", packageVersion: "1.2.3" };
    mutate(build);
    assert.throws(() => require("./release_integrity.cjs").validateBuild(build, "1.2.3"), /failed/);
  }
});

test("pinned Mix build exposes an outer checksum equal to an independent SHA-256", () => {
  const metadata = readMixMetadata();
  const build = buildCandidatePackage(metadata.version);
  assert.equal(build.checksum, build.outerChecksum);
  assert.equal(build.checksum, build.tarballSha256);
  assert.equal(build.packageName, "oarlock");
  assert.equal(build.packageVersion, metadata.version);
});

test("published consumer mode fetches and inspects the served archive and pins the exact Hex package", () => {
  const script = fs.readFileSync("bin/package_smoke.sh", "utf8");
  assert.match(script, /repo\.hex\.pm\/tarballs\/oarlock-/);
  assert.match(script, /OBSERVED_CHECKSUM.*EXPECTED_CHECKSUM/);
  assert.match(script, /hex: :oarlock/);
  assert.match(script, /export HEX_HOME="\$\{WORK_DIR%\/\}\/hex-home"/);
  assert.match(script, /cp "\$ROOT_DIR\/\.tool-versions" "\$CONSUMER_DIR\/\.tool-versions"/);
  assert.match(script, /mix compile --warnings-as-errors/);
});

test("matching and conflicting Hex states never upload; unobserved state never becomes absence", async () => {
  for (const observation of [
    { version: "1.2.3", checksum: "c".repeat(64) },
    { version: "1.2.3", checksum: "d".repeat(64) },
    null,
  ]) {
    let uploads = 0;
    const args = { version: "1.2.3", checksum: "c".repeat(64), tag: "v1.2.3", sha: SHA };
    const adapters = {
      observeHex: async () => observation,
      publish: async () => { uploads += 1; },
      revalidate: async () => ({ verified: true }),
    };
    if (observation?.checksum === "c".repeat(64)) {
      assert.equal((await reconcilePublish(args, adapters)).state, "matching");
    } else {
      await assert.rejects(reconcilePublish(args, adapters), /failed/);
    }
    assert.equal(uploads, 0);
  }
});

test("after an unclear publish, matching checksum is idempotent and absent retries only after revalidation", async () => {
  const expected = { version: "1.2.3", checksum: "c".repeat(64) };
  let uploads = 0;
  const matching = await reconcilePublish({ version: "1.2.3", checksum: expected.checksum, tag: "v1.2.3", sha: SHA }, {
    observeHex: async () => uploads === 0 ? { version: null } : expected,
    publish: async () => { uploads += 1; throw new Error("ambiguous timeout"); },
    revalidate: async () => ({ verified: true }),
  });
  assert.equal(matching.state, "matching");
  assert.equal(uploads, 1);

  uploads = 0;
  let revalidated = false;
  const retried = await reconcilePublish({ version: "1.2.3", checksum: expected.checksum, tag: "v1.2.3", sha: SHA }, {
    observeHex: async () => ({ version: null }),
    publish: async () => { uploads += 1; if (uploads === 1) throw new Error("ambiguous timeout"); return { ok: true }; },
    revalidate: async (identity) => { revalidated = true; return { ...identity, verified: true }; },
  });
  assert.equal(retried.state, "submitted");
  assert.equal(uploads, 2);
  assert.equal(revalidated, true);
});

test("ambiguous publish never retries on conflict, unobserved state, or failed identity revalidation", async () => {
  const expectedChecksum = "c".repeat(64);
  for (const [afterFailure, revalidate] of [
    [{ version: "1.2.3", checksum: "d".repeat(64) }, async () => ({ verified: true })],
    [null, async () => ({ verified: true })],
    [{ version: null }, async () => ({ verified: false })],
  ]) {
    let observations = 0;
    let uploads = 0;
    await assert.rejects(reconcilePublish({ version: "1.2.3", checksum: expectedChecksum, tag: "v1.2.3", sha: SHA }, {
      observeHex: async () => { observations += 1; return observations === 1 ? { version: null } : afterFailure; },
      publish: async () => { uploads += 1; throw new Error("ambiguous timeout"); },
      revalidate,
    }), /failed/);
    assert.equal(uploads, 1);
  }
});

test("retry requires exact tag, peeled SHA, Mix version, and candidate checksum revalidation", async () => {
  let uploads = 0;
  let observations = 0;
  await assert.rejects(reconcilePublish({ version: "1.2.3", checksum: "c".repeat(64), tag: "v1.2.3", sha: SHA }, {
    observeHex: async () => { observations += 1; return { version: null }; },
    publish: async () => { uploads += 1; throw new Error("ambiguous response"); },
    revalidate: async (identity) => ({ ...identity, sha: "b".repeat(40), verified: true }),
  }), /retry identity revalidation failed/);
  assert.equal(uploads, 1);
  assert.equal(observations, 2);
});

test("Hex absence is confirmed only after bounded repeated 404 observations", async () => {
  const observations = [{ version: null }, { version: null }, { version: "1.2.3", checksum: "c".repeat(64) }];
  let waits = 0;
  const result = await observeHexState("1.2.3", "c".repeat(64), {
    observe: async () => observations.shift(),
    wait: async (ms) => { assert.equal(ms, 5_000); waits += 1; },
  });
  assert.equal(result.version, "1.2.3");
  assert.equal(waits, 2);

  let requests = 0;
  const absent = await observeHexState("1.2.3", "c".repeat(64), {
    observe: async () => { requests += 1; return { status: "absent", version: null }; },
    wait: async () => {},
  });
  assert.equal(absent.status, "absent");
  assert.equal(requests, 4);
});

test("release incident diagnostics include safe identity links without response bodies", async () => {
  await assert.rejects(reconcilePublish({ version: "1.2.3", checksum: "c".repeat(64), tag: "v1.2.3", sha: SHA,
    runUrl: "https://github.com/acme/oarlock/actions/runs/42" }, {
    repository: "acme/oarlock",
    observeHex: async () => ({ version: "1.2.3", checksum: "raw API body\nsecret" }),
    publish: async () => assert.fail("conflict must stop before upload"),
  }), (error) => error.message.includes("expected 1.2.3 checksum") &&
    error.message.includes("https://github.com/acme/oarlock/releases/tag/v1.2.3") &&
    error.message.includes("https://github.com/acme/oarlock/actions/runs/42") &&
    error.message.includes("https://hex.pm/packages/oarlock/1.2.3") &&
    !error.message.includes("raw API body") && !error.message.includes("raw API"));
});
