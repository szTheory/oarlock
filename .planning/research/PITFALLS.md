# Domain Pitfalls

**Domain:** Elixir SDK Demo Application (SaaS + Admin UI)
**Researched:** 2024

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: E2E Database Sandboxing
**What goes wrong:** Playwright browser requests and the ExUnit test process operate in different database transactions, causing the browser to see an empty database while the test runner sees the seeded data.
**Why it happens:** Ecto SQL Sandbox isolates tests to individual DB transactions. The external Node.js/Playwright process isn't natively aware of this Elixir process ID.
**Consequences:** E2E tests fail mysteriously claiming data doesn't exist.
**Prevention:** Use `phoenix_test` which manages the user-agent header passing or explicit metadata passing to link the Ecto Sandbox to the web request. Ensure `Phoenix.Ecto.SQL.Sandbox` is configured in `endpoint.ex` for the `:test` environment.
**Detection:** Flaky test suites where data assertions fail only in the browser context.

### Pitfall 2: Local Port Collisions
**What goes wrong:** Running `mix phx.server` or `docker compose up` fails because port 4000 or 5432 is already bound by another project.
**Why it happens:** Elixir developers typically have multiple Phoenix apps running on standard ports.
**Consequences:** Developers evaluating the SDK cannot boot the demo app.
**Prevention:** Use Traefik as a reverse proxy in Docker, routing hostnames (e.g., `demo.docker.localhost`) rather than exposing raw ports, or use dynamic port binding.
**Detection:** `EADDRINUSE` errors on boot.

## Moderate Pitfalls

### Pitfall 1: Umbrella App Tight Coupling
**What goes wrong:** The demo app inadvertently relies on configuration or dependencies that exist globally in the Umbrella, but won't exist when a real user installs the SDK.
**Prevention:** Avoid an Umbrella app. Place the demo in a `/demo` folder and rely on the SDK as a path dependency (`{:oarlock, path: "../"}`).

## Minor Pitfalls

### Pitfall 1: BEM or Custom CSS Technical Debt
**What goes wrong:** Spending hours building responsive tables and modals for an Admin UI instead of focusing on SDK features.
**Prevention:** Adopt Tailwind CSS and an established component library like Petal Components.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Docker DX | Caching issues with Elixir deps compilation. | Use multi-stage Dockerfiles caching `mix.lock` and running `mix deps.get` prior to copying app source. |
| Webhook Handling | Signature verification fails locally because ngrok alters headers or local host doesn't match. | Carefully pass raw body and headers to the `oarlock` verification functions in a custom Plug. |

## Sources

- Phoenix Framework issues (Ecto Sandbox integration).
- Elixir developer community forum threads on Umbrella app caveats.
