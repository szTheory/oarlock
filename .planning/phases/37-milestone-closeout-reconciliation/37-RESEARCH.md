# Phase 37 — Implementation Research

Date: 2026-09-27. Method: local repository inspection; no new provider/API integration. Research and plan review are inline under the Codex skill adapter's spawn restriction.

## Findings

1. `repository_inventory.cjs` and `scripts/lib/repository_truth.cjs` already gather NUL-safe facts and separate ownership proposals. The ownership registry names only three historical paths. Reuse observations, then expand aggregated untracked directories for preservation; do not treat 116 status rows as 116 files.
2. `worktree_lifecycle.cjs` is report-only and requires a clean entry at its manifest base. It cannot retroactively certify this dirty root or the old locked tree. Keep that contract; create a separate reconciliation receipt for inherited work.
3. `jtbd_coverage.cjs:evaluateHandoff` compares recorded HEAD/dirty facts directly with live worktrees, insists on an open PR, and expects the candidate's immediate parent to equal `main_base_sha`. Writing a tracked observation and then committing it changes those facts. This needs a finite observation/evidence-commit protocol with integration tests, not more stale report refreshes.
4. `ci_remote_gate.cjs` already verifies the eight required lanes, run/attempt, artifact digest, event head and tested merge SHA. Its `candidate --sha` and `main` modes should remain proof authority. A local fixture tests orchestration; it cannot replace hosted evidence.
5. The existing required Node suite globs `scripts/*.test.cjs`; closeout regression tests fit there without a new job. Live local-tree inventory must stay outside hosted CI, whose checkout cannot prove this workstation's cleanliness.
6. There are mixed index/worktree versions in REQUIREMENTS/ROADMAP and several summary files. A blanket documentation commit would absorb earlier work. Preserve the index and review path/content deltas before adopting them. Phase 37 planning files are owned additions; their commit can be scoped separately from the inherited index.

## Recommended boundaries

- Preserve source data in a private local vault outside every Git checkout, with an explicit retained location and restore verification. Store only sanitized receipt metadata in versioned planning. No credentials, copied private content, absolute personal paths, raw patches or vault contents in public Git/CI artifacts.
- Inventory clean and dirty refs, tracked deletions, binary/mode changes, index content and untracked bytes. Hash and validate snapshots; detect concurrent changes and retry only affected entries. A bundle alone does not preserve index/untracked bytes.
- Reconciliation ledger states: `adopt`, `already-contained`, `preserve-external`, `needs-owner`. Each needs byte/object provenance and a specific disposition. A label alone never grants cleanup authority.
- Exact candidate proof precedes final cleanup. All later executable/config/test changes invalidate it; bounded evidence-only tails are explicit and checked against the tested Git object.
- Keep the last successful live closeout receipt outside the working tree so running verification does not dirty what it verifies. Durable tracked reports link the payload, evidence commit rules, and receipt identity; they do not chase self-referential commit hashes.

## Validation Architecture

Node's built-in test runner and temporary Git repositories cover preservation manifests, separate index/worktree bytes, linked-tree census, content drift, provenance, payload/document identities, and fail-closed behavior. A real temporary-repository tracer must complete capture → payload → evidence commit → clean read-only check. Negative cases: omitted tree/file, dirty/locked/unreadable tree, changed executable in document tail, wrong candidate/run/artifact, and concurrent mutation.

Live acceptance composes the existing inventory, hosted candidate/main gates, planning health, JTBD/handoff and history guards. Record exact commands, status, SHA and receipt digest; no manual UAT substitutes. External ownership decisions are operation authorization, not product verification.

## Reopen conditions

Revisit only if the refreshed repository/PR topology differs, retained source cannot be reconstructed, or a reliable clean-close protocol cannot be implemented without weakening existing invariants. A denied process read is an access problem to resolve narrowly, not evidence that the lock is stale.
