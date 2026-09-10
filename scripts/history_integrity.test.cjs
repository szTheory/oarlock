"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { inspectHistory } = require("./history_integrity.cjs");
const test = require("node:test");

const PROJECT_ROOT = path.resolve(__dirname, "..");
const SUBJECT = path.join(PROJECT_ROOT, "scripts/history_integrity.cjs");
const MUTATION_SUBJECT = process.env.GSD_PROHIB_SUBJECT || null;

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: "History Integrity",
      GIT_AUTHOR_EMAIL: "history-integrity@example.test",
      GIT_COMMITTER_NAME: "History Integrity",
      GIT_COMMITTER_EMAIL: "history-integrity@example.test",
      GIT_OPTIONAL_LOCKS: "0",
    },
    maxBuffer: 4 * 1024 * 1024,
  });
  if (!options.allowFailure && result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed (${result.status}): ${result.stderr}`);
  }
  return result;
}

function write(root, relative, content) {
  const target = path.join(root, relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
}

function repository(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-history-integrity-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  run("git", ["init", "-b", "main", root]);
  write(root, ".planning/milestones/v1.2-ROADMAP.md", "# Milestone v1.2\n\nFrozen roadmap.\n");
  write(root, ".planning/milestones/v1.2-REQUIREMENTS.md", "# Requirements v1.2\n\nFrozen requirements.\n");
  write(root, ".planning/EVIDENCE.md", "# Evidence\n\n| Date | Milestone | Corrected current record | Preserved source artifact | Evidence Class | Evidence | Caveat |\n|------|-----------|--------------------------|---------------------------|----------------|----------|--------|\n| 2026-09-09 | v1.2 | Added navigation | `.planning/milestones/v1.2-ROADMAP.md` | Additive navigation correction | Frozen roadmap records the shipped range | Historical wording remains unchanged |\n");
  run("git", ["add", ".planning"], { cwd: root });
  run("git", ["commit", "-m", "base history"], { cwd: root });
  return { root, base: run("git", ["rev-parse", "HEAD"], { cwd: root }).stdout.trim() };
}

function commit(root, message = "candidate history") {
  run("git", ["add", "-A"], { cwd: root });
  run("git", ["commit", "-m", message], { cwd: root });
  return run("git", ["rev-parse", "HEAD"], { cwd: root }).stdout.trim();
}

function guard(root, base, head, extra = []) {
  return run(process.execPath, [SUBJECT, "--base", base, "--head", head, ...extra], { cwd: root, allowFailure: true });
}

function mutate(root, mutation) {
  if (mutation.operation === "rewrite-archive") write(root, mutation.path, mutation.content);
  else if (mutation.operation === "additive-history") {
    write(root, mutation.archivePath, mutation.archiveContent);
    fs.appendFileSync(path.join(root, ".planning/EVIDENCE.md"), `${mutation.correction}\n`);
  } else throw new Error(`unsupported mutation operation: ${mutation.operation}`);
}

if (MUTATION_SUBJECT) {
  test("PROHIB-REPO-03-PRESERVATION: candidate history preserves frozen archives and appends corrections", (t) => {
    const mutation = JSON.parse(fs.readFileSync(path.resolve(PROJECT_ROOT, MUTATION_SUBJECT), "utf8"));
    const { root, base } = repository(t);
    mutate(root, mutation);
    const head = commit(root, mutation.name);
    const result = guard(root, base, head, ["--json"]);
    assert.equal(result.status, 0, `${mutation.name} violated history integrity:\n${result.stdout}${result.stderr}`);
    assert.equal(JSON.parse(result.stdout).status, "healthy");
  });
} else {
  test("frozen archives: editing, deleting, renaming, and replacing base paths fail from committed head", async (t) => {
    const operations = [
      ["editing", (root) => fs.appendFileSync(path.join(root, ".planning/milestones/v1.2-ROADMAP.md"), "changed\n")],
      ["deleting", (root) => fs.rmSync(path.join(root, ".planning/milestones/v1.2-ROADMAP.md"))],
      ["renaming", (root) => fs.renameSync(path.join(root, ".planning/milestones/v1.2-ROADMAP.md"), path.join(root, ".planning/milestones/v1.2-ROADMAP-renamed.md"))],
      ["replacing", (root) => write(root, ".planning/milestones/v1.2-ROADMAP.md", "replacement bytes\n")],
    ];
    for (const [name, operation] of operations) {
      await t.test(name, (subtest) => {
        const { root, base } = repository(subtest);
        operation(root);
        const head = commit(root, name);
        const result = guard(root, base, head, ["--json"]);
        assert.equal(result.status, 1, result.stderr);
        assert.match(result.stdout, /HIST_FROZEN_ARCHIVE_CHANGED/);
        assert.equal(run("git", ["status", "--porcelain"], { cwd: root }).stdout, "");
      });
    }
  });

  test("frozen archives: a snapshot absent at base is an allowed additive path", (t) => {
    const { root, base } = repository(t);
    write(root, ".planning/milestones/v2.2-ROADMAP.md", "# Milestone v2.2\n");
    const head = commit(root);
    assert.equal(guard(root, base, head).status, 0);
  });

  test("correction ledger: prior-row modification and removal fail", async (t) => {
    for (const [name, mutateLedger] of [
      ["modification", (content) => content.replace("Added navigation", "Replaced navigation")],
      ["removal", (content) => content.split("\n").filter((line) => !line.includes("2026-09-09")).join("\n")],
    ]) {
      await t.test(name, (subtest) => {
        const { root, base } = repository(subtest);
        const ledger = path.join(root, ".planning/EVIDENCE.md");
        fs.writeFileSync(ledger, mutateLedger(fs.readFileSync(ledger, "utf8")));
        const head = commit(root, name);
        const result = guard(root, base, head, ["--json"]);
        assert.equal(result.status, 1);
        assert.match(result.stdout, /HIST_EVIDENCE_NOT_APPEND_ONLY/);
      });
    }
  });

  test("correction ledger: valid rows inserted before or between existing bytes fail", async (t) => {
    const correction = "| 2026-09-10 | v1.4 | Added archive link | `.planning/milestones/v1.4-ROADMAP.md` | Additive navigation correction | Frozen roadmap records shipped work | Publication remains unknown |";
    for (const [name, insert] of [
      ["before", (content) => `${correction}\n${content}`],
      ["between", (content) => content.replace("| 2026-09-09", `${correction}\n| 2026-09-09`)],
    ]) {
      await t.test(name, (subtest) => {
        const { root, base } = repository(subtest);
        const ledger = path.join(root, ".planning/EVIDENCE.md");
        fs.writeFileSync(ledger, insert(fs.readFileSync(ledger, "utf8")));
        const head = commit(root, `insert ${name}`);
        const result = guard(root, base, head, ["--json"]);
        assert.equal(result.status, 1);
        assert.match(result.stdout, /HIST_EVIDENCE_NOT_APPEND_ONLY/);
      });
    }
  });

  test("correction ledger: a structurally valid dated correction row is allowed", (t) => {
    const { root, base } = repository(t);
    fs.appendFileSync(path.join(root, ".planning/EVIDENCE.md"), "| 2026-09-10 | v1.4 | Added archive link | `.planning/milestones/v1.4-ROADMAP.md` | Additive navigation correction | Frozen roadmap records shipped work | Publication remains unknown |\n");
    const head = commit(root);
    assert.equal(guard(root, base, head).status, 0);
  });

  test("revision evidence: missing base, missing head, and shallow repositories fail closed", async (t) => {
    const { root, base } = repository(t);
    write(root, "candidate.txt", "candidate\n");
    const head = commit(root);
    assert.equal(guard(root, "missing-base", head).status, 2);
    assert.equal(guard(root, base, "missing-head").status, 2);

    const shallow = fs.mkdtempSync(path.join(os.tmpdir(), "oarlock-history-shallow-"));
    t.after(() => fs.rmSync(shallow, { recursive: true, force: true }));
    run("git", ["clone", "--depth", "1", `file://${root}`, shallow]);
    const shallowHead = run("git", ["rev-parse", "HEAD"], { cwd: shallow }).stdout.trim();
    assert.equal(guard(shallow, shallowHead, shallowHead).status, 2);
  });

  test("evidence observation: base, head, and both-side read errors fail closed", async (t) => {
    for (const failingSides of [["base"], ["head"], ["base", "head"]]) {
      await t.test(failingSides.join(" and "), (subtest) => {
        const { root, base } = repository(subtest);
        fs.appendFileSync(path.join(root, ".planning/EVIDENCE.md"), "| 2026-09-10 | v1.4 | Added archive link | `.planning/milestones/v1.4-ROADMAP.md` | Additive navigation correction | Frozen roadmap records shipped work | Publication remains unknown |\n");
        const head = commit(root);
        const revisions = { base, head };
        const runner = (command, args, options) => {
          const side = Object.entries(revisions).find(([, revision]) => args[1] === `${revision}:.planning/EVIDENCE.md`)?.[0];
          if (args[0] === "show" && failingSides.includes(side)) {
            return { status: 1, stdout: Buffer.alloc(0), stderr: Buffer.from(`${side} evidence read failed`) };
          }
          return spawnSync(command, args, options);
        };
        const result = inspectHistory(base, head, { cwd: root, runner });
        assert.equal(result.status, "incomplete");
        assert.match(result.error, /evidence read failed/);
      });
    }
  });
}
