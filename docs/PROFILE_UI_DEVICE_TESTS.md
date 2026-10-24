# Profile and settings Android test

Branch `feature/logo-refresh`, draft mobilePR16. Test source `7638adf` plus icon commit `3fe019a`. APK hash and full evidence are recorded in IMPLEMENTATION_STATUS.md. Contract1.13.0 unchanged; backend/admin are unchanged for this UI pass. Main is unchanged. Existing local Docker/R2/Firebase configuration and demo records remain available; no setup/download or backend restart is needed.

## Install

Stop an earlier Flutter run first. Use the prepared ARM64 debug APK and retain app data:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
adb -s 13111JEC204217 reverse tcp:8080 tcp:8080
adb -s 13111JEC204217 install -r build/app/outputs/apk/debug/app-debug.apk
adb -s 13111JEC204217 shell am start -n com.paths.mobile/.MainActivity
```

Keep the existing ignored backend `.env.local` and mobile `paths.push.local.json`; no real secrets belong in screenshots/logs. If installation fails, return the exact error without uninstalling or clearing data. Cached offline rebuild instructions remain in AUTH_UI_DEVICE_TESTS.md. No iOS app build or agent-operated device/emulator was used.

## Checks

1. Open your Profile. Your existing approved photo should fill the hero; a gradual blurred/darkened transition begins around its middle. Name and username are centered, Verified/Unverified and Public/Private sit side by side at normal text size. Bio is plain text; no edit/message/connect buttons or invented social counts appear on your own profile. The top-right Settings icon follows the bottom-nav family.
2. Scroll down. Your actual post photos appear in a two-column rounded grid. Tap a photo: existing detail/moderation/deletion behavior remains. Pending/rejected own photos keep their status. Swipe down from the profile top to reload. Empty/offline/private states should be concise and readable. More pages load near the end; failed paging pauses and exposes Retry. The small existing demo fixture may not reach a page boundary; automated tests cover20-row lazy paging and duplicate/error recovery.
3. Open Settings. Expect a separate white page with search, grouped supported destinations and custom icons. Search “privacy”, then an unknown word, then clear: matching rows, “No settings found”, then the original groups. Scroll to account actions. Back should return to your profile.
4. Open Edit profile/Profile privacy, change a harmless bio or visibility value, save, then return to Profile. Expect updated data. Check Verification, Location & permissions, Notifications, Sign-in methods, Blocked accounts and Reviews where available. Delete account must open the existing protected confirmation flow; back out without deleting unless deliberately testing erasure. Sign out remains available if the profile summary cannot load.
5. Open a Demo member from Home or Likes. Expect the same portrait/status/bio/grid composition with a top-right back arrow. Existing relationship status decides whether Connect, Accept, Cancel request or Message appears. A connected member's Message opens the existing chat. Connection options use the custom menu and Disconnect still asks for confirmation. Report remains available below member actions. Private photos require the existing connection rules and must disappear after access is revoked.
6. Try large text, scrolling, background/resume and keyboard/search. Labels may wrap at large text; controls and grid should remain reachable. Return to Chats/Home and confirm navigation still works. Sign out and confirm protected profile/settings routes do not remain accessible. Opening your own ID through a member link should show your own profile, with Settings and no self-connection controls.

Return the step, action, Android version, exact error and a cropped screenshot if anything fails. Exclude credentials, tokens/OTPs, ignored configuration, identity documents, exact coordinates and real private conversations. Physical touch, native blur/GPU smoothness, photo cropping on your own image, platform keyboard and real connectivity behavior remain pending until your results.
