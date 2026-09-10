---
schema_version: 1
open_count: 0
waived_count: 0
fixed_count: 1
total_count: 1
last_updated: 2026-09-10T02:16:51.204Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 31 | deviation | .planning/STATE.md |  | Reconciled stale current-position fields after the state handler advanced from an obsolete plan count | fixed |  | 2026-09-10T02:16:37.193Z | 2026-09-10T02:16:51.204Z |

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
  }
]
````
