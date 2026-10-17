# Phase 0 physical-device runbook

Status: **not run**. Do not treat these instructions as device evidence. Branch: `feature/phase0-feasibility`; exact handoff commit is recorded in IMPLEMENTATION_STATUS.md and the phase PR. No emulator or phone was operated by the implementer.

## Prerequisites currently blocked

The installed Flutter 3.47.7 / Dart 3.13.5, Android API 36, Java 17 and cached Gradle 9.3.1 exist. Offline APK assembly stops in Flutter's `integration_test` native plugin. Missing:

- `com.android.tools.build:gradle:8.11.0` (SDK plugin's declared buildscript version). A diagnostic project-local init script aligns this to cached app AGP 9.1.0, but assembly then stops at the artifacts below.
- `androidx.test:runner:1.2+`, `androidx.test:rules:1.2+`, `androidx.test.espresso:espresso-core:3.3+`: no cached dynamic-version listings/artifacts.
- `com.google.guava:guava:28.1-android`.

No missing artifacts were downloaded. Either supply an existing complete cache, or explicitly authorize dependency fetching in a later turn. Do not run ordinary resolving builds while the no-download rule stands. Further native artifacts may be identified only after these prerequisites are available; this is not a promise the above list is exhaustive.

The Android wrapper points at an existing **all** distribution; the verified source-check command uses the cached **bin** distribution directly. Never let the wrapper fetch a distribution. iOS needs a physical signed-device setup, provisioning/team selection, and its own native build/runtime verification. Android results cannot verify iOS.

## Local checks now

From paths-mobile, using installed Flutter without upgrading it:

```sh
flutter analyze --no-pub
flutter test --no-pub
python3 tools/check_android_source.py
```

The Python check compiles all custom Kotlin against local Android/GMS/Flutter caches. If app resource assembly is blocked it substitutes only the icon resource reference in a temporary source copy with an existing Android platform icon. It does not validate resource linking, packaging, native library resolution or an installable APK. It creates no committed generated output.

From paths-backend:

```sh
npm test
```

The suite includes an authenticated loopback HTTP test. It needs permission to bind a local port, not internet access. Tests use synthetic zero-origin coordinates and ephemeral random keys only.

## Build and run after prerequisites are satisfied

These commands are for the owner, after checking prerequisites and maintaining offline mode:

```sh
cd /Users/awaisurrehman/Documents/experimental/Paths/paths-mobile
GRADLE_OFFLINE_BIN="$HOME/.gradle/wrapper/dists/gradle-9.3.1-bin/23ovyewtku6u96viwx3xl3oks/gradle-9.3.1/bin/gradle"
(cd android && "$GRADLE_OFFLINE_BIN" --offline --no-daemon -I ../tools/offline-android.init.gradle :app:assembleDebug)
```

Use your physical Android device ID only. After a successful offline APK build, you may install `build/app/outputs/apk/debug/app-debug.apk` using the installed `adb -s <phone-id> install -r ...`. This first build has **local capture only** and sends no samples. Do not provide real account credentials.

For the full active lifecycle integration test, once its missing native prerequisites exist, run with an offline Gradle init file applied (copy `tools/offline-android.init.gradle` into a temporary Gradle user init directory or use the existing cache's `init.d` under your control). Then:

```sh
flutter test --no-pub integration_test/location_lifecycle_test.dart -d <physical-android-id> --dart-define=PATHS_RUN_ACTIVE_LOCATION_TEST=true
```

`--no-pub` alone does not stop Gradle downloads; the offline init is required. The test prompts for precise location, waits for a real native sample, verifies a populated queue, pauses, waits 30 seconds for stray samples, starts a new session and verifies logout purges populated storage. The encrypted queue probe uses debug-only synthetic data. Without the explicit active-test define the active test is **skipped**, not passed.

## Two-phone matching setup (owner only)

Use two consenting adult testers and two phones. One phone can test lifecycle/battery but cannot establish encounter precision or recall. Keep ground truth separate from app verdicts; no names, coordinates, CNICs or tokens in returned reports.

1. In paths-backend run `npm run experiment:configure`. It creates ignored, permission-restricted `.env.phase0.local` and mobile `device-a.local` / `device-b.local`. It prints no keys. These disposable test keys identify only participants A/B; they are not real-account sessions.
2. Run `npm run experiment`. The Node experiment binds **127.0.0.1:8787**, holds samples only in memory, purges candidate samples after 10 minutes and dedup IDs after 15 minutes, and logs no requests/sample bodies. Stop it after the trial to erase remaining memory. It is not NestJS production infrastructure.
3. Connect both Android phones by USB; run `adb -s <phone-a-id> reverse tcp:8787 tcp:8787` and the same for B. Do not expose a plain HTTP listener to the LAN.
4. Build A and B with their matching `--dart-define-from-file=device-a.local` / `device-b.local`. With Gradle offline init in effect, run `flutter run --no-pub -d <physical-id> --dart-define-from-file=device-a.local` (B uses device-b.local). No production tokens, secrets or personal profiles belong in these configs.
5. Before each separately labeled trial, pause both phones, run `node --env-file=.env.phase0.local tools/feasibility/reset-trial.ts` in paths-backend, then explicitly start each experiment again. Reset clears all in-memory trial state, so reset only when both testers have paused. Do not paste bearer values into chat or shell history.
6. Enable foreground or explicitly opt into background capture. The status panel shows pending queue count and whether the conservative two-observation rule qualified during this trial. A matched verdict is historic for the trial, not proof of continued presence or same-venue certainty. `/summary` contains aggregate counts, no sample positions.

Android cleartext exception exists only in debug and only for loopback. iOS intentionally rejects the HTTP configuration: for paired iOS tests provide a trusted private-LAN TLS certificate/key to the same server (`PATHS_TEST_TLS_CERT`, `PATHS_TEST_TLS_KEY`, `PATHS_TEST_BIND=<private-LAN-IP>`, optional `PATHS_TEST_PORT`) and use an HTTPS endpoint trusted by the phone. Certificate trust/provisioning and iOS paired runtime validation are **pending**; TLS is not bypassed. Without TLS, iOS local-only capture remains the first test path. No proxy/service purchase is required or authorized.

## Numbered observations and expected behavior

1. Launch: original Paths splash/symbol, readable controls and scroll at large text, no automatic permission prompt or collection. Check launcher masking, light/dark launch, rotation and gesture safe insets.
2. Foreground opt-in: deny first, then use system Settings to grant precise permission. Denial shows a recovery message; no native samples. Start explicitly; move outdoors and wait for an actual fix. No fabricated count appears.
3. Pause: pending count becomes zero; after at least 30 seconds it stays zero. Native background notification disappears. Resume needs a new session/epoch.
4. Sign out: repeat with a populated queue. Pending count clears and capture does not restart on app relaunch. The experiment's sign-out is a lifecycle probe, not implemented production account authentication.
5. Background opt-in: verify visible ongoing Android notification and Stop action; lock/unlock, switch apps, revoke precise permission, disable location services, enable power saver and force-stop. Stop action must purge; remote state must be revoked online or display pending control on return offline. Force-stop must not silently restart. Record actual OS behavior and gaps.
6. Offline: stop the private server or disconnect USB; capture stays encrypted within 200 samples/15-minute eligibility. Pause offline purges locally; remote pause cannot be claimed until connected. Restart the server/reverse connection, retry Pause, then begin a fresh trial. No stale epoch or old device lease should be accepted.
7. Pair scenarios: same street walking, opposite streets, adjacent cafés, different floors, stationary table, short fast crossing. Repeat separately in foreground/background/locked modes. Standard rule needs independent observations 20–120 seconds apart; brief single-pair crossing is off. Measure false positives and misses instead of expecting every encounter.
8. Multiple device test: use A's disposable test identity on a second device after pausing the first. New lease supersedes the old; old batches reject. Do not run real accounts.
9. Clock changes: separately record forward/backward clock changes and sparse/offline delivery. Session clock-offset handling and live-alert classification are not certified by this harness. No push is configured and no notification latency result may be inferred from a match verdict.
10. Battery: repeat comparable eight-hour idle baseline and capture runs (same phone/OS, route, connectivity, charge range, screen-on time and power mode). Include locked and stationary→moving runs. Record battery percentage-point difference, observed sample delivery and OS restrictions; repeat trials. Do not infer battery cost from unit tests.

## Return only anonymized evidence

Use `docs/evidence/phase0-trials.csv`: trial label, device pseudonym/model/OS, duration, mode, scenario, ground-truth positive/negative, app verdict, TP/FP/FN, capture/drop/gap counts, battery baseline/capture, and permission/lifecycle observation. Precision = TP/(TP+FP); recall = TP/(TP+FN); undefined denominators stay blank. Record callback→server ingest→match latency separately if instrumented. Push dispatch/OS delivery are unavailable until test credentials and push integration exist. Never return exact coordinates, routes, token-bearing commands, raw queue files or real personal data.

On failure return: branch/commit, sanitized build error (artifact/version), device model/OS, test name, app status/count, permission setting, battery mode and reproducible steps. Native logs are not configured to print fixes or keys. Inspect any platform crash output before sharing. Phase 0 remains pending until device evidence and blockers are resolved; Phase 1 must not begin through this gate.
