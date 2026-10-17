# Paths — Technical Requirements Document

Version 1.0 • 17 October 2026 • Companion: [PRD](02_PRD.md), [Research](07_RESEARCH.md)

## 1. Architecture and technology decisions

Use a modular NestJS monolith with REST and Socket.IO, plus a worker process sharing application modules. PostgreSQL is the source of truth; PostGIS performs geographic queries. Valkey supports BullMQ jobs, rate limits and ephemeral cache. Persist critical events in a PostgreSQL outbox before job dispatch. No Kafka or microservice mesh.

| Layer | Selection | Reason / boundary |
|---|---|---|
| Mobile | Flutter stable, Dart, flutter_bloc | Cubit for screen workflows; Bloc for concurrent event streams |
| Routing/network | go_router, Dio | Auth redirects, shell branches, centralized HTTP behavior |
| Models/storage | Freezed/json_serializable where useful; secure token storage; encrypted short-lived local queue | Immutable typed data; no sensitive content in ordinary preferences |
| Map | maplibre_gl adapter with configurable style/tile URL | Native vector rendering; verify selected release on both platforms |
| Tracking | Native Kotlin/Swift adapter behind LocationTracker; geolocator for foreground utility where appropriate | Explicit ownership of lifecycle/low-power behavior; no paid-only runtime dependency assumed |
| Backend | NestJS, TypeScript strict, node-postgres + Drizzle migrations/schema | SQL-first PostGIS queries with parameter binding; isolate spatial SQL in repository |
| Database | Supported PostgreSQL + compatible PostGIS release | Geography meters, GiST indexes, FK integrity |
| Jobs/cache | Valkey + open-source BullMQ | Retries and event fan-out; pin compatible versions and test failure recovery |
| Media | Private S3-compatible adapter; local private filesystem adapter for development | Avoid vendor coupling; production bucket selected at deployment |
| Push/email | FCM/APNs; SMTP provider, Mailpit for development | Delivery adapters; store credentials only server-side |
| Admin | React, Vite, TypeScript, shadcn/ui, React Router, TanStack Query, React Hook Form/Zod | Client application, no Next.js server needed |
| Operations | Docker Compose, Caddy or Nginx, structured logs, OpenTelemetry-compatible metrics | VM portability and operational visibility |

Pin exact tested versions and lockfiles at kickoff; do not copy a version from this document as “latest.” Check license files for the actual transitive dependency versions. Native platform push/location dependencies are not a fully open-source ecosystem, even if application code is.

## 2. Repository boundaries

`paths-backend`: modules, SQL migrations, OpenAPI schema, worker, Dockerfile, compose.yaml, infra/runbooks and contract fixtures.

`paths-mobile`: feature-oriented Dart modules, design tokens/widgets, native tracking bridge, generated API client, unit/widget/integration tests.

`paths-admin`: React features, API client, role-aware UI, public policy/delete pages, tests, static build.

Backend publishes versioned OpenAPI JSON. Consumers pin a contract version and regenerate typed clients in their own repo. API changes remain additive until all supported app versions migrate. No direct database access from mobile/admin. Secrets/examples are separated; `.env.example` contains placeholders only.

## 3. Location strategy

### 3.1 Alternatives and selection

- Continuous high accuracy: simplest detection concept, highest energy cost and still subject to lifecycle/permission constraints. Reject as always-on default.
- Passive significant changes/geofences: low duty cycle, insufficient for many brief street crossings. Use as signals, not proof of encounter.
- Adaptive native services: selected. Change precision/delivery by foreground state, motion, uncertainty and permission. Adds native implementation effort and requires field validation.

H3 partitions geography; it does not render maps, reduce GPS power by itself or establish co-presence. Initial PostGIS radius queries are sufficient at planned load. Introduce H3 only after query evidence shows a need; examine neighboring cells and still perform exact meter/time checks. Same-cell matching alone misses boundary pairs and produces false matches.

### 3.2 Native interfaces

`LocationTracker.start(TrackingPolicy)`, `pause()`, `stopAndPurge()`, `statusStream`, `sampleStream`.

`LocationSample`: sampleId UUID, deviceSessionId, sequence, capturedAt UTC, latitude, longitude, horizontalAccuracyM, optional speedMps, appState, precisionMode, policyVersion, consentEpoch. Server supplies receivedAt and authenticated userId. Client cannot set a different owner.

Use platform channel messages with typed contracts. Native background capture must be able to queue/send a small batch without a visible Flutter screen or a Dart timer kept artificially alive. Gate every native callback on current account/consent epoch. Only one selected device session actively contributes location for an account; a new active session invalidates the previous tracker's lease.

### 3.3 Proposed adaptive policy (not an OS scheduling guarantee)

| Mode | Desired policy | Upload behavior |
|---|---|---|
| Foreground Home moving | Balanced accuracy; ~15–30 sec / 25–50 m triggers | Batch at most 30 sec; earlier if useful new fix |
| Foreground uncertain | Short high-accuracy burst, max 20 sec | Stop after useful fix/timeout; do not loop continuously |
| Background moving | Native permitted service; request ~60–120 sec / 50–100 m where supported | Batch on native delivery, accept throttling |
| Stationary | Reduce/stop fine GPS; passive/significant-change or motion wake | Last fix expires; never pretend stationary means indefinitely present |
| Low power | Reduce bursts and batching frequency | Mark coverage reduced; no battery-optimization bypass tricks |
| Permission denied / paused / signed out | No samples | Purge queue and stop native service |

Android: use fused provider, foreground service only where legally/platform-permitted with correct location type, visible ongoing notification, user opt-in and current foreground-service launch restrictions. Ordinary background execution may provide only a few updates per hour [R01]. Do not use WorkManager as a precise location clock or silently restart after user force-stop.

iOS: use Core Location authorization and background capability appropriately; significant-change/visit events can reduce power but are too coarse for guaranteed street encounters. Continuous background sessions cost power. Force quit, reduced accuracy and system suspension may prevent timely updates [R02]. Do not promise a fixed background interval or reliable resurrection.

Camera/chat screens do not need high-frequency map tracking. Pause map rendering when not visible. No location WebSocket heartbeat; batch HTTPS with bounded exponential backoff. The native queue is encrypted, scoped to account, capped at 200 samples / 15 minutes, purged on logout/pause/delete. Network reachability triggers retry, not constant polling.

## 4. Encounter engine

### 4.1 Validity and time

- Accept latitude [-90,90], longitude [-180,180], finite numbers, bounded body/batch (max 50 samples).
- Deduplicate `(user_id, device_session_id, sample_id)` and reject stale session/consent epochs.
- Reject future capture >30 sec beyond server time; record device/server time offset during session establishment. Untrusted clock drift causes historical-only treatment, not false live matches.
- For live matching require capture age <=120 sec; batch ingestion may accept <=15 min for historical matching. Older samples dropped.
- Candidate evidence: accuracy <=25 m on both devices. Coarse permission or poor indoor fixes do not unlock encounters; show reduced accuracy state.
- Suspicious speeds/teleports/mock-location flags reduce trust or discard evidence. This is abuse resistance, not spoof-proof location attestation.

### 4.2 Matching baseline

Search time-bounded samples from other discoverable adults with `ST_DWithin(geography_point, incoming_point, 50)` and capture-time difference <=60 sec. Use GiST spatial index plus time/user indexes; query plan and partition pruning must be checked under load.

Conservative standard rule: two independent paired observations separated by 20–120 sec, each meeting `distance + accuracyA + accuracyB <= 70 m`, with point distance <=50 m and individual accuracy <=25 m. Distinct sample IDs and increasing times prevent retry counting as corroboration. This favors longer café/street co-presence but misses fast crossings.

Proposed brief-crossing rule: a single pair with time difference <=15 sec, point distance <=20 m, and individual accuracy <=10 m may qualify. Keep behind a feature flag until labeled walking tests demonstrate acceptable precision. Without this validated rule, explicitly accept missed brief crossings; never quietly widen distance to increase matches.

Accuracy values are estimates, not hard geometric bounds. Neither rule proves same venue, line of sight or a social meeting. No inferred exact café name. Candidate evidence expires after ten minutes. Do not bridge long sampling gaps with invented trajectories or reuse a last-known fix as continuing presence.

### 4.3 Transactions and races

1. Validate session/status/consent and commit samples + matching outbox event in one transaction.
2. Worker processes using stable sample IDs and ordered canonical pair `(min(userId), max(userId))`.
3. Serialize pair evaluation using a transaction advisory lock; also serialize against user deletion/block actions by consistent user lock order.
4. Recheck active states, blocks and consent inside transaction. Update/create encounter session (30-minute inactivity gap); ensure unique evidence fingerprint.
5. Create per-user notification outbox rows with unique `(encounter_session_id, recipient_id, kind)`; commit.
6. Dispatcher rechecks visibility, notification cooldown and account state before sending.

Retry jobs freely; duplicate tasks must not create duplicate encounters/requests/messages. Outbox delivery is at least once. Push provider/device delivery is best effort, so exactly-once alerts cannot be guaranteed. Use collapse/event IDs and client dedup.

## 5. Privacy-safe discovery

Return an `EncounterCard`, not raw location samples: userId, username, displayName, age, bio, permitted avatar, verification badge, coarseAreaId, coarseAreaLabel, timeBucket, encounterCount, requestState, eligibilityExpiresAt.

Quantize encounter midpoint into a server-chosen ~500 m area; display approximate centroid/area polygon, without asserting a hard anonymity guarantee. Time buckets: “recently,” “earlier today,” date for older history. No exact distance, bearing, speed or live timestamp. Do not continuously update marker position or add fresh random jitter on every fetch (averaging leaks location). An area is historical, fixed for the encounter.

Radius controls filter already-authorized coarse encounter areas. Do not accept arbitrary map-center queries for people; center uses authenticated user's eligible coarse position or history. Pagination and rate limits prevent enumeration. Sparse areas still reveal contextual presence; privacy copy must explain that approximate display does not make a person anonymous.

Block/pause/deactivate/delete invalidate discovery caches. Private media checks are server-side for every grant. Public does not bypass relationship eligibility for discovery.

## 6. Database model and integrity

UUID identifiers, UTC timestamps, DB constraints for state transitions, explicit migrations. Store DOB privately; derive age at response time with a documented calendar-date policy. Email canonicalization should not rewrite provider-specific dots/aliases.

| Table | Key fields / constraints | Delete behavior |
|---|---|---|
| users | id, status, email unique, password_hash nullable, DOB, consent_epoch | Root row hard-deleted after erasure workflow |
| profiles | user_id unique FK, username canonical unique, name, bio, gender, visibility | CASCADE user |
| auth_identities | user_id, provider, provider_subject unique | CASCADE user; revoke provider grant first |
| sessions / challenges | user_id, hashed token/code, expiry, purpose | CASCADE; revoke at deletion start |
| devices | user_id, push token encrypted, tracking lease | CASCADE; token removed immediately |
| media_assets | owner_id, kind, object-key manifest, processing status | Explicit external purge then CASCADE metadata |
| posts | owner_id, asset_id, caption, timestamps | CASCADE owner; asset lifecycle explicit |
| verifications | user_id, status, document_asset_ids, reviewer_id, reason | CASCADE subject; reviewer SET NULL if removed |
| location_samples | user_id, geography Point/4326, times, accuracy, IDs | CASCADE; TTL 24h; partition strategy tested |
| encounters | low_user_id, high_user_id, coarse area, bucket/count/session | CASCADE either user; history TTL 30d |
| saved_profiles | owner_id, target_id, saved_at, eligibility flag | Both FKs CASCADE; unique pair, no self |
| connection_requests | canonical pair, sender_id, receiver_id, state, expires_at | CASCADE either user; partial unique active pair |
| connections | canonical pair unique, state | CASCADE either user; no self |
| conversations | connection_id unique | CASCADE connection |
| messages | conversation_id, sender_id, client_message_id, sequence, body | CASCADE conversation or sender; unique sender/client ID |
| blocks | blocker_id, blocked_id unique pair | CASCADE either user |
| reports | reporter/subject/content references, category/evidence | Purge personal content and linked rows on user deletion |
| notifications | recipient_id, subject_id, event_id unique, read_at | CASCADE participants; no private body in queue |
| outbox | type, entity IDs, dedup key, processing state | Purge user-bearing payloads when deleting |
| admin_audit | staff ID, action, target ID, metadata allowlist | Remove target identifiers/evidence at deletion; nonidentifying counts only |
| deletion_jobs | encrypted temporary manifest, state, retries | Independent of user FK; purge identifiers after completion/backup window |

Index every referencing FK needed for deletion. Never globally disable foreign keys. PostgreSQL cannot cascade-delete external objects; an explicit workflow owns that work. Critical cascade boundaries are migration-tested. Partitioning must preserve uniqueness semantics (e.g. dedup registry for partition-spanning IDs), so start with ordinary indexed samples + batched TTL purge if adequate.

Removing a connection by user choice marks it disconnected and preserves read-only history. Blocking marks it blocked and hides it; deletion physically cascades the conversation and all its messages. This stronger deletion also removes the other participant's messages in that one-to-one conversation, preventing dangling unread/history rows; explain this on the deletion screen.

## 7. API and realtime contract

Base `/v1`; bearer access token for mobile; separate secure HttpOnly admin session cookie. JSON error `{code,message,fieldErrors?,requestId}`; ISO UTC dates; opaque cursor pagination default 20/max50. Mutation idempotency key bound to actor/route/body hash; same key + different body is conflict. Apply object-level authorization before exposing existence.

| Endpoints | Main rule |
|---|---|
| POST /auth/signup, /auth/otp/verify, /auth/otp/resend | Purpose-bound challenge, rate limits |
| POST /auth/login, /auth/refresh, /auth/logout | Rotating refresh family with reuse detection |
| POST /auth/password/forgot, /auth/password/reset | Generic request response; reset grant only |
| POST /auth/google, /auth/apple; /auth/identities/link | Provider verification; explicit linking reauthentication |
| GET/PATCH /me; PATCH /me/settings | Typed allowlist; no arbitrary role/status fields |
| POST /me/verification; GET /me/verification | Owned processed document; reject duplicate pending submission |
| POST /locations/batch | Per-device sample IDs, server-owned identity, consent epoch |
| POST /me/discovery/pause; /resume | Atomic epoch change and queue invalidation |
| GET /encounters; GET /profiles/:id | Eligibility + privacy + blocks enforced |
| PUT/DELETE /likes/:targetId; GET /likes | Save privately; authorization before write |
| POST /requests; GET /requests | Eligible target, canonical pair uniqueness |
| POST /requests/:id/accept, /decline, /cancel | State/actor checked under pair lock |
| GET /connections; DELETE /connections/:id | Disconnect and access revocation |
| GET /conversations; GET/POST /conversations/:id/messages | Membership and active connection for send; idempotent clientMessageId |
| POST /media/intents, /media/:id/complete; POST /posts; DELETE /posts/:id | Owned asset + processing result required |
| POST/DELETE /blocks/:id; POST /reports | Cross-feature enforcement and evidence scope |
| POST /devices; DELETE /devices/:id; GET /notifications | Ownership; token rotation |
| POST /me/deletion | Recent auth, idempotent 202 job receipt, immediate session revoke |
| POST /public/deletion/challenge, /confirm | Email OTP, generic response, no admin cookies |
| GET /admin/verifications; POST /admin/verifications/:id/decision | Review permission and optimistic version |
| POST /admin/users/:id/deactivate, /reactivate | Reason + audit + active status recheck |
| GET /admin/reports; POST /admin/reports/:id/action | Restricted evidence; auditable resolution |

Socket `/v1/realtime`: authenticate handshake, join only server-assigned account rooms, disconnect on revoke. Events: `encounter.created`, `request.updated`, `connection.updated`, `message.created`, `conversation.removed`, `profile.access_changed`, `account.restricted`. Envelope `{eventId,type,occurredAt,resourceId,version}`; fetch authoritative authorized data on reconnect. No location stream to peers. Initial sends use REST; sockets deliver updates, avoiding two competing persistence paths.

## 8. Authentication and request hardening

Argon2id password hashing tuned on deployment hardware; no reversible password storage. Proposed 12–128 character password, allow paste/password managers. Access tokens 10 minutes, rotating refresh up to 30 days; hash refresh secrets in DB. Secure storage on device; no tokens in URLs or logs. Check account/session state on protected operations so deletion does not wait for JWT expiry.

OTP code stored as keyed digest with challenge/user/purpose, not plaintext or plain fast hash of six digits. Rate-limit by account, device and IP without permanent lockout denial-of-service. Starter caps: five guesses/challenge, five resend requests/hour/account, 20 connection requests/day, 30 messages/minute/connection, 20 uploads/day; load/abuse tests refine these. CNIC not used as an authentication secret.

Google/Apple: verify issuer, audience, signature/JWKS, expiration and nonce; authorization code/PKCE where the selected SDK flow requires it. Key identity on provider+subject, not email. Matching email requires signed-in explicit linking; relay email and first-login-only Apple fields supported. Provider-only users can reauthenticate with provider to delete; revoke Apple tokens during deletion [R10]. Keep credentials needed for revocation encrypted only until attempt completion.

Admin MFA, short idle timeout, least privilege (reviewer/moderator/admin), CSRF token/origin checks, secure cookie, audited sensitive viewing. Database and Valkey ports private; TLS externally and to remote services; secret rotation and least-privilege object credentials.

## 9. Media and CNIC

Upload intent binds owner, type, size and content hash; random opaque object key. Quarantine upload until type sniffing, pixel/dimension limits, decompression-bomb defense and decode/re-encode succeed. Strip EXIF including GPS. User images: max 10 MB source, max 4096 px decoded dimensions after configured validation, optimized max 1600 px display, 320 px thumbnail. Delete temporary originals after processing unless they are CNIC records.

CNIC images: separate private namespace, encryption at rest plus application-envelope encryption recommended, keys outside media storage. Front required/back optional default. Retain submitted image record while account exists, including declined/replaced submissions; no public URL, analytics copy, OCR data or bulk export. Review viewer uses authenticated proxy and `Cache-Control: no-store`, audited accesses and no service-worker cache. Staff download disabled in UI, though screenshots cannot be prevented.

Content safety: for the limited pilot, manually approve all user-visible profile/post images before publication in a dedicated moderation queue. Until approval, show a neutral avatar and keep posts pending; this does not change CNIC verification privileges. Apply server-side prohibited-content rules to bio/captions/chat, with human escalation and appeal; keyword rules alone are not comprehensive protection. Staff review workload is a launch capacity constraint. Add a separately evaluated automated classifier only if needed, without sending CNIC to it.

Profile media: authenticated gateway with permission check and short cache lifetime; ensure changing privacy/block/deletion revokes access, rather than leaving long-lived signed public links. Mobile caches per account; clear on permission change/revalidation/logout. Never store CNIC in persistent mobile caches.

## 10. Account deletion — ordered, resumable, integrity-safe

Targets: immediate hide/revoke; <=24h live-store purge; <=7 days backup expiry. These windows are proposed policy, not proof that every vendor meets them. Disclose them before launch. Immediate deletion of all historical backup bytes is not promised.

1. Authenticate recent action (password/provider/email OTP); deduplicate by request key. In one transaction lock user, set `deleting`, increment consent/session epochs, revoke devices/sessions and block all mutations. Return nonidentifying receipt; clear current device caches/queue and native tracking.
2. Make visibility checks filter deleting accounts everywhere. Stop scheduled pushes/encounter work. A deletion barrier is checked before and after workers process uploads, preventing assets from being recreated.
3. Create encrypted deletion manifest containing every external object/version/thumbnail/quarantine path, provider revocation work, and temporary account identifiers. Store independently of user FKs so root deletion cannot destroy retry instructions. It is personal operational data until purged.
4. Revoke social grants; remove email-provider profile/queued jobs where supported; delete storage objects including historical versions and abort multipart uploads; purge CDN caches. Use retries and provider receipts; external failures keep job incomplete.
5. In bounded DB transactions delete identifying reports/audit references/outbox payloads; delete user root and cascade dependents, including pair conversations. Index FKs to avoid long locks. Preserve only aggregate metrics with no subject link. Reconcile media inventory after deletion to catch races.
6. Notify remaining connected clients using their own conversation IDs that history/access changed; remove local records on next authenticated sync. Maintain a per-recipient revocation generation rather than a permanent deleted-user profile. Previously downloaded screenshots/OS-delivered notifications cannot be remotely erased.
7. Keep minimal encrypted erasure suppression entries until every backup predating deletion expires (max seven days), then destroy them and manifest identifiers. This temporary pseudonymous ledger is disclosed and access-limited, not called anonymous.
8. Restore procedure: network-isolated restore, replay suppression ledger, delete affected objects/rows, validate references and only then reopen traffic. Backups expire within seven days, including object versions and replicas. An old restore must never resurrect an account.
9. Reconciliation worker verifies zero user-owned rows/object manifests/tokens and no user reference in personal audit/report records. Mark receipt complete; discard identifier mapping after backup window. Alert if any live purge exceeds 24h; do not falsely report success.

FK strategy is hard deletion with CASCADE for truly owned/pair-dependent records and explicit purge for external systems; SET NULL only for optional staff relationships where retained content is nonidentifying. No generic “Deleted User” row storing the original identity. Deactivation is reversible and distinct from deletion. Ban evasion prevention will be limited after full erasure; do not secretly retain CNIC hashes.

## 11. Docker Compose and hosting

Services: `api`, `worker`, `postgres` (PostGIS), `valkey`, `proxy`; optional development `mailpit`. Media development adapter uses private named volume; production uses object storage or a deliberately backed-up private volume behind the gateway. All data services have health checks; migrations run once via dedicated command. API/worker share multi-stage nonroot image; no bind-mounted source or dev server in production. Restart policies, graceful shutdown and resource limits configured.

| Host option | Fit | Caveats |
|---|---|---|
| VM with Compose | Recommended deployment baseline | Full topology control; operator owns patching, backups, TLS, monitoring and recovery |
| Render | Good managed alternative | Map containers to separate services/worker/database; not a direct assumption that compose.yaml runs unchanged; persistent data outside ephemeral filesystem |
| Vercel | Good static admin host; backend would need adaptation | Current official June 2026 announcement supports WebSockets in public beta; blanket “no WebSockets” advice is outdated. Still not a Compose host for PostGIS, Valkey and long-lived workers [R14] |

Initial VM planning assumption: 4 vCPU, 8 GB RAM, 80–160 GB SSD plus separate media/backups. A 2 vCPU/4 GB pilot may work at low concurrency, but must be measured. This is a sizing hypothesis, not a vendor quote. Avoid production free tiers that sleep critical workers or lose local files.

Example load: 1,000 DAU × two hours of active collection/day × one delivered fix/min = 120,000 samples/day; 500 simultaneously active at 15-sec intervals = 33 samples/sec before batches. Background DAU may include much longer collection, so a 12-hour/one-minute case is 720,000/day. Bench test 50 samples/sec sustained, 200/sec burst and 300 socket clients. Dense same-area candidate pairing can grow quadratically; benchmark all users in one area, not only evenly scattered fixtures.

Retention, indexes and row size determine storage. At an illustrative 0.5–1 KB per indexed sample, 720k daily samples occupy ~0.36–0.72 GB before WAL/replica/backup overhead. Measure actual `pg_total_relation_size`; no fixed cost promise. Media budget example: 10k × five 0.5 MB photos ≈25 GB plus thumbnails; CNIC and versions add more.

## 12. Operations and verification

Record queue age, ingest/drop reasons, matching latency, samples per active hour, API latency, DB locks, storage failures, deletion SLA and push invalid tokens. Logs redact coordinates, bodies, CNIC, tokens and email. Keep IP/security logs short (proposed seven days) and remove user-linked data during deletion.

Daily encrypted backups, weekly restore rehearsal during pilot, then scheduled restore drills. Define pilot RPO <=24h/RTO <=4h; improve with WAL archiving if business needs it. Off-host backups mandatory. Alert on worker outage; transactional outbox catches up after Valkey loss. Time sync on servers is mandatory.

Test authorization, timestamp boundaries, cross-cell/distance boundaries, duplicate retries, inverse requests, block/delete races, expired grants, private-media access, offline queue reconciliation, backup resurrection, provider-link takeover and battery/performance on physical phones. SQLite mocks do not replace PostGIS integration tests.
