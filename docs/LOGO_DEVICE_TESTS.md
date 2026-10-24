# Open P appearance check

Branch: `feature/logo-refresh`. Approved artwork: **B — Open P**. Implementation commits: `bbc384e` (native/exports), `cc32efd` (Flutter), `70b5c34` (offline cache support). API contract: 1.12.0, unchanged. Main remains unchanged and PRs remain draft until this check.

## Prerequisites

This test APK targets ARM64 (`arm64-v8a`), not 32-bit Android or x86 emulators. Use the existing local Flutter/Android toolchain, cached project dependencies and ignored `paths.push.local.json`. Keep the local Docker backend available at port 8080. Do not share that configuration file or credentials. iOS runtime validation is separate; the selected Xcode iOS 26.5 platform is currently missing.

## Build and run

The ARM64 debug APK has passed its offline build and kernel check. To reproduce it without automatic package/SDK downloads:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS=-Dorg.gradle.java.home=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OFFLINE_BIN=/Users/awaisurrehman/.gradle/wrapper/dists/gradle-9.3.1-bin/23ovyewtku6u96viwx3xl3oks/gradle-9.3.1/bin/gradle
env 'ORG_GRADLE_PROJECT_target-platform=android-arm64' python3 tools/build_android_offline.py --api-origin=http://127.0.0.1:8080 --defines-from-file=paths.push.local.json
python3 tools/check_android_kernel.py --apk build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Stop if the build or kernel check fails. Do not use a previously built APK as evidence for this change. The actual Gradle APK path above is intentional; Flutter's separate outputs/flutter-apk copy can be stale.

## Phone checks

1. Return to the launcher. The app icon should show a single ink Open P on white, fully inside the system mask. If using themed icons, its silhouette should still be complete.
2. Close and reopen Paths. The native splash should show the complete, centered P, followed by the Flutter splash without cropping or stretching. The Flutter splash uses the same symbol.
3. Check the brand header on login/onboarding and profile flows. It should show the P beside the title-case Paths wordmark with no clipped lettering. Existing sign-in/profile behavior should be unchanged.
4. Trigger an ordinary loading action. One traveller should follow the P route; the old crossing/hourglass should be absent. With reduced motion enabled, the loader should remain still.
5. If a tracking/push notification is available, inspect its status-bar icon. It should be a small P silhouette; notification content/permission behavior is unchanged.

If anything fails, return the step, phone/Android version, launcher and light/dark or themed-icon setting, and a screenshot cropped to the affected UI. Build failures: return the first Gradle error and the kernel-check result, with any private config redacted. Never send tokens, exact coordinates, message contents or private configuration files.

Admin appearance: inspect its existing login/header in the local admin portal and browser tab icon. Expect the same P and wordmark. Desktop checks do not establish Android or iOS system-mask appearance.

## Recorded build evidence — 24 October 2026

- Offline ARM64 debug build: 274 tasks, 20 executed / 254 up-to-date, 14 seconds.
- Kernel: 76,129,064 bytes; SHA256 `289b2c75a9a89b01d21055dbdddb169db4b950aa0bf4a2018fae37f6c979341f`.
- APK SHA256 `bb81640aa263ac5044b2c006b5ce8b681704b0fd50a0d0fb0a537c12482873de`. Packaged launcher pixels match the approved PNG; P symbol/splash/notification resources are present; engine ABI is arm64-v8a.
- Stop any existing Flutter run session before installing. Install with `-r` to retain app data. If installation reports a signature/version incompatibility, return that error; do not uninstall or clear app data.

The offline init script optionally uses `~/.gradle/paths-android-maven` for the app module's `io.flutter` artifacts. This machine's cache contains the original vendor POM and exact pinned ARM64 debug engine JAR for `1.0.0-deb287481e3ce9468f3434937ced4240a70539ca`. The HTTPS range download matched Google's published MD5 `WwdEIGFzWTnltgIntaWHsw==`, passed full ZIP CRC checks and has SHA1 `5231e7ca773fc3789c114eca038c7d9a12135db9`. No artifact metadata was invented. Other machines must supply their own valid dependency cache; the script never downloads anything. SDK/plugin included builds are excluded from this optional file repository.
