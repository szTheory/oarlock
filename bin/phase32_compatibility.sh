#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="${PHASE32_EVIDENCE_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/oarlock-phase32-evidence}"
FULL_RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
VERIFY_RECEIPT_PATH="$EVIDENCE_DIR/phase32-verifier.receipt"
RECEIPT_PATH="$FULL_RECEIPT_PATH"
ACCRUE_CHECKOUT="${ACCRUE_CHECKOUT:-}"
declare -a ROW_RESULTS=()

tracked_diff_fingerprint() {
  local snapshot
  snapshot="$(mktemp)"
  git -C "$ROOT_DIR" diff --binary --no-ext-diff HEAD -- >"$snapshot"
  git -C "$ROOT_DIR" diff --binary --no-ext-diff --cached HEAD -- >>"$snapshot"
  shasum -a 256 "$snapshot" | awk '{print $1}'
  rm -f "$snapshot"
}

run_row() {
  local name="$1"
  shift
  local started elapsed
  started="$(date +%s)"
  printf '\n==> [%s]\n' "$name"
  if ! "$@"; then
    printf '<== [%s] failed\n' "$name" >&2
    return 1
  fi
  elapsed=$(( $(date +%s) - started ))
  ROW_RESULTS+=("$name=${elapsed}s")
  printf '<== [%s] passed in %ss\n' "$name" "$elapsed"
}

run_root_mix() {
  (cd "$ROOT_DIR" && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors "$@")
}

run_bounded_mix() {
  run_root_mix \
    test/paddle/error_test.exs \
    test/paddle/http_test.exs \
    test/paddle/client_test.exs \
    test/paddle/http/telemetry_test.exs \
    test/paddle/inspection_safety_test.exs \
    test/paddle/customers/addresses_test.exs:198 \
    test/paddle/customers/addresses_test.exs:211 \
    test/paddle/seam_test.exs
}

run_package_smoke() {
  local elixir_version erlang_version
  elixir_version="$(awk '$1 == "elixir" {print $2}' "$ROOT_DIR/.tool-versions")"
  erlang_version="$(awk '$1 == "erlang" {print $2}' "$ROOT_DIR/.tool-versions")"
  ASDF_ELIXIR_VERSION="$elixir_version" ASDF_ERLANG_VERSION="$erlang_version" \
    "$ROOT_DIR/bin/package_smoke.sh"
}

run_accrue_seam() {
  local elixir_version erlang_version
  elixir_version="$(awk '$1 == "elixir" {print $2}' "$ROOT_DIR/.tool-versions")"
  erlang_version="$(awk '$1 == "erlang" {print $2}' "$ROOT_DIR/.tool-versions")"
  (
    cd "$ACCRUE_CHECKOUT/accrue"
    ASDF_ELIXIR_VERSION="$elixir_version" ASDF_ERLANG_VERSION="$erlang_version" \
      MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors \
      test/accrue/billing/subscription_projection_provider_test.exs
  )
}

publish_receipt() {
  local receipt_path="$1"
  local content="$2"
  local receipt_tmp
  mkdir -p "$EVIDENCE_DIR"
  receipt_tmp="$(mktemp "$EVIDENCE_DIR/.phase32-receipt.XXXXXX")"
  trap 'rm -f "${receipt_tmp:-}"' RETURN
  printf '%s\n' "$content" >"$receipt_tmp"
  mv "$receipt_tmp" "$receipt_path"
  trap - RETURN
}

fake_matrix() {
  local mode="$1"
  local ready_path="$2"

  ROW_RESULTS=()
  run_row "fake-root" true

  case "$mode" in
    fail)
      run_row "fake-failure" false || return 1
      ;;
    interrupt)
      : >"$ready_path"
      while [[ ! -f "${ready_path}.release" ]]; do
        sleep 0.05
      done
      ;;
    complete)
      run_row "fake-downstream" true
      publish_receipt "$RECEIPT_PATH" "phase32_compatibility=passed rows=${#ROW_RESULTS[@]}"
      ;;
    *)
      printf 'Unknown fake matrix mode: %s\n' "$mode" >&2
      return 2
      ;;
  esac
}

self_test() {
  local self_test_dir failure_dir interrupted_dir success_dir ready_path interrupted_pid receipt_count
  self_test_dir="$(mktemp -d)"
  trap 'rm -rf "$self_test_dir"' RETURN

  failure_dir="$self_test_dir/failure"
  interrupted_dir="$self_test_dir/interrupted"
  success_dir="$self_test_dir/success"
  mkdir -p "$failure_dir" "$interrupted_dir" "$success_dir"

  EVIDENCE_DIR="$failure_dir"
  RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
  if fake_matrix fail "$failure_dir/ready" >/dev/null 2>&1; then
    printf 'Self-test failure row unexpectedly succeeded\n' >&2
    return 1
  fi
  [[ ! -e "$RECEIPT_PATH" ]] || {
    printf 'Self-test failure row produced an acceptance receipt\n' >&2
    return 1
  }

  EVIDENCE_DIR="$interrupted_dir"
  RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
  ready_path="$interrupted_dir/ready"
  fake_matrix interrupt "$ready_path" >/dev/null 2>&1 &
  interrupted_pid=$!
  while [[ ! -f "$ready_path" ]]; do
    kill -0 "$interrupted_pid" 2>/dev/null || {
      printf 'Self-test interrupted row exited before its kill point\n' >&2
      return 1
    }
    sleep 0.05
  done
  kill -TERM "$interrupted_pid"
  wait "$interrupted_pid" 2>/dev/null || true
  [[ ! -e "$RECEIPT_PATH" ]] || {
    printf 'Self-test interrupted row produced an acceptance receipt\n' >&2
    return 1
  }

  EVIDENCE_DIR="$success_dir"
  RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
  fake_matrix complete "$success_dir/ready" >/dev/null
  receipt_count="$(find "$success_dir" -maxdepth 1 -type f -name 'phase32-compatibility.receipt' | wc -l | tr -d ' ')"
  [[ "$receipt_count" == "1" ]] || {
    printf 'Self-test complete run produced %s receipts, expected exactly one\n' "$receipt_count" >&2
    return 1
  }

  printf 'Phase 32 compatibility receipt self-test passed\n'
}

run_matrix() {
  local before_diff after_diff receipt_body

  [[ -n "$ACCRUE_CHECKOUT" ]] || {
    printf 'ACCRUE_CHECKOUT is required\n' >&2
    return 2
  }
  [[ -f "$ACCRUE_CHECKOUT/accrue/mix.exs" ]] || {
    printf 'ACCRUE_CHECKOUT must contain the tracked accrue/mix.exs project\n' >&2
    return 2
  }

  mkdir -p "$EVIDENCE_DIR"
  RECEIPT_PATH="$FULL_RECEIPT_PATH"
  rm -f "$RECEIPT_PATH"
  before_diff="$(tracked_diff_fingerprint)"

  run_row "root-suite" run_root_mix
  run_row "focused-http-adapter" run_root_mix test/paddle/http_test.exs
  run_row "focused-customer-adapters" run_root_mix \
    test/paddle/adjustments_test.exs \
    test/paddle/customers_test.exs \
    test/paddle/customers/addresses_test.exs \
    test/paddle/customers/portal_sessions_test.exs
  run_row "focused-catalog-adapters" run_root_mix \
    test/paddle/events_test.exs \
    test/paddle/notification_settings_test.exs \
    test/paddle/prices_test.exs \
    test/paddle/products_test.exs
  run_row "focused-subscription-transaction-seam-adapters" run_root_mix \
    test/paddle/subscriptions_test.exs \
    test/paddle/transactions_test.exs \
    test/paddle/seam_test.exs
  run_row "telemetry-adapter" run_root_mix test/paddle/http/telemetry_test.exs
  run_row "mockserver-subscription-flows" run_root_mix \
    test/paddle/mock_server_test.exs \
    test/paddle/subscription_flows_test.exs
  run_row "dialyzer" bash -c 'cd "$1" && mix dialyzer' _ "$ROOT_DIR"
  run_row "docs" bash -c 'cd "$1" && mix docs' _ "$ROOT_DIR"
  run_row "package-smoke-without-optional-deps" run_package_smoke
  run_row "demo-precommit" bash -c 'cd "$1/demo" && mix precommit' _ "$ROOT_DIR"
  run_row "downstream-accrue-seam" run_accrue_seam
  run_row "online-hex-audit" bash -c 'cd "$1" && mix hex.audit' _ "$ROOT_DIR"

  after_diff="$(tracked_diff_fingerprint)"
  [[ "$before_diff" == "$after_diff" ]] || {
    printf 'Tracked repository diff changed during the compatibility matrix\n' >&2
    return 1
  }

  receipt_body="phase32_compatibility=passed
commit=$(git -C "$ROOT_DIR" rev-parse HEAD)
completed_at=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
tracked_diff_sha256=$after_diff
rows=${#ROW_RESULTS[@]}
$(printf '%s\n' "${ROW_RESULTS[@]}")"
  publish_receipt "$RECEIPT_PATH" "$receipt_body"
  printf '\nPhase 32 compatibility matrix passed (%s rows)\n' "${#ROW_RESULTS[@]}"
  printf 'Acceptance receipt: %s\n' "$RECEIPT_PATH"
}

run_verifier() {
  local before_diff after_diff receipt_body

  mkdir -p "$EVIDENCE_DIR"
  rm -f "$VERIFY_RECEIPT_PATH"
  before_diff="$(tracked_diff_fingerprint)"
  ROW_RESULTS=()

  # bounded verifier evidence is fresh local evidence subordinate to the full 13-row D-03 acceptance
  # matrix. It establishes no hosted, sandbox,
  # live-provider, release, or publication authority.
  run_row "bounded-root-suite" run_bounded_mix
  run_row "online-hex-audit" bash -c 'cd "$1" && mix hex.audit' _ "$ROOT_DIR"

  after_diff="$(tracked_diff_fingerprint)"
  [[ "$before_diff" == "$after_diff" ]] || {
    printf 'Tracked repository diff changed during bounded compatibility verification\n' >&2
    return 1
  }

  receipt_body="phase32_verifier=passed
commit=$(git -C "$ROOT_DIR" rev-parse HEAD)
completed_at=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
tracked_diff_sha256=$after_diff
checks=${#ROW_RESULTS[@]}
$(printf '%s\n' "${ROW_RESULTS[@]}")
SAFE-01=pass dependency resolution and online audit
SAFE-02=pass allowlisted process-owned telemetry isolation
SAFE-03=pass exhaustive Inspect inventory and recursive canaries
SAFE-04=pass total errors bounded reads and one-attempt mutations
SAFE-05=pass secret-safe client construction and request authority
SAFE-06=pass resource docs specs seams and local no-drift contract"

  publish_receipt "$VERIFY_RECEIPT_PATH" "$receipt_body"
  printf '\nPhase 32 bounded compatibility verifier passed\n'
  printf 'Verifier receipt: %s\n' "$VERIFY_RECEIPT_PATH"
  printf 'This receipt does not replace full 13-row D-03 acceptance.\n'
}

case "${1:-}" in
  --self-test)
    self_test
    ;;
  --verify)
    run_verifier
    ;;
  --full)
    run_matrix
    ;;
  *)
    printf 'Usage: %s --verify|--full|--self-test\n' "${0##*/}" >&2
    exit 2
    ;;
esac
