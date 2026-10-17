# Phase 0 code review

A separate read-only reviewer inspected the full source against Task1. The author inspected its findings and changed:

- Canonical two-phone matching: remove pair-of-pairs scan; bounded time-window sweep. Dense nonmatching regression and temporal/distance boundaries pass in Node.
- Backend leases: retain stop epoch watermarks; bind stop to session+epoch; prevent late stop revoking a newer lease and stop-before-lease resurrection.
- Android service: generation-bound destruction and in-place restart prevent an old foreground service from purging a new tracker session.
- Native stop: send lease-scoped remote stop; retry from Flutter on resume. Apply local status before optional network refresh and show remote-pending state offline.
- iOS permission: await Always authorization with a bounded wait; report Settings/retry state if OS defers it. Reject unsupported/incomplete transport configuration explicitly.
- Native callbacks: reject outdated session generation, pre-session fixes and foreground-only callbacks while hidden; stream current native statuses and samples to Dart.
- Queue reads prune expired encrypted bytes; reads/writes never return >200 or >15-minute fixes. Suspended OS execution cannot promise an exact disk deletion deadline; this limit is recorded, not silently waived.
- Integration test now includes actual sample delivery, populated-queue purge and a30-second pause-observation window. This test is explicitly skipped without opt-in and awaits the owner's physical-device run.
- Layout regression: compact/200% header overflow fixed; tests cover7 widths at2 text scales. Bundled fonts loaded for readable golden evidence.

Executed checks and exact scope are recorded in IMPLEMENTATION_STATUS.md. Native source compilation/type checking is weaker than an assembled and exercised device build. Background delivery, battery, precision/recall, OS notification behavior, key invalidation, disk failure, queued-control recovery after process death and iOS runtime remain unproven. Do not merge the draft PR or advance the Phase0 gate from inspection alone.

Follow-up inspection also fixed endpoint URI validation (empty root paths are valid), guaranteed active-test cleanup on timeout via registered teardown, refreshed service generation on reused background start commands, and prevented permission-revoked Activity resume from throwing a native startup exception. Two API transport regressions cover the exact runbook URL and scoped stop payload.
