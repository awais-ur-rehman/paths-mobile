import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({required this.status, super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    if (status == 'none') return const SizedBox.shrink();
    final approved = status == 'approved';
    final label = switch (status) {
      'approved' => 'Document reviewed',
      'pending' => 'Review pending',
      'declined' => 'Review declined',
      _ => 'Review unavailable',
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
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
        icon: Icon(
          approved ? Icons.verified_outlined : Icons.info_outline,
          size: 20,
        ),
        label: Text(label),
      ),
    );
  }
}
