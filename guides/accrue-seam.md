# Accrue Seam Contract

This guide is the canonical published contract for the oarlock surface that Accrue
(and any other consumer) is expected to depend on as its Paddle integration seam.
It enumerates the closed set of supported modules, functions, structs, and support
types and describes how each field may evolve inside the 0.x series.

## Boundary Policy

The published seam is **closed and explicitly enumerated**.
Only explicitly documented modules, functions, structs, and support types are supported as part of this seam.
Anything not listed here — including internal modules, helper functions, and the internals of `%Paddle.Client{}` such as `:req` — is outside the consumer contract and undocumented internals may change without notice inside the 0.x minor series.

In particular, the following are **not** part of the supported seam even though
they may appear in source or generated docs from earlier development snapshots:

- The internal transport layer and its submodules (transport implementation detail).
- `Paddle.Internal.*` (helper modules used by the SDK internally).
- `%Paddle.Client{}` internals such as the `:req` field.
- The placeholder root module.
- Any function not listed in the **Public Modules** or **Support Types** sections
  below.

## Stability Vocabulary

The seam uses exactly three field tiers:

- `locked`: typed top-level struct fields, narrow nested typed structs that are
  part of the documented seam, and other fields consumers may safely
  pattern-match and depend on. Removal or rename within 0.x is breaking.
- `additive`: the documented contract intentionally allows growth without
  breaking existing meaning. New fields or functions may appear; existing
  documented fields remain. This tier is **not** a synonym for
  "forwarded from Paddle" — it only marks places the contract is intentionally
  open to growth.
- `opaque`: forwarded provider data whose internal shape is not part of the
  typed seam. Consumers may inspect it defensively, but must not depend on
  key-level stability. The `:raw_data` field on each locked struct is itself
  `locked`; only the contents of `:raw_data` are `opaque`.

## Public Modules

The supported consumer entry modules are:

- `Paddle.Customers`
- `Paddle.Customers.Addresses`
- `Paddle.Customers.PortalSessions`
- `Paddle.Transactions`
- `Paddle.Adjustments`
- `Paddle.Subscriptions`
- `Paddle.Webhooks`
- `Paddle.Products`
- `Paddle.Prices`
- `Paddle.Events`
- `Paddle.NotificationSettings`
- `Paddle.Page`
- `Paddle.Error`

The exported public function inventory is intentionally explicit:

- `Paddle.Customers`: `create/2`, `create/3`, `get/2`, `update/3`.
- `Paddle.Customers.Addresses`: `create/3`, `create/4`, `get/3`,
  `list/2`, `list/3`, `stream/2`, `stream/3`, `all/2`, `all/3`,
  `update/4`.
- `Paddle.Customers.PortalSessions`: `create/2`, `create/3`, `create/4`.
- `Paddle.Transactions`: `create/2`, `create/3`, `get/2`.
- `Paddle.Adjustments`: `create/2`, `create/3`, `get/2`, `list/1`,
  `list/2`, `stream/1`, `stream/2`, `all/1`, `all/2`.
- `Paddle.Subscriptions`: `get/2`, `update/3`, `list/1`, `list/2`,
  `stream/1`, `stream/2`, `all/1`, `all/2`, `cancel/2`,
  `cancel_immediately/2`, `pause/2`, `pause/3`, `pause_immediately/2`,
  `pause_immediately/3`, `resume/2`, `resume/3`.
- `Paddle.Webhooks`: `verify_signature/3`, `verify_signature/4`,
  `parse_event/1`.
- `Paddle.Products`: `get/2`, `list/1`, `list/2`, `stream/1`,
  `stream/2`, `all/1`, `all/2`.
- `Paddle.Prices`: `get/2`, `list/1`, `list/2`, `stream/1`,
  `stream/2`, `all/1`, `all/2`.
- `Paddle.Events`: `get/2`, `list/1`, `list/2`, `stream/1`,
  `stream/2`, `all/1`, `all/2`.
- `Paddle.NotificationSettings`: `create/2`, `create/3`, `get/2`,
  `list/1`, `list/2`, `stream/1`, `stream/2`, `all/1`, `all/2`,
  `update/3`, `delete/2`.
- `Paddle.Page`: `next_cursor/1`.
- `Paddle.Error`: `exception/1`, `from_response/1`,
  `from_transport/1`, `message/1`.
- `Paddle.PortalSessions`: `create/2` compatibility surface. New code
  should prefer the customer-scoped portal namespace described below.

### `Paddle.Customers`

- `create(client, attrs)` returns `{:ok, %Paddle.Customer{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_attrs}`. Tier: `locked`.
- `get(client, customer_id)` returns `{:ok, %Paddle.Customer{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}`. Tier: `locked`.
- `update(client, customer_id, attrs)` returns `{:ok, %Paddle.Customer{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_attrs}`. Tier: `locked`.

### `Paddle.Customers.Addresses`

- `create(client, customer_id, attrs)` returns `{:ok, %Paddle.Address{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_attrs}`. Tier: `locked`.
- `get(client, customer_id, address_id)` returns `{:ok, %Paddle.Address{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_address_id}`. Tier: `locked`.
- `list(client, customer_id, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Address{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, customer_id, params \\ [])` returns a lazy `Enumerable` of `%Paddle.Address{}` values. Later-page `%Paddle.Error{}` failures raise during enumeration; local validation errors raise `ArgumentError`. Tier: `locked`.
- `all(client, customer_id, params \\ [])` returns `{:ok, [%Paddle.Address{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_params}` without returning partial results. Tier: `locked`.
- `update(client, customer_id, address_id, attrs)` returns `{:ok, %Paddle.Address{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_address_id}` / `{:error, :invalid_attrs}`. Tier: `locked`.

### `Paddle.Customers.PortalSessions`

- `create(client, customer_id, attrs \\ %{}, opts \\ [])` returns `{:ok, %Paddle.PortalSession{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / validation errors. Tier: `locked`. This expands to `Paddle.Customers.PortalSessions.create/2`, `Paddle.Customers.PortalSessions.create/3`, and `Paddle.Customers.PortalSessions.create/4`.

This is the preferred customer portal seam for new code. The caller must still
authorize the signed-in user, choose which customer they may manage, and decide
which returned Paddle-hosted URL is safe to show.

### `Paddle.PortalSessions`

- `create(client, attrs)` returns `{:ok, %Paddle.PortalSession{}}`, `{:error, %Paddle.Error{}}`, or validation errors. Tier: `locked` compatibility.

`Paddle.PortalSessions.create/2` remains visible because it ships and existing
consumers may call it. It is compatibility surface, not the preferred customer
portal seam for new Accrue integrations. New code should use
`Paddle.Customers.PortalSessions.create(client, customer_id, attrs \\ %{}, opts \\ [])`.

### `Paddle.Transactions`

- `get(client, transaction_id)` returns `{:ok, %Paddle.Transaction{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_transaction_id}`. Tier: `locked`.
- `create(client, attrs, opts \\ [])` returns `{:ok, %Paddle.Transaction{}}`, `{:error, %Paddle.Error{}}`, or validation error atoms. Tier: `locked`.

Recurring subscriptions start from this transaction seam (checkout or manual collection) and are then reconciled through webhooks plus canonical fetches (`Paddle.Transactions.get/2` -> `Paddle.Subscriptions.get/2`).

### `Paddle.Adjustments`

- `create(client, attrs, opts \\ [])` returns `{:ok, %Paddle.Adjustment{}}`, `{:error, %Paddle.Error{}}`, or validation error atoms. Tier: `locked`.
- `get(client, adjustment_id)` returns `{:ok, %Paddle.Adjustment{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_adjustment_id}`. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Adjustment{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, params \\ [])` returns a lazy `Enumerable` of `%Paddle.Adjustment{}` values. Later-page failures raise during enumeration; local validation errors raise `ArgumentError`. Tier: `locked`.
- `all(client, params \\ [])` returns `{:ok, [%Paddle.Adjustment{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}` without returning partial results. Tier: `locked`.

### `Paddle.Subscriptions`

- `get(client, subscription_id)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_subscription_id}`. Tier: `locked`.
- `update(client, subscription_id, params)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or local validation errors. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Subscription{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, params \\ [])` returns a lazy `Enumerable` of `%Paddle.Subscription{}` values. Later-page `%Paddle.Error{}` failures raise during enumeration; local validation errors raise `ArgumentError`. Tier: `locked`.
- `all(client, params \\ [])` returns `{:ok, [%Paddle.Subscription{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}` without returning partial results. Tier: `locked`.
- `cancel(client, subscription_id)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_subscription_id}`. Tier: `locked`.
- `cancel_immediately(client, subscription_id)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_subscription_id}`. Tier: `locked`.
- `pause(client, subscription_id, opts \\ [])` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or local validation errors. Tier: `locked`.
- `pause_immediately(client, subscription_id, opts \\ [])` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or local validation errors. Tier: `locked`.
- `resume(client, subscription_id, opts \\ [])` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or local validation errors. Tier: `locked`.

`Paddle.Subscriptions` intentionally does not expose direct create operations. `resume/3` defaults to immediate behavior and can charge immediately depending on billing state, so reconcile final subscription/transaction state via webhook events and canonical fetches.

### `Paddle.Webhooks`

- `verify_signature(raw_body, signature_header, secret_key, opts \\ [])` returns `{:ok, :verified}` or `{:error, reason}`. Tier: `locked`.
- `parse_event(raw_body)` returns `{:ok, %Paddle.Event{}}`, `{:error, :invalid_json}`, or `{:error, :invalid_event_payload}`. Tier: `locked`.

### `Paddle.Products`

- `get(client, product_id)` returns `{:ok, %Paddle.Product{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_product_id}`. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Product{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, params \\ [])` returns a lazy `Enumerable` of `%Paddle.Product{}` values. Tier: `locked`.
- `all(client, params \\ [])` returns `{:ok, [%Paddle.Product{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.

### `Paddle.Prices`

- `get(client, price_id)` returns `{:ok, %Paddle.Price{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_price_id}`. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Price{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, params \\ [])` returns a lazy `Enumerable` of `%Paddle.Price{}` values. Tier: `locked`.
- `all(client, params \\ [])` returns `{:ok, [%Paddle.Price{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.

### `Paddle.Events`

- `get(client, event_id)` returns `{:ok, %Paddle.Event{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_event_id}`. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Event{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, params \\ [])` returns a lazy `Enumerable` of `%Paddle.Event{}` values. Tier: `locked`.
- `all(client, params \\ [])` returns `{:ok, [%Paddle.Event{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.

### `Paddle.NotificationSettings`

- `create(client, attrs, opts \\ [])` returns `{:ok, %Paddle.NotificationSetting{}}`, `{:error, %Paddle.Error{}}`, or local validation errors. Tier: `locked`.
- `get(client, id)` returns `{:ok, %Paddle.NotificationSetting{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_notification_setting_id}`. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.NotificationSetting{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `stream(client, params \\ [])` returns a lazy `Enumerable` of `%Paddle.NotificationSetting{}` values. Tier: `locked`.
- `all(client, params \\ [])` returns `{:ok, [%Paddle.NotificationSetting{}]}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `update(client, id, attrs)` returns `{:ok, %Paddle.NotificationSetting{}}`, `{:error, %Paddle.Error{}}`, or local validation errors. Tier: `locked`.
- `delete(client, id)` returns `:ok`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_notification_setting_id}`. Tier: `locked`.

## Support Types

The following support types and helpers are documented as part of the seam.
Consumers may rely on them, but the typed surface stops at the fields and
functions listed below; everything else on these modules is undocumented
internals and may change without notice.

### `Paddle.Client.new!/1`

The supported way to construct a `%Paddle.Client{}` for use with every public
function above. The bang variant raises on invalid input. The returned
`%Paddle.Client{}` should be treated as a value to thread through public
functions; its internal fields (such as `:req`) are not part of the seam.

- `Paddle.Client.new!/1` returns a `%Paddle.Client{}`. Tier: `locked`.

### `%Paddle.Page{}`

The pagination envelope returned from list endpoints.

| Field | Tier | Notes |
| --- | --- | --- |
| `:data` | `locked` | Typed list of resource structs (for example `%Paddle.Address{}` or `%Paddle.Subscription{}`). |
| `:meta` | `additive` | Pagination metadata map. The cursor key consumers should depend on is read through `Paddle.Page.next_cursor/1`. |

### `Paddle.Page.next_cursor/1`

- `Paddle.Page.next_cursor/1` returns Paddle's next pagination reference string or `nil`. It may return a non-nil reference even when `meta.pagination.has_more` is false; auto-pagination helpers use `has_more` internally to decide whether another page should be fetched. Tier: `locked`.

### `%Paddle.Error{}`

The normalized error struct returned in every `{:error, %Paddle.Error{}}` tuple.

| Field | Tier | Notes |
| --- | --- | --- |
| `:type`, `:code`, `:message`, `:status_code`, `:request_id` | `locked` | Stable normalized error metadata. |
| `:errors` | `additive` | Forwarded detail entries from Paddle. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

## Locked Structs

### `%Paddle.Customer{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:name`, `:email`, `:marketing_consent`, `:status`, `:custom_data`, `:locale`, `:created_at`, `:updated_at`, `:import_meta` | `locked` | Typed top-level customer fields. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Address{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:customer_id`, `:description`, `:first_line`, `:second_line`, `:city`, `:postal_code`, `:region`, `:country_code`, `:custom_data`, `:status`, `:created_at`, `:updated_at`, `:import_meta` | `locked` | Typed top-level address fields. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Transaction{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:status`, `:customer_id`, `:address_id`, `:business_id`, `:custom_data`, `:currency_code`, `:origin`, `:subscription_id`, `:invoice_number`, `:collection_mode`, `:created_at`, `:updated_at`, `:billed_at`, `:revised_at` | `locked` | Typed top-level transaction fields. |
| `:checkout` | `locked` | Hydrated `%Paddle.Transaction.Checkout{}` when checkout data is present. |
| `:items`, `:details`, `:payments` | `opaque` | Forwarded provider data; nested shape is not part of the typed seam. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Transaction.Checkout{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:url` | `locked` | Hosted checkout URL returned from create/get responses. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Subscription{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:status`, `:customer_id`, `:address_id`, `:business_id`, `:currency_code`, `:collection_mode`, `:custom_data`, `:next_billed_at`, `:started_at`, `:first_billed_at`, `:paused_at`, `:canceled_at`, `:created_at`, `:updated_at`, `:import_meta` | `locked` | Typed top-level subscription fields. |
| `:scheduled_change` | `locked` | Hydrated `%Paddle.Subscription.ScheduledChange{}` when present. |
| `:management_urls` | `locked` | Hydrated `%Paddle.Subscription.ManagementUrls{}` when present. |
| `:items`, `:current_billing_period`, `:billing_cycle`, `:billing_details`, `:discount` | `opaque` | Forwarded provider data; nested shape is not part of the typed seam. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Subscription.ScheduledChange{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:action`, `:effective_at`, `:resume_at` | `locked` | Typed subscription scheduled-change fields. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Subscription.ManagementUrls{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:update_payment_method`, `:cancel` | `locked` | Buyer-portal URLs exposed to consumers. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Event{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:event_id`, `:event_type`, `:occurred_at`, `:notification_id` | `locked` | Typed webhook envelope fields. |
| `:data` | `opaque` | Event body is forwarded as a map; its shape depends on the event type and is not part of the typed seam. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.PortalSession{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:customer_id`, `:created_at`, `:custom_data` | `locked` | Typed top-level portal session fields. |
| `:urls` | `opaque` | Forwarded provider data; nested shape is not part of the typed seam. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

### `%Paddle.Adjustment{}`

| Field | Tier | Notes |
| --- | --- | --- |
| `:id`, `:action`, `:transaction_id`, `:subscription_id`, `:customer_id`, `:reason`, `:credit_applied_to_balance`, `:currency_code`, `:status`, `:created_at`, `:updated_at` | `locked` | Typed top-level adjustment fields. |
| `:items`, `:totals`, `:payouts` | `opaque` | Forwarded provider data; nested shape is not part of the typed seam. |
| `:raw_data` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

## Out of scope for the current 0.x seam

Product or API surfaces that may eventually be added to oarlock but are not
supported today. Consumers should not design against any of these in the
current 0.x series:

- Subscription helpers beyond the documented update and lifecycle calls above.
- Payment-method portal update flows beyond the surfaced management URLs.
- Payment-method APIs beyond customer portal sessions and surfaced management URLs.
- Invoice generation.
- Any Paddle product or API surface not enumerated in **Public Modules** or
  **Support Types** above.

## Intentionally excluded from core

Concerns that do not belong inside this library's architectural boundary
and will not be added to the core seam:

- Phoenix or Ecto coupling in core. Framework helpers, if ever needed, ship
  as optional adjacent packages and remain outside this contract.
- Marketplaces / Connect coverage.
- Paddle Classic concepts and authentication.
- UI dashboards, database synchronization, or persistence concerns.

The consuming Phoenix, Plug, or Ecto application owns raw-body capture, endpoint
secret storage, signed-in authorization, idempotency persistence, webhook
de-duplication, provisioning, entitlement state, and environment-specific Paddle
credentials. oarlock provides pure SDK calls and typed response/error shapes; it
does not provide routes, schemas, migrations, authorization policy, or a billing
domain model.

## Proof Boundary

Use this ladder when describing evidence for the seam:

- Unit and contract tests prove local SDK behavior.
- `Paddle.MockServer` proves deterministic local SDK/demo wiring. It is a
  development fixture, not a complete Paddle clone, and MockServer-backed tests
  are not live Paddle provider-state verification.
- Paddle sandbox checks prove real provider-state behavior only when they are
  run with real Paddle sandbox credentials and documented as such.
- Live mode remains operator-owned readiness before charging customers.

Do not treat offline or MockServer-backed checks as evidence that Paddle will
create, retry, order, or deliver real provider state.
