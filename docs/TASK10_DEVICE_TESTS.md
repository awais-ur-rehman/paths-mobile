# Task 10 device checks

Status: owner accepted Task 10 on their phone on 2026-10-18; this checklist is retained as a test reference. Further development waits for the owner’s full-app retest. Test `feature/safety-controls`: mobile source **cb0d545**, backend **3d21cc0** (plus whitespace/evidence commits), admin **d1b969f**. API 1.9.0. The APK was built from that mobile source; later documentation commits do not change it. Main remains unchanged. Task 11 has not started.

## Setup and commands

The local API/worker are running with migration 0013 and the existing private R2/Gmail/Android Firebase configuration. No new environment variables, packages or installations are needed on this Mac. Keep backend .env.local/.secrets and mobile paths.push.local.json private. The APK includes the existing Android Firebase options and `PATHS_API_ORIGIN=http://127.0.0.1:8080` for USB reverse. Stop any previous Flutter run first.

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
python3 tools/check_android_kernel.py
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter --suppress-analytics --no-version-check run --no-pub -d 13111JEC204217 --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
```

If services need restarting:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-backend
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml -f infra/compose.push.yaml -f infra/compose.r2.yaml up -d --no-build --pull never --wait
```

Prerequisites elsewhere: the pinned Flutter/Android/JDK toolchain, existing dependencies and local backend services/configuration; a signed iOS device build is separate. This handoff uses the already assembled APK, not a command that resolves dependencies. Do not uninstall or clear app storage just to update.

## Test steps

Use adult test accounts and synthetic content. A second account/session lets you confirm bilateral effects; demo profiles do not reply automatically. Do not report real people or delete your account for these tests. Reports submitted here are local test records; staff queue UI arrives in Task 11.

1. Open a visible test profile, then its top-right options. Choose a reason, enter a short optional explanation and Send report. Expect Report received with a reference only after the server acknowledges. Done closes the sheet. The reported account must not become restricted merely because a report was filed.
2. Open a visible peer post and its safety options. Block the member from that sheet, confirm, then submit the post report without closing it. Expect Blocked and a valid report reference; blocked/private post access disappears behind the sheet. If the post was removed or its short-lived evidence expired, expect an explicit Report member instead option, never a false post receipt. Selecting that option changes the report heading before submission.
3. With another connected test account, exchange one synthetic message. Long-press a received message and report it. Expect only that selected message to be attached. From chat options, Report a message opens the message picker; choose one and confirm a report. Own messages cannot be selected as allegations against the peer.
4. Save the pair from both test accounts and, with a chat open, block the peer. Expect both saves removed, requests closed, chat sends unavailable, private images/posts revoked and encounter/profile cards removed after sync. Resume the peer session if it was backgrounded. With no second session available, report that limitation; automated tests cover server bilateral enforcement but do not establish your second-device UI result.
5. Open your own profile options → Blocked accounts. Expect the blocked member listed. Its options still offer reporting a member or a previously received message without unblocking. Select a historical message and submit; expect a persisted reference and no restored chat composer.
6. Unblock and confirm. Expect the row removed. No saved profile, accepted connection or old encounter should reappear automatically. A new connection requires the existing relationship workflow; a new encounter requires new qualifying post-unblock observations. This test does not require collecting real location samples.
7. Turn on airplane mode before submitting a report/block/unblock. Expect an error/retry state, no fake acknowledgment and no successful unblock row removal. Restore connectivity and retry. Report retries with unchanged text must resolve to one server reference. Sign out while a request is pending, then sign in to a different test account: no prior report acknowledgment, blocked list, message or image may appear.
8. Repeat the form and blocked list with larger system text, open the keyboard and scroll. Expect concise white screens, readable controls, the shared dropdown/loader/toast, no clipped actions and working Back/Close when no mutation is pending.

Restricted-account support/appeal/deletion-help and deactivation/reactivation are covered by backend/Flutter tests in this task. Do not deactivate your real account to test them. Staff controls for a temporary test identity will be available in Task 11; self-service erasure is Task 12. No task claims those later screens already exist.

## Evidence and limitations

Return the mobile commit, Android version, step number, exact toast, whether the account was blocked/offline/backgrounded, and whether a second session was available. For failures include only relevant E/flutter lines or request IDs and synthetic screenshots. Never send tokens, .env files, private messages/images or coordinates.

Local checks pass: backend 36 unit + 13 feasibility + 113 integration; live synthetic block/report/replay/unblock/revocation through API/proxy/worker; stack restart; Flutter 250 tests/analyzer, 11 Python tooling tests; admin 2 transport + 3 browser tests/build. Android offline assembly and kernel comparison pass. Unsigned cached iOS build passes; iOS runtime/signing and APNs, actual Android push delivery/tap and Phase 0 field measurements remain separate pending evidence.

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Dart kernel 75,465,832 bytes, SHA256 `1ff51b8bf5c21170448b678985dbefd5d729186885d759f4ffcf166672d1fdf7`. Do not install if the kernel checker fails. Owner authorized the Task 10 merges. Do not start Task 11 until the owner asks after their full-app retest.

Published draft PRs: [backend #12](https://github.com/awais-ur-rehman/paths-backend/pull/12), [mobile #10](https://github.com/awais-ur-rehman/paths-mobile/pull/10), [admin #10](https://github.com/awais-ur-rehman/paths-admin/pull/10). All target development. Feature source and test evidence are pushed; owner Task 10 acceptance remains pending. Main unchanged.
