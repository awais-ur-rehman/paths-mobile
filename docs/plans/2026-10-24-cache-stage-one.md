# Request ownership and own-profile memory cache

Spec: docs/PERFORMANCE_PLAN.md, approved by owner after successful Android startup retest. Existing clean feature/logo-refresh checkout, base5abd2b3; continue existing draftPR16. No installations, no iOS build, no device operation, no main promotion.

## Global constraints

Only account-scoped in-flight reads are shared. Each image consumer owns its returned byte buffer; raw shared bytes are wiped after delivery. Cancellation detaches only that caller; the transport cancels when no subscribers remain. Active transport cap4, own-avatar reads prioritized, no auto retry. Clear queued/active work on privacy purge, disposal or account change. Do not persist peer/CNIC/chat/location content.

Own-profile metadata cache holds one immutable summary for at most30seconds of freshness in a validated session. Explicit refresh bypasses TTL; edits/verification/access/reconnect invalidate previous reads and snapshot. A cached model never authorizes setup or restriction. Do not cache peers. No persistent bytes or model caching until the staged phone measurement/lifecycle gate supports proceeding. The disk cache/API revision stages remain tracked in the parent plan.

## Task 1: Shared read ownership and media scheduling

- Read HttpMediaRepository/PrivateImage cancellation and buffer lifecycle.
- Write failures for same-key coalescing, independent returned buffers, subscriber cancellation, queued cancellation, active cap, own-avatar priority, purge/account changes, late results and failures;20rapid switch cycles.
- Implement reusable typed queue with bounded concurrency and aggregate-only diagnostics, then wire media reads. No secrets/URLs/accounts in diagnostics.
- Expected: tests RED against old unbounded reads, then GREEN; full Flutter suite passes. Commit focused code/tests.

## Task 2: Own-profile memory freshness

- Test one validated own snapshot reused across routes, TTL boundary, forced refresh, edit racing old reads, logout/restriction/account replacement/close, peer always fresh and offline/access failure behavior.
- Implement one summary cache and in-flight sharing at the owning repository; typed optional own-cache interface for profile screen, no peer cache or setup shortcut.
- Initialize preview from valid snapshot, refresh stale snapshots and force explicit pull/settings/resume refresh. Invalidate on successful writes and safety/reconnect events.
- Expected: tests RED for redundant HTTP/stale edit responses, then GREEN; full suite and analyzer pass. Commit focused code/tests.

## Task 3: Review, compare and handoff

- Compare deterministic20-switch request counts/peak transport from the real repository with delayed local transport; record actual output without phone timing claims.
- Run analyzer, full Flutter suite,14Android/tool checks, offline ARM64 build/kernel integrity. Inspect full diff and one fresh read-only code review, repair important findings RED/GREEN.
- Update parent plan/status and device commands; push changed mobile branch and update draftPR16. Backend/admin unchanged unless required by a proven interface defect.
- Expected: clean local checks, draft publication and pending owner measurement/100-switch/privacy test. Persistent cache and server revision stage remain pending this gate, not falsely complete.

## Review focus

Cancellation after transport success but before dispatch; account replacement without explicit purge; raw byte zeroing and clone ownership; all-subscriber cancellation followed by same-key retry; cancelled transports must still count against active cap; forced refresh/edit ordering; expired/invalid session must not expose cache; no peer or global image cache; diagnostic retention and request-key privacy.
