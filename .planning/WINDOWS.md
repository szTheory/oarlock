---
schema_version: 1
open_count: 0
waived_count: 0
fixed_count: 11
total_count: 11
last_updated: 2026-09-11T01:37:55.720Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 31 | deviation | .planning/STATE.md |  | Reconciled stale current-position fields after the state handler advanced from an obsolete plan count | fixed |  | 2026-09-10T02:16:37.193Z | 2026-09-10T02:16:51.204Z |
| 2 | 32 | deviation | mix.lock |  | Refreshed Bandit from vulnerable 1.12.0 to patched 1.12.5 so the required root Hex audit is clean | fixed |  | 2026-09-10T20:33:36.195Z | 2026-09-10T20:33:39.298Z |
| 3 | 32 | deviation | .planning/STATE.md |  | Reconciled skipped progress output and duplicate phase prefixes after standard state handlers | fixed |  | 2026-09-10T20:35:37.138Z | 2026-09-10T20:35:37.252Z |
| 4 | 32 | deviation | .planning/STATE.md |  | Reconciled visible state after SDK handlers advanced authoritative counters | fixed |  | 2026-09-10T21:23:02.854Z | 2026-09-10T21:23:15.402Z |
| 5 | 32 | deviation | .planning/STATE.md |  | Reconciled human-readable progress and next-step fields after state.update-progress skipped the unscoped in-progress phase. | fixed |  | 2026-09-10T22:06:29.226Z | 2026-09-10T22:06:49.737Z |
| 6 | 32 | unmet-truth | test/paddle/seam_test.exs | 105 | Plan 32-10 owns three seam-contract transition failures left after Plan 32-08; focused telemetry and all non-seam runtime tests pass. | fixed |  | 2026-09-10T22:18:50.607Z | 2026-09-10T22:37:20.219Z |
| 7 | 32 | deviation | .planning/STATE.md |  | Reconciled Plan 32 visible state after dependency-ordered execution and skipped unscoped progress update. | fixed |  | 2026-09-10T22:19:28.718Z | 2026-09-10T22:19:46.062Z |
| 8 | 32 | deviation | test/paddle/seam_test.exs |  | Repaired inherited idempotency, module-doc visibility, and contextual Paddle.Error seam transitions | fixed |  | 2026-09-10T22:36:57.327Z | 2026-09-10T22:37:20.300Z |
| 9 | 32 | deviation | README.md |  | Extended all first-read proof boundaries to the full six-tier evidence ladder | fixed |  | 2026-09-10T22:36:57.409Z | 2026-09-10T22:37:20.379Z |
| 10 | 32 | deviation | .planning/STATE.md |  | Reconciled visible execution progress after the state handler advanced to already-completed Plan 11 | fixed |  | 2026-09-10T22:38:23.982Z | 2026-09-10T22:38:24.092Z |
| 11 | 32 | deviation | .planning/STATE.md |  | Reconciled stale visible state prose after the SDK last-plan transition | fixed |  | 2026-09-11T01:37:35.442Z | 2026-09-11T01:37:55.720Z |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "31",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled stale current-position fields after the state handler advanced from an obsolete plan count",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T02:16:37.193Z",
    "resolved_at": "2026-09-10T02:16:51.204Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "32",
    "file": "mix.lock",
    "line": null,
    "description": "Refreshed Bandit from vulnerable 1.12.0 to patched 1.12.5 so the required root Hex audit is clean",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T20:33:36.195Z",
    "resolved_at": "2026-09-10T20:33:39.298Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "32",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled skipped progress output and duplicate phase prefixes after standard state handlers",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T20:35:37.138Z",
    "resolved_at": "2026-09-10T20:35:37.252Z"
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "32",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled visible state after SDK handlers advanced authoritative counters",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T21:23:02.854Z",
    "resolved_at": "2026-09-10T21:23:15.402Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "32",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled human-readable progress and next-step fields after state.update-progress skipped the unscoped in-progress phase.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T22:06:29.226Z",
    "resolved_at": "2026-09-10T22:06:49.737Z"
  },
  {
    "id": 6,
    "kind": "unmet-truth",
    "phase": "32",
    "file": "test/paddle/seam_test.exs",
    "line": 105,
    "description": "Plan 32-10 owns three seam-contract transition failures left after Plan 32-08; focused telemetry and all non-seam runtime tests pass.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T22:18:50.607Z",
    "resolved_at": "2026-09-10T22:37:20.219Z"
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "32",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled Plan 32 visible state after dependency-ordered execution and skipped unscoped progress update.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T22:19:28.718Z",
    "resolved_at": "2026-09-10T22:19:46.062Z"
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "32",
    "file": "test/paddle/seam_test.exs",
    "line": null,
    "description": "Repaired inherited idempotency, module-doc visibility, and contextual Paddle.Error seam transitions",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T22:36:57.327Z",
    "resolved_at": "2026-09-10T22:37:20.300Z"
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "32",
    "file": "README.md",
    "line": null,
    "description": "Extended all first-read proof boundaries to the full six-tier evidence ladder",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T22:36:57.409Z",
    "resolved_at": "2026-09-10T22:37:20.379Z"
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "32",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled visible execution progress after the state handler advanced to already-completed Plan 11",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T22:38:23.982Z",
    "resolved_at": "2026-09-10T22:38:24.092Z"
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "32",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Reconciled stale visible state prose after the SDK last-plan transition",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T01:37:35.442Z",
    "resolved_at": "2026-09-11T01:37:55.720Z"
  }
]
````
