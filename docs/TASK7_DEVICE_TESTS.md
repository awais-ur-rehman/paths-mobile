# Task7 owner device checks

Task6 PR6 is merged in all three repositories after owner Android approval. Task7 is **implemented and locally checked; awaiting device testing and push setup**. Test `feature/relationships-notifications`: mobile source `8ee055f`, backend source `584812f`, admin source `4df3afd`. Later commits record verification and instructions; final branch heads/PR links are in IMPLEMENTATION_STATUS.md. Main remains unchanged.

## Run on your Android phone

Existing Flutter/Android SDK, JDK21, Node packages and Docker images are available. Required Firebase Android artifacts were downloaded only after owner approval. No Firebase project/APNs setup exists yet; that is a separate prerequisite for real push, not for the Likes/inbox UI. Use synthetic adult test accounts with completed profile details. Do not upload CNIC, real photos or personal data for this test.

From `/Users/awaisurrehman/Documents/experimental/Paths/paths-backend`:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --build --wait --pull never
npm run build
node --env-file=.env.local dist/scripts/verify-relationships.js
```

Expected: migration0009 applied, services healthy and verifier status passed. This verifier creates/removes only its own synthetic fixture accounts and checks the real API/worker; it does not create visible members for the phone or send a real push. Keep the existing stable AUTH_KEY in ignored .env.local and EMAIL_PROVIDER=mailpit. Gmail/R2 are not needed. Do not delete volumes.

From `/Users/awaisurrehman/Documents/experimental/Paths/paths-mobile`:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"
adb devices
adb -s <physical-phone-id> reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter run --no-pub -d <physical-phone-id> -t lib/main.dart --dart-define-from-file=config/development.example.json
```

Expected: Home / Likes / Profile navigation. Notifications opens from Home's bell. No automatic notification permission prompt. Optional review/media controls keep their prior behavior. Exact push configuration and separate signed-iOS prerequisites are in PUSH_SETUP.md. Native cache/SDK discrepancies should be reported with the missing artifact name; no emulator is required.

## Checks

1. Open a genuinely eligible encounter from Task6. Save using its bookmark or profile Save action. Return Home: bookmark must agree. Open Likes > Saved, then unsave on the profile and return: item must disappear. Subject's Saved list must not reveal that they were saved.
2. Select Connect on the peer profile. Dismiss confirmation: no request. Confirm: Sent appears for sender, Incoming for receiver after refresh. Two eligible synthetic accounts/sessions are needed; a second phone makes this easier. If unavailable, report the paired steps blocked rather than fabricate evidence.
3. Sign into receiver. Accept or Decline on the profile; sender cannot accept its own request. Sending an inverse request must show the existing incoming request, with no automatic connection. Accept gives both accounts an active connection and Disconnect action. Cancel/decline/expiry/disconnect prevents immediate resends; automated tests cover14-day expiry and seven-day cooldown without waiting in real time.
4. Open the bell/inbox. Request cards use generic copy. Opening a currently authorized profile marks that card read after the profile loads. Cancelled/expired/deleted/blocked resources show unavailable; they must not reveal another account's profile or become read merely because the tap failed. Private saves produce no card.
5. Settings has four concise preference toggles. Save and reopen: values persist. With no push configuration the phone section says Push setup pending. It must not pretend a push was delivered. After setup, separately verify permission denial, registration retry and returning from OS settings.
6. Turn the phone offline after loading Likes/inbox; pull to refresh. Existing cards may remain with offline/Retry state. Failed Save restores its previous state. Restore connection and retry. Switch tabs rapidly, return from a peer, sign out and sign into another account: no stale account cards/actions should appear.
7. Increase system text size; inspect Saved/Incoming/Sent, peer actions, inbox and preferences. Tabs may scroll horizontally. No clipped actions or text overlap. App background/return should refresh current permission and list state.
8. Only after Firebase/APNs setup, perform the foreground/background/locked-phone delivery, opt-out, cooldown, logout/account-switch and signed-iPhone checks in PUSH_SETUP.md. Android does not verify iOS. Already accepted OS notifications cannot be reliably recalled; taps must always reauthorize.

Return branch/commit, phone/OS version, step numbers, expected/actual state and safe request IDs or short redacted crash/build excerpts. Never return tokens, passwords, OTPs, private keys, exact coordinates or personal records. Task7 remains open until required real Android/iOS push evidence is available; Task8 is not started through that gate.
