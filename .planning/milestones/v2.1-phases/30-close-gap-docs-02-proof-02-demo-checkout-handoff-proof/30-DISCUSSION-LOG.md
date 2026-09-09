# Phase 30: Close gap: DOCS-02/PROOF-02 - demo checkout handoff proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 30-close-gap-docs-02-proof-02-demo-checkout-handoff-proof
**Areas discussed:** Demo proof target, Test evidence depth, Documentation patch scope, Handoff boundary language

---

## Demo Proof Target

| Option | Description | Selected |
|--------|-------------|----------|
| Current PhoenixTest smoke | Keep the existing demo test as mostly "does not crash" proof for checkout and portal. | |
| Strengthened MockServer-backed handoff proof | Prove checkout event URL, signed webhook state update, and portal redirect deterministically. | ✓ |
| Browser-level JS proof | Add Playwright/Wallaby to exercise the client checkout hook in a browser. | |
| Live Paddle sandbox proof | Add credential-backed provider-state checkout/webhook proof. | |

**User's choice:** Discuss all and produce one expert recommendation set.
**Notes:** Research converged on strengthened deterministic demo proof. Browser
proof and live Paddle proof are useful only for separate future proof classes.

---

## Test Evidence Depth

| Option | Description | Selected |
|--------|-------------|----------|
| PhoenixTest only | Preserve one high-level user-flow test. | |
| PhoenixTest plus targeted LiveViewTest | Keep readable flow coverage and add direct `push_event` / redirect assertions. | ✓ |
| Unit-only handlers | Test `subscribe_now` and `open_portal` with narrow handler assertions only. | |
| Full E2E browser suite | Test UI and JS hook as a browser would. | |

**User's choice:** Discuss all and produce one expert recommendation set.
**Notes:** PhoenixTest is good for narrative user flow, but the checkout gap is
specifically the handoff artifact. LiveViewTest is the idiomatic tool for direct
push-event and redirect assertions.

---

## Documentation Patch Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Planning evidence only | Update `.planning/EVIDENCE.md` and phase verification artifacts. | ✓ |
| Minimal public docs patch | Update `demo/README.md` or related docs only if current wording no longer matches proof. | ✓ |
| Broad docs refresh | Rework README, Getting Started, demo README, and changelog. | |
| Public CI status docs | Put hosted CI run status or links in public docs. | |

**User's choice:** Discuss all and produce one expert recommendation set.
**Notes:** Canonical proof belongs in `.planning/EVIDENCE.md`; detailed run
evidence belongs in Phase 30 verification/summary. Public docs should remain
stable and adopter-focused, not CI-log bookkeeping.

---

## Handoff Boundary Language

| Option | Description | Selected |
|--------|-------------|----------|
| Subscription-creation language | Describe the UI as creating or editing subscriptions directly. | |
| Provider-native handoff language | Describe checkout and portal as Paddle-hosted handoffs created on demand. | ✓ |
| Heavy implementation explanation in UI | Put raw-body, Ecto, and provider-state caveats directly in the demo UI. | |
| Hide all caveats | Make the demo feel seamless and avoid trust-boundary wording. | |

**User's choice:** Discuss all and produce one expert recommendation set.
**Notes:** Use "Start checkout" / "Continue to Paddle Checkout" and "Manage
billing" / "Open Paddle portal." Keep implementation details in docs, not the
operational demo UI.

---

## Claude's Discretion

- Exact test module split is left to the planner.
- Exact public-doc patch size is left to the planner after inspecting current
  wording.
- Exact microcopy is flexible if it remains calm, precise, provider-native, and
  aligned with the newer Oarlock brand book.

## Deferred Ideas

- Browser-level checkout JS proof.
- Live Paddle sandbox/provider-state CI.
- Optional Plug/Phoenix helpers or companion integration package.
- Full billing UX kit, admin panel, route installer, migrations, or local billing
  mirror.
