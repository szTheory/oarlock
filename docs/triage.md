# Issue and pull request triage

Every open issue and pull request needs a maintainer-authored, dated disposition. Issue form answers and labels help route intake, but they do not record a decision: both can change independently of the item.

## Record a decision

Add a comment to the issue or pull request with this exact fenced block. Use a GitHub login for `Owner` and `Action owner`, or write `unknown` for `Owner` when no owner has been selected. `Action owner` must name a maintainer responsible for the next step.

````text
```oarlock-triage
Date: YYYY-MM-DD
State: needs-triage|needs-info|ready|in-progress|blocked
Owner: USER|unknown
Scope: in-scope|deferred|out-of-scope
Next action: One concrete next step
Action owner: USER
Review by: YYYY-MM-DD
```
````

Replace the example alternatives with exactly one value. `Date` is the date the comment was posted. `Review by` cannot precede it. The comment author must currently have write or admin permission on the repository; the audit checks this against GitHub rather than trusting a username written in the block.

For `State: needs-info`, add a non-empty `Information needed: ...` line and set a review date so someone owns the follow-up. Add a new dated comment when the decision changes; do not edit old comments to erase the decision history. The most recent valid triage comment is current. A malformed newest record, a permission lookup failure, or incompatible records posted at the same time leaves the item incomplete for a maintainer to resolve.

## Labels

`kind:*` labels describe what an item is, such as a bug, proposal, or dependency update. `state:*` labels are workflow cues. They can drift and are not authoritative; the dated comment controls owner, scope, next action, and state for this audit. The audit reports labels as observed and never creates or changes them.

## Run the read-only audit

Provide `GH_TOKEN` or `GITHUB_TOKEN` with repository read access, then run:

```sh
GITHUB_REPOSITORY=OWNER/REPOSITORY node scripts/triage_audit.cjs
GITHUB_REPOSITORY=OWNER/REPOSITORY node scripts/triage_audit.cjs --json
```

The audit reads all open issues and pull requests, follows every GitHub `rel="next"` page for inventory, comments, and collaborator permissions, then reports disposition gaps. It does not assign, label, close, or comment on items. Exit code `0` means collection is complete and every open item has a valid disposition; `1` means collection is complete but one or more decisions need maintainer attention; `2` means inventory or permission evidence is incomplete. For a dated inventory baseline that should succeed despite disposition gaps, use `--inventory-only --json`; it exits `0` only when collection is complete.

Fixture tests run in CI:

```sh
node --test scripts/triage_audit.test.cjs
```

A fixture pass proves parser and pagination behavior against controlled responses. It is not proof that the live repository inventory or its dispositions are complete; run the read-only audit for that claim.
