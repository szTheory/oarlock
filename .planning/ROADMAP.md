# Roadmap

## Milestones

- ✅ **v1.2 Production Surface** — Phases 8-13 (shipped 2026-06-09) — see [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 Accrue Seam Hardening** — Phases 6-7 (shipped 2026-04-29) — see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.0 MVP** — Phases 1-5 (shipped pre-archival; foundational SDK surface)

## Phases

<details>
<summary>✅ v1.1 Accrue Seam Hardening (Phases 6-7) — SHIPPED 2026-04-29</summary>

- [x] Phase 6: Transactions Retrieval (1/1 plans) — TXN-03
- [x] Phase 7: Accrue Seam Lock (2/2 plans) — SEAM-01, SEAM-02

</details>

<details>
<summary>✅ v1.0 MVP (Phases 1-5) — pre-archival baseline</summary>

- [x] Phase 1: Core Transport & Client Setup (3/3 plans) — CORE-01..05
- [x] Phase 2: Webhook Verification (2/2 plans) — WEB-01..03
- [x] Phase 3: Core Entities (Customers & Addresses) (3/3 plans) — CUST-01, ADDR-01
- [x] Phase 4: Transactions & Hosted Checkout (2/2 plans) — TXN-01, TXN-02
- [x] Phase 5: Subscriptions Management (3/3 plans) — SUB-01..03

</details>

## Progress

| Phase | Milestone | Plans Complete | Status   | Completed  |
|-------|-----------|----------------|----------|------------|
| 1. Core Transport & Client Setup | v1.0 | 3/3 | Complete | pre-archival |
| 2. Webhook Verification | v1.0 | 2/2 | Complete | pre-archival |
| 3. Core Entities (Customers & Addresses) | v1.0 | 3/3 | Complete | pre-archival |
| 4. Transactions & Hosted Checkout | v1.0 | 2/2 | Complete | pre-archival |
| 5. Subscriptions Management | v1.0 | 3/3 | Complete | pre-archival |
| 6. Transactions Retrieval | v1.1 | 1/1 | Complete | 2026-04-29 |
| 7. Accrue Seam Lock | v1.1 | 2/2 | Complete | 2026-04-29 |
| 8. Reliability Primitives | v1.2 | 4/4 | Complete    | 2026-05-30 |
| 9. Pagination Ergonomics | v1.2 | 1/1 | Complete    | 2026-05-30 |
| 10. Subscriptions Surface Completion | v1.2 | 3/3 | Complete    | 2026-05-30 |
| 11. Type-Safety Pass | v1.2 | 5/5 | Complete    | 2026-06-04 |
| 12. Documentation Pass | v1.2 | 7/7 | Complete    | 2026-06-04 |
| 13. Process Guard | v1.2 | 1/1 | Complete   | 2026-06-09 |

---

## Future Work — Accrue Integration

Driven by `~/projects/accrue` consuming oarlock as its Paddle backend. See `.planning/BACKLOG.md` for any prioritized entries that survive milestone close.

Per project memory, Accrue-side asks should be triaged into `BACKLOG.md` rather than auto-inserted as phases here.

## Post-v1.2 Direction

Once v1.2 is clean, green, and released, prefer this order:

1. Support operations: refunds/credits via `Paddle.Adjustments`.
2. Customer self-serve billing: smallest provider-native portal/session/payment-management surface.
3. Catalog read surface: products/prices read/list before any broad CRUD.

Do not mirror Paddle endpoints for their own sake. Promote only work tied to a real Phoenix SaaS adopter job.
