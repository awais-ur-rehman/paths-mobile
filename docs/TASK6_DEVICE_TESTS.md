# Task6 physical-device checks

Task5 functional approval is recorded and PR5 is merged. Task6 source is `feature/encounter-discovery`: mobile `68f7ed1`, backend `80dfda7`, admin `17bf501`; subsequent commits record documentation only. Final branch heads/PRs are in IMPLEMENTATION_STATUS.md. Task6 stays pending until owner results; main is unchanged.

## Setup and prerequisites

Already available: installed Flutter/Android SDK, Node packages, Docker images, cached MapLibre Flutter packages and Homebrew JDK21. No install is needed for the Android checks. Docker must be running. Use existing ignored backend `.env.local` with stable AUTH_KEY and `EMAIL_PROVIDER=mailpit`. Gmail SMTP and Cloudflare R2 are not needed here; no real documents, credentials or personal records should be used.

From paths-backend:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --build --wait --pull never
npm run auth:verify
npm run encounters:verify
```

Expected: services healthy, migration0006 applied and both verifier JSON statuses passed. They create synthetic accounts, exercise actual local services and remove their own accounts. Mailpit is http://127.0.0.1:8025 for synthetic signup codes. Preserve volumes. Missing cached packages/images are prerequisites to report, not a reason to silently change the stack.

From paths-mobile, using only your physical Android phone:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"
adb devices
adb -s <physical-phone-id> reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter run --no-pub -d <physical-phone-id> -t lib/main.dart --dart-define-from-file=config/development.example.json
```

The existing system Java17 cannot compile the cached map plugin; the installed JDK21 path above works without changing global Flutter settings. The final offline Android assembly passed197 Gradle tasks. APK: `build/app/outputs/apk/debug/app-debug.apk`. Flutter run can resolve native artifacts if caches differ; report a missing artifact rather than installing other SDKs. The map configuration is public and editable: PATHS_API_ORIGIN is debug loopback and PATHS_MAP_STYLE_URL is an HTTPS style. Do not put SMTP, R2, auth or private tile credentials there. Release/non-loopback APIs require HTTPS.

iOS native dependency is resolved following owner approval: MapLibre Native6.28.0, revision5ee345ca5d65238a6fce29bba87816204be7df20, pinned in the real Xcode-generated Package.resolved. Unsigned generic iphoneos Debug compilation now passes, including the embedded native framework. To repeat using the populated local cache:

```sh
xcodebuild -project ios/Runner.xcodeproj -scheme Runner -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-auth -clonedSourcePackagesDirPath build/ios-auth/SourcePackages -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

This does not install or operate a device. Physical iOS checks still need an owner-signed build and HTTPS API, then separate map/attribution/permission/background testing. Android does not validate iOS. No additional runtime results are claimed.

## Checks and expected results

1. Sign in to a synthetic adult account with saved profile details. If setup remains open, save details and skip optional review; full photo completion remains Task8. Open **Home** from the Profile bottom navigation. Expect a short header, Recent/Nearby filters and one clear empty-state action when no encounters exist. No fabricated members or photo-complete claim. Existing permission copy is unchanged; its visual redesign is deferred.
2. With sharing paused, inspect Recent, then Nearby. Recent history remains accessible; Nearby gives one contextual permission/settings action. Enable precise foreground sharing from Profile → Location & permissions, then return to Home. Change radius between0.5/1/3/5km. No results should be manufactured just because radius changes. Filters persist across Home/Profile navigation and Android Back returns correctly.
3. With internet available, switch to the map. Expect the configured basemap with visible usable attribution. Only coarse encounter areas may be marked; no precise own-location puck, peer live position, exact distance or exact time. Tap an area with multiple results: choose a profile from the area sheet. With one result, follow its profile entry. Expect only eligible name/age/bio/approved badge, neutral avatar until media exists, and Back preserving filters. No Save/Request buttons until Task7.
4. Map failure: run a separate debug build with `--dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080 --dart-define=PATHS_MAP_STYLE_URL=https://example.invalid/style.json` instead of the JSON config. Expect list fallback after failure or about12seconds and a concise Retry map action; cards remain usable. Restore the example JSON and retry. Blank map style intentionally selects list fallback. Report renderer/attribution failures rather than accepting a blank canvas.
5. Pause sharing or revoke permission in Android Settings while Home exists. Resume Home. Nearby must not claim available fresh location; Recent remains available under current eligibility. Switch between Home/Profile and background/resume: no crash, orphan map or repeated prompt. Check narrow portrait, large text200%, and scrolling; filters/cards/Back remain reachable.
6. If two physical phones and consenting synthetic adult accounts are available, enable precise foreground sharing on both in the same small open area. Supply at least two independently captured observations20–120seconds apart, each with reported accuracy at most25m. Wait for native batching/worker delivery and refresh Home on both. Expect one encounter session, count1, a coarse historical area and broad time label; reopening/refreshing/retries must not inflate it. Poor accuracy or a brief single crossing may correctly produce no match. Do not widen thresholds to force a result. Capture paired ground truth separately without sending exact coordinates.
7. On those phones, walk apart and compare older Recent areas against a new own location. Recent must keep its historical center; appending more history must not jump to a later page's city. Nearby is limited to24h and the chosen radius around a fresh own coarse center; Recent covers30days. A session after a real30minute inactivity gap may increase count; repeated samples within one session must not. Long-duration/radius and field-accuracy claims need actual evidence, not a forced fixture.
8. Pause one matched account, then refresh the other. The paused subject must disappear from current results/profile access. Sign out and sign into a different synthetic account: no old-account cards or in-flight profile may flash. Repeated fast filter changes and refreshes must show only the latest selection. Unavailable peers should show a short unavailable state rather than private status details.
9. Offline: open Recent after a successful load, stop only the backend proxy, then refresh. Existing basic history may remain with an offline retry state. Nearby must not fabricate fresh matches. Signout still clears the account's discovery UI. Restart only the proxy and retry; current results replace stale state. Commands from paths-backend:

   ```sh
   docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml stop proxy
   docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --wait --pull never proxy
   ```

10. Inspect sanitized GET /v1/encounters and GET /v1/profiles/:id response field names if a local debugging proxy is already available. Expected: coarse area center/ID, time bucket and dates; no peer exact fixes/distances/capture timestamps, DOB, private document URLs or pending/declined review state. Do not install a proxy or export a raw authenticated capture just for this check. Return field names/request IDs only. API tests already verify allowlists; native capture evidence remains pending.

Encounter pushes are deliberately not sent in Task6: two durable intents are queued for Task7 delivery/cooldown implementation. No result here proves notification latency, battery use, multi-floor precision or background reliability. Retain the separate Phase0 quantitative and Task5 background/kill/offline-purge checklists.

Return branch/commit, phone/Android version, numbered results, visible state and sanitized request IDs or crash/build excerpts. Exclude tokens, OTPs, passwords, DOB, exact coordinates, private messages and personal photos. If a pair does not match, report elapsed time, foreground/background, precise/approximate setting and broad accuracy category, not raw fixes. If a second phone is unavailable, report the paired test blocked; do not invent evidence.
