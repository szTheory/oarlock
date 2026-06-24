# Project Research Summary

## Executive Summary

The proposed project is a Demo Application for the `oarlock` Elixir SDK (Paddle Billing API). The demo will be an isolated Phoenix application (v1.7+) living in a `/demo` subdirectory. This structure accurately simulates third-party usage via a path dependency, explicitly avoiding an Umbrella app architecture. By leaning entirely into Paddle's Merchant of Record (MoR) model, the app avoids complex billing or tax logic, relying instead on hosted checkout and asynchronous webhook processing to maintain local state.

The recommended approach embraces modern Elixir tooling, utilizing Tailwind CSS and Petal Components for rapid UI development of an Admin Dashboard. For testing, it emphasizes a "shift-left" approach to E2E testing by integrating Playwright with `phoenix_test`. This allows for robust, deterministic browser tests within a Dockerized Traefik environment, eliminating local port conflicts and ensuring an excellent developer experience (DX).

Key risks include E2E database sandboxing issues—where the test browser fails to see Ecto sandbox data—and the danger of coupling the root `oarlock` library to Phoenix or Ecto. These are mitigated by using `phoenix_test` to seamlessly bridge the Ecto Sandbox to the web request, and by strictly maintaining a boundary where all UI and database mapping exists purely within the `/demo` application, keeping the root SDK completely framework-agnostic.

## Key Findings

### Technology Stack
- **Core:** Phoenix & LiveView (1.7+) as a subfolder path dependency (`{:oarlock, path: "../"}`).
- **UI:** Tailwind CSS (3.4+) and Petal Components (2.x) to accelerate Admin UI building.
- **Testing:** Playwright combined with `phoenix_test` for fast, deterministic, auto-waiting browser automation.
- **Infrastructure:** Docker + Traefik + PostgreSQL (16+) to provide reliable local DX with `demo.docker.localhost` routing, avoiding standard port collisions.

### Feature Landscape
- **Table Stakes:** SaaS Checkout Flow via Paddle overlay, Customer Portal Sessions, Admin Dashboard, and Webhook Handling for state consistency.
- **Differentiators:** Traefik Docker DX and robust Playwright E2E tests simulating complex subscription transitions.
- **Anti-Features:** Custom Authentication (use a mock user) and Complex Database Relations (keep Ecto mapping to bare minimums like `user_id` -> `paddle_customer_id`).

### Architecture
- **Boundary:** The Demo app is entirely separate from the root `oarlock` pure Elixir SDK. The root library handles HTTP transport and error normalization, while the Demo App handles all UI, user sessions, and local Postgres state.
- **MoR Model:** No custom tax or compliance logic is written; rely purely on `Paddle.Transactions.create/2` (Hosted Checkout) and webhook verifications for truth.
- **Testing Architecture:** The CI/CD pipeline runs a Dockerized demo app against which Playwright E2E tests run. These tests programmatically construct signed webhook payloads to trigger asynchronous lifecycle changes (like `subscription.created`) without exposing public tunnels.

### Domain Pitfalls
- **Critical - E2E Database Sandboxing:** ExUnit and Playwright operating in different transactions. *Prevention:* Configure `phoenix_test` to link the Ecto Sandbox correctly.
- **Critical - Local Port Collisions:** `EADDRINUSE` errors on evaluation. *Prevention:* Use Traefik reverse proxy in Docker.
- **Moderate - Umbrella App Tight Coupling:** Bleeding configs into the SDK. *Prevention:* Use a path dependency in a subfolder instead.

## Roadmap Implications

Suggested Phases: 5

1. **Phase 1: Local DX & Repository Foundation** — Sets up the isolated demo application and infrastructure.
   - *Deliverables:* `/demo` Phoenix application with path dependency to `oarlock`, Docker + Traefik environment.
   - *Features:* Docker DX setup.
   - *Pitfalls Avoided:* Umbrella App coupling, Local Port collisions.

2. **Phase 2: UI Scaffolding & Mock Auth** — Prepares the foundation for admin and user views without getting bogged down in boilerplate.
   - *Deliverables:* Tailwind CSS, Petal Components integration, Mock User Auth.
   - *Features:* Admin Dashboard scaffolding, explicit avoidance of complex custom auth.
   - *Pitfalls Avoided:* Building custom BEM/CSS technical debt.

3. **Phase 3: Core SaaS Checkout & Webhooks** — Implements the critical path of subscribing to a product.
   - *Deliverables:* Webhook endpoint with signature verification, SaaS Checkout Flow via Paddle overlay, local Ecto DB mapping.
   - *Features:* SaaS Checkout Flow, Webhook Handling.
   - *Pitfalls Avoided:* Webhook signature verification failing locally (requires raw body/headers).

4. **Phase 4: Customer Portal & Lifecycle Management** — Completes the subscription loop for user self-service.
   - *Deliverables:* Customer Portal Sessions integration.
   - *Features:* Customer Portal Session management.
   - *Pitfalls Avoided:* Duplicating MoR Business logic (billing portals).

5. **Phase 5: Shift-Left E2E Testing Pipeline** — Validates the full integration and SDK compatibility in an automated environment.
   - *Deliverables:* Playwright E2E tests running in GitHub Actions with programmatic webhooks.
   - *Features:* Simulated Clock / E2E Tests.
   - *Pitfalls Avoided:* E2E Database Sandboxing issues (must configure `phoenix_test` sandbox linking).

## Research Flags

- **Needs research:** Phase 3 (Webhook Handling - requires careful raw body Plug configuration for accurate signature verification). Phase 5 (specific webhook simulation payload structures for E2E tests in CI).
- **Standard patterns:** Phase 1 & Phase 2 (Standard Phoenix/Docker scaffolding).

## Confidence

- **Overall:** HIGH
- **Gaps:** Minor gap regarding the exact structure of programmatic webhook payloads for testing in CI, which will require referring to Paddle's API documentation during implementation.

## Sources

- Phoenix Framework Docs (Tailwind default in 1.7, Ecto Sandbox integration)
- Elixir Forum (Consensus: Path Dependencies > Umbrella Apps for SDK Demos)
- `phoenix_test` Documentation
- Developer Experience (DX) principles for OSS SDKs
- Typical SaaS reference architectures
