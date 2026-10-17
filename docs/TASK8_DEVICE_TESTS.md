# Task8 Android device checks

Status: implemented and locally checked; physical Android evidence pending. Branch `feature/protected-media` in all three repositories. Main is unchanged. API1.7.0. Source checkpoints: backend e1a5a86 (media fixes6399af6, quota f46a3ef); mobile8670cbb (uploads2ae4c8b, screens14dd691); admin67af1e5. Later commits record evidence/docs only.

## Setup already available locally

Use the existing Flutter/Android/JDK21, Node24, Docker and resolved project packages. Task8 dependencies and Android/Linux artifacts are resolved. Private local filesystem storage is selected; owner deferred R2 setup. Firebase/APNs are not needed for these checks. Gmail uses existing ignored local configuration. iOS runtime testing is separate.

Backend terminal:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-backend
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml build --pull=false
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml up -d --no-build --pull never
npm run build
node --env-file=.env.local dist/scripts/verify-media.js
```

The verifier creates only its synthetic account/images, checks the real proxy/API/outbox/worker, then erases that account and its external objects. Expected: two `Verified ...` lines. Existing accounts/volumes remain. The test overlay exposes PostgreSQL/Valkey on loopback only.

Required private environment: existing `.env.local` generated in earlier tasks, stable64-hex `AUTH_KEY`, `POSTGRES_PASSWORD`, `DATABASE_URL`, `REDIS_URL`. Set `MEDIA_PROVIDER=filesystem`; Compose mounts `MEDIA_ROOT=/data/media`. An empty `MEDIA_KEY` derives a distinct development media key from AUTH_KEY. Keep that key stable. R2 later requires its own stable64-hex `MEDIA_KEY`, account ID, private bucket and S3 access/secret keys. No credentials belong in mobile configuration.

Mobile terminal, with USB debugging enabled and the phone connected:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
flutter --suppress-analytics --no-version-check pub get --offline
adb devices
adb reverse tcp:8080 tcp:8080
flutter --suppress-analytics --no-version-check run --no-pub -d <ANDROID_DEVICE_ID> --dart-define=PATHS_API_ORIGIN=http://127.0.0.1:8080
```

Replace `<ANDROID_DEVICE_ID>` with the connected phone ID. Use your existing test login. If creating a new local account with Mailpit configured, read its OTP at http://127.0.0.1:8025. No SDK/emulator installation is part of this handoff.

Copy the three original synthetic PNG cards from `docs/testing/media/` to your phone using your usual file transfer. Their editable SVGs and generator live in paths-backend. Use these cards for uploads; for Camera photograph one of the test cards displayed on another screen or printed paper.

## Numbered tests

1. **Profile photo:** open profile setup/edit, Add/Change photo → Gallery → profile.png. Inspect the preview, then Use photo. Wait for processing and save with Next during creation (Save during editing). Expected: one primary form action; persisted details, neutral profile image labelled Photo in review. Reopen editing to inspect your own staged photo. Public display awaits the Task11 staff-review workflow.
2. **Verification:** select `cnic-front.png` and `cnic-back.png`, inspect each preview, Use photo, accept review consent, Submit for review. Expected: pending status survives reopening; no public document link or download. Front is required, back optional. Skip remains available. Submitted/replaced/declined records remain until account erasure; use the supplied synthetic cards throughout.
3. **Camera navigation:** from Home, Likes and Profile, tap Camera. Open Camera, cancel the OS picker, then close the composer. Expected: return to the originating tab with no post. OS camera permission behavior depends on the camera activity; permission denial/cancellation must leave Gallery usable.
4. **Post:** Camera → Gallery → profile.png, enter a short caption and Post. Expected: processing completes, Profile opens with exactly one In review post. Open it to inspect your private preview/caption. Refresh and restart: it persists. No new public post appears before staff approval.
5. **Offline/retry:** select a new image, disable Wi-Fi/mobile data before submitting. Expected: an error toast, retained draft and Retry. Restore the connection and Retry. Expected: one post, no duplicate intent/publication. Repeat by interrupting an upload; processing may finish on the server and Retry must recover its status.
6. **Discard:** choose a photo, close while previewing or uploading, and confirm Discard. Expected: return to the original screen, no post created. If cancellation cannot reach the server, an error is shown and the unattached upload is cleaned by its bounded retention policy. After cancelling, sign out from Profile and sign into another synthetic account: no previous photo draft, decoded image or post is displayed.
7. **Permissions/source errors:** deny access if Android offers a permission prompt, or cancel the system photo picker/camera. Expected: concise recovery, no repeated automatic prompts, Gallery/Camera remain selectable. Android's system photo picker can work without broad library permission.
8. **Process loss:** force-stop Paths while the system picker is open, then relaunch with the same command. Expected: interrupted selections are discarded; the app does not restore a previous CNIC draft or upload it automatically. Select a fresh image and confirm the flow still works.
9. **Post deletion:** delete your synthetic post, confirm, refresh and restart. Expected: it stays absent. The backend retains deletion inventory until object deletion is acknowledged. Automated tests cover privacy/disconnect/block/deleting-account revocation; the device UI clears and revalidates posts immediately after Disconnect.

Return the failing step, Android version, branch/source checkpoint, exact toast, approximate time and network state. Include a screenshot of the synthetic test UI if helpful. If needed, return only redacted event lines from `docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml logs --tail=60 api worker`; exclude environment files, credentials and private content.

## Separate pending evidence

Owner Android results are required before Task8 completion/merge or Task9. The unsigned iOS compile does not verify camera permissions, native file cleanup, UI or device behavior on iOS. Real R2 credentials/bucket checks, Firebase/APNs live delivery, signed iOS runtime and quantitative Phase0 field evidence remain recorded prerequisites. Task11 owns real staff review/approval/appeals; these builds never auto-approve real uploads.
