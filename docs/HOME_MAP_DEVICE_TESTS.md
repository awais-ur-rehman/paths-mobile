# Home map Android test

Latest location/blank-map fix: see `docs/LOCATION_MAP_RETEST.md` for cold-start commands and current code commits.

Branch: `feature/logo-refresh`. Implementation: `8ffd5ed` (with search contract/state `9dcd999`). API: `1.15.0`; backend `ef826d4`, admin contract `20ec0a0`. Later documentation commits do not change the APK. Existing draft PRs remain pending owner acceptance; main is unchanged.

## Local prerequisites and configuration

The local Docker API and worker have been updated from cached runtime code. PostgreSQL/Valkey and existing R2/push mounts were preserved. API: `http://127.0.0.1:8080`; readiness must return contract `1.15.0`. Internet is needed on the phone for OpenFreeMap tiles/glyphs and authorized private photos. No new dependency, SDK, map key or paid provider is required by this change.

The APK is already built for Android ARM64 using the existing ignored `paths.push.local.json` plus local API origin. Keep all `.env.local`, `.secrets` and local define files private. Existing default/Liberty map setting now selects `assets/maps/paths-light.json`; a deliberate alternate HTTPS style still overrides it.

Connect the phone by USB with debugging authorized, then run:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

If needed, reproduce the cached build without package resolution:

```sh
env 'ORG_GRADLE_PROJECT_target-platform=android-arm64' \
  JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
  GRADLE_OPTS=-Dorg.gradle.java.home=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
  GRADLE_OFFLINE_BIN=/Users/awaisurrehman/.gradle/wrapper/dists/gradle-9.3.1-bin/23ovyewtku6u96viwx3xl3oks/gradle-9.3.1/bin/gradle \
  python3 tools/build_android_offline.py --api-origin=http://127.0.0.1:8080 \
  --defines-from-file=paths.push.local.json
python3 tools/check_android_kernel.py --apk build/app/outputs/apk/debug/app-debug.apk
```

## Test steps and expected results

1. Sign in with the owner's existing account and open Home. Expect a full-screen light map, original bottom navigation, search and compact controls. No inline profile cards/list. Confirm native map attribution remains readable above navigation and tapping it opens provider/data credits.
2. Allow foreground precise location if requested. The native current-position puck should appear; Your location recenters on a fresh fix. Pan/zoom, walk a short distance and recenter again. Denial must keep the map usable; the top location control should offer the existing permission/settings recovery. Location services off or an unavailable fix must not invent a position. Background consent remains a separate choice.
3. Tap Show crossed paths. Expect avatar pins at approximate encounter areas. Six existing demo encounters/photos were readable in the local API smoke test. Pins represent authorized encounter history, not a live people radar; multiple paths at the same/overlapping area show a count instead of invented offsets.
4. Tap a pin/count. Expect a draggable white preview with authorized photo, name/username, verification, coarse area/time and available encounter count/bio. For a group, switch people using its avatar strip. Tap the member header to open the real profile; Back should return to the preserved map/filter.
5. Check a member in each available relationship state: Save/Remove, Send request with confirmation, incoming Accept/Decline, outgoing Cancel, connected Message. Cancel a confirmation and confirm no request was sent. Actions must reflect actual server state; unavailable/cooldown/error states must remain explicit. Message opens the existing authorized conversation.
6. Search an existing demo name or username. Clear to restore results; a nonmatching query shows No matching paths while keeping the map. Rapid typing must settle on the newest query. Toggle Recent/Nearby and radius; Nearby uses the existing location requirement. Search covers all authorized pages, not only loaded markers. More paths/Load appears only when a server cursor exists (larger data sets), and loads a bounded next page.
7. Open Map options. Refresh paths revalidates; Browse paths provides a scrollable accessible selection of loaded members; Notifications and Location sharing open their actual screens. Check TalkBack names,200percent text, keyboard search, small display and safe areas for overlap/clipping.
8. Open a preview and a request confirmation, then background/resume the app. Both must close, the map should recover and data revalidate. Switch bottom tabs and return; current map resources must clean up. Account logout/safety changes must remove stale private previews.
9. Disable internet briefly. Existing available map content may remain; failed refresh shows Retry without an inline-card fallback. Restore internet and retry. A native style-load timeout should show Retry map and recover after the service returns. Do not expect offline map downloads or new tiles without network.

If something fails, return the step, visible message, permission/service state, Android version and a screenshot where useful. For rendering/crashes, provide a short relevant `adb logcat` excerpt with tokens, messages, member details and exact coordinates removed. Do not upload full logs or credentials. Native appearance, camera movement, permissions and smoothness require this phone test; widget goldens use a test renderer. iOS validation and existing Task13 capacity/battery/soak gates remain separate and pending.
