---
phase: 30
slug: close-gap-docs-02-proof-02-demo-checkout-handoff-proof
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-25
---

# Phase 30 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser to AdminLive event | Authenticated user clicks LiveView controls that initiate external Paddle handoffs. | Authenticated UI event |
| AdminLive to MockServer | Demo server sends transaction and portal-session requests to the configured Paddle base URL. | Demo customer/address/item attrs; portal customer ID |
| Paddle-style webhook to demo endpoint | Signed webhook raw body crosses into Phoenix and updates local demo state. | Raw webhook body and Paddle signature |
| Public docs to adopter expectations | Adopters rely on README and demo runbook language to understand what proof exists. | Proof-boundary claims |
| Evidence ledger to future GSD planning | Future agents use `.planning/EVIDENCE.md` to decide whether DOCS-02/PROOF-02 are closed. | Requirement evidence |
| Local proof to hosted CI status | Local command output does not automatically prove GitHub-hosted CI status. | Local SHA and CI status claim |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-30-01 | Tampering | `DemoWeb.AdminLive.Index.handle_event("subscribe_now", ...)` | mitigate | LiveView test asserts `open_checkout` contains the MockServer checkout URL returned through `Paddle.Transactions.create/3`; demo passes SDK-valid customer/address/items/custom_data attrs. | closed |
| T-30-02 | Spoofing | Portal action for active subscription | mitigate | LiveView test authenticates through `/auth/login`, seeds active state for `mock-merchant-123`, asserts the portal button exists, and asserts external redirect to the MockServer portal URL. | closed |
| T-30-03 | Information Disclosure | Demo UI | mitigate | UI copy exposes only `Start checkout` and `Manage billing`; implementation and proof-boundary details live in docs/evidence. | closed |
| T-30-04 | Elevation of Privilege | Core SDK dependency boundary | mitigate | No root SDK dependency or framework boundary changes were made; all Phoenix/Ecto/LiveView work remains under `demo/`. | closed |
| T-30-05 | Repudiation | `.planning/EVIDENCE.md` | mitigate | Evidence rows cite Phase 30 artifacts, exact local proof command, MockServer URLs, and hosted CI caveat. | closed |
| T-30-06 | Spoofing | Public docs proof language | mitigate | Demo README and evidence use deterministic MockServer-backed wording and avoid sandbox/live provider-state claims. | closed |
| T-30-07 | Information Disclosure | Evidence artifacts | mitigate | Evidence stores concise command/status/caveat text only; no raw CI logs were committed. | closed |
| T-30-08 | Tampering | Core SDK boundary in docs | mitigate | Docs continue to state Phoenix/Ecto/webhook inbox/UI state are demo-owned and not SDK-owned framework features. | closed |
| T-30-SC | Tampering | package installs | accept | No package-manager installs were performed; package legitimacy checkpoint not required. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-30-01 | T-30-SC | No package installs or dependency changes occurred in this phase. | GSD executor | 2026-06-25 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-25 | 9 | 9 | 0 | Codex inline verifier |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-25
