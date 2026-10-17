import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../app/theme/paths_tokens.dart';
import '../../../shared/widgets/paths_brand.dart';
import '../../../shared/widgets/paths_toast.dart';
import 'auth_cubit.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});
  @override
  Widget build(BuildContext context) => const PathsWordmark();
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
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                PathsTokens.gutter(constraints.maxWidth),
                20,
                PathsTokens.gutter(constraints.maxWidth),
                32,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: PathsTokens.maxFormWidth,
                  ),
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
                  width: 24,
                  height: 24,
                  child: PathsLoader(size: 24, color: Colors.white),
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
    PathsToast.show(
      context,
      'This link could not be opened. Check your browser or email app.',
    );
  }
}
