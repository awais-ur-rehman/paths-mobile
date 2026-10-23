# Authentication layout implementation plan

> **For agentic workers:** use superpowers:executing-plans inline; checkbox statuses track implementation and checks separately from owner acceptance.

**Goal:** reproduce the supplied login/signup/recovery visual treatment with centered Open P and existing Paths colors.
**Architecture:** shared AuthScaffold/FormTheme supplies layout and field/button styling; existing forms/Cubits retain business logic; provider controls keep SDK/config availability and accessible names.
**Tech Stack:** Flutter, existing BLoC/go_router/provider SDKs, bundled Inter and official Google icon artwork. No dependency changes.
**Spec:** docs/superpowers/specs/2026-10-24-auth-layout-design.md.

## Constraints and review focus

- Android only for this round; no iOS build, emulator or phone operation. Main unchanged; draft PR pending phone acceptance.
- Keep consent, generic recovery response, session persistence, auth guards, DOB privacy and provider capability gating intact.
- Password confirmation must prevent signup requests on mismatch, reveal controls must not submit, and valid signup/OTP must still advance.
- Large text and keyboard at 320/390/768 widths must retain reachable actions and avoid clipped fields/labels; centered P must stay centered independently of Back.
- Provider icon buttons must preserve accessible names, focus/tap targets, equal prominence, disabled/busy states and cancellation/retry behavior.
- Scope the form theme so unrelated app screens retain their existing controls. Shared setup forms intentionally inherit the consistent layout.

### Task 1: Shared form layout and credentials

Files: auth_widgets.dart, credential_screens.dart, reset_screen.dart, otp_screen.dart, account_screens.dart; profile_setup_screen.dart uses the shared input treatment. Tests: auth_screens_test.dart plus focused layout/confirmation tests.
- [x] Add signup-confirmation rejection/acceptance and password-reveal tests; observe expected failures before implementation.
- [x] Implement centered symbol/header, scoped pill fields/buttons and concise account/consent controls. Add signup confirmation and reuse reveal fields in reset. Preserve existing auth contracts.
- [x] Update flow selectors for the deliberate copy changes, exercise keyboard/large text and review login/signup/recovery/OTP/age/setup rendered goldens. Commit coherent shared-layout and form changes.

### Task 2: Circular provider controls

Files: provider_button.dart, provider_auth_sheet.dart, scoped auth form theme; assets/auth source/export, pubspec.yaml, docs/ASSETS.md. Tests: provider_auth_sheet_test.dart and new provider button interaction tests.
- [x] Add accessible provider selection and disabled/keyboard-focus tests and observe missing behavior.
- [x] Bundle official Google round artwork, use existing public AppleLogoPainter, lay out supported options in one centered row/Wrap, retain SDK/config gates and busy handling. Apply consistent styling to provider setup/recovery forms.
- [x] Run provider tests and inspect rendered configured-provider golden; commit.

### Task 3: Verification and handoff

- [x] Run full Flutter tests, analyze and installed-tooling tests; inspect complete diff and fix actual issues. Obtain fresh whole-change review.
- [x] Build ARM64 debug offline, compare staged/compiler/APK kernel and inspect bundled logo/provider resources. No iOS build.
- [ ] Record actual evidence and Android install/test instructions, push updated draft PR, retain phone acceptance gate. No merge or main promotion.

## Execution ledger

Base55a6061; clean existing checkout. Owner supplied the layout and authorized direct implementation. Choice: retain local checkout/private config/caches and existing feature branch for the combined UI pass. No additional worktree/dependency setup required. Shared header/theme changes also reach age/profile/verification/location setup because they already share AuthScaffold; existing body behavior is preserved.
