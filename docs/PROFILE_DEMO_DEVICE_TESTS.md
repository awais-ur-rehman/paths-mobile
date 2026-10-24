# Profile badges and populated screens

Branch `feature/logo-refresh`, UI source `d257626`; backend fixture source `45d72ab` on `feature/profile-demo-data`. Contract1.12.0 unchanged. Both feature PRs remain draft; main unchanged. Local data has already been applied and read through the running API; no backend rebuild/restart is needed for these records.

## Install and reopen

Use the existing ARM64 phone with USB debugging and the local backend on port8080. Stop an existing Flutter run session first; retain app data:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

If already running, close and reopen Paths or refresh the relevant lists so cached views reload. Use the previously specified owner account; credentials/configuration remain private and unchanged. Do not uninstall or clear data on a signature/version error; return the error. No additional package/SDK/install is required on this prepared machine. Offline reproduction commands remain in docs/AUTH_UI_DEVICE_TESTS.md with the same ignored configuration. No iOS build was run in this pass.

## Checks

1. Confirm the bottom bar surface is light gray#F5F5F5 and distinguishable from the white page. Raised Plus and selected icon/underline remain blue; all tab/camera navigation works.
2. Open your Profile. Expect the existing profile details/photo, a Verified shield/check and two published posts, including an original labelled demo landscape. Tap Verified to see the retained explanation of document-review limits. This account's approval is an explicitly requested local simulation using synthetic TEST IMAGE document cards, not a real identity review.
3. Open Home → Recent. Six Demo profiles/encounter cards are available with image-backed avatars. Open Demo Fern or Tide to see Verified; Demo Dune or another unverified peer shows Unverified with a shield/minus. Badges should be legible on the dark profile surface. No long badge description is added to the profile.
4. In Likes inspect Saved, Incoming, Sent and Connections. The API currently returns6 saved,1 incoming,4 sent-history entries and3 connections. Existing history was preserved; one new outgoing request is pending. Try a normal test request action if desired; re-running the seed will not reopen a request you close or restore a disconnected relationship.
5. Open Chats. Three existing demo conversations have two labelled sample messages each. Open a conversation and confirm both bubble directions and image-backed peer avatars. These are fixed UI examples; demo accounts do not auto-reply.
6. Open Notifications and review updates. Eight in-app notifications and one review update were available at verification. Notifications do not imply push delivery; the seed schedules no push/email. Open events and confirm normal profile/review navigation.
7. Check your own and connected demo profile post images. Private posts on unconnected peers remain hidden under the existing privacy rules. The illustrations are explicitly labelled demo artwork, not actual people.
8. With large text or TalkBack enabled, verify the badge labels and controls remain readable. Pending/declined statuses retain distinct labels; unverified does not mean unsafe. Native Android appearance/accessibility remains this manual check.

Nearby still uses the phone's actual permission/fresh fix and radius. Demo encounters use a synthetic coarse area; the seed did not enable sharing, move your location or create GPS samples. Use Recent for the populated encounter fixture view.

If anything fails, return the step, active screen, exact action/error, Android version and a cropped screenshot. Do not include credentials, OTPs/tokens, private configuration, exact coordinates, identity documents or real private messages.

## Local evidence

- 330 Flutter tests passed without golden updates; analyzer clean; badge/nav/profile fixtures visually inspected; icon export deterministic.
- Offline ARM64 APK built in1m9s:274 tasks,24 executed/250 up-to-date. Kernel/compiler/APK match:76,165,824 bytes, SHA256 `431dfbff8dcb3beb4d295e430c5b07c77d44d9495cd4014a0ca112501a5a4915`.
- APK SHA256 `8a52e7e55d1fa8e2254b25e70f8a9d022e9c43886e0262c74a41dd472461f74e`. Badge labels/vector geometry compiled into this APK.
- Backend:220 integration,56 unit,13 feasibility and4 metrics passed; build/lint passed. Authenticated fixture reads decoded12 images; anonymous avatar401. Existing profile/consent fingerprint matched before/after. Temporary verifier session removed in finally.
- Full scope/limitations and guarded repeatable seed: backend docs/UI_DEMO_DATA.md. No phone/emulator operation or iOS build; existing backend performance qualification is unaffected.
