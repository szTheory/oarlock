# API Coverage — GitHub collaboration operations

The Phase 35 API surface is the GitHub repository collaboration state used by contributor security routing and the read-only triage audit. The SDK's Paddle API surface is unchanged. Decisions below cover the phase-relevant GitHub operations; other GitHub product APIs are outside the Phase 35 requirement boundary.

| capability | decision | reason |
|---|---|---|
| List open issues with complete pagination, including PR issue identities | INTEGRATE | |
| Read every open item's issue comments with complete pagination | INTEGRATE | |
| Read a triage comment author's repository permission | INTEGRATE | |
| Read private vulnerability reporting status | INTEGRATE | |
| Enable private vulnerability reporting when disabled and admin access permits | INTEGRATE | |
| Read repository identity and current viewer permission | INTEGRATE | |
| Read or create the compact kind labels used by issue forms | INTEGRATE | |
| Read and enable vulnerability alerts | INTEGRATE | |
| Read and enable Dependabot security updates | INTEGRATE | |
| Post dated triage decision comments | OPT-OUT | Scope/owner/action require maintainer judgment and the assistant has no authorization to communicate those decisions for the maintainer; Plan 05 requests the smallest human comment action. |
| Assign or close an issue or PR from the audit | OPT-OUT | D-07 requires read-only audit and forbids guessed assignment or automatic closure. |
| Remove or edit historical triage comments | OPT-OUT | D-06 requires durable dated history; corrections use a new maintainer comment. |

The API scope was checked on 2026-09-26 UTC. GitHub's [repository endpoints](https://docs.github.com/en/rest/repos/repos) document GET and PUT for private vulnerability reporting; the live GET returned `enabled:false` during planning. Plans require a new enabled readback before publishing the private route.
