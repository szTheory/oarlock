# Milestone Requirements: v1.4 Catalog & Events

## Active Requirements

### Catalog (Products & Prices)
- [ ] **CAT-01**: User can list products with auto-pagination (`Paddle.Products.list/2`, `Paddle.Products.stream/2`, `Paddle.Products.all/2`).
- [ ] **CAT-02**: User can fetch a single product by ID (`Paddle.Products.get/2`).
- [ ] **CAT-03**: User can list prices with auto-pagination (`Paddle.Prices.list/2`, `Paddle.Prices.stream/2`, `Paddle.Prices.all/2`).
- [ ] **CAT-04**: User can fetch a single price by ID (`Paddle.Prices.get/2`).
- [ ] **CAT-05**: User is warned in documentation about attempting to fetch "Custom" prices/products via the Catalog.

### Events
- [ ] **EVT-01**: User can list event history with auto-pagination (`Paddle.Events.list/2`, `Paddle.Events.stream/2`, `Paddle.Events.all/2`).
- [ ] **EVT-02**: User can fetch a single event by ID (`Paddle.Events.get/2`).
- [ ] **EVT-03**: Events fetched via the API are parsed into the same `%Paddle.Event{}` struct used by webhook verification.
- [ ] **EVT-04**: User is guided in documentation to use events as triggers for canonical fetches rather than state.

### Notification Settings
- [ ] **NOTIF-01**: User can list notification settings (`Paddle.NotificationSettings.list/2`, `stream/2`, `all/2`).
- [ ] **NOTIF-02**: User can fetch a single notification setting by ID (`Paddle.NotificationSettings.get/2`).
- [ ] **NOTIF-03**: User can create a notification setting (`Paddle.NotificationSettings.create/2`).
- [ ] **NOTIF-04**: User can update a notification setting (`Paddle.NotificationSettings.update/3`).
- [ ] **NOTIF-05**: User can delete a notification setting (`Paddle.NotificationSettings.delete/2`).

## Future Requirements (Deferred)
- Create/Update/Delete operations for Products and Prices (most users manage catalog via Paddle Dashboard).
- Subscriptions mutations (update, payment method portals).
- Refunds and Connect/Marketplace.

## Out of Scope
- Ecto schemas or caching layers (belongs to consumer).
- Built-in event replay or background job queues.
- Manual offset pagination for events (Paddle Events API is strictly cursor-based).

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CAT-01 | Phase 17 | Pending |
| CAT-02 | Phase 17 | Pending |
| CAT-03 | Phase 17 | Pending |
| CAT-04 | Phase 17 | Pending |
| CAT-05 | Phase 17 | Pending |
| EVT-01 | Phase 18 | Pending |
| EVT-02 | Phase 18 | Pending |
| EVT-03 | Phase 18 | Pending |
| EVT-04 | Phase 18 | Pending |
| NOTIF-01 | Phase 19 | Pending |
| NOTIF-02 | Phase 19 | Pending |
| NOTIF-03 | Phase 19 | Pending |
| NOTIF-04 | Phase 19 | Pending |
| NOTIF-05 | Phase 19 | Pending |
