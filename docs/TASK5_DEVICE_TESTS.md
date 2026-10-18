# Task 5 physical-device checks

Use `feature/location-ingestion` in all three repositories. Test source mobile `fe5fe91` and backend `ef58ff0`, or their subsequent documentation-only branch heads. Exact final commits and draft PRs are recorded in IMPLEMENTATION_STATUS.md and the handoff. Task4 PR4 is merged into development. Task5 remains pending these results; do not promote it to main.

## Existing setup

Use the installed Flutter/Android SDK, Node packages and existing Compose images. No new dependency or service installation is required for these checks. Keep ignored `.env.local` and AUTH_KEY. Use `EMAIL_PROVIDER=mailpit`; inspect local test OTPs at http://127.0.0.1:8025 . Gmail app passwords and R2 credentials are not needed for this task. Do not send credentials or personal documents.

From `paths-backend`:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --build --wait --pull never
npm run auth:verify
```

This applies migration0005, preserves existing volumes and runs a synthetic API/worker/Mailpit verifier. The verifier uses synthetic coordinates0,0 and removes its own test account. Required local services: Docker running, PostGIS/Valkey/API/worker/proxy/Mailpit healthy. Missing cached images or packages are prerequisites to report rather than resolving implicitly.

From `paths-mobile`:

```sh
adb devices
adb -s <physical-phone-id> reverse tcp:8080 tcp:8080
flutter run --no-pub -d <physical-phone-id> -t lib/main.dart --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080
```

If Flutter is absent from PATH, use `/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter`. The native Android uploader permits cleartext only for debug loopback. A non-loopback or release API needs HTTPS. Debug APK output: `build/app/outputs/apk/debug/app-debug.apk` (rebuild for the pinned source if needed). Only the owner operates the phone.

## Numbered checks and expected results

1. Sign in to a synthetic adult test account, save profile details, skip optional review, and choose **Location & permissions** in your profile. Expect the white disclosure page. Entering/leaving it must not prompt for permission or begin capture. **Not now** returns to your saved profile. No map/matches appear; those are Task6.
2. Choose **Enable while using Paths**. Expect foreground location permission first, then a sharing/reduced-accuracy status after the server grants a lease. Try approximate permission, deny, and (where the OS allows) permanent denial. Expect an actionable safe error or settings hint; profile access remains available and repeated permanent denial must not repeatedly prompt. Restore permission in Settings and retry explicitly. Repeat with precise permission; no raw coordinates appear in the UI.
3. Walk outdoors briefly with Paths open. Expect pending updates to drain while the API is reachable. Native capture can batch at adaptive intervals; no exact sample interval or encounter detection is promised. Leave the permission page and return: collection must not depend on that page remaining mounted. **Refresh status and retry** refreshes metadata and attempts pending work.
4. Choose **Enable background sharing** while Paths is visible. On supported Android versions expect a separate notification permission request and an ongoing location notification. Lock the phone and walk for5–10 minutes, then reopen Paths. Record whether status/delivery recovered and whether a notification appeared. Declining notification/background access must fall back safely or explain permission needs. Android power management and force-stop can stop delivery; there is no resurrection guarantee.
5. With sharing active, simulate an API outage by stopping only the proxy from the backend directory:

   ```sh
   docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml stop proxy
   ```

   Keep location enabled and walk briefly. Expect offline/queued status once an upload fails. ADB reverse can remain online in airplane mode, so airplane mode alone is not a reliable API outage. Queue bounds are200 fixes and15 minutes; do not return raw queue files.
6. While that outage continues, choose **Pause and clear updates**. Expect pending count0 immediately and a pending server-pause notice if the server is unreachable. Relaunch while still offline: no collection may resume. Reconnect by starting only the proxy:

   ```sh
   docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --wait --pull never proxy
   ```

   Choose **Refresh status and retry**. Expect paused state with no old queued updates sent. A fresh explicit Enable may start a new lease only after control reconciliation. Repeat rapid Enable→Pause and Pause→Enable taps; no stale request may restart capture after the final Pause.
7. Repeat an outage with queued updates, then sign out. Expect local purge and no old-account capture after relaunch or signing into another synthetic account. Reconnect and explicitly enable the new account; no old fixes/profile should appear. A pending stop for the previous account must not pause the new account's lease.
8. With background sharing active, use the notification stop action. Expect the notification to disappear and capture/queue to stop. Re-enable explicitly, force-stop through Android Settings, and relaunch. Capture must remain stopped until a new explicit Enable; no capability is restored from disk. Also turn device location services off or revoke/downgrade permission in Settings during tracking, then return and retry; report stale status, crash or unauthorized continuation.
9. If a second physical device is available, enable the same synthetic account there. Expect it to replace the first lease. A late upload/stop from the old device must not affect the new lease. This is optional additional runtime evidence; automated API tests already exercise the epoch/lease rule.
10. Check320/390-style narrow layouts where possible,200% text, scrolling and Android back. Enable, Pause, Retry and Not now remain reachable. Existing splash/auth/profile appearance should remain as accepted.

Return commit hashes, phone model/Android version, numbered pass/fail, relevant times and visible status/pending counts. If an API request fails, return only method/path/status/request ID or sanitized build/crash excerpts. Exclude coordinates, tokens, passwords, OTPs, DOB and private messages. Screenshots should omit personal data. If permission behavior differs, report precise/approximate/denied choice and the OS prompt sequence.

## Separate evidence still needed

Android results do not validate iOS. iOS requires a signed owner device build, an HTTPS API endpoint and staged When In Use→Always permission testing; the unsigned generic iphoneos compile proves compilation only. Do not assume debug HTTP passes iOS App Transport Security. Repeat foreground/background, approximate/precise, denied/Settings, offline pause/logout and force-quit scenarios when that setup is available.

This checklist does not establish battery use, paired-phone encounter precision/recall, notification latency or store approval. Existing quantitative Phase0 evidence remains separate. Real photo/CNIC media is Task8. Task5 cannot close or advance its dependent Task6 gate until the required owner results are accepted.
