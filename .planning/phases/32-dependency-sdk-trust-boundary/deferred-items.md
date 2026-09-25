# Phase 32 Deferred Items

## Open transition work

- Plans 32-07 and 32-10 own the nine remaining broad-suite failures observed after Plan 32-05: subscription and transaction mutation/idempotency expectations, subscription later-page retry fixtures, and compiled seam inventory/documentation assertions. Plan 32-05's required focused gate passes 44/44 and does not modify those out-of-scope modules or tests.
- Plan 32-10 owns the three `Paddle.SeamTest` transition failures observed after Plan 32-08: stale transaction `idempotency_key` use, stale `Paddle.Error` arity inventory, and the sealed-module list that must now admit the intentionally documented telemetry schema. Plan 32-08's focused telemetry gate passes 7/7 and leaves those explicit Plan 32-10 files unchanged.
