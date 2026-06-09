# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v1.1** in **`.planning/MILESTONES.md`** — those **v1.x** labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`MILESTONES.md`** as canonical for milestone dates and archive paths.

## [0.1.2](https://github.com/szTheory/oarlock/compare/v0.1.1...v0.1.2) (2026-06-09)


### Features

* **08-01:** rename Paddle.Error raw data field ([01f3552](https://github.com/szTheory/oarlock/commit/01f355242d13b20bea369c2993872b3bf1304190))
* **08-02:** normalize transport errors ([c7341ae](https://github.com/szTheory/oarlock/commit/c7341ae78e149d4d6059e487f23bb31e48b5181c))
* **08-03:** add idempotency key support ([9113570](https://github.com/szTheory/oarlock/commit/91135702d03e2effc1980bf2d1249ee66ab2439e))
* **08-04:** enable transient retry policy ([11ccffd](https://github.com/szTheory/oarlock/commit/11ccffd5aeab440be7c2dd4f6f0a5f8192a3105b))
* **09-01:** add resource auto-pagination helpers ([14114af](https://github.com/szTheory/oarlock/commit/14114afc34afeb38bc835538d067262808d748ce))
* **10-01:** lock recurring-start seam coverage ([d15d11e](https://github.com/szTheory/oarlock/commit/d15d11e0750c9a384004fba0e4e44cd7b0a3e3e2))
* **10-02:** implement pause and pause_immediately APIs ([f41ea7a](https://github.com/szTheory/oarlock/commit/f41ea7a4baf34bc0450313a0fa650104355e9299))
* **10-03:** implement resume lifecycle mutation ([a76aa6b](https://github.com/szTheory/oarlock/commit/a76aa6b04ae91579b2d9f843308c040a39227254))
* **11-01:** add public [@type](https://github.com/type) t contracts to the core seam carriers ([0f23e7d](https://github.com/szTheory/oarlock/commit/0f23e7dea6a965d2a6135650047c916fd75424bb))
* **11-01:** add shared helper specs and keep the seam behavior unchanged ([8fd70c5](https://github.com/szTheory/oarlock/commit/8fd70c595ea19534fbb6a0d9c9ced3430b10a30e))
* **11-02:** spec customer, address, and transaction resource functions ([d695965](https://github.com/szTheory/oarlock/commit/d695965b3357171ef3ea2ad055adc52b0082c061))
* **11-02:** spec subscription and webhook resource functions ([f84831d](https://github.com/szTheory/oarlock/commit/f84831dd7139661ef337ee66f67df89bd18c7141))
* **11-03:** implement Mix.Tasks.Typecheck.Specs as public-seam gate ([75b2e43](https://github.com/szTheory/oarlock/commit/75b2e43f458867ee2605b8e3e1c0f05a1cc0b412))
* **13-process-guard-01:** create git hook and installer scripts ([5f67421](https://github.com/szTheory/oarlock/commit/5f67421b718204ac661a78cdb2b06dc800d19700))
* **13-process-guard-01:** integrate process guard into CI ([fa3419c](https://github.com/szTheory/oarlock/commit/fa3419c242d03b0ffed60bb576d5b4b2ac11f639))
* **13-process-guard-01:** wire hook distribution into mix.exs ([825ecc5](https://github.com/szTheory/oarlock/commit/825ecc5bcdaeb19958829562a216a21b6e6c3da7))


### Bug Fixes

* **11:** revise plans based on checker feedback ([31fc41f](https://github.com/szTheory/oarlock/commit/31fc41f6d4f9bd6821864df4c7d1d439c7717b72))
* **12-02:** escape string interpolation in Client moduledoc ([21e1c63](https://github.com/szTheory/oarlock/commit/21e1c638c5c1ab8b6c123bfed8de3fa2e29e4adc))
* **phase-10:** address subscription lifecycle review findings ([c58a77f](https://github.com/szTheory/oarlock/commit/c58a77fc19be82519ea9221650ffc3a2b7a5f49a))

## [Unreleased]

### Breaking Changes

* **`%Paddle.Error{}`**: Field `:raw` renamed to `:raw_data` for consistency with all other locked structs (every `Paddle.Customer`/`Paddle.Address`/`Paddle.Transaction`/`Paddle.Subscription`/etc. already uses `:raw_data` as the documented forward-compat escape hatch). Pattern matches against `%Paddle.Error{raw: r}` will silently miss after this change — update them to `%Paddle.Error{raw_data: r}`. (See `.planning/phases/08-reliability-primitives/08-CONTEXT.md` D-01..D-05 for rationale.)

### Added

* **PAGE-01 auto-pagination helpers**: `Paddle.Subscriptions.stream/2`, `Paddle.Subscriptions.all/2`, `Paddle.Customers.Addresses.stream/3`, and `Paddle.Customers.Addresses.all/3` iterate list endpoints across Paddle pages while preserving the existing `list/2` and `list/3` `{:ok, %Paddle.Page{}}` return shapes. Stream helpers are lazy and may raise during later-page enumeration; eager `all/*` helpers return `{:error, reason}` without partial results on the first failed page.
* **`%Paddle.Error{}`**: New `:network_error?` field (boolean, defaults to `false`) — to be populated by `from_transport/1` in a follow-up plan.
* **`%Paddle.Error{}`**: New `:retryable?` field (boolean, defaults to `false`) — advisory class predicate populated by `from_transport/1` in a follow-up plan.
* **`from_transport/1`**: New public constructor that maps `%Req.TransportError{}` into a normalized `%Paddle.Error{}` with `:network_error?: true`, `:retryable?: true`, and a stable `:type` taxonomy (`"network_timeout"`, `"network_nxdomain"`, `"network_closed"`, `"network_unknown"`). Public resource calls now return `{:error, %Paddle.Error{network_error?: true, ...}}` for transport failures instead of leaking the raw `%Req.TransportError{}` to consumers — Accrue and other consumers can now pattern-match on a single error shape across both HTTP and transport failures. (REL-03)
* **Idempotency-Key support on every `create/*` POST**: `Paddle.Customers.create/3`, `Paddle.Customers.Addresses.create/4`, and `Paddle.Transactions.create/3` accept an optional `idempotency_key:` opt that is forwarded as the `Idempotency-Key` HTTP header. Callers (e.g., Accrue's Oban-job retry layer) supply a deterministic per-attempt key like `"accrue:job:#{job_id}:attempt:#{attempt}"`; the SDK does NOT auto-generate keys (see `.planning/phases/08-reliability-primitives/08-CONTEXT.md` D-06/D-07 for rationale). `nil`, empty-string, whitespace-only, or non-binary values raise `ArgumentError`. Locked v1.2 opts vocabulary on every public function: `:idempotency_key` (POSTs only) and `:retry` (boolean). (REL-01)
* **Automatic retry policy on `Paddle.Client.new!/1`**: Configures `req` with `retry: :transient` (retries on 429, 500, 502, 503, 504, and transport errors with `:reason in [:timeout, :econnrefused, :closed]`) and `max_retries: 3`. `Retry-After` headers are honored on 429 and 503 responses; otherwise exponential backoff (1s, 2s, 4s) is used. Per-call override: pass `retry: false` to disable retry for a single call (e.g., `Paddle.Customers.create(client, attrs, retry: false)`); omitted/`true` inherits client policy. The locked v1.2 opts vocabulary on every public function is `:idempotency_key` (POSTs only) and `:retry` (boolean) — `:max_retries`, `:retry_delay`, `:retry_log_level`, `:timeout` are NOT exposed as public opts (see `.planning/phases/08-reliability-primitives/08-CONTEXT.md` D-19/D-20). (REL-02)
* Docs: rewrite the README for cold-start adopters and add [`guides/getting-started.md`](guides/getting-started.md), a JTBD/user-flow guide for the current Paddle integration path.

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
