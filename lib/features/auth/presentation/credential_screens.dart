import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'auth_consent.dart';
import 'auth_cubit.dart';
import 'auth_widgets.dart';
import 'provider_auth_sheet.dart';

class CredentialsScreen extends StatelessWidget {
  const CredentialsScreen({required this.signup, super.key});
  final bool signup;

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: signup ? 'Create Account' : 'Log in',
    subtitle: signup
        ? 'Create an account to start crossing paths.'
        : 'Welcome back. Log in to your account.',
    onBack: signup ? () => context.go('/auth/login') : null,
    child: _CredentialsForm(signup: signup, key: ValueKey(signup)),
  );
}

class _CredentialsForm extends StatefulWidget {
  const _CredentialsForm({required this.signup, super.key});
  final bool signup;
  @override
  State<_CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends State<_CredentialsForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool accepted = false, termsError = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
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
            AuthFieldSurface(
              child: TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_rounded, size: 20),
                ),
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
            ),
            const SizedBox(height: 20),
          ],
          AuthFieldSurface(
            child: TextFormField(
              controller: email,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.mail_rounded, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
          ),
          const SizedBox(height: 20),
          PasswordField(
            controller: password,
            label: 'Password',
            newPassword: widget.signup,
            textInputAction: widget.signup
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: widget.signup ? null : submit,
          ),
          if (widget.signup) ...[
            const SizedBox(height: 20),
            PasswordField(
              controller: confirmation,
              label: 'Confirm password',
              newPassword: true,
              onSubmitted: submit,
              validator: (value) =>
                  value != password.text ? 'The passwords do not match.' : null,
            ),
            const SizedBox(height: 16),
            AuthConsent(
              value: accepted,
              onChanged: (value) => setState(() {
                accepted = value;
                termsError = false;
              }),
            ),
            if (termsError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Accept the Terms to continue.',
                  style: TextStyle(color: Color(0xFFB42318)),
                ),
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
            label: widget.signup ? 'Create account' : 'Login',
            onPressed: submit,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.signup
                    ? 'Already have an account?'
                    : 'Don’t have an account?',
                style: const TextStyle(fontSize: 14, color: Color(0xFF52616D)),
              ),
              TextButton(
                onPressed: () =>
                    context.go(widget.signup ? '/auth/login' : '/auth/signup'),
                child: Text(widget.signup ? 'Log in' : 'Sign up'),
              ),
            ],
          ),
          const ProviderButtons(),
        ],
      ),
    ),
  );
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Forgot Password',
    subtitle: 'Enter your email to receive a reset code.',
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
        AuthFieldSurface(
          child: TextFormField(
            controller: email,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_rounded, size: 20),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => submit(),
            validator: validateEmail,
          ),
        ),
        const SizedBox(height: 36),
        AuthSubmit(label: 'Continue', onPressed: submit),
      ],
    ),
  );
}
