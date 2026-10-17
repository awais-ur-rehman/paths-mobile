import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_cubit.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/presentation/profile_preview_screen.dart';
import '../features/verification/domain/verification_repository.dart';
import '../features/verification/presentation/verification_screen.dart';
import '../features/discovery/data/location_sync_service.dart';
import '../features/discovery/presentation/location_setup_screen.dart';
import '../features/discovery/domain/encounter_repository.dart';
import '../features/discovery/presentation/home_screen.dart';
import '../features/profile/presentation/peer_profile_screen.dart';
import 'discovery_shell.dart';
import '../features/auth/presentation/entry_screens.dart';
import '../features/auth/presentation/credential_screens.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/reset_screen.dart';
import '../features/auth/presentation/account_screens.dart';
import '../features/auth/presentation/policy_screen.dart';

class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) {
      notifyListeners();
    });
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

GoRouter createAuthRouter(
  AuthCubit cubit,
  AuthRouterRefresh refresh,
  ProfileRepository profiles,
  ProfileSummaryRepository summaries,
  VerificationRepository verification, {
  LocationSyncService? locations,
  EncounterRepository? encounters,
}) {
  final profileRoute = GoRoute(
    path: '/profile',
    builder: (context, _) => ProfilePreviewScreen(
      repository: summaries,
      userId: cubit.state.account!.id,
      onBack: encounters == null ? null : () => context.go('/home'),
      onLocationSetup: locations == null
          ? null
          : () => context.go('/setup/permissions'),
    ),
  );
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, route) {
      final state = cubit.state;
      final path = route.uri.path;
      if (path == '/policies/terms' || path == '/policies/privacy') return null;
      final target = switch (state.stage) {
        AuthStage.booting || AuthStage.blocked => '/',
        AuthStage.onboarding => '/onboarding',
        AuthStage.otp => '/auth/otp',
        AuthStage.reset => '/auth/reset-password',
        AuthStage.authenticated =>
          state.account?.restricted == true
              ? '/account/restricted'
              : state.account?.adultChecked == true
              ? ([
                      '/setup/profile',
                      '/setup/verification',
                      '/profile',
                      if (locations != null) '/setup/permissions',
                      if (encounters != null) '/home',
                      if (encounters != null && path.startsWith('/profiles/'))
                        path,
                    ].contains(path)
                    ? path
                    : '/setup/profile')
              : '/setup/age',
        AuthStage.signedOut =>
          [
                '/auth/login',
                '/auth/signup',
                '/auth/forgot-password',
              ].contains(path)
              ? path
              : state.signupPreferred
              ? '/auth/signup'
              : '/auth/login',
      };
      return target == path ? null : target;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/auth/signup',
        builder: (_, _) => const CredentialsScreen(signup: true),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const CredentialsScreen(signup: false),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/auth/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(
        path: '/auth/reset-password',
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(path: '/setup/age', builder: (_, _) => const AgeCheckScreen()),
      GoRoute(
        path: '/setup/profile',
        builder: (_, route) => ProfileSetupScreen(
          repository: profiles,
          editing: route.uri.queryParameters['edit'] == '1',
        ),
      ),
      GoRoute(
        path: '/setup/verification',
        builder: (_, _) => VerificationScreen(repository: verification),
      ),
      if (encounters == null)
        profileRoute
      else
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => DiscoveryShell(shell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, _) => HomeScreen(
                    repository: encounters,
                    locations: locations,
                    onProfile: (id) =>
                        context.push('/profiles/${Uri.encodeComponent(id)}'),
                    onLocationSetup: () => context.go(
                      locations == null ? '/profile' : '/setup/permissions',
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(routes: [profileRoute]),
          ],
        ),
      if (encounters != null)
        GoRoute(
          path: '/profiles/:id',
          builder: (context, route) => PeerProfileScreen(
            repository: summaries,
            userId: route.pathParameters['id']!,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      if (locations != null)
        GoRoute(
          path: '/setup/permissions',
          builder: (_, _) => LocationSetupScreen(sync: locations),
        ),
      GoRoute(
        path: '/account/restricted',
        builder: (_, _) => const RestrictedAccountScreen(),
      ),
      GoRoute(
        path: '/policies/terms',
        builder: (_, _) => const PolicyScreen(privacy: false),
      ),
      GoRoute(
        path: '/policies/privacy',
        builder: (_, _) => const PolicyScreen(privacy: true),
      ),
    ],
  );
}
