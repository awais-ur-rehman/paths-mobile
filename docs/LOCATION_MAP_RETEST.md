# Location and blank-map retest

Branch: `feature/logo-refresh`. Code: `f85d0b0`, with native bridge `c598410`. API remains1.15.0; no backend/admin changes. PR16 stays draft and main is unchanged.

## Findings and changes

- Confirmed: Nearby retained its unavailable response after permission/lease enable. No refresh was triggered when the first sample reached the server. Native Android/iOS now emit a nonempty upload-acknowledgment event scoped to device session/consent epoch; Dart rejects old-session, old-epoch and post-pause events. Active Home refreshes unavailable Nearby after acknowledgment, preserving the selected filter/query and existing server eligibility.
- Confirmed: Android upload completion emits from its worker executor, while Flutter channel dispatch must use the UI thread. MainActivity now marshals dispatch onto that thread, skips a destroyed activity and reads current status at delivery so an older queued status does not revive stopped sharing.
- Confirmed: recenter only used MapLibre's independent location callback. LocationCubit now keeps an in-memory, fresh consent-scoped tracker fix for map recentering, rejects invalid/stale samples and clears it on pause/revocation/service disable/pending stop. Native map callbacks remain supported. No exact fix is logged, stored in preferences or returned as a peer marker.
- Nearby now distinguishes permission/sharing disabled from waiting for a fix, upload synchronization and offline state. An unavailable map no longer produces the misleading GPS-waiting toast.
- Rendering hypothesis: the owner sees avatars/controls with no loader/error, indicating initialized projection with an invisible/empty native basemap. The APK contains the correct style; the provider's public source and world tile returnedHTTP200 from the development machine. The Android map used the default SurfaceView/Virtual Display path, which has overlay/z-order limitations. EncounterMap now selects opaque TextureView mode before constructing the native view. This is the documented compositable mode for Flutter overlays. Actual resolution on this phone remains unverified; development-machine connectivity does not prove phone connectivity or GPU rendering.

References: [MapLibre Android platform-view modes](https://maplibre.org/flutter-maplibre-gl/advanced/performance/), [Android while-in-use/foreground-service access](https://developer.android.com/training/permissions/requesting). The Android OS may show Allow only while using while a foreground location service continues with an ongoing notification; this app does not request all-the-time background permission for that service.

## Checks actually run

- Clean Flutter analyzer;387full-suite tests pass, including new upload-refresh, recenter/revocation, texture-mode selection and scoped acknowledgment tests. Initial Nearby regression failed with2requests instead of3; texture-mode regression failed before the change. The first location-handoff regression demonstrated the missing input before implementation.
-14Android/tooling checks pass (the iOS native endpoint compilation test excluded as requested).
- Offline Android ARM64 debug assemble passes, including Kotlin compilation. Compiler/staged/APK kernel matches76,351,648bytes; SHA256 `ff689f76fd857e82f4c82458e4083d8646459fc08b7ed9949da2066d1023be1c`.
- Complete diff inspected for lease/account isolation, late callbacks, lifecycle cleanup, paused sharing, permission revocation, stale fixes and private logs. No dependency download, emulator/device operation, data reset or backend migration.
- iOS acknowledgment source kept in scope, but no iOS build/runtime check. Existing capacity/battery/soak gates remain open. Widget fixtures cannot prove native basemap visibility or actual GPS/background behavior.

## Install and cold-start

The local Docker API remains at `http://127.0.0.1:8080`. Preserve your existing app data and permissions. Run:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am force-stop com.paths.mobile
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

For a build command/config prerequisites, use docs/HOME_MAP_DEVICE_TESTS.md. No new setup or installation is required for this retest. Cold-start matters because native view mode is fixed when the view is created; hot reload does not change an existing view.

## Focused steps

1. Open Home with phone internet available. Streets/parks/water should draw behind the avatar markers. Pan and zoom; verify the native attribution and the Flutter controls remain visible. This is the primary pending rendering check.
2. Select Nearby. If sharing is paused, enable it once. Precise permission granted plus device location on should lead to Waiting for location/Updating Nearby while the first fresh sample arrives, then results or No paths crossed yet. It must not repeatedly demand permission after successful upload. If GPS cannot acquire a fix, waiting is legitimate; try outdoors briefly.
3. Tap Your location after a fix, walk a short distance and tap again. It should recenter on the latest location without depending solely on MapLibre's own callback. No need to keep re-enabling permission.
4. Enable background sharing while the app is open and confirm the ongoing Paths location notification. Lock/unlock the phone and return. Report whether the notification stayed present and whether Home recovered. This short check does not establish long-duration battery/background reliability.
5. Pause sharing: it must stay paused after returning to Home. Temporarily deny location in Android settings: stale fix must disappear and recovery must use permission/settings flow. Re-enable while using plus Precise; explicitly enable sharing again if paused. Home should recover.

Return which step failed and the exact visible status. If the basemap is still white, say whether avatars move when panning, whether attribution is visible and whether switching Wi-Fi/mobile data changes it. Include a short relevant native error excerpt only if available, with tokens, messages, personal data and any coordinate/tile URLs redacted. Do not send the full device log.
