import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_cubit.dart';
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
) => GoRouter(
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
            : '/setup/profile',
      AuthStage.signedOut =>
        ['/auth/login', '/auth/signup', '/auth/forgot-password'].contains(path)
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
    GoRoute(
      path: '/setup/profile',
      builder: (_, _) => const ProfileEntryScreen(),
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
