# Phase 11: Type-Safety Pass - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 11-Type-Safety Pass
**Areas discussed:** Public @spec vocabulary and precision, Dialyzer gate and CI enforcement

---

## Public @spec Vocabulary and Precision

| Option | Description | Selected |
|--------|-------------|----------|
| Broad-first specs | Use simple `binary()`, `map()`, `keyword()`, and generic tagged tuples for fast coverage with low Dialyzer friction. | |
| Balanced public contract types | Use precise aliases and returns at the public seam, with permissive provider/raw-data edges and private implementation flexibility. | ✓ |
| Maximal precision everywhere | Encode literal unions, deep struct fields, and broad `@opaque` use across most values. | |

**User's choice:** Discuss all and produce one-shot recommendations using subagent research, ecosystem comparisons, project prompts, and oarlock's DX goals.

**Notes:** Research recommended the balanced approach. Broad specs would satisfy coverage while missing drift. Maximal specs would be brittle against Paddle provider evolution and raw-data forward compatibility. The selected approach keeps oarlock explicit and typed without pretending Elixir/Dialyzer can statically model every external API detail.

---

## Dialyzer Gate and CI Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Add Dialyzer to existing test job | Minimal workflow change; PLT likely shares broad `_build` cache; no explicit spec-coverage guard. | |
| Separate strict Dialyzer job plus Mix spec-coverage task | Add Dialyxir with committed empty ignore file, stable `priv/plts` cache, dedicated CI job, and reusable `mix typecheck.specs`. | ✓ |
| Broad matrix and heavier lint integration | Run Dialyzer across multiple Elixir/OTP versions and enforce spec coverage through ExUnit or Credo-style checks. | |

**User's choice:** Discuss all and produce one-shot recommendations using subagent research, ecosystem comparisons, project prompts, and oarlock's DX goals.

**Notes:** Research recommended a separate strict job because Phase 11's purpose is to catch type drift before production, not collect advisory warnings. A Mix task is clearer than ExUnit/shell/Credo for a project-specific public-spec coverage rule and is easier for maintainers to run locally.

---

## the agent's Discretion

- Exact type alias placement and naming.
- Exact volatile provider field types, as long as raw/provider edges remain forward-compatible.
- Exact implementation of the `mix typecheck.specs` AST scanner.
- Exact CI cache stanza and job name.
- Opportunistic private specs for hidden modules where they improve Dialyzer quality.

## Deferred Ideas

- Broad Elixir/OTP Dialyzer matrix.
- Credo adoption or a custom Credo check.
- OpenAPI-generated specs or schema validation.
- Phase 12 public documentation examples.
- Public request/command structs for attrs/options.
