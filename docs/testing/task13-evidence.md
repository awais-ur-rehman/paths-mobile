# Task 13 evidence — 2026-10-18

Task 12 owner phone and restore acceptance received; backend PR14, admin PR12 and mobile PR12 merged into development. Main was not promoted. Task 13 is on `feature/pilot-hardening` in all repositories, API **1.11.0**. It remains **in progress**, pending dense-load targets and owner field/profile/accessibility evidence. Task 14 has not started.

## Checklist coverage

| Plan item | Status and evidence |
| --- | --- |
| Clustered 50/sec, 200/sec burst, 300 sockets; plans/locks/outbox lag | Implemented and measured against isolated real services. Capacity gate remains pending; see measured values below. |
| Valkey/worker/database/upload/SMTP/push failures | Verified locally: four isolated service faults passed; cancelled HTTP upload plus real transport/local push fault fixtures passed. Actual vendor/APNs outage delivery is not inferred. |
| Authorization, enumeration, quotas, refresh replay, CSRF, private media, redaction | Verified locally by the full 151-test integration suite, including new socket and redaction regressions. |
| Production battery and labeled coverage repeat | Implemented tools/journey; awaiting owner eight-hour matched runs and ground truth. No battery, precision or recall result is claimed. |
| Rebuilds/map hidden/image memory | Image lifecycle and inactive-map regressions verified in widgets. Profile-mode harness compiles. Native memory/frame/rebuild traces await owner device evidence. |
| Accessibility/text scale/reference comparisons/limitations | Automated layouts, labels, contrast, targets, reduced motion and existing goldens passed. Home/profile reference PNGs inspected; none regenerated. Native TalkBack and full reference acceptance remain pending. |

## Checks actually executed

| Check | Result |
| --- | --- |
| Backend build/typecheck/lint | Passed |
| Backend unit/Phase0/load-metric tests | 42 +13 +3 passed |
| Backend full isolated PostGIS/Valkey integration | **151 passed**, after the migration fixture correction below |
| Generated OpenAPI drift check | Passed; API1.11.0 unchanged |
| Cached hardening image builder | Passed; no backend package/image download |
| Worker killed inside confirmed active transaction | Passed; one durable effect after replay, 35,846 ms including crash/restart/stall detection |
| Valkey restart with queue persistence disabled | Passed; durable outbox recovered, 31,695 ms including cooldown |
| Database restart with persistent fixture volume | Passed; work/readiness recovered, 4,915 ms |
| SMTP stopped and restored | Passed; pending mail ACK after recovery, 10,667 ms |
| Interrupted upload / push503→200 replay | Passed in integration tests; local HTTP transport boundary, no live vendor fault |
| Admin lint/unit/build | Passed; 8 unit tests |
| Installed Chrome browser suite | **15 passed** in final single-worker run; includes keyboard/reflow/reduced motion |
| Flutter analyzer / full widget/reference suite | No issues; **276 passed** |
| Python field tools / existing Android tooling tests | 4 +11 passed; no ADB operation performed |
| Offline Android debug build + packaged kernel | Passed; 75,676,536 bytes, SHA256 `4cb66b74cb6b1b0f7d657315d9b28b605bb008a7faa6f2eea4c35fdfe4d4c50f` |
| Android ARM64 profile integration target build | Passed after required Android artifacts were fetched under prior download approval; placeholder test credentials only; no runtime result |
| Cached unsigned generic-device iOS build | Build succeeded with automatic Swift package resolution disabled; no signing/runtime/APNs result |

The profile attempt first failed offline on Flutter `arm64_v8a_profile` and `flutter_embedding_profile` at engine deb287481e3ce9468f3434937ced4240a70539ca, AndroidX `lifecycle-livedata`/`lifecycle-livedata-core-ktx`2.6.2 and `window`1.0.0. Required artifacts/transitives were fetched using the owner's existing Android-test dependency authorization. No SDK, tool, Node/Flutter package or version update was installed. The final guarded profile harness was then rebuilt successfully with offline Gradle resolution, and analysis remained clean. There is no remaining package prerequisite for the checks above.

## Review and fixes

One fresh read-only review of the then-current whole branch was completed; subsequent queue and fixture changes were self-reviewed and checked. Its findings were addressed: failed/missing normal reads now fail latency gates, and the recovery harness kills a confirmed active job instead of only testing worker downtime. Self-inspection corrected the barrier's foreign-key lock conflict (`NO KEY UPDATE` permits fixture insertion while blocking the worker's `FOR UPDATE`), fixture quota reset, exact spatial EXPLAIN projection/filters, and monitor completion before socket teardown.

Demonstrated production fixes: authenticated-session device quota key (57/300 failing connections →300/300), TCP-only PostgreSQL readiness during initialization, prioritized outbox publication and an independent chat queue inside the existing worker process, private image hidden/background cleanup and variant reauthorization, admin reduced-motion loader and 48px deletion actions.

The first concurrent full backend run passed150/151; the failed test used a100ms connection-startup budget while trying to test query timeout. The fixture now keeps the normal connection budget and preserves its100ms query budget; focused bootstrap3/3 and full151/151 passed. The first active-crash fixture blocked its own FK insert and failed before exercising the crash; corrected before the four passing faults above. An admin run printed15 successful assertions but did not finish teardown; the pending network fixture now explicitly releases/aborts and the final15-test run completed. These unsuccessful attempts are not counted as passes.

## Measured load

Final controlled run began **2026-10-18T12:13:08Z**, after heavy builds/tests finished. All300 sockets connected and remained connected through the final monitor snapshot. All5000 offered samples were accepted and acknowledged; no failed/missed samples or normal reads. This is a short local measurement, not a soak or production sizing result.

| Phase | Offered load | Accepted | Achieved acceptance rate | Ingest p95 | Normal-read p95 |
| --- | --- | --- | --- | --- | --- |
| sustained | 50/sec for60s | 3000 | 49.97/sec | 54.46ms | 84.38ms |
| burst | 200/sec for10s | 2000 | 199.88/sec | 61.43ms | 73.81ms |

- Chat:14/14 exact recipient events, zero timeouts, p95 **1,423.87ms** from client HTTP start. This conservative boundary and API p95 meet their local thresholds in this run.
- Encounter creation: **zero completed latency observations**, p95 **unavailable**. The<=5s gate is not met; zero observations cannot count as zero latency.
- Queue: **4,958 pending**, oldest **162.66s**, after the90-second drain window; sampled peak **3 lock waiters**. The drain gate failed. Candidate matching remains the open capacity problem.
- Exact first-page spatial candidate query: `EXPLAIN ANALYZE BUFFERS` execution **132.32ms**, dense spatial candidate scan/sort with existing GiST index.5,000 stored samples occupied **2,678,784 bytes**, including table/index storage. The ignored raw report retains the full plan and monitor series.
- Earlier controlled runs also accepted all samples/held300 sockets, but missed some API/chat thresholds (one dual-queue run had chatp953,406.59ms and burst ingestp95935.26ms). Host contention/resource variation matters; the final quiet run does not erase these observations. No universal latency claim follows.

Raw final and earlier aggregate reports remain local under ignored `artifacts/task13/`; they are not personal production records. The final monitor is settled before socket teardown; report targets and snapshots agree. Synthetic services are stopped after measurement with volumes retained. No fault was injected into the owner's stack.


## Known limits and owner gates

The isolated stack runs cached amd64 PostGIS under emulation on a shared Apple M2/8GB host (Docker VM8CPUs/4,108,828,672 bytes), with PostgreSQL2CPU/1GB, API and worker1CPU/512MB each. It is not the TRD deployment sizing and establishes no cloud capacity. Dense candidate-pair transactions remain expensive; successful ingestion does not prove timely encounters. Separate chat consumption avoids waiting for a spatial worker slot but shares database CPU/locks. A final-run resource snapshot observed PostGIS205.45% CPU/324.4MiB, API7.39%/76.25MiB and worker33.06%/58.61MiB; this points to database saturation under the two-CPU cap, not proof of a particular deployment capacity. Do not advertise the encounter/capacity target as achieved or close that gate.

No phone/emulator was operated. Owner must run the profile journey, native map/image/rebuild inspection, matched eight-hour battery runs, labeled encounter coverage and native accessibility checks from paths-mobile `docs/testing/task13-device.md`. Signed iOS runtime/APNs, live push delivery/taps, off-host backup deployment, named pilot reviewers and approved policy URLs remain separate release prerequisites. User acceptance of Task12 does not close these gates. Code inspection, widget tests and unsigned builds cannot prove them.

## Source checkpoints

- Backend: `4788819` socket quota, `f818acc` TCP readiness, `138cdd4` queue separation/priorities, `d79e16d` security/failure fixtures, `5e22579` load/recovery harness, `84ef61c` full candidate query plan.
- Mobile: `4caff48` image lifecycle, `5b636d4` accessibility/inactive map, `f901dc6` production journey and field tools, `f308894` nonempty-frame guard and RSS peak sampling.
- Admin: `8f5ca5a` reduced motion/touch targets and browser regressions.

Later evidence/link commits change documentation only. All feature work stays in draft PRs into development; no Task13 merge or main promotion before applicable gates pass.

Local owner-test runtime: previous backend image retained as `paths-backend:task12-verified`; cached Task13 image applied with the existing R2/push/test Compose overlays. Services are healthy and proxy readiness returned HTTP200. Existing private environment files, keys, data and recovery volumes were retained. This was local test preparation, not an external deployment. Synthetic hardening containers/network were stopped; named fixture volumes and ignored reports remain.

## Published Task 13 review branches

All use `feature/pilot-hardening` → `development`, draft pending the open capacity/device gates. Published implementation/evidence checkpoints before this link update:

| Repository | Checkpoint | Draft PR |
| --- | --- | --- |
| Backend | `1496c86` | [PR15](https://github.com/awais-ur-rehman/paths-backend/pull/15) |
| Admin | `4513d01` | [PR13](https://github.com/awais-ur-rehman/paths-admin/pull/13) |
| Mobile | `b01a564` (application `4caff48`, journey `f308894`) | [PR13](https://github.com/awais-ur-rehman/paths-mobile/pull/13) |

Owner instructions: paths-mobile `docs/testing/task13-device.md`. Native builds correspond to the code checkpoints in the evidence; subsequent link commits change documentation only. Local checks passed within their stated scope. GitHub CI is a separate live check and is not inferred from local results. Main is unchanged; Task13 remains open and Task14 has not started.
