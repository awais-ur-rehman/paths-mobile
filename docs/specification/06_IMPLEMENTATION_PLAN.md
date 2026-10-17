# Paths Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task when that skill is available. Use subagent-driven-development only if the owner explicitly selects that execution method. Steps use checkbox (`- [ ]`) syntax for tracking. This delivery creates documentation only; no implementation has begun.

**Goal:** Build the Android/iOS Paths encounter app, NestJS backend and React admin portal with measurable location behavior and complete account erasure.

**Architecture:** Three repositories; modular backend plus worker; PostGIS matching; adaptive native tracking; Flutter feature modules; private media; transactional outbox.

**Tech Stack:** Flutter/Cubit/BLoC/go_router/Dio, Kotlin/Swift tracking, NestJS/PostgreSQL/PostGIS/Valkey/BullMQ, React/Vite/shadcn.

**Spec:** [Scope](01_SCOPE.md), [PRD](02_PRD.md), [TRD](03_TRD.md), [App Flow](04_APP_FLOW.md), [System/UI](05_SYSTEM_UI_DESIGN.md).

## Global constraints

- Implement confirmed decisions D01–D19; proposed defaults require recorded changes if modified.
- 18+; no exact peer coordinates; no contact without encounter eligibility; private saves; accepted connection for text chat.
- Optional CNIC never gates features. Retain records during account lifetime; erase on deletion.
- Privacy default private; 30-day discovery; raw location 24h; native queue max200/15min; account live purge <=24h; backups <=7d.
- Google and Apple sign-in are the last feature implementation task; validation/deployment follow.
- Stateless screen roots, selective widget rebuilds; stateful controller wrappers allowed and required where appropriate.
- No microservices, paid-only tracking SDK assumptions, fake matching percentages, or fixed background timing promises.
- Proposed platform floors Android10/iOS16, verified before pinning versions. Current store target SDK requirements separately checked at submission.
- Do not commit real CNICs, coordinates, credentials, access tokens or user photos as fixtures.

## Review focus

1. Deletion concurrent with media/job retry must not recreate personal data — Tasks 8, 12.
2. Device clock changes and stale fixes must not generate false live encounters — Tasks 1, 5, 6.
3. Simultaneous requests, blocking and token refresh must not bypass authorization — Tasks 3, 7, 9.
4. GPS drift between adjacent venues must not become a claim of same-café presence — Tasks 1, 6.
5. Offline client caches and restored backups must not resurrect deleted chat/profiles — Tasks 9, 12, 15.

## Working conventions

Each task owns a meaningful feature and its tests. For behavioral code, first write the named failing test, run it to establish the failure, implement the smallest coherent change, rerun verification, then commit within the relevant repo. Do not add tests that merely mirror trivial component markup. Use real PostGIS in integration tests. Every unchecked box is future work, not claimed completion.

Create a decision log and implementation status file per repo. For cross-repo tasks, record contract version and commit IDs together. A phase passes only with attached evidence and no unresolved critical defect.

## File ownership map

| Repo paths | Responsibility |
|---|---|
| backend `src/modules/<feature>/{*.controller,*.service,*.repository}.ts` | HTTP boundary, business policy, persistence |
| backend `src/contracts/`, `openapi/paths.v1.json` | DTOs, errors, exported API schema |
| backend `src/worker.ts`, `src/jobs/`, `src/outbox/` | Async processing and reliable dispatch |
| backend `db/schema/`, `db/migrations/`, `test/integration/` | Constraints, migrations, database behavior tests |
| backend `infra/compose.yaml`, `Dockerfile`, `docs/runbooks/` | Reproducible deployment and recovery |
| mobile `lib/features/<feature>/domain/` | Repository interfaces and complex business use cases |
| mobile `lib/features/<feature>/data/` | API DTO mapping/repository implementation |
| mobile `lib/features/<feature>/presentation/` | Cubits/Blocs, screens, local widgets |
| mobile `lib/core/platform/location_tracker.dart` and native source | Tracking contract/lifecycle |
| mobile `lib/app/`, `lib/shared/widgets/` | Router, dependency wiring, design system |
| admin `src/features/<feature>/`, `src/lib/api/`, `src/components/ui/` | Feature UI, typed transport, shadcn primitives |

## Phase 0 — location feasibility and asset baseline

### Task 1: Real-device tracking and matching experiment

**Files:** mobile `lib/core/platform/location_tracker.dart`, `android/app/src/main/kotlin/<namespace>/location/PathsLocationTracker.kt`, `ios/Runner/Location/PathsLocationTracker.swift`, `integration_test/location_lifecycle_test.dart`; backend `test/fixtures/encounters/`, `docs/location-feasibility.md`. Resolve `<namespace>` once from the chosen application ID before creating files.

**Consumes:** TRD LocationSample and TrackingPolicy. **Produces:** `LocationTracker` interface, recorded anonymized test outcomes, selected sampling policy; no production claim before evidence.

- [ ] Define typed start/pause/stopAndPurge and status/sample streams with consentEpoch/deviceSessionId.
- [ ] Write failing lifecycle assertions: pause stops samples; logout clears queue; queue caps at 200 and expires at 15 minutes; outdated epoch rejected.
- [ ] Implement Kotlin/Swift bridge and minimal test harness with no public discovery UI.
- [ ] Run paired phones on same street, opposite streets, adjacent cafés, different floors, stationary tables and fast crossings; log ground truth separately from app verdict.
- [ ] Test foreground, locked eight hours, background, app force-stop/force-quit, restart, network loss, permission downgrade, power saver and multiple devices per account.
- [ ] Measure battery against baseline with repeated comparable runs; record device/OS, duration, sampling, precision, recall and notification latency decomposition.
- [ ] Choose continuous/passive/adaptive trade-off from measured results; recommended adaptive. Brief-crossing rule stays off unless demonstrated.
- [ ] Confirm map plugin compatibility, asset/font availability and supported OS floors; pin initial versions/licenses.

**Verification:** `flutter test`; `flutter test integration_test/location_lifecycle_test.dart -d <physical-device-id>` on both platforms plus manual OS tests. Pass means lifecycle assertions succeed and limitations are documented; battery/precision target failures require an explicit product decision before release. Commit harness/report separately from later production integrations.

## Phase 1 — shared foundation and infrastructure

### Task 2: Repositories, contracts and Compose

**Files:** backend `src/main.ts`, `src/worker.ts`, `src/contracts/error.dto.ts`, `infra/compose.yaml`, `Dockerfile`, `db/migrations/0001_core.sql`, `test/integration/bootstrap.spec.ts`; mobile `lib/app/bootstrap.dart`, `lib/app/router.dart`, `lib/core/network/api_client.dart`; admin `src/main.tsx`, `src/lib/api/client.ts`.

**Produces:** health endpoints, migration runner, API error envelope, generated client workflow, CI scripts.

- [ ] Create three repositories with strict lint/type settings, lockfiles, env examples and no secrets.
- [ ] Define scripts: backend `test`, `test:integration`, `typecheck`, `lint`, `build`, `db:migrate`, `openapi:export`; admin `test`, `typecheck`, `lint`, `build`, `test:e2e`.
- [ ] Add a failing integration check that migrations create required constraints and `/health/ready` fails when DB is unavailable.
- [ ] Implement PostgreSQL/PostGIS, Valkey, API/worker, proxy and development email services with volumes/health checks.
- [ ] Add structured redaction, request IDs, typed errors, timeouts and OpenAPI export; pin generated clients in consumers.
- [ ] Verify a fresh boot and restart preserve data; worker/API stop gracefully; public ports exclude DB/cache.

**Verification:** `docker compose -f infra/compose.yaml up -d --build`; `npm run db:migrate`; `npm run test:integration -- bootstrap`; mobile `flutter analyze`; admin `npm run typecheck`. Commit reproducible foundation.

### Task 3: Email authentication, age gate and sessions

**Files:** backend `src/modules/auth/auth.service.ts`, `otp.service.ts`, `session.service.ts`, `db/migrations/0002_auth.sql`, `test/integration/auth.spec.ts`; mobile `lib/features/auth/presentation/auth_cubit.dart`, auth screens, `lib/core/network/refresh_coordinator.dart`.

**Produces:** `signUp(input): Challenge`, `verifyOtp(challengeId,code): Session`, `refresh(token): Session`, password-reset grant; route session state.

- [ ] Test OTP purpose/expiry/attempts/resend invalidation, replay, under-18 DOB, password reset revocation and refresh-family reuse.
- [ ] Implement signup/login/OTP/recovery with Argon2id and hashed secrets; server guards enforce account status.
- [ ] Implement splash, one onboarding screen, auth forms and guarded setup routes.
- [ ] Implement single-flight Dio refresh; test ten concurrent 401s produce one refresh, one replay each and no loop.
- [ ] Verify keyboard, paste/autofill, offline/error states and suspended-account support/deletion access.

**Verification:** `npm run test:integration -- auth`; `flutter test test/features/auth`; run physical-device signup/reset against development SMTP. Commit auth slice.

### Task 4: Design system, profile and optional verification submission

**Files:** mobile `lib/app/theme/paths_theme.dart`, `lib/shared/widgets/`, `lib/features/profile/`, `lib/features/verification/`; backend `src/modules/profiles/`, `src/modules/verifications/`, `test/integration/profile-access.spec.ts`.

**Consumes:** session and media adapter stub. **Produces:** `ProfileSummary`, `ProfileVisibility`, `VerificationStatus`; setup completion state.

- [ ] Build tokens/components from UI doc; record reference-to-product substitutions.
- [ ] Test username uniqueness, private DOB exclusion, adult gate, public/private response fields and CNIC skip entitlement.
- [ ] Implement profile setup/edit and verification submit/status against upload contracts from Task8 (use mocked pending asset until then).
- [ ] Add selective rebuild checks for badge/save/status and controller disposal tests where relevant.
- [ ] Verify layouts at 320/390/768 widths and 200% text; add meaningful golden tests with approved assets.

**Verification:** `flutter test test/features/profile test/shared`; `npm run test:integration -- profile-access`. No live CNIC collection until Task8 protected storage is complete. Commit UI/profile slice.

## Phase 2 — location ingestion, matching and discovery

### Task 5: Consent-aware ingestion

**Files:** backend `src/modules/locations/location.controller.ts`, `location.service.ts`, `location.repository.ts`, `test/integration/location-ingest.spec.ts`; mobile `lib/features/discovery/data/location_sync_service.dart`, permission/status UI.

**Consumes:** LocationTracker. **Produces:** `ingestBatch(actor, samples): BatchReceipt` with accepted/duplicate/rejected sample IDs and reasons.

- [ ] Test max50 batch, invalid coordinate, future>30sec, stale>15min, duplicate ID, old device lease and paused/deleting account rejection.
- [ ] Implement transactionally stored sample/outbox records and 24h retention worker.
- [ ] Integrate disclosure, staged native permissions and bounded encrypted queue; never upload after local pause.
- [ ] Test offline control ordering: pause/logout clears queued fixes and invalidates prior epochs before any resume batch.

**Verification:** `npm run test:integration -- location-ingest`; `flutter test test/features/discovery`; repeat physical permission/kill cases. Commit ingestion.

### Task 6: Encounter matcher and privacy-safe Home

**Files:** backend `src/modules/encounters/encounter-policy.ts`, `encounter.service.ts`, `encounter.repository.ts`, `src/jobs/match-location.job.ts`, `test/integration/encounter.spec.ts`; mobile `lib/features/discovery/presentation/encounter_bloc.dart`, `home_screen.dart`, `widgets/encounter_map.dart`.

**Produces:** `evaluatePair(evidence,policy): MatchDecision`; `listEncounters(actor,filters,cursor): Page<EncounterCard>`.

- [ ] Write boundary tests for <=50m/<=60sec and accuracy rules; two evidence pairs 20–120sec apart; reject invented stationary dwell.
- [ ] Test concurrent inverse ingestion creates one session and two notification intents; retry does not inflate encounter count.
- [ ] Test spatial neighbors across arbitrary grid edges, adjacent venue false positives and delayed historical batches without live push.
- [ ] Implement PostGIS query, pair lock/session dedup and coarse-area/time serialization; exclude blocked/paused/deleting users.
- [ ] Build map/list Home with Recent/Nearby, radius filters and permission/offline/map-failure states.
- [ ] Verify API responses and network captures contain no peer coordinates, exact distances or exact timestamps.

**Verification:** `npm run test:integration -- encounter`; `flutter test test/features/discovery`; query `EXPLAIN (ANALYZE, BUFFERS)` for dense and dispersed fixtures. Commit encounter slice.

## Phase 3 — saves, requests and push

### Task 7: Relationship policy and notifications

**Files:** backend `src/modules/relationships/relationship.service.ts`, `relationship.repository.ts`, `src/modules/notifications/notification.service.ts`, `src/outbox/dispatcher.ts`, `test/integration/relationships.spec.ts`; mobile `lib/features/likes/`, `lib/features/requests/`, `lib/features/notifications/`.

**Produces:** `save(actor,target)`, `requestConnection(actor,target)`, `transitionRequest(actor,id,action)`, `canInteract(actor,target)`.

- [ ] Test ineligible target denied, private save invisible to subject, saved eligibility survives history expiry.
- [ ] Test inverse request race, sender accepting own request, duplicate accept, expired request and seven-day cooldown.
- [ ] Implement atomic pair transitions and unique constraints; no implicit connection from reciprocal request.
- [ ] Implement Saved/Incoming/Sent screens with status, cancel/accept/decline and unavailable states.
- [ ] Implement FCM/APNs device registration and transactional notification fan-out; generic payloads, pair six-hour cooldown, user cap default ten encounter alerts/day with in-app history unaffected.
- [ ] Test notification worker retry, invalid token cleanup, opt-out, delayed historical match, block/deletion between enqueue and send.

**Verification:** `npm run test:integration -- relationships`; `flutter test test/features/likes test/features/requests`; verify real push on iOS/Android. Commit relationship slice.

## Phase 4 — media and messaging

### Task 8: Protected media and camera publishing

**Files:** backend `src/modules/media/media.service.ts`, `storage.port.ts`, `src/jobs/process-media.job.ts`, `src/modules/posts/`, `test/integration/media-access.spec.ts`; mobile `lib/features/camera/`, `lib/features/posts/`.

**Produces:** `createUploadIntent(actor,input): UploadIntent`, `completeUpload(actor,id): AssetStatus`, `publishPost(actor,assetId,caption): Post`.

- [ ] Test wrong owner/type/size, decompression abuse, EXIF removal, private viewer denied and pending asset unpublished.
- [ ] Implement private storage adapters, quarantine processing, variants and CNIC record retention; no public CNIC links.
- [ ] Add safety-review state for user-visible images, neutral pending avatar, pending posts and server text filtering; test unreviewed/rejected content never reaches public responses.
- [ ] Connect profile/CNIC screens from Task4 to real uploads; implement camera/gallery/preview/caption/retry/cancel.
- [ ] Test privacy/block/deletion revokes media access; worker must not publish after deletion barrier.
- [ ] Add orphan/multipart cleanup and object inventory for deletion manifest.

**Verification:** `npm run test:integration -- media-access`; `flutter test test/features/posts`; physical camera permission/upload failures; inspect sanitized sample metadata. Commit media slice.

### Task 9: Text chat, reconnect and access revocation

**Files:** backend `src/modules/chat/chat.service.ts`, `chat.gateway.ts`, `message.repository.ts`, `test/integration/chat.spec.ts`; mobile `lib/features/chat/presentation/chat_bloc.dart`, `chat_screen.dart`, data sync repository.

**Produces:** `sendMessage(actor,conversationId,clientMessageId,text): Message`, `listMessages(actor,id,cursor): Page<Message>` and realtime envelopes.

- [ ] Test send before accept denied; sender spoof denied; text>4000 denied; same client ID inserts once.
- [ ] Test concurrent block/disconnect/delete vs send using consistent locks; no unauthorized post-commit delivery.
- [ ] Implement REST persistence, server-assigned sockets and cursor catch-up; ACK only after commit.
- [ ] Implement chat list/thread, lazy history, pending/failed retry, unread state and read-only disconnected history.
- [ ] Test disconnect/reconnect with missed/duplicate/out-of-order events; deleted conversation removed from caches on sync.

**Verification:** `npm run test:integration -- chat`; `flutter test test/features/chat`; manual two-device airplane-mode recovery. Commit chat slice.

## Phase 5 — moderation and admin

### Task 10: Blocking/reporting and restricted account lifecycle

**Files:** backend `src/modules/safety/safety.service.ts`, `src/modules/users/account-status.service.ts`, `test/integration/safety.spec.ts`; mobile report/block/settings screens.

- [ ] Test block removes both saves, cancels requests, stops sends, excludes discovery and revokes private media; unblock restores nothing automatically.
- [ ] Implement report categories, scoped evidence and acknowledgment; privacy-aware evidence deletion hooks.
- [ ] Implement deactivation/reactivation status guard, session revoke and queue suppression.
- [ ] Add support/delete access for restricted users and suspected-underage escalation flow.

**Verification:** `npm run test:integration -- safety`; `flutter test test/features/safety`. Commit safety slice.

### Task 11: Admin portal and review workflow

**Files:** admin `src/features/auth/`, `verifications/`, `users/`, `reports/`, `audit/`; backend `src/modules/admin/`, `test/integration/admin-rbac.spec.ts`; admin `e2e/review.spec.ts`.

**Produces:** role-checked review/action endpoints, React operational workflows.

- [ ] Test reviewer/moderator/admin permission matrix and unauthenticated CNIC access denied.
- [ ] Implement staff provisioning/MFA/session/CSRF; shadcn shell, server-paginated lists and typed clients.
- [ ] Implement protected no-store CNIC viewer, claim/version conflict, approve/decline and notification.
- [ ] Implement image safety-review queue and text-filter escalation/appeals, with required pilot staffing.
- [ ] Implement deactivation/reactivation, reports and redacted audits; no unrestricted private-message browser.
- [ ] Verify mobile-width admin usability, keyboard navigation and sensitive-content no-cache behavior.

**Verification:** `npm run test:integration -- admin-rbac`; admin `npm run test:e2e -- review`; `npm run build`. Commit admin slice.

## Phase 6 — deletion, robustness and load

### Task 12: Complete account erasure

**Files:** backend `src/modules/deletion/deletion.service.ts`, `deletion-manifest.repository.ts`, `src/jobs/delete-account.job.ts`, `test/integration/deletion.spec.ts`, `docs/runbooks/restore.md`; mobile deletion screens/cache purger; admin public `src/features/public/delete-account/`.

**Produces:** `beginDeletion(actor,reauthProof,idempotencyKey): DeletionReceipt`, resumable stages and restore suppression.

- [ ] Seed two connected users with messages, posts, CNIC versions, reports, locations, caches and queued jobs; test deleting one leaves zero personal records and removes the shared conversation.
- [ ] Test FK constraints after deletion, another unrelated conversation unaffected, and staff audit anonymization without copied subject PII.
- [ ] Implement immediate barrier/revocation, encrypted independent manifest, external object/provider purge and bounded DB cascades.
- [ ] Inject failures after each stage; retry completes without losing manifest or recreating assets.
- [ ] Implement in-app reauth/delete/receipt and external email-OTP deletion path; validate offline request does not show false success.
- [ ] Implement backup expiry/suppression ledger; restore a pre-deletion backup in isolation and prove deleted data is removed before serving traffic.
- [ ] Verify counterpart cache invalidation on reconnect and disclosure of screenshots/backup timing limits.

**Verification:** `npm run test:integration -- deletion`; manual restore drill with signed-off evidence; run storage inventory reconciler. Commit deletion slice.

### Task 13: Load, security, battery and UI hardening

**Files:** backend `test/load/encounters.js`, `docs/operational-baseline.md`; mobile `integration_test/full_journey_test.dart`, `docs/performance.md`; admin accessibility/e2e fixtures.

- [ ] Test 50 samples/sec sustained, 200/sec burst, 300 socket clients, all candidates in one area; measure query plans/locks and outbox lag.
- [ ] Test Valkey restart, worker crash, database restart, upload cancellation and SMTP/push outage; recover committed work.
- [ ] Run authorization enumeration, rate-limit, token replay, CSRF, private-media and secrets/log-redaction checks.
- [ ] Repeat battery/coverage experiment using production integration, not only the Phase0 harness.
- [ ] Profile rebuilds/map offscreen behavior/image memory; fix demonstrated regressions.
- [ ] Complete accessibility/text-scale/reference screenshot comparisons and update honest product limitations.

**Verification:** all CI scripts pass; record p95 values and failure recovery; no unsupported claim of target achievement. Commit fixes and evidence.

## Phase 7 — final feature: Google and Apple authentication

### Task 14: Provider login and safe linking

**Files:** backend `src/modules/auth/providers/google.provider.ts`, `apple.provider.ts`, `identity-link.service.ts`, `test/integration/social-auth.spec.ts`; mobile `lib/features/auth/data/social_auth_service.dart`, provider buttons/settings.

**Consumes:** existing Session/ProfileSetup/Deletion interfaces. **Produces:** authenticated sessions from verified provider identities, explicit linking and revocation.

- [ ] Test invalid audience/issuer/nonce/expired token and signature rotation; use test verifier fixtures, never production credentials in repo.
- [ ] Test same-email collision does not merge; existing-account reauthentication required; provider+subject unique.
- [ ] Implement Google and Apple SDK flows, cancellation handling, Apple relay/name-first-login behavior and missing email recovery.
- [ ] Integrate profile/adult onboarding and secure provider reauthentication for delete.
- [ ] Add Apple token revocation to deletion workflow, test provider outage retry; prevent removing last sign-in method.
- [ ] Verify both providers on real signed iOS/Android builds as supported by configured provider flows; recheck login-service store requirement.

**Verification:** `npm run test:integration -- social-auth`; `flutter test test/features/auth`; real provider staging walkthrough. This is the final feature task. Commit provider integration.

## Phase 8 — deployment and release validation

### Task 15: Operational and store readiness

**Files:** backend `infra/compose.production.yaml`, `docs/runbooks/deploy.md`, `docs/runbooks/rollback.md`; admin public policies/support pages; mobile release configuration and store submission notes.

- [ ] Choose VM or Render using measured resource demand and current vendor quotations; document recurring storage/email/tiles/backups/developer-account costs.
- [ ] Deploy staging with HTTPS, private data ports, nonroot containers, encrypted backups and working rollback/migrations.
- [ ] Run full two-user journey: signup→OTP→profile→skip/submit CNIC→encounter→save→request→accept→chat→post→privacy→block→delete.
- [ ] Repeat deletion/restore with final social auth included and verify no stale events recreate data.
- [ ] Publish truthful privacy, terms, community/child-safety and deletion pages; staff support and escalation owner assigned.
- [ ] Complete Google background location declaration/demo, Data safety, target audience/minor restrictions as applicable; Apple privacy/review notes and login/deletion demonstrations.
- [ ] Obtain Pakistan-specific legal applicability review; do not claim friendship branding guarantees regulatory acceptance.
- [ ] Submit only after battery/accuracy limitations and platform behavior are reflected in product copy; production rollout is a separate explicit owner action.

**Verification:** real signed builds, functioning production-like backend, accessible public deletion route, clean restore drill, no critical security/functional issues. Final release report lists remaining limitations and rollback triggers.

## Phase dependency order

0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Task4 may use upload mocks, but cannot ship before Task8. Moderation/deletion contracts should be designed from the beginning even when their UI is built later. No public pilot with real CNIC/location data before safety/deletion controls exist.

## Handoff to Codex

Read every linked spec before writing code. Start with Phase0 and keep the three repositories separate. Follow feature boundaries, record any changed assumptions, and mark tasks complete only with actual evidence. If OS behavior contradicts the desired background promise, report measurements and adjust the agreed product behavior instead of hiding the limitation. Do not deploy, submit store builds or create paid resources as part of documentation execution without the owner's instruction.
