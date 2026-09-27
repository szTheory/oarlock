#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCRUE_CHECKOUT="${ACCRUE_CHECKOUT:-}"
EVIDENCE_DIR="${PHASE32_EVIDENCE_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/oarlock-phase32-evidence}"
VERIFY_RECEIPT_PATH="$EVIDENCE_DIR/phase32-contract-verifier.receipt"
PROOF_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/oarlock-phase32-contract.XXXXXX")"
VERIFY_RECEIPT_CANDIDATE=""
VERIFY_COMPLETE=0

cleanup() {
  rm -rf "$PROOF_DIR"
}

discard_verifier_receipt() {
  if [[ -n "$VERIFY_RECEIPT_CANDIDATE" ]]; then
    rm -f "$VERIFY_RECEIPT_CANDIDATE"
  fi
  rm -f "$VERIFY_RECEIPT_PATH"
}

finalize_verifier_receipt() {
  local status="$1"
  trap - EXIT INT TERM

  if [[ "$status" == "0" && "$VERIFY_COMPLETE" == "1" && -f "$VERIFY_RECEIPT_CANDIDATE" ]]; then
    mv "$VERIFY_RECEIPT_CANDIDATE" "$VERIFY_RECEIPT_PATH"
  elif [[ "$status" != "0" || -n "$VERIFY_RECEIPT_CANDIDATE" ]]; then
    discard_verifier_receipt
  fi

  cleanup
  exit "$status"
}

trap 'finalize_verifier_receipt $?' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

tracked_diff_fingerprint() {
  local snapshot
  snapshot="$(mktemp "$PROOF_DIR/tracked-diff.XXXXXX")"
  git -C "$ROOT_DIR" diff --binary --no-ext-diff HEAD -- >"$snapshot"
  git -C "$ROOT_DIR" diff --binary --no-ext-diff --cached HEAD -- >>"$snapshot"
  shasum -a 256 "$snapshot" | awk '{print $1}'
}

snapshot_contract() {
  local archive="$PROOF_DIR/contract.tar"
  local paths="$PROOF_DIR/tracked-paths"

  git -C "$ROOT_DIR" ls-files -z >"$paths"
  if ! git -C "$ROOT_DIR" ls-files --error-unmatch bin/phase32_contract_proof.sh >/dev/null 2>&1; then
    printf '%s\0' bin/phase32_contract_proof.sh >>"$paths"
  fi
  if ! git -C "$ROOT_DIR" ls-files --error-unmatch test/support/phase32_proof_formatter.ex >/dev/null 2>&1; then
    printf '%s\0' test/support/phase32_proof_formatter.ex >>"$paths"
  fi

  tar -C "$ROOT_DIR" --null -T "$paths" -cf "$archive"
  printf '%s\n' "$archive"
}

input_manifest() {
  local workspace="$1"
  (
    cd "$workspace"
    find . -type f -not -path './_build_contract/*' -print0 |
      LC_ALL=C sort -z |
      xargs -0 shasum -a 256
  )
}

run_isolated_seam_reader() {
  local workspace="$1"
  (
    cd "$workspace"
    MIX_DEPS_PATH="$ROOT_DIR/deps" MIX_BUILD_PATH="$workspace/_build_contract" \
      MIX_ENV=test mix do compile --warnings-as-errors + \
      test --warnings-as-errors test/paddle/seam_test.exs
  )
}

expected_docs_proof_triples() {
  cat <<'EOF'
safe_06_public_contract_docs|Paddle.SeamTest|test public documentation pins the secure dependency and runtime migration contract
safe_06_address_stream_docs|Paddle.SeamTest|test address stream documentation matches direct elements and raised enumeration failures
safe_06_compiled_docs_types_specs|Paddle.SeamTest|test compiled docs types and specs agree with the Phase 32 decision tables
EOF
}

validate_proof_triples() {
  local expected="$1" observed="$2" expected_sorted observed_sorted
  expected_sorted="$PROOF_DIR/expected-proof-triples.$RANDOM"
  observed_sorted="$PROOF_DIR/observed-proof-triples.$RANDOM"
  LC_ALL=C sort "$expected" >"$expected_sorted"
  LC_ALL=C sort "$observed" >"$observed_sorted"
  local expected_count observed_count
  expected_count="$(wc -l <"$expected_sorted" | tr -d ' ')"
  observed_count="$(wc -l <"$observed_sorted" | tr -d ' ')"
  [[ "$expected_count" == "$observed_count" ]] || {
    printf 'Proof event count differs from expected manifest: expected=%s observed=%s\n' \
      "$expected_count" "$observed_count" >&2
    cat "$observed_sorted" >&2 || true
    return 1
  }
  [[ "$(uniq -d "$observed_sorted" | wc -l | tr -d ' ')" == "0" ]] || {
    printf 'Duplicate runtime proof event identity\n' >&2
    return 1
  }
  cmp -s "$expected_sorted" "$observed_sorted" || {
    printf 'Runtime proof identities differ from canonical manifest\n' >&2
    diff -u "$expected_sorted" "$observed_sorted" >&2 || true
    return 1
  }
}

validate_docs_spec_summary() {
  local log="$1" summary tests failures
  summary="$(grep -E '[0-9]+ tests?, [0-9]+ failures?' "$log" | tail -n 1 || true)"
  [[ -n "$summary" ]] || { printf 'Docs/spec ExUnit completion summary missing\n' >&2; return 1; }
  tests="$(printf '%s\n' "$summary" | sed -E 's/^([0-9]+) tests?, ([0-9]+) failures?.*/\1/')"
  failures="$(printf '%s\n' "$summary" | sed -E 's/^[0-9]+ tests?, ([0-9]+) failures?.*/\1/')"
  [[ "$tests" == "3" && "$failures" == "0" ]] || {
    printf 'Docs/spec ExUnit summary mismatch: tests=%s failures=%s expected=3\n' \
      "$tests" "$failures" >&2
    return 1
  }
}

run_isolated_bounded_seam_reader() {
  local workspace="$1" events="$PROOF_DIR/docs-proof-events"
  rm -f "$events"
  (
    cd "$workspace"
    PHASE32_PROOF_EVENTS_FILE="$events" MIX_DEPS_PATH="$ROOT_DIR/deps" \
      MIX_BUILD_PATH="$workspace/_build_contract" MIX_ENV=test \
      mix do compile --warnings-as-errors + test --warnings-as-errors \
      --only phase32_bounded_docs_spec test/paddle/seam_test.exs
  )
}

run_isolated_docs_builder() {
  local workspace="$1"
  (
    cd "$workspace"
    MIX_DEPS_PATH="$ROOT_DIR/deps" MIX_BUILD_PATH="$workspace/_build_contract" \
      MIX_ENV=dev mix docs
  )
}

canonical_receipt_manifest() {
  local receipt="$1"
  awk '
    /^phase32_compatibility=passed$/ { print }
    /^rows=[0-9]+$/ { print }
    /^[a-z][a-z0-9-]*=[0-9]+s$/ { sub(/=[0-9]+s$/, "=passed"); print }
  ' "$receipt"
}

require_one_receipt() {
  local evidence_dir="$1"
  local count
  count="$(find "$evidence_dir" -maxdepth 1 -type f -name 'phase32-compatibility.receipt' | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] || {
    printf 'Expected one atomic compatibility receipt in %s, found %s\n' "$evidence_dir" "$count" >&2
    return 1
  }
}

stage_verifier_receipt() {
  mkdir -p "$EVIDENCE_DIR"
  rm -f "$VERIFY_RECEIPT_PATH"
  VERIFY_RECEIPT_CANDIDATE="$(mktemp "$EVIDENCE_DIR/.phase32-contract-verifier.receipt.XXXXXX")"
}

write_verifier_receipt() {
  local content="$1"
  printf '%s\n' "$content" >"$VERIFY_RECEIPT_CANDIDATE"
}

run_bounded_concurrent_readers() {
  local archive reader_one reader_two reader_one_pid reader_two_pid
  local reader_one_status reader_two_status

  archive="$(snapshot_contract)"
  reader_one="$PROOF_DIR/bounded-reader-one"
  reader_two="$PROOF_DIR/bounded-reader-two"
  mkdir -p "$reader_one" "$reader_two"
  tar -C "$reader_one" -xf "$archive"
  tar -C "$reader_two" -xf "$archive"

  input_manifest "$reader_one" >"$PROOF_DIR/bounded-reader-one.inputs"
  input_manifest "$reader_two" >"$PROOF_DIR/bounded-reader-two.inputs"
  cmp -s "$PROOF_DIR/bounded-reader-one.inputs" "$PROOF_DIR/bounded-reader-two.inputs" || {
    printf 'Bounded isolated reader inputs are not byte-identical\n' >&2
    return 1
  }

  expected_docs_proof_triples >"$PROOF_DIR/docs-proof-expected"
  run_isolated_docs_builder "$reader_one" >"$PROOF_DIR/bounded-docs.log" 2>&1 &
  reader_one_pid=$!
  run_isolated_bounded_seam_reader "$reader_two" >"$PROOF_DIR/bounded-seam.log" 2>&1 &
  reader_two_pid=$!

  reader_one_status=0
  reader_two_status=0
  wait "$reader_one_pid" || reader_one_status=$?
  wait "$reader_two_pid" || reader_two_status=$?

  if [[ "$reader_one_status" != "0" || "$reader_two_status" != "0" ]]; then
    printf 'Bounded docs/spec readers failed: docs=%s specs=%s\n' \
      "$reader_one_status" "$reader_two_status" >&2
    printf '%s\n' '--- isolated docs build ---' >&2
    tail -n 80 "$PROOF_DIR/bounded-docs.log" >&2
    printf '%s\n' '--- isolated docs/spec tests ---' >&2
    tail -n 80 "$PROOF_DIR/bounded-seam.log" >&2
    return 1
  fi

  if ! validate_docs_spec_summary "$PROOF_DIR/bounded-seam.log"; then
    tail -n 80 "$PROOF_DIR/bounded-seam.log" >&2
    return 1
  fi
  if ! validate_proof_triples "$PROOF_DIR/docs-proof-expected" "$PROOF_DIR/docs-proof-events"; then
    printf '%s\n' '--- isolated docs/spec test output ---' >&2
    tail -n 80 "$PROOF_DIR/bounded-seam.log" >&2
    return 1
  fi
  printf 'Bounded isolated docs build and exact docs/spec proof triples passed\n'
}

run_concurrent_readers() {
  local archive reader_one reader_two reader_one_pid reader_two_pid
  local reader_one_status reader_two_status

  archive="$(snapshot_contract)"
  reader_one="$PROOF_DIR/reader-one"
  reader_two="$PROOF_DIR/reader-two"
  mkdir -p "$reader_one" "$reader_two"
  tar -C "$reader_one" -xf "$archive"
  tar -C "$reader_two" -xf "$archive"

  input_manifest "$reader_one" >"$PROOF_DIR/reader-one.inputs"
  input_manifest "$reader_two" >"$PROOF_DIR/reader-two.inputs"
  cmp -s "$PROOF_DIR/reader-one.inputs" "$PROOF_DIR/reader-two.inputs" || {
    printf 'Isolated contract snapshots are not byte-identical\n' >&2
    return 1
  }

  run_isolated_seam_reader "$reader_one" >"$PROOF_DIR/reader-one.log" 2>&1 &
  reader_one_pid=$!
  run_isolated_docs_builder "$reader_two" >"$PROOF_DIR/reader-two.log" 2>&1 &
  reader_two_pid=$!

  reader_one_status=0
  reader_two_status=0
  wait "$reader_one_pid" || reader_one_status=$?
  wait "$reader_two_pid" || reader_two_status=$?

  if [[ "$reader_one_status" != "0" || "$reader_two_status" != "0" ]]; then
    printf 'Concurrent reader/build failed: reader-one=%s reader-two=%s\n' \
      "$reader_one_status" "$reader_two_status" >&2
    printf '%s\n' '--- reader one ---' >&2
    tail -n 80 "$PROOF_DIR/reader-one.log" >&2
    printf '%s\n' '--- reader two ---' >&2
    tail -n 80 "$PROOF_DIR/reader-two.log" >&2
    return 1
  fi

  printf 'Concurrent isolated seam reader and docs build passed\n'
}

require_verifier_receipt() {
  local evidence_dir="$1"
  local receipt="$evidence_dir/phase32-verifier.receipt"
  local count
  count="$(find "$evidence_dir" -maxdepth 1 -type f -name 'phase32-verifier.receipt' | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] || {
    printf 'Expected one atomic verifier receipt in %s, found %s\n' "$evidence_dir" "$count" >&2
    return 1
  }

  grep -qx 'phase32_verifier=passed' "$receipt"
  for safe_id in SAFE-01 SAFE-02 SAFE-03 SAFE-04 SAFE-05 SAFE-06; do
    grep -q "^${safe_id}=pass " "$receipt" || {
      printf 'Verifier receipt is missing %s\n' "$safe_id" >&2
      return 1
    }
  done
  grep -qx 'proof_count=14' "$receipt" || {
    printf 'Verifier receipt is missing the exact bounded proof count\n' >&2
    return 1
  }
  grep -Eq '^proof_manifest_sha256=[a-f0-9]{64}$' "$receipt" || {
    printf 'Verifier receipt is missing the bounded proof manifest digest\n' >&2
    return 1
  }
}

safe_verdicts() {
  printf '%s\n' \
    'SAFE-01=pass fresh dependency and audit evidence' \
    'SAFE-02=pass process-owned telemetry concurrency and canaries' \
    'SAFE-03=pass per-module inventory and recursive Inspect canaries' \
    'SAFE-04=pass total errors bounded reads and one-attempt ambiguous mutations' \
    'SAFE-05=pass secret-safe constructor and request authority boundary' \
    'SAFE-06=pass docs/specs, byte-identical readers, receipt integrity, and no drift'
}

run_verify() {
  local before_diff after_diff compatibility_dir receipt_body proof_count proof_manifest_sha256
  stage_verifier_receipt
  before_diff="$(tracked_diff_fingerprint)"

  # bounded verifier evidence remains subordinate to full D-03 acceptance and
  # establishes no hosted, sandbox, live-provider, release, or publication authority.
  run_bounded_concurrent_readers
  "$ROOT_DIR/bin/phase32_compatibility.sh" --self-test

  compatibility_dir="$PROOF_DIR/compatibility-verifier"
  mkdir -p "$compatibility_dir"
  PHASE32_MIX_BUILD_PATH="$PROOF_DIR/bounded-mix-build" \
    PHASE32_EVIDENCE_DIR="$compatibility_dir" ACCRUE_CHECKOUT="$ACCRUE_CHECKOUT" \
    "$ROOT_DIR/bin/phase32_compatibility.sh" --verify
  require_verifier_receipt "$compatibility_dir"
  proof_count="$(sed -n 's/^proof_count=//p' "$compatibility_dir/phase32-verifier.receipt")"
  proof_manifest_sha256="$(sed -n 's/^proof_manifest_sha256=//p' "$compatibility_dir/phase32-verifier.receipt")"

  after_diff="$(tracked_diff_fingerprint)"
  [[ "$before_diff" == "$after_diff" ]] || {
    printf 'Tracked repository diff changed during bounded Phase 32 contract proof\n' >&2
    return 1
  }

  receipt_body="phase32_contract_verifier=passed
commit=$(git -C "$ROOT_DIR" rev-parse HEAD)
completed_at=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
tracked_diff_sha256=$after_diff
proof_count=$proof_count
proof_manifest_sha256=$proof_manifest_sha256
compatibility_receipt_sha256=$(shasum -a 256 "$compatibility_dir/phase32-verifier.receipt" | awk '{print $1}')
$(safe_verdicts)"
  write_verifier_receipt "$receipt_body"
  VERIFY_COMPLETE=1
  safe_verdicts
  printf 'Phase 32 bounded contract verifier passed\n'
  printf 'Verifier receipt: %s\n' "$VERIFY_RECEIPT_PATH"
  printf 'This bounded verifier evidence does not replace full D-03 acceptance.\n'
}

pause_after_candidate() {
  [[ -n "${PHASE32_CANDIDATE_READY:-}" ]] || {
    printf 'PHASE32_CANDIDATE_READY is required\n' >&2
    return 2
  }

  stage_verifier_receipt
  : >"$PHASE32_CANDIDATE_READY"
  while [[ ! -f "${PHASE32_CANDIDATE_READY}.release" ]]; do
    sleep 0.05
  done
}

self_test_termination() {
  local self_test_dir evidence_dir ready_path child_pid child_status
  self_test_dir="$(mktemp -d)"
  evidence_dir="$self_test_dir/evidence"
  ready_path="$self_test_dir/candidate-ready"
  mkdir -p "$evidence_dir"
  printf 'phase32_contract_verifier=passed stale=true\n' >"$evidence_dir/phase32-contract-verifier.receipt"

  PHASE32_EVIDENCE_DIR="$evidence_dir" PHASE32_CANDIDATE_READY="$ready_path" \
    "$0" --pause-after-candidate >/dev/null 2>&1 &
  child_pid=$!

  while [[ ! -f "$ready_path" ]]; do
    kill -0 "$child_pid" 2>/dev/null || {
      printf 'Termination self-test child exited before candidate readiness\n' >&2
      rm -rf "$self_test_dir"
      return 1
    }
    sleep 0.05
  done

  kill -TERM "$child_pid"
  child_status=0
  wait "$child_pid" || child_status=$?
  [[ "$child_status" != "0" ]] || {
    printf 'Termination self-test child unexpectedly exited zero\n' >&2
    rm -rf "$self_test_dir"
    return 1
  }
  [[ ! -e "$evidence_dir/phase32-contract-verifier.receipt" ]] || {
    printf 'Termination self-test preserved a passing receipt\n' >&2
    rm -rf "$self_test_dir"
    return 1
  }
  if find "$evidence_dir" -maxdepth 1 -type f -name '.phase32-contract-verifier.receipt.*' | grep -q .; then
    printf 'Termination self-test preserved a staged receipt candidate\n' >&2
    rm -rf "$self_test_dir"
    return 1
  fi

  rm -rf "$self_test_dir"
  printf 'Phase 32 contract receipt termination self-test passed\n'
}

run_full() {
  local before_diff after_diff run_one run_two

  [[ -f "$ACCRUE_CHECKOUT/accrue/mix.exs" ]] || {
    printf 'ACCRUE_CHECKOUT must contain accrue/mix.exs\n' >&2
    return 2
  }

  before_diff="$(tracked_diff_fingerprint)"
  run_concurrent_readers
  "$ROOT_DIR/bin/phase32_compatibility.sh" --self-test

  run_one="$PROOF_DIR/matrix-one"
  run_two="$PROOF_DIR/matrix-two"
  mkdir -p "$run_one" "$run_two"

  PHASE32_EVIDENCE_DIR="$run_one" ACCRUE_CHECKOUT="$ACCRUE_CHECKOUT" \
    "$ROOT_DIR/bin/phase32_compatibility.sh" --full
  PHASE32_EVIDENCE_DIR="$run_two" ACCRUE_CHECKOUT="$ACCRUE_CHECKOUT" \
    "$ROOT_DIR/bin/phase32_compatibility.sh" --full

  require_one_receipt "$run_one"
  require_one_receipt "$run_two"
  canonical_receipt_manifest "$run_one/phase32-compatibility.receipt" >"$PROOF_DIR/matrix-one.manifest"
  canonical_receipt_manifest "$run_two/phase32-compatibility.receipt" >"$PROOF_DIR/matrix-two.manifest"
  cmp -s "$PROOF_DIR/matrix-one.manifest" "$PROOF_DIR/matrix-two.manifest" || {
    printf 'Complete matrix row/verdict manifests differ\n' >&2
    diff -u "$PROOF_DIR/matrix-one.manifest" "$PROOF_DIR/matrix-two.manifest" >&2 || true
    return 1
  }

  after_diff="$(tracked_diff_fingerprint)"
  [[ "$before_diff" == "$after_diff" ]] || {
    printf 'Tracked repository diff changed during Phase 32 contract proof\n' >&2
    return 1
  }

  safe_verdicts
  printf 'Phase 32 final contract proof passed with identical complete receipts\n'
}

case "${1:-}" in
  --verify)
    run_verify
    ;;
  --full)
    run_full
    ;;
  --self-test-termination)
    self_test_termination
    ;;
  --pause-after-candidate)
    pause_after_candidate
    ;;
  *)
    printf 'Usage: %s --verify|--full|--self-test-termination\n' "${0##*/}" >&2
    exit 2
    ;;
esac
