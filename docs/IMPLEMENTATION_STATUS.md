# Implementation status

Current phase: **Phase2 Task6 encounter matching and Home; in progress**. API contract: `1.4.0`; experiment contract `phase0.v1`.

Main is a documentation baseline, not a working release. Phase0 integration into development is explicitly approved by the owner. Detailed field metrics and iOS validation remain pending release evidence.

## Plan ledger


## Phase 0 — location feasibility and asset baseline


### Task 1: Real-device tracking and matching experiment

- [ ] Define typed start/pause/stopAndPurge and status/sample streams with consentEpoch/deviceSessionId. — **implemented — typed Dart policy/sample/status contracts and native channel methods; Dart regressions pass; native runtime awaits device test**
- [ ] Write failing lifecycle assertions: pause stops samples; logout clears queue; queue caps at 200 and expires at 15 minutes; outdated epoch rejected. — **implemented — bridge tests and debug encrypted-queue probe; populated active-delivery integration assertions added; physical execution blocked by APK prerequisites**
- [ ] Implement Kotlin/Swift bridge and minimal test harness with no public discovery UI. — **implemented — Kotlin/Swift bridge and private harness; Kotlin custom-source compile and Swift custom-source typecheck pass; assembled builds pending**
- [ ] Run paired phones on same street, opposite streets, adjacent cafés, different floors, stationary tables and fast crossings; log ground truth separately from app verdict. — **awaiting device test — no paired-phone evidence supplied**
- [ ] Test foreground, locked eight hours, background, app force-stop/force-quit, restart, network loss, permission downgrade, power saver and multiple devices per account. — **awaiting device test — no locked/background/kill/permission/power/multi-device evidence supplied**
- [ ] Measure battery against baseline with repeated comparable runs; record device/OS, duration, sampling, precision, recall and notification latency decomposition. — **awaiting device test — no battery/precision/recall figures; push latency blocked by missing test credentials and push integration**
- [ ] Choose continuous/passive/adaptive trade-off from measured results; recommended adaptive. Brief-crossing rule stays off unless demonstrated. — **blocked — final sampling trade-off requires measured evidence; preliminary balanced foreground/background candidate only; brief-crossing rule remains off**
- [ ] Confirm map plugin compatibility, asset/font availability and supported OS floors; pin initial versions/licenses. — **blocked — assets/fonts exported and rendered; direct Dart packages pinned from cache; native dependency compatibility, MapLibre and runtime OS floors unverified**


## Phase 1 — shared foundation and infrastructure


### Task 2: Repositories, contracts and Compose

- [x] Create three repositories with strict lint/type settings, lockfiles, env examples and no secrets. — **verified — foundation evidence below**
- [x] Define scripts: backend `test`, `test:integration`, `typecheck`, `lint`, `build`, `db:migrate`, `openapi:export`; admin `test`, `typecheck`, `lint`, `build`, `test:e2e`. — **verified — foundation evidence below**
- [x] Add a failing integration check that migrations create required constraints and `/health/ready` fails when DB is unavailable. — **verified — foundation evidence below**
- [x] Implement PostgreSQL/PostGIS, Valkey, API/worker, proxy and development email services with volumes/health checks. — **verified — foundation evidence below**
- [x] Add structured redaction, request IDs, typed errors, timeouts and OpenAPI export; pin generated clients in consumers. — **verified — foundation evidence below**
- [x] Verify a fresh boot and restart preserve data; worker/API stop gracefully; public ports exclude DB/cache. — **verified — foundation evidence below**

### Task 3: Email authentication, age gate and sessions

- [x] Test OTP purpose/expiry/attempts/resend invalidation, replay, under-18 DOB, password reset revocation and refresh-family reuse. — **verified — PostGIS OTP/reset/refresh/status/adult tests pass**
- [x] Implement signup/login/OTP/recovery with Argon2id and hashed secrets; server guards enforce account status. — **implemented and locally verified — real SMTP outbox/API flow passes against Mailpit**
- [x] Implement splash, one onboarding screen, auth forms and guarded setup routes. — **verified locally and accepted by owner on physical Android; PR3 merged into development**
- [x] Implement single-flight Dio refresh; test ten concurrent 401s produce one refresh, one replay each and no loop. — **verified — single-flight/one replay and secure-storage/logout races pass**
- [ ] Verify keyboard, paste/autofill, offline/error states and suspended-account support/deletion access. — **implemented — automated paste/keyboard/layout/restricted routing verified; OS autofill, mailto and storage runtime awaiting device test**


### Task 4: Design system, profile and optional verification submission

- [x] Build tokens/components from UI doc; record reference-to-product substitutions. — **verified locally — PathsTokens, shared neutral avatar/badge, original vector feedback; approved white auth surfaces retained**
- [x] Test username uniqueness, private DOB exclusion, adult gate, public/private response fields and CNIC skip entitlement. — **verified — real profile-access suite and private/public allowlist tests; strangers denied until Task6**
- [ ] Implement profile setup/edit and verification submit/status against upload contracts from Task8 (use mocked pending asset until then). — **implemented and accepted by owner on Android — details/privacy/edit/preview and real status/skip persist; PR4 merged; real uploads/profile completion blocked by Task8 as specified**
- [x] Add selective rebuild checks for badge/save/status and controller disposal tests where relevant. — **verified locally — unchanged badge instance on consent change; single-flight save; cancellation, late-success and upload-skip regressions**
- [x] Verify layouts at 320/390/768 widths and 200% text; add meaningful golden tests with approved assets. — **verified locally and accepted by owner on Android — responsive/keyboard fixtures and inspected profile/review goldens; iOS runtime remains separate**

## Phase 2 — location ingestion, matching and discovery


### Task 5: Consent-aware ingestion

- [x] Test max50 batch, invalid coordinate, future>30sec, stale>15min, duplicate ID, old device lease and paused/deleting account rejection. — **verified — real PostGIS location-ingest cases and policy boundary tests**
- [x] Implement transactionally stored sample/outbox records and 24h retention worker. — **verified — migration0005, atomic rollback/dedup, bounded sample/orphan intent retention and deletion cases pass**
- [ ] Integrate disclosure, staged native permissions and bounded encrypted queue; never upload after local pause. — **implemented; awaiting device test — native uploader and disclosure integrated; offline Android/unsigned iOS compilation and Flutter control tests pass; OS behavior pending**
- [ ] Test offline control ordering: pause/logout clears queued fixes and invalidates prior epochs before any resume batch. — **verified in automated models/API; awaiting device test — stale generation, account switch, late stop, queued purge/retry regressions pass; native runtime requires owner evidence**

### Task 6: Encounter matcher and privacy-safe Home

- [ ] Write boundary tests for <=50m/<=60sec and accuracy rules; two evidence pairs 20–120sec apart; reject invented stationary dwell. — **not started**
- [ ] Test concurrent inverse ingestion creates one session and two notification intents; retry does not inflate encounter count. — **not started**
- [ ] Test spatial neighbors across arbitrary grid edges, adjacent venue false positives and delayed historical batches without live push. — **not started**
- [ ] Implement PostGIS query, pair lock/session dedup and coarse-area/time serialization; exclude blocked/paused/deleting users. — **not started**
- [ ] Build map/list Home with Recent/Nearby, radius filters and permission/offline/map-failure states. — **not started**
- [ ] Verify API responses and network captures contain no peer coordinates, exact distances or exact timestamps. — **not started**

## Phase 3 — saves, requests and push


### Task 7: Relationship policy and notifications

- [ ] Test ineligible target denied, private save invisible to subject, saved eligibility survives history expiry. — **not started**
- [ ] Test inverse request race, sender accepting own request, duplicate accept, expired request and seven-day cooldown. — **not started**
- [ ] Implement atomic pair transitions and unique constraints; no implicit connection from reciprocal request. — **not started**
- [ ] Implement Saved/Incoming/Sent screens with status, cancel/accept/decline and unavailable states. — **not started**
- [ ] Implement FCM/APNs device registration and transactional notification fan-out; generic payloads, pair six-hour cooldown, user cap default ten encounter alerts/day with in-app history unaffected. — **not started**
- [ ] Test notification worker retry, invalid token cleanup, opt-out, delayed historical match, block/deletion between enqueue and send. — **not started**

## Phase 4 — media and messaging


### Task 8: Protected media and camera publishing

- [ ] Test wrong owner/type/size, decompression abuse, EXIF removal, private viewer denied and pending asset unpublished. — **not started**
- [ ] Implement private storage adapters, quarantine processing, variants and CNIC record retention; no public CNIC links. — **not started**
- [ ] Add safety-review state for user-visible images, neutral pending avatar, pending posts and server text filtering; test unreviewed/rejected content never reaches public responses. — **not started**
- [ ] Connect profile/CNIC screens from Task4 to real uploads; implement camera/gallery/preview/caption/retry/cancel. — **not started**
- [ ] Test privacy/block/deletion revokes media access; worker must not publish after deletion barrier. — **not started**
- [ ] Add orphan/multipart cleanup and object inventory for deletion manifest. — **not started**

### Task 9: Text chat, reconnect and access revocation

- [ ] Test send before accept denied; sender spoof denied; text>4000 denied; same client ID inserts once. — **not started**
- [ ] Test concurrent block/disconnect/delete vs send using consistent locks; no unauthorized post-commit delivery. — **not started**
- [ ] Implement REST persistence, server-assigned sockets and cursor catch-up; ACK only after commit. — **not started**
- [ ] Implement chat list/thread, lazy history, pending/failed retry, unread state and read-only disconnected history. — **not started**
- [ ] Test disconnect/reconnect with missed/duplicate/out-of-order events; deleted conversation removed from caches on sync. — **not started**

## Phase 5 — moderation and admin


### Task 10: Blocking/reporting and restricted account lifecycle

- [ ] Test block removes both saves, cancels requests, stops sends, excludes discovery and revokes private media; unblock restores nothing automatically. — **not started**
- [ ] Implement report categories, scoped evidence and acknowledgment; privacy-aware evidence deletion hooks. — **not started**
- [ ] Implement deactivation/reactivation status guard, session revoke and queue suppression. — **not started**
- [ ] Add support/delete access for restricted users and suspected-underage escalation flow. — **not started**

### Task 11: Admin portal and review workflow

- [ ] Test reviewer/moderator/admin permission matrix and unauthenticated CNIC access denied. — **not started**
- [ ] Implement staff provisioning/MFA/session/CSRF; shadcn shell, server-paginated lists and typed clients. — **not started**
- [ ] Implement protected no-store CNIC viewer, claim/version conflict, approve/decline and notification. — **not started**
- [ ] Implement image safety-review queue and text-filter escalation/appeals, with required pilot staffing. — **not started**
- [ ] Implement deactivation/reactivation, reports and redacted audits; no unrestricted private-message browser. — **not started**
- [ ] Verify mobile-width admin usability, keyboard navigation and sensitive-content no-cache behavior. — **not started**

## Phase 6 — deletion, robustness and load


### Task 12: Complete account erasure

- [ ] Seed two connected users with messages, posts, CNIC versions, reports, locations, caches and queued jobs; test deleting one leaves zero personal records and removes the shared conversation. — **not started**
- [ ] Test FK constraints after deletion, another unrelated conversation unaffected, and staff audit anonymization without copied subject PII. — **not started**
- [ ] Implement immediate barrier/revocation, encrypted independent manifest, external object/provider purge and bounded DB cascades. — **not started**
- [ ] Inject failures after each stage; retry completes without losing manifest or recreating assets. — **not started**
- [ ] Implement in-app reauth/delete/receipt and external email-OTP deletion path; validate offline request does not show false success. — **not started**
- [ ] Implement backup expiry/suppression ledger; restore a pre-deletion backup in isolation and prove deleted data is removed before serving traffic. — **not started**
- [ ] Verify counterpart cache invalidation on reconnect and disclosure of screenshots/backup timing limits. — **not started**

### Task 13: Load, security, battery and UI hardening

- [ ] Test 50 samples/sec sustained, 200/sec burst, 300 socket clients, all candidates in one area; measure query plans/locks and outbox lag. — **not started**
- [ ] Test Valkey restart, worker crash, database restart, upload cancellation and SMTP/push outage; recover committed work. — **not started**
- [ ] Run authorization enumeration, rate-limit, token replay, CSRF, private-media and secrets/log-redaction checks. — **not started**
- [ ] Repeat battery/coverage experiment using production integration, not only the Phase0 harness. — **not started**
- [ ] Profile rebuilds/map offscreen behavior/image memory; fix demonstrated regressions. — **not started**
- [ ] Complete accessibility/text-scale/reference screenshot comparisons and update honest product limitations. — **not started**

## Phase 7 — final feature: Google and Apple authentication


### Task 14: Provider login and safe linking

- [ ] Test invalid audience/issuer/nonce/expired token and signature rotation; use test verifier fixtures, never production credentials in repo. — **not started**
- [ ] Test same-email collision does not merge; existing-account reauthentication required; provider+subject unique. — **not started**
- [ ] Implement Google and Apple SDK flows, cancellation handling, Apple relay/name-first-login behavior and missing email recovery. — **not started**
- [ ] Integrate profile/adult onboarding and secure provider reauthentication for delete. — **not started**
- [ ] Add Apple token revocation to deletion workflow, test provider outage retry; prevent removing last sign-in method. — **not started**
- [ ] Verify both providers on real signed iOS/Android builds as supported by configured provider flows; recheck login-service store requirement. — **not started**

## Phase 8 — deployment and release validation


### Task 15: Operational and store readiness

- [ ] Choose VM or Render using measured resource demand and current vendor quotations; document recurring storage/email/tiles/backups/developer-account costs. — **not started**
- [ ] Deploy staging with HTTPS, private data ports, nonroot containers, encrypted backups and working rollback/migrations. — **not started**
- [ ] Run full two-user journey: signup→OTP→profile→skip/submit CNIC→encounter→save→request→accept→chat→post→privacy→block→delete. — **not started**
- [ ] Repeat deletion/restore with final social auth included and verify no stale events recreate data. — **not started**
- [ ] Publish truthful privacy, terms, community/child-safety and deletion pages; staff support and escalation owner assigned. — **not started**
- [ ] Complete Google background location declaration/demo, Data safety, target audience/minor restrictions as applicable; Apple privacy/review notes and login/deletion demonstrations. — **not started**
- [ ] Obtain Pakistan-specific legal applicability review; do not claim friendship branding guarantees regulatory acceptance. — **not started**
- [ ] Submit only after battery/accuracy limitations and platform behavior are reflected in product copy; production rollout is a separate explicit owner action. — **not started**

## Phase dependency order


## Evidence — 2026-10-17

- Backend `npm test` / `node --test test/phase0/*.test.ts`: **13 passed**, including an authenticated loopback HTTP test (local listener requires host permission), conservative boundaries, retries, stale leases, stop-before-start race and dense input. Not a TypeScript compiler or PostGIS integration test.
- Mobile `flutter analyze --no-pub`: **No issues found**.
- Mobile `flutter test --no-pub`: **25 passed**: API endpoint/scoped-stop regressions, Cubit permission/offline/native-stop flows, bridge epoch filtering and stale in-flight discard, 14 width/text-scale layouts and one rendered golden. No physical-device tests ran.
- `python3 tools/check_android_source.py`: **exit0**; custom Kotlin compiles from existing caches. Temporary substitution of unresolved generated icon resource reference is documented in DEVICE_TESTS.md; resource linking/APK/native plugin packaging are not proven.
- `xcrun swiftc -typecheck -D DEBUG` against installed iPhoneOS26.5 SDK, target arm64/iOS16, cached Flutter framework and generated bridging header: **exit0**, AppDelegate, SceneDelegate and PathsLocationTracker. No full iOS build, XCTest run or iOS runtime test.
- Asset exporter executed; original primary SVG preview rendered with installed AppKit and inspected; symbol and fonts rendered by Flutter and inspected. XML parses, PNG decoding and iOS opaque-square icon checks pass. Launcher safe areas/native splash appearance await devices.
- `git diff --check`: passes for project changes; .gitattributes preserves original third-party license whitespace verbatim.
- Separate read-only code review found and prompted fixes for matching CPU bound, stale/reordered leases, stale Android service generation, offline native status, permission/foreground callback races, URI validation and failing-test cleanup. See REVIEW.md.

Initial failed checks were not discarded: compact/200% layout overflow fixed and rerun; method-channel void cleanup fixed and rerun; endpoint regression fixed and rerun. CPU-bound failing regression was terminated and replaced by the tested bounded matcher. Initial sandbox-blocked loopback test was terminated, cleanup corrected and rerun with local listener permission.

## Exact blockers and pending checks

- Android APK `gradle --offline :app:assembleDebug`: blocked by SDK integration_test's uncached AGP8.11.0. Project-local diagnostic AGP9.1.0 override advances configuration, then stops on missing androidx.test runner1.2+, rules1.2+, espresso-core3.3+ listings/artifacts and Guava28.1-android. No downloads performed. Further missing native artifacts may emerge after these.
- Android/iOS physical lifecycle, background delivery, encrypted key lifecycle, battery, encounter precision/recall, real splash/launcher masking and multiple-device behavior: **awaiting device test**. Active integration scenario is explicitly skipped unless owner opts in.
- FCM/APNs credentials and experiment push dispatch/OS-delivery measurement: **blocked**; no alert result invented.
- Strict backend TypeScript compilation and production NestJS/PostGIS/worker checks: **not executed**, dedicated compiler/dependencies and Phase1 infrastructure not installed/implemented.
- MapLibre0.27.1 is present in cache but native compatibility, tiles and exact supported runtime floors are **unverified**. It is not linked into the Phase0 harness.
- Native encrypted queue enforces expiry/prunes while executing; forced OS suspension cannot guarantee wall-clock disk erasure exactly at15min. Recorded limitation needs field validation before acceptance.

No production deployments, purchases, personal data uploads, phone operations, emulator launches or app-store submissions. Only font assets were downloaded under the owner's visual-asset exception.

## Repository scope and commits

### paths-backend

- `7b5e7e9 feat: add private two-participant experiment transport`
- `89b99ff feat: add conservative encounter experiment policy`

### paths-admin

- `9861450 feat: add shared Paths brand and licensed fonts`

### paths-mobile

- `6b15cb6 feat: add consent-driven field harness and regression checks`
- `86c4ea8 feat: add native tracking lifecycle and encrypted queues`
- `df1d52e feat: add Paths identity and platform icon assets`

All work remains on `feature/phase0-feasibility` from development. Main/development remain at the documentation baseline; no application release or phase merge. Later phase checklist items remain not started because the Phase0 dependency gate is pending. The final docs commit records this report; its SHA is available in git/PR and need not self-reference.

Next action: supply complete local Android test artifact caches or explicitly change the no-download constraint; then run the owner's physical-device checklist. Do not advance Phase1 until Phase0 evidence and policy choice pass.

## Owner acceptance and Android build follow-up

The owner reports the experiment tested and feasible, authorizes merging the Phase0 PRs into development, and asks to continue according to plan. No device model, OS, battery figures, scenario matrix, precision/recall or iOS results were supplied; those checklist details remain pending, not invented. This explicit continuation decision supersedes the earlier hold on Phase1.

Android debug assembly with cached Gradle9.3.1, `--no-daemon -Pandroid.builder.sdkDownload=false :app:assembleDebug`, now **passes** after the authorized missing Android dependency downloads (73 tasks). This proves resource linking/Kotlin/Java/native packaging for the debug APK; it does not prove runtime behavior. Previous offline blocker entries above are historical. No SDK installation or release build performed.

Gmail SMTP and Cloudflare R2 selected for later provider integration. Phase1 dependency/image downloads now separately authorized. Main stays at its documentation baseline.

## Phase1 Task2 — current evidence (2026-10-17)

This section supersedes historical Phase0 branch/tooling statements above. Phase0 PR1 merged into development after owner acceptance. Main remains a documentation baseline. Tasks3–4 remain pending; Phase1 is not complete.

Task2 files: backend `src/`, `db/`, `scripts/`, `infra/`, `Dockerfile`, `test/{unit,integration}/`; admin `src/`, `e2e/`, `test/`, Vite/shadcn config; mobile `lib/app/{bootstrap,router}.dart`, `lib/core/network/`, `test/core/api_client_test.dart`, `tools/generate_api_contract.py`. All repos contain real dependency locks and ignored local environment examples. No credentials are tracked.

Executed checks:

- Backend strict TypeScript build/typecheck and ESLint pass. Four unit tests and thirteen retained Phase0 tests pass. Five real PostGIS/Valkey integration tests pass: serialized migrations/constraints/cascade, unavailable DB readiness, idempotent outbox/cache-loss replay, retained exhausted-job recovery, and worker startup shutdown with Redis unavailable. Integration runner owns an isolated temporary database (requires CREATEDB), avoiding races with the development worker.
- Compose build and health-gated startup pass. Latest runtime image restart check passes: retained user/outbox data survive database/cache/API restart, worker catches up, API runs as uid10001, API/worker stop with exit0, services restore healthy. Base data ports are private; explicit host-test override binds only loopback54329/63799. Proxy8080 and Mailpit8025 are loopback only. Initial empty-database migration/startup also passed. No persistent volume was deleted.
- Nest OpenAPI export1.0.0 succeeds; exact artifact pinned in both consumers. Real TypeScript and Dart DTO generation succeeds. Swagger version-field regression fixed (object to string), contract unit test passes.
- Admin ESLint, strict typecheck, two transport tests and production build pass. Three installed-Chrome E2E tests pass: narrow320px recovery without overflow, offline/incompatible contract errors, initial offline mount then reconnect. Desktop screenshot inspected for logo/font/layout. Browser health responses are explicitly test fixtures; this is not staff authentication or an admin workflow test.
- Flutter no-resolution analyzer passes with no issues; all27 tests pass (including two network contract/error tests). No package resolution, phone operations or emulator used. Existing Android debug APK assembly passed separately before Task2; no new native behavior is claimed.
- Read-only review identified retained failed-job recovery, unavailable-Redis shutdown, and initial offline admin state; all fixed with regressions and re-reviewed. A potential local integration-test race was removed with isolated databases. Code inspection cannot establish device/background/battery/iOS runtime behavior.

Remaining: GitHub CI execution is pending until push. Dependency notices report ESLint9 support ended and BullMQ's transitive cron-parser4.9 deprecated; pinned versions compile/test locally. Track maintenance separately; no toolchain upgrade was silently made. Gmail SMTP delivery/credential validation belongs to Task3; private Cloudflare R2 integration belongs to Task8. No remote email/storage action, deployment or real personal-data upload occurred. Quantitative Phase0 field/iOS evidence remains required before release.

Local container sources resolved during verification: Node24.13.0-alpine `sha256:cd6fb7efa6490f039f3471a189214d5f548c11df1ff9e5b181aa49e22c14383e`; PostGIS17-3.5 `sha256:01a6a70e41e6c4467c8f55f6063555ed72db2d6662cd0d571040d42eadaeb6f6`; Valkey8.1-alpine `sha256:081c2f5cb575efc901aa80ff9cdbd1ec6a301682fd35e1ebb4b0990a4a4a8507`; Mailpitv1.27 `sha256:e22dce5b36f93c77082e204a3942fb6b283b7896e057458400a4c88344c3df68`; Caddy2.10-alpine `sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d`.

Foundation implementation commits: backend `d8dab8b`, `446979e`; admin `269b353`; mobile `6f44e43`. The documentation commit records this evidence separately.

GitHub follow-up: corrected backend CI run39017845238 and admin CI run39017849088 pass, including lint/types/build/tests/integration (backend) and generated-artifact drift. Mobile analyzer/tests are local evidence; no hosted Flutter SDK download or iOS runtime check was performed. Foundation PRs: https://github.com/awais-ur-rehman/paths-backend/pull/2 ; https://github.com/awais-ur-rehman/paths-admin/pull/2 ; https://github.com/awais-ur-rehman/paths-mobile/pull/2 . Task2 is verified; Phase1 Tasks3–4 remain open.

Final transport review: malformed JSON was initially classified as offline by Dio. A new test failed on that classification; ApiClient now maps wrapped FormatException to invalidResponse. Full Flutter analyzer has no issues and all28 tests pass after the fix. This adds no native behavior and does not replace device validation.

## Phase1 Task3 — first session component (in progress)

Branch `feature/session-refresh`, from development merge8bda1c5. Task2 foundation PR2 merged in all repos (backend6707061, admin7568cdf, mobile8bda1c5). Main is unchanged.

`lib/core/network/refresh_coordinator.dart` implements one shared refresh for concurrent401s, one replay/request, late401 reuse, generation invalidation on sign-in/logout, original-origin restriction, no redirect following, cancellation and non-replayable stream handling. Volatile tokens are intentionally not connected to the current app. A real auth repository must own secure persistence/rotation and terminal revocation before integration; the callback uses a separate bounded HTTP client.

`test/core/refresh_coordinator_test.dart`: eleven tests, including ten concurrent requests (one refresh, exactly20 transport calls), replay401 limit, stale refresh across logout/new sign-in, shared failure, foreign-origin rejection, cancelled request, old401 and successful200 across account changes, and suppression of separate refresh-request secrets. Fixtures contain synthetic tokens only. Full no-resolution Flutter analyzer has no issues; all39 mobile tests pass. Initial missing-component test failure established red; runtime/header-map and race-test failures were diagnosed and corrected before green. Read-only review found stale successful/error response leakage and raw refresh transport errors; both fixed with regression coverage and re-reviewed.

This is an unconnected Task3 component, not a completed authentication flow. Signup/login/OTP/reset, Argon2id, server sessions/status guards, secure persistence, AuthCubit/forms/routes and physical signup/reset checks remain **not started**. No device testing requested for an incomplete flow. Draft PR remains pending the rest of Task3 integration. API export remains1.0.0; no unpublished auth endpoint or generated response is fabricated. Task4 profiles remain not started. No missing dependency is claimed as a blocker for these remaining tasks.

Task3 implementation commit: `49dde5a`; initial evidence commit: `919dcb7`. Draft https://github.com/awais-ur-rehman/paths-mobile/pull/3 targets development from feature/session-refresh; do not merge until real authentication/secure-storage integration and applicable checks pass. Foundation PR2 merged; no release promotion.

## Task3 current implementation and gate (2026-10-17)

Backend feature/email-auth: Argon2id, challenge-bound keyed OTP digests (5min/5 guesses/60s), purpose/resend invalidation, encrypted transactional SMTP outbox, 10-minute opaque hashed access tokens and rotating30-day refresh families with reuse revocation; reset grants never act as sessions. Restricted accounts retain own session metadata/logout and support contact. Public account metadata never includes DOB. JWT is not a requirement of the bearer contract.

Mobile feature/session-refresh: platform secure storage (Android Keystore/AES-GCM; iOS this-device-only non-synchronizing Keychain), serialized credential persistence, install marker and sign-out tombstone, explicit native queue cleanup, single-flight refresh and bounded replay. Native key persistence remains a runtime gate. Bootstrap/onboarding/signup/login/OTP/forgot/reset/guarded adult-check/restricted screens are implemented. The default main entry is auth; private feasibility harness moved to lib/main_phase0.dart. Full profile fields/media remain Task4/Task8, not falsely completed here.

Executed before final review: backend lint/type/build, 5 unit +13 Phase0 +20 PostGIS/Valkey tests pass; real proxy→API→outbox→worker→Mailpit signup/reset script passes and cleans its synthetic fixtures. Admin lint/types/build,2 transport and3 Chrome checks pass. Flutter analyzer reports no issues;61 tests and2 Python generator tests pass. Onboarding/login golden renders inspected with actual bundled fonts/icon glyphs;320/390/768 widths at100%/200% with keyboard pass. Android debug assembly passes with existing Gradle/SDK and authorized artifacts (177tasks). iOS full unsigned Debug iphoneos build passes using local Swift packages, package resolution disabled; entitlements/plists lint passes. No device, simulator or emulator launched. Final source review/CI/final-image rerun still pending; append final results below.

Gmail/support address supplied by owner is configured only in ignored local env. TERMS_URL/PRIVACY_URL remain editable in backend .env; blanks intentionally show development testing notices pending final URLs. Gmail settings require credentials and TLS; actual Gmail delivery is unverified because no app password was provided. Local test delivery uses Mailpit; no external email, deployment or real user data upload occurred.

Task3 remains **awaiting device test**, not complete. Do not merge the auth draft PRs or advance a dependent gate before owner Android results. iOS runtime, secure storage across OS restarts/uninstall, email-app handoff and OS autofill remain separately unverified. Detailed Phase0 quantitative evidence remains a release gate.

## Task3 final mobile evidence

Source commits: f92bfc5 (assets),4fbfd7f (secure repository),c78338c (screens/routes),b35debc (licenses/logout contract),0350b24 and bc6161a (review fixes). Final Flutter analyzer: no issues. All68 Flutter tests pass, plus2 Python contract-generator tests. Android final debug build passes177 tasks; final iOS unsigned iphoneos build succeeds with automatic package resolution disabled. iOS plist/entitlements lint passes. Exact OpenAPI copies match and Dart regeneration has no drift. A first generator check accidentally discovered zero tests; the correct test/tools discovery was subsequently run and passed2 tests. A sandbox telemetry timestamp warning during formatting was resolved by rerunning formatting with the installed SDK's required access; generated bytes remain unchanged.

Final source review fixes and limits are recorded in docs/REVIEW.md. Device checklist: docs/AUTH_DEVICE_TESTS.md. Support/URLs are configured server-side in ignored env; no credentials are committed. Mobile draft PR3: https://github.com/awais-ur-rehman/paths-mobile/pull/3 . Branch feature/session-refresh. Required owner Android results and separate iOS runtime evidence remain pending; Task3 and Phase1 are not complete. Main/development have not received this auth implementation.

## Physical-device feedback correction (2026-10-17)

Owner ran the app on Android and reported UI defects; this is not acceptance of all Task3 device cases. Requested corrections implement a smaller mask-safe splash; full-bleed52%-height onboarding photo, centered text and one animated arrow CTA to login; white auth surfaces; an age-only form that immediately routes to actual profile details; shared vector crossing-paths loader and top-right swipe-right-dismissible success/error toast. No onboarding footer links/account copy remain. Existing login content remains, with white background. Credits remain accessible from policy screens.

The requested profile page starts only the necessary details slice of Task4: canonical unique username, name, documented gender choice and optional300-character bio, guarded by verified active adult session. GET/PUT /v1/me/profile saves private details; profileComplete remains false. Photo upload, optional verification, public profile completion and later product routes are not claimed complete. No fake save/upload/Home response was introduced. Full Task4 remains pending the auth device gate and its own plan work.

Fresh read-only review found a false-success toast on retry after an earlier successful save. Reproduced with a failing widget journey and fixed: success follows a completed save revision, not clearing an error. Reviewed limits remain physical native rendering, OS behavior and deferred upload/verification. No second reviewer pass claimed.

Current files: backend db/migrations/0003_profile_details.sql, db/schema/profiles.ts, src/modules/profiles, scripts/verify-auth-mail.ts; mobile lib/shared/widgets, lib/features/profile, auth screens/router/theme/native splash and real generated API1.2.0; admin pinned contract1.2.0. Final source/build/CI evidence and commits follow below. Draft PR3 in each repository remains open; main/development unchanged until owner retest.

Verified device-feedback checks: backend lint/types/build,5 unit +13 Phase0 +25 database integration tests pass. Proxy/API/outbox/worker/Mailpit signup→adult-check→profile save/read→reset smoke passes. Admin lint/types/build,2 transport tests and3 installed-Chrome cases pass; real API1.2.0 copies match. At the intermediate checkpoint, the mobile analyzer was clean and84 Flutter tests passed;3 Python tests pass (2 generator + native circular splash safe-area geometry). Four phone goldens inspected with actual fonts and synchronous original vector branding. Final native builds/CI recorded below after completion; no physical results invented.

Profile setup retains the existing secure sign-out action after the age-only page; the age page itself has none of the removed support/deletion/sign-out controls. This prevents stranding an authenticated user during incomplete setup. Final regression count follows below.


### Final device-correction verification

Mobile source commits: b917642 (profile API), a7afe47 (shared vector branding, loader, toast and arrow), 9e6bc9e (screens/routes/native splash), 561896f (profile sign-out), 15c025e (navigation handoff and regression tests). Final Flutter analyzer reports no issues; all88 Flutter tests pass, including successful arrow handoff, retry and reduced-motion cases. All3 Python generator/splash geometry tests pass. Final offline Android Debug assembly succeeds (177 tasks); final unsigned generic iphoneos Debug build succeeds with automatic package resolution disabled. These are compile checks, not Android/iOS runtime proof. Four golden renders were inspected; no phone or emulator was operated.

Review corrections include preventing a false saved toast while retrying after an earlier successful save, retaining secure sign-out after the age-only page, and keeping the arrow at the right endpoint until navigation replaces onboarding. API copies remain1.2.0. Backend source/status c563f2f and admin1066f39 are pushed; GitHub CI passed those heads (runs39024766234 and39024770130). Mobile CI follows the final push. Focused owner retest: docs/DEVICE_UI_RETEST.md. Task3 remains awaiting device test; no draft PR merge or release promotion is authorized by these automated results alone.


## Task3 integration and Task4 start (2026-10-17)

Owner reports the corrected Android build looks good and explicitly authorizes merge and continuation. PR3 merged into development: backend4c6f11d, admin019a8a9, mobilec156ab2. Main unchanged. Pre-merge rerun: backend5 unit +13 Phase0 +25 PostGIS/Valkey tests; admin2 tests; mobile88 Flutter tests pass. Prior backend/admin CI heads passed. This records owner approval without inventing individual OS/autofill/battery cases or iOS runtime evidence; those release checks remain tracked.

Current: Phase1 Task4, feature/profile-verification branched from merged development. Plan: docs/task4-profile-plan.md.

| Task4 checklist | Status | Evidence / dependency |
|---|---|---|
| Tokens/components and reference substitutions | in progress | Existing approved white theme, black pills and shared vector feedback; extend only reused profile pieces |
| Username/adult/DOB/public-private/CNIC skip tests | in progress | Existing profile tests; expand profile-access suite |
| Profile setup/edit and optional submit/status | in progress | Details slice exists; Task8 blocks real uploads and complete profile |
| Selective badge/save/status rebuilds and disposal | not started | Add widget/Cubit regressions |
| 320/390/768,200% layouts and goldens | not started | Include profile and verification |

Task4 may use test-only pending media fixtures per plan. Production must refuse unavailable uploads; no real CNIC collection, fake successful submission or completed photo setup. Gmail SMTP and Cloudflare R2 remain intended providers; no new service purchase, deployment or credential request is needed for this task.


## Task4 final local verification

Source: backend0b92e85 (privacy/summary) andfc35740 (optional review); admin ec5411f (contract); mobile84d4ca7 (shared design), db7d2db (generated contracts/data) and2f35ddd (profile/review flows). Contract1.3.0 is exported from Nest and identical in all three repos. Dart and TypeScript regeneration have no drift.

Executed: backend lint/typecheck/build,8 unit +13 retained Phase0 +31 real PostGIS/Valkey integration tests pass. Compose migrates0004, and the real proxy/API/outbox/worker/Mailpit signup→adult→profile save/read/summary→verification skip/read→password reset verifier passes, then cleans its synthetic fixture. Admin lint/types/build,2 transport tests and3 installed-Chrome cases pass. Mobile analyzer is clean; all115 Flutter tests and4 Python generator/splash tests pass. Responsive profile/edit/review fixtures cover320/390/768 at100%/200% text, with keyboard cases; own-profile, profile-details and optional-review goldens inspected with bundled fonts. Final offline Android Debug assembly succeeds177 tasks; final unsigned generic iphoneos build succeeds with package resolution disabled. No package installation, external email, personal document upload, device or emulator operation occurred.

Fresh read-only branch review found one Important missing-profile navigation dead end. Reproduced an adult/no-details→review→skip→summary404 journey, added explicit Back to profile setup recovery, and reran the full suite. Generator review also caught Swagger boolean-enum emission as number; an API contract regression now protects boolean consent. A raw database DATE parser mismatch was fixed by selecting explicit calendar text. Skip during fixture upload cancels and ignores late completion; duplicate pending submissions and profile saves are guarded.

Current handoff: mobile docs/TASK4_DEVICE_TESTS.md. Task4 is not marked complete: owner phone retest remains pending; required photo and live CNIC uploads are explicitly blocked until Task8 media processing/private storage/ownership FKs. Full profileComplete remains false, no fake Home/post grid or approved badge is invented. Test-only processed/pending assets establish workflow behavior without collecting images. Task6 eligibility and Task11 reviewer decisions remain separate plan dependencies. iOS runtime, earlier quantitative Phase0 evidence and actual Gmail delivery remain distinct release checks. No Task4 PR merge or main promotion is implied by local checks.


## Task4 approval and Task5 start (2026-10-17)

Owner tested Task4 on physical Android, accepted it and explicitly authorized merge/Task5. PR4 merged into development: backend e3ff075, admin87edbda, mobile0dc6772. Main unchanged. Pre-merge rerun: backend8 unit +13 Phase0 +31 integration tests, mobile115 Flutter tests and admin2 tests pass; backend/admin CI green. This does not invent iOS runtime or quantitative background/battery evidence. Task8 photo/CNIC integration remains pending as planned.

Current phase: Phase2 Task5, feature/location-ingestion. Plan: docs/task5-location-plan.md.

| Task5 checklist | Status | Evidence / dependency |
|---|---|---|
| Max50/coordinates/time/dedup/lease/pause/deletion tests | in progress | Write real PostGIS integration cases first |
| Transactional samples/outbox and24h retention worker | not started | Matching handler remains Task6; no fake matching result |
| Disclosure/staged permissions/encrypted native queue | in progress | Existing native encrypted200/15min queue; production integration next |
| Offline pause/logout epoch ordering | not started | Native cancellation plus persisted pending control and expected-epoch server guard |
| Physical permission/kill cases | awaiting device test | Owner operates phone after final local checks |


## Task5 local handoff (2026-10-17)

Current task: **Phase2 Task5 implemented; awaiting owner physical-device test.** API contract1.4.0 is byte-identical to the real Nest export in all three repositories. Regeneration of Dart and TypeScript consumers has no drift. Branch: `feature/location-ingestion`; main is unchanged. Task4 PR4 was merged after explicit owner Android acceptance, superseding the earlier pending Task4 notes above.

Source commits: backend3179a68 (migration, validation, PostGIS sample/outbox and retention), e6a5c4b (scoped control/ingestion API and integration tests), ef58ff0 (worker/stack verification); mobile bef00be (contract/generator),80c0193 (native upload/permission bridge), fe5fe91 (repository, serialized controls, disclosure UI and tests); admin a42df74 (contract/readiness). Files include backend src/modules/locations, db/migrations/0005_locations.sql and test/integration/location-ingest.spec.ts; mobile lib/features/discovery, both native location trackers, test/features/discovery and tools/generate_api_contract.py; admin generated API types/readiness fixtures. Documentation commits follow these source commits and do not change the tested application.

| Applicable Task5 checklist | Status | Evidence / remaining gate |
|---|---|---|
| Max50/bounds/time/duplicates/old lease/paused/deleting tests | verified |7 real location integration cases plus finite/inclusive policy boundaries; full38-test suite passes |
| Atomic samples/matching intent and24h retention | verified | Concurrent retry dedup, transaction rollback, PostGIS/deletion and session-cascade orphan retention regressions pass; worker rebuilt and healthy |
| Disclosure, staged native permissions, encrypted bounded queue | implemented; awaiting device test | Real native receipt uploader/reachability/backoff and foreground/background choices; analyzer, Flutter fixtures and Android/unsigned iOS builds pass; physical prompts/background/kill not executed |
| Offline pause/logout/epoch ordering | verified in automated models/API; awaiting device test | Local purge, durable scoped stop, stale control/generation, account/device replacement and retry cases pass; owner runtime evidence pending |

Executed checks: backend lint/typecheck/build,9 unit tests,13 retained Phase0 tests and38 PostGIS/Valkey integration tests pass. The final equivalent SQL readability edit was followed by all7 location integration tests passing. Compose built with existing images and --pull never; migration0005 applied, API/worker/proxy/PostGIS/Valkey/Mailpit healthy. Synthetic signup→OTP→adult→profile→lease→ingest/dedup→pause/reject→reset/logout verifier passes and cleans its own fixture. No real email, private document or phone coordinates were uploaded by the implementer.

Mobile analyzer clean; all133 Flutter tests pass. Six Python tooling tests pass, including actual cached Kotlin/Swift endpoint-guard execution, generator shapes and splash geometry. Permission fixtures cover320/390/768 at100%/200% text; refreshed disclosure golden visually inspected with bundled fonts. Final offline Android Debug assembly passes (177 tasks); unsigned generic iphoneos build passes with automatic package resolution disabled. Admin lint/typecheck/build,2 transport tests and3 installed-Chrome cases pass. Contract copies and regeneration drift checks pass. No package/SDK/image installation or emulator/phone operation occurred.

Review correction: one fresh reviewer found auth-session cascades leaving orphan matching intents. A failing real-DB case reproduced it; bounded user-first aged-orphan cleanup now passes that case. Author control tests also reproduced a slow pause using a newer enable generation; generation capture now occurs before the native await. A full integration run hit shared-schema migration-lock timeouts under concurrent builds; test files now run serially while explicit concurrency cases remain active, and all38 pass. Initial sandbox local-socket/telemetry restrictions were rerun with approved local access; those failed attempts are not presented as passing checks.

Device handoff: paths-mobile/docs/TASK5_DEVICE_TESTS.md, source mobile fe5fe91 and backend ef58ff0 (or their subsequent documentation-only heads). Required owner cases: no automatic capture, coarse/precise/denied/settings, separate background choice/notification, leaving the page, API outage then local pause/restart/reconnect, account switch/logout and force-stop/permission changes. Return sanitized status/count/error-reference observations, never coordinates/tokens. iOS needs separate signed device/HTTPS validation; unsigned compilation is not runtime evidence. No unavailable tool/package currently blocks local Task5 checks. Physical access is reserved to the owner.

Known dependencies: Task6 matching/Home remains unimplemented; matching intents stay pending and expire with their observations. Task8 real profile media/CNIC and Task11 review remain deferred as specified. Quantitative Phase0 battery/encounter accuracy/push latency and iOS runtime are still release evidence. Gmail SMTP requires the owner's private configuration; R2 integration remains Task8. Task5 is not complete and dependent Task6 work does not begin before owner results.


Task5 draft PRs into development: [backend#5](https://github.com/awais-ur-rehman/paths-backend/pull/5), [mobile#5](https://github.com/awais-ur-rehman/paths-mobile/pull/5), [admin#5](https://github.com/awais-ur-rehman/paths-admin/pull/5). All remain draft pending the owner device gate. Final branch heads are available on these PRs; application source commits above remain the tested code.


## Task5 acceptance and Task6 start

Owner reports functionality working and asks to continue; Task5 PR5 merged into development (backend535dd86, admin086a234, mobile76e68e5). Main unchanged. Pre-merge rerun: backend9 unit/13 experiment/38 integration, mobile133 Flutter and admin2 tests pass; backend/admin CI green. Specific native OS case outcomes and iOS/quantitative evidence are not invented. User requests less UI copy/fewer competing actions going forward and defers full redesign.

Current branch feature/encounter-discovery. Plan: docs/task6-encounter-plan.md. All six Task6 checklist items in progress, with policy/migration tests first. New API target1.5.0; current exported contract remains1.4.0 until implemented. See the plan for controls, exact thresholds, dependencies and review focus.
