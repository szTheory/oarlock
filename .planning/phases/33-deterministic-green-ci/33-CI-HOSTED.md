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

The latest remote candidate run is not green. The current remote `main` remains
`fb3d9a185f104194e85987541519a6168e0b568c`; its latest June CI failed, and
`CI contract` is not an effective required branch check. No branch-rule change
or merge has been made. Wait for the next candidate run after the missing Phase
33 artifacts are published; only a successful complete run is eligible for
baseline timing and exact-SHA acceptance.
