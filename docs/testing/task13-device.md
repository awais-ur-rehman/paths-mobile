# Task 13 owner tests

Use `feature/pilot-hardening` after pulling the published Task 13 branch in all three repositories. Exact tested commits and PRs are in task13-evidence.md. Task 12 is merged; main is unchanged. Do not start Task 14 until these gates are resolved.

## Prerequisites and private configuration

Use the existing Flutter/Android/ADB setup and a disposable member account with a completed profile. Keep the backend and worker running with the existing private R2/Gmail/Firebase configuration. No new package is required. Keep credentials in ignored local files. Do not share keys, tokens, OTPs, photos or exact coordinates.

Copy `paths.performance.example.json` to `paths.performance.local.json` and set that disposable account's email/password. Retain the enabled flags. Use your existing `paths.push.local.json` for the phone-reachable API origin and push configuration. Profile test credentials are compiled into the test app: use only a disposable account, delete the test binary afterward, and never distribute it.

## 1. Profile-mode journey

1. Run the normal app, sign into the disposable account, enable precise production location sharing and verify a location update. Allow the intended background permission separately.
2. From paths-mobile run. If your existing API origin is `http://127.0.0.1:8080`, first run `adb -s 13111JEC204217 reverse tcp:8080 tcp:8080` yourself over USB; a LAN origin must instead be reachable from the phone:

```sh
flutter drive --profile --no-pub -d 13111JEC204217 \
  --driver=test_driver/performance.dart \
  --target=integration_test/full_journey_test.dart \
  --dart-define-from-file=paths.push.local.json \
  --dart-define-from-file=paths.performance.local.json
```

3. Keep the phone available for the native location observation (up to two minutes). The harness uses the actual app/tracker, switches tabs and scrolls, then logs out.
4. Expected: test passes; `artifacts/task13/journey.local.json` says completed/profile, contains actual frames and an observed production sample, and logout leaves zero queued samples. If no fix arrives, verify sharing/permissions and outdoor signal before retrying. Do not disable tracking verification to claim tracking success.
5. Return the aggregate JSON and any failed assertion. Build/raster p95 should each fit the 16.67 ms reference budget; report over-budget frames even if the test assertion passes. A passing journey alone does not certify smoothness.
6. In Flutter DevTools profile mode, repeat map → profile/photos → chats → home ten times. Record a short performance trace and aggregate memory before/after settling. Check hidden maps stop updating, private photos release when hidden/backgrounded, returning screens reload correctly, and memory settles rather than rising every cycle. Record rebuilding widgets; inspect focused Cubit selectors if broad rebuilds recur. Do not export traces containing private profile content.

## 2. Battery: matched eight-hour runs

Use the normal app with the production backend, not Phase 0. Sign in and enable sharing again after the profile journey logs out. Keep the backend host awake/reachable for the entire run and record any network/service gaps. Use the same phone, similar starting charge, network, power-saving settings, motion and screen usage. Do not charge during either run. A brief USB connection for ADB can affect charging; use already-configured wireless ADB or record battery percentage/time manually while unplugged. Endpoint checks cannot establish that an entire run was unplugged.

For wireless ADB, substitute its actual device ID below. Record baseline with Paths sharing paused:

```sh
python3 tools/device_measurements.py --device YOUR_WIRELESS_ADB_ID --record baseline-start
# After at least eight hours, with sharing still paused:
python3 tools/device_measurements.py --device YOUR_WIRELESS_ADB_ID --record baseline-end
```

Repeat a matched eight-hour interval with production sharing active and intended permissions:

```sh
python3 tools/device_measurements.py --device YOUR_WIRELESS_ADB_ID --record tracking-start
# After at least eight hours:
python3 tools/device_measurements.py --device YOUR_WIRELESS_ADB_ID --record tracking-end
```

Expected: valid matched durations within fifteen minutes; additional drain <=3 percentage points is the experimental target. Return aggregate drops/durations, charging confirmation, phone/OS, settings, and whether tracking continued while locked. A failed/invalid comparison remains pending. Do not treat a short run as an eight-hour result.

## 3. Labeled encounter coverage

1. Use two consenting adult test accounts/phones and production sharing. Copy `docs/testing/task13-field-labels.csv` into ignored `artifacts/task13/field.local.csv`.
2. Repeat the planned scenarios: same street foreground/locked, adjacent cafes/floors, stationary, brief fast crossing, network loss, permission downgrade and force-stop. Confirm each row's expected label from actual ground truth before recording observed yes/no. Add repeated rows and operating mode; leave unperformed rows pending.
3. For eligible cases, use two precise, accurate observations 20–120 seconds apart within the documented distance/time window. Record encounter delay and duplicates using coarse scenario labels only. Restore permissions/reopen after force-stop; background delivery is best effort.
4. Run `python3 tools/coverage_report.py artifacts/task13/field.local.csv`. Return counts, precision and recall by mode, pending scenarios and the delayed/missed/false encounters. >=90% labeled precision is a pilot target; recall must be reported separately. A handful of successful crossings is not universal accuracy evidence.

## 4. UI and accessibility

At default and 200% text, inspect auth/setup, home/map, profile/photos, likes, chat, reports, reviews and deletion. Check no clipped actions or extra horizontal scrolling, readable labels, 48px touch areas and sensible TalkBack focus. Enable reduced motion; loaders should remain understandable. Compare approved reference screens and report concrete screen/width differences. Verify a private photo returns after backgrounding without retaining a hidden photo, and offline/error/retry states remain usable.

Return aggregate evidence plus screen name, build/commit, OS, permission/network state and reproducible steps for failures. Redact personal content. iOS build success does not replace a signed iOS runtime test; that evidence remains separately pending.
