# Open P brand implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan inline. Steps use checkbox syntax for tracking.

**Goal:** apply the owner's selected B—Open P identity consistently to existing app surfaces and platform exports.
**Architecture:** approved SVG masters feed reproducible raster/native/Dart exports; existing shared widgets render that geometry without a new runtime dependency.
**Tech Stack:** Flutter CustomPainter, SVG, existing local Sharp/Pillow, Android vectors, iOS asset catalogs, React's existing asset references.
**Spec:** design/logo-refresh/README.md and b-open-p-v2.svg / b-open-p-lockup-v2.svg; owner selected B in chat on 23 October 2026.

## Global constraints

- Preserve the selected geometry, ink/white/blue palette, outlined Inter lettering and its existing SIL OFL notice.
- No dependency/SDK/font/image installation, emulator, phone operation or unrelated UI/backend changes.
- Reuse the clean feature/logo-refresh branches; no additional worktree, so existing private config and offline caches remain available.
- Keep PRs draft pending owner appearance check; do not infer iOS runtime evidence from Android.

## Review focus

- Android system circles must not crop the complete mark or notification silhouette.
- Legacy/adaptive/themed/iOS icons must preserve padding, transparency requirements and aspect ratio.
- Wordmark and animation must use the chosen P, not retain old curves or unsupported glyph parsing.
- Reduced-motion, semantics and controller disposal remain intact.
- Exporting must not copy stale assets or silently draw a different symbol than Flutter.

## Tasks

- [x] Promote approved SVG masters; replace obsolete exporter with deterministic exports from those files. Verify source/native parity and actual system-circle bounds using observed RED/GREEN checks.
- [x] Generate Flutter vector lettering and P geometry; update shared brand/loader without additional dependencies. Inspect rendered widget/goldens and run relevant/full Flutter/tooling checks.
- [x] Copy consistent admin SVG/PNG exports and favicon; run admin checks and inspect exported boards.
- [ ] Build Android offline and verify its Dart kernel; validate iOS catalogs/available offline compile. Update assets/status, review complete diff and push draft PRs with physical retest commands.

## Execution ledger

Owner approved B; implementation is already authorized without another design approval. Existing branches/private config/caches are retained. No product behavior/API contract changes.


Selected B is integrated in commits bbc384e (exports/native) and cc32efd (Flutter). Native parity/safe-area checks failed against old artwork then passed against the exported P. Rendered the actual login golden and native launcher/launch PNGs; full Flutter suite passed 301 tests without updating goldens on the final run, and analysis reported no issues. Admin commit 50611c3 passed lint, build/typecheck and 8 tests. Fresh independent read-only review found no critical or important issues; its generated Android report warning will be resolved before submission.

The first offline Android build exposed missing pinned Kotlin plugin artifacts. A separate regression reproduced configuration leaking through Python's failed subprocess exception; commit 8d95b84 removes that traceback and preserves the exit status. The focused regression passes. The authorized Android dependency cache fill does not change package versions or install an SDK. Generic unsigned iOS compilation is blocked by the selected Xcode iOS 26.5 platform being absent; catalog dimensions and opacity checks passed, but no compile or runtime pass is claimed.

Re-exported from the committed masters with installed Sharp/Pillow and cached Dart; generated geometry and all tracked asset outputs were unchanged. Final focused checks passed: 2 native parity/safe-area tests and the build-failure privacy regression. Final tooling suite executed 15 tests: 13 passed, 2 failed because the required cached Kotlin compiler 2.4.0 is absent, not because Kotlin policy assertions ran and failed. Admin CI run 40007338338 passed; admin PR16 is draft.
