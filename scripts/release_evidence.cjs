#!/usr/bin/env node

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const SHA = /^[a-f0-9]{40}$/i;
const DIGEST = /^[a-f0-9]{64}$/i;
const SAFE_RECORD_KEYS = new Set([
  "schema_version", "repository", "tag", "peeled_sha", "package_name", "package_version",
  "ci_run_url", "ci_run_id", "ci_run_attempt", "ci_artifact_id", "ci_artifact_digest",
  "release_workflow_run", "release_workflow_run_id", "release_workflow_attempt", "dry_run",
  "candidate_sha256", "hex_release_url", "hex_checksum", "fetched_tarball_sha256",
  "fetched_tarball_verified", "downstream_compile", "created_at", "caveats", "accepted_attempts",
]);

function fail(message) { throw new Error(`Release evidence ${message}`); }
function requiredString(value, label, pattern) {
  if (typeof value !== "string" || !value.trim() || (pattern && !pattern.test(value))) fail(`requires a valid ${label}.`);
  return value;
}
function safeUrl(value, hosts, label) {
  requiredString(value, label);
  let parsed;
  try { parsed = new URL(value); } catch { fail(`requires a valid ${label} URL.`); }
  if (parsed.protocol !== "https:" || !hosts.includes(parsed.hostname) || parsed.username || parsed.password || parsed.search || parsed.hash) fail(`contains an unsafe ${label} URL.`);
  return parsed.toString().replace(/\/$/, "");
}
function positiveInteger(value, label) {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number <= 0) fail(`requires a positive ${label}.`);
  return number;
}
function validateExisting(record) {
  if (!record || typeof record !== "object" || Array.isArray(record) || record.schema_version !== 1 || Object.keys(record).some((key) => !SAFE_RECORD_KEYS.has(key))) fail("asset has an unsupported schema or fields.");
  if (!Array.isArray(record.accepted_attempts) || record.accepted_attempts.length < 1) fail("asset is missing accepted attempt history.");
  for (const attempt of record.accepted_attempts) {
    if (!attempt || Object.keys(attempt).some((key) => !["ci_run_id", "ci_run_attempt", "ci_run_url", "release_workflow_run_id", "release_workflow_attempt", "created_at"].includes(key))) fail("asset contains malformed accepted attempt history.");
    positiveInteger(attempt.ci_run_id, "prior CI run ID");
    positiveInteger(attempt.ci_run_attempt, "prior CI attempt");
    safeUrl(attempt.ci_run_url, ["github.com"], "prior CI run");
    positiveInteger(attempt.release_workflow_run_id, "prior release workflow run ID");
    positiveInteger(attempt.release_workflow_attempt, "prior release workflow attempt");
    requiredString(attempt.created_at, "prior attempt timestamp");
  }
  return record;
}

function attemptFrom(record) {
  return {
    ci_run_id: record.ci_run_id,
    ci_run_attempt: record.ci_run_attempt,
    ci_run_url: record.ci_run_url,
    release_workflow_run_id: record.release_workflow_run_id,
    release_workflow_attempt: record.release_workflow_attempt,
    created_at: record.created_at,
  };
}

function buildEvidence(packet, env = process.env, now = () => new Date().toISOString()) {
  const candidate = packet?.candidate;
  const published = packet?.published;
  const repository = requiredString(packet?.repository, "repository");
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) fail("repository identity is malformed.");
  const tag = requiredString(packet?.tag, "release tag", /^v(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$/);
  const version = requiredString(packet?.version, "package version", /^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$/);
  const sha = requiredString(packet?.sha, "peeled source SHA", SHA).toLowerCase();
  if (tag !== `v${version}` || packet.schema_version !== 1 || candidate?.verified !== true || candidate.sha?.toLowerCase() !== sha) fail("has mismatched or unverified source identity.");
  if (published?.version !== version || published.packageName !== "oarlock" || packet.packageName !== "oarlock" || packet.packageVersion !== version || packet.consumer_compile !== "passed") fail("requires successful matching package and clean-consumer verification.");
  const candidateChecksum = requiredString(packet.checksum, "candidate checksum", DIGEST).toLowerCase();
  const hexChecksum = requiredString(published.checksum, "Hex checksum", DIGEST).toLowerCase();
  const fetchedChecksum = requiredString(published.fetchedChecksum, "fetched tarball checksum", DIGEST).toLowerCase();
  if (candidateChecksum !== hexChecksum || candidateChecksum !== fetchedChecksum) fail("checksums contradict verified candidate bytes.");
  const candidateRun = candidate.run || {};
  const artifact = candidate.artifact || {};
  const ciRunId = positiveInteger(candidateRun.id, "CI run ID");
  const ciAttempt = positiveInteger(candidateRun.attempt, "CI run attempt");
  const artifactId = positiveInteger(artifact.id, "CI artifact ID");
  const artifactDigest = requiredString(artifact.digest, "CI artifact digest", /^sha256:[a-f0-9]{64}$/i).toLowerCase();
  if (artifact.runId !== ciRunId || artifact.headSha?.toLowerCase() !== sha || artifact.name !== `ci-proof-${ciRunId}-${ciAttempt}`) fail("artifact identity does not match the accepted CI run.");
  if (!packet.dryRunOutput || typeof packet.dryRunOutput !== "string") fail("requires a successful Hex dry-run record.");
  const releaseRunId = positiveInteger(env.RELEASE_RUN_ID, "release workflow run ID");
  const releaseAttempt = positiveInteger(env.RELEASE_RUN_ATTEMPT, "release workflow attempt");
  const releaseRunUrl = safeUrl(env.RELEASE_WORKFLOW_RUN, ["github.com"], "release workflow run");
  if (!releaseRunUrl.endsWith(`/actions/runs/${releaseRunId}`)) fail("release workflow URL and run ID disagree.");
  const createdAt = requiredString(now(), "creation timestamp");
  const record = {
    schema_version: 1,
    repository,
    tag,
    peeled_sha: sha,
    package_name: "oarlock",
    package_version: version,
    ci_run_url: safeUrl(candidateRun.url, ["github.com"], "CI run"),
    ci_run_id: ciRunId,
    ci_run_attempt: ciAttempt,
    ci_artifact_id: artifactId,
    ci_artifact_digest: artifactDigest,
    release_workflow_run: releaseRunUrl,
    release_workflow_run_id: releaseRunId,
    release_workflow_attempt: releaseAttempt,
    dry_run: "passed",
    candidate_sha256: candidateChecksum,
    hex_release_url: safeUrl(published.url, ["hex.pm"], "Hex release"),
    hex_checksum: hexChecksum,
    fetched_tarball_sha256: fetchedChecksum,
    fetched_tarball_verified: true,
    downstream_compile: "passed",
    created_at: createdAt,
    caveats: ["GitHub Actions concurrency queue order is not a release-order guarantee."],
    accepted_attempts: [],
  };
  record.accepted_attempts.push(attemptFrom(record));
  return record;
}

function mergeAcceptedEvidence(current, prior) {
  if (!prior) return current;
  validateExisting(prior);
  for (const key of ["schema_version", "repository", "tag", "peeled_sha", "package_name", "package_version", "candidate_sha256", "hex_checksum", "fetched_tarball_sha256", "hex_release_url"]) {
    if (prior[key] !== current[key]) fail(`cannot replace contradictory prior asset field ${key}.`);
  }
  const attempts = [...prior.accepted_attempts, attemptFrom(current)];
  const unique = new Map(attempts.map((attempt) => [`${attempt.release_workflow_run_id}/${attempt.release_workflow_attempt}`, attempt]));
  return { ...current, accepted_attempts: [...unique.values()] };
}

function gh(args, options = {}) {
  const result = spawnSync("gh", args, { encoding: "utf8", timeout: 30_000, maxBuffer: 1024 * 1024, env: process.env, ...options });
  if (result.error || result.status !== 0) return { status: result.status, stdout: result.stdout || "", stderr: result.stderr || "" };
  return { status: 0, stdout: result.stdout || "", stderr: "" };
}

function loadPriorAsset(repository, tag) {
  const releaseResult = gh(["api", `repos/${repository}/releases/tags/${tag}`]);
  if (releaseResult.status !== 0) {
    if (/HTTP 404|Not Found/i.test(releaseResult.stderr)) return { release: null, prior: null };
    fail("could not read the matching GitHub Release; retry when GitHub is available.");
  }
  const release = JSON.parse(releaseResult.stdout);
  const asset = release.assets?.find((item) => item.name === "release-evidence.json");
  if (!asset) return { release, prior: null };
  const downloaded = gh(["api", `repos/${repository}/releases/assets/${asset.id}`, "-H", "Accept: application/octet-stream"]);
  if (downloaded.status !== 0) fail("could not inspect the existing evidence asset; refusing to replace it.");
  let prior;
  try { prior = JSON.parse(downloaded.stdout); } catch { fail("existing evidence asset is not valid JSON; refusing to replace it."); }
  return { release, prior };
}

function attachEvidence(evidence) {
  const packet = evidence;
  const { release, prior } = loadPriorAsset(packet.repository, packet.tag);
  const merged = mergeAcceptedEvidence(packet, prior);
  const file = path.resolve("release-evidence.json");
  fs.writeFileSync(file, `${JSON.stringify(merged, null, 2)}\n`, { mode: 0o600 });
  if (!release) {
    const created = gh(["release", "create", packet.tag, "--title", packet.tag, "--notes", `Verified Oarlock ${packet.package_version} release. See release-evidence.json for exact source, CI, and package checksums.`]);
    if (created.status !== 0) fail("GitHub Release could not be created; verify tag permissions and retry evidence attachment.");
  }
  const uploaded = gh(["release", "upload", packet.tag, file, "--clobber"]);
  if (uploaded.status !== 0) fail("asset upload failed; release verification remains incomplete. Confirm contents:write permission and retry.");
  return merged;
}

function main() {
  const packetPath = process.argv[2];
  if (!packetPath) fail("usage: release_evidence.cjs <release-candidate.json>");
  const packet = JSON.parse(fs.readFileSync(packetPath, "utf8"));
  const evidence = buildEvidence(packet);
  attachEvidence(evidence);
  process.stdout.write(`Attached verified release evidence for ${evidence.tag} at ${evidence.peeled_sha}.\n`);
}

if (require.main === module) {
  try { main(); } catch (error) { console.error(`Release evidence: ${error.message}`); process.exitCode = 1; }
}
module.exports = { buildEvidence, mergeAcceptedEvidence, validateExisting };
