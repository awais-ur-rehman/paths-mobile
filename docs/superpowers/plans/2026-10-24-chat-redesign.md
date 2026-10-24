# Chat redesign plan

Use executing-plans inline. Spec: docs/superpowers/specs/2026-10-24-chat-redesign-design.md.

- [x] Backend/API: test recent-order paging, name search including literal wildcards, cursor query/account binding, revisions and authorized detail lookup. Add ConversationQuery(search/peerId), recent keyset query/detail endpoint; generate actual1.13.0 contracts for backend/mobile/admin. Focused source/test commit.
- [x] Mobile state: one-page repository API plus detail/peer lookup, remove eager all-page scans; Cubit search debounce/cancellation, stale result rejection, bounded recents, pagination/revision reset, retry/offline/reset/close. Add regression tests before implementation.
- [x] Mobile UI: original search/back/more/send SVG icons and custom option sheet; gradient list header/recent avatars/virtualized list/time/unread, gradient lazy thread/header/timestamps and white pill composer. Preserve reporting/send/read/lifecycle. Test interactions and320px/large text/keyboard, inspect golden fixtures and commit.
- [ ] Verification: whole-change review, fix findings, run full available suites/analyzers and offline ARM64 build/kernel checks, sync/reload local backend without downloads/data loss, authenticated API smoke. Record actual evidence/device steps, push all changed repos/draft PRs; no iOS/device operation/main promotion.

Local verification is complete:348 Flutter,14 Android/tooling, backend219/56/13/4, admin8, lint/analyzer/build, inspected snapshots, offline ARM64 kernel and live API/R2 smoke. Final publication remains unchecked because github.com DNS resolution is failing; owner Android acceptance remains pending.
