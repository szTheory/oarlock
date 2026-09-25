# Phase 33 Hosted CI Observation

Read-only observation recorded 2026-09-24. No remote refs, settings, or branch
rules were changed.

## Local candidate

- Candidate SHA: `63bb822b00b61cd17d6aabab3f92b82886d8f3c0`
- `CI` run: not observed (`no_ci_run_for_sha`)
- Matching proof artifact and timing: not observed
- Verdict: unobserved; no hosted candidate acceptance

## Current remote main

- Remote main SHA: `fb3d9a185f104194e85987541519a6168e0b568c`
- Effective branch rule observation: `CI contract` is not required
- Latest exact-SHA `CI` run found: [run 27216688735](https://github.com/szTheory/oarlock/actions/runs/27216688735), attempt 1
- Run created: `2026-06-09T15:23:34Z`; updated: `2026-06-09T15:26:33Z`
- Run conclusion: failure
- Proof artifact: unavailable (`no valid artifacts found to download`)
- Timing: not accepted as a full-contract baseline; required proof/artifact is absent and the run predates the Phase 33 contract
- Verdict: observed but not verified

The selected local-only path means the workflow, hosted branch protection, merge,
and current-main proof requirements remain pending. Re-run the read-only gate
after a Phase 32+ candidate exists on a safe remote ref:

```sh
node scripts/ci_remote_gate.cjs candidate --sha "$CI_CANDIDATE_SHA" --json
node scripts/ci_remote_gate.cjs main --json
```

## Draft PR #6 Candidate Attempts (2026-09-24)

These runs are observations of failed candidates, not accepted exact-SHA proof:

| SHA | Run | Result | Finding |
|-----|-----|--------|---------|
| `63bb822b00b61cd17d6aabab3f92b82886d8f3c0` | [36053856755](https://github.com/szTheory/oarlock/actions/runs/36053856755) | failure | Exposed historical tags missing remotely, an affected Mint lock, format/spec gaps, and the initial Rebar parser assumption. |
| `63c70c9a8483416cd8fa1fd877e08975c7b34e29` | [36055236124](https://github.com/szTheory/oarlock/actions/runs/36055236124) | failure | Main test, static analysis, quality, package, optional-dependency, and PostgreSQL jobs passed; history rejected the first evidence-ledger addition and the proof-tool Hex lookup failed. |
| `852d2e6fcb4f882b42b6c93f1df5f6878c924de0` | [36055916704](https://github.com/szTheory/oarlock/actions/runs/36055916704) | failure | Confirmed Hex 2.5.1 installs as a directory, not an `.ez`; the history gate still rejected the first ledger. |
| `79f880336036fcc378b4113b1595a3b3f032f6e9` | [36056214272](https://github.com/szTheory/oarlock/actions/runs/36056214272) | failure | History guard rejected `.planning/EVIDENCE.md` because the main-base tree predates its canonical creation; CI contract correctly reported `verified: false`. Other proof lanes passed. |
| `8ced58ed1ebb7ae989ab5305a4c33fa18de83362` | [36057918086](https://github.com/szTheory/oarlock/actions/runs/36057918086) | failure | History guard and Node/prohibition suites passed after the initial-ledger fix. Planning-health smoke found four Phase 33 plan files declared by `ROADMAP.md` but absent from the remote candidate. Those planning files and related automation artifacts are prepared locally for the next candidate update. |

## Successful Candidate Acceptance (2026-09-24)

- Candidate head: `4939bddaa78e3027a014d10137191fd1dcefb27b`
- Tested PR merge SHA: `500894b963dc223d4e93c2ff1895138be477f8be`
- Run: [36061010940, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36061010940), created `2026-09-24T21:22:02Z`, completed `2026-09-24T21:25:35Z`
- All eight required jobs passed: mix test, static analysis, demo PostgreSQL, package smoke, optional dependencies, planning truth, quality checks, CI contract.
- Proof artifact: `ci-proof-36061010940-1`, artifact ID `10834019628`, SHA-256 `sha256:c13dd149f9c4821ffa15a2dae41550585e4a313297c161688f611bf4326976f0`
- Exact-SHA acceptance CLI: `verified: true`; candidate event head matched, tested merge SHA matched the proof, and run/artifact identity matched.
- Timing: 210s critical path, 8.97 summed runner minutes; per-lane timings are in `33-CI-BASELINE.md`. The provisional target was not met.

## Current Main Gate (2026-09-24)

The read-only `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json`
query observed main SHA `fb3d9a185f104194e85987541519a6168e0b568c`, found that
`CI contract` is not required, and found the latest exact-SHA CI run failed
without a valid proof artifact. Verdict: `observed: true`, `verified: false`,
reason `CI_contract_not_required`. No branch rule or merge was changed.

## Follow-up Exact-SHA Runs

- `5f76e4b23bc74eefbd12e1184bcbbd6def1fc652`, run [36061934020](https://github.com/szTheory/oarlock/actions/runs/36061934020): seven jobs passed; planning truth failed because the 500ms timeout unit fixture exceeded its startup margin and returned invalid-usage status before the timeout assertion. The exact proof correctly rejected this candidate.
- Fixed the fixture margin from 0.5s/1.5s to 2s/3s and upgraded the pinned setup-node action to v6.5.0 for its Node 24 runtime. Focused local tests and actionlint passed.
- Candidate `e75a3b1fd8b9bb86b30602f4c36c97cb60b26d97`, run [36062578662](https://github.com/szTheory/oarlock/actions/runs/36062578662), attempt 1: all eight required jobs passed. Tested PR merge SHA `d55fb19dfc70896300a0668716e43c2a13a7b4fb`. Proof artifact `ci-proof-36062578662-1`, ID `10834714346`, digest `sha256:56c299864264ff3a97d1787dc97448a1e6bef6362a4bc6a519362534848eaee8`. Exact-SHA candidate gate returned `verified: true`.
- Latest timing: 198s critical path, 8.27 runner minutes. Logs showed root dependency, demo dependency, and Dialyzer PLT cache misses on this PR ref; the main-only cache writers have not run on main yet.
- The Plan 33-03 summary/roadmap candidate `4cb3a3b23d934fbc56dd370b50f6582337c2510c` also passed all eight jobs on [run 36063394878, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36063394878). Tested merge SHA: `cc45c52dd04d2167407349ca2d9d4fc30d92190a`; proof artifact `ci-proof-36063394878-1`, ID `10835970861`, digest `sha256:8318b093e5ed185dcbb4bfa6b5b4f11f0cffd0a1054408ef6754c5d95f11d763`; exact-SHA gate verified.
- This final recorded candidate measured 229s critical path and 9.05 runner minutes. Logs again confirmed root, demo, and PLT cache misses on the PR ref. The <120s/<6-minute targets remain unmet pending trusted-main cache population and a warm comparison.

## Final Candidate Acceptance (2026-09-25)

- Candidate head: `580c1c836232e712b31e49913c694af9e1ca123e`
- Tested PR merge SHA: `74ca59097ae258329e06a2481b2e359cf952b24e`
- Run: [36077014434, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36077014434), created `2026-09-25T00:19:35Z`, completed `2026-09-25T00:24:44Z`
- All eight required jobs passed. The exact-SHA gate verified the workflow/head/tested-SHA relationship and retained artifact.
- Proof artifact: `ci-proof-36077014434-1`, artifact ID `10839959367`, digest `sha256:1e9bfde9f0062dd9753b22d16982cb51d6f660301f03bf9985106547ecf84561`
- Timing: 213s critical path, 8.68 summed runner minutes; 95s queue, 308s aggregate elapsed. The provisional target remains unmet.

An earlier candidate attempt failed the history guard because the privacy cleanup
modified 15 frozen archived artifacts. Those files were restored byte-for-byte;
the final candidate passed the guard. Home-directory prefixes were normalized in
active planning documents only. Frozen archive blobs and prior public commits
still contain historical workstation paths; rewriting published history was not
part of the approved review fix.

## Effective Main Rule and Current-Main Acceptance (2026-09-25)

- PR #6 was reviewed against remote main and merged through GitHub's normal merge path: [PR #6](https://github.com/szTheory/oarlock/pull/6), merge commit `0db804c18eaea751d19e662d020f770d53cefc57`.
- Created active repository ruleset `Require CI contract on main`, ID `23970515`, targeting `refs/heads/main`. GitHub's effective-rule read returned required context `CI contract` from GitHub Actions integration `15368`. No prior ruleset or classic branch protection existed.
- Exact current main SHA: `0db804c18eaea751d19e662d020f770d53cefc57`.
- Main push run: [36077488230, attempt 1](https://github.com/szTheory/oarlock/actions/runs/36077488230), created `2026-09-25T00:25:46Z`, completed `2026-09-25T00:29:14Z`.
- All eight required jobs passed; the run, tested SHA, and event head SHA all match current main.
- Proof artifact: `ci-proof-36077488230-1`, artifact ID `10841045079`, digest `sha256:8ad67fd8a3669401ea2a32552aecc23ea37b5c5ecaa03f85abe574107c81b752`.
- Timing: 206s critical path, 8.87 summed runner minutes; 2s queue and 208s aggregate elapsed. The provisional target remains unmet.
- Final `node scripts/ci_remote_gate.cjs main --repo szTheory/oarlock --json` verdict: `observed: true`, `verified: true`; required rule and exact-SHA proof both verified.

The evidence above is the final main observation before phase-closeout documentation.
Any later commit to main requires another exact-SHA observation; the local Phase 33
summary is retained as the handoff record so it does not advance the verified head.
