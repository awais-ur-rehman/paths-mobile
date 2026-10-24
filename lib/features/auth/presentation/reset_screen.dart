import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';
import 'auth_widgets.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'New password',
    subtitle: 'Use 12–128 characters. All devices will be signed out.',
    onBack: () => context.read<AuthCubit>().cancelFlow(),
    child: const _ResetForm(),
  );
}

class _ResetForm extends StatefulWidget {
  const _ResetForm();
  @override
  State<_ResetForm> createState() => _ResetFormState();
}

class _ResetFormState extends State<_ResetForm> {
  final form = GlobalKey<FormState>();
  final password = TextEditingController(),
      confirmation = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      context.read<AuthCubit>().reset(password.text);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PasswordField(
            controller: password,
            label: 'New password',
            newPassword: true,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: confirmation,
            label: 'Confirm new password',
            newPassword: true,
            onSubmitted: submit,
            validator: (value) =>
                value != password.text ? 'The passwords do not match.' : null,
          ),
          const SizedBox(height: 24),
          AuthSubmit(label: 'Reset password', onPressed: submit),
        ],
      ),
    ),
  );
}
