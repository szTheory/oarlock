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
