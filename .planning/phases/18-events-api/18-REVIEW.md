---
phase: 18-events-api
reviewed: 2026-06-10T14:00:00Z
depth: deep
files_reviewed: 2
files_reviewed_list:
  - lib/paddle/events.ex
  - test/paddle/events_test.exs
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: issues_found
---

# Phase 18: Code Review Report

**Reviewed:** 2026-06-10T14:00:00Z
**Depth:** deep
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The `Paddle.Events` API wrapper provides the necessary endpoints for retrieving and streaming events. The test suite is also well constructed for happy paths. However, there is a systemic pattern-matching flaw in the HTTP response handling that can lead to silent propagation of structurally invalid data or internal process crashes. Additionally, unnecessary code duplication exists that could be addressed by leveraging shared `Pagination` helper functions.

## Critical Issues

### CR-01: Missing `else` block in `with` statements causes malformed response leaks and stream crashes

**File:** `lib/paddle/events.ex:27-31`
**Issue:** The `with` blocks in `get/2`, `list/2`, and `next_page/2` pattern match against specific, expected payload shapes (e.g., `{:ok, %{"data" => data}} when is_map(data)`). Because there is no `else` block, if `Http.request` returns a successful 2xx response but with a different body shape (like `{:ok, %{}}` or an error payload missing `"data"`), the match simply fails and the `with` block returns the non-matching value (`{:ok, %{}}`). 
1. In `get/2` and `list/2`, this violates the `@spec` and returns structurally invalid data disguised as success, bypassing caller error handling completely.
2. In `stream/2` and `all/2`, returning `{:ok, %{}}` instead of the expected `{:ok, %Page{}}` tuple causes the internal `Paddle.Internal.Pagination.handle_page_result/2` state machine to crash with a `FunctionClauseError`.

**Fix:**
Add an `else` block to catch unmatched `{:ok, map}` responses and convert them into proper `{:error, reason}` tuples. Ensure expected errors are safely propagated.

```elixir
  def get(%Client{} = client, event_id) do
    with :ok <- validate_event_id(event_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, event_path(event_id)) do
      {:ok, Http.build_struct(Event, data)}
    else
      {:ok, unexpected_payload} -> {:error, {:invalid_response, unexpected_payload}}
      error -> error
    end
  end
```
*(Apply similar `else` blocks to `list/2` and `next_page/2`, if `next_page/2` is retained.)*

## Warnings

### WR-01: Redundant duplication of `Pagination.next_page/3`

**File:** `lib/paddle/events.ex:83-91`
**Issue:** The private functions `next_page/2` and `build_page/2` in `Paddle.Events` are exact duplicates of the shared `Paddle.Internal.Pagination.next_page/3` and `build_page/3` logic. Maintaining duplicate internal pagination logic requires maintaining identical bug fixes (like the `else` block fix above) across multiple endpoints, creating technical debt.
**Fix:** Remove `next_page/2` and `build_page/2` entirely. Delegate directly to `Pagination.next_page/3` inside `stream/2` and `all/2`:

```elixir
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> Pagination.next_page(client, Event, path) end
    )
  end
```

## Info

### IN-01: Missing failure test coverage for API interactions

**File:** `test/paddle/events_test.exs`
**Issue:** The test suite thoroughly covers parameter validation and successful API responses, but it lacks coverage for API failure states (e.g., HTTP 404/500 errors) or structurally invalid successful payloads. Expanding this test surface would have automatically flagged the `with` block bugs.
**Fix:** Add test cases simulating HTTP errors and malformed JSON payloads to verify they safely return `{:error, reason}` without unexpectedly crashing the client process.
