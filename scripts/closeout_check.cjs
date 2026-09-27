#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
const { parseWorktreeList, readBoundedRepositoryFile } = require("./lib/repository_truth.cjs");
const MAX = 64 * 1024 * 1024;
const digest = bytes => crypto.createHash("sha256").update(bytes).digest("hex");
function fail(code) { const error = new Error(code); error.code = code; throw error; }
function git(root, args, options = {}) {
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith("GIT_")));
  const readArgs = args[0] === "diff" ? ["-c", "diff.autoRefreshIndex=false", ...args] : args;
  const result = (options.runner || spawnSync)("git", readArgs, { cwd: root, env: { ...env, GIT_OPTIONAL_LOCKS: "0", LC_ALL: "C" }, input: options.input, maxBuffer: MAX, timeout: 30000, encoding: null });
  if (result.error || result.signal || result.status !== 0) fail("CLOSEOUT_GIT_UNREADABLE");
  return Buffer.from(result.stdout);
}
function pathText(bytes) {
  const value = Buffer.from(bytes).toString("utf8");
  if (!Buffer.from(value, "utf8").equals(Buffer.from(bytes))) fail("CLOSEOUT_UNSUPPORTED_PATH_ENCODING");
  return value;
}
function relative(value) {
  if (typeof value !== "string" || !value || value.includes("\0") || path.isAbsolute(value) || value.split(/[\\/]/).some(p => !p || p === "." || p === ".." || p.toLowerCase() === ".git")) fail("CLOSEOUT_UNSAFE_PATH");
  return value;
}
function read(root, file) {
  relative(file);
  return readBoundedRepositoryFile(root, file, { maximumBytes: MAX, encoding: null }).content;
}
function fileRecord(root, file) {
  relative(file);
  const components = file.split("/");
  let current = root;
  for (let i = 0; i < components.length; i++) {
    current = path.join(current, components[i]);
    let stat;
    try { stat = fs.lstatSync(current); } catch (error) {
      if (error.code === "ENOENT") return { path: file, type: "missing" };
      throw error;
    }
    if (i < components.length - 1) {
      if (!stat.isDirectory() || stat.isSymbolicLink()) fail("CLOSEOUT_UNSAFE_PATH");
      continue;
    }
    if (stat.isSymbolicLink()) {
      const target = pathText(fs.readlinkSync(current, { encoding: "buffer" }));
      const targetPath = path.resolve(path.dirname(current), target);
      if (targetPath !== root && !targetPath.startsWith(`${root}${path.sep}`)) fail("CLOSEOUT_SYMLINK_ESCAPE");
      let resolved;
      try { resolved = fs.realpathSync(current); } catch { fail("CLOSEOUT_SYMLINK_UNREADABLE"); }
      if (resolved !== root && !resolved.startsWith(`${root}${path.sep}`)) fail("CLOSEOUT_SYMLINK_ESCAPE");
      const after = fs.lstatSync(current);
      if (stat.ino !== after.ino || stat.ctimeMs !== after.ctimeMs) fail("CLOSEOUT_SOURCE_DRIFT");
      return { path: file, type: "symlink", mode: 0o777, sha256: digest(Buffer.from(target)) };
    }
    if (!stat.isFile()) fail("CLOSEOUT_UNSUPPORTED_FILE");
    if (!(stat.mode & 0o444)) fail("CLOSEOUT_SOURCE_UNREADABLE");
    return { path: file, type: "file", mode: stat.mode & 0o777, sha256: digest(read(root, file)) };
  }
}
function indexObjects(root, entries, options) {
  if (!entries.length) return new Map();
  const ids = [...new Set(entries.map(e => e.oid))];
  const bytes = git(root, ["cat-file", "--batch"], { ...options, input: `${ids.join("\n")}\n` });
  const blobs = new Map();
  let offset = 0;
  for (const oid of ids) {
    const end = bytes.indexOf(10, offset);
    const match = /^([a-f0-9]{40,64}) blob ([0-9]+)$/.exec(bytes.subarray(offset,end).toString());
    if (!match || match[1] !== oid) fail("CLOSEOUT_UNSUPPORTED_OBJECT");
    const size = Number(match[2]), start = end + 1;
    if (start + size >= bytes.length || bytes[start + size] !== 10) fail("CLOSEOUT_OBJECT_TRUNCATED");
    blobs.set(oid, bytes.subarray(start, start + size));
    offset = start + size + 1;
  }
  if (offset !== bytes.length) fail("CLOSEOUT_OBJECT_TRUNCATED");
  return blobs;
}
function expandedFiles(root, options) {
  const ignored = pathText(git(root,["ls-files","--others","--ignored","--exclude-standard","--directory","-z"],options)).split("\0").filter(Boolean);
  const excluded = name => ignored.some(p => p.endsWith("/") ? `${name}/`.startsWith(p) : name === p);
  const found = [];
  function walk(directory, prefix = "") {
    for (const entry of fs.readdirSync(directory,{withFileTypes:true,encoding:"buffer"})) {
      const entryName = pathText(entry.name);
      const name = prefix + entryName;
      if ((!prefix && entryName === ".git") || excluded(name)) continue;
      relative(name);
      if (entry.isDirectory()) walk(path.join(directory,entryName),`${name}/`);
      else found.push(name);
      if (found.length > 50000) fail("CLOSEOUT_CENSUS_TOO_LARGE");
    }
  }
  walk(root);
  return found;
}
function observeTree(root, options = {}) {
  const index = pathText(git(root, ["ls-files", "--stage", "-z"], options));
  const entries = index.split("\0").filter(Boolean).map(token => {
    const m = /^(100644|100755|120000) ([a-f0-9]{40,64}) ([0-3])\t([\s\S]+)$/.exec(token);
    if (!m) fail("CLOSEOUT_UNSUPPORTED_INDEX");
    return { mode: m[1], oid: m[2], stage: Number(m[3]), path: relative(m[4]) };
  });
  const blobs = indexObjects(root, entries, options);
  for (const entry of entries) entry.sha256 = digest(blobs.get(entry.oid));
  const names = pathText(git(root, ["ls-files", "--cached", "--others", "--exclude-standard", "-z"], options)).split("\0").filter(Boolean);
  // Include staged deletions: they no longer appear in ls-files --cached.
  const headNames = pathText(git(root, ["ls-tree", "-r", "--name-only", "-z", "HEAD"], options)).split("\0").filter(Boolean);
  const files = [...new Set([...names,...headNames,...expandedFiles(root,options)])].sort().map(file => fileRecord(root, file));
  const indexFile = git(root, ["rev-parse", "--path-format=absolute", "--git-path", "index"], options).toString().trim();
  const indexBytes = readBoundedRepositoryFile(path.dirname(indexFile), path.basename(indexFile), { encoding: null, maximumBytes: MAX }).content;
  return {
    head: git(root,["rev-parse","HEAD"],options).toString().trim(),
    index_sha256: digest(indexBytes), index_entries: entries, files,
    status: git(root,["status","--porcelain=v1","-z","--untracked-files=all"],options).toString("base64"),
    worktree_patch: digest(git(root,["diff","--binary","--no-ext-diff"],options)),
    index_patch: digest(git(root,["diff","--cached","--binary","--no-ext-diff"],options)),
  };
}
function observe(root, options = {}) {
  root = fs.realpathSync(root);
  const trees = parseWorktreeList(Buffer.from(pathText(git(root,["worktree","list","--porcelain","-z"],options))));
  if (!trees.length || new Set(trees.map(t => t.path)).size !== trees.length) fail("CLOSEOUT_DUPLICATE_TREE");
  const observed = trees.map((tree,i) => {
    if (tree.bare || tree.prunable || fs.realpathSync(tree.path) !== tree.path) fail("CLOSEOUT_TREE_UNREADABLE");
    return { id: `tree-${i}`, path: tree.path, branch: tree.branchRef, lock: tree.lock, ...observeTree(tree.path,options) };
  });
  return { refs: git(root,["for-each-ref","--format=%(refname) %(objectname)"],options).toString(), trees: observed };
}
function equal(left, right, code) {
  if (JSON.stringify(left) !== JSON.stringify(right)) fail(code);
}
function privateVault(candidate, roots) {
  if (!candidate) fail("CLOSEOUT_VAULT_REQUIRED");
  const vault = path.resolve(candidate), stat = fs.lstatSync(vault);
  if (fs.realpathSync(vault) !== vault || !stat.isDirectory() || (stat.mode & 0o077)) fail("CLOSEOUT_VAULT_NOT_PRIVATE");
  if (roots.some(root => vault === root || vault.startsWith(`${root}${path.sep}`))) fail("CLOSEOUT_VAULT_NOT_EXTERNAL");
  return vault;
}
function verifyPreservation(root, manifest, options = {}) {
  const spec = manifest.preservation;
  if (manifest.schema_version !== 1 || !spec || !/^[a-z0-9-]{1,80}$/.test(spec.receipt_id) || !Number.isInteger(spec.tree_count) || spec.tree_count < 1) fail("CLOSEOUT_INVALID_MANIFEST");
  const liveBefore = observe(root, options);
  const vault = privateVault(options.vault || process.env.OARLOCK_CLOSEOUT_VAULT, liveBefore.trees.map(t => t.path));
  const bytes = read(vault, `receipts/${spec.receipt_id}.json`);
  if (digest(bytes) !== read(vault, `receipts/${spec.receipt_id}.sha256`).toString().trim()) fail("CLOSEOUT_CORRUPT_RECEIPT");
  const receipt = JSON.parse(bytes);
  if (receipt.schema_version !== 1 || receipt.receipt_id !== spec.receipt_id || receipt.source_root !== fs.realpathSync(root)) fail("CLOSEOUT_WRONG_RECEIPT");
  if (!options.historical) equal(liveBefore, receipt.observed, "CLOSEOUT_SOURCE_DRIFT");
  const before = receipt.observed;
  if (spec.tree_count !== before.trees.length) fail("CLOSEOUT_OMITTED_TREE");
  if (digest(read(vault, receipt.bundle)) !== receipt.bundle_sha256) fail("CLOSEOUT_CORRUPT_BUNDLE");
  git(root, ["bundle", "verify", path.join(vault, relative(receipt.bundle))], options);
  const refs = new Map(git(root,["bundle","list-heads",path.join(vault,receipt.bundle)],options).toString().trim().split("\n").map(line => { const i=line.indexOf(" "); return [line.slice(i+1),line.slice(0,i)]; }));
  for (const row of before.refs.trim().split("\n").filter(Boolean)) {
    const [ref, oid] = row.split(" ");
    if (refs.get(ref) !== oid) fail("CLOSEOUT_OMITTED_REF");
  }
  if (!Array.isArray(receipt.restored) || receipt.restored.length !== before.trees.length || new Set(receipt.restored.map(r => r.tree_id)).size !== before.trees.length) fail("CLOSEOUT_OMITTED_RESTORE");
  for (const tree of before.trees) {
    const restoration = receipt.restored.find(r => r.tree_id === tree.id);
    if (!restoration) fail("CLOSEOUT_OMITTED_RESTORE");
    const restore = path.join(vault, relative(restoration.path));
    if (fs.realpathSync(restore) !== restore || !restore.startsWith(`${vault}/restored/`)) fail("CLOSEOUT_UNSAFE_RESTORE");
    const checksums = [tree.index_sha256, tree.worktree_patch, tree.index_patch, ...tree.index_entries.map(e => e.sha256), ...tree.files.filter(e => e.type !== "missing").map(e => e.sha256)];
    for (const sha of new Set(checksums)) {
      if (!/^[a-f0-9]{64}$/.test(sha) || digest(read(vault, `blobs/${sha}`)) !== sha) fail("CLOSEOUT_CORRUPT_BLOB");
    }
    const { id, path: sourcePath, branch, lock, ...expected } = tree;
    equal(observeTree(restore,options), expected, "CLOSEOUT_RESTORE_MISMATCH");
  }
  if (options.afterRead) options.afterRead();
  equal(observe(root, options), liveBefore, "CLOSEOUT_SOURCE_DRIFT");
  return { receipt_id: spec.receipt_id, snapshot_sha256: digest(bytes), tree_count: before.trees.length, restored: true, cleanup_authorized: false };
}
const SHA = /^[a-f0-9]{40}$/;
const EVIDENCE_PATH = /^(?:\.planning\/(?:STATE|ROADMAP|REQUIREMENTS|EVIDENCE|v2\.2-HANDOFF|v2\.2-CLOSEOUT-PLAN)\.md|\.planning\/phases\/(?:3[1-7]-[a-z0-9-]+)\/(?:3[1-7]-(?:0[1-4]-SUMMARY|VERIFICATION|VALIDATION|UAT|CANDIDATE|RECONCILIATION|REVIEW|SECURITY)\.md|37-CLOSEOUT\.json))$/;
function diffIdentity(root, base, head, options = {}) {
  if (!SHA.test(base) || !SHA.test(head)) fail("CLOSEOUT_INVALID_SHA");
  const tokens = pathText(git(root,["diff","--raw","--no-abbrev","--no-renames","-z",base,head],options)).split("\0");
  const changes=[];
  for(let i=0;i<tokens.length-1;i+=2) {
    const match=/^:([0-9]{6}) ([0-9]{6}) ([a-f0-9]{40}) ([a-f0-9]{40}) ([AMD])$/.exec(tokens[i]);
    if(!match) fail("CLOSEOUT_UNSUPPORTED_DIFF");
    changes.push({path:relative(tokens[i+1]),before_mode:match[1],after_mode:match[2],before_oid:match[3],after_oid:match[4],status:match[5]});
  }
  return changes;
}
function verifyEvidenceLineage(root, lineage, options = {}) {
  if (lineage?.schema_version !== 1 || !SHA.test(lineage.tested_payload_sha) || !Array.isArray(lineage.evidence_paths) || !lineage.evidence_paths.length || new Set(lineage.evidence_paths).size !== lineage.evidence_paths.length || lineage.evidence_paths.some(p=>!EVIDENCE_PATH.test(p))) fail("CLOSEOUT_INVALID_LINEAGE");
  const payload=lineage.tested_payload_sha;
  const evidence=git(root,["rev-parse","HEAD"],options).toString().trim();
  git(root,["merge-base","--is-ancestor",payload,evidence],options);
  const changes=diffIdentity(root,payload,evidence,options);
  if (!changes.length || changes.some(c=>!lineage.evidence_paths.includes(c.path) || c.after_mode!=="100644")) fail("CLOSEOUT_UNALLOWLISTED_TAIL");
  const vault=privateVault(options.vault || process.env.OARLOCK_CLOSEOUT_VAULT,[fs.realpathSync(root)]);
  const reviewed=JSON.parse(read(vault,"evidence-tail.json"));
  if(reviewed.schema_version!==1 || reviewed.payload_sha!==payload || reviewed.evidence_sha!==evidence) fail("CLOSEOUT_TAIL_REVIEW_MISMATCH");
  equal(reviewed.changes,changes,"CLOSEOUT_TAIL_REVIEW_MISMATCH");
  const {inspectHistory}=require("./history_integrity.cjs");
  if(inspectHistory(payload,evidence,{cwd:root}).status!=="healthy") fail("CLOSEOUT_HISTORY_CHANGED");
  return {tested_payload_sha:payload,evidence_sha:evidence,changed_evidence_paths:changes.map(c=>c.path)};
}
function externalJson(command,args,options={}) {
  const result=(options.commandRunner || spawnSync)(command,args,{encoding:"utf8",maxBuffer:MAX,timeout:120000,env:{...process.env,GIT_OPTIONAL_LOCKS:"0"}});
  if(result.error || result.signal || result.status!==0) fail("CLOSEOUT_EXTERNAL_PROOF_UNAVAILABLE");
  return JSON.parse(result.stdout);
}
function remoteProof(mode,repository,sha,options) {
  if(options.remoteGate) return options.remoteGate(mode,repository,sha);
  const args=[path.join(__dirname,"ci_remote_gate.cjs"),mode,"--repo",repository,"--json"];
  if(mode==="candidate")args.push("--sha",sha);
  return externalJson(process.execPath,args,options);
}
function dirtyPaths(tree) {
  const records=pathText(Buffer.from(tree.status,"base64")).split("\0");
  const paths=[];
  for(let i=0;i<records.length-1;i++) {
    paths.push(relative(records[i].slice(3)));
    if(/[RC]/.test(records[i].slice(0,2)))paths.push(relative(records[++i]));
  }
  return [...new Set(paths)];
}
function verifyGroups(manifest,receipt,candidate,options) {
  if(!Array.isArray(manifest.groups))fail("CLOSEOUT_GROUPS_MISSING");
  const covered=new Set();
  for(const group of manifest.groups) {
    if(!["adopt","already-contained","preserve-external"].includes(group.disposition) || !Array.isArray(group.paths))fail("CLOSEOUT_UNRESOLVED_DISPOSITION");
    const tree=group.tree_id || "tree-0";
    for(const p of group.paths) {
      relative(p);const key=`${tree}:${p}`;
      if(covered.has(key))fail("CLOSEOUT_DUPLICATE_DISPOSITION");
      covered.add(key);
      if(group.disposition!=="preserve-external") {
        const row=manifest.candidate.adopted?.find(row=>row.tree_id===tree && row.path===p);
        if(!row)fail("CLOSEOUT_ADOPTION_UNREVIEWED");
        const object=git(candidate,["ls-tree","-z",manifest.candidate.sha,"--",p],options).toString();
        const expected=object ? /^(\d+) blob ([a-f0-9]+)\t/.exec(object) : null;
        if(object && !expected)fail("CLOSEOUT_UNSUPPORTED_OBJECT");
        if(row.mode!==(expected?.[1] || "000000") || row.oid!==(expected?.[2] || "0".repeat(40)))fail("CLOSEOUT_ADOPTION_MISMATCH");
      }
    }
  }
  for(const tree of receipt.observed.trees)for(const p of dirtyPaths(tree))if(!covered.has(`${tree.id}:${p}`))fail("CLOSEOUT_OMITTED_DISPOSITION");
}
function verifyCandidate(root,manifest,options={}) {
  const spec=manifest.candidate;
  if(manifest.schema_version!==1 || !spec || !SHA.test(spec.sha) || !SHA.test(spec.base_sha) || !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(spec.repository) || !Number.isInteger(spec.pr_number) || spec.pr_number<1 || typeof spec.branch!=="string" || !spec.branch)fail("CLOSEOUT_INVALID_CANDIDATE");
  const preservation=verifyPreservation(root,manifest,{...options,historical:true});
  const vault=privateVault(options.vault || process.env.OARLOCK_CLOSEOUT_VAULT,[fs.realpathSync(root)]);
  const locations=JSON.parse(read(vault,"locations.json"));
  const candidate=locations.candidate;
  if(typeof candidate!=="string" || !path.isAbsolute(candidate) || fs.realpathSync(candidate)!==candidate)fail("CLOSEOUT_CANDIDATE_UNREADABLE");
  const candidateBefore=observeTree(candidate,options);
  const identity={sha:candidateBefore.head,parent:git(candidate,["rev-parse","HEAD^"],options).toString().trim(),branch:git(candidate,["branch","--show-current"],options).toString().trim(),remote:git(candidate,["remote","get-url","origin"],options).toString().trim()};
  const remotes=[`https://github.com/${spec.repository}`,`https://github.com/${spec.repository}.git`,`git@github.com:${spec.repository}`,`git@github.com:${spec.repository}.git`];
  if(identity.sha!==spec.sha || identity.parent!==spec.base_sha || identity.branch!==spec.branch || !remotes.includes(identity.remote) || candidateBefore.status)fail("CLOSEOUT_CANDIDATE_MISMATCH");
  equal(diffIdentity(candidate,spec.base_sha,spec.sha,options),spec.changes,"CLOSEOUT_CANDIDATE_DIFF_MISMATCH");
  const receipt=JSON.parse(read(vault,`receipts/${manifest.preservation.receipt_id}.json`));
  verifyGroups(manifest,receipt,candidate,options);
  const pr=options.readPullRequest ? options.readPullRequest(spec.repository,spec.pr_number) : externalJson("gh",["pr","view",String(spec.pr_number),"--repo",spec.repository,"--json","headRefOid,state,baseRefName,mergedAt"],options);
  if(pr.headRefOid!==spec.sha || pr.state!=="OPEN" || pr.baseRefName!=="main" || pr.mergedAt)fail("CLOSEOUT_PR_MISMATCH");
  const proof=remoteProof("candidate",spec.repository,spec.sha,options), expected=spec.proof_identity;
  if(!proof?.observed || !proof.verified || proof.sha!==spec.sha || proof.eventHeadSha!==spec.sha || !expected || proof.run?.id!==expected.run_id || proof.run?.attempt!==expected.attempt || proof.artifact?.id!==expected.artifact_id || proof.artifact?.digest!==expected.digest || proof.testedSha!==expected.tested_sha || proof.run?.headSha!==spec.sha || proof.artifact?.headSha!==spec.sha || proof.artifact?.runId!==expected.run_id || !/^sha256:[a-f0-9]{64}$/.test(expected.digest || "") || !SHA.test(expected.tested_sha))fail("CLOSEOUT_PROOF_MISMATCH");
  equal(observeTree(candidate,options),candidateBefore,"CLOSEOUT_CANDIDATE_DRIFT");
  return {preservation,tested_payload_sha:spec.sha,main_base_sha:spec.base_sha,proof_identity:expected};
}
function verifyFinal(root,manifest,options={}) {
  const before=observe(root,options);
  const candidate=verifyCandidate(root,manifest,options);
  const lineage=verifyEvidenceLineage(root,manifest.lineage,options);
  if(lineage.tested_payload_sha!==manifest.candidate.sha)fail("CLOSEOUT_LINEAGE_PAYLOAD_MISMATCH");
  const vault=privateVault(options.vault || process.env.OARLOCK_CLOSEOUT_VAULT,before.trees.map(t=>t.path));
  const receipt=JSON.parse(read(vault,`receipts/${manifest.preservation.receipt_id}.json`));
  const snapshot=manifest.lineage.source_snapshot;
  const original=receipt.observed.trees.find(t=>t.id===snapshot?.tree_id);
  if(snapshot?.receipt_id!==receipt.receipt_id || original?.head!==snapshot?.head_sha || original?.path!==fs.realpathSync(root))fail("CLOSEOUT_SNAPSHOT_LINEAGE_MISMATCH");
  equal(before.trees.map(t=>({id:t.id,path:t.path})),receipt.observed.trees.map(t=>({id:t.id,path:t.path})),"CLOSEOUT_TREE_CENSUS_MISMATCH");
  if(before.trees.some(t=>t.lock || t.status))fail("CLOSEOUT_WORKTREE_NOT_CLEAN");
  if(!Array.isArray(manifest.open_blockers) || manifest.open_blockers.length)fail("CLOSEOUT_OPEN_BLOCKERS");
  const main=remoteProof("main",manifest.candidate.repository,null,options);
  if(!main?.observed || !main.verified || !SHA.test(main.sha) || main.sha!==manifest.candidate.base_sha || !main.candidate?.verified || main.candidate.sha!==main.sha || main.candidate.eventHeadSha!==main.sha)fail("CLOSEOUT_MAIN_PROOF_MISMATCH");
  if(options.afterFinalRead)options.afterFinalRead();
  equal(observe(root,options),before,"CLOSEOUT_SOURCE_DRIFT");
  return {...candidate,...lineage,live_main_sha:main.sha,tree_count:before.trees.length,clean:true};
}
function main(argv = process.argv.slice(2), options = {}) {
  let result, status;
  try {
    let stage, manifestPath;
    const seen = new Set();
    for (let i=0;i<argv.length;i++) {
      const key = argv[i];
      if (seen.has(key)) fail("CLOSEOUT_INVALID_ARGUMENTS");
      seen.add(key);
      if (key === "--stage") stage = argv[++i];
      else if (key === "--manifest") manifestPath = argv[++i];
      else if (key !== "--json") fail("CLOSEOUT_INVALID_ARGUMENTS");
    }
    if (!["preservation","candidate","final"].includes(stage) || !manifestPath) fail("CLOSEOUT_INVALID_ARGUMENTS");
    const manifestAbsolute = path.resolve(options.cwd || process.cwd(), manifestPath);
    const manifest = JSON.parse(read(path.dirname(manifestAbsolute), path.basename(manifestAbsolute)));
    const check = {preservation:verifyPreservation,candidate:verifyCandidate,final:verifyFinal}[stage];
    const facts = check(options.cwd || process.cwd(), manifest, options);
    result = { schema_version: 1, stage, status: "passed", facts, diagnostics: [] }; status = 0;
  } catch (error) {
    // Repository contents, command stderr and personal paths never reach diagnostics.
    result = { schema_version: 1, status: "incomplete", diagnostics: [{ code: /^CLOSEOUT_[A-Z_]+$/.test(error.code || "") ? error.code : "CLOSEOUT_UNREADABLE_EVIDENCE" }] }; status = 2;
  }
  (options.stdout || process.stdout).write(`${JSON.stringify(result, null, 2)}\n`);
  return status;
}
if (require.main === module) process.exitCode = main();
module.exports = { main, observe, observeTree, digest, git, read, relative, indexObjects, verifyPreservation, verifyCandidate, verifyFinal, verifyEvidenceLineage, diffIdentity };
