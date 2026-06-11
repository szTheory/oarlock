# Feature Landscape

**Domain:** Elixir SDK Demo Application (SaaS + Admin UI)
**Researched:** 2024

## Table Stakes

Features users expect in an SDK Demo. Missing = SDK capability feels unproven.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| SaaS Checkout Flow | Demonstrates standard integration of Paddle billing. | Medium | Use Paddle Checkout overlay via SDK. |
| Customer Portal Session | Proves lifecycle management of a subscriber. | Medium | Crucial for "set it and forget it" billing flows. |
| Admin Dashboard | Visualizes how SDK objects are retrieved and paginated. | Medium | Needs solid UI components (Petal). |
| Webhook Handling | Proves asynchronous event consistency. | High | Needs an endpoint to receive and verify Paddle signatures. |

## Differentiators

Features that set this Demo App apart as high quality.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Simulated Clock / E2E Tests | Playwright tests demonstrating complex subscription transitions (e.g. upgrade/downgrade). | High | High value for adoption trust. |
| Traefik Docker DX | Launching the demo is as simple as `docker compose up` with zero port conflicts. | Low | Huge DX win for maintainers and evaluators. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Custom Authentication / User Accounts | Distracts from Paddle-specific features; adds boilerplate. | Hardcode a "Demo User" or use a simplistic session plug. |
| Complex Database Relations | Ecto complexity shouldn't overshadow the SDK. | Only store what is strictly necessary (e.g., `user_id` -> `paddle_customer_id`). |

## Feature Dependencies

```
Docker DX Scaffolding → Petal Admin UI Layout → Webhook Handling → SaaS Checkout Flow
```

## MVP Recommendation

Prioritize:
1. Docker DX and Traefik setup.
2. Petal UI layout and "Mock" User Auth.
3. SaaS Checkout Flow (creating a subscription).

Defer: Complex Upgrade/Downgrade E2E testing flows (handled in later iterations once core SDK stability is confirmed).

## Sources

- Developer Experience (DX) principles for OSS SDKs.
- Typical SaaS reference architectures.
