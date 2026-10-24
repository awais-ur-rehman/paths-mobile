# Profile badge and demo data plan

Use executing-plans inline. Spec: docs/superpowers/specs/2026-10-24-profile-demo-design.md. Preserve owner data, location consent and existing auth; no deployments, iOS builds or external notifications.

- [ ] Mobile: test both badge states and explanation/semantics; add original SVGs/generated geometry, show badge on profiles, set bar#F5F5F5, inspect rendered fixtures.
- [ ] Backend: feature branch from development; extend guarded seed and isolated integration tests for idempotency, authorization/scope, other accounts and no push. Populate account through actual private storage and persisted app records, preserving existing data.
- [ ] Verify meaningful API reads and images using a temporary session cleaned in finally; report aggregate counts only. Run possible suites/analyzer/offline Android build/kernel check, review full diff, fix issues, record evidence/status and push draft PRs. Phone gate remains pending.
