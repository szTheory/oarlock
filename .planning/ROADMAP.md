# Roadmap

## Phases

| Phase | Goal | Requirements Mapped |
|-------|------|----------------------|
| 1 | Core Transport & Client Setup | CORE-01, CORE-02, CORE-03, CORE-04, CORE-05 |
| 2 | Webhook Verification | WEB-01, WEB-02, WEB-03 |
| 3 | Core Entities (Customers & Addresses) | CUST-01, ADDR-01 |
| 4 | Transactions & Hosted Checkout | TXN-01, TXN-02 |
| 5 | Subscriptions Management | SUB-01, SUB-02, SUB-03 |
| 6 | Transactions Retrieval | TXN-03 |
| 7 | Accrue Seam Lock | SEAM-01, SEAM-02 |

---

## Phase Details

### Phase 1: Core Transport & Client Setup
**Goal:** Establish the foundational HTTP layer using `req`, define the explicit `%Paddle.Client{}` struct, manage base URLs (sandbox/live), and setup the standard `{:ok, struct}` and `{:error, error}` response patterns alongside pagination.

**Plans:** 3 plans
- [x] 01-01-PLAN.md — Bootstrap the Elixir library application and set up the foundational model structs
- [x] 01-02-PLAN.md — Implement the core Paddle.Client struct and attach domain-specific telemetry steps
- [x] 01-03-PLAN.md — Implement the execution boundary Paddle.Http module

**Success Criteria:**
1. A `%Paddle.Client{}` struct can be initialized with an API key, environment (`:sandbox` | `:live`), and a hardcoded "Paddle-Version: 1" header.
2. An internal module (e.g., `Paddle.Request`) successfully makes authenticated HTTP calls to Paddle via `req` without erroring.
3. System correctly returns standard Elixir `:ok`/`:error` tuples with normalized typed error structs on HTTP failures.
4. `Paddle.Page` struct is available for future paginated requests.

---

### Phase 2: Webhook Verification
**Goal:** Provide secure, raw-body pure functions for verifying webhook signatures according to Paddle's spec (h1, multiple signatures, timestamp tolerance) and parsing event JSON.

**Plans:** 2 plans
- [x] 02-01-PLAN.md — Create the generic Paddle.Event envelope and implement pure webhook event parsing
- [x] 02-02-PLAN.md — Implement raw-body signature verification with replay protection and multi-signature support

**Success Criteria:**
1. `Paddle.Webhooks.verify_signature/4` correctly accepts or rejects raw payloads based on a matching signature.
2. Signature verification supports a configurable timestamp tolerance (defaulting to 5 seconds).
3. `Paddle.Webhooks.parse_event/1` correctly parses verified JSON into a generic `%Paddle.Event{}` envelope.

---

### Phase 3: Core Entities (Customers & Addresses)
**Goal:** Implement the fundamental billing entities that all other billing operations depend on.

**Plans:** 3 plans
- [x] 03-01-PLAN.md — Implement the customer entity contract and customer CRUD resource functions
- [x] 03-02-PLAN.md — Implement customer-scoped address entities and resource operations
- [x] 03-03-PLAN.md — Implement customer-scoped address listing with `%Paddle.Page{}` mapping

**Success Criteria:**
1. A developer can create, get, and update a `%Paddle.Customer{}`.
2. A developer can create, list, and update a `%Paddle.Address{}` for a specific customer.
3. Both entities preserve unmapped attributes via a `raw_data` field on the struct.

---

### Phase 4: Transactions & Hosted Checkout
**Goal:** Implement the bridge for Accrue's hosted checkout approach by allowing a recurring transaction to be created that yields a checkout URL.

**Plans:** 2 plans
- [ ] 04-01-PLAN.md — Add the transaction entity contracts and nested checkout struct coverage
- [ ] 04-02-PLAN.md — Implement strict hosted-checkout transaction creation and checkout URL mapping

**Success Criteria:**
1. A developer can create a transaction referencing an existing customer and address.
2. The transaction creation response includes the generated hosted checkout URL string (`transaction.checkout.url`).

---

### Phase 5: Subscriptions Management
**Goal:** Complete the SaaS lifecycle loop by allowing canonical state fetching and cancellation.

**Plans:** 3 plans
- [x] 05-01-PLAN.md — Lock the typed subscription entity surface and the two carved-out nested structs (ScheduledChange, ManagementUrls)
- [x] 05-02-PLAN.md — Implement Paddle.Subscriptions with get/2, list/2, cancel/2, cancel_immediately/2 and per-resource nested-struct hydration
- [x] 05-03-PLAN.md — Adapter-backed ExUnit coverage for all four public functions including validation, error propagation, and Pitfalls 2/3/5/6

**Success Criteria:**
1. A developer can fetch the canonical state of a specific subscription.
2. A developer can list all subscriptions for a given customer.
3. A developer can cancel a subscription (both end-of-period and immediate variants).

---

### Phase 6: Transactions Retrieval
**Goal:** Close the Phase 4 retrieval gap by letting consumers fetch a transaction by ID using the existing typed transaction surface.

**Plans:** 1 plan
- [x] 06-01-PLAN.md — Add `Paddle.Transactions.get/2` with adapter-backed coverage and nested checkout hydration assertions

**Success Criteria:**
1. A developer can fetch a transaction by ID via `Paddle.Transactions.get/2`.
2. The response hydrates `%Paddle.Transaction.Checkout{}` when checkout data is present.
3. Invalid IDs, API errors, and transport errors preserve the existing SDK tuple conventions.

---

### Phase 7: Accrue Seam Lock
**Goal:** Freeze the consumer-facing contract with one end-to-end seam test and one published seam guide.

**Plans:** 2 plans
- [ ] 07-01-PLAN.md — Add the adapter-backed end-to-end seam contract test
- [x] 07-02-PLAN.md — Publish the Accrue seam contract guide and ExDoc wiring

**Success Criteria:**
1. The seam test exercises customer creation, address creation, transaction create/get, webhook verify/parse, subscription get, and subscription cancel without live network access.
2. The seam guide lists the supported public functions, locked structs, field tiers, and not-planned areas.
3. Generated docs include the seam guide and keep internal modules out of the published consumer contract.

---

## Future Work — Accrue Integration

Driven by `~/projects/accrue` consuming oarlock as its Paddle backend. See `.planning/BACKLOG.md` for prioritized entries (`B-01` through `B-03`) with rationale, sizing, and promotion hints.

Remaining future work stays in `.planning/BACKLOG.md`. Two of Accrue's prereqs (pure-function webhooks, deferred subscription mutations) are already met by the current oarlock surface and need no new work — see `PROJECT.md → Integration Consumers`.
