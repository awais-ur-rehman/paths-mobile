# Protected media and camera publishing implementation plan

> Use superpowers:executing-plans inline, test-driven development per behavioral slice, and one fresh read-only whole-branch review before handoff. Owner already authorizes Task8 against the existing specification; routine decisions are recorded here rather than adding an approval loop.

Goal: private, validated image uploads for profile/CNIC/posts; concise camera/gallery publishing; permission-checked media and deletion-safe processing.
Architecture: Nest API accepts bounded authenticated binary uploads into encrypted quarantine; the existing outbox/worker decodes and re-encodes images, produces derivatives and keeps visible media pending human safety review. Local private filesystem and Cloudflare R2 implement the same storage port. Flutter image_picker adapters and focused repositories/Cubits use the guarded Dio transport. Admin consumes the contract; staff moderation UI remains Task11.
Tech stack: existing PostgreSQL/PostGIS, Valkey/BullMQ, Nest/TypeScript, Flutter/Cubit/Dio/go_router; Sharp0.35.5, AWS S3 client3.1149.0, cached compatible image_picker/crypto packages pinned by real resolution. Owner approved required Task8 dependency artifacts, including Linux image binaries; caches first. No new services or Docker base images.
Spec: docs/specification/{01_SCOPE,02_PRD,03_TRD,04_APP_FLOW,05_SYSTEM_UI_DESIGN,06_IMPLEMENTATION_PLAN}.md, Task8 and media/deletion sections.

## Constraints and decisions

- Task7 PR7 merged after owner phone approval and fresh local74 integration/187 Flutter/19unit13Phase0/admin2+3 and green hosted backend/admin checks. Owner explicitly defers Firebase/APNs/live delivery and allows Task8; those release prerequisites remain tracked. Main unchanged. Bases backend4e6278f/admin afb2125/mobile8e85b0a. Reuse the three dedicated checkouts on feature/protected-media.
- Max10MB source, allowed JPEG/PNG/WebP raster, max4096px per decoded dimension and16,777,216 pixels; reject animation, SVG and malformed/truncated input. Re-encode auto-oriented JPEG, max1600px display/320px thumb, metadata stripped. Sharp has bounded concurrency/input pixels/processing timeout. No remote image fetching from user URLs.
- Authenticated API proxy upload is the same flow for filesystem and R2: server binds owner/kind/size/SHA256 and random object key, with no storage credential/public URL on mobile. Small image limit makes multipart client uploads unnecessary. Inventory and cleanup still list/abort incomplete provider multipart uploads under the application prefix. R2 has no S3 versioning API support; report that capability honestly rather than issue unsupported calls or claim version purge. Bucket must stay private.
- All stored object bytes use authenticated application encryption; dedicated MEDIA_KEY outside storage for R2, development key derivation allowed only locally. Submitted CNIC source plus sanitized record is retained through declined/replaced submissions until account erasure; never public or in routine member media reads. Task11 supplies separately permissioned audited staff viewer, no fake reviewer/public bypass now.
- User-visible profile/post media remains pending safety review, neutral avatar until approved. Own pending posts can be inspected privately; unreviewed/rejected media never reaches peer/public responses. Task11 owns actual staff approval workflow. CNIC review and image safety status are distinct. Bio/caption filtering is server-side, with safe errors and documented limited rules; human escalation is Task10/11.
- Every gateway read rechecks active accounts, eligibility, privacy/connection and blocks; no long-lived public grants. Client media bytes are memory-only, scoped to account/access generation and cleared on privacy revalidation/logout. CNIC bytes never enter persistent image cache. Native picker output is temporary; remove on cancel/success/logout and recover/cancel Android lost-data results safely.
- Object inventory is committed before external writes, survives root deletion as temporary purge work, and includes quarantine/source/display/thumb. Worker checks the deletion barrier before processing and before writing/finalizing. Root/asset locks serialize bounded external writes against deletion; decoding happens outside locks. Cleanup cannot delete a manifest while an in-flight upload may recreate its object. Never mark a failed external deletion successful.
- Proposed defensive defaults: upload intents15min, abandoned/unattached image cleanup24h, server uploads20/account/day and bounded body/read deadline; source uploads idempotent under row locks; explicit intent/publish idempotency actor/route/body-bound. Submitted documents are excluded from orphan TTL.
- UI follows owner preference: white forms, short headings, one primary action per step, shared loader/toast, original Paths assets. Camera is a shell action/modal and returns to origin on cancellation; publish returns own profile with pending status. No Chats destination before Task9, no fake posts/photos or invented social metrics.

## File responsibilities

Backend modules/media: DTO/controller HTTP boundary; media.service orchestration; media.repository authorization/SQL; storage.port + filesystem/R2 adapters; object-crypto; image-processor; media.worker/retention; modules/posts typed publishing/list/delete; modules/safety/text-policy reusable text filter. Migrations0010/schema establish owned assets, object inventory, processing jobs, idempotency, profile photo link and verification ownership FKs. Existing profile/encounter/relationship DTOs gain only additive permitted media references.
Mobile features/media: domain interfaces, picker/data upload + authenticated memory image loader, UploadCubit; camera: fullscreen source/preview/caption; posts: grid/detail/Cubit; profile/verification connect through media contracts. Existing auth transport gains bounded upload/download with refresh/replay and account-generation guards, not a second network stack. Admin only regenerates1.7 contract/readiness fixtures.

## Execution checklist

### 1. Storage and image sanitization
- [x] RED storage ownership/key confinement, authenticated encryption/tamper, byte bounds and real Sharp metadata/dimension/malformed/animation tests.
- [x] Implement filesystem and R2 storage ports with bounded requests, no redirects/public links, object listing and multipart cleanup; safe typed errors.
- [x] Implement constrained decode/re-encode and derivative output; inspect generated synthetic image metadata. GREEN focused/full unit checks; micro commits.

### 2. Upload/schema/worker lifecycle
- [x] RED real PostgreSQL/HTTP tests: wrong owner/kind/hash/size, unavailable account, upload retry, pending processing, intent/idempotency rollback, worker replay, expiry, status/deletion during processing.
- [x] Add media assets/object inventory/jobs/idempotency/profile reference tables/constraints/indexes and verification owned references. Existing test-only verification fixtures seed real owned assets for FK integrity.
- [x] Implement intent -> bounded authenticated upload -> completion/outbox -> processing and variants; no production fake success. Implement verification media port with actual processed owned CNIC kind checks.
- [x] Add object/orphan/multipart cleanup and owner inventory export for Task12. Deletion/status barrier checks before and after expensive work; submitted CNIC never ages out. GREEN focused/full integration checks.

### 3. Posts, visibility and safety
- [x] RED text filtering, processed asset/kind/owner, pending/approved/rejected publication, private/public/connected/blocked reads, avatar masking, privacy/disconnect/deletion races and delete retry tests.
- [x] Implement draft/pending posts, own/authorized profile grid/detail/delete, profile photo attachment and permission-checked binary media gateway; no direct URLs or CNIC member reads.
- [x] Implement image review state/queue and reusable server text policy on bio/caption (chat consumes Task9). No externally reachable moderation action until real staff authorization in Task11.
- [x] GREEN tests and synthetic real Compose API/worker smoke. Export real API1.7; regenerate both consumers and check drift.

### 4. Mobile upload and profile flows
- [x] RED picker/upload Cubit tests: loading/progress, retry preserving intent, cancellation/cleanup, process loss, account change, unavailable permissions, stale response, pending vs published.
- [x] Implement scoped native picker adapter, uploader and memory-only authenticated media; single-flight refresh works for stream upload/download and does not leak raw Dio exceptions/tokens.
- [x] Resume setup from server profile/offer state and account-scoped device education; retain protected destinations through restoration/sign-in, reject stale-account responses, and test persistence failure/retry.
- [x] Integrate profile photo and real optional CNIC front/back upload with consent/retention and submit/skip; keep profile creation one Next button.
- [x] Add camera/gallery/retake/preview/caption/cancel/confirmation, pending-post owner grid/detail/delete and permitted peer grids/private lock. Camera modal returns to originating tab; post creation navigates via listener.
- [x] GREEN all Flutter tests/static checks, responsive320/390/768 at200% and inspected renders; offline Android + unsigned iOS builds using available/resolved dependencies. Retain licenses/asset ledger.

### 5. Review and handoff
- [x] Verify all local backend/admin/mobile suites, contract drift, real Compose synthetic smoke and deletion/object inventory. Inspect complete branch against all six Task8 specification checkboxes.
- [x] One fresh read-only whole-branch review, fix Important/Critical issues with reproducing tests and rerun relevant checks.
- [x] Record every Task8 status/result/prerequisite/decision/API version in each repo; factual micro commits; push all changed repositories and draft PRs into development. Main unchanged.
- [ ] Provide exact physical Android permission/gallery/camera/upload-failure/cancel/logout test steps and source commits. Signed iOS and real private R2 access remain separate evidence; no real personal upload/service creation/deployment. Await owner results before dependent gate.

Implementation/local checks are verified as recorded in IMPLEMENTATION_STATUS.md. Owner Android results, real R2 and iOS runtime remain pending; the phase is not complete. No Task9 work has started.

Owner initially accepted Task8 on2026-10-17; backend/admin PR8 merged. A subsequent Android photo-cleanup failure reopens the mobile device gate. Fix3535e4c is implemented and tested locally; await the focused phone retest before mobile PR8 merge. No Task9 work or other subsequent tasks begin.

Additional device follow-up: fix8cfb4e3 preserves photo selections/drafts through session refresh.218 Flutter tests and analysis pass. Native builds/integrity and owner photo/Next results are recorded in IMPLEMENTATION_STATUS.md; mobile PR8 remains pending. No later tasks begin.
