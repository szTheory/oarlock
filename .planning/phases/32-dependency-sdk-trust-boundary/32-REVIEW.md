---
phase: 32-dependency-sdk-trust-boundary
reviewed: 2026-09-11T03:34:43Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - bin/phase32_compatibility.sh
  - bin/phase32_contract_proof.sh
  - lib/paddle/subscriptions.ex
  - test/paddle/http_test.exs
  - test/paddle/seam_test.exs
  - test/paddle/subscriptions_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 32: Code Review Report

**Reviewed:** 2026-09-11T03:34:43Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The receipt-invalidation and duplicate-retry changes are exercised by the supplied tests, but the bounded contract verifier currently certifies evidence it never collects. Its focused test selection is also line-number based and can silently select different tests after ordinary edits. The termination test exists but is not part of either normal proof path.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: [BLOCKER] Bounded verifier certifies docs/specs without executing any docs/spec proof

**File:** `bin/phase32_contract_proof.sh:233-257`
**Issue:** `run_verify/0` runs only `run_bounded_concurrent_readers`, the compatibility self-test, and the bounded compatibility runner, then emits `SAFE-06=pass docs/specs, byte-identical readers, receipt integrity, and no drift`. The docs builder is only invoked by `run_concurrent_readers` at lines 174-194, which `run_verify/0` no longer calls. Its selected seam tests are lines 1008, 1056, and 1073; none checks the public docs or builds documentation. Consequently a broken documentation build or docs/spec regression still produces a passing SAFE-06 receipt, creating false verification evidence.

**Fix:** Add an isolated documentation build (and the relevant docs/spec assertions) to the bounded verifier before setting `VERIFY_COMPLETE`, or remove docs/specs from SAFE-06 until they are actually verified. For example, retain a separate snapshot and invoke `run_isolated_docs_builder` with a failure propagated before receipt staging completes.

## Warnings

### WR-01: [WARNING] Receipt-termination self-test is not executed by normal verification

**File:** `bin/phase32_contract_proof.sh:226-240`
**Issue:** The new `self_test_termination/0` is exposed at lines 276-318, but neither `run_verify/0` nor `run_full/0` invokes it; both invoke only `phase32_compatibility.sh --self-test` (lines 234 and 330). The new seam test at `test/paddle/seam_test.exs:1073-1089` merely searches for strings. Receipt cleanup on termination can therefore regress while the normal verifier still emits SAFE-06 as passing.

**Fix:** Run `"$0" --self-test-termination` from `run_verify/0` (and, if it is part of full-proof receipt integrity, `run_full/0`) before publishing any verifier receipt. Keep the static seam assertion as an additional guard, not the sole execution path.

### WR-02: [WARNING] Bounded proof relies on unstable test line selectors

**File:** `bin/phase32_compatibility.sh:48-60`
**Issue:** Each bounded safety check is addressed as `file:line`. ExUnit accepts a non-matching location and still runs a test (for example, `mix test test/paddle/http_test.exs:99999` completes successfully while running one test). Inserting or moving tests can therefore cause this verifier to exercise a different test while still publishing a passing receipt; no assertion verifies that the intended test names ran.

**Fix:** Give each required proof test a stable, unique ExUnit tag and invoke it with `mix test --only phase32_safe_...`, or put the bounded cases in a dedicated test file. Assert the expected tagged test count before publishing the receipt.

---

_Reviewed: 2026-09-11T03:34:43Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
