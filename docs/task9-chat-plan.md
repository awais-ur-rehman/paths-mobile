# Task 9 text chat implementation

Requirements: specification/06_IMPLEMENTATION_PLAN.md Task 9, TRD sections6–8, CHAT-01/02/03 and app flow Chats. API 1.8.0. No typing indicators, public read receipts, group or image chat. White surfaces and concise labels use the existing theme, loader/toast and avatar widgets.

Implementation decisions: REST is the sole durable send path; socket events contain identifiers/versions only. Socket.IO uses existing PostgreSQL outbox/BullMQ worker, with transactional PG notifications to API listeners (each API instance subscribes; no new service/adapter). Server-assigned account rooms and per-socket authorization rechecks close revoke races. Full authorized conversation snapshot plus bounded cursor history repairs missed/duplicate/out-of-order events. Unread watermarks are private, not public read receipts. Chat caches/drafts stay account-scoped in memory and clear on auth change, removal and logout; no plaintext message persistence on device. Foreground sockets close on background; resume refreshes credentials and syncs history.

- [x] Migration, DTOs and generated contract: conversations per connection, ordered messages unique sender/client ID, private read watermark, durable metadata events and revocation triggers; cascading user deletion erases entire pair history.
- [x] REST tests first: pre-accept/spoof/foreign/oversized/empty/prohibited sends, replay/conflict, bounded pagination/catch-up, unread; pair locks for send versus disconnect/block/delete; rate30/min/connection.
- [x] Socket handshake/account rooms, expiry/revocation, outbox fanout and delivery-time authorization; metadata-only events after commit, listener reconnect cleanup and lost-event REST recovery.
- [x] Flutter chat repository/realtime transport, chats list and thread Bloc, lazy history, pending/failed same-ID retry, unread watermark and read-only disconnected history. Clear deleted/blocked conversations on sync and account switch; lifecycle/cancellation/disposal tests.
- [x] Integrate Chats tab and profile connection actions; preserve camera return and setup/deep-link guards. Generic message push uses the existing notification worker where applicable; no names or bodies in lock-screen data.
- [x] Backend/frontend tests, real database/socket checks, contract/type/lint, Android/iOS builds with available dependencies; review full diff, fix findings and repeat relevant checks.
- [ ] Update every repository status with files/commits/actual results, push draft PRs, prepare two-device airplane-mode/reconnect/revoke tests. Await owner results before merge or Task 10.

Owner approved required Task 9 dependencies, caches first. Do not modify existing credentials, seed real messages or operate the owner's phone. Keep main unchanged. The accepted R2 recovery-copy retirement and physical FCM/APNs validation remain independent release prerequisites.

Implementation and automated checks are verified within the scope recorded in IMPLEMENTATION_STATUS.md. Draft PR publication is tracked there; the final checkbox remains pending for owner two-device acceptance. No Task 10 or main promotion.
