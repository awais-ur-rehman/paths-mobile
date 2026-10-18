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
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: provider == IdentityProvider.apple
          ? SignInWithAppleButton(
              onPressed: onPressed,
              height: 52,
              borderRadius: BorderRadius.circular(26),
            )
          : Semantics(
              button: true,
              enabled: onPressed != null,
              label: 'Sign in with Google',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(26),
                  child: Opacity(
                    opacity: onPressed == null ? 0.5 : 1,
                    child: SizedBox(
                      height: 52,
                      width: 300,
                      child: Image.asset(
                        'assets/auth/google-sign-in.png',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
