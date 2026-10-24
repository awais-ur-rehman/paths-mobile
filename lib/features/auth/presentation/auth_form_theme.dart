import 'package:flutter/material.dart';

import '../../../app/theme/paths_theme.dart';

/// Scoped to authentication/setup forms, leaving the main app controls intact.
class AuthFormTheme extends StatelessWidget {
  const AuthFormTheme({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const shape = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
      borderSide: BorderSide.none,
    );
    final theme = Theme.of(context);
    // Long placeholders need the full field width at accessibility text sizes.
    final largeText = MediaQuery.textScalerOf(context).scale(15) > 20;
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          floatingLabelBehavior: largeText
              ? FloatingLabelBehavior.always
              : FloatingLabelBehavior.never,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          labelStyle: const TextStyle(fontSize: 15, color: Color(0xFF52616D)),
          hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF52616D)),
          prefixIconColor: const Color(0xFF68747D),
          suffixIconColor: const Color(0xFF68747D),
          prefixIconConstraints: BoxConstraints(
            minWidth: largeText ? 36 : 56,
            minHeight: 56,
          ),
          border: shape,
          enabledBorder: shape,
          disabledBorder: shape,
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
            borderSide: BorderSide(color: PathsTheme.blue, width: 1.5),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
            borderSide: BorderSide(color: Color(0xFFB42318)),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
            borderSide: BorderSide(color: Color(0xFFB42318), width: 1.5),
          ),
          errorMaxLines: 3,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF050708),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: const StadiumBorder(),
            elevation: 3,
            shadowColor: const Color(0x24101418),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class AuthFieldSurface extends StatelessWidget {
  const AuthFieldSurface({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(32)),
      boxShadow: [
        BoxShadow(
          color: Color(0x09101418),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}
