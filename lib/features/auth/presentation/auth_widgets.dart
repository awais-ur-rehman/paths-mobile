import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/auth_models.dart';
import 'auth_cubit.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/paths-logo-ink.png',
    width: 140,
    height: 44,
    semanticLabel: 'Paths',
  );
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    super.key,
  });
  final String title, subtitle;
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDDF4FF), Color(0xFFF5FBFF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (onBack != null)
                            IconButton(
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Back',
                            ),
                          const AuthBrand(),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF101418),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF52616D),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const AuthFeedback(),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthCubit, AuthState, (AuthFailure?, String?)>(
        selector: (state) => (state.error, state.notice),
        builder: (context, value) {
          final (failure, notice) = value;
          if (failure == null && notice == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: failure != null
                      ? const Color(0xFFFFF0EC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notice != null)
                      Text(notice, style: const TextStyle(height: 1.5)),
                    if (failure != null)
                      Text(
                        failure.message,
                        style: const TextStyle(
                          color: Color(0xFF8C251B),
                          height: 1.5,
                        ),
                      ),
                    if (failure?.requestId case final String id)
                      SelectableText(
                        'Reference: $id',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class AuthSubmit extends StatelessWidget {
  const AuthSubmit({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthCubit, AuthState, bool>(
        selector: (state) => state.busy,
        builder: (context, busy) => FilledButton(
          onPressed: busy ? null : onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  busy ? 'Please wait…' : label,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.newPassword = false,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final bool newPassword;
  final VoidCallback? onSubmitted;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool hidden = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: hidden,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        onPressed: () => setState(() => hidden = !hidden),
        tooltip: hidden ? 'Show password' : 'Hide password',
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: (value) =>
        value == null || value.runes.length < 12 || value.runes.length > 128
        ? 'Use 12–128 characters.'
        : null,
  );
}

String? validateEmail(String? value) =>
    value == null ||
        value.trim().length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Enter a valid email address.'
    : null;
Future<void> openExternal(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    /* A missing external handler is shown explicitly below. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This link could not be opened. Check your browser or email app.',
        ),
      ),
    );
  }
}
