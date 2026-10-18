import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';
import 'entry_screens.dart';
import 'auth_widgets.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({required this.privacy, super.key});
  final bool privacy;
  @override
  Widget build(BuildContext context) {
    final policies = context.select((AuthCubit cubit) => cubit.state.policies);
    final url = privacy ? policies.privacyUrl : policies.termsUrl;
    final uri = Uri.tryParse(url);
    final configured =
        uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(privacy ? 'Privacy notice' : 'Terms of use')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (configured) ...[
                    Text(
                      privacy
                          ? 'Read the current Paths Privacy notice.'
                          : 'Read the current Paths Terms of use.',
                      style: const TextStyle(fontSize: 18, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => openExternal(context, uri),
                      child: const Text('Open in browser'),
                    ),
                  ] else ...[
                    const Text(
                      'Development testing notice',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      privacy
                          ? 'Use test accounts in this build. Paths stores account email, name, a password hash and session records. Your date of birth is private. Password-reset codes expire and can be used once. Authentication does not start location tracking.\n\nOnly non-sensitive onboarding preferences are stored in ordinary device preferences; session credentials use platform secure storage. Contact support about access or deletion. The published Privacy notice will replace this testing notice before a public release.'
                          : 'This build is for private development testing by adults aged 18 or over. Use an email address you control and keep credentials private. Do not submit real identity documents or other people’s personal information.\n\nThe published Terms of use will replace this testing notice before a public release.',
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    if (policies.supportEmail.isNotEmpty)
                      SelectableText('Support: ${policies.supportEmail}'),
                  ],
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ImageCredits(),
                      ),
                    ),
                    child: const Text('Image and font credits'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
