"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const checker = require("./closeout_check.cjs");
const { git, capture } = require("./fixtures/closeout_snapshot.cjs");
function fixture(t) {
  const container = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-closeout-")));
  t.after(() => fs.rmSync(container, { recursive: true, force: true }));
  const root = path.join(container, "source"), linked = path.join(container, "linked\nwith space");
  fs.mkdirSync(root);
  git(root, ["init", "-b", "main"]);
  for (const [file, value] of Object.entries({"empty":"", "large.bin":Buffer.alloc(200000,9), "mixed.txt":"baseline", "deleted.txt":"delete me", "binary.bin":Buffer.from([0,1,2]), "executable":"baseline"})) fs.writeFileSync(path.join(root,file), value);
  git(root, ["add", "empty", "large.bin", "mixed.txt", "deleted.txt", "binary.bin", "executable"]);
  git(root, ["commit", "-m", "baseline"]);
  git(root, ["worktree", "add", "-b", "linked", linked]);
  fs.writeFileSync(path.join(root, "mixed.txt"), "index version");
  git(root, ["add", "mixed.txt"]);
  fs.writeFileSync(path.join(root, "mixed.txt"), "worktree version");
  fs.unlinkSync(path.join(root, "deleted.txt"));
  fs.writeFileSync(path.join(root, "binary.bin"), Buffer.from([0,255,19]));
  fs.chmodSync(path.join(root, "executable"), 0o755);
  fs.mkdirSync(path.join(root, "nested"));
  fs.writeFileSync(path.join(root, "nested", "space\nand newline"), "untracked");
  fs.symlinkSync("mixed.txt", path.join(root, "link"));
  fs.writeFileSync(path.join(linked, "own.txt"), "linked contribution");
  git(root, ["worktree", "lock", "--reason", "fixture owner", linked]);
  const vault = path.join(container, "vault"), manifestPath = path.join(container, "manifest.json");
  fs.writeFileSync(manifestPath, JSON.stringify({ schema_version: 1, preservation: { receipt_id: "original", tree_count: 2 } }));
  return { root, linked, vault, container, manifestPath };
}
function invoke(state, stage = "preservation", options = {}) {
  let output = "";
  const status = checker.main(["--stage",stage,"--manifest",state.manifestPath,"--json"], { cwd: state.root, vault: state.vault, stdout: { write(s) { output += s; } }, ...options });
  return { status, result: JSON.parse(output) };
}
test("tracer: independent restore preserves both index and worktree versions for every tree", (t) => {
  const state = fixture(t);
  const before = checker.observe(state.root);
  capture(state.root, state.vault, "original", checker.observe);
  const result = invoke(state);
  assert.equal(result.status, 0, JSON.stringify(result));
  assert.equal(result.result.facts.tree_count, 2);
  assert.deepEqual(checker.observe(state.root), before, "checker must not change refs, index or files");
  const restored = path.join(state.vault, "restored/original-0");
  assert.equal(git(restored, ["show", ":mixed.txt"]).toString(), "index version");
  assert.equal(fs.readFileSync(path.join(restored, "mixed.txt"), "utf8"), "worktree version");
  assert.equal(fs.existsSync(path.join(restored, "deleted.txt")), false);
  assert.equal(fs.readlinkSync(path.join(restored, "link")), "mixed.txt");
  assert.equal(fs.statSync(path.join(restored, "executable")).mode & 0o777, 0o755);
});

function changeReceipt(state, transform) {
  const file = path.join(state.vault,"receipts/original.json");
  const receipt = JSON.parse(fs.readFileSync(file));
  transform(receipt);
  const bytes = Buffer.from(`${JSON.stringify(receipt)}\n`);
  fs.writeFileSync(file,bytes);
  fs.writeFileSync(path.join(state.vault,"receipts/original.sha256"),checker.digest(bytes));
}
for (const [name, mutate, code] of [
  ["omitted tree", s => changeReceipt(s,r => r.observed.trees.pop()), "CLOSEOUT_SOURCE_DRIFT"],
  ["omitted nested untracked file", s => changeReceipt(s,r => r.observed.trees[0].files = r.observed.trees[0].files.filter(f => !f.path.startsWith("nested/"))), "CLOSEOUT_SOURCE_DRIFT"],
  ["duplicate restore identity", s => changeReceipt(s,r => r.restored[1] = r.restored[0]), "CLOSEOUT_OMITTED_RESTORE"],
  ["corrupt blob", s => { const r=JSON.parse(fs.readFileSync(path.join(s.vault,"receipts/original.json"))); fs.writeFileSync(path.join(s.vault,"blobs",r.observed.trees[0].index_sha256),"corruption"); }, "CLOSEOUT_CORRUPT_BLOB"],
  ["changed restored work", s => fs.writeFileSync(path.join(s.vault,"restored/original-0/mixed.txt"),"corruption"), "CLOSEOUT_RESTORE_MISMATCH"],
  ["traversal in bundle path", s => changeReceipt(s,r => r.bundle="../secret"), "CLOSEOUT_UNSAFE_PATH"],
  ["symlink vault escape", s => { fs.renameSync(path.join(s.vault,"blobs"),path.join(s.container,"moved")); fs.symlinkSync(path.join(s.container,"moved"),path.join(s.vault,"blobs")); }, "CLOSEOUT_UNREADABLE_EVIDENCE"],
  ["corrupt bundle", s => fs.appendFileSync(path.join(s.vault,"bundles/original.bundle"),"corrupt"), "CLOSEOUT_CORRUPT_BUNDLE"],
  ["new uncaptured source", s => fs.writeFileSync(path.join(s.linked,"new.txt"),"private data must never appear"), "CLOSEOUT_SOURCE_DRIFT"],
]) test(`preservation rejects ${name}`, t => {
  const s=fixture(t); capture(s.root,s.vault,"original",checker.observe); mutate(s);
  const out=invoke(s); assert.equal(out.status,2); assert.equal(out.result.diagnostics[0].code,code);
  assert.ok(!JSON.stringify(out).includes(s.container)); assert.ok(!JSON.stringify(out).includes("private data"));
});
test("concurrent source change invalidates the whole observation", t => {
  const s=fixture(t); capture(s.root,s.vault,"original",checker.observe);
  const out=invoke(s,"preservation",{afterRead(){fs.writeFileSync(path.join(s.root,"mixed.txt"),"racing writer");}});
  assert.equal(out.status,2); assert.equal(out.result.diagnostics[0].code,"CLOSEOUT_SOURCE_DRIFT");
});
test("unsupported files, unreadable files and escaping symlinks fail closed", t => {
  const s=fixture(t);
  fs.unlinkSync(path.join(s.root,"link")); fs.symlinkSync("../../outside",path.join(s.root,"link"));
  assert.throws(()=>checker.observe(s.root),/CLOSEOUT_SYMLINK_ESCAPE/);
  fs.unlinkSync(path.join(s.root,"link"));
  fs.chmodSync(path.join(s.root,"mixed.txt"),0);
  assert.throws(()=>checker.observe(s.root),/CLOSEOUT_SOURCE_UNREADABLE/);
  fs.chmodSync(path.join(s.root,"mixed.txt"),0o644);
  const {spawnSync}=require("node:child_process");
  assert.equal(spawnSync("mkfifo",[path.join(s.root,"pipe")]).status,0);
  assert.throws(()=>checker.observe(s.root),/CLOSEOUT_UNSUPPORTED_FILE/);
});
test("duplicate worktrees and denied Git reads cannot appear successful", t => {
  const s=fixture(t); const {spawnSync}=require("node:child_process");
  assert.throws(()=>checker.observe(s.root,{runner(){return {status:1,stderr:Buffer.from("private stderr")};}}),/CLOSEOUT_GIT_UNREADABLE/);
  assert.throws(()=>checker.observe(s.root,{runner(command,args,options){const r=spawnSync(command,args,options);if(args[0]==="worktree")r.stdout=Buffer.concat([r.stdout,r.stdout]);return r;}}),/CLOSEOUT_DUPLICATE_TREE/);
});
test("unimplemented later stages and malformed arguments cannot pass", t => {
  const s=fixture(t);
  for(const stage of ["candidate","final"])assert.equal(invoke(s,stage).status,2);
  let output="";
  assert.equal(checker.main(["--stage","preservation","--stage","final"],{stdout:{write(v){output+=v;}}}),2);
  assert.equal(JSON.parse(output).diagnostics[0].code,"CLOSEOUT_INVALID_ARGUMENTS");
});

function rawChanges(root, base, head) {
  const tokens=git(root,["diff","--raw","--no-abbrev","--no-renames","-z",base,head]).toString().split("\0");
  const rows=[];
  for(let i=0;i<tokens.length-1;i+=2){const [before_mode,after_mode,before_oid,after_oid,status]=tokens[i].slice(1).split(" ");rows.push({path:tokens[i+1],before_mode,after_mode,before_oid,after_oid,status});}
  return rows;
}
function finalFixture(t) {
  const s=fixture(t);
  const base=git(s.root,["rev-parse","HEAD"]).toString().trim();
  git(s.root,["add","--all"]);git(s.root,["commit","-m","payload"]);
  git(s.linked,["add","own.txt"]);git(s.linked,["commit","-m","retain linked contribution"]);
  git(s.root,["worktree","unlock",s.linked]);
  const payload=git(s.root,["rev-parse","HEAD"]).toString().trim();
  const candidate=path.join(s.container,"candidate");git(s.container,["clone",s.root,candidate]);
  git(candidate,["remote","set-url","origin","https://github.com/example/project.git"]);
  const observed=checker.observe(s.root);
  capture(s.root,s.vault,"original",checker.observe);
  const handoff=".planning/v2.2-HANDOFF.md";
  fs.mkdirSync(path.join(s.root,".planning"));
  fs.writeFileSync(path.join(s.root,handoff),JSON.stringify({observed_head_sha:payload,tested_payload_sha:payload}));
  git(s.root,["add",handoff]);git(s.root,["commit","-m","record evidence without its own future SHA"]);
  const evidence=git(s.root,["rev-parse","HEAD"]).toString().trim();
  const proof={observed:true,verified:true,sha:payload,eventHeadSha:payload,testedSha:"e".repeat(40),run:{id:123,attempt:1,headSha:payload},artifact:{id:456,digest:`sha256:${"d".repeat(64)}`,headSha:payload,runId:123}};
  const manifest={schema_version:1,preservation:{receipt_id:"original",tree_count:2},groups:[],open_blockers:[],candidate:{repository:"example/project",sha:payload,base_sha:base,branch:"main",pr_number:1,changes:rawChanges(s.root,base,payload),proof_identity:{run_id:123,attempt:1,artifact_id:456,digest:proof.artifact.digest,tested_sha:proof.testedSha}},lineage:{schema_version:1,tested_payload_sha:payload,source_snapshot:{receipt_id:"original",tree_id:"tree-0",head_sha:payload},evidence_paths:[handoff]}};
  fs.writeFileSync(s.manifestPath,JSON.stringify(manifest));
  fs.writeFileSync(path.join(s.vault,"locations.json"),JSON.stringify({candidate}));
  fs.writeFileSync(path.join(s.vault,"evidence-tail.json"),JSON.stringify({schema_version:1,payload_sha:payload,evidence_sha:evidence,changes:rawChanges(s.root,payload,evidence)}));
  return {...s,candidate,payload,evidence,manifest,observed,proof,remoteGate:mode=>mode==="candidate"?proof:{observed:true,verified:true,sha:base,candidate:{...proof,sha:base,eventHeadSha:base}},readPullRequest:()=>({headRefOid:payload,state:"OPEN",baseRefName:"main",mergedAt:null})};
}
test("finite tracer: P to evidence commit E closes cleanly and repeated read-only checks are stable",t=>{
  const s=finalFixture(t);
  assert.notEqual(s.payload,s.evidence,"committing the tracked observation changes HEAD and would stale the old protocol");
  const before=checker.observe(s.root);
  const options={remoteGate:s.remoteGate,readPullRequest:s.readPullRequest};
  const first=invoke(s,"final",options);
  assert.equal(first.status,0,JSON.stringify(first));
  assert.equal(first.result.facts.tested_payload_sha,s.payload);
  assert.equal(first.result.facts.evidence_sha,s.evidence);
  const receipt=JSON.parse(fs.readFileSync(path.join(s.vault,"receipts/original.json")));
  for(const tree of receipt.observed.trees){ const {id,path:sourcePath,branch,lock,...expected}=tree; const actual=checker.observeTree(path.join(s.vault,receipt.restored.find(r=>r.tree_id===id).path)); assert.deepEqual(actual,expected); }
  assert.deepEqual(invoke(s,"final",options),first);
  assert.deepEqual(checker.observe(s.root),before);
});

test("finite closure rejects changed code, forged evidence tails and executable evidence files",t=>{
  const s=finalFixture(t),options={remoteGate:s.remoteGate,readPullRequest:s.readPullRequest};
  fs.writeFileSync(path.join(s.root,"runtime.cjs"),"module.exports = false;\n");git(s.root,["add","runtime.cjs"]);git(s.root,["commit","-m","changed runtime after proof"]);
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_UNALLOWLISTED_TAIL");
  s.manifest.lineage.evidence_paths.push("runtime.cjs");fs.writeFileSync(s.manifestPath,JSON.stringify(s.manifest));
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_INVALID_LINEAGE");
});
test("candidate identity, review manifest, exact proof and final live conditions fail closed",t=>{
  const s=finalFixture(t), original=JSON.stringify(s.manifest),options={remoteGate:s.remoteGate,readPullRequest:s.readPullRequest};
  for(const [name,mutate,code,overrides] of [
    ["diff omission",m=>m.candidate.changes.pop(),"CLOSEOUT_CANDIDATE_DIFF_MISMATCH"],
    ["unreviewed adoption",m=>m.groups.push({id:"new",disposition:"adopt",paths:["mixed.txt"]}),"CLOSEOUT_ADOPTION_UNREVIEWED"],
    ["unresolved owner",m=>m.groups.push({id:"unknown",disposition:"needs-owner",paths:["mixed.txt"]}),"CLOSEOUT_UNRESOLVED_DISPOSITION"],
    ["wrong artifact",m=>m.candidate.proof_identity.artifact_id++,"CLOSEOUT_PROOF_MISMATCH"],
    ["wrong run",m=>m.candidate.proof_identity.run_id++,"CLOSEOUT_PROOF_MISMATCH"],
    ["wrong attempt",m=>m.candidate.proof_identity.attempt++,"CLOSEOUT_PROOF_MISMATCH"],
    ["wrong merge checkout",m=>m.candidate.proof_identity.tested_sha="f".repeat(40),"CLOSEOUT_PROOF_MISMATCH"],
    ["wrong snapshot",m=>m.lineage.source_snapshot.head_sha="f".repeat(40),"CLOSEOUT_SNAPSHOT_LINEAGE_MISMATCH"],
    ["open blocker",m=>m.open_blockers.push("owner decision"),"CLOSEOUT_OPEN_BLOCKERS"],
    ["moved PR",()=>{},"CLOSEOUT_PR_MISMATCH",{readPullRequest:()=>({...s.readPullRequest(),headRefOid:"f".repeat(40)})}],
    ["failed current main",()=>{},"CLOSEOUT_MAIN_PROOF_MISMATCH",{remoteGate:mode=>mode==="candidate"?s.proof:{observed:true,verified:false}}],
  ]) {
    const manifest=JSON.parse(original);mutate(manifest);fs.writeFileSync(s.manifestPath,JSON.stringify(manifest));
    const out=invoke(s,"final",{...options,...overrides});assert.equal(out.status,2,name);assert.equal(out.result.diagnostics[0].code,code,name);
  }
  fs.writeFileSync(s.manifestPath,original);
  fs.writeFileSync(path.join(s.candidate,"new.txt"),"candidate drift");
  assert.equal(invoke(s,"candidate",options).result.diagnostics[0].code,"CLOSEOUT_CANDIDATE_MISMATCH");fs.unlinkSync(path.join(s.candidate,"new.txt"));
  fs.writeFileSync(path.join(s.linked,"dirty.txt"),"concurrent work");
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_WORKTREE_NOT_CLEAN");fs.unlinkSync(path.join(s.linked,"dirty.txt"));
  git(s.root,["worktree","lock","--reason","active owner",s.linked]);
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_WORKTREE_NOT_CLEAN");git(s.root,["worktree","unlock",s.linked]);
  const review=path.join(s.vault,"evidence-tail.json"), before=fs.readFileSync(review);fs.writeFileSync(review,JSON.stringify({schema_version:1,payload_sha:s.payload,evidence_sha:s.evidence,changes:[]}));
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_TAIL_REVIEW_MISMATCH");fs.writeFileSync(review,before);
  fs.chmodSync(path.join(s.root,".planning/v2.2-HANDOFF.md"),0o755);git(s.root,["add",".planning/v2.2-HANDOFF.md"]);git(s.root,["commit","-m","executable evidence"]);
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_UNALLOWLISTED_TAIL");
});
test("missing source trees and racing final observations reject closeout",t=>{
  const s=finalFixture(t),options={remoteGate:s.remoteGate,readPullRequest:s.readPullRequest};
  assert.equal(invoke(s,"final",{...options,afterFinalRead(){fs.writeFileSync(path.join(s.root,"late.txt"),"racing write");}}).result.diagnostics[0].code,"CLOSEOUT_SOURCE_DRIFT");
  fs.unlinkSync(path.join(s.root,"late.txt"));git(s.root,["worktree","remove",s.linked]);
  assert.equal(invoke(s,"final",options).result.diagnostics[0].code,"CLOSEOUT_TREE_CENSUS_MISMATCH");
});


test("invalid UTF-8 paths and indirect escaping symlinks cannot be preserved as another path", t => {
  const s=fixture(t);
  const {spawnSync}=require("node:child_process");
  assert.throws(()=>checker.observe(s.root,{runner(command,args,options){
    const r=spawnSync(command,args,options);
    if(args[0]==="ls-files" && args.includes("--stage"))r.stdout=Buffer.concat([r.stdout,Buffer.from("100644 " + "a".repeat(40) + " 0\t"),Buffer.from([255,0])]);
    return r;
  }}),/CLOSEOUT_UNSUPPORTED_PATH_ENCODING/);
  const outside=path.join(s.container,"outside");fs.mkdirSync(outside);fs.writeFileSync(path.join(outside,"secret"),"private");
  fs.writeFileSync(path.join(s.root,".gitignore"),"ignored-link\n");
  fs.symlinkSync(outside,path.join(s.root,"ignored-link"));
  fs.unlinkSync(path.join(s.root,"link"));fs.symlinkSync("ignored-link/secret",path.join(s.root,"link"));
  assert.throws(()=>checker.observe(s.root),/CLOSEOUT_SYMLINK_ESCAPE/);
});
