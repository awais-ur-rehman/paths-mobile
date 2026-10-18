# Task12 owner testing

Status: implemented; automated checks and local builds verified; **awaiting Android device test and owner restore sign-off**. Use `feature/account-erasure` in each repository. Exact review commits are listed in IMPLEMENTATION_STATUS.md and the PR. Main remains the prior baseline. Do not delete your primary account to test this feature.

## Local prerequisites and configuration

Existing Node24, Docker Desktop, Flutter/Android SDK and installed project packages are sufficient. No new dependency is required. The existing local stack is updated, migration0015 applied, R2/Gmail/Firebase configurations preserved, and the erasure journal initialized. Keep backend `.env.local`, `.secrets` and mobile `paths.push.local.json` private. Deletion needs the four DELETION_* settings documented in `.env.example`; existing private values are configured. APNs runtime and deployment/backup redundancy remain separate prerequisites.

Admin: from paths-admin, `npm run dev`, then open http://127.0.0.1:5173 . Test admin email: `test-admin@paths.example.invalid`. Read its password from backend `.secrets/test-admin-login.local.json`; enroll the secret in `.secrets/test-admin-mfa.local.json` in your authenticator manually (SHA1, six digits,30seconds). These mode0600 files are ignored. No shared/default password exists. The staff account has an explicit local document-access grant; this does not establish pilot staffing.

Android: from paths-mobile, install the already-built, kernel-verified APK using your own phone:

```sh
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/flutter-apk/app-debug.apk
```

Open Paths on the phone. For a source rebuild with your existing local setup:

```sh
flutter run --no-pub -d 13111JEC204217 --dart-define-from-file=paths.push.local.json --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080
```

Backend services, if stopped (run from paths-backend):

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml -f infra/compose.push.yaml -f infra/compose.r2.yaml up -d --no-build --pull never api worker proxy
```

## Device and browser steps

1. Create a **disposable** member using an email alias you control. Add a synthetic/test photo, post and chat with a second disposable member. Keep an unrelated conversation between the second member and a third member. Do not upload a real CNIC to test deletion.
2. Open Profile options → Delete account. Consent is required. Enter a wrong password: no accepted receipt, no signout or loss of the account. Try offline: no success claim. Restart and use Return to Paths if the previous request is unconfirmed; the recovery proof stays saved for retry. Return to deletion and use the correct password after reconnecting.
3. Confirm permanent deletion. Expect an accepted receipt and immediate access revocation, followed by live-data completion after worker processing. No permanent “Deleted User” chat remains for the other member. Save the opaque receipt if needed; do not share it publicly. Device cleanup errors keep Retry visible and cannot change acceptance into a failure claim.
4. Reopen the app. It resumes the receipt/cleanup, then Done permits returning to sign-in. Deleted credentials cannot sign in. Verify local photo previews, messages and tracking queues are cleared. Check that a later different account keeps its own data. Capture pass/fail for background/resume and app restart as well as foreground.
5. On the counterpart account, reconnect/resume and open Chats: the deleted shared chat/messages disappear; the unrelated conversation remains. Try the deleted member's old media view: access fails. Existing screenshots and delivered notifications remain outside the erasure guarantee, as disclosed.
6. Create another disposable member and use http://127.0.0.1:5173/delete-account . No staff login is required. Request the email OTP, check consent, then delete. Wrong/expired code and network failure must never show acceptance. Resend observes the60second cooldown; codes expire after5minutes. Reload after a lost response and Check previous request; the same nonidentifying recovery proof obtains the receipt. A prior pending proof is bound to the original email using a salted hash and cannot delete another email's account. Retry the original email while that request is unresolved; no raw email/code is stored in session storage.
7. Verify restricted/incomplete-setup accounts can reach deletion too. Log into the staff portal using the test admin and confirm queues load after MFA; the public deletion path must not require or send staff cookies.
8. From paths-backend run `npm run deletion:restore-drill` and the inventory command in docs/runbooks/restore.md. Expected drill: passed, deletedUserReferences0, deletedConversationMessages0, unrelatedConversationMessages2, storageObjects0, foreignKeysValidatedtrue, trafficOpenedfalse. Inventory must report remaining0 and overdue0; pending requests may require worker retry. Return the aggregate output and explicit owner acceptance of this restore evidence. Do not open the restored DB to traffic.

## What to return

Step numbers/pass or fail, Android model/OS, branch and commit, approximate failure time, exact visible error and a redacted request ID if available. For backup checks return only the aggregate JSON, not SQL, storage keys or manifests. Never paste `.env.local`, passwords, OTPs, MFA secrets, tokens, real documents/messages or exact coordinates. iOS compiled unsigned successfully; iOS runtime/APNs delivery is not verified by Android tests.
