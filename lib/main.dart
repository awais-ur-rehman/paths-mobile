import 'core/storage/own_cache_store.dart';
import 'features/profile/data/own_persistent_cache.dart';
import 'features/auth/domain/provider_auth.dart';
import 'features/auth/data/social_auth_service.dart';
import 'features/auth/presentation/provider_scope.dart';
import 'core/network/generated/api_contract.dart' show ProviderSetupDto;
import 'features/deletion/data/http_deletion_repository.dart';
import 'features/deletion/data/deletion_store.dart';
import 'features/deletion/domain/deletion_repository.dart';
import 'features/safety/data/http_safety_repository.dart';
import 'features/safety/presentation/safety_scope.dart';
import 'features/chat/data/chat_realtime.dart';
import 'features/chat/data/http_chat_repository.dart';
import 'features/setup/domain/setup_progress.dart';
import 'core/storage/setup_progress.dart';
import 'features/media/domain/media_repository.dart';
import 'core/network/authenticated_media_api.dart';
import 'features/media/data/http_media_repository.dart';
import 'features/media/data/native_photo_picker.dart';
import 'features/media/presentation/media_scope.dart';
import 'features/posts/data/post_repository.dart';
import 'app/brand_licenses.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/router.dart';
import 'core/network/authenticated_api.dart';
import 'core/platform/push_client.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/relationships/data/relationship_repository.dart';
import 'app/theme/paths_theme.dart';
import 'core/platform/location_tracker.dart';
import 'core/storage/auth_storage.dart';
import 'features/auth/data/http_auth_repository.dart';
import 'features/auth/domain/auth_models.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'shared/widgets/paths_toast.dart';
import 'features/profile/domain/profile_repository.dart';
import 'features/verification/domain/verification_repository.dart';
import 'features/discovery/domain/location_repository.dart';
import 'features/discovery/domain/encounter_repository.dart';
import 'features/discovery/data/location_sync_service.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  registerBrandLicenses();
  runApp(PathsApp(onStartupReady: binding.allowFirstFrame));
}

class PathsApp extends StatefulWidget {
  const PathsApp({
    this.repository,
    this.onStartupReady,
    this.deletion,
    this.locationSync,
    this.photoPicker,
    this.setupProgress,
    super.key,
  });
  final VoidCallback? onStartupReady;
  final SetupProgressStore? setupProgress;
  final PhotoPicker? photoPicker;
  final LocationSyncService? locationSync;
  final AuthRepository? repository;
  final DeletionRepository? deletion;
  @override
  State<PathsApp> createState() => _PathsAppState();
}

class _PathsAppState extends State<PathsApp> {
  final providerSdk = SocialAuthService();
  final providerLinkOffer = ValueNotifier<ProviderSetupDto?>(null);
  AuthRepository? repository;
  DeletionRepository? deletion;
  AuthCubit? cubit;
  AuthRouterRefresh? refresh;
  GoRouter? navigation;
  PlatformLocationTracker? tracker;
  LocationSyncService? locations;
  AuthFailure? failure;
  HttpMediaRepository? media;
  SetupProgressStore? setupProgress;
  PhotoPicker? photoPicker;
  PostRepository? posts;
  ChatRealtime? realtime;
  HttpChatRepository? chats;
  HttpSafetyRepository? safety;
  StreamSubscription? safetyEvents;
  StreamSubscription<AuthState>? chatAuth;
  PushClient? push;
  NotificationRepository? notifications;
  StreamSubscription<AuthState>? pushAuth;
  StreamSubscription<String>? pushEvents;
  bool pushReady = false;
  bool openingPush = false;
  Future<void> _pushResume() async {
    if (!mounted ||
        !pushReady ||
        cubit?.state.stage != AuthStage.authenticated ||
        cubit?.state.account?.adultChecked != true ||
        cubit?.state.account?.restricted == true) {
      return;
    }
    await push!.resume();
    await _openPush();
  }

  Future<void> _openPush() async {
    if (!mounted ||
        openingPush ||
        !pushReady ||
        notifications?.accountId == null ||
        cubit?.state.account?.adultChecked != true ||
        cubit?.state.account?.restricted == true) {
      return;
    }
    openingPush = true;
    try {
      final id = await push!.takeTap();
      if (id == null) return;
      final account = notifications!.accountId;
      final destination = await notifications!.resolve(id);
      if (!mounted || account != notifications!.accountId) return;
      if (destination.destination == 'profile' &&
          destination.targetId != null) {
        navigation!.push(
          '/profiles/${Uri.encodeComponent(destination.targetId!)}?notification=${Uri.encodeComponent(id)}',
        );
      } else if (destination.destination == 'conversation' &&
          destination.targetId != null) {
        navigation!.push(
          '/chats/${Uri.encodeComponent(destination.targetId!)}?notification=${Uri.encodeComponent(id)}',
        );
      } else if (destination.destination == 'review') {
        await navigation!.push('/reviews');
        if (account == notifications!.accountId) await notifications!.read(id);
      } else {
        navigation!.push('/notifications');
      }
    } catch (error) {
      push!.lastFailure = error is AuthFailure
          ? error
          : const AuthFailure('push_registration');
      if (mounted) navigation?.push('/notifications');
    } finally {
      openingPush = false;
    }
  }

  bool _startupReleased = false;
  StreamSubscription<AuthState>? _startupAuth;
  void _startupReady({bool force = false}) {
    if (_startupReleased || !mounted) return;
    bool ready() =>
        force ||
        failure != null ||
        cubit?.state.stage == AuthStage.blocked ||
        (cubit?.state.stage != AuthStage.booting &&
            navigation != null &&
            !['/', '/setup/resume'].contains(
              navigation!.routerDelegate.currentConfiguration.uri.path,
            ));
    if (!ready()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startupReleased || !ready()) return;
      _startupReleased = true;
      widget.onStartupReady?.call();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  AppLifecycleListener? lifecycle;
  @override
  void initState() {
    super.initState();
    try {
      tracker = widget.repository == null ? PlatformLocationTracker() : null;
      push = widget.repository == null ? PushClient() : null;
      repository =
          widget.repository ??
          HttpAuthRepository(
            origin: const String.fromEnvironment('PATHS_API_ORIGIN'),
            ownCache: OwnPersistentCache(PlatformOwnCacheStore()),
            vault: PlatformTokenVault(),
            preferences: PlatformAuthPreferences(),
            purgeMedia: () async {
              await media?.purge();
              await photoPicker?.discardLostSelection();
            },
            purgeNotifications: () => push?.clear() ?? Future.value(),
            purgeTracking: () =>
                locations?.stopLocalAndMarkPending(forcePending: false) ??
                tracker!.stopAndPurge(),
          );
      cubit = AuthCubit(repository!);
      refresh = AuthRouterRefresh(cubit!);
      final profiles = repository;
      if (profiles is! ProfileRepository ||
          profiles is! ProfileSummaryRepository ||
          profiles is! VerificationRepository) {
        throw const AuthFailure('configuration');
      }
      locations = widget.locationSync;
      if (locations == null && tracker != null) {
        if (profiles is! LocationRepository) {
          throw const AuthFailure('configuration');
        }
        locations = LocationSyncService(
          profiles as LocationRepository,
          tracker!,
          PlatformTrackingControls(),
          const String.fromEnvironment('PATHS_API_ORIGIN'),
        );
      }
      if (profiles is AuthenticatedApi) {
        notifications = NotificationRepository(profiles as AuthenticatedApi);
      }
      if (profiles is AuthenticatedApi &&
          profiles is AuthenticatedMediaApi &&
          (widget.repository == null || widget.photoPicker != null)) {
        media = HttpMediaRepository(
          profiles as AuthenticatedApi,
          profiles as AuthenticatedMediaApi,
        );
        photoPicker = widget.photoPicker ?? NativePhotoPicker();
        setupProgress = widget.setupProgress ?? PlatformSetupProgress();
        posts = PostRepository(profiles as AuthenticatedApi);
      }
      if (profiles is AuthenticatedApi) {
        safety = HttpSafetyRepository(
          profiles as AuthenticatedApi,
          onAccessChanged: () async {
            await media?.purge();
            realtime?.refresh();
          },
        );
      }
      if (profiles is HttpAuthRepository) {
        realtime = ChatRealtime(
          origin: const String.fromEnvironment('PATHS_API_ORIGIN'),
          token: profiles.realtimeToken,
        );
        chats = HttpChatRepository(profiles, realtime!.events);
        safetyEvents = realtime!.events.listen((signal) {
          if (!mounted) return;
          if (signal.type == 'conversation.removed' ||
              signal.type == 'profile.access_changed' ||
              signal.type == 'reconnected') {
            profiles.invalidateOwnProfile();
            unawaited(media?.purge());
            safety?.invalidate();
            if (signal.type != 'reconnected') realtime?.refresh();
          }
        });
        chatAuth = cubit!.stream.listen((state) {
          realtime!.configure(
            state.stage == AuthStage.authenticated &&
                    state.account?.adultChecked == true &&
                    state.account?.restricted == false
                ? state.account!.id
                : null,
          );
        });
      }
      deletion = widget.deletion;
      if (deletion == null &&
          widget.repository == null &&
          profiles is HttpAuthRepository) {
        deletion = HttpDeletionRepository(
          origin: const String.fromEnvironment('PATHS_API_ORIGIN'),
          store: PlatformDeletionStore(),
          accountId: () => profiles.accountId,
          token: profiles.realtimeToken,
          clearDevice: (owner) async {
            if (profiles.accountId != null && profiles.accountId != owner) {
              return;
            }
            try {
              await profiles.eraseAcceptedAccount(owner);
            } finally {
              if (profiles.accountId == null || profiles.accountId == owner) {
                await Future.wait([
                  if (locations != null) locations!.eraseDeletedAccount(owner),
                  if (setupProgress != null) setupProgress!.erase(owner),
                ]);
              }
            }
          },
        );
      }
      navigation = createAuthRouter(
        cubit!,
        refresh!,
        profiles as ProfileRepository,
        profiles as ProfileSummaryRepository,
        profiles as VerificationRepository,
        onStartupBlocked: () => _startupReady(force: true),
        setupProgress: setupProgress,
        media: media,
        picker: photoPicker,
        posts: posts,
        chats: chats,
        safety: safety,
        deletion: deletion,
        notifications: notifications,
        push: push,
        relationships: profiles is AuthenticatedApi
            ? HttpRelationshipRepository(profiles as AuthenticatedApi)
            : null,
        locations: locations,
        encounters: locations != null && profiles is EncounterRepository
            ? profiles as EncounterRepository
            : null,
      );
      navigation!.routerDelegate.addListener(_startupReady);
      navigation!.routeInformationProvider.addListener(_startupReady);
      _startupAuth = cubit!.stream.listen((_) => _startupReady());
      unawaited(cubit!.initialize());
      if (deletion != null) {
        unawaited(() async {
          try {
            final record = await deletion!.saved();
            if (mounted && record?.shouldResume == true) {
              navigation?.go('/deletion/receipt');
            }
          } catch (_) {
            if (mounted) navigation?.go('/deletion/receipt');
          }
        }());
      }
      if (push != null && notifications != null) {
        pushAuth = cubit!.stream.listen((_) => unawaited(_pushResume()));
        pushEvents = push!.events.listen((id) {
          if (id.isNotEmpty) unawaited(_openPush());
        });
        unawaited(() async {
          try {
            await push!.initialize(notifications!);
            pushReady = true;
            await _pushResume();
          } catch (error) {
            push!.lastFailure = const AuthFailure('push_registration');
          }
        }());
      }
      realtime?.foreground(
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
      lifecycle = AppLifecycleListener(
        onHide: () {
          final profiles = repository;
          if (profiles is OwnProfileSnapshotRepository) {
            (profiles as OwnProfileSnapshotRepository).invalidateOwnProfile();
          }
          realtime?.foreground(false);
        },
        onPause: () {
          final profiles = repository;
          if (profiles is OwnProfileSnapshotRepository) {
            (profiles as OwnProfileSnapshotRepository).invalidateOwnProfile();
          }
        },
        onResume: () {
          realtime?.foreground(true);
          if (cubit?.state.stage == AuthStage.authenticated) {
            unawaited(cubit!.refreshSession());
            unawaited(_pushResume());
          }
        },
      );
    } on AuthFailure catch (error) {
      failure = error;
      _startupReady(force: true);
    }
  }

  @override
  void dispose() {
    providerLinkOffer.dispose();
    lifecycle?.dispose();
    unawaited(chatAuth?.cancel());
    unawaited(safetyEvents?.cancel());
    unawaited(safety?.close());
    unawaited(realtime?.close());
    unawaited(pushAuth?.cancel());
    unawaited(pushEvents?.cancel());
    unawaited(push?.dispose());
    deletion?.close();
    unawaited(_startupAuth?.cancel());
    navigation?.routerDelegate.removeListener(_startupReady);
    navigation?.routeInformationProvider.removeListener(_startupReady);
    navigation?.dispose();
    refresh?.dispose();
    final owned = cubit;
    final data = repository;
    final native = tracker;
    unawaited(() async {
      await owned?.close();
      if (widget.locationSync == null) await locations?.close();
      await media?.purge();
      media?.dispose();
      await data?.close();
      await native?.dispose();
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (failure != null || cubit == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PathsTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(failure?.message ?? 'Paths could not start.'),
              ),
            ),
          ),
        ),
      );
    }
    return BlocProvider.value(
      value: cubit!,
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (before, after) =>
            before.busy &&
            !after.busy &&
            after.error == null &&
            (before.stage != after.stage ||
                before.account?.adultChecked != after.account?.adultChecked),
        listener: (_, state) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (state.stage == AuthStage.authenticated ||
              state.stage == AuthStage.otp ||
              (state.stage == AuthStage.signedOut && state.notice != null)) {
            TextInput.finishAutofillContext(shouldSave: true);
          }
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Paths',
          theme: PathsTheme.light,
          routerConfig: navigation,
          builder: (context, child) => PathsToastHost(
            child: BlocListener<AuthCubit, AuthState>(
              listenWhen: (before, after) =>
                  (after.error != null && before.error != after.error) ||
                  (after.notice != null && before.notice != after.notice),
              listener: (context, state) {
                if (state.error case final error?) {
                  PathsToast.show(
                    context,
                    '${error.message}${error.requestId == null ? '' : '\nReference: ${error.requestId}'}',
                  );
                } else if (state.notice case final notice?) {
                  PathsToast.show(context, notice, tone: ToastTone.success);
                }
              },
              child: ProviderAuthScope(
                repository: repository is ProviderAuthRepository
                    ? repository as ProviderAuthRepository
                    : null,
                sdk: providerSdk,
                linkOffer: providerLinkOffer,
                child: SafetyScope(
                  repository: safety,
                  child: media == null
                      ? child!
                      : MediaScope(
                          media: media!,
                          picker: photoPicker!,
                          posts: posts!,
                          child: child!,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
