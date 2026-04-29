# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v1.1** in **`.planning/MILESTONES.md`** — those **v1.x** labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`MILESTONES.md`** as canonical for milestone dates and archive paths.

## [Unreleased]

### Added

* Initial public release of the Paddle Billing SDK for Elixir. See [.planning/milestones/v1.1-ROADMAP.md](.planning/milestones/v1.1-ROADMAP.md) for the v1.1 (Accrue Seam Hardening) feature set: customer/address CRUD, hosted-checkout transaction creation, transaction retrieval by ID, subscription get/list/cancel, pure-function webhook verification, and the locked [`guides/accrue-seam.md`](guides/accrue-seam.md) consumer contract.
