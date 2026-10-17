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
