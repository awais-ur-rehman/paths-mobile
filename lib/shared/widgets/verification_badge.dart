import 'package:flutter/material.dart';

import 'paths_icon.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({required this.status, super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    final label = switch (status) {
      'approved' => 'Verified',
      'none' => 'Unverified',
      'pending' => 'Review pending',
      'declined' => 'Review declined',
      _ => 'Review unavailable',
    };
    final disabledColor =
        Theme.of(context).textButtonTheme.style?.foregroundColor
            ?.resolve({WidgetState.disabled}) ??
        const Color(0xFF52616D);
    return TextButton.icon(
      style: TextButton.styleFrom(disabledForegroundColor: disabledColor),
      onPressed: approved
          ? () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Document reviewed by Paths'),
                content: const Text(
                  'Paths reviewed a voluntarily submitted document. This is not a government identity check or a guarantee of safety.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            )
          : null,
      icon: PathsIcon(
        approved ? PathsIconName.verified : PathsIconName.unverified,
        size: 20,
      ),
      label: Text(label),
    );
  }
}
