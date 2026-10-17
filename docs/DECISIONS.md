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
