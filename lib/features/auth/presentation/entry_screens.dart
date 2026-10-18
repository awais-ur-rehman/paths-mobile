import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_brand.dart';
import '../../../shared/widgets/arrow_slide_button.dart';

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
                  const PathsSymbol(),
                  const SizedBox(height: 24),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        state.error!.message,
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                      child: const PathsLoader(),
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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight * .52,
                    child: Image.asset(
                      'assets/onboarding/friends-walking.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(.12, 0),
                      semanticLabel: 'Friends enjoying a walk in a park',
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: const PathsWordmark(
                        width: 112,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Meet people you\ncross paths with',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'A familiar face. A new connection.\nSee where your paths take you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF52616D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ConstrainedBox(
                      constraints: BoxConstraints.tightFor(
                        width: (constraints.maxWidth * .78).clamp(0, 340),
                      ),
                      child: BlocSelector<AuthCubit, AuthState, bool>(
                        selector: (state) => state.busy,
                        builder: (context, busy) => ArrowSlideButton(
                          busy: busy,
                          onContinue: () async {
                            final cubit = context.read<AuthCubit>();
                            await cubit.finishOnboarding(signIn: true);
                            return cubit.state.stage != AuthStage.onboarding;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
