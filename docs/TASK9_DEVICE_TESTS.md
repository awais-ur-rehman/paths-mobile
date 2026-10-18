# Task 9 device checks

Status: awaiting owner evidence. All repositories use `feature/text-chat`, targeting `development`; leave Task 9 PRs draft until accepted. Mobile source `e3393cc`, backend source `17a076c`, admin source `acf827c`; later documentation commits do not change the app. API 1.8.0. Existing R2 image acceptance is recorded and its PRs are merged; Task 10 has not begun.

## Available setup

The backend API/worker are already running locally with migrations 0011/0012, R2, Gmail and Android FCM configuration retained. The APK below was assembled offline and passed the compiler/kernel comparison. No installation or new environment secret is required for this existing USB setup. Stop any prior Flutter run first; hot reload cannot add the native message push kind.

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
python3 tools/check_android_kernel.py
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter --suppress-analytics --no-version-check run --no-pub -d 13111JEC204217 --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
```

To restart the existing backend if needed:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-backend
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml -f infra/compose.push.yaml -f infra/compose.r2.yaml up -d --no-build --pull never --wait
```

The local development image is already built. For a fresh rebuild elsewhere, package installation and the normal Docker build need the pinned dependencies/base images; do not copy private local configuration into an image. Required private environment stays in ignored backend .env.local and .secrets; public mobile configuration is API origin (debug USB loopback) and optional Firebase app options in ignored paths.push.local.json. Do not share either private file. This task adds no new configuration keys or paid service.

## Numbered checks

Use synthetic text and two adult test accounts with an accepted connection. Existing explicitly requested connected demo profiles may appear in Chats with empty history; they do not reply automatically. Use a second physical device/session for the peer, or keep that two-device gate pending if unavailable. A second Android device needs its own adb reverse for 8080 and the same verified APK; use the actual ID from adb devices. Signing/live iOS is a separate prerequisite.

1. Open Chats. Expect connected peers with concise names/last-message previews and unread badges. Open a connected peer from its profile using Message; Back returns normally. Pending/unaccepted connections must not offer an enabled conversation send action.
2. Send a short synthetic message from A to B. Expect one pending bubble followed by one committed bubble; B receives one message and an unread badge when its thread is closed. Open B's thread: unread clears privately; no public read receipt/typing indicator appears.
3. Send enough short messages to exercise older history (over 50, spread out across multiple minutes to respect 30/minute per connection). Scroll to older messages, return and reopen. Expect correct order, no missing/duplicate messages and retained history. Empty and 4,001-character messages cannot send.
4. On B enable airplane mode. Send from A while B is offline. On B try a message: expect a failed bubble with Retry, never a fake successful ACK. Restore connectivity and retry. Expect missed messages recovered in order, and the retried intent inserted once even after repeated Retry. Close/background B during this cycle, resume and repeat.
5. With a second conversation available, open it over the first using a notification (when configured) or normal navigation. New messages in the covered conversation must remain unread until actually opened; switching apps must not mark hidden messages read. Automated coverage already checks the stacked-route case; live push tapping remains separate pending evidence if not configured.
6. Disconnect the pair from profile actions. Expect retained history with Connection ended and no composer on both clients after sync. A previously queued send must fail. Reconnect only through the documented relationship workflow/cooldown; disconnect does not silently reconnect.
7. Sign out while a request is in flight and sign in as a different test account. Expect no previous conversation, pending bubble, draft or content to appear. Force-close/reopen and confirm the correct account's history reloads.
8. Deletion/revocation cache behavior is covered by isolated backend/Flutter tests. Do not delete your real account for this check. Blocking/reporting UI is Task 10; test it later through its own workflow. Android FCM permissions/delivery/tap and APNs setup remain tracked independently; no real-delivery claim is made here.

Expected: white screens, concise controls, existing Paths loader/toasts, no overflow with larger system text and no stuck loading after retry/resume. Offline pending messages live only in memory; force-closing may discard an unsent draft, while committed messages reload from the server.

Return: mobile source commit, Android version, failing step, whether A or B was offline/foreground, exact toast and whether the bubble was Sending/Not sent/committed. Include only relevant E/flutter/request IDs or a synthetic screenshot. Never send bearer tokens, environment files, private text/images or coordinates. Report a missing second device/session explicitly; that leaves the recovery gate pending rather than passed.

## Local evidence

Backend 36 unit + 13 feasibility + 101 isolated integration pass. Live synthetic proxy/worker/socket/idempotent retry/history/read/disconnect check passes. Flutter 231 tests, analyzer and 11 Python tooling tests pass. Admin 2 transport / 3 browser cases and build pass. Android 235-task offline assembly and kernel comparison pass; unsigned cached iOS build passes. These are code/runtime checks, not physical-device acceptance. Full results/checklist are in IMPLEMENTATION_STATUS.md.

Draft PRs: [backend #11](https://github.com/awais-ur-rehman/paths-backend/pull/11), [mobile #9](https://github.com/awais-ur-rehman/paths-mobile/pull/9), [admin #9](https://github.com/awais-ur-rehman/paths-admin/pull/9). Final APK kernel 75,364,960 bytes, SHA256 93661a7b09d6b1ba5ee3d609842a575c5099fd54656c7ee756a12e9d83d88394.
