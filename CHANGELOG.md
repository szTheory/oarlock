# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.x/v2.x** in `.planning/` — those labels describe shipped tranches of work, **not** a second installable version axis on Hex. This repo remains **0.x** on Hex until a real **1.0.0** release.

## [0.1.3](https://github.com/szTheory/oarlock/compare/v0.1.2...v0.1.3) (2026-09-26)


### Bug Fixes

* **35-06:** close reviewed triage and worktree gaps ([889d091](https://github.com/szTheory/oarlock/commit/889d091def2dd9e62c92f1e7401ab10d387cc77e))
* close Phase 35 review gaps ([8905feb](https://github.com/szTheory/oarlock/commit/8905febdb55342aa07590bf6c108b079a1e12af0))

## [0.1.2](https://github.com/szTheory/oarlock/compare/v0.1.1...v0.1.2) (2026-09-25)


### Features

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
* **14-01:** define Paddle.PortalSession struct ([3f735d1](https://github.com/szTheory/oarlock/commit/3f735d1f08613a2c709113937147d05c540a84d7))
* **14-01:** implement Paddle.Customers.PortalSessions.create/3 ([67ace72](https://github.com/szTheory/oarlock/commit/67ace7270b51187bacf106244724194a38118639))
* **15-01:** create Paddle.Adjustment struct ([71e01bf](https://github.com/szTheory/oarlock/commit/71e01bf744f99cd3767717772c3d88b2220ae062))
* **15-01:** implement Paddle.Adjustments API ([f834dc0](https://github.com/szTheory/oarlock/commit/f834dc0a7953bb5338e045f29f4d244a3773bef2))
* **17-01:** implement Paddle.Product struct ([ee079d2](https://github.com/szTheory/oarlock/commit/ee079d2df723ccf74721a4d67cc40f2a8eb06dbb))
* **17-01:** implement Paddle.Products API wrapper ([fe4c39e](https://github.com/szTheory/oarlock/commit/fe4c39e6da8515c6ab5d34fc5039dee315a6f8ef))
* **17-02:** add Paddle.Price struct and tests ([edf3338](https://github.com/szTheory/oarlock/commit/edf3338af56c280ce7b26e23d666b9158cbf6a7f))
* **17-02:** implement Paddle.Prices API wrapper ([13626b2](https://github.com/szTheory/oarlock/commit/13626b2c5691712a59f3af719d7de33ef3d4d844))
* **18-01:** implement Paddle.Events API ([a5988d0](https://github.com/szTheory/oarlock/commit/a5988d0daf566c806f7ea273c4fffb82e1cf89a0))
* **19-01:** define NotificationSetting struct ([c54d18a](https://github.com/szTheory/oarlock/commit/c54d18a071c31b81f9583ab4a9cebcc97ff4407d))
* **19-01:** implement Read Operations for NotificationSettings ([f159aac](https://github.com/szTheory/oarlock/commit/f159aacc702e0712f8e9422bf55400c357e9a123))
* **19-02:** implement create, update, delete for NotificationSettings ([f634e9c](https://github.com/szTheory/oarlock/commit/f634e9c60783b38798d745e74f1dd9ab59a49b5a))
* **26-01:** add subscription update endpoints to MockServer ([bc4ff92](https://github.com/szTheory/oarlock/commit/bc4ff92324c31faf005e899e84f6ba476a0d8c1b))
* **26-01:** implement update/3 for subscriptions ([8dba7d0](https://github.com/szTheory/oarlock/commit/8dba7d0ea2b10ff6887dba8ee87db442afad11f5))
* **28-01:** gate mock server optional deps ([5c2efa5](https://github.com/szTheory/oarlock/commit/5c2efa5e5f44ce6d1f0e77b910a752700d27f170))
* **28-02:** add CI proof jobs ([da3c967](https://github.com/szTheory/oarlock/commit/da3c967356ff32cf9c37c956eda6bacb8426cb5b))
* **28-02:** add package smoke helper ([349dbae](https://github.com/szTheory/oarlock/commit/349dbae09a52f57b5cee55a42538d7a8a3068922))
* **30-01:** prove demo checkout and portal handoffs ([d9b80aa](https://github.com/szTheory/oarlock/commit/d9b80aa0e9dc324c60da59bfbc028787dd33c523))
* **31-01:** expand inventory across hostile worktree state ([26ebdbb](https://github.com/szTheory/oarlock/commit/26ebdbbafdf490627561904933e5fb885da29a37))
* **31-01:** implement read-only repository inventory tracer ([331123c](https://github.com/szTheory/oarlock/commit/331123c690a243e5253fb2388ddb0b981bf10ff8))
* **31-02:** enforce canonical planning authority ([f5cd8df](https://github.com/szTheory/oarlock/commit/f5cd8dfca0969ccf7608a077641eedf7e6f15b2f))
* **31-02:** validate completion and snapshot integrity ([2b26760](https://github.com/szTheory/oarlock/commit/2b26760ca63bdaaba5e8178fb0a5496be4a36b00))
* **31-03:** reconcile immutable milestone history ([8cf8bf1](https://github.com/szTheory/oarlock/commit/8cf8bf12549f0e02c2b1bd6ad6744983916a3ed6))
* **31-03:** validate milestone history identities ([231b897](https://github.com/szTheory/oarlock/commit/231b89738b0ffdec741da0bdad242d9cd31a17e0))
* **31-04:** bound planning authority reads to repository ([a921db9](https://github.com/szTheory/oarlock/commit/a921db9845088a1dfa26d56c88c9de170d64ba4a))
* **31-04:** fail closed on unsafe ownership registry ([32fadfb](https://github.com/szTheory/oarlock/commit/32fadfb8086d83e75aca199bf7a3fd6f68fbd06a))
* **31-05:** bind completion proof to canonical phase ([9b04a64](https://github.com/szTheory/oarlock/commit/9b04a640c625bb768186808a2c245d03ea9be5eb))
* **31-05:** compare milestone phase ranges exactly ([76a1575](https://github.com/szTheory/oarlock/commit/76a15752fcd9293701c915918774cd82ee998b24))
* **31-05:** fail closed on Git identity collection ([2f77566](https://github.com/szTheory/oarlock/commit/2f775664fc09dda1557b756f7cc02b985a422276))
* **31-08:** enforce base-to-head planning history integrity ([348fbb7](https://github.com/szTheory/oarlock/commit/348fbb783d1e1c5cfbfeac5811c17f0081381b2d))
* **31-09:** add required planning truth lane ([0733c28](https://github.com/szTheory/oarlock/commit/0733c28c87c015d1ebace889677fbeb1e2c68919))
* **31-09:** bind planning truth to exact-SHA CI proof ([8c02ecf](https://github.com/szTheory/oarlock/commit/8c02ecf57c313f8e1eb66dbc08f096303c78ed18))
* **32-03:** redact client capability state ([c082b25](https://github.com/szTheory/oarlock/commit/c082b256fddee384993b84392ec62b9bac4f33b8))
* **32-03:** validate explicit client construction ([6afcc79](https://github.com/szTheory/oarlock/commit/6afcc79af31b0edfd879b35a31780d69f539f244))
* **32-04:** enforce bounded safe-read retry policy ([458d0fb](https://github.com/szTheory/oarlock/commit/458d0fb98173e4c2c44a0196773f5283c52103c7))
* **32-04:** surface non-retryable mutation ambiguity ([8503e7a](https://github.com/szTheory/oarlock/commit/8503e7ae263acc11f81e70a7ec63dad4e1b3556e))
* **32-05:** harden adjustment and customer requests ([1608b13](https://github.com/szTheory/oarlock/commit/1608b13ab3d7b8a19f3fb25c0c2ffb8b33d59db6))
* **32-05:** harden customer address requests ([d93edbe](https://github.com/szTheory/oarlock/commit/d93edbe3fa9350d54d3cc33e2df916623e9dcab2))
* **32-05:** unify portal session request safety ([0c73115](https://github.com/szTheory/oarlock/commit/0c73115ddf70fd4dc406971e810388d66c30d02d))
* **32-06:** harden event and product reads ([da24002](https://github.com/szTheory/oarlock/commit/da2400274df119174f9c3b846461b88aaceea78b))
* **32-06:** harden price and notification requests ([e4a9423](https://github.com/szTheory/oarlock/commit/e4a94232cfafa40d5193601ca022837f66d9485b))
* **32-07:** harden subscription lifecycle requests ([65d19c0](https://github.com/szTheory/oarlock/commit/65d19c08eb213ae4a8534662a8c65ce0617bd0f7))
* **32-07:** harden transactions and pagination ([fc2b97d](https://github.com/szTheory/oarlock/commit/fc2b97dbf7dde04d5198c137d321780748192b48))
* **32-08:** complete telemetry safety contract ([599682a](https://github.com/szTheory/oarlock/commit/599682aa0e3f13567a9420098080e676ab832846))
* **32-08:** emit safe telemetry per attempt ([7a4ba68](https://github.com/szTheory/oarlock/commit/7a4ba68440f9cc1837dc9481df2af73d3ae21632))
* **32-09:** protect management and checkout inspection ([5ea6d1c](https://github.com/szTheory/oarlock/commit/5ea6d1c7cbf49f7d04b804fdc5ee330ac6eb98db))
* **32-09:** protect notification and portal inspection ([6554e46](https://github.com/szTheory/oarlock/commit/6554e46dbf6f82f4bac6ab2704ff487d2a52a50b))
* **32-10:** certify evidence-honest final compatibility contract ([b400cc4](https://github.com/szTheory/oarlock/commit/b400cc4d0c476cd399e2a90df1a5aa92fd7ee41f))
* **32-12:** close remaining mutation option paths ([4dbb20e](https://github.com/szTheory/oarlock/commit/4dbb20e3ab807e1b696f318948c33ba7f4a200b9))
* **32-12:** contain customer mutation request options ([4d9a070](https://github.com/szTheory/oarlock/commit/4d9a07064890177d9cf4832c3ff9c212c06b21b9))
* **32-12:** guard adjustment and subresource mutations ([d35843d](https://github.com/szTheory/oarlock/commit/d35843dd107050b6aee63ab822a0238d40af9c80))
* **32-13:** add exhaustive inventory and bounded proof receipts ([38f42ac](https://github.com/szTheory/oarlock/commit/38f42acfc0beeb826c238de1a2c630a27c0c0aa2))
* **32-15:** reject duplicate pause retry options ([1def022](https://github.com/szTheory/oarlock/commit/1def022c5763ab0dbe02b52bea58d9d8118b919f))
* **32-15:** reject duplicate resume retry options ([9e21494](https://github.com/szTheory/oarlock/commit/9e214944e67acab11a45ad1d4efe29dbd948de29))
* **33-01:** verify hosted proof artifacts ([e2629e7](https://github.com/szTheory/oarlock/commit/e2629e764e99f38dc5129509f8df09284878657a))
* **33-01:** write durable exact-SHA CI proof ([08ece53](https://github.com/szTheory/oarlock/commit/08ece534b3451db3a5e6c827a2d01c91127e3c27))
* **33-02:** add required quality checks ([d57127a](https://github.com/szTheory/oarlock/commit/d57127af634968b4beb32f0e6f3388a144e9da7e))
* **33-02:** verify quality lane in CI evidence ([1d26850](https://github.com/szTheory/oarlock/commit/1d26850ab46a397893ac9a9721fc92abbed67e48))
* **demo:** add e2e integration testing pipeline for phase 24 ([8818fb2](https://github.com/szTheory/oarlock/commit/8818fb2043405282a5c4e7afa70e9c0ed551acce))
* **demo:** integrate paddle checkout and webhooks for phase 22 ([26fb162](https://github.com/szTheory/oarlock/commit/26fb162be358c32b69d37a9f3b4f33a6ad5a9f5c))
* **demo:** integrate paddle customer portal and lifecycle webhooks for phase 23 ([11154b7](https://github.com/szTheory/oarlock/commit/11154b70a0664704cf42c1b3c4e7b468267b69e9))
* **demo:** scaffold ui and mock auth for phase 21 ([5c697a7](https://github.com/szTheory/oarlock/commit/5c697a7befcaabf00454ff49a199b95726313cba))
* **sdk:** build Paddle.MockServer for standalone offline testing ([01b519f](https://github.com/szTheory/oarlock/commit/01b519f4f2ea2124534240e4ba1f6b259a4f15fc))


### Bug Fixes

* **11:** revise plans based on checker feedback ([31fc41f](https://github.com/szTheory/oarlock/commit/31fc41f6d4f9bd6821864df4c7d1d439c7717b72))
* **12-02:** escape string interpolation in Client moduledoc ([21e1c63](https://github.com/szTheory/oarlock/commit/21e1c638c5c1ab8b6c123bfed8de3fa2e29e4adc))
* **19:** revise plans based on checker feedback ([3ddac06](https://github.com/szTheory/oarlock/commit/3ddac06a65778ca6427d3ffc602b001d1536601b))
* **27:** revise plan based on checker feedback ([4623a21](https://github.com/szTheory/oarlock/commit/4623a212d0b7bd311a0d9fb17f91d4d9f4076920))
* **28:** cite decision coverage in plans ([c9ee890](https://github.com/szTheory/oarlock/commit/c9ee890d4c73a54208c1c19fc5e01db2ef7fac77))
* **28:** resolve plan checker artifacts ([684c66f](https://github.com/szTheory/oarlock/commit/684c66fcaa9912b873355c2ff7897e725fb1a107))
* **28:** satisfy hosted CI proof gates ([c511da6](https://github.com/szTheory/oarlock/commit/c511da6977da808e85dcc58c017c083bd675999c))
* **29:** revise plan 03 dependency order ([b909e6a](https://github.com/szTheory/oarlock/commit/b909e6a3b1d9136cbfe7468dc44e3f13a2b6af90))
* **29:** revise planning artifacts from checker feedback ([932d4c1](https://github.com/szTheory/oarlock/commit/932d4c19f50a65699331ed6bc8b73fca5257986d))
* **30:** revise checkout proof plans ([dd8fd6c](https://github.com/szTheory/oarlock/commit/dd8fd6c022df65618e470b9070ac2574ce324ca8))
* **31-08:** keep tag and peeled SHA diagnostics independent ([426c916](https://github.com/szTheory/oarlock/commit/426c916daac5980d1ae10912846c09dd0c3ae687))
* **31:** CR-01 enforce byte-prefix evidence appends ([d9fe54a](https://github.com/szTheory/oarlock/commit/d9fe54a7aec678828b0fb78afa11d8bb2fe4cb1f))
* **31:** CR-01 reject duplicate STATE routing ([d0747fe](https://github.com/szTheory/oarlock/commit/d0747fe292a10ea01b0fc7306df61ccdf627b6ec))
* **31:** CR-01 reject failing completion evidence ([c4db46d](https://github.com/szTheory/oarlock/commit/c4db46d7289ffcdeb3e57cbb03611292ec0c2eb0))
* **31:** CR-01 validate bijective requirement mappings ([a8f7608](https://github.com/szTheory/oarlock/commit/a8f76085b9930db9fba05547c1122be21a23f6fe))
* **31:** CR-02 bind requirements to active milestone ([f115fd7](https://github.com/szTheory/oarlock/commit/f115fd704cbfe29b00ca62ce76d1d696dd4de1af))
* **31:** CR-02 fail closed on evidence read errors ([b5ef67f](https://github.com/szTheory/oarlock/commit/b5ef67f90a64ef1935f32ac0708fd02947c4223f))
* **31:** CR-02 reject ambiguous proof statuses ([f9439ac](https://github.com/szTheory/oarlock/commit/f9439acda3ff2de8b613917bd6a47ee3272d2cc5))
* **31:** CR-02 reject invalid ownership claims ([a3fb40b](https://github.com/szTheory/oarlock/commit/a3fb40b503db1ec3a67e12b674fc3411501dcfac))
* **31:** CR-03 bind archive links to milestones ([79ea2d8](https://github.com/szTheory/oarlock/commit/79ea2d86debacdca894def1cded835482d7f2946))
* **31:** CR-03 reject duplicate plan declarations ([2fabd74](https://github.com/szTheory/oarlock/commit/2fabd74bd643850f55eb00446f23cee5a9839454))
* **31:** CR-03 scope linked dirty claims by worktree ([56f24a3](https://github.com/szTheory/oarlock/commit/56f24a37f86191426cf18d9d6683ce5d8263cca4))
* **31:** CR-03 strengthen snapshot content identity ([ca19237](https://github.com/szTheory/oarlock/commit/ca19237bad307fc374ea38e61c50dab957213633))
* **31:** CR-04 accept canonical milestone date headings ([cc8781c](https://github.com/szTheory/oarlock/commit/cc8781cf43f06574a4d43bc4b4e99989c5c155c6))
* **31:** CR-04 enforce bounded descriptor reads ([959e8b6](https://github.com/szTheory/oarlock/commit/959e8b636119c68f93bdc56121a241944dc6b1fb))
* **31:** CR-04 enforce milestone history cardinality ([4f37b2c](https://github.com/szTheory/oarlock/commit/4f37b2cf9bde16c48607de6276a1f79f7a8d7583))
* **31:** CR-04 require canonical evidence links ([7f382b5](https://github.com/szTheory/oarlock/commit/7f382b553bcfd2c695665dd3f85067fd81792ad3))
* **31:** CR-05 reject caveat overrides of failed proof ([aa9746d](https://github.com/szTheory/oarlock/commit/aa9746da9933a527f5d982ec95c9877b53cfa3d2))
* **31:** CR-05 reject null mirror metadata ([1f4f12b](https://github.com/szTheory/oarlock/commit/1f4f12b4ed5331a82f19d1c4a0710ad74c77778d))
* **31:** CR-06 require structured requirement results ([b776b23](https://github.com/szTheory/oarlock/commit/b776b23b28dd7f4a907a49da802db3fed4d7ec47))
* **31:** CR-06 validate mirror routing exactly ([d9301d9](https://github.com/szTheory/oarlock/commit/d9301d9385199f96caaf72614e4158893cd9e229))
* **31:** CR-07 preserve completion diagnostics on conflicts ([9163825](https://github.com/szTheory/oarlock/commit/916382599ca6ae119fdc5d971fbb525beb8b91c1))
* **31:** CR-07 validate canonical STATE status ([4ecc32b](https://github.com/szTheory/oarlock/commit/4ecc32bdb3983b057a23bc328a747766cf3c428a))
* **31:** CR-08 block unchecked completion plans ([c76069e](https://github.com/szTheory/oarlock/commit/c76069e613faa6109f2feb728036f1e45b6e0949))
* **31:** CR-08 escape history output controls ([ba07f9c](https://github.com/szTheory/oarlock/commit/ba07f9cb7542cc46fa25fb23deeca9bad1788f53))
* **31:** CR-09 reject incomplete Git porcelain ([e7567b2](https://github.com/szTheory/oarlock/commit/e7567b2fbebb22d002439aece255b6c6c21cab05))
* **31:** CR-10 snapshot phase artifact namespaces ([9187609](https://github.com/szTheory/oarlock/commit/91876096208e7dd15cdc35e02d0b542cc5f9808d))
* **31:** CR-11 validate ROADMAP archive links ([d53c366](https://github.com/szTheory/oarlock/commit/d53c3662091eae187ca7ed85bb95a058a27f4266))
* **31:** CR-12 validate planning milestone identity ([30e433d](https://github.com/szTheory/oarlock/commit/30e433d8ef75fc5bf44e90a50f57c58b73953607))
* **31:** CR-13 reject unsupported publication claims ([f927598](https://github.com/szTheory/oarlock/commit/f92759857c84b8ccbf278a1e0b30a3ea777a09a4))
* **31:** CR-14 reject duplicate ROADMAP phases ([ea8645b](https://github.com/szTheory/oarlock/commit/ea8645bc785586248e9743a920ad7ca55a9218ff))
* **31:** CR-15 require structured archive corrections ([2baa309](https://github.com/szTheory/oarlock/commit/2baa3099c8996cb73e4e5559e3aebeea432efd42))
* **31:** resolve planning research and validation blockers ([8ab0d42](https://github.com/szTheory/oarlock/commit/8ab0d4250de1404aad11ff9e28f97f47cad8af85))
* **31:** revise gap plans based on checker feedback ([7568fd9](https://github.com/szTheory/oarlock/commit/7568fd98942e6a6d2e979b9f5a1f89f5f6614cd0))
* **31:** WR-01 bound CI monitor wall time ([ff82862](https://github.com/szTheory/oarlock/commit/ff82862924df52b8c74d579b416a088664fe3a4a))
* **31:** WR-01 honor full revisit date ([2bb9f4c](https://github.com/szTheory/oarlock/commit/2bb9f4ca385f82b5cc91d25e77fe1c4fb483383d))
* **31:** WR-01 honor workflow file selectors ([5ea0fc5](https://github.com/szTheory/oarlock/commit/5ea0fc50ee78c145367c65b92d5728b61daae7cc))
* **31:** WR-02 contain completed-run lookup errors ([3a3eb7b](https://github.com/szTheory/oarlock/commit/3a3eb7b3b485abd565def3b5e4ca20a811e89b53))
* **31:** WR-02 surface corroboration failures ([626c293](https://github.com/szTheory/oarlock/commit/626c29385996464d0f1fa9d3780a5344f7e0647e))
* **31:** WR-03 validate CI monitor timing options ([45460e2](https://github.com/szTheory/oarlock/commit/45460e2dc63048c73c64e5ee03f7bd69702e653a))
* **31:** WR-04 bound repository truth subprocesses ([78bbf62](https://github.com/szTheory/oarlock/commit/78bbf62ca3de829368cddd3ae64b38277a6bf3da))
* **32-13:** normalize malformed provider error envelopes ([6ce3979](https://github.com/szTheory/oarlock/commit/6ce3979af444139cddc1080db54d32b0ce65888d))
* **32-14:** finalize bounded receipts on successful exit ([1eb54ce](https://github.com/szTheory/oarlock/commit/1eb54ce0befcc07cde2f154e758c11a9bc3be4f1))
* **32-14:** invalidate full receipt before preflight ([1265e53](https://github.com/szTheory/oarlock/commit/1265e539e1ba44079a0fc102fc614948b35965c1))
* **32:** revise gap plans based on checker feedback ([3b0f674](https://github.com/szTheory/oarlock/commit/3b0f6748818217b7242af551cdf4bfa1461bd1fa))
* **33-01:** reject zero SHA proof identities ([c5a5802](https://github.com/szTheory/oarlock/commit/c5a5802e3f0ae6a82368b233ffd4e9297cff954b))
* **33-02:** clear strict Credo findings ([e1b32e7](https://github.com/szTheory/oarlock/commit/e1b32e70d12f6f55584c13446937b7149d7f5437))
* **33-02:** clear strict Credo findings in tests ([bd87b5b](https://github.com/szTheory/oarlock/commit/bd87b5b86a2a82d1adb4562f50fe504ade2e9404))
* **ci:** bound and stabilize hosted verification ([b62db8c](https://github.com/szTheory/oarlock/commit/b62db8c65b19fd874c856c55fe8391e8116913aa))
* **ci:** capture Rebar version output reliably ([852d2e6](https://github.com/szTheory/oarlock/commit/852d2e6fcb4f882b42b6c93f1df5f6878c924de0))
* **ci:** detect unpacked Hex install ([79f8803](https://github.com/szTheory/oarlock/commit/79f880336036fcc378b4113b1595a3b3f032f6e9))
* **ci:** isolate trusted caches and pin test inputs ([4939bdd](https://github.com/szTheory/oarlock/commit/4939bddaa78e3027a014d10137191fd1dcefb27b))
* **ci:** pin Hex and checksum Rebar installer ([5f76e4b](https://github.com/szTheory/oarlock/commit/5f76e4b23bc74eefbd12e1184bcbbd6def1fc652))
* **ci:** restore exact-SHA hosted proof ([63c70c9](https://github.com/szTheory/oarlock/commit/63c70c9a8483416cd8fa1fd877e08975c7b34e29))
* **ci:** stabilize timeout tests on hosted runners ([e75a3b1](https://github.com/szTheory/oarlock/commit/e75a3b1fd8b9bb86b30602f4c36c97cb60b26d97))
* harden CI proof and provider error inspection ([ea74661](https://github.com/szTheory/oarlock/commit/ea746612d9a28ee6a4206b36506180752a52a98f))
* **phase-10:** address subscription lifecycle review findings ([c58a77f](https://github.com/szTheory/oarlock/commit/c58a77fc19be82519ea9221650ffc3a2b7a5f49a))
* **planning:** keep transitioned state canonical ([c076e32](https://github.com/szTheory/oarlock/commit/c076e327e4b61f9e11da57c8d25c2b4121076c1f))
* **planning:** validate first evidence ledger baseline ([8ced58e](https://github.com/szTheory/oarlock/commit/8ced58ed1ebb7ae989ab5305a4c33fa18de83362))

## [Unreleased]

### Phase 32 Migration

This is an intentional pre-1.0 source and observable-behavior break. The SDK now
depends on Req `~> 0.7.4` and supports Elixir `~> 1.19`; the tracked compatibility
toolchain is Elixir 1.19.5 / OTP 28.1.

* **Mutation replay:** removed `idempotency_key` from all public option types and
  functions because sending a header is not proof of provider deduplication.
  Mutations now make one attempt; uncertain transport and terminal HTTP 408/5xx
  outcomes return non-retryable ambiguity context with lookup, webhook, and
  provider-dashboard reconciliation guidance.
* **Read retries:** only GET/HEAD may retry the documented transient allowlist,
  with three retries (four total attempts) and a 60,000 ms read-side 429
  `Retry-After` cap. `retry: false` may restrict a read; `retry: true` cannot
  enable mutation replay.
* **Telemetry metadata schema:** event names are unchanged, but raw request,
  response, and exception terms were replaced by exact low-cardinality
  measurement and metadata allowlists. Subscribers must migrate their patterns.
* **Client constructor validation:** unknown or duplicate options, blank/nonbinary
  keys, unsupported environments, invalid URLs, and conflicting environment/URL
  pairs now raise secret-safe `ArgumentError` before transport construction.
* **Inspection:** credentials, operational URLs, transport state, and
  secret-capable `raw_data` render as `[REDACTED]` without changing stored terms.

### Breaking Changes

* **`%Paddle.Error{}`**: Field `:raw` renamed to `:raw_data` for consistency with all other locked structs (every `Paddle.Customer`/`Paddle.Address`/`Paddle.Transaction`/`Paddle.Subscription`/etc. already uses `:raw_data` as the documented forward-compat escape hatch). Pattern matches against `%Paddle.Error{raw: r}` will silently miss after this change — update them to `%Paddle.Error{raw_data: r}`. (See `.planning/phases/08-reliability-primitives/08-CONTEXT.md` D-01..D-05 for rationale.)

### Added

* **PAGE-01 auto-pagination helpers**: `Paddle.Subscriptions.stream/2`, `Paddle.Subscriptions.all/2`, `Paddle.Customers.Addresses.stream/3`, and `Paddle.Customers.Addresses.all/3` iterate list endpoints across Paddle pages while preserving the existing `list/2` and `list/3` `{:ok, %Paddle.Page{}}` return shapes. Stream helpers are lazy and may raise during later-page enumeration; eager `all/*` helpers return `{:error, reason}` without partial results on the first failed page.
* **`%Paddle.Error{}`**: New `:network_error?` field (boolean, defaults to `false`) — to be populated by `from_transport/1` in a follow-up plan.
* **`%Paddle.Error{}`**: New `:retryable?` field (boolean, defaults to `false`) — advisory class predicate populated by `from_transport/1` in a follow-up plan.
* **`from_transport/1`**: New public constructor that maps `%Req.TransportError{}` into a normalized `%Paddle.Error{}` with `:network_error?: true`, `:retryable?: true`, and a stable `:type` taxonomy (`"network_timeout"`, `"network_nxdomain"`, `"network_closed"`, `"network_unknown"`). Public resource calls now return `{:error, %Paddle.Error{network_error?: true, ...}}` for transport failures instead of leaking the raw `%Req.TransportError{}` to consumers — Accrue and other consumers can now pattern-match on a single error shape across both HTTP and transport failures. (REL-03)
* **Request-local bounded retry policy**: safe reads use the central method-aware
  policy described in the Phase 32 migration notes; client construction no
  longer installs a global all-method retry policy. (REL-02, superseded)
* **Public documentation truth pass**: aligned README, [`guides/getting-started.md`](guides/getting-started.md), [`guides/accrue-seam.md`](guides/accrue-seam.md), [`demo/README.md`](demo/README.md), this changelog, and generated docs with the shipped SDK seam. The bounded supported surface now covers customers, addresses, customer portal sessions, transactions/checkout, raw-body webhook verification/parsing, subscription fetch/update/lifecycle, adjustments, catalog reads, event history, notification settings, pagination helpers, normalized errors, and compatibility `Paddle.PortalSessions.create/2`. Use [`guides/accrue-seam.md`](guides/accrue-seam.md) for the canonical contract and task guides for integration flows.
* **Proof-boundary documentation**: named the evidence ladder consistently across public docs. Unit/contract tests prove local SDK behavior; `Paddle.MockServer` proves deterministic local SDK/demo wiring; Paddle sandbox checks prove real provider-state behavior only when real sandbox credentials are used; live mode remains operator-owned before charging customers.

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
