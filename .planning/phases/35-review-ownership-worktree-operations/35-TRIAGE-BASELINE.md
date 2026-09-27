# Phase 35 Live Triage Baseline

- **Repository:** `szTheory/oarlock`
- **Initial collection:** 2026-09-26 13:21:42 UTC; complete, 0 open issues and 1 open pull request.
- **Initial gap:** PR #4 lacked a verified maintainer record and its required disposition fields; no issue or PR prose was copied here.
- **Read-only access evidence:** Repository identity was verified. The authenticated executor and the disposition author, `szTheory`, both had verified `admin` permission.
- **Comment permission evidence:** The candidate maintainer comment author was checked through GitHub's collaborator permission endpoint and returned `admin`.
- **Collector:** `node scripts/triage_audit.cjs --inventory-only --json` completed the initial inventory with `collection.complete: true`.

## Maintainer disposition and merge

- **Disposition:** Added the dated `oarlock-triage` record to [PR #4](https://github.com/szTheory/oarlock/pull/4#issuecomment-5846805309) at 2026-09-26 13:51:40 UTC. It records `State: ready`, `Owner: szTheory`, `Scope: in-scope`, the next action to merge the release PR and observe the exact-SHA release/Hex evidence gates, `Action owner: szTheory`, and review date 2026-09-26.
- **Merge:** PR #4 was merged through the standard merge path, without bypass, at 2026-09-26 13:51:57 UTC. Merge commit: `9eb5c14aa5cc362ac9262fea1044975a9505cebf`.

## Final inventory and release evidence

- **Final collection:** 2026-09-26 13:53:51 UTC; full `node scripts/triage_audit.cjs --json` exited 0 with `collection.complete: true`, 0 open issues, 0 open pull requests, 0 gaps, and conclusion `complete`.
- **Release workflow:** [Release Please run 36246581839](https://github.com/szTheory/oarlock/actions/runs/36246581839), exact merge SHA `9eb5c14aa5cc362ac9262fea1044975a9505cebf`, completed successfully. It had two successful jobs: Release Please and Publish to Hex.pm. The publish job ran tests, dry-run publication, publication, and a version-on-Hex readback. The exact workflow at the merged SHA did not contain the candidate-byte verification, clean-consumer, or release-evidence attachment job. The run has no workflow artifacts.
- **Post-merge CI:** [CI run 36246581860](https://github.com/szTheory/oarlock/actions/runs/36246581860), exact merge SHA `9eb5c14aa5cc362ac9262fea1044975a9505cebf`, completed successfully with all 8 jobs. Retained artifact [ci-proof-36246581860-1](https://github.com/szTheory/oarlock/actions/runs/36246581860) (artifact ID `10907875988`, digest `sha256:525df8d69a4438e3e85659d26d4bb0faab6030474d4449dbd359f7935f05d27e`) downloaded successfully and states `verified: true` for the exact merge SHA, run `36246581860`, attempt 1.
- **Hex readback:** Release `v0.1.2` points to the merge commit. Hex API metadata and the independently fetched served tarball agree on SHA-256 `14364b4d0d9607346e89d3be7d0512b80df41449958587bc1d6a6c4a52240fda`. A fresh consumer compiled the served package with `--warnings-as-errors` using `bash bin/package_smoke.sh --published 0.1.2`.
- **Remaining release evidence gap:** Rebuilding from the exact tagged source with Hex 2.5.1 produced SHA-256 `395c91908d1fc25782873c7119f7ec4329728e604499c5dd6067b5303b4e4731`, which does not match the published tarball. Unpacked package files compare equal, but `metadata.config` file-list ordering differs. The successful historical publish workflow did not retain a candidate artifact or attach `release-evidence.json`; the GitHub Release has no assets. Therefore exact candidate-to-published-byte identity and durable release evidence remain unproven. Phase 34's live-byte/consumer evidence must remain open; publication success is not represented as exact-byte proof.

## Final triage readback — 2026-09-27

- **Collection:** The authenticated, paginated `node scripts/triage_audit.cjs --json` readback returned complete collection, 0 issues, 10 open PRs, 0 disposition gaps, and conclusion `complete`.
- **Author:** Every record was posted by `szTheory`, whose current repository permission was read as admin.
- **Decision shape:** Each PR records `Owner: unknown` pending selection, `Scope: in-scope`, `Action owner: szTheory`, and review date `2026-10-04`. No assignee or label was changed.
- **Blocked until proof:** PR #9 is blocked pending Release Please candidate/version and exact-release-gate review. PR #15 is blocked pending a passing planning-truth/CI-contract run and setup-node compatibility review.
- **Awaiting maintainer review:** PRs #10–14 and #16–17 are `needs-triage`, with next actions tailored to each dependency group.
- **Phase 36 candidate:** PR #21 is `needs-triage`; its next step is to review the closeout evidence update, require planning-truth and exact-SHA proof, then make a separate merge decision.
- **Comment links:** [#9](https://github.com/szTheory/oarlock/pull/9#issuecomment-5856332957), [#10](https://github.com/szTheory/oarlock/pull/10#issuecomment-5856333035), [#11](https://github.com/szTheory/oarlock/pull/11#issuecomment-5856333141), [#12](https://github.com/szTheory/oarlock/pull/12#issuecomment-5856333227), [#13](https://github.com/szTheory/oarlock/pull/13#issuecomment-5856333303), [#14](https://github.com/szTheory/oarlock/pull/14#issuecomment-5856333386), [#15](https://github.com/szTheory/oarlock/pull/15#issuecomment-5856333492), [#16](https://github.com/szTheory/oarlock/pull/16#issuecomment-5856333609), [#17](https://github.com/szTheory/oarlock/pull/17#issuecomment-5856333738), [#21](https://github.com/szTheory/oarlock/pull/21#issuecomment-5856333827).

