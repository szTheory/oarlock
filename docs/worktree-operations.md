# Isolated task worktree evidence

Use this flow only after a host has provisioned a dedicated linked Git worktree for one bounded task. The lifecycle command gathers evidence about that existing tree; it does not create or clean worktrees. A clean receipt is not permission to remove, unlock, reset, or prune anything.

## Task manifest

Create a schema-v1 JSON manifest for the task. `owner` is an explicit human or team identity, `worktree_path` is the absolute path to the linked tree, `branch` is its full local ref, and `base_sha` is the exact commit from which the task starts.

```json
{
  "schema_version": 1,
  "task_id": "issue-123",
  "owner": "maintainer@example.test",
  "worktree_path": "/absolute/path/to/task-worktree",
  "branch": "refs/heads/task/issue-123",
  "base_sha": "0123456789abcdef0123456789abcdef01234567"
}
```

The directory must already be registered by Git, must not be the primary shared checkout, and must match the manifest exactly. Entry also requires `HEAD == base_sha`, a clean status, and no worktree lock or prunable metadata. The operator identity passed on the command line must equal `owner`.

## Entry and exit receipts

Capture the JSON entry receipt outside the repository, then keep it with the task record. The command writes only to stdout; it does not create receipt files.

```sh
node scripts/worktree_lifecycle.cjs entry \
  --manifest /path/to/task-manifest.json \
  --owner maintainer@example.test --json > /path/to/task-entry.json
```

After making and committing the task change, run the relevant validation commands at the resulting commit. Record every command, its result, and the exact tested SHA in a schema-v1 validation file:

```json
{
  "schema_version": 1,
  "validations": [
    {
      "command": "mix test",
      "result": "pass",
      "sha": "89abcdef0123456789abcdef0123456789abcdef"
    }
  ]
}
```

Then capture the exit receipt with the intended next disposition:

```sh
node scripts/worktree_lifecycle.cjs exit \
  --manifest /path/to/task-manifest.json \
  --owner maintainer@example.test \
  --entry-receipt /path/to/task-entry.json \
  --validation /path/to/task-validation.json \
  --disposition merge-review --json > /path/to/task-exit.json
```

Exit requires the same task, owner, canonical path, branch, and base as the entry receipt; it also requires a clean current status and passing validation records whose SHA equals the observed exit `HEAD`. The receipt reports `base_sha...HEAD` diff statistics, validation evidence, and the proposed disposition as separate facts. `remove-review` means only “review whether removal is appropriate.” Cleanup remains a separate, explicit decision by the worktree owner after checking the current tree again. Never convert an exit receipt into an automatic `git worktree remove`, unlock, reset, or prune action.

Keep the task summary tied to the entry and exit receipt identities, the observed base and exit SHAs, validation commands/results, and the proposed disposition. If the CLI returns `blocked`, preserve the diagnostics and the tree; unknown, dirty, locked, stale, unreadable, duplicate, or mismatched evidence cannot support a clean claim.

## Host support and CI boundary

Before changing GSD's worktree-per-task preference, verify that the active GSD host can create the requested dedicated tree, pass the task manifest/owner to this lifecycle check, and preserve the entry and exit receipts in the task summary. If any part is unsupported or cannot be read back, keep the preference disabled and use the existing shared-checkout workflow without describing it as isolated. This repository's `.planning/config.json` currently keeps `workflow.use_worktrees` set to `false`.

A CI checkout proves only the exact SHA and files tested by that CI run. It does not prove a developer's local tree is clean, owned, unlocked, or safe to remove.

## Dated local observation

On 2026-09-26, a read-only observation confirmed `workflow.use_worktrees: false`. Git also reported a locked linked tree on `refs/heads/worktree-agent-ae2a0ae67dfb5008f` at `56296a20841fc22a3bc232923d0e4589cfd9c4cb`; its machine-local path and lock reason are transient and intentionally omitted here. No worktree state was changed. A lock is evidence to preserve and investigate, not authority to unlock or remove.

## Finite milestone closeout

`closeout_check.cjs` composes preservation, candidate review and final workstation
checks. It only reads sources and emits JSON; exit 0 means that stage passed and
exit 2 means incomplete, unsafe or mismatched evidence. There is no cleanup flag.
Unknown work can be preserved and investigated, but unresolved dispositions still
block final closeout. A passing candidate check cannot replace current-main proof.

Keep three identities separate:

- **S:** an immutable private snapshot of every registered source tree, including
  refs, original index, staged blobs, working files, deletions, modes and untracked
  files. Its receipt ID and observed source HEAD identify historical facts.
- **P:** the reviewed payload commit directly on the observed main base. The
  candidate clone stays clean at P, and the open PR and retained eight-lane CI
  artifact must identify P. CI's tested merge checkout is recorded separately.
- **E:** the final source checkout HEAD, descended from P through reviewed
  evidence-only commits. The checker resolves E from Git. A tracked handoff uses
  `handoff_document_sha: "git:HEAD"`; it never embeds its own future commit SHA.

Select a durable operator-controlled vault outside every checkout using
`OARLOCK_CLOSEOUT_VAULT`. Its directory must be private (mode 0700), and paths
beneath it must not escape through symlinks. Keep `locations.json` (the candidate
clone's absolute `candidate` path), copied payloads and all local receipts there;
never commit personal paths, raw patches or vault contents. The checked-in
schema-v1 closeout manifest contains receipt IDs, disposition groups, exact
candidate base/payload identities and reviewed Git diff records.

The explicit capture harness is shared with real temporary-repository tests. Run
it only after reviewing source and external destination paths, with a **new**
receipt ID for each observation. It bundles refs, copies all byte versions, restores
them independently, and rejects concurrent source changes. It never cleans a
source tree:

```sh
node - <<'JS'
const { capture } = require('./scripts/fixtures/closeout_snapshot.cjs');
const { observe } = require('./scripts/closeout_check.cjs');
capture(process.cwd(), process.env.OARLOCK_CLOSEOUT_VAULT,
  'operator-selected-new-receipt', observe);
JS

node scripts/closeout_check.cjs --stage preservation \
  --manifest .planning/phases/37-milestone-closeout-reconciliation/37-CLOSEOUT.json \
  --json > "$OARLOCK_CLOSEOUT_VAULT/preservation-check.json"
```

The preservation stage requires the source still match S. Candidate/final stages
retain S as historical preservation and independently revalidate its restored
bytes; they do not require today's checkout to remain dirty like S. Each original
dirty path must have an explicit disposition. Adopted paths require reviewed
candidate blob/mode identities, and every main-to-P diff row must match the
manifest exactly. External preservation is a retained destination, not permission
to discard unknown work.

```sh
node scripts/closeout_check.cjs --stage candidate \
  --manifest /path/to/reviewed-candidate-manifest.json --json \
  > "$OARLOCK_CLOSEOUT_VAULT/candidate-check.json"
```

After candidate proof, reconcile the source trees under the recorded authorization,
retaining their original history and snapshots. Write final summaries, validation
and phase verification before finalizing the tracked schema-v2 handoff. Only an
explicit subset of planning evidence paths may differ between P and E; executable,
configuration and test changes require a new payload and new hosted proof. The
checker also enforces frozen-history integrity.

Review the complete P-to-E diff, then retain `evidence-tail.json` **outside** Git
with `schema_version: 1`, `payload_sha`, `evidence_sha`, and the exact `changes`
returned by `diffIdentity(root, P, E)`. Each row includes path, old/new mode,
old/new blob ID and change status. This is the operator's review receipt, not an
automatic approval: a missing or different row, SHA, executable mode or path
outside the narrow evidence allowlist fails closed. No tracked file needs to
contain its own hash.

```sh
node scripts/closeout_check.cjs --stage final \
  --manifest .planning/phases/37-milestone-closeout-reconciliation/37-CLOSEOUT.json \
  --json > "$OARLOCK_CLOSEOUT_VAULT/final-check.json"
node scripts/jtbd_coverage.cjs --check-handoff --json \
  > "$OARLOCK_CLOSEOUT_VAULT/handoff-check.json"
```

Final checks require the complete original tree census, all trees clean and
unlocked, a valid S/P/E lineage, no open operational blockers, the live PR still
at P, and independently verified current main at the candidate base. Repeated
checks write no tracked files and leave the same evidence valid. A moved main,
changed candidate, changed source or later commit invalidates the relevant check;
resume that specific step instead of repeating completed UAT.

The existing required Node lane discovers `scripts/closeout_check.test.cjs` via
`scripts/*.test.cjs`. Its temporary-Git fixtures exercise restore and finalization
without network access or any dependency on the operator's workstation. The live
workstation and hosted checks above remain separate acceptance evidence.
