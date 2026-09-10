"use strict";

const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");

const PROJECT_ROOT = path.resolve(__dirname, "../..");
const DEFAULT_SUBJECT = "scripts/lib/repository_truth.cjs";

function subject() {
  const requested = process.env.GSD_PROHIB_SUBJECT || DEFAULT_SUBJECT;
  return require(path.isAbsolute(requested) ? requested : path.resolve(PROJECT_ROOT, requested));
}

function baseline() {
  const roadmap = `# Roadmap

## Milestones

- ✅ **v1.5 Demo App** — Phases 20-24 (shipped 2026-06-11) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.2 Production Surface** — Phases 8-13 (shipped 2026-06-09) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; phase artifacts retained)
`;
  const milestones = `# Milestones Log

## v1.5 Demo App (Shipped: 2026-06-11)

**Status:** ✅ Shipped
**Phases:** 20-24

### Release Identity

- **Planning milestone:** \`v1.5\`
- **Git tag:** Unknown — no local ref exists.
- **Source SHA:** Unknown — no local tag target is available.
- **Declared Hex package version:** Unknown — no tagged mix.exs is available.
- **Publication status:** Unknown — explicit missing-tag caveat.

### Archive

- Roadmap: \`.planning/milestones/v1.5-ROADMAP.md\`
- Requirements: \`.planning/milestones/v1.5-REQUIREMENTS.md\`

## v1.2 Production Surface (Shipped: 2026-06-09)

**Status:** ✅ Shipped
**Phases:** 8-13

### Release Identity

- **Planning milestone:** \`v1.2\`
- **Git tag:** \`v1.2\`
- **Source SHA:** \`source-abc\`
- **Declared Hex package version:** \`0.1.1\`
- **Publication status:** Unknown — no independent registry evidence is recorded.

### Archive

- Roadmap: \`.planning/milestones/v1.2-ROADMAP.md\`
- Requirements: \`.planning/milestones/v1.2-REQUIREMENTS.md\`

## v1.0 MVP — pre-archival

**Status:** ✅ Shipped (not formally archived)
**Phases:** 1-5

### Release Identity

- **Planning milestone:** \`v1.0\`
- **Git tag:** Unknown — explicit pre-archive exception.
- **Source SHA:** Unknown — explicit pre-archive exception.
- **Declared Hex package version:** Unknown — explicit pre-archive exception.
- **Publication status:** Unknown — explicit pre-archive exception.
`;
  return {
    root: "/fixture",
    documents: {
      ".planning/ROADMAP.md": { content: roadmap },
      ".planning/MILESTONES.md": { content: milestones },
      ".planning/EVIDENCE.md": { content: "# Evidence\n" },
    },
    milestoneArchives: {
      ".planning/milestones/v1.5-ROADMAP.md": "# v1.5 roadmap\n",
      ".planning/milestones/v1.5-REQUIREMENTS.md": "# v1.5 requirements\n",
      ".planning/milestones/v1.2-ROADMAP.md": "# v1.2 roadmap\n",
      ".planning/milestones/v1.2-REQUIREMENTS.md": "# v1.2 requirements\n",
    },
    tagIdentities: [{
      tag: "v1.2",
      sourceSha: "source-abc",
      declaredPackageVersion: "0.1.1",
      publicationStatus: "unknown",
    }],
    collectionErrors: [],
  };
}

function mutateMilestones(snapshot, from, to) {
  snapshot.documents[".planning/MILESTONES.md"].content = snapshot.documents[".planning/MILESTONES.md"].content.replace(from, to);
  return snapshot;
}

const cases = [
  {
    name: "planning milestone mismatch fails while tag, SHA, package, and publication stay valid",
    code: "PIDENT_PLANNING_MILESTONE_MISMATCH",
    field: "v1.2.planningMilestone",
    mutate: (snapshot) => mutateMilestones(snapshot, "Planning milestone:** `v1.2`", "Planning milestone:** `v9.9`"),
  },
  {
    name: "tag-only failure is not concealed by a valid peeled source SHA",
    code: "PIDENT_TAG_MISMATCH",
    field: "v1.2.gitTag",
    mutate: (snapshot) => mutateMilestones(snapshot, "Git tag:** `v1.2`", "Git tag:** `v9.9`"),
  },
  {
    name: "peeled-SHA-only failure is not concealed by a valid tag",
    code: "PIDENT_SOURCE_SHA_MISMATCH",
    field: "v1.2.sourceSha",
    mutate: (snapshot) => mutateMilestones(snapshot, "Source SHA:** `source-abc`", "Source SHA:** `source-wrong`"),
  },
  {
    name: "tagged package mismatch cannot be derived from milestone or tag text",
    code: "PIDENT_PACKAGE_VERSION_MISMATCH",
    field: "v1.2.declaredPackageVersion",
    mutate: (snapshot) => mutateMilestones(snapshot, "Declared Hex package version:** `0.1.1`", "Declared Hex package version:** `1.2.0`"),
  },
  {
    name: "publication claim fails without independent registry evidence",
    code: "PIDENT_PUBLICATION_OVERCLAIM",
    field: "v1.2.publicationStatus",
    mutate: (snapshot) => mutateMilestones(snapshot, "Publication status:** Unknown — no independent registry evidence is recorded.", "Publication status:** Published to Hex."),
  },
];

for (const identityCase of cases) {
  test(`PROHIB-REPO-03-IDENTITY: ${identityCase.name}`, () => {
    const implementation = subject();
    assert.equal(typeof implementation.validateMilestoneHistory, "function", "subject must export validateMilestoneHistory(snapshot)");
    const snapshot = identityCase.mutate(baseline());
    const diagnostics = implementation.validateMilestoneHistory(snapshot);
    const diagnostic = diagnostics.find(({ code, field }) => code === identityCase.code && field === identityCase.field);
    assert.ok(diagnostic, `${identityCase.code} must identify the independently mutated field`);
    assert.equal(diagnostic.severity, "error");
  });
}

test("milestone identity caveats retain v1.5 missing-tag and v1.0 pre-archive exceptions", () => {
  const diagnostics = subject().validateMilestoneHistory(baseline());
  assert.ok(diagnostics.some(({ code, field }) => code === "PIDENT_TAG_UNKNOWN" && field === "v1.5.gitTag"));
  assert.ok(diagnostics.some(({ code, field }) => code === "PHIST_PREARCHIVE_EXCEPTION" && field === "v1.0"));
  assert.equal(diagnostics.some(({ severity }) => severity === "error"), false);
});
