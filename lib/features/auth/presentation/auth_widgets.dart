import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../app/theme/paths_tokens.dart';
import '../../../shared/widgets/paths_brand.dart';
import '../../../shared/widgets/paths_toast.dart';
import 'auth_cubit.dart';
import 'auth_form_theme.dart';
export 'auth_form_theme.dart' show AuthFieldSurface, AuthFormTheme;

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});
  @override
  Widget build(BuildContext context) => const PathsSymbol(size: 64);
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.onRefresh,
    super.key,
  });
  final String title, subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) => AuthFormTheme(
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scroll = SingleChildScrollView(
              physics: onRefresh == null
                  ? null
                  : const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                PathsTokens.gutter(constraints.maxWidth),
                16,
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
                      SizedBox(
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const AuthBrand(),
                            if (onBack != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  shadowColor: const Color(0x14101418),
                                  child: IconButton(
                                    onPressed: onBack,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 28,
                                    ),
                                    tooltip: 'Back',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                          color: Color(0xFF101418),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF52616D),
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      child,
                    ],
                  ),
                ),
              ),
            );
            return onRefresh == null
                ? scroll
                : RefreshIndicator.noSpinner(
                    onRefresh: onRefresh!,
                    child: scroll,
                  );
          },
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
    this.validator,
    this.textInputAction = TextInputAction.done,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final bool newPassword;
  final VoidCallback? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool hidden = true;
  @override
  Widget build(BuildContext context) => AuthFieldSurface(
    child: TextFormField(
      controller: widget.controller,
      obscureText: hidden,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      textInputAction: widget.textInputAction,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_rounded, size: 20),
        suffixIcon: IconButton(
          onPressed: () => setState(() => hidden = !hidden),
          tooltip: hidden ? 'Show password' : 'Hide password',
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator:
          widget.validator ??
          (value) =>
              value == null ||
                  value.runes.length < 12 ||
                  value.runes.length > 128
              ? 'Use 12–128 characters.'
              : null,
    ),
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
