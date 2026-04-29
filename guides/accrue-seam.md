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

- `Paddle.Http` and any submodule under it (transport implementation detail).
- `Paddle.Internal.*` (helper modules used by the SDK internally).
- `%Paddle.Client{}` internals such as the `:req` field.
- The placeholder root `Paddle` module.
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

The supported consumer entry modules are exactly:

- `Paddle.Customers`
- `Paddle.Customers.Addresses`
- `Paddle.Transactions`
- `Paddle.Subscriptions`
- `Paddle.Webhooks`

### `Paddle.Customers`

- `create(client, attrs)` returns `{:ok, %Paddle.Customer{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_attrs}`. Tier: `locked`.
- `get(client, customer_id)` returns `{:ok, %Paddle.Customer{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}`. Tier: `locked`.
- `update(client, customer_id, attrs)` returns `{:ok, %Paddle.Customer{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_attrs}`. Tier: `locked`.

### `Paddle.Customers.Addresses`

- `create(client, customer_id, attrs)` returns `{:ok, %Paddle.Address{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_attrs}`. Tier: `locked`.
- `get(client, customer_id, address_id)` returns `{:ok, %Paddle.Address{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_address_id}`. Tier: `locked`.
- `list(client, customer_id, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Address{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_params}`. Tier: `locked`.
- `update(client, customer_id, address_id, attrs)` returns `{:ok, %Paddle.Address{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_customer_id}` / `{:error, :invalid_address_id}` / `{:error, :invalid_attrs}`. Tier: `locked`.

### `Paddle.Transactions`

- `get(client, transaction_id)` returns `{:ok, %Paddle.Transaction{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_transaction_id}`. Tier: `locked`.
- `create(client, attrs)` returns `{:ok, %Paddle.Transaction{}}`, `{:error, %Paddle.Error{}}`, or validation error atoms. Tier: `locked`.

### `Paddle.Subscriptions`

- `get(client, subscription_id)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_subscription_id}`. Tier: `locked`.
- `list(client, params \\ [])` returns `{:ok, %Paddle.Page{data: [%Paddle.Subscription{}], meta: map()}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_params}`. Tier: `locked`.
- `cancel(client, subscription_id)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_subscription_id}`. Tier: `locked`.
- `cancel_immediately(client, subscription_id)` returns `{:ok, %Paddle.Subscription{}}`, `{:error, %Paddle.Error{}}`, or `{:error, :invalid_subscription_id}`. Tier: `locked`.

### `Paddle.Webhooks`

- `verify_signature(raw_body, signature_header, secret_key, opts \\ [])` returns `{:ok, :verified}` or `{:error, reason}`. Tier: `locked`.
- `parse_event(raw_body)` returns `{:ok, %Paddle.Event{}}`, `{:error, :invalid_json}`, or `{:error, :invalid_event_payload}`. Tier: `locked`.

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

- `Paddle.Page.next_cursor/1` returns the next pagination cursor string or `nil`. Tier: `locked`.

### `%Paddle.Error{}`

The normalized error struct returned in every `{:error, %Paddle.Error{}}` tuple.

| Field | Tier | Notes |
| --- | --- | --- |
| `:type`, `:code`, `:message`, `:status_code`, `:request_id` | `locked` | Stable normalized error metadata. |
| `:errors` | `additive` | Forwarded detail entries from Paddle. |
| `:raw` | `locked` | Forward-compat escape hatch; contents are `opaque`. |

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

## Out of scope for the current 0.x seam

Product or API surfaces that may eventually be added to oarlock but are not
supported today. Consumers should not design against any of these in the
current 0.x series:

- Subscription mutations beyond cancel: `update`, `pause`, `resume`.
- Payment-method portal update flows beyond the surfaced management URLs.
- Refunds.
- Invoice generation.
- Notification settings management.
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
