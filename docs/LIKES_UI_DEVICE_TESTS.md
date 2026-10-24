# Likes UI Android test

Branch: `feature/logo-refresh`. Application source to test: **d7dbf19** (state6c2a2b5, cardsd3f2a6b). Companion local API1.14.0: backend51c0660, evidencea2cff9f. Keep mobilePR16/backend19/admin17 draft until owner acceptance; main is unchanged.

## Prerequisites and configuration

The existing Docker development stack is running at http://127.0.0.1:8080 with PostgreSQL/PostGIS, Valkey, API, worker and proxy. Its image was rebuilt from cached artifacts without downloads. Private R2 and push settings remain in ignored local files; no new keys/installation are required for this test. Android platform tools and a USB-authorized physical device are needed. Do not substitute a stale Flutter output APK; use the checked Gradle output below. No iOS build or runtime validation is claimed.

## Install the prepared APK

Run these yourself; the agent has not operated the phone:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Use the device ID shown by `adb devices` if it has changed. No uninstall/data clear is required. The prepared debug APK uses API_ORIGIN=http://127.0.0.1:8080 through USB reverse and the existing ignored paths.push.local.json; it contains no server-side keys. Rebuilding, only if needed, uses the repository's existing offline Android build workflow; this test does not authorize new dependency downloads.

## Test steps and outcomes

1. Sign in with your existing mobile account and open Likes from the bottom navigation. Expect a white screen, search field, Saved/Requests/Sent/Connected sections and rounded photo cards using the Paths icon family. The gray bottom navigation remains distinct.
2. Saved: expect six existing demo profiles/photos. Search `Demo`, then a displayed username, then a name that does not exist. Expect matching cards and a concise No matches state. Type quickly and switch sections: old results must not reappear under the new query.
3. Select Verified: expect two approved demo profiles in Saved. Reset clears search/filters and restores all saved cards. Search/filters apply across pages, not only already visible cards.
4. Requests: expect the one incoming demo request. Pending only shows actionable unexpired requests. Tap its card: expect the existing member profile and normal request controls. Do not accept/decline unless you want to alter this test data. Return and confirm the section refreshes.
5. Sent: expect four demo records including history; Pending only leaves the one pending request. Connected: expect three demo connections. Pending only is hidden here. Tap a connected card: the normal connected profile/message action remains available.
6. Pull down to refresh; no manual reload icon is present. On a larger real list, scroll toward the end to fetch cursor pages without duplicates; the accessible More profiles action remains a fallback. Existing six-card demo data is not a capacity benchmark. To exercise offline recovery over USB, temporarily remove the reverse rule (`adb -s 13111JEC204217 reverse --remove tcp:8080`), refresh, then restore it with the command above. Expect a visible retry state, retained cards where safe, and Retry refreshing the failed page. Airplane mode alone may leave USB reverse reachable.
7. Open another tab and return; background/resume the app. Expect refreshed current criteria without a stale different-account result. Photos should recover after connectivity returns/pull refresh. Do not upload personal identity documents for this UI test.
8. Increase Android font size and show the search keyboard. Expect readable, scrollable sections/cards without overflow; the four sections may wrap at large text. On normal small-phone text, Connected stays on one line. If an unavailable Saved card exists, removing it must remain removed even if the follow-up refresh is offline.

If something fails, return the step, selected section/filter, redacted message/HTTP status and a screenshot with private names/photos hidden. Never share tokens, passwords, MFA codes/seeds, private chat text or exact coordinates. Automated checks cannot establish native image appearance, touch/keyboard behavior or final physical-device acceptance.

## Local check evidence

372 Flutter tests passed without golden updates in the final full run; analyzer reported no issues. Four320/390px normal/200percent+keyboard snapshots were inspected, and five visual/semantics tests passed.14 Android/tooling checks passed (unchanged Swift endpoint-policy probe intentionally omitted). Backend220 integration/56unit/13feasibility/4metric tests and lint/build passed; admin8 tests/lint/build passed. Whole-change read-only review was followed by reproduced/fixed refresh-retry, confirmed-removal and image-semantics regressions. API1.14.0 exports match all three repositories. Local live search, cursor scope, filters and six private R2 photos passed. Prior Task13 load/native baseline/soak gates remain open; no load qualification is claimed by this UI change.

Final APK SHA256: `45c97a77694ad76cd9611fc24ff3625ccf89be7239adeda13254dd15a413f8d7`. Kernel76,296,656bytes SHA256 `490f6aa7f9ed338fc332577f99d0c589102eeae8271152acf454f2ae67bd8f50`; compiler/staged/APK matched. Offline ARM64 build25s,274tasks(24executed/250cached).
