---
schema_version: 1
open_count: 0
waived_count: 0
fixed_count: 3
total_count: 3
last_updated: 2026-09-10T20:35:37.252Z
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
  }
]
````
