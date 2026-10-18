# Task14: provider authentication

Status: owner confirmed Google sign-in worked on physical Android. Apple/iOS setup and validation remain pending. New navigation/location fixes require the focused walkthrough in `docs/NAVIGATION_LOCATION_DEVICE_TESTS.md`. Test `feature/provider-auth` in all three repositories, at the exact commit hashes listed in `docs/IMPLEMENTATION_STATUS.md` and the phase report. Main is unchanged. Task13 capacity qualification remains open despite its authorized development merge.

## Prerequisites — configuration, not a test pass

Google Android is configured in the existing `paths-awais` project. Backend metadata reports Google enabled and Apple disabled; its health endpoint reports API1.12.0. The External OAuth app remains in Testing, with `awaisjarral37@gmail.com` saved as the test user and only OpenID/email/profile scopes. Apple and Google iOS setup remain pending. Email sign-in remains available.

## Current Android phone test — 2026-10-18

Use `feature/provider-auth`; the setup commit is identified in the handoff report. The already-built APK uses `http://127.0.0.1:8080` plus the existing ignored push options. No new install/setup prerequisite is known for this Android test: the registered debug certificate matches the actual APK, and the local API/worker are healthy. Google changes can take five minutes to several hours to propagate according to the console.

From `paths-mobile`, the owner runs (the agent does not operate the phone):

```sh
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter run -d 13111JEC204217 --no-pub --use-application-binary=build/app/outputs/apk/debug/app-debug.apk
```

1. Open login and tap Google. Cancel once, then retry. Expect one chooser, a quiet cancellation and no new session on cancel.
2. Select `awaisjarral37@gmail.com`. If it already belongs to your email/password Paths account, expect a request to sign in and link; no automatic merge. Sign in by email, open profile menu → Sign-in methods, then reauthenticate and add Google. Expect the same profile/photos/account. If it is a new account, accept terms and complete the usual age/profile flow.
3. Sign out and use Google again. Expect the same account. Close/reopen Paths and confirm its secure session restores.
4. Disconnect internet and retry Google. Expect a dismissible error with no false success; reconnect and retry. Check that repeated taps do not open multiple choosers.

Return the failed step, timestamp, exact Paths error/reference, whether the chooser opened and whether this was linking or returning sign-in. Do not share ID tokens, authorization codes, secrets or full provider response bodies. Additional Task14 security/accessibility scenarios are below. A second new Google identity requires adding its email to the test audience first; it was not configured during this owner-only setup.

Rebuilt offline:274tasks passed. APK/compiler kernel comparison passed:76,099,904bytes, SHA256 `8e8670be4182ff26f9ab47e0511393a29b7b86b9ca65a13d8043218c8aaf09a0`. APK certificate verification passed. These checks do not prove real provider login; PRs remain draft until owner acceptance.

## Configuration reference for other environments


1. Follow backend `docs/runbooks/provider-auth.md` for Google Web/Android/iOS clients, consent testing users and optional Apple team/key/capability. Use the existing Google Cloud/Firebase project; do not enable billing or Firebase Authentication for this integration.
2. Put backend IDs and the Apple private key only in ignored backend `.env.local`. The backend needs the **Web** client ID as its Google audience, not the Android/iOS ID. Add the Android debug/release public client IDs to backend `GOOGLE_ANDROID_CLIENT_IDS`; the signed native presenter is checked against that explicit allowlist. An Android OAuth client for `com.paths.mobile` must match the certificate actually signing this APK. Use the cached Gradle command below with `:app:signingReport` to inspect certificate fingerprints; those fingerprints are public, the keystore/password is private.
3. Restart the current backend API/worker after configuration, with the existing private volumes and environment; apply migration0019. `/health/ready` must report API1.12.0. Backend instructions cover the offline runtime build; a normal Dockerfile install is not an offline build.
4. For iOS Google, add ignored `ios/Flutter/ProviderAuth.local.xcconfig`:

```xcconfig
PATHS_GOOGLE_IOS_CLIENT_ID=<your public iOS OAuth client ID>
PATHS_GOOGLE_REVERSED_CLIENT_ID=<its reversed client ID URL scheme>
```

Also add the same public ID to ignored `paths.providers.local.json`:

```json
{"PATHS_GOOGLE_IOS_CLIENT_ID":"<same public iOS OAuth client ID>"}
```

The Dart ID must match backend metadata; Google stays hidden on iOS when it is missing/mismatched. Ensure the compiled Info.plist URL scheme matches the iOS OAuth client before testing. Apple needs the Sign in with Apple capability on the registered App ID and a refreshed provisioning profile matching `Runner.entitlements`. The unsigned compile does not verify provisioning or login.

Native Google and Apple SDK packages are now available locally. The only Task14 dependency download performed was the specifically approved GoogleSignIn-iOS9.x Swift dependency graph after the offline build identified it; Dart packages and Android artifacts resolved from caches. No emulator or phone was operated.

## Local checks and build commands

From `paths-mobile` with installed tools:

```sh
flutter --suppress-analytics analyze --no-pub
flutter --suppress-analytics test --no-pub
python3 -m unittest discover -s test/tools
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"
export GRADLE_OFFLINE_BIN="$HOME/.gradle/wrapper/dists/gradle-9.3.1-bin/23ovyewtku6u96viwx3xl3oks/gradle-9.3.1/bin/gradle"
python3 tools/build_android_offline.py --api-origin=http://127.0.0.1:8080 --defines-from-file=paths.push.local.json
python3 tools/check_android_kernel.py --apk build/app/outputs/apk/debug/app-debug.apk
```

The kernel integrity tool compares the actual APK/staged Dart bundle with the compiler output. Use its documented APK path option after building. Do not install an artifact that fails this comparison.

The following commands are **for the owner** after building, with the physical phone connected:

```sh
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
flutter run -d 13111JEC204217 --no-pub --use-application-binary=build/app/outputs/apk/debug/app-debug.apk
```

The offline build helper passes the API origin and local JSON values explicitly to Gradle; running Gradle alone does not preserve Dart defines from a prior Flutter invocation. Omit `--defines-from-file=paths.push.local.json` only if you do not have push configured. Do not share that local file or service credentials. The helper does not print its values. No device launch is performed by the agent.

For an iOS signed build later, pass both your existing API-origin configuration and `--dart-define-from-file=paths.providers.local.json`, use the correct development team/profile and test on an actual iPhone. The cached unsigned compile command is:

```sh
xcodebuild -project ios/Runner.xcodeproj -scheme Runner -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-auth -clonedSourcePackagesDirPath build/ios-auth/SourcePackages -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile -skipPackageUpdates CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

This is a build check only. Android evidence never verifies Apple/native iOS behavior.

## Walkthrough — disposable test accounts only

1. **Disabled configuration:** with provider env blank, open login/signup. Expect email controls and the existing white layout, with no enabled unavailable provider button.
2. **Google cancellation/retry (Android):** configure OAuth and rebuild with the correct certificate registration. Open Sign in with Google, cancel, then try again. Expect quiet return to auth, no new account/session, one chooser per attempt. Repeated taps must not stack dialogs.
3. **New Google account:** select a provider identity not already linked to Paths. Expect a short terms step; no account before explicit acceptance. After Continue, expect the existing adult check, profile/photo and optional verification flow. Verified provider email must not trigger a redundant OTP.
4. **Returning Google account:** finish onboarding, sign out, then use the same Google identity. Expect the same Paths account and normal setup/home routing; repeat after closing/reopening the app to check secure Paths-session restore.
5. **Email collision:** use a Google identity whose email already belongs to a verified email/password Paths account. Expect a sign-in instruction, no automatic merge. Sign into that existing account, finish any existing setup, open profile menu → Sign-in methods → Add sign-in method, reauthenticate and explicitly link. The pending offer lasts five minutes; after expiry, start a new provider attempt from settings. Expect one account and one identity after retry, never a replacement login while adding a method.
6. **Methods/unlink:** add a second supported method, reauthenticate and remove one. Expect last-method removal to be refused. Removing the method that issued the current session can end that session; sign back in with the remaining method. Repeating a used proof must not authorize another operation.
7. **Offline/stale callback:** disconnect before backend exchange/confirmation. Expect an error/retry and no success/navigation. Cancel a provider sheet while its chooser is open or sign out from another active session; a late result must not restore that session. Reconnect and start a fresh attempt.
8. **Apple (configured signed iPhone only):** test Share My Email and Hide My Email, cancellation, first authorization with a name and later authorization without one. Expect stable Paths identity/name and acceptance of the relay address. Test OTP recovery when a provider does not supply a verified email; do not falsify a production provider claim to force this case. Fixture coverage is separate from real evidence. Check actual SMTP delivery to the relay after registering the sender with Apple.
9. **Provider-only deletion:** with a disposable provider-only account, open Delete account, acknowledge permanence, choose the linked provider and confirm. No password is required. Expect immediate access loss, a nonidentifying pending receipt and local cleanup. Never use the owner's primary account for this destructive test.
10. **Apple revocation/outage:** on an isolated staging fixture, temporarily block the provider revocation transport, accept deletion and confirm it stays pending with access blocked. Restore connectivity and run the worker; expect eventual receipt completion and no linked/pending/queued provider credentials. Do not fault the owner's real provider services. Local automated outage/restore tests are not real Apple evidence.
11. Check 200% text, keyboard, screen-reader labels and small display behavior on your phone. Provider branding must remain recognizable and the UI must avoid clipping; success/error toasts should stay dismissible.

If a step fails, return the step number, platform/OS, commit, whether the provider chooser opened, the exact Paths error/reference and whether the account was new/returning/email-collision/provider-only. Share redacted app/backend request IDs and timestamps only. Do not send tokens, codes, private keys, full provider response bodies, real coordinates or private messages. Battery, notifications, field encounters and Task13 load remain separate gates.

## Store gate

Current Apple [guideline4.8](https://developer.apple.com/app-store/review/guidelines/#login-services) requires an equivalent privacy-preserving option for most third-party primary-account login flows, with listed exceptions. Paths intends Google plus Apple; store readiness is pending Apple setup and signed testing. No submission or exception is claimed.
