import 'resend_code_control.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/auth_models.dart';
import 'auth_cubit.dart';
import 'auth_widgets.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthCubit, AuthState, (AuthChallenge?, String)>(
        selector: (state) => (state.challenge, state.email),
        builder: (context, value) => AuthScaffold(
          title: 'Check your inbox',
          subtitle: value.$1?.purpose == 'reset'
              ? 'Enter the six-digit reset code.'
              : 'Enter the six-digit code sent to ${value.$2}.',
          onBack: () => context.read<AuthCubit>().cancelFlow(),
          child: value.$1 == null
              ? const SizedBox.shrink()
              : _OtpForm(challenge: value.$1!, key: ValueKey(value.$1!.id)),
        ),
      );
}

class _OtpForm extends StatefulWidget {
  const _OtpForm({required this.challenge, super.key});
  final AuthChallenge challenge;
  @override
  State<_OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<_OtpForm> {
  final form = GlobalKey<FormState>();
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      context.read<AuthCubit>().verify(code.text);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: code,
          decoration: const InputDecoration(
            labelText: 'Verification code',
            hintText: '6 digits',
          ),
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          autocorrect: false,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: (_) => submit(),
          validator: (value) =>
              value == null || !RegExp(r'^\d{6}$').hasMatch(value)
              ? 'Enter all six digits.'
              : null,
        ),
        const SizedBox(height: 16),
        AuthSubmit(label: 'Verify code', onPressed: submit),
        const SizedBox(height: 16),
        BlocSelector<AuthCubit, AuthState, bool>(
          selector: (s) => s.busy,
          builder: (context, busy) => ResendCodeControl(
            resendAt: widget.challenge.resendAt,
            expiresAt: widget.challenge.expiresAt,
            busy: busy,
            onResend: () => context.read<AuthCubit>().resend(),
          ),
        ),
        TextButton(
          onPressed: () => context.read<AuthCubit>().cancelFlow(),
          child: const Text('Change email or cancel'),
        ),
      ],
    ),
  );
}
