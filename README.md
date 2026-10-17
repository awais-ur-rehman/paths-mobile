# paths-mobile

Flutter Android/iOS app. Phase 0 is an explicitly opted-in private location experiment, not a public pilot.

`main` and `development` are documentation baselines, not working releases. The feature branch contains Phase0 work awaiting its verification gate. See docs/IMPLEMENTATION_STATUS.md and docs/specification/06_IMPLEMENTATION_PLAN.md.

## Branches

`main`: last verified baseline; `development`: verified integrated work; `feature/<description>` from development; `hotfix/<description>` from main. Pending tooling/device gates use draft PRs into development. Never promote unverified application changes to main.

No dependency installation, automatic fetching or container pulls are authorized in this work session.

## Phase 0 handoff

See [implementation status](docs/IMPLEMENTATION_STATUS.md) for every phase checkbox, executed checks, exact blockers and commit references. The private harness runbook is [DEVICE_TESTS.md](docs/DEVICE_TESTS.md). Do not run resolving builds while downloads remain prohibited.
