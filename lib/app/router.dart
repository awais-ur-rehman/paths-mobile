import '../features/setup/domain/setup_progress.dart';
import '../features/setup/presentation/setup_resume_cubit.dart';
import '../features/setup/presentation/setup_resume_screen.dart';
import '../features/media/data/http_media_repository.dart';
import '../features/media/domain/media_repository.dart';
import '../features/media/presentation/photo_screen.dart';
import '../features/posts/data/post_repository.dart';

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
import '../core/platform/push_client.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/presentation/notification_screen.dart';
import '../features/notifications/presentation/notification_settings.dart';
import '../shared/widgets/paths_toast.dart';
import '../features/relationships/data/relationship_repository.dart';
import '../features/relationships/presentation/likes_screen.dart';
import '../features/auth/presentation/entry_screens.dart';
import '../features/auth/presentation/credential_screens.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/reset_screen.dart';
import '../features/auth/presentation/account_screens.dart';
import '../features/auth/presentation/policy_screen.dart';

class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(AuthCubit cubit) {
    Object routeState(AuthState state) => (
      state.stage,
      state.account?.id,
      state.account?.restricted,
      state.account?.adultChecked,
      state.signupPreferred,
    );
    var previous = routeState(cubit.state);
    _subscription = cubit.stream.listen((state) {
      final next = routeState(state);
      if (next == previous) return;
      previous = next;
      // A routine resume/token refresh must preserve pushed routes and their results.
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
  SetupProgressStore? setupProgress,
  HttpMediaRepository? media,
  PhotoPicker? picker,
  PostRepository? posts,
  LocationSyncService? locations,
  EncounterRepository? encounters,
  RelationshipRepository? relationships,
  NotificationRepository? notifications,
  PushClient? push,
}) {
  SetupDestination? setupDestination;
  String? setupAccount, pendingDestination;
  bool discardOldDestination = false;
  final hasSetupGate = media != null && setupProgress != null;
  String setupPath(SetupDestination destination) => switch (destination) {
    SetupDestination.profile => '/setup/profile',
    SetupDestination.verification => '/setup/verification',
    SetupDestination.permissions => '/setup/permissions?onboarding=1',
    SetupDestination.home => encounters == null ? '/profile' : '/home',
  };
  final profileRoute = GoRoute(
    path: '/profile',
    builder: (context, route) => ProfilePreviewScreen(
      key: ValueKey(route.uri.toString()),
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
      final endedAccount =
          setupAccount != null && setupAccount != state.account?.id;
      if (endedAccount) {
        pendingDestination = null;
        // Router refresh may revisit the old protected URI after the splash.
        discardOldDestination = true;
      } else if (path.startsWith('/auth/') || path == '/onboarding') {
        discardOldDestination = false;
      }
      if (setupAccount != state.account?.id) {
        setupAccount = state.account?.id;
        setupDestination = null;
      }
      if (hasSetupGate &&
          !discardOldDestination &&
          setupDestination != SetupDestination.home &&
          route.uri.scheme.isEmpty &&
          route.uri.host.isEmpty &&
          (['/home', '/likes', '/profile', '/notifications'].contains(path) ||
              path.startsWith('/profiles/'))) {
        pendingDestination ??= route.uri.toString();
      }
      if (hasSetupGate &&
          state.stage == AuthStage.authenticated &&
          state.account?.restricted != true &&
          state.account?.adultChecked == true) {
        if (setupDestination == null && path != '/setup/resume') {
          return '/setup/resume';
        }
        if (setupDestination != null &&
            setupDestination != SetupDestination.home &&
            ![
              '/setup/resume',
              '/setup/profile',
              '/media/avatar',
              if (setupDestination == SetupDestination.verification)
                '/media/cnic_front',
              if (setupDestination == SetupDestination.verification)
                '/media/cnic_back',
              Uri.parse(setupPath(setupDestination!)).path,
              '/policies/terms',
              '/policies/privacy',
            ].contains(path)) {
          return setupPath(setupDestination!);
        }
      }
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
                      if (hasSetupGate) '/setup/resume',
                      '/setup/verification',
                      '/profile',
                      if (media != null && path.startsWith('/media/')) path,
                      if (locations != null) '/setup/permissions',
                      if (encounters != null) '/home',
                      if (relationships != null) '/likes',
                      if (notifications != null) '/notifications',
                      if (notifications != null) '/settings/notifications',
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
      if (hasSetupGate)
        GoRoute(
          path: '/setup/resume',
          builder: (context, route) => SetupResumeScreen(
            profiles: profiles,
            verification: verification,
            progress: setupProgress,
            owner: cubit.state.account!.id,
            currentAccount: () => cubit.state.account?.id,
            requirePermissionEducation: locations != null,
            onDestination: (destination) {
              setupDestination = destination;
              final next = destination == SetupDestination.home
                  ? (route.uri.queryParameters['return'] == 'profile'
                        ? '/profile?revision=${DateTime.now().microsecondsSinceEpoch}'
                        : pendingDestination ?? setupPath(destination))
                  : setupPath(destination);
              if (destination == SetupDestination.home) {
                pendingDestination = null;
              }
              context.go(next);
            },
          ),
        ),
      if (media != null && picker != null && posts != null)
        GoRoute(
          path: '/media/:kind',
          builder: (context, route) {
            final kind = switch (route.pathParameters['kind']) {
              'avatar' => MediaKind.avatar,
              'cnic_front' => MediaKind.cnicFront,
              'cnic_back' => MediaKind.cnicBack,
              _ => MediaKind.post,
            };
            return PhotoScreen(
              media: media,
              picker: picker,
              posts: posts,
              kind: kind,
              onCancel: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
              onReady: (id) {
                if (kind == MediaKind.post) {
                  PathsToast.show(
                    context,
                    'Post sent for review.',
                    tone: ToastTone.success,
                  );
                  context.go('/profile?post=$id');
                } else {
                  context.pop(id);
                }
              },
            );
          },
        ),
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
        builder: (context, route) => VerificationScreen(
          repository: verification,
          onContinue: !hasSetupGate
              ? null
              : () => context.go(
                  route.uri.queryParameters['return'] == 'profile'
                      ? '/setup/resume?return=profile'
                      : '/setup/resume',
                ),
          documents: media == null
              ? const UnavailableVerificationDocuments()
              : CallbackVerificationDocuments(
                  (side) => context.push<String>(
                    '/media/${side == DocumentSide.front ? 'cnic_front' : 'cnic_back'}',
                  ),
                ),
        ),
      ),
      if (encounters == null)
        profileRoute
      else
        StatefulShellRoute.indexedStack(
          builder: (context, _, shell) => DiscoveryShell(
            shell: shell,
            hasLikes: relationships != null,
            onCamera: media == null ? null : () => context.push('/media/post'),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, _) => HomeScreen(
                    repository: encounters,
                    relationships: relationships,
                    locations: locations,
                    onProfile: (id) async {
                      await context.push(
                        '/profiles/${Uri.encodeComponent(id)}',
                      );
                    },
                    onNotifications: notifications == null
                        ? null
                        : () => context.push('/notifications'),
                    onLocationSetup: () => context.go(
                      locations == null ? '/profile' : '/setup/permissions',
                    ),
                  ),
                ),
              ],
            ),
            if (relationships != null)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/likes',
                    builder: (context, _) => LikesScreen(
                      repository: relationships,
                      onProfile: (id) async {
                        await context.push(
                          '/profiles/${Uri.encodeComponent(id)}',
                        );
                      },
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
            relationships: relationships,
            onOpened:
                notifications == null ||
                    route.uri.queryParameters['notification'] == null
                ? null
                : () async {
                    try {
                      await notifications.read(
                        route.uri.queryParameters['notification']!,
                      );
                    } catch (_) {
                      if (context.mounted) {
                        PathsToast.show(
                          context,
                          'Opened. Could not mark as read.',
                        );
                      }
                    }
                  },
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
      if (notifications != null)
        GoRoute(
          path: '/notifications',
          builder: (context, _) => NotificationScreen(
            repository: notifications,
            onSettings: () => context.push('/settings/notifications'),
            onOpen: (id) async {
              final account = notifications.accountId;
              final destination = await notifications.resolve(id);
              if (!context.mounted || account != notifications.accountId) {
                return;
              }
              if (destination.destination == 'profile' &&
                  destination.targetId != null) {
                await context.push(
                  '/profiles/${Uri.encodeComponent(destination.targetId!)}?notification=${Uri.encodeComponent(id)}',
                );
              } else {
                PathsToast.show(
                  context,
                  'This notification is no longer available.',
                );
              }
            },
          ),
        ),
      if (notifications != null)
        GoRoute(
          path: '/settings/notifications',
          builder: (_, _) =>
              NotificationSettings(repository: notifications, push: push),
        ),
      if (locations != null)
        GoRoute(
          path: '/setup/permissions',
          builder: (context, route) => LocationSetupScreen(
            sync: locations,
            onContinue:
                !hasSetupGate ||
                    (route.uri.queryParameters['onboarding'] != '1' &&
                        setupDestination != SetupDestination.permissions)
                ? null
                : () async {
                    final owner = cubit.state.account!.id;
                    await setupProgress.markPermissionSeen(owner);
                    if (context.mounted && owner == cubit.state.account?.id) {
                      context.go('/setup/resume');
                    }
                  },
          ),
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
