# Navigation and location phone check

Google sign-in was accepted by the owner on 2026-10-18. These are new fixes on `feature/provider-auth`; implementation commits are `353087a` (Chats), `213ae6f` (native precision/background status) and `ddc9dda` (map/permission flow). The final documentation commit is in the handoff report. Owner confirmed the changed behavior passed on physical Android on2026-10-18. Keep Task14 PRs draft and main unchanged because the dense-load release gate failed; see current implementation status. API contract remains1.12.0.

## Ready locally

No new dependency or installation is required on this Mac for the prepared debug APK. Existing backend API/worker and private Google/R2/Gmail/FCM configuration remain in place. The APK uses USB loopback API `http://127.0.0.1:8080` and the existing ignored `paths.push.local.json`, including its HTTPS OpenFreeMap style. Do not share private configuration. A different machine must have the documented cached Flutter/JDK/Android tools; installs are not performed by this task.

Run these commands yourself from `paths-mobile` with the phone connected:

```sh
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter run -d 13111JEC204217 --no-pub --use-application-binary=build/app/outputs/apk/debug/app-debug.apk
```

The agent has not operated the phone or launched an emulator. To rebuild later, use the existing offline command in `docs/TASK14_DEVICE_TESTS.md`, preserving the map/push defines. Do not install an APK that fails `tools/check_android_kernel.py`.

## Numbered check

1. **Chats:** sign into the completed account; tap Chats, Home, Profile, then Chats again. Expect the chat list or its honest empty state, never profile setup. Open an existing conversation and return; switching tabs should preserve the correct screen.
2. **Map:** open Home with network and device location on. Expect the map even without crossed paths or a backend center. Grant location when requested, or tap the top-right location icon. Expect your own dot and initial centering after a fresh fix. Empty history may still show its empty-state message below the map. Pan/zoom should remain usable; other people appear only through authorized approximate encounter areas. A nearby person without qualifying evidence is not guaranteed to appear.
3. **Permission refusal/retry:** optionally deny Paths location in Android App permissions (do not clear app data). Reopen Home. If Android permits a request, expect one short explanation and the native permission sheet after Allow location. Deny it: Home/Chats/Profile remain usable, with a location icon at top right. Tap that icon to retry. Android can stop displaying prompts after repeated denial; then expect a Settings action. Grant permission there and return; expect sharing to start only from that explicit request.
4. **Precision:** select Precise in the native sheet or Android App permissions. Test outdoors with a clear signal. Paths makes one high-accuracy attempt, at most20seconds, then uses balanced collection. If the OS provides approximate access or the actual fix is poor, the app must say so honestly; background sharing must not be mislabeled as disabled merely because GPS is inaccurate. This test does not prove a guaranteed accuracy or battery budget.
5. **Background:** open the short Location settings, enable Background sharing and accept any OS notification permission. Expect the switch to remain on and the background-sharing status to stay distinguishable from the GPS-quality note. On Android, expect the ongoing location-sharing notification. Leave Paths with Home/lock the screen for about3minutes, then return. Report whether sharing remained active and whether any error appeared. The notification alone does not prove backend sample delivery; aggregate delivery can be checked after your result without exposing coordinates. Force-stop is intentionally not resurrected.
6. **Pause / Settings changes:** pause sharing, switch tabs and reopen Home. Expect no silent restart and no queued capture from a paused lease. Revoke location or turn device location off, then return: expect a recovery action, no crash or false sharing success. Restore permission/services and explicitly enable again. Your local map dot can remain visible while server sharing is paused if the OS grant remains; it is a local display, not proof of an active sharing lease.
7. **Regression:** Google sign-out/sign-in, profile photos and an existing chat still work. Check a small display/large text and dismiss the top toast; the short permission controls must remain reachable.

If something fails, return the step, Android version, tested commit, exact visible error/reference, whether the native sheet opened, Precise/Approximate selection, and whether background sharing was on. Share timestamps and redacted request IDs only. Never send tokens, coordinates, private messages, account keys or full provider responses. Do not delete your primary account for this check.

## Evidence and limits

Final full Flutter suite **301 passed**; focused Home suite17 passed, including permanent-denial Settings recovery. Analyzer clean;13 tooling/native-policy checks passed. Offline Android274tasks passed. APK/compiler kernel76,097,400bytes, SHA256 `129777b80e9a4ce33ee7cb82bfee5c84becf0e87ee26ad59f039957e073be072`. Unsigned generic iOS compile passed with pinned packages and updates/resolution disabled. Updated location golden was rendered and inspected; widget map tests isolate the native view boundary and do not prove actual tile/SDK rendering.

Owner confirmed the physical Android fixes worked. This accepts reported functionality, not a quantified GPS/battery benchmark or independently measured background delivery. Apple configuration and signed iOS runtime remain deferred; Android evidence does not verify iOS. Task13 load qualification remains open. GitHub returned403 for branch-protection access on these private repositories under the current plan; no plan upgrade/public exposure or enforced-protection claim was made. No merge/main promotion/deployment is included in this handoff.

Sources checked for the platform choice: [Android foreground-service location example](https://codelabs.developers.google.com/codelabs/while-in-use-location), [Android permission flow](https://developer.android.com/develop/sensors-and-location/location/permissions/runtime), [location accuracy and battery](https://developer.android.com/develop/sensors-and-location/location/battery). Android uses a foreground service started while the app is visible; this change does not add all-the-time background permission or promise force-stop recovery. iOS retains its separate Always-authorization path.
