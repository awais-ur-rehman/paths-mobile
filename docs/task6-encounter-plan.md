# Encounter discovery implementation plan

> For agentic workers: use superpowers:executing-plans inline; one fresh whole-branch review before handoff.

Goal: implement Task6 conservative encounter matching and a concise, privacy-safe Home.
Architecture: PostGIS candidate search, canonical user/pair locks, deduplicated evidence and durable notification intents. REST exposes only authorized coarse historical areas. Flutter BLoC owns list/filter state; MapLibre owns a small lifecycle wrapper and falls back to the same list.
Tech stack: existing Nest/TypeScript/PostGIS/BullMQ, Flutter/BLoC/Dio/go_router, cached MapLibre GL0.27.1.
Spec: documents/Paths_Documentation/{01_SCOPE,02_PRD,03_TRD,04_APP_FLOW,05_SYSTEM_UI_DESIGN,06_IMPLEMENTATION_PLAN}.md, Task6/TRD4–5 and owner UI feedback2026-10-17.

## Global constraints and rulings

- Work on feature/encounter-discovery from accepted development; main unchanged. Task5 functional acceptance does not invent individual permission/background or iOS/battery results.
- Owner wants functionality first and will request a screen-by-screen redesign later. New UI: short headings, brief state messages, one primary action, secondary details on demand; preserve Paths white/black/blue branding and bundled type/icons. The existing long permission page is deferred to that redesign.
- Standard rule only: point distance<=50m, delta<=60s, each accuracy<=25m and precise, distance+accuracies<=70m. Two distinct independent pairs advance both capture times20–120s. No brief-crossing feature, venue inference, stationary dwell or invented trajectory.
- Candidate evidence expires10min; sample admission historical window15min; live age<=120s and trusted clocks. Session inactivity gap30min; encounter history30d. Query spatial neighbors without grid restriction.
- Coarse display uses fixed approximately500m areas; no exact peer coordinates/distances/timestamps or arbitrary map-center queries. Radius0.5/1/3/5km filters eligibility, never creates it. Recent remains available without location. Date-only expiry metadata avoids exposing exact encounter times.
- Paused/restricted/deleting/blocked subjects are excluded on worker and every read. Private summary eligibility requires an encounter; visibility never bypasses eligibility. Real avatar/media, save/request, push delivery and remaining navigation destinations are Tasks7–11, with no fake handlers or completed profile flags.
- Only existing packages/caches/tools may be used. Add MapLibre with offline resolution only; record precise native prerequisites if absent. Map style is editable via PATHS_MAP_STYLE_URL; blank/unreachable style shows the real list fallback, no unapproved tile service or fake basemap. Signed iOS and physical encounter evidence remain owner gates.

## Steps

### 1. Conservative policy and database
- [x] RED unit tests for exact50m/60s/25m/70m, distinct IDs/increasing20–120s, coarse/inaccurate/time drift/historical and fast/stationary gaps.
- [x] Implement encounter-policy.ts and coarse-area.ts with deterministic dateline-safe midpoint/area and no coordinates in public policy decisions.
- [x] Add migration0006_encounters.sql/schema: blocks, expiring pair evidence,30d encounter sessions and unique per-session/recipient notification intents; user FKs/canonical pair checks and deletion indexes.
- [x] GREEN unit and real migration tests; coherent commit.

### 2. Matcher and worker
- [x] RED PostGIS encounter.spec.ts: inverse concurrent jobs/retry produce one session and two intents; cross-grid neighbors, adjacent venues fail conservative evidence, delayed batches never live-notify; pause/consent/block/deletion and retention.
- [x] processLocationEvent(db,eventId): page spatial/time candidates; each pair transaction locks users in UUID order, then canonical pair advisory lock, rechecks account/lease/blocks and inserts unique evidence. Two corroborating observations create/update one session and two notification intents atomically. Historical matches create no live notification intent.
- [x] Route location.match outside the mail worker's single-owner lock path to avoid lock inversion; dispatch match jobs, retain encounter.notify until Task7 delivery. Worker retries partial progress safely and purges expired evidence/history/intents.
- [x] GREEN full backend suite and real worker smoke with synthetic data; coherent commit.

### 3. Authorized discovery contract
- [x] RED listing/profile tests: no stranger enumeration, Recent30d/Nearby24h, server coarse center, bounded radius/page, actor/filter-bound opaque cursor, no peer exact location/time/distance, status/block/pause invalidation.
- [x] GET /encounters via adult guard returns immutable EncounterCard/page fields with coarse area centers/labels, time bucket/date-only expiry, neutral photo state and requestState=none until Task7. GET /profiles/:id permits eligible basic summaries only; private media remains unavailable.
- [x] Export API1.5.0, copy/regenerate both consumers, check actual export and regeneration drift; coherent commits per repository.

### 4. Mobile Home and map/list
- [x] RED repository/BLoC tests: cancellation, filter changes, pagination dedup, stale replies, offline/error/empty, account change and cleanup.
- [x] Build typed discovery repository and EncounterBloc. Add Home and eligible peer route; retain incomplete photo setup without fabricating profileComplete. Existing Profile/permissions remain reachable; only implemented destinations are shown.
- [x] RED widget tests at320/390/768,200% text: short Home header, Recent/Nearby and conditional radius, permission action only when needed, real cards, empty/error/retry; map failure retains list. Test selection/peer entry and resource disposal.
- [ ] Add lifecycle-owned MapLibre coarse markers/area selection with configurable HTTPS style, attribution and no own precise-location layer; reuse neutral avatars/badge/loader/toast. No gallery/fake users/unsupported buttons. Inspect goldens and native offline builds; record genuine blockers.

### 5. Review and handoff
- [x] Run all available suites, lint/types/analyzer, contract drift, cached native builds and real-stack synthetic smoke. Inspect complete diff and goldens.
- [x] One fresh read-only branch review; fix Important/Critical findings with RED→GREEN and rerun relevant suites.
- [x] Update every Task6 checkbox with evidence, decisions, actual commits, API version and prerequisites. Push all changed repositories and open draft PRs into development.
- [ ] Give owner physical paired-phone/permission/offline/map tests, exact branches/commits/commands, expected outcomes and sanitized failure observations. Do not mark Task6 complete before required evidence.

## Review focus

Ordered locks across multi-peer matching and deletion; retries after partial pair commits; cursor/privacy enumeration and date leakage; antimeridian/latitude quantization and accurate spatial neighbors; Flutter cancellation/account changes and MapLibre controller/style failures. Each is included in tests or explicitly reserved for physical/runtime evidence.

Execution status: source steps locally verified. Native map rendering/physical network and paired-phone evidence remain pending; iOS native compile is blocked by missing MapLibre6.28.0 resolution. Handoff prepared in TASK6_DEVICE_TESTS.md; owner execution remains open. All checked steps refer to implementation/local evidence, not physical phase completion. See IMPLEMENTATION_STATUS.md for actual check counts, source commits and PR gates.
