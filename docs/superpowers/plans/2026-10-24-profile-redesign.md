# Profile redesign implementation plan

> Use superpowers:executing-plans inline; one fresh whole-change review at the end.

Goal: shared portrait profile and a separate searchable account/settings page matching the supplied references.
Architecture: ProfileSurface composes a focused hero plus existing authenticated post/relationship Cubits; a settings route owns supported destinations. Extend original SVG masters/compiled PathsIcon geometry. Contract1.13.0 and backend unchanged.
Spec: docs/superpowers/specs/2026-10-24-profile-redesign-design.md
Constraints: existing Flutter stack/cache only; Android build only, no device operation/downloads/main merges.

- [x] Settings/icons/routing: write failing own-settings/search/guard tests, add original controls and grouped searchable settings route, replace old owner sheet. Preserve error recovery, sign-out/deletion/privacy destinations. Test and commit.
- [x] Profile/photos/actions: write failing surface/grid/state regressions; implement progressive blurred portrait from one private decode, centered identity/status/plain bio; top-right peer back and supported member controls/custom menu. Convert grid to lazy slivers with guarded paging/retry/private cleanup. Test and commit.
- [x] Review/verification: fresh whole-change review; reproduce/fix important findings; full Flutter suite/analyzer and Android/tooling checks; inspect320/390 renders including real fixture photo; offline ARM64 APK/kernel. No iOS app build.
- [x] Handoff: record exact evidence/commits/assets and device steps; push changed repo and update draftPR16. Keep main and performance qualification unchanged.

Code3fe019a/7638adf:362 Flutter tests,2 strengthened private-frame checks, analyzer,14 Android/tooling checks and offline ARM64 APK/kernel passed. Fresh review found no actionable findings. Owner physical Android acceptance remains pending.

Publication: pushed to existing draftPR16 (https://github.com/awais-ur-rehman/paths-mobile/pull/16), source7638adf with icons3fe019a. Only mobile changed; backend/admin remain clean. Owner test results are the next gate; main was not merged or promoted.
