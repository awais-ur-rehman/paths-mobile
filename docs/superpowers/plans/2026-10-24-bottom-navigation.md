# Bottom navigation implementation plan

> **For agentic workers:** use superpowers:executing-plans inline; one fresh whole-change reviewer at the end.

**Goal:** match the supplied sculpted icon-only bottom bar while retaining existing navigation.
**Architecture:** DiscoveryShell maps real go_router branches to PathsBottomNavigationBar; editable SVG assets generate geometry for PathsIcon. No runtime SVG/dependency change.
**Tech Stack:** existing Flutter/Material/go_router and Python stdlib exporter.
**Spec:** docs/superpowers/specs/2026-10-24-bottom-navigation-design.md.

## Constraints and review focus

- Paths white/ink/blue; Home/Likes/Chats/Profile plus existing Camera action. Android only; main unchanged, draft PR pending phone acceptance.
- 320px and larger, RTL, large text, safe area and keyboard must keep actions reachable; vector icon bounds must not crop.
- Optional Likes/Chats/Camera configurations preserve branch indices; reselect resets current branch and camera return preserves it.
- Icon-only controls retain accessible names/selected semantics, >=48px targets and keyboard activation.

### Task 1: Navigation surface and icon family

Files: lib/app/discovery_shell.dart; new lib/shared/widgets/paths_bottom_navigation.dart, paths_icon.dart and generated/paths_icon_geometry.dart; assets/icons/*.svg; tools/export_icons.py. Tests: test/shared/paths_bottom_navigation_test.dart and existing route tests.
- [ ] Add real-router regression for icon-only semantics, branch persistence/reselection and raised camera return; observe RED against existing bar. Add width/optional capability tests.
- [ ] Author original SVG icons and deterministic vector exporter. Implement shaped white Material bar with smooth notch, raised blue plus, underline and safe-area padding; preserve existing branch callbacks. Record family in docs/ASSETS.md.
- [ ] Update existing tab selectors to accessible tooltips. Run focused interaction/layout suites and inspect visual goldens; commit.

### Task 2: Verify and hand off

- [ ] Run full Flutter suite and analyzer, deterministic export/diff check. Fresh whole-change source review; fix actual findings and rerun affected checks.
- [ ] Build ARM64 debug offline; verify APK/compiler kernel. No iOS build or phone/emulator operation.
- [ ] Record implementation status and Android test steps, commit, push existing feature draft PR. Main unchanged; owner device acceptance pending.
