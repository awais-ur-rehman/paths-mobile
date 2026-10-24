import 'package:flutter/services.dart';

import 'resend_code_control.dart';
import 'provider_button.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/auth_models.dart';
import '../domain/provider_auth.dart';
import 'auth_cubit.dart';
import 'auth_consent.dart';
import 'auth_widgets.dart';
import 'provider_auth_cubit.dart';
import 'provider_scope.dart';

Future<Map<String, dynamic>?> showProviderReauth(
  BuildContext context,
  ReauthAction action, {
  ProviderSetupDto? pending,
}) async {
  final scope = ProviderAuthScope.maybeOf(context);
  if (scope?.repository == null) {
    throw const AuthFailure('PROVIDER_UNAVAILABLE');
  }
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (_) => ProviderAuthSheet(
      repository: scope!.repository!,
      sdk: scope.sdk,
      action: action,
      pending: pending,
    ),
  );
}

class ProviderButtons extends StatefulWidget {
  const ProviderButtons({super.key});
  @override
  State<ProviderButtons> createState() => _ProviderButtonsState();
}

class _ProviderButtonsState extends State<ProviderButtons> {
  ProviderAuthCubit? cubit;
  bool opening = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ProviderAuthScope.maybeOf(context);
    if (cubit == null && scope?.repository != null) {
      cubit = ProviderAuthCubit(scope!.repository!, scope.sdk);
      unawaited(cubit!.load());
    }
  }

  @override
  void dispose() {
    unawaited(cubit?.close());
    super.dispose();
  }

  Future<void> open(IdentityProvider provider) async {
    if (opening || context.read<AuthCubit>().state.busy) return;
    setState(() => opening = true);
    final scope = ProviderAuthScope.maybeOf(context)!;
    final auth = context.read<AuthCubit>();
    try {
      final result = await showModalBottomSheet<Object>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (_) => ProviderAuthSheet(
          repository: scope.repository!,
          sdk: scope.sdk,
          provider: provider,
        ),
      );
      if (!mounted) return;
      if (result is AuthSession) auth.acceptProviderSession(result);
      if (result is ProviderSetupDto) {
        scope.linkOffer.value = result;
        context.go('/auth/login');
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cubit == null) return const SizedBox.shrink();
    final scope = ProviderAuthScope.maybeOf(context)!;
    return BlocBuilder<ProviderAuthCubit, ProviderState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.config == null) {
          return state.error == null
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: state.busy ? null : cubit!.load,
                  child: const Text('Retry sign-in options'),
                );
        }
        final options = IdentityProvider.values
            .where((p) => scope.sdk.supports(p, state.config!))
            .toList();
        if (options.isEmpty) return const SizedBox.shrink();
        return BlocSelector<AuthCubit, AuthState, bool>(
          selector: (auth) => auth.busy,
          builder: (context, authBusy) => Column(
            children: [
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFD8E4EC)),
              const SizedBox(height: 24),
              const Text(
                'Or continue with',
                style: TextStyle(fontSize: 14, color: Color(0xFF52616D)),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 16,
                children: [
                  for (final p in options)
                    ProviderButton(
                      provider: p,
                      onPressed: opening || authBusy || state.busy
                          ? null
                          : () => open(p),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProviderAuthSheet extends StatefulWidget {
  const ProviderAuthSheet({
    required this.repository,
    required this.sdk,
    this.provider,
    this.action,
    this.linking = false,
    this.proof,
    this.pending,
    super.key,
  });
  final ProviderAuthRepository repository;
  final ProviderSdk sdk;
  final IdentityProvider? provider;
  final ReauthAction? action;
  final bool linking;
  final String? proof;
  final ProviderSetupDto? pending;
  @override
  State<ProviderAuthSheet> createState() => _ProviderSheetState();
}

class _ProviderSheetState extends State<ProviderAuthSheet> {
  late final cubit = ProviderAuthCubit(
    widget.repository,
    widget.sdk,
    action: widget.action,
    linking: widget.linking,
    initialPending: widget.pending,
  );
  final email = TextEditingController(),
      code = TextEditingController(),
      password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool terms = false;
  @override
  void initState() {
    super.initState();
    if (widget.proof != null) cubit.acceptLinkProof(widget.proof!);
    unawaited(() async {
      await cubit.load();
      if (!cubit.isClosed &&
          cubit.state.error == null &&
          widget.provider != null) {
        await cubit.select(widget.provider!);
      }
    }());
  }

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ProviderAuthCubit, ProviderState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.error != null && state.error!.code != 'cancelled') {
            PathsToast.show(context, state.error!.message);
          }
          if (state.step == ProviderStep.done) {
            Navigator.pop(context, state.session ?? state.result);
          }
        },
        builder: (context, state) => AuthFormTheme(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.action != null
                                ? 'Confirm it’s you'
                                : widget.linking
                                ? 'Add sign-in method'
                                : 'Continue to Paths',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (state.busy) const Center(child: PathsLoader()),
                    if (state.step == ProviderStep.collision) ...[
                      const Text(
                        'An account already uses this email. Sign in, then link this method in Sign-in methods.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state.busy
                            ? null
                            : () => Navigator.pop(context, state.pending),
                        child: const Text('Sign in'),
                      ),
                    ] else if (state.step == ProviderStep.setup) ...[
                      if (state.pending!.emailRequired)
                        AuthFieldSurface(
                          child: TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.mail_rounded, size: 20),
                            ),
                            validator: validateEmail,
                          ),
                        ),
                      AuthConsent(
                        value: terms,
                        onChanged: state.busy
                            ? null
                            : (value) => setState(() => terms = value),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state.busy || !terms
                            ? null
                            : () {
                                if (form.currentState!.validate()) {
                                  unawaited(cubit.continueSetup(email.text));
                                }
                              },
                        child: const Text('Continue'),
                      ),
                    ] else if (state.step == ProviderStep.emailCode) ...[
                      AuthFieldSurface(
                        child: TextFormField(
                          controller: code,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Email code',
                            prefixIcon: Icon(Icons.password_rounded, size: 20),
                          ),
                          maxLength: 6,
                          validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '')
                              ? null
                              : 'Enter the six-digit code.',
                        ),
                      ),
                      FilledButton(
                        onPressed: state.busy
                            ? null
                            : () {
                                if (form.currentState!.validate()) {
                                  unawaited(cubit.verifyEmail(code.text));
                                }
                              },
                        child: const Text('Verify email'),
                      ),
                      ResendCodeControl(
                        resendAt: DateTime.parse(state.challenge!.resendAt),
                        expiresAt: DateTime.parse(state.challenge!.expiresAt),
                        busy: state.busy,
                        onResend: () => cubit.continueSetup(email.text),
                      ),
                    ] else if (state.config != null) ...[
                      if (widget.action != null &&
                          state.methods?.passwordEnabled == true) ...[
                        PasswordField(
                          controller: password,
                          label: 'Password',
                          validator: (value) =>
                              value != null && value.runes.length >= 12
                              ? null
                              : 'Enter your password.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: state.busy
                              ? null
                              : () {
                                  if (form.currentState!.validate()) {
                                    unawaited(cubit.password(password.text));
                                  }
                                },
                          child: const Text('Confirm'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          for (final p in IdentityProvider.values)
                            if (widget.sdk.supports(p, state.config!) &&
                                (widget.action == null ||
                                    state.methods!.providers.contains(p.name)))
                              ProviderButton(
                                provider: p,
                                onPressed: state.busy
                                    ? null
                                    : () => cubit.select(p),
                              ),
                        ],
                      ),
                      if (widget.action != null &&
                          state.methods?.passwordEnabled == false &&
                          !IdentityProvider.values.any(
                            (p) =>
                                widget.sdk.supports(p, state.config!) &&
                                state.methods!.providers.contains(p.name),
                          ))
                        const Text(
                          'Your sign-in method is unavailable on this phone. Use a supported device or contact support.',
                        ),
                    ],
                    if (state.error != null && state.config == null)
                      TextButton(
                        onPressed: state.busy ? null : cubit.load,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
