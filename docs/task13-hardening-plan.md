# Task13 hardening plan and ledger

Baseline: 06_IMPLEMENTATION_PLAN.md Task13, PRD section6, TRD sections3/4/12 and UI section5. Task12 accepted by owner on2026-10-18, including phone deletion and restore checks. Merged backendPR14 bf871a93, adminPR12 808b2694, mobilePR12 1ddc4498. Backend/admin CI passed; mobile owner testing/local builds passed. Main unchanged.

- [ ] Load: isolated production API/worker/PostGIS/Valkey;50samples/sec sustained,200/sec burst,300 sockets, all candidates colocated. Record actual API/encounter/chat p95, schedule slips, backlog/locks/query plan and host limits; do not substitute offered for achieved throughput.
- [ ] Recovery: isolated Valkey restart/loss, killed worker, PostgreSQL restart, cancelled upload, SMTP and push outage; prove committed outbox work recovers without duplicate effects/false receipt. Never fault the owner's active stack.
- [ ] Security: expand real authorization/ID enumeration, quotas, replay, CSRF, media and redaction regressions. Fix demonstrated defects, keep fixture/measurement details out of normal user flows.
- [ ] Device: production tracking battery/coverage experiment and full-journey integration harness, private config, aggregate frame/image measurements. Owner runs physical phones; no fabricated eight-hour or accuracy results.
- [ ] UI: map offscreen lifecycle, focused rebuild/image memory regressions, accessibility200percent/width/keyboard/contrast/reduced motion, reference renders. Fix measured defects, avoid broad redesign.
- [ ] Verification/review: existing local toolchain only, complete suites/builds; one fresh whole-branch review/fix; per-repo evidence/status, feature pushes and draft PRs pending device gates. Do not startTask14.

Ruling: use the existing clean checkouts on feature/pilot-hardening, as in accepted prior tasks, to preserve private local setup and caches. No package installation or new worktree is needed; main is untouched. Cost if wrong: branch-local changes are reviewable and reversible.
Ruling: isolated cached Docker services and synthetic members for fault/load work; never restart or erase the owner's current database/cache/R2 data. Preserve results outside disposable fixture volumes. Cost if wrong: local benchmarks are not production capacity proof.
Ruling: load durations are explicit harness inputs; default60seconds sustained and10seconds burst, full300-client clustered topology. Report target failures/backlog honestly and never increase CPU/worker concurrency without measured evidence. Cost if wrong: longer pilot soak remains needed.
Ruling: Task12 owner phone and restore acceptance closes its manual gates; iOS runtime/APNs, pilot staffing and off-host backup deployment remain release prerequisites. Task13 real eight-hour battery/coverage and profile evidence remain separate owner tests. Cost if wrong: no unsupported release claim.

Pre-flight interfaces: location ingestion emits durable location.match IDs → matching worker; matching emits notification intents → delivery; chat event receipts → Socket.IO generation sync. Fault harness must operate the real services with separate credentials/queues/volumes and no vendor credentials. Mobile scenario must use production repository/native tracker, not only Phase0 fixtures. Existing API contract1.11.0 remains unless an API shape changes.
