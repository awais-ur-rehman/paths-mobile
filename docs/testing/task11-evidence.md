# Task 11 local evidence — 2026-10-18

API contract1.10.0; feature/admin-review. Owner browser/Android acceptance and pilot staffing are pending. Main/development were not changed. Hosting remains deferred.

| Check actually executed | Result / scope |
| --- | --- |
| backend npm test | 38 unit and 13 feasibility passed; includes RFC6238 TOTP/replay vectors |
| backend npm run test:integration | 131 passed in fresh isolated PostGIS database, including 18 admin cases; running development worker cannot consume fixtures |
| backend final npm run test:integration -- admin-rbac | 18 passed again after final cursor validation, completed-document cutoff and enabled-review-push receipt/dedup regression |
| backend npm run build / npm run lint | passed |
| backend npm run stack:verify | passed restart/persistence/non-root/shutdown check with configured provider overrides; no image pulls |
| backend scripts/verify-admin | real local MFA → explicit synthetic text appeal → staff approval → exact member bio save → own review update passed; synthetic member removed, staff session logged out |
| admin npm test | 6 transport tests passed |
| admin npm run build / npm run lint | passed; existing Zod package PURE-comment build warning is nonfatal |
| admin npm run test:e2e -- --workers=1 | 9 installed-Chrome tests passed: password/MFA, role navigation, explicit image request/CSRF, version conflict,320/390/1280px, keyboard/Escape and session-expiry object URL cleanup |
| admin screenshots | 320px and1280px rendered screenshots inspected; desktop top alignment corrected and browser checks repeated |
| Flutter analyze --no-pub | no issues |
| Flutter test --no-pub | 256 passed |
| four focused review Cubit tests | passed: retry key/body changes, duplicate taps, account-bound replies, cancellation |
| python3 -m unittest discover -s test/tools | 11 passed |
| Gradle assembleDebug | passed with --offline, SDK downloads disabled and existing Flutter/Firebase/MapLibre caches |
| tools/check_android_kernel.py | APK kernel matches compiler output; SHA256 70aa67a6ff72cdf81eaad447a323e0a17eb2d03f5962db81044997c4160f6622 |
| cached xcodebuild generic iOS Debug | BUILD SUCCEEDED; unsigned, automatic package resolution disabled; no runtime/device claim |

Native builds ran sequentially (Android, then iOS). No SDK, package or image downloads were needed. RHF7.85.0/Zod4.6.7 were added from local cache with real npm-generated lockfile and retained MIT licenses.

Automated browser HTTP fixtures and generated JPEGs contain no real CNIC, people or user messages. Backend integration tests verify actual HTTP authorization/SQL transactions; mocked browser tests do not prove an operator’s review judgement or real provider delivery. Native compilation cannot prove permission/background/push runtime behavior.

Initial failing regressions exposed missing endpoints, completed-image access, stale appeal approval, Reviews redirect guards, native Node TypeScript parameter-property incompatibility, browser fetch receiver binding and an unscrollable profile menu. These were corrected and the relevant checks repeated. Full backend suite passed before the last cursor/push-case additions, with the 18-case admin suite re-run after those changes. No unexecuted checks are counted as passed.

Fresh whole-branch reviewer covered all three repositories. Fixed findings: rejection-version binding for image appeals, setup Reviews allowlists, chronological audit pagination, profile/verification refresh and private enrollment-file cleanup on transaction rollback. Additional inspection addressed cancellation, no-store/explicit viewer behavior, malformed cursors and preserving optional local provider overrides during stack verification.

Implementation commits before status-only handover:

- paths-backend: `98df8f0ccfc7ea05ad5c502113b2a16637fa88ac` (`feature/admin-review`)
- paths-admin: `32fd88c5a4b5bc3b7745dd66bcb64e781c0b53e8` (`feature/admin-review`)
- paths-mobile: `8f6bf5d22459ed0812fc9a45a210d7b22c6c8ea9` (`feature/admin-review`)

See task11-admin-review.md for exact owner commands, private enrollment locations, expected outcomes, failure observations and staffing gate. No phone/emulator was operated; actual push delivery, signed iOS runtime/APNs and prior field metrics remain pending. No paid cloud resource was created.
