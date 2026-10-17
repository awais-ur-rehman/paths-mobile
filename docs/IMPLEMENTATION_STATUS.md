# Implementation status

Current phase: **Phase4 Task8 protected media; implemented, awaiting Android device evidence**. API contract: `1.7.0`; experiment contract `phase0.v1`.

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
- [ ] Integrate disclosure, staged native permissions and bounded encrypted queue; never upload after local pause. — **owner functional acceptance; integrated in development — native uploader/disclosure and local checks pass; unreported detailed OS/iOS evidence remains separate**
- [ ] Test offline control ordering: pause/logout clears queued fixes and invalidates prior epochs before any resume batch. — **verified in automated models/API and owner functional acceptance recorded — stale generation/account switch/purge/retry regressions pass; detailed native runtime observations remain separate**

### Task 6: Encounter matcher and privacy-safe Home

- [x] Write boundary tests for <=50m/<=60sec and accuracy rules; two evidence pairs 20–120sec apart; reject invented stationary dwell. — **verified locally — 15 unit tests and 13 Phase0 regressions; conservative inclusive limits and independent advancing observations**
- [x] Test concurrent inverse ingestion creates one session and two notification intents; retry does not inflate encounter count. — **verified locally — real PostGIS concurrency, retry, ordered late jobs, notification rollback/replay and session-gap cases**
- [x] Test spatial neighbors across arbitrary grid edges, adjacent venue false positives and delayed historical batches without live push. — **verified locally — cross-cell exact spatial query, uncertainty rejection and historical-no-live-intent regressions; field accuracy remains separate**
- [x] Implement PostGIS query, pair lock/session dedup and coarse-area/time serialization; exclude blocked/paused/deleting users. — **verified locally — migration0006, ordered user/pair locks, durable proof and per-session intents, authorized API1.5.0 and retention/erasure tests**
- [ ] Build map/list Home with Recent/Nearby, radius filters and permission/offline/map-failure states. — **implemented and locally verified; awaiting device test — 153 Flutter tests, inspected Home golden and offline Android build; native map/attribution/physical behavior pending; unsigned iOS compile now passes**
- [ ] Verify API responses and network captures contain no peer coordinates, exact distances or exact timestamps. — **API serialization verified locally — live HTTP and DTO allowlist tests expose only coarse areas/date buckets; owner runtime network inspection pending**

## Phase 3 — saves, requests and push


### Task 7: Relationship policy and notifications

- [x] Test ineligible target denied, private save invisible to subject, saved eligibility survives history expiry. — **verified — private/directed/durable/unsave API tests**
- [x] Test inverse request race, sender accepting own request, duplicate accept, expired request and seven-day cooldown. — **verified — canonical concurrency, idempotency, expiry/cooldown tests**
- [x] Implement atomic pair transitions and unique constraints; no implicit connection from reciprocal request. — **verified — migration0007, pair locks, rollback and inverse-race tests**
- [ ] Implement Saved/Incoming/Sent screens with status, cancel/accept/decline and unavailable states. — **implemented and locally verified; awaiting device test — mobile Likes/profile controls, responsive/state tests**
- [ ] Implement FCM/APNs device registration and transactional notification fan-out; generic payloads, pair six-hour cooldown, user cap default ten encounter alerts/day with in-app history unaffected. — **implemented and locally verified; real delivery blocked — no Firebase/APNs setup; native compile/provider fixtures are not device evidence**
- [x] Test notification worker retry, invalid token cleanup, opt-out, delayed historical match, block/deletion between enqueue and send. — **verified locally —14 notification integration cases and provider fixtures; real provider/device tests pending**

## Phase 4 — media and messaging


### Task 8: Protected media and camera publishing

- [ ] Test wrong owner/type/size, decompression abuse, EXIF removal, private viewer denied and pending asset unpublished. — **verified locally — real HTTP/PostgreSQL and Sharp tests; device transport/OS evidence pending**
- [ ] Implement private storage adapters, quarantine processing, variants and CNIC record retention; no public CNIC links. — **implemented and verified locally — encrypted FS and local S3 protocol fixture; real R2 setup/test deferred by owner**
- [ ] Add safety-review state for user-visible images, neutral pending avatar, pending posts and server text filtering; test unreviewed/rejected content never reaches public responses. — **implemented and verified locally — pending/rejected denial, neutral avatars, reusable limited pilot text policy; real staff review is Task11**
- [ ] Connect profile/CNIC screens from Task4 to real uploads; implement camera/gallery/preview/caption/retry/cancel. — **implemented and verified locally — camera/gallery/preview/caption/retry/cancel and real profile/CNIC uploads; awaiting Android device test**
- [ ] Test privacy/block/deletion revokes media access; worker must not publish after deletion barrier. — **verified locally — canonical authorization, worker deletion races and immediate Disconnect UI revalidation; iOS runtime pending**
- [ ] Add orphan/multipart cleanup and object inventory for deletion manifest. — **implemented and verified locally — bounded cleanup, source retirement, multipart enumeration and durable inventory for Task12**

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

## Task6 evidence and handoff — 2026-10-17

Status: **implemented, locally verified, awaiting physical Android evidence; unsigned iOS build verified**. Task6 is not complete and Task7 is gated. API contract is1.5.0. Task5 PR5 was merged into development after owner functional acceptance; this does not supply unreported Phase0 battery/accuracy or iOS results. Main remains the documentation baseline.

Changes: exact PostGIS neighbor search and conservative two-pair corroboration; canonical locks, retry-safe proof/session/notification intents and bounded retention; authorized coarse Recent/Nearby cards and peer summaries; concise Home, contextual filters, map/list fallback and persistent Home/Profile navigation. No push is sent until Task7 and no fake photo/profile completion is claimed before Task8. Existing permission-screen redesign is deferred to the owner's later screen-by-screen pass.

Actual checks after source fixes:
- Backend: lint/typecheck/build pass;15 unit,13 Phase0 and52 isolated PostgreSQL/PostGIS integration tests pass, including13 encounter cases. Migrations retain bounded DDL timeouts separately from application requests.
- Real existing Compose stack: build/health/migration0006 pass with --pull never. auth:verify passes API/worker/Mailpit/signup/profile/location/pause/reset. encounters:verify passes real API/worker synthetic matching, deduplication, coarse listing/peer access and pause hiding. No Gmail, R2 or real user data is used.
- Mobile: analyzer clean;153 Flutter tests and7 Python generator tests pass. Home golden inspected and responsive320/390/768 widths at100%/200% text pass. Android debug APK assembled offline using installed JDK21; compilation does not establish native map rendering or encounter accuracy.
- Admin: generation/lint/typecheck/build pass;2 transport tests and3 Chromium tests pass. No new admin workflow in this task.
- Contract: actual Nest export is byte-identical across all repositories; regenerated Dart and admin types have no drift. git diff --check passes.

One fresh read-only whole-branch review identified peer replacement retaining the previous cubit, append pagination moving the map center, and retention erasing active-session intent deduplication. Each was reproduced by a failing regression and fixed; relevant full suites reran green. Author checks also fixed implausible device movement, private pending/declined badge leakage, Recent following a new own location, Swagger's inferred Object schema and migration DDL budgets. Inspection cannot prove OS scheduling, native SDK rendering, real encounter precision/recall, battery or signed iOS behavior.

Resolved iOS prerequisite: owner approved only the required MapLibre download. Xcode resolved MapLibre Native6.28.0 at revision5ee345ca5d65238a6fce29bba87816204be7df20 and generated the committed Package.resolved. Unsigned generic iphoneos Debug build then passed with automatic package resolution disabled and resolved-file-only mode enabled. Embedded MapLibre framework verified; Info.plist/entitlements lint passed. Original BSD2-Clause license retained in mobile docs/licenses/maplibre-native-ios-6.28.0.txt. No additional SDK/tool/package was installed. Signed physical iOS, HTTPS endpoint, map rendering/attribution and permission/background behavior remain unverified.

Physical test instructions: paths-mobile/docs/TASK6_DEVICE_TESTS.md. Test feature/encounter-discovery; source commits backend80dfda7, mobile68f7ed1, admin17bf501. Later commits only record evidence/handoff. PR links and final branch heads are recorded below after push. Source and generated configuration contain no credentials; preserve ignored local env and existing Docker volumes.


### Task6 pushed branches

- paths-backend: [draft PR6](https://github.com/awais-ur-rehman/paths-backend/pull/6), verification/handoff commit `7fe1d38`, branch `feature/encounter-discovery` → `development`.
- paths-mobile: [draft PR6](https://github.com/awais-ur-rehman/paths-mobile/pull/6), verification/handoff commit `c60a93b`, branch `feature/encounter-discovery` → `development`.
- paths-admin: [draft PR6](https://github.com/awais-ur-rehman/paths-admin/pull/6), verification/handoff commit `4b696a1`, branch `feature/encounter-discovery` → `development`.

These commits contain final source evidence/handoff; subsequent linkage commits change documentation only. Drafts remain unmerged pending owner runtime results. Main has not changed.


### Approved iOS dependency follow-up

MapLibre Native6.28.0 resolution and unsigned iOS build now pass; this supersedes the previous missing-dependency blocker. Only the approved MapLibre package/binary was fetched; existing local Flutter packages were retained. The real generated pin and BSD license are in the mobile repository. No application behavior changed and broader unit/widget suites were not rerun for this native dependency-only follow-up. Task6 remains awaiting owner physical results; draft PR6 stays unmerged and main unchanged.

Native dependency follow-up commit: mobile `68f7ed1` adds the actual Xcode-generated MapLibre pin and copied BSD notice; Dart application behavior is unchanged. Use this commit or the latest feature/encounter-discovery head when repeating iOS checks.

## Profile UI feedback follow-up — 2026-10-17

Current task: **Task6 device retest, with requested profile UI changes implemented and locally verified; awaiting owner Android feedback**. API remains1.5.0. Backend/admin application source and contracts are unchanged; their previous evidence was not rerun for this mobile-only update. Task6 remains incomplete and PR6 stays draft; no main promotion or Task7 advance.

| Requested behavior | Status and evidence |
| --- | --- |
| Creation has one Next action that saves before advancing | implemented, verified locally — real repository/form route tests; validation/conflict retain edits, pending retry cannot navigate early, duplicate saves guarded |
| Themed custom gender dropdown and option menu | implemented, verified locally — shared PathsDropdownField; selection/validation/reopen/controlled update/disabled/Escape/system-back/open-menu teardown and320px/200% text tests |
| Visibility row contains only toggle and label | implemented, verified locally — no subtitle; public/private persists through Next/edit |
| Minimal Verification heading/copy and side-by-side dotted front/back slots | implemented, verified locally — both server and real local adapter readiness required; no real CNIC collection before Task8; Submit disabled, Skip persists; review details/consent retained for enabled future media |
| Refresh pending/approved/declined status without an extra action button | implemented, verified locally — pull refresh on short scroll surfaces, with Paths loader; skips refresh during active operations |
| Reference profile cover/centered identity/framed bio with supported actions only | implemented, verified locally — shared owner/eligible peer ProfileSurface; neutral unavailable-photo cover; no fabricated people/gallery/follow counters/actions; owner controls in one options menu, including loading/errors |
| Physical layout, keyboard, menu/back gestures and native rendering | awaiting device test — docs/PROFILE_UI_RETEST.md; separate Task6 matching/map checklist remains open; signed iOS runtime unverified |

Actual final checks: analyzer clean; all163 Flutter tests and7 Python tooling tests pass; Android Debug assembled offline (197 Gradle tasks); unsigned generic iphoneos Debug build passes with automatic resolution disabled and pinned-file-only mode. No package/tool/asset download. Updated profile-details, optional-verification and own-profile goldens inspected;320/390/768 widths at100%/200% text pass. git diff --check passes. The first full run exposed an outdated location-menu test; updated it to open the actual options menu and reran the full suite successfully.

One fresh read-only review found four issues. Failing regressions reproduced each before fixes: header vertically centered by expanded Stack, summary error hiding signout/options, pending review unable to refresh, and backend-only upload readiness. All four regressions pass after correction. Source inspection does not prove physical gestures/OS behavior or real media readiness. A formatter telemetry sandbox warning was resolved by rerunning formatting with required local SDK access; final formatting/analyzer pass.

Source commits: f2ace5f (dropdown),7fc83d5 (one save action),06e2f33 (verification/refresh/readiness),b5e09ac (profile surface/options/routing). Test source b5e09ac or later documentation-only head on feature/encounter-discovery. Existing draft: https://github.com/awais-ur-rehman/paths-mobile/pull/6 . Follow docs/PROFILE_UI_RETEST.md before accepting the changed visuals; Task6's broader physical evidence remains pending.


## Task6 approval and Task7 start

Owner tested the current mobile build on a physical Android phone, accepted it and explicitly authorized PR merges and Task7. PR6 merged into development: backend158919e, admin dabf953, mobile2af063d. Main unchanged. Pre-merge verification: backend15unit/13Phase0/52integration, mobile163Flutter, admin2transport/3browser and lint/type/build checks pass; backend/admin hosted CI green. First concurrent backend run timed out creating the isolated test database; isolated rerun passed. This acceptance does not invent case-by-case paired-phone/network/battery or signed iOS results.

Task7 execution: feature/relationships-notifications branched from each merged development head. See task7-relationships-plan.md for every step and dependencies. Push project/APNs setup requested from the owner; no credentials/config files present in source. Continue independent relationships/in-app notification work while genuine provider/device evidence is pending. No service creation or deployment authorized.

## Task7 implementation and local evidence — 2026-10-17

Status: **implemented, locally verified, awaiting device test; real push blocked on owner setup**. API1.6.0. Branch `feature/relationships-notifications` in all three repositories. Task8 is not started through the pending Task7 device gate; main remains unchanged. Backend source584812f, mobile8ee055f, admin4df3afd; subsequent commits record checks/instructions only.

Coverage/files: backend migrations0007–0009 and modules/relationships, modules/notifications, outbox/dispatcher and worker implement private directed saves, canonical pair/request transactions, idempotency,14-day expiry, seven-day cooldown, status pages, encrypted session/install-bound tokens, inbox/preferences/resolution/read, durable fanout and FCM/APNs adapters. Mobile features/relationships and features/notifications, shared authenticated transport, native Android push/PathsPush.kt and iOS/PathsPushNotifications.swift implement Likes Saved/Incoming/Sent, profile actions/confirmation, working Home/Likes/Profile navigation, inbox/preferences, opt-in OS permission/token/tap handling and logout cleanup. Admin consumes the real1.6 export/readiness version; its business portal remains scheduled for Task11.

Checks actually executed:
- Backend lint, TypeScript build/typecheck: passed. `npm test`:19 unit +13 Phase0 passed. Full `npm run test:integration`:74 passed, including8 relationship and14 notification cases. Real PostgreSQL/PostGIS/Valkey used; push transport fixtures isolated from live providers.
- Compose rebuilt with existing images and `--pull never`; migration0009 and service health passed. `stack:verify`: restart persistence, recovered worker probe, nonroot and clean shutdown passed. `auth:verify`, `encounters:verify`, and `node --env-file=.env.local dist/scripts/verify-relationships.js`: synthetic real HTTP/worker checks passed. No real provider send occurred.
- Mobile `analyze --no-pub`: passed with no issues. Full Flutter suite187 passed; explicit request confirmation, save rollback, intent retry keys, cancellation/account-switch races, tab/return refresh, preferences and inbox320/390/768px at200% included. Likes render inspected with bundled fonts/icons. Seven Python/native policy/generator tests passed with cache access. All three OpenAPI artifacts match byte for byte; Dart/TypeScript consumers regenerated from the real export.
- Native Android Debug assembly passed after owner-approved Firebase common/installations artifact downloads; a later strict offline assembly passed. Unsigned generic iOS Debug compiled the APNs bridge with automatic package resolution disabled/resolved-file-only mode. These are compile checks, not device delivery evidence.
- Admin lint/build/types,2 transport tests and3 local Chromium checks passed with API1.6 readiness fixtures.

Review corrections and observed failures:
- One fresh whole-branch read-only review found three issues: a failed push clear could skip tracking cleanup; cross-screen saves could leave stale Home/Likes state; cooldown pair metadata never expired. Independent cleanup attempts, route/tab refresh and bounded indexed six-hour cooldown deletion now cover these. A separate reproduced regression showed restore clearing push opt-in on every refresh; restore now preserves valid-session opt-in and logout still clears it. Tests cover the failure paths. Expired cooldown retention and restore tests were observed failing before their fixes.
- Active encounter dedup parents must outlive30-day inbox cards; the notification retention regression was reproduced and fixed without deleting active encounter intents.
- Full integration initially failed because two relationship tests counted unrelated request fixtures globally; assertions now scope their own participants and full74 rerun passed. Initial admin browser fixtures still advertised1.5; updated to1.6 and all3 passed. A screenshot fixture required runAsync for actual file writes; fixed and rerendered. Initial sandbox native-policy probe lacked Swift cache access; authorized rerun passed. One overlapping stack-check run stopped the worker under another check; isolated rerun passed, without changing service/database budgets. Idle PostgreSQL disconnect during the intentional restart emits the existing safe database_connection_failed event.
- Initial offline Android build identified firebase-common22.0.1 and firebase-installations19.1.1; owner then authorized only required Android push/transitive dependencies. No other SDK/tool/package/image was installed for this task. Existing Gradle deprecation warnings remain; no speculative AGP migration.

Material decisions (confirmed product rules versus implementation defaults):
- Confirmed: private saves do not notify subjects; no reciprocal auto-accept;14-day requests, seven-day cooldown; generic push; per-recipient/pair6h and ten encounter alerts/UTCday; current authorization always rechecked. Directed save eligibility and pause preserving established saved/request/connected eligibility follow optional location/durable save rules. Cost if a stricter pause policy is chosen later: tighten that eligibility predicate; no extra location retention was introduced.
- Proposed defensive defaults:60/account-hour relationship mutations with IP/install buckets; max5 push registrations/account; monotonic persisted install generation; encounter push staleness120sec/request24h; inbox30days; closed request minimal IDs retained without arbitrary new TTL. Wrong defaults can be changed centrally, but require policy/data-migration review where retention changes. No values are represented as measured field results.
- Native Android cached Firebase Messaging25.1.3 plus system APNs avoids an extra Flutter/Firebase iOS SDK dependency. Cost: maintain the small native bridges and validate each signed device platform separately.

Outstanding prerequisites/known limits: owner explicitly reports no Firebase/APNs setup. Real Android foreground/background/locked-phone delivery, token rotation, OS permission changes and taps must be tested after private setup. iOS needs Apple team capability/provisioning and a signed physical iPhone; unsigned build and Android evidence do not validate it. At-least-once provider delivery can duplicate after a provider acceptance/database failure; Android event binding/dedup and collapse IDs reduce repeats, never promise exactly once. Already accepted APNs generic alerts may arrive after logout; server tap resolution still denies former-account access. OS force-stop/power/network behavior is best effort. See PUSH_SETUP.md and mobile TASK7_DEVICE_TESTS.md. No invented battery/accuracy/push outcome, no deployment or cloud-service creation.

Published Task7 drafts (base development, head feature/relationships-notifications): [backend PR7](https://github.com/awais-ur-rehman/paths-backend/pull/7), [admin PR7](https://github.com/awais-ur-rehman/paths-admin/pull/7), [mobile PR7](https://github.com/awais-ur-rehman/paths-mobile/pull/7). All three branches were pushed. Task7 is not merged; real push/device gate is pending. Main unchanged. Owner next action: mobile docs/TASK7_DEVICE_TESTS.md; private push configuration is separately documented in PUSH_SETUP.md.

## Task7 owner approval and Task8 start — 2026-10-17

Owner tested Task7 on their physical Android phone, approves its functionality and authorizes merging PR7 and continuing Task8. Owner explicitly defers Firebase/APNs setup/live delivery; retain that unexecuted Android/iOS runtime check as a release prerequisite, not a passed result. PR7 merged normally into development in all three repositories after clean exact heads, green hosted backend/admin checks and fresh local74 integration,19unit13Phase0,187Flutter,admin2transport+3browser checks. No main promotion. Merge bases: backend4e6278f, admin afb2125, mobile8e85b0a. Task8 branch feature/protected-media; plan docs/task8-media-plan.md. All six specification checklist items are in progress/not started as detailed in the plan; implementation begins with image/storage security tests. API remains1.6 until the real media export. Owner approved required Task8 Sharp/image_picker and required artifacts; caches first. No Firebase/Apple/cloud service creation or real personal upload.


## Task8 implementation and local verification — 2026-10-17

Status: **implemented, locally verified, awaiting owner Android test**. Phase4 remains open; Task9 has not started. API1.7.0, SHA256 `9132509ecbef5e833a30e5c6cbec7106f257eba7a109ca736f1ac60b98e3bf54`. All three repositories use feature/protected-media; main unchanged. Source checkpoints: backend e1a5a86 (storage24bd974, upload/posts8615dd2, recovery/access6399af6, quota f46a3ef), mobile8670cbb (transport/native2ae4c8b, screens14dd691), admin67af1e5. Subsequent commits record this evidence and instructions.

| Task8 requirement | Result / evidence |
| --- | --- |
| Wrong owner/type/size, decompression, EXIF and unpublished pending assets | verified locally — real PostgreSQL/HTTP integration and constrained Sharp decode tests; encrypted key-context/MIME binding; wrong-side/foreign CNIC denied |
| Private FS/R2 adapters, quarantine/variants and CNIC lifetime | implemented and verified locally — encrypted source/variants, separate document namespace, source retirement after commit, retained submitted/replaced documents; S3 protocol test is local, real R2 deferred |
| Safety state, neutral pending avatars/posts and text filtering | implemented and verified locally — rejected and unreviewed media excluded from peer reads, pending owner previews, approved references only, narrow reusable text rules; staff UI remains Task11 |
| Profile/CNIC and camera/gallery/preview/caption/retry/cancel | implemented and verified locally — Task4 real uploads connected, one Next at creation, modal Camera, pending grid/detail/delete, bounded retries and guarded binary refresh; owner phone evidence pending |
| Privacy/block/deletion revocation and worker barrier | verified locally — canonical authorization locks, deletion before/during processing, stale account response guards, immediate Disconnect grid/pixel revalidation |
| Orphan/multipart cleanup and deletion inventory | implemented and verified locally — committed inventory before writes, root-deletion survival, acknowledged deletes, bounded multipart traversal, native temporary-file cleanup; Task12 owns the independent erasure orchestrator |

Actual checks:

- Backend ESLint and TypeScript build/typecheck pass. `npm test`:29 unit and13 retained Phase0 tests pass. Full isolated PostgreSQL/PostGIS/Valkey integration suite:88 tests pass;14 are media-access cases. A fresh test database prevents the development worker consuming fixtures.
- Real local Compose build/migration/proxy/API/outbox/worker smoke passes. Synthetic authenticated upload becomes metadata-stripped JPEG variants and an owner-only pending post; synthetic account erasure removes its object inventory. Only private local storage was exercised end to end.
- Mobile analyzer: no issues. Full `flutter test --no-pub`:202 tests pass. Seven Python contract/native-policy/splash tools tests pass. Six photo-preview cases cover320/390/768 at100%/200% text; actual bundled-font preview golden inspected. Existing profile/auth goldens remain passing.
- Android Debug assembled offline with installed JDK21 and SDK:235 Gradle tasks. Unsigned generic iphoneos Debug compiled with automatic resolution disabled and the existing project-level resolved package file. These prove compilation, not OS/device behavior. Existing Gradle/AGP deprecation warnings remain.
- Admin ESLint/typecheck/build,2 transport tests and3 installed-Chrome tests pass. Health/version fixtures now use1.7. Real OpenAPI export and both client generators have no drift; the three raw contract copies match exactly. `git diff --check` passes.

Review scope and fixes:

One fresh read-only whole-branch review reported an active-lease redelivery that could strand an image and stale private posts after Disconnect. Both were reproduced as failing regressions and fixed: active leases remain retryable, and relationship changes clear pixels/revalidate posts and detail. Self-review regressions also cover source recovery after transaction failure, symlink confinement before directory creation, ciphertext context substitution, declared MIME mismatch, rejected-content denial, original-file cleanup after native picking, detached-avatar deadlines without changing upload creation dates, and daily quota cancellation/replay behavior. Inspection does not establish real R2 permissions or native OS cleanup/permission behavior; those require the separate runtime checks below.

Earlier development runs exposed outdated profile/FK/version fixtures, a narrow preview control overflow, a PostgreSQL restart during a test run, sandbox socket restrictions and the first Xcode invocation selecting the wrong resolved-file location. Fixtures/layout/commands were corrected and the final checks above were rerun successfully. No failed or unexecuted attempt is counted as passed. Local backend/admin packages and image binaries were resolved under existing approvals; no SDK, emulator, plugin or new service image was installed.

Pending prerequisites and gate:

- Owner physical Android camera/gallery/permissions, interruption/retry/cancel, process-loss and account-switch evidence: see `docs/TASK8_DEVICE_TESTS.md`, with exact commands/checkpoints and original synthetic cards in docs/testing/media. Await results before Task8 completion/PR merge or Task9.
- Real R2 bucket/keys are not configured; owner explicitly chose private local storage for now. The live R2 check remains pending. Credentials stay in ignored local environment files.
- iOS physical runtime/signing, Firebase/APNs setup/live delivery and quantitative Phase0 field results remain separate release evidence. Android acceptance does not verify iOS.
- Actual image/CNIC staff review, appeals and authorization are Tasks10/11. Real uploads remain pending until that workflow exists; no fake approvals or staff-success routes were introduced.

No real personal images/documents, credentials or raw coordinates were committed or uploaded by these checks. No deployment, purchase or app-store submission occurred. Feature PRs remain draft for the device gate; PR links and final docs heads are recorded in the handoff.


Task8 handoff links (all draft, base development):

- Backend: https://github.com/awais-ur-rehman/paths-backend/pull/8
- Mobile: https://github.com/awais-ur-rehman/paths-mobile/pull/8
- Admin: https://github.com/awais-ur-rehman/paths-admin/pull/8

All three feature branches and their verification records are pushed. Source checkpoints remain those recorded above; subsequent changes are documentation only. Mobile has no hosted workflow; its native/static/test checks were run locally. Android owner acceptance remains pending. No PR8 merge or main promotion occurred.

Hosted verification passed for backend777e4b3 ([run39039682108](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39039682108)) and admin e4ba53f ([run39039680971](https://github.com/awais-ur-rehman/paths-admin/actions/runs/39039680971)). Later commits add PR links/documentation only; their current checks remain visible on the draft PRs. No mobile hosted check is configured.
