# Contributing

Oarlock is an independent Elixir SDK for Paddle Billing. The core library stays
small and provider focused; the Phoenix/Ecto demo is a separate integration
example.

## Choose one bounded change

Open one issue for a reproducible problem or one proposal with a clear outcome.
For a bug, include the smallest example that shows what happened and what you
expected. For a proposal, explain the user need, intended behavior, and scope.
Keep unrelated changes in separate issues and pull requests.

Before opening a pull request, read [the worktree operation guide](docs/worktree-operations.md)
if you are using an isolated task worktree. It explains the manifest and entry
and exit evidence used by this repository.

## Show the proof you ran

Use checks proportionate to the change. Documentation-only changes can include
a rendered or link check when relevant. Changes to transport, security,
optional integrations, the demo, or dependencies should name the relevant tests
and compatibility or security checks that were run.

Local checks describe the checkout you tested. When available, link the hosted
`CI contract` run for the exact candidate commit SHA; a green run for another
SHA is not evidence for this change. State commands and results plainly, and
leave checks you did not run unclaimed.

Issue forms and labels help with intake; they do not decide scope, ownership, or
whether work is accepted. A maintainer records those decisions during triage.
Ownership is not assigned by this guide. The current owner is unknown until a
maintainer records a verified person or team for the work.

## Report a vulnerability

Use the private GitHub security advisory route described in [SECURITY.md](SECURITY.md).
Do not include vulnerability details in a public issue or pull request.
