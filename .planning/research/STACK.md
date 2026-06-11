# Technology Stack

**Project:** oarlock Demo App
**Researched:** 2024

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix & LiveView | 1.7+ | Web Framework & Realtime UI | Standard for modern Elixir web apps. Unmatched productivity for admin interfaces. |
| Elixir Path Dependency | N/A | App Architecture | Placing the demo in a `/demo` folder with `{:oarlock, path: "../"}` accurately simulates third-party usage without the shared configuration bleed of an Umbrella app. |

### UI / CSS Architecture
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Tailwind CSS | 3.4+ | CSS Architecture | Default in Phoenix 1.7. Scales infinitely better than BEM, has utility classes that map perfectly to isolated Phoenix Components. |
| Petal Components | 2.x | UI Library | Idiomatic HEEx components built on Tailwind. Dramatically speeds up building an Admin UI (tables, modals, forms) without writing it from scratch. |

### E2E Testing
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Playwright | latest | Browser Automation | Highly deterministic, auto-waiting, and features Trace Viewer for debugging. Eliminates the flakiness often seen in WebDriver-based testing. |
| phoenix_test | latest | Testing Interface | Provides a unified API. Tests can run as blazing fast `LiveViewTest`s or be promoted to Playwright seamlessly without changing test syntax. |

### Infrastructure (Local DX)
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Docker + Traefik | v3 | Container & Proxy | Traefik acts as a reverse proxy routing `http://demo.docker.localhost` to the app. Avoids port 4000 collisions if running multiple Elixir apps. |
| PostgreSQL | 16+ | Database | Standard Ecto store. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Architecture | Subfolder (Path Dep) | Umbrella App | Umbrellas share global configuration (`config.exs`) which makes the demo app unrepresentative of a real, isolated user implementation. |
| CSS Architecture | Tailwind | BEM / SASS | Requires mapping CSS classes manually; slower development cycle. Tailwind is officially embraced by Phoenix generators. |
| UI Component Lib | Petal Components | CoreComponents only | `core_components.ex` is great but lacks advanced Admin UI widgets (dropdowns, cards, data tables) that Petal provides out of the box. |
| E2E Testing | Playwright | Wallaby | Wallaby relies on Selenium/ChromeDriver which is notoriously flaky with complex JS (LiveView DOM patching). Playwright communicates directly with the browser engine. |
| Docker DX | Traefik | Dynamic Host Ports | Randomly mapping ports (e.g. `8080:4000`) is confusing and requires manual lookup. Traefik provides predictable local DNS. |

## Installation

```bash
# Core setup inside /demo
mix phx.new demo --no-ecto # or with ecto if demo has local DB
cd demo

# Adding Petal
mix deps.add petal_components
mix deps.add phoenix_test_playwright --only test
```

## Sources

- Phoenix Framework Docs (Tailwind default in 1.7)
- Elixir Forum (Consensus: Path Dependencies > Umbrella Apps for SDK Demos)
- `phoenix_test` Documentation (Unified Playwright/LiveView approach)
