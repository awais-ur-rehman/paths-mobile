# Startup, profile refresh and demo photo retest

Source: `feature/logo-refresh`, startup `f5d3406`, profile `1cf7875`. Backend: `feature/chat-list-search`, concurrency `1008c36`, fixtures `e4e19be`. API contract 1.15.0 remains unchanged. These changes stay in draft pending owner Android testing; no main promotion.

## Setup

The local Docker API/worker are running with existing PostgreSQL/Valkey and private Cloudflare R2. Keep the Mac and Docker running. Phone internet is required for OpenFreeMap tiles; USB reverse forwards only the local API. No new installation is required if the previous Android setup still works. Do not clear app data or uninstall: preserve your current session for the returning-user test.

The new offline ARM64 debug APK is `build/app/outputs/apk/debug/app-debug.apk`. SHA-256: `d3606863b9d9f72aa3607d985ad6f24594b88eb6dd87493b88e72a3b12c87d79`.

Run on the Mac:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am force-stop com.paths.mobile
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Only public app configuration is built in; existing private backend `.env.local` remains local. To rebuild with existing cached tooling, use the documented offline builder with `--api-origin=http://127.0.0.1:8080 --defines-from-file=paths.push.local.json`. No credentials belong in commands, screenshots or reports.

## Check on the phone

1. Cold-open while already signed in. Expect one native Paths splash, then Home after session/setup validation. There should be no second logo screen with a spinner. An incomplete/restricted account must still reach its appropriate setup/restriction route.
2. Open Profile and pull to refresh. First uncached load may show a skeleton; subsequent refresh keeps the existing profile/photo visible. Visit settings, edit a profile detail, save and return; expect the confirmed value, not the old profile.
3. Switch Home → Likes → Chats → Profile repeatedly, including roughly 100 transitions. Open a few peer profiles and chats along the way. Expect responsive navigation with no unexpected API-error toast, crash or stale previous-account content. This remains a device measurement, not a claim established by widget tests.
4. Background and resume several times. Expect no session reset or successful-resume purge that stops active sharing. Private decoded images still clear when hidden/paused under the existing privacy policy, so a later resume may reload them until the proposed own-avatar cache is implemented.
5. On Home choose Recent and fit encounter history. Expect sample avatars in multiple Islamabad areas and two Mirpur, Azad Kashmir areas. Nearby intentionally limits results around your confirmed current position, so it may exclude those historical fixtures. Open demo profiles and inspect galleries; private galleries retain normal connection rules.
6. Sign out and reopen. Expect the usual signed-out flow after one splash. Sign back in; confirm the correct account and setup state. Never show another account's cached private image or profile.
7. Optional outage check: stop network access temporarily or make the API unavailable, then cold-open. Expect an actionable error/Retry once validation fails, not an endless native splash. Restore connectivity, retry and confirm normal routing. No offline map guarantee; uncached tiles require internet.

If a step fails, return the step number, approximate time, route/screen, exact toast text and safe request reference if shown. For startup, note whether the native logo stays visible or a Flutter loader appears. For switching, note the two screens involved and whether a refresh recovers. Do not send tokens, `.env` files, exact coordinates or private messages. Android testing does not verify iOS; no iOS build was run for this change.
