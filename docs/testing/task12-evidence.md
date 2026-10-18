# Task12 verification evidence — 2026-10-18

Status: implementation and local verification delivered on feature/account-erasure. Required Android deletion/counterpart test and owner signed restore evidence remain pending. Task13 has not started; main is unchanged.

| Check | Executed result |
|---|---|
| Backend build/typecheck and ESLint | passed |
| Backend unit suite |42 passed;13 feasibility tests passed |
| Full integration suite |144 passed on final full rerun |
| Final focused deletion suite |13 passed, including overlay isolation and complete-file/pending-DB expiry recovery |
| Final authenticated backup/journal tests |3 passed after stream cleanup fix |
| Real pre-deletion pg_dump → isolated restore → suppression |passed;0 deleted-user references,0 shared messages,0 owner objects;2 unrelated messages preserved; FKs valid; trafficOpenedfalse |
| Configured R2 plus migrated local recovery storage |synthetic disposable member only;6 private objects removed across2 stores,0 remain; complete receipt |
| Storage inventory after configured-storage test |completed1, pending0, overdue0, remaining0; passed |
| Managed encrypted backup |created successfully; authenticated metadata, seven-day deadline |
| Real private pre-migration snapshot restore |passed after current migrations and current independent suppression; trafficOpenedfalse |
| Requested test admin |password→MFA→admin/document permission→logout passed locally; no secrets logged |
| Admin unit tests |8 passed |
| Admin build/typecheck and ESLint |passed; dependency comment annotation warnings only |
| Chrome Playwright suite |10 passed; public OTP/offline/reload/wrong-target recovery/no staff calls, plus staff regression checks |
| Flutter analyze |no issues |
| Flutter tests |263 passed |
| Android Gradle |offline assembleDebug passed;235 tasks; kernel/APK checksum matches compiler output |
| iOS Xcode |generic device Debug BUILD SUCCEEDED, unsigned, automatic package resolution disabled; runtime not tested |
| Public receipt layout |render inspected at320px; no horizontal overflow in browser test |

The test runner strips all DELETION_* settings and real provider configuration before isolated subprocesses. Integration fixtures never touch the live journal. The separate configured-storage test creates only a fresh synthetic member and its own objects, then erases that member; no existing member is deleted. The original migration recovery volume is preserved except the six scoped synthetic test objects across both stores. Existing app photos remain private.

## Review and fixes

One fresh whole-branch read-only review completed. Fixed: inverse erasure chat-version deadlock; purpose recovery persistence before every submit; unconfirmed mobile receipt navigation; public proof replay across target emails; independent-journal O_NOFOLLOW reads; multipart cursor prefix leakage/malformed inventory; completed outbox retry after journal expiry; isolated restore changing the live journal; crash plaintext backup files (now authenticated two-pass streaming); expired crash work and fsync; completed-journal/pending-DB expiry recovery. Regression tests cover those code paths. No claim that inspection proves real device cleanup, production retention, iOS runtime, delivered notification recall or provider outage recovery.

## Artifacts and prerequisites

Backend implementation commits f52d502, f5128f1, fac225b. Admin implementation50670a4. Mobile implementationad694a0, dabb776. Subsequent status/evidence commits contain these reports. API contract1.11.0 is exported from Nest and consumed by generated clients.

Task11 accepted and merged: backend PR13 b70b6cf; admin PR11 684e814; mobile PR11 60de712. Test admin is test-admin@paths.example.invalid; password/MFA are ignored mode0600 backend .secrets/test-admin-login.local.json and .secrets/test-admin-mfa.local.json. Never copy values into a PR/report.

No packages, SDKs or Docker images downloaded for Task12. Local Docker image rebuilt from cached image with network disabled. R2 operations used existing configured private credentials. Configured local backups/journal are not off-machine disaster recovery. Owner/operator must preserve their independent key/journal and approve manual restore evidence. Actual backup-window passage is covered with clock-driven unit tests, not a seven-day live observation. APNs and iOS runtime remain unavailable; pilot staffing, approved Terms/Privacy destinations and production deployment remain separate release prerequisites. Social-provider data/revocation remains Task14.

See task12-erasure.md for numbered owner tests and backend docs/runbooks/restore.md for backup operations. Keep Task12 open until the device and restore gates pass.
