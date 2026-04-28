# Requirements

## v1 Requirements

### Core SDK
- [ ] **CORE-01**: Explicit client instantiation (`Paddle.Client.new!/1`) with Bearer auth, base URLs, and API version header ("1").
- [ ] **CORE-02**: HTTP transport built on `req` with built-in JSON parsing, retries, and telemetry.
- [ ] **CORE-03**: Consistent typed responses: `{:ok, struct}` and `{:error, %Paddle.Error{}}`.
- [ ] **CORE-04**: Retain raw response payloads (e.g., `raw_data`) in structs for forward compatibility.
- [ ] **CORE-05**: Pagination support returning `{:ok, %Paddle.Page{data: [...], meta: ...}}`.

### Webhooks
- [ ] **WEB-01**: Pure function signature verification (`Paddle.Webhooks.verify_signature/4`).
- [ ] **WEB-02**: Support configurable timestamp tolerance (default 5s) and multiple `h1` signatures.
- [ ] **WEB-03**: Event parsing into typed structs (`Paddle.Webhooks.parse_event/1`).

### Customers & Addresses
- [ ] **CUST-01**: Map application users to Paddle Customers (create, get, update).
- [ ] **ADDR-01**: Support customer billing addresses (create, list, update).

### Transactions
- [ ] **TXN-01**: Create recurring transactions mapping to hosted checkouts.
- [ ] **TXN-02**: Return hosted checkout URLs from transaction creation.

### Subscriptions
- [ ] **SUB-01**: Fetch canonical subscription state from Paddle.
- [ ] **SUB-02**: List subscriptions for a customer.
- [ ] **SUB-03**: Cancel subscription with end-of-period and immediate cancellation semantics.

## v2 Requirements (Deferred)
- [ ] **NOTIF-01**: Notification Settings endpoint support.
- [ ] **PHX-01**: Phoenix Plug helpers for webhook parsing.

## Out of Scope
- **Paddle Classic Support**: Legacy API concepts and authentication (vendor-id).
- **Phoenix/Ecto coupling**: No framework dependencies, UI dashboards, migrations, or schemas in core.
- **Payment Method Portals**: Excluded for v0.1.
- **Invoice Generation**: Excluded for v0.1.
- **Refunds**: Excluded for v0.1.
- **Marketplaces / Connect**: Excluded for v0.1.

## Traceability
*Mapped in ROADMAP.md*