# Phase 32 External API/SDK Coverage

Phase 32 changes the trust contract around every existing outbound Paddle request path; it adds no Paddle endpoint or capability breadth. Full coverage therefore means that every tracked request-owning module adopts the same static operation/route context, safe-read retry policy, single-attempt mutation behavior, ambiguity result, and allowlisted telemetry boundary.

| capability | decision | reason |
|---|---|---|
| Adjustments — create/get/list/stream/all | INTEGRATE | Existing paths in `lib/paddle/adjustments.ex`; Plan 05. |
| Customers — create/get/update | INTEGRATE | Existing paths in `lib/paddle/customers.ex`; Plan 05. |
| Customer addresses — create/get/list/stream/all/update | INTEGRATE | Existing paths in `lib/paddle/customers/addresses.ex`; Plan 05. |
| Customer portal sessions — canonical and compatibility entry points | INTEGRATE | Existing `lib/paddle/customers/portal_sessions.ex` and `lib/paddle/portal_sessions.ex`; Plan 05. |
| Events — get/list/stream/all | INTEGRATE | Existing paths in `lib/paddle/events.ex`; Plan 06. |
| Notification settings — create/get/list/stream/all/update/delete | INTEGRATE | Existing paths in `lib/paddle/notification_settings.ex`; Plan 06. |
| Prices — get/list/stream/all | INTEGRATE | Existing paths in `lib/paddle/prices.ex`; Plan 06. |
| Products — get/list/stream/all | INTEGRATE | Existing paths in `lib/paddle/products.ex`; Plan 06. |
| Subscriptions — get/update/list/stream/all/cancel/pause/resume variants | INTEGRATE | Existing paths in `lib/paddle/subscriptions.ex`; Plan 07. |
| Transactions — get/create | INTEGRATE | Existing paths in `lib/paddle/transactions.ex`; Plan 07. |
| Pagination continuation for every pageable surface | INTEGRATE | Existing `lib/paddle/internal/pagination.ex`; Plans 04 and 07 migrate every caller while keeping cursor data dispatch-only. |
| Shared Req transport and per-attempt telemetry | INTEGRATE | Existing `lib/paddle/http.ex` and `lib/paddle/http/telemetry.ex`; Plans 04 and 08. |

## Reasoned exclusions

| capability | decision | reason |
|---|---|---|
| New Paddle endpoints or resource capabilities | OPT-OUT | Explicitly deferred by the Phase 32 boundary; this phase hardens existing behavior only. |
| `Paddle.Webhooks` | OPT-OUT | Pure inbound signature/event processing performs no outbound Paddle API request and is unaffected by Req retry/telemetry policy. |
| `Paddle.MockServer` endpoint expansion | OPT-OUT | It is a bounded local fixture used for compatibility proof; adding modeled API breadth is a future requirement, not trust-boundary work. |
| Live Paddle provider calls | OPT-OUT | D-19 forbids presenting local or MockServer evidence as live-provider proof; no credentials or provider-state mutation are required for this phase. |

No capability row is silently omitted. Package/downstream checks validate compatibility, while hosted-CI authority remains Phase 33 and release/publication remains Phase 34.
