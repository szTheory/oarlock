# Roadmap

## Phases

| Phase | Goal | Requirements Mapped |
|-------|------|----------------------|
| 1 | Core Transport & Client Setup | CORE-01, CORE-02, CORE-03, CORE-04, CORE-05 |
| 2 | Webhook Verification | WEB-01, WEB-02, WEB-03 |
| 3 | Core Entities (Customers & Addresses) | CUST-01, ADDR-01 |
| 4 | Transactions & Hosted Checkout | TXN-01, TXN-02 |
| 5 | Subscriptions Management | SUB-01, SUB-02, SUB-03 |

---

## Phase Details

### Phase 1: Core Transport & Client Setup
**Goal:** Establish the foundational HTTP layer using `req`, define the explicit `%Paddle.Client{}` struct, manage base URLs (sandbox/live), and setup the standard `{:ok, struct}` and `{:error, error}` response patterns alongside pagination.

**Success Criteria:**
1. A `%Paddle.Client{}` struct can be initialized with an API key, environment (`:sandbox` | `:live`), and a hardcoded "Paddle-Version: 1" header.
2. An internal module (e.g., `Paddle.Request`) successfully makes authenticated HTTP calls to Paddle via `req` without erroring.
3. System correctly returns standard Elixir `:ok`/`:error` tuples with normalized typed error structs on HTTP failures.
4. `Paddle.Page` struct is available for future paginated requests.

---

### Phase 2: Webhook Verification
**Goal:** Provide secure, raw-body pure functions for verifying webhook signatures according to Paddle's spec (h1, multiple signatures, timestamp tolerance) and parsing event JSON.

**Success Criteria:**
1. `Paddle.Webhooks.verify_signature/4` correctly accepts or rejects raw payloads based on a matching signature.
2. Signature verification supports a configurable timestamp tolerance (defaulting to 5 seconds).
3. `Paddle.Webhooks.parse_event/1` correctly parses verified JSON into a generic `%Paddle.Event{}` envelope.

---

### Phase 3: Core Entities (Customers & Addresses)
**Goal:** Implement the fundamental billing entities that all other billing operations depend on.

**Success Criteria:**
1. A developer can create, get, and update a `%Paddle.Customer{}`.
2. A developer can create, list, and update a `%Paddle.Address{}` for a specific customer.
3. Both entities preserve unmapped attributes via a `raw_data` field on the struct.

---

### Phase 4: Transactions & Hosted Checkout
**Goal:** Implement the bridge for Accrue's hosted checkout approach by allowing a recurring transaction to be created that yields a checkout URL.

**Success Criteria:**
1. A developer can create a transaction referencing an existing customer and address.
2. The transaction creation response includes the generated hosted checkout URL string (`transaction.checkout.url`).

---

### Phase 5: Subscriptions Management
**Goal:** Complete the SaaS lifecycle loop by allowing canonical state fetching and cancellation.

**Success Criteria:**
1. A developer can fetch the canonical state of a specific subscription.
2. A developer can list all subscriptions for a given customer.
3. A developer can cancel a subscription (both end-of-period and immediate variants).