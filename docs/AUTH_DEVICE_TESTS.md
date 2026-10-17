# Task3 Android authentication checks

Gate: awaiting owner results. Branch `feature/session-refresh`; test the exact mobile and backend commits in the final Task3 report / draft PRs. The final documentation commit records the source commits and evidence. Do not merge these drafts or advance Task4 through this gate yet. Android results do not validate iOS.

## Available setup and separate prerequisites

The existing local Flutter3.47.7/Dart3.13.5, Android SDK/Gradle cache, Docker images and locked project packages built successfully. No emulator is needed. Required from you: physical Android with USB debugging and authorized adb connection, running Docker, and an installed email client if you want to test support handoff. Gmail SMTP is optional for this local gate; no Gmail app password has been supplied or tested. Policy URLs can remain blank for development testing only.

Backend, from paths-backend:

```sh
npm run auth:configure
# Existing Task2 env is preserved; new setups run npm run env:local first.
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --build --wait
npm run auth:verify
```

Edit ignored backend `.env.local` for SUPPORT_EMAIL (temporary address supplied by owner), TERMS_URL and PRIVACY_URL. Keep EMAIL_PROVIDER=mailpit for this checklist. Keep AUTH_KEY/private database password unchanged. SMTP credentials and AUTH_KEY never go in mobile configuration. See backend docs/runbooks/local-development.md for optional Gmail settings; Gmail delivery needs a separate observed test after private credentials are configured.

Open http://127.0.0.1:8025 on your computer to read development OTP mail. Mailpit captures mail to synthetic addresses without sending externally.

Mobile, from paths-mobile (replace `<phone-id>` with your physical ID from `adb devices`):

```sh
adb devices
adb -s <phone-id> reverse tcp:8080 tcp:8080
flutter run --no-pub -d <phone-id> -t lib/main.dart --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080
```

If Flutter is not on PATH, use `/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter`. The installed adb is under the Android SDK platform-tools directory. If you prefer installing the verified debug APK, rebuild for the exact commit first with the same define (`flutter build apk --debug --no-pub --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080`), then `adb -s <phone-id> install -r build/app/outputs/flutter-apk/app-debug.apk`. Normal auth uses main.dart; the separate location experiment uses main_phase0.dart. This auth checklist must not request location permissions or start tracking.

## Numbered checks and expected results

1. Fresh app data/install: inspect launcher mask and splash symbol, then onboarding photo/logo/type. Tap existing-account sign-in and back; Get started opens signup. Terms/Privacy show explicit development notices when env URLs are blank. No overflow at large OS font/display size or with keyboard open. This replaces existing local app data only if you choose to clear it; uninstall is not required for ordinary tests.
2. Use a unique synthetic email such as `phone-task3-<unique>@example.invalid`, name `Test Person`, and a disposable password of at least12 characters. Signup rejects invalid email, short password, and unchecked Terms. Password reveal and paste work. Repeated submit taps create one flow; OTP screen has a60-second resend countdown. No setup/discovery access before verification.
3. Read the code in Mailpit. Paste all6 digits, try a wrong code first, then the correct code. A correct code opens private age confirmation, without asking for location/CNIC. Back navigation cannot restore an active unauthenticated OTP flow. Five wrong guesses on a separate challenge must reject further guesses until a new code is requested.
4. On another signup, wait over5 minutes for expiry, then request a new code. Old code is rejected and the new code succeeds even after worker cleanup. Resend before60 seconds is blocked; resend invalidates earlier codes. Cancel/change email safely returns to auth.
5. Enter an under18 synthetic DOB; server rejects it. Enter an adult synthetic DOB (for example1990-01-01); confirm succeeds and shows Age confirmed/profile preparation. DOB is not displayed as public profile data. Full profile setup is Task4; no fabricated discovery screen is expected.
6. Background/resume, force-close/reopen and reboot/unlock the phone: the session restores to guarded setup. Check OS password-save and OTP-autofill behavior if available; paste must work even when the OS offers no autofill. No tokens should appear in logs. Wait over10 minutes then resume: refresh should restore without asking for a password. Do not intercept or share refresh secrets to test this.
7. Temporarily stop API/worker locally using `docker compose --env-file .env.local -f infra/compose.yaml stop api worker` in backend, then reopen/resume. App shows a connection error/retry and does not expose new protected content or discard the saved login. Restart with the setup command above, retry, and confirm recovery. Repeat while submitting an auth form: errors are visible; cancellation does not later navigate back into a cancelled flow. Restore backend before continuing.
8. Forgot password for your synthetic email: read the purpose-specific reset code, verify it, and enter matching new passwords. Mismatched confirmation stays on form. Success returns to login; old password fails and new password works. Other previously signed-in sessions for that account must be rejected on next server request. Repeat with an unknown synthetic email: generic challenge response must not reveal account existence.
9. Sign out online, close/reopen: credentials do not restore. Sign in, disconnect the USB reverse connection (`adb -s <phone-id> reverse --remove tcp:8080`), and sign out: app reports local sign-out with server confirmation unavailable; reconnect reverse and reopen, and it stays signed out. A network failure must never claim confirmed remote revocation.
10. Restricted account test uses only the local synthetic fixture. Open the local database shell in backend:

```sh
docker compose --env-file .env.local -f infra/compose.yaml exec -T postgres psql -U paths -d paths
```

Enter SQL with your synthetic email (no production accounts):

```sql
UPDATE users SET status='deactivated' WHERE email='phone-task3-<unique>@example.invalid';
\q
```

Sign in/resume. Expect restricted status, Contact support, Ask support about deletion, and Sign out; no setup bypass. Support buttons open the configured recipient in an email client, or show a visible launch error when unavailable. Tapping deletion help must not claim the account was deleted. Restore this test fixture afterward using the same shell and `UPDATE users SET status='active' WHERE email='...';`.
11. Rotate the phone, use keyboard Next/Done, screen reader labels,200% text, and return from mail/browser to the app. No clipped submit buttons, stale busy states, duplicate navigation, or crashes. Configuring HTTPS TERMS_URL/PRIVACY_URL and recreating API/worker should open those actual URLs; malformed/insecure URLs must not be accepted by server configuration.

## Return evidence

Report exact mobile/backend commit, phone model/Android version, each step pass/fail, and whether OS autofill/support email launch were available. For a failure return numbered step, minimal reproduction, visible safe error/reference ID, and sanitized build/crash excerpt. Do not send passwords, OTPs, token headers, database connection strings, exact coordinates or personal email content. Screenshots should use synthetic fixtures. No phone/emulator was operated by the implementer.

iOS unsigned compilation passed; signed installation, Keychain persistence, launcher/splash, autofill, background/resume and support handoff require a separate iOS physical runtime test. Android cannot close those items. Phase0 battery/encounter/notification measurements remain separate release evidence.
