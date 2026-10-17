# Push setup and verification

Task7 introduced API contract1.6.0; current contract1.7.0. Firebase Android configuration was completed on2026-10-18; see [current setup evidence and owner tests](FIREBASE_ANDROID_HANDOFF.md). FCM OAuth and validation-only checks pass. Physical-device delivery/latency and iOS APNs setup/runtime remain pending. The inbox also works without push.

## Private server configuration

Use a Firebase project owned by the operator, with Android package `com.paths.mobile`, Cloud Messaging HTTPv1 access and a service account permitted to send. Keep its JSON key private. For iOS, enable Push Notifications for the same bundle ID in the Apple team, configure signing/provisioning and obtain a P256 APNs token-auth `.p8` key, key ID and team ID. Do not commit any of these files or paste them into PRs/chat.

For a local worker, set the optional variables in `.env.local` from `.env.example`. For Compose, create ignored `.secrets/` yourself, restrict its permissions, place keys there and use **container paths** such as `/run/paths-push/firebase.json` for FCM_SERVICE_ACCOUNT_FILE and `/run/paths-push/apns.p8` for APNS_KEY_FILE. Add `-f infra/compose.push.yaml` to the normal Compose command. Only the worker receives these paths and the read-only mount. The overlay refuses to create a missing host directory. No credentials are needed for API-only local checks.

FCM_PROJECT_ID must match the service account project. APNS_TOPIC defaults to com.paths.mobile; APNS_SANDBOX=true is for a development-signed app, false for the production APNs environment. Never use a development token on the production endpoint or vice versa. Configuration errors stop worker startup; missing configuration does not acknowledge a successful delivery.

## Mobile configuration

Android public app options belong in ignored `paths.push.local.json`:

```json
{
  "PATHS_API_ORIGIN": "http://127.0.0.1:8080",
  "PATHS_MAP_STYLE_URL": "https://tiles.openfreemap.org/styles/liberty",
  "PATHS_FIREBASE_PROJECT_ID": "your-project-id",
  "PATHS_FIREBASE_APP_ID": "your-android-app-id",
  "PATHS_FIREBASE_API_KEY": "your-public-app-api-key",
  "PATHS_FIREBASE_SENDER_ID": "your-sender-id"
}
```

These public app options are not service-account credentials. They initialize the already pinned native Android SDK directly; a Google Services Gradle plugin is not required. Restart/reinstall after changing Firebase projects. Do not supply a service-account JSON to Flutter. On iOS use PATHS_APNS_ENABLED=true only after owner signing/provisioning setup; Debug uses development entitlement and Release uses production.

Build/run with `flutter run --no-pub --dart-define-from-file=paths.push.local.json` once dependencies are available. For Android over USB, owner may run `adb reverse tcp:8080 tcp:8080`. Only debug builds permit the loopback HTTP origin. No permission prompt runs at app startup. Open Notifications > settings > Enable on this phone.

## Delivery semantics

Private saves never notify the subject. Pending request and acceptance have generic in-app cards. Inverse requests remain pending until the receiver explicitly accepts. Incoming cards become unavailable after cancellation/expiry/acceptance; accepted-card resolution requires an active connection. Opening an authorized profile marks its source card read after the profile loads. Failed/unavailable opens do not mark read.

Encounter push is suppressed after120seconds; request push after24hours. Inbox retention is30days. Encounter pushes allow one alert per recipient/pair per6hours and ten per recipient/UTCday; suppression and OS opt-out do not remove inbox history. Retries record acknowledgments per device and use event collapse IDs. Delivery is at least once: a provider acceptance followed by a database failure can still duplicate an alert. There is no exactly-once claim.

Device tokens are encrypted with a push-specific derivation of AUTH_KEY. Registration is tied to a valid auth session and a persisted install generation. Logout/reset/session revocation deletes server registrations; expiry is checked at send and cleaned by retention. Native logout clears bindings and delivered app alerts before another account can bind. Android data payloads are checked against the active binding before display. APNs generic alerts already accepted by Apple can arrive after logout and cannot be recalled reliably; taps always reauthorize on the server and expose no former account identity. Force-stop, permission changes, offline state and OS power policies may prevent delivery. Exact coordinates, names, messages and documents never enter push payloads.

## Owner device checks

1. With two eligible adult test accounts on separate sessions, save a peer. Only the saver sees Saved. Unsave, refresh and confirm removal. Do not use real personal data for test fixtures.
2. Send a connection request after confirmation. Sender sees Sent, receiver Incoming. A reciprocal send must show Incoming rather than connect automatically. Sender must not accept its own request.
3. Accept on receiver. Both profiles show Disconnect, Connections contains the pair. Disconnect produces cooldown; cancel and decline paths also update the other account after refresh. Expiry/cooldown timing is covered by database tests; do not alter production data to accelerate it.
4. Without push config, verify inbox history and the concise Push setup pending state; no unsolicited OS prompt. Pull to refresh, retry offline and remove unavailable saved entries.
5. After setup, enable notifications explicitly. Check foreground, background and locked-phone encounter/request delivery on Android. Deny/re-enable OS permission, rotate token by owner-controlled reinstall, sign out/sign into another account and verify old-account taps cannot open private resources.
6. Turn off encounter/request preferences, queue new events, and confirm history still exists while alerts stop. Test block/deletion between enqueue and send once those UI workflows arrive in Task10; the current backend fixtures cover the rule.
7. Repeat push/tap/session checks on a signed physical iPhone. Android and unsigned iOS compilation do not validate APNs runtime.

Return branch/commit, Android/iOS version, app foreground/background state, permission/settings state, exact steps and visible result. Provide request IDs and redacted worker error codes only. Never send tokens, credentials, exact coordinates, screenshots of CNIC or personal data.

References: [FCM HTTPv1](https://firebase.google.com/docs/cloud-messaging/send/v1-api), [Android setup](https://firebase.google.com/docs/cloud-messaging/android/get-started), [APNs requests](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns).
