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

## Dense processing follow-up — historical source checkpoint197accc

The earlier zero-completion measurement is historical. `ee0a446` replaces per-candidate transactions/materialized-evidence dependence with owner-serialized raw-observation corroboration and bounded peer batches. It atomically writes encounters, proof/evidence rows and inbox notices, retaining durable push work for registered devices. `fe7eb6a` coalesces publication per owner and adds migration0016's partial pending index. `35ad4ca` permits ingestion's read-only user SHARE lock alongside matching while retaining the exclusive lease lock. `f2e29f9`/`197accc` require all44,850 expected pairs and run unchanged load limits on native Linux with explicit runner metadata.

New regressions cover committed corroboration before earlier jobs, historical-to-live notification, pause/expiry races, twelve concurrent dense members, equivalent observations, multi-page rollback/replay, arrivals during a pass, implausible latest observations, single-observation fast exit, covered/newer proofs, polar/date-line envelopes, concurrent publisher queue loss and duplicate ingestion during matching reads. Expected RED failures were observed before the corresponding fixes; fixture quota/installation-ID and query setup failures are not counted as passing load runs.

Fresh local verification: **165 integration**, **42 unit +13 Phase0 +3 metric** tests passed; build/typecheck/lint passed; generated OpenAPI remains1.11.0. Final full integration duration67.34s. A read-only review found no remaining concrete Critical/Important issue; its global spatial materialization finding was fixed using the conservative PostGIS envelope before deduplication. Exact distance and locked authorization remain required. Minor workflow provenance/path-filter findings were fixed. `_ST_Expand` is internal to pinned PostGIS3.5 and must be revalidated on upgrade.

Recovery rerun: active worker crash64,064ms, lost Valkey queue30,880ms, database restart5,018ms, SMTP outage9,691ms; **all four passed**. These include cooldown/stall/startup intervals, not only processing latency. The expected database connection-loss event occurred during the intentional database restart. Upload cancellation and local FCM503→200 transport replay passed again within the165 integration cases; no vendor/APNs delivery claim follows.

Final emulated-Mac quiet run started2026-10-18T13:13:21.874Z. It completed **44,850/44,850 encounters**, versus zero in the published baseline, and drained to zero pending. It still **failed** the latency/acceptance/socket gates: encounterp95 **90,920.03ms**; sustained1676/3000 acknowledged, ingestp954488.26ms/readp956486.99ms; burst749/2000 acknowledged, ingestp952943.06ms/readp954343.56ms. Chat7/14 delivered, p9510388.38ms among successes;287/300 sockets remained. Missing/failed requests are failures, not omitted latency successes. Other saved quiet attempts also missed these gates; query-level improvements do not erase those results.

The same cached amd64 database still runs under emulation on Apple M2; a native GitHub Linux job is a distinct measurement, not a reason to relabel the local failures. No thresholds, worker counts or resource limits were raised. No new local dependency/image/tool was downloaded. The GitHub workflow uses existing manifests/images, synthetic credentials and isolated volumes; it cannot read the ignored owner environment. It retains only synthetic reports for seven days. The two-epoch workload does not establish performance for arbitrary distinct observations throughout the full fifteen-minute window or deployment capacity.

The owner's local runtime has the verified cached image and migration0016; existing R2/SMTP/push configuration, member data, recovery volumes and Task12 rollback image remain intact. Local proxy readiness returnedHTTP200. Synthetic hardening services were stopped with volumes retained. No external deployment or phone operation occurred.

## Dense matching revision —2026-10-18

Production matching checkpoint `7f93a3a`; measurement checkpoint `105b73b`, API **1.11.0 unchanged**. This supersedes the earlier zero-completion baseline for functional processing; it does not close the five-second capacity gate.

- `c4fcba2`: bound distinct peer IDs before observation deduplication and advance an unfiltered cursor, including a full page of spatial-envelope false positives.
- `f496140`: shared roots for read-only session validation, exclusive mutation default, statement-time expiry revalidation after lock waits.
- `814c21d`: keep every raw accepted sample, but coalesce only exact observations whose earlier source is committed and completed. Pending equivalents and changed evidence keep pending sources; producer/worker share one rule.
- `f4fdfe6` / `5238a51`: transfer observation identities to final validation, narrow raw projections and keep peer observations in typed SQL arrays. Final authorization, four-sample policy and exact distances still run under locks. Three-page diagnostic comparison selected identical299 proofs.
- `7f93a3a`: replace blocking whole-page pair locking with nonblocking acquired subsets; commit free pairs and retry busy ones after releasing transaction locks. Two seconds without progress raises a retryable failure; source ACK waits for every page. The new barrier reproduced the previous convoy/query timeout; GREEN44 focused cases passed, including independent progress and prolonged-lock timeout/replay. The old12-member dense case also timed out during that RED run; it passed after the fix.
- `105b73b`: load coverage requires fixture-scoped total sessions, distinct canonical pairs and latency rows all equal44,850. A duplicate session cannot offset a missing pair. The oracle regression failed before the helper existed, then all4 metric tests passed. Earlier reports count rows only and are not independent distinct-pair proof.

Executed on the final production code: **172/172 integration** (77.78s), **42 unit +13Phase0 +4 load metrics**, lint, typecheck/build and cached image build passed. Earlier full165/166/169/170 runs and expected RED failures are historical checkpoints. The final application code has no new dependency or API contract change. GitHub backend checks additionally regenerate OpenAPI and reject byte drift. No app code changed in admin/mobile during this follow-up; their previously recorded tests/builds were not rerun locally for documentation-only updates.

Review covered source retention/ACK snapshots, queue loss, page boundaries, stale grants, pause/block/delete, expiry while waiting, proof/session idempotency, live-versus-historical alerts, query safety and connection cleanup. Findings fixed: global spatial materialization, expired final leases, page-cursor termination on false positives, lock convoys, unbounded busy retries and a total-row-only load oracle. Final read-only review found no concrete remaining Critical/Important issue; the coverage-oracle Minor was then fixed and re-reviewed. This inspection cannot prove arbitrary-location performance, actual vendor push/APNs delivery, battery, field precision or native UI behavior.

All load runs retain the same300 members,50/sec60s +200/sec10s,90s drain, two capture epochs30s apart, and original resource caps/thresholds. Native Linux measurements are separate from cached amd64 PostGIS under M2 emulation. Do not infer production VM sizing from either. Repeated distinct moving observations across the full15-minute window, deployment-hardware soak and owner device/field gates remain open. No real personal data, provider keys, phone operation, new local installation, external deployment or main promotion is part of these checks.

### Native Linux measurements

Earlier rows verify counts only; the final105b73b run also requires distinct fixture-pair coverage. A pass on one earlier run does not erase a later failure. All values are milliseconds.

| Source / run | Acknowledged | Max API p95 | Chat delivered / p95 | Encounter rows / p95 | Sockets held / drained |
| --- | --- | --- | --- | --- | --- |
| [`197accc` / 39130990815](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39130990815) | 5000/5000 | 252.87 | 13/14 / 1441.84 | 44850 / 27869.65 | 299/300 / yes |
| [`57f5429` / 39131442217](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39131442217) | 5000/5000 | 189.45 | 14/14 / 1329.10 | 44850 / 32926.83 | 300/300 / yes |
| [`f496140` / 39131655820](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39131655820) | 5000/5000 | 111.80 | 14/14 / 1527.83 | 44850 / 27345.38 | 300/300 / yes |
| [`2e2b850` / 39132097719](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39132097719) | 5000/5000 | 835.44 | 14/14 / 2545.64 | 44850 / 57195.55 | 300/300 / yes |
| [`f4fdfe6` / 39132816905](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39132816905) | 5000/5000 | 91.96 | 14/14 / 1781.37 | 44850 / 38024.45 | 300/300 / yes |
| [`5238a51` / 39132957857](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39132957857) | 5000/5000 | 133.97 | 14/14 / 1346.79 | 44850 / 26392.32 | 300/300 / yes |
| [`7f93a3a` / 39133271490](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39133271490) | 5000/5000 | 167.37 | 14/14 / 1135.53 | 44850 / 22439.16 | 300/300 / yes |
| [`73b3fad` / 39133400461](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39133400461) | 4913/5000 | 1692.95 | 14/14 / 4726.19 | 44850 / 47663.24 | 300/300 / yes |
| [`105b73b` / 39133554208](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39133554208) | 5000/5000 | 136.48 | 14/14 / 1176.66 | 44850 distinct / 25431.67 | 300/300 / yes |

The repeated native runner reports **2 available CPUs and8,323,969,024 bytes RAM** to the unlimited harness container. DB/API/worker caps are unchanged:2CPU/1GiB,1CPU/512MiB,1CPU/512MiB, sharing that host. This differs from the TRD's proposed4vCPU/8GB VM. Qualifying that native deployment baseline remains unavailable; more CPU is not evidence that the gate will pass. Distinct-pair work still grows quadratically and large inbox/proof writes remain part of processing. Capacity is unresolved, rather than certified by a fast individual query.

Final available-host Mac measurement began **2026-10-18T13:52:03.932Z**, application7f93a3a. It created44,850 rows; an explicit post-measurement read-only reconciliation confirmed **44,850 distinct pairs**. Pending work drained to zero, but the run **failed** capacity: sustained2912/3000 acknowledged, ingestp952109.63ms/readp952621.62ms; burst907/2000 acknowledged with955 missed, ingestp952910.22ms/readp954286.14ms; chat12/14, p959200.26ms among successes; encounterp9583747.51ms;298/300 sockets held. The original row-count report and separate coverage reconciliation are preserved privately. Other desktop activity was present, so this is not labeled a quiet or native run. No desktop process was stopped.

Fresh final recovery, application7f93a3a: confirmed active worker crash **63,710ms**, lost Valkey queue **31,348ms**, persistent DB restart **5,341ms**, SMTP outage/retry **9,991ms**; **4/4 passed**. The expected connection-loss event occurred during the intentional DB restart. Upload cancellation and local503→200 FCM transport tests passed again in the172-case full suite. These are isolated synthetic faults, not vendor/APNs delivery evidence.

Local preparation completed: cached final image applied with existing ignored R2/push/test overlays; API/worker/proxy healthy and proxy readiness **HTTP200**. Migration0016 is present. Private configuration, member data, recovery volumes and `paths-backend:task12-verified` rollback image were preserved. The synthetic stack was stopped without deleting volumes. No external hosting or phone operation occurred.

### Final strict-coverage gate and handoff

[Native run39133554208](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39133554208), source105b73b, started **2026-10-18T13:56:33.171Z**: **6/7 gates passed**. All5000 samples were accepted, no missed/failed ingest or reads; **44,850 sessions /44,850 distinct fixture pairs /44,850 committed latency observations**. Sustained ingest/readp95 **108.90/119.84ms**; burst **72.87/136.48ms**. Chat **14/14**, p95 **1176.66ms**; **300/300** sockets throughout; pending0 after drain. Sampled peak3lock waiters. Encounterp95 **25,431.67ms**, **FAIL** versus5,000ms. No thresholds, limits, member counts, worker concurrency or observation epochs were relaxed. All prior failures remain above; this run does not establish reproducible full capacity.

[Backend CI39133554221](https://github.com/awais-ur-rehman/paths-backend/actions/runs/39133554221) **passed** on105b73b: lint/typecheck,42unit/13Phase0/4metrics,172 integration and generated-contract drift check. The separate dense-load workflow **failed** its encounter latency gate; backend CI success does not override it.

**Task13 remains in progress.** Matching correctness, queue drain and fault recovery are verified within this synthetic scope. Capacity<=5s, native4vCPU deployment qualification/soak, production battery/field precision, native frame/rebuild/image-memory profiling, accessibility/reference acceptance and iOS runtime/APNs checks remain open. No Task14 start, PR merge or main promotion. Existing owner instructions remain in paths-mobile/docs/testing/task13-device.md; code changes here do not constitute new device evidence. All repositories keep feature/pilot-hardening draft PRs into development.
