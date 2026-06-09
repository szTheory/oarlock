# Roadmap

## Phases

- [ ] **Phase 14: Customer Portal Sessions** - Generate on-demand, authenticated portal session URLs for customers
- [ ] **Phase 15: Adjustments** - Handle refunds, credits, and their status tracking
- [ ] **Phase 16: Seam Validation & Documentation** - Ensure Accrue consumer contract is updated and validated with new entities

## Phase Details

### Phase 14: Customer Portal Sessions
**Goal**: Users can generate short-lived, authenticated portal session URLs for customers
**Depends on**: Nothing
**Requirements**: PORTAL-01, PORTAL-02
**Success Criteria** (what must be TRUE):
  1. User can successfully request a portal session URL for a given customer ID
  2. User can optionally restrict the generated portal session to specific subscription IDs
**Plans**: TBD

### Phase 15: Adjustments
**Goal**: Users can issue full and partial refunds or credits and retrieve their statuses
**Depends on**: Nothing
**Requirements**: ADJ-01, ADJ-02, ADJ-03, ADJ-04
**Success Criteria** (what must be TRUE):
  1. User can issue a full adjustment (refund or credit) for a transaction
  2. User can issue a partial adjustment targeting specific transaction line items
  3. User can fetch a specific adjustment by ID to check its approval status
  4. User can list adjustments using standard auto-pagination
**Plans**: TBD

### Phase 16: Seam Validation & Documentation
**Goal**: The newly added entities are explicitly documented and integrated into the Accrue seam contract
**Depends on**: Phase 14, Phase 15
**Requirements**: None (Cross-cutting validation)
**Success Criteria** (what must be TRUE):
  1. The new structs (`Paddle.PortalSession`, `Paddle.Adjustment`) are documented in `guides/accrue-seam.md` with explicit field tiers
  2. End-to-end Accrue seam test (`seam_test.exs`) successfully incorporates adjustments and portal session flows
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 14. Customer Portal Sessions | 1/1 | Complete | Yes |
| 15. Adjustments | 0/0 | Not started | - |
| 16. Seam Validation & Documentation | 0/0 | Not started | - |

