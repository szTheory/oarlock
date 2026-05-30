---
phase: 10-subscriptions-surface-completion
reviewed: 2026-05-30T15:04:46Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - lib/paddle/subscriptions.ex
  - test/paddle/subscriptions_test.exs
  - test/paddle/subscription_test.exs
  - test/paddle/transactions_test.exs
  - test/paddle/seam_test.exs
  - guides/getting-started.md
  - guides/accrue-seam.md
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---
# Phase 10: Code Review Report

**Reviewed:** 2026-05-30T15:04:46Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed all scoped Phase 10 source/docs/tests with a correctness and security-first pass, including new `resume/3` logic and seam guidance. No exploitable security flaws were found, but two quality/contract defects were found that should be fixed before release documentation is treated as authoritative.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `resume/3` raises a pause-specific error message

**File:** `lib/paddle/subscriptions.ex:132`
**Issue:** `reject_idempotency_key!/1` is reused by both pause and resume flows, but the raised message says `"idempotency_key is not supported for pause operations; only retry is supported"`. Calling `Paddle.Subscriptions.resume/3` with `idempotency_key:` raises a misleading pause-only message, which is an API ergonomics defect and makes caller diagnostics inaccurate.
**Fix:**
```elixir
defp reject_idempotency_key!(opts, operation) do
  if Keyword.has_key?(opts, :idempotency_key) do
    raise ArgumentError,
          "idempotency_key is not supported for #{operation} operations; only retry is supported"
  else
    :ok
  end
end

# pause path
reject_idempotency_key!(remaining, "pause")

# resume path
reject_idempotency_key!(remaining, "resume")
```

### WR-02: Getting-started guide contradicts implemented subscription lifecycle surface

**File:** `guides/getting-started.md:273`
**Issue:** The guide still claims oarlock does not own `"Direct subscription pause/resume flows"`, but Phase 10 implemented and documented `Paddle.Subscriptions.pause/3`, `pause_immediately/3`, and `resume/3` (also reflected in `guides/accrue-seam.md`). This creates a contract contradiction across first-party docs and can lead integrators to skip supported lifecycle APIs.
**Fix:** Update the “does not try to own” list to remove pause/resume exclusion and replace it with a narrower statement that direct *subscription creation* is intentionally absent while lifecycle mutations are supported via the documented `Paddle.Subscriptions` calls.

---

_Reviewed: 2026-05-30T15:04:46Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
