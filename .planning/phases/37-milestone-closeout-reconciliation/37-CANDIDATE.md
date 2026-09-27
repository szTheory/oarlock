# Phase 37 Candidate

The reviewed payload is one commit directly on observed main `8905febdb55342aa07590bf6c108b079a1e12af0`. Its SHA and hosted proof will be recorded in the evidence-only tail after the run completes; this document never embeds its own commit SHA.

The candidate adopts outstanding Phase 31–36 runtime, CI and planning evidence plus Phase 37 preservation and finite handoff checks. It retains main's released package/version metadata, dependency locks, pagination typespecs and all frozen milestone archives. Original source/index versions remain independently restored in the private preservation vault and retained native branch.

The explicit path selection is retained privately. Public `37-CLOSEOUT.json` will bind every adopted group to exact candidate objects and the complete main-to-payload diff. No cache, local state mirror, lock, patch, bundle, copied private content or absolute operator path is included. Personal path references in active planning reports use portable aliases. The existing PR #21 and its `c5bcc7b` run remain historical; the required direct-parent topology calls for a new draft PR without rewriting that branch.

Local candidate verification before publication:

- `mix test`: 275 tests, 0 failures (includes seam coverage).
- Demo `mix test`: 25 tests, 0 failures, including PostgreSQL-backed flows.
- `bin/package_smoke.sh`: fresh downstream consumer compiled successfully from the local package.
- `mix format --check-formatted`: exit 0.
- Complete Node regression: 272 tests, 0 failures. Planning health: healthy, 0 errors and 3 historical warnings. JTBD coverage: healthy, 18 records. History guard is checked against the resulting commit before push.
- Privacy review: no personal absolute paths, private keys or credential-pattern matches in selected files.

The installed actionlint 1.7.12 reports only the two supported GitHub `queue: max` keys. The established narrow `-ignore 'unexpected key "queue"'` invocation passes; release contract tests still enforce queue serialization. GitHub's current concurrency documentation confirms the field: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency . No release workflow behavior was relaxed for the local linter.

Evidence reconciliation preserves main's EVIDENCE bytes and appends dated records. The stale historical release window is dispositioned using the already documented maintainer exception; v0.1.2's missing original release provenance remains explicit, and future release gates remain strict.

Publication, merge, release and milestone archival are outside this phase.
