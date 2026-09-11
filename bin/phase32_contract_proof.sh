#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCRUE_CHECKOUT="${ACCRUE_CHECKOUT:-}"
EVIDENCE_DIR="${PHASE32_EVIDENCE_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/oarlock-phase32-evidence}"
VERIFY_RECEIPT_PATH="$EVIDENCE_DIR/phase32-contract-verifier.receipt"
PROOF_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/oarlock-phase32-contract.XXXXXX")"

cleanup() {
  rm -rf "$PROOF_DIR"
}
trap cleanup EXIT INT TERM

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

publish_receipt() {
  local content="$1"
  local receipt_tmp
  mkdir -p "$EVIDENCE_DIR"
  receipt_tmp="$(mktemp "$EVIDENCE_DIR/.phase32-contract-verifier.receipt.XXXXXX")"
  trap 'rm -f "${receipt_tmp:-}"' RETURN
  printf '%s\n' "$content" >"$receipt_tmp"
  mv "$receipt_tmp" "$VERIFY_RECEIPT_PATH"
  trap - RETURN
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
  local before_diff after_diff compatibility_dir receipt_body
  before_diff="$(tracked_diff_fingerprint)"
  rm -f "$VERIFY_RECEIPT_PATH"

  # bounded verifier evidence remains subordinate to full D-03 acceptance and
  # establishes no hosted, sandbox, live-provider, release, or publication authority.
  run_concurrent_readers
  "$ROOT_DIR/bin/phase32_compatibility.sh" --self-test

  compatibility_dir="$PROOF_DIR/compatibility-verifier"
  mkdir -p "$compatibility_dir"
  PHASE32_EVIDENCE_DIR="$compatibility_dir" ACCRUE_CHECKOUT="$ACCRUE_CHECKOUT" \
    "$ROOT_DIR/bin/phase32_compatibility.sh" --verify
  require_verifier_receipt "$compatibility_dir"

  after_diff="$(tracked_diff_fingerprint)"
  [[ "$before_diff" == "$after_diff" ]] || {
    printf 'Tracked repository diff changed during bounded Phase 32 contract proof\n' >&2
    return 1
  }

  receipt_body="phase32_contract_verifier=passed
commit=$(git -C "$ROOT_DIR" rev-parse HEAD)
completed_at=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
tracked_diff_sha256=$after_diff
compatibility_receipt_sha256=$(shasum -a 256 "$compatibility_dir/phase32-verifier.receipt" | awk '{print $1}')
$(safe_verdicts)"
  publish_receipt "$receipt_body"
  safe_verdicts
  printf 'Phase 32 bounded contract verifier passed\n'
  printf 'Verifier receipt: %s\n' "$VERIFY_RECEIPT_PATH"
  printf 'This bounded verifier evidence does not replace full D-03 acceptance.\n'
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
  *)
    printf 'Usage: %s --verify|--full\n' "${0##*/}" >&2
    exit 2
    ;;
esac
