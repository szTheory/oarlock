# Phase 37 — Existing Patterns

| Planned file | Existing analog | Reuse |
|---|---|---|
| `scripts/closeout_check.cjs` | `repository_inventory.cjs`, `worktree_lifecycle.cjs` | One result model, injected runners/streams, bounded reads, explicit incomplete status, report-only source operations. |
| `scripts/closeout_check.test.cjs` | `worktree_lifecycle.test.cjs`, `repository_inventory.test.cjs` | Real temporary Git repositories and linked worktrees; assert byte/ref/index preservation and negative outcomes. |
| `scripts/jtbd_coverage.cjs` | Existing `evaluateHandoff`, `observeCandidateCheckout` | Extend finite evidence identity handling, retaining live census and exact candidate checks. |
| `scripts/jtbd_coverage.test.cjs` | Handoff tests around lines 314–397 | Preserve existing dirty/lock/wrong-proof rejection; add evidence-commit integration fixture. |
| Closeout proof collection | `ci_remote_gate.cjs` | Call existing candidate/main gates; never duplicate or weaken eight-lane proof validation. |
| Versioned receipts/docs | Phase 35 worktree guide and Phase 36 handoff | Separate factual observations, ownership authority, proposed action, and accepted historical caveats. |

All new tests run through the existing `scripts/*.test.cjs` glob. No additional dependency or service is needed.
