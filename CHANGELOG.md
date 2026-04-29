# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v1.1** in **`.planning/MILESTONES.md`** — those **v1.x** labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`MILESTONES.md`** as canonical for milestone dates and archive paths.

## [0.1.1](https://github.com/szTheory/oarlock/compare/v0.1.0...v0.1.1) (2026-04-29)


### Bug Fixes

* stay in 0.x for breaking changes (bump-minor-pre-major: false) ([c73b71b](https://github.com/szTheory/oarlock/commit/c73b71bc9a7c94ebdaa6874cc23865fe835d47ee))

## 0.1.0 (2026-04-29)


### Features

* **01-01:** implement paddle error mapping ([7cfbf37](https://github.com/szTheory/oarlock/commit/7cfbf378beac5be9f3483529151f0f90f5f20106))
* **01-01:** implement paddle page ([8a83bd2](https://github.com/szTheory/oarlock/commit/8a83bd2d3f2ca443a0c0f28c0570f906d6066af0))
* **01-01:** initialize mix project skeleton ([0471190](https://github.com/szTheory/oarlock/commit/04711906fd58df8a04a6a09da24582e7bbb63f24))
* **01-02:** emit paddle request telemetry ([da1f40b](https://github.com/szTheory/oarlock/commit/da1f40b751ecd286e1332796ba72b53c60eac033))
* **01-02:** implement paddle client ([23c4067](https://github.com/szTheory/oarlock/commit/23c40672c3b05a56d91cc5e07f6b60c0668179c9))
* **01-03:** implement http execution boundary ([4a07f51](https://github.com/szTheory/oarlock/commit/4a07f519c77da05a212b462857c3ce6d058b035b))
* **02-01:** add webhook event envelope contract ([e58d148](https://github.com/szTheory/oarlock/commit/e58d1487e7831c55c45784628cad1403409b54bb))
* **02-01:** implement webhook event parsing ([22ba539](https://github.com/szTheory/oarlock/commit/22ba539baf0d2826547b7c928be8fed57eb20ea9))
* **02-02:** implement webhook signature verification ([bb6bd61](https://github.com/szTheory/oarlock/commit/bb6bd61b4acdf29328d8be1fd539f1d0de0455ca))
* **03-01:** add customer entity contract ([3f1f063](https://github.com/szTheory/oarlock/commit/3f1f0632da779f0d7f1d5b6249067b36be6a5506))
* **03-01:** implement customer resource functions ([b72706f](https://github.com/szTheory/oarlock/commit/b72706f32b9856305c155c00953d0ecdbb49a978))
* **03-02:** add address entity contract ([3588180](https://github.com/szTheory/oarlock/commit/3588180ebdc3afd5b0dc4883ffdc18d4740f3d1c))
* **03-02:** add customer-scoped address resource ([518390c](https://github.com/szTheory/oarlock/commit/518390cc39206ff66202a918cdfb693efaa72886))
* **03-03:** implement customer address listing ([db996c0](https://github.com/szTheory/oarlock/commit/db996c0ce067d8620fa245bf02156c65202cc214))
* **04-01:** implement Paddle.Transaction and Paddle.Transaction.Checkout struct modules ([61a9b6a](https://github.com/szTheory/oarlock/commit/61a9b6ab461c2952441e53a0838b765207dcd69c))
* **04-02:** implement Paddle.Transactions.create/2 strict hosted-checkout path ([c0026d4](https://github.com/szTheory/oarlock/commit/c0026d439175092a402306b3950b7a4a6c65882a))
* **05-01:** implement Paddle.Subscription entity and nested struct modules ([e1d67dc](https://github.com/szTheory/oarlock/commit/e1d67dc74371b2118e6fe2f9a8aac60b9d8f02f3))
* **05-02:** implement Paddle.Subscriptions resource module ([4b4ea76](https://github.com/szTheory/oarlock/commit/4b4ea7674aaeb689653c24a170217cc74d664aad))
* **07-02:** hide internal modules from generated docs surface ([49f8f39](https://github.com/szTheory/oarlock/commit/49f8f3907761dcdaf51dc9b7e03cc4255b9364a6))
* add Hex package metadata to mix.exs ([f269837](https://github.com/szTheory/oarlock/commit/f269837a6a21f2d2384c11fea4317abe4e1462fb))


### Bug Fixes

* **04:** WR-01 validate quantity is positive integer in normalize_item/1 ([23efa59](https://github.com/szTheory/oarlock/commit/23efa59ead0536a1726075f444fd5857338909c5))
* **04:** WR-02 treat checkout: nil as omitted optional parameter ([aca0765](https://github.com/szTheory/oarlock/commit/aca076590de91230a8a3ffeec69986aeb83857b5))
* **04:** WR-03 type-check custom_data and reject non-map values ([3b8ba58](https://github.com/szTheory/oarlock/commit/3b8ba589db282863fe7fd01687f73f4dbac45ca8))
* **04:** WR-04 extract shared attr normalization to Paddle.Internal.Attrs ([78d312e](https://github.com/szTheory/oarlock/commit/78d312ebd60b2c4a69c12eb4698093826ec15a4d))
* **06-01:** commit Paddle.Transactions.get/2 implementation ([813438d](https://github.com/szTheory/oarlock/commit/813438d61250ab165c374b918da7789ea67cbfdf))
* baseline release-please manifest at 0.0.0 ([a49e9e5](https://github.com/szTheory/oarlock/commit/a49e9e50a3c7c78a29a85bf34c1378e9c4cffebd))
* **phase-02:** reject malformed webhook signature segments ([534b8b2](https://github.com/szTheory/oarlock/commit/534b8b29bf214da7979303f21443b723001f4e1b))
* **phase-03:** encode resource path ids ([c011262](https://github.com/szTheory/oarlock/commit/c011262e74f6a4145fbfa3c1b77d5a881deeeae0))
* pin first release to 0.1.0 via release-as ([546467b](https://github.com/szTheory/oarlock/commit/546467b1b2a55b59329b31131c7e8296971a0c90))
* set Hex package name to oarlock in package/0 ([a69d8e7](https://github.com/szTheory/oarlock/commit/a69d8e7e21e53b5b3dc315d5499acfbe0365c66d))

## [Unreleased]

### Added

* Initial public release of the Paddle Billing SDK for Elixir. See [.planning/milestones/v1.1-ROADMAP.md](.planning/milestones/v1.1-ROADMAP.md) for the v1.1 (Accrue Seam Hardening) feature set: customer/address CRUD, hosted-checkout transaction creation, transaction retrieval by ID, subscription get/list/cancel, pure-function webhook verification, and the locked [`guides/accrue-seam.md`](guides/accrue-seam.md) consumer contract.
