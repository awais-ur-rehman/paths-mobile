# Task 11 owner testing

Branch in all repositories: `feature/admin-review`. API contract: 1.10.0. Main and development are unchanged for this task. Test the implementation commits and final status commit shown in each draft PR; do not merge until this gate is accepted.

## Local setup already prepared

The local stack has migration 0014, private R2 storage and the existing push configuration. No hosting was deployed. A private database snapshot was retained at backend `.secrets/task11-before-migration.sql`; it is not committed. Do not remove storage recovery volumes.

Staff sign-in is separate from member sign-in. Local owner staff email: `awaisjarral37@gmail.com`. Open backend `.secrets/staff-login.local.json` locally for its generated password and `.secrets/staff-mfa.local.json` for manual enrollment in your TOTP authenticator (SHA1, six digits, 30 seconds). Do not paste these files, passwords, authenticator secrets or screenshots into chat. They are ignored and mode 0600. Initial admin has no CNIC permission: grant it explicitly through Staff if testing verification, then sign in again using a fresh code. Role/grant changes revoke all that staff member’s sessions.

Required manual prerequisite: a TOTP authenticator. Existing packages, SDKs and Docker images suffice; no additional installation is needed for the commands below. APNs runtime setup is still unavailable. Firebase delivery is a separate pending release check; inbox updates can be tested independently.

From paths-backend:

```sh
docker compose --env-file .env.local -f infra/compose.yaml -f infra/compose.test.yaml -f infra/compose.push.yaml -f infra/compose.r2.yaml up -d --no-build --pull never --wait
```

Backend `.env.local` now has `ADMIN_ORIGIN=http://127.0.0.1:5173` and `ADMIN_ALLOW_LOCAL_HTTP=true`. This exception accepts only a loopback origin. Use the exact URL below; `localhost` is a different origin. A future deployed origin must use HTTPS and disable the exception. Keep the existing R2, SMTP, AUTH_KEY and push settings private.

From paths-admin:

```sh
npm run dev -- --port 5173 --strictPort
```

Open http://127.0.0.1:5173. Browser uses same-origin cookie requests through Vite. No staff tokens belong in localStorage. Password is followed by the authenticator code. A code is single-use; wait for the next time step if it was just used. Idle timeout is 15 minutes; absolute timeout is eight hours.

From paths-mobile, on your physical Android phone (you run these):

```sh
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
python3 - <<'PYCODE'
import json, os
from pathlib import Path
value=json.loads(Path('paths.push.local.json').read_text())
value['PATHS_API_ORIGIN']='http://127.0.0.1:8080'
path=Path('/tmp/paths-task11-phone.local.json')
path.write_text(json.dumps(value));path.chmod(0o600)
PYCODE
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter --suppress-analytics --no-version-check run --no-pub -d 13111JEC204217 --dart-define-from-file=/tmp/paths-task11-phone.local.json
```

The APK compiled offline and its kernel was checked. No emulator or phone was operated by the agent. Unsigned iOS compilation passed; this proves compilation only.

## Test steps and expected outcomes

1. Sign in to the staff portal. Incorrect MFA fails; valid MFA opens only the permitted queues. Sign out and confirm Back cannot restore the workspace. Verify narrow browser width and keyboard Tab/Escape access.
2. On the phone use a disposable test member and the generated `docs/testing/media/profile.png`, `cnic-front.png`, `cnic-back.png` cards. Do not submit real CNIC data. Upload a photo/post: it remains pending until reviewed. In Images, claim it, explicitly open it, add a reason and approve. Refresh/return on the phone: approved media appears. A rejection shows a reason under Profile → Reviews; Appeal submits that exact rejected version.
3. Grant your staff account CNIC permission explicitly and sign in again. Submit the generated cards from the disposable member. Claim its verification, open front/back explicitly, and approve/decline with a reason. Images must not preload. Closing or hiding the tab removes the in-memory image; no download control is offered. The phone’s Reviews page receives the result and returning/resuming refreshes verification state. An earlier approved badge survives a pending replacement.
4. Edit the disposable member bio to a quoted phrase containing `kill you`. Saving is filtered. Tap Request review, explain the context, and submit once. In Appeals approve that exact text. Return to the editor and retry saving the same text: it succeeds; changed filtered text still requires review. Repeat in a post caption and an active chat; message approval applies only to that conversation. Empty reasons cannot submit. Retry after an interrupted request must not create duplicates.
5. Use a second provisioned reviewer (see provisioning below) on the same pending verification/image. Only one active claim succeeds. After ten minutes an expired claim can be replaced; the first reviewer’s stale decision fails. A changed item must show a conflict and refresh, never a success message. An image appeal created before a subsequent moderation removal cannot reverse that removal.
6. Report a demo post or one selected message. Reports contains only submitted evidence, never a general private-message browser. Try dismiss/warn/remove post on disposable content. Confirm a reason is required, the reporter receives a generic outcome, and removed content disappears after revalidation. Use a disposable member for deactivate/reactivate; restriction revokes member sessions/tracking and old queued notifications remain suppressed. Reactivation requires a new member sign-in.
7. Change/revoke a disposable staff role and refresh its old browser tab: it must sign out and clear private content. Moderator has no CNIC access; administrator without the explicit grant also has none. The last enabled administrator cannot be disabled/demoted. Changes require MFA within five minutes; sign in again if prompted. Audit shows action/staff/time without copied personal content.
8. Disconnect the network while a queue, image or appeal request is loading. No decision may claim success. Reconnect and Retry/Refresh. Background/resume the phone and return from Reviews: profile/verification refresh without clearing an active document upload. Review inbox bodies and push payloads stay generic. Disable Review updates in notification settings and confirm future review push delivery is suppressed; in-app updates remain available.

Record pass/fail by step, Android model/OS, branch and commit, browser/version, visible message, approximate test time and a redacted request ID if shown. Return screenshots only without personal documents/messages, secrets or coordinates. Do not paste private config or full network headers. iOS runtime, actual push delivery and pilot staffing are separate pending checks.

## Provision another local staff account

Create a new ignored mode-0600 JSON file with email, a unique password of 12–128 characters, role (`reviewer`, `moderator`, `admin`) and boolean `documentAccess`. Moderator cannot have documentAccess. Run from backend:

```sh
node --env-file=.env.local dist/scripts/provision-staff.js .secrets/second-staff.local.json .secrets/second-staff-mfa.local.json
```

The enrollment output must not already exist. Import it manually into the staff authenticator. Trusted local recovery uses the same command with a new output path and `--reset-mfa`; this rotates password/MFA and revokes sessions, without silently changing role/enabled state. Keep credential backups outside Git and remove enrollment copies after secure backup/import. There is no public staff signup.

## Pilot gate

Before inviting a pilot, name the people covering verification, image safety and urgent report review, assign least-privilege accounts and an explicit document grant where needed, agree review hours/escalation coverage, and confirm the queues are actively staffed. No staffing coverage or response-time commitment is claimed by the implementation. Task 11 remains pending owner acceptance and this operational prerequisite. Task 12 has not started.
