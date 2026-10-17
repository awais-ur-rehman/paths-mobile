# paths-mobile

Flutter Android/iOS app. Phase 0 is an explicitly opted-in private location experiment, not a public pilot.

`main` remains the documentation baseline. Phase0 was accepted by the owner and merged into `development`. Phase1 foundation work is tracked in docs/IMPLEMENTATION_STATUS.md.

## Branches

`main`: last verified baseline; `development`: verified integrated work; `feature/<description>` from development; `hotfix/<description>` from main. Pending tooling/device gates use draft PRs into development. Never promote unverified application changes to main.

The owner authorized Android test dependencies and Phase1 project packages/Docker images. SDK upgrades and production deployment remain outside this authorization.

## Phase 0 handoff

See [implementation status](docs/IMPLEMENTATION_STATUS.md) for every phase checkbox, executed checks, exact blockers and commit references. The private harness runbook is [DEVICE_TESTS.md](docs/DEVICE_TESTS.md). Use `--no-pub` for local Flutter checks; installed dependencies are already locked.
