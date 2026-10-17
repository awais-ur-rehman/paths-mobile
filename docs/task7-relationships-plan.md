# Relationships and notifications implementation plan

> For agentic workers: use superpowers:executing-plans inline, TDD per step, one fresh whole-branch review before handoff.

Goal: complete Task7 private saves, explicit connection requests and generic FCM/APNs notification delivery with a concise mobile Likes/inbox flow.
Architecture: canonical user/pair-locked PostgreSQL transitions and a durable outbox; minimal directed saves and request/connection eligibility, provider adapters and encrypted session-bound push tokens; Flutter repositories/Cubits and small native push bridges.
Tech stack: existing Nest/TypeScript/PostGIS/Valkey/BullMQ, Flutter/Cubit/Dio/go_router, cached Android Firebase Messaging25.1.3 and native Apple APNs. No added services or unnecessary SDK wrappers.
Spec: docs/specification/{01_SCOPE,02_PRD,03_TRD,04_APP_FLOW,05_SYSTEM_UI_DESIGN,06_IMPLEMENTATION_PLAN}.md, Task7 and relationship/notification sections.

## Constraints and rulings

- Task6 owner Android functional approval authorizes PR6 merges and Task7. Merge heads backend158919e/admin dabf953/mobile2af063d; main unchanged. Do not invent individual paired-phone/battery/network/iOS outcomes.
- Work from development on feature/relationships-notifications. Three repositories stay separate; existing dedicated checkouts reused. No clone/pull/force push or new services.
- Saves are private/idempotent and directed. Only the saver gains durable eligibility; making it bilateral could reveal another person's private save after history expires. Pending requests and active connections grant bilateral basic-profile eligibility; blocks/status are always rechecked. Pause removes encounter-only discovery, not established saved/request/connection eligibility: location is optional and durable saves end on unsave/block/deletion. No location retained for durable eligibility.
- Requests expire14days. Decline/cancel/expiry/disconnect starts seven-day cooldown using actual transition/expiry time. Reciprocal requests return the incoming pending resource; never auto-accept. Actor/route/body-bound idempotency and pair constraints make retries safe.
- Notifications persist in-app independently of push opt-out/cooldown/OS delivery. Encounter alerts use per-recipient pair6h cooldown and ten alerts/user/UTCday; both recipients of one encounter remain eligible. Delivery is at least once with event collapse/client dedup, never an exactly-once claim.
- Generic pushes contain event/binding IDs only, no names/messages/coordinates/review details. Current blocks/status/preferences/devices are rechecked at send; scoped device tokens are encrypted and revoked on logout/reset/expiry. Historical/stale encounter events cannot generate live alerts.
- Keep new UI short: Saved/Incoming/Sent, one contextual action, small status labels, shared menus/loader/toast. No fake media or unsupported Chat destination before Task9. Save/request is distinct; request has explicit confirmation.
- Android Firebase SDK25.1.3 is already cached. Use a small native adapter; iOS uses system APNs directly, avoiding an unrelated Firebase iOS SDK download. Credential/runtime checks remain blocked until owner adds private push configuration. Never commit real config/keys or create cloud projects/services.

## Steps

### 1. Relationship policy and schema
- [x] Add real PostGIS relationships.spec.ts for ineligible/stranger denial, private saves/durable eligibility/unsave, inverse races, sender-accept denial, duplicate retries,14d expiry/7d cooldown, status/block/deletion and rollback.
- [x] Add migration0007/schema for directed saves, requests with partial unique active pair, connections, actor/route/body-bound idempotency and needed FK/delete indexes.
- [x] Implement repository/policy/service and canonical user-first locks; update authorized peer eligibility, query bounded actor-bound pages and real relationship state on Home.
- [x] Verify focused/full backend checks; coherent commits.

### 2. Notification persistence and dispatch
- [x] Add provider-isolated DB tests for atomic relationship fanout, in-app history/ownership, opt-out, token rotation/revocation/encryption, six-hour/day caps, historical/no-live, block/deletion before send, provider retry/invalid token and rollback.
- [x] Add migration0008/schema for preferences, encrypted device registrations/session binding, generic notifications/intents, per-device receipts and budget/cooldown records; cascade all participant references.
- [x] Implement FCM HTTPv1 service-account OAuth and APNs HTTP2 token-auth adapters with bounded timeouts and safe error classification. No successful unavailable provider responses.
- [x] Wire source-event ingestion, transactional fanout, push job retries, retention/session cleanup and authoritative notification resolution/read. Recheck eligibility at send; log no payloads/tokens.
- [x] Verify tests and local synthetic API/worker smoke; real push recorded separately when credentials/device available.

### 3. Contract and consumers
- [x] Export API1.6.0 including likes, requests/transitions, disconnect, devices/preferences/notifications/resolution/read and typed relationship status; rate-limit mutations/listing.
- [x] Copy real export to mobile/admin, regenerate and verify drift; generator additions only if a real contract shape requires them and covered RED/GREEN.
- [x] Update consumer readiness versions; retain strict schema/error handling; admin has no new workflow until Task11.

### 4. Mobile relationship and inbox flow
- [x] Add repository/Cubit tests for optimistic save rollback, idempotency/cancellation, stale responses/account change, state transitions/offline/unavailable and selective rebuilds.
- [x] Implement Likes Saved/Incoming/Sent lists and profile actions, request confirmation/accept/decline/cancel/disconnect. Add working Likes navigation only; preserve Home/Profile state and no fake future destinations.
- [x] Implement notification center/preferences and authorized tap resolution after auth; mark read only on successful open/explicit action. Missing/deleted resource shows generic unavailable.
- [x] Add lifecycle-owned native push channel: explicit permission request, Android token refresh/data notification and iOS APNs registration/tap, logout clear and bounded event dedup. Credentials never enter source; public Firebase app options come from ignored local config.
- [x] Verify full Flutter/tooling checks,320/390/768 at200% text, inspected goldens and cached Android/unsigned iOS builds. Track missing artifacts precisely without implicit installation.

### 5. Review and handoff
- [x] Run all available backend/admin/mobile checks, real Compose synthetic smoke and contract drift. Fix discovered code-level issues and rerun affected suites.
- [x] One fresh read-only whole-branch review; reproduce Important/Critical findings RED→GREEN; preserve runtime exclusions explicitly.
- [x] Update every applicable Task7 checklist/status, decisions/licenses/API evidence and exact commits/prerequisites. Push changed repos and open draft PRs into development; main unchanged.
- [ ] Give exact Android/iOS push/device test instructions and await owner results before closing Task7 or dependent Task8 gate. Missing access blocks only provider/device evidence, not independent implementation.

Execution status: local implementation and checks completed; provider/device evidence remains pending as recorded in IMPLEMENTATION_STATUS.md. Real push setup is unavailable; all native compilation claims exclude runtime delivery. No Task8 gate bypass.
