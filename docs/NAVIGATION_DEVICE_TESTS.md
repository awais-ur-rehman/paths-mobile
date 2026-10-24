# Bottom navigation phone check

Branch: `feature/logo-refresh`. Test source: `83ad77c`, including icon family `2bb3636`. API contract1.12.0 unchanged. Mobile PR16 remains draft; main unchanged. This APK also includes the preceding Open P and auth UI updates.

## Prerequisites

Use the existing ARM64 Android phone, USB debugging and local Docker backend on port8080. The ignored `paths.push.local.json` and provider configuration are unchanged; do not share them. No dependency, SDK or tool installation is required on this prepared machine. No iOS build was run for this pass, per the owner's Android-only instruction; iOS runtime validation remains pending.

## Install

Stop any existing Flutter run session. Install with `-r` to retain data:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Use that actual Gradle APK path; the separate Flutter output copy can be stale. If installation reports incompatible signatures or versions, return the error; do not uninstall or clear app data. Offline rebuild commands remain in docs/AUTH_UI_DEVICE_TESTS.md and use the same API origin/configuration.

## Steps and expected results

1. Sign in and finish existing setup if needed. The bar has rounded white ends, a central scoop and a raised blue Plus. Home/Likes are on the left; Chats/Profile on the right. No visible tab text; the selected icon and short underline are blue. Icon lines should remain sharp, uncropped and consistent.
2. Tap every tab. Confirm the correct page opens and its icon becomes selected. In Home choose a filter, switch to another tab and return: the filter remains. Reselect an already selected tab: its existing reset-to-start behavior remains.
3. From Chats or Profile tap Plus. The existing camera/photo flow opens. Cancel or return: the original tab remains selected. Complete a test post if desired; uploading behavior is unchanged.
4. Scroll to the last item on Likes and Profile. Content must be reachable above the bar; the profile background should continue behind the notch/margins. Check the navigation does not cover a final action.
5. Check near the Android gesture/navigation area: targets remain separated from system gestures. With large text enabled, the icon-only bar remains usable and tooltips do not become permanent labels.
6. Open a software keyboard on a screen within a tab if one is available. The bar hides while the keyboard is open and returns afterward. Full-screen pushed chat/photo routes retain their existing navigation behavior.
7. With TalkBack enabled, move through the controls. Expect Home, Likes, Camera, Chats, Profile with the active tab announced as selected. No duplicate or missing names. If using a physical keyboard, Tab/Enter should activate controls in visual order. RTL layouts mirror the side groups while Plus remains centered.

If a step fails, return its number, Android version, gesture/three-button setting, active tab and exact action. Include a screenshot cropped to the affected UI or the first build/install error and kernel-check result. Keep private messages, credentials, OTPs, tokens, exact coordinates and private configuration out of logs/screenshots.

## Executed checks

- 325 Flutter tests passed without golden updates; analyzer clean. Includes real go_router branch/reselection/camera-return checks, all8 optional capability combinations at320px/large text, safe areas, RTL, keyboard activation/hide/restore, two rendered navigation goldens and a contrasting-page pixel regression for the notch.
- Original SVG icons deterministically regenerate to the same Flutter geometry. Rendered320/390px bars inspected; no runtime SVG parser or new dependency.
- Offline ARM64 APK built in35s:274 tasks,24 executed/250 up-to-date. Kernel matches compiler output:76,163,264 bytes, SHA256 `18388007efc663aaab5aa36848f47d75737af1c0f51dfdc9aaccf1ab27d822a7`.
- APK SHA256 `9d4fa193849a5020b658702f14a4e66f4055cabfee6842437b53527d8a3cd993`. Generated icon geometry and new navigation compiled into the APK; ARM64 engine only.
- No phone/emulator operation. Native TalkBack appearance/order and actual gesture-area behavior require owner acceptance above.
