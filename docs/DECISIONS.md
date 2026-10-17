# Decisions

- 2026-10-17: Documentation v1.0 is the baseline; proposed defaults remain proposals until measured. Phase 0 blocks Phase 1.
- Work in the three new feature-branch checkouts requested by the owner; no extra worktrees needed for empty repositories. No scaffolding or dependency bootstrap on main.
- No public pilot, real CNIC collection, deployment or store submission. No location-bearing logs or committed device traces.
- GitHub owner verified as awais-ur-rehman; repositories must remain private.
- Flutter application identifier: com.paths.mobile (Android and iOS); Android 10 / iOS 16 are experiment floors, not compatibility claims.
- Phase 0 contracts are experimental `phase0.v1`; production `/v1` OpenAPI is not yet published.

- 2026-10-17: Execute existing implementation plan inline. Separate read-only reviewer used per local review skill; no parallel implementation.
- Phase0 uses a memory-only Node experiment under tools/, not a replacement for the documented NestJS API/PostGIS/worker. Production framework setup remains behind Phase0 gate.
- No package/SDK/tool/container downloads. Pub lock generated solely from local cache via offline resolution; missing native artifacts are blockers. Font files/licenses downloaded only under explicit visual-asset exception.
- Trial transport is loopback HTTP over owner-operated Android USB reverse; iOS requires trusted private-LAN TLS. No TLS bypass and no public trial listener.
- Preliminary foreground/background balanced collection is a candidate, not measured final adaptive policy. No claims for battery, venue certainty or push delivery.
- Keep native TTL execution limitations and missing MapLibre/iOS runtime validation visible. Do not waive the phase/device gate.

- Owner follow-up: “I have tested it and it is feasable”; explicitly authorized merging Phase0 PRs into development and continuing the plan. This is owner-reported feasibility acceptance, not a measured battery/precision report or iOS validation. Adaptive baseline retained; brief-crossing stays off. Main remains unchanged.
- Owner selected Gmail SMTP for email and a Cloudflare bucket (R2/S3-compatible adapter) for production media. Credentials will be environment-only; no service provisioning or real-data upload authorized. Development uses Mailpit/private filesystem until their integrations.
- Owner authorized downloading missing Android test artifacts, then separately authorized Phase1 packages and Docker images. No SDK/tool upgrades or store/deployment actions inferred.

## Phase1 foundation defaults

- API contract1.0.0 is exported from Nest decorators; consumer DTO generation is reproducible. The Dart generator supports current required scalar models and rejects unsupported schemas; extend it deliberately for auth/profile contracts.
- Local email uses Mailpit. Gmail SMTP is selected for real delivery at Task3, with mandatory TLS and server-side credentials. Cloudflare R2 is selected for protected media at Task8; no public bucket or client-held keys.
- Development database/cache remain private in base Compose; host tests opt into loopback mappings. PostGIS currently uses amd64 emulation on this Mac. No production capacity claim.
- Integration tests own a unique temporary database and require CREATEDB; only that created database is removed after tests, preserving development fixtures/volumes.
- Worker retries retained failed jobs from durable unprocessed outbox rows after30-second cooldown. Unknown kinds remain failures. Shutdown drains DB transactions and leaves unacknowledged jobs for idempotent replay.
- Existing physical feasibility acceptance permits Phase1 work. Detailed Phase0 battery/accuracy and iOS evidence remain release gates. No new device test is needed for Task2's network/bootstrap-only Flutter addition; Task3 requires device authentication testing.

## Task3 session transport boundary

The refresh component owns volatile coordination only. Auth-repository integration must persist rotations in platform secure storage and apply terminal refresh revocation; it is not connected to the current harness. Authenticated transport pins its origin, disables redirects and rejects generation-mismatched responses as well as retries. Refresh failures never expose the separate refresh request. Streaming requests require explicit retry; multipart bodies use a cloned body. This boundary does not replace backend authorization or logout revocation.

## Task3 authentication decisions

- API contract1.1.0 uses opaque, hashed bearer sessions with immediate database revocation; the documentation requires bearer authorization, not JWT encoding. Access lifetime10min; refresh family absolute lifetime30days with one-use rotation/reuse revocation.
- Signup credentials are challenge-bound until email verification. Codes last5min, allow5 guesses, and resend after60sec. Pending password hashes remain only within the 24-hour expired-challenge retention window to permit resend; successful verification clears them immediately.
- DOB is private, checked using a UTC calendar18-year boundary at guarded setup entry, and excluded from account responses. Remaining profile fields are Task4.
- Public one-use authentication mutations are not automatically replayed. Protected retries require an idempotent verb or explicit idempotency key. Temporary refresh outages preserve credentials behind explicit retry; definitive revocation clears them.
- Restricted accounts can view their own status, sign out, and contact support about deletion. Automated account erasure remains Task12; support mail handoff does not claim a completed deletion.
- Owner supplied temporary Gmail/support address; configure SUPPORT_EMAIL/SMTP_USER/SMTP_FROM server-side only. TERMS_URL and PRIVACY_URL are editable HTTPS environment values. Blank values display development testing notices pending published policies; they are not final legal documents.
- Actual Gmail delivery requires an app password supplied privately. Mailpit verifies local SMTP/outbox behavior. R2 integration remains Task8; no storage credentials belong in clients.

## Owner device feedback overrides (2026-10-17)

- New user instructions override earlier onboarding footer/signup defaults: one full-bleed photo-led page, centered copy and single Get started CTA, white lower/auth backgrounds, animated arrow before login. Policies/credits stay on reachable auth policy routes.
- Native Android12 splash uses a separately scaled vector inside its circular safe area; launcher foreground art is retained. Older Android/iOS and Flutter splash sizes are bounded explicitly. Physical masking remains an owner retest.
- Branded loader is drawn from original Paths Bezier vectors with a disposed Flutter ticker and reduced-motion still state; editable SVG source retained. Toasts enter at top right, replace prior notices, allow swipe-right/manual dismissal and remain persistent for accessible navigation.
- User explicitly requested an actual profile form after age confirmation. Add only the needed private details slice now, preserving pending Task3 retest and not completing all Task4/Task8 work. Routine username default:3–24 lowercase ASCII letters/digits/underscore; server canonicalizes trim/case and the database arbitrates unique claims. Bio limit300 and gender choices follow confirmed scope.
- Saving profile details is idempotent and does not grant profile completion, image moderation or verification entitlements. DOB remains separate/private. No extra package, tool, SDK, emulator or phone operation is required.


## Task4 profile and optional review

Owner accepted Task3 Android UI and authorized PR3 merges into development on2026-10-17. Main remains a verified-release gate. Existing dedicated checkouts are reused on feature/profile-verification without dependency installations.

Private is the default; visibility is editable. Older clients omitting visibility preserve the existing setting. Basic summaries use an explicit field allowlist and UTC calendar age (Feb29 birthdays on Mar1 in non-leap years), never DOB/email/document fields. Until Task6 provides encounter/relationship eligibility, only an owner can read their summary; strangers receive the same404 for existing and missing IDs. Public visibility does not grant stranger discovery.

The optional offer-seen marker is separate from review status. Skip is idempotent and never changes pending/approved/declined status or profile entitlements. User-first transaction locks serialize submissions and account-status/session changes. Pending duplicates conflict; decline resubmissions retain earlier records; deletion cascades offer/review records. Production media adapter refuses every asset until Task8's private storage/processing/ownership FK exists. Test-only fixture media covers owned front/back, processing and review states without collecting images. Reviewer decisions remain Task11. Cloudflare R2 is the intended private object store; no bucket or SDK is configured early.

Task4 does not invent completed setup or Home: required photo upload remains unavailable, profileComplete=false. The saved private preview exposes edit/review actions and neutral avatar; upload and post publishing remain Task8. Shared design components are added where reused, with original white/black/blue style and existing fonts/Material line icons. No assets downloaded.


## Task5 location controls and ingestion

Task4 owner Android approval authorized PR4 merges into development; main remains unchanged. Task5 uses feature/location-ingestion and API1.4.0. Existing native encrypted capture queues are retained; no new package/service was introduced.

A full adult session explicitly grants a24h location-only upload capability bound to its account session, selected device and consent epoch. Only its digest is stored server-side; native keeps the capability in memory, never account access/refresh credentials. Process death requires a fresh explicit enable. Grant request IDs are idempotent; expected epochs reject delayed resume after pause. A new device lease replaces the prior lease. Scoped native stop and persisted non-secret account/epoch stop metadata cannot pause a newer device/account. Explicit Enable intentionally selects this phone.

Batch ingestion accepts up to50 observations, validates finite/time/coordinate/accuracy/speed bounds and deduplicates IDs/sequence under the account lock. Samples and matching intents commit atomically. Observations older120sec or affected by establishment clock offset over30sec are historical-only. Proposed defensive bounds: accuracy<=10000m, speed<=100m/s; these are routine validation defaults, not measured encounter guarantees. Coordinates remain only in private PostGIS samples, not logs/outbox payloads/responses. Worker removes observations and orphan matching intents in bounded24h retention batches. Matcher dispatch is deferred to Task6.

Foreground permission is requested first; background is a separate choice with best-effort OS delivery. Native handles receipts, bounded retries/reachability and redirect refusal without Dart timers or mounted pages. The200-item/15min encrypted queue is purged locally before remote pause/logout; pending remote control is durable and scoped. Android HTTP is allowed only for debug loopback; real endpoints require HTTPS. iOS ATS remains intact and device testing requires HTTPS. No force-stop resurrection or iOS runtime result is claimed.


## Owner feedback and Task6 start

Owner reports Task5 functionality working smoothly and authorizes continuing according to the plan; UI is too text-heavy. Record this as functional acceptance of the slice, not fabricated case-by-case background/iOS/quantitative evidence. Task5 PR5 is merged into development; main unchanged. New screens use concise copy, one primary action and contextual secondary controls. Full screen-by-screen redesign is deferred at the owner's request. Installed frontend-design guides composition; existing Paths branding/fonts take precedence over generic skill defaults. No new skill/plugin installation is needed.


Task6 map setup: existing MapLibre GL0.27.1 packages and transitive dependencies resolved with pub get --offline, with source licenses retained. Android requires the already installed Homebrew JDK21 (the system Java registry lists17 only). No JDK was downloaded. Map style remains configurable via PATHS_MAP_STYLE_URL; config/development.example.json supplies the official OpenFreeMap Liberty style for owner testing, without an account/key or a paid resource. Blank/unreachable style retains the authorized list. See ASSETS.md for provider source/attribution and runtime data boundaries. Owner subsequently approved the required iOS dependency download. MapLibre Native6.28.0 is now pinned by Xcode and the unsigned build passes; signed runtime remains separate.


## Task6 encounter contract and gates

Conservative standard matching follows documented50m/60s/25m/70m and two independent advancing20–120s observation pairs; proposed defensive travel bound100m/s also rejects implausible paired movement. Live evidence age120s, admission15min, evidence10min, session gap30min and history30days. Approximately500m fixed display areas are serialization only; exact PostGIS candidates cross those boundaries. Actor/filter-bound opaque cursors contain no timestamps. Recent uses historical areas; Nearby24h uses a fresh own server coarse center with0.5/1/3/5km presets. Peer summaries require current eligibility and expose approved verification only.

Notification intents are durable per-session records retained with active sessions; Task7 owns delivery/cooldowns. Full photos/profile completion remain Task8. Home shows only working Home/Profile destinations. Mobile reuses original branding, neutral avatars and concise states; full existing-screen redesign is deferred per owner. Auth private errors/logging and exact coordinates remain protected. API1.5.0 is copied/generated in all three repos. Main is not promoted.


Task6 iOS follow-up: owner approved the required MapLibre Native6.28.0 package/binary download. Keep the Xcode-generated exact revision pin and BSD license; future builds use resolved-file-only mode. Unsigned compilation is verified; no device runtime result or Task6 completion is inferred.
