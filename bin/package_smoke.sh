#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${RUNNER_TEMP:-$(mktemp -d)}"
UNPACKED_DIR="${WORK_DIR%/}/oarlock-unpacked"
CONSUMER_DIR="${WORK_DIR%/}/oarlock-consumer-proof"

echo "==> Building and unpacking local Hex artifact"
cd "$ROOT_DIR"
rm -rf "$UNPACKED_DIR" "$CONSUMER_DIR"
mix hex.build --unpack --output "$UNPACKED_DIR"

echo "==> Creating fresh downstream Mix consumer"
mix new "$CONSUMER_DIR" --sup --app oarlock_consumer_proof

cat > "$CONSUMER_DIR/mix.exs" <<'ELIXIR'
defmodule OarlockConsumerProof.MixProject do
  use Mix.Project

  def project do
    [
      app: :oarlock_consumer_proof,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {OarlockConsumerProof.Application, []}
    ]
  end

  defp deps do
    unpacked_path = System.fetch_env!("OARLOCK_UNPACKED_PATH")

    [
      {:paddle, path: unpacked_path}
    ]
  end
end
ELIXIR

mkdir -p "$CONSUMER_DIR/lib/oarlock_consumer_proof"
cat > "$CONSUMER_DIR/lib/oarlock_consumer_proof/use_paddle.ex" <<'ELIXIR'
defmodule OarlockConsumerProof.UsePaddle do
  @moduledoc false

  def public_modules do
    [
      Paddle.Client,
      Paddle.Webhooks,
      Paddle.Customers
    ]
  end

  def webhook_parser, do: &Paddle.Webhooks.parse_event/1
  def customer_creator, do: &Paddle.Customers.create/2
end
ELIXIR

echo "==> Verifying fresh consumer dependency boundary"
if grep -Eq '\{:(plug|bandit),' "$CONSUMER_DIR/mix.exs"; then
  echo "Fresh consumer declared an optional fixture dependency"
  exit 1
fi

echo "==> Compiling fresh consumer with warnings as errors"
cd "$CONSUMER_DIR"
OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix deps.get
OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix compile --warnings-as-errors

echo "==> Package smoke proof passed"
