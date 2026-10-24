# Encrypted own-cache Android retest

Branch `feature/logo-refresh`, draft mobile PR16; backend `feature/chat-list-search`, draft PR19; admin contract PR17 stays draft too. Source to test: mobile `ab20054` plus its documentation commit, backend `d0971f1`. APK SHA256 `969edcd900fef4fdd47e64aac545f11b8e7748f800abd27b8a1184f6b3ff7602`. API1.16.0 must be running. No merge/main promotion until owner acceptance.

## Prerequisites and configuration

Existing Android SDK/adb, locally configured Docker API/worker/PostGIS/Valkey and private R2 are already available. No new dependency installation needed for this batch. Keep Docker and the Mac running; phone Wi-Fi/mobile internet is required for map tiles. API origin is http://127.0.0.1:8080 via USB reverse. Existing ignored paths.push.local.json/backend .env.local remain local; do not share them. Native code changed: install this APK over the existing app, do not only hot reload. Do not clear app data; we want to test current sessions and upgrade behavior. iOS source is included but was not built or runtime-tested.

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am force-stop com.paths.mobile
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

## Functional steps

1. Signed-in launch: expect one splash and Home, then open your Profile. Confirm own photo/details and gallery. An initial cache miss still downloads normally.
2. Visit Home/Likes/Chats/Profile20 times within30seconds. Own metadata/photo should be available on return, with no crash, wrong photo, stuck loader or unexpected API toast. Peer/gallery images still reauthorize and are not written to this new disk cache.
3. Force-stop/start using the last two commands, then open Profile. Session and server profile revision must be checked before the stored own photo is reused. The transport regression verifies no second image download for unchanged own assets; visual responsiveness still needs this phone check.
4. Pull refresh, edit name/bio, save and return. Confirm latest server values. Change avatar, then repeat restart; old avatar must not return. A second open edit form saved after another editor changes the profile must report a conflict and offer Reload latest profile, without silently overwriting it.
5. Background/resume within30seconds and again after30seconds. Old cache authorization must be invalidated; Profile rechecks the server. Normal tracking/permissions and notifications should continue.
6. After viewing Profile, force-stop, turn off connectivity and relaunch. Disk metadata must not grant offline sign-in/setup/access; expect retry/error handling until connectivity returns. Reconnect and retry. A visible model on a warm refresh may retain its documented offline behavior.
7. Sign out while images load. Expect signed-out flow, no old private image. Sign in with another existing test account, check its Profile, then sign out/back into the first account. No cross-account photo or text should flash. Account restriction/deletion purges are covered locally; only test those with a disposable test account and approved admin action.
8. Switch all four tabs100 times, open/close peer profiles and chat threads and scroll galleries. Expect no API failures, mixed data or broken tap/navigation. Return failing step/screen pair, exact toast/request reference, whether retry recovers, and rough photo-readiness time. Never send tokens, message bodies, exact locations or environment files.

## Isolated native crypto probe

This debug-only probe creates separate fixture files and a separate Android Keystore alias; it never reads or changes the actual cache/account. It checks real native crypto, so please run it once. The agent has not operated the phone or executed this probe.

```sh
adb -s 13111JEC204217 shell am force-stop com.paths.mobile
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity --ez paths.runOwnCacheProbe true
adb -s 13111JEC204217 logcat -d -s 'PathsOwnCacheProbe:I'
```

Return the latest JSON line only. Expected all true: roundTrip, encryptedAtRest, tamperRejected, accountSwapPurged, oldSessionRejected, keyDestroyed, fixtureFilesRemoved. After collecting it, force-stop/start normally without the extra flag. Dart fake-store tests cannot prove these native properties.

## Measurement gate

This debug build is a behavior test. Stage6 remains pending comparable profile/release cold/warm readiness, requests/bytes,100switches, frame jank and peak memory on the same account/network. TTL24h expiry, malformed records, storage failure, cancellation, account/session races and guarded edit concurrency have automated coverage. No device battery/memory/latency improvement or iOS acceptance is inferred from those tests. PRs remain draft until the owner tests this batch.
