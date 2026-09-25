# Phase 16: Seam Validation & Documentation - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

The newly added entities (Customer Portal Sessions, Adjustments) are explicitly documented and integrated into the Accrue seam contract. This ensures Accrue consumers can safely rely on the newly added structs and functions.

</domain>

<decisions>
## Implementation Decisions

### Test Flow Integration
- **D-01:** Append `Paddle.Customers.PortalSessions.create/3` right after Customer creation in `test/paddle/seam_test.exs`.
- **D-02:** Append `Paddle.Adjustments.create/2` (e.g. full refund or credit) after the Transaction is completed and verified via webhook in `test/paddle/seam_test.exs`.

### Seam Documentation
- **D-03:** Add `Paddle.Customers.PortalSessions` and `Paddle.Adjustments` to the "Public Modules" section in `guides/accrue-seam.md`.
- **D-04:** Document `%Paddle.PortalSession{}` and `%Paddle.Adjustment{}` under "Locked Structs" with standard top-level fields as `locked` and `raw_data` as `locked` (contents `opaque`).

### Claude's Discretion
- Exact placement of the test assertions within the flow.
- Minor formatting choices in `guides/accrue-seam.md`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and locked local decisions
- `.planning/ROADMAP.md` — Phase 16 goal and success criteria.
- `.planning/REQUIREMENTS.md` — Context that Portal Sessions and Adjustments were added in Phases 14 and 15.

### Integration Points
- `guides/accrue-seam.md` — The seam documentation file to be updated.
- `test/paddle/seam_test.exs` — The end-to-end seam test to be updated.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `%Paddle.Client{}`: Used for client creation in tests.
- `client_with_adapter`: Helper in `seam_test.exs` using Req mock responses.

### Established Patterns
- Tests use `decode_json_body` for assertions on request shapes.
- `guides/accrue-seam.md` uses a tiered structure (`locked`, `additive`, `opaque`) for all fields.

### Integration Points
- `guides/accrue-seam.md`
- `test/paddle/seam_test.exs`

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 16-Seam Validation & Documentation*
*Context gathered: 2026-06-09*
