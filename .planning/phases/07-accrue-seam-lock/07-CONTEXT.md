# Phase 7: Accrue Seam Lock - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze the Accrue-facing consumer contract for oarlock with one canonical end-to-end seam test and one published seam guide. This phase locks how consumers should depend on the library's public surface and how the project documents stability. It does not add new billing capabilities, new framework integrations, or broader Paddle API coverage.

</domain>

<decisions>
## Implementation Decisions

### Seam test strictness
- **D-01:** The seam test should be a semantic contract test, not a full-fixture equality test.
- **D-02:** The seam test must lock the sequence of public operations and the documented tuple/struct boundary across the full path: customer create, address create, transaction create/get, webhook verify/parse, subscription get, subscription cancel.
- **D-03:** Assertions should focus on published, consumer-relevant guarantees: named public functions, locked struct fields, selected nested typed structs, normalized error/tuple behavior where applicable, and the presence of `raw_data` escape hatches.
- **D-04:** The seam test must not freeze incidental upstream payload trivia, full raw payload equality, undocumented nested map keys, or every optional field returned by Paddle.
- **D-05:** The seam guide is the source of truth for what the seam test is allowed to freeze. If a field or behavior is not documented as part of the supported seam, the seam test should not implicitly promote it into the contract.

### Published contract boundary
- **D-06:** The published seam is closed and enumerated, not namespace-by-convention. Only explicitly named modules, functions, structs, and support types belong to the supported consumer contract.
- **D-07:** The public seam should explicitly include the consumer entry modules already in use: `Paddle.Customers`, `Paddle.Customers.Addresses`, `Paddle.Transactions`, `Paddle.Subscriptions`, and `Paddle.Webhooks`.
- **D-08:** Seam-adjacent support types that consumers reasonably depend on should also be documented explicitly: `Paddle.Client.new!/1`, `%Paddle.Page{}`, `Paddle.Page.next_cursor/1`, and `%Paddle.Error{}`.
- **D-09:** Internal modules and implementation details are not part of the consumer contract even if they are visible in source or generated docs. This includes `Paddle.Http`, `Paddle.Internal.*`, `%Paddle.Client{}` internals such as `req`, and any undocumented helper functions.
- **D-10:** The seam guide should state clearly that undocumented modules, functions, fields, and internal implementation details are outside the supported contract and may change without notice inside the minor series.

### Field tier policy
- **D-11:** Adopt a three-tier field policy for the seam guide: `locked`, `additive`, and `opaque`.
- **D-12:** `locked` applies to typed top-level struct fields, narrow nested typed structs that are part of the documented seam, and other fields consumers may safely pattern-match and depend on.
- **D-13:** `additive` applies only where the documented contract intentionally allows growth without breaking existing meaning. It should not be used as a vague synonym for "forwarded from Paddle."
- **D-14:** `opaque` replaces the current `raw` wording for forwarded provider data whose internal shape is not part of the typed seam. Consumers may inspect it defensively, but must not depend on key-level stability.
- **D-15:** The `:raw_data` field itself is part of the locked seam as an escape hatch, but the contents of `raw_data` are `opaque`.
- **D-16:** `not-planned` is not a field tier. It belongs in scope/deferred language only, not in struct field tables.

### Deferred surface wording
- **D-17:** The public guide should use two high-level exclusion buckets only:
  - `Out of scope for the current 0.x seam` for product/API surfaces that may be added later but are not supported now.
  - `Intentionally excluded from core` for concerns that do not belong in this library's architectural boundary, such as Phoenix/Ecto coupling.
- **D-18:** Avoid public-facing taxonomy like `deferred`, `not in this minor series`, and `not planned` when describing unsupported surface area in the guide. Those terms create unnecessary roadmap promises and vocabulary drift.
- **D-19:** Reserve deprecation language for already-supported public APIs only. Unsupported or excluded surfaces should not be described as deprecated.

### Decision-making preference
- **D-20:** For this project, GSD should prefer decisive, ecosystem-grounded defaults and shift low-level decision-making left into research, planning, and implementation whenever the choice does not materially alter the product direction or public seam.
- **D-21:** Escalate only genuinely high-impact choices to the user: public-contract changes, architectural-boundary shifts, or anything that would meaningfully change Accrue's integration posture.
- **D-22:** Recommendations should stay coherent with idiomatic Elixir library design, least surprise, forward compatibility, strong DX, and the repo's existing "narrow typed seam over broad upstream surface" strategy.

### the agent's Discretion
- Exact wording in `guides/accrue-seam.md`, so long as it preserves the locked decisions above.
- Exact assertion style in `test/paddle/seam_test.exs`, so long as it remains semantic and contract-oriented rather than fixture-ossifying.
- Exact placement of seam-policy notes in README, ExDoc, and inline docs.
- Whether to explicitly add a short glossary in the guide to define `locked`, `additive`, `opaque`, `out of scope`, and `intentionally excluded from core`.

</decisions>

<specifics>
## Specific Ideas

- Treat the seam guide as the canonical published contract and the seam test as the executable proof of that guide.
- Favor ExUnit pattern-matching and targeted assertions over exhaustive struct/map equality; this is the most idiomatic way to lock a narrow Elixir seam without making additive upstream changes look breaking.
- Keep the public contract optimized for library consumers inside Phoenix/Plug/Ecto applications, but do not pull framework coupling into the core SDK itself.
- The project should continue its established strategy: typed top-level entities and a few high-value nested typed structs for ergonomic dot access, with `raw_data` available as the forward-compat escape hatch.
- User preference for this project: shift decision-making left inside GSD and default to strong, coherent recommendations unless the decision is truly consequential to product direction or contract shape.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and active requirement
- `.planning/PROJECT.md` — v1.1 goal, integration-consumer framing, and core architectural constraints.
- `.planning/REQUIREMENTS.md` — `SEAM-01` and `SEAM-02`, plus cross-phase typed-struct and tuple-return constraints.
- `.planning/ROADMAP.md` — Phase 7 goal, planned deliverables, and success criteria.
- `.planning/STATE.md` — Current milestone position and why the seam is being frozen now.
- `.planning/BACKLOG.md` — `B-02` and `B-03` rationale for the seam test and seam guide.

### Prior locked decisions
- `.planning/phases/04-transactions-hosted-checkout/04-CONTEXT.md` — transaction seam curation, selective nested struct promotion, and decisive-defaults posture.
- `.planning/phases/05-subscriptions-management/05-CONTEXT.md` — separate named mutation paths, selective nested struct promotion, and lightweight boundary validation.
- `.planning/phases/06-transactions-retrieval/06-CONTEXT.md` — transaction retrieval seam symmetry, contract-style testing, and explicit Accrue seam posture.

### Existing seam artifacts
- `test/paddle/seam_test.exs` — current end-to-end seam proof and the baseline assertion style to preserve/refine.
- `guides/accrue-seam.md` — current published seam contract guide.
- `mix.exs` — ExDoc extras wiring for the seam guide.
- `README.md` — guide discoverability and consumer-facing entry point.

### Milestone research
- `.planning/research/FEATURES.md` — phase-level deliverable framing for the seam test and seam guide.
- `.planning/research/ARCHITECTURE.md` — placement guidance for the seam artifacts and test organization.
- `.planning/research/PITFALLS.md` — seam-specific failure modes and anti-footguns.
- `.planning/research/STACK.md` — toolchain expectations and reasons not to add new infrastructure.

### Ecosystem references used to lock these decisions
- `https://hexdocs.pm/ex_unit/ExUnit.Assertions.html` — idiomatic Elixir assertion style and pattern-matching expectations.
- `https://hexdocs.pm/ecto/Ecto.Schema.html` — precedent for documenting what is and is not part of a public struct contract.
- `https://hexdocs.pm/plug/Plug.Conn.html` — precedent for documenting stable derived fields without freezing an entire struct blob.
- `https://hexdocs.pm/elixir/library-guidelines.html` — Elixir library documentation and public-API guidance.
- `https://hexdocs.pm/ex_doc/0.32.0/Mix.Tasks.Docs.html` — ExDoc extras/public-guide publication mechanics.
- `https://hexdocs.pm/req/Req.Request.html` — example of a focused public API surface in a modern Elixir HTTP library.
- `https://hexdocs.pm/lattice_stripe/api_stability.html` — Elixir payment-library precedent for explicit API stability framing.
- `https://docs.stripe.com/sdks/versioning` — SDK versioning and contract-language precedent from a major adjacent ecosystem.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/paddle/seam_test.exs` already exercises the exact end-to-end path Phase 7 is meant to freeze.
- `guides/accrue-seam.md` already contains the first-pass consumer contract structure: public modules, locked structs, field tiers, and unsupported areas.
- `mix.exs` already publishes the seam guide through ExDoc extras.
- `README.md` already links consumers to the seam guide.

### Established Patterns
- Public functions take `%Paddle.Client{}` explicitly and return tagged tuples.
- Typed structs lock the ergonomic top-level contract while preserving `raw_data` for forward compatibility.
- Narrow nested typed structs are promoted only when they materially improve consumer ergonomics.
- Prior phases consistently prefer curated public seams over broad upstream mirroring.

### Integration Points
- The seam guide and the seam test must evolve together: guide defines the contract; seam test proves it.
- Any plan work in Phase 7 should audit `guides/accrue-seam.md` and `test/paddle/seam_test.exs` together rather than treating docs and test as separate concerns.
- Future public additions should only become part of the seam after they are documented in the guide and pinned by the appropriate contract tests.

</code_context>

<deferred>
## Deferred Ideas

None beyond the already documented unsupported surface areas. This discussion stayed within the Phase 7 boundary and locked how to present and protect the seam rather than adding new capability.

</deferred>

---

*Phase: 07-accrue-seam-lock*
*Context gathered: 2026-04-29*
