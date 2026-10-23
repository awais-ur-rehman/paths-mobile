# Implementation status

Current phase: **Phase 6 Task13 load, security, battery and UI hardening; in progress**. Task12 phone/restore acceptance received and PRs merged; main unchanged. API contract1.11.0.

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

- [x] Test send before accept denied; sender spoof denied; text>4000 denied; same client ID inserts once. — **verified locally; Task 9 accepted by owner — see acceptance entry below**
- [x] Test concurrent block/disconnect/delete vs send using consistent locks; no unauthorized post-commit delivery. — **verified locally; Task 9 accepted by owner — see acceptance entry below**
- [x] Implement REST persistence, server-assigned sockets and cursor catch-up; ACK only after commit. — **verified locally; Task 9 accepted by owner — see acceptance entry below**
- [x] Implement chat list/thread, lazy history, pending/failed retry, unread state and read-only disconnected history. — **verified locally; Task 9 accepted by owner — see acceptance entry below**
- [x] Test disconnect/reconnect with missed/duplicate/out-of-order events; deleted conversation removed from caches on sync. — **verified locally; Task 9 accepted by owner — see acceptance entry below**

## Phase 5 — moderation and admin


### Task 10: Blocking/reporting and restricted account lifecycle

- [x] Test block removes both saves, cancels requests, stops sends, excludes discovery and revokes private media; unblock restores nothing automatically. — **verified locally; owner accepted Task 10 on their phone — see acceptance entry below**
- [x] Implement report categories, scoped evidence and acknowledgment; privacy-aware evidence deletion hooks. — **verified locally; owner accepted Task 10 on their phone — see acceptance entry below**
- [x] Implement deactivation/reactivation status guard, session revoke and queue suppression. — **verified locally; owner accepted Task 10 on their phone — see acceptance entry below**
- [x] Add support/delete access for restricted users and suspected-underage escalation flow. — **verified locally; owner accepted Task 10 on their phone — see acceptance entry below**

### Task 11: Admin portal and review workflow

- [x] Test reviewer/moderator/admin permission matrix and unauthenticated CNIC access denied. — **verified — 18 staff integration cases include role matrix and unauthenticated document denial**
- [x] Implement staff provisioning/MFA/session/CSRF; shadcn shell, server-paginated lists and typed clients. — **verified locally — provision/recovery, MFA replay/attempts, session expiry, CSRF and typed paginated portal**
- [x] Implement protected no-store CNIC viewer, claim/version conflict, approve/decline and notification. — **verified locally — exclusive/expired claims, version conflicts, audited no-store bytes and atomic updates**
- [ ] Implement image safety-review queue and text-filter escalation/appeals, with required pilot staffing. — **implemented and locally verified; blocked — actual pilot staffing/coverage has not been supplied**
- [x] Implement deactivation/reactivation, reports and redacted audits; no unrestricted private-message browser. — **verified locally — reasoned status/report actions, redacted audit and scoped submitted evidence**
- [x] Verify mobile-width admin usability, keyboard navigation and sensitive-content no-cache behavior. — **verified locally — Chrome at 320/390/1280px, keyboard/Escape and expired-session object URL cleanup; owner browser acceptance pending**

## Phase 6 — deletion, robustness and load


### Task 12: Complete account erasure

- [x] Seed two connected users with messages, posts, CNIC versions, reports, locations, caches and queued jobs; test deleting one leaves zero personal records and removes the shared conversation. — **verified — synthetic graph, shared-chat removal, locations/media/CNIC revisions/reports/queued work tests pass**
- [x] Test FK constraints after deletion, another unrelated conversation unaffected, and staff audit anonymization without copied subject PII. — **verified — FK integrity, unrelated conversation and anonymized audit tests pass**
- [x] Implement immediate barrier/revocation, encrypted independent manifest, external object/provider purge and bounded DB cascades. — **implemented and locally verified — immediate barrier, encrypted independent journal, durable retry, R2/recovery purge and bounded cascades; social providers remain Task14**
- [x] Inject failures after each stage; retry completes without losing manifest or recreating assets. — **verified — checkpoint, storage failure, rollback, duplicate/concurrent erasure and recovery regressions pass**
- [x] Implement in-app reauth/delete/receipt and external email-OTP deletion path; validate offline request does not show false success. — **implemented; automated checks verified; awaiting device test — password/receipt/cleanup and public OTP recovery/offline/browser tests pass**
- [x] Implement backup expiry/suppression ledger; restore a pre-deletion backup in isolation and prove deleted data is removed before serving traffic. — **implemented and locally verified; awaiting owner restore sign-off — actual isolated pre-deletion pg_dump restored/suppressed, managed backup expiry and restore barrier tested**
- [x] Verify counterpart cache invalidation on reconnect and disclosure of screenshots/backup timing limits. — **implemented; awaiting counterpart device test — server revocation generation/reconnect tests and screenshot/backup disclosures verified locally**


Owner acceptance2026-10-18: phone tests and restore checks passed; Task12 merged. Earlier pending labels describe pre-acceptance evidence. Separate iOS runtime and production operational prerequisites remain open.

### Task 13: Load, security, battery and UI hardening

- [ ] Test 50 samples/sec sustained, 200/sec burst, 300 socket clients, all candidates in one area; measure query plans/locks and outbox lag. — **in progress — dense processing now completes and drains; five-second encounter gate still pending; see testing/task13-evidence.md**
- [x] Test Valkey restart, worker crash, database restart, upload cancellation and SMTP/push outage; recover committed work. — **verified locally — four isolated service faults and upload/push transport regressions passed; real vendor/APNs evidence remains separate**
- [x] Run authorization enumeration, rate-limit, token replay, CSRF, private-media and secrets/log-redaction checks. — **verified locally — complete172-test backend integration suite including quotas, replay, CSRF, media and redaction passed**
- [ ] Repeat battery/coverage experiment using production integration, not only the Phase0 harness. — **awaiting device test — production journey, eight-hour battery tooling and labeled coverage template implemented; no field results claimed**
- [ ] Profile rebuilds/map offscreen behavior/image memory; fix demonstrated regressions. — **implemented and partly verified — hidden image/map regressions pass; native frame/RSS/rebuild profiling awaits owner**
- [ ] Complete accessibility/text-scale/reference screenshot comparisons and update honest product limitations. — **partly verified —276 Flutter tests/goldens and15 browser cases passed; native accessibility/reference acceptance pending**


## Phase 7 — final feature: Google and Apple authentication


### Task 14: Provider login and safe linking

- [x] Test invalid audience/issuer/nonce/expired token and signature rotation; use test verifier fixtures, never production credentials in repo. — **verified locally — signed fixture validation, key rotation, fetch limits/backoff and native presenter allowlists; no production credentials in tests**
- [x] Test same-email collision does not merge; existing-account reauthentication required; provider+subject unique. — **verified locally — explicit linking and account-bound candidates; collision, OTP/signup, unique-subject and concurrent last-method regressions**
- [x] Implement Google and Apple SDK flows, cancellation handling, Apple relay/name-first-login behavior and missing email recovery. — **implemented; automated checks verified — cached native SDK flows, quiet cancellation, fresh nonce, relay/name and missing-email steps; live-provider acceptance pending**
- [x] Integrate profile/adult onboarding and secure provider reauthentication for delete. — **implemented; automated checks verified — existing adult/profile routing, secure Paths sessions and action/session-scoped provider deletion proof; device walkthrough pending**
- [x] Add Apple token revocation to deletion workflow, test provider outage retry; prevent removing last sign-in method. — **verified locally — encrypted revocation outbox/manifests, outage retry, bounded cleanup progress, restore replay and last-method protection**
- [ ] Verify both providers on real signed iOS/Android builds as supported by configured provider flows; recheck login-service store requirement. — **awaiting device test / blocked by configuration — Google OAuth clients and Apple Developer capability/key setup missing; Android and unsigned iOS compile, policy review recorded; no real signed login evidence**

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

Status: **implemented, locally verified, awaiting owner Android test**. Phase4 remains open; Task9 has not started. API1.7.0, SHA256 `9132509ecbef5e833a30e5c6cbec7106f257eba7a109ca736f1ac60b98e3bf54`. All three repositories use feature/protected-media; main unchanged. Source checkpoints: backend e1a5a86 (storage24bd974, upload/posts8615dd2, recovery/access6399af6, quota f46a3ef), mobile55e0110 (transport/native2ae4c8b, screens14dd691, setup6f278ca, camera cleanup14f664d, session routing55e0110), admin67af1e5. Subsequent commits record this evidence and instructions.

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
- Mobile analyzer: no issues. Full `flutter test --no-pub`:212 tests pass. Seven Python contract/native-policy/splash tools tests pass. Six photo-preview cases cover320/390/768 at100%/200% text; actual bundled-font preview golden inspected. Existing profile/auth goldens remain passing.
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


Task8 final mobile checks: source55e0110 includes server-authoritative profile/verification resume, per-account device permission education, and cancellation cleanup for the cached Android picker camera-file naming scheme. All212 Flutter tests pass, analyzer has no issues, all7 Python tool tests pass; Android Debug assembles offline (235 tasks) and unsigned generic iphoneos Debug compiles with package autoresolution disabled. Setup regressions cover completed returning accounts, mandatory incomplete setup, optional verification skip, failed education persistence/retry, and protected destinations during signed-out and delayed secure-session restoration. The focused follow-up review identified loss of a cold-start destination; capture now precedes boot/auth redirects and clears on actual account switch/logout. A second regression reproduced the router revisiting its old protected URI during sign-out;55e0110 suppresses that stale destination until login/onboarding, so a later sign-in starts fresh. The real logout/sign-in widget test passes. Camera cleanup tests retain unrelated files and symlinks. These checks do not establish physical OS behavior.

Hosted checks passed at backend32f4997 ([run39039893496](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39039893496)) and admin2e682bf ([run39039891388](https://github.com/awais-ur-rehman/paths-admin/actions/runs/39039891388)). Later handoff updates are documentation only. Draft PR8/device gate remains pending.


## Task8 acceptance, photo-cleanup follow-up and work hold — 2026-10-17

The owner initially accepted Task8 on physical Android and authorized PR8 merges, then reported "photo cleanup not completed" while selecting/uploading a photo. Backend PR8 merged into development at4296874 and admin PR8 at97d7db1 after current CI and local tests passed. Mobile PR8 remains draft and unmerged; the reported failure reopens its Android gate. Main is unchanged. No Task9 work begins; subsequent tasks are on hold at the owner's request.

Root cause verified in cached Flutter/image_picker Android source: Flutter PathUtils configures Directory.systemTemp from Context.getCodeCacheDir(), while image_picker stages gallery/camera files in Context.getCacheDir(). The old canonical-path guard rejected valid files in the sibling image cache. Fix3535e4c obtains the actual canonical cache directory over paths/media and uses it for owned-file confinement, lost selections and camera-cancel cleanup. It preserves outside-cache originals and symlink targets; cleanup failure clears selected bytes. No new package, SDK or service is needed. API remains1.7.0.

Regression evidence: the sibling-cache test reproduced AuthFailure before the fix, and the original-file protection test exposed the too-broad host-temp assumption. Both pass after the fix; five focused native-picker tests pass, including a camera file created during a cancelled picker call. Full Flutter suite215 tests passes; analyzer has no issues. Final native build results and the focused retest are recorded below. The interrupted pre-merge full-suite rerun is not counted as passed; the successful215-test run is the post-fix evidence.

Required retest: fully stop/rebuild the app (native channel changed), select a gallery photo and confirm preview/upload, then test Camera selection and picker cancellation. Mobile PR8 stays unmerged until those phone results arrive. Backend/admin functionality is unchanged by this mobile-only fix. Live R2, iOS runtime, deferred Firebase/APNs and quantitative Phase0 evidence remain separate pending release prerequisites.

Unsigned generic iphoneos Debug build passes with package autoresolution disabled. The first offline Android attempt compiled the change but failed because Gradle could not find output-metadata.json at listing validation; the metadata subsequently exists and the repeated offline assembly passes in15s (235 tasks). This failed attempt is not counted as passed. No application-code or dependency changes were needed for the build recheck.


## Task8 Android startup recovery — 2026-10-17

Owner's next launch failed with Invalid kernel binary / Indicated size is invalid and root-isolate creation errors. Inspection found the packaged and staged kernel had the same length as compiler output74982720, but their final64 bytes were zeroed. The compiler's app.dill contained a nonzero trailer; SHA256 differed. This proves a damaged generated bundle, not a successful device launch despite the earlier Gradle exit0. The specific writer/corruption mechanism is not established; avoid simultaneous build writers.

Added tools/check_android_kernel.py and four regression cases: exact match, zero-padded APK, equally corrupt staged/APK bundles, and build-ID traversal. The tool failed on the actual bad artifact before recovery. Removed only project-generated build/app and .dart_tool/flutter_build, preserving package resolution, SDKs, source, credentials and phone data. The first cleanup used Android-relative paths and missed those project directories; the corrected absolute-path cleanup preceded the final build.

Actual final verification: offline Android assembleDebug passes in41s (235 tasks); all4 new integrity tests pass. Verified packaged/staged kernel equals compiler output:74988392 bytes, SHA256 e4ce82ac0514497c0ae57ce41860d95c2a803f6a6d32a94bab2b8ef42b016398. Application code remains the photo-cache fix3535e4c from the215-test/analyzer/native checks; no dependencies were installed or generated outputs committed. This byte check does not prove phone launch.

Owner must launch the already-verified local APK using the runbook's --use-application-binary command, then repeat Gallery/Camera/cancel checks. Mobile PR8 remains draft pending startup and photo retest. Backend/admin are merged; main and all subsequent tasks remain unchanged/on hold.


## Task8 profile-photo return after Android resume — 2026-10-17

Owner can now launch and upload, but Use photo returns to a form still labelled Add photo and Next cannot continue. Read-only aggregate diagnostics show ready, pending-review, unattached avatar assets; no user identity or content was read. The server upload is complete, while the form has lost its selected ID.

Reproduction: a real-router/HTTP-repository widget flow succeeds without resume, but a valid Android-style background/resume followed by Use photo loses Change photo before the fix. AuthRouterRefresh previously notified GoRouter on every AuthCubit busy/session-metadata update, disturbing the imperative photo route and its return future. Fix8cfb4e3 refreshes routing only when stage, account ID, restriction, adult-check or signup preference changes. Routine session refresh preserves the pushed route, its returned asset and unsaved form controllers. Authorization-relevant changes still redirect immediately.

Actual verification so far: all218 Flutter tests pass and analyzer has no issues. Eight focused setup-routing cases pass; the new cases verify both ordinary/resume photo return, decoded private image pixels, typed-name preservation, exact saved avatarAssetId, Next reaching Verification, and restriction-on-resume closing the photo screen. The binary-content fixture handles variant query strings and uses an original valid synthetic PNG. Earlier fixture-decoding failures were corrected before the final successful suite; they are not application fixes.

Native checks run sequentially; final Android build/integrity evidence follows below. API remains1.7.0. Mobile PR8 stays draft pending the owner's focused Gallery/Camera/Next test on the new APK. Backend/admin are already merged. Main, live R2/push/iOS-runtime prerequisites and the hold on Task9/later work remain unchanged.

Final native evidence for8cfb4e3: unsigned generic iphoneos Debug compiles with package autoresolution disabled. A sequential fresh Android app output rebuild passes offline in36s (235 tasks). APK/staged kernel exactly matches compiler output:74984256 bytes, SHA256 b721f1c586b3263d5064796d3d4fc646bb710f27e4c98d50d487e25648d6c9de. All4 APK-integrity regression tests pass. The prepared APK embeds the existing local API origin; owner launch uses --use-application-binary to preserve this checked artifact. Physical retest remains pending.


## Firebase Android configuration — 2026-10-18

Owner authorized project creation and notification setup on Spark without billing. Created paths-awais and Android com.paths.mobile, enabled FCM, and configured a dedicated sending service account in ignored local files. Cloud Billing reports disabled/no account linked. Backend build,4 push unit tests, real OAuth and FCM validation-only checks pass. Worker is healthy with a read-only secret mount; APNs remains unconfigured. Offline Android235-task build and exact APK kernel/options checks pass. Runtime delivery/permission/tap/account-switch tests await the owner; no live delivery is claimed. R2 credentials pass read-only bucket access, with no storage switch or migration. No app source changed; main and later-task hold remain unchanged. See [Firebase Android handoff](FIREBASE_ANDROID_HANDOFF.md) for evidence, setup and numbered owner tests.


## Owner image acceptance and Task9 authorization — 2026-10-18

Owner confirms images work on their physical Android phone and authorizes pending PR merges and Task9. Fresh218 Flutter tests pass. This acceptance covers image functionality; physical FCM/APNs delivery, iOS runtime and quantitative field checks remain separate evidence. Main stays unchanged. Task9 starts after development integration, with owner approval for required Socket.IO dependencies.

## Task9 started — 2026-10-18

Owner accepted R2 image behavior and authorized pending merges plus Task9. Mobile PR8 merged as fa8636b; backend PR9 as17ad1f0 and PR10 as c97def4. Main unchanged. Branch feature/text-chat from development. Cache-resolved Socket.IO Flutter client3.1.6 added; Task9 plan is docs/task9-chat-plan.md. Text chat, reconnect/access revocation, unread and lifecycle checks are in progress; device gate remains pending. Real push/iOS and R2 recovery-copy retirement retain separate evidence requirements.


## Task 9 text chat — 2026-10-18

Status: implemented and locally verified; awaiting owner physical-device tests. Branch `feature/text-chat`, PR target `development`. Task 10 and main promotion remain gated. Owner accepted the R2 images; backend PR9/10 and mobile PR8 are merged into development. Backend merge checkpoints `17ad1f0` / `c97def4`; mobile `fa8636b`. No working-release claim or main promotion.

Plan checklist (06_IMPLEMENTATION_PLAN.md Task 9):

| Applicable item | Status | Evidence |
| --- | --- | --- |
| Pre-accept/spoof/>4000 denial and same-client-ID single insert | verified locally | backend chat.spec.ts; server validation and transaction/idempotency tests |
| Consistent locks for send vs block/disconnect/delete; no unauthorized post-commit delivery | verified locally | concurrent integration races, rollback test and real Socket.IO delivery reauthorization |
| REST persistence, server-owned sockets, cursor catch-up, ACK after commit | verified locally | chat service/gateway/migrations; proxy + live worker synthetic check |
| Chat list/thread, lazy history, failed retry, unread and disconnected read-only history | implemented; automated checks verified; awaiting device test | Flutter chat Bloc/screens and generated API1.8 |
| Missed/duplicate/out-of-order recovery; removed conversations clear from caches | automated checks verified; awaiting two-device recovery test | backend cursors, Flutter transport/Bloc/removal/account-epoch/route-visibility tests |
| Manual two-device airplane-mode recovery | awaiting device test | TASK9_DEVICE_TESTS.md; no result invented |
| Physical iOS and real FCM/APNs delivery | blocked by separate runtime/setup prerequisites | unsigned iOS compilation is not runtime evidence; APNs remains unconfigured |

API contract 1.8.0, raw OpenAPI SHA256: `4730d17914e48f17ff8425d4bc36ea8cad92e006911bb62a6265312e8e533060`. All three raw copies match, both client generators updated. Backend source `17a076c` (storage `e16d4cb`, service/socket tests `a9952e5`, generic alerts/outbox/live check `c6308ac`). Mobile source `e3393cc` (sync/retry `23ab75a`). Admin source `acf827c` (initial contract `70ed288`). Later commits record the handoff/evidence only.

Checks actually executed:

- Backend ESLint/typecheck/build; 36 unit + 13 retained feasibility + 101 isolated PostgreSQL/Valkey integration cases pass. The 11 new chat cases include real Socket.IO authorization and post-block suppression. Fresh synthetic live check passes through Caddy, API, durable worker, PG listener and socket; retries insert once, history/read/disconnect work. Temporary identities removed. No messages sent from the owner's account.
- Mobile analyzer has no issues; 231 Flutter tests pass, including 13 new chat cases. Full suite rerun passes after the covered-response read regression and readiness version correction.11 Python tooling tests pass. Android offline Debug assembly passes 235 tasks; APK kernel 75,364,960 bytes, SHA256 93661a7b09d6b1ba5ee3d609842a575c5099fd54656c7ee756a12e9d83d88394 matches compiler output. Unsigned generic iphoneos Debug builds with cached resolved packages and automatic resolution disabled. Neither platform was operated on a physical device by the agent.
- Admin ESLint/typecheck, 2 transport tests, Vite build and 3 installed-browser cases pass. No new admin workflow belongs to this task. Contract generation/drift and branch whitespace checks pass.

Review findings addressed: covered routes now combine route and app visibility before syncing/marking read; delayed connection.updated hints reauthorize the current pair while own removal tombstones remain deliverable; the existing bounded 30-day processed message-intent cleanup is centralized in the tested notification retention routine, including already-read intents without inbox cards. A full-suite fixture assumption that its probe always fit within the first 50 outbox rows was fixed using bounded dispatch and uniquely owned test queues; production batch size unchanged. Socket listener loss closes clients and blocks new handshakes until listening resumes; clients repair through REST. Private message text is never included in socket/push envelopes or logs.

Earlier attempts blocked by sandbox loopback permissions were rerun successfully with local access. One new route test initially lacked a resumed app lifecycle; explicit lifecycle setup and a real initial-visibility fix were applied, then focused/full suites passed. Whole npm-cache image transfer was cancelled; a 32,970,705-byte cache of 324 lockfile-pinned tarballs built the local runtime with network disabled, adding 17 server packages. Dart dependencies also resolved from existing offline cache. No SDK, tool, emulator or service image downloaded. Current API/worker use the local image with migrations 0011/0012 and retain R2/Gmail/Firebase configuration.

Pending: owner Task 9 physical Android/second-session tests before merge/Task 10; separately iOS physical signing/runtime, real Android push/APNs validation and quantitative Phase 0 release evidence. R2 recovery copies remain read-only until the documented recovery deadline and retirement; no storage volume was deleted. No known failed local check remains. Inspection/builds cannot establish OS background recovery, real push delivery or user-visible multi-device behavior. See TASK9_DEVICE_TESTS.md for commands, expected outcomes and redacted failure evidence.

Follow-up review reproduced a response completing under a covered route without advancing read state on return; a post-frame visibility check and regression fix it. Readiness and OpenAPI now share a backend version constant; a real HTTP integration regression and updated frontend fixtures verify 1.8.0. Final 101 backend integration and 231 Flutter tests pass after these fixes. Android and unsigned iOS were rebuilt sequentially after the final mobile source change; kernel evidence above is from that exact APK. Live readiness returns 200 / 1.8.0.

Published draft PRs: [backend #11](https://github.com/awais-ur-rehman/paths-backend/pull/11), [mobile #9](https://github.com/awais-ur-rehman/paths-mobile/pull/9), [admin #9](https://github.com/awais-ur-rehman/paths-admin/pull/9). All target development. Source checkpoints above are pushed; this evidence commit will also be pushed. Required physical tests remain pending; do not merge Task 9 or proceed through its dependent gate.

## Task 9 owner acceptance and Task 10 start — 2026-10-18

Owner confirms Task 9 works on their physical Android phone and authorizes merging its PRs and starting Task 10. Backend PR11, mobile PR9 and admin PR9 merged into development (c3de54d,23f7c51,a29191e). Backend/admin hosted checks passed; mobile local231 tests/native builds and owner acceptance were the gate. No additional two-device or iOS measurements are inferred. Current branch feature/safety-controls. See task10-safety-plan.md for every applicable checklist and explicit Task11/12 dependencies.

## Task 10 safety controls — 2026-10-18

Status: **implemented and locally verified; awaiting device test**. Phase 5 remains open. Branch `feature/safety-controls`, target `development`; main unchanged. API **1.9.0**, raw OpenAPI SHA256 `b935cfab611b1eb4c201e599f9f46dd37743d7a1a5aab014b6fd03e5a98d7f05`; all three copies match.

Checklist coverage:

- **Verified locally:** bilateral blocks remove both saves, cancel pending/accepted requests, block connections, revoke chat/private media/discovery and remove old encounters. Idempotent retries and inverse operations serialize on canonical user/pair locks. Unblock removes only the actor's block, restores no connection/save and requires new samples captured after the final unblock for encounter eligibility.
- **Verified locally:** profile/post/one-selected-message reports, six categories, optional bounded details, actor/body-bound idempotency and reference acknowledgment. Subject/content ownership and member access are checked on the server. Member-only historical-message selection remains available from Blocked accounts; it does not reenable chat. Identifying evidence/grants cascade on reporter/subject/content deletion; category/day totals retain no identifiers.
- **Verified locally:** status transitions revoke old sessions, leases and push registrations; pause tracking and suppress pre-restriction queued notifications even after reactivation. Reactivation requires fresh login and explicit tracking consent. Internal service records reason and matched underage report, with no unprotected staff endpoint.
- **Implemented, automated UI checks verified; awaiting device test:** concise report/block controls in profile/chat/post, report receipt, blocked list/unblock, retry/offline/cancellation/account-switch guards, mounted-view/resume/reconnect invalidation, restricted support/appeal and Request deletion help. Self-service erasure is Task 12; staff RBAC, report triage and status UI are Task 11. These dependent tasks remain not started.
- **Verified locally:** suspected-minor/threat/exploitation reports enter urgent review. An unverified report never automatically restricts another account. Evidence-confirmed underage restriction requires the matching report through the internal moderation operation.

Checks executed and final results:

| Check | Result |
| --- | --- |
| Backend `npm run build`, `npm run lint`, `npm test` | Pass; 36 unit and 13 feasibility tests |
| Backend `npm run test:integration` | Pass; 113 isolated PostgreSQL/PostGIS integration tests |
| Backend `node --env-file=.env.local dist/scripts/verify-safety.js` | Pass through live proxy/API/worker/socket; temporary synthetic accounts only, cleaned up |
| Backend `npm run stack:verify` | Pass restart/persistence/non-root/graceful shutdown; expected connection-loss warning during DB restart; full R2/push overrides restored afterward |
| Mobile `flutter analyze --no-pub`, `flutter test --no-pub` | Pass; no analyzer issues, 250 tests |
| Mobile `python3 -m unittest discover -s test/tools` | Pass; 11 tooling tests |
| Admin lint/test/build and installed Playwright `npm run test:e2e` | Pass; 2 transport tests, 3 browser cases |
| Android offline Gradle `:app:assembleDebug` | Pass; 235 tasks; no device operated |
| Android `python3 tools/check_android_kernel.py` | Pass; compiler/staged/APK match, 75,465,832 bytes; SHA256 `1ff51b8bf5c21170448b678985dbefd5d729186885d759f4ffcf166672d1fdf7` |
| iOS cached `xcodebuild`, unsigned generic physical target, automatic resolution disabled | Build succeeded; signing/runtime/APNs remain pending |
| Review and complete branch whitespace check | Review findings addressed; final diff checked |

Review fixes: final-unblock capture boundary prevents queued during-block samples restoring encounters; canonical version-row locks avoid inverse status deadlocks; reconnect/resume revalidate mounted views and private media; post reporting uses an actor/subject/post-bound 15-minute server capability prepared while access exists. Blocking never waits for evidence preparation. Capability expiry uses a monotonic client deadline; uncertain report retries first reuse the exact original body, then renew only if the server confirms an expired/uncommitted attempt. A blocked/removed post offers explicit member-report fallback. Failed preparation/quota/expiry cannot prevent a block. Focused tests cover these cases and the full suites pass after fixes. Fresh read-only review found no remaining issue in those fixes; inspection is not device evidence.

Early test runs caught an outdated restricted-screen label and reconnect event expectation, a premature account-switch fixture and an invalid image fixture; corrected before the passing runs above. Sandbox-only socket/cache attempts were rerun with the required local access. No new dependency or asset download was required.

Source checkpoints: backend `64a42e5` (storage/API/status), `3d21cc0` (tests/live check); mobile `4f0b3a5` (safety forms), `684a41f` (integration/invalidation), `cb0d545` (tests); admin `d1b969f` (contract/readiness). Later whitespace/evidence commits do not change app behavior. Local migration 0013 applied; private R2, Gmail and Firebase configuration retained. No real account was restricted or reported by automated tests. Original encrypted local-media recovery volume remains read-only; no volume deletion.

Pending prerequisites: owner physical Android acceptance for Task 10; separate signed iOS runtime evidence, Android FCM delivery/tap evidence and APNs setup; quantitative Phase 0 field metrics remain release evidence. No unavailable package/tool blocked the checks listed above. Builds cannot prove OS/device behavior. See TASK10_DEVICE_TESTS.md for exact commands, expected outcomes and redacted failure evidence. Do not merge Task 10 or start Task 11 before owner acceptance.

Published draft PRs: [backend #12](https://github.com/awais-ur-rehman/paths-backend/pull/12), [mobile #10](https://github.com/awais-ur-rehman/paths-mobile/pull/10), [admin #10](https://github.com/awais-ur-rehman/paths-admin/pull/10). All target development. Feature source and test evidence are pushed; owner Task 10 acceptance remains pending. Main unchanged.

## Task 10 owner acceptance — 2026-10-18

The owner tested Task 10 on their physical phone, confirmed it looks good and authorized merging backend PR12, mobile PR10 and admin PR10 into development. This acceptance supersedes the earlier draft/device-pending handoff status. No additional per-step, multi-device, iOS or push-delivery measurements are inferred. Main remains unchanged.

The owner explicitly requested waiting while they test the full app again. Task 11 and all further development are on hold; do not start the next task until asked. Existing separate release-evidence gaps remain documented above.

## Task 11 start — 2026-10-18

Owner resumed the next task after accepting Task 10. Hosting remains deferred. Branch `feature/admin-review` from development. Task 11 checklist, policy defaults and interfaces are tracked in task11-admin-plan.md; no device/operational acceptance is inferred.

## Task 11 verification and handover — 2026-10-18

Implementation on `feature/admin-review`, API 1.10.0. No Task11 merge or main promotion. [Owner test instructions](testing/task11-admin-review.md) and [scope/decision ledger](task11-admin-plan.md).

- Backend: build/lint; 38 unit +13 feasibility; full isolated PostGIS/Valkey integration 131 passed (18 staff cases). Final malformed-cursor regression re-run recorded in evidence.
- Admin: six transport tests, build/lint, nine installed-Chrome browser tests passed; screenshots inspected at 320 and 1280px. Browser tests use isolated mock HTTP responses, not real CNIC.
- Mobile: analyzer clean; full Flutter suite 256 passed; four focused review tests cover intent retries, duplicate taps, account changes and cancellation. Python verification-tool tests 11 passed. Offline Android APK build and matching kernel passed; cached unsigned iOS build passed. No phone/emulator or iOS runtime testing performed.
- Live local checks: migration0014 applied after private backup; existing R2/SMTP/push config retained; restart/persistence/non-root/shutdown verification passed with full Compose overrides; real local staff MFA → synthetic appeal → approval → member update passed and synthetic member was removed. Owner staff credentials/MFA are ignored private files documented in the runbook.
- Fresh whole-branch review fixed: superseded image appeal approval, setup Reviews redirects, audit chronology, stale profile/verification refresh, enrollment cleanup on rollback. Additional inspection fixed completed-image viewer access, request cancellation, browser fetch receiver and cursor validation.
- Pending: owner browser/Android acceptance; named pilot reviewers and coverage; real push delivery evidence and iOS/APNs runtime. Earlier phase field/battery/accuracy evidence and Task12 erasure remain separate open gates. No new unavailable package/tool prerequisite blocked these code checks.

Draft PRs into development (owner acceptance pending):

- Backend: https://github.com/awais-ur-rehman/paths-backend/pull/13 — implementation/status head83a3859 before this link-only update.
- Admin: https://github.com/awais-ur-rehman/paths-admin/pull/11 — implementation/status head506dda5 before this link-only update.
- Mobile: https://github.com/awais-ur-rehman/paths-mobile/pull/11 — implementation/status head8fe78ee before this link-only update.

All use feature/admin-review. No Task11 merge or main promotion. GitHub checks are separate from the local evidence above; inspect the current PR check state. The local staff portal is running at http://127.0.0.1:5173.

## Task 12 start — 2026-10-18

Owner accepted Task11 and requested Task12. All Task11 PRs merged into development; no main promotion. Task12 checklist/rulings are in task12-deletion-plan.md. Dedicated test staff account is local only; private credential/enrollment files are ignored. Restore sign-off, device testing and earlier release evidence are not assumed.


## Task12 delivery — 2026-10-18

Feature branch `feature/account-erasure`; API1.11.0. Implementation, actual check scope, review fixes and code commits are recorded in [task12-evidence.md](testing/task12-evidence.md). [Owner test steps](testing/task12-erasure.md). Task11 owner acceptance is recorded; main remains unchanged. Device/restore gates remain pending, so no Task12 merge or Task13 start.

## Published review branches

All use `feature/account-erasure` → `development`, draft pending owner Android/counterpart test and restore sign-off. Published implementation/evidence heads before this cross-reference update:

- paths-backend: `1168861`, [draft PR](https://github.com/awais-ur-rehman/paths-backend/pull/14).
- paths-admin: `0c8b030`, [draft PR](https://github.com/awais-ur-rehman/paths-admin/pull/12).
- paths-mobile: `c476846`, [draft PR](https://github.com/awais-ur-rehman/paths-mobile/pull/12).

Main is unchanged. No Task12 PR has been merged and Task13 has not started. Follow docs/testing/task12-erasure.md on these feature branches. Later cross-reference commits change documentation only; native builds correspond to the implementation commits recorded in the evidence.


## Task13 start —2026-10-18

Task12 accepted and merged: backendbf871a93, admin808b2694, mobile1ddc4498. Current feature branch `feature/pilot-hardening`; see [plan/ledger](task13-hardening-plan.md). All six Task13 checklist items are in progress or pending; no load, outage, battery or frame targets are claimed.

## Task 13 local verification and pending gates — 2026-10-18

Feature `feature/pilot-hardening`, API1.11.0. See [executed checks, review fixes, measured limits and source commits](testing/task13-evidence.md). All six checklist items are accounted for above. Task13 remains in progress: dense-load latency/drain gates and owner production battery/coverage/frame/memory/accessibility evidence are pending. The profile harness compiles, but has not run on a device. No Task14 start or main promotion.

Task12 acceptance supersedes its older historical pending labels. No package/tool prerequisite remains for executed local checks. Owner phone/iOS runtime, deployment hardware capacity, APNs/live push and other release prerequisites cannot be inferred from code inspection or builds.

## Published Task 13 review branches

All use `feature/pilot-hardening` → `development`, draft pending the open capacity/device gates. Published implementation/evidence checkpoints before this link update:

| Repository | Checkpoint | Draft PR |
| --- | --- | --- |
| Backend | `1496c86` | [PR15](https://github.com/awais-ur-rehman/paths-backend/pull/15) |
| Admin | `4513d01` | [PR13](https://github.com/awais-ur-rehman/paths-admin/pull/13) |
| Mobile | `b01a564` (application `4caff48`, journey `f308894`) | [PR13](https://github.com/awais-ur-rehman/paths-mobile/pull/13) |

Owner instructions: paths-mobile `docs/testing/task13-device.md`. Native builds correspond to the code checkpoints in the evidence; subsequent link commits change documentation only. Local checks passed within their stated scope. GitHub CI is a separate live check and is not inferred from local results. Main is unchanged; Task13 remains open and Task14 has not started.

## Dense processing follow-up —2026-10-18

Backend application7f93a3a, strict measurement105b73b, API1.11.0. Fixes cover owner snapshots, bounded peer pages, completed-observation coalescing, typed proof references, shared read locks, nonblocking pair subsets and bounded busy retries. See [complete evidence](testing/task13-evidence.md) and [ledger](task13-hardening-plan.md).

- **Verified:**172 backend integration;42unit/13Phase0/4metrics; lint/type/build/contract; four final isolated recovery faults. Final backend CI39133554221 passed. Admin/mobile code did not change during this follow-up; prior native/browser results remain explicitly historical.
- **Load in progress:** strict native run39133554208 verified5000 accepted,44,850 distinct pairs,300 sockets, zero backlog; APIp95<=136.48ms and chatp951176.66ms. Encounterp9525431.67ms **failed** the5000ms gate. Load workflow remains failing; do not mark complete based on successful ingestion or backend CI.
- **Awaiting device/field tests:** production battery/coverage, frames/rebuilds/map/image memory, accessibility/reference acceptance and iOS runtime/APNs evidence. No phone operated, no results invented.
- **Qualification prerequisite:** native4vCPU/8GB deployment baseline/soak unavailable. The measured Linux harness exposes2CPUs; the Mac database is emulated. Additional CPU is not assumed to make the gate pass.

All Task13 PRs remain draft into development. Main unchanged; no Task14. Local backend runtime refreshed from the cached verified image, readiness200, private config/data and rollback image preserved. No external deployment or new local dependency installation.


## Shared incremental matching — 2026-10-18

**Task 13: in progress.** API contract **1.11.0**; branch `feature/pilot-hardening`. Historical pre-merge report: superseded by the owner-authorized Task13 development merge and Task14 status below. Main remains unchanged.

| Work | Status | Evidence |
| --- | --- | --- |
| Full pipeline measurements | Verified | Synthetic-only stage, queue, source-commit, CPU/WAL and plan reports; `55cfe41` |
| Exact observation projection | Verified | Raw samples retained; distinct matching history, expiry and deletion regressions; `01f23f8` |
| Shared incremental matching | Implemented; regression verified | Durable source batches, canonical 500-pair chunks, grant maps, bounded proof reads, two chunks/global wakeup, per-batch replanning; `f56532e` through `a484cf2` |
| Native capacity | In progress; gate failed | Final run `39139807060`: 5,000 samples, 44,850 pairs, 300 sockets, drained; API/chat passed; encounter p95 **37,160.129 ms** failed the 5,000 ms limit |
| Required native 4vCPU/8GB baseline/soak | Blocked | Runner unavailable; measured CI runner has 2 CPUs; local PostGIS is emulated |
| Remaining push/device/field gates | Not started / awaiting device test | Registered-device synthetic push pressure, battery/coverage, frames/image memory, accessibility/reference acceptance and iOS runtime/APNs |

Checks: **192 integration**, **47 unit**, **13 Phase 0** and **4 load-metric** tests passed at `2fbfb36`; lint/types/build/contract and cached offline image build passed. The final diagnostic-label fix `a484cf2` passed 3 focused unit and 14 shared integration checks plus lint/types/build. Backend CI `39139807054` passed on `a484cf2`. Admin/mobile application code is unchanged; previous browser/Flutter/native evidence remains historical.

All five final runtime recovery faults passed at `2fbfb36`: worker crash 33.517 s, post-commit/pre-ACK matching replay 34.086 s, queue loss 31.497 s, database restart 4.912 s and SMTP outage 9.718 s. Replay preserved effects and eventual source completion. Isolated services were stopped without deleting volumes. Review fixed lost wakeups, rollback batch draining, repeated discovery/proof scans and the subsequent timing-label regression; final read-only review found no further actionable issue in the label fix.

**Qualification remains open:** shared matching is slower than the 19,928.782 ms owner control in this workload. Passing streak is zero; cold discovery also exceeded the application query deadline in a separate probe. Proof/evidence/atomic-inbox costs need further work. No threshold, constraint or authorization rule was weakened. The application remains on the owner default. No owner data/device or vendor service was faulted; no local dependency/tool/image downloads occurred.

Backend [draft PR15](https://github.com/awais-ur-rehman/paths-backend/pull/15) contains the full measurements in `docs/task13-incremental-measurements.md` and checklist in `docs/superpowers/plans/2026-10-18-incremental-matching.md`. Earlier failed runs remain recorded.


## Task 14: provider login — in progress; signed-provider acceptance pending

Owner requested Task13 development integration despite its reported failed load gate. Backend PR15/admin PR13/mobile PR13 merged normally (9a53f8f/e5ed6bf/6df7564); no main promotion or protection bypass. Task13 remains unqualified, owner matching stays default and prior load/native-baseline/device debt remains open. Task15 deployment/store work has not started.

Branch: `feature/provider-auth`. API contract **1.12.0**, identical backend/admin/mobile artifact, genuinely regenerated client DTOs. Applicable checklist coverage is recorded above; checked code/fixture tasks do not imply real-provider acceptance.

| Work | Status | Evidence |
| --- | --- | --- |
| Signed provider verification/config | Verified locally | Backend8458f39 and review fixf64e233; fixed JWKS endpoints, signature/issuer/audience/nonce/time checks, Google native presenter allowlist, bounded cache/fetch/rotation |
| Identity/session/link transitions | Implemented; verified locally | Backend618ec5f, unique identities, terms/email OTP, collision handling, authenticated account-bound link candidate, secure existing session/adult routing |
| Reauth, unlink, Apple erasure/retention/restore | Implemented; verified locally | Backend5b2fef6/03c507b/f64e233; action/session-scoped one-use proof, last-method serialization, encrypted retry/manifest, cleanup saturation regression |
| Native SDK/session/UI | Implemented; automated checks verified | Mobile0f62871/bb9234e/a160d13; per-attempt nonce, serialized SDK cleanup, cancellation/epoch/vault, compact controls/settings, provider-only deletion, shared OTP cooldown |
| Provider credentials/signed runtime | Google Android configured; awaiting device test | Web/Android OAuth clients and debug certificate configured in paths-awais. Owner test user/basic identity scopes saved. Apple/iOS configuration pending; no real provider login claimed |
| Handoff/review | Verified locally; draft PR/device handoff prepared | Whole-branch reviewer found Google presenter rejection and expired-cleanup starvation; both fixed with observed RED/GREEN regressions and rechecked. Final evidence/push/PR links follow |

Checks observed: backend **56 unit**, **13 Phase0**, **4 metric**, **32 final focused auth/deletion** pass. Final full **211 integration** passed after the isolated3-test bootstrap check. A preceding run during concurrent native compilation had210 pass/1 migration100ms-query-budget timeout; the same isolated test and serial full suite then passed without changing limits or code. The failed attempt is retained here; runtime capacity is not inferred from these checks. Mobile **294 Flutter**, **12 Python tooling** and analyzer pass. Admin contract generation/lint/types/build and **8 tests** pass; unchanged admin browser UI was not retested for this contract-only task.

Android Debug assembled offline (274 tasks) with explicit USB-loopback origin and existing ignored push configuration. Final APK/staged Dart kernel equals compiler output: **76,099,904 bytes**, SHA256 **163befe01eccfcde5e547180d5c698f85e358f0f700aaea183e4b4d7082697d6**. Unsigned generic iOS Debug compiled with automatic resolution/updates disabled. These builds do not establish signing, OAuth consent, native chooser behavior or phone acceptance.

Dependencies: Google/Apple Dart packages and Android artifacts came from existing caches. Initial iOS compile correctly blocked on missing GoogleSignIn-iOS; the owner then specifically approved its download. Real Swift resolution records GoogleSignIn9.2.0 and required transitives while retaining MapLibre6.28.0. No fabricated lockfile, tool installation, emulator or phone operation. Original Google button artwork is bundled under its branding terms; standard Apple button uses its cached package. Asset sources/license details are in mobile `docs/ASSETS.md`.

Local backend runtime f64e233 was built by copying compiled sources/migrations into the cached image with network disabled. Additive migration0019 applied; only API/worker restarted. Readiness and public provider metadata returned200/API1.12.0 with both providers disabled. Existing private env, R2/Gmail/FCM mounts and volumes were retained. Provider environment keys are passed to both services by Compose; no real user/provider data was added for these checks.

Setup/protocol/release gates: backend `docs/runbooks/provider-auth.md`. Exact owner build/configuration and numbered physical checks: mobile `docs/TASK14_DEVICE_TESTS.md`. Apple guideline4.8 login-service requirements were checked against the official current page; no exception/store readiness is claimed. No deployment, purchase or store submission.

Draft PRs into development (all pushed):

| Repository | PR | Verified implementation commits |
| --- | --- | --- |
| Backend | https://github.com/awais-ur-rehman/paths-backend/pull/16 | 8458f39, 5b2fef6, 618ec5f, 03c507b, f64e233; verification report0513493 |
| Admin | https://github.com/awais-ur-rehman/paths-admin/pull/14 | ef09c0a (contract/evidence only) |
| Mobile | https://github.com/awais-ur-rehman/paths-mobile/pull/14 | 0f62871, bb9234e, a160d13; device/setup report e624119 |

Task14 code/available local checks and review are implemented/verified; phase acceptance remains **awaiting device test**. Google Android configuration is ready; Apple/iOS configuration remains pending. All six task checklist items are accounted for; the signed walkthrough remains unchecked. Remote CI is a separate gate and was not inferred from local results. No PR was merged for Task14. Main remains the last prior verified baseline.

## Google setup checkpoint — 2026-10-18

Owner requested Google sign-in using existing `paths-awais`; Apple deferred and all Task14 PRs remain draft until the owner's Google phone test. Registered and verified the actual debug certificate SHA-1/SHA-256 on existing `com.paths.mobile` Firebase app. Refreshed private SDK config still has no OAuth clients. Google Cloud browser authentication is required to configure the Web/Android clients; the open panel awaits owner login. No Google sign-in, billing change or real-device pass is claimed. Backend/mobile application code and private runtime configuration remain unchanged at this checkpoint. Details: backend `docs/testing/task14-google-setup.md`.

## Google Android ready for owner test — 2026-10-18

Supersedes the earlier Google setup checkpoint. Owner authenticated the browser and approved the policy plus both OAuth clients. Existing `paths-awais` now has Paths backend Web and Paths Android debug clients; actual APK certificate matches registered `com.paths.mobile` SHA-1/SHA-256. External audience stays Testing with the owner email as test user. Saved only OpenID/email/profile; no sensitive/restricted scopes. Public client IDs are in ignored backend `.env.local`; refreshed Firebase config remains ignored. No billing change or Firebase Auth migration.

Current local checks: API/worker healthy after configuration restart with retained private env/volumes, readiness200/API1.12.0, provider metadata200/Googletrue/Applefalse. Offline Android build passed (274tasks,24executed/250up-to-date). Kernel comparison passed (76,099,904bytes; SHA256 `8e8670be4182ff26f9ab47e0511393a29b7b86b9ca65a13d8043218c8aaf09a0`); actual APK signature verification passed. Existing Gradle deprecation warnings remain. No application code or API contract changed; previous unit/integration/widget counts above are prior evidence, not rerun checks for this configuration-only update. Reviewed the configuration/documentation diff and confirmed private files are ignored.

Google chooser/login, owner email collision/linking, cancellation/retry and secure session restore are **awaiting device test**. Apple and signed iOS provider setup/validation remain **blocked** on owner configuration. No real Google login or physical-device result claimed. All Task14 PRs stay draft (backend16/admin14/mobile14); main unchanged, no merge. Setup details: backend `docs/testing/task14-google-setup.md`; owner commands/numbered steps: mobile `docs/TASK14_DEVICE_TESTS.md`. Task13 capacity debt remains separate.

## Android navigation/location follow-up — 2026-10-18

Owner reports Google sign-in worked on the physical Android phone. This records that acceptance only; Apple setup and signed iOS provider testing remain deferred. Owner then reported Chats redirecting to profile setup, Home hiding the map without encounters, and confusing permission/background status.

| Applicable item | Status | Evidence |
| --- | --- | --- |
| Chats navigation after completed setup | Implemented; automated regression verified | Mobile353087a: `/chats` was missing from the authenticated route allowlist; detail routes now also check chat availability |
| Empty-history map and own-location layer | Implemented; automated behavior verified; awaiting device test | Mobileddc9dda: map no longer requires backend center; native self-location layer follows permission/services and centers once on a fresh fix; peers remain authorized approximate encounter areas |
| First Home permission / retry / Settings | Implemented; automated behavior verified; awaiting device test | Mobileddc9dda: concise optional prompt, top-right icon, explicit retry and permanent-denial Settings recovery; no standalone permission onboarding gate; no silent restart of paused sharing |
| Background sharing vs GPS quality | Implemented; native policy verified; awaiting device test | Mobile213ae6f: active background choice reported separately on Android/iOS; one Android precision burst capped at20sec, foreground/precise only, ends early at<=25m; balanced collection afterward |
| Concise location controls | Implemented; widget/accessibility-size checks verified | Mobileddc9dda: one primary enable/pause action, background switch and contextual Settings; updated rendered golden inspected |
| Native/device gate | Android offline build and unsigned iOS compile verified; awaiting device test | No phone/emulator operated. GPS quality, actual permission sheets, tile rendering, background delivery and battery remain physical/runtime checks |
| Merge/main promotion | Pending | Google owner acceptance recorded, but new navigation/location device checks are pending. Main remains unchanged; Task13 failed load qualification remains open; no history rewrite/protection bypass |

Checks: affected set62 passed before final additional regressions; final Home set17 passed including permanent-denial return from Settings. Final full Flutter suite **301 passed**, including the extra Settings-recovery test. Dart analyzer clean;13 Python/tooling tests passed, including executed cached Kotlin precision-policy and Kotlin/Swift endpoint guards. Final offline Android build passed274tasks (24executed/250up-to-date); kernel comparison76,097,400bytes, SHA256 `129777b80e9a4ce33ee7cb82bfee5c84becf0e87ee26ad59f039957e073be072`. Unsigned generic iOS build succeeded with dependency resolution/updates disabled; no iOS runtime claim.

Review corrections: missing Chats allowlist and chat-detail capability condition; map no longer hidden by null server center; permission denial leaves Home usable; precise-fix quality does not erase the background switch; precision timer cannot restart foreground-only capture after leaving the app; existing OS permission cannot silently restart paused sharing. Existing encounter accuracy/authorization rules, API1.12.0 and private settings remain intact. Only fixtures represent synthetic users/coordinates.

GitHub branch-protection inspection returned403 for each private repository: current plan requires an upgrade or public visibility. Neither was changed; no claim of enforced GitHub protection. Maintain the documented release gate and normal PR workflow. All Task14 PRs remain draft pending this follow-up's phone check. No deployment, purchase, tool/package download, public repository or main push.

Owner retest: mobile `docs/NAVIGATION_LOCATION_DEVICE_TESTS.md`. Backend/admin application code is unchanged in this follow-up; their earlier test counts are historical, not rerun passes.

## Owner acceptance and release-gate audit — 2026-10-18

Owner confirmed the navigation/location fixes worked on the physical Android phone and authorized merge/promotion **only if CI and load gates pass**. This closes the reported Android functionality retest at mobilee66bd26; it does not invent quantified battery/accuracy/background-delivery results or signed iOS evidence. Apple/iOS runtime setup remains deferred. No UI work was started.

Gate audit at pushed implementation heads:

- Backend31400a9: [Backend checks39147846827](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39147846827) **passed**.
- Adminda021ca: [Admin checks39147846133](https://github.com/awais-ur-rehman/paths-admin/actions/runs/39147846133) **passed**.
- Mobilee66bd26: no GitHub workflow/check is configured; local evidence remains301 Flutter/13 tooling tests, clean analyzer, Android build/kernel check and unsigned iOS compile, plus owner Android acceptance. No missing remote check is reported as passed.
- Backend [dense-load39147846764](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39147846764) **failed** against head31400a9 (PR merge teste143670d91266d40116fe97f601fa55b84e29326). Downloaded the actual synthetic artifact and inspected the failed measurement step; this was not a build/startup failure. Chatp95 **2063.645483ms** misses<2000ms; encounterp95 **35871.806ms** misses<5000ms. APIp95<=137.091313ms passed; all5000 offered observations accepted,44,850 expected pairs produced,300 sockets remained connected and the queue drained. Backend `docs/testing/task14-release-gate.json` retains the small artifact-derived summary and provenance.

Result: **release gate failed**. All Task14 PRs remain draft; no development merge or main promotion, threshold change, rerun-to-green, or branch-protection bypass. This audit changes documentation only; it does not fix the known Task13 capacity issue or rerun application suites. CI triggered by this documentation push is separate evidence and must pass before any future merge. Next engineering work required for release is the failing dense-processing/chat-latency gate; UI work remains for the owner's later session.


## Latency follow-up — 2026-10-18

Current task: fix the failed encounter/chat release gate before Task14 integration. API contract remains **1.12.0**. No UI changes or device operation in this follow-up. Branch remains `feature/provider-auth`.

| Applicable work | Status | Evidence |
| --- | --- | --- |
| Independent chat publication and read-root concurrency | Implemented; regression verified; native latency passed at measured heads | Backendda5bf43:100ms scoped dispatcher; shared root reads with pair/conversation serialization and exclusive safety mutations |
| Exact short-history matching / stored-pair inbox input | Implemented; regression verified; capacity still failing | Backendf16ac18/5b7775c:exactly-two-fix proof path, full-history fallback, one bounded history read/member, proof hash reuse, database-derived recipients |
| Authorization/idempotency under new concurrency | Verified by observed RED/GREEN regressions | Backenddf64321:reject token expired during pair-lock wait;translate exact sender/message uniqueness race after rollback;no partial sequence/message effects |
| Final local backend checks | Verified |218 integration,56 unit,13 feasibility,4 metric tests;lint/types/build/contract drift and cached offline hardening image passed |
| Runtime recovery on final source | Verified |df64321 rebuilt offline;5/5faults passed:34.174s worker,33.811s committed-chunk replay,30.770s queue,5.172s database,10.142s SMTP;isolated services stopped with volumes retained |
| Native full load | Failed |39154572163:f16ac18 chatp95481.095ms / encounter31,961.871ms;39154869412:5b7775c chat451.011ms / encounter25,002.482ms. Both retained all5,000 observations/44,850 pairs/300 sockets/API/drain. Limits remain2,000/5,000ms |
| Remaining Task13 qualification | Pending / blocked prerequisites |Zero consecutive full passing runs;required4vCPU/8GB native deployment baseline/soak unavailable;field/device/push-pressure evidence remains separately pending. No claim of iOS runtime validation |
| Merge and main promotion | Blocked by failed load gate |All three PRs remain draft:backend16/admin14/mobile14. No branch-protection bypass or threshold change |

Fresh read-only review found the pair-wait expiry and cross-conversation idempotency races;both were reproduced then fixed. Reviewer did not establish capacity or independently execute suites. Local PostgreSQL probes were rollback-only synthetic diagnostics;no owner data/queue or vendor service was faulted. No dependency/tool/image download occurred locally. Temporary collation experiment was rejected after no measured improvement;no schema/collation change was added.

Backend nativeCI39154572320/39154869416/39155026735 passed at their respective implementation heads. AdminCI39153852041 passed at50e0ae9. Admin/mobile application suites were not rerun for this backend-only work;prior Android acceptance remains recorded above. Final reviewed-source load39155026717 failed:chatp95531.834ms passed;encounter36,652.463ms failed;APIp95<=285.490ms and all5,000observations/44,850pairs/300sockets/drain passed. The intermediate25,002ms result was not stable;encounter latency remains unresolved. Complete performance stage/provenance data is in backend `docs/task13-incremental-measurements.md` and `docs/testing/task14-latency-gates.json`.


## Owner-authorized main promotion — 2026-10-18

Owner explicitly requested merging the open PRs and promoting all current work to main for continued testing, overriding the earlier requirement to wait for the encounter load gate. This promotion does not qualify Task13 or represent a verified performance release. Final measured source df64321 passed chatp95=531.834ms and failed encounterp95=36,652.463ms against5,000ms; all5,000samples/44,850pairs/300sockets/API/drain passed. Existing218integration/56unit/13feasibility/4metric and5recovery results remain the evidence for that source; documentation updates do not rerun those tests.

Proceed through normal feature→development and development→main PR merges, preserving published history and branch protections. Keep the failed load measurements and outstanding native baseline/soak/field/push/iOS gates open. No UI change, deployment or device operation is included. UI work and further owner testing are deferred to the next session.


## UI pass1 — logo refresh, 23 October 2026

Current work: owner requested an elegant, subtle replacement logo using the linked logo-design skill, followed by app integration. API contract remains1.12.0. Branch: feature/logo-refresh, from development.

| Applicable item | Status | Evidence |
| --- | --- | --- |
| Read requested skill / inspect current brand and consumers | Verified | Read remote SKILL.md and redesign/construction/testing/library references; inspected existing SVG/exporter/Flutter painter/loader and admin uses |
| Three original concepts / refinement | Implemented; visual checks verified | design/logo-refresh contains V1/V2 vectors, outlined bundled Inter wordmarks and comparison; recommendation B—Open P |
| Asset validation | Verified |12SVGs parsed,31PNGs decoded; inspected actual16/24/32/64px, reversed/mirror/rotation/blur views using existing Sharp/Pillow |
| Direction selection | Awaiting owner choice | Requested skill explicitly requires a concept checkpoint before final asset kit/integration |
| App, splash, launcher, loader and admin integration | Not started; depends on selection | Production assets/code remain unchanged; no runtime/native rendering result claimed |
| Device/build gate | Pending integration | No phone/emulator operated; no Flutter build or application tests rerun for concept-only work |

No dependency, SDK, font or plugin installation. Read the skill over HTTPS and kept three reference-library study SVGs temporarily outside the repositories; only original concept artwork is committed. Draft asset sources/licensing are in docs/ASSETS.md. Existing encounter performance qualification remains open and is unaffected by this design work.


## UI pass 1 — approved Open P integration, 23 October 2026

Owner chose **B — Open P**, superseding the concept-selection checkpoint above. Branch: `feature/logo-refresh`; API contract **1.12.0**, unchanged.

| Applicable item | Status | Evidence |
| --- | --- | --- |
| Editable approved masters and export kit | Implemented | bbc384e; SVG symbol, horizontal/stacked/wordmark compositions, ink/white/blue SVG and PNG variants; `tools/export_brand.py` uses existing local Sharp/Pillow/Dart |
| Flutter brand and loader | Implemented; automated checks verified | cc32efd; generated vector lettering/route shared by brand and loader, retained semantics/reduced motion/disposal; inspected actual login golden |
| Android launchers, splash and notification silhouette | Implemented; offline ARM64 build verified; appearance pending | Distinct legacy/adaptive/splash scales; white notification drawable; source parity and conservative circular safe-area tests passed after observed failure against old artwork |
| iOS app icons and launch images | Implemented; catalog checks verified; compile blocked | All 22 app-icon entries checked against slot sizes and opaque RGB; launch assets inspected; Xcode's selected iOS 26.5 platform is not installed, so generic unsigned build exited 70 before compilation |
| Admin / browser brand | Implemented; automated checks verified | Admin 50611c3/a5d25dc; matching exported assets, favicon and Apple touch icon; lint/build and 8 tests passed; draft PR16 |
| Flutter checks | Verified | `flutter analyze --no-pub`: no issues; `flutter test --no-pub`: 301 passed on final run without golden updates |
| Offline build failure privacy | Verified by regression | 8d95b84; observed encoded configuration leaking through failed subprocess exception, then removed argv traceback and retained exit status; focused regression passed |
| Independent final review | Verified within inspection scope | No critical/important defect found; source/Flutter/native parity, safe areas, notification silhouette, icon opacity, semantics and cleanup inspected; generated build report excluded from commits |
| Device appearance / merge | Awaiting device test | No phone/emulator operated; draft PRs remain unmerged; main unchanged |

The initial offline Android attempt was blocked by missing pinned Kotlin artifacts (including Google sign-in plugin Kotlin 2.3.0). The two native Kotlin tooling checks also require cached Kotlin compiler/stdlib/script-runtime 2.4.0. A separate owner-authorized cache fill is running with Android SDK downloads disabled; no manifest versions changed. Final build/tooling results follow below when available.

Brand use, source and license records: `docs/brand/OPEN_P.md`, `docs/ASSETS.md`. No backend application change. Existing failed encounter load qualification and unavailable iOS runtime evidence remain open; these brand checks do not qualify either gate.

Additional native verification: installed Android build-tools 36.0.0 `aapt2 compile --dir android/app/src/main/res` passed; compiled entries include the P symbol, splash, notification and adaptive icon. Deterministic re-export left tracked assets/generated Dart unchanged. Final tooling run: 15 executed, 13 passed, 2 prerequisite failures for absent Kotlin 2.4.0 compiler/stdlib. iOS retry outside sandbox restrictions also exited 70 with the same unavailable generic iOS 26.5 destination; no SDK/package was installed for that retry.

Native tooling prerequisite resolved: the authorized cache fill provided compiler 2.4.0; the exact missing test dependency kotlinx-coroutines-core-jvm 1.10.2 was resolved separately using a temporary Gradle project outside the repository. Final `python3 -m unittest discover -s test/tools` passed **15/15** with existing Swift module-cache write access. Earlier prerequisite failures above are retained as attempt history, not final code failures. No manifests or lockfiles changed.

Build scope adjustment: the all-ABI build was stopped with SIGTERM after identifying three uncached Flutter debug-engine libraries, rather than a source failure. The test APK is now explicitly ARM64 via Flutter/Gradle target-platform; this does not change the project default or qualify 32-bit/x86 builds. The new device-test command preserves that target so later offline rebuilds do not request unused engines.


### Final brand verification — 24 October 2026

Current implementation: `cc32efd` (Flutter) / `bbc384e` (native/exports), plus `70b5c34` (offline cache support and device instructions). This closes the Android dependency/build prerequisites recorded in the attempt history above. Owner appearance acceptance and iOS validation remain open.

- Final ARM64 debug build **passed fully offline** in 14 seconds: 274 tasks, 20 executed / 254 up-to-date. The preceding authorized cache fill passed in 1m18s. No SDK download or dependency version change.
- Kernel matched compiler output: **76,129,064 bytes**, SHA256 `289b2c75a9a89b01d21055dbdddb169db4b950aa0bf4a2018fae37f6c979341f`. APK SHA256 `bb81640aa263ac5044b2c006b5ce8b681704b0fd50a0d0fb0a537c12482873de`. Launcher pixels match the approved export; P symbol/splash/notification entries are packaged; engine is ARM64 only.
- Final tooling suite **15 passed** (9.168s). Existing final Flutter suite **301 passed**, analyzer clean; source geometry and application code did not change during native cache preparation. Native `aapt2 compile` passed. Admin final head b0e5b8c passed [CI 40007548648](https://github.com/awais-ur-rehman/paths-admin/actions/runs/40007548648), alongside local lint/build and 8 tests.
- The pinned 180,591,679-byte engine artifact was fetched in bounded HTTPS ranges, checked against Google's published MD5 and ZIP CRC, and mirrored with the original vendor POM. Details/checksums are in `docs/LOGO_DEVICE_TESTS.md`. The optional local Maven cache is restricted to the app module's io.flutter resolution. Initial inclusion of the SDK Gradle project failed its repository policy; restricting to `:app` fixed that issue, and the final actual offline build passed. Included SDK/plugin repositories and normal project versions are unchanged.
- Final review found no functional brand blocker. Generated Android problem report was restored and excluded from commits. `git diff --check` passed. Local backend `/health/ready` returned ok / contract1.12.0 without service changes.
- iOS generic unsigned build **blocked**: Xcode reports its generic iOS26.5 destination unavailable, exit70, including a retry outside sandbox cache restrictions. Catalog validation is not a compile/runtime pass. No phone or emulator was operated.

Draft PRs: [mobile16](https://github.com/awais-ur-rehman/paths-mobile/pull/16), [admin16](https://github.com/awais-ur-rehman/paths-admin/pull/16). Main is unchanged. Owner next action: use `docs/LOGO_DEVICE_TESTS.md` to install the verified APK while retaining data, then check launcher/splash/headers/loader/notification artwork. No existing backend performance gate is closed by this brand update.


## UI pass 2 — authentication forms, 24 October 2026

Current phase/task: screen-by-screen authentication UI, implemented and locally verified; awaiting Android device test. Owner accepted the Open P direction and requested the supplied form/reference layout with existing Paths colors. Branch `feature/logo-refresh`; API contract **1.12.0**, unchanged. Source commits: `06858ef` (shared forms/confirmation), `0385c34` (provider controls/artwork/visual tests). No backend/admin application change in this pass. Earlier concept-selection and logo-direction checkpoints are superseded by owner acceptance; the combined auth appearance gate remains pending.

| Applicable item | Status | Files / evidence |
| --- | --- | --- |
| Center P without wordmark; centered short title/description; scoped pill fields/buttons | Implemented; automated checks verified | auth_widgets.dart, auth_form_theme.dart; login/signup/recovery visual fixtures and symbol positioning tests |
| Signup, reset and password reveal consistency | Implemented; automated checks verified | credential_screens.dart, password_field.dart, reset_screen.dart; mismatched confirmation blocks requests, corrected confirmation sends once, independent reveal state and controller disposal |
| OTP, age and profile setup fields | Implemented; automated checks verified | otp_screen.dart, account_screens.dart, profile_setup_screen.dart; existing signup/OTP/adult/profile routing tests pass |
| Required consent and policy links | Implemented; automated checks verified | auth_consent.dart; 48px checkbox target, retained edits, independent link access, policy visit does not auto-accept |
| Circular supported-provider controls and provider setup | Implemented; automated checks verified | provider_button.dart, provider_auth_sheet.dart, official round Google SVG/PNG; keyboard/disabled semantics, capability and busy gates retained. Apple remains deferred, not advertised as available |
| Keyboard, narrow layout and large text | Automated checks verified; awaiting device test | Existing and new 320/390/768 layouts; actual large-font label truncation reproduced and fixed with floating labels/compact inset at large text |
| Full automated verification | Verified | 311 Flutter tests passed without golden updates on final source; flutter analyze --no-pub clean; 15 tooling tests passed; git diff --check passed |
| Fresh whole-change review | Verified within source-review scope | No critical/important functional defect found; accidental nested provider-email shadow removed. Temporary rendering diagnostics removed before final checks |
| Android ARM64 APK and bundled assets | Verified | Offline debug build21s, 274 tasks:24 executed/250 up-to-date. Kernel/compiler/APK comparison passed; official round Google bytes match source, old pill absent, new auth copy compiled and engine ARM64 only |
| Android native UI/provider/autofill appearance | Awaiting device test | docs/AUTH_UI_DEVICE_TESTS.md; no phone/emulator operated |
| iOS build/runtime | Not run / runtime validation pending | Owner explicitly excluded iOS builds this round; implementation preserved. Earlier missing Xcode destination remains unresolved; no iOS result inferred from Android |
| Push and draft handoff | In progress | Existing mobile PR16 targets development; retain draft and main unchanged pending owner phone acceptance |

Final kernel: **76,139,616 bytes**, SHA256 `71400d110aeff05161b55df10a46901aedccb8648c4a73e0892c2edcf9647ad2`. APK SHA256 `6775dba6ffb0c81abf8309ef853e304a1d51d93610bae8bd8a27b45955728419`. Actual APK: `build/app/outputs/apk/debug/app-debug.apk`. Local backend readiness returned ok / contract1.12.0. No dependencies or SDKs installed; official Google artwork fetched under the visual-assets exception and recorded in docs/ASSETS.md.

Review/check fixes: a large-font Confirm password label was clipped and the initial compact consent target was40px; both were reproduced by failing tests and corrected. First configured Google golden initially raced image decoding; explicit asset precaching fixed the harness. Shared location/verification goldens were deliberately updated for the centered P header. An apparently missing verification P was investigated rather than accepted: cropped output contains629 ink pixels, and a live rendered pixel assertion verifies the symbol; no production painter workaround was required. Final full suite reran without updating goldens.

Material decisions: use existing OTP recovery rather than adding reset links; preserve persistent secure sessions rather than adding a decorative Remember me checkbox; retain supported Google/Apple filtering rather than add unsupported Facebook. Login remains the signed-out root with no inert Back button; signup/recovery/challenges retain functional navigation. Shared AuthScaffold styling intentionally reaches setup forms while unrelated app controls keep their current theme.

Phone instructions and acceptance steps: docs/AUTH_UI_DEVICE_TESTS.md. Existing encounter load qualification remains open; this UI pass does not rerun or close backend performance gates.
