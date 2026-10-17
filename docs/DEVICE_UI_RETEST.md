# Device UI correction retest

Use the final commits in the handoff report: mobile feature/session-refresh, backend feature/email-auth. PR3 remains draft in all three repositories. This retest verifies the reported corrections; it does not replace unreported Task3 security/OS scenarios or iOS runtime checks.

## Setup

Use the installed Flutter/Android SDK and authorized physical Android connection. No emulator is required. Backend migration0003 must be applied by the normal Compose migration service. Existing AUTH_KEY and local data remain intact; do not delete Docker volumes.

From paths-backend:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --build --wait
npm run auth:verify
```

Mailpit testing only: EMAIL_PROVIDER=mailpit. Read OTPs at http://127.0.0.1:8025 . The verifier exercises signup, adult check, real profile save/read and reset, and cleans only its synthetic fixture. Gmail is configured separately in the ignored server env; never send credentials in feedback.

From paths-mobile:

```sh
adb devices
adb -s <physical-phone-id> reverse tcp:8080 tcp:8080
flutter run --no-pub -d <physical-phone-id> -t lib/main.dart --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080
```

Use `/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter` if Flutter is not on PATH. The existing locally built APK is also available at build/app/outputs/apk/debug/app-debug.apk. Install only after rebuilding/checking the matching commit: `adb -s <physical-phone-id> install -r build/app/outputs/apk/debug/app-debug.apk`.

For onboarding only, returning users need fresh local app data because the app correctly remembers onboarding. If you choose to reset this test installation, `adb -s <physical-phone-id> shell pm clear com.paths.mobile` removes all local app data and signs it out locally. This is optional and does not delete backend accounts or revoke other sessions. Never run it against app data you need to retain.

## Steps and expected outcomes

1. Cold launch: the whole crossing-paths symbol fits, with more breathing room and a white background. Check OS splash and Flutter bootstrap separately; no clipped stroke ends or stretched image. No artificial splash delay is added.
2. Fresh onboarding: photo spans the full width and roughly top half, with centered heading/description and one black Get started pill. No account link, age line, policy links or credit footer appear underneath. Paths branding is original; the illustrative licensed photo does not represent active users.
3. Tap Get started once and then try repeated taps. The white arrow circle travels from left to right inside the black pill before login appears, exactly once. Reduced-motion mode skips travel without delaying navigation. Login/signup/OTP/reset backgrounds are white; their existing fields/actions remain available.
4. Sign up with a synthetic development address, paste the Mailpit code and confirm age. The age page contains only branding, age explanation/date field and Confirm age. It has no support, deletion or sign-out buttons. An under18 date still fails server validation. A valid adult date opens the profile-details form immediately, with the keyboard dismissed.
5. Fill name, username (3–24 letters/numbers/underscores), one documented gender option and optional bio (up to300 characters). Save details. Expect a top-right success toast only after the real save completes; reopen the app and confirm saved details are restored. Username casing canonicalizes. Saving details does not claim the photo/verification steps or full profile setup are finished.
6. Use Sign out on the profile page, then sign in with a second synthetic adult account and try the first account's username. Expect an error toast, editable form retained, and no fake success. Correct the username and retry. After a prior successful save, also force a later failure and retry: no saved toast should appear while a request is pending/failing.
7. Inspect loading during bootstrap/network requests and profile saves: two travellers follow the original crossing Paths curves, with no default circular spinner. Enable reduced motion and confirm a clear static mark appears. Disconnect/reconnect to check error/retry behavior; no success is fabricated offline.
8. Success and error toasts enter at top right. Swipe right to slide one off-screen or use its close button. A replacement toast must not vanish because of the previous toast's timer. With accessible navigation enabled, notices remain until dismissed. Underlying fields remain usable outside the toast area.
9. Repeat onboarding/forms at200% text and with keyboard visible; rotate/relaunch. Check button labels, arrow containment, scrolling, focus and absence of clipped content. Confirm a restricted test account still has support/deletion-help access on its separate restricted screen; removing age-page actions does not remove those protections.

Return mobile/backend commits, phone model/Android version, steps pass/fail and screenshots of any mismatch. Include safe visible error/reference IDs or sanitized crash/build excerpts. Do not share passwords, OTPs, tokens, DOB, raw session storage or personal email content. No physical device or emulator was operated by the implementer.
