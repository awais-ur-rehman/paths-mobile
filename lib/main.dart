import 'app/brand_licenses.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/router.dart';
import 'app/theme/paths_theme.dart';
import 'core/platform/location_tracker.dart';
import 'core/storage/auth_storage.dart';
import 'features/auth/data/http_auth_repository.dart';
import 'features/auth/domain/auth_models.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'shared/widgets/paths_toast.dart';
import 'features/profile/domain/profile_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerBrandLicenses();
  runApp(const PathsApp());
}

class PathsApp extends StatefulWidget {
  const PathsApp({this.repository, super.key});
  final AuthRepository? repository;
  @override
  State<PathsApp> createState() => _PathsAppState();
}

class _PathsAppState extends State<PathsApp> {
  AuthRepository? repository;
  AuthCubit? cubit;
  AuthRouterRefresh? refresh;
  GoRouter? navigation;
  PlatformLocationTracker? tracker;
  AuthFailure? failure;
  AppLifecycleListener? lifecycle;
  @override
  void initState() {
    super.initState();
    try {
      tracker = widget.repository == null ? PlatformLocationTracker() : null;
      repository =
          widget.repository ??
          HttpAuthRepository(
            origin: const String.fromEnvironment('PATHS_API_ORIGIN'),
            vault: PlatformTokenVault(),
            preferences: PlatformAuthPreferences(),
            purgeTracking: tracker!.stopAndPurge,
          );
      cubit = AuthCubit(repository!);
      refresh = AuthRouterRefresh(cubit!);
      final profiles = repository;
      if (profiles is! ProfileRepository) {
        throw const AuthFailure('configuration');
      }
      navigation = createAuthRouter(
        cubit!,
        refresh!,
        profiles as ProfileRepository,
      );
      unawaited(cubit!.initialize());
      lifecycle = AppLifecycleListener(
        onResume: () {
          if (cubit?.state.stage == AuthStage.authenticated) {
            unawaited(cubit!.refreshSession());
          }
        },
      );
    } on AuthFailure catch (error) {
      failure = error;
    }
  }

  @override
  void dispose() {
    lifecycle?.dispose();
    navigation?.dispose();
    refresh?.dispose();
    final owned = cubit;
    final data = repository;
    final native = tracker;
    unawaited(() async {
      await owned?.close();
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
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}
