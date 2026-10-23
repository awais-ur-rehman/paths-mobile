# Open P appearance check

Branch: `feature/logo-refresh`. Approved artwork: **B — Open P**. Implementation commits: `bbc384e` (native/exports), `cc32efd` (Flutter). API contract: 1.12.0, unchanged. Main remains unchanged and PRs remain draft until this check.

## Prerequisites

Use the existing local Flutter/Android toolchain, cached project dependencies and ignored `paths.push.local.json`. Keep the local Docker backend available at port 8080. Do not share that configuration file or credentials. iOS runtime validation is separate; the selected Xcode iOS 26.5 platform is currently missing.

## Build and run

After the recorded Android dependency/cache gate is resolved, build this branch without automatic package/SDK downloads:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS=-Dorg.gradle.java.home=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OFFLINE_BIN=/Users/awaisurrehman/.gradle/wrapper/dists/gradle-9.3.1-bin/23ovyewtku6u96viwx3xl3oks/gradle-9.3.1/bin/gradle
python3 tools/build_android_offline.py --api-origin=http://127.0.0.1:8080 --defines-from-file=paths.push.local.json
python3 tools/check_android_kernel.py --apk build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter run -d 13111JEC204217 --no-pub --use-application-binary=build/app/outputs/apk/debug/app-debug.apk
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
