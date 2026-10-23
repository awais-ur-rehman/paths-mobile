# Authentication UI phone check

Branch: `feature/logo-refresh`. Test source: `0385c34`, including shared forms at `06858ef`. Draft mobile PR16 targets development. API contract1.12.0 is unchanged. Main remains unchanged pending owner acceptance. The owner accepted the Open P direction; this check covers its centered-symbol auth layout and forms.

## Prerequisites and configuration

Use the existing ARM64 Android phone and locally running Docker backend on port8080. Keep the ignored `paths.push.local.json` private. The APK uses `http://127.0.0.1:8080` through USB reverse forwarding and existing Firebase/provider configuration. No new environment key, package, SDK or install is required on this prepared machine. Another machine needs the project's pinned Flutter/Android/JDK/Gradle dependencies cached before offline reproduction. iOS compilation is deliberately excluded from this pass at the owner's request; iOS runtime validation remains separate.

## Install the tested APK

Stop any existing Flutter run session first. These commands retain app data:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Use this Gradle APK path; Flutter's separate `outputs/flutter-apk` copy can be stale. If installation reports incompatible signatures or versions, return the exact error instead of uninstalling or clearing app data.

To reproduce the ARM64 build without package resolution or SDK downloads:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS=-Dorg.gradle.java.home=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OFFLINE_BIN=/Users/awaisurrehman/.gradle/wrapper/dists/gradle-9.3.1-bin/23ovyewtku6u96viwx3xl3oks/gradle-9.3.1/bin/gradle
env 'ORG_GRADLE_PROJECT_target-platform=android-arm64' python3 tools/build_android_offline.py --api-origin=http://127.0.0.1:8080 --defines-from-file=paths.push.local.json
python3 tools/check_android_kernel.py --apk build/app/outputs/apk/debug/app-debug.apk
```

## Test steps and expected outcomes

1. If already signed in, use Settings → Sign out. Login shows only the centered P, a short centered heading/description, rounded email/password fields, reveal control, black Login button and blue links. There is no Paths wordmark. Google is a circular button; unavailable providers remain hidden. Apple remains deferred until configured.
2. Enter an invalid email or leave fields empty and submit. Inline validation appears without navigation. Reveal/hide the password; it retains the typed value and does not submit. Log in with a real test account, then sign out again.
3. Open Sign up. Enter name/email/password and a different confirmation. After checking Terms/Privacy consent, submit. The confirmation error appears and no signup email/request is sent. Correct the confirmation. Password and confirmation reveal independently. Open Terms/Privacy and return: typed values remain, and viewing a policy does not automatically check consent.
4. Complete signup with a fresh test email, paste the OTP, enter an adult birth date and continue through profile setup. Existing eligibility, photo, profile Next and optional verification behavior should work. The consistent P/header, pill fields and buttons should remain intact. Do not upload real identity documents for this appearance test.
5. From Login, open Forgot Password. Request a code for your test account, enter the OTP and set matching new passwords. Recovery still uses codes, despite the reference image describing a link. Confirm the new password works and an old session is rejected as before.
6. Tap Google, cancel the account chooser, then try again and sign in. The control should recover after cancellation; repeated taps should not open duplicate sheets. Existing linked/new-account provider flows retain their setup/consent requirements.
7. Enable large system text and open the keyboard on Login, Sign up, Forgot Password and reset. Scroll to each action: no overflow, cut-off field labels or unreachable controls. In particular, Confirm password must remain readable. Restore your usual text size afterward.
8. Reopen Paths after a successful login. Its existing secure-session restore should continue to work. This UI pass adds no Remember me mode.

If a step fails, return its number, screen/action, exact visible error, Android version and a screenshot of the affected UI. For build/install failures include the first error and kernel-check result. Redact email addresses as desired; never send passwords, OTPs, tokens, private config files, exact locations, private messages or identity images.

Automated tests cannot establish physical keyboard/autofill, OS account-picker rendering or native provider success on this phone. Those remain the owner's checks above.

## Recorded local evidence

- Final source `0385c34`:311 Flutter tests passed without golden updates; analyzer clean;15 tooling tests passed.
- Offline ARM64 build passed in21s (274 tasks:24 executed/250 up-to-date).
- Kernel/compiler/APK comparison passed:76,139,616 bytes, SHA256 `71400d110aeff05161b55df10a46901aedccb8648c4a73e0892c2edcf9647ad2`.
- APK SHA256 `6775dba6ffb0c81abf8309ef853e304a1d51d93610bae8bd8a27b45955728419`. New round Google PNG matches source bytes; old pill asset absent; new auth copy compiled; engine ARM64 only.
- Existing backend `/health/ready`:ok, contract1.12.0. No iOS build, emulator or physical-device operation performed.
