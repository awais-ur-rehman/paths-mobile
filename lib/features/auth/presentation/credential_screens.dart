import 'provider_auth_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'auth_cubit.dart';
import 'auth_widgets.dart';

class CredentialsScreen extends StatelessWidget {
  const CredentialsScreen({required this.signup, super.key});
  final bool signup;
  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: signup ? 'A new path starts here' : 'Good to see you',
    subtitle: signup
        ? 'Create your account with an email you can access.'
        : 'Sign in to continue where you left off.',
    child: _CredentialsForm(signup: signup),
  );
}

class _CredentialsForm extends StatefulWidget {
  const _CredentialsForm({required this.signup});
  final bool signup;
  @override
  State<_CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends State<_CredentialsForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool accepted = false;
  bool termsError = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    if (widget.signup && !accepted) {
      setState(() => termsError = true);
      return;
    }
    final cubit = context.read<AuthCubit>();
    if (widget.signup) {
      cubit.signup(name.text, email.text, password.text, accepted);
    } else {
      cubit.login(email.text, password.text);
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
          if (widget.signup) ...[
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null ||
                      value.trim().runes.length < 2 ||
                      value.trim().runes.length > 80
                  ? 'Use 2–80 characters.'
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.next,
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: password,
            label: 'Password',
            newPassword: widget.signup,
            onSubmitted: submit,
          ),
          if (widget.signup) ...[
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: accepted,
              onChanged: (value) => setState(() {
                accepted = value ?? false;
                termsError = false;
              }),
              title: const Text(
                'I agree to the Terms and acknowledge the Privacy notice.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () => context.push('/policies/terms'),
                  child: const Text('Read Terms'),
                ),
                TextButton(
                  onPressed: () => context.push('/policies/privacy'),
                  child: const Text('Read Privacy notice'),
                ),
              ],
            ),
            if (termsError)
              const Text(
                'Read and accept the Terms to continue.',
                style: TextStyle(color: Color(0xFFB42318)),
              ),
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/auth/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
          const SizedBox(height: 24),
          AuthSubmit(
            label: widget.signup ? 'Create account' : 'Sign in',
            onPressed: submit,
          ),
          const ProviderButtons(),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.go(widget.signup ? '/auth/login' : '/auth/signup'),
            child: Text(
              widget.signup
                  ? 'Already have an account? Sign in'
                  : 'New to Paths? Create an account',
            ),
          ),
        ],
      ),
    ),
  );
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Find your way back',
    subtitle: 'Enter your account email. If an account exists, we’ll send a password-reset code.',
    onBack: () => context.go('/auth/login'),
    child: const _ForgotForm(),
  );
}

class _ForgotForm extends StatefulWidget {
  const _ForgotForm();
  @override
  State<_ForgotForm> createState() => _ForgotFormState();
}

class _ForgotFormState extends State<_ForgotForm> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      context.read<AuthCubit>().forgot(email.text);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          validator: validateEmail,
        ),
        const SizedBox(height: 24),
        AuthSubmit(label: 'Send reset code', onPressed: submit),
      ],
    ),
  );
}
