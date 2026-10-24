# Paths mobile performance plan

Status: proposal for staged implementation after baseline measurement. Immediate startup/resume/lock-contention fixes in this change are separate from the proposed persistent cache. This plan does not claim measured phone frame-time, memory, cold-start or battery improvements.

## Findings before this change

- Android's native splash hands off to Flutter before session and setup checks finish. Hold the first Flutter frame until a validated destination or actionable error is ready; never add an artificial splash delay.
- Warm `restore()` currently purges tracking and media. Successful same-account revalidation should preserve resources; cold restore, logout, restriction, deletion and access revocation must still invalidate them.
- Profile refresh discards its previous model, unmounting the photo/grid and repeating reads. Retain the current own-profile surface while refreshing; first-load skeleton only, explicit retry/offline state if there is no usable model.
- PrivateImage deliberately bypasses Flutter's global image cache and clears decoded frames on pause/hidden/account/access changes. It currently downloads and decodes again. This is a privacy boundary, not something to disable casually.
- Media endpoints hold exclusive account/pair locks during private R2 reads; parallel photos can serialize behind network latency. Test shared read locks without weakening write/revocation ordering before tuning pool sizes.

## Measure before choosing cache limits

On the owner's Android phone, capture cold launch (process absent), warm resume and Home/Likes/Chats/Profile switching for 100 transitions. Measure native splash duration, time to first usable route, profile/first-photo readiness, p50/p95 HTTP latency by route template, requests/bytes per transition, cancellations, HTTP status counts, peak in-flight requests, frame jank and decoded-image memory. Compare the same account/data/network and release/profile builds. Keep debug timings separate; USB-local API timings do not establish production latency. Never log tokens, CNIC, message bodies, coordinates or real profile values. Correlate failures with request IDs and safe route/status metrics.

## Storage boundaries

| Data | Proposed placement | Freshness and rules |
| --- | --- | --- |
| Access/refresh credentials, encryption keys | Existing OS-backed secure vault | Small secrets only; serialized rotation, account generation and logout cleanup |
| Own profile snapshot (name/bio/avatar ID/preferences) | Versioned encrypted app-private file/database; key in secure vault | Account/schema keyed; short bounded stale window. Do not put large JSON or images directly into keychain/Keystore. Revalidate `/me/session` before authenticated use; cached profile never authorizes adult/restricted/setup/access decisions |
| Own avatar thumbnail | Bounded encrypted app-private cache; key in vault | Opt-in product/security decision before persistence. Account+asset/version keyed. Fresh validated account and matching avatar ID required; purge on logout/deletion/restriction/account change. Do not cache CNIC or arbitrary peer photos in this phase |
| Peer images/profile visibility | Revocable in-memory cache only initially | Reauthorize per server rules. Block/privacy/deletion/socket safety events evict immediately. No global public ImageCache or unbounded disk URL cache |
| Chat bodies / exact locations / CNIC | No new cache under this plan | Existing encrypted native tracking queue retains its documented limits; separate audited design required for any message persistence |
| Public icon/font/style assets | Existing bundled assets | Version with app; map provider tiles remain governed by provider/SDK caching and online availability |

Secure storage protects small keys and credentials. Keeping private images indefinitely in secure storage does not solve decode cost, revocation or stale authorization. An encrypted cache still needs strict expiration, size budgets, account isolation and cleanup after failed writes/key loss.

## Staged work and gates

1. **Request ownership:** coalesce duplicate immutable GETs at the account-scoped repository layer. A disposed widget cancels its subscription, not a shared read needed elsewhere. Bound media concurrency (initial candidate 4), remove queued requests when offscreen, prioritize own visible avatar and avoid recursive immediate retries. Keep idempotency for writes and one shared refresh operation. Test 20 rapid switches with delayed/out-of-order responses and account changes.
2. **Own-profile memory snapshot:** keep a bounded model per authenticated account, render instantly on tab return, background revalidate at a measured TTL (candidate 30 seconds), force-refresh on pull/edit/avatar/verification changes. Do not reuse a snapshot from another account or after a terminal access failure. Retain stale content only for explicitly allowed offline cases.
3. **Versioned freshness:** add an API version/ETag or updated revision for own profile/media metadata. Conditional reads should preserve `no-store` privacy semantics for personalized shared proxies. Apply server-confirmed edits locally; keep previous state and show failures on rejected edits. Avoid last-write-wins overwriting newer data; use conflict revisions where needed. Contract/migration changes require a separate tested task.
4. **Encrypted persistent own cache:** only after the account/lifecycle tests pass and measurements justify it. Write atomically; include account/schema/revision/fetchedAt; validate sizes/integrity before decoding. Expire after a bounded interval (candidate 24 hours for own metadata, shorter on sensitive state); initial candidate 20 MiB/12 thumbnail entries with LRU. These are proposed defaults, not approved product guarantees. Store no plaintext JSON/pixels in preferences; disable backups as configured. Delete cache and key/tombstone safely on logout/deletion/key corruption.
5. **Image rendering:** decode thumbnails at actual device-pixel target sizes, not one fixed large width everywhere. Bound decode work and decoded pixels; retain one safely owned in-memory own-avatar frame while the account is validated and visible. Keep aspect-ratio skeletons for uncached initial loads; retain loaded photos during refresh. Respect reduced motion; avoid indefinite spinners/shimmers or falsely showing successful content.
6. **Release comparison:** repeat the exact baseline, including offline/server outage/expired token/restriction/block/deletion/low-memory/permission changes. Candidate acceptance: no crash or unexpected 5xx across 100 switches, no stale cross-account/private media after invalidation, lower request count and p95 readiness than baseline, no material frame/memory regression. Numeric latency/battery targets must follow measured device/server baselines, not guesses.

## Open decisions

No framework/database/cache dependency is selected or downloaded. Evaluate installed capabilities first. Persistent own-avatar caching changes current retention policy and requires explicit agreement on offline access, retention and invalidation; peer/message/CNIC caching remains outside this first cache phase. iOS keychain/data protection/runtime behavior must be validated separately; Android acceptance cannot close it.
