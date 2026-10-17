import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'auth_cubit.dart';
import 'auth_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BlocBuilder<AuthCubit, AuthState>(
              buildWhen: (a, b) =>
                  a.stage != b.stage || a.error != b.error || a.busy != b.busy,
              builder: (context, state) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/brand/paths-symbol.png',
                    width: 88,
                    height: 88,
                    semanticLabel: 'Paths',
                  ),
                  const SizedBox(height: 24),
                  const AuthFeedback(),
                  if (state.stage == AuthStage.blocked) ...[
                    Text(
                      'Let’s reconnect',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    AuthSubmit(
                      label: 'Retry',
                      onPressed: () => context.read<AuthCubit>().initialize(),
                    ),
                  ] else
                    Semantics(
                      label: 'Loading your session',
                      child: const CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AuthBrand(),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: AspectRatio(
                    aspectRatio: 1.25,
                    child: Image.asset(
                      'assets/onboarding/friends-walking.jpg',
                      fit: BoxFit.cover,
                      semanticLabel: 'Friends enjoying a walk in a park',
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFC4F2F3),
                        child: Center(
                          child: Icon(
                            Icons.route_rounded,
                            size: 80,
                            color: Color(0xFF147DCE),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Meet people you\ncross paths with',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                const Text(
                  'A familiar face can become a new friend. Start with your email, then make Paths your own.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF52616D),
                  ),
                ),
                const SizedBox(height: 24),
                const AuthFeedback(),
                AuthSubmit(
                  label: 'Get started',
                  onPressed: () => context.read<AuthCubit>().finishOnboarding(),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<AuthCubit>().finishOnboarding(signIn: true),
                  child: const Text('Already have an account? Sign in'),
                ),
                const Text(
                  'For adults aged 18 and over.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF52616D)),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/policies/terms'),
                      child: const Text('Terms'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/policies/privacy'),
                      child: const Text('Privacy'),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ImageCredits(),
                    ),
                  ),
                  child: const Text(
                    'Image credit',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ImageCredits extends StatelessWidget {
  const ImageCredits({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Image credit')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboarding photo: MART PRODUCTION / Pexels.\n\nThis photograph illustrates friendship. The people shown are not presented as Paths members or endorsers.',
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'Paths'),
              child: const Text('Open-source licenses'),
            ),
          ],
        ),
      ),
    ),
  );
}
