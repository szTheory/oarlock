#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${RUNNER_TEMP:-$(mktemp -d)}"
export HEX_HOME="${WORK_DIR%/}/hex-home"
mkdir -p "$HEX_HOME"
UNPACKED_DIR="${WORK_DIR%/}/oarlock-unpacked"
CONSUMER_DIR="${WORK_DIR%/}/oarlock-consumer-proof"
PUBLISHED_TARBALL="${WORK_DIR%/}/oarlock-published-${2:-unknown}.tar"
MODE="local"
PUBLISHED_VERSION=""
if [[ "${1:-}" == "--published" ]]; then
  MODE="published"
  PUBLISHED_VERSION="${2:-}"
  [[ "$PUBLISHED_VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || { echo "Published package mode requires a version in X.Y.Z form" >&2; exit 2; }
fi

if [[ "$MODE" == "local" ]]; then
  echo "==> Building and unpacking local Hex artifact"
  cd "$ROOT_DIR"
  rm -rf "$UNPACKED_DIR" "$CONSUMER_DIR"
  mix hex.build --unpack --output "$UNPACKED_DIR"
else
  echo "==> Creating a clean consumer for published oarlock ${PUBLISHED_VERSION}"
  EXPECTED_CHECKSUM="${EXPECTED_CHECKSUM:-}"
  [[ "$EXPECTED_CHECKSUM" =~ ^[a-f0-9]{64}$ ]] || { echo "Published package mode requires the verified expected SHA-256 checksum" >&2; exit 2; }
  rm -rf "$CONSUMER_DIR"
  echo "==> Fetching the served Hex tarball and checking its package identity"
  curl --fail --silent --show-error --location "https://repo.hex.pm/tarballs/oarlock-${PUBLISHED_VERSION}.tar" --output "$PUBLISHED_TARBALL"
  OBSERVED_CHECKSUM="$(sha256sum "$PUBLISHED_TARBALL" | cut -d ' ' -f 1)"
  [[ "$OBSERVED_CHECKSUM" == "$EXPECTED_CHECKSUM" ]] || { echo "Served Hex tarball checksum mismatch: expected ${EXPECTED_CHECKSUM}, observed ${OBSERVED_CHECKSUM}" >&2; exit 1; }
  PACKAGE_METADATA="$(tar -xOf "$PUBLISHED_TARBALL" metadata.config)"
  grep -Fq "{<<\"name\">>,<<\"oarlock\">>}." <<<"$PACKAGE_METADATA" || { echo "Served Hex tarball package name is not oarlock" >&2; exit 1; }
  grep -Fq "{<<\"version\">>,<<\"${PUBLISHED_VERSION}\">>}." <<<"$PACKAGE_METADATA" || { echo "Served Hex tarball version does not match ${PUBLISHED_VERSION}" >&2; exit 1; }
fi

echo "==> Creating fresh downstream Mix consumer"
cd "$ROOT_DIR"
mix new "$CONSUMER_DIR" --sup --app oarlock_consumer_proof
cp "$ROOT_DIR/.tool-versions" "$CONSUMER_DIR/.tool-versions"

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
    case System.get_env("OARLOCK_PUBLISHED_VERSION") do
      version when is_binary(version) and version != "" -> [{:paddle, "== " <> version, hex: :oarlock}]
      _ -> [{:paddle, path: System.fetch_env!("OARLOCK_UNPACKED_PATH")}]
    end
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
if [[ "$MODE" == "published" ]]; then
  OARLOCK_PUBLISHED_VERSION="$PUBLISHED_VERSION" mix deps.get
  OARLOCK_PUBLISHED_VERSION="$PUBLISHED_VERSION" mix compile --warnings-as-errors
else
  OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix deps.get
  OARLOCK_UNPACKED_PATH="$UNPACKED_DIR" mix compile --warnings-as-errors
fi

echo "==> Package smoke proof passed"
