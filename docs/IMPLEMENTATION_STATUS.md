# Implementation status

Current phase: **0, Task 1 — in progress**. API contract: `phase0.v1` (experiment only).

Main is a documentation baseline, not a working release. Feature work cannot merge until required checks and device evidence pass.

## Plan ledger


## Phase 0 — location feasibility and asset baseline


### Task 1: Real-device tracking and matching experiment

- [ ] Define typed start/pause/stopAndPurge and status/sample streams with consentEpoch/deviceSessionId. — **not started**
- [ ] Write failing lifecycle assertions: pause stops samples; logout clears queue; queue caps at 200 and expires at 15 minutes; outdated epoch rejected. — **not started**
- [ ] Implement Kotlin/Swift bridge and minimal test harness with no public discovery UI. — **not started**
- [ ] Run paired phones on same street, opposite streets, adjacent cafés, different floors, stationary tables and fast crossings; log ground truth separately from app verdict. — **not started**
- [ ] Test foreground, locked eight hours, background, app force-stop/force-quit, restart, network loss, permission downgrade, power saver and multiple devices per account. — **not started**
- [ ] Measure battery against baseline with repeated comparable runs; record device/OS, duration, sampling, precision, recall and notification latency decomposition. — **not started**
- [ ] Choose continuous/passive/adaptive trade-off from measured results; recommended adaptive. Brief-crossing rule stays off unless demonstrated. — **not started**
- [ ] Confirm map plugin compatibility, asset/font availability and supported OS floors; pin initial versions/licenses. — **not started**

## Phase 1 — shared foundation and infrastructure


### Task 2: Repositories, contracts and Compose

- [ ] Create three repositories with strict lint/type settings, lockfiles, env examples and no secrets. — **not started**
- [ ] Define scripts: backend `test`, `test:integration`, `typecheck`, `lint`, `build`, `db:migrate`, `openapi:export`; admin `test`, `typecheck`, `lint`, `build`, `test:e2e`. — **not started**
- [ ] Add a failing integration check that migrations create required constraints and `/health/ready` fails when DB is unavailable. — **not started**
- [ ] Implement PostgreSQL/PostGIS, Valkey, API/worker, proxy and development email services with volumes/health checks. — **not started**
- [ ] Add structured redaction, request IDs, typed errors, timeouts and OpenAPI export; pin generated clients in consumers. — **not started**
- [ ] Verify a fresh boot and restart preserve data; worker/API stop gracefully; public ports exclude DB/cache. — **not started**

### Task 3: Email authentication, age gate and sessions

- [ ] Test OTP purpose/expiry/attempts/resend invalidation, replay, under-18 DOB, password reset revocation and refresh-family reuse. — **not started**
- [ ] Implement signup/login/OTP/recovery with Argon2id and hashed secrets; server guards enforce account status. — **not started**
- [ ] Implement splash, one onboarding screen, auth forms and guarded setup routes. — **not started**
- [ ] Implement single-flight Dio refresh; test ten concurrent 401s produce one refresh, one replay each and no loop. — **not started**
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


## Evidence

No application checks executed at baseline. See subsequent phase evidence entries for actual results and prerequisite blockers.
