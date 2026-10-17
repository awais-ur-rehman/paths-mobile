# Profile UI retest

Test source `b5e09ac` or the latest documentation-only `feature/encounter-discovery` head in the mobile repository, draft PR6. This is a Task6 device-feedback update; Task6 remains open for its separate Home/map/matching checklist. No backend/admin contract change or new dependency is needed.

## Run on your Android phone

Keep the existing local backend running. From paths-mobile:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"
adb -s <physical-phone-id> reverse tcp:8080 tcp:8080
/Users/awaisurrehman/Documents/flutter_sdk/flutter/bin/flutter run --no-pub -d <physical-phone-id> -t lib/main.dart --dart-define-from-file=config/development.example.json
```

Use existing packages, SDKs and the already pinned map dependency. Only the owner operates the phone. No real CNIC, photos or credentials are needed. Existing support/policy configuration and Gmail/R2 plans are unchanged.

## Steps and expected outcomes

1. Enter profile creation. Expect white background, basic fields, a visibility toggle and one **Next** button. No Save details, Save and continue, View profile or Sign out controls. Tap Next with missing/invalid fields: validation stays on the form. Complete valid details and tap Next: one save completes before Verification opens. A failed save must keep edits and show a concise error; retry must not navigate before success.
2. Open Gender. Expect an anchored white menu using the app's borders/corners/selection mark. Choose a value, reopen to check selection, then dismiss outside or with Android Back. The form and other edits remain intact. Private/Public toggling changes only the label and switch; no description paragraph appears. Repeat with the keyboard open and large text200%.
3. Verification shows its heading, one short line, two side-by-side dotted slots labeled CNIC front/back with icons, Submit for review and Skip. Both slots and Submit are disabled until the actual media adapter and backend are ready. Tapping them must not request document access or pretend to upload. Skip persists and opens your profile. Pulling down refreshes real status; it does not invent a review. Consent/retention details remain available only when real uploads are enabled in a later task.
4. Your profile follows the reference's cover, centered identity and framed bio. Current accounts show a neutral No photo yet cover until Task8; no stock member photo, fabricated gallery, follower counts or Follow button. Edit profile is the primary action. Change details and Save: return only after successful persistence. Open Profile options for Verification, Location & permissions and Sign out. Controls remain at the top and available during summary loading/errors; body content scrolls at200% text.
5. If an eligible encounter is available, open its peer profile from Home. Expect the same cover/identity/bio layout with Close and no unsupported actions. Back returns to Home with filters intact. Existing authorization/unavailable behavior remains. Sign out from your own options and confirm the old account's profile/discovery UI is cleared.

Return the commit, phone/Android version and numbered pass/fail. If something fails, provide a screenshot or sanitized crash/request ID and the action immediately before it. Omit tokens, OTPs, DOB, exact coordinates and real documents. Unsigned iOS compilation is separate evidence; signed iOS rendering, gestures, permissions and background behavior remain unverified.
