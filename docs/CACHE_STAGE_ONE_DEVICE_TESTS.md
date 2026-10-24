# Caching stage 1–2 Android retest

Branch: `feature/logo-refresh`, draft mobile PR16. Request scheduler commit `4b09ba4`, own-profile cache `a523fc7`; review fix `7ac2c7f`. Final source to test: `7ac2c7f`. APK SHA-256: `4022179d958dee7275ce849d26f790d96bf6507d950918d9f072ce8c270c7987`. API 1.15.0 unchanged. Backend/admin require no update for this batch.

## Setup and commands

Use the existing local Docker stack/private R2 and configured owner account. Phone internet is required for map tiles; keep the Mac/Docker running. No new installation or dependency resolution is required. Keep app data/session: install over the prior app.

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am force-stop com.paths.mobile
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Configuration is unchanged: local API origin 127.0.0.1:8080, private ignored paths.push.local.json, backend .env.local. Do not paste these files or secrets into reports. No agent operates the phone. No iOS build/runtime acceptance is implied.

## Test steps and expected outcomes

1. Launch while signed in. Expect the single native splash and the correct Home/setup route. Visit Profile once. Initial uncached content may use a skeleton.
2. Return to Home/Likes/Chats/Profile 20 times within 30 seconds. Own profile details should stay available without repeated metadata fetches; overlapping photos share downloads. Scrolling/offscreen work must cancel without cancelling a still-visible copy of the same photo. Images still clear when hidden or the app is paused and reauthorize on return; this batch does not promise instant cached pixels.
3. Remain away from Profile for over 30 seconds, then return. Expect a fresh summary; there should be no endless loader. Pull-to-refresh should request current details immediately even inside the 30-second window.
4. Open settings, edit name/bio and save. Return to Profile and confirm the saved value. Change the avatar if useful; the new image must replace the previous asset. If verification state changes, refresh and check its badge. An older pending request must not restore the old details.
5. Switch among all four tabs roughly 100 times, open peer profiles/galleries and a few chats, scroll quickly, then return. Expect no unexpected API-error toast, crash, stuck loading or mixed profile. Peer metadata/photos continue to reauthorize; private gallery locks must still apply.
6. While photos are loading, sign out. Expect immediate cancellation/normal signed-out route and no previous private image. Reopen/sign back in; verify account details. If you have another test account, switch and confirm no previous-account profile snapshot or photo appears.
7. Temporarily go offline after Profile loads, then pull refresh. The currently displayed own model may remain with its offline handling; failed/denied peer media must not become visible. Reconnect and pull refresh. A cold-start offline app must still validate or show actionable Retry; cached metadata does not authorize sign-in or setup.
8. Background/resume and revisit Profile. Expect a fresh summary check and ordinary permission/tracking behavior. No duplicate splash or lost session should be introduced.

## Return observations

Send failing step number, screen pair, rough time, exact toast/request reference and whether pull refresh recovers. Note whether Profile text appears before the image, and whether switching feels better or worse. Do not share tokens, exact location, message contents or environment files.

For actual performance qualification, record comparable cold/warm first-use and profile/photo readiness, 100 switches, peak memory and Flutter frame timings in a profile/release build. This provided debug APK verifies behavior; its timings are not a release baseline. Existing frame-collection integration support is available for a subsequent owner-run measurement pass. Do not infer Flutter rendering performance from Android gfxinfo alone. After this batch's acceptance, continue the server revision and encrypted own-cache stages under the approved plan.
