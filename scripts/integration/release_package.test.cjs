const assert = require("node:assert/strict");
const test = require("node:test");
const { buildCandidatePackage, readMixMetadata } = require("../release_integrity.cjs");

test("pinned Mix build exposes an outer checksum equal to an independent SHA-256", () => {
  const metadata = readMixMetadata();
  const build = buildCandidatePackage(metadata.version);
  assert.equal(build.checksum, build.outerChecksum);
  assert.equal(build.checksum, build.tarballSha256);
  assert.equal(build.packageName, "oarlock");
  assert.equal(build.packageVersion, metadata.version);
});
