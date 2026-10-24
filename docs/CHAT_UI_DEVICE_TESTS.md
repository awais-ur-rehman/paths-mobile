# Chat redesign Android test

Branch: `feature/logo-refresh`; API branch: `feature/chat-list-search`; contract **1.13.0**. Both remain draft until owner acceptance. Main unchanged. Source commit: `53f6c2c` (chat), with `cd4fa86` (custom controls). Exact APK evidence is recorded in IMPLEMENTATION_STATUS.md. Draft PRs: mobile16, backend19, admin17.

## Prepared local setup

Local Docker API/worker have been rebuilt offline and restarted; PostgreSQL/Valkey volumes, Firebase and R2 configuration were preserved. Three existing demo conversations and private R2 avatars passed authenticated API reads. No new package/SDK installation or environment changes are required on this machine. Retain the existing ignored `paths.push.local.json` and backend `.env.local`; never copy their secrets into chat.

Install the prepared ARM64 debug APK on the same USB-debugging phone. Stop any earlier Flutter run first. These commands retain app data:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Do not uninstall/clear data if installation fails; return the error. The API port remains8080 via USB reverse. Rebuild instructions using the existing offline configuration are in AUTH_UI_DEVICE_TESTS.md.

## Test steps

1. Open Chats on the owner test account. Expect a blue gradient, search field, “Let's Stay Connected”, three real recent demo conversations and a white list. No Chats title or refresh button. Avatar images, preview, time and unread badge should fit; bottom navigation remains light gray.
2. Search one Demo name, then an unknown name. Expect matching rows, then “No conversations found”; the recent row remains available. Quickly edit/clear the query: no old search results should replace newer results. Swipe down to refresh the current search.
3. Open a recent avatar or conversation row. Expect back arrow, image/name and only three dots. Open/dismiss the custom menu; Report member and Report a message should lead to the existing safety flow. Cancel without filing a report unless intentionally testing it.
4. Send a harmless message to a Demo account. Expect a readable outgoing bubble and time, blank-input send disabled, and the existing delivery/retry behavior. Turn off connectivity and try another harmless message: it should show “Not sent · Retry”, then recover on retry after reconnecting. It must not duplicate the intent.
5. Reopen the thread, rotate or use large text/the keyboard, and scroll. Expect no overlap; composer stays above the keyboard, message area ends with rounded lower corners, and the white pill composer remains usable. Older history loads lazily when available. Existing3-row demo fixtures do not exercise20-row paging; that boundary is covered by automated state/API tests.
6. Background/return to the app and navigate back to Chats. Expect current ordering/preview/unread state; no old identity or history after sign-out/account change. A failed history sync offers an inline Retry while retaining existing messages. Earlier-page errors retry the earlier cursor.

Return step number, action, Android version, exact error and a cropped screenshot if anything fails. Exclude credentials, OTPs/tokens, ignored configuration, coordinates, documents and real private messages. No agent-operated device/emulator or iOS build/runtime validation is included. Physical-device layout, touch, keyboard and connectivity acceptance remain pending until these results.
