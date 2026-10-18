import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';
import 'auth_widgets.dart';

class AgeCheckScreen extends StatelessWidget {
  const AgeCheckScreen({super.key});
  @override
  Widget build(BuildContext context) => const AuthScaffold(
    title: 'Confirm you’re 18 or over',
    subtitle: 'Your full date of birth stays private.',
    child: _AdultForm(),
  );
}

class _AdultForm extends StatefulWidget {
  const _AdultForm();
  @override
  State<_AdultForm> createState() => _AdultFormState();
}

class _AdultFormState extends State<_AdultForm> {
  final form = GlobalKey<FormState>();
  final dob = TextEditingController();
  @override
  void dispose() {
    dob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: dob,
          decoration: InputDecoration(
            labelText: 'Date of birth',
            hintText: 'YYYY-MM-DD',
            suffixIcon: IconButton(
              tooltip: 'Choose date of birth',
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 18, now.month, now.day),
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (picked != null && mounted) {
                  dob.text =
                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                }
              },
            ),
          ),
          keyboardType: TextInputType.datetime,
          validator: (value) =>
              value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
              ? 'Use YYYY-MM-DD.'
              : null,
        ),
        const SizedBox(height: 24),
        AuthSubmit(
          label: 'Confirm age',
          onPressed: () {
            if (form.currentState!.validate()) {
              context.read<AuthCubit>().checkAdult(dob.text);
            }
          },
        ),
      ],
    ),
  );
}

class RestrictedAccountScreen extends StatelessWidget {
  const RestrictedAccountScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Your account is restricted',
    subtitle: 'Contact support to appeal or request deletion.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SupportActions(),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => context.read<AuthCubit>().logout(),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
}

class SupportActions extends StatelessWidget {
  const SupportActions({super.key});
  @override
  Widget build(BuildContext context) {
    final policies = context.select((AuthCubit cubit) => cubit.state.policies);
    final email = policies.supportEmail;
    if (email.isEmpty) {
      return Column(
        children: [
          const Text('Support contact information could not be loaded.'),
          TextButton(
            onPressed: () => context.read<AuthCubit>().initialize(),
            child: const Text('Reconnect and retry'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => openExternal(
            context,
            Uri(
              scheme: 'mailto',
              path: email,
              queryParameters: {'subject': 'Paths account support'},
            ),
          ),
          child: const Text('Contact support'),
        ),
        TextButton(
          onPressed: () => openExternal(
            context,
            Uri(
              scheme: 'mailto',
              path: email,
              queryParameters: {
                'subject': 'Paths account deletion request',
                'body': 'Please help me request deletion of my Paths account.',
              },
            ),
          ),
          child: const Text('Request deletion help'),
        ),
        const Text(
          'This opens an email request. Your account is not deleted by tapping the button.',
          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF52616D)),
        ),
      ],
    );
  }
}
