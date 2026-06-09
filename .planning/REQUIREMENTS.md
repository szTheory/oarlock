# Requirements: oarlock

**Defined:** 2026-06-09
**Core Value:** Native Elixir interaction with Paddle Billing API v1 via explicit `%Paddle.Client{}` passing, typed struct responses, and pure-function webhook verification.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Customer Portal Sessions

- [ ] **PORTAL-01**: User can generate a short-lived Customer Portal session URL (`Paddle.Customers.PortalSessions.create/3`).
- [ ] **PORTAL-02**: User can optionally scope a Portal session to specific subscription IDs.

### Adjustments

- [ ] **ADJ-01**: User can create a full refund or credit adjustment for a completed/billed transaction (`Paddle.Adjustments.create/2`).
- [ ] **ADJ-02**: User can create a partial refund or credit adjustment by specifying line items and amounts.
- [ ] **ADJ-03**: User can retrieve an existing adjustment by its ID (`Paddle.Adjustments.get/2`).
- [ ] **ADJ-04**: User can list adjustments with standard pagination (`Paddle.Adjustments.stream`, `Paddle.Adjustments.all`).

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Catalog

- **CAT-01**: User can list Products.
- **CAT-02**: User can list Prices.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Paddle Classic Support | Must only support Paddle Billing API v1. |
| Phoenix/Ecto coupling | No framework or database integration code in the core library. |
| Invoice Generation | Deferred for v0.x. |
| Connect / Marketplaces | Deferred for v0.x. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PORTAL-01 | Phase [N] | Pending |
| PORTAL-02 | Phase [N] | Pending |
| ADJ-01 | Phase [N] | Pending |
| ADJ-02 | Phase [N] | Pending |
| ADJ-03 | Phase [N] | Pending |
| ADJ-04 | Phase [N] | Pending |

**Coverage:**
- v1 requirements: 6 total
- Mapped to phases: 0
- Unmapped: 6 ⚠️

---
*Requirements defined: 2026-06-09*
*Last updated: 2026-06-09 after v1.3 requirement definition*