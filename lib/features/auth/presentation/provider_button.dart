import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/provider_auth.dart';

class ProviderButton extends StatelessWidget {
  const ProviderButton({
    required this.provider,
    required this.onPressed,
    super.key,
  });
  final IdentityProvider provider;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 60,
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x14101418),
      child: IconButton(
        onPressed: onPressed,
        tooltip: provider == IdentityProvider.google
            ? 'Sign in with Google'
            : 'Sign in with Apple',
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(shape: const CircleBorder()),
        icon: Opacity(
          opacity: onPressed == null ? .4 : 1,
          child: provider == IdentityProvider.google
              ? Image.asset(
                  'assets/auth/google-round.png',
                  width: 60,
                  height: 60,
                  excludeFromSemantics: true,
                )
              : const SizedBox(
                  width: 25,
                  height: 30,
                  child: CustomPaint(
                    painter: AppleLogoPainter(color: Color(0xFF101418)),
                  ),
                ),
        ),
      ),
    ),
  );
}
