# Architecture Patterns: Demo App Integration

**Domain:** Demo Application (SaaS + Apps) for Paddle Elixir SDK (`oarlock`)
**Researched:** 2026-06-10

## Recommended Architecture

The Demo App will be an isolated Phoenix application living alongside the library, designed to demonstrate the "Merchant of Record" (MoR) integration pattern using `oarlock` as a path dependency.

### Integration Point: Path Dependency

**Recommendation:** Build the demo app as a standard Phoenix project in a `/demo` (or `/demo_app`) subdirectory using a path dependency to the local SDK (`{:oarlock, path: "../"}`).

**Why not an Umbrella App?**
- **Library Purity:** Umbrellas bleed configuration and dependencies. The root `oarlock` library must remain a pure, framework-agnostic package.
- **Consumer Accuracy:** A path dependency exactly mirrors the Developer Experience (DX) of an end-user integrating `oarlock` into a standalone Phoenix project.
- **Hex Publishing:** Standard Mix library structures are significantly easier to publish to Hex without accidental inclusion of demo application code.

**Tradeoffs:**
- Requires separate Mix commands in CI (one for root `oarlock` tests, one for `/demo` tests).

### Boundary with Accrue: Embracing MoR

Accrue abstracts Payment Service Providers (PSPs) like Stripe/Braintree behind a generic processor interface. The Demo App must explicitly avoid this abstraction and lean entirely into Paddle's Merchant of Record (MoR) model.

**How to highlight Paddle's MoR model:**
- **No Tax or Compliance Logic:** The demo app must not calculate taxes, handle location-based pricing, or manage invoice generation. It relies 100% on Paddle for this.
- **Hosted Checkout over Custom Forms:** Use Paddle's Hosted Checkout (`Paddle.Transactions.create/2` returning a checkout URL) rather than building custom PCI-compliant credit card forms.
- **Webhook-Driven Source of Truth:** The demo app's local database (e.g., standard Postgres via Ecto) should be entirely event-driven. Subscriptions and transaction completions should only be updated in the local DB upon successful verification and parsing of Paddle Webhooks (using `Paddle.Webhooks.verify_signature/4`).
- **Explicit Client Passing:** Instantiate and pass `%Paddle.Client{}` explicitly through context functions, demonstrating multi-tenant safety and avoiding global application configuration.

### CI/CD Architecture: Shift-Left E2E

**Recommendation:** A robust GitHub Actions pipeline running the demo app in Docker, with Playwright for browser-based E2E tests.

**Architecture Details:**
1. **Dockerized Environment:** The demo app will include a `Dockerfile` and `docker-compose.yml` to spin up the Phoenix server and Postgres database cleanly.
2. **Playwright E2E:** Use Playwright (Node.js or Elixir bindings) to drive real browser interactions (e.g., clicking "Subscribe", navigating the Admin UI).
3. **Sandbox vs. Local Webhooks:**
   - E2E tests should hit a real Paddle Sandbox environment using dedicated CI API keys to prove 100% SDK compatibility.
   - For webhook verification in CI without exposing a public tunnel (like ngrok), the test suite will programmatically construct signed webhook payloads (mimicking Paddle) and POST them directly to the running demo app's webhook endpoint to trigger asynchronous lifecycle changes (like `subscription.created`).
4. **Pipeline Matrix:** Modify the existing `.github/workflows/ci.yml` to include a separate job for the Demo App:
   - Sets up Elixir/Erlang.
   - Starts Docker services.
   - Runs Demo App unit/integration tests.
   - Runs Playwright E2E tests against the running demo app container.

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Root (`/`)** | Pure Elixir SDK (`oarlock`). Parses webhooks, handles HTTP transport, normalizes errors. | Paddle Billing API |
| **Demo App (`/demo`)** | Phoenix web app. Manages user sessions, Admin UI, SaaS logic, local Postgres state. | Local Postgres, `oarlock` path dep |
| **Playwright CI** | E2E test runner driving the browser. Simulates user behavior and dispatches signed webhooks. | Demo App HTTP ports |

## Anti-Patterns to Avoid

### Anti-Pattern 1: Ecto/Phoenix coupling in the root SDK
**What:** Writing `oarlock` helpers that expect `Plug.Conn` or Ecto schemas.
**Why bad:** Violates the pure-library constraint of `oarlock` and pollutes the Hex package.
**Instead:** All UI and database mapping must exist strictly within the `/demo` project.

### Anti-Pattern 2: Duplicating MoR Business Logic
**What:** Building a custom billing portal or tax calculator in the Demo App.
**Why bad:** Recreates Accrue's complexity and ignores Paddle's primary value proposition.
**Instead:** Use Paddle's native Customer Portal (`Paddle.Customers.PortalSessions`) and trust Paddle's API for all financial calculations.
