#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="${PHASE32_EVIDENCE_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/oarlock-phase32-evidence}"
FULL_RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
VERIFY_RECEIPT_PATH="$EVIDENCE_DIR/phase32-verifier.receipt"
RECEIPT_PATH="$FULL_RECEIPT_PATH"
ACCRUE_CHECKOUT="${ACCRUE_CHECKOUT:-}"
declare -a ROW_RESULTS=()
BOUNDED_PROOF_DIR=""
BOUNDED_PROOF_EVENTS_FILE=""
BOUNDED_PROOF_LOG=""

cleanup_bounded_proof_dir() {
  if [[ -n "$BOUNDED_PROOF_DIR" && -d "$BOUNDED_PROOF_DIR" ]]; then
    rm -rf "$BOUNDED_PROOF_DIR"
  fi
}
trap cleanup_bounded_proof_dir EXIT

bounded_proof_files() {
  printf '%s\n' \
    test/paddle/error_test.exs \
    test/paddle/http_test.exs \
    test/paddle/client_test.exs \
    test/paddle/http/telemetry_test.exs \
    test/paddle/inspection_safety_test.exs \
    test/paddle/customers/addresses_test.exs \
    test/paddle/seam_test.exs
}

bounded_expected_triples() {
  cat <<'EOF'
safe_01_full_receipt_invalidation|Paddle.SeamTest|test Phase 32 full receipt invalidation precedes every Accrue preflight
safe_02_telemetry_allowlist|Paddle.Http.TelemetryTest|test a successful physical attempt emits exact allowlisted start and stop payloads
safe_03_recursive_inspect_redaction|Paddle.InspectionSafetyTest|test all six capability-bearing values redact promoted, nested, and transport canaries
safe_04_ambiguous_mutation|Paddle.ErrorTest|test context-aware constructors from_response/2 prefers body meta request_id and marks uncertain mutations
safe_04_public_retry_options|Paddle.HttpTest|test validate_public_request_opts!/1 accepts only a unique boolean retry option
safe_04_retry_decision|Paddle.HttpTest|test request/4 retry policy retry decisions are deterministic, safe-read-only, and cap only 429 Retry-After
safe_04_address_stream_pagination|Paddle.Customers.AddressesTest|test stream/3 streams addresses across three nested pages in order and replays Paddle next URLs
safe_05_custom_base_url|Paddle.ClientTest|test new!/1 base-URL-only custom client performs one adapter-backed request
safe_05_address_validation|Paddle.Customers.AddressesTest|test list/3 returns exact validation tuples before dispatch
safe_06_address_stream_docs|Paddle.SeamTest|test address stream documentation matches direct elements and raised enumeration failures
safe_06_compiled_docs_types_specs|Paddle.SeamTest|test compiled docs types and specs agree with the Phase 32 decision tables
safe_06_contract_receipt_finalization|Paddle.SeamTest|test Phase 32 bounded contract receipt finalizes only from successful exit
safe_06_evidence_tier_separation|Paddle.SeamTest|test Phase 32 proof runners separate bounded verification from full acceptance
safe_06_public_contract_docs|Paddle.SeamTest|test public documentation pins the secure dependency and runtime migration contract
EOF
}

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
  if [[ -n "${PHASE32_MIX_BUILD_PATH:-}" ]]; then
    (
      cd "$ROOT_DIR" && MIX_ENV=test MIX_BUILD_PATH="$PHASE32_MIX_BUILD_PATH" \
        mix do compile --warnings-as-errors + test --warnings-as-errors "$@"
    )
  else
    (cd "$ROOT_DIR" && MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors "$@")
  fi
}

validate_exact_lines() {
  local expected="$1" observed="$2" label="$3" expected_sorted observed_sorted
  expected_sorted="$BOUNDED_PROOF_DIR/${label}.expected.sorted"
  observed_sorted="$BOUNDED_PROOF_DIR/${label}.observed.sorted"
  LC_ALL=C sort "$expected" >"$expected_sorted"
  LC_ALL=C sort "$observed" >"$observed_sorted"
  [[ "$(wc -l <"$expected_sorted" | tr -d ' ')" == "$(wc -l <"$observed_sorted" | tr -d ' ')" ]] || {
    printf '%s count differs from canonical manifest\n' "$label" >&2
    return 1
  }
  [[ "$(uniq -d "$observed_sorted" | wc -l | tr -d ' ')" == "0" ]] || {
    printf '%s contains duplicate identities\n' "$label" >&2
    return 1
  }
  cmp -s "$expected_sorted" "$observed_sorted" || {
    printf '%s differs from canonical manifest\n' "$label" >&2
    diff -u "$expected_sorted" "$observed_sorted" >&2 || true
    return 1
  }
}

validate_bounded_source_manifest() {
  local expected observed expected_sources observed_sources file tag_file
  expected="$BOUNDED_PROOF_DIR/expected-triples"
  observed="$BOUNDED_PROOF_DIR/observed-source-ids"
  expected_sources="$BOUNDED_PROOF_DIR/expected-source-files"
  observed_sources="$BOUNDED_PROOF_DIR/observed-source-files"
  tag_file="$BOUNDED_PROOF_DIR/source-tags"
  bounded_expected_triples >"$expected"
  bounded_proof_files >"$expected_sources"
  : >"$observed"
  : >"$observed_sources"
  while IFS= read -r -d '' file; do
    : >"$tag_file"
    awk '
      function emit_tag(    line) {
        if (tag !~ /phase32_proof_id:/) return
        if (tag !~ /@tag[[:space:]]+phase32_bounded_proof:[[:space:]]*true/ || tag !~ /phase32_proof_id:[[:space:]]*:[a-z0-9_]+/) {
          print "malformed or unpaired proof tag" > "/dev/stderr"; failed=1; return
        }
        line=tag
        sub(/^.*phase32_proof_id:[[:space:]]*:/, "", line)
        sub(/[^a-z0-9_].*$/, "", line)
        print line
      }
      /@tag[[:space:]]/ { emit_tag(); tag=$0; next }
      tag != "" && /^[[:space:]]+[a-z0-9_]+:/ { tag=tag " " $0; next }
      tag != "" { emit_tag(); tag="" }
      END { emit_tag(); if (failed) exit 2 }
    ' "$file" >"$tag_file" || return 1
    if [[ -s "$tag_file" ]]; then
      printf '%s\n' "${file#"$ROOT_DIR/"}" >>"$observed_sources"
      cat "$tag_file" >>"$observed"
    fi
  done < <(find "$ROOT_DIR/test" -type f -name '*_test.exs' -print0)
  cut -d'|' -f1 "$expected" >"$BOUNDED_PROOF_DIR/expected-source-ids"
  validate_exact_lines "$BOUNDED_PROOF_DIR/expected-source-ids" "$observed" source-proof-ids
  validate_exact_lines "$expected_sources" "$observed_sources" source-proof-files
}

validate_exunit_summary() {
  local summary tests failures expected_count
  summary="$(grep -E '[0-9]+ tests?, [0-9]+ failures?' "$BOUNDED_PROOF_LOG" | tail -n 1 || true)"
  [[ -n "$summary" ]] || { printf 'ExUnit completion summary missing\n' >&2; return 1; }
  tests="$(printf '%s\n' "$summary" | sed -E 's/^([0-9]+) tests?, ([0-9]+) failures?.*/\1/')"
  failures="$(printf '%s\n' "$summary" | sed -E 's/^[0-9]+ tests?, ([0-9]+) failures?.*/\1/')"
  expected_count="$(wc -l <"$BOUNDED_PROOF_DIR/expected-triples" | tr -d ' ')"
  [[ "$tests" == "$expected_count" && "$failures" == "0" ]] || {
    printf 'ExUnit summary mismatch: tests=%s failures=%s expected=%s\n' "$tests" "$failures" "$expected_count" >&2
    return 1
  }
}

run_bounded_mix() {
  local events expected
  BOUNDED_PROOF_DIR="$(mktemp -d "${TMPDIR:-/tmp}/oarlock-phase32-bounded.XXXXXX")"
  BOUNDED_PROOF_EVENTS_FILE="$BOUNDED_PROOF_DIR/runtime-triples"
  BOUNDED_PROOF_LOG="$BOUNDED_PROOF_DIR/mix.log"
  : >"$BOUNDED_PROOF_EVENTS_FILE"
  validate_bounded_source_manifest || return 1
  expected="$BOUNDED_PROOF_DIR/expected-triples"
  bounded_expected_triples | LC_ALL=C sort >"$expected"

  PHASE32_PROOF_EVENTS_FILE="$BOUNDED_PROOF_EVENTS_FILE" \
    run_root_mix --only phase32_bounded_proof $(bounded_proof_files) 2>&1 | tee "$BOUNDED_PROOF_LOG"
  validate_exact_lines "$expected" "$BOUNDED_PROOF_EVENTS_FILE" runtime-proof-triples
  validate_exunit_summary
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

invalidate_full_receipt() {
  FULL_RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
  RECEIPT_PATH="$FULL_RECEIPT_PATH"
  mkdir -p "$EVIDENCE_DIR"
  rm -f "$FULL_RECEIPT_PATH"
}

run_matrix_preflight() {
  # A new full attempt revokes its old local acceptance before any prerequisite can fail.
  invalidate_full_receipt

  [[ -n "$ACCRUE_CHECKOUT" ]] || {
    printf 'ACCRUE_CHECKOUT is required\n' >&2
    return 2
  }
  [[ -f "$ACCRUE_CHECKOUT/accrue/mix.exs" ]] || {
    printf 'ACCRUE_CHECKOUT must contain the tracked accrue/mix.exs project\n' >&2
    return 2
  }
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
  local self_test_dir failure_dir interrupted_dir success_dir preflight_missing_dir preflight_invalid_dir
  local ready_path interrupted_pid receipt_count expected observed
  self_test_dir="$(mktemp -d)"
  trap 'rm -rf "$self_test_dir"' RETURN

  failure_dir="$self_test_dir/failure"
  interrupted_dir="$self_test_dir/interrupted"
  success_dir="$self_test_dir/success"
  preflight_missing_dir="$self_test_dir/preflight-missing"
  preflight_invalid_dir="$self_test_dir/preflight-invalid"
  mkdir -p "$failure_dir" "$interrupted_dir" "$success_dir" "$preflight_missing_dir" "$preflight_invalid_dir"

  BOUNDED_PROOF_DIR="$self_test_dir/proof-validation"
  mkdir -p "$BOUNDED_PROOF_DIR"
  expected="$BOUNDED_PROOF_DIR/expected-triples"
  observed="$BOUNDED_PROOF_DIR/observed-triples"
  bounded_expected_triples >"$expected"
  validate_bounded_source_manifest
  cp "$expected" "$observed"
  validate_exact_lines "$expected" "$observed" self-test-exact

  # Same IDs and count, but swapped test bindings must fail.
  printf '%s\n' 'proof_a|Paddle.Test|first test' 'proof_b|Paddle.Test|second test' >"$expected"
  printf '%s\n' 'proof_a|Paddle.Test|second test' 'proof_b|Paddle.Test|first test' >"$observed"
  if validate_exact_lines "$expected" "$observed" self-test-swapped >/dev/null 2>&1; then
    printf 'Self-test accepted swapped proof-to-test bindings\n' >&2
    return 1
  fi
  printf '%s\n' 'proof_a|Paddle.Test|first test' >"$observed"
  if validate_exact_lines "$expected" "$observed" self-test-missing >/dev/null 2>&1; then
    printf 'Self-test accepted a missing proof identity\n' >&2
    return 1
  fi
  printf '%s\n' 'proof_a|Paddle.Test|first test' 'proof_a|Paddle.Test|first test' >"$observed"
  if validate_exact_lines "$expected" "$observed" self-test-duplicate >/dev/null 2>&1; then
    printf 'Self-test accepted duplicate proof identities\n' >&2
    return 1
  fi
  printf '%s\n' 'proof_a|Paddle.Test|first test' 'proof_c|Paddle.Test|third test' >"$observed"
  if validate_exact_lines "$expected" "$observed" self-test-unexpected >/dev/null 2>&1; then
    printf 'Self-test accepted an unexpected proof identity\n' >&2
    return 1
  fi

  printf '%s\n' 'proof_a|Paddle.Test|first test' 'proof_b|Paddle.Test|second test' >"$expected"
  BOUNDED_PROOF_LOG="$BOUNDED_PROOF_DIR/mix.log"
  printf '2 tests, 0 failures\n' >"$BOUNDED_PROOF_LOG"
  validate_exunit_summary
  for summary in '1 test, 0 failures' '3 tests, 0 failures' '2 tests, 1 failure'; do
    printf '%s\n' "$summary" >"$BOUNDED_PROOF_LOG"
    if validate_exunit_summary >/dev/null 2>&1; then
      printf 'Self-test accepted invalid ExUnit summary: %s\n' "$summary" >&2
      return 1
    fi
  done

  for case_name in preflight-missing preflight-invalid; do
    local case_dir case_checkout
    case_dir="$preflight_missing_dir"
    case_checkout=""
    if [[ "$case_name" == "preflight-invalid" ]]; then
      case_dir="$preflight_invalid_dir"
      case_checkout="$self_test_dir/not-an-accrue-checkout"
      mkdir -p "$case_checkout"
    fi

    EVIDENCE_DIR="$case_dir"
    FULL_RECEIPT_PATH="$EVIDENCE_DIR/phase32-compatibility.receipt"
    RECEIPT_PATH="$FULL_RECEIPT_PATH"
    ACCRUE_CHECKOUT="$case_checkout"
    printf 'phase32_compatibility=passed stale=true\n' >"$FULL_RECEIPT_PATH"

    if run_matrix >/dev/null 2>&1; then
      printf 'Self-test %s full preflight unexpectedly succeeded\n' "$case_name" >&2
      return 1
    fi
    [[ ! -e "$FULL_RECEIPT_PATH" ]] || {
      printf 'Self-test %s preserved a stale full acceptance receipt\n' "$case_name" >&2
      return 1
    }
  done

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

  run_matrix_preflight || return $?
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
proof_count=$(wc -l <"$BOUNDED_PROOF_DIR/expected-triples" | tr -d ' ')
proof_manifest_sha256=$(shasum -a 256 "$BOUNDED_PROOF_DIR/expected-triples" | awk '{print $1}')
$(printf '%s\n' "${ROW_RESULTS[@]}")
SAFE-01=pass dependency resolution and online audit
SAFE-02=pass allowlisted process-owned telemetry isolation
SAFE-03=pass exhaustive Inspect inventory and recursive canaries
SAFE-04=pass total errors bounded reads and one-attempt mutations
SAFE-05=pass secret-safe client construction and request authority
SAFE-06=pass bounded runtime selection, proof counts, and local no-drift evidence"

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
