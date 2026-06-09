# Pitfalls Research

**Domain:** Paddle Billing API v1 (Customer Portal & Adjustments)
**Researched:** 2026-06-09
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Caching Portal Session URLs

**What goes wrong:**
Developers store the `url` returned by `POST /customers/{customer_id}/portal-sessions` in their database and serve it multiple times. Users see "Expired" or "Invalid" errors.

**Why it happens:**
Treating the portal URL like a static asset or standard web link rather than a single-use, short-lived authentication token (magic link).

**How to avoid:**
Never store portal URLs. The SDK should be designed to invoke the `create/3` function synchronously on-demand when the user clicks a "Manage Billing" button, and the application must immediately redirect.

**Warning signs:**
Database migrations adding `portal_url` fields to the `users` table; caching layers wrapped around the portal session API call.

**Phase to address:**
PORTAL-01 (Customer Portal Sessions)

---

### Pitfall 2: Assuming Synchronous Refund Execution

**What goes wrong:**
The application assumes a refund is finalized immediately when the API returns a `201 Created` or `200 OK`. The user is told "Refund Complete" but the refund is actually rejected later.

**Why it happens:**
Paddle adjustments (especially refunds on live accounts) often default to a `pending_approval` status, requiring manual review by Paddle's risk team. 

**How to avoid:**
The SDK must explicitly surface the `status` field (e.g., `pending_approval`, `approved`, `rejected`). Applications must rely on webhook events (`adjustment.updated`) to confirm final state rather than the synchronous API response.

**Warning signs:**
SDK consumers checking `{:ok, _}` and assuming success without inspecting the `%Paddle.Adjustment{status: ...}` field; missing webhook handlers for adjustment states.

**Phase to address:**
ADJ-01 (Adjustments)

---

### Pitfall 3: Wrong ID for Partial Refunds

**What goes wrong:**
When creating a partial adjustment, developers pass the catalog `price_id` instead of the specific transaction `item_id`. The API rejects the request.

**Why it happens:**
Confusion between catalog entities (`pri_...`) and transaction line items (`txnitm_...`). The API requires the exact line item ID generated when the transaction occurred.

**How to avoid:**
In the SDK's `Paddle.Adjustments.create/2` parameters, explicitly document and/or type the `items` array to require transaction line item IDs instead of generic price IDs.

**Warning signs:**
Passing standard product/price IDs into the adjustment payload instead of parsing the `details.line_items` from the parent transaction.

**Phase to address:**
ADJ-01 (Adjustments)

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping `subscription_ids` in Portal Sessions | Less code, faster implementation | Users land on a generic overview instead of directly managing the subscription they want, causing confusion. | Only acceptable if the user has exactly one subscription or you want a generic billing dashboard. |
| Using string amounts directly from UI | Passes through payload easily | Currency mismatch bugs (e.g., passing `"50.00"` instead of `"5000"` for cents). | Never. The SDK should guide users toward lowest-denominator formats. |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Customer Portal | Iframing the portal URL | Paddle blocks iframes for security (clickjacking). Use a full window redirect or `target="_blank"`. |
| Adjustments | Trying to update/delete an adjustment | Adjustments are immutable financial records. The SDK should deliberately omit `update` and `delete` functions for `Paddle.Adjustments`. |
| Customer Portal | Assuming internal User ID == Paddle Customer ID | Maintain a strict mapping between your internal ID and the Paddle `ctm_` ID, handling email changes carefully. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Generating portals on login | Slow login times, rate limiting | Generate portal sessions lazily (only when the user clicks "Manage Billing"). | When active users exceed API rate limits (e.g., large user spikes). |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing environment-mismatched IDs | Portal generation fails or shows wrong data | Ensure `PADDLE_API_KEY` and the requested `customer_id` strictly belong to the same environment (Live vs Sandbox). |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Generic Portal Redirects | User wants to cancel "Sub A" but has to click through multiple screens | Pass `subscription_ids: [sub_id]` to generate deep links (`urls.subscriptions[].cancel_subscription`) and redirect directly there. |
| Not handling `pending_approval` | User believes refund is done, contacts support when funds don't appear | Show UI state as "Refund Pending Review" until the webhook fires confirming approval. |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Portal Sessions:** Often missing deep-linking — verify `subscription_ids` are passed if applicable.
- [ ] **Adjustments:** Often missing webhook handling — verify `adjustment.updated` is integrated for state changes.
- [ ] **Adjustments (Partial):** Often missing correct IDs — verify `txnitm_` IDs are used, not `pri_`.
- [ ] **Adjustments:** Often missing immutable design — verify no `update` or `delete` functions are exposed in the SDK.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Cached Portal URLs | LOW | Delete cached URLs, update application logic to generate synchronously, and force-refresh the UI. |
| Refund state mismatch | MEDIUM | Run a sync script via `GET /adjustments` to update local database states for any refunds stuck in "Pending". |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Caching Portal URLs | PORTAL-01 | Ensure guides explicitly forbid caching and code examples show on-demand generation. |
| Generic Portal Redirects | PORTAL-01 | Include `@doc` examples showing how to use `subscription_ids` for deep-linking. |
| Synchronous Refund Assumptions | ADJ-01 | The struct `%Paddle.Adjustment{}` must expose `status` typed appropriately (`pending_approval`, `approved`, etc). |
| Partial Refund ID errors | ADJ-01 | Add clear typed specs for `items` requiring `txnitm_` formats and highlight in docs. |
| Modifying Adjustments | ADJ-01 | Review the `Paddle.Adjustments` module to ensure ONLY `create` and `get/list` are implemented. |

## Sources

- [Paddle Docs: Customer Portal Sessions](https://developer.paddle.com/api-reference/customer-portal-sessions)
- [Paddle Docs: Adjustments](https://developer.paddle.com/api-reference/adjustments)
- Community discussions on Paddle V1 integration gotchas

---
*Pitfalls research for: Paddle Billing API v1 Customer Portal & Adjustments*
*Researched: 2026-06-09*