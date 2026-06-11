---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Offline Mode & Advanced Billing
status: planning
last_updated: "2026-06-11T12:00:00.000Z"
last_activity: 2026-06-11
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

**Core Value**: A production-quality, idiomatic Elixir SDK for Paddle Billing (`paddle_sdk`) serving as a pure, standalone foundation for Accrue's "second processor" strategy.
**Current Focus**: Delivering v2.0 (Offline Mode & Advanced Billing) - establishing an isolated testing mode without hitting the real Paddle sandbox and building complex upgrade/downgrade logic.

## Current Position

Phase: Pre-Planning
Plan: —
Status: Scoping Requirements
Last activity: Archived Milestone v1.5

### Progress

Phase 25: TBD [....................] 0%

## Performance Metrics

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|

- Requirement Coverage: 0/2 mapped (0%)
- Success Criteria: 0 defined
- Current Milestone: v2.0

## Accumulated Context

### Architectural Decisions

- Strict adherence to the `req` HTTP client.
- Explicit passing of `%Paddle.Client{}`.
- Rely on built-in Elixir `Stream` for auto-pagination.
- Strictly map JSON responses to explicit typed structs with `:raw_data` escape hatches.
- Reuse existing `%Paddle.Event{}` for the Events REST API.
- Followed strict CRUD pattern without domain-specific verbs (e.g., notification settings).
- **Milestone v1.5:** The demo app is isolated in `/demo` as a path dependency; explicitly avoided Umbrella Apps for SDK demo structure.

### Known Technical Debt / Blockers

- Deferred for future: Create/Update/Delete operations for Products/Prices, Subscriptions mutations, Refunds, and Connect/Marketplace.

### Todos

- Draft the requirements for the next milestone (v2.0) and generate a new Roadmap.

## Session Continuity

- Archived v1.5. Created clean slates for `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` targeting v2.0.
- Ready to begin `.planning/ROADMAP.md` creation for v2.0.
