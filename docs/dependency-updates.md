# Dependency updates

Dependabot opens proposals; it does not merge them. Root SDK, Phoenix/Ecto demo, and GitHub Actions updates use separate streams so each change stays tied to the lockfile or workflow boundary it affects. Compatible patch and minor releases are grouped only inside their own Mix project. Major releases and Actions changes remain individually reviewable. Security groups apply only to security updates; security majors stay separate. There is no auto-merge path.

## Review a proposal

1. Confirm the proposal's directory and changed files. Root Mix updates belong to `mix.lock`; demo updates belong to `demo/mix.lock`. If a proposal crosses those boundaries unexpectedly, split or reject it before review.
2. Read the full diff and release/advisory notes for the proposed packages. For a grouped update, inspect each dependency and its lockfile change separately. Treat major changes as compatibility work, even when the provider labels one as a security fix.
3. Open the hosted CI run for the pull request and confirm it tested the exact candidate SHA currently proposed. The `CI contract` job must pass and its retained exact-SHA proof must identify the same repository, PR head, run attempt, and checked-out SHA. A green run for an earlier commit or a different SHA is not evidence for the current proposal.
4. Check the jobs relevant to changed files: root SDK tests/compile and Dialyzer, optional dependency coverage, fresh package smoke, demo/PostgreSQL tests for demo changes, and quality checks including `mix hex.audit`. The aggregate contract requires all listed jobs; do not infer success from a partial job list or a skipped check.
5. For Hex changes, review the audit output and applicable advisory details. Do not claim the audit passed unless `mix hex.audit` completed successfully for this candidate.
6. Record the candidate SHA, CI run URL and attempt, required job results, and the Hex audit result in the PR review. State only evidence actually observed. If the head changes, repeat the SHA and evidence review for the new candidate.

## Security update settings

Repository vulnerability alerts and Dependabot automated security fixes were enabled and read back as enabled on 2026-09-26. The settings request security proposals; they do not authorize merging or change the review requirements above. If the settings are later changed, verify their live repository readbacks before claiming that security proposals are enabled.
