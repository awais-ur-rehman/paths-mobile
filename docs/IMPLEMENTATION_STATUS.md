# Implementation status

Current phase: **Phase1 Task2 verified and merged; Task3 session-refresh component in progress; Task4 not started**. API contract: `1.0.0`; isolated experiment contract remains `phase0.v1`.

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

- [ ] Test OTP purpose/expiry/attempts/resend invalidation, replay, under-18 DOB, password reset revocation and refresh-family reuse. — **not started**
- [ ] Implement signup/login/OTP/recovery with Argon2id and hashed secrets; server guards enforce account status. — **not started**
- [ ] Implement splash, one onboarding screen, auth forms and guarded setup routes. — **not started**
- [ ] Implement single-flight Dio refresh; test ten concurrent 401s produce one refresh, one replay each and no loop. — **in progress — coordinator/interceptor and eleven regressions implemented and locally verified; real auth API and secure-storage wiring pending**
- [ ] Verify keyboard, paste/autofill, offline/error states and suspended-account support/deletion access. — **not started**

### Task 4: Design system, profile and optional verification submission

- [ ] Build tokens/components from UI doc; record reference-to-product substitutions. — **not started**
- [ ] Test username uniqueness, private DOB exclusion, adult gate, public/private response fields and CNIC skip entitlement. — **not started**
- [ ] Implement profile setup/edit and verification submit/status against upload contracts from Task8 (use mocked pending asset until then). — **not started**
- [ ] Add selective rebuild checks for badge/save/status and controller disposal tests where relevant. — **not started**
- [ ] Verify layouts at 320/390/768 widths and 200% text; add meaningful golden tests with approved assets. — **not started**

## Phase 2 — location ingestion, matching and discovery


### Task 5: Consent-aware ingestion

- [ ] Test max50 batch, invalid coordinate, future>30sec, stale>15min, duplicate ID, old device lease and paused/deleting account rejection. — **not started**
- [ ] Implement transactionally stored sample/outbox records and 24h retention worker. — **not started**
- [ ] Integrate disclosure, staged native permissions and bounded encrypted queue; never upload after local pause. — **not started**
- [ ] Test offline control ordering: pause/logout clears queued fixes and invalidates prior epochs before any resume batch. — **not started**

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
