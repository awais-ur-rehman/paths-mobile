# Likes redesign implementation plan

Use superpowers:executing-plans inline and one fresh whole-change review.
Spec: docs/superpowers/specs/2026-10-24-likes-redesign-design.md

- [x] Backend: failing integration search/literal filters/privacy/expired pending/cursor actor-section-query binding; implement bounded filters in existing relationship query and export real1.14.0 contract. Full locally available suites/lint/build; micro commits.
- [x] Mobile: failing debounced search/filter/page/reset and UI tests; implement bounded repository/Cubit, four visible sections, photo grid, available/unavailable actions, reset/retry/cleanup. Inspect320/390 and large-text/keyboard snapshots. Preserve existing request/profile behavior.
- [x] Admin guide/contract: inspect protected account metadata privately; verify local login+MFA+logout without secret output; write requested documents/ADMIN_LOGIN.md and admin/docs copy. Regenerate admin/mobile types from actual export and check consumer suites.
- [ ] Review/verify/publish: one fresh review, reproduce/fix important findings; full Flutter/analyzer/Android tools/offline ARM64/kernel, backend/admin checks, local API image/smoke, honest status/device steps. Push every changed repo and update existing draft PRs, main unchanged.
