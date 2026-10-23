import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Separate controls keep both policy links accessible to screen readers.
class AuthConsent extends StatelessWidget {
  const AuthConsent({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 48,
        height: 48,
        child: Checkbox(
          value: value,
          onChanged: onChanged == null
              ? null
              : (next) => onChanged!(next == true),
          semanticLabel: 'Accept Terms and Privacy notice',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      Expanded(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('I agree to the', style: TextStyle(fontSize: 13)),
            TextButton(
              onPressed: () => context.push('/policies/terms'),
              child: const Text('Terms'),
            ),
            const Text('and', style: TextStyle(fontSize: 13)),
            TextButton(
              onPressed: () => context.push('/policies/privacy'),
              child: const Text('Privacy notice'),
            ),
          ],
        ),
      ),
    ],
  );
}
