#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCRUE_CHECKOUT="${ACCRUE_CHECKOUT:-}"
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

run_isolated_reader_and_docs() {
  local workspace="$1"
  (
    cd "$workspace"
    MIX_DEPS_PATH="$ROOT_DIR/deps" MIX_BUILD_PATH="$workspace/_build_contract" \
      MIX_ENV=test mix do compile --warnings-as-errors + \
      test --warnings-as-errors test/paddle/seam_test.exs
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

[[ -f "$ACCRUE_CHECKOUT/accrue/mix.exs" ]] || {
  printf 'ACCRUE_CHECKOUT must contain accrue/mix.exs\n' >&2
  exit 2
}

before_diff="$(tracked_diff_fingerprint)"
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
  exit 1
}

run_isolated_reader_and_docs "$reader_one" >"$PROOF_DIR/reader-one.log" 2>&1 &
reader_one_pid=$!
run_isolated_reader_and_docs "$reader_two" >"$PROOF_DIR/reader-two.log" 2>&1 &
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
  exit 1
fi
printf 'Concurrent isolated seam readers and docs builds passed\n'

"$ROOT_DIR/bin/phase32_compatibility.sh" --self-test

run_one="$PROOF_DIR/matrix-one"
run_two="$PROOF_DIR/matrix-two"
mkdir -p "$run_one" "$run_two"

PHASE32_EVIDENCE_DIR="$run_one" ACCRUE_CHECKOUT="$ACCRUE_CHECKOUT" \
  "$ROOT_DIR/bin/phase32_compatibility.sh"
PHASE32_EVIDENCE_DIR="$run_two" ACCRUE_CHECKOUT="$ACCRUE_CHECKOUT" \
  "$ROOT_DIR/bin/phase32_compatibility.sh"

require_one_receipt "$run_one"
require_one_receipt "$run_two"
canonical_receipt_manifest "$run_one/phase32-compatibility.receipt" >"$PROOF_DIR/matrix-one.manifest"
canonical_receipt_manifest "$run_two/phase32-compatibility.receipt" >"$PROOF_DIR/matrix-two.manifest"
cmp -s "$PROOF_DIR/matrix-one.manifest" "$PROOF_DIR/matrix-two.manifest" || {
  printf 'Complete matrix row/verdict manifests differ\n' >&2
  diff -u "$PROOF_DIR/matrix-one.manifest" "$PROOF_DIR/matrix-two.manifest" >&2 || true
  exit 1
}

after_diff="$(tracked_diff_fingerprint)"
[[ "$before_diff" == "$after_diff" ]] || {
  printf 'Tracked repository diff changed during Phase 32 contract proof\n' >&2
  exit 1
}

printf '%s\n' \
  'SAFE-01=pass dependency/package/downstream matrix' \
  'SAFE-02=pass allowlisted attempt telemetry' \
  'SAFE-03=pass Inspect redaction contract' \
  'SAFE-04=pass bounded reads and one-attempt ambiguous mutations' \
  'SAFE-05=pass secret-safe constructor decision table' \
  'SAFE-06=pass docs/types/specs, concurrency, interruption, repeatability, and no drift'
printf 'Phase 32 final contract proof passed with identical complete receipts\n'
