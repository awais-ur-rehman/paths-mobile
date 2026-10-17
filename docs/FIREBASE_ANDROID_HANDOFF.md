# Firebase Android handoff — 2026-10-18

Project: `paths-awais` ([console](https://console.firebase.google.com/project/paths-awais/overview)). Android package: `com.paths.mobile`. Registered app: `1:798261399062:android:ae70db5083147e5fd5ef37`. Google Analytics, databases, Storage and Functions were not configured. Cloud Billing reports billing disabled and no linked billing account; this is the no-cost Spark configuration. Do not link billing to enable notifications.

## Local configuration

Backend `.env.local` contains FCM_PROJECT_ID and container FCM_SERVICE_ACCOUNT_FILE. The dedicated `paths-notifications` service account has only the project-level Firebase Cloud Messaging API Admin role. Its key is in ignored `.secrets/firebase.json` (file mode600, directory700), mounted read-only only into the worker by `infra/compose.push.yaml`. Do not commit or share it. Existing Gmail, R2, database and encryption settings were preserved.

Mobile ignored `google-services.json` is the downloaded Android configuration. Ignored `paths.push.local.json` supplies the four public Firebase options and existing loopback API/map defaults. The app initializes Firebase directly; no Google Services Gradle plugin change is needed. Neither these files nor the private server key is included in Git. Builds without the JSON defines remain unconfigured for push.

R2: the owner's four settings passed a read-only HeadBucket request. No objects were uploaded, changed or migrated. Filesystem remains the media provider. R2 write/delete, private serving and migration verification remain pending; do not change MEDIA_KEY or MEDIA_PROVIDER before migration planning.

## Checks actually run

- Backend TypeScript build and all4 push transport unit cases passed.
- Dedicated service-account OAuth and FCM HTTPv1 `validate_only` request passed; no notification was delivered. An initial validation failed during setup; diagnostic retry with a longer test timeout passed, then the original application timeout settings also passed. No transport behavior was changed.
- Existing local Docker images started with `--no-build --pull never`; API and worker health checks passed. The running worker loaded its secret, completed real FCM OAuth and reported FCM configured / APNs unconfigured.
- Android debug build passed offline,235 tasks. All4 Firebase option values are present in its packaged Dart kernel. The compiler, staged bundle and APK bundle match:74989688 bytes, SHA256 `cfe25a32e349e05f778d7a686d2874152d6506bb8e3f1ba44e6ecd9ac089e75e`.
- No app source changed. Full Flutter/integration suites were not rerun for this configuration-only setup. Provider validation cannot prove Android permission, registration, delivery, background behavior or notification taps. Owner phone tests remain pending. iOS APNs credentials/signing/runtime are separately pending.

## Owner Android test

Start Docker Desktop if it has been stopped. From paths-backend:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml -f infra/compose.push.yaml up -d --no-build --pull never --wait
```

From paths-mobile, using the already built and checked APK:

```sh
adb reverse tcp:8080 tcp:8080
flutter run --no-pub -d 13111JEC204217 --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
```

Do not uninstall or clear app data merely to enable push. On a later rebuild, include `--dart-define-from-file=paths.push.local.json`; recheck the APK kernel before installing if Android startup corruption recurs.

1. Sign in with your test account. Open Notifications, its settings, then Enable on this phone. Allow Android notification permission. Expected: enabled/registered state without the setup-pending message. If denied, re-enable through Android settings and retry the app action.
2. From a separate test account/session, send a connection request to this account. Expected: inbox card and a generic Paths notification; no private name, message or location in the OS alert. Accept from the receiving account and check the sender's acceptance alert. A real incoming event is needed; enabling permission alone does not prove delivery.
3. Repeat with Paths in the background and phone locked. Tap the alert: the current session must authorize and open the appropriate destination. Offline/power restrictions may delay delivery; force-stop is not a supported delivery guarantee.
4. Disable request notifications in the app, then trigger another eligible event. Expected: inbox history remains, OS alert stops. Deny OS permission and retry enable after granting it again.
5. Sign out, then use another test account. An old notification tap must never reveal the former account's private content. Recheck photo selection → Use photo → Change photo/preview → Next → Verification, since that earlier fix still awaits owner retest.

Return the step, Android version, foreground/background/locked state, permission state, approximate time and visible error. Return only redacted worker error codes/request IDs if needed; do not send device tokens, credentials, private messages, exact coordinates or personal documents. See PUSH_SETUP.md for the full device matrix.

Main remains unchanged. Task9 and later development remain on hold. Do not merge the mobile PR or call live push verified until the relevant owner tests pass.
