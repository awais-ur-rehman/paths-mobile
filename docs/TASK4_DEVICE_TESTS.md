# Profile and optional verification retest

Test feature/profile-verification in mobile and backend using the final commits in the handoff. PR4 remains draft pending these results. Previous Task3 Android approval is recorded separately; no need to reset onboarding for this task.

## Prerequisites and configuration

Use the existing installed Flutter/Android SDK, Node packages and development Compose stack. No new dependency installation is required. Task8 is the explicit prerequisite for actual profile photo/CNIC upload and full profile completion. Do not provide a real CNIC or collect personal images in this build. Gmail delivery still requires the owner's private app password; local checks use Mailpit. R2 credentials are not needed yet. iOS runtime validation is separate from Android.

Backend, from paths-backend:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --build --wait --pull never
npm run auth:verify
```

Normal migration service applies0004_verification.sql without deleting existing volumes. Keep AUTH_KEY and existing ignored `.env.local`. EMAIL_PROVIDER=mailpit for this local verifier; OTPs at http://127.0.0.1:8025 . Terms/privacy/support configuration remains server-side and editable. Never share passwords/keys.

Mobile, from paths-mobile:

```sh
adb devices
adb -s <physical-phone-id> reverse tcp:8080 tcp:8080
flutter run --no-pub -d <physical-phone-id> -t lib/main.dart --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080
```

If Flutter is not on PATH use `/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter`. The existing debug APK can also be rebuilt for this commit and installed by you; no phone/emulator is operated by the implementer.

## Steps

1. Sign in with a synthetic adult test account. Expect the existing white profile form, a neutral avatar and an honest photo-unavailable notice. Name/username/gender/bio remain editable; there is no DOB edit field. A non-adult account must remain on the age page.
2. Save details with Private profile enabled. Expect success only after the server responds. Toggle Public profile, edit bio and save; relaunch/reload and confirm persistence. Public means eligible signed-in viewers, not unrestricted stranger search.
3. Try another account's username. Expect an error toast and your unsaved edits/privacy choice retained. Correct it and retry. Disconnect for a save: expect failure rather than a saved notice; reconnect and retry explicitly.
4. Choose Save and continue. Expect optional document review. No photo, document or verification success is fabricated. The front/back controls are unavailable in this build; no system gallery/camera permission should be requested.
5. Choose Skip for now. Expect the saved own-profile preview with name, derived age, username, gender, bio and privacy. Skip must persist server-side, retain access and never create a reviewed badge. Reopen Document review: it remains optional.
6. Choose Edit profile, change fields/privacy, save and return via the back control or View your profile. Expect the current saved values; no stale preview. Sign out and sign in to a different synthetic account: no previous user's details or review status may appear.
7. Scroll forms/review at200% text, show the keyboard on the last field and rotate/relaunch. Essential actions remain reachable. Repeat at normal text and confirm the splash/onboarding correction is unchanged.
8. Status fixtures are automated only: pending, declined/retry and approved badge explanation are tested with synthetic opaque asset IDs, never uploaded CNIC images. There is no staff decision UI yet. Report any reviewed badge on an account that has no approved review as a failure.

Return mobile/backend commit, phone model/Android version, numbered pass/fail and screenshots of mismatches. Include only sanitized visible error/reference IDs or build/crash excerpts; exclude DOB, passwords, OTPs, tokens and personal documents. Battery/background tracking, real media and iOS runtime are not verified by this checklist.
