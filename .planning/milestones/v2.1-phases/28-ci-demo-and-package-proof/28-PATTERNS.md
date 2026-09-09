# Phase 28: ci-demo-and-package-proof - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.github/workflows/ci.yml` demo PostgreSQL job | config | batch + request-response | `demo/config/test.exs` + `demo/mix.exs` | exact |
| `.github/workflows/ci.yml` package smoke job | config | batch + file-I/O | `.github/workflows/hex-publish.yml` + `mix.exs` | role-match |
| `.github/workflows/ci.yml` optional-deps proof job/step | config | batch | `.github/workflows/ci.yml` + `test/paddle/mock_server_test.exs` | role-match |
| `bin/package_smoke.sh` (optional) | utility | batch + file-I/O | `bin/check_summary_drift.sh` | role-match |
| `mix.exs` | config | package metadata | `mix.exs` | exact |
| `lib/paddle/mock_server.ex` | service / fixture | request-response | `lib/paddle/mock_server.ex` | exact |
| `test/paddle/mock_server_test.exs` | test | request-response | `test/paddle/mock_server_test.exs` | exact |
| `demo/config/test.exs` | config | request-response / database I/O | `demo/config/test.exs` | exact |
| `README.md` | docs | transform | `README.md` + `guides/accrue-seam.md` | exact |
| `demo/README.md` | docs | transform | `demo/README.md` | exact |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Workflow trigger and permissions pattern** (lines 6-19):
```yaml
name: CI

on:
  push:
    branches:
      - main
  pull_request:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

**Pinned action + strict BEAM setup pattern** (lines 26-31):
```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

- uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
  with:
    version-file: .tool-versions
    version-type: strict
```

**Root release gate command pattern** (lines 41-64):
```yaml
- name: Install Hex + Rebar
  run: |
    mix local.hex --force
    mix local.rebar --force

- name: Fetch library deps
  run: mix deps.get

- name: Check formatting
  run: mix format --check-formatted

- name: Check unused deps
  run: mix deps.unlock --check-unused

- name: Compile (warnings as errors)
  run: mix compile --warnings-as-errors

- name: Run tests
  env:
    MIX_ENV: test
  run: mix test

- name: Check for SUMMARY/git-state drift
  run: ./bin/check_summary_drift.sh
```

**Dialyzer cache pattern** (lines 72-93, 103-114):
```yaml
- uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
  id: setup-beam
  with:
    version-file: .tool-versions
    version-type: strict

- name: Restore PLTs
  uses: actions/cache/restore@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0
  id: plt-cache
  with:
    path: priv/plts
    key: ${{ runner.os }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-

- name: Check public specs
  run: mix typecheck.specs

- name: Run Dialyzer
  run: mix dialyzer

- name: Save PLTs
  uses: actions/cache/save@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0
  if: always()
```

Planner note: preserve `test` and `dialyzer`; add separate named jobs for demo, package smoke, and optional-deps proof.

---

### `.github/workflows/ci.yml` demo PostgreSQL job (config, batch + request-response)

**Analogs:** `demo/config/test.exs`, `demo/mix.exs`, `demo/test/test_helper.exs`

**Demo test DB env pattern** (`demo/config/test.exs` lines 8-14):
```elixir
config :demo, Demo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  database: "demo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
```

**Demo CI-safe commands source** (`demo/mix.exs` lines 79-93):
```elixir
defp aliases do
  [
    setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
    "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
    "assets.build": ["compile", "tailwind demo", "esbuild demo"],
    "assets.deploy": [
      "tailwind demo --minify",
      "esbuild demo --minify",
      "phx.digest"
    ],
    precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
  ]
end
```

Use explicit CI commands from CONTEXT, not `mix precommit`, because `precommit` runs mutating `format`.

**Positive MockServer startup through demo tests** (`demo/test/test_helper.exs` lines 1-6):
```elixir
# Start the Paddle MockServer on a random port for tests
{:ok, _pid} = Paddle.MockServer.start_link(port: 4448)
Application.put_env(:demo, :paddle_base_url, "http://localhost:4448")

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Demo.Repo, :manual)
```

**Demo integration proof pattern** (`demo/test/demo_web/integration/billing_flow_test.exs` lines 59-99):
```elixir
test "E2E Offline Flow: UI buttons trigger MockServer integrations successfully", %{conn: conn} do
  session =
    conn
    |> visit("/login")
    |> click_button("Login as Demo Merchant")
    |> assert_path("/admin")

  session =
    session
    |> click_button("Subscribe Now")
    |> assert_path("/admin")

  webhook_payload = %{
    "id" => "sub_test_mock_server_123",
    "status" => "active",
    "customer_id" => "ctm_mock_server_123",
    "current_billing_period" => %{
      "starts_at" => "2026-06-11T12:00:00.000000Z",
      "ends_at" => "2026-07-11T12:00:00.000000Z"
    },
    "custom_data" => %{"mock_user_id" => "mock-merchant-123"}
  }

  WebhookSimulator.post_webhook(
    build_conn(),
    "/webhooks/paddle",
    "subscription.created",
    webhook_payload
  )

  session
  |> assert_has("button", text: "Manage Subscription")
  |> click_button("Manage Subscription")
  |> assert_path("https://sandbox-my.paddle.com/mock-portal-session")
end
```

Planner note: GitHub Actions PostgreSQL service should set `DB_HOST=localhost`; no Docker Compose is needed.

---

### `.github/workflows/ci.yml` package smoke job (config, batch + file-I/O)

**Analogs:** `.github/workflows/hex-publish.yml`, `mix.exs`, `README.md`

**Package publish workflow setup pattern** (`.github/workflows/hex-publish.yml` lines 29-58):
```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

- uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
  with:
    version-file: .tool-versions
    version-type: strict

- name: Cache library deps
  uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0
  with:
    path: |
      deps
      _build
    key: ${{ runner.os }}-library-${{ hashFiles('mix.lock') }}

- name: Install Hex + Rebar
  run: |
    mix local.hex --force
    mix local.rebar --force

- name: Fetch library deps
  run: mix deps.get

- name: Compile (warnings as errors)
  run: mix compile --warnings-as-errors
```

**Hex artifact/publish command source** (`.github/workflows/hex-publish.yml` lines 65-73):
```yaml
- name: Dry run Hex publish
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: mix hex.publish --dry-run --yes

- name: Publish to Hex
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: mix hex.publish --yes
```

For Phase 28, do not publish. Use Hex tooling with `mix hex.build --unpack -o "$RUNNER_TEMP/oarlock-unpack"` and compile a fresh temp app against that unpacked artifact.

**Package metadata pattern** (`mix.exs` lines 7-23, 57-67):
```elixir
def project do
  [
    app: :paddle,
    version: @version,
    elixir: "~> 1.19",
    start_permanent: Mix.env() == :prod,
    aliases: aliases(),
    deps: deps(),
    name: "oarlock",
    description:
      "Paddle Billing SDK for Elixir — typed structs, pure-function webhooks, " <>
        "Req-based HTTP transport, explicit %Paddle.Client{} passing. No Phoenix or Ecto " <>
        "coupling. Used by Accrue. See https://hexdocs.pm/oarlock and guides/accrue-seam.md.",
    source_url: @source_url,
    homepage_url: @source_url,
    package: package(),
    docs: docs(),
  ]
end

defp package do
  [
    name: "oarlock",
    licenses: ["MIT"],
    links: %{
      "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
      "Documentation" => "https://hexdocs.pm/oarlock",
      "GitHub" => @source_url
    },
    files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
  ]
end
```

**Consumer identity docs pattern** (`README.md` lines 50-60):
```elixir
The Hex package is named `oarlock`, while the OTP app and module namespace are
still `:paddle` / `Paddle.*`.

def deps do
  [
    {:paddle, "~> 0.1.1", hex: :oarlock}
  ]
end
```

Planner note: fresh consumer proof should explicitly reference `Paddle.Client`, `Paddle.Webhooks`, and one resource module such as `Paddle.Customers`.

---

### `.github/workflows/ci.yml` optional-deps proof job/step (config, batch)

**Analogs:** `mix.exs`, `lib/paddle/mock_server.ex`, `test/paddle/mock_server_test.exs`

**Optional dependency declaration pattern** (`mix.exs` lines 40-48):
```elixir
defp deps do
  [
    {:req, "~> 0.5.17"},
    {:telemetry, "~> 1.4"},
    {:plug, "~> 1.0", optional: true},
    {:bandit, "~> 1.0", optional: true},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    {:dialyxir, "~> 1.4.7", only: [:dev, :test], runtime: false}
  ]
end
```

**Current compile-time risk source** (`lib/paddle/mock_server.ex` lines 25-39):
```elixir
use Plug.Router
alias Paddle.MockServer.Fixtures

plug :match
plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
plug :dispatch

def start_link(opts \\ []) do
  port = Keyword.get(opts, :port, 4001)
  Bandit.start_link(plug: __MODULE__, port: port)
end
```

Planner note: this must be gated/split before a downstream no-optional-deps consumer can compile. Keep fixture data package-safe if moving modules.

**Positive optional-deps test pattern** (`test/paddle/mock_server_test.exs` lines 1-18):
```elixir
defmodule Paddle.MockServerTest do
  use ExUnit.Case, async: false

  alias Paddle.MockServer

  setup_all do
    port = 4447
    {:ok, _pid} = MockServer.start_link(port: port)

    client = Paddle.Client.new!(
      api_key: "sk_test_mock",
      base_url: "http://localhost:#{port}"
    )

    {:ok, client: client}
  end
end
```

**Positive request-response assertions** (`test/paddle/mock_server_test.exs` lines 20-39):
```elixir
test "POST /customers returns a mocked customer payload", %{client: client} do
  assert {:ok, %Paddle.Customer{} = customer} = Paddle.Customers.create(client, %{email: "test@example.com", name: "Test"})
  assert customer.id == "ctm_mock123"
  assert customer.email == "mock@example.com"
end

test "POST /transactions returns a mocked transaction payload", %{client: client} do
  assert {:ok, %Paddle.Transaction{} = txn} = Paddle.Transactions.create(client, %{customer_id: "ctm_123", address_id: "add_123", items: [%{price_id: "pri_123", quantity: 1}]})
  assert txn.id == "txn_mock123"
  assert txn.checkout.url == "https://sandbox-checkout.paddle.com/mock-checkout-url"
end
```

---

### `bin/package_smoke.sh` (optional utility, batch + file-I/O)

**Analog:** `bin/check_summary_drift.sh`

**Shell style pattern** (lines 1-21):
```bash
#!/usr/bin/env bash

# Check for uncommitted changes to ensure working tree is clean.
# In CI, enforces completely clean working tree after tests.
# Locally, blocks commits that include a SUMMARY.md if there are ANY unstaged or untracked files.

set -e

RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${RED}ERROR: Working tree is dirty in CI.${NC}"
        echo -e "${YELLOW}The following files are untracked or have uncommitted changes:${NC}"
        git status --porcelain
        echo -e "${RED}Failing the build to prevent drift.${NC}"
        exit 1
    fi
    exit 0
fi
```

Planner note: if adding a script, use bash with `set -e`/clear failure output. Prefer inline YAML unless the fresh consumer setup becomes hard to read.

---

### `lib/paddle/mock_server.ex` (service / fixture, request-response)

**Analog:** `lib/paddle/mock_server.ex`

**Module and route imports pattern** (lines 1-30):
```elixir
defmodule Paddle.MockServer do
  @moduledoc """
  A standalone Plug Router that simulates the Paddle Billing API.
  """

  use Plug.Router
  alias Paddle.MockServer.Fixtures

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
  plug :dispatch
end
```

**Core request-response route pattern** (lines 43-83):
```elixir
post "/customers" do
  send_json(conn, 201, Fixtures.customer())
end

get "/customers/:id" do
  send_json(conn, 200, Fixtures.customer(id))
end

post "/transactions" do
  send_json(conn, 201, Fixtures.transaction())
end

get "/transactions/:id" do
  send_json(conn, 200, Fixtures.transaction(id))
end
```

**Fallback/error response pattern** (lines 86-98):
```elixir
match _ do
  conn
  |> put_resp_content_type("application/json")
  |> send_resp(404, Jason.encode!(%{error: %{message: "Mock route not found"}}))
end

defp send_json(conn, status, data) do
  conn
  |> put_resp_content_type("application/json")
  |> send_resp(status, Jason.encode!(%{data: data}))
end
```

**Fixture pattern** (`lib/paddle/mock_server/fixtures.ex` lines 1-17):
```elixir
defmodule Paddle.MockServer.Fixtures do
  @moduledoc """
  Simulated JSON payloads representing Paddle Billing API responses.
  These fixtures are dynamic and can inject specific IDs into the response.
  """

  def customer(id \\ "ctm_mock123") do
    %{
      "id" => id,
      "name" => "Mock Customer",
      "email" => "mock@example.com"
    }
  end
end
```

Planner note: if splitting for optional deps, keep routes/fallback semantics identical and preserve `Paddle.MockServer.start_link/1` for positive MockServer users.

---

### `README.md`, `guides/getting-started.md`, `guides/accrue-seam.md`, `demo/README.md` (docs, transform)

**Analogs:** existing proof boundary docs

**Root proof ladder wording** (`README.md` lines 27-37):
```markdown
## Proof Boundary

Use the same proof ladder throughout an integration:

- Unit and contract tests prove local SDK behavior.
- `Paddle.MockServer` proves deterministic local SDK/demo wiring. It is not
  live Paddle provider-state verification.
- Paddle sandbox checks prove real provider-state behavior only when you run
  them with real Paddle sandbox credentials.
- Live mode remains your operator-owned readiness step before charging
  customers.
```

**Core boundary wording** (`README.md` lines 43-49, 154-161):
```markdown
- Your app owns users, accounts, provisioning, entitlements, and persistence.
- Paddle owns billing state and checkout.
- oarlock is the seam between them.

That seam is intentionally narrow. It helps you talk to Paddle in idiomatic
Elixir without pulling Phoenix, Plug, or Ecto into the core library.

oarlock is intentionally not:

- A Phoenix or Plug integration package.
- An Ecto schema or database sync layer.
- A billing UI or customer portal replacement.
- A complete Paddle endpoint mirror.
```

**Accrue seam contract boundary** (`guides/accrue-seam.md` lines 320-336):
```markdown
- Phoenix or Ecto coupling in core. Framework helpers, if ever needed, ship
  as optional adjacent packages and remain outside this contract.

The consuming Phoenix, Plug, or Ecto application owns raw-body capture, endpoint
secret storage, signed-in authorization, idempotency persistence, webhook
de-duplication, provisioning, entitlement state, and environment-specific Paddle
credentials. oarlock provides pure SDK calls and typed response/error shapes; it
does not provide routes, schemas, migrations, authorization policy, or a billing
domain model.
```

**Demo MockServer boundary** (`demo/README.md` lines 47-65):
```markdown
## Offline Paddle Mode

The tests start `Paddle.MockServer` and point the demo client at it. For manual
experiments, start the mock server in IEx and create a client with `base_url`
set to that server:

{:ok, _pid} = Paddle.MockServer.start_link(port: 4448)

The mock server is intentionally a development fixture, not a complete Paddle
clone. It covers the demo and SDK integration paths, but it does not model every
Paddle endpoint, error, rate-limit, or provider state transition.
```

**Docs guard test pattern** (`test/paddle/seam_test.exs` lines 583-601):
```elixir
test "public docs do not claim provider-state proof from local fixtures" do
  unsupported_claims = [
    ~r/\bsandbox verified\b/i,
    ~r/\bprovider-state verified\b/i,
    ~r/\blive verified\b/i
  ]

  for path <- @public_docs do
    body = File.read!(path)

    for claim <- unsupported_claims do
      refute Regex.match?(claim, body),
             "#{path} contains unsupported provider proof wording matching #{inspect(claim)}"
    end
  end

  assert Enum.any?(@public_docs, fn path ->
           File.read!(path) =~ "MockServer"
         end)
end
```

Planner note: docs changes should state that `Paddle.MockServer` requires optional `plug`/`bandit`, while core SDK, webhooks, typed resources, and HTTP client do not.

## Shared Patterns

### CI Job Setup
**Source:** `.github/workflows/ci.yml` lines 26-47 and `.github/workflows/hex-publish.yml` lines 29-55  
**Apply to:** all new CI jobs
```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
- uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
  with:
    version-file: .tool-versions
    version-type: strict
- name: Install Hex + Rebar
  run: |
    mix local.hex --force
    mix local.rebar --force
```

### Check-Mode Mix Commands
**Source:** `.github/workflows/ci.yml` lines 49-61 and `demo/mix.exs` lines 79-93  
**Apply to:** root and demo CI lanes
```yaml
- name: Check formatting
  run: mix format --check-formatted
- name: Check unused deps
  run: mix deps.unlock --check-unused
- name: Compile (warnings as errors)
  run: mix compile --warnings-as-errors
- name: Run tests
  env:
    MIX_ENV: test
  run: mix test
```

### Package Identity
**Source:** `mix.exs` lines 7-23, 57-67 and `README.md` lines 50-60  
**Apply to:** package smoke and docs
```elixir
app: :paddle,
name: "oarlock",
files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
```

### Optional Dependency Boundary
**Source:** `mix.exs` lines 40-48 and `lib/paddle/mock_server.ex` lines 25-39  
**Apply to:** MockServer source, package smoke, optional-deps CI
```elixir
{:plug, "~> 1.0", optional: true},
{:bandit, "~> 1.0", optional: true}
```

### MockServer Response Shape
**Source:** `lib/paddle/mock_server.ex` lines 86-98  
**Apply to:** any MockServer split/gating implementation
```elixir
conn
|> put_resp_content_type("application/json")
|> send_resp(status, Jason.encode!(%{data: data}))
```

### Public Docs Proof Boundary
**Source:** `README.md` lines 27-37, `guides/accrue-seam.md` lines 338-351, `demo/README.md` lines 63-75  
**Apply to:** README/guides/demo docs
```markdown
`Paddle.MockServer` proves deterministic local SDK/demo wiring. It is not
live Paddle provider-state verification.
```

## No Analog Found

No files lacked an analog. The only new shape is a downstream Hex artifact smoke job/script, but it can compose existing workflow setup, Hex publish workflow setup, package metadata, and shell helper style.

## Metadata

**Analog search scope:** `.github/workflows`, `mix.exs`, `demo/mix.exs`, `demo/config`, `demo/test`, `lib/paddle`, `test/paddle`, `bin`, `README.md`, `guides`  
**Files scanned:** 70+ via `rg --files` and targeted `rg` searches  
**Pattern extraction date:** 2026-06-24  
**Project instructions:** no root `AGENTS.md`; `demo/AGENTS.md` applies to demo Phoenix/Mix work. No repo-local `.codex/skills` or `.agents/skills` found.
