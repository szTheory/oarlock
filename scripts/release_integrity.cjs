#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { DEFAULT_REQUIRED_JOBS } = require("./ci_monitor.cjs");
const { observeCandidate } = require("./ci_remote_gate.cjs");

const TAG = /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const SHA = /^[a-f0-9]{40}$/i;
const HEX_DIGEST = /^[a-f0-9]{64}$/i;

function reject(check, expected, observed, nextStep, extra = {}) {
  const safe = (value) => String(value).replace(/[\r\n\t\0-\x1f\x7f]/g, "?").slice(0, 180);
  const links = [extra.tagUrl, extra.runUrl, extra.hexUrl].filter(Boolean).map(safe);
  const linkText = links.length ? ` Links: ${links.join("; ")}` : "";
  const error = new Error(`${safe(check)} failed: expected ${safe(expected)}; observed ${safe(observed)}. ${safe(nextStep)}${linkText}`);
  error.details = { check: safe(check), expected: safe(expected), observed: safe(observed), ...extra };
  throw error;
}

function validateTag(tag) {
  if (typeof tag !== "string" || !TAG.test(tag)) reject("release tag", "vX.Y.Z", "invalid input", "Select an existing versioned release tag.");
  return tag;
}

function validateCandidateProof(candidate, sha) {
  if (!candidate?.verified || candidate.sha?.toLowerCase() !== sha.toLowerCase()) reject("Phase 33 CI contract", sha, candidate?.sha || "no accepted candidate", "Open the exact-SHA CI run and resolve its failed or missing proof.", { runUrl: candidate?.run?.url });
  const { run, proof, artifact, jobs } = candidate;
  const runId = run?.id;
  const attempt = run?.attempt;
  if (!Number.isSafeInteger(runId) || runId <= 0 || !Number.isSafeInteger(attempt) || attempt <= 0 ||
      proof?.verified !== true || proof.testedSha?.toLowerCase() !== sha.toLowerCase() ||
      proof.eventHeadSha?.toLowerCase() !== sha.toLowerCase() || proof.runId !== runId || proof.runAttempt !== attempt) {
    reject("Phase 33 proof identity", `${sha} run ${runId || "?"} attempt ${attempt || "?"}`, "missing or contradictory proof", "Open the exact-SHA CI run and regenerate its retained contract proof.", { runUrl: run?.url });
  }
  if (!Array.isArray(jobs) || jobs.length !== DEFAULT_REQUIRED_JOBS.length || new Set(jobs.map((job) => job.name)).size !== DEFAULT_REQUIRED_JOBS.length ||
      DEFAULT_REQUIRED_JOBS.some((name) => !jobs.some((job) => job.name === name && job.found && job.status === "completed" && job.conclusion === "success"))) {
    reject("Phase 33 required jobs", "all eight successful jobs", "missing, duplicate, or unsuccessful job", "Open the exact-SHA CI run and repair the failed contract lane.", { runUrl: run?.url });
  }
  if (!artifact || !Number.isSafeInteger(artifact.id) || artifact.id <= 0 || artifact.runId !== runId || artifact.headSha?.toLowerCase() !== sha.toLowerCase() ||
      artifact.name !== `ci-proof-${runId}-${attempt}` || !/^sha256:[a-f0-9]{64}$/i.test(artifact.digest || "")) {
    reject("Phase 33 retained artifact", `ci-proof-${runId}-${attempt} for ${sha}`, "missing or mismatched artifact identity", "Open the exact-SHA CI run and restore its retained proof artifact.", { runUrl: run?.url });
  }
  return candidate;
}

async function runRecovery({ tag, repository }, adapters) {
  validateTag(tag);
  const version = tag.slice(1);
  const resolved = await adapters.resolveTag(tag);
  const sha = typeof resolved === "string" ? resolved : resolved?.sha;
  if (!SHA.test(sha || "") || resolved?.tag && resolved.tag !== tag) reject("remote release tag", `${tag} at one peeled commit`, resolved?.sha || "missing or moved tag", "Restore the protected release tag or select its authorized existing tag.");
  const checkoutSha = await adapters.checkoutSha();
  if (checkoutSha?.toLowerCase() !== sha.toLowerCase()) reject("checked-out source", sha, checkoutSha || "unavailable", "Check out the selected tag's peeled commit before retrying.");
  const metadata = await adapters.mixMetadata();
  if (metadata?.packageName !== "oarlock" || metadata?.appName !== "paddle" || metadata?.version !== version) {
    reject("Mix package identity", `oarlock/${version} (Mix app paddle)`, `${metadata?.packageName || "?"}/${metadata?.version || "?"} (app ${metadata?.appName || "?"})`, "Correct the tag or tagged Mix package metadata before retrying.");
  }
  const candidate = validateCandidateProof(await adapters.observeCandidate(sha, repository), sha);
  const build = validateBuild(await adapters.build(), version);
  const dryRun = await adapters.dryRun();
  if (!dryRun?.ok) reject("Hex dry run", "success", "failed", "Resolve the Mix/Hex package warnings before publication.");
  const repeatedBuild = validateBuild(await adapters.build(), version);
  if (repeatedBuild.checksum !== build.checksum) reject("deterministic candidate checksum", build.checksum, repeatedBuild.checksum, "Stop and investigate nondeterministic package inputs before publication.");
  const publication = await reconcilePublish({ tag, sha, version, checksum: build.checksum, runUrl: candidate.run.url }, adapters);
  const published = await adapters.verifyHex(version, build.checksum);
  validatePublishedPackage({ expectedVersion: version, expectedChecksum: build.checksum, release: published,
    fetchedChecksum: published?.fetchedChecksum, packageMetadata: published?.packageMetadata });
  if (published.compile !== true) reject("published Hex consumer", "clean exact-version compile", "missing or failed", "Inspect the fresh downstream consumer compile before recording release evidence.", { runUrl: candidate.run.url });
  const evidence = {
    schema_version: 1, repository, tag, sha: sha.toLowerCase(), package_name: "oarlock", package_version: version,
    ci_run_url: candidate.run.url, ci_run_id: candidate.run.id, ci_run_attempt: candidate.run.attempt,
    ci_artifact_id: candidate.artifact.id, ci_artifact_digest: candidate.artifact.digest,
    dry_run: "passed", candidate_sha256: build.checksum.toLowerCase(), hex_release_url: published.url,
    hex_checksum: published.checksum.toLowerCase(), fetched_tarball_sha256: published.fetchedChecksum.toLowerCase(),
    consumer_compile: "passed", created_at: new Date().toISOString(),
  };
  await adapters.writeEvidence(evidence);
  return { verified: true, candidate, build, dryRun, publication, published, evidence };
}

async function reconcilePublish({ tag, sha, version, checksum, runUrl }, adapters) {
  const observe = async () => adapters.observeHex ? adapters.observeHex(version) : adapters.inspectHex(version);
  const classify = async () => {
    try { return classifyHexObservation(version, checksum, await observe()); }
    catch { return classifyHexObservation(version, checksum, null); }
  };
  const rejectState = (state, expected, check = "Hex publication state") => {
    const observedVersion = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(state.observation?.version || "") ? state.observation.version : "malformed version";
    const observedChecksum = HEX_DIGEST.test(state.observation?.checksum || "") ? state.observation.checksum : "malformed checksum";
    return reject(check, expected,
    `${state.state}: ${observedVersion} checksum ${observedChecksum}`,
    "Stop without publishing. Check the tag and CI run, inspect the Hex release URL, then retry only after exact identity and registry absence are verified.",
    { tagUrl: `https://github.com/${adapters.repository || ""}/releases/tag/${tag}`, runUrl, hexUrl: `https://hex.pm/packages/oarlock/${version}` });
  };

  let state = await classify();
  if (state.state === "matching") return { state: "matching", idempotent: true, url: `https://hex.pm/packages/oarlock/${version}` };
  if (state.state !== "absent") rejectState(state, `${version} checksum ${checksum}`, "existing Hex release");
  try {
    await adapters.publish({ tag, sha, version, checksum });
    return { state: "submitted", idempotent: false, url: `https://hex.pm/packages/oarlock/${version}` };
  } catch {
    state = await classify();
    if (state.state === "matching") return { state: "matching", idempotent: true, url: `https://hex.pm/packages/oarlock/${version}` };
    if (state.state !== "absent") rejectState(state, `${version} checksum ${checksum} or confirmed absence`);
  }

  const identity = await adapters.revalidate?.({ tag, sha, version, checksum });
  if (identity?.verified !== true || identity.tag !== tag || identity.sha?.toLowerCase() !== sha.toLowerCase() ||
      identity.version !== version || identity.checksum?.toLowerCase() !== checksum.toLowerCase()) {
    reject("retry identity revalidation", `${tag} at ${sha}, version ${version}, checksum ${checksum}`, "missing or contradictory", "Rerun exact tag, CI proof, Mix version, and candidate checksum checks under the publisher lock.",
      { tagUrl: `https://github.com/${adapters.repository || ""}/releases/tag/${tag}`, runUrl, hexUrl: `https://hex.pm/packages/oarlock/${version}` });
  }
  state = await classify();
  if (state.state === "matching") return { state: "matching", idempotent: true, url: `https://hex.pm/packages/oarlock/${version}` };
  if (state.state !== "absent") rejectState(state, `${version} checksum ${checksum} or confirmed absence`);
  try {
    await adapters.publish({ tag, sha, version, checksum, retry: true });
    return { state: "submitted", idempotent: false, retried: true, url: `https://hex.pm/packages/oarlock/${version}` };
  } catch {
    state = await classify();
    if (state.state === "matching") return { state: "matching", idempotent: true, url: `https://hex.pm/packages/oarlock/${version}` };
    rejectState(state, `${version} checksum ${checksum} after one revalidated attempt`);
  }
}

function command(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: "utf8", timeout: options.timeoutMs || 60_000, maxBuffer: 2 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw new Error(`${command} ${args[0]} failed (${result.status ?? "unavailable"})`);
  return result.stdout.trim();
}

function resolveRemoteTag(tag) {
  validateTag(tag);
  const refs = command("git", ["ls-remote", "origin", `refs/tags/${tag}`, `refs/tags/${tag}^{}`]).split(/\r?\n/).filter(Boolean);
  const entries = refs.map((line) => line.split(/\s+/));
  const peeled = entries.find(([, ref]) => ref === `refs/tags/${tag}^{}`)?.[0];
  const direct = entries.find(([, ref]) => ref === `refs/tags/${tag}`)?.[0];
  const sha = peeled || direct;
  if (!SHA.test(sha || "")) reject("remote release tag", `${tag} resolving to a commit`, "missing or invalid", "Confirm the versioned tag exists on origin.");
  return { tag, sha: sha.toLowerCase() };
}

function readMixMetadata() {
  const raw = command("mix", ["eval", 'project = Mix.Project.get!(); config = Mix.Project.config(); IO.puts([config[:package][:name] || config[:name], config[:app], config[:version]] |> Enum.join("\\t"))']);
  const [packageName, appName, version] = raw.split(/\r?\n/).at(-1).split("\t");
  return { packageName, appName: String(appName || "").replace(/^:/, ""), version };
}

function writeJson(path, value) {
  fs.writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600, flag: "wx" });
}

function run(commandName, args, options = {}) {
  const result = spawnSync(commandName, args, { encoding: "utf8", timeout: options.timeoutMs || 60_000, maxBuffer: 2 * 1024 * 1024, env: options.env || process.env });
  if (result.error || result.status !== 0) throw new Error(`${options.label || commandName} failed (${result.status ?? "unavailable"})`);
  return result.stdout.trim();
}

function validateBuild(build, expectedVersion) {
  const checksum = String(build?.checksum || "").toLowerCase();
  const outerChecksum = String(build?.outerChecksum || "").toLowerCase();
  const tarballSha256 = String(build?.tarballSha256 || "").toLowerCase();
  if (!HEX_DIGEST.test(checksum) || checksum !== outerChecksum || checksum !== tarballSha256) {
    reject("candidate checksum parity", `Mix outer checksum = independent SHA-256 = ${checksum || "valid SHA-256"}`, `outer ${outerChecksum || "missing"}; file ${tarballSha256 || "missing"}`, "Stop and compare the pinned Hex build output with an independent hash of the generated tarball.");
  }
  if (build.packageName !== "oarlock" || build.packageVersion !== expectedVersion) {
    reject("candidate tarball metadata", `oarlock/${expectedVersion}`, `${build.packageName || "missing"}/${build.packageVersion || "missing"}`, "Stop and correct the tagged package metadata before publication.");
  }
  return { ...build, checksum };
}

function classifyHexObservation(expectedVersion, expectedChecksum, observation) {
  if (observation?.status === "unobserved" || observation == null) return { state: "unobserved", observation };
  if (observation?.status === "absent" || observation?.version === null) return { state: "absent", observation };
  if (typeof observation !== "object" || typeof observation.version !== "string" || !HEX_DIGEST.test(observation.checksum || "")) {
    return { state: "unobserved", observation };
  }
  if (observation.version !== expectedVersion) return { state: "conflict", observation };
  return { state: observation.checksum.toLowerCase() === expectedChecksum.toLowerCase() ? "matching" : "conflict", observation };
}

function validatePublishedPackage({ expectedVersion, expectedChecksum, release, fetchedChecksum, packageMetadata }) {
  if (!release || release.version !== expectedVersion || !HEX_DIGEST.test(release.checksum || "")) {
    reject("Hex release metadata", `${expectedVersion} with lowercase hex SHA-256`, `${release?.version || "missing"} checksum ${release?.checksum || "missing"}`, "Wait for a valid Hex release response; do not treat malformed metadata as absence.");
  }
  if (release.checksum !== release.checksum.toLowerCase() || release.checksum !== expectedChecksum.toLowerCase()) {
    reject("Hex API checksum", expectedChecksum, release.checksum, "Stop and investigate the release checksum mismatch.");
  }
  if (!HEX_DIGEST.test(fetchedChecksum || "") || fetchedChecksum.toLowerCase() !== expectedChecksum.toLowerCase()) {
    reject("fetched Hex tarball SHA-256", expectedChecksum, fetchedChecksum || "missing", "Stop and investigate the bytes served by the Hex repository.");
  }
  if (packageMetadata?.name !== "oarlock" || packageMetadata?.version !== expectedVersion) {
    reject("fetched Hex package metadata", `oarlock/${expectedVersion}`, `${packageMetadata?.name || "missing"}/${packageMetadata?.version || "missing"}`, "Stop and inspect the served package before recording release evidence.");
  }
  return { verified: true, version: expectedVersion, checksum: expectedChecksum.toLowerCase() };
}

function inspectPackageMetadata(tarballPath) {
  const metadata = run("tar", ["-xOf", tarballPath, "metadata.config"], { label: "Hex tarball metadata" });
  const name = metadata.match(/\{<<"name">>,<<"([^"\n]+)">>\}\./)?.[1];
  const version = metadata.match(/\{<<"version">>,<<"([^"\n]+)">>\}\./)?.[1];
  return { name, version };
}

function buildCandidatePackage(version) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-release-build-"));
  const tarballPath = path.join(directory, `oarlock-${version}.tar`);
  try {
    const output = run("mix", ["hex.build", "--output", tarballPath], { label: "Mix package build", timeoutMs: 180_000 });
    const checksumMatch = output.match(/Package checksum:\s*([a-f0-9]{64})/i);
    const tarballSha256 = crypto.createHash("sha256").update(fs.readFileSync(tarballPath)).digest("hex");
    const packageMetadata = inspectPackageMetadata(tarballPath);
    return validateBuild({ checksum: checksumMatch?.[1], outerChecksum: checksumMatch?.[1], tarballSha256,
      packageName: packageMetadata.name, packageVersion: packageMetadata.version, output }, version);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

async function prepare() {
  const tag = validateTag(process.env.RELEASE_TAG);
  const repository = process.env.GH_REPO;
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository || "")) reject("repository identity", "owner/repository", "invalid", "Run this workflow from the canonical repository.");
  const resolved = resolveRemoteTag(tag);
  run("git", ["fetch", "origin", tag], { label: "tag fetch" });
  run("git", ["checkout", "--detach", resolved.sha], { label: "tag checkout" });
  if (run("git", ["rev-parse", "HEAD"]) !== resolved.sha) reject("checked-out source", resolved.sha, "different commit", "Check out the protected release tag and retry.");
  const metadata = readMixMetadata();
  const version = tag.slice(1);
  if (metadata.packageName !== "oarlock" || metadata.appName !== "paddle" || metadata.version !== version) reject("Mix package identity", `oarlock/${version} (app paddle)`, `${metadata.packageName}/${metadata.version} (app ${metadata.appName})`, "Correct the tagged package metadata before retrying.");
  let candidate;
  for (let attempt = 0; attempt < 16; attempt += 1) {
    const result = spawnSync(process.execPath, ["scripts/ci_remote_gate.cjs", "candidate", "--sha", resolved.sha, "--repo", repository, "--json"], { encoding: "utf8", timeout: 75_000, maxBuffer: 2 * 1024 * 1024 });
    try { candidate = JSON.parse(result.stdout); } catch { candidate = null; }
    if (candidate?.verified) break;
    if (attempt < 15) await new Promise((resolve) => setTimeout(resolve, 30_000));
  }
  validateCandidateProof(candidate, resolved.sha);
  const firstBuild = buildCandidatePackage(version);
  const dryRunOutput = run("mix", ["hex.publish", "--dry-run", "--yes"], { label: "Hex dry run", timeoutMs: 180_000 });
  const secondBuild = buildCandidatePackage(version);
  if (secondBuild.checksum !== firstBuild.checksum) reject("deterministic candidate checksum", firstBuild.checksum, secondBuild.checksum, "Stop and investigate nondeterministic package inputs before publication.");
  const packet = { schema_version: 1, repository, tag, sha: resolved.sha, version, metadata, candidate,
    checksum: firstBuild.checksum, buildOutput: firstBuild.output, repeatedBuildOutput: secondBuild.output,
    packageName: firstBuild.packageName, packageVersion: firstBuild.packageVersion, dryRunOutput,
    created_at: new Date().toISOString() };
  writeJson("release-candidate.json", packet);
  const output = process.env.GITHUB_OUTPUT;
  if (output) fs.appendFileSync(output, `tag=${tag}\nsha=${resolved.sha}\nversion=${version}\nchecksum=${firstBuild.checksum}\n`);
  process.stdout.write(`Verified ${tag} at ${resolved.sha}; CI proof ${candidate.run.id}/${candidate.run.attempt}; package SHA-256 ${firstBuild.checksum}.\n`);
}

function loadPacket() { return JSON.parse(fs.readFileSync("release-candidate.json", "utf8")); }

async function revalidate() {
  const packet = loadPacket();
  validateTag(packet.tag);
  const current = resolveRemoteTag(packet.tag);
  if (current.sha !== packet.sha) reject("locked release tag", packet.sha, current.sha, "Stop and investigate the moved tag; do not publish.");
  const accepted = validateCandidateProof(await observeCandidate(packet.sha, packet.repository), packet.sha);
  const original = packet.candidate;
  if (accepted.run.id !== original.run.id || accepted.run.attempt !== original.run.attempt ||
      accepted.artifact.id !== original.artifact.id || accepted.artifact.digest !== original.artifact.digest) {
    reject("locked CI proof identity", `run ${original.run.id}/${original.run.attempt}, artifact ${original.artifact.id} ${original.artifact.digest}`,
      `run ${accepted.run.id}/${accepted.run.attempt}, artifact ${accepted.artifact.id} ${accepted.artifact.digest}`,
      "Stop and rerun the secret-free candidate preflight against the newly accepted proof.", { runUrl: accepted.run.url });
  }
  const metadata = readMixMetadata();
  if (metadata.packageName !== "oarlock" || metadata.appName !== "paddle" || metadata.version !== packet.version) reject("locked Mix package identity", `oarlock/${packet.version} (app paddle)`, `${metadata.packageName}/${metadata.version} (app ${metadata.appName})`, "Stop and restore the verified tagged source.");
  const build = buildCandidatePackage(packet.version);
  if (build.checksum !== packet.checksum) reject("locked candidate checksum", packet.checksum, build.checksum, "Stop and restore the exact checked-out candidate package bytes.");
  const observation = await observeHexState(packet.version, packet.checksum);
  const state = classifyHexObservation(packet.version, packet.checksum, observation);
  if (state.state === "conflict") reject("existing Hex release", `${packet.version} checksum ${packet.checksum}`, `${state.observation.version || "?"} checksum ${state.observation.checksum || "unknown"}`, "Resolve the registry conflict; do not overwrite the release.");
  if (state.state === "unobserved") reject("Hex registry observation", "valid release metadata or confirmed absence", "unavailable or malformed response", "Retry when Hex registry observations are available; do not publish on an unknown state.");
  const output = process.env.GITHUB_OUTPUT;
  if (output) fs.appendFileSync(output, `publish=${state.state === "matching" ? "false" : "true"}\n`);
  process.stdout.write(state.state === "matching" ? "Matching Hex release already exists; recording idempotent success.\n" : "Tag, proof, package checksum, and confirmed registry absence revalidated under the publish lock.\n");
}

async function verifyHex() {
  const packet = loadPacket();
  const release = await waitForHexRelease(packet.version);
  const tarballResponse = await fetch(`https://repo.hex.pm/tarballs/oarlock-${packet.version}.tar`, { signal: AbortSignal.timeout(30_000) });
  if (!tarballResponse.ok) reject("Hex tarball", packet.version, `HTTP ${tarballResponse.status}`, "Wait for Hex package replication, then rerun verification.");
  const bytes = Buffer.from(await tarballResponse.arrayBuffer());
  const checksum = crypto.createHash("sha256").update(bytes).digest("hex");
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-published-"));
  const tarballPath = path.join(directory, `oarlock-${packet.version}.tar`);
  try {
    fs.writeFileSync(tarballPath, bytes, { mode: 0o600 });
    validatePublishedPackage({ expectedVersion: packet.version, expectedChecksum: packet.checksum, release,
      fetchedChecksum: checksum, packageMetadata: inspectPackageMetadata(tarballPath) });
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
  packet.published = { version: release.version, packageName: "oarlock", checksum: release.checksum,
    fetchedChecksum: checksum, url: `https://hex.pm/packages/oarlock/${packet.version}` };
  fs.writeFileSync("release-candidate.json", `${JSON.stringify(packet, null, 2)}\n`, { mode: 0o600 });
}

async function observeHexRelease(version) {
  try {
    const response = await fetch(`https://hex.pm/api/packages/oarlock/releases/${version}`, { signal: AbortSignal.timeout(15_000) });
    if (response.status === 404) return { status: "absent", version: null };
    if (!response.ok) return { status: "unobserved", httpStatus: response.status };
    return await response.json();
  } catch {
    return { status: "unobserved" };
  }
}

async function observeHexState(version, checksum, { observe = observeHexRelease, wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms)) } = {}) {
  for (let attempt = 0; attempt < 4; attempt += 1) {
    const observation = await observe(version);
    const state = classifyHexObservation(version, checksum, observation);
    if (state.state !== "absent" || attempt === 3) return observation;
    await wait(5_000);
  }
  return { status: "unobserved" };
}

async function waitForHexRelease(version) {
  for (let attempt = 0; attempt < 12; attempt += 1) {
    const observation = await observeHexRelease(version);
    const state = classifyHexObservation(version, "0".repeat(64), observation);
    if (state.state === "conflict" && observation.version === version && HEX_DIGEST.test(observation.checksum || "")) return observation;
    if (state.state === "unobserved") reject("Hex release observation", version, "unavailable or malformed response", "Restore Hex registry access before recording release evidence.");
    if (attempt < 11) await new Promise((resolve) => setTimeout(resolve, 10_000));
  }
  reject("Hex release indexing", version, "release remained absent for 120 seconds", "Wait for Hex indexing and rerun post-publish verification.");
}

function recordConsumer() {
  const packet = loadPacket();
  if (!packet.published) reject("consumer verification", "verified Hex release", "no publication verification", "Run Hex metadata and tarball verification first.");
  packet.consumer_compile = "passed";
  fs.writeFileSync("release-candidate.json", `${JSON.stringify(packet, null, 2)}\n`, { mode: 0o600 });
}

if (require.main === module) {
  try {
    const [mode, value] = process.argv.slice(2);
    if (mode === "resolve-tag") console.log(JSON.stringify(resolveRemoteTag(value)));
    else if (mode === "mix-metadata") console.log(JSON.stringify(readMixMetadata()));
    else if (mode === "prepare") prepare().catch((error) => { console.error(`Release preflight: ${error.message}`); process.exitCode = 1; });
    else if (mode === "revalidate") revalidate().catch((error) => { console.error(`Release revalidation: ${error.message}`); process.exitCode = 1; });
    else if (mode === "verify-hex") verifyHex().catch((error) => { console.error(`Hex verification: ${error.message}`); process.exitCode = 1; });
    else if (mode === "record-consumer") recordConsumer();
    else if (mode === "validate-proof") {
      const packet = JSON.parse(fs.readFileSync(value, "utf8"));
      validateCandidateProof(packet.candidate, packet.sha);
      process.stdout.write("Exact-SHA CI proof and artifact identity verified.\n");
    } else throw new Error("Usage: release_integrity.cjs resolve-tag <vX.Y.Z> | mix-metadata | validate-proof <candidate.json>");
  } catch (error) {
    console.error(`Release preflight: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { runRecovery, validateCandidateProof, validateTag, resolveRemoteTag, readMixMetadata, writeJson,
  validateBuild, classifyHexObservation, validatePublishedPackage, buildCandidatePackage, reconcilePublish, observeHexState };
